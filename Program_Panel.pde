// ============================================================
//  Program_Panel.pde — Interfaz del panel de programación
//  Paleta de acciones, lista apilada con scroll (▲ ▼ ✕ por fila) y
//  botones Limpiar / Correr. Solo edita el Program; no ejecuta nada.
//  Cada fila reacciona al mouse (hover) y se SELECCIONA al hacer clic sobre ella (otro clic en
//  la misma la suelta). Al moverla con ▲/▼ la selección la acompaña, para no perderla de vista.
// ============================================================

class ProgramPanel {
  Rect area;
  Program program;
  ProgramRunner runner;
  LevelScreen owner;       // a quién avisar al pulsar "Correr"

  // Layout
  int paletteGap = 12;
  int paletteCols = 4;
  int stackStartYOffset = 90;   // debajo de la paleta, relativo al panel
  int itemH = 34;
  int itemGap = 6;
  int stackBottomMargin = 20;   // separación respecto de los botones inferiores
  int rowBtn = 22;              // tamaño de los botones ▲▼✕ de cada fila
  int bottomBtnH = 40;
  int bottomBtnGap = 10;

  float stackScrollY = 0;       // desplazamiento actual (lo que se ve)
  float scrollTarget = 0;       // hacia dónde se desliza suavemente (seguimiento automático)
  int followedStep = -1;        // último paso en ejecución que ya se siguió
  boolean dragging = false;     // arrastre con click sostenido sobre la lista
  float dragStartY, dragScrollStart;
  UIButton clearBtn, runBtn;
  int selectedIndex = -1;       // fila seleccionada (-1 = ninguna)
  int pressIndex = -1;          // fila sobre la que se pulsó el mouse (para distinguir clic de arrastre)

  ProgramPanel(Rect area, Program program, ProgramRunner runner, LevelScreen owner) {
    this.area = area;
    this.program = program;
    this.runner = runner;
    this.owner = owner;

    float bx = area.x + 15;
    float bw = area.w - 30;

    clearBtn = new UIButton(bx, area.y + area.h - bottomBtnH * 2 - bottomBtnGap - 15, bw, bottomBtnH, "Limpiar todo");
    clearBtn.danger();

    runBtn = new UIButton(bx, area.y + area.h - bottomBtnH - 15, bw, bottomBtnH, "Correr");
    runBtn.primary();
    runBtn.playIcon = true;
    runBtn.textSz = 12;
  }

  void refreshButtons() {
    clearBtn.enabled = !runner.running && !program.isEmpty();
    runBtn.enabled = !runner.running;
    runBtn.label = runner.running ? "Ejecutando..." : "Correr";
    runBtn.playIcon = !runner.running;
  }

  // ----- Geometría de la lista -----
  int stackX() { return (int) area.x + 15; }
  int stackY() { return (int) area.y + stackStartYOffset; }
  int stackW() { return (int) area.w - 30; }
  int stackH() { return (int) area.h - stackStartYOffset - (bottomBtnH * 2 + bottomBtnGap) - stackBottomMargin; }
  int stackContentH() { return program.size() * (itemH + itemGap); }
  int maxScroll() { return max(0, stackContentH() - stackH()); }
  int scrollPx() { return round(stackScrollY); }   // entero: evita texto borroso al dibujar
  void clampScroll() {
    stackScrollY = constrain(stackScrollY, 0, maxScroll());
    scrollTarget = constrain(scrollTarget, 0, maxScroll());
  }
  boolean overStack() {
    int ax = stackX(), ay = stackY(), aw = stackW(), ah = stackH();
    return mouseX >= ax && mouseX <= ax + aw && mouseY >= ay && mouseY <= ay + ah;
  }
  // Fila bajo el mouse (-1 si no hay: fuera de la lista, o en el hueco entre filas).
  int rowAt() {
    if (!overStack()) return -1;
    float contentY = mouseY - stackY() + scrollPx();
    int index = (int) (contentY / (itemH + itemGap));
    if (contentY < 0 || index < 0 || index >= program.size()) return -1;
    if (contentY > index * (itemH + itemGap) + itemH) return -1;
    return index;
  }
  boolean canDragHere() { return maxScroll() > 0 && overStack(); }

  // Pide que la fila 'index' quede a la vista, desplazando lo mínimo y con suavidad.
  void ensureVisible(int index) {
    float top = index * (itemH + itemGap);
    float bottom = top + itemH;
    float t = scrollTarget;
    if (top < t) t = top;
    else if (bottom > t + stackH()) t = bottom - stackH() + itemGap;
    scrollTarget = constrain(t, 0, maxScroll());
  }

  // Se llama cada frame: sigue la acción en ejecución y desliza el scroll hacia su destino.
  void update() {
    int cur = runner.running ? runner.currentStep : -1;
    if (cur != followedStep) {
      followedStep = cur;
      if (cur >= 0) ensureVisible(cur);
    }

    if (!dragging) {
      float d = scrollTarget - stackScrollY;
      if (abs(d) < 0.5) stackScrollY = scrollTarget;
      else stackScrollY += d * 0.25;
    }
  }

