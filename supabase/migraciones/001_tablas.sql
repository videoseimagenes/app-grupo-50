-- NEXO Performance, grupo 50. PROPUESTA PARA REVISAR, NO APLICADA.
-- Traducción del modelo docs/modelo-er.png: seis tablas, 34 campos.
-- Referencia para una base VACÍA; el proyecto actual ya contiene estas tablas.
-- No ejecutar en Supabase real sin aprobación expresa del grupo.
-- Después se revisa 002_seguridad.sql. No incluye datos ni claves de acceso.
-- Las funciones validan las reglas del modelo y permiten guardar datos juntos.
BEGIN;

CREATE TABLE public.deportista (
 id_deportista text PRIMARY KEY,
 alias text NOT NULL CHECK (length(btrim(alias)) BETWEEN 1 AND 160),
 fecha_alta timestamptz NOT NULL DEFAULT now(),
 activo boolean NOT NULL DEFAULT true
);
CREATE TABLE public.test (
 id_test text PRIMARY KEY,
 nombre text NOT NULL CHECK (length(btrim(nombre)) BETWEEN 1 AND 240),
 capacidad_principal text NOT NULL CHECK (length(btrim(capacidad_principal)) BETWEEN 1 AND 240),
 admite_registro boolean NOT NULL DEFAULT false
);
CREATE TABLE public.protocolo (
 id_protocolo text PRIMARY KEY,
 version text NOT NULL CHECK (length(btrim(version)) BETWEEN 1 AND 200),
 instrucciones text NOT NULL CHECK (length(btrim(instrucciones)) BETWEEN 1 AND 60000),
 referencia_fuente text NOT NULL CHECK (length(btrim(referencia_fuente)) BETWEEN 1 AND 4000),
 estado text NOT NULL CHECK (estado IN ('vigente','retirado')),
 id_test text NOT NULL REFERENCES public.test(id_test) ON DELETE RESTRICT,
 UNIQUE (id_test,version)
);
CREATE TABLE public.evaluacion (
 id_evaluacion text PRIMARY KEY,
 fecha_creacion timestamptz NOT NULL DEFAULT now(),
 fecha_realizacion timestamptz,
 estado text NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente','en_curso','completada','cancelada')),
 id_deportista text NOT NULL REFERENCES public.deportista(id_deportista) ON DELETE RESTRICT,
 id_protocolo text NOT NULL REFERENCES public.protocolo(id_protocolo) ON DELETE RESTRICT,
 CHECK (estado <> 'completada' OR fecha_realizacion IS NOT NULL)
);
CREATE TABLE public.metrica (
 id_metrica text PRIMARY KEY,
 nombre text NOT NULL CHECK (length(btrim(nombre)) BETWEEN 1 AND 240),
 unidad text NOT NULL CHECK (length(btrim(unidad)) BETWEEN 1 AND 60),
 tipo_valor text NOT NULL CHECK (tipo_valor IN ('entero','decimal')),
 obligatoria boolean NOT NULL,
 sentido_mejora text NOT NULL CHECK (sentido_mejora IN ('mayor','menor','no_comparar')),
 id_protocolo text NOT NULL REFERENCES public.protocolo(id_protocolo) ON DELETE RESTRICT
);
CREATE TABLE public.medicion (
 id_medicion text PRIMARY KEY,
 valor numeric NOT NULL CHECK (valor NOT IN ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric)),
 numero_intento integer NOT NULL CHECK (numero_intento > 0),
 lado text NOT NULL CHECK (lado IN ('izquierdo','derecho','no_aplica')),
 origen text NOT NULL CHECK (origen IN ('manual','calculado','ia_confirmada')),
 id_evaluacion text NOT NULL REFERENCES public.evaluacion(id_evaluacion) ON DELETE RESTRICT,
 id_metrica text NOT NULL REFERENCES public.metrica(id_metrica) ON DELETE RESTRICT,
 UNIQUE (id_evaluacion,id_metrica,numero_intento,lado)
);
CREATE INDEX evaluacion_deportista_fecha_idx ON public.evaluacion(id_deportista,fecha_creacion DESC);
CREATE INDEX evaluacion_protocolo_idx ON public.evaluacion(id_protocolo);
CREATE INDEX metrica_protocolo_idx ON public.metrica(id_protocolo);
CREATE INDEX medicion_metrica_idx ON public.medicion(id_metrica);

