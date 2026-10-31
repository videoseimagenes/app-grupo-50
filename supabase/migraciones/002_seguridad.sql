-- NEXO Performance, grupo 50. Seguridad aprobada, 31/10/2026.
-- Se aplica después de 001_tablas.sql; también admite una política ya existente.
-- Conserva el servidor privado: anon y authenticated no acceden a estas tablas.
-- service_role es un rol técnico: este archivo no obtiene ni usa su clave.
-- Solo se conceden SELECT, INSERT, UPDATE y DELETE; sin TRUNCATE, TRIGGER o REFERENCES.
BEGIN;

DO $nexo_seguridad$
DECLARE tabla text; comando text;
BEGIN
 FOREACH tabla IN ARRAY ARRAY['deportista','test','protocolo','evaluacion','metrica','medicion'] LOOP
  EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',tabla);
  EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC,anon,authenticated,service_role',tabla);
  EXECUTE format('GRANT SELECT,INSERT,UPDATE,DELETE ON public.%I TO service_role',tabla);
  SELECT cmd INTO comando FROM pg_policies
   WHERE schemaname='public' AND tablename=tabla AND policyname='ec_solo_servidor';
  IF FOUND THEN
   IF comando<>'ALL' THEN
    RAISE EXCEPTION 'NEXO: La política existente de % necesita revisión.',tabla USING ERRCODE='23514';
   END IF;
   EXECUTE format('ALTER POLICY ec_solo_servidor ON public.%I TO anon,authenticated USING (false) WITH CHECK (false)',tabla);
  ELSE
   EXECUTE format('CREATE POLICY ec_solo_servidor ON public.%I FOR ALL TO anon,authenticated USING (false) WITH CHECK (false)',tabla);
  END IF;
 END LOOP;
END;
$nexo_seguridad$;

REVOKE ALL ON FUNCTION public.nexo_ec_estado(),public.nexo_ec_mutar(text,jsonb),public.nexo_ec_assert_integridad(),public.nexo_ec_comprobar_diferido(),public.nexo_ec_validar_evaluacion(),public.nexo_ec_validar_medicion(),public.nexo_ec_preservar_protocolo(),public.nexo_ec_preservar_metrica() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.nexo_ec_estado(),public.nexo_ec_mutar(text,jsonb),public.nexo_ec_assert_integridad(),public.nexo_ec_comprobar_diferido(),public.nexo_ec_validar_evaluacion(),public.nexo_ec_validar_medicion(),public.nexo_ec_preservar_protocolo(),public.nexo_ec_preservar_metrica() TO service_role;

-- Verifica permisos efectivos, además de las concesiones escritas.
DO $nexo_permisos$
DECLARE tabla text; rol text; permiso text;
BEGIN
 FOREACH tabla IN ARRAY ARRAY['deportista','test','protocolo','evaluacion','metrica','medicion'] LOOP
  FOREACH rol IN ARRAY ARRAY['anon','authenticated'] LOOP
   FOREACH permiso IN ARRAY ARRAY['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER'] LOOP
    IF has_table_privilege(rol,format('public.%I',tabla),permiso) THEN
     RAISE EXCEPTION 'NEXO: Permiso inesperado % para % en %.',permiso,rol,tabla USING ERRCODE='23514';
    END IF;
   END LOOP;
  END LOOP;
  FOREACH permiso IN ARRAY ARRAY['SELECT','INSERT','UPDATE','DELETE'] LOOP
   IF NOT has_table_privilege('service_role',format('public.%I',tabla),permiso) THEN
    RAISE EXCEPTION 'NEXO: Falta permiso % del servidor en %.',permiso,tabla USING ERRCODE='23514';
   END IF;
  END LOOP;
  FOREACH permiso IN ARRAY ARRAY['TRUNCATE','REFERENCES','TRIGGER'] LOOP
   IF has_table_privilege('service_role',format('public.%I',tabla),permiso) THEN
    RAISE EXCEPTION 'NEXO: Sobra permiso % del servidor en %.',permiso,tabla USING ERRCODE='23514';
   END IF;
  END LOOP;
 END LOOP;
END;
$nexo_permisos$;
COMMIT;
