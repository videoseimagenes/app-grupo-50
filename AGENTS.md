# Instrucciones para ChatGPT/Codex

Lee primero `CHATGPT.md`, `docs/modelo-er.png` y
`docs/guia-tablas-y-seguridad.md`. Revisa la imagen, incluidas sus líneas,
cardinalidades y puntos de participación.

- Explica cada cambio en español y con palabras de principiante.
- Trabaja en una rama nueva y registra la propuesta en un Pull Request.
- Los archivos de `supabase/migraciones` son una propuesta para revisar.
  No los ejecutes ni modifiques tablas, datos, políticas o permisos del proyecto
  real sin aprobación expresa del grupo para ese cambio concreto.
- No uses nunca la secret key de Supabase. No solicites, copies, registres ni
  publiques credenciales privilegiadas, tokens, contraseñas o archivos `.env`.
- Mantén las seis entidades y los 28 atributos propios del modelo aprobado.
  Las tablas resultantes tienen 34 campos y seis claves ajenas.
- Todo test tiene al menos un protocolo y toda evaluación guardada tiene al
  menos una medición. Conserva también la coherencia entre métrica y protocolo.
- No declares que existe una publicación en Cloudflare, acceso directo desde
  el navegador o una sincronización de código que no se haya comprobado.
- Comprueba el SQL en una base aislada. La consulta de metadatos reales es de
  solo lectura; una prueba con cambios y ROLLBACK en producción también exige
  aprobación previa.
- La siguiente fase de la guía consiste en que el grupo revise y comprenda la
  propuesta. No presupongas que preparar estos archivos autoriza su aplicación.
