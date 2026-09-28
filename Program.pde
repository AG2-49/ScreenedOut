// ===== Tipos de instrucción disponibles =====
final int ACT_FORWARD = 0;
final int ACT_TURN_LEFT = 1;
final int ACT_TURN_RIGHT = 2;
final int ACT_INTERACT = 3;

ArrayList<Integer> programSequence = new ArrayList<Integer>();

boolean running = false;      // true mientras se ejecuta la secuencia
int currentStep = -1;         // índice de la instrucción actual durante la ejecución
int stepDelay = 400;          // ms entre cada instrucción
int lastStepTime = 0;

// ===== Layout de la paleta de botones =====
int paletteBtnSize = 50;
int paletteBtnGap = 12;
int paletteCols = 4;

String[] actionIcons = {"↑", "↺", "↻", "✋"};
String[] actionLabels = {"Avanzar", "Girar Izq.", "Girar Der.", "Interactuar"};

// ===== Layout de la lista apilada (secuencia ya construida) =====
int stackStartYOffset = 90;  // debajo de la paleta, relativo a progAreaY
int stackItemH = 34;
int stackItemGap = 6;
int stackBottomMargin = 20;  // espacio reservado abajo para separarla de los botones inferiores

int stackScrollY = 0;        // desplazamiento vertical (en píxeles) dentro de la lista
int rowBtnSize = 22;         // tamaño de los botones ▲▼✕ de cada fila

// ===== Botones inferiores: Limpiar todo / Correr =====
int bottomBtnH = 40;
int bottomBtnGap = 10;


void drawProgramPanel() {
  pushStyle();

  noFill();
  stroke(0);
  strokeWeight(2);
  rect(progAreaX, progAreaY, progAreaW, progAreaH);

  drawPalette();
  drawSequenceStack();
  drawBottomButtons();

  popStyle();
}

// ===== Paleta de botones de acción =====
void drawPalette() {
  int startX = progAreaX + 15;
  int startY = progAreaY + 15;

  for (int i = 0; i < actionIcons.length; i++) {
    int col = i % paletteCols;
    int row = i / paletteCols;

    int bx = startX + col * (paletteBtnSize + paletteBtnGap);
    int by = startY + row * (paletteBtnSize + paletteBtnGap);

    boolean hover = mouseX >= bx && mouseX <= bx + paletteBtnSize &&
                    mouseY >= by && mouseY <= by + paletteBtnSize;

    pushStyle();
    fill(hover ? color(210, 225, 255) : color(230, 238, 255));
    stroke(60, 90, 160);
    strokeWeight(2);
    rect(bx, by, paletteBtnSize, paletteBtnSize, 8);

    fill(30, 50, 100);
    textAlign(CENTER, CENTER);
    textSize(22);
    text(actionIcons[i], bx + paletteBtnSize / 2.0, by + paletteBtnSize / 2.0 - 2);
    popStyle();
  }
}

// ===== Área ocupada por la lista (usada para clip, scroll y detección de clicks) =====
int stackAreaX() { return progAreaX + 15; }
int stackAreaY() { return progAreaY + stackStartYOffset; }
int stackAreaW() { return progAreaW - 30; }
int stackAreaH() { return progAreaH - stackStartYOffset - (bottomBtnH * 2 + bottomBtnGap) - stackBottomMargin; }

int stackContentH() {
  return programSequence.size() * (stackItemH + stackItemGap);
}

int maxStackScroll() {
  return max(0, stackContentH() - stackAreaH());
}

