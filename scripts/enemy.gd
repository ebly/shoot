extends CharacterBody2D
## Zombie — chases player, grabs on contact, deals damage over time while latched.

@export var max_hp: float = 30.0
@export var speed: float = 110.0
@export var grab_damage: float = 6.0      # damage per tick while grabbing
@export var grab_tick: float = 0.6        # seconds between damage ticks
@export var grab_range: float = 18.0      # distance to initiate grab
@export var escape_range: float = 45.0    # distance player must reach to escape grab
@export var xp_value: int = 5

var hp: float
var player_ref: CharacterBody2D = null
var is_grabbing: bool = false
var grab_timer: float = 0.0
var _sprite_orig_scale: Vector2 = Vector2(2.0, 2.0)


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp

	if $Sprite2D.texture == null:
		$Sprite2D.texture = AssetDB.enemy_texture
	$Sprite2D.scale = _sprite_orig_scale

	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 9.0
	$CollisionShape2D.shape = shape

	var hb_shape: CircleShape2D = CircleShape2D.new()
	hb_shape.radius = 14.0
	$Hitbox/CollisionShape2D.shape = hb_shape

	_resolve_player()


func set_enemy_type(type_data: Dictionary) -> void:
	max_hp = type_data.get("max_hp", 30.0)
	speed = type_data.get("speed", 110.0)
	grab_damage = type_data.get("grab_damage", 6.0)
	xp_value = type_data.get("xp_value", 5)
	hp = max_hp

	var tex_key: String = type_data.get("texture_key", "enemy_texture")
	$Sprite2D.texture = AssetDB.get_texture(tex_key)
	$Sprite2D.scale = _sprite_orig_scale


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

	var dir_to_player: Vector2 = player_ref.global_position - global_position
	var dist: float = dir_to_player.length()

	if is_grabbing:
		# ── GRABBING state ──
		# Stay close to the player
		if dist > escape_range:
			is_grabbing = false
			modulate = Color.WHITE
		else:
			# Move toward the player's position
			velocity = dir_to_player.normalized() * speed * 1.5
			move_and_slide()

			# Damage over time
			grab_timer -= delta
			if grab_timer <= 0.0:
				grab_timer = grab_tick
				if player_ref.has_method("take_damage"):
					player_ref.take_damage(grab_damage)
				_effects().damage_burst(global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5)))
			return

	# ── CHASE state ──
	var dir: Vector2 = dir_to_player.normalized()
	velocity = dir * speed
	move_and_slide()

	# Check grab initiation
	if dist < grab_range and not player_ref.is_invincible():
		is_grabbing = true
		grab_timer = 0.0
		modulate = Color(0.8, 0.6, 0.6, 1.0)  # slight red tint when grabbing


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		die()


func die() -> void:
	_effects().death_burst(global_position)
	GameManager.add_score(10)
	GameManager.enemies_killed += 1
	var drop_pos: Vector2 = global_position
	var drop_xp: int = xp_value
	call_deferred("_spawn_xp_orb", drop_pos, drop_xp)
	queue_free()


func _spawn_xp_orb(pos: Vector2, xp: int) -> void:
	var orb_scene: PackedScene = load("res://scenes/xp_orb.tscn")
	var orb: Area2D = orb_scene.instantiate()
	orb.global_position = pos
	orb.xp_amount = xp
	get_parent().add_child(orb)


func _on_hitbox_body_entered(body: Node2D) -> void:
	# Legacy contact damage fallback — grab handles most damage now
	pass


func _effects() -> Node:
	var g: Node = get_tree().get_first_node_in_group("effects")
	if g:
		return g
	return get_node_or_null("/root/Main/EffectsManager")
