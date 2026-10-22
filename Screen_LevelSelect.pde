// ============================================================
//  Screen_LevelSelect.pde — Lista de niveles con su progreso
//  Un nivel está bloqueado hasta completar el anterior (Progress.isUnlocked).
// ============================================================

class LevelSelectScreen extends Screen {
  RoomCam cam = new RoomCam();
  PFont pixelFont;
  boolean confirmReset = false;
  int born;

  LevelSelectScreen() {
    pixelFont = createFont("PressStart2P-Regular.ttf", 32);
    born = millis();
  }

  // cuadrícula de niveles dentro de la pantalla del monitor (hasta 8 niveles)
  int perRow()    { return levels.count() <= 6 ? 3 : 4; }
  float tileW()   { return levels.count() <= 6 ? 40 : 30; }
  float tileH()   { return levels.count() <= 6 ? 28 : 24; }
  float gridW()   { int n = min(levels.count(), perRow()); return n * tileW() + (n - 1) * 6; }
  float tileX(int i) { return 190 - gridW() / 2.0 + (i % perRow()) * (tileW() + 6); }
  float tileY(int i) { return 58 + (i / perRow()) * (tileH() + 6); }

  // mouse convertido al espacio del dibujo (380 x 205)
  float mx() { return (cam.invX(mouseX) - roomOX()) / roomS(); }
  float my() { return cam.invY(mouseY) / roomS(); }

  int hoveredTile() {
    for (int i = 0; i < levels.count(); i++) {
      if (mx() >= tileX(i) && mx() < tileX(i) + tileW() && my() >= tileY(i) && my() < tileY(i) + tileH()) return i;
    }
    return -1;
  }
  boolean overBack()  { return mx() > 122 && mx() < 182 && my() > 123 && my() < 136; }
  boolean overReset() { return mx() > 196 && mx() < 260 && my() > 123 && my() < 136; }

  void draw() {
    textSize(g.textSize);
    PFont normalFont = g.textFont;
    float normalSize = g.textSize;

    float s = roomS(), ox = roomOX();
    cam.set(1);
    float al = constrain((millis() - born) / 400.0, 0, 1);   // el contenido aparece suave
    int a = (int) (255 * al);

    int hover = hoveredTile();
    boolean hBack = overBack(), hReset = overReset();
    boolean tileClickable = hover >= 0 && progress.isUnlocked(hover);

    pushStyle();
    drawRoom(cam);

    // formas dentro de la pantalla
    cam.begin();
    pushMatrix();
    translate(ox, 0);
    scale(s);

    stroke(34, 230, 255, 100 * al);
    strokeWeight(1);
    line(124, 50, 256, 50);

    for (int i = 0; i < levels.count(); i++) {
      boolean unlocked = progress.isUnlocked(i);
      boolean done = progress.isCompleted(levels.idAt(i));
      float x = tileX(i), y = tileY(i), w = tileW(), h = tileH();
      boolean hv = (i == hover) && unlocked;

      if (!unlocked)  { fill(22, 38, 63, a);    stroke(45, 74, 99, a); }
      else if (done)  { fill(63, 166, 107, a);  stroke(160, 230, 190, a); }
      else            { fill(255, 181, 90, a);  stroke(255, 224, 176, a); }
      if (hv) stroke(255, a);
      strokeWeight(hv ? 2 : 1);
      rect(x, y, w, h, 3);

      if (!unlocked) {          // candado
        noStroke();
        fill(74, 106, 133, a);
        rect(x + w - 11, y + h - 7, 7, 5);
        noFill();
        stroke(74, 106, 133, a);
        strokeWeight(1);
        arc(x + w - 7.5, y + h - 7, 4, 4, PI, TWO_PI);
      }
      if (done) {               // palomita
        stroke(26, 29, 61, a);
        strokeWeight(1.5);
        line(x + w - 12, y + h - 6, x + w - 9.5, y + h - 3.5);
        line(x + w - 9.5, y + h - 3.5, x + w - 5, y + h - 9);
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
    text("NIVELES", cam.x(ox + 190 * s), cam.y(42 * s));

    textSize(11 * s * cam.cz);
    for (int i = 0; i < levels.count(); i++) {
      color c = progress.isUnlocked(i) ? color(26, 29, 61) : color(74, 106, 133);
      fill(red(c), green(c), blue(c), a);
      float cx = tileX(i) + tileW() / 2.0;
      float cy = tileY(i) + tileH() / 2.0 - 2;
      text(str(i + 1), cam.x(ox + cx * s), cam.y(cy * s));
    }

    textSize(6 * s * cam.cz);
    textAlign(LEFT, CENTER);
    if (hBack) fill(255, a); else fill(143, 232, 245, a);
    text("< Volver", cam.x(ox + 126 * s), cam.y(130 * s));

    textAlign(RIGHT, CENTER);
    if (confirmReset) fill(255, 181, 90, a);
    else if (hReset)  fill(255, 190, 215, a);
    else              fill(255, 122, 168, a);
    text(confirmReset ? "¿Seguro?" : "Reiniciar", cam.x(ox + 256 * s), cam.y(130 * s));

    popStyle();
    textFont(normalFont, normalSize);
    cursor((tileClickable || hBack || hReset) ? HAND : ARROW);
  }

  void mousePressed() {
    int i = hoveredTile();
    if (i >= 0 && progress.isUnlocked(i)) {
      goTo(new LevelScreen(i));
      return;
    }
    if (overBack()) {
      goTo(new HomeScreen(true));   // zoom hacia atrás al cuarto
      return;
    }
    if (overReset()) {
      if (confirmReset) {
        progress.reset();
        confirmReset = false;
      } else {
        confirmReset = true;
      }
      return;
    }
    confirmReset = false;   // un click en cualquier otro lado cancela la confirmación
  }
}
