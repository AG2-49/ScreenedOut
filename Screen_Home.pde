
 class HomeScreen extends Screen {
  String[] labels = { "Niveles", "Tutorial", "Créditos", "Salir" };
  PFont pixelFont;
  int sel = 0;
  RoomCam cam = new RoomCam();

  int mode = 0;          // 0 quieto, 1 acercándose, 2 alejándose
  int target = 0;        // a cuál pantalla vamos: 0 niveles, 1 tutorial, 2 créditos
  int animStart = 0;
  int animDur = 1100;    // milisegundos

  HomeScreen() { this(false); }

  HomeScreen(boolean zoomOut) {
    pixelFont = uiFont;
    if (zoomOut) { mode = 2; animStart = millis(); }
  }

  // posición vertical de cada opción (76 = primera, 15 = separación entre ellas)
  float lineY(int i) { return 76 + 15 * i; }

  int hoveredRow() {
    if (mode != 0) return -1;
    float lx = (mouseX - roomOX()) / roomS();
    float ly = mouseY / roomS();
    for (int i = 0; i < labels.length; i++) {
      float cy = lineY(i);
      if (lx > 120 && lx < 260 && ly > cy - 7.5 && ly < cy + 7.5) return i;
    }
    return -1;
  }

  void draw() {
    textSize(g.textSize);
    PFont normalFont = g.textFont;
    float normalSize = g.textSize;

    float s = roomS(), ox = roomOX();
    int hov = hoveredRow();
    if (hov >= 0) sel = hov;

    float t = 0, p = 0;
    if (mode != 0) {
      t = constrain((millis() - animStart) / (float) animDur, 0, 1);
      p = (mode == 1) ? t : 1 - t;
    }
    cam.set(roomEase(p));

    pushStyle();
    drawRoom(cam);

    float fade = 1 - constrain((p - 0.55) / 0.35, 0, 1);
    int a = (int) (255 * fade);

    // línea bajo el título
    cam.begin();
    stroke(COL_CYAN, 100 * fade);
    strokeWeight(s);
    line(ox + 124 * s, 60 * s, ox + 256 * s, 60 * s);
    cam.end();

    // textos
    noStroke();
    textFont(pixelFont);
    textSize(9 * s * cam.cz);

    textAlign(CENTER, CENTER);
    fill(COL_CYAN, a);
    text("SCREENED-OUT", cam.x(ox + 190 * s), cam.y(50 * s));

    textAlign(LEFT, CENTER);
    for (int i = 0; i < labels.length; i++) {
      boolean on = (i == sel);
      String txt = (on ? "> " : "  ") + labels[i];
      color c = on ? COL_AMBER : (i == 3 ? COL_PINK : COL_TEXT_SOFT);
      fill(red(c), green(c), blue(c), a);
      float x = cam.x(ox + 128 * s);
      float y = cam.y(lineY(i) * s);
      text(txt, x, y);

      if (on && mode == 0 && (frameCount / 30) % 2 == 0) {
        float tw = textWidth(txt);
        fill(COL_AMBER, a);
        rect(x + tw + 4 * s * cam.cz, y - 4 * s * cam.cz, 5 * s * cam.cz, 8 * s * cam.cz);
      }
    }

    popStyle();
    textFont(normalFont, normalSize);
    cursor(hov >= 0 ? HAND : ARROW);

    if (mode != 0 && t >= 1) {
      int m = mode;
      mode = 0;
      if (m == 1) {
        if (target == 0) goTo(new LevelSelectScreen());
        else if (target == 1) goTo(new TutorialSelectScreen());
        else goTo(new CreditsScreen());
      }
    }
  }

  void mousePressed() {
    if (mode != 0) return;
    int i = hoveredRow();
    if (i >= 0 && i <= 2) { target = i; mode = 1; animStart = millis(); }
    else if (i == 3) exit();
  }
}
