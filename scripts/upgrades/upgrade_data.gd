class_name UpgradeResource
extends Resource
## A single upgrade definition — name, description, and its effect.

@export var id: String = ""
@export var label: String = ""
@export var description: String = ""
@export var max_level: int = 5
var _applied_count: int = 0

## Override in subclasses or set via Callable.
## The default implementation calls `_do_apply`.
func apply(player) -> void:
	_do_apply(player)
	_applied_count += 1

func _do_apply(_player) -> void:
	pass

func is_maxed() -> bool:
	return _applied_count >= max_level


# ── concrete upgrade definitions ─────────────────────────────────────────────

class MaxHpUp extends UpgradeResource:
	func _do_apply(player) -> void:
		player.stats.max_hp += 20
		player.stats.hp = min(player.stats.hp + 20, player.stats.max_hp)

class RegenUp extends UpgradeResource:
	func _do_apply(player) -> void:
		player.stats.hp_regen += 0.3

class SpeedUp extends UpgradeResource:
	func _do_apply(player) -> void:
		player.stats.move_speed += 30

class DamageUp extends UpgradeResource:
	func _do_apply(player) -> void:
		player.stats.damage_mult += 0.2

class FireRateUp extends UpgradeResource:
	func _do_apply(player) -> void:
		player.stats.fire_rate_mult += 0.15

class BulletSpeedUp extends UpgradeResource:
	func _do_apply(player) -> void:
		player.stats.bullet_speed_mult += 0.2

class BulletSizeUp extends UpgradeResource:
	func _do_apply(player) -> void:
		player.stats.bullet_size_mult += 0.15

class MultiShotUp extends UpgradeResource:
	func _do_apply(player) -> void:
		player.stats.extra_projectiles += 1

class MagnetUp extends UpgradeResource:
	func _do_apply(player) -> void:
		player.stats.magnet_radius += 40

class XpBoostUp extends UpgradeResource:
	func _do_apply(player) -> void:
		player.stats.xp_mult += 0.2


class RangeUp extends UpgradeResource:
	func _do_apply(player) -> void:
		player.stats.attack_range += 40
