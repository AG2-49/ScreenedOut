// ============================================================
//  UI_TaskPanel.pde — Región de tareas y notas leídas
//  Hoja de papel con cinta, contador de tareas y nota adhesiva.
//  Solo muestra: tareas reveladas y texto de las notas ya leídas. Se desplaza con la rueda.
// ============================================================

class TaskPanel {
  Rect area;
  Level level;

  PFont pixelFont;
  PFont normalFont;      // la letra normal del juego (se guarda en cada draw)
  float normalSize;

  // Paleta (tomada de note.png y del suelo)
  color paper = color(238, 195, 154);
  color rule  = color(217, 160, 102);
  color ink   = color(102, 57, 49);
  color soft  = color(143, 86, 59);    // texto de tareas ya cumplidas

  // Nota adhesiva
  color stickyPaper = color(246, 240, 184);
  color stickyEdge  = color(201, 184, 106);
  color stickyLine  = color(216, 204, 138);
  color stickyInk   = color(95, 70, 25);

  // Casilla cumplida
  color doneFill = color(142, 214, 160);
  color doneEdge = color(47, 122, 74);

  float scrollY = 0;
  float contentH = 0;                  // alto del contenido, medido en el último dibujo

  int pad = 14;
  int lineH = 16;
  int boxSize = 14;

  TaskPanel(Rect area, Level level) {
    this.area = area;
    this.level = level;
    pixelFont = createFont("PressStart2P-Regular.ttf", 32);
  }

  void draw() {
    textSize(g.textSize);
    normalFont = g.textFont;
    normalSize = g.textSize;

    pushStyle();

    // papel
    fill(paper);
    stroke(ink);
    strokeWeight(2);
    rect(area.x, area.y, area.w, area.h);

    if (contentH + 50 < area.h) drawPencil();   // el lápiz solo se ve si sobra espacio

    pushMatrix();
    clip(area.x + 2, area.y + 2, area.w - 4, area.h - 4);
    translate(0, -scrollY);

    float x0 = area.x + pad;
    float w = area.w - pad * 2;
    float y = area.y + pad + 4;    // un poco más abajo por la cinta

    // ----- Tareas -----
    int total = 0, done = 0;
    for (Task t : level.tasks) {
      if (!t.revealed) continue;
      total++;
      if (t.isDone()) done++;
    }
    y = drawHeading("TAREAS", total > 0 ? done + "/" + total : "", x0, y, w);
    for (Task t : level.tasks) {
      if (!t.revealed) continue;
      y = drawTask(t, x0, y, w);
    }
    if (total == 0) y += 6;

    // ----- Notas -----
    if (!level.notes.isEmpty()) {
      y += 10;
      y = drawNotes(x0, y, w);
    }

    contentH = y - area.y + pad;

    noClip();
    popMatrix();

    drawScrollbar();
    drawTape();

    popStyle();
    textFont(normalFont, normalSize);
  }

  // Título con letra pixel y una pastilla con el avance (ej. 1/2)
  float drawHeading(String label, String badge, float x, float y, float w) {
    noStroke();
    textFont(pixelFont);
    textSize(13);
    textAlign(LEFT, CENTER);
    fill(ink);
    text(label, x, y + 12);

    if (badge.length() > 0) {
      fill(ink);
      rect(x + w - 40, y + 3, 40, 18, 9);
      textFont(normalFont, 12);
      textAlign(CENTER, CENTER);
      fill(paper);
      text(badge, x + w - 20, y + 11);
    }

    stroke(rule);
    strokeWeight(2);
    line(x, y + 28, x + w, y + 28);
    return y + 38;
  }

  float drawTask(Task t, float x, float y, float w) {
    boolean done = t.isDone();
    textFont(normalFont, 13);
    ArrayList<String> lines = wrap(t.label(), w - boxSize - 10);
    float h = max(boxSize + 4, lines.size() * lineH);

    // línea roja de margen, entre la casilla y el texto
    stroke(217, 130, 107, 110);
    strokeWeight(1);
    float mx = x + boxSize + 5;
    line(mx, y - 3, mx, y + h + 8);

    // Casilla de verificación
    strokeWeight(1.5);
    if (done) { fill(doneFill); stroke(doneEdge); }
    else      { fill(paper);    stroke(ink); }
    rect(x, y + 1, boxSize, boxSize, 3);
    if (done) {
      stroke(29, 74, 46);
      strokeWeight(2);
      line(x + 3, y + 8, x + 6, y + 11);
      line(x + 6, y + 11, x + 11, y + 4);
    }

    // Texto (tachado si está cumplida)
    textAlign(LEFT, TOP);
    for (int i = 0; i < lines.size(); i++) {
      float ly = y + i * lineH;
      fill(done ? soft : ink);
      noStroke();
      text(lines.get(i), x + boxSize + 10, ly);
      if (done) {
        stroke(soft);
        strokeWeight(1);
        float lw = textWidth(lines.get(i));
        line(x + boxSize + 10, ly + 5, x + boxSize + 10 + lw, ly + 5);
      }
    }

    stroke(rule);
    strokeWeight(1);
    line(x, y + h + 5, x + w, y + h + 5);
    return y + h + 11;
  }

