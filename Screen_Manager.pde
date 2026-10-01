// ============================================================
//  Screen_Manager.pde — Máquina de pantallas
//  Cada "pantalla" (menú, selector de niveles, nivel...) es una
//  clase que hereda de Screen. Para cambiar de pantalla: goTo(new X()).
// ============================================================

Screen currentScreen;

void goTo(Screen next) {
  currentScreen = next;
  cursor(ARROW);
  currentScreen.onEnter();
}

abstract class Screen {
  void onEnter() {}
  void update() {}
  abstract void draw();
  void mousePressed() {}
  void mouseDragged() {}
  void mouseReleased() {}
  void mouseWheel(int amount) {}
  void keyPressed() {}
}
