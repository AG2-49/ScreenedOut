// ============================================================
//  UI_FloorSelector.pde — Lista desplegable para MIRAR cualquier piso del nivel
//  Va arriba a la izquierda del mapa (solo si el nivel tiene varios pisos). Cambia únicamente
//  el piso que se VE (LevelScreen.viewFloor); el personaje sigue donde esté. La fila del piso
//  donde está el personaje lleva su carita. Sirve para planear el programa completo sin tener
//  que «Correr» hasta llegar a otro piso. Si el personaje cambia de piso (escaleras), la vista lo sigue.
// ============================================================

class FloorSelector {
  Rect area;               // el mapa: se ancla a su esquina superior izquierda
  boolean open = false;

  final float MARGIN = 8, HEAD_H = 26, ROW_H = 26, GAP = 2, PAD = 10, ICON = 20;

  // Geometría calculada en cada llamada (depende del texto)
  float x, y, w;

  FloorSelector(Rect area) {
    this.area = area;
  }

  String nameOf(Level level, int i) {
    String n = level.floors.get(i).name;
    return n.length() > 0 ? n : "Piso " + (i + 1);
  }

  void layout(Level level) {
    pushStyle();
    textSize(13);
    float maxName = 0;
    for (int i = 0; i < level.floors.size(); i++) maxName = max(maxName, textWidth(nameOf(level, i)));
    popStyle();
    x = area.x + MARGIN;
    y = area.y + MARGIN;
    w = PAD + maxName + 10 + ICON + 10 + 14 + PAD - 10;   // nombre + carita + flecha
  }

  float rowY(int i) { return y + HEAD_H + GAP + i * ROW_H; }

  boolean visible(Level level) {
    return level.hasManyFloors();
  }

  boolean over(Level level) {
    if (!visible(level)) return false;
    layout(level);
    float h = HEAD_H + (open ? GAP + level.floors.size() * ROW_H : 0);
    return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  }

  void draw(Level level, int viewFloor) {
    if (!visible(level)) return;
    layout(level);
    boolean viewingOther = viewFloor != level.floor;

    pushStyle();
    textSize(13);
    textAlign(LEFT, CENTER);

    // ----- Cabecera: piso que se está viendo -----
    boolean headHover = mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + HEAD_H;
    fill(headHover || open ? COL_SLATE : COL_SCREEN, 240);
    stroke(headHover || open ? COL_WHITE : COL_CYAN, 200);
    strokeWeight(1.5);
    rect(x, y, w, HEAD_H, UI_ROW_RADIUS);
    noStroke();
    fill(COL_WHITE);
    text(nameOf(level, viewFloor), x + PAD, y + HEAD_H / 2.0 - 1);
    if (!viewingOther) image(assets.playerFaceIcon, x + w - PAD - 14 - ICON, y + (HEAD_H - ICON) / 2.0);
    textAlign(CENTER, CENTER);
    textSize(10);
    text(open ? "▲" : "▼", x + w - PAD - 2, y + HEAD_H / 2.0);

    // Recordatorio de dónde está el personaje cuando se mira otro piso
    if (viewingOther && !open) {
      textAlign(LEFT, CENTER);
      textSize(11);
      String hint = "Personaje: " + nameOf(level, level.floor);
      float hw = textWidth(hint) + 16;
      fill(COL_SCREEN, 225);
      rect(x, y + HEAD_H + GAP, hw, 20, UI_ROW_RADIUS);
      fill(COL_TEXT_SOFT);
      text(hint, x + 8, y + HEAD_H + GAP + 9);
    }

    // ----- Lista desplegada -----
    if (open) {
      textSize(13);
      for (int i = 0; i < level.floors.size(); i++) {
        float ry = rowY(i);
        boolean hover = mouseX >= x && mouseX <= x + w && mouseY >= ry && mouseY < ry + ROW_H;
        boolean shown = i == viewFloor;
        noStroke();
        if (hover)      fill(COL_AMBER);
        else if (shown) fill(COL_SLATE, 245);
        else            fill(COL_SCREEN, 235);
        rect(x, ry, w, ROW_H - 1, UI_ROW_RADIUS);
        if (shown && !hover) {            // el piso que se está viendo lleva borde cian
          noFill();
          stroke(COL_CYAN, 200);
          strokeWeight(1.5);
          rect(x, ry, w, ROW_H - 1, UI_ROW_RADIUS);
          noStroke();
        }

        textAlign(LEFT, CENTER);
        fill(hover ? COL_NAVY : COL_WHITE);
        text(nameOf(level, i), x + PAD, ry + ROW_H / 2.0 - 1);
        if (i == level.floor) image(assets.playerFaceIcon, x + w - PAD - 14 - ICON, ry + (ROW_H - ICON) / 2.0 - 0.5);
      }
    }
    popStyle();
  }

  // Devuelve -1 si el clic no era para el selector; si lo era, el piso a mostrar
  // (o `viewFloor` si solo se abrió/cerró la lista). Un clic fuera la cierra y sigue su camino.
  int mousePressed(Level level, int viewFloor) {
    if (!visible(level)) return -1;
    layout(level);

    if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + HEAD_H) {
      open = !open;
      return viewFloor;
    }
    if (open) {
      for (int i = 0; i < level.floors.size(); i++) {
        float ry = rowY(i);
        if (mouseX >= x && mouseX <= x + w && mouseY >= ry && mouseY < ry + ROW_H) {
          open = false;
          return i;
        }
      }
      open = false;     // clic en cualquier otro lado: se cierra
    }
    return -1;
  }
}
