extends CanvasLayer
## 升级菜单 — 升级时出现，选择「拾取→背包」或「装备→角色」。

@onready var card_container: HBoxContainer = $Panel/CardContainer
@onready var card_scene: PackedScene = preload("res://scenes/upgrade_card.tscn")

var _current_choices: Array = []
var _is_showing: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	hide()
	GameManager.level_up.connect(_on_level_up)


func _on_level_up(_new_level: int) -> void:
	_effects().freeze(0.06)
	if _is_showing:
		call_deferred("_show_choices")
		return
	_show_choices()


func _show_choices() -> void:
	_current_choices = UpgradeManager.generate_choices(3)
	if _current_choices.is_empty():
		return

	for c in card_container.get_children():
		c.queue_free()

	for upgrade in _current_choices:
		var card = card_scene.instantiate()
		card_container.add_child(card)
		card.setup(upgrade)
		card.picked.connect(_on_picked)
		card.equipped.connect(_on_equipped)

	show()
	_is_showing = true
	get_tree().paused = true


## 拾取 → 存入背包，不生效。
func _on_picked(upgrade_id: String) -> void:
	UpgradeManager.store_in_backpack(upgrade_id)
	_close()


## 装备 → 直接生效到角色。
func _on_equipped(upgrade_id: String) -> void:
	var player = _find_player()
	if player:
		UpgradeManager.apply_upgrade(upgrade_id, player)
	_close()


func _close() -> void:
	_is_showing = false
	get_tree().paused = false
	hide()


func _find_player():
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null


func _effects() -> Node:
	return get_node_or_null("/root/Main/EffectsManager")
