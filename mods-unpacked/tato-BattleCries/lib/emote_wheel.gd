# Emote wheel UI + input. A full-screen Control under a high CanvasLayer. Hold the wheel
# KEY (keyboard) or BUTTON (controller) to open it; aim with the mouse or the RIGHT analog
# stick; release to play a random clip of the pointed emotion via /root/BattleCriesPlayer.
# The game is NOT paused — you emote while playing.
#
# Labels use the GAME's font (so Vietnamese diacritics render and it matches the game) and
# the game's current language (falling back to English). Sizing scales to the viewport and
# the palette mirrors Brotato's dark panels + gold accent.
#
# Input is RAW physical events (scancode / joypad button index / right-stick axes), consumed
# with set_input_as_handled() only for OUR trigger and (while open) the right stick — the
# left stick / D-pad / arrows are never touched (see CLAUDE.md "Input separation").
extends Control

const Config = preload("res://mods-unpacked/tato-BattleCries/config.gd")

const STICK_DEAD := 0.4   # right-stick magnitude below this = no selection
const TRIGGER_PRESS := 0.6    # L2 analog value at/above which the trigger counts as held
const TRIGGER_RELEASE := 0.4  # ...and at/below which it counts as released (hysteresis)

# Brotato-ish palette
const COL_DIM := Color(0, 0, 0, 0.5)
const COL_DISC := Color(0.07, 0.07, 0.09, 0.72)
const COL_HOLE := Color(0, 0, 0, 0.55)
const COL_SEP := Color(0.85, 0.80, 0.65, 0.22)
const COL_GOLD := Color(0.82, 0.73, 0.26, 0.45)   # highlight wedge
const COL_TEXT := Color(0.92, 0.90, 0.82)         # idle label
const COL_SEL := Color(1.0, 0.90, 0.42)           # selected label / title
const COL_DOT := Color(1, 1, 1, 0.7)

var _open := false
var _sel := -1
var _rx := 0.0
var _ry := 0.0
var _place := 0          # co-op player index ("place") the open wheel belongs to (0 = leader/solo)
var _owner_dev := -1     # joypad device that owns the open wheel (-1 = none)
var _owner_key := false  # true when the keyboard owns the open wheel
var _trig_down := {}     # per-device L2 analog edge state (device:int -> bool)
var _lang := "en"
var _labels := []
var _title : Label
var _version : Label
var _icon = null         # owning player's character icon Texture, drawn in the wheel center
var _font_label = null
var _font_title = null
var _r_outer := 200.0
var _r_inner := 75.0
var _label_r := 150.0


