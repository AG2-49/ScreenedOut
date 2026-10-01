// ============================================================
//  Screen_Level.pde — Pantalla de juego de un nivel
//  Ensambla: Level + Player + Camera + MapRenderer + TaskPanel + NoteViewer + Program(+Runner+Panel).
// ============================================================

class LevelScreen extends Screen {
  int levelIndex;
  Level level;
  Player player = new Player();
  Camera camera;
  MapRenderer renderer = new MapRenderer();

  Program program = new Program();
  ProgramRunner runner;
  ProgramPanel panel;
  TaskPanel taskPanel;
  NoteViewer noteViewer;

  UIButton menuBtn;
  int lastRow, lastCol;
  boolean wasAnimating = false;
  boolean progressSaved = false;

  LevelScreen(int levelIndex) {
    this.levelIndex = levelIndex;
    level = levels.create(levelIndex);

    camera = new Camera(mapArea);
    camera.setContentSize(level.cols * TILE_SIZE, level.rows * TILE_SIZE);

    runner = new ProgramRunner(program, player, level);
    panel = new ProgramPanel(progArea, program, runner, this);
    taskPanel = new TaskPanel(taskArea, level);
    noteViewer = new NoteViewer(mapArea, level);

    // Botón de salida al menú principal, arriba a la derecha del panel de programación
    menuBtn = new UIButton(progArea.x + progArea.w - 15 - 90, progArea.y + 15, 90, 32, "Menú");
    menuBtn.textSz = 14;

    resetLevel();
  }

  // Restaura jugador, nivel y cámara a su estado inicial.
  void resetLevel() {
    level.reset();
    player.reset(level);
    camera.reset();
    camera.follow(player.px(), player.py());
    lastRow = player.row;
    lastCol = player.col;
  }

  // Lo llama el panel al pulsar "Correr": cada intento empieza limpio.
  void startRun() {
    if (program.isEmpty()) return;
    resetLevel();
    runner.start();
    panel.ensureVisible(0);   // la lista vuelve a la primera acción
  }

  // ----- Ciclo -----
  void update() {
    runner.update();
    player.update();
    panel.update();
    level.updateCompletion();

    // La cámara sigue al jugador al cambiar de casilla y durante toda la animación del paso
    // (así acompaña el deslizamiento). En reposo no tira de ella: se puede arrastrar el mapa.
    boolean changedCell = player.row != lastRow || player.col != lastCol;
    boolean animNow = player.isAnimating();
    if (changedCell || animNow || wasAnimating) {   // wasAnimating: un último ajuste al terminar
      camera.follow(player.px(), player.py());
      lastRow = player.row;
      lastCol = player.col;
    }
    wasAnimating = animNow;

    if (level.completed && !progressSaved) {
      progress.markCompleted(level.id);
      progressSaved = true;
    }
  }

  void draw() {
    if (noteViewer.isOpen()) {
      // Con una nota abierta, su contenido reemplaza al mapa
      noteViewer.draw();
    } else {
      camera.begin();
      renderer.draw(level, camera);
      player.draw();
      camera.end();
      drawBanner();
    }

    taskPanel.draw();
    panel.draw();
    menuBtn.draw();

    updateCursor();
  }

  // Cursor según lo que se pueda arrastrar bajo el mouse.
  void updateCursor() {
    int c = ARROW;
    if (noteViewer.isOpen()) {
      if (noteViewer.closeBtn.hover()) c = HAND;
      else if (noteViewer.canDragHere()) c = noteViewer.dragging ? MOVE : HAND;
    } else if (camera.canDragHere()) {
      c = camera.dragging ? MOVE : HAND;
    }
    if (c == ARROW && panel.dragging) c = MOVE;
    else if (c == ARROW && panel.canDragHere()) c = HAND;
    cursor(c);
  }

  // Mensaje sobre el mapa: victoria, caída o aviso del último objeto usado.
  void drawBanner() {
    String msg = "";
    if (level.completed)           msg = "¡Nivel completado!  Vuelve al menú con el botón «Menú».";
    else if (player.fell)          msg = "Caíste en un hueco. Pulsa «Correr» para reintentar.";
    else if (level.message.length() > 0) msg = level.message;
    if (msg.length() == 0) return;

    pushStyle();
    float bh = 34;
    fill(0, 170);
    noStroke();
    rect(mapArea.x, mapArea.y + mapArea.h - bh, mapArea.w, bh);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(13);
    text(msg, mapArea.x + mapArea.w / 2.0, mapArea.y + mapArea.h - bh / 2.0);
    popStyle();
  }

  // ----- Entrada -----
  // Con una nota abierta solo responden: su botón de cerrar, el botón «Menú» y los desplazamientos.
  void mousePressed() {
    if (menuBtn.clicked()) {
      goTo(new HomeScreen());
      return;
    }
    if (noteViewer.isOpen()) {
      noteViewer.mousePressed();
      return;
    }
    if (camera.mousePressed()) return;   // click sobre el mapa = empieza arrastre
    panel.mousePressed();
  }

  void mouseDragged() {
    camera.mouseDragged();
    panel.mouseDragged();
    noteViewer.mouseDragged();
  }

  void mouseReleased() {
    camera.mouseReleased();
    panel.mouseReleased();
    noteViewer.mouseReleased();
  }

  void mouseWheel(int amount) {
    taskPanel.mouseWheel(amount);
    panel.mouseWheel(amount);
    noteViewer.mouseWheel(amount);
  }

  // Movimiento manual con flechas / WASD y E para interactuar (útil para probar niveles)
  void keyPressed() {
    if (noteViewer.isOpen()) {
      noteViewer.keyPressed();
      return;
    }

    int dx = 0, dy = 0;
    if (keyCode == RIGHT || keyCode == 'D') dx = 1;
    else if (keyCode == LEFT || keyCode == 'A') dx = -1;
    else if (keyCode == UP || keyCode == 'W') dy = -1;
    else if (keyCode == DOWN || keyCode == 'S') dy = 1;

    if (dx != 0 || dy != 0) {
      player.tryMove(level, dx, dy);
    } else if (keyCode == 'E') {
      player.interact(level);
    }
  }
}
