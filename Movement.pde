boolean needsScrollX, needsScrollY;
boolean dragging = false;
float offsetX = 0, offsetY = 0;
float dragStartX, dragStartY;
float offsetStartX, offsetStartY;

int followMargin = tileSize; // qué tan cerca del borde debe estar el jugador para empezar a desplazar la cámara

void updateCursor() {
  boolean overMap = mouseX >= mapAreaX && mouseX <= mapAreaX + mapAreaW &&
                     mouseY >= mapAreaY && mouseY <= mapAreaY + mapAreaH;
  boolean canScroll = (needsScrollX || needsScrollY) && overMap;

  if (canScroll) {
    cursor(HAND);
    if (dragging) {
      cursor(MOVE);
    }
  } else {
    cursor(ARROW);
  }
}

void mousePressed() {
  boolean overMap = mouseX >= mapAreaX && mouseX <= mapAreaX + mapAreaW &&
                     mouseY >= mapAreaY && mouseY <= mapAreaY + mapAreaH;

  if (overMap) {
    dragging = true;
    dragStartX = mouseX;
    dragStartY = mouseY;
    offsetStartX = offsetX;
    offsetStartY = offsetY;
    return;
  }

  // Si no fue sobre el mapa, puede ser un click en el panel de programación
  handleProgramClick();
}

void mouseDragged() {
  if (!dragging) return;

  if (needsScrollX) {
    offsetX = offsetStartX - (mouseX - dragStartX);
    offsetX = constrain(offsetX, 0, mapPixelW - mapAreaW);
  }
  if (needsScrollY) {
    offsetY = offsetStartY - (mouseY - dragStartY);
    offsetY = constrain(offsetY, 0, mapPixelH - mapAreaH);
  }
}

void mouseReleased() {
  dragging = false;
}

// Desplaza la cámara (offsetX/Y) lo mínimo necesario para que el jugador
// quede dentro del área visible, respetando followMargin como colchón.
// El usuario puede seguir arrastrando después para ver otras zonas.
void followPlayer() {
  float playerX = Pos[1] * tileSize + tileSize / 2.0;
  float playerY = Pos[0] * tileSize + tileSize / 2.0;

  if (needsScrollX) {
    float leftEdge = offsetX + followMargin;
    float rightEdge = offsetX + mapAreaW - followMargin;

    if (playerX < leftEdge) {
      offsetX = playerX - followMargin;
    } else if (playerX > rightEdge) {
      offsetX = playerX - mapAreaW + followMargin;
    }

    offsetX = constrain(offsetX, 0, mapPixelW - mapAreaW);
  }

  if (needsScrollY) {
    float topEdge = offsetY + followMargin;
    float bottomEdge = offsetY + mapAreaH - followMargin;

    if (playerY < topEdge) {
      offsetY = playerY - followMargin;
    } else if (playerY > bottomEdge) {
      offsetY = playerY - mapAreaH + followMargin;
    }

    offsetY = constrain(offsetY, 0, mapPixelH - mapAreaH);
  }
}
