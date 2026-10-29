-- =====================================================================
-- GesLab · 08 · Solo correos institucionales (@udea.edu.co)
-- Requiere 07 (tabla invitaciones). Re-ejecutable.
-- Las personas con una invitación vigente (Admin → Asignar rol por correo)
-- pueden registrarse con cualquier correo; el resto, solo @udea.edu.co.
-- Las cuentas que ya existen no se tocan.
-- =====================================================================
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_inv invitaciones;
begin
  select * into v_inv from invitaciones where lower(email) = lower(new.email) and usada_en is null;
  if v_inv.id is null and lower(new.email) !~ '@([a-z0-9-]+\.)*udea\.edu\.co$' then
    raise exception 'Solo se permiten correos institucionales @udea.edu.co';
  end if;
  insert into perfiles (id, email, nombre, rol)
  values (new.id, new.email,
          coalesce(nullif(new.raw_user_meta_data->>'full_name', ''), nullif(new.raw_user_meta_data->>'name', ''), v_inv.nombre, ''),
          coalesce(v_inv.rol, 'estudiante'));
  if v_inv.id is not null then
    update invitaciones set usada_en = now() where id = v_inv.id;
  end if;
  return new;
end $$;
