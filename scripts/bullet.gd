extends Area2D
## Bullet — flies in a direction, damages the first enemy it hits, self-destructs.

var direction: Vector2 = Vector2.UP
var speed: float = 400.0
var damage: float = 15.0
var lifetime: float = 3.0


func _ready() -> void:
	# collision shape
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 3.0
	$CollisionShape2D.shape = shape

	# sprite
	$Sprite2D.texture = AssetDB.bullet_texture
	$Sprite2D.scale = Vector2(2.5, 2.5)

	body_entered.connect(_on_hit)


func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	global_position += direction * speed * delta


func _on_hit(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
