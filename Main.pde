int windowW = 900;
int windowH = 500;

int halfW = windowW / 2; // línea imaginaria que separa mapa / panel de programación
int mapMargin = 20;      // separación entre el marco del mapa y los bordes de su mitad

// Área real donde se dibuja y recorta el mapa (dentro del margen)
int mapAreaX = mapMargin;
int mapAreaY = mapMargin;
int mapAreaW = halfW - mapMargin * 2;
int mapAreaH = windowH - mapMargin * 2;

// Área del panel de programación (con el mismo margen, por simetría visual)
int progAreaX = halfW + mapMargin;
int progAreaY = mapMargin;
int progAreaW = windowW - halfW - mapMargin * 2;
int progAreaH = windowH - mapMargin * 2;

color bgColor = color(245); // fondo único para toda la ventana

float mapPixelW, mapPixelH;
int tileSize = 60;

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

int[] Pos = {0, 0};       // {fila, columna}
float Looking = HALF_PI;  // radianes, 0 = arriba, sentido horario

int[] PosOriginal;        // copia de la posición inicial del nivel
float LookingOriginal;    // copia de la orientación inicial del nivel
char[][] Map1Original;    // copia del mapa inicial (por si 'D' se abre con interact())


void setup() {
  size(900, 500);

  int cols = Map1[0].length;
  int rows = Map1.length;

  mapPixelW = tileSize * cols;
  mapPixelH = tileSize * rows;

  needsScrollX = mapPixelW > mapAreaW;
  needsScrollY = mapPixelH > mapAreaH;

  // Guarda el estado inicial del nivel para poder restaurarlo en cada intento
  PosOriginal = new int[]{Pos[0], Pos[1]};
  LookingOriginal = Looking;

  Map1Original = new char[Map1.length][];
  for (int i = 0; i < Map1.length; i++) {
    Map1Original[i] = Map1[i].clone();
  }
}

void draw() {
  background(bgColor);

  updateRun(); // avanza la ejecución paso a paso si está corriendo

  drawMapPanel();
  drawProgramPanel();

  updateCursor();
}

// ===== PANEL IZQUIERDO: MAPA =====
void drawMapPanel() {
  pushMatrix();
  pushStyle();

  translate(mapAreaX, mapAreaY);
  clip(0, 0, mapAreaW, mapAreaH); // recorta el dibujo del mapa a su área

  translate(-offsetX, -offsetY);

  stroke(0, 60);
  strokeWeight(5);

  for (int fila = 0; fila < Map1.length; fila++) {
    for (int col = 0; col < Map1[fila].length; col++) {

      char simbolo = Map1[fila][col];
      int[] c = Colors.get(simbolo);

      fill(c[0], c[1], c[2]);
      rect(col * tileSize, fila * tileSize, tileSize, tileSize);
    }
  }

  noStroke();

  drawPlayer();

  noClip();
  popStyle();
  popMatrix();

  drawEdgeShadows();

  // Marco alrededor del área del mapa
  pushStyle();
  noFill();
  stroke(0);
  strokeWeight(2);
  rect(mapAreaX, mapAreaY, mapAreaW, mapAreaH);
  popStyle();
}

// Restaura Pos, Looking, fell y el mapa a su estado inicial.
// Se llama al presionar "Correr", para que cada intento empiece limpio.
void resetToStart() {
  Pos[0] = PosOriginal[0];
  Pos[1] = PosOriginal[1];
  Looking = LookingOriginal;
  fell = false;

  for (int i = 0; i < Map1.length; i++) {
    Map1[i] = Map1Original[i].clone();
  }

  offsetX = 0;
  offsetY = 0;
  followPlayer();
}
