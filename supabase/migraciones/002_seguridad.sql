-- NEXO Performance, grupo 50. PROPUESTA PARA REVISAR, NO APLICADA.
-- Aplicable después de 001_tablas.sql en una base VACÍA autorizada.
-- Requiere los roles estándar de Supabase: anon, authenticated y service_role.
-- Conserva el acceso por servidor privado de la app actual.
-- El rol service_role no es una clave: aquí no se solicita ni usa ninguna.
-- Solo se concede CRUD; no se concede TRUNCATE, TRIGGER ni REFERENCES.
BEGIN;

ALTER TABLE public.deportista ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.protocolo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evaluacion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.metrica ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medicion ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.deportista,public.test,public.protocolo,public.evaluacion,public.metrica,public.medicion FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.deportista,public.test,public.protocolo,public.evaluacion,public.metrica,public.medicion TO service_role;
CREATE POLICY ec_solo_servidor ON public.deportista FOR ALL TO anon,authenticated USING (false) WITH CHECK (false);
CREATE POLICY ec_solo_servidor ON public.test FOR ALL TO anon,authenticated USING (false) WITH CHECK (false);
CREATE POLICY ec_solo_servidor ON public.protocolo FOR ALL TO anon,authenticated USING (false) WITH CHECK (false);
CREATE POLICY ec_solo_servidor ON public.evaluacion FOR ALL TO anon,authenticated USING (false) WITH CHECK (false);
CREATE POLICY ec_solo_servidor ON public.metrica FOR ALL TO anon,authenticated USING (false) WITH CHECK (false);
CREATE POLICY ec_solo_servidor ON public.medicion FOR ALL TO anon,authenticated USING (false) WITH CHECK (false);

REVOKE ALL ON FUNCTION public.nexo_ec_estado(),public.nexo_ec_mutar(text,jsonb),public.nexo_ec_assert_integridad(),public.nexo_ec_comprobar_diferido(),public.nexo_ec_validar_evaluacion(),public.nexo_ec_validar_medicion(),public.nexo_ec_preservar_protocolo(),public.nexo_ec_preservar_metrica() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.nexo_ec_estado(),public.nexo_ec_mutar(text,jsonb),public.nexo_ec_assert_integridad(),public.nexo_ec_comprobar_diferido(),public.nexo_ec_validar_evaluacion(),public.nexo_ec_validar_medicion(),public.nexo_ec_preservar_protocolo(),public.nexo_ec_preservar_metrica() TO service_role;

COMMIT;
