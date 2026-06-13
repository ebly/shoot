extends Weapon
## AutoCannon — fires at the nearest enemy on the player's facing side.


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
	if player == null or not player.has_method("get_facing_dir"):
		return Vector2.ZERO

	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return Vector2.ZERO

	var player_pos: Vector2 = player.global_position
	var facing_dir: Vector2 = player.get_facing_dir()

	var best: Node2D = null
	var best_score: float = INF

	for e in enemies:
		if not is_instance_valid(e):
			continue
		var delta_vec: Vector2 = e.global_position - player_pos
		var dist_sq: float = delta_vec.length_squared()
		# Score: distance + huge penalty if enemy is behind the player
		var dot: float = delta_vec.normalized().dot(facing_dir)
		var score: float = dist_sq
		if dot < 0.0:
			score += 500000.0  # big penalty for enemies behind

		if score < best_score:
			best_score = score
			best = e

	if best:
		return best.global_position
	return Vector2.ZERO
