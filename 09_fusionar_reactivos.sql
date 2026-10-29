-- =====================================================================
-- GesLab · 09 · Fusionar reactivos duplicados del catálogo
-- Requiere 05 y 06 (función auditar). Re-ejecutable.
-- Cuando un mismo reactivo está dos veces en el catálogo (p. ej. «Ácido sulfúrico»
-- de las solicitudes y «Acido sulfurico 95-97%» del inventario), la solicitud
-- no encuentra el stock. Esta función los une en uno solo.
-- =====================================================================

create or replace view v_reactivos_resumen with (security_invoker = true) as
select cr.id, cr.nombre, cr.cas, cr.unidad::text as unidad, cr.activo,
       count(distinct e.id) as envases,
       coalesce(sum(e.cantidad_actual), 0) as total,
       string_agg(distinct c.nombre, ', ') as sedes,
       (select count(*) from sesion_reactivos sr where sr.reactivo_id = cr.id) as en_solicitudes
from catalogo_reactivos cr
left join envases e on e.reactivo_id = cr.id
left join campus c on c.id = e.campus_id
group by cr.id;
grant select on v_reactivos_resumen to authenticated;

create or replace function fusionar_reactivos(p_origen uuid, p_destino uuid) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  o catalogo_reactivos; d catalogo_reactivos; e record; l record; x sesion_reactivos;
  v_env int := 0; v_lin int := 0; v_f numeric;
begin
  if auth.uid() is not null and not es_personal() then raise exception 'Solo el personal puede fusionar reactivos'; end if;
  if p_origen = p_destino then raise exception 'Elija dos reactivos distintos'; end if;
  select * into o from catalogo_reactivos where id = p_origen for update;
  select * into d from catalogo_reactivos where id = p_destino for update;
  if o.id is null or d.id is null then raise exception 'Reactivo no encontrado'; end if;
  if convertir_cantidad(1, o.unidad::text, d.unidad::text) is null then
    raise exception 'No se pueden fusionar: unidades incompatibles (% y %)', o.unidad, d.unidad;
  end if;
  v_f := convertir_cantidad(1, o.unidad::text, d.unidad::text);

  -- Envases: pasan al reactivo destino (cantidades convertidas a su unidad)
  for e in select id from envases where reactivo_id = o.id loop
    update envases set reactivo_id = d.id,
           cantidad_inicial = cantidad_inicial * v_f, cantidad_actual = cantidad_actual * v_f
     where id = e.id;
    v_env := v_env + 1;
  end loop;

  -- Líneas de solicitudes: si la sesión ya tenía el destino, se suman
  for l in select * from sesion_reactivos where reactivo_id = o.id loop
    select * into x from sesion_reactivos where sesion_id = l.sesion_id and reactivo_id = d.id;
    if x.id is null then
      update sesion_reactivos set reactivo_id = d.id where id = l.id;
    else
      update sesion_reactivos set
        cantidad_prevista = case when x.cantidad_prevista is null and l.cantidad_prevista is null then null
          else coalesce(x.cantidad_prevista, 0) + coalesce(convertir_cantidad(l.cantidad_prevista, l.unidad, x.unidad), l.cantidad_prevista, 0) end,
        cantidad_consumida = case when x.cantidad_consumida is null and l.cantidad_consumida is null then null
          else coalesce(x.cantidad_consumida, 0) + coalesce(convertir_cantidad(l.cantidad_consumida, l.unidad, x.unidad), l.cantidad_consumida, 0) end,
        texto_original = coalesce(x.texto_original, '') || ' | ' || coalesce(l.texto_original, '')
       where id = x.id;
      delete from sesion_reactivos where id = l.id;
    end if;
    v_lin := v_lin + 1;
  end loop;

  -- Nombres reconocidos: ahora apuntan al destino
  update alias_reactivos set reactivo_id = d.id where reactivo_id = o.id;
  insert into alias_reactivos (alias, reactivo_id) values (normalizar_texto(o.nombre), d.id) on conflict (alias) do nothing;
  if d.cas is null and o.cas is not null then update catalogo_reactivos set cas = null where id = o.id; update catalogo_reactivos set cas = o.cas where id = d.id; end if;

  update catalogo_reactivos set activo = false, notas = coalesce(notas || ' · ', '') || 'Fusionado en ' || d.nombre where id = o.id;
  perform auditar('catalogo_reactivos', o.id, 'fusionar', jsonb_build_object('origen', o.nombre, 'destino', d.nombre, 'destino_id', d.id, 'envases', v_env, 'lineas', v_lin));
  return jsonb_build_object('envases', v_env, 'lineas', v_lin);
end $$;
revoke execute on function fusionar_reactivos(uuid, uuid) from public, anon;
grant execute on function fusionar_reactivos(uuid, uuid) to authenticated;

-- Mensaje de error más claro al reportar consumo (muestra cuánto se necesita y cuánto hay)
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
  if auth.uid() is not null and not es_personal() then
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
        raise exception 'Existencia vigente insuficiente de % en %: se necesitan % % y hay % %. Si el reactivo está en el inventario con otro nombre, fusiónelo en Admin → Catálogo.',
          cr.nombre, (select nombre from campus where id = s.campus_id),
          trim_scale(round(v_delta, 3)), cr.unidad, trim_scale(round(v_delta - v_rest, 3)), cr.unidad;
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

notify pgrst, 'reload schema';


-- Caso reportado: unir «Ácido sulfúrico» (solicitudes) con «Acido sulfurico 95-97%» (inventario)
select fusionar_reactivos(
  '3ea7d3a1-d75f-5d23-8280-8ddfb92d4354',
  (select id from catalogo_reactivos where cas = '7664-93-9' and id <> '3ea7d3a1-d75f-5d23-8280-8ddfb92d4354' and activo limit 1)
) as resultado;
