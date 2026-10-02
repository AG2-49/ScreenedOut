// ============================================================
//  Screen_Credits.pde — Créditos del equipo
//  Para añadir a alguien: una fila más en CREDITS = {rol, nombre}.
// ============================================================

class CreditsScreen extends Screen {
  final String[][] CREDITS = {
    {"Project leader", "Farid Melendez"},
    {"Level and art design", "Shadia Cure"},
    {"Programmer", "Adrián Góngora"},
    {"Archivist", "Sebastián Payares"}
  };

  UIButton backBtn = new UIButton(20, WINDOW_H - 60, 120, 40, "Volver");

  void draw() {
    pushStyle();
    textAlign(CENTER, CENTER);

    fill(30, 50, 100);
    textSize(32);
    text("Credits", WINDOW_W / 2.0, 70);

    float y = 150;
    for (int i = 0; i < CREDITS.length; i++) {
      fill(100, 120, 160);
      textSize(16);
      text(CREDITS[i][0], WINDOW_W / 2.0, y);
      fill(30, 50, 100);
      textSize(28);
      text(CREDITS[i][1], WINDOW_W / 2.0, y + 28);
      y += 68;
    }
    popStyle();

    backBtn.draw();
    cursor(backBtn.hover() ? HAND : ARROW);
  }

  void mousePressed() {
    if (backBtn.clicked()) goTo(new HomeScreen());
  }
}
// ============================================================
//  Screen_Credits.pde — Créditos del equipo
//  Para añadir a alguien: una fila más en CREDITS = {rol, nombre}.
// ============================================================


class BehindScreen extends Screen {
  final String TITULO = "Concepto del juego";

  final String CONCEPTO =
    "Un adolescente se pasa el tiempo en la computadora. Para dejar de " +
    "procrastinar, los papás le ponen cierto número de tareas a lo largo del día.";

  final String[] PUNTOS = {
    "La matriz se utiliza para cargar el mapa y limitar el rango de movimiento del jugador.",
    "Los arreglos se utilizan para aspectos variados como almacenar las instrucciones.",
    "Las cadenas permiten almacenar el texto de las interfaces del juego."
  };

  final String[] CODIGO = {
    "char terrainAt(int row, int col) {",
    "  return terrain[row][col];",
    "}",
    "",
    "boolean tryMove(Level level, int dx, int dy) {",
    "  if (fell) return false;",
    "",
    "  int nextRow = row + dy;",
    "  int nextCol = col + dx;",
    "  if (!level.inBounds(nextRow, nextCol)) return false;",
    "",
    "  setLookingFromDelta(dx, dy);",
    "",
    "  // Pared: choca (solo gira hacia ella)",
    "  if (level.terrainAt(nextRow, nextCol) == 'W') {",
    "    startAnim(TURN_MS);",
    "    return false;",
    "  }",
    "",
    "  // Objeto sólido (p. ej. una puerta cerrada)",
    "  GameObject obj = level.objectAt(nextRow, nextCol);",
    "  if (obj != null && obj.blocksMovement()) {",
    "    startAnim(TURN_MS);",
    "    return false;",
    "  }",
    "",
    "  row = nextRow;",
    "  col = nextCol;",
    "  startAnim(MOVE_MS);",
    "",
    "  // Hueco: cae",
    "  if (level.terrainAt(row, col) == 'H') {",
    "    fell = true;",
    "    onFall();",
    "  }",
    "  return true;",
    "}"
  };

  UIButton backBtn = new UIButton(20, WINDOW_H - 60, 120, 40, "Volver");
  PFont codeFont;
  float scrollY = 0;
  boolean arrastrando = false;

  // Zona del panel de código (la usan draw() y mousePressed())
  final float MARGEN = 40;
  final float COL_IZQ_W = WINDOW_W * 0.38;
  final float PANEL_X = MARGEN + COL_IZQ_W + 30;
  final float PANEL_Y = 40;
  final float PANEL_W = WINDOW_W - PANEL_X - MARGEN;
  final float PANEL_H = WINDOW_H - PANEL_Y - 80;
  final float LINEA_H = 18;
  final float PAD = 12;

