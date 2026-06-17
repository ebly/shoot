extends CanvasLayer
## 背包面板 — 左侧5装备 + 中央立绘+属性 + 右侧5装备 + 背包25格。

const TOTAL_SLOTS: int = ConfigData.BACKPACK.total_slots
const EQUIP_SLOTS: int = 10   # 左右各5

const BASE_STATS: Dictionary = {
	"max_hp":            {"label": "生命",   "base": 100.0, "suffix": ""},
	"hp_regen":          {"label": "恢复",   "base": 0.5,   "suffix": "/秒"},
	"move_speed":        {"label": "移速",   "base": 280.0, "suffix": ""},
	"damage_mult":       {"label": "伤害",   "base": 1.0,   "suffix": "×"},
	"fire_rate_mult":    {"label": "射速",   "base": 1.0,   "suffix": "×"},
	"extra_projectiles": {"label": "弹道",   "base": 1,     "suffix": ""},
	"magnet_radius":     {"label": "拾取",   "base": 60.0,  "suffix": ""},
	"xp_mult":           {"label": "经验",   "base": 1.0,   "suffix": "×"},
}

@onready var grid: GridContainer = $Panel/MainHBox/BackpackVBox/GridContainer
@onready var gold_label: Label = $Panel/MainHBox/BackpackVBox/BottomBar/GoldLabel
@onready var portrait_rect: TextureRect = $Panel/MainHBox/CenterVBox/PortraitRect
@onready var stats_label: RichTextLabel = $Panel/MainHBox/CenterVBox/StatsLabel
@onready var left_equip: VBoxContainer = $Panel/MainHBox/LeftEquipVBox
@onready var right_equip: VBoxContainer = $Panel/MainHBox/RightEquipVBox
@onready var slot_scene: PackedScene = preload("res://scenes/backpack_slot.tscn")

var _slots: Array = []
var _equip_slots: Array = []


func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	if AssetDB.player_texture:
		portrait_rect.texture = AssetDB.player_texture
	hide()


func open() -> void:
	_refresh()
	show()
	get_tree().paused = true


func close() -> void:
	hide()
	get_tree().paused = false


func _refresh() -> void:
	# ── 属性 ──
	var player = _find_player()
	if player and player.stats:
		var txt: String = ""
		for key in BASE_STATS:
			var info: Dictionary = BASE_STATS[key]
			var base_val = info["base"]
			var cur_val = player.stats.get(key)
			var delta = cur_val - base_val
			var delta_str: String = ""
			if delta > 0.001 or delta < -0.001:
				if key in ["damage_mult", "fire_rate_mult"]:
					delta_str = " [color=#4f4]+%.1f[/color]" % delta
				else:
					delta_str = " [color=#4f4]+%d[/color]" % int(delta)
			var val_str: String
			if typeof(cur_val) == TYPE_FLOAT:
				val_str = "%.1f" % cur_val if abs(cur_val - int(cur_val)) >= 0.01 else "%d" % int(cur_val)
			else:
				val_str = "%d" % cur_val
			txt += "%s: %s%s%s\n" % [info["label"], val_str, info["suffix"], delta_str]
		stats_label.text = txt.strip_edges()

	# ── 装备栏（左右各5） ──
	for c in left_equip.get_children():
		c.queue_free()
	for c in right_equip.get_children():
		c.queue_free()
	_equip_slots.clear()

	var equipped_list: Array = UpgradeManager.get_equipped_list()
	for i in range(EQUIP_SLOTS):
		var slot = slot_scene.instantiate()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.size_flags_horizontal = Control.SIZE_FILL

		var occupied: bool = i < equipped_list.size()
		var upg_id: String = ""
		var cnt: int = 0
		if occupied:
			upg_id = equipped_list[i]["id"]
			cnt = equipped_list[i]["count"]

		if i < 5:
			left_equip.add_child(slot)
		else:
			right_equip.add_child(slot)
		_equip_slots.append(slot)

		slot.setup(i, false, occupied, upg_id, cnt, true)
		slot.unequip_requested.connect(_on_unequip_requested)

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
		slot.custom_minimum_size = Vector2(64, 64)
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

		slot.setup(i, locked, occupied, upg_id, cnt, false)
		slot.slot_pressed.connect(_on_slot_pressed)
		slot.discard_requested.connect(_on_discard_requested)
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


func _on_unlock_requested(_slot_index: int) -> void:
	if GameManager.unlock_slot():
		_refresh()
	else:
		gold_label.modulate = Color(1, 0.3, 0.3, 1)
		await get_tree().create_timer(0.3).timeout
		gold_label.modulate = Color.WHITE


func _on_unequip_requested(slot_index: int) -> void:
	var slot = _equip_slots[slot_index]
	if not slot.is_occupied:
		return
	UpgradeManager.unequip(slot.upgrade_id)
	var player = _find_player()
	if player:
		player.stats.reset()
		UpgradeManager.reapply_equipped(player)
	_refresh()


func _on_discard_requested(slot_index: int) -> void:
	var slot = _slots[slot_index]
	if not slot.is_occupied:
		return
	UpgradeManager.discard(slot.upgrade_id)
	_refresh()


func _find_player():
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null


func _on_close_pressed() -> void:
	close()
