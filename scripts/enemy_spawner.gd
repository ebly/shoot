extends Node2D
## EnemySpawner — spawns waves of enemies around the screen edges.

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var spawn_margin: float = 40.0

var spawn_timer: float = 0.0
var spawn_interval: float = 1.8        # seconds between spawns
var time_elapsed: float = 0.0
var fast_enemy_threshold: float = 60.0  # seconds until fast enemies appear

# zombie type definitions
var basic_zombie: Dictionary = {
	"max_hp": 30.0,
	"speed": 100.0,
	"grab_damage": 6.0,
	"xp_value": 5,
	"texture_key": "enemy_texture",
}

var fast_zombie: Dictionary = {
	"max_hp": 15.0,
	"speed": 180.0,
	"grab_damage": 4.0,
	"xp_value": 3,
	"texture_key": "fast_enemy_texture",
}


func _ready() -> void:
	# Match spawn timer to the first spawn quickly
	spawn_timer = 0.3


func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	time_elapsed += delta
	spawn_timer -= delta

	if spawn_timer <= 0.0:
		_spawn_wave()
		spawn_timer = spawn_interval
		# Gradually decrease interval (min 0.3s)
		spawn_interval = max(0.3, spawn_interval - 0.015)


func _spawn_wave() -> void:
	var count: int = 1 + int(time_elapsed / 30.0)  # more enemies as time goes on
	for i in count:
		_spawn_one()


func _spawn_one() -> void:
	var e = enemy_scene.instantiate()
	e.global_position = _random_edge_pos()

	# Pick type
	var type: Dictionary = basic_zombie
	if time_elapsed >= fast_enemy_threshold and randf() < 0.35:
		type = fast_zombie

	e.set_enemy_type(type)

	# Scale HP with time
	e.max_hp *= 1.0 + time_elapsed * 0.015
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
		0: return cam_pos + Vector2(randf_range(-hw, hw), -hh)       # top
		1: return cam_pos + Vector2(randf_range(-hw, hw), hh)        # bottom
		2: return cam_pos + Vector2(-hw, randf_range(-hh, hh))       # left
		_: return cam_pos + Vector2(hw, randf_range(-hh, hh))        # right
