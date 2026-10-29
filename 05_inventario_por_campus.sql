-- =====================================================================
-- GesLab · 05 · Inventario por campus, disponibilidad y consumos
-- Requiere haber ejecutado antes 04_campus_programa_decisiones.sql
-- Es re-ejecutable (usa IF NOT EXISTS / CREATE OR REPLACE).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. COLUMNAS NUEVAS
-- ---------------------------------------------------------------------
alter table envases
  add column if not exists campus_id       uuid references campus(id),
  add column if not exists id_inventario   text unique,      -- p. ej. REA-TUR-0001 (el ID del Excel)
  add column if not exists fecha_conteo    date,
  add column if not exists base_existencia text,
  add column if not exists revisar         boolean not null default false,
  add column if not exists motivo_revision text,
  add column if not exists origen          text,
  add column if not exists ubicacion_texto text,
  add column if not exists marca           text,
  add column if not exists pureza          text,
  add column if not exists codigo_interno  text,
  add column if not exists recibido_por    text;
create index if not exists envases_campus_idx on envases (campus_id, reactivo_id);

alter table catalogo_materiales
  add column if not exists tipo_item text not null default 'vidrieria'
  check (tipo_item in ('vidrieria', 'equipo', 'consumible'));

alter table equipos
  add column if not exists campus_id            uuid references campus(id),
  add column if not exists fuera_de_sede        text,   -- null = está en su sede; si no, dónde está (préstamo o envío)
  add column if not exists material_id          uuid references catalogo_materiales(id),
  add column if not exists cantidad             int not null default 1 check (cantidad >= 1),
  add column if not exists salon                text,
  add column if not exists area                 text,
  add column if not exists codigo_activo        text,
  add column if not exists numero_inventario    text,
  add column if not exists condicion            text,
  add column if not exists responsable          text,
  add column if not exists fecha_inventario     date,
  add column if not exists id_inventario        text unique,
  add column if not exists revisar              boolean not null default false,
  add column if not exists motivo_revision      text,
  add column if not exists origen               text;
create index if not exists equipos_campus_idx on equipos (campus_id, material_id);

-- Vidriería por campus
create table if not exists existencias_material (
  id               uuid primary key default gen_random_uuid(),
  material_id      uuid not null references catalogo_materiales(id) on delete cascade,
  campus_id        uuid not null references campus(id),
  cantidad_buena   int not null default 0 check (cantidad_buena >= 0),
  cantidad_regular int not null default 0 check (cantidad_regular >= 0),
  cantidad_danada  int not null default 0 check (cantidad_danada >= 0),
  ubicacion        text,
  fecha_conteo     date,
  observaciones    text,
  id_inventario    text unique,
  unique (material_id, campus_id)
);

create table if not exists movimientos_existencia_material (
  id            uuid primary key default gen_random_uuid(),
  existencia_id uuid not null references existencias_material(id) on delete cascade,
  tipo          text not null check (tipo in ('rotura', 'correccion', 'conteo')),
  cantidad      int not null,                       -- con signo: + rotura, − corrección
  sesion_id     uuid references sesiones_practica(id) on delete set null,
  usuario_id    uuid references perfiles(id) default auth.uid(),
  motivo        text,
  creado_en     timestamptz not null default now()
);

alter table existencias_material enable row level security;
alter table movimientos_existencia_material enable row level security;
drop policy if exists exm_lectura on existencias_material;
create policy exm_lectura on existencias_material for select to authenticated using (true);
drop policy if exists exm_personal on existencias_material;
create policy exm_personal on existencias_material for all to authenticated
  using (es_personal()) with check (es_personal());
drop policy if exists mexm_lectura on movimientos_existencia_material;
create policy mexm_lectura on movimientos_existencia_material for select to authenticated using (es_personal());

