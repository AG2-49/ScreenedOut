int shadowSize = 25;

void drawGradient(float x, float y, float w, float h, boolean horizontal, boolean reversed) {
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
  noStroke();
}

void drawEdgeShadows() {
  if (needsScrollX && offsetX > 0) {
    drawGradient(mapAreaX, mapAreaY, shadowSize, mapAreaH, true, false);
  }
  if (needsScrollX && offsetX < mapPixelW - mapAreaW) {
    drawGradient(mapAreaX + mapAreaW - shadowSize, mapAreaY, shadowSize, mapAreaH, true, true);
  }
  if (needsScrollY && offsetY > 0) {
    drawGradient(mapAreaX, mapAreaY, mapAreaW, shadowSize, false, false);
  }
  if (needsScrollY && offsetY < mapPixelH - mapAreaH) {
    drawGradient(mapAreaX, mapAreaY + mapAreaH - shadowSize, mapAreaW, shadowSize, false, true);
  }
}
