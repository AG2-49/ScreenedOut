// ============================================================
//  Game_Objects.pde — Objetos interactivos de un nivel
//
//  Para añadir un objeto nuevo:
//    1) crea una clase que herede de GameObject,
//    2) elige su carácter en Level.createObject(),
//    3) dale textura en Assets (y sonido en Audio, si lo tiene).
//  Enlaces: un objeto A ligado a B llama a B.onTrigger() cuando A se activa
//  (ej.: un botón ligado a una puerta).
//
//  Regla común: una vez cumplido (done), la mayoría de objetos ya no responden
//  (onInteract devuelve false), así que repetir «Interactuar» no repite el sonido.
// ============================================================

abstract class GameObject {
  int row, col;
  char symbol = '?';           // carácter del mapa con el que se creó (lo usan las tareas "all")
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
  void onEnter(Level level, Player player) {}   // el jugador acaba de pisar su casilla

  // ¿Merece la pena interactuar con él AHORA? Alimenta la caja de resalte del mapa.
  // Por defecto: tiene una tarea visible sin cumplir (bloqueado o ya hecho = no brilla).
  boolean interactive(Level level) {
    return level.hasPendingTask(this);
  }

  // ¿Se resalta al pasar el mouse por encima? Lo interactivo, y además todo lo que active
  // a otros objetos (un botón ya pulsado sigue mostrando qué puerta controla).
  boolean hoverable(Level level) {
    return interactive(level) || !targets.isEmpty();
  }

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
  boolean vertical = false;    // en una pared N-S se dibuja girada (lo fija Level al construir)

  Door(int row, int col) { super(row, col); }

  boolean blocksMovement() { return !open; }
  PImage texture() { return open ? null : (vertical ? assets.doorVertical : assets.door); }

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
    audio.play("DoorOpening");
    return true;
  }

  void onTrigger(Level level) {
    open = !open;
    audio.play("DoorOpening");
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
    audio.play("ButtonClick");
    fireTargets(level);
    return true;
  }
}

// Computadora (el escritorio del jugador): se apaga al interactuar.
class Computer extends GameObject {
  Computer(int row, int col) { super(row, col); }

  PImage texture() { return assets.computer; }

  boolean onInteract(Level level) {
    if (done) return false;
    audio.play("ComputerOFF");
    return true;
  }
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
    audio.play("LetterPicking");
    return true;
  }
}

// Cama: desordenada (BedMess) hasta que se ordena (Bed).
class Bed extends GameObject {
  Bed(int row, int col) { super(row, col); }

  PImage texture() { return done ? assets.bed : assets.bedMess; }

  boolean onInteract(Level level) {
    if (done) return false;
    audio.play("BedDoing");
    return true;
  }
}

// Suciedad en el piso: se barre al interactuar (desaparece). Cada una elige al azar
// una de las 4 texturas al crearse (ver Level.createObject).
class Grime extends GameObject {
  int variant;

  Grime(int row, int col, int variant) {
    super(row, col);
    this.variant = variant;
  }

  PImage texture() { return done ? null : assets.grime[variant]; }

  boolean onInteract(Level level) {
    if (done) return false;
    audio.play("Sweeping");
    return true;
  }
}

// Plato sucio: se recoge al interactuar (el jugador lo lleva; ver Level.dishesCarried).
class DishDirty extends GameObject {
  DishDirty(int row, int col) { super(row, col); }

  PImage texture() { return done ? null : assets.dishDirty; }

  boolean onInteract(Level level) {
    if (done) return false;
    level.dishesCarried++;
    audio.play("DishesPicking");
    return true;
  }
}

// Lavabo: lava TODOS los platos que lleve el jugador. Su tarea se cumple cuando ya no queda
// ningún plato sin lavar en el nivel; con platos pendientes, lavar no la da por cumplida aún.
class Sink extends GameObject {
  Sink(int row, int col) { super(row, col); }

  PImage texture() { return assets.sink; }

  // Solo brilla cuando hay algo que lavar.
  boolean interactive(Level level) {
    return level.dishesCarried > 0 && level.hasPendingTask(this);
  }

  boolean onInteract(Level level) {
    if (done) return false;
    if (level.dishesCarried == 0) {
      level.say("“No tengo platos que lavar.”");
      return false;
    }
    level.dishesWashed += level.dishesCarried;
    level.dishesCarried = 0;
    audio.play("DishesCleaning");
    if (!level.allDishesWashed()) {
      level.say("“Aún quedan platos por recoger.”");
      return false;
    }
    return true;
  }
}

// Plato de agua del gato: sucio (WaterDirty) hasta que se cambia (WaterClean).
class CatBowl extends GameObject {
  CatBowl(int row, int col) { super(row, col); }

  PImage texture() { return done ? assets.waterClean : assets.waterDirty; }

  boolean onInteract(Level level) {
    if (done) return false;
    audio.play("WaterPouring");
    return true;
  }
}

// Escalera: al PISARLA el jugador pasa a la escalera pareja del otro piso (se emparejan
// al cargar el nivel: ver Level.linkStairs). '^' sube (piso anterior), 'v' baja (siguiente).
class Stairs extends GameObject {
  boolean up;
  int floorIndex;
  Stairs dest = null;

  Stairs(int row, int col, boolean up) {
    super(row, col);
    this.up = up;
  }

  PImage texture() { return up ? assets.stairUp : assets.stairDown; }

  void onEnter(Level level, Player player) {
    if (dest == null) {
      level.say("Esta escalera no lleva a ningún lado.");
      return;
    }
    level.setFloor(dest.floorIndex);
    player.teleportTo(level, dest.row, dest.col);
  }
}
