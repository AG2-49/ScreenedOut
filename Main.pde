// ============================================================
//  Main.pde — Punto de entrada
//  Solo inicializa los sistemas globales y reparte los eventos
//  a la pantalla activa. La lógica vive en cada módulo (ver README.md).
// ============================================================

void settings() {
  size(WINDOW_W, WINDOW_H);
}

void setup() {
  assets = new Assets();
  assets.load();

  levels = new LevelCatalog();
  levels.load();

  progress = new Progress();
  progress.load();

  goTo(new HomeScreen());
}

void draw() {
  background(bgColor);
  currentScreen.update();
  currentScreen.draw();
}

// ----- Los eventos de Processing se delegan a la pantalla activa -----
void mousePressed()  { currentScreen.mousePressed(); }
void mouseDragged()  { currentScreen.mouseDragged(); }
void mouseReleased() { currentScreen.mouseReleased(); }
void keyPressed()    { currentScreen.keyPressed(); }
void mouseWheel(MouseEvent event) { currentScreen.mouseWheel(event.getCount()); }