// ===== Lista apilada de instrucciones ya añadidas, con scroll y botones por fila =====
void drawSequenceStack() {
  int ax = stackAreaX();
  int ay = stackAreaY();
  int aw = stackAreaW();
  int ah = stackAreaH();

  pushStyle();
  pushMatrix();

  // Fondo sutil del área de lista, para que se note el recorte
  fill(255);
  stroke(200);
  strokeWeight(1);
  rect(ax, ay, aw, ah);

  clip(ax, ay, aw, ah);
  translate(0, -stackScrollY);

  textAlign(LEFT, CENTER);
  textSize(13);

  for (int i = 0; i < programSequence.size(); i++) {
    int iy = ay + i * (stackItemH + stackItemGap);

    int action = programSequence.get(i);
    boolean isCurrent = running && i == currentStep;

    // Fila
    fill(isCurrent ? color(255, 221, 120) : color(247, 249, 255));
    stroke(60, 90, 160);
    strokeWeight(1.5);
    rect(ax, iy, aw, stackItemH, 6);

    fill(30, 50, 100);
    text((i + 1) + ".  " + actionIcons[action] + "  " + actionLabels[action], ax + 10, iy + stackItemH / 2.0);

    // Botones ▲ ▼ ✕ de la fila (alineados a la derecha)
    drawRowButton(ax + aw - rowBtnSize * 3 - 6, iy + (stackItemH - rowBtnSize) / 2.0, "▲", i > 0);
    drawRowButton(ax + aw - rowBtnSize * 2 - 3, iy + (stackItemH - rowBtnSize) / 2.0, "▼", i < programSequence.size() - 1);
    drawRowButton(ax + aw - rowBtnSize, iy + (stackItemH - rowBtnSize) / 2.0, "✕", true);
  }

  noClip();
  popMatrix();

  // Marco del área de lista (por encima del clip, para que se vea sólido)
  noFill();
  stroke(0);
  strokeWeight(1.5);
  rect(ax, ay, aw, ah);

  // Indicador simple de scroll si hay contenido oculto
  if (maxStackScroll() > 0) {
    float scrollFrac = stackScrollY / (float) maxStackScroll();
    int barH = max(20, (int) (ah * (ah / (float) stackContentH())));
    int barY = ay + (int) ((ah - barH) * scrollFrac);
    fill(160);
    noStroke();
    rect(ax + aw - 4, barY, 3, barH, 2);
  }

  popStyle();
}

void drawRowButton(float bx, float by, String icon, boolean enabled) {
  pushStyle();
  fill(enabled ? color(255, 235, 235) : color(235));
  stroke(enabled ? color(160, 60, 60) : color(200));
  strokeWeight(1);
  rect(bx, by, rowBtnSize, rowBtnSize, 4);

  fill(enabled ? color(120, 30, 30) : color(180));
  textAlign(CENTER, CENTER);
  textSize(11);
  text(icon, bx + rowBtnSize / 2.0, by + rowBtnSize / 2.0);
  popStyle();
}

// ===== Botones inferiores: Limpiar todo / Correr =====
void drawBottomButtons() {
  int bx = progAreaX + 15;
  int bw = progAreaW - 30;

  int clearY = progAreaY + progAreaH - bottomBtnH * 2 - bottomBtnGap - 15;
  int runY = progAreaY + progAreaH - bottomBtnH - 15;

  // Limpiar todo
  boolean clearHover = mouseX >= bx && mouseX <= bx + bw &&
                        mouseY >= clearY && mouseY <= clearY + bottomBtnH;
  boolean clearEnabled = !running && !programSequence.isEmpty();

  pushStyle();
  fill(!clearEnabled ? color(230) : (clearHover ? color(240, 150, 140) : color(245, 180, 170)));
  stroke(150, 60, 50);
  strokeWeight(2);
  rect(bx, clearY, bw, bottomBtnH, 8);
  fill(clearEnabled ? color(100, 30, 25) : color(170));
  textAlign(CENTER, CENTER);
  textSize(14);
  text("Limpiar todo", bx + bw / 2.0, clearY + bottomBtnH / 2.0);
  popStyle();

  // Correr
  boolean runHover = mouseX >= bx && mouseX <= bx + bw &&
                      mouseY >= runY && mouseY <= runY + bottomBtnH;

  pushStyle();
  fill(running ? color(200) : (runHover ? color(120, 200, 140) : color(140, 215, 160)));
  stroke(30, 100, 60);
  strokeWeight(2);
  rect(bx, runY, bw, bottomBtnH, 8);
  fill(20, 60, 35);
  textAlign(CENTER, CENTER);
  textSize(16);
  text(running ? "Ejecutando…" : "▶ Correr", bx + bw / 2.0, runY + bottomBtnH / 2.0);
  popStyle();
}