-- ---------------------------------------------------------------------
-- 2. CONVERSIÓN DE UNIDADES (g, kg, mg · mL, L · unidad)
-- Devuelve NULL si las unidades no son comparables (p. ej. «frasco lavador»).
-- ---------------------------------------------------------------------
create or replace function convertir_cantidad(p_cant numeric, p_de text, p_a text)
returns numeric
language plpgsql immutable as $$
declare
  de text := lower(trim(coalesce(p_de, '')));
  a  text := lower(trim(coalesce(p_a, '')));
  g_de text; g_a text; f_de numeric; f_a numeric;
begin
  if p_cant is null then return null; end if;
  if de = '' then de := a; end if;      -- línea sin unidad: se asume la del catálogo
  g_de := case when de in ('mg', 'g', 'gr', 'kg') then 'm'
               when de in ('ml', 'l', 'lt') then 'v'
               when de in ('unidad', 'unidades') then 'u' end;
  g_a  := case when a in ('mg', 'g', 'gr', 'kg') then 'm'
               when a in ('ml', 'l', 'lt') then 'v'
               when a in ('unidad', 'unidades') then 'u' end;
  if g_de is null or g_a is null or g_de <> g_a then return null; end if;
  f_de := case de when 'mg' then 0.001 when 'kg' then 1000 when 'l' then 1000 when 'lt' then 1000 else 1 end;
  f_a  := case a  when 'mg' then 0.001 when 'kg' then 1000 when 'l' then 1000 when 'lt' then 1000 else 1 end;
  return p_cant * f_de / f_a;
end $$;

-- ---------------------------------------------------------------------
-- 3. VISTAS: EXISTENCIA VIGENTE Y COMPROMETIDA POR CAMPUS
-- Vigente = envases disponibles/en uso y no vencidos. Los vencidos se
-- cargan y se marcan, pero no cuentan como disponibles.
-- ---------------------------------------------------------------------
create or replace view v_existencias_reactivo with (security_invoker = true) as
select e.campus_id, e.reactivo_id,
       coalesce(sum(e.cantidad_actual) filter (
         where e.estado in ('disponible', 'en_uso')
           and (e.fecha_caducidad is null or e.fecha_caducidad >= current_date)), 0) as vigente,
       coalesce(sum(e.cantidad_actual) filter (
         where e.estado = 'vencido' or e.fecha_caducidad < current_date), 0) as vencido,
       count(*) as envases
from envases e
group by e.campus_id, e.reactivo_id;

create or replace view v_comprometido_reactivo with (security_invoker = true) as
select s.campus_id, sr.reactivo_id,
       sum(greatest(
         coalesce(convertir_cantidad(sr.cantidad_prevista, sr.unidad, cr.unidad::text), 0)
         - coalesce(convertir_cantidad(sr.cantidad_consumida, sr.unidad, cr.unidad::text), 0), 0)) as comprometido
from sesion_reactivos sr
join sesiones_practica s on s.id = sr.sesion_id and s.estado = 'aprobada'
join catalogo_reactivos cr on cr.id = sr.reactivo_id
group by s.campus_id, sr.reactivo_id;

-- ---------------------------------------------------------------------
-- 4. ¿HAY LO QUE PIDE CADA SESIÓN?
-- Reactivos: consumibles → existencia vigente − comprometido por sesiones
--   aprobadas − lo pedido por sesiones anteriores de la misma consulta.
-- Equipos y vidriería: reutilizables → se comparan solo contra sesiones
--   que se cruzan en el tiempo, en el mismo campus.
-- Equipos prestados a otra sede cuentan como disponibles, con aviso de traslado.
-- estado: ok | ok_traslado | falta | sin_cantidad | sin_unidad | sin_campus
-- ---------------------------------------------------------------------
create or replace function disponibilidad_sesiones(p_ids uuid[])
returns table (sesion_id uuid, tipo text, item_id uuid, item text, unidad text,
               solicitado numeric, disponible numeric, faltante numeric,
               estado text, mensaje text)
