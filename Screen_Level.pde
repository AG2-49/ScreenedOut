// ============================================================
//  Screen_Level.pde — Pantalla de juego de un nivel
//  Ensambla: Level + Player + Camera + MapRenderer + TaskPanel + NoteViewer + ClockIntro + Program(+Runner+Panel).
// ============================================================

class LevelScreen extends Screen {
  LevelCatalog catalog;      // de dónde viene el nivel (levels o tutorials)
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
  ClockIntro clock;

  UIButton menuBtn, nextBtn;
  int lastRow, lastCol;
  boolean wasAnimating = false;
  boolean progressSaved = false;

  boolean attempted = false;       // ya se pulsó «Correr» al menos una vez
  GameObject hintObj = null;       // objeto en rango de interacción (caja ámbar)
  int hintUntil = 0;
  boolean hintLive = false;
  final int HINT_LINGER_MS = 600;
  GameObject hoverObj = null;      // objeto bajo el mouse (la misma caja)
  int viewFloor = 0;               // piso que SE VE (el del personaje, o el que el jugador eligió mirar)
  int playerFloorSeen = 0;         // último piso del personaje que ya se atendió (detecta escaleras)
  FloorSelector floorSelector;

  // Transición: 0 ninguna, 1 entrando (paneles deslizan hacia dentro), 2 saliendo,
  // 3 reloj de apertura a pantalla completa (si el nivel lo tiene; al terminar pasa a 1).
  int transMode = 0;
  int transStart = 0;
  int transDur = 600;
  int leaveAction = 0;             // al terminar de salir: 1 = menú principal, 2 = siguiente nivel

  LevelScreen(int levelIndex) {
    this(levels, levelIndex);
  }

  LevelScreen(LevelCatalog catalog, int levelIndex) {
    this.catalog = catalog;
    this.levelIndex = levelIndex;
    level = catalog.create(levelIndex);

    camera = new Camera(mapArea);
    camera.setContentSize(level.cols * TILE_SIZE, level.rows * TILE_SIZE);

    runner = new ProgramRunner(program, player, level);
    panel = new ProgramPanel(progArea, program, runner, this);
    taskPanel = new TaskPanel(taskArea, level);
    noteViewer = new NoteViewer(mapArea, level);
    clock = new ClockIntro(new Rect(0, 0, WINDOW_W, WINDOW_H), level);   // la apertura ocupa toda la ventana
    floorSelector = new FloorSelector(mapArea);

    // Botón de salida al menú principal, arriba a la derecha del panel de programación
    menuBtn = new UIButton(progArea.x + progArea.w - 15 - 90, progArea.y + 15, 90, 32, "Menú");
    menuBtn.textSz = 10;

    // Botón que aparece sobre el mapa al completar el nivel (encima del banner)
    float nw = 220, nh = 42;
    nextBtn = new UIButton(mapArea.x + (mapArea.w - nw) / 2.0, mapArea.y + mapArea.h - 34 - nh - 12, nw, nh, nextLabel());
    nextBtn.textSz = 10;

    resetLevel();
  }

  // Variante corta de la entrada (al venir de «Siguiente»).
  LevelScreen quick() {
    transDur = 250;
    return this;
  }

  void onEnter() {
    transMode = clock.isActive() ? 3 : 1;
    transStart = millis();
  }

  void beginLeave(int action, int dur) {
    if (transMode == 2) return;
    transMode = 2;
    transStart = millis();
    transDur = dur;
    leaveAction = action;
  }

  float transT() { return constrain((millis() - transStart) / (float) transDur, 0, 1); }

  // Cuánto está «en su sitio» cada elemento (0 = fuera, 1 = en su sitio): k 0 = tareas, 1 = mapa, 2 = programa.
  // Entrando salen de izquierda a derecha, escalonados; saliendo, al revés.
  float elemShown(int k) {
    if (transMode == 0) return 1;
    float local = constrain((transT() - (transMode == 1 ? k : 2 - k) * 0.13) / 0.74, 0, 1);
    return transMode == 1 ? easeOutCubic(local) : 1 - easeInCubic(local);
  }

