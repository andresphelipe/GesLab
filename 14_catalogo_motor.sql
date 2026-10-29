-- =====================================================================
-- GesLab · 14 · Catálogo semántico y motor de informes dinámico
-- Fase 2 (F2) de la hoja de ruta.
-- Requiere 01–13. Re-ejecutable.
--
-- 1. Tablas de catálogo (informes_dimensiones, informes_metricas,
--    informes_dominios) con sus seeds.
-- 2. Función informe_dinamico(spec jsonb) que ejecuta de forma segura
--    consultas armadas desde la UI, con RLS y lista blanca de campos.
-- 3. Tabla informes_favoritos para que cada usuario guarde sus informes.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. DOMINIOS: cada dominio apunta a una vista materializada o vista
-- ---------------------------------------------------------------------
create table if not exists informes_dominios (
  id            text primary key,
  nombre        text not null,
  descripcion   text,
  tabla         text not null,
  roles_permitidos text[] not null default '{tecnico,admin}',
  activo        boolean not null default true
);

insert into informes_dominios (id, nombre, descripcion, tabla, roles_permitidos) values
  ('consumo_reactivos',   'Consumo de reactivos',   'Reactivo × mes × campus × programa × docente × práctica × curso', 'mv_consumo_reactivo_mes',  '{docente,tecnico,admin}'),
  ('stock_tiempo',        'Stock a lo largo del tiempo', 'Serie diaria de stock por reactivo × campus (365 días)', 'mv_stock_tiempo',           '{tecnico,admin}'),
  ('tasa_ruptura',        'Tasa de ruptura',        'Material × campus × proveedor con rupturas, mermas y descartes', 'mv_tasa_ruptura',          '{tecnico,admin}'),
  ('ocupacion_lab',       'Ocupación de laboratorios', 'Laboratorio × día de semana × hora', 'mv_ocupacion_lab',          '{tecnico,admin}'),
  ('uso_equipo',          'Uso de equipos',         'Equipo × mes × campus con horas, reservas y mantenimientos', 'mv_uso_equipo',             '{tecnico,admin}'),
  ('cumplimiento',        'Cumplimiento de sesiones', 'KPIs de aprobación, consumo previsto vs real', 'mv_cumplimiento_sesion',    '{docente,tecnico,admin}')
on conflict (id) do update set
  nombre = excluded.nombre, descripcion = excluded.descripcion,
  tabla = excluded.tabla, roles_permitidos = excluded.roles_permitidos;

-- ---------------------------------------------------------------------
-- 2. DIMENSIONES: campos para agrupar o filtrar
-- ---------------------------------------------------------------------
create table if not exists informes_dimensiones (
  id            text primary key,
  dominio_id    text not null references informes_dominios(id) on delete cascade,
  campo_sql     text not null,
  tipo          text not null check (tipo in ('uuid','text','date','timestamp','int','numeric','boolean','text[]')),
  etiqueta      text not null,
  roles_permitidos text[] not null default '{tecnico,admin}',
  autocomplete_sql text,
  orden         int not null default 100,
  activo        boolean not null default true,
  unique (dominio_id, id)
);

