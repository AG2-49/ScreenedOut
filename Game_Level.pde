// ============================================================
//  Game_Level.pde — Datos de un nivel y catálogo de niveles
//
//  Cada nivel es un JSON en data/levels/ (ver README.md). El mapa es una
//  matriz de textos; cada carácter es una casilla:
//    .  suelo      W  pared      H  hueco
//    D  puerta     G  computadora (escritorio)   B  botón     N  nota
//    C  cama       S  suciedad (se barre)        P  plato sucio
//    L  lavabo     A  agua del gato              ^  escalera que sube   v  escalera que baja
//  El TERRENO (suelo/pared/hueco) va en una matriz y los OBJETOS
//  (puertas, botón, meta) en una lista, para poder ligarlos entre sí.
//
//  PISOS: un nivel puede tener varios pisos ("floors" en el JSON). Cada piso tiene su propio
//  mapa; `terrain`, `objects`, `rows` y `cols` del Level siempre describen el piso ACTUAL
//  (setFloor los cambia), así que el resto del código no necesita saber de pisos.
// ============================================================

import java.util.Random;

// Lo que piensa el jugador al intentar usar un objeto que no le han pedido usar (aún).
final String MSG_ALL_DONE = "“Ya hice todo lo que me pidieron.”";
final String MSG_NOTHING  = "“¿Tengo que hacer algo aquí?”";
final int MESSAGE_MS = 3000;   // cuánto dura un aviso sobre el mapa

// Un piso: su mapa, sus objetos y las casillas que el jugador ha pisado.
class Floor {
  String name;
  int rows, cols;
  char[][] terrain;                 // ' ' suelo, 'W' pared, 'H' hueco
  ArrayList<GameObject> objects = new ArrayList<GameObject>();
  boolean[][] visited;

  boolean inBounds(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
  }

  GameObject objectAt(int row, int col) {
    for (GameObject o : objects) {
      if (o.row == row && o.col == col) return o;
    }
    return null;
  }

  // Escaleras de este piso, en orden de lectura (fila a fila); up = '^', !up = 'v'.
  ArrayList<Stairs> stairs(boolean up) {
    ArrayList<Stairs> list = new ArrayList<Stairs>();
    for (GameObject o : objects) {
      if (o instanceof Stairs && ((Stairs) o).up == up) list.add((Stairs) o);
    }
    return list;
  }
}

class Level {
  JSONObject json;          // definición original (se reutiliza en reset())
  String id, name;
  long seed;                // semilla de las variantes de suciedad: fija por nivel abierto, así
                            // «Correr» no cambia el aspecto del piso entre intentos

  ArrayList<Floor> floors;
  int floor = 0;            // índice del piso actual
  int rows, cols;           // del piso actual
  char[][] terrain;         // del piso actual
  ArrayList<GameObject> objects;   // del piso actual
  ArrayList<Task> tasks;    // todas las tareas (las de notas sin leer aún no son visibles)
  ArrayList<Note> notes;    // de todos los pisos

  int startFloor, startRow, startCol;
  float startLooking;       // radianes, 0 = arriba, sentido horario

  int dishesCarried = 0;    // platos recogidos y aún sin lavar (los lleva el jugador)
  int dishesWashed = 0;

  boolean completed = false;
  String message = "";      // aviso breve para mostrar al jugador (usar say(); caduca solo)
  int messageUntil = 0;     // millis() hasta el que el aviso es visible

  // Reloj de introducción (opcional): ver "clock" en el JSON del nivel y ClockIntro.
  boolean hasClock = false;
  int clockFrom = 8 * 60, clockTo = 10 * 60;   // en minutos desde las 0:00 (clockTo puede pasar de 1440)
  String clockText = "";                       // frase opcional bajo el reloj
  String hint = "";                            // ayuda opcional bajo el mapa (la usan los tutoriales)

  Note openNote = null;     // nota que se está leyendo (null = ninguna); el juego se pausa mientras haya una