  float paletteX(int i) { return area.x + 15 + (i % paletteCols) * (PALETTE_BTN_SIZE + paletteGap); }
  float paletteY(int i) { return area.y + 15 + (i / paletteCols) * (PALETTE_BTN_SIZE + paletteGap); }

  // ============================================================
  //  DIBUJO
  // ============================================================
  void draw() {
    refreshButtons();
    pushStyle();

    drawPanelBox(area, COL_SCREEN);

    drawPalette();
    drawStack();
    clearBtn.draw();
    runBtn.draw();

    popStyle();
  }

  void drawPalette() {
    for (int i = 0; i < ACTION_COUNT; i++) {
      float bx = paletteX(i);
      float by = paletteY(i);
      boolean hover = mouseX >= bx && mouseX <= bx + PALETTE_BTN_SIZE &&
                      mouseY >= by && mouseY <= by + PALETTE_BTN_SIZE;

      // El asset ya trae su fondo y borde; al pasar el mouse se tiñe un poco
      image(assets.iconPalette[i], bx, by);
      if (hover) {
        pushStyle();
        noFill();
        stroke(COL_AMBER);
        strokeWeight(2);
        rect(bx - 1, by - 1, PALETTE_BTN_SIZE + 2, PALETTE_BTN_SIZE + 2, 6);
        popStyle();
      }

      if (i == ACT_INTERACT && owner.hintAlpha() > 0) {
        pushStyle();
        noFill();
        stroke(red(hintColor), green(hintColor), blue(hintColor), 255 * owner.hintAlpha());
        strokeWeight(3);
        rect(bx - 3, by - 3, PALETTE_BTN_SIZE + 6, PALETTE_BTN_SIZE + 6, 8);
        popStyle();
      }
    }
  }

  void drawStack() {
    int ax = stackX(), ay = stackY(), aw = stackW(), ah = stackH();

    pushStyle();
    pushMatrix();

    fill(COL_WELL);
    stroke(COL_SLATE_EDGE);
    strokeWeight(1);
    rect(ax, ay, aw, ah);

    clip(ax, ay, aw, ah);
    translate(0, -scrollPx());

    textAlign(LEFT, CENTER);
    textSize(13);

    if (selectedIndex >= program.size()) selectedIndex = -1;
    int hoverRow = rowAt();

    for (int i = 0; i < program.size(); i++) {
      int iy = ay + i * (itemH + itemGap);
      int action = program.get(i);
      boolean isCurrent = runner.running && i == runner.currentStep;
      boolean isSelected = i == selectedIndex;
      boolean isHover = !runner.running && !dragging && i == hoverRow;

      // Prioridad: en ejecución (ámbar) > seleccionada (cian) > bajo el mouse > normal
      if (isCurrent)       fill(COL_AMBER);
      else if (isSelected) fill(color(28, 62, 92));
      else if (isHover)    fill(color(30, 52, 84));
      else                 fill(COL_SLATE);
      if (isCurrent) {
        stroke(COL_AMBER_EDGE);
        strokeWeight(1.5);
      } else if (isSelected) {
        stroke(COL_CYAN);
        strokeWeight(2.5);
      } else {
        stroke(isHover ? COL_CYAN : COL_SLATE_EDGE);
        strokeWeight(isHover ? 2 : 1.5);
      }
      rect(ax, iy, aw, itemH, UI_ROW_RADIUS);
      if (isSelected && !isCurrent) {   // barra lateral: se ve incluso de reojo
        noStroke();
        fill(COL_CYAN);
        rect(ax, iy, 5, itemH, UI_ROW_RADIUS, 0, 0, UI_ROW_RADIUS);
      }

      fill(isCurrent ? COL_NAVY : COL_MUTED);
      text((i + 1) + ".", ax + 10, iy + itemH / 2.0);
      image(assets.iconRow[action], ax + 34, iy + (itemH - ROW_ICON_SIZE) / 2.0);
      fill(isCurrent ? COL_NAVY : (isSelected ? COL_WHITE : COL_TEXT_SOFT));
      text(ACTION_LABELS[action], ax + 34 + ROW_ICON_SIZE + 8, iy + itemH / 2.0);

      float by = iy + (itemH - rowBtn) / 2.0;
      drawRowButton(ax + aw - rowBtn * 3 - 6, by, "▲", i > 0);
      drawRowButton(ax + aw - rowBtn * 2 - 3, by, "▼", i < program.size() - 1);
      drawRowButton(ax + aw - rowBtn, by, "✕", true);
    }

    noClip();
    popMatrix();

    // Marco por encima del clip
    noFill();
    stroke(COL_CYAN, 110);
    strokeWeight(1.5);
    rect(ax, ay, aw, ah);

    // Indicador de scroll
    if (maxScroll() > 0) {
      float frac = stackScrollY / (float) maxScroll();
      int barH = max(20, (int) (ah * (ah / (float) stackContentH())));
      int barY = ay + (int) ((ah - barH) * frac);
      fill(COL_MUTED);
      noStroke();
      rect(ax + aw - 4, barY, 3, barH, 2);
    }

    popStyle();
  }

