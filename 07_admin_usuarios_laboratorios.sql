-- =====================================================================
-- GesLab · 07 · Administración de usuarios y laboratorios
-- Requiere 04 (campus). Re-ejecutable.
-- Roles de la app: docente, tecnico y admin (líder de laboratorios).
-- El valor «estudiante» queda como «sin rol asignado»: la persona entra,
-- pero no ve nada hasta que un administrador le asigne un rol.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. LABORATORIOS POR SEDE
-- ---------------------------------------------------------------------
insert into laboratorios (nombre, campus_id)
select c.nombre || ' · ' || v.n, c.id
from campus c
join (values
  ('Turbo', '101'), ('Turbo', '102'), ('Turbo', '103'), ('Turbo', '104'), ('Turbo', '105'),
  ('Apartadó', '101'), ('Apartadó', '102'), ('Apartadó', '103'),
  ('Carepa', '101'), ('Carepa', '102'), ('Carepa', '103')
) as v(campus, n) on v.campus = c.nombre
on conflict (nombre) do update set campus_id = excluded.campus_id;

-- ---------------------------------------------------------------------
-- 2. INVITACIONES: asignar el rol por correo antes de que la persona exista
-- Cuando se crea la cuenta (Authentication → Add user), recibe ese rol.
-- ---------------------------------------------------------------------
create table if not exists invitaciones (
  id         uuid primary key default gen_random_uuid(),
  email      text not null,
  rol        rol_usuario not null check (rol in ('docente', 'tecnico', 'admin')),
  nombre     text,
  creado_por uuid references perfiles(id) default auth.uid(),
  creado_en  timestamptz not null default now(),
  usada_en   timestamptz
);
create unique index if not exists invitaciones_email_idx on invitaciones (lower(email));
alter table invitaciones enable row level security;
drop policy if exists inv_admin on invitaciones;
create policy inv_admin on invitaciones for all to authenticated
  using (es_admin()) with check (es_admin());

create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_inv invitaciones;
begin
  select * into v_inv from invitaciones where lower(email) = lower(new.email) and usada_en is null;
  insert into perfiles (id, email, nombre, rol)
  values (new.id, new.email,
          coalesce(nullif(new.raw_user_meta_data->>'full_name', ''), nullif(new.raw_user_meta_data->>'name', ''), v_inv.nombre, ''),
          coalesce(v_inv.rol, 'estudiante'));
  if v_inv.id is not null then
    update invitaciones set usada_en = now() where id = v_inv.id;
  end if;
  return new;
end $$;

-- Invitar o cambiar el rol de alguien por su correo
create or replace function invitar_usuario(p_email text, p_rol rol_usuario, p_nombre text default null) returns text
language plpgsql security definer set search_path = public as $$
declare v_email text := lower(trim(p_email)); v_id uuid;
begin
  if not es_admin() then raise exception 'Solo un administrador puede asignar roles'; end if;
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then raise exception 'Correo no válido'; end if;
  if p_rol not in ('docente', 'tecnico', 'admin') then raise exception 'Rol no válido'; end if;
  select id into v_id from perfiles where lower(email) = v_email;
  if v_id is not null then
    update perfiles set rol = p_rol, activo = true,
           nombre = case when coalesce(trim(nombre), '') = '' then coalesce(nullif(trim(p_nombre), ''), nombre) else nombre end
     where id = v_id;
    return 'actualizado';
  end if;
  insert into invitaciones (email, rol, nombre) values (v_email, p_rol, nullif(trim(p_nombre), ''))
  on conflict ((lower(email))) do update set rol = excluded.rol, nombre = excluded.nombre, usada_en = null;
  return 'invitado';
end $$;
revoke execute on function invitar_usuario(text, rol_usuario, text) from public, anon;
grant execute on function invitar_usuario(text, rol_usuario, text) to authenticated;

-- ---------------------------------------------------------------------
-- 3. SIEMPRE DEBE QUEDAR AL MENOS UN ADMINISTRADOR ACTIVO
-- ---------------------------------------------------------------------
create or replace function proteger_ultimo_admin() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.rol = 'admin' and old.activo and (new.rol <> 'admin' or not new.activo) then
    if not exists (select 1 from perfiles where rol = 'admin' and activo and id <> old.id) then
      raise exception 'Debe quedar al menos un administrador activo';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists trg_ultimo_admin on perfiles;
create trigger trg_ultimo_admin before update on perfiles
  for each row execute function proteger_ultimo_admin();

notify pgrst, 'reload schema';
