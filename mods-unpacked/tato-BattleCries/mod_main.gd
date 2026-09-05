# Entry point for the Battle Cries voice mod (ModLoader).
# _init():  install the wave-START hook. The wave timer is part of main.tscn (reloaded
#           every wave) and counts the wave down, so its _ready fires once at the start of
#           each wave. This is the same proven script-extension pattern the Endless
#           Leaderboard mod uses for the wave-CLEARED label — but for wave start.
# _ready(): spawn the persistent VoicePlayer node at /root. It owns the AudioStreamPlayer
#           and plays the leader's (player 0's) random voice line when the hook fires.
extends Node

const Config = preload("res://mods-unpacked/tato-BattleCries/config.gd")
const VoicePlayer = preload("res://mods-unpacked/tato-BattleCries/lib/voice_player.gd")
const EmoteWheel = preload("res://mods-unpacked/tato-BattleCries/lib/emote_wheel.gd")
const OptionsHook = preload("res://mods-unpacked/tato-BattleCries/lib/options_hook.gd")

const _EXT_DIR := "res://mods-unpacked/tato-BattleCries/extensions/"


func _init() -> void:
	# We only call ._ready() and then play a sound in the extension — we connect NO game
	# signals, so the "already connected" double-connect problem that made the Leaderboard
	# mod avoid extending main.gd does not apply to this hook.
	ModLoaderMod.install_script_extension(_EXT_DIR + "ui/hud/wave_timer.gd")


func _ready() -> void:
	if not ClassDB.class_exists("AudioStreamMP3"):
		printerr("[BattleCries] AudioStreamMP3 not available in this build — voice lines disabled.")
		return
	var player = VoicePlayer.new()
	player.name = "BattleCriesPlayer"
	get_tree().root.call_deferred("add_child", player)

	# Emote wheel UI on a high canvas layer — hold WHEEL_KEY / WHEEL_BUTTON in-game to open.
	var wheel_layer = CanvasLayer.new()
	wheel_layer.name = "BattleCriesWheelLayer"
	wheel_layer.layer = 128
	var wheel = EmoteWheel.new()
	wheel.name = "BattleCriesWheel"
	wheel_layer.add_child(wheel)
	get_tree().root.call_deferred("add_child", wheel_layer)

	# Persistent listener that injects the "Character Voices" toggle into the Audio settings tab.
	var options_hook = OptionsHook.new()
	options_hook.name = "BattleCriesOptionsHook"
	get_tree().root.call_deferred("add_child", options_hook)

	print("[BattleCries] loaded v" + Config.MOD_VERSION)
