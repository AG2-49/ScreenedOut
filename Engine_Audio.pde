// ============================================================
//  Engine_Audio.pde — Música y efectos de sonido (librería Minim)
//
//  Requiere la librería «Minim» (Sketch ▸ Importar librería ▸ Gestionar librerías).
//  Los archivos viven en data/Assets/sounds/.
//
//  USO desde el resto del juego (todo pasa por la variable global `audio`):
//    audio.play("DoorOpening");     efecto suelto (si ya sonaba, se reinicia: nunca se apila)
//    audio.stop("ClockTick");       lo corta
//    audio.walkStep(ms);            «di un paso»: arranca/mantiene el bucle de pasos ms milisegundos
//    audio.stopWalk();              «hice otra cosa»: el bucle se apaga con un fundido corto
//    audio.silence();               corta TODO lo que no sea música (al reiniciar el nivel o cambiar de pantalla)
//
//  PASOS: Walk.mp3 dura ~2 s y trae varias pisadas, así que en vez de lanzarlo en cada
//  casilla (se solaparía) se reproduce en BUCLE mientras el jugador siga caminando:
//    · cada paso exitoso llama a walkStep(), que fija hasta cuándo debe seguir sonando
//      (walkUntil) y, si no estaba sonando, lo arranca desde el principio;
//    · cualquier otra acción (girar, interactuar, chocar, caer...) llama a stopWalk();
//    · si nadie renueva el plazo (se acabó el programa, soltaste la tecla...), update()
//      lo apaga solo cuando vence walkUntil.
// ============================================================

import ddf.minim.*;

class Audio {
  // ----- Catálogo: nombre de archivo (sin extensión) y ganancia en dB -----
  // Minim solo admite hasta +6 dB. Algunos archivos (BedDoing, Sweeping, ClockTick) están
  // grabados muy bajos y otros muy altos, así que aquí se igualan a ojo. Ajusta a gusto.
  String[] SFX_FILES = {"BedDoing", "ButtonClick", "ClockTick", "ComputerOFF", "DishesCleaning",
                        "DishesPicking", "DoorOpening", "LetterPicking", "Sweeping", "WaterPouring"};
  float[]  SFX_GAIN  = {      6,         -3,           6,           0,            -2,
                              -6,           -10,           -1,            6,           2};

  float WALK_GAIN = -7;        // dB del bucle de pasos
  int   WALK_FADE_MS = 110;    // duración del fundido al cortar los pasos

  float MUSIC_GAIN_MENU  = -12;   // dB de la música en menús
  float MUSIC_GAIN_LEVEL = -22;   // dB de la música dentro de un nivel (más baja para oír los efectos)

  Minim minim;
  HashMap<String, AudioPlayer> sfx = new HashMap<String, AudioPlayer>();
  AudioPlayer music, walk;

  boolean muted = false;
  boolean inLevel = false;
  float musicGainNow = -80;    // ganancia aplicada ahora (se acerca suavemente a la deseada)

  // Pasos
  boolean walking = false;     // ¿el bucle está sonando (o desvaneciéndose)?
  boolean walkFading = false;
  int walkUntil = 0;           // millis() hasta el que se mantiene
  int walkFadeStart = 0;

  Audio(Object sketch) {
    minim = new Minim(sketch);
  }

  void load() {
    String dir = "Assets/sounds/";
    for (int i = 0; i < SFX_FILES.length; i++) {
      AudioPlayer p = minim.loadFile(dir + SFX_FILES[i] + ".mp3");
      if (p == null) {
        println("Aviso (audio): no se pudo cargar " + SFX_FILES[i] + ".mp3");
        continue;
      }
      setGain(p, SFX_GAIN[i]);
      sfx.put(SFX_FILES[i], p);
    }

    walk = minim.loadFile(dir + "Walk.mp3");
    if (walk == null) println("Aviso (audio): no se pudo cargar Walk.mp3");
    else setGain(walk, WALK_GAIN);

    // El tema es un WAV de ~34 MB: Minim lo lee en streaming, no lo carga entero en memoria.
    music = minim.loadFile(dir + "ThemeMain.wav");
    if (music == null) println("Aviso (audio): no se pudo cargar ThemeMain.wav");
  }

  // Minim lanza un aviso si el dispositivo no tiene control de ganancia: se comprueba antes.
  void setGain(AudioPlayer p, float db) {
    if (p != null && p.hasControl(Controller.GAIN)) p.setGain(db);
  }

  // ============================================================
  //  Efectos sueltos
  // ============================================================
  void play(String name) {
    if (muted) return;
    AudioPlayer p = sfx.get(name);
    if (p == null) return;
    p.rewind();
    p.play();
  }

  void stop(String name) {
    AudioPlayer p = sfx.get(name);
    if (p == null) return;
    p.pause();
    p.rewind();
  }

  // Corta todos los efectos y los pasos al instante (la música sigue).
  void silence() {
    for (String name : sfx.keySet()) stop(name);
    if (walk != null && walking) {
      walk.pause();
      walk.rewind();
    }
    walking = false;
    walkFading = false;
  }

  // ============================================================
  //  Pasos
  // ============================================================
  // Se llama al cambiar de casilla. holdMs = cuánto debe seguir sonando si no llega otro paso.
  void walkStep(int holdMs) {
    if (muted || walk == null) return;
    walkUntil = millis() + holdMs;
    if (!walking) {
      walk.rewind();            // la primera pisada coincide con el primer paso
      walk.loop();
      walking = true;
    }
    if (walkFading) {           // llegó otro paso mientras se apagaba: se retoma
      walkFading = false;
      setGain(walk, WALK_GAIN);
    }
  }

  // Cualquier acción que no sea caminar: los pasos se apagan con un fundido corto.
  void stopWalk() {
    if (!walking || walkFading) return;
    walkFading = true;
    walkFadeStart = millis();
  }

  // ============================================================
  //  Música
  // ============================================================
  void startMusic() {
    if (music == null) return;
    music.rewind();
    music.loop();
  }

  void setInLevel(boolean value) {
    inLevel = value;
  }

  void toggleMute() {
    muted = !muted;
    if (muted) silence();
  }

  // ============================================================
  //  Se llama cada frame (Main.draw)
  // ============================================================
  void update() {
    // --- Pasos: vencimiento del plazo y fundido de salida ---
    if (walking) {
      if (!walkFading && millis() >= walkUntil) {
        walkFading = true;
        walkFadeStart = millis();
      }
      if (walkFading) {
        float t = (millis() - walkFadeStart) / (float) WALK_FADE_MS;
        if (t >= 1) {
          walk.pause();
          walk.rewind();
          setGain(walk, WALK_GAIN);
          walking = false;
          walkFading = false;
        } else {
          setGain(walk, WALK_GAIN - 40 * t);
        }
      }
    }

    // --- Música: se acerca suavemente a su volumen (menú / nivel / silenciada) ---
    if (music != null) {
      float target = muted ? -80 : (inLevel ? MUSIC_GAIN_LEVEL : MUSIC_GAIN_MENU);
      musicGainNow = lerp(musicGainNow, target, 0.06);
      if (abs(musicGainNow - target) < 0.1) musicGainNow = target;
      setGain(music, musicGainNow);
    }
  }

  void close() {
    for (AudioPlayer p : sfx.values()) p.close();
    if (walk != null) walk.close();
    if (music != null) music.close();
    minim.stop();
  }
}
