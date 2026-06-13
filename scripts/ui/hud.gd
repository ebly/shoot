extends CanvasLayer
## HUD — health bar, XP bar, level, survival timer, and game-over overlay.

@onready var hp_bar: ProgressBar = $Margin/HBox/LeftPanel/HPBar
@onready var xp_bar: ProgressBar = $Margin/HBox/LeftPanel/XPBar
@onready var level_label: Label = $Margin/HBox/LeftPanel/LevelLabel
@onready var timer_label: Label = $Margin/HBox/RightPanel/TimerLabel
@onready var enemies_label: Label = $Margin/HBox/RightPanel/EnemiesLabel
@onready var game_over_panel: Panel = $GameOverPanel


func _ready() -> void:
	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_started.connect(_on_game_started)
	game_over_panel.hide()


func _process(_delta: float) -> void:
	if GameManager.is_game_over:
		return
	var t: float = GameManager.survival_time
	var mins: int = int(t) / 60
	var secs: int = int(t) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	enemies_label.text = "Kills: %d" % GameManager.enemies_killed

	# update HP bar from player
	var player: Node2D = _find_player()
	if player and player.stats:
		hp_bar.max_value = player.stats.max_hp
		hp_bar.value = player.stats.hp


func _on_xp_changed(current_xp: int, xp_to_next: int) -> void:
	xp_bar.max_value = xp_to_next
	xp_bar.value = current_xp
	level_label.text = "Lv.%d" % GameManager.level


func _on_game_over(_time: float, _score: int) -> void:
	game_over_panel.show()
	var mins: int = int(_time) / 60
	var secs: int = int(_time) % 60
	$GameOverPanel/VBox/TimeLabel.text = "Survived: %02d:%02d" % [mins, secs]
	$GameOverPanel/VBox/ScoreLabel.text = "Score: %d" % _score


func _on_game_started() -> void:
	game_over_panel.hide()
	hp_bar.value = hp_bar.max_value
	xp_bar.value = 0
	xp_bar.max_value = GameManager.xp_to_next()
	level_label.text = "Lv.1"


func _on_restart_pressed() -> void:
	GameManager.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/chapter_select.tscn")


func _find_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null
