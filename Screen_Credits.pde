// ============================================================
//  Screen_Credits.pde — Créditos del equipo y "Detrás del código"
//  Para añadir a alguien: una fila más en CREDITS = {rol, nombre}.
// ============================================================

class CreditsScreen extends Screen {
  final String[][] CREDITS = {
    {"Project leader", "Farid Melendez"},
    {"Level and art design", "Shadia Cure"},
    {"Programmer", "Adrián Góngora"},
    {"Archivist", "Sebastián Payares"}
  };

  // un color por persona (si agregan más gente, los colores se repiten)
  final int[] NAME_COLORS = {
    COL_AMBER,    // naranja
    COL_PINK,   // rosa
    color(63, 224, 122),    // verde
    color(176, 140, 255),   // morado
    COL_CYAN,    // cian
    color(246, 240, 120)    // amarillo
  };

  RoomCam cam = new RoomCam();
  PFont pixelFont;
  int born;
  final float ENTRY_H = 30;                      // alto de cada bloque rol + nombre
  final float VIS_TOP = 52, VIS_BOTTOM = 120;    // zona visible de los créditos

  CreditsScreen() {
    pixelFont = uiFont;
    born = millis();
    cam.set(1);
  }

  float mx() { return (cam.invX(mouseX) - roomOX()) / roomS(); }
  float my() { return cam.invY(mouseY) / roomS(); }

  boolean overBack()   { return mx() > 122 && mx() < 172 && my() > 123 && my() < 136; }
  boolean overBehind() { return mx() > 172 && mx() < 262 && my() > 123 && my() < 136; }

  void draw() {
    textSize(g.textSize);
    PFont normalFont = g.textFont;
    float normalSize = g.textSize;

    float s = roomS(), ox = roomOX();
    cam.set(1);
    float al = constrain((millis() - born) / 400.0, 0, 1);
    int a = (int) (255 * al);
    boolean hBack = overBack(), hBehind = overBehind();

    pushStyle();
    drawRoom(cam);

    // línea bajo el título
    cam.begin();
    stroke(COL_CYAN, 100 * al);
    strokeWeight(s);
    line(ox + 124 * s, 45 * s, ox + 256 * s, 45 * s);
    cam.end();

    noStroke();
    textFont(pixelFont);

    textAlign(CENTER, CENTER);
    textSize(8 * s * cam.cz);
    fill(COL_CYAN, a);
    text("CRÉDITOS", cam.x(ox + 190 * s), cam.y(36 * s));

    // créditos que suben solos (se recortan a la pantalla del monitor)
    float period = (VIS_BOTTOM - VIS_TOP) + CREDITS.length * ENTRY_H + 10;
    float off = ((millis() - born) / 1000.0 * 12) % period;     // 12 = velocidad
    float y0 = VIS_BOTTOM - off;

    clip(cam.x(ox + 116 * s), cam.y(VIS_TOP * s), 152 * s * cam.cz, (VIS_BOTTOM - VIS_TOP) * s * cam.cz);
    for (int i = 0; i < CREDITS.length; i++) {
      float ry = y0 + i * ENTRY_H;
      int c = NAME_COLORS[i % NAME_COLORS.length];

      textSize(5 * s * cam.cz);
      fill(red(c), green(c), blue(c), a * 0.6);
      text(CREDITS[i][0], cam.x(ox + 190 * s), cam.y(ry * s));

      String nm = CREDITS[i][1];
      textSize(min(7, 140.0 / max(1, nm.length())) * s * cam.cz);
      fill(red(c), green(c), blue(c), a);
      text(nm, cam.x(ox + 190 * s), cam.y((ry + 10) * s));
    }
    noClip();

    // botones
    textSize(5 * s * cam.cz);
    textAlign(LEFT, CENTER);
    if (hBack) fill(255, a); else fill(COL_TEXT_SOFT, a);
    text("< Volver", cam.x(ox + 126 * s), cam.y(130 * s));

    textAlign(RIGHT, CENTER);
    if (hBehind) fill(255, a); else fill(COL_AMBER, a);
    text("Detrás del código", cam.x(ox + 258 * s), cam.y(130 * s));

    popStyle();
    textFont(normalFont, normalSize);
    cursor((hBack || hBehind) ? HAND : ARROW);
  }

