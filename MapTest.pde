HashMap<Character, int[]> Colors = new HashMap<Character, int[]>() {{
  put(' ', new int[]{0, 255, 0});
  put('W', new int[]{158, 127, 89});
  put('D', new int[]{182, 184, 171});
  put('H', new int[]{0, 0, 0});
  put('G', new int[]{255, 231, 71});
}};

char[][] Map1 = {{' ', ' ', ' ', ' ', 'W', ' ', ' ', ' '},
                 {'W', 'W', 'W', ' ', 'W', ' ', ' ', ' '},
                 {' ', ' ', ' ', ' ', 'W', 'D', 'W', ' '},
                 {' ', 'W', 'W', 'W', 'W', ' ', 'W', ' '},
                 {' ', ' ', ' ', ' ', ' ', ' ', 'H', ' '},
                 {' ', ' ', ' ', ' ', ' ', ' ', 'H', ' '},
                 {' ', ' ', ' ', ' ', 'W', 'W', 'W', ' '},
                 {' ', ' ', ' ', ' ', 'W', ' ', ' ', 'G'}};

int[] Pos = {0, 0};

int tileSize = 60;

float mapPixelW, mapPixelH;
boolean needsScrollX, needsScrollY;

float offsetX = 0, offsetY = 0;

boolean dragging = false;
float dragStartX, dragStartY;
float offsetStartX, offsetStartY;

int shadowSize = 25;
void setup() {
  size(400, 400);

  int cols = Map1[0].length;
  int rows = Map1.length;

  mapPixelW = tileSize * cols;
  mapPixelH = tileSize * rows;

  needsScrollX = mapPixelW > width;
  needsScrollY = mapPixelH > height;
}

void draw() {
  background(255);

  pushMatrix();
  translate(-offsetX, -offsetY);

  stroke(0, 60);
  strokeWeight(1);

  for (int fila = 0; fila < Map1.length; fila++) {
    for (int col = 0; col < Map1[fila].length; col++) {

      char simbolo = Map1[fila][col];
      int[] c = Colors.get(simbolo);

      fill(c[0], c[1], c[2]);
      rect(col * tileSize, fila * tileSize, tileSize, tileSize);
    }
  }

  noStroke();

  popMatrix();

  drawEdgeShadows();
  updateCursor();
}

void drawEdgeShadows() {
  // Izquierda: hay mapa oculto a la izquierda
  if (needsScrollX && offsetX > 0) {
    drawGradient(0, 0, shadowSize, height, true, false);
  }
  // Derecha
  if (needsScrollX && offsetX < mapPixelW - width) {
    drawGradient(width - shadowSize, 0, shadowSize, height, true, true);
  }
  // Arriba
  if (needsScrollY && offsetY > 0) {
    drawGradient(0, 0, width, shadowSize, false, false);
  }
  // Abajo
  if (needsScrollY && offsetY < mapPixelH - height) {
    drawGradient(0, height - shadowSize, width, shadowSize, false, true);
  }
}

// horizontal=true => gradiente varía en X, si no, en Y
// reversed=true => el lado oscuro queda hacia el borde opuesto (derecha/abajo)
void drawGradient(float x, float y, float w, float h, boolean horizontal, boolean reversed) {
  noFill();
  int steps = (int) (horizontal ? w : h);
  for (int i = 0; i < steps; i++) {
    float t = i / (float) steps;
    float alpha = reversed ? lerp(0, 70, t) : lerp(70, 0, t);
    stroke(0, alpha);
    if (horizontal) {
      line(x + i, y, x + i, y + h);
    } else {
      line(x, y + i, x + w, y + i);
    }
  }
  noStroke();
}

void updateCursor() {
  boolean overMap = mouseX >= 0 && mouseX <= width && mouseY >= 0 && mouseY <= height;
  boolean canScroll = (needsScrollX || needsScrollY) && overMap;

  if (canScroll) {
    cursor(HAND);
    if (dragging) {
      cursor(MOVE);
    }
  } else {
    cursor(ARROW);
  }
}

void mousePressed() {
  dragging = true;
  dragStartX = mouseX;
  dragStartY = mouseY;
  offsetStartX = offsetX;
  offsetStartY = offsetY;
}

void mouseDragged() {
  if (!dragging) return;

  if (needsScrollX) {
    offsetX = offsetStartX - (mouseX - dragStartX);
    offsetX = constrain(offsetX, 0, mapPixelW - width);
  }
  if (needsScrollY) {
    offsetY = offsetStartY - (mouseY - dragStartY);
    offsetY = constrain(offsetY, 0, mapPixelH - height);
  }
}

void mouseReleased() {
  dragging = false;
}
