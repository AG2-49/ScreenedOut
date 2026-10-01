// ============================================================
//  Game_Tasks.pde — Tareas de un nivel
//  Una tarea es un texto + el objeto con el que hay que interactuar.
//  Se considera cumplida cuando ese objeto registra una interacción exitosa
//  (GameObject.done). Las tareas iniciales están visibles desde el principio;
//  las que añade una nota se revelan al leerla (ver Note).
// ============================================================

class Task {
  String text;
  GameObject target;
  boolean revealed;     // ¿ya aparece en la lista del jugador?

  Task(String text, GameObject target, boolean revealed) {
    this.text = text;
    this.target = target;
    this.revealed = revealed;
  }

  boolean isDone() {
    return target.done;
  }
}
