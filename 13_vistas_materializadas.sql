-- =====================================================================
-- GesLab · 13 · Vistas materializadas y refresco programado
-- Fase 1 (F1) — Segunda entrega.
-- Requiere 01–12. Re-ejecutable.
--
-- Vistas materializadas por dominio para alimentar el motor de informes
-- sin castigar las tablas transaccionales. Refresco por pg_cron cada
-- 15 minutos (vía refresh materialized view concurrently).
-- =====================================================================

-- Habilitar extensiones necesarias (idempotente en Supabase)
create extension if not exists pg_cron;
create extension if not exists pg_stat_statements;

-- ---------------------------------------------------------------------
-- 1. mv_consumo_reactivo_mes
--    Reactivo × mes × campus × programa × docente, con conversión a unidad base
-- ---------------------------------------------------------------------
drop materialized view if exists mv_consumo_reactivo_mes cascade;
create materialized view mv_consumo_reactivo_mes as
select
  cr.id        as reactivo_id,
  cr.nombre    as reactivo,
  cr.cas,
  cr.unidad::text as unidad_base,
  date_trunc('month', s.inicio)::date as mes,
  coalesce(s.campus_id, '00000000-0000-0000-0000-000000000000'::uuid) as campus_key,
  s.campus_id,
  c.nombre     as campus,
  coalesce(nullif(s.programa_academico,''), 'Sin programa') as programa,
  coalesce(s.docente_id, '00000000-0000-0000-0000-000000000000'::uuid) as docente_key,
  s.docente_id,
  pd.nombre    as docente,
  coalesce(s.practica_id, '00000000-0000-0000-0000-000000000000'::uuid) as practica_key,
  s.practica_id,
  pr.nombre    as practica,
  coalesce(s.curso,'') as curso_key,
  s.curso,
  coalesce(sum(convertir_cantidad(sr.cantidad_prevista,  coalesce(sr.unidad, cr.unidad::text), cr.unidad::text)), 0) as previsto_base,
  coalesce(sum(convertir_cantidad(sr.cantidad_consumida, coalesce(sr.unidad, cr.unidad::text), cr.unidad::text)), 0) as consumido_base,
  count(distinct s.id)                        as n_sesiones,
  coalesce(sum(s.num_estudiantes), 0)         as n_estudiantes
from sesion_reactivos sr
  join sesiones_practica s on s.id = sr.sesion_id
  join catalogo_reactivos cr on cr.id = sr.reactivo_id
  left join campus c on c.id = s.campus_id
  left join perfiles pd on pd.id = s.docente_id
  left join practicas pr on pr.id = s.practica_id
where s.estado <> 'cancelada'
group by cr.id, cr.nombre, cr.cas, cr.unidad,
         date_trunc('month', s.inicio), s.campus_id, c.nombre,
         s.programa_academico, s.docente_id, pd.nombre,
         s.practica_id, pr.nombre, s.curso;
create unique index on mv_consumo_reactivo_mes (reactivo_id, mes, campus_key, docente_key, practica_key, curso_key, programa);
create index on mv_consumo_reactivo_mes (campus_id, mes);
create index on mv_consumo_reactivo_mes (docente_id);
create index on mv_consumo_reactivo_mes (programa);
grant select on mv_consumo_reactivo_mes to authenticated;

-- ---------------------------------------------------------------------
-- 2. mv_stock_tiempo
--    Serie diaria de stock vigente por reactivo × campus (últimos 365 días)
-- ---------------------------------------------------------------------
drop materialized view if exists mv_stock_tiempo cascade;
create materialized view mv_stock_tiempo as
with dias as (
  select generate_series(current_date - 365, current_date, interval '1 day')::date as dia
),
entradas as (
  select e.reactivo_id, e.campus_id, e.cantidad_inicial as cantidad, e.fecha_recepcion as dia
  from envases e
),
salidas as (
  select m.envase_id, e.reactivo_id, e.campus_id,
         case when m.tipo = 'entrada' then m.cantidad
              when m.tipo in ('salida','consumo','residuo','ajuste_negativo') then -m.cantidad
              when m.tipo = 'ajuste_positivo' then m.cantidad
              else 0 end as delta,
         m.creado_en::date as dia
  from movimientos_stock m
  join envases e on e.id = m.envase_id
)
select
  d.dia,
  e.reactivo_id,
  cr.nombre as reactivo,
  cr.unidad::text as unidad,
  e.campus_id,
  c.nombre as campus,
  coalesce(sum(case when en.dia <= d.dia then en.cantidad else 0 end), 0)
    + coalesce(sum(case when s.dia <= d.dia then s.delta else 0 end), 0) as stock_calculado