  Level(JSONObject json) {
    this.json = json;
    this.seed = (long) (Math.random() * 1000000000L);
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
    messageUntil = 0;
    openNote = null;
    dishesCarried = 0;
    dishesWashed = 0;

    floors = new ArrayList<Floor>();
    tasks = new ArrayList<Task>();
    notes = new ArrayList<Note>();
    Random rnd = new Random(seed);

    // ----- Mapas: "floors": [ {"name": "Piso 2", "map": [...]}, ... ]  o bien un solo "map" -----
    if (json.hasKey("floors")) {
      JSONArray list = json.getJSONArray("floors");
      for (int i = 0; i < list.size(); i++) {
        JSONObject fj = list.getJSONObject(i);
        floors.add(buildFloor(fj.getJSONArray("map"), fj.getString("name", ""), i, rnd));
      }
    } else {
      floors.add(buildFloor(json.getJSONArray("map"), "", 0, rnd));
    }
    linkStairs();

    // ----- Orientación de computadoras y escaleras: {"at": [piso, fila, col], "direction": "left"} -----
    // direction: up / right / down / left. Computadora = lado del teclado; escalera = hacia dónde
    // mira el jugador al salir por ella. Las escaleras sin orientación la deducen de las paredes.
    if (json.hasKey("orientation")) {
      JSONArray list = json.getJSONArray("orientation");
      for (int i = 0; i < list.size(); i++) {
        JSONObject oj = list.getJSONObject(i);
        int[] p = parsePos(oj.getJSONArray("at"));
        GameObject o = objectAtFloor(p[0], p[1], p[2]);
        int d = directionIndex(oj.getString("direction", "down"));
        if (o instanceof Computer) ((Computer) o).facing = d;
        else if (o instanceof Stairs) ((Stairs) o).exitDir = d;
        else println("Aviso (" + id + "): 'orientation' en " + (i) + " no apunta a una computadora ni a una escalera");
      }
    }
    for (Floor fl : floors) {
      for (GameObject o : fl.objects) {
        if (o instanceof Stairs && ((Stairs) o).exitDir < 0) ((Stairs) o).exitDir = guessStairExit(fl, (Stairs) o);
      }
    }

    // ----- Inicio del jugador -----
    // Con "row" y "col" se coloca a mano. Sin ellos, arranca sentado en la casilla de enfrente de
    // la primera computadora del piso, mirándola (así su orientación decide dónde y hacia dónde).
    JSONObject start = json.getJSONObject("start");
    startFloor = constrain(start.getInt("floor", 0), 0, floors.size() - 1);
    if (start.hasKey("row") && start.hasKey("col")) {
      startRow = start.getInt("row");
      startCol = start.getInt("col");
      startLooking = directionToAngle(start.getString("direction", "right"));
    } else {
      Computer pc = null;
      for (GameObject o : floors.get(startFloor).objects) {
        if (o instanceof Computer) { pc = (Computer) o; break; }
      }
      if (pc == null) {
        println("Aviso (" + id + "): 'start' sin fila/columna y no hay computadora en el piso inicial");
        startRow = 1;
        startCol = 1;
        startLooking = HALF_PI;
      } else {
        startRow = pc.row + DIR_ROW[pc.facing];
        startCol = pc.col + DIR_COL[pc.facing];
        startLooking = ((pc.facing + 2) % 4) * HALF_PI;
      }
    }
    setFloor(startFloor);

    // ----- Ayuda opcional (tutoriales): {"hint": "texto"} -----
    hint = json.getString("hint", "");

    // ----- Reloj de introducción: {"from": "8:00", "to": "10:00", "text": "..."} (24 h) -----
    hasClock = false;
    if (json.hasKey("clock")) {
      JSONObject c = json.getJSONObject("clock");
      clockFrom = parseTime(c.getString("from", "8:00"), 8 * 60);
      clockTo = parseTime(c.getString("to", "10:00"), 10 * 60);
      if (clockTo < clockFrom) clockTo += 24 * 60;   // cruza la medianoche
      clockText = c.getString("text", "");
      hasClock = true;
    }

    // ----- Enlaces entre objetos: {"from": [fila, col], "to": [fila, col]} -----
    // Las posiciones son [fila, col] (piso 0) o [piso, fila, col].
    if (json.hasKey("links")) {
      JSONArray links = json.getJSONArray("links");
      for (int i = 0; i < links.size(); i++) {
        JSONObject l = links.getJSONObject(i);
        int[] pa = parsePos(l.getJSONArray("from"));
        int[] pb = parsePos(l.getJSONArray("to"));
        GameObject a = objectAtFloor(pa[0], pa[1], pa[2]);
        GameObject b = objectAtFloor(pb[0], pb[1], pb[2]);
        if (a != null && b != null) {
          a.linkTo(b);
        } else {
          println("Aviso (" + id + "): enlace inválido en el índice " + i);
        }
      }
    }

    // ----- Tareas iniciales -----
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
        int[] p = parsePos(nj.getJSONArray("at"));
        GameObject o = objectAtFloor(p[0], p[1], p[2]);
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

  // Construye un piso a partir de su matriz de textos.
  Floor buildFloor(JSONArray mapRows, String floorName, int floorIndex, Random rnd) {
    Floor f = new Floor();
    f.name = floorName;
    f.rows = mapRows.size();
    f.cols = 0;
    for (int r = 0; r < f.rows; r++) {
      f.cols = max(f.cols, mapRows.getString(r).length());
    }
    f.terrain = new char[f.rows][f.cols];
    f.visited = new boolean[f.rows][f.cols];

    for (int r = 0; r < f.rows; r++) {
      String line = mapRows.getString(r);
      for (int c = 0; c < f.cols; c++) {
        char ch = c < line.length() ? line.charAt(c) : '.';

        f.terrain[r][c] = (ch == 'W' || ch == 'H') ? ch : ' ';

        GameObject obj = createObject(ch, r, c, rnd);
        if (obj != null) {
          obj.symbol = ch;
          if (obj instanceof Stairs) ((Stairs) obj).floorIndex = floorIndex;
          f.objects.add(obj);
          if (obj instanceof Note) notes.add((Note) obj);
        }
      }
    }

    // Una puerta entre dos paredes N-S (arriba y abajo) se dibuja girada.
    for (GameObject o : f.objects) {
      if (o instanceof Door) {
        ((Door) o).vertical = wallLike(f, o.row - 1, o.col) && wallLike(f, o.row + 1, o.col);
      }
    }
    return f;
  }

  boolean wallLike(Floor f, int row, int col) {
    if (!f.inBounds(row, col)) return false;
    return f.terrain[row][col] == 'W' || f.objectAt(row, col) instanceof Door;
  }

  // Empareja las escaleras: la k-ésima 'v' de cada piso con la k-ésima '^' del piso de abajo
  // (los pisos se listan de arriba hacia abajo en el JSON).
  void linkStairs() {
    for (int f = 0; f + 1 < floors.size(); f++) {
      ArrayList<Stairs> down = floors.get(f).stairs(false);
      ArrayList<Stairs> up = floors.get(f + 1).stairs(true);
      int n = min(down.size(), up.size());
      for (int k = 0; k < n; k++) {
        down.get(k).dest = up.get(k);
        up.get(k).dest = down.get(k);
      }
    }
    for (Floor fl : floors) {
      for (GameObject o : fl.objects) {
        if (o instanceof Stairs && ((Stairs) o).dest == null) {
          println("Aviso (" + id + "): la escalera en fila " + o.row + ", columna " + o.col + " no tiene pareja");
        }
      }
    }
  }

  // Cambia el piso actual (actualiza los alias que usa el resto del código).
  void setFloor(int index) {
    floor = constrain(index, 0, floors.size() - 1);
    Floor f = floors.get(floor);
    rows = f.rows;
    cols = f.cols;
    terrain = f.terrain;
    objects = f.objects;
  }

  String floorName() {
    return floors.get(floor).name;
  }

  boolean hasManyFloors() {
    return floors.size() > 1;
  }

  // ----- Casillas pisadas (para las tareas de «llegar a») -----
  void markVisited(int row, int col) {
    Floor f = floors.get(floor);
    if (f.inBounds(row, col)) f.visited[row][col] = true;
  }

  boolean wasVisited(int floorIndex, int row, int col) {
    if (floorIndex < 0 || floorIndex >= floors.size()) return false;
    Floor f = floors.get(floorIndex);
    return f.inBounds(row, col) && f.visited[row][col];
  }

  // "H:MM" (24 h) -> minutos desde las 0:00. Con formato inválido avisa y usa 'fallback'.
  int parseTime(String s, int fallback) {
    try {
      String[] p = s.trim().split(":");
      int h = Integer.parseInt(p[0].trim());
      int m = p.length > 1 ? Integer.parseInt(p[1].trim()) : 0;
      return h * 60 + m;
    } catch (Exception e) {
      println("Aviso (" + id + "): hora inválida \"" + s + "\", se usa " + fallback / 60 + ":00");
      return fallback;
    }
  }

  // [fila, col] -> {0, fila, col};  [piso, fila, col] -> {piso, fila, col}
  int[] parsePos(JSONArray a) {
    if (a.size() >= 3) return new int[]{a.getInt(0), a.getInt(1), a.getInt(2)};
    return new int[]{0, a.getInt(0), a.getInt(1)};
  }

  // Crea una tarea; devuelve null (con aviso) si no tiene objetivo válido, para no bloquear el nivel.
  //   {"text": "...", "target": [fila, col]}            un objeto
  //   {"text": "...", "targets": [[f, c], [f, c]]}      varios objetos
  //   {"text": "...", "all": "S"}                       todos los objetos de ese carácter del mapa
  //                                                      ("floor": n limita a ese piso)
  //   {"text": "...", "reach": [fila, col]}             se cumple al pisar esa casilla
  Task parseTask(JSONObject tj, boolean revealed) {
    String text = tj.getString("text", "?");
    Task t = new Task(this, text, revealed);

    if (tj.hasKey("reach")) {
      int[] p = parsePos(tj.getJSONArray("reach"));
      Floor f = (p[0] >= 0 && p[0] < floors.size()) ? floors.get(p[0]) : null;
      if (f == null || !f.inBounds(p[1], p[2])) {
        println("Aviso (" + id + "): tarea \"" + text + "\" con casilla de llegada fuera del mapa");
        return null;
      }
      t.setReach(p[0], p[1], p[2]);
      return t;
    }

    if (tj.hasKey("all")) {
      char sym = tj.getString("all").charAt(0);
      int onlyFloor = tj.getInt("floor", -1);
      for (int fi = 0; fi < floors.size(); fi++) {
        if (onlyFloor >= 0 && fi != onlyFloor) continue;
        for (GameObject o : floors.get(fi).objects) {
          if (o.symbol == sym) t.targets.add(o);
        }
      }
    }
    if (tj.hasKey("targets")) {
      JSONArray list = tj.getJSONArray("targets");
      for (int i = 0; i < list.size(); i++) {
        int[] p = parsePos(list.getJSONArray(i));
        GameObject o = objectAtFloor(p[0], p[1], p[2]);
        if (o != null) t.targets.add(o);
      }
    }
    if (tj.hasKey("target")) {
      int[] p = parsePos(tj.getJSONArray("target"));
      GameObject o = objectAtFloor(p[0], p[1], p[2]);
      if (o != null) t.targets.add(o);
    }

    if (t.targets.isEmpty()) {
      println("Aviso (" + id + "): tarea \"" + text + "\" sin ningún objeto en las posiciones indicadas");
      return null;
    }
    return t;
  }

  // Fábrica: qué objeto corresponde a cada carácter del mapa (null = solo terreno).
  GameObject createObject(char ch, int row, int col, Random rnd) {
    switch (ch) {
      case 'D': return new Door(row, col);
      case 'G': return new Computer(row, col);
      case 'B': return new FloorButton(row, col);
      case 'N': return new Note(row, col);
      case 'C': return new Bed(row, col);
      case 'S': return new Grime(row, col, rnd.nextInt(4));
      case 'P': return new DishDirty(row, col);
      case 'L': return new Sink(row, col);
      case 'A': return new CatBowl(row, col);
      case '^': return new Stairs(row, col, true);
      case 'v': return new Stairs(row, col, false);
      default:  return null;
    }
  }

  // Direcciones como índice: 0 arriba, 1 derecha, 2 abajo, 3 izquierda (como el ángulo, en cuartos de vuelta)
  final int[] DIR_ROW = {-1, 0, 1, 0};
  final int[] DIR_COL = {0, 1, 0, -1};

  int directionIndex(String dir) {
    if (dir.equals("up")) return 0;
    if (dir.equals("right")) return 1;
    if (dir.equals("left")) return 3;
    return 2; // "down" y cualquier otro valor
  }

  // Salida por defecto de una escalera: hacia el lado libre que tenga una pared justo detrás
  // (el pozo contra la pared); si no hay ninguno, hacia el primer lado libre.
  int guessStairExit(Floor f, Stairs s) {
    int firstFree = -1;
    for (int d = 0; d < 4; d++) {
      boolean free = f.inBounds(s.row + DIR_ROW[d], s.col + DIR_COL[d]) && f.terrain[s.row + DIR_ROW[d]][s.col + DIR_COL[d]] != 'W';
      if (!free) continue;
      if (firstFree < 0) firstFree = d;
      int back = (d + 2) % 4;
      int br = s.row + DIR_ROW[back], bc = s.col + DIR_COL[back];
      if (!f.inBounds(br, bc) || f.terrain[br][bc] == 'W') return d;
    }
    return firstFree < 0 ? 2 : firstFree;
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

  // Objeto del piso ACTUAL en esa casilla.
  GameObject objectAt(int row, int col) {
    for (GameObject o : objects) {
      if (o.row == row && o.col == col) return o;
    }
    return null;
  }

  // Objeto de cualquier piso (para leer el JSON).
  GameObject objectAtFloor(int floorIndex, int row, int col) {
    if (floorIndex < 0 || floorIndex >= floors.size()) return null;
    return floors.get(floorIndex).objectAt(row, col);
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

  // ----- Avisos sobre el mapa -----
  void say(String text) {
    message = text;
    messageUntil = millis() + MESSAGE_MS;
  }

  void clearMessage() {
    message = "";
  }

  // El aviso vigente ("" si no hay o ya caducó).
  String activeMessage() {
    return (message.length() > 0 && millis() < messageUntil) ? message : "";
  }

  // ----- Tareas y objetos: qué se puede usar y cuándo -----
  // Un objeto está BLOQUEADO si es el objetivo de alguna tarea pero ninguna de ellas
  // se ha revelado todavía (falta leer la nota que la añade). Hasta entonces el jugador
  // "no sabe" que debe usarlo. Los objetos que no son objetivo de ninguna tarea
  // (puertas de paso, botones sueltos...) nunca se bloquean.
  boolean isLocked(GameObject o) {
    boolean isTarget = false;
    for (Task t : tasks) {
      if (!t.hasTarget(o)) continue;
      if (t.revealed) return false;
      isTarget = true;
    }
    return isTarget;
  }

  // ¿Hay alguna tarea visible, sin cumplir, que apunte a este objeto (y que él aún no haya cumplido)?
  boolean hasPendingTask(GameObject o) {
    for (Task t : tasks) {
      if (t.hasTarget(o) && t.revealed && !o.done && !t.isDone()) return true;
    }
    return false;
  }

  // Aviso al intentar usar un objeto bloqueado: si ya no queda nada visible por hacer,
  // "ya hice todo"; si queda algo pendiente (u hoy no hay tareas), "¿tengo que hacer algo aquí?".
  void sayLocked() {
    int revealed = 0;
    boolean allDone = true;
    for (Task t : tasks) {
      if (!t.revealed) continue;
      revealed++;
      if (!t.isDone()) allDone = false;
    }
    say((revealed > 0 && allDone) ? MSG_ALL_DONE : MSG_NOTHING);
  }

  int notesRead() {
    int n = 0;
    for (Note note : notes) {
      if (note.read) n++;
    }
    return n;
  }

  // ----- Platos: cuántos hay en total (en todos los pisos) y si ya se lavaron todos -----
  int dishesTotal() {
    int n = 0;
    for (Floor f : floors) {
      for (GameObject o : f.objects) {
        if (o instanceof DishDirty) n++;
      }
    }
    return n;
  }

  boolean allDishesWashed() {
    return dishesWashed >= dishesTotal();
  }
}


// ============================================================
//  Catálogo: lista ordenada de niveles (data/levels/index.json)
// ============================================================
class LevelCatalog {
  String folder;            // subcarpeta de data/ ("levels", "tutorials"...)
  ArrayList<String> ids = new ArrayList<String>();
  ArrayList<String> names = new ArrayList<String>();

  LevelCatalog(String folder) {
    this.folder = folder;
  }

  void load() {
    JSONArray list = loadJSONObject(folder + "/index.json").getJSONArray("levels");
    for (int i = 0; i < list.size(); i++) {
      String id = list.getString(i);
      ids.add(id);
      names.add(loadJSONObject(folder + "/" + id + ".json").getString("name", id));
    }
  }

  int count() { return ids.size(); }
  String idAt(int index) { return ids.get(index); }
  String nameAt(int index) { return names.get(index); }

  Level create(int index) {
    return new Level(loadJSONObject(folder + "/" + ids.get(index) + ".json"));
  }
}
