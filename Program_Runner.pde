// ============================================================
//  Program_Runner.pde — La secuencia programada y su ejecución paso a paso
// ============================================================

// Lista ordenada de acciones que arma el jugador.
class Program {
  ArrayList<Integer> steps = new ArrayList<Integer>();

  void add(int action)       { steps.add(action); }
  void removeAt(int index)   { steps.remove(index); }
  void clear()               { steps.clear(); }
  int size()                 { return steps.size(); }
  int get(int index)         { return steps.get(index); }
  boolean isEmpty()          { return steps.isEmpty(); }

  void swap(int i, int j) {
    int tmp = steps.get(i);
    steps.set(i, steps.get(j));
    steps.set(j, tmp);
  }
}

// Ejecuta un Program sobre un jugador/nivel, una acción cada stepDelay ms.
// Usa un cronómetro acumulado (no la hora absoluta) para poder PAUSARSE: mientras hay una
// nota abierta el tiempo no corre y la ejecución sigue donde se quedó al cerrarla.
class ProgramRunner {
  Program program;
  Player player;
  Level level;

  boolean running = false;
  int currentStep = -1;     // -1 mientras corre = aún no empezó la primera acción
  int stepDelay = 400;      // ms entre acciones
  int startDelay = 450;     // ms mostrando la casilla de salida antes de la primera acción
  int timer = 0;            // ms acumulados desde la última acción
  int lastTick = 0;

  ProgramRunner(Program program, Player player, Level level) {
    this.program = program;
    this.player = player;
    this.level = level;
  }

  // Arranca (el estado del nivel ya debe estar reiniciado). NO ejecuta nada todavía:
  // el jugador se ve primero en su casilla de salida y la primera acción llega tras startDelay.
  void start() {
    if (program.isEmpty()) return;
    running = true;
    currentStep = -1;
    timer = 0;
    lastTick = millis();
  }

  void stop() {
    running = false;
    currentStep = -1;
  }

  // Se llama cada frame.
  void update() {
    if (!running) return;

    int now = millis();
    int dt = now - lastTick;
    lastTick = now;

    // Si el jugador cayó o ya ganó, se corta la ejecución
    if (player.fell || level.completed) {
      stop();
      return;
    }

    // Pausa: no se avanza mientras se lee una nota
    if (level.openNote != null) return;

    timer += dt;
    int wait = (currentStep < 0) ? startDelay : stepDelay;
    if (timer >= wait) {
      currentStep++;
      if (currentStep >= program.size()) {
        stop();
        return;
      }
      executeAction(program.get(currentStep), player, level);
      timer = 0;
    }
  }
}
