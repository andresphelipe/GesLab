-- =====================================================================
-- GesLab · 11 · Tablero semanal (pantalla de inicio)
-- Requiere 01–10. Re-ejecutable.
--
-- Devuelve toda la información que la pantalla de Inicio necesita:
--   · sesiones de la semana con lab, docente, campus, programa y # est.
--   · indicadores de faltantes y pendientes por sesión
--
-- Las RLS existentes se encargan de que un docente solo vea sus propias
-- sesiones; técnico y admin ven todo el campus (o todos si no se filtra).
-- =====================================================================

create or replace function tablero_semana(
  p_fecha date default current_date,
  p_campus uuid default null
) returns table (
  sesion_id uuid,
  inicio timestamptz, fin timestamptz,
  practica text, docente text, laboratorio text,
  campus_id uuid, campus text,
  programa text, curso text,
  num_estudiantes int, estado text,
  dia_semana int,              -- 1 = lunes … 6 = sábado
  faltantes int, pendientes int
)
language sql stable security invoker set search_path = public as $$
  with lun as (select (p_fecha - ((extract(isodow from p_fecha)::int - 1)))::date as l),
  rango as (
    select l as desde, l + 6 as hasta from lun
  ),
  ses as (
    select s.*,
           pr.nombre  as practica_n,
           pd.nombre  as docente_n,
           l.nombre   as lab_n,
           c.nombre   as campus_n
    from sesiones_practica s
    left join practicas  pr on pr.id = s.practica_id
    left join perfiles   pd on pd.id = s.docente_id
    left join laboratorios l on l.id = s.laboratorio_id
    left join campus     c on c.id = s.campus_id
    where s.inicio::date between (select desde from rango) and (select hasta from rango)
      and (p_campus is null or s.campus_id = p_campus)
      and s.estado <> 'cancelada'
  ),
  ids as (select array_agg(id) as a from ses),
  cnt as (
    select d.sesion_id,
           count(*) filter (where d.estado in ('falta','sin_cantidad'))::int as faltantes
    from disponibilidad_sesiones((select a from ids)) d
    group by d.sesion_id
  )
  select s.id,
         s.inicio, s.fin,
         coalesce(s.practica_n, 'Sin práctica'),
         coalesce(s.docente_n, 'Sin asignar'),
         coalesce(s.lab_n, '—'),
         s.campus_id, coalesce(s.campus_n, '—'),
         coalesce(nullif(s.programa_academico, ''), 'Sin programa'),
         s.curso,
         coalesce(s.num_estudiantes, 0),
         s.estado::text,
         extract(isodow from s.inicio)::int,
         coalesce(cnt.faltantes, 0),
         case when s.estado in ('borrador','solicitada') then 1 else 0 end
  from ses s
  left join cnt on cnt.sesion_id = s.id
  order by s.inicio;
$$;
grant execute on function tablero_semana(date, uuid) to authenticated;

-- KPIs reducidos para la pantalla de inicio (reutiliza las vistas de 10)
create or replace function inicio_resumen(
  p_fecha date default current_date,
  p_campus uuid default null
) returns jsonb
language sql stable security invoker set search_path = public as $$
  with lun as (select (p_fecha - ((extract(isodow from p_fecha)::int - 1)))::date as l),
  rango as (select l as desde, l + 6 as hasta from lun),
  s as (
    select * from sesiones_practica
     where inicio::date between (select desde from rango) and (select hasta from rango)
       and (p_campus is null or campus_id = p_campus)
       and estado <> 'cancelada'
  ),
  env as (
    select count(*) filter (where estado in ('disponible','en_uso')
      and fecha_caducidad is not null and fecha_caducidad <= current_date + 14) as por_vencer
    from envases
    where (p_campus is null or campus_id = p_campus)
  )
  select jsonb_build_object(
    'desde', (select desde from rango),
    'hasta', (select hasta from rango),
    'sesiones', (select count(*) from s),
    'estudiantes', (select coalesce(sum(num_estudiantes), 0) from s),
    'docentes',    (select count(distinct docente_id) from s),
    'pendientes',  (select count(*) from s where estado in ('borrador','solicitada')),
    'envases_por_vencer', (select por_vencer from env)
  );
$$;
grant execute on function inicio_resumen(date, uuid) to authenticated;

notify pgrst, 'reload schema';
