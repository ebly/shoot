extends Node2D
## EnemySpawner — 按波次生成僵尸，每波有击杀目标。

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var spawn_margin: float = 40.0

var spawn_timer: float = 0.0
var spawn_interval: float = 1.6
var time_elapsed: float = 0.0

# zombie type definitions
var basic_zombie: Dictionary = {
	"max_hp": 30.0,
	"speed": 100.0,
	"grab_damage": 6.0,
	"xp_value": 5,
	"body_size": 1.0,
	"texture_key": "enemy_texture",
}

var fast_zombie: Dictionary = {
	"max_hp": 8.0,
	"speed": 180.0,
	"grab_damage": 4.0,
	"xp_value": 3,
	"body_size": 0.5,
	"texture_key": "fast_enemy_texture",
}

var spitter_zombie: Dictionary = {
	"max_hp": 15.0,
	"speed": 70.0,
	"grab_damage": 0,
	"xp_value": 8,
	"body_size": 0.7,
	"texture_key": "spitter_texture",
}


func _ready() -> void:
	spawn_timer = 0.3


func _process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_stage_clear:
		return

	if not GameManager.wave_active or GameManager.between_waves:
		return

	time_elapsed += delta
	spawn_timer -= delta

	if spawn_timer <= 0.0:
		_spawn_cluster()
		# 每波生成间隔递减，每波重置
		var wave_mod: float = 1.0 / GameManager.current_wave
		spawn_interval = max(0.3, 1.6 * wave_mod + 0.3)
		spawn_timer = spawn_interval


func _spawn_cluster() -> void:
	var count: int = 1 + int(GameManager.current_wave / 2)  # 波次越高越多
	for _i in count:
		_spawn_one()


func _spawn_one() -> void:
	var e = enemy_scene.instantiate()
	e.global_position = _random_edge_pos()

	# 根据波次和存活时间决定类型
	var type: Dictionary = basic_zombie
	if GameManager.current_wave >= 2 and randf() < 0.2:
		type = fast_zombie
	if GameManager.current_wave >= 3 and randf() < 0.35:
		type = fast_zombie
	# 第3波起出现远程僵尸
	if GameManager.current_wave >= 3 and randf() < 0.15:
		type = spitter_zombie

	e.set_enemy_type(type)

	# 标记远程僵尸
	if type.get("texture_key") == "spitter_texture":
		e._is_spitter = true

	# HP 随波次和时间缩放
	var hp_mult: float = 1.0 + (GameManager.current_wave - 1) * 0.15 + time_elapsed * 0.005
	e.max_hp *= hp_mult
	e.hp = e.max_hp

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
