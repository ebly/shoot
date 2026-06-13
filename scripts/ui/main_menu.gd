extends Control
## Main menu — start, settings, quit.

@onready var settings_panel: Panel = $SettingsPanel


func _ready() -> void:
	settings_panel.hide()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/chapter_select.tscn")


func _on_settings_pressed() -> void:
	settings_panel.show()


func _on_settings_back_pressed() -> void:
	settings_panel.hide()


func _on_quit_pressed() -> void:
	get_tree().quit()