insert into informes_dimensiones (id, dominio_id, campo_sql, tipo, etiqueta, roles_permitidos, autocomplete_sql, orden) values
  -- consumo_reactivos
  ('reactivo',        'consumo_reactivos', 'reactivo',       'text', 'Reactivo',        '{docente,tecnico,admin}', 'select distinct reactivo from mv_consumo_reactivo_mes where reactivo ilike $1 || ''%'' order by 1 limit 20', 10),
  ('cas',             'consumo_reactivos', 'cas',            'text', 'CAS',             '{docente,tecnico,admin}', null, 15),
  ('mes',             'consumo_reactivos', 'mes',            'date', 'Mes',             '{docente,tecnico,admin}', null, 20),
  ('campus',          'consumo_reactivos', 'campus',         'text', 'Campus',          '{docente,tecnico,admin}', 'select distinct campus from mv_consumo_reactivo_mes order by 1', 30),
  ('campus_id',       'consumo_reactivos', 'campus_id',      'uuid', 'Campus (id)',     '{docente,tecnico,admin}', null, 31),
  ('programa',        'consumo_reactivos', 'programa',       'text', 'Programa académico', '{docente,tecnico,admin}', 'select distinct programa from mv_consumo_reactivo_mes order by 1', 40),
  ('docente',         'consumo_reactivos', 'docente',        'text', 'Docente',         '{docente,tecnico,admin}', 'select distinct docente from mv_consumo_reactivo_mes where docente ilike $1 || ''%'' order by 1 limit 20', 50),
  ('curso',           'consumo_reactivos', 'curso',          'text', 'Curso',           '{docente,tecnico,admin}', 'select distinct curso from mv_consumo_reactivo_mes where curso is not null order by 1', 60),
  ('practica',        'consumo_reactivos', 'practica',       'text', 'Práctica',        '{docente,tecnico,admin}', null, 70),

  -- stock_tiempo
  ('dia',             'stock_tiempo',      'dia',            'date', 'Día',             '{tecnico,admin}', null, 10),
  ('reactivo_s',      'stock_tiempo',      'reactivo',       'text', 'Reactivo',        '{tecnico,admin}', 'select distinct reactivo from mv_stock_tiempo where reactivo ilike $1 || ''%'' order by 1 limit 20', 20),
  ('campus_s',        'stock_tiempo',      'campus',         'text', 'Campus',          '{tecnico,admin}', 'select distinct campus from mv_stock_tiempo order by 1', 30),

  -- tasa_ruptura
  ('material_r',      'tasa_ruptura',      'material',       'text', 'Material',        '{tecnico,admin}', 'select distinct material from mv_tasa_ruptura where material ilike $1 || ''%'' order by 1 limit 20', 10),
  ('tipo_r',          'tasa_ruptura',      'tipo',           'text', 'Tipo',            '{tecnico,admin}', 'select distinct tipo from mv_tasa_ruptura order by 1', 20),
  ('campus_r',        'tasa_ruptura',      'campus',         'text', 'Campus',          '{tecnico,admin}', 'select distinct campus from mv_tasa_ruptura order by 1', 30),
  ('proveedor_r',     'tasa_ruptura',      'proveedor',      'text', 'Proveedor',       '{tecnico,admin}', 'select distinct proveedor from mv_tasa_ruptura where proveedor is not null order by 1', 40),

  -- ocupacion_lab
  ('laboratorio',     'ocupacion_lab',     'laboratorio',    'text', 'Laboratorio',     '{tecnico,admin}', 'select distinct laboratorio from mv_ocupacion_lab order by 1', 10),
  ('campus_o',        'ocupacion_lab',     'campus',         'text', 'Campus',          '{tecnico,admin}', 'select distinct campus from mv_ocupacion_lab order by 1', 20),
  ('dia_semana',      'ocupacion_lab',     'dia_semana',     'int',  'Día de semana',   '{tecnico,admin}', null, 30),
  ('hora',            'ocupacion_lab',     'hora',           'int',  'Hora',            '{tecnico,admin}', null, 40),

  -- uso_equipo
  ('equipo',          'uso_equipo',        'equipo',         'text', 'Equipo',          '{tecnico,admin}', 'select distinct equipo from mv_uso_equipo where equipo ilike $1 || ''%'' order by 1 limit 20', 10),
  ('campus_e',        'uso_equipo',        'campus',         'text', 'Campus',          '{tecnico,admin}', 'select distinct campus from mv_uso_equipo order by 1', 20),
  ('mes_e',           'uso_equipo',        'mes',            'date', 'Mes',             '{tecnico,admin}', null, 30),
  ('estado_e',        'uso_equipo',        'estado',         'text', 'Estado del equipo', '{tecnico,admin}', 'select distinct estado from mv_uso_equipo order by 1', 40),

  -- cumplimiento
  ('fecha_c',         'cumplimiento',      'fecha',          'date', 'Fecha',           '{docente,tecnico,admin}', null, 10),
  ('mes_c',           'cumplimiento',      'mes',            'date', 'Mes',             '{docente,tecnico,admin}', null, 20),
  ('campus_c',        'cumplimiento',      'campus_id',      'uuid', 'Campus (id)',     '{docente,tecnico,admin}', null, 30),
  ('programa_c',      'cumplimiento',      'programa',       'text', 'Programa académico', '{docente,tecnico,admin}', null, 40),
  ('curso_c',         'cumplimiento',      'curso',          'text', 'Curso',           '{docente,tecnico,admin}', null, 50),
  ('docente_c',       'cumplimiento',      'docente_id',     'uuid', 'Docente (id)',    '{docente,tecnico,admin}', null, 60),
  ('estado_c',        'cumplimiento',      'estado',         'text', 'Estado',          '{docente,tecnico,admin}', 'select distinct estado from mv_cumplimiento_sesion order by 1', 70)