  void drawRowButton(float bx, float by, String icon, boolean enabled) {
    pushStyle();
    // El dibujo ya está trasladado por el scroll: el mouse se compara en coordenadas de la lista
    boolean over = enabled && !runner.running && overStack() &&
                   mouseX >= bx && mouseX <= bx + rowBtn &&
                   mouseY + scrollPx() >= by && mouseY + scrollPx() <= by + rowBtn;
    boolean del = icon.equals("✕");                       // ✕ es destructivo: rosa; ▲▼ en cian
    color accent = del ? COL_PINK : COL_CYAN;
    fill(!enabled ? COL_WELL : (over ? (del ? color(61, 45, 70) : COL_SLATE) : COL_SCREEN));
    stroke(!enabled ? COL_SLATE_EDGE : (over ? (del ? COL_PINK_LIGHT : COL_WHITE) : accent));
    strokeWeight(1);
    rect(bx, by, rowBtn, rowBtn, 4);

    fill(enabled ? accent : COL_MUTED);
    textAlign(CENTER, CENTER);
    textSize(11);
    text(icon, bx + rowBtn / 2.0, by + rowBtn / 2.0);
    popStyle();
  }

  // ============================================================
  //  ENTRADA
  // ============================================================
  void mousePressed() {
    // Mientras corre no se edita la secuencia, pero sí se puede arrastrar la lista para mirarla
    if (runner.running) {
      pressIndex = -1;
      if (overStack()) beginDrag();
      return;
    }
    refreshButtons();

    // Paleta: añade la acción al final y la deja a la vista
    for (int i = 0; i < ACTION_COUNT; i++) {
      float bx = paletteX(i);
      float by = paletteY(i);
      if (mouseX >= bx && mouseX <= bx + PALETTE_BTN_SIZE &&
          mouseY >= by && mouseY <= by + PALETTE_BTN_SIZE) {
        program.add(i);
        ensureVisible(program.size() - 1);
        return;
      }
    }

    if (handleStackClick()) return;

    // Click en la lista que no cayó en un botón de fila: puede ser un clic (selecciona la fila,
    // se resuelve al soltar) o el inicio de un arrastre para desplazar la lista
    if (overStack()) {
      pressIndex = rowAt();
      beginDrag();
      return;
    }

    if (clearBtn.clicked()) {
      selectedIndex = -1;
      program.clear();
      stackScrollY = 0;
      scrollTarget = 0;
      return;
    }

    if (runBtn.clicked()) {
      selectedIndex = -1;
      owner.startRun();
    }
  }

  // ----- Arrastre de la lista con click sostenido -----
  void beginDrag() {
    dragging = true;
    dragStartY = mouseY;
    dragScrollStart = stackScrollY;
  }

  void mouseDragged() {
    if (!dragging) return;
    stackScrollY = constrain(dragScrollStart - (mouseY - dragStartY), 0, maxScroll());
    scrollTarget = stackScrollY;   // el seguimiento automático no debe "tirar" de vuelta
  }

  void mouseReleased() {
    // Soltar casi donde se pulsó = clic: selecciona la fila (o la suelta si ya lo estaba; en vacío, suelta)
    if (dragging && !runner.running && abs(mouseY - dragStartY) < 5) {
      selectedIndex = (pressIndex >= 0 && pressIndex != selectedIndex) ? pressIndex : -1;
    }
    pressIndex = -1;
    dragging = false;
  }

  // Clicks en ▲▼✕ de cada fila, considerando scroll y clip.
  boolean handleStackClick() {
    int ax = stackX(), ay = stackY(), aw = stackW(), ah = stackH();
    if (mouseX < ax || mouseX > ax + aw || mouseY < ay || mouseY > ay + ah) return false;

    float contentY = mouseY - ay + scrollPx();
    int index = (int) (contentY / (itemH + itemGap));
    if (index < 0 || index >= program.size()) return false;

    float rowTop = index * (itemH + itemGap);
    if (contentY < rowTop || contentY > rowTop + itemH) return false; // cayó en el hueco entre filas

    float btnUpX = ax + aw - rowBtn * 3 - 6;
    float btnDownX = ax + aw - rowBtn * 2 - 3;
    float btnDelX = ax + aw - rowBtn;

    if (mouseX >= btnUpX && mouseX <= btnUpX + rowBtn) {
      if (index > 0) {
        program.swap(index, index - 1);
        selectedIndex = index - 1;      // la selección acompaña a la acción movida
        ensureVisible(index - 1);
      }
      return true;
    }
    if (mouseX >= btnDownX && mouseX <= btnDownX + rowBtn) {
      if (index < program.size() - 1) {
        program.swap(index, index + 1);
        selectedIndex = index + 1;
        ensureVisible(index + 1);
      }
      return true;
    }
    if (mouseX >= btnDelX && mouseX <= btnDelX + rowBtn) {
      program.removeAt(index);
      selectedIndex = -1;
      clampScroll();
      return true;
    }
    return false;
  }

  void mouseWheel(int amount) {
    if (!overStack()) return;
    stackScrollY += amount * 20;
    clampScroll();
    scrollTarget = stackScrollY;
  }
}
