extends CharacterBody2D
## Enemy — chases the player, deals contact damage, drops XP on death.

@export var max_hp: float = 30.0
@export var speed: float = 110.0
@export var contact_damage: float = 10.0
@export var xp_value: int = 5

var hp: float
var player_ref: CharacterBody2D = null
var hit_cooldown: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp

	# default texture (overridden by set_enemy_type)
	if $Sprite2D.texture == null:
		$Sprite2D.texture = AssetDB.enemy_texture
	$Sprite2D.scale = Vector2(2.0, 2.0)

	# collision shape
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 9.0
	$CollisionShape2D.shape = shape

	# hitbox shape
	var hb_shape: CircleShape2D = CircleShape2D.new()
	hb_shape.radius = 12.0
	$Hitbox/CollisionShape2D.shape = hb_shape

	# find player
	_resolve_player()


func set_enemy_type(type_data: Dictionary) -> void:
	max_hp = type_data.get("max_hp", 30.0)
	speed = type_data.get("speed", 110.0)
	contact_damage = type_data.get("contact_damage", 10.0)
	xp_value = type_data.get("xp_value", 5)
	hp = max_hp

	var tex_key: String = type_data.get("texture_key", "enemy_texture")
	$Sprite2D.texture = AssetDB.get_texture(tex_key)
	$Sprite2D.scale = Vector2(2.0, 2.0)


func _resolve_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player_ref == null:
		_resolve_player()
		if player_ref == null:
			return

	var dir: Vector2 = (player_ref.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	hit_cooldown = max(0.0, hit_cooldown - delta)


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		die()


func die() -> void:
	_effects().death_burst(global_position)
	GameManager.add_score(10)
	GameManager.enemies_killed += 1

	# spawn XP orb — deferred to avoid flushing-queries error
	call_deferred("_spawn_xp_orb")

	queue_free()


func _spawn_xp_orb() -> void:
	var orb_scene: PackedScene = load("res://scenes/xp_orb.tscn")
	var orb: Area2D = orb_scene.instantiate()
	orb.global_position = global_position
	orb.xp_amount = xp_value
	get_parent().add_child(orb)

	queue_free()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and hit_cooldown <= 0.0:
		body.take_damage(contact_damage)
		hit_cooldown = 0.8


func _effects() -> Node:
	var g: Node = get_tree().get_first_node_in_group("effects")
	if g:
		return g
	return get_node_or_null("/root/Main/EffectsManager")
