// ============================================================
//  Program_Actions.pde — Catálogo de acciones programables
//  Para añadir una acción: nueva constante, etiqueta, ícono (Assets.iconPalette/iconRow)
//  y un case en executeAction().
// ============================================================

final int ACT_FORWARD    = 0;
final int ACT_TURN_LEFT  = 1;
final int ACT_TURN_RIGHT = 2;
final int ACT_INTERACT   = 3;

final int ACTION_COUNT = 4;
String[] ACTION_LABELS = {"Avanzar", "Girar Izq.", "Girar Der.", "Interactuar"};

// Traduce una acción a su efecto sobre el jugador y el nivel.
void executeAction(int action, Player player, Level level) {
  switch (action) {
    case ACT_FORWARD:
      player.moveForward(level);
      break;
    case ACT_TURN_LEFT:
      player.turn(-1);
      break;
    case ACT_TURN_RIGHT:
      player.turn(1);
      break;
    case ACT_INTERACT:
      player.interact(level);
      break;
  }
}
