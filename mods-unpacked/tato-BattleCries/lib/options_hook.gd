# Injects a "Character Voices" on/off toggle into the options menu's Audio tab.
#
# We can't use a ModLoader script extension on menu_options.gd: that script fails to reload
# from its .gdc as a base class ("type can't be inferred"), so `extends "...menu_options.gd"`
# never compiles. Instead this persistent node watches the scene tree: when the Audio tab's
# RightContainer is added (works for BOTH the main-menu and in-run options), we clone one of
# its CheckButtons so the toggle matches the game's style exactly, relabel it, and wire it to
# the Character-Voices setting on /root/BattleCriesPlayer.
extends Node

const Config = preload("res://mods-unpacked/tato-BattleCries/config.gd")
const VoicesToggle = preload("res://mods-unpacked/tato-BattleCries/lib/voices_toggle.gd")


func _ready() -> void:
	get_tree().connect("node_added", self, "_on_node_added")


func _on_node_added(node) -> void:
	# The audio toggles live in Audio_Container/AudioContainer/RightContainer. Match that exact
	# chain so we don't react to other "RightContainer" nodes elsewhere in the game.
	if not (node is VBoxContainer) or node.name != "RightContainer":
		return
	var p = node.get_parent()
	if p == null or p.name != "AudioContainer":
		return
	var gp = p.get_parent()
	if gp == null or gp.name != "Audio_Container":
		return
	# The track CheckButtons are added right after their container; defer so one exists to clone.
	call_deferred("_inject", node)


func _inject(right) -> void:
	if not is_instance_valid(right) or right.has_node("BattleCriesVoicesButton"):
		return
	var template = _find_checkbutton(right)
	var cb
	if template != null:
		cb = template.duplicate(0)   # flags 0 = copy node + properties, NOT signals/groups/scripts
	else:
		cb = CheckButton.new()
	cb.name = "BattleCriesVoicesButton"
	cb.disabled = false
	# voices_toggle.gd owns the label (per locale, live-updating) + the on/off setting.
	cb.set_script(VoicesToggle)
	right.add_child(cb)


func _find_checkbutton(node):
	for c in node.get_children():
		if c is CheckButton:
			return c
	return null
