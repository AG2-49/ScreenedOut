// ============================================================
//  Screen_Manager.pde — Máquina de pantallas
//  Cada "pantalla" (menú, selector de niveles, nivel...) es una
//  clase que hereda de Screen. Para cambiar de pantalla: goTo(new X()).
// ============================================================

Screen currentScreen;

void goTo(Screen next) {
  audio.silence();                               // los efectos no cruzan de una pantalla a otra
  audio.setInLevel(next instanceof LevelScreen); // la música baja de volumen dentro de un nivel
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
