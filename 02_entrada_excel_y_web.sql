-- =====================================================================
-- 02 · ENTRADA DE SOLICITUDES: EXCEL Y FORMULARIO WEB (mismo núcleo)
-- Ejecutar en Supabase > SQL Editor DESPUÉS de schema_labs.sql
-- (y, si ya la hizo, después de la carga inicial).
--
-- Idea: tanto el Excel subido como el formulario web terminan llamando
-- a UNA sola función: importar_formulario(json). Esa función:
--   1. crea la sesión de práctica,
--   2. vincula cada reactivo/material con el catálogo por su nombre,
--   3. deja en "pendientes" lo que no reconoce, para que el técnico
--      lo vincule UNA vez; el sistema lo recuerda para siempre.
-- =====================================================================

create schema if not exists extensions;
create extension if not exists unaccent with schema extensions;

-- Normaliza un texto: minúsculas, sin tildes, sin espacios dobles ni puntuación final
create or replace function normalizar_texto(t text) returns text
language sql stable set search_path = public, extensions as $$
  select trim(both ' .,;:' from regexp_replace(lower(unaccent(coalesce(t, ''))), '\s+', ' ', 'g'))
$$;

-- ---------------------------------------------------------------------
-- 1. EQUIVALENCIAS DE NOMBRES (alias) Y LÍNEAS PENDIENTES
-- ---------------------------------------------------------------------
create table alias_reactivos (
  alias       text primary key,                 -- texto normalizado, p. ej. 'hidroxido de sodio'
  reactivo_id uuid not null references catalogo_reactivos(id) on delete cascade,
  creado_en   timestamptz not null default now()
);

create table alias_materiales (
  alias       text primary key,
  material_id uuid not null references catalogo_materiales(id) on delete cascade,
  creado_en   timestamptz not null default now()
);

create table lineas_pendientes (          -- lo que el sistema no pudo vincular solo
  id             uuid primary key default gen_random_uuid(),
  sesion_id      uuid not null references sesiones_practica(id) on delete cascade,
  tipo           text not null check (tipo in ('reactivo','material')),
  texto_original text not null,
  cantidad       numeric(12,3) check (cantidad >= 0),
  unidad         text,
  concentracion  text,
  notas          text,
  resuelta       boolean not null default false,
  creado_en      timestamptz not null default now()
);
create index on lineas_pendientes (sesion_id) where not resuelta;

-- Todo reactivo/material nuevo del catálogo se vuelve reconocible por su nombre
create or replace function alias_desde_catalogo() returns trigger
language plpgsql security definer set search_path = public, extensions as $$
begin
  if tg_table_name = 'catalogo_reactivos' then
    insert into alias_reactivos (alias, reactivo_id) values (normalizar_texto(new.nombre), new.id)
    on conflict (alias) do nothing;
  else
    insert into alias_materiales (alias, material_id) values (normalizar_texto(new.nombre), new.id)
    on conflict (alias) do nothing;
  end if;
  return new;
end $$;

create trigger trg_alias_reactivo after insert or update of nombre on catalogo_reactivos
  for each row execute function alias_desde_catalogo();
create trigger trg_alias_material after insert or update of nombre on catalogo_materiales
  for each row execute function alias_desde_catalogo();

-- Alias de lo que ya existe (nombres del catálogo + textos de formularios ya cargados)
insert into alias_reactivos (alias, reactivo_id)
  select normalizar_texto(nombre), id from catalogo_reactivos on conflict (alias) do nothing;
insert into alias_materiales (alias, material_id)
  select normalizar_texto(nombre), id from catalogo_materiales on conflict (alias) do nothing;

-- Solo de líneas que corresponden a UNA sustancia (se omiten celdas con varias o con alternativas)
insert into alias_reactivos (alias, reactivo_id)
  select distinct normalizar_texto(t), sr.reactivo_id
  from sesion_reactivos sr, lateral unnest(string_to_array(sr.texto_original, ' | ')) as t
  where sr.texto_original is not null
    and coalesce(sr.notas, '') not like '%Cantidad conjunta%'
    and coalesce(sr.notas, '') not like '%alternativas%'
  on conflict (alias) do nothing;

