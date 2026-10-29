-- =====================================================================
-- GesLab · 10 · Informes y analítica
-- Requiere 01–09. Re-ejecutable.
--
-- Entrega vistas y funciones para el módulo de Informes:
--   · KPIs ejecutivos  · consumo de reactivos  · uso de equipos
--   · vidriería y roturas  · docentes y programas  · cumplimiento
--   · tendencia y proyección  · alertas de inventario
--
-- Todas las funciones aceptan rango de fechas y, opcionalmente, campus.
-- NULL en p_campus = todos los campus en los que el usuario tiene acceso.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Función auxiliar: convertir una línea de solicitud/consumo a la
--    unidad base del catálogo (g o mL). Devuelve NULL si no es convertible.
-- ---------------------------------------------------------------------
create or replace function _conv_a_base(p_cant numeric, p_u text, p_base text) returns numeric
language sql immutable as $$
  select case
    when p_cant is null then null
    when coalesce(p_u, '') = '' then p_cant
    else convertir_cantidad(p_cant, p_u, p_base)
  end;
$$;

-- ---------------------------------------------------------------------
-- 2. VISTAS DE APOYO (una fila por línea, con todos los descriptores)
-- ---------------------------------------------------------------------
drop view if exists v_informe_consumo_reactivos cascade;
create view v_informe_consumo_reactivos with (security_invoker = true) as
select
  sr.id,
  s.id            as sesion_id,
  s.inicio::date  as fecha,
  date_trunc('month', s.inicio)::date as mes,
  extract(year from s.inicio)::int    as anio,
  extract(month from s.inicio)::int   as mes_num,
  s.campus_id,
  c.nombre        as campus,
  s.programa_academico as programa,
  s.curso,
  s.estado,
  s.docente_id,
  pd.nombre as docente,
  s.practica_id,
  pr.nombre       as practica,
  cr.id           as reactivo_id,
  cr.nombre       as reactivo,
  cr.cas,
  cr.unidad::text as unidad_base,
  sr.unidad       as unidad_linea,
  sr.cantidad_prevista,
  sr.cantidad_consumida,
  _conv_a_base(sr.cantidad_prevista,  coalesce(sr.unidad, cr.unidad::text), cr.unidad::text) as prevista_base,
  _conv_a_base(sr.cantidad_consumida, coalesce(sr.unidad, cr.unidad::text), cr.unidad::text) as consumida_base
from sesion_reactivos sr
  join sesiones_practica s on s.id = sr.sesion_id
  join catalogo_reactivos cr on cr.id = sr.reactivo_id
  left join campus c on c.id = s.campus_id
  left join perfiles pd on pd.id = s.docente_id
  left join practicas pr on pr.id = s.practica_id;

drop view if exists v_informe_consumo_materiales cascade;
create view v_informe_consumo_materiales with (security_invoker = true) as
select
  sm.id,
  s.id as sesion_id,
  s.inicio::date as fecha,
  date_trunc('month', s.inicio)::date as mes,
  s.campus_id, c.nombre as campus,
  s.programa_academico as programa, s.curso, s.estado,
  s.docente_id, pd.nombre as docente,
  s.practica_id, pr.nombre as practica,
  cm.id as material_id, cm.nombre as material, cm.tipo_item,
  sm.cantidad_prevista, sm.cantidad_consumida
from sesion_materiales sm
  join sesiones_practica s on s.id = sm.sesion_id
  join catalogo_materiales cm on cm.id = sm.material_id
  left join campus c on c.id = s.campus_id
  left join perfiles pd on pd.id = s.docente_id
  left join practicas pr on pr.id = s.practica_id;

