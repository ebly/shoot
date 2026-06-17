extends Panel
## 背包格子 — 支持背包格（装/弃）和装备格（卸）。

signal slot_pressed(slot_index: int)
signal unequip_requested(slot_index: int)
signal discard_requested(slot_index: int)
signal unlock_requested(slot_index: int)

var slot_index: int = 0
var is_locked: bool = false
var is_occupied: bool = false
var is_equip_slot: bool = false
var upgrade_id: String = ""
var upgrade_count: int = 0


func setup(index: int, locked: bool, occupied: bool, upg_id: String = "", count: int = 0, equip_slot: bool = false) -> void:
	slot_index = index
	is_locked = locked
	is_occupied = occupied
	upgrade_id = upg_id
	upgrade_count = count
	is_equip_slot = equip_slot

	var ll: Label = get_node_or_null("VBox/LockLabel")
	var nl: Label = get_node_or_null("VBox/NameLabel")
	var cl: Label = get_node_or_null("VBox/CountLabel")
	var ab: Button = get_node_or_null("VBox/HBox/ActionButton")
	var db: Button = get_node_or_null("VBox/HBox/DiscardButton")

	if ll == null or nl == null or cl == null or ab == null or db == null:
		return

	ll.visible = locked
	nl.visible = not locked and occupied
	cl.visible = not locked and occupied
	ab.visible = not locked and occupied
	db.visible = not locked and occupied and not equip_slot

	if locked:
		modulate = Color(0.4, 0.4, 0.4, 0.6)
		ll.text = "🔒"
	elif occupied:
		modulate = Color.WHITE
		var upg = UpgradeManager.find_upgrade(upgrade_id)
		if upg:
			nl.text = upg.label
		else:
			nl.text = upgrade_id
		cl.text = "×%d" % count
		ab.text = "卸 下" if equip_slot else "装 备"
	else:
		modulate = Color(0.25, 0.25, 0.25, 0.4)
		ll.text = ""


func _on_action_button_pressed() -> void:
	if is_occupied:
		if is_equip_slot:
			unequip_requested.emit(slot_index)
		else:
			slot_pressed.emit(slot_index)


func _on_discard_button_pressed() -> void:
	if is_occupied:
		discard_requested.emit(slot_index)