  void mousePressed() {
    if (overBack()) goTo(new HomeScreen(true));       // zoom hacia atrás al cuarto
    else if (overBehind()) goTo(new BehindScreen());
  }
}


// ------------------------------------------------------------
//  Piezas comunes de "Detrás del código" (pantalla de monitor grande)
// ------------------------------------------------------------
float scrX() { return 44; }
float scrY() { return 38; }
float scrW() { return width - 88; }
float scrH() { return height - 76; }

void drawMonitorPanel() {
  background(COL_NAVY);
  stroke(90, 90, 80);
  strokeWeight(3);
  fill(217, 210, 192);
  rect(30, 24, width - 60, height - 48, 16);
  noStroke();
  fill(13, 26, 46);
  rect(scrX(), scrY(), scrW(), scrH(), 8);
}

// Dibuja un texto que funciona como botón y dice si el mouse está encima.
// (se llama con la letra y el tamaño ya configurados)
boolean pixelLink(String t, float x, float y, int align, int base, int hov) {
  textAlign(align, CENTER);
  float w = textWidth(t);
  float x0 = (align == LEFT) ? x : (align == RIGHT ? x - w : x - w / 2);
  float h = g.textSize;
  boolean over = mouseX > x0 - 6 && mouseX < x0 + w + 6 && mouseY > y - h / 2 - 6 && mouseY < y + h / 2 + 6;
  fill(over ? hov : base);
  text(t, x, y);
  return over;
}