-- ---------------------------------------------------------------------
-- 3. KPIs EJECUTIVOS
-- ---------------------------------------------------------------------
create or replace function informe_kpis(
  p_desde date, p_hasta date, p_campus uuid default null
) returns jsonb
language sql stable security invoker set search_path = public as $$
  with s as (
    select * from sesiones_practica
     where inicio::date between p_desde and p_hasta
       and (p_campus is null or campus_id = p_campus)
  ),
  cons as (
    select coalesce(sum(consumida_base), 0) as consumo
    from v_informe_consumo_reactivos
    where fecha between p_desde and p_hasta
      and (p_campus is null or campus_id = p_campus)
  ),
  cons_prev as (
    select coalesce(sum(prevista_base), 0) as previsto
    from v_informe_consumo_reactivos
    where fecha between p_desde and p_hasta
      and (p_campus is null or campus_id = p_campus)
  ),
  inc as (
    select count(*) filter (where creado_en::date between p_desde and p_hasta) as nuevas,
           count(*) filter (where estado = 'abierta') as abiertas
    from incidencias i
    left join laboratorios l on l.id = i.laboratorio_id
    where (p_campus is null or l.campus_id = p_campus)
  ),
  stock as (
    select count(*) filter (where fecha_caducidad is not null
                              and fecha_caducidad <= current_date + 60) as por_vencer,
           count(*) filter (where estado = 'disponible'
                              and (fecha_caducidad is null or fecha_caducidad > current_date)) as envases_ok,
           count(distinct reactivo_id) as reactivos_distintos
    from envases
    where (p_campus is null or campus_id = p_campus)
  )
  select jsonb_build_object(
    'sesiones_total',   (select count(*) from s),
    'sesiones_aprobadas',(select count(*) from s where estado in ('aprobada','finalizada')),
    'sesiones_borrador',(select count(*) from s where estado = 'borrador'),
    'sesiones_rechazadas',(select count(*) from s where estado = 'rechazada'),
    'docentes_activos', (select count(distinct docente_id) from s),
    'estudiantes',      (select coalesce(sum(num_estudiantes),0) from s),
    'consumo_total',    (select consumo from cons),
    'previsto_total',   (select previsto from cons_prev),
    'eficiencia',       case when (select previsto from cons_prev) > 0
                             then round(100 * (select consumo from cons) / (select previsto from cons_prev), 1)
                             else null end,
    'incidencias_nuevas',(select nuevas from inc),
    'incidencias_abiertas',(select abiertas from inc),
    'envases_por_vencer',(select por_vencer from stock),
    'envases_vigentes',  (select envases_ok from stock),
    'reactivos_catalogo',(select reactivos_distintos from stock)
  );