CREATE FUNCTION public.nexo_ec_validar_evaluacion() RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
DECLARE pr public.protocolo%ROWTYPE; habilitado boolean; persona_activa boolean;
BEGIN
 IF TG_OP='UPDATE' AND (NEW.id_protocolo IS DISTINCT FROM OLD.id_protocolo OR NEW.id_deportista IS DISTINCT FROM OLD.id_deportista)
    AND EXISTS (SELECT 1 FROM public.medicion WHERE id_evaluacion=OLD.id_evaluacion) THEN
  RAISE EXCEPTION 'NEXO: Una evaluación con mediciones conserva su deportista y su protocolo.' USING ERRCODE='23514';
 END IF;
 IF TG_OP='INSERT' OR NEW.id_protocolo IS DISTINCT FROM OLD.id_protocolo OR NEW.id_deportista IS DISTINCT FROM OLD.id_deportista THEN
  SELECT * INTO pr FROM public.protocolo WHERE id_protocolo=NEW.id_protocolo FOR SHARE;
  IF NOT FOUND THEN RETURN NEW; END IF; -- la FK informa de la referencia ausente
  SELECT activo INTO persona_activa FROM public.deportista WHERE id_deportista=NEW.id_deportista;
  SELECT admite_registro INTO habilitado FROM public.test WHERE id_test=pr.id_test;
  IF coalesce(current_setting('nexo_ec.importando',true),'') <> '1' THEN
   IF NOT coalesce(persona_activa,false) THEN RAISE EXCEPTION 'NEXO: El deportista debe estar activo para crear una evaluación.' USING ERRCODE='23514'; END IF;
   IF pr.estado <> 'vigente' OR NOT coalesce(habilitado,false) THEN RAISE EXCEPTION 'NEXO: Elige un test registrable y un protocolo vigente.' USING ERRCODE='23514'; END IF;
  END IF;
 END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER ec_validar_evaluacion BEFORE INSERT OR UPDATE ON public.evaluacion
FOR EACH ROW EXECUTE FUNCTION public.nexo_ec_validar_evaluacion();

CREATE FUNCTION public.nexo_ec_validar_medicion() RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
DECLARE ev public.evaluacion%ROWTYPE; mt public.metrica%ROWTYPE;
BEGIN
 SELECT * INTO ev FROM public.evaluacion WHERE id_evaluacion=NEW.id_evaluacion FOR UPDATE;
 IF NOT FOUND THEN RETURN NEW; END IF;
 SELECT * INTO mt FROM public.metrica WHERE id_metrica=NEW.id_metrica;
 IF NOT FOUND THEN RETURN NEW; END IF;
 IF mt.id_protocolo <> ev.id_protocolo THEN RAISE EXCEPTION 'NEXO: La métrica debe pertenecer al protocolo de la evaluación.' USING ERRCODE='23514'; END IF;
 IF mt.tipo_valor='entero' AND NEW.valor <> trunc(NEW.valor) THEN RAISE EXCEPTION 'NEXO: Esta métrica solo admite valores enteros.' USING ERRCODE='23514'; END IF;
 IF ev.estado IN ('completada','cancelada') AND coalesce(current_setting('nexo_ec.importando',true),'') <> '1' THEN
  RAISE EXCEPTION 'NEXO: Reabre la evaluación antes de cambiar sus mediciones.' USING ERRCODE='23514';
 END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER ec_validar_medicion BEFORE INSERT OR UPDATE ON public.medicion
FOR EACH ROW EXECUTE FUNCTION public.nexo_ec_validar_medicion();

CREATE FUNCTION public.nexo_ec_preservar_protocolo() RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
BEGIN
 IF EXISTS (SELECT 1 FROM public.evaluacion WHERE id_protocolo=OLD.id_protocolo) THEN
  IF TG_OP='DELETE' THEN RAISE EXCEPTION 'NEXO: Un protocolo utilizado se conserva en el historial.' USING ERRCODE='23514'; END IF;
  IF (NEW.version,NEW.instrucciones,NEW.referencia_fuente,NEW.id_test,NEW.id_protocolo)
       IS DISTINCT FROM (OLD.version,OLD.instrucciones,OLD.referencia_fuente,OLD.id_test,OLD.id_protocolo) THEN
   RAISE EXCEPTION 'NEXO: Crea otra versión para cambiar un protocolo utilizado.' USING ERRCODE='23514';
  END IF;
 END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER ec_preservar_protocolo BEFORE UPDATE OR DELETE ON public.protocolo
