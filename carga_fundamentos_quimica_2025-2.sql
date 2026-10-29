-- =====================================================================
-- CARGA INICIAL: Fundamentos de Química MIA 2025-2  (generada desde su Excel)
-- Ejecutar UNA VEZ en Supabase > SQL Editor, DESPUÉS de schema_labs.sql.
-- Se puede repetir sin duplicar datos.
--
-- ► ÚNICO CAMBIO QUE DEBE HACER: escriba su correo en la línea de abajo
--   (debe ser el correo de un usuario ya creado en Supabase).
-- =====================================================================
do $carga$
declare
  v_correo  text := 'CAMBIE_AQUI@su-correo.com';   -- ← EDITE SOLO ESTO
  v_docente uuid;
  v_lab     uuid;
begin
  select id into v_docente from perfiles where lower(email) = lower(v_correo);
  if v_docente is null then
    raise exception 'No existe un usuario con el correo %. Cree el usuario primero (Authentication > Users) y vuelva a ejecutar.', v_correo;
  end if;

  insert into laboratorios (id, nombre) values ('5fab40b6-4e68-5aaa-8ff8-2f1410ca77d7', 'Laboratorio de Química') on conflict do nothing;
  select id into v_lab from laboratorios where nombre = 'Laboratorio de Química';

  -- Catálogo de reactivos (sin CAS ni pictogramas: complételos con las fichas SDS)
  insert into catalogo_reactivos (id, nombre, formula, unidad, clase_almacenamiento) values
    ('6f916b68-b7c2-5a48-b083-11a624774bba', 'Agua destilada', 'H2O', 'mL'::unidad_medida, 'general'),
    ('a44092ba-763d-5e76-832f-44c75090560e', 'Etanol', 'C2H5OH', 'mL'::unidad_medida, 'inflamables'),
    ('2252fa8a-c2ec-52ac-a8f2-c4c4c7ea3dc0', 'Glicerina (glicerol)', 'C3H8O3', 'mL'::unidad_medida, 'general'),
    ('19f45963-56fc-500a-9567-d0ec0714df92', 'Cloruro de sodio', 'NaCl', 'g'::unidad_medida, 'general'),
    ('000bde2f-a1cf-5da0-a8dd-389aa77b3aff', 'Acetanilida', 'C8H9NO', 'g'::unidad_medida, 'general'),
    ('b06a3b93-88e4-571f-b645-91cef3d48bff', 'Jabón líquido', NULL, 'mL'::unidad_medida, 'general'),
    ('f73354f1-c921-52da-9f08-6fc8fed2f3d5', 'Aceite mineral', NULL, 'mL'::unidad_medida, 'general'),
    ('ddc90e97-bf01-5f9b-8bb8-54f8cef215a3', 'Colorante', NULL, 'g'::unidad_medida, 'general'),
    ('af609bdc-7c82-5eb5-bc33-1bfe3ff5d2e3', 'Carbonato de calcio', 'CaCO3', 'g'::unidad_medida, 'general'),
    ('a2a45edd-5007-5ac7-8f5c-3f516c701570', 'Dióxido de silicio', 'SiO2', 'g'::unidad_medida, 'general'),
    ('e585e729-6109-59fa-93bf-0fe06dd87c6a', 'Ácido clorhídrico', 'HCl', 'mL'::unidad_medida, 'acidos'),
    ('80bcc97e-06da-5c32-8c28-86d399e0da17', 'Acetato de etilo', 'C4H8O2', 'mL'::unidad_medida, 'inflamables'),
    ('3002ff7e-c0eb-5297-bb6b-6d2deca85140', 'Hexano', 'C6H14', 'mL'::unidad_medida, 'inflamables'),
    ('04ffa719-965c-5b5d-999f-8666c14a75a7', 'Zinc', 'Zn', 'g'::unidad_medida, 'general'),
    ('c3c0623f-9324-566f-99ba-23ee3f55b097', 'Magnesio', 'Mg', 'g'::unidad_medida, 'general'),
    ('1dc4bb2a-e3e4-5df1-a626-8fb0e00ff7da', 'Cobre', 'Cu', 'g'::unidad_medida, 'general'),
    ('4b99ec48-e4cb-50b7-a760-9f0df8c0f43a', 'Azufre', 'S', 'g'::unidad_medida, 'general'),
    ('06a5bae2-a851-5b04-bf42-5afd44d32dcb', 'Hierro', 'Fe', 'g'::unidad_medida, 'general'),
    ('643482de-1b40-5898-be76-92920a30f2ec', 'Aluminio', 'Al', 'g'::unidad_medida, 'general'),
    ('de9a81cc-d0fb-5fd8-8e9c-6f9426bd561d', 'Sodio metálico', 'Na', 'g'::unidad_medida, 'reactivo_con_agua'),
    ('c731bebc-d041-50e9-a840-fcddc311039c', 'Mercurio', 'Hg', 'mL'::unidad_medida, 'toxicos'),
    ('e8a023f1-6edc-59ab-965c-1d77f1f6fa76', 'Yodo', 'I2', 'g'::unidad_medida, 'general'),
    ('d76d4c01-6efe-5b9a-9945-115388dd0e37', 'Plomo', 'Pb', 'g'::unidad_medida, 'toxicos'),
    ('eb439c96-a9b9-5f24-9ec6-9368560677fd', 'Carbono grafito', 'C', 'g'::unidad_medida, 'general'),
    ('ed45390d-c02d-5a0d-9297-390eae914d64', 'Yoduro de potasio', 'KI', 'g'::unidad_medida, 'general'),
    ('dac0281a-7d1c-5abb-af26-522c543d673c', 'Cloruro de calcio', 'CaCl2', 'g'::unidad_medida, 'general'),
    ('13dacfe8-8eee-5cce-9005-29444f90ae42', 'Cloruro de níquel', 'NiCl2', 'g'::unidad_medida, 'general'),
    ('e9a7ff9c-6de5-52ed-aeb4-8e35732ff57d', 'Sulfato de cobre pentahidratado', 'CuSO4·5H2O', 'g'::unidad_medida, 'general'),
    ('948ba644-477a-5c2e-91f0-f7e4ffb6b656', 'Nitrato de bario', 'Ba(NO3)2', 'g'::unidad_medida, 'toxicos'),
    ('881cc962-2982-5e3b-912e-18e69bdf4889', 'Hidróxido de sodio', 'NaOH', 'g'::unidad_medida, 'bases'),
    ('4c2d01e3-7dda-5613-960b-7d0136d3b32a', 'Yoduro de sodio', 'NaI', 'g'::unidad_medida, 'general'),
    ('7fc953e6-0a2a-5a07-8370-848c750eb5b2', 'Acetato de plomo(II)', 'Pb(CH3COO)2', 'g'::unidad_medida, 'toxicos'),
    ('51ca596b-528f-535a-85a2-50319c391aac', 'Ácido nítrico', 'HNO3', 'mL'::unidad_medida, 'acidos'),
    ('a3100cc8-ac60-5db1-9a50-e48a91df9ea5', 'Fenolftaleína', NULL, 'mL'::unidad_medida, 'general'),
    ('d5879bb3-4850-5e50-9bb6-544555ee6826', 'Anaranjado de metilo', NULL, 'mL'::unidad_medida, 'general'),
    ('53097844-e2d9-512f-a56c-94ccb574ae21', 'Azul de timol', NULL, 'mL'::unidad_medida, 'general'),
    ('5148bcba-d706-5ec6-8450-f273e046406b', 'Ftalato ácido de potasio', 'KHC8H4O4', 'g'::unidad_medida, 'general'),
    ('41dbef7b-d940-5a87-9a3a-99653bff16cd', 'Dicromato de potasio', 'K2Cr2O7', 'g'::unidad_medida, 'oxidantes'),
    ('da618e17-477a-5839-bb08-38dd7786b1f8', 'n-Heptano', 'C7H16', 'mL'::unidad_medida, 'inflamables'),
    ('3eb03ece-5034-58a6-b07f-1c9ffecb55a6', 'Ciclohexeno', 'C6H10', 'mL'::unidad_medida, 'inflamables'),
    ('61c52101-f312-53b7-b9ea-748c0e2f80e0', 'n-Butanol', 'C4H10O', 'mL'::unidad_medida, 'inflamables'),
    ('2040833c-aac6-57a9-a1ee-721711ac3990', 'Propionaldehído', 'C3H6O', 'mL'::unidad_medida, 'inflamables'),
    ('e7f294e7-82cf-5ca6-a318-6b22009297e8', 'Butiraldehído', 'C4H8O', 'mL'::unidad_medida, 'inflamables'),
    ('0415b1da-b3eb-5d3a-9f70-c43886184b7e', 'Acetona', 'C3H6O', 'mL'::unidad_medida, 'inflamables'),
    ('27d2f435-4b01-594a-8937-6fb9e08ea878', '2-Butanona', 'C4H8O', 'mL'::unidad_medida, 'inflamables'),
    ('fe818d90-5625-5de0-8c2c-7cba70fc0fe5', 'Ácido acético', 'CH3COOH', 'mL'::unidad_medida, 'acidos'),
    ('d23ddff5-32be-5450-af81-0998b490e950', 'Ácido propiónico', 'C3H6O2', 'mL'::unidad_medida, 'acidos'),
    ('67e36961-44fb-52d5-9539-ebbd53aede2f', 'Dietilamina', 'C4H11N', 'mL'::unidad_medida, 'inflamables'),
    ('64a0d51f-f2e6-5d4a-9827-c851adc28fa4', 'Permanganato de potasio', 'KMnO4', 'g'::unidad_medida, 'oxidantes'),
    ('a218255b-cbe3-5df6-9131-f1c26c334f61', 'Nitrato de plata', 'AgNO3', 'g'::unidad_medida, 'oxidantes'),
    ('8533df08-4115-5d5f-9380-af047db82ba8', 'Hidróxido de amonio', 'NH4OH', 'mL'::unidad_medida, 'bases'),
    ('3ea7d3a1-d75f-5d23-8280-8ddfb92d4354', 'Ácido sulfúrico', 'H2SO4', 'mL'::unidad_medida, 'acidos'),
    ('c5575628-0468-5e9f-b49d-6fde8ea573e2', '2,4-Dinitrofenilhidrazina', 'C6H6N4O4', 'g'::unidad_medida, 'general'),
    ('d1eb326b-df55-5adc-bc75-901047a964b0', 'Rojo de metilo', NULL, 'mL'::unidad_medida, 'general'),
    ('99e07f43-96c7-5475-ac41-ea864ceecf5d', 'Azul de bromotimol', NULL, 'mL'::unidad_medida, 'general'),
    ('f19fedab-293b-5343-b4ae-b78cc341fc0e', 'Amarillo de metilo', NULL, 'mL'::unidad_medida, 'general')
  on conflict (id) do nothing;

  -- Catálogo de materiales, vidriería y equipos solicitados (stock inicial 0: lo completa el técnico)
  insert into catalogo_materiales (id, nombre, categoria, unidad) values
    ('ce24ff35-d394-5266-acc1-f7175ba64bb3', 'Pipeta volumétrica', 'Vidriería', 'unidad'),
    ('50190125-4c68-5d2c-a5c6-a56583ffcd48', 'Pipeta graduada', 'Vidriería', 'unidad'),
    ('8904e3b4-455d-51e1-aa48-3b7729c7a2dd', 'Pera de succión', 'Utensilio', 'unidad'),
    ('064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 'Beaker (vaso de precipitado)', 'Vidriería', 'unidad'),
    ('19daf60e-b108-5e55-89df-83f7c3a073be', 'Balanza digital', 'Equipo', 'unidad'),
    ('ef803188-2ef7-5c7d-97d1-2266d0d1d99b', 'Pie de rey (vernier)', 'Instrumento', 'unidad'),
    ('96ec5fdf-0007-5994-8228-9a225f2daaaa', 'Termómetro', 'Instrumento', 'unidad'),
    ('ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 'Probeta graduada', 'Vidriería', 'unidad'),
    ('d116cecc-4956-51b0-a103-244c397caa9a', 'Pesas de referencia', 'Instrumento', 'unidad'),
    ('d61dea56-6ef1-5ffe-b1dc-e22a3957d2cf', 'Condensador', 'Vidriería', 'unidad'),
    ('5961f497-6b82-54f8-a674-07788ee1c013', 'Embudo de vidrio', 'Vidriería', 'unidad'),
    ('59370edf-747d-5ce4-ae0a-0fdd69ee88b6', 'Crisol', 'Utensilio', 'unidad'),
    ('51074689-415c-5425-8438-740eb7b00638', 'Tubo de Thiele', 'Vidriería', 'unidad'),
    ('703eb001-8968-5163-951d-6de7224d779c', 'Tubo de ensayo', 'Vidriería', 'unidad'),
    ('0eac8838-f54f-5db6-ba5f-aec15a9e241e', 'Embudo de separación', 'Vidriería', 'unidad'),
    ('7b018fef-5280-554c-bc5b-18ade9efa1cd', 'Embudo Büchner', 'Vidriería', 'unidad'),
    ('784e25aa-5e19-568b-b6ff-d2f9e7f9f648', 'Balón volumétrico (matraz aforado)', 'Vidriería', 'unidad'),
    ('108c6816-9128-50ce-b784-a6eaa3a6173e', 'Erlenmeyer', 'Vidriería', 'unidad'),
    ('e2adbdff-cfee-52e8-9a77-35fd7701f1bd', 'Mortero con pistilo', 'Utensilio', 'unidad'),
    ('5010c358-aea8-554f-aa4c-2934745fe6cd', 'Espátula', 'Utensilio', 'unidad'),
    ('4879407a-5079-56ff-9d26-cdda5b70a3c6', 'Gradilla para tubos', 'Utensilio', 'unidad'),
    ('b4fe6d69-aa4a-5339-996f-af40db817b82', 'Vidrio de reloj', 'Vidriería', 'unidad'),
    ('c530ec2d-44a7-5d48-8819-f3992bf31c4e', 'Mechero', 'Utensilio', 'unidad'),
    ('801a687f-e173-5780-9c32-e9b96b9bafbd', 'Pinzas para tubo de ensayo', 'Utensilio', 'unidad'),
    ('eae9ccb5-31ab-574d-b4a9-cefaa70a8e07', 'Bureta', 'Vidriería', 'unidad'),
    ('d4dcaab2-2859-573b-b8cc-5c2e41ee08d9', 'Varilla de vidrio (agitación)', 'Vidriería', 'unidad'),
    ('cf78a03f-97ed-51a5-8993-b67b0faaf064', 'Picnómetro', 'Vidriería', 'unidad'),
    ('749be4a7-1914-5f29-ac9e-c4aef193c55f', 'Sólidos geométricos (cubo, cilindro, esfera)', 'Utensilio', 'unidad'),
    ('3e001c5e-a731-5d33-be2b-98e43006631b', 'Recipiente para residuos líquidos', 'Utensilio', 'unidad'),
    ('b96a88d8-e7c2-5494-8478-d5c944ce276c', 'Cronómetro', 'Instrumento', 'unidad'),
    ('83476430-e1a9-5b99-958a-ed5beb19e6c2', 'Canicas', 'Utensilio', 'unidad'),
    ('544eb5bd-c301-54ca-afaf-d0e24e349d26', 'Baño maría', 'Equipo', 'unidad'),
    ('84fa36fc-d71a-582d-b46b-b502ad05541c', 'Capilares', 'Consumible', 'unidad'),
    ('d1cc526a-099b-59d6-9bd8-056aa0ebc2a6', 'Bandas de caucho', 'Consumible', 'unidad'),
    ('23d6090e-5d9f-5d90-af05-7fc51b4d5d7f', 'Plancha de calentamiento', 'Equipo', 'unidad'),
    ('5e05c62d-b87e-51c0-baec-8c59edce24ee', 'Soporte universal', 'Utensilio', 'unidad'),
    ('a451b76f-52c8-5d50-b7ff-904cb7d10bb1', 'Placa de calentamiento', 'Equipo', 'unidad'),
    ('cb92a1f9-4e51-5dde-930c-106e0220257f', 'Pinzas', 'Utensilio', 'unidad'),
    ('ff52895c-ffad-5e54-b8f4-27127f0e1a22', 'Nuez', 'Utensilio', 'unidad'),
    ('78c172c7-1d3c-5e75-83b9-1daa4f09c4c0', 'Papel filtro', 'Consumible', 'unidad'),
    ('f8550b72-6e14-54a7-bfbe-b8510e15e150', 'Cápsula de porcelana', 'Utensilio', 'unidad'),
    ('19624741-d380-5689-8eea-62d1a67c61d9', 'Perlas de ebullición', 'Consumible', 'unidad'),
    ('66326b8a-1e44-5072-b1ba-50b72c155dae', 'Balón de destilación', 'Vidriería', 'unidad'),
    ('16eac7b2-b357-5e97-8111-2d441c91a044', 'Placa cromatográfica', 'Consumible', 'unidad'),
    ('b5ccff20-5a04-5ffa-8509-e54f86099e47', 'Pinzas para crisol', 'Utensilio', 'unidad'),
    ('5c23926f-4491-5ed8-990a-1e87746c496b', 'Pipeta Pasteur', 'Vidriería', 'unidad')
  on conflict (id) do nothing;

  -- ---------- Práctica 1: MANEJO DE EQUIPO DE LABORATORIO. DETERMINACIÓN DE MASAS Y VOLÚMENES
  insert into practicas (id, codigo, nombre, asignatura, programa, laboratorio_id, docente_responsable_id, duracion_min)
  values ('a47afee8-8fae-515c-8b9d-10c8c170df9d', 'FQ-P01', 'MANEJO DE EQUIPO DE LABORATORIO. DETERMINACIÓN DE MASAS Y VOLÚMENES', 'Fundamentos de Química', 'MIA', v_lab, v_docente, 180) on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('8dfa659b-b658-577e-b553-8cb5b4b4267b', 'a47afee8-8fae-515c-8b9d-10c8c170df9d', v_docente, v_lab, 13, 4, timestamptz '2025-08-14 09:00:00-05', timestamptz '2025-08-14 12:00:00-05', 'solicitada', 'Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('b4546dfc-69a7-516a-8c00-cb0d60dc84bd', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '6f916b68-b7c2-5a48-b083-11a624774bba', 4, 'frasco lavador', NULL, NULL, 'Agua destilada')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('a79a87ce-e1d1-5d6b-9ff3-2f16748f083e', '8dfa659b-b658-577e-b553-8cb5b4b4267b', 'ce24ff35-d394-5266-acc1-f7175ba64bb3', 16, NULL, 'Pipeta volumétrica (8 con capacidad de 10 mL y 8 con capacidad de 5 mL)'),
    ('b89ec868-c66a-5197-8012-d04a892418ae', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '50190125-4c68-5d2c-a5c6-a56583ffcd48', 16, NULL, 'Pipeta graduada (6 con capacidad de 10 mL y 6 con capacidad de 5 mL)'),
    ('abe02eff-4b8e-5906-9306-b905cd037e80', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '8904e3b4-455d-51e1-aa48-3b7729c7a2dd', 8, NULL, 'Pera de succión'),
    ('a101f82e-7779-5696-9f84-df79ad3f2fb2', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 12, NULL, 'Beaker (6 con capacidad de 250 mL y 6 con capacidad de 50 mL) | Beaker'),
    ('6b7742fd-0bf7-5a92-8c2e-03c9c341d82c', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '19daf60e-b108-5e55-89df-83f7c3a073be', 5, NULL, 'Balanza digital | Balanza digital'),
    ('c53a116e-580c-535b-bcbf-d877b7142809', '8dfa659b-b658-577e-b553-8cb5b4b4267b', 'ef803188-2ef7-5c7d-97d1-2266d0d1d99b', 8, NULL, 'Pie de Rey o Vernier'),
    ('d7aa478a-4975-5878-86bb-d7b5307ee469', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '96ec5fdf-0007-5994-8228-9a225f2daaaa', 8, NULL, 'Termómetro'),
    ('6eb61cd7-e19b-5865-9fb0-9e48aaa30227', '8dfa659b-b658-577e-b553-8cb5b4b4267b', 'ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 8, NULL, 'Probeta con capacidad de 50 mL'),
    ('3c12b060-cf6b-5709-a9fe-6d29bf1a829d', '8dfa659b-b658-577e-b553-8cb5b4b4267b', 'd116cecc-4956-51b0-a103-244c397caa9a', 8, NULL, 'Pesas de metal de referencia'),
    ('9b27e5f9-6799-5de6-9de8-44a41891e0db', '8dfa659b-b658-577e-b553-8cb5b4b4267b', 'd61dea56-6ef1-5ffe-b1dc-e22a3957d2cf', 4, NULL, 'Condensador'),
    ('1e522cb1-d2fb-5f57-8f3d-cd576f5fbfbf', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '5961f497-6b82-54f8-a674-07788ee1c013', 4, NULL, 'Embudo'),
    ('478ff191-36c3-5511-a006-b788d84164c1', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '59370edf-747d-5ce4-ae0a-0fdd69ee88b6', 4, NULL, 'Crisol'),
    ('b3f45ef1-652b-5e3b-b4db-2893deed1606', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '51074689-415c-5425-8438-740eb7b00638', 4, NULL, 'Tubo thiele'),
    ('69f5c0cd-6e0a-5ba4-9c20-d74b4390b3b8', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '703eb001-8968-5163-951d-6de7224d779c', 8, NULL, 'Tubo de ensayo'),
    ('57744009-073b-5607-bf54-38d79d9518b6', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '0eac8838-f54f-5db6-ba5f-aec15a9e241e', 4, NULL, 'Embudo de separación o decantación'),
    ('792311cb-076a-5c20-a618-71c8db3494df', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '7b018fef-5280-554c-bc5b-18ade9efa1cd', 4, NULL, 'Embudo buchner'),
    ('9667572c-1fa7-58f4-bb7a-4111b8297c58', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '784e25aa-5e19-568b-b6ff-d2f9e7f9f648', 4, NULL, 'Balón volumétrico'),
    ('240cf0ff-ff3c-59aa-a784-32287b72328d', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '108c6816-9128-50ce-b784-a6eaa3a6173e', 4, NULL, 'Erlenmeyer'),
    ('f4d615fd-cb71-5e00-bb7d-13315af63429', '8dfa659b-b658-577e-b553-8cb5b4b4267b', 'e2adbdff-cfee-52e8-9a77-35fd7701f1bd', 4, NULL, 'Mortero con pistilo'),
    ('5b48ece0-de1c-501d-ae5d-34e653afb8b5', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '5010c358-aea8-554f-aa4c-2934745fe6cd', 4, NULL, 'Espátula'),
    ('e860c795-18e1-5ca5-b497-38c517e05bb0', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '4879407a-5079-56ff-9d26-cdda5b70a3c6', 4, NULL, 'Gradilla para tubos'),
    ('c61aab74-244e-58e2-90d7-5bc1c5d7fb53', '8dfa659b-b658-577e-b553-8cb5b4b4267b', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 4, NULL, 'Vidrio de reloj'),
    ('8a88da7c-9ac4-5b4b-b04a-c6894e33c1d7', '8dfa659b-b658-577e-b553-8cb5b4b4267b', 'c530ec2d-44a7-5d48-8819-f3992bf31c4e', 4, NULL, 'Mechero'),
    ('d992f52e-ecd7-54ff-9a46-cbf0c53990e8', '8dfa659b-b658-577e-b553-8cb5b4b4267b', '801a687f-e173-5780-9c32-e9b96b9bafbd', 4, NULL, 'Pinzas para tubo de ensayo'),
    ('94a0a5d5-d3e3-5c44-946d-fa01db292f36', '8dfa659b-b658-577e-b553-8cb5b4b4267b', 'eae9ccb5-31ab-574d-b4a9-cefaa70a8e07', 4, NULL, 'Bureta'),
    ('583abfcf-03ff-5f6a-8e3c-764a0834878f', '8dfa659b-b658-577e-b553-8cb5b4b4267b', 'd4dcaab2-2859-573b-b8cc-5c2e41ee08d9', 4, NULL, 'Varilla de vidrio')
  on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('45dc2f96-f228-5027-a63a-f62601945aab', 'a47afee8-8fae-515c-8b9d-10c8c170df9d', v_docente, v_lab, 12, NULL, timestamptz '2025-08-14 13:00:00-05', timestamptz '2025-08-14 16:00:00-05', 'solicitada', 'Segunda sesión del mismo día, deducida de las observaciones del formulario. Mismos materiales y reactivos que la primera.', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('6b8fa5d7-3573-5f40-a495-ca7c2b4b6daa', '45dc2f96-f228-5027-a63a-f62601945aab', '6f916b68-b7c2-5a48-b083-11a624774bba', 4, 'frasco lavador', NULL, NULL, 'Agua destilada')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('35f5767f-88fa-5f80-b316-f51f930e3231', '45dc2f96-f228-5027-a63a-f62601945aab', 'ce24ff35-d394-5266-acc1-f7175ba64bb3', 16, NULL, 'Pipeta volumétrica (8 con capacidad de 10 mL y 8 con capacidad de 5 mL)'),
    ('784399db-9502-5e48-9bfa-e0017c8257fc', '45dc2f96-f228-5027-a63a-f62601945aab', '50190125-4c68-5d2c-a5c6-a56583ffcd48', 16, NULL, 'Pipeta graduada (6 con capacidad de 10 mL y 6 con capacidad de 5 mL)'),
    ('2c2314d8-7ab0-545e-b0ce-b6547ff76378', '45dc2f96-f228-5027-a63a-f62601945aab', '8904e3b4-455d-51e1-aa48-3b7729c7a2dd', 8, NULL, 'Pera de succión'),
    ('6d1f0ac0-1f96-5c77-891c-817a7c3dea2f', '45dc2f96-f228-5027-a63a-f62601945aab', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 12, NULL, 'Beaker (6 con capacidad de 250 mL y 6 con capacidad de 50 mL) | Beaker'),
    ('616f9545-12b9-5903-8427-a70f1e0dea12', '45dc2f96-f228-5027-a63a-f62601945aab', '19daf60e-b108-5e55-89df-83f7c3a073be', 5, NULL, 'Balanza digital | Balanza digital'),
    ('bb3ea3d1-baa7-58dc-a4e9-38d7b511d6a2', '45dc2f96-f228-5027-a63a-f62601945aab', 'ef803188-2ef7-5c7d-97d1-2266d0d1d99b', 8, NULL, 'Pie de Rey o Vernier'),
    ('00d5f6a8-d99f-577b-b17c-f54d7e88ea39', '45dc2f96-f228-5027-a63a-f62601945aab', '96ec5fdf-0007-5994-8228-9a225f2daaaa', 8, NULL, 'Termómetro'),
    ('a19e9312-a20b-5ba8-8232-c8c2982c3e2d', '45dc2f96-f228-5027-a63a-f62601945aab', 'ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 8, NULL, 'Probeta con capacidad de 50 mL'),
    ('904cdbdf-b70e-5285-a4b4-6c45c904c767', '45dc2f96-f228-5027-a63a-f62601945aab', 'd116cecc-4956-51b0-a103-244c397caa9a', 8, NULL, 'Pesas de metal de referencia'),
    ('1f6d5199-deda-587e-8fe0-efcb1cc3f247', '45dc2f96-f228-5027-a63a-f62601945aab', 'd61dea56-6ef1-5ffe-b1dc-e22a3957d2cf', 4, NULL, 'Condensador'),
    ('d651d2d1-153d-50db-abeb-f1ba012bc0cf', '45dc2f96-f228-5027-a63a-f62601945aab', '5961f497-6b82-54f8-a674-07788ee1c013', 4, NULL, 'Embudo'),
    ('e66fc4c7-24fd-5e2c-a007-6adb8ce0101b', '45dc2f96-f228-5027-a63a-f62601945aab', '59370edf-747d-5ce4-ae0a-0fdd69ee88b6', 4, NULL, 'Crisol'),
    ('37cf1ce7-0145-5efd-9294-581cbdbd2aea', '45dc2f96-f228-5027-a63a-f62601945aab', '51074689-415c-5425-8438-740eb7b00638', 4, NULL, 'Tubo thiele'),
    ('95eb48de-4452-53d7-8584-953f112496f8', '45dc2f96-f228-5027-a63a-f62601945aab', '703eb001-8968-5163-951d-6de7224d779c', 8, NULL, 'Tubo de ensayo'),
    ('fb24d992-bc02-5c05-8899-5a8b7224411d', '45dc2f96-f228-5027-a63a-f62601945aab', '0eac8838-f54f-5db6-ba5f-aec15a9e241e', 4, NULL, 'Embudo de separación o decantación'),
    ('c7b2dc8c-43df-5049-8ba3-2ac85786581b', '45dc2f96-f228-5027-a63a-f62601945aab', '7b018fef-5280-554c-bc5b-18ade9efa1cd', 4, NULL, 'Embudo buchner'),
    ('43b5041f-c272-5485-b217-86b3d9a530a9', '45dc2f96-f228-5027-a63a-f62601945aab', '784e25aa-5e19-568b-b6ff-d2f9e7f9f648', 4, NULL, 'Balón volumétrico'),
    ('b11e9b7f-69dd-58e7-93f3-8af58a51da1d', '45dc2f96-f228-5027-a63a-f62601945aab', '108c6816-9128-50ce-b784-a6eaa3a6173e', 4, NULL, 'Erlenmeyer'),
    ('e530a507-92fc-515c-8f9c-60d6b30ebc2f', '45dc2f96-f228-5027-a63a-f62601945aab', 'e2adbdff-cfee-52e8-9a77-35fd7701f1bd', 4, NULL, 'Mortero con pistilo'),
    ('98472744-4009-5faf-b729-08b257a980d3', '45dc2f96-f228-5027-a63a-f62601945aab', '5010c358-aea8-554f-aa4c-2934745fe6cd', 4, NULL, 'Espátula'),
    ('61ca40db-755c-5cbd-9932-e45f5d7c791e', '45dc2f96-f228-5027-a63a-f62601945aab', '4879407a-5079-56ff-9d26-cdda5b70a3c6', 4, NULL, 'Gradilla para tubos'),
    ('68ff4552-d0b4-54f0-8063-81c810dd9124', '45dc2f96-f228-5027-a63a-f62601945aab', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 4, NULL, 'Vidrio de reloj'),
    ('14719fe4-41c3-5f45-86a0-72509f4e6fc0', '45dc2f96-f228-5027-a63a-f62601945aab', 'c530ec2d-44a7-5d48-8819-f3992bf31c4e', 4, NULL, 'Mechero'),
    ('61ae756a-057c-589e-9f2c-3f7a19989bac', '45dc2f96-f228-5027-a63a-f62601945aab', '801a687f-e173-5780-9c32-e9b96b9bafbd', 4, NULL, 'Pinzas para tubo de ensayo'),
    ('4ace7e65-3abb-5934-ad8e-3439ef58cf4f', '45dc2f96-f228-5027-a63a-f62601945aab', 'eae9ccb5-31ab-574d-b4a9-cefaa70a8e07', 4, NULL, 'Bureta'),
    ('2f84f35a-e5f0-5d06-bc91-87620159389f', '45dc2f96-f228-5027-a63a-f62601945aab', 'd4dcaab2-2859-573b-b8cc-5c2e41ee08d9', 4, NULL, 'Varilla de vidrio')
  on conflict (id) do nothing;
  insert into importaciones_formularios (id, nombre_archivo, subido_por, estado, payload, sesion_id, procesado_en)
  values ('88d3a96d-2069-5b06-9971-8f43a1d1e36f', 'Fundamentos_de_Química_MIA__2025-2.xlsx / Práctica 1', v_docente, 'procesado', $j${"archivo": "Fundamentos_de_Química_MIA__2025-2.xlsx", "hoja": "Práctica 1", "practica": "MANEJO DE EQUIPO DE LABORATORIO. DETERMINACIÓN DE MASAS Y VOLÚMENES", "fecha": "2025-08-14", "inicio": "09:00:00", "fin": "12:00:00", "estudiantes": 13, "grupos": 4, "equipos_vidrieria": [{"texto": "Pipeta volumétrica (8 con capacidad de 10 mL y 8 con capacidad de 5 mL)", "cantidad": 16.0}, {"texto": "Pipeta graduada (6 con capacidad de 10 mL y 6 con capacidad de 5 mL)", "cantidad": 16.0}, {"texto": "Pera de succión", "cantidad": 8.0}, {"texto": "Beaker (6 con capacidad de 250 mL y 6 con capacidad de 50 mL)", "cantidad": 8.0}, {"texto": "Balanza digital", "cantidad": 2.0}, {"texto": "Pie de Rey o Vernier", "cantidad": 8.0}, {"texto": "Termómetro", "cantidad": 8.0}, {"texto": "Probeta con capacidad de 50 mL", "cantidad": 8.0}, {"texto": "Pesas de metal de referencia", "cantidad": 8.0}, {"texto": "Condensador", "cantidad": 4.0}, {"texto": "Embudo", "cantidad": 4.0}, {"texto": "Crisol", "cantidad": 4.0}, {"texto": "Tubo thiele", "cantidad": 4.0}, {"texto": "Beaker", "cantidad": 4.0}, {"texto": "Tubo de ensayo", "cantidad": 8.0}, {"texto": "Embudo de separación o decantación", "cantidad": 4.0}, {"texto": "Embudo buchner", "cantidad": 4.0}, {"texto": "Balón volumétrico", "cantidad": 4.0}, {"texto": "Erlenmeyer", "cantidad": 4.0}, {"texto": "Mortero con pistilo", "cantidad": 4.0}, {"texto": "Espátula", "cantidad": 4.0}, {"texto": "Gradilla para tubos", "cantidad": 4.0}, {"texto": "Balanza digital", "cantidad": 3.0}, {"texto": "Vidrio de reloj", "cantidad": 4.0}, {"texto": "Mechero", "cantidad": 4.0}, {"texto": "Pinzas para tubo de ensayo", "cantidad": 4.0}, {"texto": "Bureta", "cantidad": 4.0}, {"texto": "Varilla de vidrio", "cantidad": 4.0}], "reactivos": [{"texto": "Agua destilada", "cantidad": 4.0, "unidad": "frasco lavador", "concentracion": null}], "observaciones": "Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00"}$j$::jsonb, '8dfa659b-b658-577e-b553-8cb5b4b4267b', now()) on conflict (id) do nothing;

  -- ---------- Práctica 2: Propiedades físicas 1 PARTE 1 Determinación de densidades (sólido y lí
  insert into practicas (id, codigo, nombre, asignatura, programa, laboratorio_id, docente_responsable_id, duracion_min)
  values ('cf7f730e-1a36-54c7-bca3-03dc22b6d643', 'FQ-P02', 'Propiedades físicas 1 PARTE 1 Determinación de densidades (sólido y líquido) y viscosidad', 'Fundamentos de Química', 'MIA', v_lab, v_docente, 180) on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('b7a0792d-f801-57bc-8c0a-0c91864590cf', 'cf7f730e-1a36-54c7-bca3-03dc22b6d643', v_docente, v_lab, 13, 4, timestamptz '2025-08-21 09:00:00-05', timestamptz '2025-08-21 12:00:00-05', 'solicitada', 'Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('92d36deb-4cac-51ca-abde-5076968405b9', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', '6f916b68-b7c2-5a48-b083-11a624774bba', 400, 'mL', NULL, NULL, 'Agua destilada'),
    ('83289c6c-a723-516d-af17-8e866ab0c218', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', 'a44092ba-763d-5e76-832f-44c75090560e', 100, 'mL', NULL, NULL, 'Etanol'),
    ('1f954735-e813-5330-9cb6-5f8ef963ba71', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', '2252fa8a-c2ec-52ac-a8f2-c4c4c7ea3dc0', 200, 'mL', NULL, NULL, 'Glicerina'),
    ('02725074-c9a8-524c-9a57-784815b26759', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', '19f45963-56fc-500a-9567-d0ec0714df92', 100, 'g', NULL, 'Error de escritura en el original (Coruro).', 'Coruro de sodio sólido')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('3727531f-8318-591e-9e73-070840aad786', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', '19daf60e-b108-5e55-89df-83f7c3a073be', 2, NULL, 'Balanza digital'),
    ('b10ee280-7128-5b67-95ad-3e7800d0ccd8', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', 'ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 16, NULL, 'Probeta graduada de 25 mL | Probeta graduada de 100 mL'),
    ('32c1b438-0c5a-5f50-8cbf-966b79742efe', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', 'ef803188-2ef7-5c7d-97d1-2266d0d1d99b', 8, NULL, 'Pie de rey o Vernier'),
    ('7c1c69fb-015e-5e81-b51d-ccb51565bbbd', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', '96ec5fdf-0007-5994-8228-9a225f2daaaa', 8, NULL, 'Termómetro como mínimo 0 - 100 ºC'),
    ('050fdbca-67c0-5ada-8745-7022d76238b3', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', 'cf78a03f-97ed-51a5-8993-b67b0faaf064', 8, NULL, 'Picnómetro'),
    ('cec67258-d986-5943-89bc-f926cd405ae1', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', '749be4a7-1914-5f29-ac9e-c4aef193c55f', 8, NULL, 'Sólido de forma geometrica regular (cubo cilindro y esfera)'),
    ('442ab34c-983e-5aac-ad0c-08d4e6b595c3', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 8, NULL, 'Beaker 50-100 mL'),
    ('5ff1781f-db72-5788-879b-b6abf09c365c', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', '3e001c5e-a731-5d33-be2b-98e43006631b', NULL, NULL, 'Recipiente o beaker para residuos líquidos'),
    ('e6fbb7e5-ce78-5a58-b333-e9b5aa77e44d', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', 'b96a88d8-e7c2-5494-8478-d5c944ce276c', 8, NULL, 'Cronómetro'),
    ('04da3417-b084-560a-bae1-fc551e15fd98', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', '83476430-e1a9-5b99-958a-ed5beb19e6c2', 8, NULL, 'Canicas'),
    ('c0f244f7-7898-58cc-898e-6bc93f60fd30', 'b7a0792d-f801-57bc-8c0a-0c91864590cf', '544eb5bd-c301-54ca-afaf-d0e24e349d26', 2, NULL, 'Baño maría')
  on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('b6d796b8-8f16-5849-a557-5fe21a7e54e0', 'cf7f730e-1a36-54c7-bca3-03dc22b6d643', v_docente, v_lab, 12, NULL, timestamptz '2025-08-21 13:00:00-05', timestamptz '2025-08-21 16:00:00-05', 'solicitada', 'Segunda sesión del mismo día, deducida de las observaciones del formulario. Mismos materiales y reactivos que la primera.', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('008b3962-ab1f-503f-a95b-3068ed65d39e', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', '6f916b68-b7c2-5a48-b083-11a624774bba', 400, 'mL', NULL, NULL, 'Agua destilada'),
    ('e32f652c-29ac-5ddc-a952-8d915788f574', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', 'a44092ba-763d-5e76-832f-44c75090560e', 100, 'mL', NULL, NULL, 'Etanol'),
    ('b2210249-46e5-5d44-a3ce-a3d42525c607', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', '2252fa8a-c2ec-52ac-a8f2-c4c4c7ea3dc0', 200, 'mL', NULL, NULL, 'Glicerina'),
    ('dd55ca2f-cf26-5197-bb67-b91535f104ce', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', '19f45963-56fc-500a-9567-d0ec0714df92', 100, 'g', NULL, 'Error de escritura en el original (Coruro).', 'Coruro de sodio sólido')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('db32f4c5-9ccc-5ae4-b0c1-caf3d544af5e', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', '19daf60e-b108-5e55-89df-83f7c3a073be', 2, NULL, 'Balanza digital'),
    ('e32fc524-d019-5410-a560-17addca0d525', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', 'ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 16, NULL, 'Probeta graduada de 25 mL | Probeta graduada de 100 mL'),
    ('85ae322d-0a1e-5d84-a214-452c80703248', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', 'ef803188-2ef7-5c7d-97d1-2266d0d1d99b', 8, NULL, 'Pie de rey o Vernier'),
    ('6c0a7cdf-7e68-570e-a266-781866175b51', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', '96ec5fdf-0007-5994-8228-9a225f2daaaa', 8, NULL, 'Termómetro como mínimo 0 - 100 ºC'),
    ('ff279758-8df3-5345-94ae-519087ae4ab1', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', 'cf78a03f-97ed-51a5-8993-b67b0faaf064', 8, NULL, 'Picnómetro'),
    ('466871c4-19a1-522f-8591-21a4b320caed', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', '749be4a7-1914-5f29-ac9e-c4aef193c55f', 8, NULL, 'Sólido de forma geometrica regular (cubo cilindro y esfera)'),
    ('ac054a99-be7f-5f17-9bcf-9281c01eba9f', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 8, NULL, 'Beaker 50-100 mL'),
    ('c34319f1-89e8-5184-a1e9-c89ea54f1261', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', '3e001c5e-a731-5d33-be2b-98e43006631b', NULL, NULL, 'Recipiente o beaker para residuos líquidos'),
    ('b959d27d-13f9-583c-902d-e285971f2d0a', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', 'b96a88d8-e7c2-5494-8478-d5c944ce276c', 8, NULL, 'Cronómetro'),
    ('4d5ea898-0138-541c-9af0-d15ea186b186', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', '83476430-e1a9-5b99-958a-ed5beb19e6c2', 8, NULL, 'Canicas'),
    ('51786ce1-2897-5bad-abae-f4aa3a9e3f60', 'b6d796b8-8f16-5849-a557-5fe21a7e54e0', '544eb5bd-c301-54ca-afaf-d0e24e349d26', 2, NULL, 'Baño maría')
  on conflict (id) do nothing;
  insert into importaciones_formularios (id, nombre_archivo, subido_por, estado, payload, sesion_id, procesado_en)
  values ('4f4780da-761b-5c98-ab09-0b6e4434ba21', 'Fundamentos_de_Química_MIA__2025-2.xlsx / Práctica 2', v_docente, 'procesado', $j${"archivo": "Fundamentos_de_Química_MIA__2025-2.xlsx", "hoja": "Práctica 2", "practica": "Propiedades físicas 1 PARTE 1 Determinación de densidades (sólido y líquido) y viscosidad", "fecha": "2025-08-21", "inicio": "09:00:00", "fin": "12:00:00", "estudiantes": 13, "grupos": 4, "equipos_vidrieria": [{"texto": "Balanza digital", "cantidad": 2.0}, {"texto": "Probeta graduada de 25 mL", "cantidad": 8.0}, {"texto": "Pie de rey o Vernier", "cantidad": 8.0}, {"texto": "Termómetro como mínimo 0 - 100 ºC", "cantidad": 8.0}, {"texto": "Picnómetro", "cantidad": 8.0}, {"texto": "Sólido de forma geometrica regular (cubo cilindro y esfera)", "cantidad": 8.0}, {"texto": "Beaker 50-100 mL", "cantidad": 8.0}, {"texto": "Recipiente o beaker para residuos líquidos", "cantidad": null}, {"texto": "Probeta graduada de 100 mL", "cantidad": 8.0}, {"texto": "Cronómetro", "cantidad": 8.0}, {"texto": "Canicas", "cantidad": 8.0}, {"texto": "Baño maría", "cantidad": 2.0}], "reactivos": [{"texto": "Agua destilada", "cantidad": 400.0, "unidad": "mL", "concentracion": null}, {"texto": "Etanol", "cantidad": 100.0, "unidad": "mL", "concentracion": null}, {"texto": "Glicerina", "cantidad": 200.0, "unidad": "mL", "concentracion": null}, {"texto": "Coruro de sodio sólido", "cantidad": 100.0, "unidad": "g", "concentracion": null}], "observaciones": "Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00"}$j$::jsonb, 'b7a0792d-f801-57bc-8c0a-0c91864590cf', now()) on conflict (id) do nothing;

  -- ---------- Práctica 3: Propiedades físicas 1 PARTE 2 Temperatura de Fusión Y Ebullición, Vola
  insert into practicas (id, codigo, nombre, asignatura, programa, laboratorio_id, docente_responsable_id, duracion_min)
  values ('75bb69fe-b69a-5120-9103-804136260ea4', 'FQ-P03', 'Propiedades físicas 1 PARTE 2 Temperatura de Fusión Y Ebullición, Volatilidad, Tensión Superficial, Viscosidad.', 'Fundamentos de Química', 'MIA', v_lab, v_docente, 180) on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('c68f9d7d-e15f-586c-8bff-fb386ab29eac', '75bb69fe-b69a-5120-9103-804136260ea4', v_docente, v_lab, 13, 4, timestamptz '2025-08-28 09:00:00-05', timestamptz '2025-08-28 12:00:00-05', 'solicitada', 'Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('502b1ef3-21cb-5f5e-b629-eff3a8248b4d', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', '6f916b68-b7c2-5a48-b083-11a624774bba', 8, 'frasco lavador', NULL, NULL, 'Agua destilada'),
    ('096cfa37-6540-5a76-9d09-921e3e91abde', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', '000bde2f-a1cf-5da0-a8dd-389aa77b3aff', 50, 'g', NULL, NULL, 'Acetanilida'),
    ('2c5de53b-a29e-5be5-9b92-8ad7834b1c45', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', 'a44092ba-763d-5e76-832f-44c75090560e', 50, 'mL', 'Absoluto', NULL, 'Etanol'),
    ('190b4892-e996-56d9-8b7b-62bf6902d8dc', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', 'b06a3b93-88e4-571f-b645-91cef3d48bff', 100, 'mL', NULL, NULL, 'Jabón líquido'),
    ('f90604a8-4f7d-542f-9769-672a80d6579c', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', 'f73354f1-c921-52da-9f08-6fc8fed2f3d5', 800, 'mL', NULL, NULL, 'Aceite mineral')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('a6764aec-d45c-5044-9469-2067905256ef', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', '96ec5fdf-0007-5994-8228-9a225f2daaaa', 8, NULL, 'Termómetro'),
    ('85fd3b8a-c16d-5b69-946e-8728863c2eef', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', '84fa36fc-d71a-582d-b46b-b502ad05541c', 18, NULL, 'Capilares'),
    ('423da50c-92f8-5d41-915c-5f1ece933519', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', 'd1cc526a-099b-59d6-9bd8-056aa0ebc2a6', 8, NULL, 'Bandas de caucho'),
    ('2d351951-d154-56c2-a45b-714e91d964bd', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 16, NULL, 'Beakers con capacidad de 50 - 100 mL'),
    ('7984334b-3917-58c8-aa1f-ae547f81ba64', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', '703eb001-8968-5163-951d-6de7224d779c', 10, NULL, 'Tubo de ensayo largo'),
    ('d893c5e6-3b62-5cfc-9bf6-95151467b270', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', 'c530ec2d-44a7-5d48-8819-f3992bf31c4e', 8, NULL, 'Mechero de alcohol'),
    ('575183ea-4b87-5abc-87d9-721ca989b414', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', '23d6090e-5d9f-5d90-af05-7fc51b4d5d7f', 8, NULL, 'Plancha de calentamiento'),
    ('485c98b4-2092-5c26-8af0-671d50a46abc', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', '5e05c62d-b87e-51c0-baec-8c59edce24ee', 8, NULL, 'Soporte universal'),
    ('cca38db2-a0b9-586d-a677-8a8428fd9304', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', 'a451b76f-52c8-5d50-b7ff-904cb7d10bb1', 8, NULL, 'Placa de calentamiento (schott)'),
    ('780ca00c-3452-59eb-b96d-516fa83eaf46', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', 'cb92a1f9-4e51-5dde-930c-106e0220257f', 8, NULL, 'Pinzas'),
    ('f14a0dc0-eab1-52a4-b634-1abb7e1d1ab0', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', 'ff52895c-ffad-5e54-b8f4-27127f0e1a22', 8, NULL, 'Nuez'),
    ('a761106f-8ae3-561c-afae-40afcfc9937d', 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', '51074689-415c-5425-8438-740eb7b00638', 8, NULL, 'Tubo de Thiele')
  on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('64d94d3a-253e-57a2-8098-d97a50fa7dad', '75bb69fe-b69a-5120-9103-804136260ea4', v_docente, v_lab, 12, NULL, timestamptz '2025-08-28 13:00:00-05', timestamptz '2025-08-28 16:00:00-05', 'solicitada', 'Segunda sesión del mismo día, deducida de las observaciones del formulario. Mismos materiales y reactivos que la primera.', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('d8e3beee-91ec-5e54-baf0-ae6c9c49f4c2', '64d94d3a-253e-57a2-8098-d97a50fa7dad', '6f916b68-b7c2-5a48-b083-11a624774bba', 8, 'frasco lavador', NULL, NULL, 'Agua destilada'),
    ('7c62f760-fe49-5589-a3b7-cf47821740b0', '64d94d3a-253e-57a2-8098-d97a50fa7dad', '000bde2f-a1cf-5da0-a8dd-389aa77b3aff', 50, 'g', NULL, NULL, 'Acetanilida'),
    ('45546fbd-3ac0-5a89-8d7b-b34aa7bc2b65', '64d94d3a-253e-57a2-8098-d97a50fa7dad', 'a44092ba-763d-5e76-832f-44c75090560e', 50, 'mL', 'Absoluto', NULL, 'Etanol'),
    ('66d2228e-6889-5146-af09-90e0eba66ae4', '64d94d3a-253e-57a2-8098-d97a50fa7dad', 'b06a3b93-88e4-571f-b645-91cef3d48bff', 100, 'mL', NULL, NULL, 'Jabón líquido'),
    ('c628761b-717f-504f-862c-c5e6a69e4f61', '64d94d3a-253e-57a2-8098-d97a50fa7dad', 'f73354f1-c921-52da-9f08-6fc8fed2f3d5', 800, 'mL', NULL, NULL, 'Aceite mineral')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('28f5d955-0d25-570c-bebb-fea4f797634e', '64d94d3a-253e-57a2-8098-d97a50fa7dad', '96ec5fdf-0007-5994-8228-9a225f2daaaa', 8, NULL, 'Termómetro'),
    ('944f5966-985d-5f85-bceb-34bc3415f662', '64d94d3a-253e-57a2-8098-d97a50fa7dad', '84fa36fc-d71a-582d-b46b-b502ad05541c', 18, NULL, 'Capilares'),
    ('cee82196-0b52-5f50-ae37-939a78557c7f', '64d94d3a-253e-57a2-8098-d97a50fa7dad', 'd1cc526a-099b-59d6-9bd8-056aa0ebc2a6', 8, NULL, 'Bandas de caucho'),
    ('2be1ac21-9c86-5184-a727-1e582ea0e952', '64d94d3a-253e-57a2-8098-d97a50fa7dad', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 16, NULL, 'Beakers con capacidad de 50 - 100 mL'),
    ('68ef7bbc-8c13-54b7-96e0-b78d9159b5f4', '64d94d3a-253e-57a2-8098-d97a50fa7dad', '703eb001-8968-5163-951d-6de7224d779c', 10, NULL, 'Tubo de ensayo largo'),
    ('c53b8f8d-fccb-5a5e-83ee-6afd1b338a80', '64d94d3a-253e-57a2-8098-d97a50fa7dad', 'c530ec2d-44a7-5d48-8819-f3992bf31c4e', 8, NULL, 'Mechero de alcohol'),
    ('16710fbb-29cd-5f4b-a8a9-3f13ed92f72f', '64d94d3a-253e-57a2-8098-d97a50fa7dad', '23d6090e-5d9f-5d90-af05-7fc51b4d5d7f', 8, NULL, 'Plancha de calentamiento'),
    ('1df1b5ec-36b2-5c76-a5f8-7579d11f6dbc', '64d94d3a-253e-57a2-8098-d97a50fa7dad', '5e05c62d-b87e-51c0-baec-8c59edce24ee', 8, NULL, 'Soporte universal'),
    ('53465e3d-f601-5bbf-810b-2850a0397c63', '64d94d3a-253e-57a2-8098-d97a50fa7dad', 'a451b76f-52c8-5d50-b7ff-904cb7d10bb1', 8, NULL, 'Placa de calentamiento (schott)'),
    ('9ea54599-099e-5707-8041-7364b444599e', '64d94d3a-253e-57a2-8098-d97a50fa7dad', 'cb92a1f9-4e51-5dde-930c-106e0220257f', 8, NULL, 'Pinzas'),
    ('c339c957-23b9-5ee5-b73a-6f340e2ab20d', '64d94d3a-253e-57a2-8098-d97a50fa7dad', 'ff52895c-ffad-5e54-b8f4-27127f0e1a22', 8, NULL, 'Nuez'),
    ('2f96404f-7c05-54ba-8eb8-15cbd537f2f1', '64d94d3a-253e-57a2-8098-d97a50fa7dad', '51074689-415c-5425-8438-740eb7b00638', 8, NULL, 'Tubo de Thiele')
  on conflict (id) do nothing;
  insert into importaciones_formularios (id, nombre_archivo, subido_por, estado, payload, sesion_id, procesado_en)
  values ('649d9a61-0029-5bad-aa8f-cf340d4dd357', 'Fundamentos_de_Química_MIA__2025-2.xlsx / Práctica 3', v_docente, 'procesado', $j${"archivo": "Fundamentos_de_Química_MIA__2025-2.xlsx", "hoja": "Práctica 3", "practica": "Propiedades físicas 1 PARTE 2 Temperatura de Fusión Y Ebullición, Volatilidad, Tensión Superficial, Viscosidad.", "fecha": "2025-08-28", "inicio": "09:00:00", "fin": "12:00:00", "estudiantes": 13, "grupos": 4, "equipos_vidrieria": [{"texto": "Termómetro", "cantidad": 8.0}, {"texto": "Capilares", "cantidad": 18.0}, {"texto": "Bandas de caucho", "cantidad": 8.0}, {"texto": "Beakers con capacidad de 50 - 100 mL", "cantidad": 16.0}, {"texto": "Tubo de ensayo largo", "cantidad": 10.0}, {"texto": "Mechero de alcohol", "cantidad": 8.0}, {"texto": "Plancha de calentamiento", "cantidad": 8.0}, {"texto": "Soporte universal", "cantidad": 8.0}, {"texto": "Placa de calentamiento (schott)", "cantidad": 8.0}, {"texto": "Pinzas", "cantidad": 8.0}, {"texto": "Nuez", "cantidad": 8.0}, {"texto": "Tubo de Thiele", "cantidad": 8.0}], "reactivos": [{"texto": "Agua destilada", "cantidad": 8.0, "unidad": "frasco lavador", "concentracion": null}, {"texto": "Acetanilida", "cantidad": 50.0, "unidad": "g", "concentracion": null}, {"texto": "Etanol", "cantidad": 50.0, "unidad": "ml", "concentracion": "Absoluto"}, {"texto": "Jabón líquido", "cantidad": 100.0, "unidad": "ml", "concentracion": null}, {"texto": "Aceite mineral", "cantidad": 800.0, "unidad": "ml", "concentracion": null}], "observaciones": "Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00"}$j$::jsonb, 'c68f9d7d-e15f-586c-8bff-fb386ab29eac', now()) on conflict (id) do nothing;

  -- ---------- Práctica 4: SEPARACIÓN DE MEZCLAS parte 1: Separación de mezcla sólida (Ésta práct
  insert into practicas (id, codigo, nombre, asignatura, programa, laboratorio_id, docente_responsable_id, duracion_min)
  values ('cba36c58-93d4-539b-a27a-c00f1123b2c7', 'FQ-P04', 'SEPARACIÓN DE MEZCLAS parte 1: Separación de mezcla sólida (Ésta práctica se realizará en dos sesiones)', 'Fundamentos de Química', 'MIA', v_lab, v_docente, 180) on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('90cc4979-5096-5925-a97f-36d5f8fdafd0', 'cba36c58-93d4-539b-a27a-c00f1123b2c7', v_docente, v_lab, 13, 4, timestamptz '2025-09-04 09:00:00-05', timestamptz '2025-09-04 12:00:00-05', 'solicitada', 'Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('d0d0569c-4ad2-5578-b21e-977b121457b1', '90cc4979-5096-5925-a97f-36d5f8fdafd0', '6f916b68-b7c2-5a48-b083-11a624774bba', 8, 'frasco lavador', NULL, NULL, 'Agua destilada'),
    ('1565c264-24e3-51ce-a049-9bce4e90e49c', '90cc4979-5096-5925-a97f-36d5f8fdafd0', 'ddc90e97-bf01-5f9b-8bb8-54f8cef215a3', 25, 'g', NULL, NULL, 'Colorante'),
    ('2f04cf96-17d9-546a-853e-2e46c6f7778f', '90cc4979-5096-5925-a97f-36d5f8fdafd0', 'af609bdc-7c82-5eb5-bc33-1bfe3ff5d2e3', 20, 'g', NULL, NULL, 'carbonato de calcio (CaCO3)'),
    ('9755d6e1-1a27-5275-8c15-a180b4ba0d7e', '90cc4979-5096-5925-a97f-36d5f8fdafd0', '19f45963-56fc-500a-9567-d0ec0714df92', 20, 'g', NULL, NULL, 'cloruro de sodio (NaCl)'),
    ('da922a00-9d05-5a2b-b328-8fab82829f31', '90cc4979-5096-5925-a97f-36d5f8fdafd0', 'a2a45edd-5007-5ac7-8f5c-3f516c701570', 20, 'g', NULL, NULL, 'dióxido de silicio (SiO2)'),
    ('417601ce-8462-5d47-ba32-4ca35d9cdf42', '90cc4979-5096-5925-a97f-36d5f8fdafd0', 'e585e729-6109-59fa-93bf-0fe06dd87c6a', 80, 'mL', '4 M', NULL, 'Ácido clorhídrico 4 M')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('44720c87-f790-54e2-a3ec-7201f781c61e', '90cc4979-5096-5925-a97f-36d5f8fdafd0', '78c172c7-1d3c-5e75-83b9-1daa4f09c4c0', 16, NULL, 'Papel filtro'),
    ('c725721f-314b-5dff-a4d8-d0d0e798775a', '90cc4979-5096-5925-a97f-36d5f8fdafd0', 'ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 8, NULL, 'Probeta'),
    ('16ef7eb3-b02f-58ab-ae81-6bc3d39ef34e', '90cc4979-5096-5925-a97f-36d5f8fdafd0', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 8, NULL, 'Vidrio de reloj'),
    ('f5557170-b58b-5c52-97ea-221696c50bef', '90cc4979-5096-5925-a97f-36d5f8fdafd0', 'f8550b72-6e14-54a7-bfbe-b8510e15e150', 8, NULL, 'Cápsula de porcelana'),
    ('d3dc24a7-3d18-5c14-b593-b3ce7d24c687', '90cc4979-5096-5925-a97f-36d5f8fdafd0', '5010c358-aea8-554f-aa4c-2934745fe6cd', 8, NULL, 'Espátula'),
    ('cde768db-8ff8-5016-a714-8689f1fc971d', '90cc4979-5096-5925-a97f-36d5f8fdafd0', 'd4dcaab2-2859-573b-b8cc-5c2e41ee08d9', 8, NULL, 'Varilla de agitación'),
    ('f50dd7f1-ff93-5b0b-bc1a-32fd8fe6f9e9', '90cc4979-5096-5925-a97f-36d5f8fdafd0', '0eac8838-f54f-5db6-ba5f-aec15a9e241e', 8, NULL, 'Embudo de separación'),
    ('ebe3b75d-5b49-5a70-b3af-0368d8f6ee3d', '90cc4979-5096-5925-a97f-36d5f8fdafd0', '108c6816-9128-50ce-b784-a6eaa3a6173e', 16, NULL, 'Erlenmeyer'),
    ('1011ff73-a6f8-59df-a716-0019751c4710', '90cc4979-5096-5925-a97f-36d5f8fdafd0', '96ec5fdf-0007-5994-8228-9a225f2daaaa', 8, NULL, 'Termómetro'),
    ('34053868-69fe-5f5b-84e5-04386e3ebf2a', '90cc4979-5096-5925-a97f-36d5f8fdafd0', 'a451b76f-52c8-5d50-b7ff-904cb7d10bb1', 8, NULL, 'Placa de calentamiento Schott'),
    ('21f71a4a-4174-5cf9-b3d7-4358197cb588', '90cc4979-5096-5925-a97f-36d5f8fdafd0', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 16, NULL, 'Beaker 250 mL | Beaker 400 mL'),
    ('8f8e9d77-b460-50e8-a4e3-521308f6920d', '90cc4979-5096-5925-a97f-36d5f8fdafd0', 'c530ec2d-44a7-5d48-8819-f3992bf31c4e', 8, NULL, 'Mechero'),
    ('b2a19252-98a9-5550-ac9e-8603a71df8b4', '90cc4979-5096-5925-a97f-36d5f8fdafd0', '23d6090e-5d9f-5d90-af05-7fc51b4d5d7f', 8, NULL, 'Plancha de calentamiento'),
    ('046995e5-9d35-55eb-8ba8-6f887309f518', '90cc4979-5096-5925-a97f-36d5f8fdafd0', '5e05c62d-b87e-51c0-baec-8c59edce24ee', 8, NULL, 'Soporte universal'),
    ('82991df1-d230-5040-9df5-1967b0fc552e', '90cc4979-5096-5925-a97f-36d5f8fdafd0', 'cb92a1f9-4e51-5dde-930c-106e0220257f', 8, NULL, 'pinzas'),
    ('c987b2fa-8470-5111-a6a5-10d8e5532f85', '90cc4979-5096-5925-a97f-36d5f8fdafd0', 'ff52895c-ffad-5e54-b8f4-27127f0e1a22', 8, NULL, 'nueces'),
    ('778e6d78-4cfe-5fda-84c4-432424231c1f', '90cc4979-5096-5925-a97f-36d5f8fdafd0', '5961f497-6b82-54f8-a674-07788ee1c013', 8, NULL, 'Embudo de vidrio')
  on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('aa72b636-2ab2-5991-8101-172294fbda10', 'cba36c58-93d4-539b-a27a-c00f1123b2c7', v_docente, v_lab, 12, NULL, timestamptz '2025-09-04 13:00:00-05', timestamptz '2025-09-04 16:00:00-05', 'solicitada', 'Segunda sesión del mismo día, deducida de las observaciones del formulario. Mismos materiales y reactivos que la primera.', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('151d540b-8e4b-5728-8312-3b7ae3f73508', 'aa72b636-2ab2-5991-8101-172294fbda10', '6f916b68-b7c2-5a48-b083-11a624774bba', 8, 'frasco lavador', NULL, NULL, 'Agua destilada'),
    ('e4b5338d-b35e-5dd7-86f0-c337ab58d3b5', 'aa72b636-2ab2-5991-8101-172294fbda10', 'ddc90e97-bf01-5f9b-8bb8-54f8cef215a3', 25, 'g', NULL, NULL, 'Colorante'),
    ('a81dd7c4-91d5-530c-99f3-9f80fb6d2409', 'aa72b636-2ab2-5991-8101-172294fbda10', 'af609bdc-7c82-5eb5-bc33-1bfe3ff5d2e3', 20, 'g', NULL, NULL, 'carbonato de calcio (CaCO3)'),
    ('8d9466d5-29b2-5686-9f91-817d0a0f0f8e', 'aa72b636-2ab2-5991-8101-172294fbda10', '19f45963-56fc-500a-9567-d0ec0714df92', 20, 'g', NULL, NULL, 'cloruro de sodio (NaCl)'),
    ('cd81bb89-85e3-55e3-b2c5-0d37976683c9', 'aa72b636-2ab2-5991-8101-172294fbda10', 'a2a45edd-5007-5ac7-8f5c-3f516c701570', 20, 'g', NULL, NULL, 'dióxido de silicio (SiO2)'),
    ('53ed30aa-848d-552c-a31a-0a59036b8c79', 'aa72b636-2ab2-5991-8101-172294fbda10', 'e585e729-6109-59fa-93bf-0fe06dd87c6a', 80, 'mL', '4 M', NULL, 'Ácido clorhídrico 4 M')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('e299e18a-ba98-58b6-88d1-f2ca11f81750', 'aa72b636-2ab2-5991-8101-172294fbda10', '78c172c7-1d3c-5e75-83b9-1daa4f09c4c0', 16, NULL, 'Papel filtro'),
    ('cc088d46-dc2a-5650-a82d-2e875e85a143', 'aa72b636-2ab2-5991-8101-172294fbda10', 'ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 8, NULL, 'Probeta'),
    ('d9f73063-9e2d-588e-b803-c832b6af48aa', 'aa72b636-2ab2-5991-8101-172294fbda10', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 8, NULL, 'Vidrio de reloj'),
    ('0bf516c8-8d12-5779-92f5-6b5e24066ea3', 'aa72b636-2ab2-5991-8101-172294fbda10', 'f8550b72-6e14-54a7-bfbe-b8510e15e150', 8, NULL, 'Cápsula de porcelana'),
    ('f6a7b8a7-a61f-5858-9192-3212dbcd767f', 'aa72b636-2ab2-5991-8101-172294fbda10', '5010c358-aea8-554f-aa4c-2934745fe6cd', 8, NULL, 'Espátula'),
    ('44c57450-51bf-5b6b-8b78-3d73803e73af', 'aa72b636-2ab2-5991-8101-172294fbda10', 'd4dcaab2-2859-573b-b8cc-5c2e41ee08d9', 8, NULL, 'Varilla de agitación'),
    ('cc1f27fd-ad9d-506a-a831-4ebed5f52bba', 'aa72b636-2ab2-5991-8101-172294fbda10', '0eac8838-f54f-5db6-ba5f-aec15a9e241e', 8, NULL, 'Embudo de separación'),
    ('150d46b9-ccdf-5c03-bdcc-60f79d02fc81', 'aa72b636-2ab2-5991-8101-172294fbda10', '108c6816-9128-50ce-b784-a6eaa3a6173e', 16, NULL, 'Erlenmeyer'),
    ('085fb118-8591-50b7-979a-0cbc911ee3cd', 'aa72b636-2ab2-5991-8101-172294fbda10', '96ec5fdf-0007-5994-8228-9a225f2daaaa', 8, NULL, 'Termómetro'),
    ('94b1ecba-11ea-5833-bb01-d563b2d29094', 'aa72b636-2ab2-5991-8101-172294fbda10', 'a451b76f-52c8-5d50-b7ff-904cb7d10bb1', 8, NULL, 'Placa de calentamiento Schott'),
    ('60ec5c3e-5c2c-5d32-8f7a-979d885722bc', 'aa72b636-2ab2-5991-8101-172294fbda10', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 16, NULL, 'Beaker 250 mL | Beaker 400 mL'),
    ('a7eee9e8-7006-52a3-a352-6de84e811918', 'aa72b636-2ab2-5991-8101-172294fbda10', 'c530ec2d-44a7-5d48-8819-f3992bf31c4e', 8, NULL, 'Mechero'),
    ('ba67005f-35f1-54b0-99b2-48c0e9f27713', 'aa72b636-2ab2-5991-8101-172294fbda10', '23d6090e-5d9f-5d90-af05-7fc51b4d5d7f', 8, NULL, 'Plancha de calentamiento'),
    ('49a72547-2de8-51ec-a235-8e09d82565c7', 'aa72b636-2ab2-5991-8101-172294fbda10', '5e05c62d-b87e-51c0-baec-8c59edce24ee', 8, NULL, 'Soporte universal'),
    ('4a3a0675-9717-52c4-8966-249d1f63c93e', 'aa72b636-2ab2-5991-8101-172294fbda10', 'cb92a1f9-4e51-5dde-930c-106e0220257f', 8, NULL, 'pinzas'),
    ('99a5bbca-cfc6-5d4c-b587-a195e8f08c70', 'aa72b636-2ab2-5991-8101-172294fbda10', 'ff52895c-ffad-5e54-b8f4-27127f0e1a22', 8, NULL, 'nueces'),
    ('bd409301-23b7-5446-9aed-c90e33eddf00', 'aa72b636-2ab2-5991-8101-172294fbda10', '5961f497-6b82-54f8-a674-07788ee1c013', 8, NULL, 'Embudo de vidrio')
  on conflict (id) do nothing;
  insert into importaciones_formularios (id, nombre_archivo, subido_por, estado, payload, sesion_id, procesado_en)
  values ('a866f3d2-085c-5cd7-85df-fd25b470996b', 'Fundamentos_de_Química_MIA__2025-2.xlsx / Práctica 4', v_docente, 'procesado', $j${"archivo": "Fundamentos_de_Química_MIA__2025-2.xlsx", "hoja": "Práctica 4", "practica": "SEPARACIÓN DE MEZCLAS parte 1: Separación de mezcla sólida (Ésta práctica se realizará en dos sesiones)", "fecha": "2025-09-04", "inicio": "09:00:00", "fin": "12:00:00", "estudiantes": 13, "grupos": 4, "equipos_vidrieria": [{"texto": "Papel filtro", "cantidad": 16.0}, {"texto": "Probeta", "cantidad": 8.0}, {"texto": "Vidrio de reloj", "cantidad": 8.0}, {"texto": "Cápsula de porcelana", "cantidad": 8.0}, {"texto": "Espátula", "cantidad": 8.0}, {"texto": "Varilla de agitación", "cantidad": 8.0}, {"texto": "Embudo de separación", "cantidad": 8.0}, {"texto": "Erlenmeyer", "cantidad": 16.0}, {"texto": "Termómetro", "cantidad": 8.0}, {"texto": "Placa de calentamiento Schott", "cantidad": 8.0}, {"texto": "Beaker 250 mL", "cantidad": 8.0}, {"texto": "Mechero", "cantidad": 8.0}, {"texto": "Plancha de calentamiento", "cantidad": 8.0}, {"texto": "Soporte universal", "cantidad": 8.0}, {"texto": "pinzas", "cantidad": 8.0}, {"texto": "nueces", "cantidad": 8.0}, {"texto": "Beaker 400 mL", "cantidad": 8.0}, {"texto": "Embudo de vidrio", "cantidad": 8.0}], "reactivos": [{"texto": "Agua destilada", "cantidad": 8.0, "unidad": "frasco lavador", "concentracion": null}, {"texto": "Colorante", "cantidad": 25.0, "unidad": "g", "concentracion": null}, {"texto": "carbonato de calcio (CaCO3)", "cantidad": 20.0, "unidad": "g", "concentracion": null}, {"texto": "cloruro de sodio (NaCl)", "cantidad": 20.0, "unidad": "g", "concentracion": null}, {"texto": "dióxido de silicio (SiO2)", "cantidad": 20.0, "unidad": "g", "concentracion": null}, {"texto": "Ácido clorhídrico 4 M", "cantidad": 80.0, "unidad": "mL", "concentracion": "4 M"}], "observaciones": "Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00"}$j$::jsonb, '90cc4979-5096-5925-a97f-36d5f8fdafd0', now()) on conflict (id) do nothing;

  -- ---------- Práctica 5: SEPARACIÓN DE MEZCLAS parte 2: Separación de mezcla líquida y cromatog
  insert into practicas (id, codigo, nombre, asignatura, programa, laboratorio_id, docente_responsable_id, duracion_min)
  values ('6d87d467-2220-55ec-b551-11742999a276', 'FQ-P05', 'SEPARACIÓN DE MEZCLAS parte 2: Separación de mezcla líquida y cromatografía (Ésta práctica se realizará en dos sesiones)', 'Fundamentos de Química', 'MIA', v_lab, v_docente, 180) on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('d0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '6d87d467-2220-55ec-b551-11742999a276', v_docente, v_lab, 13, 4, timestamptz '2025-09-18 09:00:00-05', timestamptz '2025-09-18 12:00:00-05', 'solicitada', 'Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('67bc1453-1bc9-51d1-8100-320abecfad19', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', 'a44092ba-763d-5e76-832f-44c75090560e', 200, 'mL', NULL, NULL, 'Etanol'),
    ('6fed5b2f-3740-509d-a2d8-759a51f13bfd', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '6f916b68-b7c2-5a48-b083-11a624774bba', 8, 'frasco lavador', NULL, NULL, 'Agua destilada'),
    ('7103b48d-e01d-5f3c-a9a9-42202c17ccc7', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', 'ddc90e97-bf01-5f9b-8bb8-54f8cef215a3', 25, 'g', NULL, NULL, 'Colorante'),
    ('98538198-343a-5d2d-8e26-b3fbc39b77d7', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '80bcc97e-06da-5c32-8c28-86d399e0da17', 100, 'mL', NULL, NULL, 'acetato de etilo'),
    ('7638bd81-50eb-5be9-8ac1-f2de7c8a4bc3', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '3002ff7e-c0eb-5297-bb6b-6d2deca85140', 100, 'mL', NULL, NULL, 'Hexano')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('96578a2d-5e92-54da-9ebb-28b04ce16088', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '50190125-4c68-5d2c-a5c6-a56583ffcd48', 8, NULL, 'Pipeta graduadas 10 mL'),
    ('20a89f2c-ac9d-5086-bc57-43dbc967cf81', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '19624741-d380-5689-8eea-62d1a67c61d9', NULL, NULL, 'Perlas de ebullición'),
    ('08012871-2cd2-5df7-863a-7d9cad5514ae', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '703eb001-8968-5163-951d-6de7224d779c', 40, NULL, 'Tubos de ensayo capacidad de 10 mL o más'),
    ('4110dc78-4b12-558c-8685-429d2a06f1ed', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '4879407a-5079-56ff-9d26-cdda5b70a3c6', 8, NULL, 'Gradilla de tubos'),
    ('c74ae9a4-7117-59da-888c-4e42c4164c6b', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', 'ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 8, NULL, 'Probeta'),
    ('af6a451c-e042-5330-b920-e4ca02434cbe', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 16, NULL, 'vidrio reloj'),
    ('e49fbc0c-d5d3-56b9-b0ff-aab2bfd5748f', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '66326b8a-1e44-5072-b1ba-50b72c155dae', 8, NULL, 'Balón de destilación'),
    ('ebc8a405-c15f-598d-b4b2-7deb36810952', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', 'd61dea56-6ef1-5ffe-b1dc-e22a3957d2cf', 8, NULL, 'condensador'),
    ('83b1998b-c7a4-5c0a-b707-34e04e81a18d', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', 'a451b76f-52c8-5d50-b7ff-904cb7d10bb1', 8, NULL, 'Placa de calentamiento'),
    ('60c2ddaa-ead3-5961-a128-6f4275671146', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '96ec5fdf-0007-5994-8228-9a225f2daaaa', 8, NULL, 'Termómetro'),
    ('f5201757-0dc8-58d0-89f4-6bee63079377', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '23d6090e-5d9f-5d90-af05-7fc51b4d5d7f', 8, NULL, 'Plancha de calentamiento'),
    ('95b0f90d-dd4a-5508-a024-4d986c9f4cae', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', 'cb92a1f9-4e51-5dde-930c-106e0220257f', 8, NULL, 'pinzas'),
    ('79fda567-6a8f-5332-b7f3-5bc21cf9f634', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', 'ff52895c-ffad-5e54-b8f4-27127f0e1a22', 8, NULL, 'nueces'),
    ('81527aeb-0af0-5e38-a64d-e866e7cda8d9', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 16, NULL, 'Beaker 50 mL'),
    ('0881be57-27b4-52eb-bdd3-345ab707ab7f', 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', '16eac7b2-b357-5e97-8111-2d441c91a044', 32, NULL, 'Placa cromatográfica')
  on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '6d87d467-2220-55ec-b551-11742999a276', v_docente, v_lab, 12, NULL, timestamptz '2025-09-18 13:00:00-05', timestamptz '2025-09-18 16:00:00-05', 'solicitada', 'Segunda sesión del mismo día, deducida de las observaciones del formulario. Mismos materiales y reactivos que la primera.', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('06ca7c0c-6390-54b7-8061-f93ffa8f26a6', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', 'a44092ba-763d-5e76-832f-44c75090560e', 200, 'mL', NULL, NULL, 'Etanol'),
    ('83348bc9-3b00-598b-8f1c-aacb1b752275', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '6f916b68-b7c2-5a48-b083-11a624774bba', 8, 'frasco lavador', NULL, NULL, 'Agua destilada'),
    ('176d4ac0-ae82-5a9b-932e-c2275a20a804', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', 'ddc90e97-bf01-5f9b-8bb8-54f8cef215a3', 25, 'g', NULL, NULL, 'Colorante'),
    ('86352756-1737-58ff-922b-bb1d849af0d0', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '80bcc97e-06da-5c32-8c28-86d399e0da17', 100, 'mL', NULL, NULL, 'acetato de etilo'),
    ('ded7ed28-7129-59bd-a979-cd94c092ef49', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '3002ff7e-c0eb-5297-bb6b-6d2deca85140', 100, 'mL', NULL, NULL, 'Hexano')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('42d4aada-1118-5e44-8788-76fca2884dd9', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '50190125-4c68-5d2c-a5c6-a56583ffcd48', 8, NULL, 'Pipeta graduadas 10 mL'),
    ('89e814cd-428b-5dd1-bcb9-ebd891c7987f', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '19624741-d380-5689-8eea-62d1a67c61d9', NULL, NULL, 'Perlas de ebullición'),
    ('5dd2102a-edc6-5d4b-95f1-f996276b56a2', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '703eb001-8968-5163-951d-6de7224d779c', 40, NULL, 'Tubos de ensayo capacidad de 10 mL o más'),
    ('3229c3a1-9cfb-5f77-9c95-5ef3c5dbd98a', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '4879407a-5079-56ff-9d26-cdda5b70a3c6', 8, NULL, 'Gradilla de tubos'),
    ('2adf0bc8-b479-5680-9af3-1acc1e609f1c', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', 'ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 8, NULL, 'Probeta'),
    ('d8bd3968-6b3c-5f31-a9f0-06f2943681c1', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 16, NULL, 'vidrio reloj'),
    ('ae040f15-aaf6-509c-912b-2c65b46172c7', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '66326b8a-1e44-5072-b1ba-50b72c155dae', 8, NULL, 'Balón de destilación'),
    ('2b655742-d1e3-538a-8f97-4ca97a546eb7', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', 'd61dea56-6ef1-5ffe-b1dc-e22a3957d2cf', 8, NULL, 'condensador'),
    ('61aeef0a-5997-5dea-9b55-51c38b8e0f94', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', 'a451b76f-52c8-5d50-b7ff-904cb7d10bb1', 8, NULL, 'Placa de calentamiento'),
    ('ea95b067-a27e-57bc-8f3c-c33863bd03d3', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '96ec5fdf-0007-5994-8228-9a225f2daaaa', 8, NULL, 'Termómetro'),
    ('6537c965-67ff-53d8-a374-c78b0c69ed6a', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '23d6090e-5d9f-5d90-af05-7fc51b4d5d7f', 8, NULL, 'Plancha de calentamiento'),
    ('192a1661-6b18-5a96-bff8-1f12b67b0f00', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', 'cb92a1f9-4e51-5dde-930c-106e0220257f', 8, NULL, 'pinzas'),
    ('2ef02a69-2931-5e9e-852b-8aace342a638', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', 'ff52895c-ffad-5e54-b8f4-27127f0e1a22', 8, NULL, 'nueces'),
    ('951013d4-8229-5909-aefb-553ff601753e', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 16, NULL, 'Beaker 50 mL'),
    ('d0c61609-0ddd-541f-a8bd-486b4b1a3f23', 'f78d3491-2f25-5d55-bf51-b8e6160cfc3b', '16eac7b2-b357-5e97-8111-2d441c91a044', 32, NULL, 'Placa cromatográfica')
  on conflict (id) do nothing;
  insert into importaciones_formularios (id, nombre_archivo, subido_por, estado, payload, sesion_id, procesado_en)
  values ('c9cb7204-5e55-56fc-abab-c81e241ce389', 'Fundamentos_de_Química_MIA__2025-2.xlsx / Práctica 5', v_docente, 'procesado', $j${"archivo": "Fundamentos_de_Química_MIA__2025-2.xlsx", "hoja": "Práctica 5", "practica": "SEPARACIÓN DE MEZCLAS parte 2: Separación de mezcla líquida y cromatografía (Ésta práctica se realizará en dos sesiones)", "fecha": "2025-09-18", "inicio": "09:00:00", "fin": "12:00:00", "estudiantes": 13, "grupos": 4, "equipos_vidrieria": [{"texto": "Pipeta graduadas 10 mL", "cantidad": 8.0}, {"texto": "Perlas de ebullición", "cantidad": null}, {"texto": "Tubos de ensayo capacidad de 10 mL o más", "cantidad": 40.0}, {"texto": "Gradilla de tubos", "cantidad": 8.0}, {"texto": "Probeta", "cantidad": 8.0}, {"texto": "vidrio reloj", "cantidad": 16.0}, {"texto": "Balón de destilación", "cantidad": 8.0}, {"texto": "condensador", "cantidad": 8.0}, {"texto": "Placa de calentamiento", "cantidad": 8.0}, {"texto": "Termómetro", "cantidad": 8.0}, {"texto": "Plancha de calentamiento", "cantidad": 8.0}, {"texto": "pinzas", "cantidad": 8.0}, {"texto": "nueces", "cantidad": 8.0}, {"texto": "Beaker 50 mL", "cantidad": 16.0}, {"texto": "Placa cromatográfica", "cantidad": 32.0}], "reactivos": [{"texto": "Etanol", "cantidad": 200.0, "unidad": "mL", "concentracion": null}, {"texto": "Agua destilada", "cantidad": 8.0, "unidad": "frasco lavador", "concentracion": null}, {"texto": "Colorante", "cantidad": 25.0, "unidad": "g", "concentracion": null}, {"texto": "acetato de etilo", "cantidad": 100.0, "unidad": "mL", "concentracion": null}, {"texto": "Hexano", "cantidad": 100.0, "unidad": "mL", "concentracion": null}], "observaciones": "Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00"}$j$::jsonb, 'd0cfb9ab-58a1-56ce-a14f-6ea4e018da4b', now()) on conflict (id) do nothing;

  -- ---------- Práctica 6: Propiedades Químicas
  insert into practicas (id, codigo, nombre, asignatura, programa, laboratorio_id, docente_responsable_id, duracion_min)
  values ('22867208-d195-5d36-aa38-8be3af3e64a9', 'FQ-P06', 'Propiedades Químicas', 'Fundamentos de Química', 'MIA', v_lab, v_docente, 180) on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('effee0ff-b162-55f0-8336-19fa93f6e168', '22867208-d195-5d36-aa38-8be3af3e64a9', v_docente, v_lab, 13, 4, timestamptz '2025-10-02 09:00:00-05', timestamptz '2025-10-02 12:00:00-05', 'solicitada', 'Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('c86f726e-f86f-5c6c-85fc-8ca78714b193', 'effee0ff-b162-55f0-8336-19fa93f6e168', '04ffa719-965c-5b5d-999f-8666c14a75a7', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('eacf30dd-b828-533d-96df-e3cd54733062', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'c3c0623f-9324-566f-99ba-23ee3f55b097', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('547fe07a-1581-518a-87a9-4c3fbba2ced0', 'effee0ff-b162-55f0-8336-19fa93f6e168', '1dc4bb2a-e3e4-5df1-a626-8fb0e00ff7da', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('528abe4b-9f83-5610-826f-1ceb69973ac9', 'effee0ff-b162-55f0-8336-19fa93f6e168', '4b99ec48-e4cb-50b7-a760-9f0df8c0f43a', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('36444f98-fefb-5314-992f-9fc46eab71a8', 'effee0ff-b162-55f0-8336-19fa93f6e168', '06a5bae2-a851-5b04-bf42-5afd44d32dcb', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('a4bc7820-9899-5494-8a00-d42022028b21', 'effee0ff-b162-55f0-8336-19fa93f6e168', '643482de-1b40-5898-be76-92920a30f2ec', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('44817ffd-f898-5871-bd8d-fcf692dd88fd', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'de9a81cc-d0fb-5fd8-8e9c-6f9426bd561d', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('c5ae7be7-0571-56c9-96fa-51da2a0fe88c', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'c731bebc-d041-50e9-a840-fcddc311039c', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('07ee6b71-275a-5f3a-9726-8e632fb77f8e', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'e8a023f1-6edc-59ab-965c-1d77f1f6fa76', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('6b65d517-3882-50b5-9924-cd11aac5343d', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'd76d4c01-6efe-5b9a-9945-115388dd0e37', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('a2a68870-27a5-5aac-81d4-0d743ce7cc9c', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'eb439c96-a9b9-5f24-9ec6-9368560677fd', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('aea47d83-2fe9-5a3d-a58c-e6e2c3de3de5', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'ed45390d-c02d-5a0d-9297-390eae914d64', NULL, 'mL', '1 M', 'Cantidad conjunta del formulario: 50 mL para 6 sustancias en una sola celda.', 'yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),'),
    ('891c7b63-45eb-5576-af3e-309bed260aa4', 'effee0ff-b162-55f0-8336-19fa93f6e168', '19f45963-56fc-500a-9567-d0ec0714df92', NULL, 'mL', '1 M', 'Cantidad conjunta del formulario: 50 mL para 6 sustancias en una sola celda.', 'yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),'),
    ('da1b34a3-7d61-50d8-94f0-8a8832d99bc1', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'dac0281a-7d1c-5abb-af26-522c543d673c', NULL, 'mL', '1 M', 'Cantidad conjunta del formulario: 50 mL para 6 sustancias en una sola celda.', 'yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),'),
    ('164c2c0e-c1e5-580b-bbdf-5101a539919b', 'effee0ff-b162-55f0-8336-19fa93f6e168', '13dacfe8-8eee-5cce-9005-29444f90ae42', NULL, 'mL', '1 M', 'Cantidad conjunta del formulario: 50 mL para 6 sustancias en una sola celda.', 'yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),'),
    ('762dcab1-2253-5e6e-b272-68eb100a5e6d', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'e9a7ff9c-6de5-52ed-aeb4-8e35732ff57d', NULL, 'mL', '1 M', 'Cantidad conjunta del formulario: 50 mL para 6 sustancias en una sola celda.', 'yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),'),
    ('295683f2-8463-5c97-a82e-fd925e637e2c', 'effee0ff-b162-55f0-8336-19fa93f6e168', '948ba644-477a-5c2e-91f0-f7e4ffb6b656', NULL, 'mL', '1 M', 'Cantidad conjunta del formulario: 50 mL para 6 sustancias en una sola celda.', 'yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),'),
    ('750e7a6a-7f4e-5070-90ff-7c3200feffb1', 'effee0ff-b162-55f0-8336-19fa93f6e168', '881cc962-2982-5e3b-912e-18e69bdf4889', 50, 'mL', '0,1 M', NULL, 'NaOH'),
    ('0c08df7a-0aab-5c01-a09e-b3d46c9f886d', 'effee0ff-b162-55f0-8336-19fa93f6e168', '4c2d01e3-7dda-5613-960b-7d0136d3b32a', 50, 'mL', '0,1 M', NULL, 'NaI'),
    ('e45ff51f-5444-5306-b0c2-be1202837626', 'effee0ff-b162-55f0-8336-19fa93f6e168', '7fc953e6-0a2a-5a07-8370-848c750eb5b2', 50, 'mL', '0,1 M', NULL, 'acetato de plomo (Pb(CH3COO)2'),
    ('c4b214b8-1735-52f2-ab74-60cea2aac543', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'e585e729-6109-59fa-93bf-0fe06dd87c6a', 50, 'mL', '0,1 M, 1 M, 4 M', NULL, 'HCl'),
    ('59e1709f-8bf1-56a2-9804-b1756c84dc9e', 'effee0ff-b162-55f0-8336-19fa93f6e168', '51ca596b-528f-535a-85a2-50319c391aac', 50, 'mL', '0,1 M, 1 M, 4 M', NULL, 'HNO3'),
    ('ba5b1c5d-f9a2-5f1e-bd6f-8ae0e8da7a3c', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'a3100cc8-ac60-5db1-9a50-e48a91df9ea5', NULL, 'mL', NULL, 'Cantidad conjunta del formulario: 20 mL para 3 sustancias en una sola celda.', 'Fenolftaleína, anaranjado de metilo, azul de timol'),
    ('2acaf766-7ffb-5ecd-b679-8091788237c7', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'd5879bb3-4850-5e50-9bb6-544555ee6826', NULL, 'mL', NULL, 'Cantidad conjunta del formulario: 20 mL para 3 sustancias en una sola celda.', 'Fenolftaleína, anaranjado de metilo, azul de timol'),
    ('4ca85ba7-216e-5ff8-b871-05800387247c', 'effee0ff-b162-55f0-8336-19fa93f6e168', '53097844-e2d9-512f-a56c-94ccb574ae21', NULL, 'mL', NULL, 'Cantidad conjunta del formulario: 20 mL para 3 sustancias en una sola celda.', 'Fenolftaleína, anaranjado de metilo, azul de timol')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('1622da3c-08b6-5d35-a261-ef92159870db', 'effee0ff-b162-55f0-8336-19fa93f6e168', '703eb001-8968-5163-951d-6de7224d779c', 32, NULL, 'Tubos de ensayo'),
    ('021932ab-e764-53d6-ad74-b096a7d55d3e', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'f8550b72-6e14-54a7-bfbe-b8510e15e150', 8, NULL, 'Cápsula de porcelana'),
    ('293e7a03-11a5-5fc7-9524-8dd45898e7f8', 'effee0ff-b162-55f0-8336-19fa93f6e168', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 8, NULL, 'Vidrio de reloj'),
    ('b750577d-2945-5f40-8136-99055085acd7', 'effee0ff-b162-55f0-8336-19fa93f6e168', '4879407a-5079-56ff-9d26-cdda5b70a3c6', 8, NULL, 'Gradilla para tubos')
  on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('342b9eff-f10a-5765-81a3-92b2c512cfed', '22867208-d195-5d36-aa38-8be3af3e64a9', v_docente, v_lab, 12, NULL, timestamptz '2025-10-02 13:00:00-05', timestamptz '2025-10-02 16:00:00-05', 'solicitada', 'Segunda sesión del mismo día, deducida de las observaciones del formulario. Mismos materiales y reactivos que la primera.', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('97814ed7-0216-54d1-ab70-22703f30e873', '342b9eff-f10a-5765-81a3-92b2c512cfed', '04ffa719-965c-5b5d-999f-8666c14a75a7', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('98aa708d-7544-524e-ace8-a017821e13b2', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'c3c0623f-9324-566f-99ba-23ee3f55b097', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('24e5cb3d-f1bc-5cb6-b86a-91470bd1bb25', '342b9eff-f10a-5765-81a3-92b2c512cfed', '1dc4bb2a-e3e4-5df1-a626-8fb0e00ff7da', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('b80decdf-de62-5124-b636-50384d7c5f67', '342b9eff-f10a-5765-81a3-92b2c512cfed', '4b99ec48-e4cb-50b7-a760-9f0df8c0f43a', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('ec46e0cf-3fd0-5347-ad95-660a47c6f258', '342b9eff-f10a-5765-81a3-92b2c512cfed', '06a5bae2-a851-5b04-bf42-5afd44d32dcb', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('85092733-e80d-515f-b572-71d9a3688b5b', '342b9eff-f10a-5765-81a3-92b2c512cfed', '643482de-1b40-5898-be76-92920a30f2ec', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('bcd40d4c-0fa1-59d5-ba02-5b317a286a05', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'de9a81cc-d0fb-5fd8-8e9c-6f9426bd561d', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('ff32bb93-3304-5c83-b933-26efb0f04684', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'c731bebc-d041-50e9-a840-fcddc311039c', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('a45d06c3-3099-5a1c-aceb-a22187c5daaa', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'e8a023f1-6edc-59ab-965c-1d77f1f6fa76', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('5063b60c-6df8-533e-a7e0-29b8123d8532', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'd76d4c01-6efe-5b9a-9945-115388dd0e37', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('7c2a3ebc-a9be-515c-82d1-1a33a46106a3', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'eb439c96-a9b9-5f24-9ec6-9368560677fd', NULL, 'g', NULL, 'Cantidad conjunta del formulario: 16 g para 11 sustancias en una sola celda.', 'Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).'),
    ('62e67c65-cd75-5c16-88db-9fbef0aef92e', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'ed45390d-c02d-5a0d-9297-390eae914d64', NULL, 'mL', '1 M', 'Cantidad conjunta del formulario: 50 mL para 6 sustancias en una sola celda.', 'yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),'),
    ('2f2cd755-638a-54dc-b89a-ef4fe62fd4d3', '342b9eff-f10a-5765-81a3-92b2c512cfed', '19f45963-56fc-500a-9567-d0ec0714df92', NULL, 'mL', '1 M', 'Cantidad conjunta del formulario: 50 mL para 6 sustancias en una sola celda.', 'yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),'),
    ('ccd5dd85-1073-541d-ae9e-e37eabd7fcea', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'dac0281a-7d1c-5abb-af26-522c543d673c', NULL, 'mL', '1 M', 'Cantidad conjunta del formulario: 50 mL para 6 sustancias en una sola celda.', 'yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),'),
    ('495d08cf-22bc-587c-ad7c-923349fd7cea', '342b9eff-f10a-5765-81a3-92b2c512cfed', '13dacfe8-8eee-5cce-9005-29444f90ae42', NULL, 'mL', '1 M', 'Cantidad conjunta del formulario: 50 mL para 6 sustancias en una sola celda.', 'yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),'),
    ('7fb6fb16-261d-59a6-99ce-c8ad9e39bbbd', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'e9a7ff9c-6de5-52ed-aeb4-8e35732ff57d', NULL, 'mL', '1 M', 'Cantidad conjunta del formulario: 50 mL para 6 sustancias en una sola celda.', 'yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),'),
    ('82f208d8-a1dc-50c1-8597-d87da0832e62', '342b9eff-f10a-5765-81a3-92b2c512cfed', '948ba644-477a-5c2e-91f0-f7e4ffb6b656', NULL, 'mL', '1 M', 'Cantidad conjunta del formulario: 50 mL para 6 sustancias en una sola celda.', 'yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),'),
    ('e9c0ca6f-29e5-5b0e-90a5-a30b2f49a4cd', '342b9eff-f10a-5765-81a3-92b2c512cfed', '881cc962-2982-5e3b-912e-18e69bdf4889', 50, 'mL', '0,1 M', NULL, 'NaOH'),
    ('0ec02989-e066-586d-9545-9da95568d62d', '342b9eff-f10a-5765-81a3-92b2c512cfed', '4c2d01e3-7dda-5613-960b-7d0136d3b32a', 50, 'mL', '0,1 M', NULL, 'NaI'),
    ('884f2bc5-848f-5856-80cd-a403abfbb6da', '342b9eff-f10a-5765-81a3-92b2c512cfed', '7fc953e6-0a2a-5a07-8370-848c750eb5b2', 50, 'mL', '0,1 M', NULL, 'acetato de plomo (Pb(CH3COO)2'),
    ('b2031618-f656-565a-baf8-b66369715dbf', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'e585e729-6109-59fa-93bf-0fe06dd87c6a', 50, 'mL', '0,1 M, 1 M, 4 M', NULL, 'HCl'),
    ('56e95a84-08b9-59dc-a13e-2fc1289bbcb5', '342b9eff-f10a-5765-81a3-92b2c512cfed', '51ca596b-528f-535a-85a2-50319c391aac', 50, 'mL', '0,1 M, 1 M, 4 M', NULL, 'HNO3'),
    ('c947ef51-f40a-5178-b1df-43fc11f955ce', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'a3100cc8-ac60-5db1-9a50-e48a91df9ea5', NULL, 'mL', NULL, 'Cantidad conjunta del formulario: 20 mL para 3 sustancias en una sola celda.', 'Fenolftaleína, anaranjado de metilo, azul de timol'),
    ('6c6606ad-8e1b-5921-b17e-216e9c4a9796', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'd5879bb3-4850-5e50-9bb6-544555ee6826', NULL, 'mL', NULL, 'Cantidad conjunta del formulario: 20 mL para 3 sustancias en una sola celda.', 'Fenolftaleína, anaranjado de metilo, azul de timol'),
    ('a1af2b05-653c-5ded-a0a6-5a08a4f7d26e', '342b9eff-f10a-5765-81a3-92b2c512cfed', '53097844-e2d9-512f-a56c-94ccb574ae21', NULL, 'mL', NULL, 'Cantidad conjunta del formulario: 20 mL para 3 sustancias en una sola celda.', 'Fenolftaleína, anaranjado de metilo, azul de timol')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('10295faa-82ff-5db6-b64a-e558c722f230', '342b9eff-f10a-5765-81a3-92b2c512cfed', '703eb001-8968-5163-951d-6de7224d779c', 32, NULL, 'Tubos de ensayo'),
    ('df943159-f36c-5a0a-8c86-8843b71e74d8', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'f8550b72-6e14-54a7-bfbe-b8510e15e150', 8, NULL, 'Cápsula de porcelana'),
    ('073680cd-a9f5-5869-9542-76a817a25cc7', '342b9eff-f10a-5765-81a3-92b2c512cfed', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 8, NULL, 'Vidrio de reloj'),
    ('2127fa59-4619-5dbb-94d4-adb0d4a3ada3', '342b9eff-f10a-5765-81a3-92b2c512cfed', '4879407a-5079-56ff-9d26-cdda5b70a3c6', 8, NULL, 'Gradilla para tubos')
  on conflict (id) do nothing;
  insert into importaciones_formularios (id, nombre_archivo, subido_por, estado, payload, sesion_id, procesado_en)
  values ('39b83531-c3b8-5de2-937a-a7cd08bd4aac', 'Fundamentos_de_Química_MIA__2025-2.xlsx / Práctica 6', v_docente, 'procesado', $j${"archivo": "Fundamentos_de_Química_MIA__2025-2.xlsx", "hoja": "Práctica 6", "practica": "Propiedades Químicas", "fecha": "2025-10-02", "inicio": "09:00:00", "fin": "12:00:00", "estudiantes": 13, "grupos": 4, "equipos_vidrieria": [{"texto": "Tubos de ensayo", "cantidad": 32.0}, {"texto": "Cápsula de porcelana", "cantidad": 8.0}, {"texto": "Vidrio de reloj", "cantidad": 8.0}, {"texto": "Gradilla para tubos", "cantidad": 8.0}], "reactivos": [{"texto": "Zinc (Zn(s)), Magnesio (Mg(s)), Cobre (Cu(s)), Azufre (S(s)), Hierro (Fe(s)), Aluminio (Al(s)), Sodio (Na(s)), Mercurio (Hg(l)), Yodo (I(s)), Plomo (Pb(s)), Carbono grafito (C(graf)).", "cantidad": 16.0, "unidad": "g", "concentracion": null}, {"texto": "yoduro de potasio (KI(sln)), cloruro de sodio (NaCl(sln)), cloruro de calcio (CaCl2(sln)), cloruro de níquel (NiCl2(sln)), sulfato de cobre pentahidratado (CuSO4.5H2O(sln)), nitrato de bario ((Ba(NO3)2(sln)),", "cantidad": 50.0, "unidad": "mL", "concentracion": "1 M"}, {"texto": "NaOH", "cantidad": 50.0, "unidad": "mL", "concentracion": "0,1 M"}, {"texto": "NaI", "cantidad": 50.0, "unidad": "mL", "concentracion": "0,1 M"}, {"texto": "acetato de plomo (Pb(CH3COO)2", "cantidad": 50.0, "unidad": "mL", "concentracion": "0,1 M"}, {"texto": "HCl", "cantidad": 50.0, "unidad": "mL", "concentracion": "0,1 M, 1 M, 4 M"}, {"texto": "HNO3", "cantidad": 50.0, "unidad": "mL", "concentracion": "0,1 M, 1 M, 4 M"}, {"texto": "Fenolftaleína, anaranjado de metilo, azul de timol", "cantidad": 20.0, "unidad": "mL", "concentracion": null}], "observaciones": "Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00"}$j$::jsonb, 'effee0ff-b162-55f0-8336-19fa93f6e168', now()) on conflict (id) do nothing;

  -- ---------- Práctica 7: ESTEQUIOMETRIA: MÉTODO DE JOB
  insert into practicas (id, codigo, nombre, asignatura, programa, laboratorio_id, docente_responsable_id, duracion_min)
  values ('f57014d6-daf3-5c25-aad9-a2da00f8a649', 'FQ-P07', 'ESTEQUIOMETRIA: MÉTODO DE JOB', 'Fundamentos de Química', 'MIA', v_lab, v_docente, 180) on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('893c2cdb-81db-57be-aa1e-f8c193802d9f', 'f57014d6-daf3-5c25-aad9-a2da00f8a649', v_docente, v_lab, 13, 4, timestamptz '2025-10-09 09:00:00-05', timestamptz '2025-10-09 12:00:00-05', 'solicitada', 'Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('e312d99c-fdf4-5565-80c7-e621675b7ef9', '893c2cdb-81db-57be-aa1e-f8c193802d9f', '881cc962-2982-5e3b-912e-18e69bdf4889', 300, 'mL', '2 M', NULL, 'NaOH (2M)'),
    ('17982435-7b72-5846-b2b7-0fb248039dc2', '893c2cdb-81db-57be-aa1e-f8c193802d9f', 'e585e729-6109-59fa-93bf-0fe06dd87c6a', 300, 'mL', '2 M', NULL, 'HCl (2M)'),
    ('49a6cb32-d719-5b45-b9de-0a79e5352e15', '893c2cdb-81db-57be-aa1e-f8c193802d9f', 'd5879bb3-4850-5e50-9bb6-544555ee6826', 50, 'mL', NULL, NULL, 'Indicador ácido-base: naranja de metilo'),
    ('6bbf1cd8-c1e4-5191-afcb-55ce2e777370', '893c2cdb-81db-57be-aa1e-f8c193802d9f', 'a3100cc8-ac60-5db1-9a50-e48a91df9ea5', 50, 'mL', NULL, NULL, 'Indicador ácido-base: Fenolftaleína')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('ee03ec13-a154-5c7d-a212-5d9012632c4a', '893c2cdb-81db-57be-aa1e-f8c193802d9f', '703eb001-8968-5163-951d-6de7224d779c', 120, NULL, 'Tubos de ensayo'),
    ('7fade4c9-e837-5a82-bc69-f63f23e2aac4', '893c2cdb-81db-57be-aa1e-f8c193802d9f', 'f8550b72-6e14-54a7-bfbe-b8510e15e150', 8, NULL, 'Cápsula de porcelana'),
    ('57188471-d212-5442-a906-d72469a51f7c', '893c2cdb-81db-57be-aa1e-f8c193802d9f', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 8, NULL, 'Vidrio de reloj'),
    ('b14c6654-5e78-556f-94f7-88d5e2a6a965', '893c2cdb-81db-57be-aa1e-f8c193802d9f', '4879407a-5079-56ff-9d26-cdda5b70a3c6', NULL, NULL, 'Gradilla para tubos'),
    ('8778ba93-c316-5d0f-b980-abb7257094f4', '893c2cdb-81db-57be-aa1e-f8c193802d9f', '96ec5fdf-0007-5994-8228-9a225f2daaaa', 8, NULL, 'Termómetro'),
    ('3661eca6-c127-5c47-b56e-26fddf18fb33', '893c2cdb-81db-57be-aa1e-f8c193802d9f', '50190125-4c68-5d2c-a5c6-a56583ffcd48', 16, NULL, 'Pipeta graduada de 10 mL')
  on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('296f75b4-0387-5e08-a2b6-c75c89757e68', 'f57014d6-daf3-5c25-aad9-a2da00f8a649', v_docente, v_lab, 12, NULL, timestamptz '2025-10-09 13:00:00-05', timestamptz '2025-10-09 16:00:00-05', 'solicitada', 'Segunda sesión del mismo día, deducida de las observaciones del formulario. Mismos materiales y reactivos que la primera.', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('61673f64-7a7a-5753-85c8-e9f9baeb28fb', '296f75b4-0387-5e08-a2b6-c75c89757e68', '881cc962-2982-5e3b-912e-18e69bdf4889', 300, 'mL', '2 M', NULL, 'NaOH (2M)'),
    ('047dd5ba-39c7-583e-bcdc-692ef4de1d00', '296f75b4-0387-5e08-a2b6-c75c89757e68', 'e585e729-6109-59fa-93bf-0fe06dd87c6a', 300, 'mL', '2 M', NULL, 'HCl (2M)'),
    ('c444e7b5-8f01-5bcb-bb79-45d7bde80fe2', '296f75b4-0387-5e08-a2b6-c75c89757e68', 'd5879bb3-4850-5e50-9bb6-544555ee6826', 50, 'mL', NULL, NULL, 'Indicador ácido-base: naranja de metilo'),
    ('69fbec4a-f505-5487-8b13-2340fb15586e', '296f75b4-0387-5e08-a2b6-c75c89757e68', 'a3100cc8-ac60-5db1-9a50-e48a91df9ea5', 50, 'mL', NULL, NULL, 'Indicador ácido-base: Fenolftaleína')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('ed89eb3c-d6b7-530f-9766-23509dc714b6', '296f75b4-0387-5e08-a2b6-c75c89757e68', '703eb001-8968-5163-951d-6de7224d779c', 120, NULL, 'Tubos de ensayo'),
    ('38a60b74-6dc0-58d0-8656-9578c401daa3', '296f75b4-0387-5e08-a2b6-c75c89757e68', 'f8550b72-6e14-54a7-bfbe-b8510e15e150', 8, NULL, 'Cápsula de porcelana'),
    ('0e1317cb-55e4-5b0e-8c9d-8a11ff9f4453', '296f75b4-0387-5e08-a2b6-c75c89757e68', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 8, NULL, 'Vidrio de reloj'),
    ('15a812ca-64ea-50e2-82c7-c0f6fba45852', '296f75b4-0387-5e08-a2b6-c75c89757e68', '4879407a-5079-56ff-9d26-cdda5b70a3c6', NULL, NULL, 'Gradilla para tubos'),
    ('65c58496-3aec-5b5c-946b-860df7d734ad', '296f75b4-0387-5e08-a2b6-c75c89757e68', '96ec5fdf-0007-5994-8228-9a225f2daaaa', 8, NULL, 'Termómetro'),
    ('76d0337b-148a-5123-968e-e70ca053084e', '296f75b4-0387-5e08-a2b6-c75c89757e68', '50190125-4c68-5d2c-a5c6-a56583ffcd48', 16, NULL, 'Pipeta graduada de 10 mL')
  on conflict (id) do nothing;
  insert into importaciones_formularios (id, nombre_archivo, subido_por, estado, payload, sesion_id, procesado_en)
  values ('88877a5b-2897-5cf6-adce-8840cc608c21', 'Fundamentos_de_Química_MIA__2025-2.xlsx / Práctica 7', v_docente, 'procesado', $j${"archivo": "Fundamentos_de_Química_MIA__2025-2.xlsx", "hoja": "Práctica 7", "practica": "ESTEQUIOMETRIA: MÉTODO DE JOB", "fecha": "2025-10-09", "inicio": "09:00:00", "fin": "12:00:00", "estudiantes": 13, "grupos": 4, "equipos_vidrieria": [{"texto": "Tubos de ensayo", "cantidad": 120.0}, {"texto": "Cápsula de porcelana", "cantidad": 8.0}, {"texto": "Vidrio de reloj", "cantidad": 8.0}, {"texto": "Gradilla para tubos", "cantidad": null}, {"texto": "Termómetro", "cantidad": 8.0}, {"texto": "Pipeta graduada de 10 mL", "cantidad": 16.0}], "reactivos": [{"texto": "NaOH (2M)", "cantidad": 300.0, "unidad": "mL", "concentracion": "2 M"}, {"texto": "HCl (2M)", "cantidad": 300.0, "unidad": "mL", "concentracion": "2 M"}, {"texto": "Indicador ácido-base: naranja de metilo", "cantidad": 50.0, "unidad": "mL", "concentracion": null}, {"texto": "Indicador ácido-base: Fenolftaleína", "cantidad": 50.0, "unidad": "mL", "concentracion": null}], "observaciones": "Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00"}$j$::jsonb, '893c2cdb-81db-57be-aa1e-f8c193802d9f', now()) on conflict (id) do nothing;

  -- ---------- Práctica 8: SOLUCIONES Parte 1
  insert into practicas (id, codigo, nombre, asignatura, programa, laboratorio_id, docente_responsable_id, duracion_min)
  values ('0685bc43-eee3-5f21-b211-9ab7830ce029', 'FQ-P08', 'SOLUCIONES Parte 1', 'Fundamentos de Química', 'MIA', v_lab, v_docente, 180) on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('686c96a5-d2ee-5c3a-9201-6df6281c8ddd', '0685bc43-eee3-5f21-b211-9ab7830ce029', v_docente, v_lab, 13, 4, timestamptz '2025-10-16 09:00:00-05', timestamptz '2025-10-16 12:00:00-05', 'solicitada', 'Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('2a30d6a3-973f-5e32-abad-6f045ab2b2cd', '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', '881cc962-2982-5e3b-912e-18e69bdf4889', 1, 'Reactivo sólido', NULL, NULL, 'Hidroxido de sodio'),
    ('3ae07506-3784-5f21-8de8-a58d064859c9', '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', 'e585e729-6109-59fa-93bf-0fe06dd87c6a', 1, NULL, 'concentrado', 'Cantidad 1 sin unidad en el formulario.', 'Ácido clorhídrico'),
    ('01ba0962-a98a-5e55-b77c-a999328bb412', '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', '6f916b68-b7c2-5a48-b083-11a624774bba', 8, 'Frasco lavador', NULL, NULL, 'Agua destilada')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('f1aea77d-6dff-5870-af86-58d86e1dfcb1', '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 16, NULL, 'Beaker con capacidad para 100 mL | Beaker con capacidad para 200 mL'),
    ('6be6331c-8cd2-50cd-a47c-bd2481bdd02a', '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', '50190125-4c68-5d2c-a5c6-a56583ffcd48', 8, NULL, 'Pipeta graduada'),
    ('b903d389-ff75-5b7f-be06-becbf802ed27', '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', 'ce24ff35-d394-5266-acc1-f7175ba64bb3', 8, NULL, 'Pipeta volumétrica'),
    ('3126e4c5-c000-5397-bfac-d82fa263c308', '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', '19daf60e-b108-5e55-89df-83f7c3a073be', 2, NULL, 'Balanza digital'),
    ('80ba0cb9-fc4b-5442-b9ae-d1af4e79a559', '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', 'f8550b72-6e14-54a7-bfbe-b8510e15e150', 8, NULL, 'Cápsula de porcelana'),
    ('925444af-c3f8-53c2-9d53-82fdf74d9ccb', '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 8, NULL, 'Vidrio reloj'),
    ('5986005b-d86b-5a7d-8dcf-52ec4592e3ea', '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', '23d6090e-5d9f-5d90-af05-7fc51b4d5d7f', 8, NULL, 'Plancha de calentamiento'),
    ('ecd78be6-8445-543f-a756-c79f4b0ced22', '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', '784e25aa-5e19-568b-b6ff-d2f9e7f9f648', 16, NULL, 'Balón volumétrico con capacidad para 100 mL'),
    ('8530dea1-c0b0-594b-96b4-1f6e2f599fa7', '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', 'ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 8, NULL, 'Probeta graduada con capacidad de 50 mL')
  on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('b8ec227c-c44e-557e-bcd1-e75ce62a88b5', '0685bc43-eee3-5f21-b211-9ab7830ce029', v_docente, v_lab, 12, NULL, timestamptz '2025-10-16 13:00:00-05', timestamptz '2025-10-16 16:00:00-05', 'solicitada', 'Segunda sesión del mismo día, deducida de las observaciones del formulario. Mismos materiales y reactivos que la primera.', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('c0989eed-4dc8-5b76-ab8b-5a6e70c11351', 'b8ec227c-c44e-557e-bcd1-e75ce62a88b5', '881cc962-2982-5e3b-912e-18e69bdf4889', 1, 'Reactivo sólido', NULL, NULL, 'Hidroxido de sodio'),
    ('9a3060a6-204a-55f0-8aa4-f11336012e45', 'b8ec227c-c44e-557e-bcd1-e75ce62a88b5', 'e585e729-6109-59fa-93bf-0fe06dd87c6a', 1, NULL, 'concentrado', 'Cantidad 1 sin unidad en el formulario.', 'Ácido clorhídrico'),
    ('64b70710-760c-527c-88a3-b3e42bfcc213', 'b8ec227c-c44e-557e-bcd1-e75ce62a88b5', '6f916b68-b7c2-5a48-b083-11a624774bba', 8, 'Frasco lavador', NULL, NULL, 'Agua destilada')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('ffaf93e0-9f71-5002-9e85-4bec75fc919a', 'b8ec227c-c44e-557e-bcd1-e75ce62a88b5', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 16, NULL, 'Beaker con capacidad para 100 mL | Beaker con capacidad para 200 mL'),
    ('159fb246-db8e-53be-9d84-e86c209e6207', 'b8ec227c-c44e-557e-bcd1-e75ce62a88b5', '50190125-4c68-5d2c-a5c6-a56583ffcd48', 8, NULL, 'Pipeta graduada'),
    ('c1aa1294-6dc3-5e2b-8871-b7de47992826', 'b8ec227c-c44e-557e-bcd1-e75ce62a88b5', 'ce24ff35-d394-5266-acc1-f7175ba64bb3', 8, NULL, 'Pipeta volumétrica'),
    ('91ac64de-48c5-5920-bf6b-e8a75e879952', 'b8ec227c-c44e-557e-bcd1-e75ce62a88b5', '19daf60e-b108-5e55-89df-83f7c3a073be', 2, NULL, 'Balanza digital'),
    ('9a02471f-0e10-5f92-94d0-c57bfcb51d60', 'b8ec227c-c44e-557e-bcd1-e75ce62a88b5', 'f8550b72-6e14-54a7-bfbe-b8510e15e150', 8, NULL, 'Cápsula de porcelana'),
    ('c519229b-01e4-59e6-b6a3-cbb40d18b971', 'b8ec227c-c44e-557e-bcd1-e75ce62a88b5', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 8, NULL, 'Vidrio reloj'),
    ('37a5975a-20fa-57a0-abe1-5817df22cff8', 'b8ec227c-c44e-557e-bcd1-e75ce62a88b5', '23d6090e-5d9f-5d90-af05-7fc51b4d5d7f', 8, NULL, 'Plancha de calentamiento'),
    ('2baf2b07-c93d-53cc-b50b-a87d28c2d83a', 'b8ec227c-c44e-557e-bcd1-e75ce62a88b5', '784e25aa-5e19-568b-b6ff-d2f9e7f9f648', 16, NULL, 'Balón volumétrico con capacidad para 100 mL'),
    ('8f9be67f-13e7-50c2-a0f5-e1e1a7ec1b4c', 'b8ec227c-c44e-557e-bcd1-e75ce62a88b5', 'ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 8, NULL, 'Probeta graduada con capacidad de 50 mL')
  on conflict (id) do nothing;
  insert into importaciones_formularios (id, nombre_archivo, subido_por, estado, payload, sesion_id, procesado_en)
  values ('1d0ec8ba-7045-511b-a6cc-8dca094a78b5', 'Fundamentos_de_Química_MIA__2025-2.xlsx / Práctica 8', v_docente, 'procesado', $j${"archivo": "Fundamentos_de_Química_MIA__2025-2.xlsx", "hoja": "Práctica 8", "practica": "SOLUCIONES Parte 1", "fecha": "2025-10-16", "inicio": "09:00:00", "fin": "12:00:00", "estudiantes": 13, "grupos": 4, "equipos_vidrieria": [{"texto": "Beaker con capacidad para 100 mL", "cantidad": 8.0}, {"texto": "Pipeta graduada", "cantidad": 8.0}, {"texto": "Pipeta volumétrica", "cantidad": 8.0}, {"texto": "Balanza digital", "cantidad": 2.0}, {"texto": "Cápsula de porcelana", "cantidad": 8.0}, {"texto": "Vidrio reloj", "cantidad": 8.0}, {"texto": "Plancha de calentamiento", "cantidad": 8.0}, {"texto": "Balón volumétrico con capacidad para 100 mL", "cantidad": 16.0}, {"texto": "Probeta graduada con capacidad de 50 mL", "cantidad": 8.0}, {"texto": "Beaker con capacidad para 200 mL", "cantidad": 8.0}], "reactivos": [{"texto": "Hidroxido de sodio", "cantidad": 1.0, "unidad": "Reactivo sólido", "concentracion": null}, {"texto": "Ácido clorhídrico", "cantidad": 1.0, "unidad": "Concentrado", "concentracion": null}, {"texto": "Agua destilada", "cantidad": 8.0, "unidad": "Frasco lavador", "concentracion": null}], "observaciones": "Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00"}$j$::jsonb, '686c96a5-d2ee-5c3a-9201-6df6281c8ddd', now()) on conflict (id) do nothing;

  -- ---------- Práctica 9: SOLUCIONES Parte 2
  insert into practicas (id, codigo, nombre, asignatura, programa, laboratorio_id, docente_responsable_id, duracion_min)
  values ('57e77f01-1ddd-5897-ab38-3f984074c880', 'FQ-P09', 'SOLUCIONES Parte 2', 'Fundamentos de Química', 'MIA', v_lab, v_docente, 180) on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('3bd37ab8-ca78-52d3-869f-5149ba048c7f', '57e77f01-1ddd-5897-ab38-3f984074c880', v_docente, v_lab, 13, 4, timestamptz '2025-10-23 09:00:00-05', timestamptz '2025-10-23 12:00:00-05', 'solicitada', 'Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('43bf67c5-2ad4-5940-b263-8300b3cd144a', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', '5148bcba-d706-5ec6-8450-f273e046406b', 1, 'Reactivo sólido', NULL, NULL, 'Ftalato ácido de potasio'),
    ('5ef562db-41a3-5a68-85ad-800a0598ae6a', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', '881cc962-2982-5e3b-912e-18e69bdf4889', 1, 'Reactivo sólido', NULL, NULL, 'Hidroxido de sodio'),
    ('03bc5add-7759-5e09-8b33-c8ce18d2d6cb', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', 'a3100cc8-ac60-5db1-9a50-e48a91df9ea5', 1, 'gotero', NULL, NULL, 'Fenolftaleina'),
    ('7ca8c93b-6f7d-5de3-8753-585a76640e9c', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', '19f45963-56fc-500a-9567-d0ec0714df92', NULL, NULL, '3,4 M', 'El formulario puso la concentración (3.4 mol/L) en la columna de cantidad.', 'Cloruro de sodio'),
    ('c3a96260-727c-5745-8b33-49be25a5187e', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', 'e585e729-6109-59fa-93bf-0fe06dd87c6a', 1, NULL, 'concentrado', 'Cantidad 1 sin unidad en el formulario.', 'Ácido clorhídrico'),
    ('cc43cb1d-0922-5a42-997d-d434e9f319b4', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', '6f916b68-b7c2-5a48-b083-11a624774bba', 8, 'Frasco lavador', NULL, NULL, 'Agua destilada')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('837de3ba-82c2-51f0-876f-c3c354d04b3b', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', 'eae9ccb5-31ab-574d-b4a9-cefaa70a8e07', 8, NULL, 'Bureta'),
    ('c3e58142-cbe3-5d00-9e19-c77e3e12594a', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', '5e05c62d-b87e-51c0-baec-8c59edce24ee', 8, NULL, 'Soporte universal'),
    ('16f28756-ab71-55ea-8555-86f0108630d6', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', 'cb92a1f9-4e51-5dde-930c-106e0220257f', 16, NULL, 'Pinzas'),
    ('3704f353-555f-5504-a87b-fb05206a4506', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', 'ff52895c-ffad-5e54-b8f4-27127f0e1a22', 16, NULL, 'nuéz'),
    ('efd9864d-52db-5f82-96db-282cc82b1a8a', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 16, NULL, 'Beaker con capacidad para 100 mL | Beaker con capacidad para 200 mL'),
    ('0ed79e39-0cb1-53e8-8635-784d1be7a7b7', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', '50190125-4c68-5d2c-a5c6-a56583ffcd48', 8, NULL, 'Pipeta graduada'),
    ('14d5a3be-4bdb-528f-813f-0f6546839d2c', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', 'ce24ff35-d394-5266-acc1-f7175ba64bb3', 8, NULL, 'Pipeta volumétrica'),
    ('bce6b59c-4c92-5fac-ab54-36971ae2c0ba', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', '19daf60e-b108-5e55-89df-83f7c3a073be', 2, NULL, 'Balanza digital'),
    ('8728c026-a049-5872-b33a-7ca5c8995d49', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', 'f8550b72-6e14-54a7-bfbe-b8510e15e150', 8, NULL, 'Cápsula de porcelana'),
    ('8037b757-94a5-5619-944c-f25a3965ca9c', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 8, NULL, 'Vidrio reloj'),
    ('5b960138-f509-50d1-9b40-f01606a89e4e', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', '23d6090e-5d9f-5d90-af05-7fc51b4d5d7f', 8, NULL, 'Plancha de calentamiento'),
    ('5fe48a07-b5b4-5eea-a592-cc23d7ee9547', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', 'a451b76f-52c8-5d50-b7ff-904cb7d10bb1', 8, NULL, 'Placa de calentamiento'),
    ('c6fca0b1-32b1-5632-ba6d-3a781fb3257b', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', 'b5ccff20-5a04-5ffa-8509-e54f86099e47', 8, NULL, 'Pinzas para crisol'),
    ('95df579e-38ac-517f-a2ce-daf2562e15ff', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', '784e25aa-5e19-568b-b6ff-d2f9e7f9f648', 16, NULL, 'Balón volumétrico con capacidad para 100 mL'),
    ('01b1ca07-2514-59b7-8f70-013b2df9faad', '3bd37ab8-ca78-52d3-869f-5149ba048c7f', 'ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 8, NULL, 'Probeta graduada con capacidad de 50 mL')
  on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', '57e77f01-1ddd-5897-ab38-3f984074c880', v_docente, v_lab, 12, NULL, timestamptz '2025-10-23 13:00:00-05', timestamptz '2025-10-23 16:00:00-05', 'solicitada', 'Segunda sesión del mismo día, deducida de las observaciones del formulario. Mismos materiales y reactivos que la primera.', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('7de05392-c563-543f-9471-6c20f381f86c', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', '5148bcba-d706-5ec6-8450-f273e046406b', 1, 'Reactivo sólido', NULL, NULL, 'Ftalato ácido de potasio'),
    ('fee804ee-ff98-5660-9d6e-59a52989f7a0', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', '881cc962-2982-5e3b-912e-18e69bdf4889', 1, 'Reactivo sólido', NULL, NULL, 'Hidroxido de sodio'),
    ('34fa0bed-f955-59d0-ae23-dc640029c011', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', 'a3100cc8-ac60-5db1-9a50-e48a91df9ea5', 1, 'gotero', NULL, NULL, 'Fenolftaleina'),
    ('c6c1f3f7-bc41-5145-a116-d7a6a66b32f0', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', '19f45963-56fc-500a-9567-d0ec0714df92', NULL, NULL, '3,4 M', 'El formulario puso la concentración (3.4 mol/L) en la columna de cantidad.', 'Cloruro de sodio'),
    ('ba4bd8f9-ac4b-563d-8a80-d3420778efd9', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', 'e585e729-6109-59fa-93bf-0fe06dd87c6a', 1, NULL, 'concentrado', 'Cantidad 1 sin unidad en el formulario.', 'Ácido clorhídrico'),
    ('41ce1624-3132-58f7-a2da-e28f1beef8ab', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', '6f916b68-b7c2-5a48-b083-11a624774bba', 8, 'Frasco lavador', NULL, NULL, 'Agua destilada')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('1cda9825-b1bf-51b3-a08a-4d1d2a6d992f', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', 'eae9ccb5-31ab-574d-b4a9-cefaa70a8e07', 8, NULL, 'Bureta'),
    ('26c4f819-28bb-5742-903b-cf7d38d6abb4', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', '5e05c62d-b87e-51c0-baec-8c59edce24ee', 8, NULL, 'Soporte universal'),
    ('83f0170d-746e-5397-96b5-37a20f8d8670', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', 'cb92a1f9-4e51-5dde-930c-106e0220257f', 16, NULL, 'Pinzas'),
    ('09f112a1-8bd3-5d34-b222-d1eb344ef322', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', 'ff52895c-ffad-5e54-b8f4-27127f0e1a22', 16, NULL, 'nuéz'),
    ('728962dc-7498-5cdd-908a-99c221ee0c76', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', 16, NULL, 'Beaker con capacidad para 100 mL | Beaker con capacidad para 200 mL'),
    ('d10d34be-115b-5daf-b6b7-d12acf453eca', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', '50190125-4c68-5d2c-a5c6-a56583ffcd48', 8, NULL, 'Pipeta graduada'),
    ('5ed66176-a76b-5d47-b422-3cdc69b11555', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', 'ce24ff35-d394-5266-acc1-f7175ba64bb3', 8, NULL, 'Pipeta volumétrica'),
    ('0d2c2d6d-a225-50d7-8f29-06be31ccc8a2', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', '19daf60e-b108-5e55-89df-83f7c3a073be', 2, NULL, 'Balanza digital'),
    ('093762ba-b042-5818-844c-9f68b3af1736', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', 'f8550b72-6e14-54a7-bfbe-b8510e15e150', 8, NULL, 'Cápsula de porcelana'),
    ('00832707-078c-5ce1-8940-fedd020fc452', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', 'b4fe6d69-aa4a-5339-996f-af40db817b82', 8, NULL, 'Vidrio reloj'),
    ('589eb9d7-1ce2-5103-a1d6-b291698af2e4', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', '23d6090e-5d9f-5d90-af05-7fc51b4d5d7f', 8, NULL, 'Plancha de calentamiento'),
    ('85bdedf4-9be4-5050-87f6-35c52a7a4241', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', 'a451b76f-52c8-5d50-b7ff-904cb7d10bb1', 8, NULL, 'Placa de calentamiento'),
    ('4a70f29d-a390-5848-b260-4ebc82250e89', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', 'b5ccff20-5a04-5ffa-8509-e54f86099e47', 8, NULL, 'Pinzas para crisol'),
    ('4f5bcf11-a80b-5beb-a30c-41149f3d5050', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', '784e25aa-5e19-568b-b6ff-d2f9e7f9f648', 16, NULL, 'Balón volumétrico con capacidad para 100 mL'),
    ('7b83bb98-352a-52b2-b342-bf79f11ea4d0', 'e9f56c1b-bf67-5ce7-83fc-e88fdb57fd7d', 'ab91cd82-4a8a-58c9-bc04-596d2464cc2c', 8, NULL, 'Probeta graduada con capacidad de 50 mL')
  on conflict (id) do nothing;
  insert into importaciones_formularios (id, nombre_archivo, subido_por, estado, payload, sesion_id, procesado_en)
  values ('cccb6cb9-4302-5ece-9243-3ac733412ccf', 'Fundamentos_de_Química_MIA__2025-2.xlsx / Práctica 9', v_docente, 'procesado', $j${"archivo": "Fundamentos_de_Química_MIA__2025-2.xlsx", "hoja": "Práctica 9", "practica": "SOLUCIONES Parte 2", "fecha": "2025-10-23", "inicio": "09:00:00", "fin": "12:00:00", "estudiantes": 13, "grupos": 4, "equipos_vidrieria": [{"texto": "Bureta", "cantidad": 8.0}, {"texto": "Soporte universal", "cantidad": 8.0}, {"texto": "Pinzas", "cantidad": 16.0}, {"texto": "nuéz", "cantidad": 16.0}, {"texto": "Beaker con capacidad para 100 mL", "cantidad": 8.0}, {"texto": "Pipeta graduada", "cantidad": 8.0}, {"texto": "Pipeta volumétrica", "cantidad": 8.0}, {"texto": "Balanza digital", "cantidad": 2.0}, {"texto": "Cápsula de porcelana", "cantidad": 8.0}, {"texto": "Vidrio reloj", "cantidad": 8.0}, {"texto": "Plancha de calentamiento", "cantidad": 8.0}, {"texto": "Placa de calentamiento", "cantidad": 8.0}, {"texto": "Pinzas para crisol", "cantidad": 8.0}, {"texto": "Balón volumétrico con capacidad para 100 mL", "cantidad": 16.0}, {"texto": "Probeta graduada con capacidad de 50 mL", "cantidad": 8.0}, {"texto": "Beaker con capacidad para 200 mL", "cantidad": 8.0}], "reactivos": [{"texto": "Ftalato ácido de potasio", "cantidad": 1.0, "unidad": "Reactivo sólido", "concentracion": null}, {"texto": "Hidroxido de sodio", "cantidad": 1.0, "unidad": "Reactivo sólido", "concentracion": null}, {"texto": "Fenolftaleina", "cantidad": 1.0, "unidad": "gotero", "concentracion": null}, {"texto": "Cloruro de sodio", "cantidad": 3.4, "unidad": "mol/L", "concentracion": null}, {"texto": "Ácido clorhídrico", "cantidad": 1.0, "unidad": "Concentrado", "concentracion": null}, {"texto": "Agua destilada", "cantidad": 8.0, "unidad": "Frasco lavador", "concentracion": null}], "observaciones": "Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00"}$j$::jsonb, '3bd37ab8-ca78-52d3-869f-5149ba048c7f', now()) on conflict (id) do nothing;

  -- ---------- Práctica 10: Equilibrio Químico
  insert into practicas (id, codigo, nombre, asignatura, programa, laboratorio_id, docente_responsable_id, duracion_min)
  values ('ea530855-d8d5-512e-acae-c3da02e32ab3', 'FQ-P10', 'Equilibrio Químico', 'Fundamentos de Química', 'MIA', v_lab, v_docente, 180) on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('7841d06a-c367-5497-bd3a-4a4285d83250', 'ea530855-d8d5-512e-acae-c3da02e32ab3', v_docente, v_lab, 13, 4, timestamptz '2025-10-30 09:00:00-05', timestamptz '2025-10-30 12:00:00-05', 'solicitada', 'Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('1766d57f-c6fc-5c8d-b92d-dfd22e3c928a', '7841d06a-c367-5497-bd3a-4a4285d83250', 'e585e729-6109-59fa-93bf-0fe06dd87c6a', 1, 'mL', '2 M', 'Inconsistencia: total 1 pero por mesa 100.', 'Ácido clorhídrico'),
    ('939a9558-bf7f-5e6a-a4d0-1232e71d32ac', '7841d06a-c367-5497-bd3a-4a4285d83250', '881cc962-2982-5e3b-912e-18e69bdf4889', 1, 'mL', '2 M', 'Inconsistencia: total 1 pero por mesa 100.', 'Hidroxido de sodio'),
    ('b0be82e5-b1ac-5d50-b381-bfed814e1668', '7841d06a-c367-5497-bd3a-4a4285d83250', '41dbef7b-d940-5a87-9a3a-99653bff16cd', 1, 'mL', '2 M', 'Inconsistencia: total 1 pero por mesa 100.', 'Dicromato de potasio')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('32e18ff5-20b6-5397-b164-45d8967fccf8', '7841d06a-c367-5497-bd3a-4a4285d83250', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', NULL, NULL, 'Beaker 100 mL'),
    ('ecee5f42-35bc-5eb5-9ca4-30cabfd3da4b', '7841d06a-c367-5497-bd3a-4a4285d83250', '5c23926f-4491-5ed8-990a-1e87746c496b', NULL, NULL, 'Pipeta pasteur'),
    ('2ffee9f3-0143-57bc-9daa-5b535206b1da', '7841d06a-c367-5497-bd3a-4a4285d83250', 'f8550b72-6e14-54a7-bfbe-b8510e15e150', NULL, NULL, 'Capsula de porcelana'),
    ('715db857-1a03-5574-92a0-18f985b12e4f', '7841d06a-c367-5497-bd3a-4a4285d83250', 'b4fe6d69-aa4a-5339-996f-af40db817b82', NULL, NULL, 'Vidrio reloj'),
    ('22c23528-2b6b-574b-bddc-fb0476d5e802', '7841d06a-c367-5497-bd3a-4a4285d83250', '703eb001-8968-5163-951d-6de7224d779c', NULL, NULL, 'tubos de ensayo'),
    ('9e7e704a-7fd4-5f1b-bcad-a52b602b096b', '7841d06a-c367-5497-bd3a-4a4285d83250', '4879407a-5079-56ff-9d26-cdda5b70a3c6', NULL, NULL, 'Gradilla')
  on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('69249d45-2f4b-53e4-b501-a3801ff76f59', 'ea530855-d8d5-512e-acae-c3da02e32ab3', v_docente, v_lab, 12, NULL, timestamptz '2025-10-30 13:00:00-05', timestamptz '2025-10-30 16:00:00-05', 'solicitada', 'Segunda sesión del mismo día, deducida de las observaciones del formulario. Mismos materiales y reactivos que la primera.', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('9e8d3c26-e28b-5883-be86-d1f462c98b68', '69249d45-2f4b-53e4-b501-a3801ff76f59', 'e585e729-6109-59fa-93bf-0fe06dd87c6a', 1, 'mL', '2 M', 'Inconsistencia: total 1 pero por mesa 100.', 'Ácido clorhídrico'),
    ('abcdecfa-c668-5f30-b7fd-c7fcd70463c9', '69249d45-2f4b-53e4-b501-a3801ff76f59', '881cc962-2982-5e3b-912e-18e69bdf4889', 1, 'mL', '2 M', 'Inconsistencia: total 1 pero por mesa 100.', 'Hidroxido de sodio'),
    ('8d3c765c-0cdf-556c-9e59-1cf5b2b8f4c2', '69249d45-2f4b-53e4-b501-a3801ff76f59', '41dbef7b-d940-5a87-9a3a-99653bff16cd', 1, 'mL', '2 M', 'Inconsistencia: total 1 pero por mesa 100.', 'Dicromato de potasio')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('5292d9e3-fe39-565a-91c4-e6faa9f97e93', '69249d45-2f4b-53e4-b501-a3801ff76f59', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', NULL, NULL, 'Beaker 100 mL'),
    ('5406c6e6-1443-5b8a-84c2-7a6a921c1492', '69249d45-2f4b-53e4-b501-a3801ff76f59', '5c23926f-4491-5ed8-990a-1e87746c496b', NULL, NULL, 'Pipeta pasteur'),
    ('fb13ca7a-c638-51d8-9065-c386f10c7648', '69249d45-2f4b-53e4-b501-a3801ff76f59', 'f8550b72-6e14-54a7-bfbe-b8510e15e150', NULL, NULL, 'Capsula de porcelana'),
    ('bf323cf4-79ba-53ef-be32-d3cfbd531ac8', '69249d45-2f4b-53e4-b501-a3801ff76f59', 'b4fe6d69-aa4a-5339-996f-af40db817b82', NULL, NULL, 'Vidrio reloj'),
    ('df31ae92-21d5-5ed0-8b9a-01309c76f9f0', '69249d45-2f4b-53e4-b501-a3801ff76f59', '703eb001-8968-5163-951d-6de7224d779c', NULL, NULL, 'tubos de ensayo'),
    ('a1e366ab-abcc-5c9a-a546-34a9d681eb65', '69249d45-2f4b-53e4-b501-a3801ff76f59', '4879407a-5079-56ff-9d26-cdda5b70a3c6', NULL, NULL, 'Gradilla')
  on conflict (id) do nothing;
  insert into importaciones_formularios (id, nombre_archivo, subido_por, estado, payload, sesion_id, procesado_en)
  values ('1c33aaea-0b5f-52e0-a391-ae6f67701c9b', 'Fundamentos_de_Química_MIA__2025-2.xlsx / Práctica 10', v_docente, 'procesado', $j${"archivo": "Fundamentos_de_Química_MIA__2025-2.xlsx", "hoja": "Práctica 10", "practica": "Equilibrio Químico", "fecha": "2025-10-30", "inicio": "09:00:00", "fin": "12:00:00", "estudiantes": 13, "grupos": 4, "equipos_vidrieria": [{"texto": "Beaker 100 mL", "cantidad": null}, {"texto": "Pipeta pasteur", "cantidad": null}, {"texto": "Capsula de porcelana", "cantidad": null}, {"texto": "Vidrio reloj", "cantidad": null}, {"texto": "tubos de ensayo", "cantidad": null}, {"texto": "Gradilla", "cantidad": null}], "reactivos": [{"texto": "Ácido clorhídrico", "cantidad": 1.0, "unidad": "mL", "concentracion": "2 M"}, {"texto": "Hidroxido de sodio", "cantidad": 1.0, "unidad": "mL", "concentracion": "2 M"}, {"texto": "Dicromato de potasio", "cantidad": 1.0, "unidad": "mL", "concentracion": "2 M"}], "observaciones": "Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00"}$j$::jsonb, '7841d06a-c367-5497-bd3a-4a4285d83250', now()) on conflict (id) do nothing;

  -- ---------- Práctica 11: Análisis orgánico cualitativo
  insert into practicas (id, codigo, nombre, asignatura, programa, laboratorio_id, docente_responsable_id, duracion_min)
  values ('aa299db3-e5fb-5794-b2a2-a9ea6c7ed8a9', 'FQ-P11', 'Análisis orgánico cualitativo', 'Fundamentos de Química', 'MIA', v_lab, v_docente, 180) on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('f81d9cf5-8ee8-5886-9115-53a365bf346c', 'aa299db3-e5fb-5794-b2a2-a9ea6c7ed8a9', v_docente, v_lab, 13, 4, timestamptz '2025-11-06 09:00:00-05', timestamptz '2025-11-06 12:00:00-05', 'solicitada', 'Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('c4c4d484-0828-59c1-a79d-1b762782297e', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', 'da618e17-477a-5839-bb08-38dd7786b1f8', NULL, NULL, NULL, NULL, 'n-heptano (alcano)'),
    ('c32fef89-f8e4-5ed7-b72f-695471a97be4', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '3eb03ece-5034-58a6-b07f-1c9ffecb55a6', NULL, NULL, NULL, NULL, 'Ciclohexeno (alqueno)'),
    ('0052a978-6761-5474-8ebb-6a39d54241b3', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', 'a44092ba-763d-5e76-832f-44c75090560e', NULL, NULL, NULL, 'El formulario dice "Etanol o n-butanol (alcoholes)" (alternativas). Aparece más de una vez en el formulario: "Etanol, C2H5OH".', 'Etanol o n-butanol (alcoholes) | Etanol, C2H5OH'),
    ('549b340b-def1-50e9-8f50-34ce425a2897', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '61c52101-f312-53b7-b9ea-748c0e2f80e0', NULL, NULL, NULL, 'El formulario dice "Etanol o n-butanol (alcoholes)" (alternativas).', 'Etanol o n-butanol (alcoholes)'),
    ('8459ae8a-6824-581a-8618-d1c9ee389d40', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '2040833c-aac6-57a9-a1ee-721711ac3990', NULL, NULL, NULL, 'El formulario dice "Propionaldehído o butiraldehído (aldehídos)" (alternativas).', 'Propionaldehído o butiraldehído (aldehídos)'),
    ('9295b619-15ed-5e4a-9055-c405a64a847f', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', 'e7f294e7-82cf-5ca6-a318-6b22009297e8', NULL, NULL, NULL, 'El formulario dice "Propionaldehído o butiraldehído (aldehídos)" (alternativas).', 'Propionaldehído o butiraldehído (aldehídos)'),
    ('35a1af95-9afa-526e-9449-9d0c61e25a31', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '0415b1da-b3eb-5d3a-9f70-c43886184b7e', NULL, NULL, NULL, 'El formulario dice "Acetona o 2-butanona (cetonas)" (alternativas).', 'Acetona o 2-butanona (cetonas)'),
    ('43bd0f65-1dda-568f-8eaf-67f8e18b2ab0', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '27d2f435-4b01-594a-8937-6fb9e08ea878', NULL, NULL, NULL, 'El formulario dice "Acetona o 2-butanona (cetonas)" (alternativas).', 'Acetona o 2-butanona (cetonas)'),
    ('e0383e9e-90ac-578c-874b-b6be974f1344', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', 'fe818d90-5625-5de0-8c2c-7cba70fc0fe5', NULL, NULL, NULL, 'El formulario dice "Ácido acético o ácido propiónico (ácidos carboxílicos)" (alternativas).', 'Ácido acético o ácido propiónico (ácidos carboxílicos)'),
    ('8a6fd045-4600-5f20-85fd-ab2ef8a7c398', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', 'd23ddff5-32be-5450-af81-0998b490e950', NULL, NULL, NULL, 'El formulario dice "Ácido acético o ácido propiónico (ácidos carboxílicos)" (alternativas).', 'Ácido acético o ácido propiónico (ácidos carboxílicos)'),
    ('8cbfaba2-db52-5efc-8421-5da6a78de168', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '67e36961-44fb-52d5-9539-ebbd53aede2f', NULL, NULL, NULL, NULL, 'Dietilamina (aminas)'),
    ('c4804962-7437-540b-b36f-15b1b4d2d623', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '64a0d51f-f2e6-5d4a-9827-c851adc28fa4', NULL, NULL, NULL, NULL, 'Permanganato de potasio, KMnO4'),
    ('8ac11830-b8ac-56cd-8e52-b22232a96814', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', 'a218255b-cbe3-5df6-9131-f1c26c334f61', NULL, NULL, NULL, NULL, 'Nitrato de plata, AgNO3'),
    ('5c05931b-ea3c-5be8-a6d8-8ad9e057f60e', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '881cc962-2982-5e3b-912e-18e69bdf4889', NULL, NULL, NULL, NULL, 'Hidróxido de sodio,NaOH'),
    ('949f8a65-2fca-5fa8-83cc-5bc411d08a9f', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '8533df08-4115-5d5f-9380-af047db82ba8', NULL, NULL, NULL, NULL, 'Hidróxido de amonio, NH4OH'),
    ('5d91aaca-bd8a-5da6-94d0-81ada09d7d23', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '3ea7d3a1-d75f-5d23-8280-8ddfb92d4354', NULL, NULL, NULL, NULL, 'Ácido sulfúrico, H2SO4'),
    ('dd389676-7322-5813-8462-18f87fa64efe', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '51ca596b-528f-535a-85a2-50319c391aac', NULL, NULL, NULL, NULL, 'Ácido nítrico, HNO3'),
    ('08ef623e-ad4f-56b3-b3e8-ec93c3ded69c', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', 'c5575628-0468-5e9f-b49d-6fde8ea573e2', NULL, NULL, NULL, NULL, '2,4-dinitrofenilhidrazina'),
    ('dcb8100e-f31c-59b8-9ffb-097316e34a49', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', 'de9a81cc-d0fb-5fd8-8e9c-6f9426bd561d', NULL, NULL, NULL, NULL, 'Sodio metálico, Na'),
    ('c56e2eaf-7d50-5c03-aa10-dd63cbd1ca4c', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', 'a3100cc8-ac60-5db1-9a50-e48a91df9ea5', NULL, NULL, NULL, NULL, 'Fenolftaleína'),
    ('fb39a2eb-f886-5134-8e05-3b0d47ff3e71', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', 'd1eb326b-df55-5adc-bc75-901047a964b0', NULL, NULL, NULL, NULL, 'Rojo de metilo'),
    ('38bfde88-55a6-53a0-b019-2f554e359237', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '99e07f43-96c7-5475-ac41-ea864ceecf5d', NULL, NULL, NULL, NULL, 'Azul de bromotimol'),
    ('8f102b22-6098-56a2-b07f-3a21e2f0aedc', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', 'f19fedab-293b-5343-b4ae-b78cc341fc0e', NULL, NULL, NULL, NULL, 'Amarillo de metilo')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('abfa6eb0-d8df-5a3d-b40f-5af12673f5b7', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '703eb001-8968-5163-951d-6de7224d779c', NULL, NULL, 'Tubos de ensayo con tapón'),
    ('c256ceca-a9b1-52a6-9e17-0ad54320819a', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', NULL, NULL, 'Vasos de precipitado de 50 ml'),
    ('f7dce992-f208-559a-ad3a-64a5a2c9c144', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '50190125-4c68-5d2c-a5c6-a56583ffcd48', NULL, NULL, 'Pipeta graduada de 10 ml | Pipeta graduada de 5 ml'),
    ('1a80ace7-eb9d-573b-929f-e54331c6d6df', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '784e25aa-5e19-568b-b6ff-d2f9e7f9f648', NULL, NULL, 'Matraces aforados de 100 ml | Matraces aforados de 50 ml'),
    ('67f35cb0-1a93-574c-b4ef-f62f3a136d00', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '108c6816-9128-50ce-b784-a6eaa3a6173e', NULL, NULL, 'Erlenmeyer de 50 ml'),
    ('e2b142cd-2f0d-5d15-bd1c-0a0fd44fbcde', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', 'd4dcaab2-2859-573b-b8cc-5c2e41ee08d9', NULL, NULL, 'Varilla de vidrio'),
    ('15a8ec8d-75d8-5917-8842-14d52a7e925e', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '5010c358-aea8-554f-aa4c-2934745fe6cd', NULL, NULL, 'Espátula'),
    ('1cda4817-4c9e-5b21-b6bc-ae57de20de3c', 'f81d9cf5-8ee8-5886-9115-53a365bf346c', '4879407a-5079-56ff-9d26-cdda5b70a3c6', NULL, NULL, 'Gradilla para tubos de ensayo')
  on conflict (id) do nothing;
  insert into sesiones_practica (id, practica_id, docente_id, laboratorio_id, num_estudiantes, num_grupos_trabajo, inicio, fin, estado, observaciones, origen)
  values ('8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'aa299db3-e5fb-5794-b2a2-a9ea6c7ed8a9', v_docente, v_lab, 12, NULL, timestamptz '2025-11-06 13:00:00-05', timestamptz '2025-11-06 16:00:00-05', 'solicitada', 'Segunda sesión del mismo día, deducida de las observaciones del formulario. Mismos materiales y reactivos que la primera.', 'excel_import') on conflict (id) do nothing;
  insert into sesion_reactivos (id, sesion_id, reactivo_id, cantidad_prevista, unidad, concentracion, notas, texto_original) values
    ('1a6ace72-1976-55ab-93ae-343053ef47dc', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'da618e17-477a-5839-bb08-38dd7786b1f8', NULL, NULL, NULL, NULL, 'n-heptano (alcano)'),
    ('c148357e-bd85-50f0-b0b1-4b85be52d885', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '3eb03ece-5034-58a6-b07f-1c9ffecb55a6', NULL, NULL, NULL, NULL, 'Ciclohexeno (alqueno)'),
    ('0a1f6655-bcd2-5be5-b4cc-b40dcb10557f', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'a44092ba-763d-5e76-832f-44c75090560e', NULL, NULL, NULL, 'El formulario dice "Etanol o n-butanol (alcoholes)" (alternativas). Aparece más de una vez en el formulario: "Etanol, C2H5OH".', 'Etanol o n-butanol (alcoholes) | Etanol, C2H5OH'),
    ('6ecc35b6-3d3f-5923-bb07-e2cdb63248a0', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '61c52101-f312-53b7-b9ea-748c0e2f80e0', NULL, NULL, NULL, 'El formulario dice "Etanol o n-butanol (alcoholes)" (alternativas).', 'Etanol o n-butanol (alcoholes)'),
    ('5dd7be0c-a220-553c-88df-11af49732cc3', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '2040833c-aac6-57a9-a1ee-721711ac3990', NULL, NULL, NULL, 'El formulario dice "Propionaldehído o butiraldehído (aldehídos)" (alternativas).', 'Propionaldehído o butiraldehído (aldehídos)'),
    ('d67e6ebb-0b80-51a0-adde-98a468a2f5f1', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'e7f294e7-82cf-5ca6-a318-6b22009297e8', NULL, NULL, NULL, 'El formulario dice "Propionaldehído o butiraldehído (aldehídos)" (alternativas).', 'Propionaldehído o butiraldehído (aldehídos)'),
    ('d5c526e0-3496-573b-9bb1-2a49c2bd10b4', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '0415b1da-b3eb-5d3a-9f70-c43886184b7e', NULL, NULL, NULL, 'El formulario dice "Acetona o 2-butanona (cetonas)" (alternativas).', 'Acetona o 2-butanona (cetonas)'),
    ('2bcffdf1-7616-51b3-8fa9-f2cfe9afb62d', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '27d2f435-4b01-594a-8937-6fb9e08ea878', NULL, NULL, NULL, 'El formulario dice "Acetona o 2-butanona (cetonas)" (alternativas).', 'Acetona o 2-butanona (cetonas)'),
    ('12a78d0d-9be2-5a13-b043-75513a59117f', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'fe818d90-5625-5de0-8c2c-7cba70fc0fe5', NULL, NULL, NULL, 'El formulario dice "Ácido acético o ácido propiónico (ácidos carboxílicos)" (alternativas).', 'Ácido acético o ácido propiónico (ácidos carboxílicos)'),
    ('8029a11c-d11a-5ec3-b5a1-e6add93da012', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'd23ddff5-32be-5450-af81-0998b490e950', NULL, NULL, NULL, 'El formulario dice "Ácido acético o ácido propiónico (ácidos carboxílicos)" (alternativas).', 'Ácido acético o ácido propiónico (ácidos carboxílicos)'),
    ('f6a4307f-818b-5a27-a99b-8009de000517', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '67e36961-44fb-52d5-9539-ebbd53aede2f', NULL, NULL, NULL, NULL, 'Dietilamina (aminas)'),
    ('b9024d32-32eb-56e8-a39e-4acd37987f99', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '64a0d51f-f2e6-5d4a-9827-c851adc28fa4', NULL, NULL, NULL, NULL, 'Permanganato de potasio, KMnO4'),
    ('bddffce9-123e-5efa-82b0-737797777500', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'a218255b-cbe3-5df6-9131-f1c26c334f61', NULL, NULL, NULL, NULL, 'Nitrato de plata, AgNO3'),
    ('fb62d125-8591-5718-96a9-c7d49fcbbc72', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '881cc962-2982-5e3b-912e-18e69bdf4889', NULL, NULL, NULL, NULL, 'Hidróxido de sodio,NaOH'),
    ('1ae144d9-7fbc-5e40-b583-81afb6114cbf', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '8533df08-4115-5d5f-9380-af047db82ba8', NULL, NULL, NULL, NULL, 'Hidróxido de amonio, NH4OH'),
    ('3a4ddd96-278b-5116-b5db-0bc17d059d49', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '3ea7d3a1-d75f-5d23-8280-8ddfb92d4354', NULL, NULL, NULL, NULL, 'Ácido sulfúrico, H2SO4'),
    ('afc86c59-233f-540d-b0ce-021c8a3565dd', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '51ca596b-528f-535a-85a2-50319c391aac', NULL, NULL, NULL, NULL, 'Ácido nítrico, HNO3'),
    ('5f21b0f8-786d-50e2-b178-28278af9c775', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'c5575628-0468-5e9f-b49d-6fde8ea573e2', NULL, NULL, NULL, NULL, '2,4-dinitrofenilhidrazina'),
    ('2e709de3-52ae-527f-883f-f43ea09cb089', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'de9a81cc-d0fb-5fd8-8e9c-6f9426bd561d', NULL, NULL, NULL, NULL, 'Sodio metálico, Na'),
    ('69207ea0-fef9-5a09-bfc9-9d200a698970', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'a3100cc8-ac60-5db1-9a50-e48a91df9ea5', NULL, NULL, NULL, NULL, 'Fenolftaleína'),
    ('e4453f7a-1e1c-51bb-86e6-e0120b01c6a9', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'd1eb326b-df55-5adc-bc75-901047a964b0', NULL, NULL, NULL, NULL, 'Rojo de metilo'),
    ('b2d9b2e9-a22c-5f45-8fa8-ffd7a0d5830a', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '99e07f43-96c7-5475-ac41-ea864ceecf5d', NULL, NULL, NULL, NULL, 'Azul de bromotimol'),
    ('f19dd62f-811e-52ae-9364-ae2f848a2492', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'f19fedab-293b-5343-b4ae-b78cc341fc0e', NULL, NULL, NULL, NULL, 'Amarillo de metilo')
  on conflict (id) do nothing;
  insert into sesion_materiales (id, sesion_id, material_id, cantidad_prevista, notas, texto_original) values
    ('9723e00e-85ee-52ae-b9a9-72dceb387771', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '703eb001-8968-5163-951d-6de7224d779c', NULL, NULL, 'Tubos de ensayo con tapón'),
    ('4721b97e-760c-5c5f-9f03-833975494290', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '064e0d6d-5df4-5ad3-9a02-eed9561b90ff', NULL, NULL, 'Vasos de precipitado de 50 ml'),
    ('141150df-266b-5cf0-a6d7-c471a103fe45', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '50190125-4c68-5d2c-a5c6-a56583ffcd48', NULL, NULL, 'Pipeta graduada de 10 ml | Pipeta graduada de 5 ml'),
    ('1954a143-eb40-5bb5-940a-730932e2ec01', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '784e25aa-5e19-568b-b6ff-d2f9e7f9f648', NULL, NULL, 'Matraces aforados de 100 ml | Matraces aforados de 50 ml'),
    ('7e677584-455f-5c1f-9743-dbe7788d975c', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '108c6816-9128-50ce-b784-a6eaa3a6173e', NULL, NULL, 'Erlenmeyer de 50 ml'),
    ('7d5ccfaf-c7b0-5e9c-bbe5-556a804d12cb', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', 'd4dcaab2-2859-573b-b8cc-5c2e41ee08d9', NULL, NULL, 'Varilla de vidrio'),
    ('b8ccb25f-d02f-5854-a436-01cc06b5a80e', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '5010c358-aea8-554f-aa4c-2934745fe6cd', NULL, NULL, 'Espátula'),
    ('5c8137aa-433e-53f3-8f0c-669be8a42f5f', '8ae760c6-8c89-5354-b286-37af8dbcc1bd', '4879407a-5079-56ff-9d26-cdda5b70a3c6', NULL, NULL, 'Gradilla para tubos de ensayo')
  on conflict (id) do nothing;
  insert into importaciones_formularios (id, nombre_archivo, subido_por, estado, payload, sesion_id, procesado_en)
  values ('ce68f596-3b90-51e5-ad56-58cc28c7ebc9', 'Fundamentos_de_Química_MIA__2025-2.xlsx / Práctica 11', v_docente, 'procesado', $j${"archivo": "Fundamentos_de_Química_MIA__2025-2.xlsx", "hoja": "Práctica 11", "practica": "Análisis orgánico cualitativo", "fecha": "2025-11-06", "inicio": "09:00:00", "fin": "12:00:00", "estudiantes": 13, "grupos": 4, "equipos_vidrieria": [{"texto": "Tubos de ensayo con tapón", "cantidad": null}, {"texto": "Vasos de precipitado de 50 ml", "cantidad": null}, {"texto": "Pipeta graduada de 10 ml", "cantidad": null}, {"texto": "Pipeta graduada de 5 ml", "cantidad": null}, {"texto": "Matraces aforados de 100 ml", "cantidad": null}, {"texto": "Matraces aforados de 50 ml", "cantidad": null}, {"texto": "Erlenmeyer de 50 ml", "cantidad": null}, {"texto": "Varilla de vidrio", "cantidad": null}, {"texto": "Espátula", "cantidad": null}, {"texto": "Gradilla para tubos de ensayo", "cantidad": null}], "reactivos": [{"texto": "n-heptano (alcano)", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Ciclohexeno (alqueno)", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Etanol o n-butanol (alcoholes)", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Propionaldehído o butiraldehído (aldehídos)", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Acetona o 2-butanona (cetonas)", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Ácido acético o ácido propiónico (ácidos carboxílicos)", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Dietilamina (aminas)", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Permanganato de potasio, KMnO4", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Nitrato de plata, AgNO3", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Hidróxido de sodio,NaOH", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Hidróxido de amonio, NH4OH", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Etanol, C2H5OH", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Ácido sulfúrico, H2SO4", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Ácido nítrico, HNO3", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "2,4-dinitrofenilhidrazina", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Sodio metálico, Na", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Fenolftaleína", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Rojo de metilo", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Azul de bromotimol", "cantidad": null, "unidad": null, "concentracion": null}, {"texto": "Amarillo de metilo", "cantidad": null, "unidad": null, "concentracion": null}], "observaciones": "Observaciones: La informacion que aquí se describe es para una sola sesión de práctica. La informacion que aquí se describe es para una sola práctica. Esta misma práctica se repetirá para 12 estudiantes en el horario de 13:00-16:00"}$j$::jsonb, 'f81d9cf5-8ee8-5886-9115-53a365bf346c', now()) on conflict (id) do nothing;

  raise notice 'Carga completada. Revise las tablas sesiones_practica, sesion_reactivos y sesion_materiales.';
end
$carga$;