// Cuenta cuántas líneas ocupa un texto al ajustarlo a un ancho dado
// (debe llamarse con la letra y el tamaño ya configurados)
int countLinesFor(String s, float w) {
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


// ------------------------------------------------------------
//  Pantalla principal: de qué trata el juego + un botón por tema
// ------------------------------------------------------------
class BehindScreen extends Screen {
  final String TITULO = "CONCEPTO DEL JUEGO";

  final String CONCEPTO =
    "Un adolescente se pasa el tiempo en la computadora. Para dejar de " +
    "procrastinar, los papás le ponen cierto número de tareas a lo largo del día.";

  final String HINT = "Elige un tema para ver cómo lo usamos en el código:";

  final String[] TEMAS = { "Arreglos", "Matrices", "Cadenas", "Funciones", "Subrutinas" };

  PFont pixelFont, bodyFont;
  int hoverTema = -1;
  boolean hoverBack = false;

  BehindScreen() {
    pixelFont = uiFont;
    bodyFont  = createFont("SansSerif", 18);
  }

  float btnX() { return scrX() + scrW() * 0.52; }
  float btnW() { return scrW() * 0.48 - 30; }
  float btnH() { return 40; }
  float btnY(int i) { return scrY() + 84 + i * (btnH() + 12); }

  void draw() {
    textSize(g.textSize);
    PFont normalFont = g.textFont;
    float normalSize = g.textSize;

    pushStyle();
    drawMonitorPanel();
    float x0 = scrX() + 28;

    // título
    noStroke();
    textFont(pixelFont);
    textSize(18);
    textAlign(LEFT, CENTER);
    fill(COL_CYAN);
    text(TITULO, x0, scrY() + 34);
    stroke(COL_CYAN, 100);
    strokeWeight(2);
    line(x0, scrY() + 60, scrX() + scrW() - 28, scrY() + 60);
    noStroke();

    // concepto del juego
    float colW = scrW() * 0.52 - 28 - 20;
    textFont(bodyFont);
    textSize(18);
    textLeading(26);
    textAlign(LEFT, TOP);
    fill(232, 251, 255);
    float y = scrY() + 84;
    text(CONCEPTO, x0, y, colW, 220);
    y += countLinesFor(CONCEPTO, colW) * 26 + 22;
    fill(COL_AMBER);
    text(HINT, x0, y, colW, 120);

    // botones de temas
    hoverTema = -1;
    textFont(pixelFont);
    textSize(14);
    for (int i = 0; i < TEMAS.length; i++) {
      float bx = btnX(), by = btnY(i), bw = btnW(), bh = btnH();
      boolean over = mouseX > bx && mouseX < bx + bw && mouseY > by && mouseY < by + bh;
      if (over) hoverTema = i;

      strokeWeight(2);
      if (over) { fill(COL_AMBER); stroke(255, 224, 176); }
      else      { fill(22, 38, 63);   stroke(45, 74, 99); }
      rect(bx, by, bw, bh, 8);

      noStroke();
      if (over) fill(COL_NAVY); else fill(COL_TEXT_SOFT);
      textAlign(CENTER, CENTER);
      text(TEMAS[i], bx + bw / 2.0, by + bh / 2.0);
    }

    // volver
    textFont(pixelFont);
    textSize(12);
    hoverBack = pixelLink("< Volver", x0, scrY() + scrH() - 28, LEFT, COL_TEXT_SOFT, color(255));

    popStyle();
    textFont(normalFont, normalSize);
    cursor((hoverTema >= 0 || hoverBack) ? HAND : ARROW);
  }

  void mousePressed() {
    if (hoverBack) goTo(new CreditsScreen());
    else if (hoverTema >= 0) goTo(new TopicScreen(hoverTema));
  }
}


// ------------------------------------------------------------
//  Página de un tema: explicación + código real del proyecto
// ------------------------------------------------------------
class TopicScreen extends Screen {
  final String[] TEMAS = { "Arreglos", "Matrices", "Cadenas", "Funciones", "Subrutinas" };

  final String[][] EXPLICACION = {
    { // Arreglos
      "Un arreglo guarda varios valores del mismo tipo en una sola variable. Cada valor se llama con su posición (índice).",
      "Las acciones que el jugador programa tienen un número (ACT_FORWARD es 0, ACT_TURN_LEFT es 1...) y sus nombres están en el arreglo ACTION_LABELS. Así, ACTION_LABELS[2] da \"Girar Der.\".",
      "También usamos ArrayList, un arreglo que puede crecer, para los objetos de cada piso y las tareas del nivel."
    },
    { // Matrices
      "Una matriz es un arreglo de arreglos: una tabla con filas y columnas.",
      "El mapa de cada piso es una matriz de caracteres, terrain[fila][columna]. Cada casilla guarda ' ' (suelo), 'W' (pared) o 'H' (hueco).",
      "Con ella el juego sabe por dónde puede caminar el jugador y dónde cae. La matriz visited marca las casillas que ya pisó."
    },
    { // Cadenas
      "Una cadena (String) es un texto. Se puede recorrer letra por letra, cortar con split y unir con +.",
      "Cada piso del mapa llega como una lista de cadenas, y cada carácter de la cadena es una casilla (charAt).",
      "También usamos cadenas para las horas del reloj (\"8:00\" se separa con split), los mensajes del juego y los textos de los botones."
    },
    { // Funciones
      "Una función es un bloque de código con nombre que recibe datos (parámetros) y devuelve un resultado con return.",
      "inBounds responde true o false según si una casilla está dentro del mapa. allGoalsMet revisa si ya se leyeron todas las notas y se cumplieron todas las tareas para completar el nivel.",
      "Así el mismo código se reutiliza desde muchos lugares en vez de repetirse."
    },
    { // Subrutinas
      "Una subrutina también es un bloque con nombre, pero no devuelve ningún valor: solo hace algo. En Processing se declara con void.",
      "say muestra un aviso sobre el mapa durante unos segundos. executeAction convierte una acción programada en lo que hace el jugador.",
      "Separar el código en subrutinas lo hace más fácil de leer y de cambiar."
    }
  };

  final String[][] CODIGO = {
    { // Arreglos
      "final int ACT_FORWARD    = 0;",
      "final int ACT_TURN_LEFT  = 1;",
      "final int ACT_TURN_RIGHT = 2;",
      "final int ACT_INTERACT   = 3;",
      "",
      "String[] ACTION_LABELS = {",
      "  \"Avanzar\", \"Girar Izq.\",",
      "  \"Girar Der.\", \"Interactuar\"",
      "};",
      "",
      "// ACTION_LABELS[ACT_TURN_RIGHT] da \"Girar Der.\"",
      "",
      "// ArrayList: un arreglo que puede crecer",
      "ArrayList<GameObject> objects =",
      "  new ArrayList<GameObject>();",
      "ArrayList<Task> tasks;"
    },
    { // Matrices
      "char[][] terrain;   // ' ' suelo, 'W' pared, 'H' hueco",
      "boolean[][] visited;",
      "",
      "f.terrain = new char[f.rows][f.cols];",
      "f.visited = new boolean[f.rows][f.cols];",
      "",
      "for (int r = 0; r < f.rows; r++) {",
      "  String line = mapRows.getString(r);",
      "  for (int c = 0; c < f.cols; c++) {",
      "    char ch = c < line.length() ? line.charAt(c) : '.';",
      "    f.terrain[r][c] = (ch == 'W' || ch == 'H') ? ch : ' ';",
      "  }",
      "}",
      "",
      "char terrainAt(int row, int col) {",
      "  return terrain[row][col];",
      "}"
    },
    { // Cadenas
      "// Leer el mapa: cada carácter es una casilla",
      "String line = mapRows.getString(r);",
      "char ch = line.charAt(c);",
      "",
      "// \"8:00\" -> minutos desde las 0:00 (resumida)",
      "int parseTime(String s, int fallback) {",
      "  String[] p = s.trim().split(\":\");",
      "  int h = Integer.parseInt(p[0].trim());",
      "  int m = p.length > 1 ? Integer.parseInt(p[1].trim()) : 0;",
      "  return h * 60 + m;",
      "}",
      "",
      "// Unir cadenas con +",
      "b.label = levels.nameAt(i) + \"\\n(completado)\";"
    },
    { // Funciones
      "boolean inBounds(int row, int col) {",
      "  return row >= 0 && row < rows && col >= 0 && col < cols;",
      "}",
      "",
      "char terrainAt(int row, int col) {",
      "  return terrain[row][col];",
      "}",
      "",
      "boolean allGoalsMet() {",
      "  if (tasks.isEmpty() && notes.isEmpty()) return false;",
      "  for (Note n : notes) {",
      "    if (!n.read) return false;",
      "  }",
      "  for (Task t : tasks) {",
      "    if (!t.isDone()) return false;",
      "  }",
      "  return true;",
      "}"
    },
    { // Subrutinas
      "void say(String text) {",
      "  message = text;",
      "  messageUntil = millis() + MESSAGE_MS;",
      "}",
      "",
      "void clearMessage() {",
      "  message = \"\";",
      "}",
      "",
      "void executeAction(int action, Player player, Level level) {",
      "  switch (action) {",
      "    case ACT_FORWARD:",
      "      player.moveForward(level);",
      "      break;",
      "    case ACT_TURN_LEFT:",
      "      player.turn(-1);",
      "      break;",
      "    case ACT_TURN_RIGHT:",
      "      player.turn(1);",
      "      break;",
      "    case ACT_INTERACT:",
      "      player.interact(level);",
      "      break;",
      "  }",
      "}"
    }
  };

  final float LINEA_H = 17;
  final float PAD = 12;

  int idx;
  PFont pixelFont, bodyFont, codeFont;
  float scrollY = 0;
  boolean dragging = false;
  boolean hoverTemas = false, hoverPrev = false, hoverNext = false;

  TopicScreen(int idx) {
    this.idx = idx;
    pixelFont = uiFont;
    bodyFont  = createFont("SansSerif", 15);
    codeFont  = createFont("Monospaced", 12);
  }

  // zona del recuadro de código
  float codeX() { return scrX() + scrW() * 0.50; }
  float codeY() { return scrY() + 84; }
  float codeW() { return scrW() * 0.50 - 28; }
  float codeH() { return scrH() - 84 - 60; }

  void draw() {
    textSize(g.textSize);
    PFont normalFont = g.textFont;
    float normalSize = g.textSize;

    pushStyle();
    drawMonitorPanel();
    float x0 = scrX() + 28;
    float xr = scrX() + scrW() - 28;

    // título
    noStroke();
    textFont(pixelFont);
    textSize(18);
    textAlign(LEFT, CENTER);
    fill(COL_CYAN);
    text(TEMAS[idx].toUpperCase(), x0, scrY() + 34);
    stroke(COL_CYAN, 100);
    strokeWeight(2);
    line(x0, scrY() + 60, xr, scrY() + 60);
    noStroke();

    // explicación (izquierda)
    float colW = scrW() * 0.46 - 28;
    textFont(bodyFont);
    textSize(15);
    textLeading(21);
    textAlign(LEFT, TOP);
    fill(232, 251, 255);
    float y = scrY() + 84;
    for (int i = 0; i < EXPLICACION[idx].length; i++) {
      String par = EXPLICACION[idx][i];
      text(par, x0, y, colW, 300);
      y += countLinesFor(par, colW) * 21 + 14;
    }

    // recuadro de código (derecha)
    float cx = codeX(), cy = codeY(), cw = codeW(), ch = codeH();
    noStroke();
    fill(30, 34, 46);
    rect(cx, cy, cw, ch, 8);

    String[] code = CODIGO[idx];
    float contenidoH = code.length * LINEA_H + PAD * 2;
    float maxScroll = max(0, contenidoH - ch);

    if (dragging && mousePressed) {
      scrollY += pmouseY - mouseY;
    } else {
      dragging = false;
    }
    if (keyPressed && key == CODED) {
      if (keyCode == DOWN) scrollY += 6;
      if (keyCode == UP)   scrollY -= 6;
    }
    scrollY = constrain(scrollY, 0, maxScroll);

    clip(cx, cy, cw, ch);
    textFont(codeFont);
    textSize(12);
    textAlign(LEFT, TOP);
    for (int i = 0; i < code.length; i++) {
      float ly = cy + PAD + i * LINEA_H - scrollY;
      if (ly < cy - LINEA_H || ly > cy + ch) continue;
      if (code[i].trim().startsWith("//")) fill(120, 150, 120);   // comentarios
      else fill(220, 225, 235);
      text(code[i], cx + PAD, ly);
    }
    noClip();

    if (maxScroll > 0) {
      float barH = ch * (ch / contenidoH);
      float barY = cy + (scrollY / maxScroll) * (ch - barH);
      fill(255, 255, 255, 70);
      rect(cx + cw - 8, barY, 4, barH, 2);
    }

    // pie: volver a los temas, anterior / siguiente y contador
    textFont(pixelFont);
    textSize(11);
    int cyan = COL_TEXT_SOFT, white = color(255);
    float fy = scrY() + scrH() - 28;
    hoverTemas = pixelLink("< Temas", x0, fy, LEFT, cyan, white);
    hoverNext  = pixelLink("Siguiente >", xr, fy, RIGHT, cyan, white);
    float nextW = textWidth("Siguiente >");
    hoverPrev  = pixelLink("< Anterior", xr - nextW - 30, fy, RIGHT, cyan, white);

    textAlign(CENTER, CENTER);
    fill(COL_PINK);
    text((idx + 1) + " / " + TEMAS.length, scrX() + scrW() / 2.0, fy);

    boolean overCode = mouseX > cx && mouseX < cx + cw && mouseY > cy && mouseY < cy + ch;

    popStyle();
    textFont(normalFont, normalSize);
    cursor((hoverTemas || hoverPrev || hoverNext) ? HAND : (overCode ? MOVE : ARROW));
  }

  void mouseWheel(int amount)   { scrollY += amount * 20; }
  void mouseWheel(float delta)  { scrollY += delta * 20; }

  void mousePressed() {
    if (hoverTemas) goTo(new BehindScreen());
    else if (hoverNext) goTo(new TopicScreen((idx + 1) % TEMAS.length));
    else if (hoverPrev) goTo(new TopicScreen((idx + TEMAS.length - 1) % TEMAS.length));
    else {
      // empieza el arrastre solo si el clic fue dentro del recuadro de código
      dragging = mouseX > codeX() && mouseX < codeX() + codeW()
              && mouseY > codeY() && mouseY < codeY() + codeH();
    }
  }
}
