extends CharacterBody2D
## Zombie — chases player, grabs on contact, deals damage over time while latched.

@export var max_hp: float = 30.0
@export var speed: float = 110.0
@export var grab_damage: float = 6.0      # damage per tick while grabbing
@export var grab_tick: float = 0.6        # seconds between damage ticks
@export var grab_range: float = 18.0      # distance to initiate grab
@export var escape_range: float = 45.0    # distance player must reach to escape grab
@export var xp_value: int = 5
@export var body_size: float = 1.0        # 体型：越大越难被击退

var hp: float
var player_ref: CharacterBody2D = null
var is_grabbing: bool = false
var grab_timer: float = 0.0
var _sprite_orig_scale: Vector2 = Vector2(2.0, 2.0)
var _is_dead: bool = false
var _knockback: Vector2 = Vector2.ZERO   # 击退速度
var _stun_timer: float = 0.0              # 击退硬直计时
var _is_spitter: bool = false             # 远程喷射僵尸
var _spit_timer: float = 0.0
const KNOCKBACK_DECAY: float = 30.0       # 击退衰减速度（高=快弹快停）


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
	body_size = type_data.get("body_size", 1.0)
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

	# ── knockback decay ──
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	_stun_timer = max(0.0, _stun_timer - delta)

	var dir_to_player: Vector2 = player_ref.global_position - global_position
	var dist: float = dir_to_player.length()

	if is_grabbing:
		# ── SPITTER state ──
	if _is_spitter:
		_spit_timer -= delta
		var ideal_dist: float = 180.0
		if dist < ideal_dist * 0.6:
			# 太近了，后退
			velocity = -dir * speed
		elif dist > ideal_dist * 1.4:
			# 太远了，靠近
			velocity = dir * speed
		else:
			velocity = Vector2.ZERO

		if _stun_timer > 0.0:
			velocity = _knockback

		move_and_slide()

		# 喷射毒液
		if _spit_timer <= 0.0 and not _stun_timer > 0.0:
			_spit_timer = 1.5 + randf() * 0.5
			_spit_at_player()
		return

	# ── GRABBING state ──
		# Stay close to the player
		if dist > escape_range:
			is_grabbing = false
			modulate = Color.WHITE
		else:
			# Move toward the player's position
			if _stun_timer > 0.0:
				velocity = _knockback
			else:
				velocity = dir_to_player.normalized() * speed * 1.5 + _knockback
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
	if _stun_timer > 0.0:
		velocity = _knockback
	else:
		velocity = dir * speed + _knockback
	move_and_slide()

	# Check grab initiation
	if dist < grab_range and not player_ref.is_invincible():
		is_grabbing = true
		grab_timer = 0.0
		modulate = Color(0.8, 0.6, 0.6, 1.0)  # slight red tint when grabbing


func take_damage(amount: float) -> void:
	if _is_dead:
		return
	hp -= amount
	if hp <= 0.0:
		die()


func apply_knockback(dir: Vector2, power: float) -> void:
	# 体型越大越难击退，最小保护值 0.3
	var resistance: float = max(body_size, 0.3)
	var force: float = power / resistance
	_knockback += dir * force
	# 短暂硬直，确保回弹不受追击干扰
	_stun_timer = max(_stun_timer, 0.12)
	# 击退打断撕咬
	if is_grabbing:
		is_grabbing = false
		modulate = Color.WHITE


func is_in_state(state: String) -> bool:
	return state == "grabbing" and is_grabbing


func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	_effects().death_burst(global_position)
	GameManager.add_score(10)
	GameManager.on_enemy_killed()
	# 掉落金币（实体拾取物）
	call_deferred("_spawn_gold_coin")
	# 经验直接增加（无需拾取）
	GameManager.gain_xp(xp_value)
	queue_free()


func _spawn_gold_coin() -> void:
	var coin_scene: PackedScene = load("res://scenes/gold_coin.tscn")
	var coin: Area2D = coin_scene.instantiate()
	coin.global_position = global_position
	coin.gold_amount = randi_range(1, 3)
	get_parent().add_child(coin)


func _on_hitbox_body_entered(body: Node2D) -> void:
	# Legacy contact damage fallback — grab handles most damage now
	pass


func _effects() -> Node:
	var g: Node = get_tree().get_first_node_in_group("effects")
	if g:
		return g
	return get_node_or_null("/root/Main/EffectsManager")


func _spit_at_player() -> void:
	if player_ref == null:
		return
	var dir_to: Vector2 = (player_ref.global_position - global_position).normalized()
	var spit: Area2D = load("res://scenes/spit_projectile.tscn").instantiate()
	spit.global_position = global_position
	spit.direction = dir_to
	get_parent().add_child(spit)
