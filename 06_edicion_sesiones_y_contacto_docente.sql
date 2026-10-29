-- =====================================================================
-- GesLab · 06 · Edición de solicitudes por el personal y datos de contacto del docente
-- Requiere 04 y 05. Re-ejecutable.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. AUDITORÍA: la tabla solo la lee el administrador y nadie escribe en ella
-- directamente; estas funciones (SECURITY DEFINER) registran los cambios.
-- ---------------------------------------------------------------------
create or replace function auditar(p_tabla text, p_registro uuid, p_accion text, p_datos jsonb) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into auditoria (tabla, registro_id, accion, usuario_id, datos)
  values (p_tabla, p_registro, p_accion, auth.uid(), p_datos);
end $$;
revoke execute on function auditar(text, uuid, text, jsonb) from public, anon;
grant execute on function auditar(text, uuid, text, jsonb) to authenticated;

-- ---------------------------------------------------------------------
-- 1. CONTACTO DEL DOCENTE (se captura una sola vez, en su perfil)
-- ---------------------------------------------------------------------
alter table perfiles add column if not exists celular text;
alter table perfiles drop constraint if exists perfiles_celular_formato;
alter table perfiles add constraint perfiles_celular_formato
  check (celular is null or celular ~ '^\+?[0-9 ]{7,15}$');

-- Un docente no puede enviar una solicitud sin nombre y celular en su perfil
create or replace function exigir_contacto_docente() returns trigger
language plpgsql security definer set search_path = public as $$
declare p perfiles;
begin
  if new.estado = 'solicitada' and new.origen = 'app' and new.docente_id = auth.uid() then
    select * into p from perfiles where id = new.docente_id;
    if coalesce(trim(p.nombre), '') = '' or coalesce(trim(p.celular), '') = '' then
      raise exception 'Complete su nombre y celular antes de enviar la solicitud';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists trg_exigir_contacto on sesiones_practica;
create trigger trg_exigir_contacto before insert on sesiones_practica
  for each row execute function exigir_contacto_docente();

-- ---------------------------------------------------------------------
-- 2. EDICIÓN DE UNA SOLICITUD (personal técnico y administradores)
-- Solo solicitudes enviadas o aprobadas. Cada edición deja en la tabla
-- auditoria lo que había antes y lo que quedó después.
-- p admite (solo se cambia lo que venga):
--   practica_nombre, campus_id, programa_academico, curso, agua_destilada_l,
--   fecha + inicio + fin (juntos), num_estudiantes, num_grupos_trabajo,
--   observaciones, laboratorio_id,
--   reactivos / materiales: lista COMPLETA de líneas. Con "id" se actualiza la
--   línea; sin "id" se busca por nombre (o queda pendiente). Las líneas que no
--   vengan se quitan, salvo que ya tengan consumo reportado.
-- ---------------------------------------------------------------------
alter table sesiones_practica
  add column if not exists editado_por uuid references perfiles(id),
  add column if not exists editado_en  timestamptz;

create or replace function editar_sesion(p_id uuid, p jsonb) returns jsonb
language plpgsql set search_path = public, extensions as $$
declare
  s sesiones_practica; antes jsonb; despues jsonb;
  v_prac uuid; v_nombre text; v_ini timestamptz; v_fin timestamptz;
  it jsonb; v_id uuid; v_n text; v_n2 text; v_cant numeric; v_uni text; v_conc text; v_line uuid;
  v_keep uuid[]; v_pend int := 0; v_avisos jsonb := '[]'::jsonb;
