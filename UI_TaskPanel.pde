// ============================================================
//  UI_TaskPanel.pde — Región de tareas y notas leídas
//  Usa la paleta del ítem de nota: papel crema, líneas ocre y marrón oscuro.
//  Solo muestra: tareas reveladas y texto de las notas ya leídas. Se desplaza con la rueda.
// ============================================================

class TaskPanel {
  Rect area;
  Level level;

  // Paleta (tomada de note.png y del suelo)
  color paper = color(238, 195, 154);
  color rule  = color(217, 160, 102);
  color ink   = color(102, 57, 49);
  color soft  = color(143, 86, 59);    // texto de tareas ya cumplidas

  float scrollY = 0;
  float contentH = 0;                  // alto del contenido, medido en el último dibujo

  int pad = 14;
  int lineH = 16;
  int boxSize = 14;

  TaskPanel(Rect area, Level level) {
    this.area = area;
    this.level = level;
  }

  void draw() {
    pushStyle();

    fill(paper);
    stroke(ink);
    strokeWeight(2);
    rect(area.x, area.y, area.w, area.h);

    pushMatrix();
    clip(area.x + 2, area.y + 2, area.w - 4, area.h - 4);
    translate(0, -scrollY);

    float x0 = area.x + pad;
    float w = area.w - pad * 2;
    float y = area.y + pad;

    // ----- Tareas -----
    y = drawHeading("Tareas", x0, y, w);
    int shown = 0;
    for (Task t : level.tasks) {
      if (!t.revealed) continue;
      y = drawTask(t, x0, y, w);
      shown++;
    }
    if (shown == 0) y += 6;

    // ----- Notas leídas -----
    if (!level.notes.isEmpty()) {
      y += 10;
      y = drawHeading("Notas  " + level.notesRead() + "/" + level.notes.size(), x0, y, w);
      for (Note n : level.notes) {
        if (!n.read) continue;
        y = drawNoteText(n, x0, y, w);
      }
    }

    contentH = y - area.y + pad;

    noClip();
    popMatrix();

    drawScrollbar();
    popStyle();
  }

  float drawHeading(String label, float x, float y, float w) {
    fill(ink);
    textAlign(LEFT, TOP);
    textSize(16);
    text(label, x, y);
    stroke(rule);
    strokeWeight(2);
    line(x, y + 24, x + w, y + 24);
    return y + 32;
  }

  float drawTask(Task t, float x, float y, float w) {
    boolean done = t.isDone();
    textSize(13);
    ArrayList<String> lines = wrap(t.label(), w - boxSize - 10);
    float h = max(boxSize + 4, lines.size() * lineH);

    // Casilla de verificación
    stroke(ink);
    strokeWeight(1.5);
    fill(done ? rule : paper);
    rect(x, y + 1, boxSize, boxSize);
    if (done) {
      stroke(ink);
      strokeWeight(2);
      line(x + 3, y + 8, x + 6, y + 11);
      line(x + 6, y + 11, x + 11, y + 4);
    }

    // Texto (tachado si está cumplida)
    textAlign(LEFT, TOP);
    textSize(13);
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

  float drawNoteText(Note n, float x, float y, float w) {
    textSize(13);
    textAlign(LEFT, TOP);
    ArrayList<String> lines = wrap(n.text, w);
    fill(ink);
    noStroke();
    for (int i = 0; i < lines.size(); i++) {
      text(lines.get(i), x, y + i * lineH);
    }
    float h = lines.size() * lineH;
    stroke(rule);
    strokeWeight(1);
    line(x, y + h + 5, x + w, y + h + 5);
    return y + h + 11;
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