FOR EACH ROW EXECUTE FUNCTION public.nexo_ec_preservar_protocolo();

CREATE FUNCTION public.nexo_ec_preservar_metrica() RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
DECLARE pid text;
BEGIN
 IF TG_OP='INSERT' THEN pid:=NEW.id_protocolo; ELSE pid:=OLD.id_protocolo; END IF;
 PERFORM 1 FROM public.protocolo WHERE id_protocolo=pid FOR UPDATE;
 IF EXISTS (SELECT 1 FROM public.evaluacion WHERE id_protocolo=pid) THEN
  RAISE EXCEPTION 'NEXO: Las métricas de un protocolo utilizado se conservan; crea otra versión.' USING ERRCODE='23514';
 END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER ec_preservar_metrica BEFORE INSERT OR UPDATE OR DELETE ON public.metrica
FOR EACH ROW EXECUTE FUNCTION public.nexo_ec_preservar_metrica();

CREATE FUNCTION public.nexo_ec_assert_integridad() RETURNS void
LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
BEGIN
 IF EXISTS (SELECT 1 FROM public.test t WHERE NOT EXISTS (SELECT 1 FROM public.protocolo p WHERE p.id_test=t.id_test)) THEN
  RAISE EXCEPTION 'NEXO: Todo test debe tener al menos un protocolo.' USING ERRCODE='23514';
 END IF;
 IF EXISTS (SELECT 1 FROM public.evaluacion e WHERE NOT EXISTS (SELECT 1 FROM public.medicion m WHERE m.id_evaluacion=e.id_evaluacion)) THEN
  RAISE EXCEPTION 'NEXO: Toda evaluación guardada debe tener al menos una medición.' USING ERRCODE='23514';
 END IF;
 IF EXISTS (SELECT 1 FROM public.protocolo p WHERE NOT EXISTS (SELECT 1 FROM public.metrica m WHERE m.id_protocolo=p.id_protocolo)
   OR NOT EXISTS (SELECT 1 FROM public.metrica m WHERE m.id_protocolo=p.id_protocolo AND m.obligatoria)) THEN
  RAISE EXCEPTION 'NEXO: Cada protocolo necesita al menos una métrica y alguna obligatoria.' USING ERRCODE='23514';
 END IF;
 IF EXISTS (SELECT 1 FROM public.test t WHERE t.admite_registro AND NOT EXISTS
   (SELECT 1 FROM public.protocolo p WHERE p.id_test=t.id_test AND p.estado='vigente')) THEN
  RAISE EXCEPTION 'NEXO: Un test registrable necesita un protocolo vigente.' USING ERRCODE='23514';
 END IF;
 IF EXISTS (SELECT 1 FROM public.evaluacion e WHERE e.estado='completada' AND
   (e.fecha_realizacion IS NULL OR EXISTS (SELECT 1 FROM public.metrica m WHERE m.id_protocolo=e.id_protocolo AND m.obligatoria
      AND NOT EXISTS (SELECT 1 FROM public.medicion d WHERE d.id_evaluacion=e.id_evaluacion AND d.id_metrica=m.id_metrica)))) THEN
  RAISE EXCEPTION 'NEXO: Para completar una evaluación se necesitan fecha y todas sus métricas obligatorias.' USING ERRCODE='23514';
 END IF;
 IF EXISTS (SELECT 1 FROM public.medicion d JOIN public.evaluacion e USING(id_evaluacion)
   JOIN public.metrica m USING(id_metrica) WHERE e.id_protocolo<>m.id_protocolo) THEN
  RAISE EXCEPTION 'NEXO: Hay una medición ajena al protocolo de su evaluación.' USING ERRCODE='23514';
 END IF;
END;
$$;
CREATE FUNCTION public.nexo_ec_comprobar_diferido() RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
BEGIN PERFORM public.nexo_ec_assert_integridad(); RETURN NULL; END;
$$;
CREATE CONSTRAINT TRIGGER ec_integridad_test AFTER INSERT OR UPDATE OR DELETE ON public.test
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.nexo_ec_comprobar_diferido();
CREATE CONSTRAINT TRIGGER ec_integridad_protocolo AFTER INSERT OR UPDATE OR DELETE ON public.protocolo
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.nexo_ec_comprobar_diferido();
CREATE CONSTRAINT TRIGGER ec_integridad_metrica AFTER INSERT OR UPDATE OR DELETE ON public.metrica
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.nexo_ec_comprobar_diferido();
CREATE CONSTRAINT TRIGGER ec_integridad_evaluacion AFTER INSERT OR UPDATE OR DELETE ON public.evaluacion
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.nexo_ec_comprobar_diferido();
CREATE CONSTRAINT TRIGGER ec_integridad_medicion AFTER INSERT OR UPDATE OR DELETE ON public.medicion
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.nexo_ec_comprobar_diferido();

