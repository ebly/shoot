class_name Weapon
extends Node
## Base class for all weapons — owned by the player, fires bullets periodically.

@export var fire_rate: float = 1.0         # shots per second (before mult)
@export var base_damage: float = 15.0
@export var bullet_speed: float = 400.0
@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var bullet_scale: float = 1.0

var player: CharacterBody2D = null
var time_since_last_shot: float = 0.0


func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return
	time_since_last_shot += delta


## Override in subclasses. Returns the world position the bullet should aim at.
func _get_target_pos() -> Vector2:
	return Vector2.ZERO


func _effective_fire_rate() -> float:
	if player and player.stats:
		return fire_rate * player.stats.fire_rate_mult
	return fire_rate


func _effective_damage() -> float:
	if player and player.stats:
		return base_damage * player.stats.damage_mult
	return base_damage


func _effective_bullet_speed() -> float:
	if player and player.stats:
		return bullet_speed * player.stats.bullet_speed_mult
	return bullet_speed


func _effective_bullet_scale() -> float:
	if player and player.stats:
		return bullet_scale * player.stats.bullet_size_mult
	return bullet_scale


func _extra_projectiles() -> int:
	if player and player.stats:
		return player.stats.extra_projectiles
	return 0


func _fire(target_pos: Vector2) -> void:
	var dir: Vector2 = (target_pos - player.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP

	var count: int = 1 + _extra_projectiles()
	var spread: float = 0.12  # radians between shots

	for i in count:
		var b: Node = bullet_scene.instantiate()
		b.damage = _effective_damage()
		b.speed = _effective_bullet_speed()
		b.global_position = player.global_position
		b.scale = Vector2.ONE * _effective_bullet_scale()

		if count > 1:
			var offset_angle: float = (i - (count - 1) * 0.5) * spread
			b.direction = dir.rotated(offset_angle)
		else:
			b.direction = dir

		player.get_parent().add_child(b)