$$;
grant execute on function informe_kpis(date, date, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 4. SERIE TEMPORAL por mes (sesiones y consumo)
-- ---------------------------------------------------------------------
create or replace function informe_serie_mensual(
  p_desde date, p_hasta date, p_campus uuid default null
) returns table (
  mes date, sesiones int, estudiantes int,
  consumo_g numeric, consumo_ml numeric, consumo_unidad numeric,
  previsto_g numeric, previsto_ml numeric
)
language sql stable security invoker set search_path = public as $$
  with meses as (
    select generate_series(date_trunc('month', p_desde),
                           date_trunc('month', p_hasta),
                           interval '1 month')::date as mes
  ),
  ses as (
    select date_trunc('month', inicio)::date as mes,
           count(*) as sesiones,
           coalesce(sum(num_estudiantes),0) as estudiantes
    from sesiones_practica
    where inicio::date between p_desde and p_hasta
      and (p_campus is null or campus_id = p_campus)
    group by 1
  ),
  reac as (
    select mes,
           sum(consumida_base) filter (where unidad_base = 'g')  as consumo_g,
           sum(consumida_base) filter (where unidad_base = 'mL') as consumo_ml,
           sum(consumida_base) filter (where unidad_base = 'unidad') as consumo_unidad,
           sum(prevista_base)  filter (where unidad_base = 'g')  as previsto_g,
           sum(prevista_base)  filter (where unidad_base = 'mL') as previsto_ml
    from v_informe_consumo_reactivos
    where fecha between p_desde and p_hasta
      and (p_campus is null or campus_id = p_campus)
    group by mes
  )
  select m.mes,
         coalesce(ses.sesiones,0),
         coalesce(ses.estudiantes,0),
         coalesce(reac.consumo_g,0),  coalesce(reac.consumo_ml,0),  coalesce(reac.consumo_unidad,0),
         coalesce(reac.previsto_g,0), coalesce(reac.previsto_ml,0)
  from meses m
  left join ses on ses.mes = m.mes
  left join reac on reac.mes = m.mes
  order by m.mes;
$$;
grant execute on function informe_serie_mensual(date, date, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 5. TOP REACTIVOS, MATERIALES, EQUIPOS, DOCENTES, PROGRAMAS
-- ---------------------------------------------------------------------
create or replace function informe_top_reactivos(
  p_desde date, p_hasta date, p_campus uuid default null, p_limite int default 15
) returns table (
  reactivo_id uuid, reactivo text, cas text, unidad text,
  sesiones int, consumo numeric, previsto numeric, eficiencia numeric
)
language sql stable security invoker set search_path = public as $$
  select reactivo_id, reactivo, cas, unidad_base as unidad,
         count(distinct sesion_id)::int as sesiones,
         coalesce(sum(consumida_base), 0) as consumo,
         coalesce(sum(prevista_base), 0)  as previsto,
         case when coalesce(sum(prevista_base),0) > 0
              then round(100 * sum(consumida_base) / sum(prevista_base), 1) end as eficiencia
  from v_informe_consumo_reactivos
  where fecha between p_desde and p_hasta
    and (p_campus is null or campus_id = p_campus)
  group by reactivo_id, reactivo, cas, unidad_base
  order by 6 desc nulls last, 5 desc
  limit greatest(1, p_limite);
$$;
grant execute on function informe_top_reactivos(date, date, uuid, int) to authenticated;

create or replace function informe_top_materiales(
  p_desde date, p_hasta date, p_campus uuid default null, p_limite int default 15
) returns table (
  material_id uuid, material text, tipo text,
  sesiones int, consumo numeric, previsto numeric
)
language sql stable security invoker set search_path = public as $$
  select material_id, material, tipo_item::text as tipo,
         count(distinct sesion_id)::int as sesiones,
         coalesce(sum(cantidad_consumida),0) as consumo,
         coalesce(sum(cantidad_prevista),0) as previsto
  from v_informe_consumo_materiales
  where fecha between p_desde and p_hasta
    and (p_campus is null or campus_id = p_campus)
  group by material_id, material, tipo_item
  order by 5 desc nulls last, 4 desc
  limit greatest(1, p_limite);
$$;
grant execute on function informe_top_materiales(date, date, uuid, int) to authenticated;

create or replace function informe_top_docentes(
  p_desde date, p_hasta date, p_campus uuid default null, p_limite int default 15
) returns table (
  docente_id uuid, docente text, programa text,
  sesiones int, estudiantes int, horas numeric, consumo_g numeric, consumo_ml numeric
)
language sql stable security invoker set search_path = public as $$
  with ses as (
    select s.docente_id, p.nombre, s.programa_academico,
           s.id as sesion_id,
           s.num_estudiantes,
           extract(epoch from (s.fin - s.inicio))/3600 as horas
    from sesiones_practica s left join perfiles p on p.id = s.docente_id
    where s.inicio::date between p_desde and p_hasta
      and (p_campus is null or s.campus_id = p_campus)
  ),
  cons as (
    select sesion_id,
           sum(consumida_base) filter (where unidad_base = 'g')  as cg,
           sum(consumida_base) filter (where unidad_base = 'mL') as cm
    from v_informe_consumo_reactivos
    where fecha between p_desde and p_hasta
      and (p_campus is null or campus_id = p_campus)
    group by sesion_id
  )
  select ses.docente_id,
         coalesce(ses.nombre, 'Sin asignar') as docente,
         max(ses.programa_academico) as programa,
         count(*)::int as sesiones,
         coalesce(sum(ses.num_estudiantes),0)::int as estudiantes,
         round(sum(ses.horas)::numeric, 1) as horas,
         coalesce(sum(cons.cg),0) as consumo_g,
         coalesce(sum(cons.cm),0) as consumo_ml
  from ses left join cons on cons.sesion_id = ses.sesion_id
  group by ses.docente_id, ses.nombre
  order by count(*) desc, sum(ses.num_estudiantes) desc nulls last
  limit greatest(1, p_limite);
$$;
grant execute on function informe_top_docentes(date, date, uuid, int) to authenticated;

create or replace function informe_top_programas(
  p_desde date, p_hasta date, p_campus uuid default null
) returns table (
  programa text, sesiones int, estudiantes int,
  docentes int, consumo_g numeric, consumo_ml numeric
)
language sql stable security invoker set search_path = public as $$
  with ses as (
    select coalesce(nullif(programa_academico, ''), 'Sin especificar') as programa,
           id as sesion_id, docente_id, num_estudiantes
    from sesiones_practica
    where inicio::date between p_desde and p_hasta
      and (p_campus is null or campus_id = p_campus)
  ),
  cons as (
    select sesion_id,
           sum(consumida_base) filter (where unidad_base = 'g') as cg,
           sum(consumida_base) filter (where unidad_base = 'mL') as cm
    from v_informe_consumo_reactivos
    where fecha between p_desde and p_hasta
      and (p_campus is null or campus_id = p_campus)
    group by sesion_id
  )
  select ses.programa,
         count(*)::int as sesiones,
         coalesce(sum(ses.num_estudiantes),0)::int as estudiantes,
         count(distinct ses.docente_id)::int as docentes,
         coalesce(sum(cons.cg),0) as consumo_g,
         coalesce(sum(cons.cm),0) as consumo_ml
  from ses left join cons on cons.sesion_id = ses.sesion_id
  group by ses.programa
  order by count(*) desc;
$$;
grant execute on function informe_top_programas(date, date, uuid) to authenticated;

create or replace function informe_top_practicas(
  p_desde date, p_hasta date, p_campus uuid default null, p_limite int default 15
) returns table (
  practica_id uuid, practica text, sesiones int, estudiantes int
)
language sql stable security invoker set search_path = public as $$
  select s.practica_id,
         coalesce(pr.nombre, 'Sin práctica asignada') as practica,
         count(*)::int as sesiones,
         coalesce(sum(s.num_estudiantes),0)::int as estudiantes
  from sesiones_practica s left join practicas pr on pr.id = s.practica_id
  where s.inicio::date between p_desde and p_hasta
    and (p_campus is null or s.campus_id = p_campus)
  group by s.practica_id, pr.nombre
  order by count(*) desc
  limit greatest(1, p_limite);
$$;
grant execute on function informe_top_practicas(date, date, uuid, int) to authenticated;

-- ---------------------------------------------------------------------
-- 6. EQUIPOS: uso y disponibilidad
-- ---------------------------------------------------------------------
create or replace function informe_uso_equipos(
  p_desde date, p_hasta date, p_campus uuid default null, p_limite int default 20
) returns table (
  equipo_id uuid, equipo text, campus text, laboratorio text,
  reservas int, horas numeric, estado text
)
language sql stable security invoker set search_path = public as $$
  select e.id, e.nombre,
         c.nombre as campus, l.nombre as laboratorio,
         count(r.id)::int as reservas,
         round(coalesce(sum(extract(epoch from (upper(r.periodo) - lower(r.periodo)))/3600), 0)::numeric, 1) as horas,
         e.estado::text
  from equipos e
  left join laboratorios l on l.id = e.laboratorio_id
  left join campus c on c.id = l.campus_id
  left join reservas r on r.equipo_id = e.id
       and lower(r.periodo)::date between p_desde and p_hasta
       and r.estado = 'aprobada'
  where (p_campus is null or l.campus_id = p_campus)
  group by e.id, e.nombre, c.nombre, l.nombre, e.estado
  order by 6 desc nulls last, 5 desc
  limit greatest(1, p_limite);
$$;
grant execute on function informe_uso_equipos(date, date, uuid, int) to authenticated;

-- ---------------------------------------------------------------------
-- 7. VIDRIERÍA Y ROTURAS
-- ---------------------------------------------------------------------
create or replace function informe_vidrieria(
  p_desde date, p_hasta date, p_campus uuid default null
) returns table (
  campus text, material text,
  buena int, regular int, danada int, roturas int, costo_roturas numeric
)
language sql stable security invoker set search_path = public as $$
  with em as (
    select c.nombre as campus, cm.nombre as material,
           coalesce(sum(e.cantidad_buena),0)::int    as buena,
           coalesce(sum(e.cantidad_regular),0)::int  as regular,
           coalesce(sum(e.cantidad_danada),0)::int  as dannada
    from existencias_material e
    join catalogo_materiales cm on cm.id = e.material_id
    join campus c on c.id = e.campus_id
    where cm.tipo_item = 'vidrieria'
      and (p_campus is null or e.campus_id = p_campus)
    group by c.nombre, cm.nombre
  ),
  rot as (
    select c.nombre as campus, cm.nombre as material,
           coalesce(sum(mem.cantidad) filter (where mem.tipo = 'rotura'), 0)::int as roturas,
           0::numeric as costo
    from movimientos_existencia_material mem
    join existencias_material ex on ex.id = mem.existencia_id
    join catalogo_materiales cm on cm.id = ex.material_id
    join campus c on c.id = ex.campus_id
    where mem.creado_en::date between p_desde and p_hasta
      and (p_campus is null or ex.campus_id = p_campus)
    group by c.nombre, cm.nombre
  )
  select em.campus, em.material, em.buena, em.regular, em.dannada,
         coalesce(rot.roturas, 0), coalesce(rot.costo, 0)
  from em left join rot on rot.campus = em.campus and rot.material = em.material
  order by em.campus, em.material;
$$;
grant execute on function informe_vidrieria(date, date, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 8. CUMPLIMIENTO: aprobación, consumo real vs previsto, tiempos
-- ---------------------------------------------------------------------
create or replace function informe_cumplimiento(
  p_desde date, p_hasta date, p_campus uuid default null
) returns jsonb
language sql stable security invoker set search_path = public as $$
  with s as (
    select *, extract(epoch from (coalesce(aprobado_en, now()) - creado_en))/3600 as horas_apro
    from sesiones_practica
    where inicio::date between p_desde and p_hasta
      and (p_campus is null or campus_id = p_campus)
  ),
  reac as (
    select sum(consumida_base) as c, sum(prevista_base) as p
    from v_informe_consumo_reactivos
    where fecha between p_desde and p_hasta
      and (p_campus is null or campus_id = p_campus)
  )
  select jsonb_build_object(
    'total', (select count(*) from s),
    'por_estado', (select jsonb_object_agg(estado, cnt)
                   from (select estado::text, count(*) as cnt from s group by estado) x),
    'pct_aprobadas', case when (select count(*) from s) > 0
      then round(100.0 * (select count(*) from s where estado in ('aprobada','finalizada'))
                       / (select count(*) from s), 1) end,
    'horas_aprobacion_prom', (select round(avg(horas_apro)::numeric, 1) from s where aprobado_en is not null),
    'horas_aprobacion_p50',  (select round(percentile_cont(0.5) within group (order by horas_apro)::numeric, 1)
                              from s where aprobado_en is not null),
    'consumo_vs_previsto_pct', case when (select p from reac) > 0
      then round(100 * (select c from reac) / (select p from reac), 1) end
  );
$$;
grant execute on function informe_cumplimiento(date, date, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 9. TENDENCIA Y PROYECCIÓN (regresión lineal sobre serie mensual)
-- ---------------------------------------------------------------------
create or replace function informe_proyeccion(
  p_desde date, p_hasta date, p_campus uuid default null, p_meses int default 3
) returns table (
  mes date, sesiones_prev numeric, consumo_g_prev numeric, consumo_ml_prev numeric, es_proyeccion boolean
)
language plpgsql stable security invoker set search_path = public as $$
declare
  v_a_s numeric; v_b_s numeric;
  v_a_g numeric; v_b_g numeric;
  v_a_m numeric; v_b_m numeric;
  v_ult date;
  i int;
begin
  create temporary table _hist on commit drop as
  select *, row_number() over (order by mes) - 1 as t
  from informe_serie_mensual(p_desde, p_hasta, p_campus);

  select regr_slope(sesiones, t), regr_intercept(sesiones, t) into v_a_s, v_b_s from _hist;
  select regr_slope(consumo_g, t), regr_intercept(consumo_g, t) into v_a_g, v_b_g from _hist;
  select regr_slope(consumo_ml, t), regr_intercept(consumo_ml, t) into v_a_m, v_b_m from _hist;
  select max(mes) into v_ult from _hist;

  return query
    select h.mes,
           h.sesiones::numeric, h.consumo_g, h.consumo_ml, false
    from _hist h;

  for i in 1..greatest(0, p_meses) loop
    return query select
      (v_ult + (i || ' month')::interval)::date,
      greatest(0, round(coalesce(v_b_s,0) + coalesce(v_a_s,0) * ((select max(t) from _hist) + i), 2)),
      greatest(0, round(coalesce(v_b_g,0) + coalesce(v_a_g,0) * ((select max(t) from _hist) + i), 2)),
      greatest(0, round(coalesce(v_b_m,0) + coalesce(v_a_m,0) * ((select max(t) from _hist) + i), 2)),
      true;
  end loop;
end $$;
grant execute on function informe_proyeccion(date, date, uuid, int) to authenticated;

-- ---------------------------------------------------------------------
-- 10. ALERTAS: inventario crítico cruzado con consumo histórico
-- ---------------------------------------------------------------------
create or replace function informe_alertas(
  p_campus uuid default null, p_dias_consumo int default 180
) returns jsonb
language sql stable security invoker set search_path = public as $$
  with vencer as (
    select e.id, cr.nombre, c.nombre as campus,
           e.fecha_caducidad, e.cantidad_actual, cr.unidad::text as unidad
    from envases e
    join catalogo_reactivos cr on cr.id = e.reactivo_id
    join campus c on c.id = e.campus_id
    where e.estado in ('disponible','en_uso')
      and e.fecha_caducidad is not null
      and e.fecha_caducidad <= current_date + 90
      and (p_campus is null or e.campus_id = p_campus)
    order by e.fecha_caducidad
  ),
  bajos as (
    select cr.id, cr.nombre, cr.unidad::text as unidad, cr.stock_minimo,
           coalesce(sum(e.cantidad_actual) filter (
             where e.estado in ('disponible','en_uso')
               and (e.fecha_caducidad is null or e.fecha_caducidad > current_date)
           ), 0) as stock
    from catalogo_reactivos cr
    left join envases e on e.reactivo_id = cr.id
          and (p_campus is null or e.campus_id = p_campus)
    where cr.activo and cr.stock_minimo > 0
    group by cr.id
    having coalesce(sum(e.cantidad_actual) filter (
             where e.estado in ('disponible','en_uso')
               and (e.fecha_caducidad is null or e.fecha_caducidad > current_date)
           ), 0) < cr.stock_minimo
    order by cr.nombre
  ),
  demanda as (
    select reactivo_id, reactivo, unidad_base as unidad,
           sum(consumida_base) as consumo,
           round(sum(consumida_base) / (p_dias_consumo::numeric / 30.0), 2) as consumo_mes
    from v_informe_consumo_reactivos
    where fecha >= current_date - p_dias_consumo
      and (p_campus is null or campus_id = p_campus)
    group by reactivo_id, reactivo, unidad_base
    order by sum(consumida_base) desc nulls last
    limit 15
  )
  select jsonb_build_object(
    'por_vencer',    coalesce((select jsonb_agg(to_jsonb(v)) from vencer v), '[]'::jsonb),
    'bajos_minimo',  coalesce((select jsonb_agg(to_jsonb(b)) from bajos b), '[]'::jsonb),
    'alta_demanda',  coalesce((select jsonb_agg(to_jsonb(d)) from demanda d), '[]'::jsonb)
  );
$$;
grant execute on function informe_alertas(uuid, int) to authenticated;

-- ---------------------------------------------------------------------
-- 11. HEATMAP: horario preferido de uso (día de semana × hora)
-- ---------------------------------------------------------------------
create or replace function informe_heatmap_horario(
  p_desde date, p_hasta date, p_campus uuid default null
) returns table (dia_semana int, hora int, sesiones int)
language sql stable security invoker set search_path = public as $$
  select extract(dow from inicio)::int,
         extract(hour from inicio)::int,
         count(*)::int
  from sesiones_practica
  where inicio::date between p_desde and p_hasta
    and (p_campus is null or campus_id = p_campus)
  group by 1, 2
  order by 1, 2;
$$;
grant execute on function informe_heatmap_horario(date, date, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 12. DETALLE POR SESIÓN (para exportar a Excel)
-- ---------------------------------------------------------------------
create or replace function informe_sesiones_detalle(
  p_desde date, p_hasta date, p_campus uuid default null
) returns table (
  sesion_id uuid, fecha date, campus text, programa text, curso text,
  docente text, practica text, estudiantes int, estado text,
  reactivos int, consumo_g numeric, consumo_ml numeric
)
language sql stable security invoker set search_path = public as $$
  select s.id, s.inicio::date, c.nombre, s.programa_academico, s.curso,
         pd.nombre, pr.nombre, s.num_estudiantes, s.estado::text,
         (select count(*) from sesion_reactivos sr where sr.sesion_id = s.id)::int,
         (select coalesce(sum(consumida_base),0) from v_informe_consumo_reactivos v
          where v.sesion_id = s.id and v.unidad_base = 'g'),
         (select coalesce(sum(consumida_base),0) from v_informe_consumo_reactivos v
          where v.sesion_id = s.id and v.unidad_base = 'mL')
  from sesiones_practica s
  left join campus c on c.id = s.campus_id
  left join perfiles pd on pd.id = s.docente_id
  left join practicas pr on pr.id = s.practica_id
  where s.inicio::date between p_desde and p_hasta
    and (p_campus is null or s.campus_id = p_campus)
  order by s.inicio desc;
$$;
grant execute on function informe_sesiones_detalle(date, date, uuid) to authenticated;

notify pgrst, 'reload schema';
