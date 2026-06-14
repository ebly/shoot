extends Panel
## 背包格子 — 方形格子，支持空/有物品/锁定三种状态。

signal slot_pressed(slot_index: int)
signal unlock_requested(slot_index: int)

var slot_index: int = 0
var is_locked: bool = false
var is_occupied: bool = false
var upgrade_id: String = ""
var upgrade_count: int = 0

@onready var lock_label: Label = $VBox/LockLabel
@onready var name_label: Label = $VBox/NameLabel
@onready var count_label: Label = $VBox/CountLabel
@onready var equip_button: Button = $VBox/EquipButton


func _ready() -> void:
	equip_button.pressed.connect(_on_equip_button_pressed)


func setup(index: int, locked: bool, occupied: bool, upg_id: String = "", count: int = 0) -> void:
	slot_index = index
	is_locked = locked
	is_occupied = occupied
	upgrade_id = upg_id
	upgrade_count = count

	lock_label.visible = locked
	name_label.visible = not locked and occupied
	count_label.visible = not locked and occupied
	equip_button.visible = not locked and occupied

	if locked:
		modulate = Color(0.4, 0.4, 0.4, 0.6)
		lock_label.text = "🔒"
	elif occupied:
		modulate = Color.WHITE
		var upg = UpgradeManager.find_upgrade(upgrade_id)
		if upg:
			name_label.text = upg.label
		else:
			name_label.text = upgrade_id
		count_label.text = "×%d" % count
	else:
		modulate = Color(0.25, 0.25, 0.25, 0.4)
		lock_label.text = ""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_locked:
			unlock_requested.emit(slot_index)
		elif is_occupied:
			slot_pressed.emit(slot_index)
		accept_event()


func _on_equip_button_pressed() -> void:
	if is_occupied:
		slot_pressed.emit(slot_index)
