# Battle Cries (`tato-BattleCries`)

A Brotato (Godot 3.x / GodotModLoader 6.x) mod that plays a **random character voice
line at the start of every wave**. In **co-op only the first player (the leader) speaks**.

## How it works

- **Wave-start hook** — `extensions/ui/hud/wave_timer.gd` extends the game's wave timer.
  That timer is re-created at the start of every wave, so its `_ready` is a reliable
  per-wave trigger. The extension only calls `._ready()` and then asks the player node to
  speak — it connects no game signals.
- **Leader = player 0** — `lib/voice_player.gd` reads `RunData.players_data[0]` (falling
  back to `RunData.current_character`). Player 0 is the host, treated as the leader, so
  co-op naturally only plays the first character's voice.
- **Character → voice slug** — the game id `character_x_y` maps to the folder slug `x-y`
  (e.g. `character_arms_dealer` → `arms-dealer`), with the one exception
  `character_one_arm` → `one-armed`. Modded/unknown characters simply stay silent.
- **Audio** — clips are bundled `.mp3` files read as raw bytes into an `AudioStreamMP3`
  (the engine ships `.mp3` support for the game's music). Loaded streams are cached.

## Voice clips

The `.mp3` clips live in `voices/<slug>/<slug>_NN.mp3` (10 per character) — this mod is
their single home (the web app does not use them). `voices/CHECKLIST.md` documents the
per-character voice/pitch/effect map and is excluded from the shipped zip.

## Build / test / publish

```bash
./build-zip.sh                  # -> dist/tato-BattleCries.zip (voices staged in)
./publish-steamcmd.sh <account> # upload to Steam Workshop (needs thumbnail.png)
```

To test locally before publishing, upload `dist/tato-BattleCries.zip` via
GodotWorkshopUtility (ships in the Brotato folder), subscribe, and relaunch.

Add a `thumbnail.png` (any size Steam accepts) before publishing — the
publish script errors if it is missing.

> Keep `config.gd` `MOD_VERSION` in sync with `manifest.json` `version_number`.
