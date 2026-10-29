-- =====================================================================
-- GesLab · 12 · Modelo de datos extendido para informes
-- Fase 1 (F1) de la hoja de ruta.
-- Requiere 01–11. Re-ejecutable.
--
-- Añade: proveedores, lotes, ubicaciones físicas jerárquicas,
--        ciclo de vida de equipos y materiales, mantenimientos,
--        documentos adjuntos (MSDS, manuales, certificados),
--        campos químicos CAS/GHS en catalogo_reactivos.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. PROVEEDORES
-- ---------------------------------------------------------------------
create table if not exists proveedores (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  nit         text,
  contacto    text,
  email       text,
  telefono    text,
  pais        text,
  notas       text,
  activo      boolean not null default true,
  creado_en   timestamptz not null default now()
);
create unique index if not exists proveedores_nombre_key on proveedores (lower(nombre));

alter table proveedores enable row level security;
drop policy if exists prov_lectura on proveedores;
create policy prov_lectura on proveedores for select to authenticated using (true);
drop policy if exists prov_personal on proveedores;
create policy prov_personal on proveedores for all to authenticated
  using (es_personal()) with check (es_personal());

-- ---------------------------------------------------------------------
-- 2. UBICACIONES FÍSICAS JERÁRQUICAS
--    Reemplaza/complementa la tabla 'ubicaciones' existente sin romperla.
-- ---------------------------------------------------------------------
create table if not exists ubicaciones_fisicas (
  id          uuid primary key default gen_random_uuid(),
  campus_id   uuid not null references campus(id) on delete cascade,
  nombre      text not null,
  tipo        text not null check (tipo in ('almacen','sala','armario','estante','anaquel','nevera','vitrina','otro')),
  padre_id    uuid references ubicaciones_fisicas(id) on delete set null,
  descripcion text,
  activo      boolean not null default true,
  creado_en   timestamptz not null default now(),
  unique (campus_id, padre_id, nombre)
);
create index if not exists ubicfis_campus_idx on ubicaciones_fisicas (campus_id);
create index if not exists ubicfis_padre_idx on ubicaciones_fisicas (padre_id);

alter table ubicaciones_fisicas enable row level security;
drop policy if exists ubicfis_lectura on ubicaciones_fisicas;
create policy ubicfis_lectura on ubicaciones_fisicas for select to authenticated using (true);
drop policy if exists ubicfis_personal on ubicaciones_fisicas;
create policy ubicfis_personal on ubicaciones_fisicas for all to authenticated
  using (es_personal()) with check (es_personal());

-- Vista recursiva: ruta jerárquica legible ("Turbo / Almacén A / Estante 3")
create or replace view v_ubicacion_ruta with (security_invoker = true) as
with recursive ruta as (
  select u.id, u.nombre, u.tipo, u.campus_id, u.padre_id,
         (select nombre from campus where id = u.campus_id) || ' / ' || u.nombre as ruta,
         1 as nivel
  from ubicaciones_fisicas u where u.padre_id is null
  union all
  select u.id, u.nombre, u.tipo, u.campus_id, u.padre_id,
         r.ruta || ' / ' || u.nombre, r.nivel + 1
  from ubicaciones_fisicas u join ruta r on u.padre_id = r.id
)
select * from ruta;
grant select on v_ubicacion_ruta to authenticated;

-- ---------------------------------------------------------------------
-- 3. CAMPOS QUÍMICOS EXTENDIDOS EN catalogo_reactivos
--    GHS pictogramas, frases H/P, MSDS, controlado, UN, ADR
-- ---------------------------------------------------------------------
alter table catalogo_reactivos
  add column if not exists peso_molecular numeric(10,3),
  add column if not exists densidad       numeric(10,3),
  add column if not exists frases_h       text[] not null default '{}',
  add column if not exists frases_p       text[] not null default '{}',
  add column if not exists numero_un      text,
  add column if not exists clase_adr      text,
  add column if not exists msds_vencimiento date,
  add column if not exists ubicacion_fisica_id uuid references ubicaciones_fisicas(id) on delete set null;
