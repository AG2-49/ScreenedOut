//   ============================================================
//  Game_Player.pde — Jugador y sus interacciones con el nivel
//  Convención de ángulo: 0 = arriba, sentido horario.
//
//  Estado LÓGICO (row, col, looking): cambia al instante al ejecutar una acción.
//  Estado VISUAL (visX, visY, visLooking): lo que se dibuja; alcanza al lógico con una
//  animación breve de deslizamiento/giro. La lógica nunca espera a la animación.
// ============================================================

class Player {
  int row, col;
  float looking;
  boolean fell = false;

  // ----- Animación (solo visual) -----
  final int MOVE_MS = 260;       // duración de un paso (incluye el giro si lo hay)
  final int TURN_MS = 220;       // duración de un giro en el sitio
  float visX, visY, visLooking;  // posición (centro, en px del mapa) y ángulo dibujados
  float fromX, fromY, fromLooking;
  int animStart = 0, animMs = 1;
  boolean animating = false;

  // Cuánto debe seguir sonando el bucle de pasos tras un paso si no llega otro (ms).
  // El ProgramRunner lo ajusta antes de cada acción: más largo si el siguiente paso también es
  // «Avanzar» (el bucle no se corta entre casillas) y justo lo que dura el paso si es el último.
  int walkHoldMs = MOVE_MS + 150;

  void reset(Level level) {
    level.setFloor(level.startFloor);
    row = level.startRow;
    col = level.startCol;
    looking = level.startLooking;
    fell = false;
    level.markVisited(row, col);
    snapVisual();   // al reiniciar no se anima: se ve la casilla de salida tal cual
  }

  // Salta a otra casilla del piso actual sin animar y mirando hacia 'angle' (lo usan las escaleras).
  void teleportTo(Level level, int newRow, int newCol, float angle) {
    row = newRow;
    col = newCol;
    looking = angle;
    level.markVisited(row, col);
    snapVisual();
  }

  // Coloca lo dibujado exactamente sobre el estado lógico, sin animación.
  void snapVisual() {
    visX = targetX();
    visY = targetY();
    visLooking = looking;
    animating = false;
  }

  float targetX() { return col * TILE_SIZE + TILE_SIZE / 2.0; }
  float targetY() { return row * TILE_SIZE + TILE_SIZE / 2.0; }

  // Centro VISUAL del jugador en coordenadas del mapa (la cámara lo sigue a él)
  float px() { return visX; }
  float py() { return visY; }

  boolean isAnimating() { return animating; }

  // Arranca una animación desde lo que se ve ahora hacia el estado lógico actual.
  void startAnim(int ms) {
    fromX = visX;
    fromY = visY;
    fromLooking = visLooking;
    animStart = millis();
    animMs = ms;
    animating = true;
  }

  // Se llama cada frame.
  void update() {
    if (!animating) return;

    float t = constrain((millis() - animStart) / (float) animMs, 0, 1);
    float e = t * t * (3 - 2 * t);   // suavizado de entrada y salida

    visX = lerp(fromX, targetX(), e);
    visY = lerp(fromY, targetY(), e);
    visLooking = fromLooking + angleDiff(fromLooking, looking) * e;

    if (t >= 1) snapVisual();
  }

  // Giro más corto de a hacia b, en (-PI, PI]. Evita dar la vuelta larga.
  float angleDiff(float a, float b) {
    float d = (b - a) % TWO_PI;
    if (d > PI) d -= TWO_PI;
    if (d < -PI) d += TWO_PI;
    return d;
  }

  // Cabeza = círculo con la cara (siempre derecha, para que se lea) + una flecha en forma de
  // «techo» (^) separada del círculo que gira a su alrededor y marca hacia dónde mira.
  // Todas las medidas y colores se ajustan en Config.pde (PLAYER_*).

  void draw() {
    float r = TILE_SIZE * PLAYER_RADIUS_K;
    color ink = fell ? playerInkFell : playerInk;

    pushMatrix();
    pushStyle();
    translate(px(), py());

    pushMatrix();
    if (PLAYER_FACE_ROTATES) rotate(visLooking);
    stroke(ink);
    strokeWeight(PLAYER_RING_WEIGHT);
    fill(255);
    ellipse(0, 0, r * 2, r * 2);
    imageMode(CENTER);
    if (fell) tint(150);
    image(assets.playerFace, 0, 0);
    noTint();
    popMatrix();

    // Flecha: proporciones del boceto (más ancha que la cara y baja)
    rotate(visLooking);
    noFill();
    stroke(ink);
    strokeWeight(PLAYER_ARROW_WEIGHT);
    strokeJoin(MITER);
    float halfW = r * PLAYER_ARROW_HALF_W, h = r * PLAYER_ARROW_HEIGHT, gap = r * PLAYER_ARROW_GAP;
    beginShape();
    vertex(-halfW, -(r + gap));
    vertex(0, -(r + gap + h));
    vertex(halfW, -(r + gap));
    endShape();

    popStyle();
    popMatrix();
  }