CREATE FUNCTION public.nexo_ec_estado() RETURNS jsonb
LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$
 SELECT jsonb_build_object(
 'deportista',coalesce((SELECT jsonb_agg(to_jsonb(t) ORDER BY alias,id_deportista) FROM public.deportista t),'[]'::jsonb),
 'test',coalesce((SELECT jsonb_agg(to_jsonb(t) ORDER BY nombre,id_test) FROM public.test t),'[]'::jsonb),
 'protocolo',coalesce((SELECT jsonb_agg(to_jsonb(t) ORDER BY id_test,version) FROM public.protocolo t),'[]'::jsonb),
 'metrica',coalesce((SELECT jsonb_agg(to_jsonb(t) ORDER BY id_protocolo,nombre) FROM public.metrica t),'[]'::jsonb),
 'evaluacion',coalesce((SELECT jsonb_agg(to_jsonb(t) ORDER BY fecha_creacion DESC,id_evaluacion) FROM public.evaluacion t),'[]'::jsonb),
 'medicion',coalesce((SELECT jsonb_agg(to_jsonb(t) ORDER BY id_evaluacion,numero_intento,lado,id_metrica) FROM public.medicion t),'[]'::jsonb));
$$;

CREATE FUNCTION public.nexo_ec_mutar(p_accion text,p_datos jsonb) RETURNS jsonb
LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
DECLARE d jsonb; pid text; eid text; n integer; ev public.evaluacion%ROWTYPE; total integer:=0;
BEGIN
 IF jsonb_typeof(p_datos)<>'object' THEN RAISE EXCEPTION 'NEXO: Datos no válidos.' USING ERRCODE='22023'; END IF;
 PERFORM pg_advisory_xact_lock(7564,20261030); -- serializa las escrituras del espacio
 CASE p_accion
 WHEN 'guardar_deportista' THEN
  INSERT INTO public.deportista(id_deportista,alias,fecha_alta,activo)
  VALUES(p_datos->>'id_deportista',p_datos->>'alias',coalesce((p_datos->>'fecha_alta')::timestamptz,now()),coalesce((p_datos->>'activo')::boolean,true))
  ON CONFLICT(id_deportista) DO UPDATE SET alias=EXCLUDED.alias,activo=EXCLUDED.activo;
 WHEN 'guardar_test' THEN
  UPDATE public.test SET nombre=p_datos->>'nombre',capacidad_principal=p_datos->>'capacidad_principal',admite_registro=(p_datos->>'admite_registro')::boolean
   WHERE id_test=p_datos->>'id_test';
  IF NOT FOUND THEN RAISE EXCEPTION 'NEXO: Crea el test junto con su primer protocolo y sus métricas.' USING ERRCODE='23514'; END IF;
 WHEN 'crear_test_completo' THEN
  IF EXISTS (SELECT 1 FROM public.test WHERE id_test=p_datos->'test'->>'id_test') THEN
   IF EXISTS (SELECT 1 FROM public.protocolo WHERE id_protocolo=p_datos->'protocolo'->>'id_protocolo' AND id_test=p_datos->'test'->>'id_test') THEN RETURN public.nexo_ec_estado(); END IF;
   RAISE EXCEPTION 'NEXO: Ese test ya existe; añade otra versión desde su ficha.' USING ERRCODE='23505';
  END IF;
  INSERT INTO public.test SELECT * FROM jsonb_populate_record(NULL::public.test,p_datos->'test');
  PERFORM public.nexo_ec_mutar('crear_protocolo',jsonb_build_object('protocolo',(p_datos->'protocolo')||jsonb_build_object('id_test',p_datos->'test'->>'id_test'),'metricas',p_datos->'metricas','habilitar_registro',false));
 WHEN 'crear_protocolo' THEN
  pid:=p_datos->'protocolo'->>'id_protocolo';
  IF EXISTS (SELECT 1 FROM public.protocolo WHERE id_protocolo=pid) THEN RETURN public.nexo_ec_estado(); END IF;
  INSERT INTO public.protocolo SELECT * FROM jsonb_populate_record(NULL::public.protocolo,p_datos->'protocolo');
  IF jsonb_typeof(p_datos->'metricas')<>'array' OR jsonb_array_length(p_datos->'metricas') NOT BETWEEN 1 AND 40 THEN
   RAISE EXCEPTION 'NEXO: Define al menos una métrica.' USING ERRCODE='23514';
  END IF;
  FOR d IN SELECT value FROM jsonb_array_elements(p_datos->'metricas') LOOP
   INSERT INTO public.metrica SELECT * FROM jsonb_populate_record(NULL::public.metrica,d||jsonb_build_object('id_protocolo',pid));
  END LOOP;
  IF coalesce((p_datos->>'habilitar_registro')::boolean,false) THEN UPDATE public.test SET admite_registro=true WHERE id_test=p_datos->'protocolo'->>'id_test'; END IF;
 WHEN 'estado_protocolo' THEN
  UPDATE public.protocolo SET estado=p_datos->>'estado' WHERE id_protocolo=p_datos->>'id_protocolo';
  IF NOT FOUND THEN RAISE EXCEPTION 'NEXO: Protocolo no encontrado.' USING ERRCODE='22023'; END IF;
 WHEN 'crear_evaluacion' THEN
  eid:=p_datos->'evaluacion'->>'id_evaluacion';
  IF jsonb_typeof(p_datos->'mediciones') IS DISTINCT FROM 'array' OR jsonb_array_length(p_datos->'mediciones') NOT BETWEEN 1 AND 200 THEN
   RAISE EXCEPTION 'NEXO: Añade al menos una medición antes de guardar la evaluación.' USING ERRCODE='23514';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.evaluacion WHERE id_evaluacion=eid) THEN
   INSERT INTO public.evaluacion(id_evaluacion,fecha_creacion,fecha_realizacion,estado,id_deportista,id_protocolo)
   VALUES(eid,coalesce((p_datos->'evaluacion'->>'fecha_creacion')::timestamptz,now()),(p_datos->'evaluacion'->>'fecha_realizacion')::timestamptz,'pendiente',p_datos->'evaluacion'->>'id_deportista',p_datos->'evaluacion'->>'id_protocolo');
   PERFORM public.nexo_ec_mutar('guardar_mediciones',jsonb_build_object('id_evaluacion',eid,'mediciones',p_datos->'mediciones','fecha_realizacion',p_datos->'evaluacion'->'fecha_realizacion','completar',coalesce((p_datos->>'completar')::boolean,false)));
  END IF;
 WHEN 'guardar_mediciones' THEN
  eid:=p_datos->>'id_evaluacion';
  SELECT * INTO ev FROM public.evaluacion WHERE id_evaluacion=eid FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NEXO: Evaluación no encontrada.' USING ERRCODE='22023'; END IF;
  IF ev.estado IN ('completada','cancelada') THEN RAISE EXCEPTION 'NEXO: Reabre la evaluación antes de modificar sus intentos.' USING ERRCODE='23514'; END IF;
  IF jsonb_typeof(p_datos->'mediciones')<>'array' OR jsonb_array_length(p_datos->'mediciones') NOT BETWEEN 1 AND 200 THEN
   RAISE EXCEPTION 'NEXO: Añade entre 1 y 200 mediciones.' USING ERRCODE='22023';
  END IF;
  FOR d IN SELECT value FROM jsonb_array_elements(p_datos->'mediciones') LOOP
   INSERT INTO public.medicion SELECT * FROM jsonb_populate_record(NULL::public.medicion,d||jsonb_build_object('id_evaluacion',eid))
   ON CONFLICT(id_medicion) DO UPDATE SET valor=EXCLUDED.valor,numero_intento=EXCLUDED.numero_intento,lado=EXCLUDED.lado,origen=EXCLUDED.origen,id_metrica=EXCLUDED.id_metrica
   WHERE public.medicion.id_evaluacion=EXCLUDED.id_evaluacion;
   GET DIAGNOSTICS n=ROW_COUNT;
   IF n<>1 THEN RAISE EXCEPTION 'NEXO: Identificador de medición no válido.' USING ERRCODE='22023'; END IF;
  END LOOP;
  UPDATE public.evaluacion SET estado=CASE WHEN coalesce((p_datos->>'completar')::boolean,false) THEN 'completada' ELSE 'en_curso' END,
   fecha_realizacion=coalesce((p_datos->>'fecha_realizacion')::timestamptz,fecha_realizacion)
   WHERE id_evaluacion=eid;
 WHEN 'estado_evaluacion' THEN
  UPDATE public.evaluacion SET estado=p_datos->>'estado',fecha_realizacion=CASE WHEN p_datos ? 'fecha_realizacion' THEN (p_datos->>'fecha_realizacion')::timestamptz ELSE fecha_realizacion END
   WHERE id_evaluacion=p_datos->>'id_evaluacion';
  IF NOT FOUND THEN RAISE EXCEPTION 'NEXO: Evaluación no encontrada.' USING ERRCODE='22023'; END IF;
 WHEN 'eliminar_medicion' THEN
  SELECT e.* INTO ev FROM public.evaluacion e JOIN public.medicion m USING(id_evaluacion) WHERE m.id_medicion=p_datos->>'id_medicion' FOR UPDATE OF e;
  IF NOT FOUND THEN RAISE EXCEPTION 'NEXO: Medición no encontrada.' USING ERRCODE='22023'; END IF;
  IF ev.estado IN ('completada','cancelada') THEN RAISE EXCEPTION 'NEXO: Reabre la evaluación antes de quitar una medición.' USING ERRCODE='23514'; END IF;
  IF (SELECT count(*) FROM public.medicion WHERE id_evaluacion=ev.id_evaluacion)<=1 THEN
   RAISE EXCEPTION 'NEXO: No puedes eliminar la última medición de una evaluación. Puedes corregirla.' USING ERRCODE='23514';
  END IF;
  DELETE FROM public.medicion WHERE id_medicion=p_datos->>'id_medicion';
 WHEN 'importar_ec' THEN
  PERFORM set_config('nexo_ec.importando','1',true);
  INSERT INTO public.deportista SELECT r.* FROM jsonb_populate_recordset(NULL::public.deportista,coalesce(p_datos->'deportista','[]'::jsonb)) r WHERE NOT EXISTS(SELECT 1 FROM public.deportista x WHERE x.id_deportista=r.id_deportista);
  INSERT INTO public.test SELECT r.* FROM jsonb_populate_recordset(NULL::public.test,coalesce(p_datos->'test','[]'::jsonb)) r WHERE NOT EXISTS(SELECT 1 FROM public.test x WHERE x.id_test=r.id_test);
  INSERT INTO public.protocolo SELECT r.* FROM jsonb_populate_recordset(NULL::public.protocolo,coalesce(p_datos->'protocolo','[]'::jsonb)) r WHERE NOT EXISTS(SELECT 1 FROM public.protocolo x WHERE x.id_protocolo=r.id_protocolo);
  INSERT INTO public.metrica SELECT r.* FROM jsonb_populate_recordset(NULL::public.metrica,coalesce(p_datos->'metrica','[]'::jsonb)) r WHERE NOT EXISTS(SELECT 1 FROM public.metrica x WHERE x.id_metrica=r.id_metrica);
  INSERT INTO public.evaluacion SELECT r.* FROM jsonb_populate_recordset(NULL::public.evaluacion,coalesce(p_datos->'evaluacion','[]'::jsonb)) r WHERE NOT EXISTS(SELECT 1 FROM public.evaluacion x WHERE x.id_evaluacion=r.id_evaluacion);
  INSERT INTO public.medicion SELECT r.* FROM jsonb_populate_recordset(NULL::public.medicion,coalesce(p_datos->'medicion','[]'::jsonb)) r WHERE NOT EXISTS(SELECT 1 FROM public.medicion x WHERE x.id_medicion=r.id_medicion);
  PERFORM set_config('nexo_ec.importando','',true);
 ELSE RAISE EXCEPTION 'NEXO: Operación no disponible.' USING ERRCODE='22023';
 END CASE;
 PERFORM public.nexo_ec_assert_integridad();
 RETURN public.nexo_ec_estado();
END;
$$;

-- Protección inicial: no se abre acceso entre 001 y 002.
ALTER TABLE public.deportista ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.protocolo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evaluacion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.metrica ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medicion ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.deportista,public.test,public.protocolo,public.evaluacion,public.metrica,public.medicion FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.nexo_ec_estado(),public.nexo_ec_mutar(text,jsonb),public.nexo_ec_assert_integridad(),public.nexo_ec_comprobar_diferido(),public.nexo_ec_validar_evaluacion(),public.nexo_ec_validar_medicion(),public.nexo_ec_preservar_protocolo(),public.nexo_ec_preservar_metrica() FROM PUBLIC,anon,authenticated;

COMMIT;
