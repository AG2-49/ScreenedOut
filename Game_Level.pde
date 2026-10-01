// ============================================================
//  Game_Level.pde — Datos de un nivel y catálogo de niveles
//
//  Cada nivel es un JSON en data/levels/ (ver README.md). El mapa es una
//  matriz de textos; cada carácter es una casilla:
//    .  suelo      W  pared      H  hueco
//    D  puerta     G  computadora (escritorio)   B  botón     N  nota
//  El TERRENO (suelo/pared/hueco) va en una matriz y los OBJETOS
//  (puertas, botón, meta) en una lista, para poder ligarlos entre sí.
// ============================================================

class Level {
  JSONObject json;          // definición original (se reutiliza en reset())
  String id, name;
  int rows, cols;
  char[][] terrain;         // ' ' suelo, 'W' pared, 'H' hueco
  ArrayList<GameObject> objects;
  ArrayList<Task> tasks;    // todas las tareas (las de notas sin leer aún no son visibles)
  ArrayList<Note> notes;

  int startRow, startCol;
  float startLooking;       // radianes, 0 = arriba, sentido horario

  boolean completed = false;
  String message = "";      // aviso breve para mostrar al jugador
  Note openNote = null;     // nota que se está leyendo (null = ninguna); el juego se pausa mientras haya una

  Level(JSONObject json) {
    this.json = json;
    build();
  }

  // Vuelve el nivel a su estado inicial (puertas cerradas, botones sueltos...).
  void reset() {
    build();
  }

  void build() {
    id = json.getString("id");
    name = json.getString("name", id);
    completed = false;
    message = "";
    openNote = null;

    // ----- Mapa -----
    JSONArray mapRows = json.getJSONArray("map");
    rows = mapRows.size();
    cols = 0;
    for (int r = 0; r < rows; r++) {
      cols = max(cols, mapRows.getString(r).length());
    }

    terrain = new char[rows][cols];
    objects = new ArrayList<GameObject>();
    tasks = new ArrayList<Task>();
    notes = new ArrayList<Note>();

    for (int r = 0; r < rows; r++) {
      String line = mapRows.getString(r);
      for (int c = 0; c < cols; c++) {
        char ch = c < line.length() ? line.charAt(c) : '.';

        terrain[r][c] = (ch == 'W' || ch == 'H') ? ch : ' ';

        GameObject obj = createObject(ch, r, c);
        if (obj != null) {
          objects.add(obj);
          if (obj instanceof Note) notes.add((Note) obj);
        }
      }
    }

    // ----- Inicio del jugador -----
    JSONObject start = json.getJSONObject("start");
    startRow = start.getInt("row");
    startCol = start.getInt("col");
    startLooking = directionToAngle(start.getString("direction", "right"));

    // ----- Enlaces entre objetos: {"from": [fila, col], "to": [fila, col]} -----
    if (json.hasKey("links")) {
      JSONArray links = json.getJSONArray("links");
      for (int i = 0; i < links.size(); i++) {
        JSONObject l = links.getJSONObject(i);
        JSONArray from = l.getJSONArray("from");
        JSONArray to = l.getJSONArray("to");
        GameObject a = objectAt(from.getInt(0), from.getInt(1));
        GameObject b = objectAt(to.getInt(0), to.getInt(1));
        if (a != null && b != null) {
          a.linkTo(b);
        } else {
          println("Aviso (" + id + "): enlace inválido en el índice " + i);
        }
      }
    }

    // ----- Tareas iniciales: {"text": "...", "target": [fila, col]} -----
    if (json.hasKey("tasks")) {
      JSONArray list = json.getJSONArray("tasks");
      for (int i = 0; i < list.size(); i++) {
        Task t = parseTask(list.getJSONObject(i), true);
        if (t != null) tasks.add(t);
      }
    }

    // ----- Notas: {"at": [fila, col], "text": "...", "tasks": [ ...tareas que añade... ]} -----
    // La nota debe existir en el mapa con el carácter 'N' en esa posición.
    if (json.hasKey("notes")) {
      JSONArray list = json.getJSONArray("notes");
      for (int i = 0; i < list.size(); i++) {
        JSONObject nj = list.getJSONObject(i);
        JSONArray at = nj.getJSONArray("at");
        GameObject o = objectAt(at.getInt(0), at.getInt(1));
        if (!(o instanceof Note)) {
          println("Aviso (" + id + "): no hay una nota 'N' en el mapa para la entrada " + i + " de notes");
          continue;
        }
        Note n = (Note) o;
        n.text = nj.getString("text", "");
        if (nj.hasKey("tasks")) {
          JSONArray added = nj.getJSONArray("tasks");
          for (int k = 0; k < added.size(); k++) {
            Task t = parseTask(added.getJSONObject(k), false);
            if (t != null) {
              n.addedTasks.add(t);
              tasks.add(t);
            }
          }
        }
      }
    }
  }

