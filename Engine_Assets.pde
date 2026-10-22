// ============================================================
//  Engine_Assets.pde — Carga de texturas y utilidades de imagen
//  Las imágenes viven en data/Assets/tiles y data/Assets/ui.
//  Todo se escala UNA vez al cargar (vecino más cercano, píxel art nítido).
// ============================================================

// Bits de la máscara de vecinos (ver Engine_Tiles.pde)
final int N_BIT = 1;
final int E_BIT = 2;
final int S_BIT = 4;
final int W_BIT = 8;

class Assets {
  PImage floor, door, doorVertical, computer, note, buttonPressed, buttonUnpressed;
  PImage bed, bedMess, dishDirty, sink, stairUp, stairDown, waterClean, waterDirty;
  PImage[] computerRot = new PImage[4];   // computadora girada: índice = vueltas de 90° en sentido horario
  PImage[] stairUpRot = new PImage[4];
  PImage[] stairDownRot = new PImage[4];
  PImage playerFace, playerFaceIcon;      // cara del personaje (Assets/skin/Face.png), grande y para el selector de pisos
  PImage[] grime = new PImage[4];        // 4 variantes; cada suciedad elige una al azar
  PImage[] wallByMask = new PImage[16];   // indexada por máscara de vecinos
  PImage[] holeByMask = new PImage[16];

  // Íconos de acciones, en el orden de ACT_FORWARD, ACT_TURN_LEFT, ACT_TURN_RIGHT, ACT_INTERACT
  PImage[] iconPalette = new PImage[4];
  PImage[] iconRow = new PImage[4];

  void load() {
    String t = "Assets/tiles/";

    floor           = loadTile(t + "Floor.png");
    door            = loadTile(t + "Door.png");
    computer        = loadTile(t + "Computer.png");   // la meta usa el asset de computadora
    note            = loadTile(t + "Note.png");       // reservada para uso futuro
    buttonPressed   = loadTile(t + "ButtonPressed.png");
    buttonUnpressed = loadTile(t + "ButtonUnpressed.png");

    // Door.png es una barra horizontal (para paredes E-W): la versión girada sirve para paredes N-S
    doorVertical    = scaleNearest(rotateCW(loadImage(t + "Door.png")), TILE_SIZE);

    // ----- Tareas domésticas -----
    bed         = loadTile(t + "Bed.png");          // cama ordenada
    bedMess     = loadTile(t + "BedMess.png");      // cama desordenada
    dishDirty   = loadTile(t + "DishDirty.png");
    sink        = loadTile(t + "Sink.png");
    stairUp     = loadTile(t + "StairUp.png");
    stairDown   = loadTile(t + "StairDown.png");
    waterClean  = loadTile(t + "WaterClean.png");
    waterDirty  = loadTile(t + "WaterDirty.png");
    // ----- Personaje: la cara se escala para caber dentro de su círculo (casi el diámetro completo) -----
    PImage face = loadImage("Assets/skin/Face.png");
    playerFace     = scaleNearest(face, round(TILE_SIZE * PLAYER_RADIUS_K * 2 * PLAYER_FACE_FILL));
    playerFaceIcon = scaleNearest(face, 20);

    computerRot  = rotations(computer);
    stairUpRot   = rotations(stairUp);
    stairDownRot = rotations(stairDown);
    for (int i = 0; i < grime.length; i++) {
      grime[i] = loadTile(t + "Grime" + (i + 1) + ".png");
    }

    // ----- Paredes: sprites SIN fondo (solo la banda gris), se dibujan sobre el suelo -----
    // Cada uno con los lados "abiertos" (conectados) que tiene la imagen base:
    //   Wall1: E+W (recta)   Wall2: N+W (esquina)   Wall3: N+E+W (T)   Wall4: los 4 (cruz)
    // registerRotations() añade las versiones giradas 90/180/270°.
    registerRotations(wallByMask, loadImage(t + "Wall1.png"), E_BIT | W_BIT);
    registerRotations(wallByMask, loadImage(t + "Wall2.png"), N_BIT | W_BIT);
    registerRotations(wallByMask, loadImage(t + "Wall3.png"), N_BIT | E_BIT | W_BIT);
    registerRotations(wallByMask, loadImage(t + "Wall4.png"), N_BIT | E_BIT | S_BIT | W_BIT);

    // Un solo vecino: Wall1 alineada con ese vecino. Sin vecinos: Wall1 por ahora.
    wallByMask[N_BIT] = wallByMask[S_BIT] = wallByMask[N_BIT | S_BIT];
    wallByMask[E_BIT] = wallByMask[W_BIT] = wallByMask[E_BIT | W_BIT];
    wallByMask[0] = wallByMask[E_BIT | W_BIT];

    // ----- Huecos -----
    //   hole1: sin vecinos   hole2: N   hole3: N+S   hole4: N+E   hole5: N+E+S   hole6: 4 vecinos
    registerRotations(holeByMask, loadImage(t + "Hole1.png"), 0);
    registerRotations(holeByMask, loadImage(t + "Hole2.png"), N_BIT);
    registerRotations(holeByMask, loadImage(t + "Hole3.png"), N_BIT | S_BIT);
    registerRotations(holeByMask, loadImage(t + "Hole4.png"), N_BIT | E_BIT);
    registerRotations(holeByMask, loadImage(t + "Hole5.png"), N_BIT | E_BIT | S_BIT);
    registerRotations(holeByMask, loadImage(t + "Hole6.png"), N_BIT | E_BIT | S_BIT | W_BIT);

    // ----- Íconos de la interfaz -----
    String[] iconFiles = {"step.png", "counterclockwise.png", "clockwise.png", "action.png"};
    for (int i = 0; i < iconFiles.length; i++) {
      PImage src = loadImage("Assets/ui/" + iconFiles[i]);
      iconPalette[i] = scaleNearest(src, PALETTE_BTN_SIZE);
      iconRow[i]     = scaleNearest(src, ROW_ICON_SIZE);
    }
  }