  void endTransition() {
    int mode = transMode, action = leaveAction;
    transMode = 0;
    leaveAction = 0;
    if (mode != 2) return;
    if (action == 1) goTo(new HomeScreen(true));
    else if (action == 2) doNext();
  }

  // Restaura jugador, nivel y cámara a su estado inicial.
  void resetLevel() {
    audio.silence();                 // «Correr» de nuevo: nada del intento anterior debe seguir sonando
    level.reset();
    player.reset(level);
    floorSelector.open = false;
    playerFloorSeen = level.floor;
    setViewFloor(level.floor);
    lastRow = player.row;
    lastCol = player.col;
  }

  // Cambia el piso que se ve: ajusta la cámara a su tamaño (cada piso puede medir distinto).
  // Si es el del personaje, la cámara lo sigue; si no, se queda en la esquina para curiosear.
  void setViewFloor(int index) {
    viewFloor = constrain(index, 0, level.floors.size() - 1);
    Floor f = level.floors.get(viewFloor);
    camera.setContentSize(f.cols * TILE_SIZE, f.rows * TILE_SIZE);
    camera.reset();
    hintObj = null;
    hoverObj = null;
    if (viewFloor == level.floor) camera.follow(player.px(), player.py());
  }

  boolean viewingPlayerFloor() { return viewFloor == level.floor; }

  // Lo llama el panel al pulsar "Correr": cada intento empieza limpio.
  void startRun() {
    if (program.isEmpty()) return;
    resetLevel();
    attempted = true;
    runner.start();
    panel.ensureVisible(0);   // la lista vuelve a la primera acción
  }

  // ----- Siguiente nivel -----
  boolean isTutorial() { return catalog == tutorials; }
  boolean hasNext()    { return levelIndex + 1 < catalog.count(); }

  String nextLabel() {
    if (hasNext()) return isTutorial() ? "Siguiente tutorial" : "Siguiente nivel";
    return isTutorial() ? "Ir a los niveles" : "Ver créditos";
  }

  // El botón se ve solo con el nivel completado y el mapa a la vista.
  boolean showNext() {
    return level.completed && !clock.isActive() && !noteViewer.isOpen();
  }

  void goNext() {
    beginLeave(2, 250);
  }

  void doNext() {
    if (hasNext()) goTo(new LevelScreen(catalog, levelIndex + 1).quick());
    else if (isTutorial()) goTo(new LevelSelectScreen());
    else goTo(new CreditsScreen());
  }

  // ----- Ciclo -----
  void update() {
    if (transMode == 3) {            // el reloj va solo; al apagarse entran los paneles
      clock.update();
      if (!clock.isActive() && !clock.fading()) {
        transMode = 1;
        transStart = millis();
      }
      return;
    }
    if (transMode != 0) {            // durante la transición el juego espera (el reloj arranca al terminar la entrada)
      if (transT() >= 1) endTransition();
      return;
    }
    clock.update();
    runner.update();
    player.update();
    panel.update();
    level.updateCompletion();

    // Al usar unas escaleras cambia el piso del personaje: la vista lo acompaña
    if (level.floor != playerFloorSeen) {
      playerFloorSeen = level.floor;
      setViewFloor(level.floor);
    }

    updateHint();
    updateHover();

    // La cámara sigue al jugador al cambiar de casilla y durante toda la animación del paso
    // (así acompaña el deslizamiento). En reposo no tira de ella: se puede arrastrar el mapa.
    boolean changedCell = player.row != lastRow || player.col != lastCol;
    boolean animNow = player.isAnimating();
    if (changedCell || animNow || wasAnimating) {   // wasAnimating: un último ajuste al terminar
      if (viewingPlayerFloor()) camera.follow(player.px(), player.py());
      lastRow = player.row;
      lastCol = player.col;
    }
    wasAnimating = animNow;

    if (level.completed && !progressSaved) {
      progress.markCompleted(level.id);
      progressSaved = true;
    }
  }

  void updateHint() {
    GameObject t = attempted ? player.interactTarget(level) : null;
    hintLive = t != null;
    if (hintLive) {
      hintObj = t;
      hintUntil = millis() + HINT_LINGER_MS;
    } else if (hintObj != null && millis() >= hintUntil) {
      hintObj = null;
    }
  }

