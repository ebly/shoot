extends Node2D
## Tiny particle — moves outward, fades, and self-destructs.

var velocity: Vector2 = Vector2.ZERO
var color: Color = Color.WHITE
var lifetime: float = 0.4
var size: float = 3.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	velocity *= 0.93
	global_position += velocity * delta
	queue_redraw()


func _draw() -> void:
	var alpha: float = min(1.0, lifetime / 0.08)
	draw_circle(Vector2.ZERO, size * (lifetime / 0.4), Color(color, alpha))
