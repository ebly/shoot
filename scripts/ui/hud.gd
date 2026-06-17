extends CanvasLayer
## HUD — health bar, XP bar, level, gold, game-over, stage-clear.

@onready var hp_bar: ProgressBar = $Margin/HBox/LeftPanel/HPBar
@onready var xp_bar: ProgressBar = $Margin/HBox/LeftPanel/XPBar
@onready var level_label: Label = $Margin/HBox/LeftPanel/LevelLabel
@onready var gold_label: Label = $Margin/HBox/RightPanel/GoldLabel
@onready var timer_label: Label = $Margin/HBox/RightPanel/TimerLabel
@onready var enemies_label: Label = $Margin/HBox/RightPanel/EnemiesLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var stage_clear_panel: Panel = $StageClearPanel

func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_started.connect(_on_game_started)
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.stage_complete.connect(_on_stage_clear)
	game_over_panel.hide()
	stage_clear_panel.hide()
	_on_gold_changed(GameManager.gold)
	# 初始化关卡（game_started 在场景切换前发射，HUD 还没就绪）
	GameManager.setup_stage(ProgressManager.current_chapter, ProgressManager.current_stage)


func _process(_delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_stage_clear:
		return
	var t: float = GameManager.survival_time

	# 显示模式相关
	if GameManager.stage_mode == "kill_all":
		timer_label.hide()
	elif GameManager.stage_mode == "survive":
		timer_label.show()
		var remain: float = max(0, GameManager.stage_duration - t)
		var mins: int = int(remain) / 60
		var secs: int = int(remain) % 60
		timer_label.text = "剩余 %02d:%02d" % [mins, secs]
	else:
		timer_label.show()
		var mins: int = int(t) / 60
		var secs: int = int(t) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
	enemies_label.text = "击杀: %d" % GameManager.enemies_killed

	var player = _find_player()
	if player and player.stats:
		hp_bar.max_value = player.stats.max_hp
		hp_bar.value = player.stats.hp


func _on_xp_changed(current_xp: int, xp_to_next: int) -> void:
	xp_bar.max_value = xp_to_next
	xp_bar.value = current_xp
	level_label.text = "等级 %d" % GameManager.level


func _on_game_over(_time: float, _score: int) -> void:
	game_over_panel.show()
	var mins: int = int(_time) / 60
	var secs: int = int(_time) % 60
	$GameOverPanel/VBox/TimeLabel.text = "存活: %02d:%02d" % [mins, secs]
	$GameOverPanel/VBox/ScoreLabel.text = "得分: %d" % _score


func _on_game_started() -> void:
	GameManager.setup_stage(ProgressManager.current_chapter, ProgressManager.current_stage)
	game_over_panel.hide()
	stage_clear_panel.hide()
	hp_bar.value = hp_bar.max_value
	xp_bar.value = 0
	xp_bar.max_value = GameManager.xp_to_next()
	level_label.text = "等级 1"
	_on_gold_changed(GameManager.gold)


func _on_gold_changed(amount: int) -> void:
	gold_label.text = "金币: %d" % amount


func _on_stage_clear() -> void:
	ProgressManager.complete_stage(ProgressManager.current_chapter, ProgressManager.current_stage)
	SaveManager.save_game()
	var t: float = GameManager.survival_time
	var mins: int = int(t) / 60
	var secs: int = int(t) % 60
	$StageClearPanel/VBox/ClearScoreLabel.text = "存活: %02d:%02d\n得分: %d\n击杀: %d" % [mins, secs, GameManager.score, GameManager.enemies_killed]
	stage_clear_panel.show()
	get_tree().paused = true


func _on_restart_pressed() -> void:
	GameManager.reset_for_new_stage()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/chapter_select.tscn")


func _on_stage_continue_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/chapter_select.tscn")


func _on_gameover_map_pressed() -> void:
	UpgradeManager.clear_equipped()
	GameManager.reset_for_new_stage()
	SaveManager.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/chapter_select.tscn")


func _go_to_map() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/chapter_select.tscn")


func _on_backpack_pressed() -> void:
	var bp = get_node_or_null("/root/Main/BackpackPanel")
	if bp:
		bp.open()


func _find_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null
