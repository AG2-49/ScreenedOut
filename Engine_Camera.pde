// ============================================================
//  Engine_Camera.pde — Ventana al mapa: recorte, arrastre y seguimiento
//  El mapa solo se puede arrastrar en un eje si su contenido desborda el área.
// ============================================================

class Camera {
  Rect area;                       // región de pantalla donde se ve el mapa
  float contentW, contentH;        // tamaño del mapa en píxeles
  boolean needsScrollX, needsScrollY;

  float offsetX = 0, offsetY = 0;
  boolean dragging = false;
  float dragStartX, dragStartY, offsetStartX, offsetStartY;

  int followMargin = TILE_SIZE;    // cuánto debe acercarse el jugador al borde para mover la cámara
  int shadowSize = 25;

  Camera(Rect area) {
    this.area = area;
  }

  void setContentSize(float w, float h) {
    contentW = w;
    contentH = h;
    needsScrollX = contentW > area.w;
    needsScrollY = contentH > area.h;
  }

  void reset() {
    offsetX = 0;
    offsetY = 0;
    dragging = false;
  }

  // ----- Dibujo: envolver el dibujo del mundo entre begin() y end() -----
  void begin() {
    pushMatrix();
    pushStyle();
    translate(area.x, area.y);
    clip(0, 0, area.w, area.h);
    // Offset redondeado a píxel entero: evita costuras entre tiles al desplazar
    translate(-round(offsetX), -round(offsetY));
  }

  void end() {
    noClip();
    popStyle();
    popMatrix();

    drawEdgeShadows();

    pushStyle();
    noFill();
    stroke(0);
    strokeWeight(2);
    rect(area.x, area.y, area.w, area.h);
    popStyle();
  }

  // ----- Entrada -----
  // Devuelve true si el click cayó sobre el mapa (y por tanto empezó un arrastre).
  boolean mousePressed() {
    if (!area.containsMouse()) return false;
    dragging = true;
    dragStartX = mouseX;
    dragStartY = mouseY;
    offsetStartX = offsetX;
    offsetStartY = offsetY;
    return true;
  }

  void mouseDragged() {
    if (!dragging) return;
    if (needsScrollX) {
      offsetX = constrain(offsetStartX - (mouseX - dragStartX), 0, contentW - area.w);
    }
    if (needsScrollY) {
      offsetY = constrain(offsetStartY - (mouseY - dragStartY), 0, contentH - area.h);
    }
  }

  void mouseReleased() {
    dragging = false;
  }

  // ¿Se puede arrastrar el mapa desde donde está el mouse? (la pantalla decide el cursor)
  boolean canDragHere() {
    return (needsScrollX || needsScrollY) && area.containsMouse();
  }

  // Desplaza la cámara lo mínimo para que el punto (px, py) —en coordenadas del mapa—
  // quede dentro del área visible, con followMargin de colchón.
  void follow(float px, float py) {
    if (needsScrollX) {
      float leftEdge = offsetX + followMargin;
      float rightEdge = offsetX + area.w - followMargin;
      if (px < leftEdge) offsetX = px - followMargin;
      else if (px > rightEdge) offsetX = px - area.w + followMargin;
      offsetX = constrain(offsetX, 0, contentW - area.w);
    }
    if (needsScrollY) {
      float topEdge = offsetY + followMargin;
      float bottomEdge = offsetY + area.h - followMargin;
      if (py < topEdge) offsetY = py - followMargin;
      else if (py > bottomEdge) offsetY = py - area.h + followMargin;
      offsetY = constrain(offsetY, 0, contentH - area.h);
    }
  }

  // ----- Sombras en los bordes que indican que hay más mapa por ver -----
  void drawEdgeShadows() {
    if (needsScrollX && offsetX > 0) {
      drawGradient(area.x, area.y, shadowSize, area.h, true, false);
    }
    if (needsScrollX && offsetX < contentW - area.w) {
      drawGradient(area.x + area.w - shadowSize, area.y, shadowSize, area.h, true, true);
    }
    if (needsScrollY && offsetY > 0) {
      drawGradient(area.x, area.y, area.w, shadowSize, false, false);
    }
    if (needsScrollY && offsetY < contentH - area.h) {
      drawGradient(area.x, area.y + area.h - shadowSize, area.w, shadowSize, false, true);
    }
  }
}

void drawGradient(float x, float y, float w, float h, boolean horizontal, boolean reversed) {
  pushStyle();
  noFill();
  int steps = (int) (horizontal ? w : h);
  for (int i = 0; i < steps; i++) {
    float t = i / (float) steps;
    float alpha = reversed ? lerp(0, 70, t) : lerp(70, 0, t);
    stroke(0, alpha);
    if (horizontal) {
      line(x + i, y, x + i, y + h);
    } else {
      line(x, y + i, x + w, y + i);
    }
  }
  popStyle();
}
