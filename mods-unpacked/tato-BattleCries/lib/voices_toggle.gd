# Script attached to the injected "Character Voices" CheckButton in the Audio settings tab.
#
# The label must follow the game's language. A plain literal text won't: Godot re-runs tr()
# on a control's text when the locale changes, and our text isn't a translation key, so it
# would stay frozen in whatever language was active when the menu first opened. Instead we
# re-pick the label from our own per-locale table on _ready AND on every locale change
# (NOTIFICATION_TRANSLATION_CHANGED), so it updates live when the player switches language.
extends CheckButton

const Config = preload("res://mods-unpacked/tato-BattleCries/config.gd")


func _ready() -> void:
	_apply_label()
	var player = get_tree().root.get_node_or_null("BattleCriesPlayer")
	pressed = player.voices_enabled() if player != null else true
	connect("toggled", self, "_on_toggled")


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_apply_label()


# Label in the game's current language: try the full locale (e.g. "zh_TW"), then the language
# part (e.g. "pt_BR" -> "pt"), then fall back to English.
func _apply_label() -> void:
	var d = Config.VOICES_TOGGLE_LABEL
	var loc := TranslationServer.get_locale()
	if d.has(loc):
		text = d[loc]
	elif d.has(loc.split("_")[0]):
		text = d[loc.split("_")[0]]
	else:
		text = d["en"]


func _on_toggled(is_on: bool) -> void:
	var player = get_tree().root.get_node_or_null("BattleCriesPlayer")
	if player != null:
		player.set_voices_enabled(is_on)
