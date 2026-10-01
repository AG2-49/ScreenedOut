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
  void onTrigger(Level level) {}                // llamado por un objeto ligado hacia este

  // ----- Comunes -----
  // Devuelve true si la interacción "contó". Player.interact() usa ese valor para decidir
  // si prueba con el objeto de la casilla de enfrente cuando el de debajo no hizo nada.
  boolean interact(Level level) {
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

  boolean onInteract(Level level) {
    // Ya abierta (p. ej. el jugador está parado en el umbral): no hay nada que hacer.
    if (open) return false;
    if (controllers > 0) {
      level.message = "La puerta no cede. Debe haber algo que la controle.";
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

  boolean onInteract(Level level) {
    read = true;
    for (Task t : addedTasks) t.revealed = true;
    level.openNote = this;
    return true;
  }
}
