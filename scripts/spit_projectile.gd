extends Area2D
## 毒液弹 — 远程僵尸喷射的毒液，飞行一段时间后消失。

var direction: Vector2 = Vector2.DOWN
var speed: float = 200.0
var damage: float = 8.0
var lifetime: float = 2.0


func _ready() -> void:
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 4.0
	$CollisionShape2D.shape = shape

	var sprite: Sprite2D = $Sprite2D
	sprite.texture = AssetDB.bullet_texture
	sprite.scale = Vector2(2.0, 2.0)
	sprite.modulate = Color(0.4, 0.85, 0.25, 1.0)  # 绿色毒液

	body_entered.connect(_on_hit)


func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	global_position += direction * speed * delta


func _on_hit(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	# 不击中敌人，只击中玩家；撞墙消失
	if not body.is_in_group("enemies") and not body.is_in_group("player"):
		queue_free()
