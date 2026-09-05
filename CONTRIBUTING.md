# Contributing

Bug reports, ideas and pull requests are welcome. This is a small mod maintained in spare
time, so please keep changes focused and easy to review.

## Reporting a bug

Open an issue using the **Bug report** template in `.github/ISSUE_TEMPLATE/`. It asks for the
mod version, the Brotato and Godot Mod Loader versions, other enabled mods, whether you were
solo or in co-op (and how the co-op was set up), and your OS.

Please attach the Godot log - mod errors surface there and almost nowhere else:

| OS | Path |
| --- | --- |
| macOS | `~/Library/Application Support/Brotato/logs/godot.log` |
| Windows | `%APPDATA%\Brotato\logs\godot.log` |
| Linux | `~/.local/share/Brotato/logs/godot.log` |

The ModLoader writes its own `modloader.log` next to it in the same folder; include that too
if the problem is that the mod does not load at all. When it loads correctly you will see
`[BattleCries] loaded v<version>` in the log.

For ideas, use the **Idea / feature request** template instead.

## Dev environment

You need:

- Brotato installed, with mod support enabled and Godot Mod Loader subscribed.
- `zip` (for `build-zip.sh`).
- `steamcmd` only if you intend to publish (`brew install --cask steamcmd` on macOS).
- `ffmpeg`, `ffprobe`, Python 3 and a locally hosted Voicebox / Qwen CustomVoice service on
  `http://127.0.0.1:17493` **only** if you touch the voice generator. It is not needed for
  any code change - the clips are already in the repo.

The mod source is plain GDScript under `mods-unpacked/tato-BattleCries/`; there is no Godot
project file to open and nothing to compile.

## Build and test loop

Brotato's shipped build loads mods only from the Steam Workshop content directory, so you
cannot just edit files in this repo and relaunch. The loop is:

1. Edit the GDScript.
2. Bump the version (see below).
3. Build and install: `./sync-to-mac.sh` on macOS, which runs `build-zip.sh` and copies
   `dist/tato-BattleCries.zip` into the Workshop folder of the published item. On other
   platforms, run `./build-zip.sh` and put the zip in the equivalent Workshop content folder
   yourself, or upload it through GodotWorkshopUtility.
4. Relaunch Brotato and read the log.

`sync-to-mac.sh` needs the item to have been published and subscribed once so the folder
exists. It overwrites Steam-managed files, which Steam may revert on a file-integrity check
or a server-side item update.

The emote wheel prints the mod version in the bottom-right corner while it is open - use that
to confirm the game really picked up your build before you debug anything else.

## GDScript house rules

**Indent with TABs, never spaces.** Godot 3's GDScript parser rejects mixed indentation, and
a file that mixes them will fail to parse with an unhelpful error. Every file in the mod uses
tabs; keep it that way.

**Bump the version on every change.** Any edit to the mod must raise the version, and the two
places that carry it must stay in sync:

- `mods-unpacked/tato-BattleCries/config.gd` -> `MOD_VERSION`
- `mods-unpacked/tato-BattleCries/manifest.json` -> `version_number`

The version shows in the load log and in the wheel's corner watermark, so an in-game glance
confirms which build is loaded. Semver:

- **patch** (third number) - a small fix or tweak, no new capability.
- **minor** (second number) - a new feature or capability.
- **major** (first number) - a breaking change: something that stops working the way it did,
  such as a change to the voice folder layout or to the saved settings format.

Other conventions the existing code follows and that a PR should not quietly break:

- Do not connect game signals from a script extension unless you have to. `wave_timer.gd`
  only calls `._ready()` and then defers into the mod's own node, which avoids the
  double-connect problems that come with extensions being applied more than once.
- Read raw physical input events (`InputEventKey` scancode, `InputEventJoypadButton` index,
  explicit joypad axes) and call `set_input_as_handled()` only when the mod actually acts.
  Do not grab the left stick, D-pad or `ui_*` actions - they are the game's focus navigation.
- Keep user-visible strings in `config.gd`'s per-locale tables and fall back to English.

## Adding or changing voice lines

All text lives in `voice-content.json`. Each character entry has:

- `voice` - the preset voice used (`Ryan` or `Aiden` today),
- `pitch` - semitone shift,
- `style` - the effect colour: `base`, `deep`, `menace`, `ghostly`, `robotic` or `loud`,
- `delivery` - the acting direction for that character,
- `lines` - the actual text, keyed by category.

The categories are `ready`, `laugh`, `cheer`, `taunt`, `nooo`, `hurt`, `quip`. The current
counts are 5 `ready` lines and 2 of each other category per character, 17 in total, and every
one of the 64 characters follows that shape. Keep lines short - they are barks, and the
generator enforces per-category duration ceilings (`ready` 2.8s, `nooo` 5.0s, `laugh` and
`hurt` 4.5s, the rest 4.0s).

To render a change:

```bash
# delete only the clips you are replacing - the generator skips files that already exist
rm mods-unpacked/tato-BattleCries/voices/<slug>/<category>/<category>_0N.mp3
no_proxy='*' python3 generate-voices.py --only <slug>
no_proxy='*' python3 generate-voices.py --fixlong        # if anything came out too long
```

Naming is not optional: the mod looks up
`voices/<slug>/<category>/<category>_NN.mp3` with `NN` zero-padded to two digits and starting
at `01`, matching the 1-based position of the line inside that category in
`voice-content.json`. It probes indexes `01` to `20`, so a category can hold at most 20 clips
and must not have gaps at the start. The slug is the character id minus the `character_`
prefix with `_` turned into `-`, plus the single exception `character_one_arm` ->
`one-armed`. Clips are mono 48 kHz mp3; the generator produces that automatically.

**Please do not commit bulk regenerated audio without discussing it in an issue first.** The
repository already carries roughly 19 MB of mp3s. A full regeneration rewrites all 1088 of
them and would add another copy of everything to the git history for what is usually an
inaudible difference. Re-rendering a handful of clips for a line you actually changed is
fine.

## Testing

There are no automated tests. Verifying a change means launching the game and checking the
behaviour and the log. In your PR, say what you tested:

- which build you ran (the version watermark),
- solo or co-op, and with what devices (keyboard, one pad, two pads),
- whether the wave-start bark fired, whether the wheel opened, aimed and played,
- whether the Settings > Audio toggle still appears and still persists after a restart,
- anything new or suspicious in the log.

Co-op paths are the easiest to break, so if you touch input handling or the wheel, please
test with at least two devices.

## Pull requests

Keep them small and focused on one thing. Include the version bump. Explain what changed and
how you verified it in-game. If a change alters the folder layout, the saved settings file or
anything else players' existing installs depend on, say so - that is a major version bump.

By contributing you agree that your contribution is licensed under this repository's
licences: MIT for code, CC BY 4.0 for assets.
