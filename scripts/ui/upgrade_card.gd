extends Panel
## 升级卡 - 显示升级名称/描述，提供「拾取→背包」「装备→角色」双按钮。

signal picked(upgrade_id: String)
signal equipped(upgrade_id: String)

var upgrade: UpgradeResource = null


func setup(upg: UpgradeResource) -> void:
	upgrade = upg
	$VBox/NameLabel.text = upg.label
	$VBox/DescLabel.text = upg.description
	if upg.is_maxed():
		$VBox/Buttons/PickButton.disabled = true
		$VBox/Buttons/PickButton.text = "已满"
		$VBox/Buttons/EquipButton.disabled = true
		$VBox/Buttons/EquipButton.text = "已满"


func _on_pick_button_pressed() -> void:
	if upgrade:
		picked.emit(upgrade.id)


func _on_equip_button_pressed() -> void:
	if upgrade:
		equipped.emit(upgrade.id)