insert into alias_materiales (alias, material_id)
  select distinct normalizar_texto(t), sm.material_id
  from sesion_materiales sm, lateral unnest(string_to_array(sm.texto_original, ' | ')) as t
  where sm.texto_original is not null
  on conflict (alias) do nothing;

-- ---------------------------------------------------------------------
-- 2. FUNCIÓN ÚNICA DE ENTRADA
-- ---------------------------------------------------------------------
-- Formato del JSON (lo mismo para Excel y para el formulario web):
-- {
--   "origen": "excel_import" | "app",         "archivo": "Fundamentos.xlsx",
--   "practica_id": "<uuid>" (opcional)  |  "practica_nombre": "Equilibrio Químico",
--   "laboratorio_id": "<uuid>",               "estado": "borrador" | "solicitada",
--   "fecha": "2026-03-05", "inicio": "09:00", "fin": "12:00",
--   "num_estudiantes": 13, "num_grupos_trabajo": 4, "observaciones": "...",
--   "reactivos":  [ {"texto": "Ácido clorhídrico 4 M", "cantidad": 80, "unidad": "mL", "concentracion": null} ],
--   "materiales": [ {"texto": "Pipeta graduada", "cantidad": 16} ]
-- }
create or replace function importar_formulario(p jsonb) returns jsonb
language plpgsql set search_path = public, extensions as $$
declare
  v_user   uuid := auth.uid();
  v_doc    uuid;
  v_lab    uuid := nullif(p->>'laboratorio_id', '')::uuid;
  v_prac   uuid := nullif(p->>'practica_id', '')::uuid;
  v_nombre text := nullif(trim(p->>'practica_nombre'), '');
  v_estado estado_sesion := coalesce(nullif(p->>'estado', ''), 'solicitada')::estado_sesion;
  v_ini    timestamptz;
  v_fin    timestamptz;
  v_ses    uuid := gen_random_uuid();
  v_origen text := coalesce(nullif(p->>'origen', ''), 'app');
  it jsonb; v_id uuid; v_n text; v_n2 text; v_conc text; v_cant numeric; v_uni text;
  r_ok int := 0; r_pend int := 0; m_ok int := 0; m_pend int := 0;
