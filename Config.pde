// ============================================================
//  Config.pde — Constantes globales y layout de la ventana
// ============================================================

final int PANEL_MARGIN = 20;       // separación entre regiones y con los bordes de la ventana

// Tres regiones en fila: tareas | mapa | programación
final int TASK_W = 260;
final int MAP_W  = 410;
final int PROG_W = 410;

final int WINDOW_W = PANEL_MARGIN * 4 + TASK_W + MAP_W + PROG_W;
final int WINDOW_H = 500;

final int TILE_SIZE = 60;          // tamaño en pantalla de cada casilla (los assets son de 32 px)
final int PALETTE_BTN_SIZE = 50;   // tamaño de los botones de acción de la paleta
final int ROW_ICON_SIZE = 26;      // tamaño del ícono en cada fila de la lista de instrucciones

color bgColor = color(245);        // fondo único para toda la ventana

// Región de la lista de tareas y notas leídas (izquierda)
Rect taskArea = new Rect(PANEL_MARGIN, PANEL_MARGIN, TASK_W, WINDOW_H - PANEL_MARGIN * 2);

// Rectángulo donde se dibuja y recorta el mapa (centro)
Rect mapArea = new Rect(taskArea.x + TASK_W + PANEL_MARGIN, PANEL_MARGIN,
                        MAP_W, WINDOW_H - PANEL_MARGIN * 2);

// Panel de programación (derecha)
Rect progArea = new Rect(mapArea.x + MAP_W + PANEL_MARGIN, PANEL_MARGIN,
                         PROG_W, WINDOW_H - PANEL_MARGIN * 2);

// ----- Sistemas globales (se crean en setup()) -----
Assets assets;
LevelCatalog levels;
Progress progress;
