extends Weapon
## AutoCannon — automatically fires at the nearest enemy.


func _ready() -> void:
	fire_rate = 1.2
	base_damage = 15.0
	bullet_speed = 420.0


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

	var nearest: Node2D = null
	var nearest_dist: float = INF
	var player_pos: Vector2 = player.global_position

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