-- pictogramas, palabra_senal, url_sds, clase_almacenamiento, es_controlado ya existen en schema_labs.sql

create index if not exists catreac_ubicacion_idx on catalogo_reactivos (ubicacion_fisica_id);
create index if not exists catreac_cas_idx on catalogo_reactivos (cas) where cas is not null;
create index if not exists catreac_controlado_idx on catalogo_reactivos (es_controlado) where es_controlado;
create index if not exists catreac_ghs_gin on catalogo_reactivos using gin (pictogramas);

-- ---------------------------------------------------------------------
-- 4. LOTES DE ENVASES
-- ---------------------------------------------------------------------
create table if not exists lotes_envases (
  id              uuid primary key default gen_random_uuid(),
  envase_id       uuid not null references envases(id) on delete cascade,
  proveedor_id    uuid references proveedores(id) on delete set null,
  numero_lote     text,
  orden_compra    text,
  fecha_compra    date,
  fecha_recepcion date,
  precio_unitario numeric(12,2),
  moneda          text default 'COP',
  factura_url     text,
  recibido_por    uuid references perfiles(id),
  notas           text,
  creado_en       timestamptz not null default now()
);
create index if not exists lotes_envase_idx on lotes_envases (envase_id);
create index if not exists lotes_prov_idx on lotes_envases (proveedor_id);

alter table lotes_envases enable row level security;
drop policy if exists lotes_lectura on lotes_envases;
create policy lotes_lectura on lotes_envases for select to authenticated using (true);
drop policy if exists lotes_personal on lotes_envases;
create policy lotes_personal on lotes_envases for all to authenticated
  using (es_personal()) with check (es_personal());

-- ---------------------------------------------------------------------
-- 5. CICLO DE VIDA DE EQUIPOS
-- ---------------------------------------------------------------------
create table if not exists equipos_ciclo_vida (
  id          uuid primary key default gen_random_uuid(),
  equipo_id   uuid not null references equipos(id) on delete cascade,
  evento      text not null check (evento in ('alta','asignacion','mantenimiento','reparacion','calibracion','baja','traslado')),
  fecha       timestamptz not null default now(),
  usuario_id  uuid references perfiles(id) default auth.uid(),
  descripcion text,
  costo       numeric(12,2),
  moneda      text default 'COP',
  campus_destino_id uuid references campus(id) on delete set null,
  documento_url text
);
create index if not exists ecv_equipo_fecha_idx on equipos_ciclo_vida (equipo_id, fecha desc);

alter table equipos_ciclo_vida enable row level security;
drop policy if exists ecv_lectura on equipos_ciclo_vida;
create policy ecv_lectura on equipos_ciclo_vida for select to authenticated using (true);
drop policy if exists ecv_personal on equipos_ciclo_vida;
create policy ecv_personal on equipos_ciclo_vida for all to authenticated
  using (es_personal()) with check (es_personal());

-- ---------------------------------------------------------------------
-- 6. CICLO DE VIDA DE MATERIALES (vidriería, consumibles)
-- ---------------------------------------------------------------------
create table if not exists materiales_ciclo_vida (
  id            uuid primary key default gen_random_uuid(),
  material_id   uuid not null references catalogo_materiales(id),
  campus_id     uuid not null references campus(id),
  evento        text not null check (evento in ('ingreso','rotura','merma','descarte','auditoria','traslado','prestamo','devolucion')),
  cantidad      int not null check (cantidad > 0),
  fecha         timestamptz not null default now(),
  usuario_id    uuid references perfiles(id) default auth.uid(),
  sesion_id     uuid references sesiones_practica(id) on delete set null,
  proveedor_id  uuid references proveedores(id) on delete set null,
  ubicacion_fisica_id uuid references ubicaciones_fisicas(id) on delete set null,
  motivo        text,
  evidencia_url text
);
create index if not exists mcv_mat_campus_idx on materiales_ciclo_vida (material_id, campus_id, fecha desc);
create index if not exists mcv_evento_idx on materiales_ciclo_vida (evento, fecha desc);
create index if not exists mcv_sesion_idx on materiales_ciclo_vida (sesion_id) where sesion_id is not null;

