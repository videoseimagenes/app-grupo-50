# NEXO Performance · Grupo 50

Registro de evaluaciones físicas y consulta del historial de deportistas.

## Modelo y base de datos

- [Modelo E-C definitivo](docs/modelo-er.png): seis entidades y 28 atributos propios.
- [Revisión del modelo](docs/revision-modelo-ec.md).
- [Proyecto, conexión pública y reglas para ChatGPT](CHATGPT.md).
- [Instrucciones para ChatGPT/Codex](AGENTS.md).
- [001: tablas, reglas y reconocimiento de la estructura existente](supabase/migraciones/001_tablas.sql).
- [002: RLS y permisos mínimos del servidor](supabase/migraciones/002_seguridad.sql).
- [Explicación fácil de tablas, claves y permisos](docs/guia-tablas-y-seguridad.md).
- [Las 30 comprobaciones del SQL](docs/verificacion-sql.md).
- [Aplicación y comprobación en Supabase](docs/aplicacion-supabase.md).

**Fase 2, paso 3: aplicado y verificado el 31/10/2026.** Se reutilizó el
proyecto gratuito existente en Europa. Las migraciones conservaron las seis
tablas, sus datos y sus reglas, y limitaron al servidor a los permisos que
necesita. El asesor de seguridad devolvió cero avisos.

La app continúa en una vista previa privada de ChatGPT Sites. Este repositorio
contiene el modelo, la documentación y el SQL aplicado; todavía no contiene
toda la implementación ni una publicación en Cloudflare Pages.
