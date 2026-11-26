// ============================================================
//  Config.pde — Constantes globales y layout de la ventana
// ============================================================

// ----- Paleta del juego (la misma del menú principal) -----
final color COL_CYAN  = #22e6ff;   // títulos, líneas, lo digital
final color COL_PINK  = #ff7aa8;   // acciones destructivas
final color COL_AMBER = #ffb55a;   // selección, hover, acción principal
final color COL_NAVY  = #1a1d3d;   // fondo (la pared del cuarto)
final color COL_WHITE = #ffffff;   // texto resaltado
// Tonos derivados (ya usados por el menú)
final color COL_SCREEN     = color(13, 26, 46);      // fondo de los paneles
final color COL_WELL       = color(9, 19, 36);       // fondo hundido de la lista
final color COL_SLATE      = color(22, 38, 63);      // filas, casillas bloqueadas
final color COL_SLATE_EDGE = color(45, 74, 99);      // borde apagado
final color COL_MUTED      = color(74, 106, 133);    // texto apagado
final color COL_TEXT_SOFT  = color(143, 232, 245);   // texto claro
final color COL_AMBER_LIGHT = color(255, 212, 160);  // hover del ámbar
final color COL_AMBER_EDGE  = color(255, 224, 176);  // borde del ámbar
final color COL_PINK_LIGHT  = color(255, 190, 215);  // hover del rosa
final color COL_GREEN      = color(63, 166, 107);    // solo para lo «hecho»
final color COL_GREEN_SOFT = color(160, 230, 190);

final int PANEL_MARGIN = 20;       // separación entre regiones y con los bordes de la ventana

// Tres regiones en fila: tareas | mapa | programación
final int TASK_W = 260;
final int MAP_W  = 410;
final int PROG_W = 410;

final int WINDOW_W = PANEL_MARGIN * 4 + TASK_W + MAP_W + PROG_W;
final int WINDOW_H = 500;

final int TILE_SIZE = 60;          // tamaño en pantalla de cada casilla (los assets son de 32 px)
final int PALETTE_BTN_SIZE = 48;   // tamaño de los botones de acción de la paleta
final int ROW_ICON_SIZE = 24;      // tamaño del ícono en cada fila de la lista de instrucciones

color bgColor = COL_NAVY;          // fondo único para toda la ventana
color hintColor = COL_AMBER;       // caja de la casilla en rango de interacción o bajo el mouse
color linkColor = COL_CYAN;        // caja de lo que ACTIVA un objeto (la puerta de un botón...)

// Región de la lista de tareas y notas leídas (izquierda)
Rect taskArea = new Rect(PANEL_MARGIN, PANEL_MARGIN, TASK_W, WINDOW_H - PANEL_MARGIN * 2);

// Rectángulo donde se dibuja y recorta el mapa (centro)
Rect mapArea = new Rect(taskArea.x + TASK_W + PANEL_MARGIN, PANEL_MARGIN,
                        MAP_W, WINDOW_H - PANEL_MARGIN * 2);

// Panel de programación (derecha)
Rect progArea = new Rect(mapArea.x + MAP_W + PANEL_MARGIN, PANEL_MARGIN,
                         PROG_W, WINDOW_H - PANEL_MARGIN * 2);

// ----- Sistemas globales (se crean en setup()) -----
boolean FreeMove = false;
Assets assets;
Audio audio;               // música y efectos (Engine_Audio.pde)
LevelCatalog levels;       // niveles del juego (data/levels)
LevelCatalog tutorials;    // niveles de práctica (data/tutorials)
Progress progress;
// ----- Aspecto del personaje (Player.draw). Las medidas de la flecha van en múltiplos del radio -----
final float PLAYER_RADIUS_K = 0.35;     // radio de la cabeza, en fracción de casilla (0.26 ≈ 16 px)
final float PLAYER_FACE_FILL = 0.9;    // tamaño de la cara dentro del círculo (1 = toca el borde)
final float PLAYER_RING_WEIGHT = 2.5;   // grosor del borde del círculo
final float PLAYER_ARROW_HALF_W = 0.7;  // semiancho de la flecha (1.5 = más ancha que la cara)
final float PLAYER_ARROW_HEIGHT = 0.3; // alto de la flecha
final float PLAYER_ARROW_GAP = 0.1;    // separación entre la flecha y el círculo
final float PLAYER_ARROW_WEIGHT = 3;    // grosor de la línea de la flecha
final boolean PLAYER_FACE_ROTATES = false;  // ¿la cara gira con el personaje? (la flecha siempre gira)
color playerInk = COL_CYAN;             // color del borde y la flecha
color playerInkFell = color(110);       // ... al caer en un hueco