on conflict (id) do update set
  campo_sql = excluded.campo_sql, tipo = excluded.tipo,
  etiqueta = excluded.etiqueta, roles_permitidos = excluded.roles_permitidos,
  autocomplete_sql = excluded.autocomplete_sql, orden = excluded.orden;

-- ---------------------------------------------------------------------
-- 3. MÉTRICAS: columnas numéricas con agregación
-- ---------------------------------------------------------------------
create table if not exists informes_metricas (
  id            text primary key,
  dominio_id    text not null references informes_dominios(id) on delete cascade,
  agregacion    text not null check (agregacion in ('sum','avg','count','count_distinct','min','max','custom')),
  expresion_sql text not null,
  etiqueta      text not null,
  unidad        text,
  formato       text not null default 'numero' check (formato in ('numero','entero','decimal','moneda','porcentaje','duracion')),
  roles_permitidos text[] not null default '{tecnico,admin}',
  orden         int not null default 100,
  activo        boolean not null default true,
  unique (dominio_id, id)
);

insert into informes_metricas (id, dominio_id, agregacion, expresion_sql, etiqueta, unidad, formato, roles_permitidos, orden) values
  -- consumo_reactivos
  ('consumo_base',    'consumo_reactivos', 'sum',           'consumido_base',     'Consumido (unidad base)', 'g/mL', 'decimal', '{docente,tecnico,admin}', 10),
  ('previsto_base',   'consumo_reactivos', 'sum',           'previsto_base',      'Previsto (unidad base)',  'g/mL', 'decimal', '{docente,tecnico,admin}', 20),
  ('cumplimiento_pct','consumo_reactivos', 'custom',        'case when sum(previsto_base) > 0 then round(100 * sum(consumido_base) / sum(previsto_base), 1) else null end',
                                                                                 'Cumplimiento %',          '%',    'porcentaje', '{docente,tecnico,admin}', 30),
  ('n_sesiones_cr',   'consumo_reactivos', 'sum',           'n_sesiones',         'Sesiones',                null,   'entero',  '{docente,tecnico,admin}', 40),
  ('n_estudiantes_cr','consumo_reactivos', 'sum',           'n_estudiantes',      'Estudiantes',             null,   'entero',  '{docente,tecnico,admin}', 50),

  -- stock_tiempo
  ('stock_calculado', 'stock_tiempo',      'avg',           'stock_calculado',    'Stock',                   'g/mL', 'decimal', '{tecnico,admin}', 10),

  -- tasa_ruptura
  ('rupturas_m',      'tasa_ruptura',      'sum',           'rupturas',           'Rupturas',                null,   'entero',  '{tecnico,admin}', 10),
  ('mermas_m',        'tasa_ruptura',      'sum',           'mermas',             'Mermas',                  null,   'entero',  '{tecnico,admin}', 20),
  ('descartes_m',     'tasa_ruptura',      'sum',           'descartes',          'Descartes',               null,   'entero',  '{tecnico,admin}', 30),
  ('ingresos_m',      'tasa_ruptura',      'sum',           'ingresos',           'Ingresos',                null,   'entero',  '{tecnico,admin}', 40),
  ('tasa_ruptura_pct','tasa_ruptura',      'avg',           'tasa_ruptura_pct',   'Tasa de ruptura',         '%',    'porcentaje','{tecnico,admin}', 50),

  -- ocupacion_lab
  ('n_sesiones_ol',   'ocupacion_lab',     'sum',           'n_sesiones',         'Sesiones',                null,   'entero',  '{tecnico,admin}', 10),
  ('horas_totales',   'ocupacion_lab',     'sum',           'horas_totales',      'Horas de uso',            'h',    'decimal', '{tecnico,admin}', 20),
  ('estudiantes_at',  'ocupacion_lab',     'sum',           'estudiantes_atendidos','Estudiantes atendidos', null,   'entero',  '{tecnico,admin}', 30),

  -- uso_equipo
  ('horas_uso',       'uso_equipo',        'sum',           'horas_uso',          'Horas de uso',            'h',    'decimal', '{tecnico,admin}', 10),
  ('n_reservas_eq',   'uso_equipo',        'sum',           'n_reservas',         'Reservas',                null,   'entero',  '{tecnico,admin}', 20),
  ('n_mant',          'uso_equipo',        'sum',           'n_mantenimientos',   'Mantenimientos',          null,   'entero',  '{tecnico,admin}', 30),
  ('costo_mant',      'uso_equipo',        'sum',           'costo_mantenimiento','Costo mantenimiento',     'COP',  'moneda',  '{tecnico,admin}', 40),

  -- cumplimiento
  ('n_sesiones_c',    'cumplimiento',      'count',         '*',                  'Sesiones',                null,   'entero',  '{docente,tecnico,admin}', 10),
  ('horas_aprobacion','cumplimiento',      'avg',           'horas_hasta_aprobacion','Horas hasta aprobación', 'h',  'decimal', '{docente,tecnico,admin}', 20),
  ('previsto_c',      'cumplimiento',      'sum',           'previsto_base',      'Previsto',                'g/mL','decimal', '{docente,tecnico,admin}', 30),
  ('consumido_c',     'cumplimiento',      'sum',           'consumido_base',     'Consumido',               'g/mL','decimal', '{docente,tecnico,admin}', 40),
  ('estudiantes_c',   'cumplimiento',      'sum',           'num_estudiantes',    'Estudiantes',             null,  'entero',  '{docente,tecnico,admin}', 50)
