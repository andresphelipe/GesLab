-- =====================================================================
-- 03 · STORAGE BUCKETS, POLÍTICAS Y FUNCIONES DE NOTIFICACIÓN
-- Ejecutar en Supabase > SQL Editor DESPUÉS de 02_entrada_excel_y_web.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. BUCKETS DE ALMACENAMIENTO
-- ---------------------------------------------------------------------
-- Ejecutar desde el Dashboard > Storage > New bucket, o con la API:
--   • sds-fichas        (público lectura, privado escritura)
--   • incidencias-fotos (privado)
--   • guias-practicas   (público lectura, privado escritura)

insert into storage.buckets (id, name, public) values
  ('sds-fichas',        'sds-fichas',        true),
  ('incidencias-fotos', 'incidencias-fotos', false),
  ('guias-practicas',   'guias-practicas',   true)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- 2. POLÍTICAS DE STORAGE
-- ---------------------------------------------------------------------

-- SDS: cualquier autenticado lee, solo personal sube/modifica
create policy "sds_lectura" on storage.objects for select
  to authenticated using (bucket_id = 'sds-fichas');
create policy "sds_gestion" on storage.objects for insert
  to authenticated with check (bucket_id = 'sds-fichas' and es_personal());
create policy "sds_update" on storage.objects for update
  to authenticated using (bucket_id = 'sds-fichas' and es_personal());
create policy "sds_delete" on storage.objects for delete
  to authenticated using (bucket_id = 'sds-fichas' and es_personal());

-- Fotos de incidencias: el autor sube, personal ve todo
create policy "inc_foto_insert" on storage.objects for insert
  to authenticated with check (bucket_id = 'incidencias-fotos');
create policy "inc_foto_select_propia" on storage.objects for select
  to authenticated using (
    bucket_id = 'incidencias-fotos'
    and (owner_id = auth.uid()::text or es_personal())
  );
create policy "inc_foto_delete" on storage.objects for delete
  to authenticated using (bucket_id = 'incidencias-fotos' and es_personal());

-- Guías: cualquier autenticado lee, docentes y personal suben
create policy "guias_lectura" on storage.objects for select
  to authenticated using (bucket_id = 'guias-practicas');
create policy "guias_upload" on storage.objects for insert
  to authenticated with check (
    bucket_id = 'guias-practicas'
    and rol_actual() in ('docente', 'tecnico', 'admin')
  );
create policy "guias_update" on storage.objects for update
  to authenticated using (
    bucket_id = 'guias-practicas'
    and rol_actual() in ('docente', 'tecnico', 'admin')
  );
create policy "guias_delete" on storage.objects for delete
  to authenticated using (bucket_id = 'guias-practicas' and es_personal());

-- ---------------------------------------------------------------------
-- 3. FUNCIÓN DE ALERTAS CONSOLIDADAS (para el dashboard)
-- ---------------------------------------------------------------------
-- Devuelve un JSON con las alertas activas del sistema.
-- El frontend la llama con supabase.rpc('obtener_alertas')
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
      'laboratorio', l.nombre, 'inicio', s.inicio, 'fin', s.fin,
      'num_estudiantes', s.num_estudiantes, 'estado', s.estado
    ) order by s.inicio), '[]'::jsonb)
    from sesiones_practica s
    left join practicas p on p.id = s.practica_id
    join perfiles pr on pr.id = s.docente_id
    join laboratorios l on l.id = s.laboratorio_id
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
        'id', s.id, 'practica', p.nombre, 'laboratorio', l.nombre,
        'inicio', s.inicio, 'fin', s.fin, 'estado', s.estado,
        'num_estudiantes', s.num_estudiantes
      ) order by s.inicio), '[]'::jsonb)
      from sesiones_practica s
      left join practicas p on p.id = s.practica_id
      join laboratorios l on l.id = s.laboratorio_id
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

-- ---------------------------------------------------------------------
-- 5. PERMISOS
-- ---------------------------------------------------------------------
grant execute on function obtener_alertas() to authenticated;
grant execute on function resumen_docente() to authenticated;