func _ready() -> void:
	set_anchors_and_margins_preset(Control.PRESET_WIDE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_mode = Node.PAUSE_MODE_PROCESS
	_font_label = load(Config.FONT_LABEL)
	_font_title = load(Config.FONT_TITLE)
	for i in range(Config.CATEGORIES.size()):
		var lab := Label.new()
		lab.align = Label.ALIGN_CENTER
		lab.valign = Label.VALIGN_CENTER
		lab.rect_size = Vector2(190, 44)
		lab.visible = false
		if _font_label != null:
			lab.add_font_override("font", _font_label)
		add_child(lab)
		_labels.append(lab)
	_title = Label.new()
	_title.align = Label.ALIGN_CENTER
	_title.valign = Label.VALIGN_CENTER
	_title.rect_size = Vector2(460, 64)
	_title.visible = false
	if _font_title != null:
		_title.add_font_override("font", _font_title)
	add_child(_title)
	# Version readout in the bottom-right while the wheel is open (build tracking).
	_version = Label.new()
	_version.align = Label.ALIGN_RIGHT
	_version.valign = Label.VALIGN_CENTER
	_version.rect_size = Vector2(260, 30)
	_version.visible = false
	if _font_label != null:
		_version.add_font_override("font", _font_label)
	add_child(_version)


func _input(event) -> void:
	if event is InputEventKey:
		if event.scancode == Config.WHEEL_KEY and not event.echo:
			if event.pressed:
				_press(0, true)
			else:
				_release(0, true)
	elif event is InputEventJoypadButton:
		if event.button_index == Config.WHEEL_BUTTON:
			if event.pressed:
				_press(event.device, false)
			else:
				_release(event.device, false)
	elif event is InputEventJoypadMotion:
		# L2 (open/close): many pads report the trigger ONLY as an analog axis, not a button,
		# so synthesise press/release PER DEVICE from the axis value.
		if event.axis == Config.WHEEL_TRIGGER_AXIS:
			_handle_trigger_axis(event.axis_value, event.device)
		# Aim with the RIGHT stick of the device that owns the open wheel (co-op: only theirs).
		elif _open and not _owner_key and event.device == _owner_dev and event.axis == 2:
			_rx = event.axis_value
			_update_sel(Vector2(_rx, _ry), true)
			get_tree().set_input_as_handled()
		elif _open and not _owner_key and event.device == _owner_dev and event.axis == 3:
			_ry = event.axis_value
			_update_sel(Vector2(_rx, _ry), true)
			get_tree().set_input_as_handled()
	# The keyboard owner aims with the mouse.
	elif _open and _owner_key and event is InputEventMouseMotion:
		_update_sel(event.position - _center(), false)


# A device pressed its open-trigger. ONE wheel at a time: if one is already open we ignore
# other openers (and don't consume, so their other inputs still work). Otherwise open the
# wheel for the player ("place") that device belongs to and remember the owner, so only that
# device's release closes + plays. We consume input only when we actually act (so the trigger
# passes through on the main menu and when ignored).
func _press(device: int, is_key: bool) -> void:
	if _open or not _can_open():
		return
	_place = _place_for(device, is_key)
	_owner_dev = device
	_owner_key = is_key
	_open_wheel()
	get_tree().set_input_as_handled()


# The owning device released its trigger -> close + play. Releases from other devices are
# ignored so a second player can't close the owner's wheel.
func _release(device: int, is_key: bool) -> void:
	if not _open:
		return
	if is_key != _owner_key or (not is_key and device != _owner_dev):
		return
	_close_wheel()
	get_tree().set_input_as_handled()


# L2 as an analog axis, tracked PER DEVICE: rising past TRIGGER_PRESS = press, falling below
# TRIGGER_RELEASE = release (hysteresis avoids flutter). Each pad edges independently.
func _handle_trigger_axis(v: float, device: int) -> void:
	var down : bool = _trig_down.get(device, false)
	if not down and v >= TRIGGER_PRESS:
		_trig_down[device] = true
		_press(device, false)
	elif down and v <= TRIGGER_RELEASE:
		_trig_down[device] = false
		_release(device, false)


# Map the input device that opened the wheel to a co-op player index ("place").
# CoopService.connected_players = [[device, place], ...]; the keyboard player's stored device
# is a virtual id (not a physically-connected joypad), real pads use their Godot device id.
# Solo / no co-op data -> 0 (the only player).
func _place_for(device: int, is_key: bool) -> int:
	var cs = get_tree().root.get_node_or_null("CoopService")
	if cs == null or not ("connected_players" in cs):
		return 0
	var players = cs.connected_players
	if typeof(players) != TYPE_ARRAY or players.size() == 0:
		return 0
	var pads := Input.get_connected_joypads()
	var result := 0
	if is_key:
		# Keyboard = the entry whose device is NOT one of the connected joypads.
		for pair in players:
			if typeof(pair) == TYPE_ARRAY and pair.size() >= 2 and not (int(pair[0]) in pads):
				result = int(pair[1])
				break
	else:
		# Joypad = the entry whose stored device matches this physical device id.
		for pair in players:
			if typeof(pair) == TYPE_ARRAY and pair.size() >= 2 and int(pair[0]) == device:
				result = int(pair[1])
				break
	return result


# The wheel only works in a run (character select → run → game over), not on the home menu.
func _can_open() -> bool:
	var player = get_tree().root.get_node_or_null("BattleCriesPlayer")
	return player != null and player.voices_enabled() and player.is_run_active()


func _open_wheel() -> void:
	_open = true
	_sel = -1
	_rx = 0.0
	_ry = 0.0
	var loc := TranslationServer.get_locale()
	_lang = "vi" if loc.begins_with("vi") else "en"
	# Brotato authors 2D UI in a size_override design space (e.g. 1920x1080) that differs from
	# get_viewport().size (the 1280x720 render size). Nodes draw in the OVERRIDE space, so the
	# overlay must size itself to that to fill the screen — no CanvasLayer scaling needed.
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.scale = Vector2(1, 1)
	var player = get_tree().root.get_node_or_null("BattleCriesPlayer")
	_icon = player.icon_for_place(_place) if player != null else null
	var size := _vp_size()
	var rad : float = min(size.x, size.y)
	_r_outer = rad * 0.26
	_r_inner = rad * 0.10
	_label_r = rad * 0.185
	for i in range(_labels.size()):
		_labels[i].text = Config.CATEGORIES[i].get(_lang, Config.CATEGORIES[i]["en"])
		_labels[i].visible = true
	_title.visible = true
	_version.text = "v" + Config.MOD_VERSION
	_version.visible = true
	_layout()
	_refresh()
	update()


func _close_wheel() -> void:
	if not _open:
		return
	_open = false
	for lab in _labels:
		lab.visible = false
	_title.visible = false
	_version.visible = false
	if _sel >= 0 and _sel < Config.CATEGORIES.size():
		var player = get_tree().root.get_node_or_null("BattleCriesPlayer")
		if player != null:
			player.play_category(Config.CATEGORIES[_sel]["key"], _place)
	_owner_dev = -1
	_owner_key = false
	update()


# The 2D coordinate space nodes actually draw in: Brotato's size_override (e.g. 1920x1080)
# when set, else the viewport size. Using this (not get_viewport().size) makes the overlay
# cover the whole screen and keeps the wheel centered.
func _vp_size() -> Vector2:
	var o : Vector2 = get_viewport().get_size_override()
	if o.x > 0 and o.y > 0:
		return o
	return get_viewport().size


func _center() -> Vector2:
	return _vp_size() * 0.5


# clockwise-from-top unit vector for `deg` (0 = up, 90 = right, 180 = down)
func _dir(deg: float) -> Vector2:
	var t := deg2rad(deg)
	return Vector2(sin(t), -cos(t))


func _update_sel(v: Vector2, is_stick: bool) -> void:
	var r := v.length()
	var dead = STICK_DEAD if is_stick else _r_inner
	var new_sel := -1
	if r >= dead:
		var t := rad2deg(atan2(v.x, -v.y))
		if t < 0.0:
			t += 360.0
		new_sel = int(round(t / 60.0)) % 6
	if new_sel != _sel:
		_sel = new_sel
		_refresh()
		update()


func _layout() -> void:
	var c := _center()
	for i in range(_labels.size()):
		var pos := c + _dir(i * 60.0) * _label_r
		_labels[i].rect_position = pos - _labels[i].rect_size * 0.5
	_title.rect_position = Vector2(c.x - _title.rect_size.x * 0.5, c.y - _r_outer - 64.0)
	var sz := _vp_size()
	_version.rect_position = Vector2(sz.x - _version.rect_size.x - 16.0, sz.y - _version.rect_size.y - 12.0)


func _refresh() -> void:
	for i in range(_labels.size()):
		_labels[i].modulate = COL_SEL if i == _sel else COL_TEXT
	if _sel >= 0:
		_title.text = Config.CATEGORIES[_sel].get(_lang, Config.CATEGORIES[_sel]["en"])
		_title.modulate = COL_SEL
	else:
		_title.text = Config.WHEEL_TITLE.get(_lang, Config.WHEEL_TITLE["en"])
		_title.modulate = COL_TEXT


func _draw() -> void:
	if not _open:
		return
	var c := _center()
	draw_rect(Rect2(Vector2.ZERO, _vp_size()), COL_DIM)
	draw_circle(c, _r_outer, COL_DISC)
	for i in range(6):
		var d := _dir(i * 60.0 + 30.0)
		draw_line(c + d * _r_inner, c + d * _r_outer, COL_SEP, 2.0)
	if _sel >= 0:
		var pts := PoolVector2Array()
		pts.append(c)
		var a := 0.0
		while a <= 60.0:
			pts.append(c + _dir(_sel * 60.0 - 30.0 + a) * _r_outer)
			a += 6.0
		draw_colored_polygon(pts, COL_GOLD)
	draw_circle(c, _r_inner, COL_HOLE)
	if _icon != null:
		var s := _r_inner * 1.3
		draw_texture_rect(_icon, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)
	else:
		draw_circle(c, 6.0, COL_DOT)
