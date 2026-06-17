extends Area2D
## Bullet — flies in a direction, damages the first enemy it hits, self-destructs.

var direction: Vector2 = Vector2.UP
var speed: float = 400.0
var damage: float = 15.0

var _lifetime: float = ConfigData.BULLET.lifetime


func _ready() -> void:
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 3.0
	$CollisionShape2D.shape = shape

	$Sprite2D.texture = AssetDB.bullet_texture
	$Sprite2D.scale = Vector2(1.0, 1.0)

	body_entered.connect(_on_hit)


func _process(delta: float) -> void:
	# 飞出屏幕即销毁
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam:
		var vp: Rect2 = get_viewport_rect()
		var cam_pos: Vector2 = cam.global_position
		var margin: float = 80.0
		var world_rect: Rect2 = Rect2(cam_pos.x - vp.size.x * 0.5 - margin, cam_pos.y - vp.size.y * 0.5 - margin, vp.size.x + margin * 2, vp.size.y + margin * 2)
		if not world_rect.has_point(global_position):
			queue_free()
			return
	var step: float = speed * delta
	global_position += direction * step


const KNOCKBACK_PER_DAMAGE: float = ConfigData.BULLET.knockback_per_damage   # 击退力基数 = 伤害 × 弹体大小 × 此系数


func _on_hit(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if body.has_method("apply_knockback"):
			# 击退力受伤害和子弹大小共同影响
			var size_mult: float = scale.x  # 子弹缩放反映大小倍率
			body.apply_knockback(direction.normalized(), damage * size_mult * KNOCKBACK_PER_DAMAGE)
		queue_free()
