// ============================================================
//  Engine_Tiles.pde — Convierte un Level (matriz) en imagen
//
//  Autotiling por máscara de vecinos: cada pared/hueco mira sus 4 vecinos
//  (N, E, S, W); los que sean del mismo tipo suman un bit. Esa máscara (0–15)
//  indexa la tabla de texturas ya rotadas de Assets.
//  Orden de dibujo, por capas:
//    1) suelo en TODAS las casillas
//    2) terreno encima: paredes (sprites sin fondo) y huecos (opacos, tapan el suelo)
//    3) objetos del nivel (puertas, botones, meta...)
// ============================================================

class MapRenderer {
  // ¿Los bordes del mapa cuentan como "vecino"? (false = el borde se ve como vacío)
  boolean edgeCountsAsNeighbor = false;

  // Casilla a resaltar (la fija la pantalla cada frame)
  GameObject hintObj = null;
  float hintAlpha = 0;

  // Se espera que la cámara ya haya aplicado su translate (Camera.begin()).
  void draw(Level level, Camera cam) {
    int firstCol = max(0, floor(cam.offsetX / TILE_SIZE));
    int lastCol  = min(level.cols - 1, floor((cam.offsetX + cam.area.w) / TILE_SIZE));
    int firstRow = max(0, floor(cam.offsetY / TILE_SIZE));
    int lastRow  = min(level.rows - 1, floor((cam.offsetY + cam.area.h) / TILE_SIZE));

    for (int row = firstRow; row <= lastRow; row++) {
      for (int col = firstCol; col <= lastCol; col++) {
        image(assets.floor, col * TILE_SIZE, row * TILE_SIZE);

        PImage overlay = terrainOverlay(level, row, col);
        if (overlay != null) image(overlay, col * TILE_SIZE, row * TILE_SIZE);
      }
    }

    for (GameObject obj : level.objects) {
      obj.draw();
    }

    if (hintObj != null && hintAlpha > 0) drawHint(hintObj);
  }

  void drawHint(GameObject obj) {
    pushStyle();
    noFill();
    stroke(red(hintColor), green(hintColor), blue(hintColor), 255 * hintAlpha);
    strokeWeight(4);
    rect(obj.col * TILE_SIZE + 3, obj.row * TILE_SIZE + 3, TILE_SIZE - 6, TILE_SIZE - 6, 8);
    popStyle();
  }

  // Textura que va SOBRE el suelo en esa casilla (null = solo suelo).
  PImage terrainOverlay(Level level, int row, int col) {
    switch (level.terrainAt(row, col)) {
      case 'W': return assets.wallByMask[neighborMask(level, row, col)];
      case 'H': return assets.holeByMask[neighborMask(level, row, col)];
      default:  return null;
    }
  }

  // ¿La casilla (row, col) se une visualmente con una casilla de terreno 'self'?
  //  - Paredes: se unen a otras paredes y a las puertas, tratándolas como pared.
  //    Se decide por el TIPO de objeto (Door), no por su estado: abrir o cerrar la
  //    puerta no cambia el aspecto de las paredes vecinas.
  //  - Huecos: solo se unen a otros huecos.
  boolean neighborJoins(Level level, char self, int row, int col) {
    if (!level.inBounds(row, col)) return edgeCountsAsNeighbor;
    if (self == 'W' && level.objectAt(row, col) instanceof Door) return true;
    return level.terrainAt(row, col) == self;
  }

  int neighborMask(Level level, int row, int col) {
    char self = level.terrainAt(row, col);
    int m = 0;
    if (neighborJoins(level, self, row - 1, col)) m |= N_BIT;
    if (neighborJoins(level, self, row, col + 1)) m |= E_BIT;
    if (neighborJoins(level, self, row + 1, col)) m |= S_BIT;
    if (neighborJoins(level, self, row, col - 1)) m |= W_BIT;
    return m;
  }
}
