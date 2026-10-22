// ============================================================
//  Save_Progress.pde — Progreso entre sesiones (data/save.json)
//  Guarda solo QUÉ niveles se completaron (no el estado dentro de un nivel).
//  "Desbloqueado" se deduce: el nivel i se abre al completar el i-1.
// ============================================================

import java.util.HashSet;

class Progress {
  HashSet<String> completed = new HashSet<String>();

  String path() {
    return dataPath("save.json");
  }

  void load() {
    File f = new File(path());
    if (!f.exists()) return;

    JSONObject json = loadJSONObject(path());
    if (json == null || !json.hasKey("completed")) return;

    JSONArray list = json.getJSONArray("completed");
    for (int i = 0; i < list.size(); i++) {
      completed.add(list.getString(i));
    }
  }

  void save() {
    JSONArray list = new JSONArray();
    for (String id : completed) {
      list.append(id);
    }
    JSONObject json = new JSONObject();
    json.setJSONArray("completed", list);
    saveJSONObject(json, path());
  }

  boolean isCompleted(String levelId) {
    return completed.contains(levelId);
  }

  boolean isUnlocked(int levelIndex) {
    if (levelIndex == 0) return true;
    return completed.contains(levels.idAt(levelIndex - 1));
  }

  void markCompleted(String levelId) {
    if (completed.add(levelId)) save();
  }

  void reset() {
    completed.clear();
    save();
  }
}