  // Objeto bajo el mouse que merece resaltarse (solo con el mapa a la vista y sin arrastrarlo).
  // A diferencia de la caja de «en rango», esta no espera al primer «Correr»: pasar el mouse
  // es una acción del jugador, no una pista automática.
  void updateHover() {
    hoverObj = null;
    if (clock.isActive() || noteViewer.isOpen() || camera.dragging) return;
    if (!mapArea.containsMouse() || floorSelector.over(level)) return;

    // Se mira el piso que se está viendo, no necesariamente el del personaje
    int realFloor = level.floor;
    level.setFloor(viewFloor);
    int[] rc = camera.tileAt(mouseX, mouseY);
    if (level.inBounds(rc[0], rc[1])) {
      GameObject o = level.objectAt(rc[0], rc[1]);
      if (o != null && o.hoverable(level)) hoverObj = o;
    }
    level.setFloor(realFloor);
  }

  float hintAlpha() {
    if (hintObj == null) return 0;
    if (hintLive) return 1;
    return constrain((hintUntil - millis()) / (float) HINT_LINGER_MS, 0, 1);
  }

  void draw() {
    if (transMode == 3) {            // reloj de apertura: solo, a pantalla completa
      clock.draw();
      cursor(ARROW);
      return;
    }

    // La caja de «en rango» pertenece al piso del personaje: no se dibuja al mirar otro
    renderer.hintObj = viewingPlayerFloor() ? hintObj : null;
    renderer.hintAlpha = hintAlpha();
    renderer.hoverObj = hoverObj;

    if (noteViewer.isOpen()) {
      // Con una nota abierta, su contenido reemplaza al mapa
      noteViewer.draw();
    } else {
      camera.begin();
      int realFloor = level.floor;
      level.setFloor(viewFloor);            // el renderer dibuja el piso que se está viendo
      renderer.draw(level, camera);
      level.setFloor(realFloor);
      if (viewingPlayerFloor()) {
        player.draw();
        player.drawCarrying(level.dishesCarried);
      }
      camera.end();
      if (!viewingPlayerFloor()) {          // velo suave: «esto es otro piso, el personaje no está aquí»
        pushStyle();
        noStroke();
        fill(COL_NAVY, 80);
        rect(mapArea.x, mapArea.y, mapArea.w, mapArea.h);
        popStyle();
      }
      floorSelector.draw(level, viewFloor);
      drawBanner();
      if (showNext()) nextBtn.draw();
    }

    float eT = elemShown(0), eM = elemShown(1), eP = elemShown(2);
    if (eM < 1) {                      // el mapa aparece / se desvanece
      pushStyle();
      noStroke();
      fill(COL_NAVY, 255 * (1 - eM));
      rect(mapArea.x, mapArea.y, mapArea.w, mapArea.h);
      popStyle();
    }

    pushMatrix();
    translate(-(taskArea.x + taskArea.w + 12) * (1 - eT), 0);
    taskPanel.draw();
    popMatrix();

    pushMatrix();
    translate((WINDOW_W - progArea.x + 12) * (1 - eP), 0);
    panel.draw();
    menuBtn.draw();
    popMatrix();

    if (transMode != 0) cursor(ARROW);
    else updateCursor();
  }

