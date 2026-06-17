extends Node2D
## EnemySpawner — 按波次生成僵尸，出完本波换下一波。

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var spawn_margin: float = 40.0

var _spawn_timer: float = 0.0
var _spawn_interval: float = 1.0
var _wave_spawned: int = 0
var _boss_spawned: bool = false
var _all_waves_done: bool = false


func _ready() -> void:
	_spawn_timer = 0.3


func _process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_stage_clear:
		return

	# 当前波次信息
	var waves: Array = ProgressManager.get_stage_waves(_ch(), _st())
	var wave_count: int = waves.size()

	# 空配置 → 没有波次，直接标记生成结束
	if wave_count == 0:
		_all_waves_done = true
		GameManager.wave_active = false
		GameManager.spawn_phase_over = true
		# kill_all 且无待出 boss → 直接过关
		if GameManager.stage_mode == "kill_all" and not GameManager.boss_pending:
			GameManager.complete_stage()
		return

	# ── Boss 生成（普通波次全部出完后） ──
	if _all_waves_done and not _boss_spawned:
		var boss_id = ProgressManager.get_stage_config(_ch(), _st(), "boss", "")
		if boss_id != "":
			var can_boss: bool = false
			if GameManager.stage_mode == "survive":
				can_boss = true
			elif GameManager.stage_mode == "kill_all" and GameManager.enemies_alive <= 0:
				can_boss = true
			if can_boss:
				_spawn_boss(boss_id)
				_boss_spawned = true
		return

	if not GameManager.wave_active or _all_waves_done:
		return

	# 当前波次信息
	var wave: int = GameManager.current_wave

	if wave > wave_count:
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		var max_cnt: int = int(_wave_prop("count", 999))
		if _wave_spawned < max_cnt:
			_spawn_one()
			_wave_spawned += 1
			_spawn_timer = _wave_prop("interval", 1.0)
		else:
			# 本波出完 → 换下一波
			if wave < wave_count:
				GameManager.current_wave = wave + 1
				_wave_spawned = 0
				_spawn_timer = _wave_prop("interval", 1.0)
				GameManager.wave_changed.emit(GameManager.current_wave, wave_count)
			else:
				# 所有波次出完
				_all_waves_done = true
				GameManager.wave_active = false
				GameManager.spawn_phase_over = true
				GameManager.wave_changed.emit(wave, wave_count)


func _ch() -> int: return ProgressManager.current_chapter
func _st() -> int: return ProgressManager.current_stage

func _wave_prop(key: String, default):
	var w: int = GameManager.current_wave
	return ProgressManager.get_wave_prop(_ch(), _st(), w, key, default)


func _spawn_one() -> void:
	var wave: int = GameManager.current_wave
	var waves: Array = ProgressManager.get_stage_waves(_ch(), _st())
	var type_id: String = "basic"
	if wave <= waves.size():
		var wd = waves[wave - 1]
		if typeof(wd) == TYPE_DICTIONARY and wd.has("zombie"):
			type_id = wd.zombie

	var e = enemy_scene.instantiate()
	e.global_position = _random_edge_pos()
	e.set_enemy_type(Enemys.get_data(type_id))

	var type_info: Dictionary = Enemys.get_data(type_id)
	if type_info.get("_is_spitter", false): e._is_spitter = true
	if type_info.get("_is_boss", false):
		e._is_boss = true
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam:
			e.global_position = cam.global_position
		else:
			e.global_position = Vector2(640, 360)

	var hp_mult: float = _wave_prop("hp_mult", 1.0) * (1.0 + GameManager.survival_time * 0.005)
	e.max_hp *= hp_mult
	e.hp = e.max_hp

	GameManager.on_enemy_spawned()
	get_parent().add_child(e)


func _spawn_boss(boss_id: String) -> void:
	var boss_type: Dictionary = Enemys.get_data(boss_id)
	var e = enemy_scene.instantiate()
	e.set_enemy_type(boss_type)
	e._is_boss = true
	e.max_hp = boss_type.get("max_hp", 200.0)
	e.hp = e.max_hp

	var vp: Rect2 = get_viewport_rect()
	var cam: Camera2D = get_viewport().get_camera_2d()
	var cam_pos: Vector2 = cam.global_position if cam else Vector2.ZERO
	e.global_position = cam_pos + Vector2(vp.size.x * 0.5, -vp.size.y * 0.5)

	GameManager.on_enemy_spawned()
	get_parent().add_child(e)


func _random_edge_pos() -> Vector2:
	var vp: Rect2 = get_viewport_rect()
	var cam_pos: Vector2 = Vector2.ZERO
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam:
		cam_pos = cam.global_position

	var hw: float = vp.size.x * 0.5 + spawn_margin
	var hh: float = vp.size.y * 0.5 + spawn_margin

	var edge: int = randi() % 4
	match edge:
		0: return cam_pos + Vector2(randf_range(-hw, hw), -hh)
		1: return cam_pos + Vector2(randf_range(-hw, hw), hh)
		2: return cam_pos + Vector2(-hw, randf_range(-hh, hh))
		_: return cam_pos + Vector2(hw, randf_range(-hh, hh))
