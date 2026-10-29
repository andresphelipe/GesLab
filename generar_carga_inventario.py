#!/usr/bin/env python3
"""Genera carga_inventario_<Sede>.sql a partir de los libros Inventario/GesLab_v2/Inventario_GesLab_<Sede>.xlsx
Uso:  python3 generar_carga_inventario.py            (las 3 sedes)
      python3 generar_carga_inventario.py Turbo      (una sola)
El SQL es re-ejecutable: al repetirlo NO pisa existencias ya movidas en la app (solo actualiza datos descriptivos)."""
import openpyxl,sys,os,datetime,warnings,collections
warnings.filterwarnings('ignore')
BASE=os.path.join(os.path.dirname(os.path.abspath(__file__)),'Inventario','GesLab_v2')
SEDES=['Turbo','Apartadó','Carepa']
ESTADO={'Operativo':'operativo','En mantenimiento':'en_mantenimiento','Fuera de servicio':'fuera_de_servicio','Baja':'baja'}
def q(x):
    if x is None or x=='': return 'null'
    if isinstance(x,bool): return 'true' if x else 'false'
    if isinstance(x,(int,float)): return repr(round(x,6)) if isinstance(x,float) else str(x)
    if isinstance(x,datetime.datetime): x=x.date()
    if isinstance(x,datetime.date): return "'%s'::date"%x.isoformat()
    return "'"+str(x).replace("'","''")+"'"
def tabla(ws):
    h=[c.value for c in ws[1]]
    for r in ws.iter_rows(min_row=2,values_only=True):
        yield dict(zip(h,r))
def vals(rows,cols):
    out=[]
    for i in range(0,len(rows),150):
        out.append('insert into %s values\n%s;'%('{T}',',\n'.join('('+','.join(q(r[c]) for c in cols)+')' for r in rows[i:i+150])))
    return out
def num(x):
    try: return float(x) if x not in(None,'') else None
    except: return None