on conflict (id) do update set
  agregacion = excluded.agregacion, expresion_sql = excluded.expresion_sql,
  etiqueta = excluded.etiqueta, unidad = excluded.unidad, formato = excluded.formato,
  roles_permitidos = excluded.roles_permitidos, orden = excluded.orden;

-- Lectura pública (autenticada) del catálogo
alter table informes_dominios    enable row level security;
alter table informes_dimensiones enable row level security;
alter table informes_metricas    enable row level security;

drop policy if exists idom_r on informes_dominios;
create policy idom_r on informes_dominios for select to authenticated using (true);
drop policy if exists idim_r on informes_dimensiones;
create policy idim_r on informes_dimensiones for select to authenticated using (true);
drop policy if exists imet_r on informes_metricas;
create policy imet_r on informes_metricas for select to authenticated using (true);

-- ---------------------------------------------------------------------
-- 4. MOTOR DE INFORMES: informe_dinamico(spec jsonb) returns jsonb
--    Operadores permitidos y validación por lista blanca.
-- ---------------------------------------------------------------------
create or replace function informe_dinamico(p_spec jsonb) returns jsonb
language plpgsql security invoker set search_path = public, extensions as $$
declare
  v_dominio text := p_spec->>'dominio';
  v_tabla text;
  v_roles text[];
  v_rol  text := coalesce(rol_actual()::text, 'admin');
  v_metricas text[];
  v_dimensiones text[];
  v_filtros jsonb;
  v_orden jsonb;
  v_limite int := least(coalesce((p_spec->>'limite')::int, 500), 10000);
  v_select text := '';
  v_group  text := '';
  v_order  text := '';
  v_where  text := '';
  v_sql    text;
  v_cols   jsonb;
  v_filas  jsonb;
  v_tiempo numeric;
  v_t0 timestamptz := clock_timestamp();
  r record;
  m record;
  f jsonb;
  o jsonb;
  v_filtros_arr jsonb[];
  v_param_idx int := 0;
  v_params text[];
  v_valor text;
  v_op text;
  v_op_sql text;
  v_campo_sql text;
  v_tipo text;