begin
  if not es_personal() then
    raise exception 'Solo el personal técnico y los administradores pueden editar solicitudes';
  end if;
  select * into s from sesiones_practica where id = p_id for update;
  if not found then raise exception 'La sesión no existe'; end if;
  if s.estado not in ('solicitada', 'aprobada') then
    raise exception 'Solo se editan solicitudes enviadas o aprobadas (estado actual: %)', s.estado;
  end if;

  antes := jsonb_build_object(
    'sesion', to_jsonb(s),
    'reactivos', (select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) from sesion_reactivos x where x.sesion_id = p_id),
    'materiales', (select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) from sesion_materiales x where x.sesion_id = p_id));

  -- Práctica por nombre (se busca o se crea)
  v_nombre := nullif(trim(p->>'practica_nombre'), '');
  if v_nombre is not null then
    select id into v_prac from practicas where normalizar_texto(nombre) = normalizar_texto(v_nombre) limit 1;
    if v_prac is null then
      insert into practicas (nombre, asignatura, programa, docente_responsable_id)
      values (v_nombre, coalesce(nullif(trim(p->>'curso'), ''), s.curso), coalesce(nullif(trim(p->>'programa_academico'), ''), s.programa_academico), s.docente_id)
      returning id into v_prac;
    end if;
  end if;

  -- Fecha y horario: deben venir los tres
  if (p ? 'fecha') or (p ? 'inicio') or (p ? 'fin') then
    if nullif(p->>'fecha', '') is null or nullif(p->>'inicio', '') is null or nullif(p->>'fin', '') is null then
      raise exception 'Para cambiar el horario indique fecha, hora de inicio y hora de fin';
    end if;
    v_ini := ((p->>'fecha') || ' ' || (p->>'inicio'))::timestamp at time zone 'America/Bogota';
    v_fin := ((p->>'fecha') || ' ' || (p->>'fin'))::timestamp at time zone 'America/Bogota';
    if v_fin <= v_ini then raise exception 'La hora de fin debe ser posterior a la de inicio'; end if;
  end if;

  update sesiones_practica set
    practica_id        = coalesce(v_prac, practica_id),
    campus_id          = case when p ? 'campus_id' then nullif(p->>'campus_id', '')::uuid else campus_id end,
    laboratorio_id     = case when p ? 'laboratorio_id' then nullif(p->>'laboratorio_id', '')::uuid else laboratorio_id end,
    programa_academico = case when p ? 'programa_academico' then nullif(trim(p->>'programa_academico'), '') else programa_academico end,
    curso              = case when p ? 'curso' then nullif(trim(p->>'curso'), '') else curso end,
    agua_destilada_l   = case when p ? 'agua_destilada_l' then nullif(p->>'agua_destilada_l', '')::numeric else agua_destilada_l end,
    num_estudiantes    = case when p ? 'num_estudiantes' then nullif(p->>'num_estudiantes', '')::int else num_estudiantes end,
    num_grupos_trabajo = case when p ? 'num_grupos_trabajo' then nullif(p->>'num_grupos_trabajo', '')::int else num_grupos_trabajo end,
    observaciones      = case when p ? 'observaciones' then nullif(trim(p->>'observaciones'), '') else observaciones end,
    inicio             = coalesce(v_ini, inicio),
    fin                = coalesce(v_fin, fin),
    editado_por        = auth.uid(),
    editado_en         = now()
  where id = p_id;

  -- Reactivos
  if p ? 'reactivos' then
    v_keep := '{}';
    for it in select * from jsonb_array_elements(p->'reactivos') loop
      v_cant := nullif(it->>'cantidad', '')::numeric;
      v_uni  := case when lower(nullif(it->>'unidad', '')) = 'ml' then 'mL' else nullif(it->>'unidad', '') end;
      v_conc := nullif(it->>'concentracion', '');
      v_line := nullif(it->>'id', '')::uuid;
      if v_line is not null then
        update sesion_reactivos set cantidad_prevista = v_cant, unidad = v_uni, concentracion = v_conc
         where id = v_line and sesion_id = p_id;
        if not found then raise exception 'Una línea de reactivo no pertenece a esta sesión'; end if;
        v_keep := v_keep || v_line;
      else
        v_n := normalizar_texto(it->>'texto');
        continue when v_n = '';
        v_n2 := trim(regexp_replace(v_n, '\(?\s*\d+(?:[.,]\d+)?\s*m\)?\s*$', ''));
        v_id := null;
        select reactivo_id into v_id from alias_reactivos where alias in (v_n, v_n2) order by (alias = v_n) desc limit 1;
        if v_id is not null then
          insert into sesion_reactivos (sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, texto_original)
          values (p_id, v_id, v_cant, v_uni, v_conc, it->>'texto')
          on conflict (sesion_id, reactivo_id) do update set
            cantidad_prevista = excluded.cantidad_prevista, unidad = excluded.unidad, concentracion = excluded.concentracion
          returning id into v_line;
          v_keep := v_keep || v_line;
        else
          insert into lineas_pendientes (sesion_id, tipo, texto_original, cantidad, unidad, concentracion)
          values (p_id, 'reactivo', it->>'texto', v_cant, v_uni, v_conc);
          v_pend := v_pend + 1;
        end if;
      end if;
    end loop;
    if exists (select 1 from sesion_reactivos where sesion_id = p_id and id <> all (v_keep) and cantidad_consumida is not null) then
      raise exception 'No se puede quitar un reactivo que ya tiene consumo reportado';
    end if;
    delete from sesion_reactivos where sesion_id = p_id and id <> all (v_keep);
  end if;

  -- Materiales, vidriería y equipos
  if p ? 'materiales' then
    v_keep := '{}';
    for it in select * from jsonb_array_elements(p->'materiales') loop
      v_cant := nullif(it->>'cantidad', '')::numeric;
      v_line := nullif(it->>'id', '')::uuid;
      if v_line is not null then
        update sesion_materiales set cantidad_prevista = v_cant where id = v_line and sesion_id = p_id;
        if not found then raise exception 'Una línea de material no pertenece a esta sesión'; end if;
        v_keep := v_keep || v_line;
      else
        v_n := normalizar_texto(it->>'texto');
        continue when v_n = '';
        v_id := null;
        select material_id into v_id from alias_materiales where alias = v_n;
        if v_id is not null then
          insert into sesion_materiales (sesion_id, material_id, cantidad_prevista, texto_original)
          values (p_id, v_id, v_cant, it->>'texto')
          on conflict (sesion_id, material_id) do update set cantidad_prevista = excluded.cantidad_prevista
          returning id into v_line;
          v_keep := v_keep || v_line;
        else
          insert into lineas_pendientes (sesion_id, tipo, texto_original, cantidad)
          values (p_id, 'material', it->>'texto', v_cant);
          v_pend := v_pend + 1;
        end if;
      end if;
    end loop;
    if exists (select 1 from sesion_materiales where sesion_id = p_id and id <> all (v_keep) and cantidad_consumida is not null) then
      raise exception 'No se puede quitar un material que ya tiene consumo reportado';
    end if;
    delete from sesion_materiales where sesion_id = p_id and id <> all (v_keep);
  end if;

  despues := jsonb_build_object(
    'sesion', (select to_jsonb(x) from sesiones_practica x where x.id = p_id),
    'reactivos', (select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) from sesion_reactivos x where x.sesion_id = p_id),
    'materiales', (select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) from sesion_materiales x where x.sesion_id = p_id));
  perform auditar('sesiones_practica', p_id, 'editar', jsonb_build_object('antes', antes, 'despues', despues));

  -- Si ya está aprobada, avisar si tras el cambio faltan existencias
  if s.estado = 'aprobada' then
    select coalesce(jsonb_agg(jsonb_build_object('tipo', d.tipo, 'item', d.item, 'estado', d.estado, 'mensaje', d.mensaje)), '[]'::jsonb)
      into v_avisos from disponibilidad_sesiones(array[p_id]) d where d.estado in ('falta', 'ok_traslado');
  end if;

  return jsonb_build_object('ok', true, 'pendientes_nuevas', v_pend, 'avisos', v_avisos);
