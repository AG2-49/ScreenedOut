# Screened Out — estructura del proyecto

Juego de programación por bloques hecho en Processing: el jugador arma una secuencia de acciones
(avanzar, girar, interactuar) y pulsa «Correr» para que su personaje cumpla las tareas de cada nivel.

> **Limitación de Processing:** los `.pde` deben estar todos en la carpeta raíz del sketch
> (se concatenan en una sola clase), así que **no se pueden agrupar en subcarpetas**.
> Los módulos se agrupan por **prefijo de nombre**: el IDE ordena las pestañas
> alfabéticamente, por lo que cada grupo queda junto. Las carpetas reales sí funcionan
> dentro de `data/` (assets, sonidos, niveles, guardado).

## Requisitos

- **Processing** (el sketch fija el tamaño de la ventana en `settings()`, así que necesita Processing 3 o 4).
- Librería **Minim** (Sketch ▸ Importar librería ▸ Gestionar librerías ▸ «Minim»).
- Los archivos de sonido en `data/Assets/sounds/` (ver [Audio](#audio)). Si faltan, el juego **sigue
  funcionando**: solo imprime un aviso en la consola por cada archivo que no encuentra.

## Módulos (pestañas)

| Prefijo | Archivo | Responsabilidad |
|---|---|---|
| — | `ScreenedOut` | Archivo principal: `settings`/`setup`/`draw`, reparto de eventos a la pantalla activa, tecla **M** (silencio) y aviso de sonido desactivado. Nada más. |
| — | `Config` | Constantes globales, paleta `COL_*`, layout (`taskArea`, `mapArea`, `progArea`, `TILE_SIZE`), ajustes del personaje (`PLAYER_*`) y sistemas globales (`assets`, `audio`, `levels`, `tutorials`, `progress`). |
| — | `Room_Scene` | Cuarto de fondo del menú (monitor, lámpara, planta) y `RoomCam`, la cámara que se acerca a la pantalla del monitor. Lo usan todas las pantallas de menú. |
| **Engine** | `Engine_Assets` | Carga y prepara texturas (escala, rotaciones, tablas por máscara) e íconos de acciones. |
| | `Engine_Tiles` | `MapRenderer`: convierte un `Level` en imagen (autotiling + objetos). Las paredes se conectan a las puertas como si fueran pared (`neighborJoins`). |
| | `Engine_Camera` | `Camera`: recorte, arrastre (solo si hay desborde), seguimiento y sombras. |
| | `Engine_Audio` | `Audio` (Minim): música, efectos y bucle de pasos. |
| **Game** | `Game_Level` | `Level` (pisos + objetos + inicio + tareas + notas), carga desde JSON y `LevelCatalog`. |
| | `Game_Objects` | `GameObject` y sus tipos: `Door`, `FloorButton`, `Computer`, `Note`, `Bed`, `Grime`, `DishDirty`, `Sink`, `CatBowl`, `Stairs`. |
| | `Game_Tasks` | `Task`: texto + objetos con los que hay que interactuar (o casilla a la que hay que llegar). |
| | `Game_Player` | `Player`: movimiento, verificación de casilla destino, interacción y animación (estado lógico vs. visual). |
| **Program** | `Program_Actions` | Catálogo de acciones y `executeAction()`. |
| | `Program_Runner` | `Program` (la secuencia) y `ProgramRunner` (ejecución paso a paso). |
| | `Program_Panel` | Interfaz: paleta, lista con scroll, botones «Limpiar todo» y «Correr». |
| **Save** | `Save_Progress` | `Progress`: niveles completados, guardar/cargar/reiniciar. |
| **Screen** | `Screen_Manager` | Clase base `Screen` y `goTo()` (corta los efectos y ajusta el volumen de la música al cambiar de pantalla). |
| | `Screen_Home` / `_LevelSelect` / `_Tutorials` / `_Level` / `_Credits` / `_Placeholder` | Cada pantalla del juego. `LevelScreen` sirve tanto para niveles como para tutoriales (recibe el `LevelCatalog`). |
| **UI** | `UI_Theme` | Fuentes (`uiFont` pixel y `handFont` manuscrita) y dibujo común: `drawFrame`, `drawPanelBox`. La paleta (`COL_*`) está en `Config`. |
| | `UI_Widgets` | `Rect` y `UIButton` reutilizables (estilos `primary()` ámbar, `danger()` rosa y contorno cian por defecto) y `wrapText`. |
| | `UI_Transition` | Funciones de suavizado (`easeOutCubic`, `easeInCubic`) y `drawGrowRect`, la ficha que crece hasta cubrir la ventana al elegir un nivel o tutorial. |
| | `UI_Clock` | `ClockIntro`: reloj digital (siete segmentos) que reemplaza al mapa al empezar el nivel. |
| | `UI_NoteViewer` | Nota a pantalla completa: reemplaza al mapa y pausa el juego hasta cerrarla. |
| | `UI_TaskPanel` | Región izquierda: tareas visibles y texto de las notas leídas (paleta de la nota). |
| | `UI_FloorSelector` | Lista desplegable para mirar otro piso en niveles con varios. |

Flujo de dependencias: `Screen_*` → (`Game_*`, `Engine_*`, `Program_*`, `Save_*`) → `UI_*`/`Config`.
Los módulos de motor y de juego **no conocen** las pantallas.

## Carpeta `data/`

```
data/
  Assets/tiles/    texturas del mapa (Floor, Wall1-4, Hole1-6, Door, Computer, Note, botones,
                   Bed/BedMess, Grime1-4, DishDirty, Sink, WaterClean/WaterDirty, StairUp/StairDown)
                   Wall1-4 son sprites SIN fondo (solo la banda gris): se dibujan sobre Floor.
  Assets/ui/       íconos de acciones, de 24×24 (step, action, clockwise, counterclockwise)
  Assets/skin/     Face.png: la cara del personaje
  Assets/sounds/   música y efectos (ver «Audio»)
  tutorials/       index.json + un JSON por tutorial (mismo formato que un nivel; el campo opcional "hint" es la ayuda bajo el mapa)
  levels/          index.json (orden de niveles) + un JSON por nivel
                   (prueba_notas.json no está en index.json: nivel de pruebas con nota, tareas ocultas y puerta)
  save.json        progreso: {"completed": [ids de niveles]}
  PressStart2P-Regular.ttf        letra pixel de menús y botones
  PatrickHand-Regular.ttf         letra manuscrita de tareas y notas (licencia: OFL-PatrickHand.txt)
```

> `Assets/tiles/elpepe.png` no lo carga ningún módulo; es un sobrante que se puede borrar.

## Cómo se añade…

**Un nivel:** crea `data/levels/levelXX.json` y añade su id a `levels/index.json`.
**Un tutorial:** igual, en `data/tutorials/` y su `index.json`.

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

**Caracteres del mapa:**

| Carácter | Significado | Carácter | Significado |
|---|---|---|---|
| `.` | suelo | `C` | cama |
| `W` | pared | `S` | suciedad |
| `H` | hueco | `P` | plato sucio |
| `D` | puerta | `L` | lavabo |
| `G` | computadora | `A` | agua del gato (`CatBowl`) |
| `B` | botón | `^` | escalera que sube |
| `N` | nota | `v` | escalera que baja |

Coordenadas siempre `[fila, columna]`. `direction`: `up`, `right`, `down`, `left`.

**Campos del JSON:**

- `clock` (opcional): reloj de introducción. `from`/`to` en 24 h (`"14:30"`); si `to` es menor que `from`
  cruza la medianoche. `text` (opcional) es una frase bajo el reloj. Sin `clock`, el nivel empieza directo en el mapa.
- `hint` (opcional, pensado para tutoriales): ayuda que se muestra sobre el borde inferior del mapa.
- `links`: el objeto `from` activa al objeto `to` (botón → puerta). Una puerta ligada **no** se abre con interactuar.
- `tasks`: tareas visibles desde el inicio (formatos abajo).
- `notes`: cada nota debe estar en el mapa con `N` en la posición `at`. Al leerla (interactuar) se abre su `text`
  a pantalla completa sobre el mapa; además pasa a la lista de notas leídas y sus `tasks` se añaden a la lista de tareas.
- Una tarea o nota que apunte a una posición sin objeto se ignora con un aviso en la consola.

**Pisos:** en lugar de `"map"` se usa `"floors": [{"name": "Piso 3", "map": [...]}, ...]` (de arriba hacia abajo).
La k-ésima `v` de un piso se empareja con la k-ésima `^` del piso siguiente; basta con pisar la escalera.
Posiciones en `links`, `notes` y tareas: `[fila, col]` (piso 0) o `[piso, fila, col]`. `start` admite `"floor"`.

**Tareas:** `{"target": [f,c]}` · `{"targets": [[f,c],...]}` · `{"all": "S"}` (todas las S; `"floor": n` las limita a un piso) ·
`{"reach": [f,c]}` (se cumple al pisar esa casilla). Con varios objetivos la lista muestra «(2/5)».

**Orientación (computadora y escaleras):** `"orientation": [{"at": [piso, fila, col], "direction": "up|right|down|left"}]`.

- **Computadora:** `direction` es el lado del teclado (donde se sienta el jugador). Si `start` no trae `row`/`col`,
  el jugador arranca en la casilla de enfrente, mirándola. (`start` con `row`, `col` y `direction` sigue funcionando.)
- **Escalera:** `direction` es hacia dónde queda mirando el jugador al SALIR por esa escalera. El pozo del sprite
  queda a su espalda; se entra caminando hacia el pozo. Sin orientación, se deduce de las paredes.
  Ejemplo: la `v` de arriba sale mirando `up` y su `^` pareja, abajo, sale mirando `down`.

**Un tipo de objeto:** clase que herede de `GameObject` (`Game_Objects`), un `case` en
`Level.createObject()` y su textura en `Assets`.

**Una acción programable:** constante + etiqueta + `case` en `Program_Actions`, e ícono en `Assets`.

**Una pantalla:** clase que herede de `Screen` y `goTo(new MiPantalla())`.

**Un sonido:** el archivo en `data/Assets/sounds/` y su nombre (y ganancia) en `SFX_FILES` / `SFX_GAIN` de `Engine_Audio`;
luego `audio.play("Nombre")` donde corresponda.

## Reglas de juego actuales (fáciles de cambiar)

**Objetos y avance**
- Una puerta cerrada bloquea el paso; se abre con *Interactuar* (si no está ligada a un botón).
- **El nivel se completa al leer todas las notas y cumplir todas las tareas** (`Level.allGoalsMet`).
  Un nivel sin tareas ni notas no se completa solo.
- Un nivel se desbloquea al completar el anterior (`Progress.isUnlocked`).
- **Al completar un nivel** aparece sobre el mapa el botón «Siguiente nivel» (o Enter). En el último nivel
  lleva a los créditos; en el último tutorial, al selector de niveles.
- Objetos bloqueados por notas: ver `Level.isLocked` (textos en `Game_Level`).
- Las notas no bloquean el paso; se leen interactuando con ellas desde una casilla vecina **o estando encima**.
- **Platos:** al recogerlos el jugador los lleva (se ve el plato junto a él); el lavabo los lava todos de una vez y
  su tarea se cumple cuando ya no queda ninguno sin lavar.
- **Interactuar:** ver `Player.interact` (prioridad al objeto de enfrente).
- Indicador de interacción: `Player.interactTarget`, `LevelScreen.updateHint`, `MapRenderer.drawHighlight`.
- Los avisos sobre el mapa (`Level.say`) caducan solos a los 3 s (`MESSAGE_MS`).

**Ejecución del programa**
- Al pulsar «Correr» el nivel se reinicia y el jugador se ve primero en su casilla de salida
  (`ProgramRunner.startDelay`); la primera acción llega después. Mientras corre, el botón dice «Ejecutando...».
- Los movimientos y giros se animan (`Player.MOVE_MS` / `TURN_MS`). La lógica cambia al instante; solo lo dibujado
  se desliza, y la cámara del mapa acompaña el movimiento.
- La lista de comandos se desplaza sola para mostrar el comando recién añadido o el que se está ejecutando, y
  también se puede arrastrar con click sostenido (además de rueda).
- **Reloj de introducción:** al abrir un nivel con `clock`, el reloj ocupa el lugar del mapa, avanza rápido
  de `from` a `to` (≈18 ms por minuto simulado, entre 1,8 y 4 s), se queda 0,9 s y se cierra solo. Un click,
  Enter o Espacio lo saltan. Mientras se ve, el juego no responde (salvo «Menú»). Solo se muestra al entrar
  al nivel, no en cada «Correr».
- **Nota abierta = juego en pausa:** el programa deja de avanzar (`ProgramRunner` no acumula tiempo),
  no se edita la secuencia ni se mueve el jugador, y el nivel no puede completarse. Solo responden
  «Cerrar nota» (también Enter/Espacio), el botón «Menú» y los desplazamientos. Al cerrar, la ejecución continúa.

**Transiciones** (`UI_Transition`, `Screen_Level`)
- Al elegir un nivel o tutorial, la ficha pulsada crece hasta cubrir la ventana.
- Dentro de `LevelScreen` los paneles (tareas, mapa, programa) entran y salen deslizándose, escalonados.
  Un click salta la animación. «Siguiente nivel» usa una entrada más corta (`quick()`).

**Pantallas de menú**
- **Tutoriales:** `data/tutorials/` con su propio `index.json`; todos están disponibles desde el menú «Tutorial».
  Se juegan igual que un nivel y el campo `"hint"` se muestra sobre el borde inferior del mapa.
- **Créditos:** lista `CREDITS` en `Screen_Credits.pde`.

**Teclas**
- **M**: silenciar / activar el sonido (en cualquier pantalla).
- **T** (dentro de un nivel): activa/desactiva el *movimiento manual de prueba* (`FreeMove`, apagado por defecto).
  Con él activo: flechas / WASD para moverse y **E** para interactuar. Es una herramienta de depuración.
- Enter / Espacio: saltan el reloj, cierran una nota; Enter avanza a «Siguiente nivel».

## Panel de acciones

Las filas se resaltan al pasar el mouse; un clic las selecciona (otro clic en la misma, o en vacío, la suelta).
Al moverla con ▲/▼ la selección la acompaña. Se limpia al borrar, al «Limpiar todo» y al «Correr».

## Selector de pisos (`UI_FloorSelector.pde`)

En niveles con varios pisos aparece arriba a la izquierda del mapa una lista desplegable. Cambia solo el piso que
SE VE (`LevelScreen.viewFloor`), no el del personaje; la fila del piso donde está el personaje lleva su carita.
Al mirar otro piso el mapa se oscurece un poco y se indica «Personaje: Piso N». Si el personaje cambia de piso
(escaleras), la vista lo sigue.

## Resalte de objetos

Caja ámbar (`hintColor`) sobre el objeto en rango o bajo el mouse; en cian (`linkColor`) los objetos
que ese objeto activa (la puerta de un botón). Para ligar un objeto a otro: `links` en el JSON.

## Personaje

Cabeza = círculo con `data/Assets/skin/Face.png` + flecha en forma de «techo» (^) que gira a su alrededor
(`Player.draw`). Todo se ajusta con las constantes `PLAYER_*` de `Config.pde`: tamaño del círculo, de la cara, medidas
y grosor de la flecha, colores, y si la cara gira con el personaje (`PLAYER_FACE_ROTATES`).

## Estilo visual

> **Texto de los botones:** `UIButton.draw` centra verticalmente la letra pixel por la altura de las mayúsculas
> (`textAscent`) y no con `textAlign(CENTER)`, porque con Press Start 2P este último la deja baja y aplastada.
> Si cambias la fuente de los botones, revisa ese cálculo.

Toda la interfaz usa la paleta del menú, definida en `Config.pde`: `COL_CYAN #22e6ff`, `COL_PINK #ff7aa8`,
`COL_AMBER #ffb55a`, `COL_NAVY #1a1d3d`, `COL_WHITE #ffffff`, más los tonos derivados (`COL_SCREEN`, `COL_SLATE`,
`COL_TEXT_SOFT`...). No pongas colores sueltos en las pantallas: usa estas constantes.
- Las regiones llevan fondo `COL_SCREEN` y borde cian tenue (`drawPanelBox` / `drawFrame`).
- Cian = lo digital y los bordes; ámbar = selección, hover y acción principal; rosa = acciones destructivas.
- El verde (`COL_GREEN`) solo marca lo «hecho» (casillas cumplidas, nivel completado).
- Los tiles del mapa y el papel de `TaskPanel` / `NoteViewer` conservan su paleta propia (la de los assets).
- Los iconos de acción (`Assets/ui/`) son de 24×24: se ven exactos con `PALETTE_BTN_SIZE` 48 (×2) y `ROW_ICON_SIZE` 24 (×1).

### Tipografías

- `PressStart2P-Regular.ttf`: letra pixel de menús y botones (`uiFont`).
- `PatrickHand-Regular.ttf` (Patrick Hand, SIL OFL 1.1, licencia en `data/OFL-PatrickHand.txt`): letra manuscrita de
  tareas y notas (`handFont`). Se cambia con `HAND_FONT_FILE` en `UI_Theme.pde`.

## Layout

Ventana de 1160×500: tareas (260 px) | mapa (410 px) | programación (410 px), con 20 px de margen. Se ajusta en `Config.pde`.

## Audio

Todo pasa por la variable global `audio` (`Engine_Audio.pde`): `play("Nombre")`, `stop("Nombre")`, `walkStep(ms)`,
`stopWalk()`, `silence()`. Las ganancias por sonido (en dB) están en `SFX_GAIN`; el volumen de la música en menús y en
nivel, en `MUSIC_GAIN_MENU` / `MUSIC_GAIN_LEVEL`. Tecla **M**: silenciar / activar.

Archivos esperados en `data/Assets/sounds/`:

- Efectos (`.mp3`): `BedDoing`, `ButtonClick`, `ClockTick`, `ComputerOFF`, `DishesCleaning`, `DishesPicking`,
  `DoorOpening`, `LetterPicking`, `Sweeping`, `WaterPouring`.
- Pasos: `Walk.mp3` (bucle).
- Música: `ThemeMain.wav` (~34 MB; Minim la lee en streaming). Suena en bucle y baja de volumen dentro de un nivel.

Si un archivo no está, se imprime un aviso en consola y ese sonido simplemente no suena; el resto del juego no se ve afectado.

**Pasos:** `Walk.mp3` suena en bucle mientras el jugador siga caminando. Cada paso exitoso renueva
un plazo (`walkStep`); girar, interactuar, chocar o caer lo cortan con un fundido (`stopWalk`);
si nadie lo renueva, se apaga solo. El `ProgramRunner` avisa si la siguiente acción también es
«Avanzar» para que el bucle no se corte entre casillas.

Al cambiar de pantalla (`goTo`) y al reiniciar un nivel se cortan todos los efectos (la música sigue).

## Pendiente / ideas

- `save.json` se escribe en `data/`; si exportas la app, verifica que esa ruta sea escribible.
- `Assets/tiles/elpepe.png` sin uso (ver `data/`).
