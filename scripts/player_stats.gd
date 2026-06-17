class_name PlayerStats
extends Resource
## 玩家属性 — 初始值从 Players.get_current() 读取，升级可修改。

@export var max_hp: float = 100.0
@export var hp: float = 100.0
@export var hp_regen: float = 0.5
@export var move_speed: float = 280.0
@export var damage_mult: float = 1.0
@export var fire_rate_mult: float = 1.0
@export var bullet_speed_mult: float = 1.0
@export var bullet_size_mult: float = 1.0
@export var extra_projectiles: int = 1
@export var magnet_radius: float = 60.0
@export var xp_mult: float = 1.0
@export var body_size: float = 1.0


func reset() -> void:
	var cfg: Dictionary = Players.get_current()
	max_hp      = cfg.get("max_hp", 100.0)
	hp          = max_hp
	hp_regen    = cfg.get("hp_regen", 0.0)
	move_speed  = cfg.get("speed", 280.0)
	damage_mult = cfg.get("damage_mult", 1.0)
	fire_rate_mult = cfg.get("fire_rate_mult", 1.0)
	bullet_speed_mult = cfg.get("bullet_speed_mult", 1.0)
	bullet_size_mult = cfg.get("bullet_size_mult", 1.0)
	extra_projectiles = int(cfg.get("extra_projectiles", 1))
	magnet_radius = cfg.get("magnet_radius", 60.0)
	xp_mult     = cfg.get("xp_mult", 1.0)
	body_size   = cfg.get("body_size", 1.0)