end $$;

-- ---------------------------------------------------------------------
-- 3. LÍNEAS PENDIENTES: vincular a un ítem del catálogo (y recordar el nombre) o descartar
-- ---------------------------------------------------------------------
create or replace function vincular_pendiente(p_id uuid, p_item uuid) returns void
language plpgsql set search_path = public, extensions as $$
declare l lineas_pendientes; v_n text; v_n2 text;
begin
  if not es_personal() then raise exception 'Solo el personal puede vincular líneas'; end if;
  select * into l from lineas_pendientes where id = p_id and not resuelta for update;
  if not found then raise exception 'La línea ya no está pendiente'; end if;
  v_n  := normalizar_texto(l.texto_original);
  v_n2 := trim(regexp_replace(v_n, '\(?\s*\d+(?:[.,]\d+)?\s*m\)?\s*$', ''));
  if l.tipo = 'reactivo' then
    if not exists (select 1 from catalogo_reactivos where id = p_item) then raise exception 'Reactivo no encontrado'; end if;
    insert into sesion_reactivos (sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, texto_original)
    values (l.sesion_id, p_item, l.cantidad, l.unidad, l.concentracion, l.texto_original)
    on conflict (sesion_id, reactivo_id) do update set
      cantidad_prevista = coalesce(sesion_reactivos.cantidad_prevista, 0) + coalesce(excluded.cantidad_prevista, 0),
      texto_original = sesion_reactivos.texto_original || ' | ' || excluded.texto_original;
    insert into alias_reactivos (alias, reactivo_id) values (v_n, p_item) on conflict (alias) do nothing;
    if v_n2 <> '' then insert into alias_reactivos (alias, reactivo_id) values (v_n2, p_item) on conflict (alias) do nothing; end if;
  else
    if not exists (select 1 from catalogo_materiales where id = p_item) then raise exception 'Material no encontrado'; end if;
    insert into sesion_materiales (sesion_id, material_id, cantidad_prevista, texto_original)
    values (l.sesion_id, p_item, l.cantidad, l.texto_original)
    on conflict (sesion_id, material_id) do update set
      cantidad_prevista = coalesce(sesion_materiales.cantidad_prevista, 0) + coalesce(excluded.cantidad_prevista, 0),
      texto_original = sesion_materiales.texto_original || ' | ' || excluded.texto_original;
    insert into alias_materiales (alias, material_id) values (v_n, p_item) on conflict (alias) do nothing;
  end if;
  update lineas_pendientes set resuelta = true where id = p_id;
  perform auditar('lineas_pendientes', p_id, 'vincular', jsonb_build_object('item', p_item, 'texto', l.texto_original, 'sesion_id', l.sesion_id));
