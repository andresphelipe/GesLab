-- =====================================================================
-- GESTIÓN DE LABORATORIOS DOCENTES (CIENCIAS) - Supabase / PostgreSQL 15+
-- Módulos: usuarios y roles · inventario (reactivos, materiales, equipos)
--          prácticas y reservas · incidencias · informes · importación
-- Ejecutar en el SQL Editor de Supabase, de arriba hacia abajo.
-- =====================================================================

create extension if not exists btree_gist;   -- necesaria para evitar reservas solapadas

-- ---------------------------------------------------------------------
-- 1. TIPOS
-- ---------------------------------------------------------------------
create type rol_usuario      as enum ('estudiante','docente','tecnico','admin');
create type estado_equipo    as enum ('operativo','en_mantenimiento','fuera_de_servicio','baja');
create type estado_envase    as enum ('disponible','en_uso','agotado','vencido','baja');
create type tipo_mov         as enum ('entrada','salida','consumo','ajuste_positivo','ajuste_negativo','residuo');
create type estado_sesion    as enum ('borrador','solicitada','aprobada','rechazada','finalizada','cancelada');
create type estado_reserva   as enum ('solicitada','aprobada','rechazada','cancelada');
create type estado_incidencia as enum ('abierta','en_proceso','resuelta','descartada');
create type severidad        as enum ('baja','media','alta','critica');
create type unidad_medida    as enum ('g','kg','mg','mL','L','unidad','caja','par');
create type estado_importacion as enum ('pendiente','procesado','error');

-- ---------------------------------------------------------------------
-- 2. USUARIOS Y ROLES
-- ---------------------------------------------------------------------
create table perfiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  nombre     text not null default '',
  email      text not null,
  rol        rol_usuario not null default 'estudiante',
  documento  text,
  programa   text,
  activo     boolean not null default true,
  creado_en  timestamptz not null default now()
);

-- Funciones auxiliares (SECURITY DEFINER para evitar recursión en RLS)
create or replace function rol_actual() returns rol_usuario
language sql stable security definer set search_path = public as $$
  select rol from perfiles where id = auth.uid() and activo
$$;

create or replace function es_personal() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(rol_actual() in ('tecnico','admin'), false)
$$;

create or replace function es_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(rol_actual() = 'admin', false)
$$;

