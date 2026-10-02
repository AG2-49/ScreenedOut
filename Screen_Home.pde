// ============================================================
//  Screen_Home.pde — Menú principal
// ============================================================

class HomeScreen extends Screen {
  UIButton playBtn, tutorialBtn, creditsBtn, exitBtn, BehindBtn;

  HomeScreen() {
    float w = 240, h = 48, gap = 14;
    float x = (WINDOW_W - w) / 2.0;
    float y = 180;

    playBtn     = new UIButton(x, y, w, h, "Niveles");
    BehindBtn     = new UIButton(x, y + (h + gap) * 4, w, h, "Detrás del Código");
    tutorialBtn = new UIButton(x, y + (h + gap), w, h, "Tutorial");
    creditsBtn  = new UIButton(x, y + (h + gap) * 2, w, h, "Créditos");
    exitBtn     = new UIButton(x, y + (h + gap) * 3, w, h, "Salir");
    exitBtn.colors(color(245, 180, 170), color(240, 150, 140), color(150, 60, 50), color(100, 30, 25));
  }

  void draw() {
    pushStyle();
    fill(30, 50, 100);
    textAlign(CENTER, CENTER);
    textSize(44);
    text("PROCRASTINATOR", WINDOW_W / 2.0, 100);
    popStyle();

    playBtn.draw();
    BehindBtn.draw();
    tutorialBtn.draw();
    creditsBtn.draw();
    exitBtn.draw();

    cursor((playBtn.hover() || tutorialBtn.hover() || creditsBtn.hover() || exitBtn.hover()) ? HAND : ARROW);
  }

  void mousePressed() {
    if (playBtn.clicked()) goTo(new LevelSelectScreen());
    else if (tutorialBtn.clicked()) goTo(new TutorialSelectScreen());
    else if (creditsBtn.clicked()) goTo(new CreditsScreen());
    else if (BehindBtn.clicked()) goTo(new BehindScreen());
    else if (exitBtn.clicked()) exit();
  }
}
