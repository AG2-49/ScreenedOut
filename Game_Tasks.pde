// ============================================================
//  Game_Tasks.pde — Tareas de un nivel
//  Hay dos clases de tarea:
//    · INTERACTUAR: texto + uno o VARIOS objetos (todos deben registrar una interacción
//      exitosa, GameObject.done). Ej.: «Barrer el piso» apunta a todas las suciedades.
//      Con varios objetos, la lista muestra el avance «(2/5)».
//    · LLEGAR: se cumple al pisar una casilla concreta (ej.: «Salir de tu habitación»).
//  Las tareas iniciales están visibles desde el principio; las que añade una nota
//  se revelan al leerla (ver Note).
// ============================================================

class Task {
  Level level;
  String text;
  ArrayList<GameObject> targets = new ArrayList<GameObject>();
  int reachFloor = -1, reachRow, reachCol;   // tarea de «llegar»: reachFloor >= 0
  boolean revealed;     // ¿ya aparece en la lista del jugador?

  Task(Level level, String text, boolean revealed) {
    this.level = level;
    this.text = text;
    this.revealed = revealed;
  }

  void setReach(int floor, int row, int col) {
    reachFloor = floor;
    reachRow = row;
    reachCol = col;
  }

  boolean isReach() { return reachFloor >= 0; }

  boolean hasTarget(GameObject o) { return targets.contains(o); }

  boolean isDone() {
    if (isReach()) return level.wasVisited(reachFloor, reachRow, reachCol);
    if (targets.isEmpty()) return false;
    for (GameObject o : targets) {
      if (!o.done) return false;
    }
    return true;
  }

  int doneCount() {
    int n = 0;
    for (GameObject o : targets) {
      if (o.done) n++;
    }
    return n;
  }

  // Texto para la lista, con el avance si hay varios objetos.
  String label() {
    if (!isReach() && targets.size() > 1) return text + " (" + doneCount() + "/" + targets.size() + ")";
    return text;
  }
}