  // [original, +90°, +180°, +270°] en sentido horario (los sprites se dibujan mirando hacia ABAJO)
  PImage[] rotations(PImage src) {
    PImage[] r = new PImage[4];
    r[0] = src;
    for (int i = 1; i < 4; i++) r[i] = rotateCW(r[i - 1]);
    return r;
  }

  PImage loadTile(String path) {
    return scaleNearest(loadImage(path), TILE_SIZE);
  }

  // Guarda la imagen base y sus 3 rotaciones (90° horario) en la posición de máscara
  // que les corresponde. No pisa máscaras ya ocupadas (Wall1 girada 180° = Wall1).
  void registerRotations(PImage[] table, PImage base, int baseMask) {
    PImage img = base;
    int mask = baseMask;
    for (int k = 0; k < 4; k++) {
      if (table[mask] == null) {
        table[mask] = scaleNearest(img, TILE_SIZE);
      }
      img = rotateCW(img);
      mask = rotateMaskCW(mask);
    }
  }
}

// Rota los bits de una máscara 90° horario: N→E, E→S, S→W, W→N.
int rotateMaskCW(int m) {
  return ((m << 1) | (m >> 3)) & 15;
}

// Rota una imagen 90° en sentido horario.
PImage rotateCW(PImage src) {
  int w = src.width, h = src.height;
  PImage dst = createImage(h, w, ARGB);
  src.loadPixels();
  dst.loadPixels();
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      dst.pixels[x * h + (h - 1 - y)] = src.pixels[y * w + x];
    }
  }
  dst.updatePixels();
  return dst;
}

// Escala a size×size con vecino más cercano (bordes duros, sin difuminar).
PImage scaleNearest(PImage src, int size) {
  PImage dst = createImage(size, size, ARGB);
  src.loadPixels();
  dst.loadPixels();
  for (int y = 0; y < size; y++) {
    int sy = min(src.height - 1, (int) (y * src.height / (float) size));
    for (int x = 0; x < size; x++) {
      int sx = min(src.width - 1, (int) (x * src.width / (float) size));
      dst.pixels[y * size + x] = src.pixels[sy * src.width + sx];
    }
  }
  dst.updatePixels();
  return dst;
}