begin
  if rol_actual() is null or rol_actual() = 'estudiante' then
    raise exception 'Solo docentes y personal técnico pueden registrar solicitudes';
  end if;
  if v_lab is null then raise exception 'Falta el laboratorio'; end if;
  if v_estado not in ('borrador', 'solicitada') then
    raise exception 'Una solicitud nueva solo puede entrar como borrador o solicitada';
  end if;
  if v_origen not in ('app', 'excel_import') then v_origen := 'app'; end if;

  -- Un docente siempre registra a su nombre; el personal puede registrar a nombre de otro docente
  v_doc := case when es_personal() and nullif(p->>'docente_id', '') is not null
                then (p->>'docente_id')::uuid else v_user end;

  -- Horario en hora de Colombia (UTC-5)
  v_ini := ((p->>'fecha') || ' ' || (p->>'inicio'))::timestamp at time zone 'America/Bogota';
  v_fin := ((p->>'fecha') || ' ' || (p->>'fin'))::timestamp at time zone 'America/Bogota';

  -- Práctica: por id, por nombre o se crea
  if v_prac is null and v_nombre is not null then
    select id into v_prac from practicas where normalizar_texto(nombre) = normalizar_texto(v_nombre) limit 1;
    if v_prac is null then
      insert into practicas (nombre, laboratorio_id, docente_responsable_id)
      values (v_nombre, v_lab, v_doc) returning id into v_prac;
    end if;
  end if;

  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes,
                                 num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values (v_ses, v_prac, v_doc, v_lab, nullif(p->>'num_estudiantes', '')::int,
          nullif(p->>'num_grupos_trabajo', '')::int, v_ini, v_fin, v_estado,
          nullif(p->>'observaciones', ''), v_origen);

  -- Reactivos
  for it in select * from jsonb_array_elements(coalesce(p->'reactivos', '[]'::jsonb)) loop
    v_n := normalizar_texto(it->>'texto');
    continue when v_n = '';
    v_cant := nullif(it->>'cantidad', '')::numeric;
    v_uni  := case when lower(nullif(it->>'unidad', '')) = 'ml' then 'mL' else nullif(it->>'unidad', '') end;
    v_conc := coalesce(nullif(it->>'concentracion', ''),
                (select replace(m[1], '.', ',') || ' M' from regexp_match(v_n, '(\d+(?:[.,]\d+)?)\s*m\b') as m));
    v_n2   := trim(regexp_replace(v_n, '\(?\s*\d+(?:[.,]\d+)?\s*m\)?\s*$', ''));
    select reactivo_id into v_id from alias_reactivos
      where alias in (v_n, v_n2) order by (alias = v_n) desc limit 1;
    if v_id is not null then
      insert into sesion_reactivos (sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, texto_original)
      values (v_ses, v_id, v_cant, v_uni, v_conc, it->>'texto')
      on conflict (sesion_id, reactivo_id) do update set
        cantidad_prevista = case when sesion_reactivos.cantidad_prevista is null then excluded.cantidad_prevista
                                 when excluded.cantidad_prevista is null then sesion_reactivos.cantidad_prevista
                                 else sesion_reactivos.cantidad_prevista + excluded.cantidad_prevista end,
        texto_original = sesion_reactivos.texto_original || ' | ' || excluded.texto_original;
      r_ok := r_ok + 1;
    else
      insert into lineas_pendientes (sesion_id, tipo, texto_original, cantidad, unidad, concentracion)
      values (v_ses, 'reactivo', it->>'texto', v_cant, v_uni, v_conc);
      r_pend := r_pend + 1;
    end if;
    v_id := null;
  end loop;

  -- Materiales, vidriería y equipos
  for it in select * from jsonb_array_elements(coalesce(p->'materiales', '[]'::jsonb)) loop
    v_n := normalizar_texto(it->>'texto');
    continue when v_n = '';
    v_cant := nullif(it->>'cantidad', '')::numeric;
    select material_id into v_id from alias_materiales where alias = v_n;
    if v_id is not null then
      insert into sesion_materiales (sesion_id, material_id, cantidad_prevista, texto_original)
      values (v_ses, v_id, v_cant, it->>'texto')
      on conflict (sesion_id, material_id) do update set
        cantidad_prevista = case when sesion_materiales.cantidad_prevista is null then excluded.cantidad_prevista
                                 when excluded.cantidad_prevista is null then sesion_materiales.cantidad_prevista
                                 else sesion_materiales.cantidad_prevista + excluded.cantidad_prevista end,
        texto_original = sesion_materiales.texto_original || ' | ' || excluded.texto_original;
      m_ok := m_ok + 1;
    else
      insert into lineas_pendientes (sesion_id, tipo, texto_original, cantidad)
      values (v_ses, 'material', it->>'texto', v_cant);
      m_pend := m_pend + 1;
    end if;
    v_id := null;
  end loop;

  -- Registro de lo recibido (sirve de respaldo y de historial del Excel/formulario)
  insert into importaciones_formularios (nombre_archivo, subido_por, estado, payload, errores, sesion_id, procesado_en)
  values (coalesce(nullif(p->>'archivo', ''), 'Formulario web'), v_user, 'procesado', p,
          case when r_pend + m_pend > 0
               then jsonb_build_object('lineas_sin_vincular', r_pend + m_pend) end,
          v_ses, now());

  return jsonb_build_object('sesion_id', v_ses,
    'reactivos_vinculados', r_ok, 'reactivos_pendientes', r_pend,
    'materiales_vinculados', m_ok, 'materiales_pendientes', m_pend);
end $$;

