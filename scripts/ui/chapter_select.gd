extends Control
## ChapterSelect — 自由行走地图，碰到圆点选中关卡。

var _ready_done: bool = false
var _player_pos: Vector2 = Vector2.ZERO
var _move_speed: float = 300.0
var _selected_key: String = ""
var _stage_positions: Dictionary = {}
var _map_margin_left: float = 140
var _map_margin_right: float = 40
var _map_margin_top: float = 80
var _map_margin_bottom: float = 80

@onready var _map_view: Node2D = $MapView


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	$BottomBar/EnterButton.hide()

	var vp: Rect2 = get_viewport_rect()
	var area_w: float = max(vp.size.x, 800)
	var area_h: float = max(vp.size.y, 600)
	var start_x: float = _map_margin_left
	var end_x: float = area_w - _map_margin_right
	var start_y: float = _map_margin_top
	var end_y: float = area_h - _map_margin_bottom
	var spacing_y: float = (end_y - start_y) / max(ProgressManager.total_chapters - 1, 1)

	for ch in range(1, ProgressManager.total_chapters + 1):
		var ch_y: float = start_y + (ch - 1) * spacing_y
		var st_count: int = ProgressManager.STAGE_COUNTS[ch]
		var spacing_x: float = (end_x - start_x) / max(st_count - 1, 1)
		for st in range(1, st_count + 1):
			var st_x: float = start_x + (st - 1) * spacing_x
			_stage_positions[ProgressManager.stage_key(ch, st)] = Vector2(st_x, ch_y)

	# 章节标签
	for ch in range(1, ProgressManager.total_chapters + 1):
		var first_key: String = ProgressManager.stage_key(ch, 1)
		if first_key in _stage_positions:
			var pos: Vector2 = _stage_positions[first_key]
			var lbl: Label = Label.new()
			lbl.text = "第%d章" % ch
			lbl.position = Vector2(10, pos.y - 6)
			lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.9))
			add_child(lbl)

	for key in _stage_positions:
		var pos: Vector2 = _stage_positions[key]
		var parts: PackedStringArray = key.split("-")
		var st: int = int(parts[1])
		var lbl: Label = Label.new()
		lbl.text = str(st)
		lbl.position = pos - Vector2(6, 12)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		lbl.add_theme_font_size_override("font_size", 11)
		add_child(lbl)

	# 玩家出生在第一关
	var start_key: String = ProgressManager.stage_key(1, 1)
	if start_key in _stage_positions:
		_player_pos = _stage_positions[start_key]

	# 设地图数据
	_map_view.stage_positions = _stage_positions
	_map_view.player_pos = _player_pos

	_ready_done = true
	_queue_map_redraw()


func _process(delta: float) -> void:
	if not _ready_done:
		return

	# WASD 自由移动
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var vel: Vector2 = input * _move_speed
	_player_pos += vel * delta

	# 更新 MapView
	_map_view.player_pos = _player_pos

	# 检测是否靠近圆点
	_check_dot_proximity()

	_queue_map_redraw()


func _check_dot_proximity() -> void:
	var best_key: String = ""
	var best_dist: float = 30.0  # 触发距离

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


func _queue_map_redraw() -> void:
	if _map_view:
		_map_view.queue_redraw()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_enter_pressed() -> void:
	if _selected_key == "":
		return
	var parts: PackedStringArray = _selected_key.split("-")
	ProgressManager.current_chapter = int(parts[0])
	ProgressManager.current_stage = int(parts[1])
	get_tree().change_scene_to_file("res://scenes/main.tscn")
