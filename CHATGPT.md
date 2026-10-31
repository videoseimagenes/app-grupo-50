# NEXO Performance: proyecto del grupo 50

## Qué queremos hacer

NEXO Performance permite registrar evaluaciones físicas y consultar el historial
de cada deportista. Se elige una prueba y la versión de sus instrucciones y se
guardan los resultados de los distintos intentos. Así sabemos quién hizo la
prueba, qué instrucciones siguió y qué obtuvo.

## Integrantes

- Pablo Martínez Ferro.
- Sergio Pérez Barrientos.
- Daniel Mato Gómez.

La asignación de los roles A, B y C no está confirmada en este repositorio.

## Tecnología y estado comprobado

| Parte | Situación actual |
| --- | --- |
| Modelo | Canva; copia definitiva en `docs/modelo-er.png`. |
| Datos de evaluación | PostgreSQL en Supabase: seis tablas del modelo. |
| Interfaz académica | HTML, CSS y JavaScript dentro de la app de ChatGPT Sites. |
| Servidor | API privada de Sites y una función de Supabase que limita las operaciones disponibles. |
| Identificación | La app comprueba la identidad de ChatGPT del propietario en el servidor. No equivale a iniciar sesión con Supabase Auth. |
| Código de la app | Proyecto existente de ChatGPT Sites, con proceso de compilación. Este repositorio contiene por ahora documentación y la propuesta SQL; no contiene todavía toda la app. |
| Publicación | Vista previa privada de ChatGPT Sites. |

La ruta de la guía propone HTML/CSS/JS sin compilación, `supabase-js` desde CDN y
Cloudflare Pages. Es una alternativa pendiente de decidir e implementar.
Preparar el SQL no migra la app a Cloudflare ni activa acceso público a sus
datos. Si se adopta esa ruta, habrá que definir antes el servidor o el sistema
de autenticación que autorizará cada operación.

## Modelo de datos aprobado

| Entidad | Para qué sirve | Atributos propios |
| --- | --- | ---: |
| deportista | Persona evaluada. | 4 |
| test | Ficha de la prueba física. | 4 |
| protocolo | Una versión de las instrucciones de un test. | 5 |
| evaluacion | Una ocasión de evaluación de una persona según un protocolo. | 4 |
| metrica | Qué se mide, su unidad y las condiciones del valor. | 6 |
| medicion | Valor obtenido en un intento. | 5 |

Son seis entidades, 28 atributos propios y seis correspondencias binarias 1:n.
Al transformar el modelo se obtienen seis tablas: los 28 campos propios más
seis claves ajenas. No existen relaciones N:M en este modelo aprobado.

Cada test tiene uno o más protocolos. Cada protocolo pertenece a un test y
define una o más métricas, con alguna obligatoria. Cada evaluación corresponde
a un deportista y a un protocolo, y contiene una o más mediciones. Cada medición
corresponde a una evaluación y a una métrica del protocolo de esa evaluación.
Un deportista puede existir sin evaluaciones; un protocolo y una métrica pueden
existir antes de registrar resultados.

Un formulario vacío es un borrador en pantalla. La evaluación se guarda junto
con su primera medición. Los protocolos utilizados conservan sus instrucciones
y métricas; un cambio de procedimiento requiere otra versión.

## Preparación de la fase 2, paso 1

- `supabase/migraciones/001_tablas.sql`: propuesta del esquema, restricciones,
  validaciones y operaciones conjuntas de las seis tablas.
- `supabase/migraciones/002_seguridad.sql`: RLS y permisos del acceso por servidor.
- `docs/guia-tablas-y-seguridad.md`: explicación para revisar las decisiones.

Estos archivos no se han ejecutado en el proyecto real. Son una referencia
para una base vacía: en el proyecto actual las tablas ya existen. No constituyen
una migración que se pueda aplicar directamente sobre ellas. Si se aprueba un
cambio real, se preparará una migración específica que conserve los datos.

El catálogo documental y otras funciones antiguas de la app están fuera de las
seis entidades de evaluación; no se copian sus datos ni se recrea esa
infraestructura en estos dos archivos.

## Reglas de trabajo

1. Explicar los cambios para principiantes y justificar cada clave ajena.
2. Pedir aprobación expresa antes de modificar Supabase real.
3. No usar nunca la secret key de Supabase; no pedirla, copiarla ni publicarla.
4. Mantener el modelo, el SQL y la documentación coherentes entre sí.
5. Guardar las propuestas en ramas y Pull Requests que el grupo pueda revisar.
6. Separar lo preparado, lo aprobado y lo aplicado; no dar una fase por
   aplicada solo porque sus archivos estén escritos.

La infraestructura existente utiliza internamente el rol técnico `service_role`
en una función del servidor de Supabase. Ese rol puede saltarse RLS: la
autorización del propietario se comprueba antes, en el servidor. Esta
preparación SQL no obtiene ni utiliza una clave de ese rol. Ese funcionamiento
debe explicarse como una diferencia respecto a una página que acceda
directamente desde el navegador con una clave pública.
