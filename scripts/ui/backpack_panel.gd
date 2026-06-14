extends CanvasLayer
## 背包面板 — 5×6 格子布局，前 N 格解锁，后 20 格锁住需金币开启。

const TOTAL_SLOTS: int = GameManager.TOTAL_BACKPACK_SLOTS

@onready var grid: GridContainer = $Panel/VBox/GridContainer
@onready var gold_label: Label = $Panel/VBox/BottomBar/GoldLabel
@onready var slot_scene: PackedScene = preload("res://scenes/backpack_slot.tscn")

var _slots: Array = []  # 所有格子节点的引用


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
	# 重建格子
	for c in grid.get_children():
		c.queue_free()
	_slots.clear()

	var unlocked: int = GameManager.unlocked_backpack_slots
	# 按升级池顺序排列物品，保持显示顺序一致
	var item_list: Array = []
	for u in UpgradeManager.get_upgrade_pool():
		var cnt: int = UpgradeManager.get_backpack_count(u.id)
		if cnt > 0:
			item_list.append({"id": u.id, "count": cnt})

	# 创建 30 个格子
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
			if UpgradeManager.is_backpack_empty():
				close()


func _on_unlock_requested(slot_index: int) -> void:
	if GameManager.unlock_slot():
		_refresh()
	else:
		# 显示余额不足提示（简单闪烁金币标签）
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
