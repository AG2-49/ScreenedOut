// ============================================================
//  UI_NoteViewer.pde — Nota a pantalla completa sobre el mapa
//  Cuando hay una nota abierta (level.openNote) esta vista REEMPLAZA al mapa y el juego
//  queda en pausa hasta pulsar «Cerrar nota» (o Enter / Espacio). El texto ya queda
//  guardado en la lista de notas leídas del TaskPanel.
//  Si el texto no cabe, se desplaza con la rueda o arrastrando.
// ============================================================

class NoteViewer {
  Rect area;
  Level level;
  UIButton closeBtn;

  // Misma paleta que TaskPanel / note.png
  color paper = color(238, 195, 154);
  color rule  = color(217, 160, 102);
  color ink   = color(102, 57, 49);

  int pad = 26;
  int lineH = 22;
  float textSz = 16;

  Note shown = null;          // para volver al inicio del texto al abrir otra nota
  float scrollY = 0;
  float contentH = 0;
  boolean dragging = false;
  float dragStartY, dragScrollStart;

  NoteViewer(Rect area, Level level) {
    this.area = area;
    this.level = level;

    float bw = 170, bh = 40;
    closeBtn = new UIButton(area.x + (area.w - bw) / 2.0, area.y + area.h - pad - bh, bw, bh, "Cerrar nota");
    closeBtn.colors(rule, color(196, 140, 86), ink, color(60, 30, 25));
    closeBtn.textSz = 16;
  }

  boolean isOpen() { return level.openNote != null; }

  void close() {
    level.openNote = null;
    dragging = false;
  }

  // ----- Geometría del texto -----
  float textTop()    { return area.y + pad + 56; }
  float textBottom() { return closeBtn.r.y - 16; }
  float textH()      { return textBottom() - textTop(); }
  float maxScroll()  { return max(0, contentH - textH()); }

  // ============================================================
  //  DIBUJO
  // ============================================================
  void draw() {
    Note n = level.openNote;
    if (n == null) return;
    if (n != shown) {
      shown = n;
      scrollY = 0;
      dragging = false;
    }

    pushStyle();

    // Papel
    fill(paper);
    stroke(0);
    strokeWeight(2);
    rect(area.x, area.y, area.w, area.h);

    // Encabezado: ícono de la nota + título + línea
    float x0 = area.x + pad;
    float w = area.w - pad * 2;
    float y0 = area.y + pad;

    image(assets.note, x0, y0 - 4, 40, 40);
    fill(ink);
    textAlign(LEFT, CENTER);
    textSize(24);
    text("Nota", x0 + 52, y0 + 16);
    stroke(rule);
    strokeWeight(2);
    line(x0, y0 + 44, x0 + w, y0 + 44);

    // Texto (recortado a su región, con scroll)
    textSize(textSz);
    ArrayList<String> lines = wrapText(n.text, w - 8);
    contentH = lines.size() * lineH;
    scrollY = constrain(scrollY, 0, maxScroll());

    pushMatrix();
    clip(area.x + 2, textTop(), area.w - 4, textH());
    translate(0, -round(scrollY));
    fill(ink);
    noStroke();
    textAlign(LEFT, TOP);
    for (int i = 0; i < lines.size(); i++) {
      text(lines.get(i), x0, textTop() + i * lineH);
    }
    noClip();
    popMatrix();

    // Indicador de scroll
    if (maxScroll() > 0) {
      float frac = scrollY / maxScroll();
      float barH = max(20, textH() * (textH() / contentH));
      float barY = textTop() + (textH() - barH) * frac;
      noStroke();
      fill(rule);
      rect(area.x + area.w - 10, barY, 4, barH, 2);
    }

    closeBtn.draw();
    popStyle();
  }

  // ============================================================
  //  ENTRADA
  // ============================================================
  void mousePressed() {
    if (closeBtn.clicked()) {
      close();
      return;
    }
    if (area.containsMouse() && maxScroll() > 0) {
      dragging = true;
      dragStartY = mouseY;
      dragScrollStart = scrollY;
    }
  }

  void mouseDragged() {
    if (!dragging) return;
    scrollY = constrain(dragScrollStart - (mouseY - dragStartY), 0, maxScroll());
  }

  void mouseReleased() {
    dragging = false;
  }

  void mouseWheel(int amount) {
    if (!area.containsMouse()) return;
    scrollY = constrain(scrollY + amount * 20, 0, maxScroll());
  }

  // Enter o Espacio cierran la nota (Esc no: en Processing cierra el programa).
  void keyPressed() {
    if (key == ENTER || key == RETURN || key == ' ') close();
  }

  // ¿Qué cursor corresponde si el mouse está sobre el visor?
  boolean canDragHere() {
    return maxScroll() > 0 && area.containsMouse() && !closeBtn.r.containsMouse();
  }
}
