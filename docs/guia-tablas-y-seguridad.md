# Tablas, claves y seguridad, explicado fácilmente

## Qué está terminado en este paso

El SQL y la seguridad del modelo se aprobaron, adaptaron y aplicaron el
31/10/2026. Como las seis tablas ya existían, el archivo 001 comprobó que
coincidían y las conservó. El archivo 002 dejó al servidor solo los permisos
de leer, crear, editar y borrar que necesita la app. Los recuentos no cambiaron.

Los archivos también pueden instalar el modelo en una base vacía autorizada.
Si encuentran solo algunas tablas o una estructura distinta, se detienen: no
borran datos ni intentan corregir el proyecto sin una revisión específica.

El SQL usa nombres en español, en minúsculas y sin tildes. Las funciones
adicionales comprueban reglas; no son más entidades ni más tablas.

## Una tabla es una lista ordenada

Cada fila contiene un caso: un deportista, una prueba o una medición. Cada
columna guarda un dato. En el modelo tenemos seis listas relacionadas:

| Tabla | Qué guarda | Clave primaria | Campos totales |
| --- | --- | --- | ---: |
| deportista | El perfil de una persona. | id_deportista | 4 |
| test | Una prueba física. | id_test | 4 |
| protocolo | Una versión de sus instrucciones. | id_protocolo | 6 |
| evaluacion | Una ocasión en que una persona se evalúa. | id_evaluacion | 6 |
| metrica | Qué se mide y con qué unidad. | id_metrica | 7 |
| medicion | El resultado de un intento. | id_medicion | 7 |

Total: seis tablas y 34 campos. Los 28 atributos propios de las entidades se
conservan y se añaden seis claves ajenas al transformar las correspondencias.

## Para qué sirve cada clave primaria

La clave primaria es el código único de una fila: no se repite ni admite NULL
(ausencia de valor). Los códigos se guardan como texto. Un nombre o un alias pueden repetirse, por
eso no identificamos a las personas por su nombre.

- `id_deportista` distingue un perfil de otro.
- `id_test` distingue una prueba de otra.
- `id_protocolo` distingue una versión concreta de las instrucciones.
- `id_evaluacion` distingue una ocasión de evaluación de otra.
- `id_metrica` distingue una variable definida dentro de un protocolo.
- `id_medicion` distingue un resultado concreto de otro.

Por ejemplo, repetir una prueba otro día crea otra evaluación. Hacer dos
intentos dentro de la misma evaluación crea dos mediciones.

## Por qué colocamos las seis claves ajenas ahí

Una clave ajena guarda el código de una fila de otra tabla. En nuestras
correspondencias 1:n, se añade a la tabla del lado n. Todas son obligatorias:
una fila del lado n tiene que señalar exactamente una fila del lado 1.

| Campo que se añade | A qué apunta | Por qué está ahí |
| --- | --- | --- |
| protocolo.id_test | test.id_test | Un test tiene varias versiones; cada protocolo necesita identificar su test. |
| evaluacion.id_deportista | deportista.id_deportista | Una persona puede tener muchas evaluaciones; cada evaluación indica quién la realiza. |
| evaluacion.id_protocolo | protocolo.id_protocolo | Un protocolo puede usarse muchas veces; cada evaluación conserva la versión que siguió. |
| metrica.id_protocolo | protocolo.id_protocolo | Un protocolo define varias métricas; cada métrica indica a qué protocolo pertenece. |
| medicion.id_evaluacion | evaluacion.id_evaluacion | Una evaluación puede tener muchos resultados; cada resultado indica de qué ocasión procede. |
| medicion.id_metrica | metrica.id_metrica | Una métrica puede medirse muchas veces; cada resultado indica qué se ha medido. |

La clave ajena también evita guardar un código que no existe. No podemos
atribuir una evaluación a un deportista inexistente.

## Cómo se resuelve cada N:M

No hay correspondencias N:M en el modelo aprobado: las seis son 1:n. Por eso
no añadimos una tabla puente. No hay que inventar una relación de cada tipo
solo porque la teoría explique varios tipos.

Si más adelante una evaluación incluyese varios deportistas, ya sería otro
requisito y habría que revisar el modelo antes de cambiar las tablas.

## Los puntos obligatorios necesitan comprobaciones adicionales

Una clave ajena en PROTOCOLO obliga a que ese protocolo tenga un test. Por sí
sola no obliga a que todos los tests tengan un protocolo. Por eso añadimos una
comprobación al terminar la transacción, es decir, al guardar juntas todas las
operaciones de una acción.

- Un test se guarda junto con su primer protocolo y sus métricas.
- Una evaluación se guarda junto con su primera medición.
- Un protocolo debe tener métricas, con al menos una obligatoria.
- Una evaluación completada debe tener fecha y al menos un resultado válido
  de cada métrica obligatoria.
- Cada medición debe usar una métrica del mismo protocolo que la evaluación.

Comprobarlo al final permite crear primero la fila principal y después sus
filas relacionadas, dentro del mismo guardado. Si falta algo, se cancela el
conjunto; no se conserva una evaluación vacía ni se inventa un valor cero.

Las funciones de operaciones conjuntas usan un bloqueo de transacción para
ordenar las escrituras que pasan por esa función. El SQL incluye esas
operaciones además de las tablas; no añade entidades al modelo.

## Otras reglas que protege el SQL

- Una misma versión no se repite dentro del mismo test: UNIQUE(id_test, version).
- Un mismo intento de una métrica y lado no se registra dos veces dentro de
  una evaluación: UNIQUE(id_evaluacion, id_metrica, numero_intento, lado).
