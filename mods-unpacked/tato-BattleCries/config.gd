# Config for the Battle Cries voice mod.
extends Reference

const MOD_ID := "tato-BattleCries"

# Shown in the load log so you can confirm the installed build at a glance.
# KEEP IN SYNC with manifest.json "version_number".
const MOD_VERSION := "0.5.3"

# Root of the bundled voice clips inside the mounted mod zip. Every clip lives under
# voices/<slug>/<category>/<category>_NN.mp3 (per-emotion, Qwen-rendered).
const VOICES_DIR := "res://mods-unpacked/tato-BattleCries/voices"

# Category played at wave start (the leader's "charging in" bark). Its own folder, separate
# from the emote-wheel CATEGORIES below.
const WAVE_START_CATEGORY := "ready"

# Playback level in dB. The clips already carry per-character gain; nudge this if the
# barks come out too loud or too quiet over the game's audio.
const VOLUME_DB := 0.0

# Where the player's "character voices on/off" choice persists. Our own file in user://,
# since we can't add a field to Brotato's settings save. Read by BattleCriesPlayer.
const SETTINGS_PATH := "user://tato_battlecries.cfg"

# Label for the on/off toggle this mod injects into the Audio settings tab, per locale.
# Looked up by full locale, then by language code (e.g. "pt_BR" -> "pt"), then "en".
const VOICES_TOGGLE_LABEL := {
	"en": "Character Voices",
	"vi": "Giọng nhân vật",
	"fr": "Voix des personnages",
	"de": "Charakterstimmen",
	"es": "Voces de personajes",
	"it": "Voci dei personaggi",
	"pt": "Vozes dos personagens",
	"ru": "Голоса персонажей",
	"ja": "キャラクターボイス",
	"ko": "캐릭터 음성",
	"zh": "角色语音",
	"zh_TW": "角色語音",
	"pl": "Głosy postaci",
	"tr": "Karakter sesleri",
	"nl": "Personagestemmen",
	"uk": "Голоси персонажів",
}

# ---- Emote wheel (hold to open, point a direction, release to emote) ----
# Hold this key (keyboard) or the controller L2 trigger to open the wheel; aim with the
# mouse or the RIGHT analog stick; release to play. Some pads report L2 as a digital joypad
# button (index 6), others ONLY as an analog axis (axis 6) — we read BOTH so it works either
# way. Change these if L2 clashes in-game.
const WHEEL_KEY := KEY_T
const WHEEL_BUTTON := 6              # controller L2 as a digital button (pads that send one)
const WHEEL_TRIGGER_AXIS := 6        # controller L2 as an analog axis (left trigger)

# Wheel slots, clockwise from the TOP. key = voices/<slug>/<key>/ folder. Labels are shown
# in the game's current language; falls back to "en" for any locale without an entry.
const CATEGORIES := [
	{"key": "laugh", "en": "Laugh", "vi": "Cười"},
	{"key": "cheer", "en": "Cheer", "vi": "Ăn mừng"},
	{"key": "taunt", "en": "Taunt", "vi": "Khích"},
	{"key": "nooo",  "en": "Nooo!", "vi": "Nooo!"},
	{"key": "hurt",  "en": "Hurt",  "vi": "Đau"},
	{"key": "quip",  "en": "Quip",  "vi": "Cảm thán"},
]

# Wheel title shown above the ring, by language (falls back to "en").
const WHEEL_TITLE := {"en": "Emote", "vi": "Cảm xúc"}

# Game fonts (the VN translation mod replaces these with Vietnamese-capable versions, so
# our labels render diacritics AND match the game's look). Fall back to the engine default
# if a path is missing in some build.
const FONT_LABEL := "res://resources/fonts/actual/base/font_26_outline.tres"
const FONT_TITLE := "res://resources/fonts/actual/base/font_40_outline.tres"
