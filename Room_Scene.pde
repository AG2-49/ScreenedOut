
final float ROOM_ZOOM = 1.85;   // qué tanto se acerca la cámara al monitor

float[][] roomStars = {
  {0.06, 0.12}, {0.13, 0.45}, {0.20, 0.08}, {0.28, 0.25}, {0.62, 0.07},
  {0.74, 0.55}, {0.82, 0.15}, {0.90, 0.40}, {0.95, 0.10}
};

float roomS()  { return height / 205.0; }
float roomOX() { return (WINDOW_W - 380 * roomS()) / 2.0; }
float roomEase(float t) { return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2; }

class RoomCam {
  float cz = 1, cty = 0, cpx = 0, cpy = 0;

  // e = 0: se ve todo el cuarto. e = 1: la pantalla del monitor ocupa la ventana
  void set(float e) {
    float s = roomS();
    cpx = roomOX() + 190 * s;
    cpy = 83 * s;
    cz  = lerp(1, ROOM_ZOOM, e);
    cty = (height / 2.0 - cpy) * e;
  }

  void begin() {
    pushMatrix();
    translate(0, cty);
    translate(cpx, cpy);
    scale(cz);
    translate(-cpx, -cpy);
  }
  void end() { popMatrix(); }

  float x(float px) { return cpx + cz * (px - cpx); }
  float y(float py) { return cpy + cty + cz * (py - cpy); }
  float invX(float X) { return cpx + (X - cpx) / cz; }
  float invY(float Y) { return cpy + (Y - cpy - cty) / cz; }
}

void drawRoom(RoomCam cam) {
  float s = roomS(), ox = roomOX();
  background(26, 29, 61);

  cam.begin();

  noStroke();
  fill(255);
  for (float[] p : roomStars) ellipse(p[0] * width, p[1] * height, 3, 3);

  fill(139, 90, 60);
  rect(0, 170 * s, width, height - 170 * s);
  fill(34, 230, 255);
  rect(0, 169 * s, width, 2 * s);

  pushMatrix();
  translate(ox, 0);
  scale(s);

  // lámpara
  noStroke();
  fill(255, 181, 90, 34);
  ellipse(60, 110, 88, 88);
  fill(255, 181, 90);
  quad(46, 100, 74, 100, 68, 82, 52, 82);
  stroke(154, 107, 67);
  strokeWeight(3);
  line(60, 100, 60, 168);
  noStroke();
  fill(154, 107, 67);
  rect(50, 166, 20, 4);

  // monitor
  stroke(90, 90, 80);
  strokeWeight(2);
  fill(207, 200, 180);
  rect(170, 158, 40, 12);
  fill(217, 210, 192);
  rect(100, 18, 180, 140, 8);
  noStroke();
  fill(13, 26, 46);
  rect(112, 30, 156, 106, 4);
  fill(63, 224, 122);
  ellipse(268, 147, 5, 5);

  // teclado
  fill(223, 227, 234);
  rect(130, 176, 120, 12, 2);

  // planta
  noStroke();
  fill(181, 96, 58);
  quad(310, 152, 332, 152, 328, 170, 314, 170);
  fill(63, 166, 107);
  ellipse(321, 140, 12, 26);
  pushMatrix(); translate(313, 144); rotate(radians(-25)); ellipse(0, 0, 10, 22); popMatrix();
  pushMatrix(); translate(329, 144); rotate(radians(25));  ellipse(0, 0, 10, 22); popMatrix();

  popMatrix();
  cam.end();
}
