// ============================================================
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

  void reset(Level level) {
    row = level.startRow;
    col = level.startCol;
    looking = level.startLooking;
    fell = false;
    snapVisual();   // al reiniciar no se anima: se ve la casilla de salida tal cual
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

  void draw() {
    pushMatrix();
    pushStyle();
    translate(px(), py());
    rotate(visLooking);

    fill(fell ? color(120) : color(255, 0, 0));
    noStroke();

    float r = TILE_SIZE * 0.3; // radio del cuerpo
    ellipse(0, 0, r * 2, r * 2);

    float triLen = r * 1.3;
    float triBase = r * 1.1;
    triangle(
      -triBase / 2, -r * 0.3,
       triBase / 2, -r * 0.3,
       0, -r - triLen + r * 0.3
    );

    popStyle();
    popMatrix();
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

    // Pared: choca (solo gira hacia ella)
    if (level.terrainAt(nextRow, nextCol) == 'W') {
      startAnim(TURN_MS);
      return false;
    }

    // Objeto sólido (p. ej. una puerta cerrada)
    GameObject obj = level.objectAt(nextRow, nextCol);
    if (obj != null && obj.blocksMovement()) {
      startAnim(TURN_MS);
      return false;
    }

    row = nextRow;
    col = nextCol;
    startAnim(MOVE_MS);

    // Hueco: cae
    if (level.terrainAt(row, col) == 'H') {
      fell = true;
      onFall();
    }
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
    looking += dir * HALF_PI;
    startAnim(TURN_MS);
  }

  // Interactúa SIN moverse. Prioridad:
  //   1) el objeto de la casilla donde está parado (nota, botón...),
  //   2) si ese no existe o no hizo nada (p. ej. una puerta ya abierta), el de enfrente.
  // Los objetos con colisión (puerta cerrada) nunca están bajo el jugador, así que no hay casos absurdos.
  void interact(Level level) {
    if (fell) return;

    GameObject under = level.objectAt(row, col);
    if (under != null && under.interact(level)) return;

    int[] d = lookingToDelta();
    int targetRow = row + d[1];
    int targetCol = col + d[0];
    if (!level.inBounds(targetRow, targetCol)) return;

    GameObject front = level.objectAt(targetRow, targetCol);
    if (front != null) front.interact(level);
  }

  void onFall() {
    println("¡Caíste en un hueco!");
  }
}