language plpgsql stable set search_path = public as $$
#variable_conflict use_column
begin
  return query
  with ses as (
    select s.id, s.campus_id, s.inicio, s.fin from sesiones_practica s where s.id = any(p_ids)
  ), lin as (
    select ses.id as sid, ses.campus_id as cid, ses.inicio as ini, cr.id as rid, cr.nombre as nom,
           cr.unidad::text as u, sr.cantidad_prevista as pedido,
           convertir_cantidad(sr.cantidad_prevista, sr.unidad, cr.unidad::text) as sol
    from ses
    join sesion_reactivos sr on sr.sesion_id = ses.id
    join catalogo_reactivos cr on cr.id = sr.reactivo_id
  ), acc as (
    select lin.*,
           coalesce(sum(lin.sol) over (partition by lin.cid, lin.rid order by lin.ini, lin.sid
                    rows between unbounded preceding and 1 preceding), 0) as previo
    from lin
  ), base as (
    select acc.*,
      coalesce((select ex.vigente from v_existencias_reactivo ex
                where ex.campus_id = acc.cid and ex.reactivo_id = acc.rid), 0) as vig,
      coalesce((select ex.vencido from v_existencias_reactivo ex
                where ex.campus_id = acc.cid and ex.reactivo_id = acc.rid), 0) as venc,
      coalesce((select sum(greatest(
                  coalesce(convertir_cantidad(sr2.cantidad_prevista, sr2.unidad, acc.u), 0)
                  - coalesce(convertir_cantidad(sr2.cantidad_consumida, sr2.unidad, acc.u), 0), 0))
                from sesion_reactivos sr2
                join sesiones_practica s2 on s2.id = sr2.sesion_id
                where s2.estado = 'aprobada' and s2.campus_id = acc.cid
                  and sr2.reactivo_id = acc.rid and s2.id <> all (p_ids)), 0) as comp
    from acc
  )
  select b.sid, 'reactivo'::text, b.rid, b.nom, b.u, b.sol,
         b.vig - b.comp - b.previo,
         greatest(b.sol - (b.vig - b.comp - b.previo), 0),
         case when b.cid is null then 'sin_campus'
              when b.pedido is null then 'sin_cantidad'
              when b.sol is null then 'sin_unidad'
              when b.sol <= b.vig - b.comp - b.previo then 'ok' else 'falta' end,
         case when b.cid is null then 'La sesión no tiene campus'
              when b.pedido is null then 'No se indicó cantidad'
              when b.sol is null then 'La unidad pedida no se puede comparar con ' || b.u
              when b.sol <= b.vig - b.comp - b.previo then null
              else 'Libre: ' || round(greatest(b.vig - b.comp - b.previo, 0), 2) || ' ' || b.u
                   || ' · pedido: ' || round(b.sol, 2) || ' ' || b.u
                   || case when b.venc > 0 then ' · hay ' || round(b.venc, 2) || ' ' || b.u || ' vencido' else '' end end
  from base b

  union all

  (with ses as (
    select s.id, s.campus_id, s.inicio, s.fin from sesiones_practica s where s.id = any(p_ids)
  ), mlin as (
    select ses.id as sid, ses.campus_id as cid, ses.inicio as ini, ses.fin as fn,
           cm.id as mid, cm.nombre as nom, cm.tipo_item as ti, sm.cantidad_prevista as pedido
    from ses
    join sesion_materiales sm on sm.sesion_id = ses.id
    join catalogo_materiales cm on cm.id = sm.material_id
  ), mb as (
    select mlin.*,
      case when mlin.ti = 'equipo'
           then coalesce((select sum(e.cantidad) from equipos e
                          where e.material_id = mlin.mid and e.campus_id = mlin.cid and e.estado = 'operativo'), 0)
           else coalesce((select sum(x.cantidad_buena + x.cantidad_regular) from existencias_material x
                          where x.material_id = mlin.mid and x.campus_id = mlin.cid), 0) end as total,
      case when mlin.ti = 'equipo'
           then coalesce((select sum(e.cantidad) from equipos e
                          where e.material_id = mlin.mid and e.campus_id = mlin.cid and e.estado = 'operativo'
                            and e.fuera_de_sede is not null), 0)
           else 0 end as fuera,
      coalesce((select sum(sm2.cantidad_prevista) from sesion_materiales sm2
                join sesiones_practica s2 on s2.id = sm2.sesion_id
                where sm2.material_id = mlin.mid and s2.campus_id = mlin.cid and s2.estado = 'aprobada'
                  and s2.id <> all (p_ids) and s2.inicio < mlin.fn and s2.fin > mlin.ini), 0)
      + coalesce((select sum(sm3.cantidad_prevista) from ses s3
                  join sesion_materiales sm3 on sm3.sesion_id = s3.id
                  where sm3.material_id = mlin.mid and s3.campus_id = mlin.cid and s3.id <> mlin.sid
                    and (s3.inicio, s3.id) < (mlin.ini, mlin.sid)
                    and s3.inicio < mlin.fn and s3.fin > mlin.ini), 0) as ocupado
    from mlin
  )
  select m.sid, case when m.ti = 'equipo' then 'equipo' else 'vidrieria' end, m.mid, m.nom, 'unidad'::text,
         m.pedido::numeric, (m.total - m.ocupado)::numeric,
         greatest(m.pedido - (m.total - m.ocupado), 0)::numeric,
         case when m.cid is null then 'sin_campus'
              when m.pedido is null then 'sin_cantidad'
              when m.pedido > m.total - m.ocupado then 'falta'
              when m.fuera > 0 and m.pedido > (m.total - m.fuera) - m.ocupado then 'ok_traslado'
              else 'ok' end,
         case when m.cid is null then 'La sesión no tiene campus'
              when m.pedido is null then 'No se indicó cantidad'
              when m.pedido > m.total - m.ocupado then
                case when m.total = 0 then 'Sin registro en el inventario de esta sede'
                     else 'Libres en ese horario: ' || greatest(m.total - m.ocupado, 0) || ' · pedido: ' || m.pedido end
              when m.fuera > 0 and m.pedido > (m.total - m.fuera) - m.ocupado
                then 'Hay ' || m.fuera || ' en otra sede: hacer el traslado antes de la práctica'
              else null end
  from mb m);