from dias d
cross join (select distinct reactivo_id, campus_id from envases where campus_id is not null) e
join catalogo_reactivos cr on cr.id = e.reactivo_id
join campus c on c.id = e.campus_id
left join entradas en on en.reactivo_id = e.reactivo_id and en.campus_id = e.campus_id
left join salidas  s  on s.reactivo_id  = e.reactivo_id and s.campus_id  = e.campus_id
group by d.dia, e.reactivo_id, cr.nombre, cr.unidad, e.campus_id, c.nombre;
create unique index on mv_stock_tiempo (dia, reactivo_id, campus_id);
create index on mv_stock_tiempo (reactivo_id, campus_id, dia);
grant select on mv_stock_tiempo to authenticated;

-- ---------------------------------------------------------------------
-- 3. mv_tasa_ruptura
--    Material × campus × proveedor, con rupturas sobre existencia promedio
-- ---------------------------------------------------------------------
drop materialized view if exists mv_tasa_ruptura cascade;
create materialized view mv_tasa_ruptura as
with rupturas as (
  select mcv.material_id, mcv.campus_id, mcv.proveedor_id,
         sum(mcv.cantidad) filter (where mcv.evento = 'rotura')  as rupturas,
         sum(mcv.cantidad) filter (where mcv.evento = 'merma')   as mermas,
         sum(mcv.cantidad) filter (where mcv.evento = 'descarte') as descartes,
         sum(mcv.cantidad) filter (where mcv.evento = 'ingreso') as ingresos
  from materiales_ciclo_vida mcv
  where mcv.fecha >= current_date - interval '365 days'
  group by mcv.material_id, mcv.campus_id, mcv.proveedor_id
),
existencia as (
  select material_id, campus_id,
         (cantidad_buena + cantidad_regular + cantidad_danada) as existencia_total
  from existencias_material
)
select
  cm.id        as material_id,
  cm.nombre    as material,
  cm.tipo_item::text as tipo,
  r.campus_id,
  c.nombre     as campus,
  coalesce(r.proveedor_id, '00000000-0000-0000-0000-000000000000'::uuid) as proveedor_key,
  r.proveedor_id,
  p.nombre     as proveedor,
  coalesce(r.rupturas,  0)::int as rupturas,
  coalesce(r.mermas,    0)::int as mermas,
  coalesce(r.descartes, 0)::int as descartes,
  coalesce(r.ingresos,  0)::int as ingresos,
  coalesce(e.existencia_total, 0)::int as existencia_actual,
  case when coalesce(e.existencia_total,0) > 0
       then round(100.0 * coalesce(r.rupturas,0) / e.existencia_total, 2)
       else null end as tasa_ruptura_pct
from rupturas r
join catalogo_materiales cm on cm.id = r.material_id
join campus c on c.id = r.campus_id
left join proveedores p on p.id = r.proveedor_id
left join existencia e on e.material_id = r.material_id and e.campus_id = r.campus_id;
create unique index on mv_tasa_ruptura (material_id, campus_id, proveedor_key);
grant select on mv_tasa_ruptura to authenticated;

-- ---------------------------------------------------------------------
-- 4. mv_ocupacion_lab
--    Ocupación por laboratorio × bloque horario (día semana × hora)
-- ---------------------------------------------------------------------
drop materialized view if exists mv_ocupacion_lab cascade;
create materialized view mv_ocupacion_lab as
select
  l.id as laboratorio_id,
  l.nombre as laboratorio,
  l.campus_id,
  c.nombre as campus,
  extract(isodow from s.inicio)::int as dia_semana,
  extract(hour   from s.inicio)::int as hora,
  count(*)::int as n_sesiones,
  sum(extract(epoch from (s.fin - s.inicio))/3600)::numeric(10,2) as horas_totales,
  sum(s.num_estudiantes)::int as estudiantes_atendidos
from sesiones_practica s
join laboratorios l on l.id = s.laboratorio_id
left join campus c on c.id = l.campus_id
where s.estado in ('aprobada','finalizada')
  and s.inicio >= current_date - interval '365 days'
group by l.id, l.nombre, l.campus_id, c.nombre,
         extract(isodow from s.inicio), extract(hour from s.inicio);
create unique index on mv_ocupacion_lab (laboratorio_id, dia_semana, hora);
create index on mv_ocupacion_lab (campus_id, dia_semana, hora);
grant select on mv_ocupacion_lab to authenticated;

