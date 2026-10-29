-- =====================================================================
-- 04 · CAMPUS, PROGRAMA ACADÉMICO, CURSO, AGUA DESTILADA Y DECISIONES EN BLOQUE
-- Ejecutar en Supabase > SQL Editor DESPUÉS de 01, 02 y 03.
-- Se puede repetir sin dañar datos.
--
-- Qué hace:
--   1. Crea la tabla de campus (Turbo, Apartadó, Carepa).
--   2. Agrega a la sesión: campus, programa académico, curso, agua destilada
--      estimada (litros) y motivo de rechazo.
--   3. El laboratorio deja de pedirse al docente: lo asigna el líder de
--      laboratorios o el técnico al aprobar (laboratorio_id admite vacío).
--   4. Reemplaza importar_formulario() para el formulario nuevo (web y Excel),
--      con jornadas adicionales.
--   5. Crea decidir_sesiones() y deshacer_decision() para aprobar o rechazar
--      varias sesiones a la vez.
--   6. Ajusta las alertas del tablero para sesiones sin laboratorio.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. CAMPUS
-- ---------------------------------------------------------------------
create table if not exists campus (
  id     uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  orden  int  not null default 0
);

insert into campus (nombre, orden) values
  ('Turbo', 1), ('Apartadó', 2), ('Carepa', 3)
on conflict (nombre) do nothing;

alter table campus enable row level security;
drop policy if exists campus_lectura on campus;
drop policy if exists campus_admin on campus;
create policy campus_lectura on campus for select to authenticated using (true);
create policy campus_admin on campus for all to authenticated
  using (es_admin()) with check (es_admin());
revoke all on campus from anon;
grant select, insert, update, delete on campus to authenticated;

-- ---------------------------------------------------------------------
-- 2. CAMPOS NUEVOS EN LA SESIÓN
-- ---------------------------------------------------------------------
alter table laboratorios add column if not exists campus_id uuid references campus(id);

alter table sesiones_practica
  add column if not exists campus_id          uuid references campus(id),
  add column if not exists programa_academico text,
  add column if not exists curso              text,
  add column if not exists agua_destilada_l   numeric(8,2) check (agua_destilada_l >= 0),
  add column if not exists motivo_rechazo     text;

-- El laboratorio lo asigna el personal al aprobar
alter table sesiones_practica alter column laboratorio_id drop not null;

create index if not exists sesiones_campus_idx on sesiones_practica (campus_id);

-- ---------------------------------------------------------------------
-- 3. ENTRADA ÚNICA DE SOLICITUDES (web y Excel): importar_formulario v2
-- ---------------------------------------------------------------------
-- JSON esperado:
-- {
--   "origen": "app" | "excel_import",  "archivo": "Practica 1.xlsx",
--   "estado": "borrador" | "solicitada",
--   "practica_nombre": "Equilibrio Químico",
--   "campus": "Turbo" | "Apartadó" | "Carepa"   (o "campus_id": "<uuid>"),
--   "programa_academico": "...", "curso": "...",
--   "agua_destilada_l": 4.5,
--   "fecha": "2026-03-05", "inicio": "09:00", "fin": "12:00",
--   "num_estudiantes": 13, "num_grupos_trabajo": 4, "observaciones": "...",
--   "otras_jornadas": [ {"fecha": "...", "inicio": "13:00", "fin": "16:00",
--                        "num_estudiantes": 12, "num_grupos_trabajo": 4} ],
--   "reactivos":  [ {"texto": "HCl", "cantidad": 80, "cantidad_por_mesa": 20,
--                    "unidad": "mL", "concentracion": "4 M"} ],
--   "materiales": [ {"texto": "Pipeta graduada", "cantidad": 16, "cantidad_por_mesa": 4} ]
-- }
-- Cada jornada crea una sesión con las mismas listas. El laboratorio NO se
-- recibe del docente; solo el personal puede enviarlo.
create or replace function importar_formulario(p jsonb) returns jsonb
language plpgsql set search_path = public, extensions as $$
declare
  v_user   uuid := auth.uid();
  v_doc    uuid;
  v_lab    uuid;
  v_prac   uuid := nullif(p->>'practica_id', '')::uuid;
  v_nombre text := nullif(trim(p->>'practica_nombre'), '');
  v_estado estado_sesion := coalesce(nullif(p->>'estado', ''), 'solicitada')::estado_sesion;
  v_origen text := coalesce(nullif(p->>'origen', ''), 'app');
  v_campus uuid := nullif(p->>'campus_id', '')::uuid;
  v_prog   text := nullif(trim(p->>'programa_academico'), '');
  v_curso  text := nullif(trim(p->>'curso'), '');
  v_agua   numeric := nullif(p->>'agua_destilada_l', '')::numeric;
  v_jor    jsonb;
  j        jsonb;
  v_ini    timestamptz;
  v_fin    timestamptz;
  v_ses    uuid;
  v_ids    uuid[] := '{}';
  v_mesas  int;
  it jsonb; v_id uuid; v_n text; v_n2 text; v_conc text; v_cant numeric; v_cpm numeric; v_uni text;
  r_ok int := 0; r_pend int := 0; m_ok int := 0; m_pend int := 0;
