# Verificación del SQL aplicado

Fecha: 31 de octubre de 2026.

Los archivos 001_tablas.sql y 002_seguridad.sql se ejecutaron primero en
PostgreSQL aislado en memoria mediante PGlite 0.3.14, con roles locales anon,
authenticated y service_role. Resultado: **30 comprobaciones correctas**.

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
| Instalación vacía protegida incluso antes de 002 | Correcto |
| Reaplicar 001 conserva las filas y los objetos existentes | Correcto |
| Reaplicar 002 conserva políticas y permisos sin duplicarlos | Correcto |
| 001 rechaza un campo inesperado sin borrar filas ni corregir a ciegas | Correcto |
| Migración de una base poblada con la estructura anterior | Correcto |
| Retira TRUNCATE, TRIGGER y REFERENCES y conserva CRUD del servidor | Correcto |
| Una estructura parcial aborta sin crear ni borrar otras tablas | Correcto |

Los datos de estas pruebas son ficticios. Se comprobó la instalación vacía,
la adaptación de una estructura anterior ya poblada y la reaplicación de ambos
archivos sin perder filas, duplicar políticas ni cambiar los objetos existentes.
Una estructura parcial o diferente hizo abortar la migración de forma segura.

Después se aplicaron los archivos adaptados en Supabase real, con aprobación
para cerrar este paso. Las verificaciones posteriores consultaron metadatos,
permisos y recuentos. Confirmaron estructura conservada, integridad, acceso
del servidor, bloqueo del acceso REST anónimo y cero avisos de seguridad.
Versiones y recuentos: [Informe de aplicación](aplicacion-supabase.md).

La comprobación de RLS con un GRANT temporal solo se hizo en la base aislada
y se revirtió. No se concedió acceso público temporal en Supabase real.

Las pruebas no cubren concurrencia entre conexiones, toda la sesión HTTP de
ChatGPT, Supabase Auth, Cloudflare ni dispositivos reales. Este cambio modifica
los permisos de las seis tablas; no despliega una interfaz nueva.