  // Crea una tarea; devuelve null (con aviso) si su objeto no existe, para no bloquear el nivel.
  Task parseTask(JSONObject tj, boolean revealed) {
    JSONArray p = tj.getJSONArray("target");
    GameObject target = objectAt(p.getInt(0), p.getInt(1));
    if (target == null) {
      println("Aviso (" + id + "): tarea \"" + tj.getString("text", "?") + "\" sin objeto en la posición indicada");
      return null;
    }
    return new Task(tj.getString("text", ""), target, revealed);
  }

  // Fábrica: qué objeto corresponde a cada carácter del mapa (null = solo terreno).
  GameObject createObject(char ch, int row, int col) {
    switch (ch) {
      case 'D': return new Door(row, col);
      case 'G': return new Computer(row, col);
      case 'B': return new FloorButton(row, col);
      case 'N': return new Note(row, col);
      default:  return null;
    }
  }

  float directionToAngle(String dir) {
    if (dir.equals("up")) return 0;
    if (dir.equals("down")) return PI;
    if (dir.equals("left")) return -HALF_PI;
    return HALF_PI; // "right" y cualquier otro valor
  }

  boolean inBounds(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
  }

  char terrainAt(int row, int col) {
    return terrain[row][col];
  }

  GameObject objectAt(int row, int col) {
    for (GameObject o : objects) {
      if (o.row == row && o.col == col) return o;
    }
    return null;
  }

  // El nivel se completa al leer TODAS las notas y cumplir TODAS las tareas
  // (incluidas las que añaden las notas). Un nivel sin tareas ni notas no se completa solo.
  boolean allGoalsMet() {
    if (tasks.isEmpty() && notes.isEmpty()) return false;
    for (Note n : notes) {
      if (!n.read) return false;
    }
    for (Task t : tasks) {
      if (!t.isDone()) return false;
    }
    return true;
  }

  // Se llama cada frame desde la pantalla del nivel.
  // No se completa mientras haya una nota abierta: primero hay que cerrarla.
  void updateCompletion() {
    if (openNote != null) return;
    if (!completed && allGoalsMet()) completed = true;
  }

  int notesRead() {
    int n = 0;
    for (Note note : notes) {
      if (note.read) n++;
    }
    return n;
  }
}


// ============================================================
//  Catálogo: lista ordenada de niveles (data/levels/index.json)
// ============================================================
class LevelCatalog {
  ArrayList<String> ids = new ArrayList<String>();
  ArrayList<String> names = new ArrayList<String>();

  void load() {
    JSONArray list = loadJSONObject("levels/index.json").getJSONArray("levels");
    for (int i = 0; i < list.size(); i++) {
      String id = list.getString(i);
      ids.add(id);
      names.add(loadJSONObject("levels/" + id + ".json").getString("name", id));
    }
  }

  int count() { return ids.size(); }
  String idAt(int index) { return ids.get(index); }
  String nameAt(int index) { return names.get(index); }

  Level create(int index) {
    return new Level(loadJSONObject("levels/" + ids.get(index) + ".json"));
  }
}
