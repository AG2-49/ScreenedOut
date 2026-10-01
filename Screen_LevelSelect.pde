// ============================================================
//  Screen_LevelSelect.pde — Lista de niveles con su progreso
//  Un nivel está bloqueado hasta completar el anterior (Progress.isUnlocked).
// ============================================================

class LevelSelectScreen extends Screen {
  ArrayList<UIButton> levelBtns = new ArrayList<UIButton>();
  UIButton backBtn, resetBtn;
  boolean confirmReset = false;

  LevelSelectScreen() {
    float w = 150, h = 70, gap = 16;
    int perRow = 4;
    float startX = (WINDOW_W - (perRow * w + (perRow - 1) * gap)) / 2.0;
    float startY = 130;

    for (int i = 0; i < levels.count(); i++) {
      float x = startX + (i % perRow) * (w + gap);
      float y = startY + (i / perRow) * (h + gap);
      UIButton b = new UIButton(x, y, w, h, levels.nameAt(i));
      levelBtns.add(b);
    }

    backBtn  = new UIButton(20, WINDOW_H - 60, 120, 40, "Volver");
    resetBtn = new UIButton(WINDOW_W - 240, WINDOW_H - 60, 220, 40, "Reiniciar progreso");
    resetBtn.textSz = 14;
    resetBtn.colors(color(245, 180, 170), color(240, 150, 140), color(150, 60, 50), color(100, 30, 25));
  }

  void draw() {
    pushStyle();
    fill(30, 50, 100);
    textAlign(CENTER, CENTER);
    textSize(32);
    text("Niveles", WINDOW_W / 2.0, 70);
    popStyle();

    boolean anyHover = false;

    for (int i = 0; i < levelBtns.size(); i++) {
      UIButton b = levelBtns.get(i);
      b.enabled = progress.isUnlocked(i);

      if (progress.isCompleted(levels.idAt(i))) {
        b.label = levels.nameAt(i) + "\n(completado)";
      } else if (!b.enabled) {
        b.label = levels.nameAt(i) + "\n(bloqueado)";
      } else {
        b.label = levels.nameAt(i);
      }
      b.draw();
      anyHover |= b.hover();
    }

    resetBtn.label = confirmReset ? "¿Seguro? Pulsa de nuevo" : "Reiniciar progreso";
    backBtn.draw();
    resetBtn.draw();
    anyHover |= backBtn.hover() || resetBtn.hover();

    cursor(anyHover ? HAND : ARROW);
  }

  void mousePressed() {
    for (int i = 0; i < levelBtns.size(); i++) {
      if (levelBtns.get(i).clicked()) {
        goTo(new LevelScreen(i));
        return;
      }
    }

    if (backBtn.clicked()) {
      goTo(new HomeScreen());
      return;
    }

    if (resetBtn.clicked()) {
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
