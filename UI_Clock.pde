// ============================================================
//  UI_Clock.pde — Reloj digital de introducción
//  Al empezar un nivel con "clock" en su JSON, esta vista REEMPLAZA al mapa: marca la hora
//  de inicio, avanza rápido hasta la hora final (con suavizado), se queda un instante
//  y se cierra sola. Un click, Enter o Espacio la saltan. El juego espera mientras se ve.
//  Los dígitos se dibujan como display de siete segmentos (no dependen de ninguna fuente).
// ============================================================

class ClockIntro {
  Rect area;
  Level level;

  boolean finished;
  int startMs = -1;          // se fija en el primer update (no cuenta el tiempo de carga)
  int advanceMs;             // duración del avance rápido
  int holdMs = 900;          // pausa mostrando la hora final

  // Segmentos por dígito: bits a=1 (arriba), b=2 (arriba der.), c=4 (abajo der.),
  // d=8 (abajo), e=16 (abajo izq.), f=32 (arriba izq.), g=64 (medio)
  int[] SEGMENTS = {63, 6, 91, 79, 102, 109, 125, 7, 127, 111};

  // Paleta
  color back  = color(24, 27, 40);
  color lit   = color(130, 235, 255);
  color glow  = color(130, 235, 255, 45);
  color ghost = color(255, 255, 255, 20);
  color soft  = color(150, 160, 185);

  ClockIntro(Rect area, Level level) {
    this.area = area;
    this.level = level;
    finished = !level.hasClock;
    // Unos 18 ms por minuto simulado, entre 1,8 y 4 s: 2 horas ≈ 2,2 s; medio día no se eterniza
    advanceMs = (int) constrain((level.clockTo - level.clockFrom) * 18, 1800, 4000);
  }

  boolean isActive() { return !finished; }

  void skip() { finished = true; }

  // Se llama cada frame.
  void update() {
    if (finished) return;
    if (startMs < 0) startMs = millis();
    if (millis() - startMs >= advanceMs + holdMs) finished = true;
  }

  // Minutos (desde las 0:00) que marca el reloj ahora mismo.
  int shownMinutes() {
    float t = constrain((millis() - startMs) / (float) advanceMs, 0, 1);
    float e = t * t * (3 - 2 * t);
    return (int) (level.clockFrom + (level.clockTo - level.clockFrom) * e);
  }

  // ============================================================
  //  DIBUJO
  // ============================================================
  void draw() {
    if (finished) return;
    if (startMs < 0) startMs = millis();

    int total = shownMinutes() % (24 * 60);
    int h24 = total / 60;
    int mins = total % 60;
    boolean pm = h24 >= 12;
    int h12 = h24 % 12;
    if (h12 == 0) h12 = 12;

    pushStyle();
    fill(back);
    stroke(0);
    strokeWeight(2);
    rect(area.x, area.y, area.w, area.h);

    // Medidas del display
    float dw = 52, dh = 96, t = 10;
    float gap = 10, colonW = 26;
    float totalW = dw * 4 + gap * 2 + colonW;
    float x = area.x + (area.w - totalW) / 2.0;
    float y = area.y + area.h / 2.0 - dh / 2.0 - 24;

    drawDigit(x, y, dw, dh, t, h12 >= 10 ? h12 / 10 : -1);   // -1 = apagado (hora de un dígito)
    x += dw + gap;
    drawDigit(x, y, dw, dh, t, h12 % 10);
    x += dw;

    // Dos puntos, parpadeando
    boolean on = (millis() / 500) % 2 == 0;
    noStroke();
    fill(on ? lit : ghost);
    float cx = x + colonW / 2.0 - 5;
    rect(cx, y + dh * 0.30, 10, 10, 2);
    rect(cx, y + dh * 0.62, 10, 10, 2);
    x += colonW;

    drawDigit(x, y, dw, dh, t, mins / 10);
    x += dw + gap;
    drawDigit(x, y, dw, dh, t, mins % 10);

    // AM / PM bajo el display, alineado a la derecha
    textAlign(RIGHT, TOP);
    textSize(18);
    float tx = area.x + (area.w + totalW) / 2.0;
    fill(!pm ? lit : color(255, 255, 255, 55));
    text("AM", tx - 40, y + dh + 14);
    fill(pm ? lit : color(255, 255, 255, 55));
    text("PM", tx, y + dh + 14);

    // Frase opcional del nivel
    if (level.clockText.length() > 0) {
      fill(soft);
      textAlign(CENTER, TOP);
      textSize(16);
      ArrayList<String> lines = wrapText(level.clockText, area.w - 80);
      for (int i = 0; i < lines.size(); i++) {
        text(lines.get(i), area.x + area.w / 2.0, y + dh + 62 + i * 22);
      }
    }

    // Pista para saltar
    fill(soft, 150);
    textAlign(CENTER, BOTTOM);
    textSize(12);
    text("Clic para saltar", area.x + area.w / 2.0, area.y + area.h - 12);

    popStyle();
  }

  // Un dígito de siete segmentos. digit = -1 lo deja apagado (solo se ve el "fantasma").
  void drawDigit(float x, float y, float w, float h, float t, int digit) {
    int mask = digit >= 0 ? SEGMENTS[digit] : 0;
    float g = 1.5;                      // separación entre segmentos
    float half = (h - 3 * t) / 2.0;     // alto de cada tramo vertical

    // a, b, c, d, e, f, g  →  {x, y, ancho, alto}
    float[][] seg = {
      { x + t + g,     y,                    w - 2 * t - 2 * g, t },          // a
      { x + w - t,     y + t + g,            t, half - 2 * g },               // b
      { x + w - t,     y + 2 * t + half + g, t, half - 2 * g },               // c
      { x + t + g,     y + h - t,            w - 2 * t - 2 * g, t },          // d
      { x,             y + 2 * t + half + g, t, half - 2 * g },               // e
      { x,             y + t + g,            t, half - 2 * g },               // f
      { x + t + g,     y + t + half,         w - 2 * t - 2 * g, t }           // g
    };

    noStroke();
    for (int i = 0; i < 7; i++) {
      float[] s = seg[i];
      if ((mask & (1 << i)) != 0) {
        fill(glow);                     // resplandor
        rect(s[0] - 3, s[1] - 3, s[2] + 6, s[3] + 6, 4);
        fill(lit);
        rect(s[0], s[1], s[2], s[3], 2);
      } else {
        fill(ghost);                    // segmento apagado
        rect(s[0], s[1], s[2], s[3], 2);
      }
    }
  }
}
