class_name PlayerStats
extends Resource
## Runtime stats for the player — mutated by upgrades and reset on new game.

@export var max_hp: float = 100.0
@export var hp: float = 100.0
@export var hp_regen: float = 0.5
@export var move_speed: float = 280.0
@export var damage_mult: float = 1.0
@export var fire_rate_mult: float = 1.0
@export var bullet_speed_mult: float = 1.0
@export var bullet_size_mult: float = 1.0
@export var extra_projectiles: int = 0
@export var magnet_radius: float = 60.0
@export var xp_mult: float = 1.0
@export var body_size: float = 1.0   # 体型：越大越难被击退


func reset() -> void:
	max_hp = 100.0
	hp = 100.0
	hp_regen = 0.5
	move_speed = 280.0
	damage_mult = 1.0
	fire_rate_mult = 1.0
	bullet_speed_mult = 1.0
	bullet_size_mult = 1.0
	extra_projectiles = 0
	magnet_radius = 60.0
	xp_mult = 1.0
	body_size = 1.0
