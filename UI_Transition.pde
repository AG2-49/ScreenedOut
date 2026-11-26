// ============================================================
//  UI_Transition.pde — Piezas comunes de las transiciones entre pantallas
//  Los selectores (niveles y tutoriales) hacen crecer la ficha pulsada hasta cubrir la
//  ventana; LevelScreen entra y sale con los paneles deslizándose (ver Screen_Level.pde).
// ============================================================

float easeOutCubic(float t) { t = constrain(t, 0, 1); return 1 - pow(1 - t, 3); }
float easeInCubic(float t)  { t = constrain(t, 0, 1); return t * t * t; }

// Rectángulo que crece desde (x, y, w, h) —coordenadas de pantalla— hasta cubrir toda la
// ventana, pasando del color «from» al «to». p va de 0 a 1.
void drawGrowRect(float x, float y, float w, float h, float p, color from, color to, float radius) {
  float e = roomEase(constrain(p, 0, 1));
  float c = constrain(e * 1.25, 0, 1);       // el color llega al final un poco antes que el tamaño
  pushStyle();
  noStroke();
  fill(lerpColor(from, to, c));
  rect(lerp(x, 0, e), lerp(y, 0, e), lerp(w, WINDOW_W, e), lerp(h, WINDOW_H, e), lerp(radius, 0, e));
  popStyle();
}