begin
  if rol_actual() is null or rol_actual() = 'estudiante' then
    raise exception 'Solo docentes y personal técnico pueden registrar solicitudes';
  end if;
  if v_estado not in ('borrador', 'solicitada') then
    raise exception 'Una solicitud nueva solo puede entrar como borrador o solicitada';
  end if;
  if v_origen not in ('app', 'excel_import') then v_origen := 'app'; end if;

  -- Campus: por id o por nombre
  if v_campus is null and nullif(trim(p->>'campus'), '') is not null then
    select id into v_campus from campus
      where normalizar_texto(nombre) = normalizar_texto(p->>'campus');
    if v_campus is null then
      raise exception 'Campus no válido: %. Use Turbo, Apartadó o Carepa.', p->>'campus';
    end if;
  end if;

  -- Requisitos para enviar la solicitud (el borrador puede quedar incompleto)
  if v_estado = 'solicitada' then
    if v_nombre is null and v_prac is null then raise exception 'Falta el nombre de la práctica de laboratorio'; end if;
    if v_campus is null then raise exception 'Falta el campus'; end if;
    if v_prog   is null then raise exception 'Falta el programa académico'; end if;
    if v_curso  is null then raise exception 'Falta el nombre del curso'; end if;
    if v_agua   is null then raise exception 'Falta el agua destilada estimada por sesión'; end if;
  end if;
  if nullif(p->>'fecha', '') is null or nullif(p->>'inicio', '') is null or nullif(p->>'fin', '') is null then
    raise exception 'Faltan la fecha y el horario de la práctica';
  end if;

  -- Un docente siempre registra a su nombre; el personal puede registrar a nombre de otro docente
  v_doc := case when es_personal() and nullif(p->>'docente_id', '') is not null
                then (p->>'docente_id')::uuid else v_user end;
  -- El laboratorio solo lo asigna el personal
  v_lab := case when es_personal() then nullif(p->>'laboratorio_id', '')::uuid end;

  -- Práctica: por id, por nombre o se crea
  if v_prac is null and v_nombre is not null then
    select id into v_prac from practicas
      where normalizar_texto(nombre) = normalizar_texto(v_nombre) limit 1;
    if v_prac is null then
      insert into practicas (nombre, asignatura, programa, docente_responsable_id)
      values (v_nombre, v_curso, v_prog, v_doc) returning id into v_prac;
    end if;
  end if;

  -- Jornada principal + jornadas adicionales
  v_jor := jsonb_build_array(jsonb_build_object(
             'fecha', p->>'fecha', 'inicio', p->>'inicio', 'fin', p->>'fin',
             'num_estudiantes', p->>'num_estudiantes',
             'num_grupos_trabajo', p->>'num_grupos_trabajo'))
           || coalesce(p->'otras_jornadas', '[]'::jsonb);

  for j in select * from jsonb_array_elements(v_jor) loop
    continue when nullif(j->>'fecha', '') is null;     -- fila vacía del formulario
    if nullif(j->>'inicio', '') is null or nullif(j->>'fin', '') is null then
      raise exception 'Cada jornada necesita hora de inicio y de fin';
    end if;
    v_ini := ((j->>'fecha') || ' ' || (j->>'inicio'))::timestamp at time zone 'America/Bogota';
    v_fin := ((j->>'fecha') || ' ' || (j->>'fin'))::timestamp at time zone 'America/Bogota';
    v_mesas := coalesce(nullif(j->>'num_grupos_trabajo', '')::int, nullif(p->>'num_grupos_trabajo', '')::int);
    v_ses := gen_random_uuid();
    v_ids := v_ids || v_ses;

    insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, campus_id,
                                   programa_academico, curso, agua_destilada_l,
                                   num_estudiantes, num_grupos_trabajo, inicio, fin,
                                   estado, observaciones, origen)
    values (v_ses, v_prac, v_doc, v_lab, v_campus, v_prog, v_curso, v_agua,
            nullif(j->>'num_estudiantes', '')::int, v_mesas, v_ini, v_fin,
            v_estado, nullif(p->>'observaciones', ''), v_origen);

    -- Reactivos
    for it in select * from jsonb_array_elements(coalesce(p->'reactivos', '[]'::jsonb)) loop
      v_n := normalizar_texto(it->>'texto');
      continue when v_n = '';
      v_cant := nullif(it->>'cantidad', '')::numeric;
      v_cpm  := nullif(it->>'cantidad_por_mesa', '')::numeric;
      if v_cant is null and v_cpm is not null and coalesce(v_mesas, 0) > 0 then v_cant := v_cpm * v_mesas; end if;
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
      v_cpm  := nullif(it->>'cantidad_por_mesa', '')::numeric;
      if v_cant is null and v_cpm is not null and coalesce(v_mesas, 0) > 0 then v_cant := v_cpm * v_mesas; end if;
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
  end loop;

  if coalesce(array_length(v_ids, 1), 0) = 0 then
    raise exception 'No se recibió ninguna jornada con fecha';
  end if;

  insert into importaciones_formularios (nombre_archivo, subido_por, estado, payload, errores, sesion_id, procesado_en)
  values (coalesce(nullif(p->>'archivo', ''), 'Formulario web'), v_user, 'procesado', p,
          case when r_pend + m_pend > 0
               then jsonb_build_object('lineas_sin_vincular', r_pend + m_pend) end,
          v_ids[1], now());

  return jsonb_build_object('sesion_id', v_ids[1], 'sesion_ids', to_jsonb(v_ids),
    'sesiones_creadas', array_length(v_ids, 1),
    'reactivos_vinculados', r_ok, 'reactivos_pendientes', r_pend,
    'materiales_vinculados', m_ok, 'materiales_pendientes', m_pend);