  BehindScreen() {
    codeFont = createFont("Monospaced", 13);
  }

  void draw() {
    pushStyle();

    // ---- Columna izquierda: concepto ----
    textAlign(LEFT, TOP);
    fill(30, 50, 100);
    textSize(28);
    text(TITULO, MARGEN, PANEL_Y);

    textSize(16);
    textLeading(22);
    float y = PANEL_Y + 50;
    text(CONCEPTO, MARGEN, y, COL_IZQ_W, 200);
    y += countLines(CONCEPTO, COL_IZQ_W) * 22 + 16;

    for (int i = 0; i < PUNTOS.length; i++) {
      fill(100, 120, 160);
      text("•", MARGEN, y);
      fill(30, 50, 100);
      text(PUNTOS[i], MARGEN + 20, y, COL_IZQ_W - 20, 200);
      y += countLines(PUNTOS[i], COL_IZQ_W - 20) * 22 + 10;
    }

    // ---- Panel de código ----
    noStroke();
    fill(30, 34, 46);
    rect(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, 8);

    float contenidoH = CODIGO.length * LINEA_H + PAD * 2;
    float maxScroll = max(0, contenidoH - PANEL_H);

    // Arrastrar con el mouse
    if (arrastrando && mousePressed) {
      scrollY += pmouseY - mouseY;
    } else {
      arrastrando = false;
    }

    // Flechas del teclado
    if (keyPressed && key == CODED) {
      if (keyCode == DOWN) scrollY += 6;
      if (keyCode == UP)   scrollY -= 6;
    }

    scrollY = constrain(scrollY, 0, maxScroll);

    // Recorta para que el código no se salga del panel
    clip(PANEL_X, PANEL_Y, PANEL_W, PANEL_H);
    textFont(codeFont);
    textSize(13);
    textAlign(LEFT, TOP);
    for (int i = 0; i < CODIGO.length; i++) {
      float ly = PANEL_Y + PAD + i * LINEA_H - scrollY;
      if (ly < PANEL_Y - LINEA_H || ly > PANEL_Y + PANEL_H) continue;

      String linea = CODIGO[i];
      if (linea.trim().startsWith("//")) fill(120, 140, 120);   // comentarios
      else fill(220, 225, 235);
      text(linea, PANEL_X + PAD, ly);
    }
    noClip();

    // Barra de scroll
    if (maxScroll > 0) {
      float barH = PANEL_H * (PANEL_H / contenidoH);
      float barY = PANEL_Y + (scrollY / maxScroll) * (PANEL_H - barH);
      fill(255, 255, 255, 70);
      rect(PANEL_X + PANEL_W - 8, barY, 4, barH, 2);
    }

    popStyle();

    backBtn.draw();
    cursor(backBtn.hover() ? HAND : ARROW);
  }

  // Cuenta cuántas líneas ocupa un texto al ajustarlo a un ancho dado
  // (debe llamarse con el textSize ya configurado)
  int countLines(String s, float w) {
    String[] palabras = split(s, ' ');
    String linea = "";
    int lineas = 1;
    for (String palabra : palabras) {
      String prueba = linea.equals("") ? palabra : linea + " " + palabra;
      if (textWidth(prueba) > w && !linea.equals("")) {
        lineas++;
        linea = palabra;
      } else {
        linea = prueba;
      }
    }
    return lineas;
  }

  void mouseWheel(float delta) {
    scrollY += delta * 20;
  }

  void mousePressed() {
    if (backBtn.clicked()) {
      goTo(new HomeScreen());
      return;
    }
    // Empieza el arrastre solo si el clic fue dentro del panel
    arrastrando = mouseX > PANEL_X && mouseX < PANEL_X + PANEL_W
               && mouseY > PANEL_Y && mouseY < PANEL_Y + PANEL_H;
  }
}
