// ============================================================
//  UI_Widgets.pde — Piezas reutilizables de interfaz
// ============================================================

// Rectángulo con detección de punto/mouse dentro.
class Rect {
  float x, y, w, h;

  Rect(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  boolean contains(float px, float py) {
    return px >= x && px <= x + w && py >= y && py <= y + h;
  }

  boolean containsMouse() {
    return contains(mouseX, mouseY);
  }
}

// Botón de texto genérico (menús, panel de programación, etc.).
class UIButton {
  Rect r;
  String label;
  boolean enabled = true;
  float textSz = 16;

  // Colores (por defecto: estilo azul de la paleta)
  color fillC     = color(230, 238, 255);
  color hoverC    = color(210, 225, 255);
  color strokeC   = color(60, 90, 160);
  color textC     = color(30, 50, 100);
  color disabledFill = color(230);
  color disabledText = color(170);

  UIButton(float x, float y, float w, float h, String label) {
    this.r = new Rect(x, y, w, h);
    this.label = label;
  }

  UIButton colors(color fill, color hover, color stroke, color text) {
    fillC = fill;
    hoverC = hover;
    strokeC = stroke;
    textC = text;
    return this;
  }

  boolean hover() {
    return enabled && r.containsMouse();
  }

  boolean clicked() {
    return enabled && r.containsMouse();
  }

  void draw() {
    pushStyle();
    fill(!enabled ? disabledFill : (hover() ? hoverC : fillC));
    stroke(strokeC);
    strokeWeight(2);
    rect(r.x, r.y, r.w, r.h, 8);

    fill(enabled ? textC : disabledText);
    textAlign(CENTER, CENTER);
    textSize(textSz);
    text(label, r.x + r.w / 2.0, r.y + r.h / 2.0);
    popStyle();
  }
}

// Parte un texto en líneas que quepan en maxW (respeta saltos de línea "\n").
// Requiere que textSize() ya esté fijado.
ArrayList<String> wrapText(String s, float maxW) {
  ArrayList<String> lines = new ArrayList<String>();
  for (String para : s.split("\n")) {
    String cur = "";
    for (String word : para.split(" ")) {
      String test = cur.length() == 0 ? word : cur + " " + word;
      if (cur.length() == 0 || textWidth(test) <= maxW) {
        cur = test;
      } else {
        lines.add(cur);
        cur = word;
      }
    }
    lines.add(cur);
  }
  return lines;
}