end $$;

-- ---------------------------------------------------------------------
-- 5. APROBAR / RECHAZAR CON VERIFICACIÓN DE EXISTENCIAS
-- Nuevo parámetro p_solo_si_disponible: si es true, no aprueba las sesiones
-- que no tengan todo. Se evalúan en orden de fecha, de modo que lo que se
-- aprueba primero queda comprometido para las siguientes.
-- ---------------------------------------------------------------------
drop function if exists decidir_sesiones(uuid[], text, text, uuid);

create or replace function decidir_sesiones(
  p_ids uuid[], p_decision text, p_motivo text default null, p_laboratorio uuid default null,
  p_solo_si_disponible boolean default false
) returns jsonb
language plpgsql set search_path = public as $$
declare
  v_id uuid; s sesiones_practica; v_msg text; v_orden uuid[];
  v_falt jsonb; v_det text;
  v_res jsonb := '[]'::jsonb; v_ok int := 0;
begin
  if not es_personal() then
    raise exception 'Solo el personal técnico y los administradores pueden aprobar o rechazar';
  end if;
  if p_decision not in ('aprobada', 'rechazada') then
    raise exception 'Decisión no válida: use aprobada o rechazada';
  end if;
  if p_decision = 'rechazada' and nullif(trim(coalesce(p_motivo, '')), '') is null then
    raise exception 'Indique el motivo del rechazo';
  end if;
  if p_laboratorio is not null
     and not exists (select 1 from laboratorios where id = p_laboratorio and activo) then
    raise exception 'El laboratorio indicado no existe o está inactivo';
  end if;

  v_orden := coalesce((select array_agg(x.id order by x.inicio, x.id)
                         from sesiones_practica x where x.id = any(p_ids)), '{}'::uuid[])
          || array(select u from unnest(coalesce(p_ids, '{}'::uuid[])) u
                    where not exists (select 1 from sesiones_practica y where y.id = u));

  foreach v_id in array v_orden loop
    v_msg := null; v_falt := '[]'::jsonb;
    select * into s from sesiones_practica where id = v_id for update;
    if not found then
      v_msg := 'La sesión no existe';
    elsif s.estado <> 'solicitada' then
      v_msg := 'Ya estaba en estado ' || s.estado;
    elsif p_decision = 'aprobada' and s.laboratorio_id is null and p_laboratorio is null then
      v_msg := 'Asigne un laboratorio para aprobar';
    end if;

    if v_msg is null and p_decision = 'aprobada' then
      select coalesce(jsonb_agg(jsonb_build_object('tipo', d.tipo, 'item', d.item, 'estado', d.estado, 'mensaje', d.mensaje)), '[]'::jsonb),
             string_agg(d.item || coalesce(' (' || d.mensaje || ')', ''), '; ')
        into v_falt, v_det
        from disponibilidad_sesiones(array[v_id]) d
       where d.estado in ('falta', 'ok_traslado');
      if p_solo_si_disponible and exists (select 1 from jsonb_array_elements(v_falt) e where e->>'estado' = 'falta') then
        v_msg := 'Faltan existencias: ' || (select string_agg(e->>'item', ', ')
                                              from jsonb_array_elements(v_falt) e where e->>'estado' = 'falta');
      end if;
    end if;

    if v_msg is null then
      update sesiones_practica set
        estado         = p_decision::estado_sesion,
        laboratorio_id = case when p_decision = 'aprobada'
                              then coalesce(laboratorio_id, p_laboratorio) else laboratorio_id end,
        motivo_rechazo = case when p_decision = 'rechazada' then trim(p_motivo) else null end,
        aprobado_por   = case when p_decision = 'aprobada' then auth.uid() else aprobado_por end,
        aprobado_en    = case when p_decision = 'aprobada' then now() else aprobado_en end
      where id = v_id;
      v_ok := v_ok + 1;
    end if;
    v_res := v_res || jsonb_build_object('id', v_id, 'ok', v_msg is null, 'mensaje', v_msg, 'avisos', v_falt);
  end loop;

  return jsonb_build_object('aplicadas', v_ok, 'resultados', v_res);