// ===== Clicks en el panel de programación =====
// Se llama desde mousePressed() en Movement.pde cuando el click cae fuera del mapa.
void handleProgramClick() {
  if (running) return; // no editar la secuencia mientras corre

  // Paleta
  int startX = progAreaX + 15;
  int startY = progAreaY + 15;

  for (int i = 0; i < actionIcons.length; i++) {
    int col = i % paletteCols;
    int row = i / paletteCols;

    int bx = startX + col * (paletteBtnSize + paletteBtnGap);
    int by = startY + row * (paletteBtnSize + paletteBtnGap);

    if (mouseX >= bx && mouseX <= bx + paletteBtnSize &&
        mouseY >= by && mouseY <= by + paletteBtnSize) {
      programSequence.add(i);
      clampScroll();
      return;
    }
  }

  // Botones de fila (▲▼✕) dentro de la lista
  if (handleStackClick()) return;

  // Botón limpiar
  int bx = progAreaX + 15;
  int bw = progAreaW - 30;
  int clearY = progAreaY + progAreaH - bottomBtnH * 2 - bottomBtnGap - 15;

  if (!programSequence.isEmpty() &&
      mouseX >= bx && mouseX <= bx + bw &&
      mouseY >= clearY && mouseY <= clearY + bottomBtnH) {
    programSequence.clear();
    stackScrollY = 0;
    return;
  }

  // Botón correr
  int runY = progAreaY + progAreaH - bottomBtnH - 15;

  if (mouseX >= bx && mouseX <= bx + bw &&
      mouseY >= runY && mouseY <= runY + bottomBtnH) {
    startRun();
    return;
  }
}

// Detecta clicks en los botones ▲▼✕ de cada fila de la lista, considerando el scroll y el clip.
// Devuelve true si el click fue manejado (para no seguir buscando otros botones).
boolean handleStackClick() {
  int ax = stackAreaX();
  int ay = stackAreaY();
  int aw = stackAreaW();
  int ah = stackAreaH();

  // Si el click no cae dentro del área visible de la lista, ignorar
  if (mouseX < ax || mouseX > ax + aw || mouseY < ay || mouseY > ay + ah) return false;

  // Convierte la posición del mouse a coordenadas "de contenido" (antes del scroll)
  float contentY = mouseY - ay + stackScrollY;

  int index = (int) (contentY / (stackItemH + stackItemGap));
  if (index < 0 || index >= programSequence.size()) return false;

  float rowTop = index * (stackItemH + stackItemGap);
  float rowBottom = rowTop + stackItemH;
  if (contentY < rowTop || contentY > rowBottom) return false; // cayó en el gap entre filas

  float btnUpX = ax + aw - rowBtnSize * 3 - 6;
  float btnDownX = ax + aw - rowBtnSize * 2 - 3;
  float btnDelX = ax + aw - rowBtnSize;

  if (mouseX >= btnUpX && mouseX <= btnUpX + rowBtnSize) {
    if (index > 0) swapSteps(index, index - 1);
    return true;
  }
  if (mouseX >= btnDownX && mouseX <= btnDownX + rowBtnSize) {
    if (index < programSequence.size() - 1) swapSteps(index, index + 1);
    return true;
  }
  if (mouseX >= btnDelX && mouseX <= btnDelX + rowBtnSize) {
    programSequence.remove(index);
    clampScroll();
    return true;
  }

  return false;
}

void swapSteps(int i, int j) {
  int tmp = programSequence.get(i);
  programSequence.set(i, programSequence.get(j));
  programSequence.set(j, tmp);
}

void clampScroll() {
  stackScrollY = constrain(stackScrollY, 0, maxStackScroll());
}

// ===== Scroll de la lista con la rueda del mouse =====
void mouseWheel(MouseEvent event) {
  int ax = stackAreaX();
  int ay = stackAreaY();
  int aw = stackAreaW();
  int ah = stackAreaH();

  boolean overStack = mouseX >= ax && mouseX <= ax + aw && mouseY >= ay && mouseY <= ay + ah;
  if (!overStack) return;

  stackScrollY += event.getCount() * 20;
  clampScroll();
}

// ===== Ejecución paso a paso =====
void startRun() {
  if (programSequence.isEmpty()) return;
  resetToStart(); // vuelve a la posición/orientación/mapa inicial en cada intento
  running = true;
  currentStep = 0;
  lastStepTime = millis();
  executeStep(currentStep); // ejecuta el primer paso de inmediato
}

// Llamado cada frame desde draw() para avanzar la ejecución con delay.
void updateRun() {
  if (!running) return;

  if (fell) {
    // El jugador cayó: corta la ejecución de inmediato, no sigue gastando pasos
    running = false;
    currentStep = -1;
    return;
  }

  if (millis() - lastStepTime >= stepDelay) {
    currentStep++;

    if (currentStep >= programSequence.size()) {
      running = false;
      currentStep = -1;
      return;
    }

    executeStep(currentStep);
    lastStepTime = millis();
  }
}

void executeStep(int index) {
  int action = programSequence.get(index);

  switch (action) {
    case ACT_FORWARD:
      moveForward();
      break;
    case ACT_TURN_LEFT:
      turn(-1);
      break;
    case ACT_TURN_RIGHT:
      turn(1);
      break;
    case ACT_INTERACT:
      interact();
      break;
  }
}