-- ---------------------------------------------------------------------
-- 5. mv_uso_equipo
--    Horas de uso por equipo × mes × campus (incluye reservas y mantenimientos)
-- ---------------------------------------------------------------------
drop materialized view if exists mv_uso_equipo cascade;
create materialized view mv_uso_equipo as
with uso as (
  select r.equipo_id,
         date_trunc('month', lower(r.periodo))::date as mes,
         extract(epoch from (upper(r.periodo) - lower(r.periodo)))/3600 as horas,
         count(*) over (partition by r.equipo_id, date_trunc('month', lower(r.periodo))) as n_reservas
  from reservas r
  where r.equipo_id is not null and r.estado = 'aprobada'
),
mant as (
  select mp.equipo_id,
         date_trunc('month', mp.fecha_real)::date as mes,
         count(*)::int as n_mantenimientos,
         coalesce(sum(mp.costo),0)::numeric(12,2) as costo_mantenimiento
  from mantenimientos_programados mp
  where mp.estado = 'completado' and mp.fecha_real is not null
  group by mp.equipo_id, date_trunc('month', mp.fecha_real)
)
select
  e.id as equipo_id,
  e.nombre as equipo,
  e.campus_id,
  c.nombre as campus,
  l.nombre as laboratorio,
  coalesce(u.mes, mn.mes) as mes,
  coalesce(sum(u.horas),0)::numeric(10,2) as horas_uso,
  coalesce(max(u.n_reservas),0)::int as n_reservas,
  coalesce(max(mn.n_mantenimientos),0)::int as n_mantenimientos,
  coalesce(max(mn.costo_mantenimiento),0)::numeric(12,2) as costo_mantenimiento,
  e.estado::text as estado
from equipos e
left join campus c on c.id = e.campus_id
left join laboratorios l on l.id = e.laboratorio_id
left join uso u on u.equipo_id = e.id
left join mant mn on mn.equipo_id = e.id and mn.mes = u.mes
where coalesce(u.mes, mn.mes) is not null
group by e.id, e.nombre, e.campus_id, c.nombre, l.nombre, coalesce(u.mes, mn.mes), e.estado;
create unique index on mv_uso_equipo (equipo_id, mes);
create index on mv_uso_equipo (campus_id, mes);
grant select on mv_uso_equipo to authenticated;

-- ---------------------------------------------------------------------
-- 6. mv_cumplimiento_sesion
--    KPIs de aprobación, consumo previsto vs real, tiempos de respuesta
-- ---------------------------------------------------------------------
drop materialized view if exists mv_cumplimiento_sesion cascade;
create materialized view mv_cumplimiento_sesion as
select
  s.id as sesion_id,
  s.campus_id,
  s.docente_id,
  s.programa_academico as programa,
  s.curso,
  s.practica_id,
  s.inicio::date as fecha,
  date_trunc('month', s.inicio)::date as mes,
  s.estado::text as estado,
  s.num_estudiantes,
  extract(epoch from (coalesce(s.aprobado_en, now()) - s.creado_en))/3600 as horas_hasta_aprobacion,
  (select coalesce(sum(convertir_cantidad(sr.cantidad_prevista,  coalesce(sr.unidad, cr.unidad::text), cr.unidad::text)), 0)
     from sesion_reactivos sr join catalogo_reactivos cr on cr.id = sr.reactivo_id
     where sr.sesion_id = s.id) as previsto_base,
  (select coalesce(sum(convertir_cantidad(sr.cantidad_consumida, coalesce(sr.unidad, cr.unidad::text), cr.unidad::text)), 0)
     from sesion_reactivos sr join catalogo_reactivos cr on cr.id = sr.reactivo_id
     where sr.sesion_id = s.id) as consumido_base,
  (select count(*) from sesion_reactivos where sesion_id = s.id) as n_reactivos,
  (select count(*) from sesion_materiales where sesion_id = s.id) as n_materiales
from sesiones_practica s
where s.inicio >= current_date - interval '730 days';
create unique index on mv_cumplimiento_sesion (sesion_id);
create index on mv_cumplimiento_sesion (campus_id, mes);
create index on mv_cumplimiento_sesion (docente_id, mes);
grant select on mv_cumplimiento_sesion to authenticated;

-- ---------------------------------------------------------------------
-- 7. Función que refresca todas las MVs concurrentemente
-- ---------------------------------------------------------------------
create or replace function refrescar_mvs_informes() returns void
language plpgsql security definer set search_path = public as $$
begin
  refresh materialized view concurrently mv_consumo_reactivo_mes;
  refresh materialized view concurrently mv_stock_tiempo;
  refresh materialized view concurrently mv_tasa_ruptura;
  refresh materialized view concurrently mv_ocupacion_lab;
  refresh materialized view concurrently mv_uso_equipo;
  refresh materialized view concurrently mv_cumplimiento_sesion;
end $$;
revoke execute on function refrescar_mvs_informes() from public, anon;
grant execute on function refrescar_mvs_informes() to authenticated;

-- Primer refresco inmediato
select refrescar_mvs_informes();

-- ---------------------------------------------------------------------
-- 8. Programación con pg_cron: cada 15 minutos
-- ---------------------------------------------------------------------
-- Elimina cualquier job previo con el mismo nombre
do $$ begin
  if exists (select 1 from cron.job where jobname = 'geslab_mv_refresh') then
    perform cron.unschedule('geslab_mv_refresh');
  end if;
end $$;
select cron.schedule('geslab_mv_refresh', '*/15 * * * *', 'select public.refrescar_mvs_informes();');

notify pgrst, 'reload schema';
