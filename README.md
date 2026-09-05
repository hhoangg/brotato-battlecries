# Battle Cries

A mod for [Brotato](https://store.steampowered.com/app/1942280/Brotato/) that gives every
character a voice. When a wave starts, your character shouts a random line; during a run you
can hold a key or a controller trigger to open an emote wheel and play an emotion voice on
demand. All 64 base characters are voiced, each with its own delivery, pitch and effect
colour. The mod is written in GDScript for Godot 3.x and loads through
[Godot Mod Loader](https://github.com/GodotModding/godot-mod-loader) 6.x.

The voice clips are **AI-generated** (see [Regenerating the voices](#regenerating-the-voices)).
They are in English; on-screen labels follow the in-game language.

## Features

- **Wave-start bark.** `extensions/ui/hud/wave_timer.gd` extends the game's wave timer, which
  is re-created at the start of every wave, so its `_ready` is a reliable per-wave trigger.
  It asks the persistent voice player to play a random clip from the `ready` category for
  player 0. In co-op that is the leader (the host) only - the other players do not bark
  automatically.
- **Emote wheel.** Hold `T` on the keyboard, or the L2 trigger on a controller, to open a
  wheel with six emotions: Laugh, Cheer, Taunt, Nooo!, Hurt, Quip. Aim with the mouse (if you
  opened it with the keyboard) or the right analog stick (if you opened it with a pad), then
  release to play the emotion you are pointing at. Releasing while pointing at the centre
  plays nothing. The game is **not** paused while the wheel is open.
- **Per-player in co-op.** The wheel belongs to the device that opened it. That device is
  matched against `CoopService.connected_players` to work out which co-op player it is, so
  each player emotes with their own character, and the wheel shows that character's icon in
  the middle. Only one wheel can be open at a time; while it is open, other players' open
  and close inputs are ignored, so nobody can close someone else's wheel.
- **Run-only.** The wheel only opens while a run is active (a character has been chosen,
  through to game over). On the main menu the trigger passes through untouched.
- **Audio toggle.** The mod injects a "Character Voices" check button into
  **Settings > Audio**, cloned from the tab's existing toggles so it matches the game's
  style. Turning it off stops any playing clip, silences the wave-start barks and prevents
  the wheel from opening. The choice is saved to `user://tato_battlecries.cfg` and is read
  back on the next launch. The toggle's label is translated into 16 languages and re-picks
  itself live when you change the game's language.

## Install

1. Subscribe to **Godot Mod Loader** on the Steam Workshop and make sure mods are enabled
   for Brotato.
2. Subscribe to the Battle Cries Workshop item:
   <https://steamcommunity.com/sharedfiles/filedetails/?id=3742196613>
3. Launch the game. The mod prints `[BattleCries] loaded v<version>` to the Godot log when it
   loads.

If your Godot build has no `AudioStreamMP3` class, the mod logs a warning and disables
itself instead of erroring - the clips are mp3 and are decoded through that class.

## Controls and settings

| Action | Keyboard | Controller |
| --- | --- | --- |
| Open the emote wheel | hold `T` | hold L2 |
| Aim | mouse | right analog stick |
| Emote | release the key | release the trigger |

L2 is read both as a digital joypad button (index 6) and as an analog axis (axis 6, with
press/release thresholds of 0.6/0.4), because some pads report it only one way. The wheel's
input is handled as raw physical events and is consumed only when the mod actually acts, so
arrows, D-pad and left stick keep working as normal menu navigation.

There is no in-game rebind. To change the key or button, edit `WHEEL_KEY`, `WHEEL_BUTTON`
and `WHEEL_TRIGGER_AXIS` in `mods-unpacked/tato-BattleCries/config.gd` and rebuild.

Other things you can tune in `config.gd`: `VOLUME_DB` (playback level), `WAVE_START_CATEGORY`
(which folder the wave-start bark is drawn from), the wheel `CATEGORIES` list and its labels.

The on/off switch is in **Settings > Audio > Character Voices**, in the main menu and in the
in-run options alike.

## Building from source

```bash
./build-zip.sh
```

Produces `dist/tato-BattleCries.zip`. The zip's internal layout is
`mods-unpacked/tato-BattleCries/...`, which is what the ModLoader expects (it mounts the zip
at `res://`). `voices/CHECKLIST.md` and `.DS_Store` files are excluded. The script prints the
number of bundled clips and the first entries of the archive so you can check the layout.

To try a build without publishing, upload the zip with GodotWorkshopUtility (it ships in the
Brotato folder), subscribe, and relaunch.

Publishing to the Steam Workshop:

```bash
./publish-steamcmd.sh <steam_account>
```

This builds the zip, stages a content folder holding only that zip, renders
`workshop_item.vdf` with absolute paths, and uploads via `steamcmd`. It needs `steamcmd`
installed, a Steam account that owns Brotato and the item, and `thumbnail.jpeg` present. The
title and description that end up on the Workshop page come from `workshop_item.vdf`.

## Local development loop

`sync-to-mac.sh` is the fast iteration loop on macOS. Brotato's shipped build loads mods only
from the Steam Workshop content directory - it ignores a local `mods/` or `mods-unpacked/` -
so the script builds the zip and copies it straight into the downloaded Workshop folder of
the published item, replacing whatever zip is there:

```bash
./sync-to-mac.sh                       # uses the default item id
WS_ITEM=<published_item_id> ./sync-to-mac.sh
WS_DIR=<path> ./sync-to-mac.sh         # or point at the folder directly
```

Prerequisite: the item must have been published once and subscribed to, so Steam has
downloaded it and the folder exists. Then relaunch Brotato to load the new build (modding
branch, `--enable-mods`).

Caveat, stated in the script: this overwrites Steam-managed files. Steam may revert them when
you verify the game's file integrity or when the item is updated server-side. For a real
release, upload through `publish-steamcmd.sh`.

The emote wheel draws the mod version in the bottom-right corner while it is open, so a
glance in-game tells you which build is actually loaded.

## Project layout

```
build-zip.sh                 build dist/tato-BattleCries.zip
sync-to-mac.sh               build + drop the zip into the local Steam Workshop folder
publish-steamcmd.sh          build + upload to the Steam Workshop via steamcmd
workshop_item.vdf            Workshop title/description/item id used by the publish script
generate-voices.py           voice-clip generator (see below)
voice-content.json           the lines, per-character delivery and per-category emotions
thumbnail.jpeg               Workshop preview image
LICENSE                      MIT, for the code
LICENSE-ASSETS               CC BY 4.0, for this mod's own assets
mods-unpacked/tato-BattleCries/
  manifest.json              ModLoader manifest (name, namespace, version)
  config.gd                  version, paths, hotkeys, wheel categories, toggle labels
  mod_main.gd                entry point: installs the hook, spawns the runtime nodes
  extensions/ui/hud/
    wave_timer.gd            script extension: the wave-start trigger
  lib/
    voice_player.gd          /root/BattleCriesPlayer: clip lookup, caching, playback, on/off
    emote_wheel.gd           the wheel overlay: drawing, input, per-device ownership
    options_hook.gd          injects the toggle into the Audio settings tab
    voices_toggle.gd         the toggle's own script: localized label, saves the setting
  voices/
    CHECKLIST.md             per-character voice map (excluded from the shipped zip)
    <slug>/<category>/<category>_NN.mp3
```

There are 1088 clips: 64 characters x 7 categories, with 5 `ready` lines and 2 lines for each
of `laugh`, `cheer`, `taunt`, `nooo`, `hurt`, `quip`. Each is mono 48 kHz mp3.

**How a clip is resolved.** The character id from `RunData` is turned into a folder slug by
stripping the `character_` prefix and replacing `_` with `-`, with one hard-coded exception:
`character_one_arm` maps to `one-armed`. The mod then probes
`voices/<slug>/<category>/<category>_01.mp3` through `_20.mp3` with `File.file_exists` (it
probes instead of listing, because enumerating a directory inside a mounted resource pack is
unreliable) and picks one at random. Clip lists and decoded streams are cached.

**There is no fallback.** If the character is modded or otherwise unknown, or the category
folder is missing or empty, nothing plays - the mod stays silent rather than substituting
another character's voice. A single `AudioStreamPlayer` is shared, so a new clip replaces one
that is still playing.

## Regenerating the voices

**You do not need to do this.** The mod ships with every clip already rendered; the generator
is only here so the lines can be changed or the voices redone.

`generate-voices.py` renders the clips through a **locally hosted Voicebox / Qwen CustomVoice
HTTP service at `http://127.0.0.1:17493`**. That service is an external dependency that this
repository does **not** ship and does not install. Without it running, the script cannot
produce anything. `ffmpeg` and `ffprobe` must also be on `PATH`.

What the script does, per line:

1. Looks up (or creates) a preset profile named `qv-<voice>` on the service, using the
   `qwen_custom_voice` engine. `voice-content.json` currently uses two English preset voices,
   `Ryan` and `Aiden`.
2. `POST /generate` with the line text and an `instruct` string built as
   `"<character delivery>, <category emotion>"` - the character's delivery comes from its
   entry in `voice-content.json`, the emotion from the shared `category_emotion` table (for
   example `ready` is "pumped and ready, charging into battle").
3. Applies an effects chain so the two base voices spread out per character: a `pitch_shift`
   in semitones plus a style colour - `deep` (lowpass + slight gain), `menace` and `ghostly`
   (reverb, increasingly wet), `robotic` (chorus), `loud` (gain), or `base` for no colour.
4. Polls `GET /audio/<id>` until real audio comes back, then transcodes with `ffmpeg` to mono
   48 kHz mp3 (`libmp3lame -q:a 4`) at
   `mods-unpacked/tato-BattleCries/voices/<slug>/<category>/<category>_NN.mp3`, where `NN` is
   the 1-based index of the line within that category.

**It is resumable.** Any clip whose mp3 already exists is skipped, so a killed run just
re-runs the remainder. Qwen is slow on MLX/MPS, so run it in the background.

```bash
no_proxy='*' python3 generate-voices.py                 # render everything still missing
no_proxy='*' python3 generate-voices.py --limit 1       # smoke-test a single clip
no_proxy='*' python3 generate-voices.py --only crazy    # one character only
no_proxy='*' python3 generate-voices.py --fixlong       # re-render clips that came out too long
no_proxy='*' python3 generate-voices.py --fixlong --rounds 6
```

`--fixlong` exists because the model sometimes rambles or loops and returns a clip far longer
than a few words warrant. It re-renders every existing clip that exceeds its category's
duration ceiling, up to `--rounds` attempts (default 4), keeping the shortest take and
stopping early once the clip is under the ceiling. The ceilings, in seconds, are:

| ready | laugh | cheer | taunt | nooo | hurt | quip |
| --- | --- | --- | --- | --- | --- | --- |
| 2.8 | 4.5 | 4.0 | 4.0 | 5.0 | 4.5 | 4.0 |

The wave-start bark has the tightest ceiling because it has to be snappy.

**To change what a character says**, edit its entry in `voice-content.json` - `lines` holds
the text per category, `delivery` is the character's acting direction, and `voice`, `pitch`
and `style` decide the timbre. Delete the mp3 files you want redone (the generator skips
files that exist), then run the generator with `--only <slug>`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Licence

The code is MIT ([LICENSE](LICENSE)). The assets original to this mod, including the
generated voice clips, are CC BY 4.0 ([LICENSE-ASSETS](LICENSE-ASSETS)). Both let you fork,
modify and redistribute this, commercially or not, as long as you credit the author.

Neither licence covers Brotato itself or anything extracted from the game - sprites, sounds,
names, translations. Those remain the property of their owner.

## Support

If the mod made your runs louder and you want to chip in, there is a Ko-fi:
<https://ko-fi.com/hhoangg>. Entirely optional - the mod is free and always will be.

## Credits and disclaimer

Made by **hhoangg** (byptah), mod namespace `tato`. Voice clips are AI-generated.

Brotato is a game by **Blobfish**. This is an unofficial fan mod, not affiliated with or
endorsed by Blobfish, and it is not supported by them - if something breaks while this mod is
installed, report it here, not to the game's developers.
