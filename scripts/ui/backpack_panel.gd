extends CanvasLayer
## 背包面板 — 左侧角色列表 + 中间属性&装备栏 + 右侧背包格子。

const TOTAL_SLOTS: int = GameManager.TOTAL_BACKPACK_SLOTS
const EQUIP_SLOTS: int = 10   # 最大装备格

# 角色基础属性（用于计算 +XX）
const BASE_STATS: Dictionary = {
	"max_hp":            {"label": "生命",   "base": 100.0, "suffix": ""},
	"hp_regen":          {"label": "恢复",   "base": 0.5,   "suffix": "/秒"},
	"move_speed":        {"label": "移速",   "base": 280.0, "suffix": ""},
	"attack_range":      {"label": "射程",   "base": 200.0, "suffix": ""},
	"damage_mult":       {"label": "伤害",   "base": 1.0,   "suffix": "×"},
	"fire_rate_mult":    {"label": "射速",   "base": 1.0,   "suffix": "×"},
	"extra_projectiles": {"label": "弹道",   "base": 1,     "suffix": ""},
	"magnet_radius":     {"label": "拾取",   "base": 60.0,  "suffix": ""},
	"xp_mult":           {"label": "经验",   "base": 1.0,   "suffix": "×"},
}

@onready var grid: GridContainer = $Panel/MainHBox/RightVBox/GridContainer
@onready var gold_label: Label = $Panel/MainHBox/RightVBox/BottomBar/GoldLabel
@onready var char_vbox: VBoxContainer = $Panel/MainHBox/CharacterPanel/CharVBox
@onready var stats_label: RichTextLabel = $Panel/MainHBox/DetailPanel/DetailVBox/StatsLabel
@onready var equip_grid: GridContainer = $Panel/MainHBox/DetailPanel/DetailVBox/EquipGrid
@onready var char_name_label: Label = $Panel/MainHBox/DetailPanel/DetailVBox/CharNameLabel
@onready var slot_scene: PackedScene = preload("res://scenes/backpack_slot.tscn")

var _slots: Array = []
var _equip_slots: Array = []

# 角色数据
var _characters: Array = [
	{"name": "幸存者", "color": Color(0.18, 0.55, 0.85), "unlocked": true},
	{"name": "医生",   "color": Color(0.85, 0.85, 0.85), "unlocked": false},
	{"name": "警察",   "color": Color(0.85, 0.85, 0.85), "unlocked": false},
	{"name": "运动员", "color": Color(0.85, 0.85, 0.85), "unlocked": false},
]


func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	hide()


func open() -> void:
	_refresh()
	show()
	get_tree().paused = true


func close() -> void:
	hide()
	get_tree().paused = false


func _refresh() -> void:
	# ── 角色列表 ──
	for c in char_vbox.get_children():
		c.queue_free()

	for ch in _characters:
		var icon: Panel = Panel.new()
		icon.custom_minimum_size = Vector2(56, 56)
		char_vbox.add_child(icon)

		if ch["unlocked"]:
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = ch["color"]
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			icon.add_theme_stylebox_override("panel", style)

			var lbl: Label = Label.new()
			lbl.text = ch["name"]
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", Color.WHITE)
			lbl.anchors_preset = 15
			lbl.set_anchor_and_offset(SIDE_LEFT, 0, 0)
			lbl.set_anchor_and_offset(SIDE_TOP, 0, 0)
			lbl.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
			lbl.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
			icon.add_child(lbl)
		else:
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = Color(0.25, 0.25, 0.25, 0.6)
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			icon.add_theme_stylebox_override("panel", style)

			var lbl: Label = Label.new()
			lbl.text = "?"
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 20)
			lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			lbl.anchors_preset = 15
			lbl.set_anchor_and_offset(SIDE_LEFT, 0, 0)
			lbl.set_anchor_and_offset(SIDE_TOP, 0, 0)
			lbl.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
			lbl.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
			icon.add_child(lbl)

	# ── 角色属性 ──
	var player = _find_player()
	if player and player.stats:
		char_name_label.text = "幸存者"
		var txt: String = ""
		for key in BASE_STATS:
			var info: Dictionary = BASE_STATS[key]
			var base_val = info["base"]
			var cur_val = player.stats.get(key)
			var delta = cur_val - base_val
			var delta_str: String = ""
			if delta > 0.001 or delta < -0.001:
				if key == "damage_mult" or key == "fire_rate_mult":
					delta_str = " [color=#4f4]+%.1f[/color]" % delta
				else:
					delta_str = " [color=#4f4]+%d[/color]" % int(delta)
			var val_str: String
			if typeof(cur_val) == TYPE_FLOAT:
				if abs(cur_val - int(cur_val)) < 0.01:
					val_str = "%d" % int(cur_val)
				else:
					val_str = "%.1f" % cur_val
			else:
				val_str = "%d" % cur_val
			txt += "%s: %s%s%s\n" % [info["label"], val_str, info["suffix"], delta_str]
		stats_label.text = txt.strip_edges()
	else:
		stats_label.text = "—"

	# ── 装备栏 ──
	for c in equip_grid.get_children():
		c.queue_free()
	_equip_slots.clear()

	var equipped_list: Array = UpgradeManager.get_equipped_list()
	for i in range(EQUIP_SLOTS):
		var slot = slot_scene.instantiate()
		slot.custom_minimum_size = Vector2(0, 56)
		slot.size_flags_vertical = 3
		equip_grid.add_child(slot)
		_equip_slots.append(slot)

		var occupied: bool = i < equipped_list.size()
		var upg_id: String = ""
		var cnt: int = 0
		if occupied:
			upg_id = equipped_list[i]["id"]
			cnt = equipped_list[i]["count"]
		slot.setup(i, false, occupied, upg_id, cnt)
		slot.slot_pressed.connect(_on_equip_slot_pressed.bind(i))

	# ── 背包格子 ──
	for c in grid.get_children():
		c.queue_free()
	_slots.clear()

	var unlocked: int = GameManager.unlocked_backpack_slots
	var item_list: Array = []
	for u in UpgradeManager.get_upgrade_pool():
		var cnt: int = UpgradeManager.get_backpack_count(u.id)
		if cnt > 0:
			item_list.append({"id": u.id, "count": cnt})

	for i in range(TOTAL_SLOTS):
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		_slots.append(slot)

		var locked: bool = i >= unlocked
		var occupied: bool = false
		var upg_id: String = ""
		var cnt: int = 0

		if not locked and i < item_list.size():
			occupied = true
			upg_id = item_list[i]["id"]
			cnt = item_list[i]["count"]

		slot.setup(i, locked, occupied, upg_id, cnt)
		slot.slot_pressed.connect(_on_slot_pressed)
		slot.unlock_requested.connect(_on_unlock_requested)

	gold_label.text = "💰 金币: %d" % GameManager.gold


func _on_slot_pressed(slot_index: int) -> void:
	var slot = _slots[slot_index]
	if not slot.is_occupied:
		return
	var player = _find_player()
	if player:
		if UpgradeManager.equip_from_backpack(slot.upgrade_id, player):
			_refresh()


func _on_equip_slot_pressed(slot_index: int) -> void:
	# 装备栏点击显示信息，暂不操作
	pass


func _on_unlock_requested(_slot_index: int) -> void:
	if GameManager.unlock_slot():
		_refresh()
	else:
		gold_label.modulate = Color(1, 0.3, 0.3, 1)
		await get_tree().create_timer(0.3).timeout
		gold_label.modulate = Color.WHITE


func _find_player():
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null


func _on_close_pressed() -> void:
	close()
