boolean fell = false;

void drawPlayer() {
  float px = Pos[1] * tileSize + tileSize / 2.0; // columna -> x
  float py = Pos[0] * tileSize + tileSize / 2.0; // fila -> y

  pushMatrix();
  translate(px, py);
  rotate(Looking);

  fill(fell ? color(120) : color(255, 0, 0)); // ejemplo simple: se pone gris si cayó
  noStroke();

  float r = tileSize * 0.3; // radio del cuerpo

  ellipse(0, 0, r * 2, r * 2);

  float triLen = r * 1.3;
  float triBase = r * 1.1;

  triangle(
    -triBase / 2, -r * 0.3,
     triBase / 2, -r * 0.3,
     0, -r - triLen + r * 0.3
  );

  popMatrix();
}

// Calcula el ángulo de Looking a partir de un desplazamiento (dx, dy)
// en coordenadas de celda (columna, fila). Convención: 0 = arriba.
void setLookingFromDelta(int dx, int dy) {
  if (dx == 0 && dy == 0) return;
  Looking = atan2(dx, -dy);
}

// Convierte el ángulo actual de Looking al par (dx, dy) más cercano
// entre las 4 direcciones cardinales. Útil para "avanzar" según hacia dónde mira.
int[] lookingToDelta() {
  // Normaliza Looking a [0, TWO_PI)
  float a = Looking % TWO_PI;
  if (a < 0) a += TWO_PI;

  // Redondea al múltiplo de 90° más cercano (0=arriba, HALF_PI=derecha, PI=abajo, -HALF_PI/1.5PI=izquierda)
  int octant = round(a / HALF_PI) % 4;

  switch (octant) {
    case 0: return new int[]{0, -1};  // arriba
    case 1: return new int[]{1, 0};   // derecha
    case 2: return new int[]{0, 1};   // abajo
    case 3: return new int[]{-1, 0};  // izquierda
    default: return new int[]{0, 0};
  }
}

// Intenta mover al jugador según (dx, dy) en celdas.
// Revisa el tipo de casilla destino y decide qué hacer.
void tryMove(int dx, int dy) {
  if (fell) return; // si ya cayó, no se mueve más (ajusta a tu gusto)

  int nextRow = Pos[0] + dy;
  int nextCol = Pos[1] + dx;

  // Fuera del mapa: no hacer nada
  if (nextRow < 0 || nextRow >= Map1.length ||
      nextCol < 0 || nextCol >= Map1[0].length) {
    return;
  }

  char destino = Map1[nextRow][nextCol];

  switch (destino) {
    case 'W':
      // Choca contra el muro: no se mueve, pero sí actualiza hacia dónde mira
      setLookingFromDelta(dx, dy);
      return;

    case 'H':
      // Cae en el hueco: se mueve a esa celda y queda marcado como caído
      Pos[0] = nextRow;
      Pos[1] = nextCol;
      setLookingFromDelta(dx, dy);
      fell = true;
      onFall();
      followPlayer();
      return;

    default:
      // Resto de casillas (' ', 'D', 'G', ...): movimiento libre por ahora
      Pos[0] = nextRow;
      Pos[1] = nextCol;
      setLookingFromDelta(dx, dy);
      followPlayer();
      return;
  }
}

// ===== Acciones de alto nivel usadas por los bloques de programación =====

// Avanza una celda en la dirección hacia la que el jugador está mirando.
void moveForward() {
  int[] d = lookingToDelta();
  tryMove(d[0], d[1]);
}

// Gira 90° sin moverse. dir: 1 = sentido horario (derecha), -1 = antihorario (izquierda).
void turn(int dir) {
  if (fell) return; // caído: no puede realizar ninguna acción más
  Looking += dir * HALF_PI;
}

// Interactúa con la casilla que tiene justo en frente (sin moverse a ella).
// Despachador por tipo de casilla: aquí es donde se añadirán palancas, NPCs, etc.
void interact() {
  if (fell) return; // caído: no puede realizar ninguna acción más

  int[] d = lookingToDelta();
  int targetRow = Pos[0] + d[1];
  int targetCol = Pos[1] + d[0];

  if (targetRow < 0 || targetRow >= Map1.length ||
      targetCol < 0 || targetCol >= Map1[0].length) {
    return;
  }

  char objetivo = Map1[targetRow][targetCol];

  switch (objetivo) {
    case 'D':
      // Abre la puerta: la convierte en casilla libre
      Map1[targetRow][targetCol] = ' ';
      println("Puerta abierta en fila " + targetRow + ", columna " + targetCol);
      return;

    // Futuro: case 'L' -> palanca, case 'N' -> NPC, etc.

    default:
      // Nada con qué interactuar en esa casilla
      return;
  }
}

// Lo que pase cuando el jugador cae en un hueco.
// De momento solo un print; aquí puedes meter reinicio de nivel, animación, etc.
void onFall() {
  println("¡Caíste en un hueco!");
}

void keyPressed() {
  int dx = 0, dy = 0;

  if (keyCode == RIGHT || keyCode == 'D') dx = 1;
  else if (keyCode == LEFT || keyCode == 'A') dx = -1;
  else if (keyCode == UP || keyCode == 'W') dy = -1;
  else if (keyCode == DOWN || keyCode == 'S') dy = 1;

  if (dx != 0 || dy != 0) {
    tryMove(dx, dy);
  }
}