-- ---------------------------------------------------------------------
-- 3. EL TÉCNICO VINCULA UNA VEZ; EL SISTEMA APRENDE
-- ---------------------------------------------------------------------
-- Vincula una línea pendiente con un reactivo/material del catálogo, guarda la
-- equivalencia y resuelve de paso todas las líneas pendientes con el mismo texto.
create or replace function resolver_linea_pendiente(p_linea uuid, p_item uuid) returns int
language plpgsql security definer set search_path = public, extensions as $$
declare l lineas_pendientes; n text; r lineas_pendientes; c int := 0;
begin
  if not es_personal() then raise exception 'Solo el personal técnico puede vincular líneas'; end if;
  select * into l from lineas_pendientes where id = p_linea and not resuelta;
  if not found then raise exception 'La línea no existe o ya fue resuelta'; end if;
  n := normalizar_texto(l.texto_original);

  if l.tipo = 'reactivo' then
    if not exists (select 1 from catalogo_reactivos where id = p_item) then raise exception 'Reactivo no encontrado'; end if;
    insert into alias_reactivos (alias, reactivo_id) values (n, p_item)
      on conflict (alias) do update set reactivo_id = excluded.reactivo_id;
    for r in select * from lineas_pendientes where tipo = 'reactivo' and not resuelta
             and normalizar_texto(texto_original) = n loop
      insert into sesion_reactivos (sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original)
      values (r.sesion_id, p_item, r.cantidad, r.unidad, r.concentracion, r.notas, r.texto_original)
      on conflict (sesion_id, reactivo_id) do update set
        cantidad_prevista = coalesce(sesion_reactivos.cantidad_prevista, 0) + coalesce(excluded.cantidad_prevista, 0),
        texto_original = sesion_reactivos.texto_original || ' | ' || excluded.texto_original;
      update lineas_pendientes set resuelta = true where id = r.id;
      c := c + 1;
    end loop;
  else
    if not exists (select 1 from catalogo_materiales where id = p_item) then raise exception 'Material no encontrado'; end if;
    insert into alias_materiales (alias, material_id) values (n, p_item)
      on conflict (alias) do update set material_id = excluded.material_id;
    for r in select * from lineas_pendientes where tipo = 'material' and not resuelta
             and normalizar_texto(texto_original) = n loop
      insert into sesion_materiales (sesion_id, material_id, cantidad_prevista, notas, texto_original)
      values (r.sesion_id, p_item, r.cantidad, r.notas, r.texto_original)
      on conflict (sesion_id, material_id) do update set
        cantidad_prevista = coalesce(sesion_materiales.cantidad_prevista, 0) + coalesce(excluded.cantidad_prevista, 0),
        texto_original = sesion_materiales.texto_original || ' | ' || excluded.texto_original;
      update lineas_pendientes set resuelta = true where id = r.id;
      c := c + 1;
    end loop;
  end if;
  return c;
end $$;

-- Bandeja del técnico: qué falta por vincular
create view v_pendientes_vinculacion with (security_invoker = true) as
select lp.id, lp.tipo, lp.texto_original, lp.cantidad, lp.unidad, lp.concentracion,
       p.nombre as practica, (s.inicio at time zone 'America/Bogota')::date as fecha, lp.sesion_id
from lineas_pendientes lp
join sesiones_practica s on s.id = lp.sesion_id
left join practicas p on p.id = s.practica_id
where not lp.resuelta;

-- ---------------------------------------------------------------------
-- 4. SEGURIDAD (RLS) Y PERMISOS
-- ---------------------------------------------------------------------
alter table alias_reactivos enable row level security;
alter table alias_materiales enable row level security;
alter table lineas_pendientes enable row level security;

create policy alias_r_lectura on alias_reactivos for select to authenticated using (true);
create policy alias_r_personal on alias_reactivos for all to authenticated using (es_personal()) with check (es_personal());
create policy alias_m_lectura on alias_materiales for select to authenticated using (true);
create policy alias_m_personal on alias_materiales for all to authenticated using (es_personal()) with check (es_personal());

create policy pend_lectura on lineas_pendientes for select to authenticated
  using (exists (select 1 from sesiones_practica s where s.id = sesion_id));
create policy pend_docente_ins on lineas_pendientes for insert to authenticated
  with check (exists (select 1 from sesiones_practica s where s.id = sesion_id
    and s.docente_id = auth.uid() and s.estado in ('borrador', 'solicitada')));
create policy pend_personal on lineas_pendientes for all to authenticated
  using (es_personal()) with check (es_personal());

revoke all on alias_reactivos, alias_materiales, lineas_pendientes from anon;
grant select, insert, update, delete on alias_reactivos, alias_materiales, lineas_pendientes to authenticated;
grant select on v_pendientes_vinculacion to authenticated;

revoke execute on function normalizar_texto(text), importar_formulario(jsonb),
  resolver_linea_pendiente(uuid, uuid), alias_desde_catalogo() from public, anon;
grant execute on function normalizar_texto(text), importar_formulario(jsonb),
  resolver_linea_pendiente(uuid, uuid) to authenticated;
