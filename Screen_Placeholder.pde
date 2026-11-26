// ============================================================
//  Screen_Placeholder.pde — Pantalla genérica "en construcción"
//  (Tutorial y Créditos, hasta que tengan su propia pantalla)
// ============================================================

class PlaceholderScreen extends Screen {
  String title, body;
  UIButton backBtn = new UIButton(20, WINDOW_H - 60, 120, 40, "Volver");

  PlaceholderScreen(String title, String body) {
    this.title = title;
    this.body = body;
  }

  void draw() {
    pushStyle();
    fill(COL_TEXT_SOFT);
    textAlign(CENTER, CENTER);
    textSize(32);
    text(title, WINDOW_W / 2.0, 100);
    textSize(18);
    text(body, WINDOW_W / 2.0, WINDOW_H / 2.0);
    popStyle();

    backBtn.draw();
    cursor(backBtn.hover() ? HAND : ARROW);
  }

  void mousePressed() {
    if (backBtn.clicked()) goTo(new HomeScreen());
  }
}