  // Nota adhesiva con chincheta: título "Notas n/m" y el texto de las notas ya leídas
  float drawNotes(float x, float y, float w) {
    textFont(normalFont, 13);

    // primero se mide lo que va dentro
    ArrayList<ArrayList<String>> all = new ArrayList<ArrayList<String>>();
    float inner = w - 20;
    float bodyH = 0;
    for (Note n : level.notes) {
      if (!n.read) continue;
      ArrayList<String> ls = wrap(n.text, inner);
      all.add(ls);
      bodyH += ls.size() * lineH + 11;
    }
    if (all.isEmpty()) bodyH = 3 * 14 + 4;     // renglones de adorno mientras no hay notas leídas
    float h = 44 + bodyH + 8;

    // hoja amarilla
    stroke(stickyEdge);
    strokeWeight(1.5);
    fill(stickyPaper);
    rect(x - 4, y, w + 8, h);

    // chincheta
    stroke(138, 47, 44);
    strokeWeight(1);
    fill(217, 83, 79);
    ellipse(x + w / 2.0, y + 2, 11, 11);

    // título
    noStroke();
    fill(stickyInk);
    textAlign(LEFT, TOP);
    textFont(normalFont, 15);
    text("Notas  " + level.notesRead() + "/" + level.notes.size(), x + 6, y + 14);
    stroke(stickyLine);
    strokeWeight(1);
    line(x + 6, y + 36, x + w - 6, y + 36);

    float cy = y + 44;
    textFont(normalFont, 13);
    textAlign(LEFT, TOP);
    if (all.isEmpty()) {
      stroke(stickyLine);
      for (int i = 0; i < 3; i++) {
        line(x + 6, cy + 6 + i * 14, x + w - 6 - (i == 2 ? 50 : 0), cy + 6 + i * 14);
      }
    } else {
      for (ArrayList<String> ls : all) {
        noStroke();
        fill(stickyInk);
        for (int i = 0; i < ls.size(); i++) {
          text(ls.get(i), x + 10, cy + i * lineH);
        }
        cy += ls.size() * lineH;
        stroke(stickyLine);
        strokeWeight(1);
        line(x + 6, cy + 5, x + w - 6, cy + 5);
        cy += 11;
      }
    }
    return y + h + 6;
  }

  // Cinta adhesiva arriba, por encima del contenido
  void drawTape() {
    pushMatrix();
    translate(area.x + area.w / 2.0, area.y);
    rotate(radians(-2));
    stroke(201, 184, 106);
    strokeWeight(1.5);
    fill(246, 240, 184, 235);
    rect(-26, -9, 52, 18);
    popMatrix();
  }

  void drawPencil() {
    pushMatrix();
    translate(area.x + area.w - 70, area.y + area.h - 26);
    rotate(radians(-18));
    stroke(165, 104, 61);
    strokeWeight(1.2);
    fill(242, 193, 78);
    rect(0, 0, 44, 9);
    fill(239, 196, 154);
    triangle(44, 0, 56, 4.5, 44, 9);
    noStroke();
    fill(58, 58, 68);
    triangle(52, 3, 56, 4.5, 52, 6);
    stroke(165, 104, 61);
    fill(232, 143, 168);
    rect(-6, 0, 6, 9);
    popMatrix();
  }

  // Parte un texto en líneas (ver wrapText en UI_Widgets). Requiere textSize() ya fijado.
  ArrayList<String> wrap(String s, float maxW) {
    return wrapText(s, maxW);
  }

  float maxScroll() {
    return max(0, contentH - area.h);
  }

  void drawScrollbar() {
    if (maxScroll() <= 0) return;
    float frac = scrollY / maxScroll();
    float barH = max(20, area.h * (area.h / contentH));
    float barY = area.y + (area.h - barH) * frac;
    noStroke();
    fill(rule);
    rect(area.x + area.w - 6, barY, 4, barH, 2);
  }

  void mouseWheel(int amount) {
    if (!area.containsMouse()) return;
    scrollY = constrain(scrollY + amount * 20, 0, maxScroll());
  }
}
