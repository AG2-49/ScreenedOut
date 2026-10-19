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
| | `Game_Objects` | `GameObject` y sus tipos: `Door`, `FloorButton`, `Computer`, `Note` y las tareas domésticas `Bed`, `Trash`, `Dishes`, `Feeder` (figuras de color hasta tener sprites). |
| | `Game_Tasks` | `Task`: texto + objeto con el que hay que interactuar. |
| | `Game_Player` | `Player`: movimiento, verificación de casilla destino, interacción y animación (estado lógico vs. visual). |
| **Program** | `Program_Actions` | Catálogo de acciones y `executeAction()`. |
| | `Program_Runner` | `Program` (la secuencia) y `ProgramRunner` (ejecución paso a paso). |
| | `Program_Panel` | Interfaz: paleta, lista con scroll, botones Limpiar/Correr. |
| **Save** | `Save_Progress` | `Progress`: niveles completados, guardar/cargar/reiniciar. |
| **Screen** | `Screen_Manager` | Clase base `Screen` y `goTo()`. |
| | `Screen_Home` / `_LevelSelect` / `_Tutorials` / `_Level` / `_Credits` / `_Placeholder` | Cada pantalla del juego. `LevelScreen` sirve tanto para niveles como para tutoriales (recibe el `LevelCatalog`). |
| **UI** | `UI_Widgets` | `Rect` y `UIButton` reutilizables. |
| | `UI_Clock` | `ClockIntro`: reloj digital (siete segmentos) que reemplaza al mapa al empezar el nivel. |
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
  tutorials/      index.json + un JSON por tutorial (mismo formato que un nivel; el campo opcional "hint" es la ayuda bajo el mapa)
  levels/         index.json (orden de niveles) + un JSON por nivel
                  (prueba_notas.json no está en index.json: nivel de pruebas con nota, tareas ocultas y puerta)
  save.json       se crea solo al completar el primer nivel
```

## Cómo se añade…

**Un nivel:** crea `data/levels/levelXX.json` y añade su id a `levels/index.json`.

```json
{
  "id": "level02",
  "name": "Nivel 2",
  "start": { "row": 0, "col": 0, "direction": "right" },
  "clock": { "from": "8:00", "to": "10:00", "text": "Solo un video más…" },
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
Caracteres del mapa: `.` suelo · `W` pared · `H` hueco · `D` puerta · `G` computadora (escritorio) · `B` botón · `N` nota · `C` cama · `T` basura · `L` lavaplatos · `M` comedero.
Coordenadas siempre `[fila, columna]`. `direction`: `up`, `right`, `down`, `left`.
- `clock` (opcional): reloj de introducción. `from`/`to` en 24 h (`"14:30"`); si `to` es menor que `from`
  cruza la medianoche. `text` (opcional) es una frase bajo el reloj. Sin `clock`, el nivel empieza directo en el mapa.
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
- **Reloj de introducción:** al abrir un nivel con `clock`, el reloj ocupa el lugar del mapa, avanza rápido
  de `from` a `to` (≈18 ms por minuto simulado, entre 1,8 y 4 s), se queda 0,9 s y se cierra solo. Un click,
  Enter o Espacio lo saltan. Mientras se ve, el juego no responde (salvo «Menú»). Solo se muestra al entrar
  al nivel, no en cada «Correr».
- Objetos bloqueados por notas: ver `Level.isLocked` (textos en `Game_Level`).
- Indicador de interacción: `Player.interactTarget`, `LevelScreen.updateHint`, `MapRenderer.drawHint`.
- Los avisos sobre el mapa (`Level.say`) caducan solos a los 3 s (`MESSAGE_MS`).
- Las notas no bloquean el paso; se leen interactuando con ellas desde una casilla vecina **o estando encima**.
- **Interactuar:** ver `Player.interact` (prioridad al objeto de enfrente).
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

- **Tutoriales:** `data/tutorials/` con su propio `index.json`; todos están disponibles desde el menú «Tutorial».
  Se juegan igual que un nivel y el campo `"hint"` se muestra sobre el borde inferior del mapa.
- **Al completar un nivel** aparece sobre el mapa el botón «Siguiente nivel» (o Enter). En el último nivel
  lleva a los créditos; en el último tutorial, al selector de niveles.
- **Créditos:** lista `CREDITS` en `Screen_Credits.pde`.

## Layout

Ventana de 1160×500: tareas (260 px) | mapa (410 px) | programación (410 px). Se ajusta en `Config.pde`.

## Pendiente / ideas

- `save.json` se escribe en `data/`; si exportas la app, verifica que esa ruta sea escribible.

---

## Audio (Engine_Audio.pde)

Requiere la librería **Minim** (Sketch ▸ Importar librería ▸ Gestionar librerías ▸ «Minim»).
Todo pasa por la variable global `audio`: `play("Nombre")`, `stop("Nombre")`, `walkStep(ms)`,
`stopWalk()`, `silence()`. Las ganancias por sonido (en dB) están en `SFX_GAIN`.
Tecla **M**: silenciar / activar.

**Pasos:** `Walk.mp3` suena en bucle mientras el jugador siga caminando. Cada paso exitoso renueva
un plazo (`walkStep`); girar, interactuar, chocar o caer lo cortan con un fundido (`stopWalk`);
si nadie lo renueva, se apaga solo. El `ProgramRunner` avisa si la siguiente acción también es
«Avanzar» para que el bucle no se corte entre casillas.

## Mapas

Caracteres: `.` suelo · `W` pared · `H` hueco · `D` puerta · `G` computadora · `B` botón · `N` nota ·
`C` cama · `S` suciedad · `P` plato sucio · `L` lavabo · `A` agua del gato · `^` escalera que sube · `v` escalera que baja.

**Pisos:** en lugar de `"map"` se usa `"floors": [{"name": "Piso 3", "map": [...]}, ...]` (de arriba hacia abajo).
La k-ésima `v` de un piso se empareja con la k-ésima `^` del piso siguiente; basta con pisar la escalera.
Posiciones en `links`, `notes` y tareas: `[fila, col]` (piso 0) o `[piso, fila, col]`. `start` admite `"floor"`.

**Tareas:** `{"target": [f,c]}` · `{"targets": [[f,c],...]}` · `{"all": "S"}` (todas las S; `"floor": n` las limita a un piso) ·
`{"reach": [f,c]}` (se cumple al pisar esa casilla). Con varios objetivos la lista muestra «(2/5)».

**Platos:** al recogerlos el jugador los lleva (se ve el plato junto a él); el lavabo los lava todos de una vez y
su tarea se cumple cuando ya no queda ninguno sin lavar.

## Resalte de objetos

Caja ámbar (`hintColor`) sobre el objeto en rango o bajo el mouse; en violeta (`linkColor`) los objetos
que ese objeto activa (la puerta de un botón). Para ligar un objeto a otro: `links` en el JSON.
