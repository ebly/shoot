extends Panel
## 背包内单行物品：名称 + 数量 + 装备按钮

signal equip_pressed

var _upgrade_id: String = ""


func setup(upg, count: int) -> void:
	_upgrade_id = upg.id
	$HBox/NameLabel.text = upg.label
	$HBox/CountLabel.text = "×%d" % count


func _on_equip_button_pressed() -> void:
	equip_pressed.emit()
