extends Panel
## A single upgrade card in the LevelUpMenu.

signal selected

var upgrade: UpgradeResource = null


func setup(upg: UpgradeResource) -> void:
	upgrade = upg
	$VBox/NameLabel.text = upg.label
	$VBox/DescLabel.text = upg.description
	if upg.is_maxed():
		$VBox/PickButton.disabled = true
		$VBox/PickButton.text = "MAXED"


func _on_pick_button_pressed() -> void:
	selected.emit()
