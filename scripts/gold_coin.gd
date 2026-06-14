extends Area2D
## 金币 — 僵尸掉落，玩家靠近时自动吸附，拾取后增加金币数量。

@export var gold_amount: int = 1

var player_ref: CharacterBody2D = null
var magnet_speed: float = 300.0
var magnet_delay: float = 0.15

var _magnet_timer: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# 碰撞形状
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 5.0
	$CollisionShape2D.set_deferred("shape", shape)

	# 精灵 — 黄色圆点代表金币
	$Sprite2D.texture = AssetDB.gold_coin_texture
	$Sprite2D.scale = Vector2(2.0, 2.0)

	# 查找玩家
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	if player_ref == null:
		return

	_magnet_timer += delta
	if _magnet_timer < magnet_delay:
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
	_effects().gold_pop(global_position)
	GameManager.add_gold(gold_amount)
	queue_free()


func _effects() -> Node:
	var g: Node = get_tree().get_first_node_in_group("effects")
	if g:
		return g
	return get_node_or_null("/root/Main/EffectsManager")
