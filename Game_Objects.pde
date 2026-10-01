// ============================================================
//  Game_Objects.pde — Objetos interactivos de un nivel
//
//  Para añadir un objeto nuevo:
//    1) crea una clase que herede de GameObject,
//    2) elige su carácter en Level.createObject(),
//    3) (opcional) dale textura en Assets.
//  Enlaces: un objeto A ligado a B llama a B.onTrigger() cuando A se activa
//  (ej.: un botón ligado a una puerta).
// ============================================================

abstract class GameObject {
  int row, col;
  boolean done = false;        // ¿ya se interactuó con él con éxito? (lo usan las tareas)
  int controllers = 0;         // cuántos objetos lo controlan (ligados hacia él)
  ArrayList<GameObject> targets = new ArrayList<GameObject>();

  GameObject(int row, int col) {
    this.row = row;
    this.col = col;
  }

  // ----- Lo que se puede sobrescribir -----
  boolean blocksMovement() { return false; }
  PImage texture() { return null; }             // null = no dibuja nada (se ve el suelo)
  boolean onInteract(Level level) { return true; } // devuelve true si la interacción "cuenta"

  // ¿Merece la pena interactuar con él AHORA? Alimenta el destello sutil del mapa.
  // Por defecto: tiene una tarea visible sin cumplir (bloqueado o ya hecho = no brilla).
  boolean interactive(Level level) {
    return level.hasPendingTask(this);
  }
  void onTrigger(Level level) {}                // llamado por un objeto ligado hacia este

  // ----- Comunes -----
  // Devuelve true si la interacción "contó". Player.interact() usa ese valor para decidir
  // si prueba con el objeto de la casilla de enfrente cuando el de debajo no hizo nada.
  boolean interact(Level level) {
    // Aún no le han pedido usar esto (su tarea la revela una nota sin leer)
    if (level.isLocked(this)) {
      level.sayLocked();
      return false;
    }
    boolean counted = onInteract(level);
    if (counted) done = true;
    return counted;
  }

  void linkTo(GameObject target) {
    targets.add(target);
    target.controllers++;
  }

  void fireTargets(Level level) {
    for (GameObject t : targets) t.onTrigger(level);
  }

  void draw() {
    PImage t = texture();
    if (t != null) image(t, col * TILE_SIZE, row * TILE_SIZE);
  }
}

// Puerta: cerrada bloquea el paso. Si nada la controla, se abre interactuando;
// si está ligada a un botón, solo se abre/cierra desde el botón.
class Door extends GameObject {
  boolean open = false;

  Door(int row, int col) { super(row, col); }

  boolean blocksMovement() { return !open; }
  PImage texture() { return open ? null : assets.door; }

  // Brilla si se puede abrir con las manos: cerrada, sin nada que la controle y no bloqueada.
  boolean interactive(Level level) {
    return !open && controllers == 0 && !level.isLocked(this);
  }

  boolean onInteract(Level level) {
    // Ya abierta (p. ej. el jugador está parado en el umbral): no hay nada que hacer.
    if (open) return false;
    if (controllers > 0) {
      level.say("La puerta no cede. Debe haber algo que la controle.");
      return false;
    }
    open = true;
    println("Puerta abierta en fila " + row + ", columna " + col);
    return true;
  }

  void onTrigger(Level level) {
    open = !open;
  }
}

// Botón: al interactuar alterna su estado y activa los objetos ligados.
class FloorButton extends GameObject {
  boolean pressed = false;

  FloorButton(int row, int col) { super(row, col); }

  PImage texture() { return pressed ? assets.buttonPressed : assets.buttonUnpressed; }

  boolean interactive(Level level) {
    return !done && !level.isLocked(this);
  }

  boolean onInteract(Level level) {
    pressed = !pressed;
    fireTargets(level);
    return true;
  }
}

// Computadora (el escritorio del jugador). Por ahora solo se puede usar como objetivo de una tarea.
class Computer extends GameObject {
  Computer(int row, int col) { super(row, col); }

  PImage texture() { return assets.computer; }
}

// Nota: al interactuar con ella se lee. Se abre a pantalla completa sobre el mapa
// (level.openNote) y el juego se detiene hasta que el jugador la cierra. Su texto pasa a
// la lista de notas leídas y las tareas que añade se revelan en la lista de tareas.
class Note extends GameObject {
  String text = "";
  boolean read = false;
  ArrayList<Task> addedTasks = new ArrayList<Task>();

  Note(int row, int col) { super(row, col); }

  PImage texture() { return assets.note; }

  // Brilla hasta que se lee por primera vez.
  boolean interactive(Level level) { return !read; }

  boolean onInteract(Level level) {
    read = true;
    for (Task t : addedTasks) t.revealed = true;
    level.openNote = this;
    return true;
  }
}


// Tareas domésticas sin sprite todavía: figuras de color sobre la casilla.
abstract class Chore extends GameObject {
  Chore(int row, int col) { super(row, col); }

  void draw() {
    pushMatrix();
    pushStyle();
    translate(col * TILE_SIZE, row * TILE_SIZE);
    scale(TILE_SIZE / 60.0);
    drawShape();
    popStyle();
    popMatrix();
  }

  abstract void drawShape();   // en una casilla de 60 x 60
}

class Bed extends Chore {
  Bed(int row, int col) { super(row, col); }

  void drawShape() {
    stroke(60, 90, 160);
    strokeWeight(2);
    fill(110, 150, 220);
    rect(8, 8, 44, 46, 4);
    fill(255);
    rect(13, 12, 34, 13, 4);
    noFill();
    line(10, 36, 50, 36);
  }
}

class Trash extends Chore {
  Trash(int row, int col) { super(row, col); }

  void drawShape() {
    stroke(70, 80, 55);
    strokeWeight(2);
    fill(125, 140, 95);
    beginShape();
    vertex(12, 44); vertex(17, 27); vertex(30, 17); vertex(44, 25); vertex(50, 43); vertex(40, 51); vertex(22, 51);
    endShape(CLOSE);
    fill(165, 120, 80);
    triangle(28, 30, 40, 44, 24, 46);
  }
}

class Dishes extends Chore {
  Dishes(int row, int col) { super(row, col); }

  void drawShape() {
    stroke(90, 130, 160);
    strokeWeight(2);
    fill(205, 228, 238);
    rect(7, 13, 46, 34, 5);
    fill(255);
    beginShape();
    vertex(22, 22); vertex(30, 19); vertex(38, 22); vertex(41, 30); vertex(38, 38); vertex(30, 41); vertex(22, 38); vertex(19, 30);
    endShape(CLOSE);
  }
}

class Feeder extends Chore {
  Feeder(int row, int col) { super(row, col); }

  void drawShape() {
    stroke(140, 80, 30);
    strokeWeight(2);
    fill(230, 150, 60);
    quad(9, 24, 51, 24, 43, 46, 17, 46);
    fill(120, 70, 40);
    quad(15, 24, 45, 24, 43, 29, 17, 29);
  }
}
