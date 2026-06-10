extends CharacterBody2D
## Player — 8-direction movement, health, invincibility frames, magnet pickup.

signal died

@export var stats: PlayerStats
var weapons: Array[Node] = []
var invincible: bool = false
var invincible_timer: float = 0.0
var weapon_offset: float = 0.0


func _ready() -> void:
	add_to_group("player")

	if stats == null:
		stats = PlayerStats.new()

	# collision shape
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 8.0
	$CollisionShape2D.shape = shape

	# sprite
	$Sprite2D.texture = AssetDB.player_texture
	$Sprite2D.scale = Vector2(2.5, 2.5)

	# magnet area
	var magnet_shape: CircleShape2D = CircleShape2D.new()
	magnet_shape.radius = stats.magnet_radius
	$MagnetArea/CollisionShape2D.shape = magnet_shape

	# default weapon — equipped by main scene, but provide fallback
	if weapons.is_empty():
		add_default_weapon()


func add_default_weapon() -> void:
	var ac_script = load("res://scripts/weapons/auto_cannon.gd")
	var ac: Node = ac_script.new()
	ac.name = "AutoCannon"
	add_weapon(ac)


func add_weapon(weapon: Node) -> void:
	weapon.player = self
	weapons.append(weapon)
	add_child(weapon)


func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# ── movement ──
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * stats.move_speed
	move_and_slide()

	# ── invincibility flash ──
	if invincible:
		invincible_timer -= delta
		$Sprite2D.modulate.a = 0.4 + 0.6 * abs(sin(invincible_timer * 25.0))
		if invincible_timer <= 0.0:
			invincible = false
			$Sprite2D.modulate.a = 1.0

	# ── regen ──
	if stats.hp < stats.max_hp:
		stats.hp = min(stats.hp + stats.hp_regen * delta, stats.max_hp)

	# ── update magnet radius (may have changed via upgrades) ──
	if $MagnetArea/CollisionShape2D.shape is CircleShape2D:
		($MagnetArea/CollisionShape2D.shape as CircleShape2D).radius = stats.magnet_radius


func take_damage(amount: float) -> void:
	if invincible or GameManager.is_game_over:
		return
	stats.hp -= amount
	_effects().shake(5.0, 0.12)
	_effects().damage_burst(global_position)
	if stats.hp <= 0.0:
		stats.hp = 0.0
		died.emit()
		GameManager.trigger_game_over()
	else:
		invincible = true
		invincible_timer = 0.5


func get_magnet_radius() -> float:
	return stats.magnet_radius


func _effects() -> Node:
	var g: Node = get_tree().get_first_node_in_group("effects")
	if g:
		return g
	return get_node_or_null("/root/Main/EffectsManager")
