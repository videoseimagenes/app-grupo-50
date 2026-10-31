# Instrucciones para ChatGPT/Codex

Lee primero `CHATGPT.md`, `docs/modelo-er.png` y
`docs/guia-tablas-y-seguridad.md`. Revisa la imagen, incluidas sus líneas,
cardinalidades y puntos de participación.

- Explica cada cambio en español y con palabras de principiante.
- Trabaja en una rama nueva y registra la propuesta en un Pull Request.
- `001_tablas.sql` y `002_seguridad.sql` están aplicados y verificados desde
  el 31/10/2026. La primera admite instalación vacía o reconoce exactamente
  la estructura existente; la segunda conserva el acceso exclusivo por servidor.
  Cualquier ejecución futura o cambio en tablas, datos, políticas o permisos
  requiere aprobación expresa para ese cambio concreto.
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
- El paso de aprobación y aplicación de las dos migraciones está cerrado.
  Lee `docs/aplicacion-supabase.md` para ver qué se aplicó y qué se comprobó.
  No confundas la autorización de este cierre con permiso para cambios futuros.
- La URL y la publishable key de `CHATGPT.md` son públicas. Nunca las sustituyas
  por una secret key, una credencial de service_role o una contraseña.