end $$;

-- ---------------------------------------------------------------------
-- 6. REPORTE DE CONSUMO (lo hace el técnico)
-- p_reactivos: [{"reactivo_id": "...", "cantidad": 12.5, "unidad": "g"}]
--   cantidad = TOTAL consumido en la sesión; si se corrige, solo se aplica
--   la diferencia. Descuenta de los envases del campus por vencimiento más
--   próximo (FEFO). Si no alcanza, no se guarda nada.
-- p_materiales: [{"material_id": "...", "cantidad": 2}]  → piezas de vidriería rotas.
-- ---------------------------------------------------------------------
create or replace function registrar_consumo(
  p_sesion uuid, p_reactivos jsonb default '[]'::jsonb, p_materiales jsonb default '[]'::jsonb,
  p_finalizar boolean default false
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  s sesiones_practica; it jsonb; cr catalogo_reactivos; sr sesion_reactivos; sm sesion_materiales;
  cm catalogo_materiales; ex existencias_material; env record; mov record;
  v_u_in text; v_u_lin text; v_nuevo numeric; v_prev numeric; v_delta numeric; v_rest numeric; v_take numeric;
  v_n numeric; v_prev_i int; v_new_i int; v_d int; v_quitar int; v_n_re int := 0; v_n_ma int := 0;
begin
  if not es_personal() then
    raise exception 'Solo el personal técnico y los administradores registran consumos';
  end if;
  select * into s from sesiones_practica where id = p_sesion for update;
  if not found then raise exception 'La sesión no existe'; end if;
  if s.estado not in ('aprobada', 'finalizada') then
    raise exception 'Solo se registra consumo de sesiones aprobadas o finalizadas (estado: %)', s.estado;
  end if;
  if s.campus_id is null then raise exception 'La sesión no tiene campus asignado'; end if;

  for it in select * from jsonb_array_elements(coalesce(p_reactivos, '[]'::jsonb)) loop
    select * into cr from catalogo_reactivos where id = (it->>'reactivo_id')::uuid;
    if not found then raise exception 'Reactivo no encontrado: %', it->>'reactivo_id'; end if;
    select * into sr from sesion_reactivos where sesion_id = p_sesion and reactivo_id = cr.id for update;
    v_u_in  := coalesce(nullif(it->>'unidad', ''), sr.unidad, cr.unidad::text);
    v_nuevo := convertir_cantidad((it->>'cantidad')::numeric, v_u_in, cr.unidad::text);
    if v_nuevo is null then
      raise exception 'Unidad «%» no comparable con %, de %', v_u_in, cr.unidad, cr.nombre;
    end if;
    if v_nuevo < 0 then raise exception 'La cantidad de % no puede ser negativa', cr.nombre; end if;
    v_u_lin := coalesce(sr.unidad, cr.unidad::text);
    v_prev  := coalesce(convertir_cantidad(sr.cantidad_consumida, v_u_lin, cr.unidad::text), 0);
    v_delta := v_nuevo - v_prev;

    if v_delta > 0 then
      v_rest := v_delta;
      for env in
        select e.id, e.cantidad_actual from envases e
         where e.reactivo_id = cr.id and e.campus_id = s.campus_id
           and e.estado in ('disponible', 'en_uso') and e.cantidad_actual > 0
           and (e.fecha_caducidad is null or e.fecha_caducidad >= current_date)
         order by e.fecha_caducidad nulls last, e.fecha_recepcion, e.codigo
         for update
      loop
        v_take := least(env.cantidad_actual, v_rest);
        insert into movimientos_stock (envase_id, tipo, cantidad, sesion_id, motivo)
        values (env.id, 'consumo', v_take, p_sesion, 'Consumo reportado por el técnico');
        v_rest := v_rest - v_take;
        exit when v_rest <= 0;
      end loop;
      if v_rest > 0 then
        raise exception 'Existencia vigente insuficiente de % en este campus: faltan % %', cr.nombre, round(v_rest, 3), cr.unidad;
      end if;
    elsif v_delta < 0 then
      v_rest := -v_delta;
      for mov in
        select m.envase_id,
               sum(case when m.tipo = 'consumo' then m.cantidad else -m.cantidad end) as neto
          from movimientos_stock m join envases e on e.id = m.envase_id
         where m.sesion_id = p_sesion and e.reactivo_id = cr.id and m.tipo in ('consumo', 'ajuste_positivo')
         group by m.envase_id
        having sum(case when m.tipo = 'consumo' then m.cantidad else -m.cantidad end) > 0
         order by max(m.creado_en) desc
      loop
        v_take := least(mov.neto, v_rest);
        insert into movimientos_stock (envase_id, tipo, cantidad, sesion_id, motivo)
        values (mov.envase_id, 'ajuste_positivo', v_take, p_sesion, 'Corrección del consumo reportado');
        v_rest := v_rest - v_take;
        exit when v_rest <= 0;
      end loop;
    end if;

    if sr.id is null then
      insert into sesion_reactivos (sesion_id, reactivo_id, cantidad_prevista, cantidad_consumida, unidad, notas)
      values (p_sesion, cr.id, null, v_nuevo, cr.unidad::text, 'Agregado al reportar consumo');
    else
      update sesion_reactivos
         set cantidad_consumida = convertir_cantidad(v_nuevo, cr.unidad::text, v_u_lin), unidad = v_u_lin
       where id = sr.id;
    end if;
    v_n_re := v_n_re + 1;
  end loop;

  for it in select * from jsonb_array_elements(coalesce(p_materiales, '[]'::jsonb)) loop
    select * into cm from catalogo_materiales where id = (it->>'material_id')::uuid;
    if not found then raise exception 'Material no encontrado: %', it->>'material_id'; end if;
    if cm.tipo_item = 'equipo' then
      raise exception '«%» es un equipo: no se descuenta; use mantenimiento o baja', cm.nombre;
    end if;
    select * into ex from existencias_material where material_id = cm.id and campus_id = s.campus_id for update;
    if not found then raise exception '«%» no está en el inventario de vidriería de este campus', cm.nombre; end if;
    v_new_i := (it->>'cantidad')::int;
    if v_new_i < 0 then raise exception 'La cantidad de % no puede ser negativa', cm.nombre; end if;
    select * into sm from sesion_materiales where sesion_id = p_sesion and material_id = cm.id for update;
    v_prev_i := coalesce(sm.cantidad_consumida, 0)::int;
    v_d := v_new_i - v_prev_i;
    if v_d > 0 then
      if ex.cantidad_buena + ex.cantidad_regular < v_d then
        raise exception 'No hay suficientes piezas útiles de % para registrar % rotas', cm.nombre, v_d;
      end if;
      v_quitar := least(ex.cantidad_buena, v_d);
      update existencias_material set cantidad_buena = cantidad_buena - v_quitar,
             cantidad_regular = cantidad_regular - (v_d - v_quitar), cantidad_danada = cantidad_danada + v_d
       where id = ex.id;
    elsif v_d < 0 then
      if ex.cantidad_danada < -v_d then
        raise exception 'No se puede corregir: solo hay % piezas dañadas de %', ex.cantidad_danada, cm.nombre;
      end if;
      update existencias_material set cantidad_danada = cantidad_danada + v_d, cantidad_buena = cantidad_buena - v_d
       where id = ex.id;
    end if;
    if v_d <> 0 then
      insert into movimientos_existencia_material (existencia_id, tipo, cantidad, sesion_id, motivo)
      values (ex.id, case when v_d > 0 then 'rotura' else 'correccion' end, v_d, p_sesion, 'Reportado por el técnico');
    end if;
    if sm.id is null then
      insert into sesion_materiales (sesion_id, material_id, cantidad_prevista, cantidad_consumida, notas)
      values (p_sesion, cm.id, null, v_new_i, 'Agregado al reportar roturas');
    else
      update sesion_materiales set cantidad_consumida = v_new_i where id = sm.id;
    end if;
    v_n_ma := v_n_ma + 1;
  end loop;

  if p_finalizar and s.estado = 'aprobada' then
    update sesiones_practica set estado = 'finalizada' where id = p_sesion;
  end if;

  return jsonb_build_object('sesion_id', p_sesion, 'reactivos_registrados', v_n_re,
                            'materiales_registrados', v_n_ma, 'finalizada', p_finalizar);
end $$;

-- ---------------------------------------------------------------------
-- 7. PERMISOS
-- ---------------------------------------------------------------------
revoke execute on function convertir_cantidad(numeric, text, text), disponibilidad_sesiones(uuid[]),
  decidir_sesiones(uuid[], text, text, uuid, boolean), registrar_consumo(uuid, jsonb, jsonb, boolean)
  from public, anon;
grant execute on function convertir_cantidad(numeric, text, text), disponibilidad_sesiones(uuid[]),
  decidir_sesiones(uuid[], text, text, uuid, boolean), registrar_consumo(uuid, jsonb, jsonb, boolean)
  to authenticated;
grant select on v_existencias_reactivo, v_comprometido_reactivo to authenticated;

notify pgrst, 'reload schema';
