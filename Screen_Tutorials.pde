// ============================================================
//  Screen_Tutorials.pde — Lista de tutoriales (data/tutorials)
//  Todos están disponibles desde el principio; se juegan con la misma pantalla
//  de nivel (LevelScreen) y su ayuda sale del campo "hint" del JSON.
// ============================================================

class TutorialSelectScreen extends Screen {
  RoomCam cam = new RoomCam();
  PFont pixelFont;
  int born;

  TutorialSelectScreen() {
    pixelFont = createFont("PressStart2P-Regular.ttf", 32);
    born = millis();
    cam.set(1);
  }

  // Filas dentro de la pantalla del monitor (espacio de 380 x 205).
  // Hasta 4 tutoriales van en una columna; de 5 a 8, en dos columnas.
  boolean twoCols() { return tutorials.count() > 4; }
  float rowW() { return twoCols() ? 74 : 140; }
  float rowH() { return 13; }
  float rowX(int i) { return twoCols() ? 118 + (i / 4) * 78 : 120; }
  float rowY(int i) { return 57 + (i % 4) * 16; }

  float mx() { return (cam.invX(mouseX) - roomOX()) / roomS(); }
  float my() { return cam.invY(mouseY) / roomS(); }

  int hoveredRow() {
    for (int i = 0; i < tutorials.count(); i++) {
      if (mx() >= rowX(i) && mx() < rowX(i) + rowW() && my() >= rowY(i) && my() < rowY(i) + rowH()) return i;
    }
    return -1;
  }
  boolean overBack() { return mx() > 122 && mx() < 182 && my() > 123 && my() < 136; }

  void draw() {
    textSize(g.textSize);
    PFont normalFont = g.textFont;
    float normalSize = g.textSize;

    float s = roomS(), ox = roomOX();
    cam.set(1);
    float al = constrain((millis() - born) / 400.0, 0, 1);   // el contenido aparece suave
    int a = (int) (255 * al);
    int hover = hoveredRow();
    boolean hBack = overBack();

    pushStyle();
    drawRoom(cam);

    // formas dentro de la pantalla
    cam.begin();
    pushMatrix();
    translate(ox, 0);
    scale(s);

    stroke(34, 230, 255, 100 * al);
    strokeWeight(1);
    line(124, 45, 256, 45);

    for (int i = 0; i < tutorials.count(); i++) {
      boolean done = progress.isCompleted(tutorials.idAt(i));
      float x = rowX(i), y = rowY(i), w = rowW(), h = rowH();
      boolean hv = (i == hover);

      if (hv) { fill(31, 58, 92, a); stroke(255, a); strokeWeight(1.5); }
      else    { fill(22, 38, 63, a); stroke(45, 74, 99, a); strokeWeight(1); }
      rect(x, y, w, h, 2);

      noStroke();
      if (done) fill(63, 166, 107, a); else fill(255, 181, 90, a);
      rect(x + 2, y + 2, h - 4, h - 4, 2);

      if (done) {   // palomita a la derecha
        stroke(160, 230, 190, a);
        strokeWeight(1);
        line(x + w - 10, y + 7, x + w - 8, y + 9.5);
        line(x + w - 8, y + 9.5, x + w - 4.5, y + 4);
      }
    }
    popMatrix();
    cam.end();

    // textos
    noStroke();
    textFont(pixelFont);

    textAlign(CENTER, CENTER);
    textSize(8 * s * cam.cz);
    fill(34, 230, 255, a);
    text("TUTORIAL", cam.x(ox + 190 * s), cam.y(36 * s));

    textSize(5 * s * cam.cz);
    fill(143, 232, 245, a);
    text("Practica los controles", cam.x(ox + 190 * s), cam.y(51 * s));

    for (int i = 0; i < tutorials.count(); i++) {
      float x = rowX(i), y = rowY(i), h = rowH();
      boolean done = progress.isCompleted(tutorials.idAt(i));
      float cy = y + h / 2.0;

      // número
      textAlign(CENTER, CENTER);
      textSize(6 * s * cam.cz);
      fill(26, 29, 61, a);
      text(str(i + 1), cam.x(ox + (x + 2 + (h - 4) / 2.0) * s), cam.y(cy * s));

      // nombre: se encoge solo si es largo, para que no se salga de la fila
      String name = tutorials.nameAt(i);
      float avail = rowW() - h - 4 - 12;
      float sz = min(6, avail / max(1, name.length()));
      textAlign(LEFT, CENTER);
      textSize(sz * s * cam.cz);
      if (done) fill(160, 230, 190, a); else fill(232, 251, 255, a);
      text(name, cam.x(ox + (x + h + 2) * s), cam.y(cy * s));
    }

    textSize(6 * s * cam.cz);
    textAlign(LEFT, CENTER);
    if (hBack) fill(255, a); else fill(143, 232, 245, a);
    text("< Volver", cam.x(ox + 126 * s), cam.y(130 * s));

    popStyle();
    textFont(normalFont, normalSize);
    cursor((hover >= 0 || hBack) ? HAND : ARROW);
  }

  void mousePressed() {
    int i = hoveredRow();
    if (i >= 0) {
      goTo(new LevelScreen(tutorials, i));
      return;
    }
    if (overBack()) goTo(new HomeScreen(true));   // zoom hacia atrás al cuarto
  }
}
