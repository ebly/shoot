extends Weapon
## AutoCannon — 自动射击最近的一个僵尸。


func _ready() -> void:
	fire_rate = ConfigData.WEAPON.fire_rate
	base_damage = ConfigData.WEAPON.base_damage
	bullet_speed = ConfigData.WEAPON.bullet_speed


func _process(delta: float) -> void:
	super(delta)
	var interval: float = 1.0 / _effective_fire_rate()
	if time_since_last_shot >= interval:
		time_since_last_shot -= interval
		var target: Vector2 = _get_target_pos()
		if target != Vector2.ZERO:
			_fire(target)


func _get_target_pos() -> Vector2:
	if player == null:
		return Vector2.ZERO

	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return Vector2.ZERO

	var player_pos: Vector2 = player.global_position
	var nearest: Node2D = null
	var nearest_dist: float = INF

	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d: float = player_pos.distance_squared_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e

	if nearest:
		return nearest.global_position
	return Vector2.ZERO
