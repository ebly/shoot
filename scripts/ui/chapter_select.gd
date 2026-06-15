extends Control
## ChapterSelect — 自由行走地图，背景滚动，无黑边。

var _ready_done: bool = false
var _player_pos: Vector2 = Vector2.ZERO
var _move_speed: float = 250.0
var _selected_key: String = ""
var _stage_positions: Dictionary = {}
var _map_size: Vector2 = Vector2(1600, 900)
var _screen_size: Vector2 = Vector2(1152, 648)
var _scale: float = 1.0  # 地图缩放比例（填满屏幕）

@onready var _map_container: Node2D = $MapContainer
@onready var _map_view: Node2D = $MapContainer/MapView
@onready var _map_bg: TextureRect = $MapContainer/MapBg
@onready var _map_darken: ColorRect = $MapContainer/MapDarken
@onready var _top_bar: ColorRect = $TopBar
@onready var _info_button: Button = $TopBar/BackPackButton


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	$TopBar/TitleLabel.hide()
	$EnterButton.hide()
	$ShopButton.show()

	_screen_size = get_viewport_rect().size

	# 获取地图图片尺寸
	var tex: Texture2D = _map_bg.texture
	if tex:
		_map_size = Vector2(tex.get_width(), tex.get_height())
		# 计算缩放使地图填满屏幕（无黑边）
		_scale = max(_screen_size.x / _map_size.x, _screen_size.y / _map_size.y)
		var scaled: Vector2 = _map_size * _scale
		_map_bg.custom_minimum_size = scaled
		_map_bg.size = scaled
		_map_darken.custom_minimum_size = scaled
		_map_darken.size = scaled
		# MapView 缩放匹配背景图
		_map_view.scale = Vector2(_scale, _scale)

	# 用地图像素坐标计算关卡位置，乘缩放因子
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

	# 章节标签和关卡数字（作为 MapView 子节点，随地图滚动）
	for ch in range(1, ProgressManager.total_chapters + 1):
		var first_key: String = ProgressManager.stage_key(ch, 1)
		if first_key in _stage_positions:
			var pos: Vector2 = _stage_positions[first_key]
			var lbl: Label = Label.new()
			lbl.text = "第%d章" % ch
			lbl.position = Vector2(pos.x - 80, pos.y - 8)
			lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 0.9))
			lbl.add_theme_font_size_override("font_size", 14)
			_map_view.add_child(lbl)

	for key in _stage_positions:
		var pos: Vector2 = _stage_positions[key]
		var parts: PackedStringArray = key.split("-")
		var st: int = int(parts[1])
		var lbl: Label = Label.new()
		lbl.text = str(st)
		lbl.position = pos - Vector2(5, 10)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
		lbl.add_theme_font_size_override("font_size", 13)
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

	# 更新顶部信息栏
	var bp_count: int = 0
	for u in UpgradeManager.get_upgrade_pool():
		bp_count += UpgradeManager.get_backpack_count(u.id)
	var unlocked: int = GameManager.unlocked_backpack_slots
	_info_button.text = "💰 %d       🎒 %d/%d" % [GameManager.gold, min(bp_count, unlocked), unlocked]

	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_player_pos += input * _move_speed * delta

	# 限制到地图范围
	_player_pos.x = clamp(_player_pos.x, 0, _map_size.x)
	_player_pos.y = clamp(_player_pos.y, 0, _map_size.y)

	_map_view.player_pos = _player_pos
	_update_camera()
	_check_dot_proximity()
	_map_view.queue_redraw()


func _update_camera() -> void:
	if _map_size.x <= 0:
		return
	# 缩放后的地图尺寸
	var scaled: Vector2 = _map_size * _scale

	# 偏移量：让玩家位于屏幕中央
	var offset_x: float = _screen_size.x * 0.5 - _player_pos.x * _scale
	var offset_y: float = _screen_size.y * 0.5 - _player_pos.y * _scale

	# 限制到地图边界（无黑边）
	offset_x = clamp(offset_x, _screen_size.x - scaled.x, 0)
	offset_y = clamp(offset_y, _screen_size.y - scaled.y, 0)

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
		$TopBar/TitleLabel.show()
		$TopBar/TitleLabel.text = "第%s章 · 第%s关" % [parts[0], parts[1]]
		$EnterButton.show()
	elif best_key == "" and _selected_key != "":
		_selected_key = ""
		$TopBar/TitleLabel.hide()
		$EnterButton.hide()

	_map_view.selected_key = _selected_key


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_shop_pressed() -> void:
	var shop_scene: PackedScene = preload("res://scenes/shop_panel.tscn")
	var shop = shop_scene.instantiate()
	add_child(shop)
	shop.closed.connect(func(): shop.queue_free())


func _on_enter_pressed() -> void:
	if _selected_key == "":
		return
	var parts: PackedStringArray = _selected_key.split("-")
	ProgressManager.current_chapter = int(parts[0])
	ProgressManager.current_stage = int(parts[1])
	GameManager.reset_for_new_stage()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