def gen(sede):
    wb=openpyxl.load_workbook(os.path.join(BASE,f'Inventario_GesLab_{sede}.xlsx'),data_only=False)
    sql=[f'-- GesLab · carga de inventario · sede {sede}\n-- Generado el {datetime.date.today()} desde Inventario_GesLab_{sede}.xlsx\n-- Requiere 04 y 05. Re-ejecutable: no pisa existencias ya movidas.\n-- Todo va en un único bloque, para que funcione en el SQL Editor de Supabase.\ndo $carga$\ndeclare v_campus uuid; n int;\nbegin',
         f"select id into v_campus from campus where nombre = {q(sede)};",
         "if v_campus is null then raise exception 'No existe el campus %', "+q(sede)+"; end if;",
         "drop table if exists _rea, _map, _eq, _vid;"]
    # ---------- Reactivos
    cons=collections.defaultdict(float)
    for m in tabla(wb['Movimientos']):
        if m.get('ID reactivo') and num(m.get('Cantidad usada')): cons[m['ID reactivo']]+=num(m['Cantidad usada'])
    R=[];ncons=0
    for d in tabla(wb['Reactivos']):
        if not d.get('Reactivo'): continue
        cont=num(d['Existencia (último conteo)']); ini=num(d['Cantidad inicial'])
        used=cons.get(d['ID'],0); act=None if cont is None else max(cont-used,0)
        if used: ncons+=1
        motivo=d.get('Motivo de revisión'); rev=(d.get('Revisar')=='Sí')
        if cont is not None and used>cont: rev=True; motivo=((motivo+'; ') if motivo else '')+'Consumos registrados superan el conteo'
        v=d.get('Vencimiento'); 
        R.append(dict(id=d['ID'],nombre=d['Reactivo'],formula=d.get('Fórmula'),cas=d.get('CAS'),unidad=d.get('Unidad') or 'g',ini=ini if ini is not None else act,act=act,
          fc=d.get('Fecha del conteo'),venc=v if isinstance(v,(datetime.datetime,datetime.date)) else None,lote=d.get('Lote'),marca=d.get('Marca'),pureza=d.get('Pureza / concentración'),
          clase=d.get('Clase de almacenamiento'),ubic=d.get('Ubicación'),interno=d.get('Cód. interno'),recibio=d.get('Recibió'),base=d.get('Base de la existencia'),
          rev=rev or act is None,motivo=motivo or ('Sin cantidad actual' if act is None else None),origen=d.get('Origen (archivo · hoja · fila)')))
    cols=['id','nombre','formula','cas','unidad','ini','act','fc','venc','lote','marca','pureza','clase','ubic','interno','recibio','base','rev','motivo','origen']
    sql.append("create temp table _rea (id_inv text, nombre text, formula text, cas text, unidad text, ini numeric, act numeric, fconteo date, venc date, lote text, marca text, pureza text, clase text, ubic text, interno text, recibio text, base text, revisar boolean, motivo text, origen text);")
    sql+= [s.replace('{T}','_rea') for s in vals(R,cols)]
    sql.append("""create temp table _map as
select s.id_inv,
       coalesce((select c.id from catalogo_reactivos c where s.cas is not null and c.cas = s.cas),
                (select a.reactivo_id from alias_reactivos a where a.alias = normalizar_texto(s.nombre))) as reactivo_id
from _rea s;
insert into catalogo_reactivos (nombre, formula, cas, clase_almacenamiento, unidad)
select distinct on (coalesce(s.cas, normalizar_texto(s.nombre))) s.nombre, s.formula, s.cas, coalesce(s.clase, 'general'), s.unidad::unidad_medida
from _rea s join _map m using (id_inv) where m.reactivo_id is null
order by coalesce(s.cas, normalizar_texto(s.nombre)), s.nombre
on conflict do nothing;
update _map m set reactivo_id = coalesce(
    (select c.id from catalogo_reactivos c where s.cas is not null and c.cas = s.cas),
    (select a.reactivo_id from alias_reactivos a where a.alias = normalizar_texto(s.nombre)))
from _rea s where s.id_inv = m.id_inv and m.reactivo_id is null;
select count(*) into n from _map where reactivo_id is null;
if n > 0 then raise exception '% reactivos no se pudieron vincular al catálogo', n; end if;
insert into envases (codigo, reactivo_id, lote, proveedor, fecha_recepcion, fecha_caducidad, cantidad_inicial, cantidad_actual, estado,
                     campus_id, id_inventario, fecha_conteo, base_existencia, revisar, motivo_revision, origen, ubicacion_texto, marca, pureza, codigo_interno, recibido_por)
select s.id_inv, m.reactivo_id, s.lote, s.marca, current_date, s.venc,
       coalesce(s.ini, s.act, 0), coalesce(s.act, 0),
       case when coalesce(s.act, 0) = 0 then 'agotado'::estado_envase
            when s.venc < current_date then 'vencido'::estado_envase else 'disponible'::estado_envase end,
       v_campus, s.id_inv, s.fconteo, s.base, s.revisar, s.motivo, s.origen, s.ubic, s.marca, s.pureza, s.interno, s.recibio
from _rea s join _map m using (id_inv)
on conflict (id_inventario) do update set
  lote = excluded.lote, fecha_caducidad = excluded.fecha_caducidad, revisar = excluded.revisar,
  motivo_revision = excluded.motivo_revision, ubicacion_texto = excluded.ubicacion_texto,
  marca = excluded.marca, pureza = excluded.pureza, codigo_interno = excluded.codigo_interno, recibido_por = excluded.recibido_por;""")
    # ---------- Equipos
    E=[]
    for d in tabla(wb['Equipos']):
        if not d.get('Equipo'): continue
        E.append(dict(id=d['ID'],nombre=d['Equipo'],marca=d.get('Marca'),modelo=d.get('Modelo'),serie=d.get('Serie'),activo=d.get('Cód. activo'),inv=d.get('N° inventario'),
          salon=d.get('Salón o laboratorio'),area=d.get('Área'),cant=int(num(d.get('Cantidad')) or 1),estado=ESTADO.get(d.get('Estado'),'operativo'),cond=d.get('Condición'),
          fuera=d.get('Prestado o enviado a'),resp=d.get('Responsable'),fecha=d.get('Fecha del inventario') if isinstance(d.get('Fecha del inventario'),(datetime.datetime,datetime.date)) else None,
          obs=d.get('Observaciones'),rev=d.get('Revisar')=='Sí',motivo=d.get('Motivo de revisión'),origen=d.get('Origen (archivo · hoja · fila)')))
    ecols=['id','nombre','marca','modelo','serie','activo','inv','salon','area','cant','estado','cond','fuera','resp','fecha','obs','rev','motivo','origen']
    sql.append("create temp table _eq (id_inv text, nombre text, marca text, modelo text, serie text, activo text, inv text, salon text, area text, cant int, estado text, cond text, fuera text, resp text, fecha date, obs text, revisar boolean, motivo text, origen text);")
    sql+= [s.replace('{T}','_eq') for s in vals(E,ecols)]
    sql.append("""insert into laboratorios (nombre, campus_id)
select distinct %s || ' · ' || coalesce(nullif(trim(salon), ''), 'Sin asignar'), v_campus from _eq
on conflict (nombre) do nothing;
insert into catalogo_materiales (nombre, categoria, unidad, tipo_item)
select distinct on (normalizar_texto(nombre)) nombre, 'Equipo', 'unidad', 'equipo' from _eq
where not exists (select 1 from alias_materiales a where a.alias = normalizar_texto(_eq.nombre))
order by normalizar_texto(nombre), nombre;
insert into equipos (laboratorio_id, codigo, nombre, marca, modelo, serie, estado, reservable, notas, campus_id, material_id, cantidad, salon, area,
                     codigo_activo, numero_inventario, condicion, responsable, fecha_inventario, id_inventario, revisar, motivo_revision, origen, fuera_de_sede)
select (select l.id from laboratorios l where l.nombre = %s || ' · ' || coalesce(nullif(trim(e.salon), ''), 'Sin asignar')),
       e.id_inv, e.nombre, e.marca, e.modelo, e.serie, e.estado::estado_equipo, e.estado = 'operativo', e.obs, v_campus,
       (select a.material_id from alias_materiales a where a.alias = normalizar_texto(e.nombre)),
       e.cant, e.salon, e.area, e.activo, e.inv, e.cond, e.resp, e.fecha, e.id_inv, e.revisar, e.motivo, e.origen, e.fuera
from _eq e
on conflict (id_inventario) do update set
  nombre = excluded.nombre, marca = excluded.marca, modelo = excluded.modelo, serie = excluded.serie, estado = excluded.estado,
  reservable = excluded.reservable, notas = excluded.notas, cantidad = excluded.cantidad, salon = excluded.salon, area = excluded.area,
  codigo_activo = excluded.codigo_activo, numero_inventario = excluded.numero_inventario, condicion = excluded.condicion,
  responsable = excluded.responsable, revisar = excluded.revisar, motivo_revision = excluded.motivo_revision, fuera_de_sede = excluded.fuera_de_sede;""" % (q(sede),q(sede)))
    # ---------- Vidriería
    V=[]
    rot=collections.defaultdict(int)
    for m in tabla(wb['Roturas']):
        if m.get('ID vidriería') and num(m.get('Cantidad rota o dada de baja')): rot[m['ID vidriería']]+=int(num(m['Cantidad rota o dada de baja']))
    for d in tabla(wb['Vidriería']):
        item=d.get('Ítem (p. ej. Beaker, Probeta, Pipeta aforada)')
        if not item: continue
        esp=d.get('Capacidad / especificación'); nombre=item+(' '+str(esp) if esp else '')
        b=int(num(d.get('Cantidad buena')) or 0); rg=int(num(d.get('Cantidad regular')) or 0); dn=int(num(d.get('Cantidad dañada o dada de baja')) or 0)
        r=rot.get(d['ID'],0); take=min(b,r); b-=take; rg=max(rg-(r-take),0); dn+=r
        V.append(dict(id=d['ID'],nombre=nombre,mat=d.get('Material'),b=b,r=rg,d=dn,ub=d.get('Ubicación'),fc=d.get('Fecha del conteo') if isinstance(d.get('Fecha del conteo'),(datetime.datetime,datetime.date)) else None,obs=d.get('Observaciones')))
    if V:
        sql.append("create temp table _vid (id_inv text, nombre text, material text, buena int, regular int, danada int, ubic text, fconteo date, obs text);")
        sql+= [s.replace('{T}','_vid') for s in vals(V,['id','nombre','mat','b','r','d','ub','fc','obs'])]
        sql.append("""insert into catalogo_materiales (nombre, categoria, unidad, tipo_item)
select distinct on (normalizar_texto(nombre)) nombre, material, 'unidad', 'vidrieria' from _vid
where not exists (select 1 from alias_materiales a where a.alias = normalizar_texto(_vid.nombre))
order by normalizar_texto(nombre), nombre;
insert into existencias_material (material_id, campus_id, cantidad_buena, cantidad_regular, cantidad_danada, ubicacion, fecha_conteo, observaciones, id_inventario)
select (select a.material_id from alias_materiales a where a.alias = normalizar_texto(v.nombre)), v_campus,
       v.buena, v.regular, v.danada, v.ubic, v.fconteo, v.obs, v.id_inv
from _vid v
on conflict (id_inventario) do update set ubicacion = excluded.ubicacion, observaciones = excluded.observaciones;""")
    sql.append(f"drop table if exists _rea, _map, _eq, _vid;\nraise notice 'Carga {sede} lista: {len(R)} reactivos, {len(E)} equipos, {len(V)} vidriería';\nend\n$carga$;")
    out=os.path.join(BASE,f'carga_inventario_{sede}.sql'); open(out,'w',encoding='utf-8').write('\n'.join(sql)+'\n')
    print(sede,len(R),'reactivos',len(E),'equipos',len(V),'vidriería · consumos aplicados a',ncons,'envases ·',os.path.getsize(out)//1024,'KB')
for s in (sys.argv[1:] or SEDES): gen(s)
