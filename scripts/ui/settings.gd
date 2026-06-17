extends CanvasLayer
## Settings — 设置页面。
## 包含主音量调节和返回按钮。

@onready var master_slider: HSlider = $Panel/VBox/MasterVolume/HSlider
@onready var back_button: Button = $Panel/VBox/BackButton


func _ready() -> void:
	var bus_idx: int = AudioServer.get_bus_index("Master")
	# 将当前音量(dB)转为线性值(0~1)赋给滑动条
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(value)
	)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