  // Plato(s) en las manos: un platito junto al jugador (no gira con él) y el número si son varios.
  void drawCarrying(int count) {
    if (count <= 0) return;
    pushStyle();
    float s = TILE_SIZE * 0.5;
    float x = px() + TILE_SIZE * 0.12;
    float y = py() - TILE_SIZE * 0.62;
    image(assets.dishDirty, x, y, s, s);
    if (count > 1) {
      fill(30, 50, 100);
      noStroke();
      ellipse(x + s, y + 4, 18, 18);
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(12);
      text(count, x + s, y + 3);
    }
    popStyle();
  }

  // ----- Orientación -----
  void setLookingFromDelta(int dx, int dy) {
    if (dx == 0 && dy == 0) return;
    looking = atan2(dx, -dy);
  }

  // Dirección cardinal más cercana a 'looking' como (dx, dy) en celdas.
  int[] lookingToDelta() {
    float a = looking % TWO_PI;
    if (a < 0) a += TWO_PI;
    switch (round(a / HALF_PI) % 4) {
      case 0:  return new int[]{0, -1};  // arriba
      case 1:  return new int[]{1, 0};   // derecha
      case 2:  return new int[]{0, 1};   // abajo
      default: return new int[]{-1, 0};  // izquierda
    }
  }

  // ----- Movimiento: verifica la casilla destino y decide qué pasa -----
  // Devuelve true si el jugador cambió de casilla.
  boolean tryMove(Level level, int dx, int dy) {
    if (fell) return false;

    int nextRow = row + dy;
    int nextCol = col + dx;
    if (!level.inBounds(nextRow, nextCol)) return false;

    setLookingFromDelta(dx, dy);

    int hold = walkHoldMs;                // se consume: el siguiente paso vuelve al valor por defecto
    walkHoldMs = MOVE_MS + 150;

    // Pared: choca (solo gira hacia ella)
    if (level.terrainAt(nextRow, nextCol) == 'W') {
      startAnim(TURN_MS);
      audio.stopWalk();
      return false;
    }

    // Objeto sólido (p. ej. una puerta cerrada)
    GameObject obj = level.objectAt(nextRow, nextCol);
    if (obj != null && obj.blocksMovement()) {
      startAnim(TURN_MS);
      audio.stopWalk();
      return false;
    }

    row = nextRow;
    col = nextCol;
    startAnim(MOVE_MS);
    level.markVisited(row, col);
    audio.walkStep(hold);

    // Hueco: cae
    if (level.terrainAt(row, col) == 'H') {
      fell = true;
      onFall();
      return true;
    }

    // Lo que haya en la casilla (escaleras...) reacciona al pisarla
    GameObject here = level.objectAt(row, col);
    if (here != null) here.onEnter(level, this);
    return true;
  }

  // ----- Acciones de alto nivel (las usan los comandos programados) -----
  void moveForward(Level level) {
    int[] d = lookingToDelta();
    tryMove(level, d[0], d[1]);
  }

  // dir: 1 = horario (derecha), -1 = antihorario (izquierda)
  void turn(int dir) {
    if (fell) return;
    audio.stopWalk();
    looking += dir * HALF_PI;
    startAnim(TURN_MS);
  }

  GameObject frontObject(Level level) {
    int[] d = lookingToDelta();
    int r = row + d[1], c = col + d[0];
    return level.inBounds(r, c) ? level.objectAt(r, c) : null;
  }

  GameObject underObject(Level level) {
    return level.objectAt(row, col);
  }

  // El objeto que recibiría la interacción: el de enfrente tiene prioridad.
  GameObject interactTarget(Level level) {
    if (fell) return null;
    GameObject front = frontObject(level);
    if (front != null && front.interactive(level)) return front;
    GameObject under = underObject(level);
    if (under != null && under.interactive(level)) return under;
    return null;
  }

  void interact(Level level) {
    audio.stopWalk();
    if (fell) return;

    GameObject target = interactTarget(level);
    if (target != null) {
      target.interact(level);
      return;
    }

    // Nada útil: que respondan igual (avisos, repeticiones), primero el de enfrente
    GameObject front = frontObject(level);
    if (front != null && front.interact(level)) return;
    GameObject under = underObject(level);
    if (under != null && under.interact(level)) level.clearMessage();
  }

  void onFall() {
    audio.stopWalk();
    println("¡Caíste en un hueco!");
  }
}