end $$;

-- ---------------------------------------------------------------------
-- 4. APROBAR O RECHAZAR VARIAS SESIONES A LA VEZ
-- ---------------------------------------------------------------------
-- p_laboratorio: al aprobar, se asigna a las sesiones que aún no tienen
-- laboratorio (no cambia el de las que ya lo tienen).
-- Devuelve el resultado de cada sesión, para mostrar qué se aplicó y qué no.
create or replace function decidir_sesiones(
  p_ids uuid[], p_decision text, p_motivo text default null, p_laboratorio uuid default null
) returns jsonb
language plpgsql set search_path = public as $$
declare
  v_id uuid; s sesiones_practica; v_msg text;
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

  foreach v_id in array coalesce(p_ids, '{}'::uuid[]) loop
    v_msg := null;
    select * into s from sesiones_practica where id = v_id for update;
    if not found then
      v_msg := 'La sesión no existe';
    elsif s.estado <> 'solicitada' then
      v_msg := 'Ya estaba en estado ' || s.estado;
    elsif p_decision = 'aprobada' and s.laboratorio_id is null and p_laboratorio is null then
      v_msg := 'Asigne un laboratorio para aprobar';
    end if;

    if v_msg is null then
      update sesiones_practica set
        estado         = p_decision::estado_sesion,
        laboratorio_id = case when p_decision = 'aprobada'
                              then coalesce(laboratorio_id, p_laboratorio) else laboratorio_id end,
        motivo_rechazo = case when p_decision = 'rechazada' then trim(p_motivo) else null end
      where id = v_id;
      v_ok := v_ok + 1;
    end if;
    v_res := v_res || jsonb_build_object('id', v_id, 'ok', v_msg is null, 'mensaje', v_msg);
  end loop;

  return jsonb_build_object('aplicadas', v_ok, 'resultados', v_res);
end $$;

-- Deshacer una decisión reciente: vuelve a «solicitada»
create or replace function deshacer_decision(p_ids uuid[]) returns int
language plpgsql set search_path = public as $$
declare n int;
begin
  if not es_personal() then
    raise exception 'Solo el personal técnico y los administradores pueden deshacer decisiones';
  end if;
  update sesiones_practica set
    estado = 'solicitada', aprobado_por = null, aprobado_en = null, motivo_rechazo = null
  where id = any(p_ids) and estado in ('aprobada', 'rechazada');
  get diagnostics n = row_count;
  return n;
end $$;

revoke execute on function importar_formulario(jsonb), decidir_sesiones(uuid[], text, text, uuid),
  deshacer_decision(uuid[]) from public, anon;
grant execute on function importar_formulario(jsonb), decidir_sesiones(uuid[], text, text, uuid),
  deshacer_decision(uuid[]) to authenticated;

-- ---------------------------------------------------------------------
-- 5. ALERTAS DEL TABLERO: sesiones sin laboratorio y con campus
-- ---------------------------------------------------------------------
create or replace function obtener_alertas()
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_result jsonb := '{}'::jsonb;
  v_count int;
