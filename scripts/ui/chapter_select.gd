extends Control
## ChapterSelect — 自由行走地图，背景地图跟随滚动。

var _ready_done: bool = false
var _player_pos: Vector2 = Vector2.ZERO
var _move_speed: float = 250.0
var _selected_key: String = ""
var _stage_positions: Dictionary = {}
var _map_size: Vector2 = Vector2(1600, 900)
var _screen_size: Vector2 = Vector2(1152, 648)

@onready var _map_container: Node2D = $MapContainer
@onready var _map_view: Node2D = $MapContainer/MapView
@onready var _map_bg: TextureRect = $MapContainer/MapBg
@onready var _map_darken: ColorRect = $MapContainer/MapDarken


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	$BottomBar/EnterButton.hide()

	_screen_size = get_viewport_rect().size

	# 获取地图图片尺寸
	var tex: Texture2D = _map_bg.texture
	if tex:
		_map_size = Vector2(tex.get_width(), tex.get_height())
		_map_bg.custom_minimum_size = _map_size
		_map_bg.size = _map_size
		_map_darken.custom_minimum_size = _map_size
		_map_darken.size = _map_size

	# 用地图百分比计算关卡位置
	var margin_x: float = _map_size.x * 0.1
	var margin_y: float = _map_size.y * 0.15
	var start_x: float = margin_x
	var end_x: float = _map_size.x - margin_x
	var start_y: float = margin_y
	var end_y: float = _map_size.y - margin_y * 0.5
	var spacing_y: float = (end_y - start_y) / max(ProgressManager.total_chapters - 1, 1)

	for ch in range(1, ProgressManager.total_chapters + 1):
		var ch_y: float = start_y + (ch - 1) * spacing_y
		var st_count: int = ProgressManager.STAGE_COUNTS[ch]
		var spacing_x: float = (end_x - start_x) / max(st_count - 1, 1)
		for st in range(1, st_count + 1):
			var st_x: float = start_x + (st - 1) * spacing_x
			_stage_positions[ProgressManager.stage_key(ch, st)] = Vector2(st_x, ch_y)

	_map_view.stage_positions = _stage_positions

	# 章节标签（随地图滚动）
	for ch in range(1, ProgressManager.total_chapters + 1):
		var first_key: String = ProgressManager.stage_key(ch, 1)
		if first_key in _stage_positions:
			var pos: Vector2 = _stage_positions[first_key]
			var lbl: Label = Label.new()
			lbl.text = "第%d章" % ch
			lbl.position = Vector2(10, pos.y - 6)
			lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.9))
			_map_view.add_child(lbl)

	# 关卡数字标签（随地图滚动）
	for key in _stage_positions:
		var pos: Vector2 = _stage_positions[key]
		var parts: PackedStringArray = key.split("-")
		var st: int = int(parts[1])
		var lbl: Label = Label.new()
		lbl.text = str(st)
		lbl.position = pos - Vector2(6, 12)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		lbl.add_theme_font_size_override("font_size", 12)
		_map_view.add_child(lbl)

	# 玩家出生在第一关
	var start_key: String = ProgressManager.stage_key(1, 1)
	if start_key in _stage_positions:
		_player_pos = _stage_positions[start_key]

	_map_view.player_pos = _player_pos

	_ready_done = true
	_update_camera()
	_map_view.queue_redraw()


func _process(delta: float) -> void:
	if not _ready_done:
		return

	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_player_pos += input * _move_speed * delta

	_player_pos.x = clamp(_player_pos.x, 0, _map_size.x)
	_player_pos.y = clamp(_player_pos.y, 0, _map_size.y)

	_map_view.player_pos = _player_pos
	_update_camera()
	_check_dot_proximity()
	_map_view.queue_redraw()


func _update_camera() -> void:
	if _map_size.x <= 0 or _map_size.y <= 0:
		return

	var offset_x: float = _screen_size.x * 0.5 - _player_pos.x
	var offset_y: float = _screen_size.y * 0.5 - _player_pos.y

	offset_x = clamp(offset_x, _screen_size.x - _map_size.x, 0)
	offset_y = clamp(offset_y, _screen_size.y - _map_size.y, 0)

	_map_container.position = Vector2(offset_x, offset_y)


func _check_dot_proximity() -> void:
	var best_key: String = ""
	var best_dist: float = 30.0

	for key in _stage_positions:
		if not ProgressManager.is_unlocked(
			int(key.split("-")[0]), int(key.split("-")[1])):
			continue
		var dist: float = _player_pos.distance_to(_stage_positions[key])
		if dist < best_dist:
			best_dist = dist
			best_key = key

	if best_key != "" and best_key != _selected_key:
		_selected_key = best_key
		var parts = best_key.split("-")
		ProgressManager.select_stage(int(parts[0]), int(parts[1]))
		$BottomBar/EnterButton.show()
		$BottomBar/StageInfoLabel.text = "第%s章 第%s关" % [parts[0], parts[1]]
	elif best_key == "" and _selected_key != "":
		_selected_key = ""
		$BottomBar/EnterButton.hide()

	_map_view.selected_key = _selected_key


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_enter_pressed() -> void:
	if _selected_key == "":
		return
	var parts: PackedStringArray = _selected_key.split("-")
	ProgressManager.current_chapter = int(parts[0])
	ProgressManager.current_stage = int(parts[1])
	get_tree().change_scene_to_file("res://scenes/main.tscn")