-- Alta automática de perfil al registrarse (rol inicial: estudiante)
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  -- Para restringir al dominio institucional, descomente y ajuste:
  -- if new.email !~* '@su-universidad\.edu(\.co)?$' then
  --   raise exception 'Solo se permiten correos institucionales';
  -- end if;
  insert into perfiles (id, email, nombre)
  values (new.id, new.email,
          coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', ''));
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users for each row execute function handle_new_user();

-- Solo un admin puede cambiar roles o activar/desactivar usuarios
create or replace function proteger_perfil() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not es_admin() then
    if new.rol is distinct from old.rol or new.activo is distinct from old.activo
       or new.email is distinct from old.email then
      raise exception 'Solo un administrador puede cambiar rol, estado o correo';
    end if;
  end if;
  return new;
end $$;

create trigger trg_proteger_perfil before update on perfiles
  for each row execute function proteger_perfil();

-- ---------------------------------------------------------------------
-- 3. LABORATORIOS, UBICACIONES Y EQUIPOS
-- ---------------------------------------------------------------------
create table laboratorios (
  id        uuid primary key default gen_random_uuid(),
  nombre    text not null unique,
  ubicacion text,
  capacidad int,
  activo    boolean not null default true
);

create table ubicaciones (            -- armarios, estantes, neveras, etc.
  id                   uuid primary key default gen_random_uuid(),
  laboratorio_id       uuid not null references laboratorios(id) on delete cascade,
  nombre               text not null,
  -- clase de almacenamiento: inflamables, acidos, bases, oxidantes, toxicos, general...
  clase_almacenamiento text not null default 'general',
  unique (laboratorio_id, nombre)
);

create table equipos (
  id                    uuid primary key default gen_random_uuid(),
  laboratorio_id        uuid not null references laboratorios(id),
  codigo                text not null unique,
  nombre                text not null,
  marca                 text,
  modelo                text,
  serie                 text,
  estado                estado_equipo not null default 'operativo',
  reservable            boolean not null default true,
  fecha_adquisicion     date,
  ultima_calibracion    date,
  proxima_calibracion   date,
  proximo_mantenimiento date,
  notas                 text,
  creado_en             timestamptz not null default now()
);

create table mantenimientos (
  id             uuid primary key default gen_random_uuid(),
  equipo_id      uuid not null references equipos(id) on delete cascade,
  tipo           text not null check (tipo in ('preventivo','correctivo','calibracion')),
  fecha          date not null default current_date,
  proximo        date,
  descripcion    text,
  responsable_id uuid references perfiles(id),
  costo          numeric(12,2)
);

-- ---------------------------------------------------------------------
-- 4. INVENTARIO DE REACTIVOS Y MATERIALES
-- ---------------------------------------------------------------------
create table catalogo_reactivos (
  id                   uuid primary key default gen_random_uuid(),
  nombre               text not null,
  formula              text,
  cas                  text unique,
  pictogramas          text[] not null default '{}',         -- GHS01..GHS09
  palabra_senal        text check (palabra_senal in ('peligro','atencion')),
  url_sds              text,                                  -- ficha de seguridad (Storage o Drive)
  clase_almacenamiento text not null default 'general',
  unidad               unidad_medida not null default 'g',    -- unidad base del stock
  stock_minimo         numeric(12,3) not null default 0,
  es_controlado        boolean not null default false,
  notas                text,
  activo               boolean not null default true
);

-- Cada envase físico. Cantidades SIEMPRE en la unidad base del reactivo.
create table envases (
  id                uuid primary key default gen_random_uuid(),
  codigo            text not null unique
                    default ('ENV-' || upper(substr(gen_random_uuid()::text, 1, 8))),  -- para QR/código de barras
  reactivo_id       uuid not null references catalogo_reactivos(id),
  lote              text,
  proveedor         text,
  fecha_recepcion   date not null default current_date,
  fecha_apertura    date,
  fecha_caducidad   date,
  cantidad_inicial  numeric(12,3) not null check (cantidad_inicial >= 0),
  cantidad_actual   numeric(12,3) not null check (cantidad_actual >= 0),
  ubicacion_id      uuid references ubicaciones(id),
  estado            estado_envase not null default 'disponible'
);
create index on envases (reactivo_id);
create index on envases (fecha_caducidad);

create table catalogo_materiales (     -- vidriería, consumibles, EPP...
  id            uuid primary key default gen_random_uuid(),
  nombre        text not null,
  categoria     text,
  unidad        unidad_medida not null default 'unidad',
  stock_actual  numeric(12,3) not null default 0 check (stock_actual >= 0),
  stock_minimo  numeric(12,3) not null default 0,
  ubicacion_id  uuid references ubicaciones(id),
  activo        boolean not null default true
);

-- ---------------------------------------------------------------------
-- 5. DOCENCIA: PRÁCTICAS, GRUPOS Y SESIONES
-- ---------------------------------------------------------------------
create table practicas (               -- plantilla de práctica (guía)
  id                    uuid primary key default gen_random_uuid(),
  codigo                text unique,
  nombre                text not null,
  asignatura            text,
  programa              text,
  laboratorio_id        uuid references laboratorios(id),
  docente_responsable_id uuid references perfiles(id),
  duracion_min          int,
  guia_url              text,
  drive_file_id         text,          -- enlace con el formulario/guía en Drive
  activa                boolean not null default true
);

create table grupos (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null,
  periodo    text,                     -- p. ej. 2026-2
  docente_id uuid not null references perfiles(id)
);

create table grupo_estudiantes (
  grupo_id      uuid references grupos(id) on delete cascade,
  estudiante_id uuid references perfiles(id) on delete cascade,
  primary key (grupo_id, estudiante_id)
);

create or replace function es_miembro_grupo(g uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from grupo_estudiantes where grupo_id = g and estudiante_id = auth.uid())
$$;

create or replace function es_docente_grupo(g uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from grupos where id = g and docente_id = auth.uid())
$$;

create table sesiones_practica (       -- una programación concreta de una práctica
  id               uuid primary key default gen_random_uuid(),
  practica_id      uuid references practicas(id),
  docente_id       uuid not null references perfiles(id),
  laboratorio_id   uuid not null references laboratorios(id),
  grupo_id         uuid references grupos(id),
  num_estudiantes  int check (num_estudiantes >= 0),
  num_grupos_trabajo int check (num_grupos_trabajo >= 0),   -- 'mesas' del formulario
  inicio           timestamptz not null,
  fin              timestamptz not null,
  estado           estado_sesion not null default 'borrador',
  observaciones    text,
  origen           text not null default 'app' check (origen in ('app','excel_import')),
  drive_file_id    text,
  aprobado_por     uuid references perfiles(id),
  aprobado_en      timestamptz,
  creado_en        timestamptz not null default now(),
  check (fin > inicio)
);
create index on sesiones_practica (inicio);

create table sesion_reactivos (
  id                uuid primary key default gen_random_uuid(),
  sesion_id         uuid not null references sesiones_practica(id) on delete cascade,
  reactivo_id       uuid not null references catalogo_reactivos(id),
  cantidad_prevista numeric(12,3) check (cantidad_prevista >= 0),   -- puede venir vacía en el formulario
  cantidad_consumida numeric(12,3) check (cantidad_consumida >= 0),
  unidad            text,          -- unidad de las cantidades de esta línea (g, mL, frasco lavador...)
  concentracion     text,          -- p. ej. '2 M', 'concentrado', 'absoluto'
  notas             text,
  texto_original    text,          -- lo que escribió el docente, sin modificar
  unique (sesion_id, reactivo_id)
);

create table sesion_materiales (
  id                uuid primary key default gen_random_uuid(),
  sesion_id         uuid not null references sesiones_practica(id) on delete cascade,
  material_id       uuid not null references catalogo_materiales(id),
  cantidad_prevista numeric(12,3) check (cantidad_prevista >= 0),
  cantidad_consumida numeric(12,3) check (cantidad_consumida >= 0),
  notas             text,
  texto_original    text,
  unique (sesion_id, material_id)
);

-- ---------------------------------------------------------------------
-- 6. MOVIMIENTOS DE STOCK (el stock solo cambia por aquí)
-- ---------------------------------------------------------------------
create table movimientos_stock (
  id         uuid primary key default gen_random_uuid(),
  envase_id  uuid not null references envases(id),
  tipo       tipo_mov not null,
  cantidad   numeric(12,3) not null check (cantidad > 0),
  sesion_id  uuid references sesiones_practica(id),
  usuario_id uuid references perfiles(id) default auth.uid(),
  motivo     text,
  creado_en  timestamptz not null default now()
);

create table movimientos_material (
  id          uuid primary key default gen_random_uuid(),
  material_id uuid not null references catalogo_materiales(id),
  tipo        tipo_mov not null,
  cantidad    numeric(12,3) not null check (cantidad > 0),
  sesion_id   uuid references sesiones_practica(id),
  usuario_id  uuid references perfiles(id) default auth.uid(),
  motivo      text,
  creado_en   timestamptz not null default now()
);

create or replace function aplicar_mov_envase() returns trigger
language plpgsql security definer set search_path = public as $$
declare delta numeric; nueva numeric; actual numeric;
begin
  delta := case when new.tipo in ('entrada','ajuste_positivo') then new.cantidad else -new.cantidad end;
  select cantidad_actual into actual from envases where id = new.envase_id for update;
  if actual is null or actual + delta < 0 then
    raise exception 'Stock insuficiente en el envase % (disponible: %)', new.envase_id, coalesce(actual, 0);
  end if;
  update envases
     set cantidad_actual = cantidad_actual + delta,
         estado = case when cantidad_actual + delta <= 0 then 'agotado'::estado_envase
                       when estado = 'agotado' then 'disponible'::estado_envase
                       when new.tipo = 'consumo' then 'en_uso'::estado_envase
                       else estado end,
         fecha_apertura = case when new.tipo = 'consumo' then coalesce(fecha_apertura, current_date)
                               else fecha_apertura end
   where id = new.envase_id
   returning cantidad_actual into nueva;
  if nueva is null or nueva < 0 then
    raise exception 'Stock insuficiente en el envase %', new.envase_id;
  end if;
  return new;
end $$;

create trigger trg_mov_envase after insert on movimientos_stock
  for each row execute function aplicar_mov_envase();

create or replace function aplicar_mov_material() returns trigger
language plpgsql security definer set search_path = public as $$
declare delta numeric; nueva numeric; actual numeric;
begin
  delta := case when new.tipo in ('entrada','ajuste_positivo') then new.cantidad else -new.cantidad end;
  select stock_actual into actual from catalogo_materiales where id = new.material_id for update;
  if actual is null or actual + delta < 0 then
    raise exception 'Stock insuficiente del material % (disponible: %)', new.material_id, coalesce(actual, 0);
  end if;
  update catalogo_materiales set stock_actual = stock_actual + delta
   where id = new.material_id returning stock_actual into nueva;
  if nueva is null or nueva < 0 then
    raise exception 'Stock insuficiente del material %', new.material_id;
  end if;
  return new;
end $$;

create trigger trg_mov_material after insert on movimientos_material
  for each row execute function aplicar_mov_material();

-- ---------------------------------------------------------------------
-- 7. RESERVAS (sin solapes garantizado por la base de datos)
-- ---------------------------------------------------------------------
create table reservas (
  id             uuid primary key default gen_random_uuid(),
  equipo_id      uuid references equipos(id),
  laboratorio_id uuid references laboratorios(id),
  sesion_id      uuid references sesiones_practica(id) on delete set null,
  solicitante_id uuid not null references perfiles(id) default auth.uid(),
  periodo        tstzrange not null,
  estado         estado_reserva not null default 'solicitada',
  notas          text,
  creado_en      timestamptz not null default now(),
  constraint reservas_un_recurso
    check ((equipo_id is not null)::int + (laboratorio_id is not null)::int = 1),
  constraint reservas_periodo_valido check (not isempty(periodo)),
  -- Dos reservas activas no pueden solapar el mismo equipo / laboratorio.
  -- Error al violarse: SQLSTATE 23P01 (mostrar "horario no disponible").
  constraint reservas_sin_solape_equipo
    exclude using gist (equipo_id with =, periodo with &&)
    where (equipo_id is not null and estado in ('solicitada','aprobada')),
  constraint reservas_sin_solape_lab
    exclude using gist (laboratorio_id with =, periodo with &&)
    where (laboratorio_id is not null and estado in ('solicitada','aprobada'))
);

-- Impedir reservar equipos no operativos o no reservables
create or replace function validar_reserva() returns trigger
language plpgsql security definer set search_path = public as $$
declare ok boolean;
begin
  if new.equipo_id is not null then
    select (estado = 'operativo' and reservable) into ok from equipos where id = new.equipo_id;
    if not coalesce(ok, false) then
      raise exception 'El equipo no está disponible para reserva';
    end if;
  end if;
  return new;
end $$;

create trigger trg_validar_reserva before insert on reservas
  for each row execute function validar_reserva();

-- ---------------------------------------------------------------------
-- 8. INCIDENCIAS, AUDITORÍA E IMPORTACIÓN DE FORMULARIOS
-- ---------------------------------------------------------------------
create table incidencias (
  id              uuid primary key default gen_random_uuid(),
  reportado_por   uuid not null references perfiles(id) default auth.uid(),
  laboratorio_id  uuid references laboratorios(id),
  equipo_id       uuid references equipos(id),
  envase_id       uuid references envases(id),
  tipo            text not null default 'general'
                  check (tipo in ('general','averia','seguridad','derrame','material','otro')),
  severidad       severidad not null default 'media',
  descripcion     text not null,
  foto_path       text,
  estado          estado_incidencia not null default 'abierta',
  asignado_a      uuid references perfiles(id),
  resolucion      text,
  creado_en       timestamptz not null default now(),
  resuelto_en     timestamptz
);

create table auditoria (
  id          bigint generated always as identity primary key,
  tabla       text not null,
  registro_id uuid,
  accion      text not null,
  usuario_id  uuid,
  datos       jsonb,
  creado_en   timestamptz not null default now()
);

-- Puente para los formularios Excel de Drive (se integra en la siguiente fase).
-- Cada archivo procesado se guarda aquí tal cual (payload) antes de crear la sesión.
create table importaciones_formularios (
  id             uuid primary key default gen_random_uuid(),
  nombre_archivo text not null,
  drive_file_id  text,
  drive_url      text,
  subido_por     uuid references perfiles(id) default auth.uid(),
  estado         estado_importacion not null default 'pendiente',
  payload        jsonb,                -- contenido leído del Excel
  errores        jsonb,
  sesion_id      uuid references sesiones_practica(id),
  creado_en      timestamptz not null default now(),
  procesado_en   timestamptz
);

create or replace function registrar_auditoria() returns trigger
language plpgsql security definer set search_path = public as $$
declare d jsonb;
begin
  d := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  insert into auditoria (tabla, registro_id, accion, usuario_id, datos)
  values (tg_table_name, nullif(d->>'id','')::uuid, tg_op, auth.uid(), d);
  return null;
end $$;

do $$
declare t text;
begin
  foreach t in array array['perfiles','equipos','catalogo_reactivos','envases',
    'catalogo_materiales','sesiones_practica','reservas','incidencias'] loop
    execute format('create trigger aud_%1$s after insert or update or delete on %1$I
                    for each row execute function registrar_auditoria()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 9. REGLAS DE NEGOCIO PROTEGIDAS POR TRIGGER
-- ---------------------------------------------------------------------
-- El docente solo puede mover una sesión entre borrador, solicitada y cancelada.
-- Aprobar / rechazar / finalizar es del personal técnico.
create or replace function proteger_sesion() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not es_personal() then
    if old.estado not in ('borrador','solicitada') and new.estado <> 'cancelada' then
      raise exception 'La sesión ya fue procesada y no puede modificarse';
    end if;
    if new.estado not in ('borrador','solicitada','cancelada') then
      raise exception 'Solo el personal técnico puede aprobar, rechazar o finalizar';
    end if;
    new.aprobado_por := old.aprobado_por;
    new.aprobado_en  := old.aprobado_en;
    new.docente_id   := old.docente_id;
  end if;
  if new.estado in ('aprobada','rechazada') and new.estado is distinct from old.estado then
    new.aprobado_por := auth.uid();
    new.aprobado_en  := now();
  end if;
  return new;
end $$;

create trigger trg_proteger_sesion before update on sesiones_practica
  for each row execute function proteger_sesion();

-- Cuando la sesión ya no es editable, el docente solo puede registrar lo consumido.
create or replace function proteger_items() returns trigger
language plpgsql security definer set search_path = public as $$
declare est estado_sesion;
begin
  if auth.uid() is not null and not es_personal() then
    select estado into est from sesiones_practica where id = new.sesion_id;
    new.sesion_id := old.sesion_id;
    if est not in ('borrador','solicitada') then
      new.cantidad_prevista := old.cantidad_prevista;
    end if;
  end if;
  return new;
end $$;

create trigger trg_proteger_items_r before update on sesion_reactivos
  for each row execute function proteger_items();
create trigger trg_proteger_items_m before update on sesion_materiales
  for each row execute function proteger_items();

-- ---------------------------------------------------------------------
-- 10. SEGURIDAD A NIVEL DE FILA (RLS)
-- ---------------------------------------------------------------------
-- Catálogos: lectura para todo usuario autenticado, escritura solo personal técnico
do $$
declare t text;
begin
  foreach t in array array['laboratorios','ubicaciones','equipos','catalogo_reactivos','catalogo_materiales'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy lectura_autenticados on %I for select to authenticated using (true)', t);
    execute format('create policy gestion_personal on %I for all to authenticated
                    using (es_personal()) with check (es_personal())', t);
  end loop;
end $$;

-- Tablas solo para personal técnico / admin
do $$
declare t text;
begin
  foreach t in array array['mantenimientos','movimientos_stock','movimientos_material'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy solo_personal on %I for all to authenticated
                    using (es_personal()) with check (es_personal())', t);
  end loop;
end $$;

-- perfiles
alter table perfiles enable row level security;
create policy perfiles_propio     on perfiles for select to authenticated using (id = auth.uid());
create policy perfiles_personal   on perfiles for select to authenticated using (es_personal());
create policy perfiles_mis_alumnos on perfiles for select to authenticated using (
  exists (select 1 from grupo_estudiantes ge
          where ge.estudiante_id = perfiles.id and es_docente_grupo(ge.grupo_id)));
create policy perfiles_editar_propio on perfiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy perfiles_admin      on perfiles for all to authenticated
  using (es_admin()) with check (es_admin());

-- envases: lectura docentes y personal; escritura personal
alter table envases enable row level security;
create policy envases_lectura on envases for select to authenticated
  using (rol_actual() in ('docente','tecnico','admin'));
create policy envases_gestion on envases for all to authenticated
  using (es_personal()) with check (es_personal());

-- prácticas
alter table practicas enable row level security;
create policy practicas_lectura on practicas for select to authenticated using (activa or es_personal());
create policy practicas_docente_ins on practicas for insert to authenticated
  with check (rol_actual() = 'docente' and docente_responsable_id = auth.uid());
create policy practicas_docente_upd on practicas for update to authenticated
  using (docente_responsable_id = auth.uid()) with check (docente_responsable_id = auth.uid());
create policy practicas_personal on practicas for all to authenticated
  using (es_personal()) with check (es_personal());

-- grupos
alter table grupos enable row level security;
create policy grupos_lectura on grupos for select to authenticated
  using (docente_id = auth.uid() or es_miembro_grupo(id) or es_personal());
create policy grupos_docente on grupos for all to authenticated
  using (docente_id = auth.uid()) with check (docente_id = auth.uid());
create policy grupos_personal on grupos for all to authenticated
  using (es_personal()) with check (es_personal());

alter table grupo_estudiantes enable row level security;
create policy ge_lectura on grupo_estudiantes for select to authenticated
  using (estudiante_id = auth.uid() or es_docente_grupo(grupo_id) or es_personal());
create policy ge_docente on grupo_estudiantes for all to authenticated
  using (es_docente_grupo(grupo_id)) with check (es_docente_grupo(grupo_id));
create policy ge_personal on grupo_estudiantes for all to authenticated
  using (es_personal()) with check (es_personal());

-- sesiones de práctica
alter table sesiones_practica enable row level security;
create policy ses_lectura on sesiones_practica for select to authenticated using (
  docente_id = auth.uid() or es_personal()
  or (estado in ('aprobada','finalizada') and grupo_id is not null and es_miembro_grupo(grupo_id)));
create policy ses_docente_ins on sesiones_practica for insert to authenticated
  with check (rol_actual() = 'docente' and docente_id = auth.uid()
              and estado in ('borrador','solicitada'));
create policy ses_docente_upd on sesiones_practica for update to authenticated
  using (docente_id = auth.uid()) with check (docente_id = auth.uid());
create policy ses_personal on sesiones_practica for all to authenticated
  using (es_personal()) with check (es_personal());

-- ítems de sesión (reactivos y materiales)
do $$
declare t text;
begin
  foreach t in array array['sesion_reactivos','sesion_materiales'] loop
    execute format('alter table %I enable row level security', t);
    -- Lee quien puede leer la sesión (la RLS de sesiones se aplica en la subconsulta)
    execute format('create policy items_lectura on %I for select to authenticated
      using (exists (select 1 from sesiones_practica s where s.id = sesion_id))', t);
    -- El docente edita lo previsto mientras la sesión esté en borrador/solicitada
    execute format('create policy items_docente_ins on %I for insert to authenticated
      with check (exists (select 1 from sesiones_practica s where s.id = sesion_id
        and s.docente_id = auth.uid() and s.estado in (''borrador'',''solicitada'')))', t);
    execute format('create policy items_docente_del on %I for delete to authenticated
      using (exists (select 1 from sesiones_practica s where s.id = sesion_id
        and s.docente_id = auth.uid() and s.estado in (''borrador'',''solicitada'')))', t);
    -- Y registra el consumo real cuando la sesión está aprobada o finalizada
    execute format('create policy items_docente_upd on %I for update to authenticated
      using (exists (select 1 from sesiones_practica s where s.id = sesion_id
        and s.docente_id = auth.uid()
        and s.estado in (''borrador'',''solicitada'',''aprobada'',''finalizada'')))', t);
    execute format('create policy items_personal on %I for all to authenticated
      using (es_personal()) with check (es_personal())', t);
  end loop;
end $$;

-- reservas
alter table reservas enable row level security;
create policy res_lectura on reservas for select to authenticated using (
  solicitante_id = auth.uid() or es_personal()
  or exists (select 1 from sesiones_practica s where s.id = sesion_id and s.docente_id = auth.uid()));
create policy res_docente_ins on reservas for insert to authenticated
  with check (rol_actual() = 'docente' and solicitante_id = auth.uid());
-- El estudiante solo reserva equipos dentro de una sesión aprobada de su grupo
create policy res_estudiante_ins on reservas for insert to authenticated
  with check (
    rol_actual() = 'estudiante' and solicitante_id = auth.uid()
    and equipo_id is not null and sesion_id is not null
    and exists (select 1 from sesiones_practica s
                where s.id = sesion_id and s.estado = 'aprobada'
                  and s.grupo_id is not null and es_miembro_grupo(s.grupo_id)));
create policy res_cancelar_propia on reservas for update to authenticated
  using (solicitante_id = auth.uid() and estado in ('solicitada','aprobada'))
  with check (solicitante_id = auth.uid() and estado = 'cancelada');
create policy res_personal on reservas for all to authenticated
  using (es_personal()) with check (es_personal());

-- Vista pública de disponibilidad: muestra "ocupado" sin revelar quién reservó
create view v_disponibilidad with (security_invoker = false) as
  select id, equipo_id, laboratorio_id, periodo, estado
  from reservas where estado in ('solicitada','aprobada');

-- incidencias
alter table incidencias enable row level security;
create policy inc_lectura on incidencias for select to authenticated
  using (reportado_por = auth.uid() or es_personal());
create policy inc_crear on incidencias for insert to authenticated
  with check (reportado_por = auth.uid());
create policy inc_personal on incidencias for all to authenticated
  using (es_personal()) with check (es_personal());

-- auditoría: solo lectura para admin (las inserciones las hace el trigger)
alter table auditoria enable row level security;
create policy aud_admin on auditoria for select to authenticated using (es_admin());

-- importaciones de formularios
alter table importaciones_formularios enable row level security;
create policy imp_propias on importaciones_formularios for select to authenticated
  using (subido_por = auth.uid() or es_personal());
create policy imp_crear on importaciones_formularios for insert to authenticated
  with check (rol_actual() in ('docente','tecnico','admin') and subido_por = auth.uid());
create policy imp_personal on importaciones_formularios for update to authenticated
  using (es_personal()) with check (es_personal());

-- ---------------------------------------------------------------------
-- 11. MÓDULO DE INFORMES (vistas; respetan la RLS de quien consulta)
-- ---------------------------------------------------------------------
create view v_stock_reactivos with (security_invoker = true) as
select r.id as reactivo_id, r.nombre, r.cas, r.unidad, r.stock_minimo,
       coalesce(sum(e.cantidad_actual) filter (where e.estado in ('disponible','en_uso')), 0) as stock_total,
       coalesce(sum(e.cantidad_actual) filter (where e.estado in ('disponible','en_uso')), 0) < r.stock_minimo as bajo_minimo
from catalogo_reactivos r
left join envases e on e.reactivo_id = r.id
where r.activo
group by r.id;

create view v_reactivos_por_vencer with (security_invoker = true) as
select e.id as envase_id, e.codigo, r.nombre, r.cas, e.lote, e.cantidad_actual, r.unidad,
       e.fecha_caducidad, (e.fecha_caducidad - current_date) as dias_restantes, u.nombre as ubicacion
from envases e
join catalogo_reactivos r on r.id = e.reactivo_id
left join ubicaciones u on u.id = e.ubicacion_id
where e.estado in ('disponible','en_uso') and e.fecha_caducidad <= current_date + 60
order by e.fecha_caducidad;

create view v_materiales_bajo_minimo with (security_invoker = true) as
select id, nombre, categoria, unidad, stock_actual, stock_minimo
from catalogo_materiales where activo and stock_actual < stock_minimo;

create view v_consumo_por_practica with (security_invoker = true) as
select s.id as sesion_id, p.nombre as practica, s.inicio::date as fecha, l.nombre as laboratorio,
       r.nombre as reactivo, sr.concentracion, coalesce(sr.unidad, r.unidad::text) as unidad,
       sr.cantidad_prevista, sr.cantidad_consumida,
       (sr.cantidad_consumida - sr.cantidad_prevista) as desviacion
from sesion_reactivos sr
join sesiones_practica s on s.id = sr.sesion_id
left join practicas p on p.id = s.practica_id
join laboratorios l on l.id = s.laboratorio_id
join catalogo_reactivos r on r.id = sr.reactivo_id;

create view v_consumo_mensual_reactivos with (security_invoker = true) as
select date_trunc('month', s.inicio)::date as mes, r.nombre as reactivo,
       coalesce(sr.unidad, r.unidad::text) as unidad,
       sum(sr.cantidad_consumida) as total_consumido
from sesion_reactivos sr
join sesiones_practica s on s.id = sr.sesion_id
join catalogo_reactivos r on r.id = sr.reactivo_id
where sr.cantidad_consumida is not null
group by 1, 2, 3;

create view v_equipos_mantenimiento with (security_invoker = true) as
select id, codigo, nombre, laboratorio_id, estado, proxima_calibracion, proximo_mantenimiento,
       least(proxima_calibracion, proximo_mantenimiento) as fecha_limite
from equipos
where estado <> 'baja'
  and (proxima_calibracion <= current_date + 30 or proximo_mantenimiento <= current_date + 30);

create view v_uso_laboratorios with (security_invoker = true) as
select date_trunc('month', lower(rs.periodo))::date as mes,
       coalesce(l.nombre, l2.nombre) as laboratorio,
       count(*) as reservas,
       round(sum(extract(epoch from upper(rs.periodo) - lower(rs.periodo)) / 3600)::numeric, 1) as horas_reservadas
from reservas rs
left join laboratorios l on l.id = rs.laboratorio_id
left join equipos eq on eq.id = rs.equipo_id
left join laboratorios l2 on l2.id = eq.laboratorio_id
where rs.estado = 'aprobada'
group by 1, 2;

create view v_incidencias_resumen with (security_invoker = true) as
select date_trunc('month', creado_en)::date as mes, tipo, severidad, estado, count(*) as total
from incidencias group by 1, 2, 3, 4;

-- Alerta (no bloqueante): envases guardados en una ubicación de otra clase de almacenamiento
create view v_alertas_almacenamiento with (security_invoker = true) as
select e.codigo, r.nombre as reactivo, r.clase_almacenamiento as clase_reactivo,
       u.nombre as ubicacion, u.clase_almacenamiento as clase_ubicacion
from envases e
join catalogo_reactivos r on r.id = e.reactivo_id
join ubicaciones u on u.id = e.ubicacion_id
where e.estado in ('disponible','en_uso')
  and u.clase_almacenamiento <> 'general'
  and u.clase_almacenamiento <> r.clase_almacenamiento;

-- ---------------------------------------------------------------------
-- 12. TAREAS PROGRAMADAS
-- ---------------------------------------------------------------------
create or replace function marcar_vencidos() returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  update envases set estado = 'vencido'
   where estado in ('disponible','en_uso') and fecha_caducidad < current_date;
  get diagnostics n = row_count;
  return n;
end $$;

-- Consulta mínima para mantener activo el proyecto (plan gratuito se pausa tras 7 días sin uso)
create or replace function ping() returns timestamptz
language sql stable as $$ select now() $$;

-- Con la extensión pg_cron habilitada (Database > Extensions):
-- select cron.schedule('marcar-vencidos', '0 6 * * *', $$select public.marcar_vencidos()$$);

-- ---------------------------------------------------------------------
-- 13. PERMISOS EXPLÍCITOS (necesarios en Supabase desde oct-2026)
-- ---------------------------------------------------------------------
revoke all on all tables in schema public from anon;
revoke all on all functions in schema public from anon;

grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant execute on all functions in schema public to authenticated;
-- (RLS decide qué filas puede tocar cada rol; los GRANT solo abren la puerta a la tabla)

-- ---------------------------------------------------------------------
-- 14. PRIMER ADMINISTRADOR
-- ---------------------------------------------------------------------
-- 1) Inicie sesión una vez con su correo para que se cree su perfil.
-- 2) Ejecute (desde el SQL Editor):
--    update perfiles set rol = 'admin' where email = 'su-correo@universidad.edu';
