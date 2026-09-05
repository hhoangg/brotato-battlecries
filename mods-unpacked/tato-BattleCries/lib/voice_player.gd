# Persistent node at /root/BattleCriesPlayer. Owns one AudioStreamPlayer and, on
# play_for_leader(), reads the leader (player 0 — the host, treated as the leader in
# co-op) from the RunData autoload, maps the character id to a voice slug, picks a random
# bundled .mp3 clip, and plays it. Loaded streams and per-slug clip lists are cached.
extends Node

const Config = preload("res://mods-unpacked/tato-BattleCries/config.gd")

var _audio : AudioStreamPlayer
var _clips := {}      # slug -> Array of res:// .mp3 paths that exist
var _streams := {}    # res:// path -> AudioStreamMP3 (lazy cache)
var _rng := RandomNumberGenerator.new()
var _enabled := true  # "Character Voices" master on/off (toggled in the Audio settings tab)


func _ready() -> void:
	_rng.randomize()
	_audio = AudioStreamPlayer.new()
	_audio.volume_db = Config.VOLUME_DB
	add_child(_audio)
	_load_settings()


# Play a random wave-start line for the current run's leader (player 0).
func play_for_leader() -> void:
	play_category(Config.WAVE_START_CATEGORY)


# Play a random clip from `category` for player `place` (0 = leader/solo; in co-op each
# player emotes with their own character via the emote wheel). No-op when there is no active
# run, that player's character is unknown/modded, or the category has no clips.
func play_category(category: String, place: int = 0) -> void:
	if _audio == null or not _enabled:
		return
	var slug := _slug_for(place)
	if slug == "":
		return
	var clips := _clips_for(slug, category)
	if clips.empty():
		return
	var path : String = clips[_rng.randi_range(0, clips.size() - 1)]
	var stream = _stream_for(path)
	if stream == null:
		return
	_audio.stream = stream
	_audio.play()


# True while a run is set up (a character is chosen) through game-over, false on the main
# menu — so the emote wheel only activates in a run, not on the home screen.
func is_run_active() -> bool:
	var rd = get_tree().root.get_node_or_null("RunData")
	if rd == null:
		return false
	return _resolve_character_id(rd, 0) != ""


# ---------------------------------------------------------------------------
# "Character Voices" on/off — toggled from the Audio settings tab, saved to user://
# ---------------------------------------------------------------------------

func voices_enabled() -> bool:
	return _enabled


func set_voices_enabled(v: bool) -> void:
	_enabled = v
	if not _enabled and _audio != null:
		_audio.stop()
	_save_settings()


func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(Config.SETTINGS_PATH) == OK:
		_enabled = bool(cf.get_value("audio", "voices_enabled", true))


func _save_settings() -> void:
	var cf := ConfigFile.new()
	cf.load(Config.SETTINGS_PATH)   # keep any other keys already present
	cf.set_value("audio", "voices_enabled", _enabled)
	cf.save(Config.SETTINGS_PATH)


# Player `place`'s character icon Texture, for the wheel center, or null.
# Brotato's CharacterData carries an `icon` Texture, so we read it straight off RunData.
func icon_for_place(place: int):
	var rd = get_tree().root.get_node_or_null("RunData")
	if rd == null:
		return null
	var cd = null
	if ("players_data" in rd) and typeof(rd.players_data) == TYPE_ARRAY and rd.players_data.size() > place:
		var pd = rd.players_data[place]
		if pd != null:
			for field in ["current_character", "character", "character_data"]:
				if field in pd:
					cd = pd.get(field)
					break
	if cd == null and place == 0 and "current_character" in rd:
		cd = rd.current_character
	if cd == null and rd.has_method("get_player_character"):
		cd = rd.get_player_character(place)
	if typeof(cd) == TYPE_ARRAY and cd.size() > 0:
		cd = cd[0]
	if cd != null and ("icon" in cd):
		return cd.icon
	return null


# ---------------------------------------------------------------------------
# leader -> voice slug
# ---------------------------------------------------------------------------

# Map player `place`'s character id to the voice folder slug used in apps/web:
# strip "character_", turn "_" into "-", with the one known exception one_arm -> one-armed.
func _slug_for(place: int) -> String:
	var rd = get_tree().root.get_node_or_null("RunData")
	if rd == null:
		return ""
	var cid := _resolve_character_id(rd, place)
	if cid == "" or not cid.begins_with("character_"):
		return ""
	var slug := cid.substr("character_".length()).replace("_", "-")
	if slug == "one-arm":
		slug = "one-armed"
	return slug


# Player `place`'s character id. Read players_data[place] first, then (for place 0) fall back
# to RunData.current_character / a getter (the layout varies between versions).
func _resolve_character_id(rd, place: int) -> String:
	if ("players_data" in rd) and typeof(rd.players_data) == TYPE_ARRAY and rd.players_data.size() > place:
		var pd = rd.players_data[place]
		if pd != null:
			for field in ["current_character", "character", "character_data", "character_id"]:
				if field in pd:
					var id := _char_id_of(pd.get(field))
					if id != "":
						return id
	if place == 0 and "current_character" in rd:
		var id1 := _char_id_of(rd.current_character)
		if id1 != "":
			return id1
	if rd.has_method("get_player_character"):
		return _char_id_of(rd.get_player_character(place))
	return ""


# Pull "my_id" from a CharacterData / Dictionary / Array-of-them / String, or "".
func _char_id_of(v) -> String:
	if v == null:
		return ""
	if typeof(v) == TYPE_ARRAY:
		if v.size() == 0:
			return ""
		v = v[0]
	if typeof(v) == TYPE_STRING:
		return v
	if v != null and ("my_id" in v):
		return String(v.my_id)
	return ""


# ---------------------------------------------------------------------------
# clip discovery + loading
# ---------------------------------------------------------------------------

# Clip paths for (slug, category): voices/<slug>/<category>/<category>_NN.mp3, probing 01..20.
# We probe (not list) because directory enumeration of a mounted resource pack is
# unreliable; File.file_exists on a res:// pack path is not.
func _clips_for(slug: String, category: String) -> Array:
	var key := slug + "/" + category
	if _clips.has(key):
		return _clips[key]
	var found := []
	var f := File.new()
	for i in range(1, 21):
		var cp := "%s/%s/%s/%s_%02d.mp3" % [Config.VOICES_DIR, slug, category, category, i]
		if f.file_exists(cp):
			found.append(cp)
	_clips[key] = found
	return found


# Lazily build + cache an AudioStreamMP3 from raw bytes. Mod assets are bundled
# un-imported, so we read the bytes with File and set them on the stream directly rather
# than load() an imported resource. ClassDB.instance avoids a hard reference to the class.
func _stream_for(path: String):
	if _streams.has(path):
		return _streams[path]
	var f := File.new()
	if f.open(path, File.READ) != OK:
		return null
	var bytes := f.get_buffer(f.get_len())
	f.close()
	if bytes.size() == 0:
		return null
	var stream = ClassDB.instance("AudioStreamMP3")
	if stream == null:
		return null
	stream.set("data", bytes)
	_streams[path] = stream
	return stream