end $$;

create or replace function descartar_pendiente(p_id uuid) returns void
language plpgsql set search_path = public as $$
begin
  if not es_personal() then raise exception 'Solo el personal puede descartar líneas'; end if;
  update lineas_pendientes set resuelta = true where id = p_id and not resuelta;
  perform auditar('lineas_pendientes', p_id, 'descartar', '{}'::jsonb);
end $$;

-- ---------------------------------------------------------------------
-- 4. EL PERSONAL PUEDE COMPLETAR EL CONTACTO DE UN DOCENTE (nombre y celular)
-- El correo pertenece a la cuenta de acceso y no se cambia desde aquí.
-- ---------------------------------------------------------------------
create or replace function actualizar_contacto_docente(p_docente uuid, p_nombre text, p_celular text) returns void
language plpgsql security definer set search_path = public as $$
declare antes jsonb;
begin
  if not es_personal() then raise exception 'Solo el personal puede editar el contacto de un docente'; end if;
  if coalesce(trim(p_nombre), '') = '' then raise exception 'El nombre no puede quedar vacío'; end if;
  if p_celular is not null and trim(p_celular) <> '' and trim(p_celular) !~ '^\+?[0-9 ]{7,15}$' then
    raise exception 'Celular no válido: use solo números (7 a 15 dígitos)';
  end if;
  select jsonb_build_object('nombre', nombre, 'celular', celular) into antes from perfiles where id = p_docente;
  if antes is null then raise exception 'El docente no existe'; end if;
  update perfiles set nombre = trim(p_nombre), celular = nullif(trim(coalesce(p_celular, '')), '') where id = p_docente;
  perform auditar('perfiles', p_docente, 'contacto', jsonb_build_object('antes', antes,
          'despues', jsonb_build_object('nombre', trim(p_nombre), 'celular', nullif(trim(coalesce(p_celular, '')), ''))));
end $$;
revoke execute on function actualizar_contacto_docente(uuid, text, text) from public, anon;
grant execute on function actualizar_contacto_docente(uuid, text, text) to authenticated;

revoke execute on function editar_sesion(uuid, jsonb), vincular_pendiente(uuid, uuid), descartar_pendiente(uuid) from public, anon;
grant execute on function editar_sesion(uuid, jsonb), vincular_pendiente(uuid, uuid), descartar_pendiente(uuid) to authenticated;

notify pgrst, 'reload schema';
