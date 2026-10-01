// ============================================================
//  Screen_Tutorials.pde — Lista de tutoriales (data/tutorials)
//  Todos están disponibles desde el principio; se juegan con la misma pantalla
//  de nivel (LevelScreen) y su ayuda sale del campo "hint" del JSON.
// ============================================================

class TutorialSelectScreen extends Screen {
  ArrayList<UIButton> btns = new ArrayList<UIButton>();
  UIButton backBtn;

  TutorialSelectScreen() {
    float w = 260, h = 70, gap = 16;
    int perRow = 2;
    float startX = (WINDOW_W - (perRow * w + (perRow - 1) * gap)) / 2.0;
    float startY = 130;

    for (int i = 0; i < tutorials.count(); i++) {
      float x = startX + (i % perRow) * (w + gap);
      float y = startY + (i / perRow) * (h + gap);
      btns.add(new UIButton(x, y, w, h, tutorials.nameAt(i)));
    }

    backBtn = new UIButton(20, WINDOW_H - 60, 120, 40, "Volver");
  }

  void draw() {
    pushStyle();
    fill(30, 50, 100);
    textAlign(CENTER, CENTER);
    textSize(32);
    text("Tutorial", WINDOW_W / 2.0, 70);
    textSize(15);
    text("Practica los controles antes de empezar.", WINDOW_W / 2.0, 105);
    popStyle();

    boolean anyHover = false;
    for (int i = 0; i < btns.size(); i++) {
      UIButton b = btns.get(i);
      String name = tutorials.nameAt(i);
      b.label = progress.isCompleted(tutorials.idAt(i)) ? name + "\n(completado)" : name;
      b.draw();
      anyHover |= b.hover();
    }

    backBtn.draw();
    anyHover |= backBtn.hover();
    cursor(anyHover ? HAND : ARROW);
  }

  void mousePressed() {
    for (int i = 0; i < btns.size(); i++) {
      if (btns.get(i).clicked()) {
        goTo(new LevelScreen(tutorials, i));
        return;
      }
    }
    if (backBtn.clicked()) goTo(new HomeScreen());
  }
}
