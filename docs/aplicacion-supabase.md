# Aplicación en Supabase: fase 2, paso 3

Fecha: 31 de octubre de 2026. Estado: **aplicado y verificado**.

## Proyecto reutilizado

- Proyecto: NEXO Performance (`wkgatoyuddpmvsjrugor`).
- Organización existente: Pablo Martínez Ferro.
- Región europea: `eu-west-3`.
- Plan: Free. No se creó un proyecto de pago ni se cambió el plan.
- La Project URL y la publishable key activa están en [CHATGPT.md](../CHATGPT.md).

La guía propone nombres grupo-50/app-grupo-50. Se reutilizó el proyecto
existente que ya utiliza NEXO, conservando su nombre y su conexión actual.

## Qué se ejecutó

| Migración registrada | Versión de Supabase |
| --- | --- |
| `grupo50_001_tablas` | `20261031160928` |
| `grupo50_002_seguridad` | `20261031160949` |

Los archivos exactos están en `supabase/migraciones/001_tablas.sql` y
`supabase/migraciones/002_seguridad.sql`.

| Archivo | SHA-256 |
| --- | --- |
| 001_tablas.sql | `264eaf8dbca2b117f9ece4d59e4f6dc84f4880309c1b1280dad3b2d66722efc6` |
| 002_seguridad.sql | `d53babd1dcad843c9c0394f2d5bee02e7b0dbc05077f47fb7effce1a57911072` |

La aprobación de cierre recibida del representante del grupo incluía adaptar,
aplicar y registrar las migraciones en el proyecto existente. No autoriza
cambios futuros ni una modificación de los requisitos del modelo.

## Por qué se adaptaron los archivos

Las seis tablas ya existían. La versión inicial de 001 solo creaba una base
vacía: ejecutarla sin adaptar habría fallado. Ahora comprueba cinco grupos
completos de metadatos: campos, restricciones, índices, funciones y triggers.
Si están las seis tablas y coinciden, las conserva. Si no hay ninguna,
instala el modelo. Si hay una estructura parcial o diferente, aborta.

Las huellas de 001 corresponden solo a definiciones técnicas. No se calculan
ni exportan huellas del contenido de las filas. El archivo 002 crea o ajusta
las políticas existentes sin duplicarlas y comprueba los permisos efectivos.

## Resultado técnico

- Seis tablas, 34 campos, seis claves primarias y seis claves ajenas.
- Las seis FK son obligatorias y tienen ON DELETE RESTRICT.
- Los 34 campos, las 36 restricciones, los 12 índices, las ocho funciones,
  los nueve triggers y las seis políticas se conservaron.
- RLS sigue activo en las seis tablas. anon/authenticated no tienen acceso directo.
- El rol técnico conserva SELECT, INSERT, UPDATE y DELETE. Se retiraron sus
  permisos explícitos TRUNCATE, TRIGGER y REFERENCES sobre estas seis tablas.
- Se mantiene EXECUTE de las funciones del servidor y se deniega a los clientes.
- La función de lectura pudo ejecutarse como service_role y la comprobación
  de integridad terminó correctamente. No se utilizó ninguna clave privilegiada.
- La petición REST con la publishable key y sin usuario obtuvo HTTP 401 / 42501.
- El asesor de seguridad de Supabase devolvió **cero avisos** antes y después.

No fue necesaria una tercera migración para corregir avisos. Las dos aplicadas
registran el modelo y sus permisos. El rol técnico puede saltarse RLS: la
autorización del propietario continúa en el servidor privado de la app.

## Recuentos conservados

Se consultaron exclusivamente recuentos y metadatos. Las migraciones aplicadas
no ejecutaron inserciones, actualizaciones ni borrados de las filas existentes.

| Tabla | Antes | Después |
| --- | ---: | ---: |
| catalogo_documental | 320 | 320 |
| deportista | 4 | 4 |
| evaluacion | 11 | 11 |
| invites | 0 | 0 |
| medicion | 13 | 13 |
| members | 0 | 0 |
| metrica | 24 | 24 |
| protocolo | 24 | 24 |
| test | 21 | 21 |
| versions | 0 | 0 |
| workspaces | 0 | 0 |

## Comprobaciones aisladas

Pasaron **30 comprobaciones** en PostgreSQL en memoria con PGlite 0.3.14:
las 23 de integridad y permisos del modelo, más siete de instalación,
reaplicación sin duplicados, conservación de filas ficticias, retirada de
permisos adicionales y rechazo seguro de estructuras parciales o diferentes.
Los detalles están en [Verificación SQL](verificacion-sql.md).

Estas pruebas no sustituyen pruebas en dispositivos reales, de concurrencia
entre conexiones, de Supabase Auth o de una publicación en Cloudflare.
La app actual conserva su servidor privado de ChatGPT Sites.

## Cómo explicarlo con palabras fáciles

«Las seis listas ya estaban creadas. Comprobamos que tenían las casillas y
las conexiones del dibujo. Guardamos esa comprobación como migración y
quitamos al servidor permisos de administración que no necesitaba. Las
personas y los resultados guardados siguen ahí.»
