extends CanvasLayer
## 背包面板 — 查看已拾取但未装备的升级，点击「装备」生效。

@onready var item_container: VBoxContainer = $Panel/VBox/ItemContainer
@onready var empty_label: Label = $Panel/VBox/EmptyLabel
@onready var item_row_scene: PackedScene = preload("res://scenes/backpack_item_row.tscn")


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
	# 清空旧列表
	for c in item_container.get_children():
		c.queue_free()

	if UpgradeManager.is_backpack_empty():
		empty_label.show()
		return

	empty_label.hide()

	# 遍历背包（upgrade_pool 获取完整信息）
	for u in UpgradeManager.get_upgrade_pool():
		var cnt: int = UpgradeManager.get_backpack_count(u.id)
		if cnt <= 0:
			continue
		var row: Panel = item_row_scene.instantiate()
		item_container.add_child(row)
		row.setup(u, cnt)
		row.equip_pressed.connect(_on_row_equip.bind(u.id))


func _on_row_equip(upgrade_id: String) -> void:
	var player = _find_player()
	if player:
		if UpgradeManager.equip_from_backpack(upgrade_id, player):
			_refresh()
			if UpgradeManager.is_backpack_empty():
				close()


func _find_player():
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null


func _on_close_pressed() -> void:
	close()
