// ============================================================
//  Screen_Credits.pde — Créditos del equipo
//  Para añadir a alguien: una fila más en CREDITS = {rol, nombre}.
// ============================================================

class CreditsScreen extends Screen {
  final String[][] CREDITS = {
    {"Project leader", "Farid"},
    {"Level and art design", "Shadia"},
    {"Programmer", "Adrián"},
    {"Archivist", "Sebastián"}
  };

  UIButton backBtn = new UIButton(20, WINDOW_H - 60, 120, 40, "Volver");

  void draw() {
    pushStyle();
    textAlign(CENTER, CENTER);

    fill(30, 50, 100);
    textSize(32);
    text("Créditos", WINDOW_W / 2.0, 70);

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
