# Verificación de la propuesta SQL

Fecha: 31 de octubre de 2026.

Los archivos 001_tablas.sql y 002_seguridad.sql se ejecutaron en una base
PostgreSQL aislada en memoria mediante PGlite 0.3.14. Para la prueba se crearon
roles locales anon, authenticated y service_role, sin conexión a Supabase.

Resultado: **23 comprobaciones correctas**.

| Comprobación | Resultado |
| --- | --- |
| 001 y 002 se ejecutan en PostgreSQL aislado | Correcto |
| Seis tablas y 34 campos coinciden con el modelo | Correcto |
| Seis claves primarias y seis claves ajenas con RESTRICT | Correcto |
| RLS y políticas de denegación en las seis tablas | Correcto |
| Permisos mínimos del servidor y bloqueo del acceso directo | Correcto |
| Crear un test con su protocolo y métrica en un guardado | Correcto |
| Guardar una evaluación con dos intentos sin filas vacías | Correcto |
| Rechazar test sin protocolo | Correcto |
| Rechazar evaluación sin mediciones | Correcto |
| Rechazar eliminación de la última medición | Correcto |
| Rechazar códigos de deportista inexistentes | Correcto |
| La clave ajena rechaza un protocolo inexistente | Correcto |
| Rechazar intento duplicado | Correcto |
| Rechazar métrica de otro protocolo | Correcto |
| Conservar instrucciones de un protocolo utilizado | Correcto |
| Conservar las métricas de un protocolo utilizado | Correcto |
| Bloquear borrado de deportista con evaluaciones | Correcto |
| Exigir fecha para completar una evaluación | Correcto |
| Rechazar decimales en una métrica entera | Correcto |
| Completar una evaluación con fecha y métricas obligatorias | Correcto |
| Denegar SELECT anónimo por permisos | Correcto |
| RLS oculta filas incluso si se concede SELECT temporalmente | Correcto |
| El PNG original y sus cardinalidades se conservan | Correcto |

Estas pruebas comprueban SQL, restricciones y permisos de PostgreSQL. No
simulan una sesión real de ChatGPT, las conexiones HTTP, Supabase Auth ni un
despliegue de la aplicación. Tampoco prueban concurrencia entre conexiones.

En Supabase real se consultaron únicamente metadatos de RLS, políticas y
permisos. No se ejecutaron los archivos propuestos ni se aplicaron cambios.

El permiso temporal de lectura utilizado para demostrar que RLS oculta filas
solo se concedió dentro de una transacción de la base aislada y se revirtió.

La propuesta deja pendiente la revisión del grupo y cualquier autorización de
un cambio concreto en el proyecto real.
