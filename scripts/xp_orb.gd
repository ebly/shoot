extends Area2D
## XP Orb — when the player is nearby, magnet toward them; on contact, grant XP.

@export var xp_amount: int = 5

var player_ref: CharacterBody2D = null
var magnet_speed: float = 300.0
var life_timer: float = 0.0
var magnet_delay: float = 0.35  # brief pause before magnet activates


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# collision shape — deferred to avoid flushing-queries during spawn
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 5.0
	$CollisionShape2D.set_deferred("shape", shape)

	# sprite
	$Sprite2D.texture = AssetDB.xp_orb_texture
	$Sprite2D.scale = Vector2(2.0, 2.0)

	# resolve player
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	life_timer += delta
	if life_timer > 10.0:
		# start blinking and disappear
		if life_timer > 12.0:
			queue_free()
		$Sprite2D.modulate.a = 0.3 + 0.7 * abs(sin((life_timer - 10.0) * 10.0))
		return

	if player_ref == null or life_timer < magnet_delay:
		return

	var dist: float = player_ref.global_position.distance_to(global_position)
	var magnet_range: float = player_ref.get_magnet_radius()

	if dist < magnet_range:
		var dir: Vector2 = (player_ref.global_position - global_position).normalized()
		var spd: float = magnet_speed * (1.0 + (magnet_range - dist) / magnet_range)
		global_position += dir * spd * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()


func _collect() -> void:
	_effects().xp_pop(global_position)
	var mult: float = 1.0
	if player_ref and player_ref.stats:
		mult = player_ref.stats.xp_mult
	GameManager.gain_xp(int(xp_amount * mult))
	queue_free()


func _effects() -> Node:
	var g: Node = get_tree().get_first_node_in_group("effects")
	if g:
		return g
	return get_node_or_null("/root/Main/EffectsManager")
