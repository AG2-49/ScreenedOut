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
// Estilo por defecto: contorno cian sobre fondo oscuro, letra pixel (como «< Volver» del menú).
// Roles: primary() = ámbar (acción principal), danger() = rosa (destructiva).
class UIButton {
  Rect r;
  String label;
  boolean enabled = true;
  boolean playIcon = false;     // dibuja un triángulo ▶ delante del texto
  float textSz = UI_BTN_TEXT;
  PFont font = null;            // null = letra pixel del tema; asignar handFont para botones «de papel»

  color fillC        = COL_SCREEN;
  color hoverC       = COL_SLATE;
  color strokeC      = COL_CYAN;
  color hoverStrokeC = COL_WHITE;
  color textC        = COL_TEXT_SOFT;
  color disabledFill   = COL_SLATE;
  color disabledStroke = COL_SLATE_EDGE;
  color disabledText   = COL_MUTED;

  UIButton(float x, float y, float w, float h, String label) {
    this.r = new Rect(x, y, w, h);
    this.label = label;
  }

  // Colores a medida (el borde de hover es el mismo que el normal).
  UIButton colors(color fill, color hover, color stroke, color text) {
    fillC = fill;
    hoverC = hover;
    strokeC = stroke;
    hoverStrokeC = stroke;
    textC = text;
    return this;
  }

  // Acción principal: ámbar con texto navy (como las fichas de nivel del menú).
  UIButton primary() {
    colors(COL_AMBER, COL_AMBER_LIGHT, COL_AMBER_EDGE, COL_NAVY);
    hoverStrokeC = COL_WHITE;
    disabledFill = color(98, 80, 61);
    disabledStroke = color(140, 112, 70);
    disabledText = color(200, 160, 105);
    return this;
  }

  // Acción destructiva: contorno y texto rosa (como «Salir» y «Reiniciar»).
  UIButton danger() {
    colors(COL_SCREEN, color(61, 45, 70), COL_PINK, COL_PINK);
    hoverStrokeC = COL_PINK_LIGHT;
    return this;
  }

  boolean hover() {
    return enabled && r.containsMouse();
  }

  boolean clicked() {
    return enabled && r.containsMouse();
  }

  void draw() {
    textSize(g.textSize);          // asegura que ya hay una fuente activa que restaurar al final
    boolean hov = hover();
    pushStyle();
    fill(!enabled ? disabledFill : (hov ? hoverC : fillC));
    stroke(!enabled ? disabledStroke : (hov ? hoverStrokeC : strokeC));
    strokeWeight(2);
    rect(r.x, r.y, r.w, r.h, UI_BTN_RADIUS);

    noStroke();
    color tc = enabled ? textC : disabledText;
    fill(tc);
    textFont(font != null ? font : uiFont);
    textSize(textSz);
    // Centrado vertical: textAlign(CENTER) de Processing usa métricas que en PressStart2P dejan el
    // texto bajo y «aplastado». Con la letra pixel se centra la altura de las mayúsculas (textAscent)
    // sobre el centro del botón, colocando la línea base a mano. Una fuente propia (handFont) conserva
    // el centrado de siempre.
    boolean pixel = (font == null);
    float cy = r.y + r.h / 2.0 - (pixel ? 0 : 1);
    float base = cy + textAscent() / 2.0;
    int vAlign = pixel ? BASELINE : CENTER;
    float ty = pixel ? base : cy;
    if (playIcon) {
      textAlign(LEFT, vAlign);
      float tw = textWidth(label);
      float ix = r.x + (r.w - (tw + 18)) / 2.0;
      triangle(ix, cy - 5, ix, cy + 5, ix + 9, cy);
      text(label, ix + 18, ty);
    } else {
      textAlign(CENTER, vAlign);
      text(label, r.x + r.w / 2.0, ty);
    }
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