begin
  if v_dominio is null then raise exception 'Falta el dominio'; end if;

  select tabla, roles_permitidos into v_tabla, v_roles from informes_dominios where id = v_dominio and activo;
  if v_tabla is null then raise exception 'Dominio desconocido: %', v_dominio; end if;
  if not (v_rol = any(v_roles)) then raise exception 'No tiene permisos para este dominio'; end if;

  select array_agg(x) into v_metricas    from jsonb_array_elements_text(coalesce(p_spec->'metricas','[]'::jsonb)) x;
  select array_agg(x) into v_dimensiones from jsonb_array_elements_text(coalesce(p_spec->'dimensiones','[]'::jsonb)) x;
  v_filtros := coalesce(p_spec->'filtros','[]'::jsonb);
  v_orden   := coalesce(p_spec->'orden','[]'::jsonb);

  -- SELECT de dimensiones
  if v_dimensiones is not null then
    for r in
      select d.id, d.campo_sql, d.etiqueta from informes_dimensiones d
       where d.dominio_id = v_dominio and d.id = any(v_dimensiones) and d.activo
         and v_rol = any(d.roles_permitidos)
       order by d.orden
    loop
      v_select := v_select || format('%I as %I, ', r.campo_sql, r.id);
      v_group  := v_group  || format('%I, ', r.campo_sql);
    end loop;
  end if;

  -- SELECT de métricas
  if v_metricas is not null then
    for m in
      select mt.id, mt.agregacion, mt.expresion_sql, mt.etiqueta from informes_metricas mt
       where mt.dominio_id = v_dominio and mt.id = any(v_metricas) and mt.activo
         and v_rol = any(mt.roles_permitidos)
       order by mt.orden
    loop
      if m.agregacion = 'custom' then
        v_select := v_select || format('(%s) as %I, ', m.expresion_sql, m.id);
      elsif m.agregacion = 'count' then
        v_select := v_select || format('count(%s) as %I, ', m.expresion_sql, m.id);
      elsif m.agregacion = 'count_distinct' then
        v_select := v_select || format('count(distinct %I) as %I, ', m.expresion_sql, m.id);
      else
        v_select := v_select || format('%s(%I) as %I, ', m.agregacion, m.expresion_sql, m.id);
      end if;
    end loop;
  end if;

  if length(v_select) = 0 then raise exception 'Debe seleccionar al menos una dimensión o métrica'; end if;
  v_select := left(v_select, length(v_select) - 2);
  if length(v_group) > 0 then v_group := 'group by ' || left(v_group, length(v_group) - 2); end if;

  -- WHERE con validación por lista blanca
  if jsonb_array_length(v_filtros) > 25 then raise exception 'Máximo 25 filtros por consulta'; end if;

  for f in select * from jsonb_array_elements(v_filtros) loop
    select d.campo_sql, d.tipo into v_campo_sql, v_tipo
      from informes_dimensiones d
     where d.dominio_id = v_dominio and d.id = f->>'campo' and d.activo
       and v_rol = any(d.roles_permitidos);
    if v_campo_sql is null then raise exception 'Filtro no permitido: %', f->>'campo'; end if;
    v_op := lower(coalesce(f->>'op','eq'));
    v_op_sql := case v_op
      when 'eq' then '='
      when 'ne' then '<>'
      when 'lt' then '<'
      when 'lte' then '<='
      when 'gt' then '>'
      when 'gte' then '>='
      when 'in' then 'in'
      when 'not_in' then 'not in'
      when 'between' then 'between'
      when 'contains' then '@>'
      when 'starts_with' then 'ilike'
      when 'ends_with' then 'ilike'
      when 'is_null' then 'is null'
      when 'is_not_null' then 'is not null'
      else null end;
    if v_op_sql is null then raise exception 'Operador no permitido: %', v_op; end if;

    if length(v_where) = 0 then v_where := 'where '; else v_where := v_where || ' and '; end if;

    if v_op in ('is_null','is_not_null') then
      v_where := v_where || format('%I %s', v_campo_sql, v_op_sql);
    elsif v_op in ('in','not_in') then
      v_where := v_where || format('%I %s (select unnest($%s::text[])::%s)', v_campo_sql, v_op_sql, v_param_idx + 1, v_tipo);
      v_param_idx := v_param_idx + 1;
      v_params := array_append(v_params, (f->'valor')::text);
    elsif v_op = 'between' then
      v_where := v_where || format('%I between ($%s::%s) and ($%s::%s)',
                 v_campo_sql, v_param_idx + 1, v_tipo, v_param_idx + 2, v_tipo);
      v_param_idx := v_param_idx + 2;
      v_params := array_append(v_params, (f->'valor'->>0));
      v_params := array_append(v_params, (f->'valor'->>1));
    elsif v_op = 'starts_with' then
      v_where := v_where || format('%I ilike ($%s || ''%%'')', v_campo_sql, v_param_idx + 1);
      v_param_idx := v_param_idx + 1;
      v_params := array_append(v_params, f->>'valor');
    elsif v_op = 'ends_with' then
      v_where := v_where || format('%I ilike (''%%'' || $%s)', v_campo_sql, v_param_idx + 1);
      v_param_idx := v_param_idx + 1;
      v_params := array_append(v_params, f->>'valor');
    elsif v_op = 'contains' then
      v_where := v_where || format('%I @> ARRAY[$%s::text]', v_campo_sql, v_param_idx + 1);
      v_param_idx := v_param_idx + 1;
      v_params := array_append(v_params, f->>'valor');
    else
      v_where := v_where || format('%I %s $%s::%s', v_campo_sql, v_op_sql, v_param_idx + 1, v_tipo);
      v_param_idx := v_param_idx + 1;
      v_params := array_append(v_params, f->>'valor');
    end if;
  end loop;

  -- ORDER BY
  if jsonb_array_length(v_orden) > 0 then
    v_order := 'order by ';
    for o in select * from jsonb_array_elements(v_orden) loop
      v_order := v_order || format('%I %s, ', o->>'campo',
                                   case when lower(coalesce(o->>'dir','asc')) = 'desc' then 'desc' else 'asc' end);
    end loop;
    v_order := left(v_order, length(v_order) - 2);
  end if;

  v_sql := format('select %s from %I %s %s %s limit %s',
                  v_select, v_tabla, v_where, v_group, v_order, v_limite);

  -- Ejecutar y empacar resultado
  execute format('select coalesce(jsonb_agg(row_to_json(t)), ''[]''::jsonb) from (%s) t', v_sql)
    using v_params into v_filas;

  v_tiempo := extract(epoch from (clock_timestamp() - v_t0)) * 1000;

  -- Registro de auditoría (usa auditar() SECURITY DEFINER para pasar la RLS)
  begin
    perform auditar('informes_consultas', gen_random_uuid(), 'consultar',
                    jsonb_build_object('dominio', v_dominio, 'spec', p_spec,
                                       'filas', jsonb_array_length(v_filas),
                                       'ms', v_tiempo, 'sql', v_sql));
  exception when others then null;
  end;

  return jsonb_build_object(
    'dominio', v_dominio,
    'tabla', v_tabla,
    'filas', v_filas,
    'n_filas', jsonb_array_length(v_filas),
    'ejecutado_en', clock_timestamp(),
    'duracion_ms', v_tiempo,
    'spec', p_spec
  );
exception when others then
  raise exception 'Error en informe_dinamico: % (SQL: %)', SQLERRM, coalesce(v_sql, '(no armado)');
end $$;
revoke execute on function informe_dinamico(jsonb) from public, anon;
grant  execute on function informe_dinamico(jsonb) to authenticated;

-- ---------------------------------------------------------------------
-- 5. INFORMES FAVORITOS
-- ---------------------------------------------------------------------
create table if not exists informes_favoritos (
  id          uuid primary key default gen_random_uuid(),
  usuario_id  uuid not null references perfiles(id) on delete cascade,
  nombre      text not null,
  descripcion text,
  dominio_id  text not null references informes_dominios(id),
  spec        jsonb not null,
  compartido  boolean not null default false,
  creado_en   timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);
create index if not exists favoritos_usuario_idx on informes_favoritos (usuario_id);

alter table informes_favoritos enable row level security;
drop policy if exists fav_lectura on informes_favoritos;
create policy fav_lectura on informes_favoritos for select to authenticated
  using (usuario_id = auth.uid() or compartido or es_personal());
drop policy if exists fav_propio on informes_favoritos;
create policy fav_propio on informes_favoritos for all to authenticated
  using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

notify pgrst, 'reload schema';