  // Cursor según lo que se pueda arrastrar bajo el mouse.
  void updateCursor() {
    int c = ARROW;
    if (showNext() && nextBtn.hover()) {
      c = HAND;
    } else if (!clock.isActive() && !noteViewer.isOpen() && floorSelector.over(level)) {
      c = HAND;
    } else if (noteViewer.isOpen()) {
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
  // Franja navy con una línea de color arriba: cian (aviso), rosa (caída) o verde (completado).
  void drawBanner() {
    String msg = "";
    color accent = COL_CYAN;
    color ink = COL_WHITE;
    if (level.completed) {
      msg = isTutorial() ? "¡Tutorial completado!" : "¡Nivel completado!";
      accent = COL_GREEN;
      ink = COL_GREEN_SOFT;
    } else if (player.fell) {
      msg = "Caíste en un hueco. Pulsa «Correr» para reintentar.";
      accent = COL_PINK;
      ink = COL_PINK;
    } else {
      msg = level.activeMessage();
    }
    if (msg.length() == 0) {
      // Sin avisos, los tutoriales muestran su ayuda
      if (level.hint.length() > 0) drawTutorialHint(level.hint);
      return;
    }

    pushStyle();
    float bh = 34;
    float top = mapArea.y + mapArea.h - bh;
    noStroke();
    fill(COL_SCREEN, 235);
    rect(mapArea.x, top, mapArea.w, bh);
    fill(accent);
    rect(mapArea.x, top, mapArea.w, 2);
    fill(ink);
    textAlign(CENTER, CENTER);
    textSize(13);
    text(msg, mapArea.x + mapArea.w / 2.0, top + bh / 2.0 + 1);
    popStyle();
  }

  // Ayuda de un tutorial: franja con texto ajustado al ancho, pegada al borde inferior del mapa.
  void drawTutorialHint(String s) {
    pushStyle();
    textSize(13);
    ArrayList<String> lines = wrapText(s, mapArea.w - 24);
    float lh = 17;
    float bh = lines.size() * lh + 16;
    float top = mapArea.y + mapArea.h - bh;
    noStroke();
    fill(COL_SCREEN, 235);
    rect(mapArea.x, top, mapArea.w, bh);
    fill(COL_CYAN);
    rect(mapArea.x, top, mapArea.w, 2);
    fill(COL_WHITE);
    textAlign(LEFT, TOP);
    for (int i = 0; i < lines.size(); i++) {
      text(lines.get(i), mapArea.x + 12, top + 9 + i * lh);
    }
    popStyle();
  }

  // ----- Entrada -----
  // Con el reloj o una nota abiertos solo responden: el botón de cerrar (o saltar), «Menú» y los desplazamientos.
  void mousePressed() {
    if (transMode == 3) {            // reloj de apertura: un click lo salta
      clock.skip();
      return;
    }
    if (transMode != 0) {            // un click salta la animación
      transStart = millis() - transDur - 1;
      return;
    }
    if (menuBtn.clicked()) {
      beginLeave(1, 400);
      return;
    }
    if (clock.isActive()) {
      clock.skip();
      return;
    }
    if (noteViewer.isOpen()) {
      noteViewer.mousePressed();
      return;
    }
    if (showNext() && nextBtn.clicked()) {
      goNext();
      return;
    }
    int picked = floorSelector.mousePressed(level, viewFloor);   // lista desplegable de pisos
    if (picked >= 0) {
      if (picked != viewFloor) setViewFloor(picked);
      return;
    }
    if (camera.mousePressed()) return;   // click sobre el mapa = empieza arrastre
    panel.mousePressed();
  }

  void mouseDragged() {
    if (transMode != 0) return;
    camera.mouseDragged();
    panel.mouseDragged();
    noteViewer.mouseDragged();
  }

  void mouseReleased() {
    if (transMode != 0) return;
    camera.mouseReleased();
    panel.mouseReleased();
    noteViewer.mouseReleased();
  }

  void mouseWheel(int amount) {
    if (transMode != 0) return;
    taskPanel.mouseWheel(amount);
    panel.mouseWheel(amount);
    noteViewer.mouseWheel(amount);
  }

  // Movimiento manual con flechas / WASD y E para interactuar (útil para probar niveles)
  void keyPressed() {
    if (transMode == 3) {
      if (key == ENTER || key == RETURN || key == ' ') clock.skip();
      return;
    }
    if (transMode != 0) return;
    if (clock.isActive()) {
      if (key == ENTER || key == RETURN || key == ' ') clock.skip();
      return;
    }
    if (noteViewer.isOpen()) {
      noteViewer.keyPressed();
      return;
    }

    if (showNext() && (key == ENTER || key == RETURN)) {
      goNext();
      return;
    }
    
    if (FreeMove) {
      if (keyCode == 'T') FreeMove = false;
      
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
    else if (keyCode == 'T') FreeMove = true;

  }
}
