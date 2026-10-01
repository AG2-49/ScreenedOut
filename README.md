# Estructura del proyecto

> **Limitación de Processing:** los `.pde` deben estar todos en la carpeta raíz del sketch
> (se concatenan en una sola clase), así que **no se pueden agrupar en subcarpetas**.
> Los módulos se agrupan por **prefijo de nombre**: el IDE ordena las pestañas
> alfabéticamente, por lo que cada grupo queda junto. Las carpetas reales sí funcionan
> dentro de `data/` (assets, niveles, guardado).

## Módulos (pestañas)

| Prefijo | Archivo | Responsabilidad |
|---|---|---|
| — | `Main` | `setup`/`draw` y reparto de eventos a la pantalla activa. Nada más. |
| — | `Config` | Constantes globales y layout (`mapArea`, `progArea`, `TILE_SIZE`). |
| **Engine** | `Engine_Assets` | Carga y prepara texturas (escala, rotaciones, tablas por máscara). |
| | `Engine_Tiles` | `MapRenderer`: convierte un `Level` en imagen (autotiling + objetos). Las paredes se conectan a las puertas como si fueran pared (`neighborJoins`). |
| | `Engine_Camera` | `Camera`: recorte, arrastre (solo si hay desborde), seguimiento y sombras. |
| **Game** | `Game_Level` | `Level` (matriz + objetos + inicio), carga desde JSON, `LevelCatalog`. |
| | `Game_Objects` | `GameObject` y sus tipos: `Door`, `FloorButton`, `Computer`, `Note`. |
| | `Game_Tasks` | `Task`: texto + objeto con el que hay que interactuar. |
| | `Game_Player` | `Player`: movimiento, verificación de casilla destino, interacción y animación (estado lógico vs. visual). |
| **Program** | `Program_Actions` | Catálogo de acciones y `executeAction()`. |
| | `Program_Runner` | `Program` (la secuencia) y `ProgramRunner` (ejecución paso a paso). |
| | `Program_Panel` | Interfaz: paleta, lista con scroll, botones Limpiar/Correr. |
| **Save** | `Save_Progress` | `Progress`: niveles completados, guardar/cargar/reiniciar. |
| **Screen** | `Screen_Manager` | Clase base `Screen` y `goTo()`. |
| | `Screen_Home` / `_LevelSelect` / `_Level` / `_Placeholder` | Cada pantalla del juego. |
| **UI** | `UI_Widgets` | `Rect` y `UIButton` reutilizables. |
| | `UI_NoteViewer` | Nota a pantalla completa: reemplaza al mapa y pausa el juego hasta cerrarla. |
| | `UI_TaskPanel` | Región izquierda: tareas visibles y texto de las notas leídas (paleta de la nota). |

Flujo de dependencias: `Screen_*` → (`Game_*`, `Engine_*`, `Program_*`, `Save_*`) → `UI_*`/`Config`.
Los módulos de motor y de juego **no conocen** las pantallas.

## Carpeta `data/`

```
data/
  Assets/tiles/   texturas del mapa (Floor, Wall1-4, hole1-6, door, computer, note, botones)
                  Wall1-4 son sprites SIN fondo (solo la banda gris): se dibujan sobre Floor.
  Assets/ui/      íconos de acciones (step, action, clockwise, counterclockwise)
  levels/         index.json (orden de niveles) + un JSON por nivel
  save.json       se crea solo al completar el primer nivel
```

## Cómo se añade…

**Un nivel:** crea `data/levels/levelXX.json` y añade su id a `levels/index.json`.

```json
{
  "id": "level02",
  "name": "Nivel 2",
  "start": { "row": 0, "col": 0, "direction": "right" },
  "map": [ "B.D.N" ],
  "links": [ { "from": [0, 0], "to": [0, 2] } ],
  "tasks": [ { "text": "Pulsar el botón", "target": [0, 0] } ],
  "notes": [ {
    "at": [0, 4],
    "text": "Texto de la nota.",
    "tasks": [ { "text": "Abrir la puerta", "target": [0, 2] } ]
  } ]
}
```
Caracteres del mapa: `.` suelo · `W` pared · `H` hueco · `D` puerta · `G` computadora (escritorio) · `B` botón · `N` nota.
Coordenadas siempre `[fila, columna]`. `direction`: `up`, `right`, `down`, `left`.
- `links`: el objeto `from` activa al objeto `to` (botón → puerta). Una puerta ligada **no** se abre con interactuar.
- `tasks`: tareas visibles desde el inicio. Cada una es un texto y el objeto (`target`) con el que hay que interactuar.
- `notes`: cada nota debe estar en el mapa con `N` en la posición `at`. Al leerla (interactuar) se abre su `text`
  a pantalla completa sobre el mapa; además pasa a la lista de notas leídas y sus `tasks` se añaden a la lista de tareas.
- Una tarea o nota que apunte a una posición sin objeto se ignora con un aviso en la consola.

**Un tipo de objeto:** clase que herede de `GameObject` (`Game_Objects`), un `case` en
`Level.createObject()` y su textura en `Assets`.

**Una acción programable:** constante + etiqueta + `case` en `Program_Actions`, e ícono en `Assets`.

**Una pantalla:** clase que herede de `Screen` y `goTo(new MiPantalla())`.

## Reglas de juego actuales (fáciles de cambiar)

- Una puerta cerrada bloquea el paso; se abre con *Interactuar* (si no está ligada a un botón).
- **El nivel se completa al leer todas las notas y cumplir todas las tareas** (`Level.allGoalsMet`).
  Un nivel sin tareas ni notas no se completa solo.
- Una tarea cuenta como cumplida si su objeto registró una interacción exitosa, aunque haya sido
  *antes* de que la nota que la añade se leyera.
- Las notas no bloquean el paso; se leen interactuando con ellas desde una casilla vecina **o estando encima**.
- **Interactuar** prueba primero el objeto de la casilla donde está el jugador y, si no existe o no hizo
  nada (p. ej. una puerta ya abierta), el de la casilla de enfrente (`Player.interact`).
- **Nota abierta = juego en pausa:** el programa deja de avanzar (`ProgramRunner` no acumula tiempo),
  no se edita la secuencia ni se mueve el jugador, y el nivel no puede completarse. Solo responden
  «Cerrar nota» (también Enter/Espacio), el botón «Menú» y los desplazamientos. Al cerrar, la ejecución continúa.
- Al pulsar «Correr» el nivel se reinicia y el jugador se ve primero en su casilla de salida
  (`ProgramRunner.startDelay`); la primera acción llega después.
- Los movimientos y giros se animan (`Player.MOVE_MS` / `TURN_MS`). La lógica cambia al instante; solo lo dibujado
  se desliza, y la cámara del mapa acompaña el movimiento.
- La lista de comandos se desplaza sola para mostrar el comando recién añadido o el que se está ejecutando, y
  también se puede arrastrar con click sostenido (además de rueda).
- Un nivel se desbloquea al completar el anterior (`Progress.isUnlocked`).
- Movimiento manual de prueba: flechas / WASD para moverse y E para interactuar, dentro de un nivel.

## Layout

Ventana de 1160×500: tareas (260 px) | mapa (410 px) | programación (410 px). Se ajusta en `Config.pde`.

## Pendiente / ideas

- Pantallas reales de Tutorial y Créditos (hoy `PlaceholderScreen`).
- Botón "Siguiente nivel" al ganar.
- `save.json` se escribe en `data/`; si exportas la app, verifica que esa ruta sea escribible.