- El número de intento es un entero positivo. Los resultados son números
  finitos; un número negativo puede ser correcto.
- Si la métrica admite solo enteros, se rechazan resultados con decimales.
- Para nuevas evaluaciones, el deportista debe estar activo, el test debe
  admitir registro y el protocolo estar vigente.
- Los protocolos usados conservan sus instrucciones y sus métricas. Se crea
  otra versión para un procedimiento nuevo.

## Qué ocurre al borrar: ON DELETE RESTRICT

Todas las claves ajenas usan RESTRICT: se bloquea el borrado de una fila si
otra depende de ella. No hay borrado automático en cascada.

| Intento de borrado | Qué lo bloquea |
| --- | --- |
| Borrar un deportista | Sus evaluaciones. |
| Borrar un test | Sus protocolos. |
| Borrar un protocolo | Sus métricas y evaluaciones; también se protege el historial de protocolos utilizados. |
| Borrar una evaluación | Sus mediciones. |
| Borrar una métrica | Sus mediciones; además, las métricas de un protocolo utilizado se conservan. |
| Borrar una medición | No depende otra tabla de ella, pero no puede ser la última de su evaluación. La operación de la app exige reabrir una evaluación completada o cancelada antes de cambiar resultados. |

Desactivar un deportista o retirar un protocolo permite conservar el historial.
No significa borrar las filas que lo componen.

## Seguridad: dos puertas distintas

Los permisos de tabla indican qué operaciones puede intentar un rol. RLS
comprueba qué filas puede utilizar. Tener una clave pública no sustituye esas
comprobaciones.

En la app actual, el navegador solicita las acciones al servidor privado de
NEXO. El servidor comprueba la identidad de ChatGPT del propietario y se
comunica con una función acotada de Supabase. No se usa Supabase Auth para
identificar a ese propietario en el navegador.

| Rol | Permiso aplicado sobre las seis tablas |
| --- | --- |
| anon | Sin acceso directo de lectura o escritura. |
| authenticated | Sin acceso directo, aunque exista una sesión de Supabase Auth. Esa sesión por sí sola no autoriza datos de NEXO. |
| service_role | SELECT, INSERT, UPDATE y DELETE desde infraestructura de servidor autorizada. No se le conceden TRUNCATE, TRIGGER ni REFERENCES en esta configuración. |

### Qué permite cada política

El archivo 002 crea la política `ec_solo_servidor` en cada una de las seis
tablas: deportista, test, protocolo, evaluacion, metrica y medicion.

Todas tienen el mismo significado:

- Se dirigen a los roles anon y authenticated, para todas las operaciones.
- USING(false) no permite usar filas existentes para leer, actualizar o borrar.
- WITH CHECK(false) no permite insertar una fila ni conservar una actualización.
- Además, se retiran los permisos directos sobre las tablas y las funciones.

Son seis políticas independientes con la misma regla. No autorizan a los
usuarios del navegador a entrar en las tablas. En una base vacía, el archivo
001 activa RLS desde el principio para que no exista una ventana de acceso
abierto antes de aplicar el archivo 002.

El rol técnico service_role puede saltarse RLS. Por eso el control de quién
puede usar NEXO está en el servidor y sus credenciales no pueden estar en
HTML, JavaScript del navegador, documentos ni GitHub. Este cierre no
obtiene ni utiliza ninguna secret key.

Si se cambia a la ruta de la guía de una web estática con acceso directo a
Supabase, estas políticas no permitirán consultar ni guardar desde ella. Antes
habrá que diseñar y aprobar la autenticación y los permisos correspondientes;
no se resuelve dando permiso a todo el mundo.

## Qué coincide con la base actual y qué cambió

La comparación del 31/10/2026 confirmó que coincidían los 34 campos, las
36 restricciones de PostgreSQL, los 12 índices, las ocho funciones, los nueve
triggers y las seis políticas. Son objetos técnicos; no son más entidades.

La migración 001 reconoció esa estructura. La 002 retiró del rol técnico
TRUNCATE, TRIGGER y REFERENCES: son permisos de vaciar o administrar tablas
que el servidor no necesita. Conservó SELECT, INSERT, UPDATE y DELETE.
Los roles anon y authenticated siguen sin acceso directo.

Se comprobaron los recuentos antes y después, sin extraer filas ni huellas de
su contenido. El catálogo documental conserva sus 320 fichas y la
infraestructura privada se mantiene. El asesor de seguridad muestra cero avisos.

## Qué tiene que poder explicar el grupo

Cada integrante debe entender las seis claves ajenas, los puntos obligatorios,
las reglas de borrado y los permisos anteriores. La aplicación técnica de los
SQL no sustituye vuestra comprensión. Podéis practicar con un deportista,
una prueba, un protocolo, una métrica, una evaluación y dos intentos.

El informe de cierre está en [Aplicación en Supabase](aplicacion-supabase.md).
La app continúa en su vista previa privada de ChatGPT Sites. Este paso no
cambia su publicación ni habilita el acceso directo desde una web estática.

## Documentación técnica consultada

- [RLS en Supabase](https://supabase.com/docs/guides/database/postgres/row-level-security).
- [Claves ajenas en PostgreSQL](https://www.postgresql.org/docs/current/ddl-constraints.html).
- [Políticas en PostgreSQL](https://www.postgresql.org/docs/current/sql-createpolicy.html).