alter table materiales_ciclo_vida enable row level security;
drop policy if exists mcv_lectura on materiales_ciclo_vida;
create policy mcv_lectura on materiales_ciclo_vida for select to authenticated using (true);
drop policy if exists mcv_personal on materiales_ciclo_vida;
create policy mcv_personal on materiales_ciclo_vida for all to authenticated
  using (es_personal()) with check (es_personal());

-- ---------------------------------------------------------------------
-- 7. MANTENIMIENTOS (planificados + ejecutados)
-- ---------------------------------------------------------------------
create table if not exists mantenimientos_programados (
  id              uuid primary key default gen_random_uuid(),
  equipo_id       uuid not null references equipos(id) on delete cascade,
  tipo            text not null check (tipo in ('preventivo','correctivo','calibracion')),
  fecha_prog      date not null,
  fecha_real      date,
  tecnico_id      uuid references perfiles(id),
  estado          text not null default 'programado' check (estado in ('programado','en_curso','completado','vencido','cancelado')),
  descripcion     text,
  costo           numeric(12,2),
  prox_mantenimiento date,
  creado_en       timestamptz not null default now()
);
create index if not exists mprog_equipo_idx on mantenimientos_programados (equipo_id, fecha_prog);
create index if not exists mprog_estado_idx on mantenimientos_programados (estado);

alter table mantenimientos_programados enable row level security;
drop policy if exists mprog_lectura on mantenimientos_programados;
create policy mprog_lectura on mantenimientos_programados for select to authenticated using (true);
drop policy if exists mprog_personal on mantenimientos_programados;
create policy mprog_personal on mantenimientos_programados for all to authenticated
  using (es_personal()) with check (es_personal());

-- ---------------------------------------------------------------------
-- 8. DOCUMENTOS ADJUNTOS (MSDS, manuales, certificados, fotos)
-- ---------------------------------------------------------------------
create table if not exists documentos (
  id          uuid primary key default gen_random_uuid(),
  tipo        text not null check (tipo in ('msds','certificado','manual','factura','foto','protocolo','otro')),
  entidad     text not null check (entidad in ('reactivo','material','equipo','lote','sesion','envase','mantenimiento','incidencia')),
  entidad_id  uuid not null,
  nombre      text not null,
  url         text not null,
  mime        text,
  size_kb     int,
  hash_sha256 text,
  version     text,
  vencimiento date,
  creado_por  uuid references perfiles(id) default auth.uid(),
  creado_en   timestamptz not null default now()
);
create index if not exists doc_entidad_idx on documentos (entidad, entidad_id);
create index if not exists doc_tipo_idx on documentos (tipo);
create index if not exists doc_vencimiento_idx on documentos (vencimiento) where vencimiento is not null;

alter table documentos enable row level security;
drop policy if exists doc_lectura on documentos;
create policy doc_lectura on documentos for select to authenticated using (true);
drop policy if exists doc_personal on documentos;
create policy doc_personal on documentos for all to authenticated
  using (es_personal()) with check (es_personal());

-- ---------------------------------------------------------------------
-- 9. VISTAS DE RESUMEN QUÍMICO (consulta rápida en UI)
-- ---------------------------------------------------------------------
create or replace view v_reactivo_resumen_quimico with (security_invoker = true) as
select cr.id,
       cr.nombre, cr.cas, cr.formula, cr.unidad::text as unidad,
       cr.pictogramas, cr.palabra_senal, cr.frases_h, cr.frases_p,
       cr.clase_almacenamiento, cr.es_controlado, cr.numero_un, cr.clase_adr,
       cr.url_sds, cr.msds_vencimiento,
       cr.msds_vencimiento is not null and cr.msds_vencimiento <= current_date as msds_vencida,
       cr.url_sds is null as msds_faltante,
       cr.stock_minimo, cr.activo,
       (select ruta from v_ubicacion_ruta where id = cr.ubicacion_fisica_id) as ubicacion_ruta
from catalogo_reactivos cr;
grant select on v_reactivo_resumen_quimico to authenticated;

notify pgrst, 'reload schema';
