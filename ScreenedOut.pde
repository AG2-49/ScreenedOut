// ============================================================
//  ScreenedOut.pde — Punto de entrada
//  Solo inicializa los sistemas globales y reparte los eventos
//  a la pantalla activa. La lógica vive en cada módulo (ver README.md).
// ============================================================

void settings() {
  size(WINDOW_W, WINDOW_H);
}

void setup() {
  initTheme();
  assets = new Assets();
  assets.load();

  audio = new Audio(this);
  audio.load();
  audio.startMusic();

  levels = new LevelCatalog("levels");
  levels.load();

  tutorials = new LevelCatalog("tutorials");
  tutorials.load();

  progress = new Progress();
  progress.load();

  goTo(new HomeScreen());
}

void draw() {
  background(bgColor);
  audio.update();
  currentScreen.update();
  currentScreen.draw();
  drawMuteNotice();
}

// Aviso discreto en el margen superior mientras el sonido está desactivado (tecla M).
void drawMuteNotice() {
  if (!audio.muted) return;
  pushStyle();
  fill(COL_TEXT_SOFT, 170);
  textAlign(CENTER, CENTER);
  textSize(11);
  text("Sonido desactivado (M para activarlo)", WINDOW_W / 2.0, PANEL_MARGIN / 2.0);
  popStyle();
}

// Libera los dispositivos de audio al cerrar la ventana.
void dispose() {
  audio.close();
  super.dispose();
}

// ----- Los eventos de Processing se delegan a la pantalla activa -----
void mousePressed()  { currentScreen.mousePressed(); }
void mouseDragged()  { currentScreen.mouseDragged(); }
void mouseReleased() { currentScreen.mouseReleased(); }
void keyPressed() {
  if (key == 'm' || key == 'M') {   // silenciar / activar el sonido en cualquier pantalla
    audio.toggleMute();
    return;
  }
  currentScreen.keyPressed();
}
void mouseWheel(MouseEvent event) { currentScreen.mouseWheel(event.getCount()); }
