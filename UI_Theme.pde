// ============================================================
//  UI_Theme.pde — Tema visual compartido
//  La paleta (COL_*) vive en Config.pde. Aquí están la fuente pixel única y las piezas de
//  dibujo comunes a todas las pantallas, para que el juego se vea igual que el menú.
// ============================================================

final float UI_BTN_RADIUS = 8;    // esquinas de botones (igual que los botones del menú)
final float UI_ROW_RADIUS = 6;    // esquinas de filas y selector de pisos (más bajas que un botón)
final float UI_BTN_TEXT   = 10;   // tamaño de la letra pixel en botones

final String HAND_FONT_FILE = "PatrickHand-Regular.ttf";   // letra «a mano» de notas y tareas (cambiar aquí para probar otra)

PFont uiFont;                     // PressStart2P, cargada una sola vez
PFont handFont;                   // letra manuscrita del papel (TaskPanel, NoteViewer)

void initTheme() {
  uiFont = createFont("PressStart2P-Regular.ttf", 32);
  handFont = createFont(HAND_FONT_FILE, 32);
}

// Borde cian tenue de una región (mapa, paneles, reloj).
void drawFrame(Rect r) {
  pushStyle();
  noFill();
  stroke(COL_CYAN, 130);
  strokeWeight(2);
  rect(r.x, r.y, r.w, r.h);
  popStyle();
}

// Panel: fondo oscuro con borde cian tenue.
void drawPanelBox(Rect r, color fillC) {
  pushStyle();
  fill(fillC);
  noStroke();
  rect(r.x, r.y, r.w, r.h);
  popStyle();
  drawFrame(r);
}
