# Hook: wave START. The wave timer is (re)created at the start of every wave, so its
# _ready is our per-wave trigger. Ask the persistent VoicePlayer to play the leader's
# random voice line. Deferred so a playback hiccup can never interfere with the timer
# (and so RunData is fully settled for this wave).
extends "res://ui/hud/wave_timer.gd"


func _ready():
	._ready()
	var vp = get_tree().root.get_node_or_null("BattleCriesPlayer")
	if vp != null:
		vp.call_deferred("play_for_leader")