begin
  -- Solo personal técnico y admin reciben alertas completas
  if not es_personal() then
    return jsonb_build_object('permitido', false);
  end if;

  -- 3a. Reactivos bajo stock mínimo
  select jsonb_agg(jsonb_build_object(
    'reactivo_id', reactivo_id, 'nombre', nombre, 'cas', cas,
    'unidad', unidad, 'stock_total', stock_total, 'stock_minimo', stock_minimo
  ))
  into v_result
  from v_stock_reactivos where bajo_minimo;
  v_result := jsonb_build_object('stock_bajo_minimo', coalesce(v_result, '[]'::jsonb));

  -- 3b. Materiales bajo stock mínimo
  v_result := v_result || jsonb_build_object('materiales_bajo_minimo', (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', id, 'nombre', nombre, 'categoria', categoria,
      'stock_actual', stock_actual, 'stock_minimo', stock_minimo
    )), '[]'::jsonb) from v_materiales_bajo_minimo
  ));

  -- 3c. Envases próximos a vencer (60 días)
  v_result := v_result || jsonb_build_object('proximos_a_vencer', (
    select coalesce(jsonb_agg(jsonb_build_object(
      'envase_id', envase_id, 'codigo', codigo, 'reactivo', nombre,
      'lote', lote, 'cantidad_actual', cantidad_actual, 'unidad', unidad,
      'fecha_caducidad', fecha_caducidad, 'dias_restantes', dias_restantes,
      'ubicacion', ubicacion
    )), '[]'::jsonb) from v_reactivos_por_vencer
  ));

  -- 3d. Equipos con mantenimiento/calibración próximo (30 días)
  v_result := v_result || jsonb_build_object('equipos_mantenimiento', (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', id, 'codigo', codigo, 'nombre', nombre,
      'estado', estado, 'proxima_calibracion', proxima_calibracion,
      'proximo_mantenimiento', proximo_mantenimiento, 'fecha_limite', fecha_limite
    )), '[]'::jsonb) from v_equipos_mantenimiento
  ));

  -- 3e. Sesiones pendientes de aprobación
  v_result := v_result || jsonb_build_object('sesiones_pendientes', (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', s.id, 'practica', p.nombre, 'docente', pr.nombre,
      'laboratorio', l.nombre, 'campus', c.nombre, 'inicio', s.inicio, 'fin', s.fin,
      'num_estudiantes', s.num_estudiantes, 'estado', s.estado
    ) order by s.inicio), '[]'::jsonb)
    from sesiones_practica s
    left join practicas p on p.id = s.practica_id
    join perfiles pr on pr.id = s.docente_id
    left join laboratorios l on l.id = s.laboratorio_id
    left join campus c on c.id = s.campus_id
    where s.estado = 'solicitada'
  ));

  -- 3f. Líneas pendientes de vincular
  select count(*) into v_count from lineas_pendientes where not resuelta;
  v_result := v_result || jsonb_build_object('lineas_sin_vincular', v_count);

  -- 3g. Alertas de almacenamiento incompatible
  v_result := v_result || jsonb_build_object('alertas_almacenamiento', (
    select coalesce(jsonb_agg(jsonb_build_object(
      'codigo', codigo, 'reactivo', reactivo,
      'clase_reactivo', clase_reactivo, 'ubicacion', ubicacion,
      'clase_ubicacion', clase_ubicacion
    )), '[]'::jsonb) from v_alertas_almacenamiento
  ));

  return v_result;
end $$;

-- ---------------------------------------------------------------------
-- 4. FUNCIÓN DE RESUMEN PARA DASHBOARD DOCENTE
-- ---------------------------------------------------------------------
create or replace function resumen_docente()
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  return jsonb_build_object(
    'sesiones_activas', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', s.id, 'practica', p.nombre, 'laboratorio', l.nombre, 'campus', c.nombre,
        'inicio', s.inicio, 'fin', s.fin, 'estado', s.estado,
        'num_estudiantes', s.num_estudiantes
      ) order by s.inicio), '[]'::jsonb)
      from sesiones_practica s
      left join practicas p on p.id = s.practica_id
      left join laboratorios l on l.id = s.laboratorio_id
    left join campus c on c.id = s.campus_id
      where s.docente_id = v_uid
        and s.estado in ('borrador', 'solicitada', 'aprobada')
    ),
    'proximas_7_dias', (
      select count(*)
      from sesiones_practica
      where docente_id = v_uid
        and estado = 'aprobada'
        and inicio between now() and now() + interval '7 days'
    ),
    'mis_practicas', (
      select count(*) from practicas
      where docente_responsable_id = v_uid and activa
    ),
    'mis_grupos', (
      select count(*) from grupos where docente_id = v_uid
    )
  );
end $$;


grant execute on function obtener_alertas() to authenticated;
grant execute on function resumen_docente() to authenticated;

-- Refresca la caché de esquema de la API (necesario para que PostgREST vea la relación sesiones_practica→campus)
notify pgrst, 'reload schema';
