extends Node
## EffectsManager — screen shake, freeze-frame, particle bursts.
## Attached to the main scene.

const PARTICLE_FX: PackedScene = preload("res://scenes/particle_fx.tscn")

var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _freeze_timer: float = 0.0
var _camera: Camera2D


func _ready() -> void:
	add_to_group("effects")
	_camera = get_viewport().get_camera_2d()


func _process(delta: float) -> void:
	# ── screen shake ──
	if _shake_timer > 0.0:
		_shake_timer -= delta
		if _camera:
			var decay: float = _shake_timer / max(_shake_duration, 0.01)
			_camera.offset = Vector2(
				randf_range(-1.0, 1.0) * _shake_intensity * decay,
				randf_range(-1.0, 1.0) * _shake_intensity * decay
			)
		if _shake_timer <= 0.0 and _camera:
			_camera.offset = Vector2.ZERO

	# ── freeze-frame ──
	if _freeze_timer > 0.0:
		_freeze_timer -= delta
		Engine.time_scale = 0.1
		if _freeze_timer <= 0.0:
			Engine.time_scale = 1.0


# ── public API ──

func shake(intensity: float = 6.0, duration: float = 0.15) -> void:
	_shake_intensity = intensity
	_shake_duration = duration
	_shake_timer = duration


func freeze(duration: float = 0.08) -> void:
	_freeze_timer = duration


func burst(pos: Vector2, count: int, color: Color, speed_range: Vector2, size_range: Vector2, life: float) -> void:
	for _i in count:
		var p: Node2D = PARTICLE_FX.instantiate()
		p.global_position = pos
		p.velocity = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(speed_range.x, speed_range.y)
		p.color = color
		p.size = randf_range(size_range.x, size_range.y)
		p.lifetime = life
		add_child(p)


func death_burst(pos: Vector2) -> void:
	burst(pos, 8, Color(1.0, 0.35, 0.1), Vector2(30, 100), Vector2(2.0, 4.5), 0.5)


func xp_pop(pos: Vector2) -> void:
	burst(pos, 5, Color(0.3, 1.0, 0.45), Vector2(20, 70), Vector2(1.5, 3.5), 0.3)


func damage_burst(pos: Vector2) -> void:
	burst(pos, 4, Color(1.0, 0.85, 0.2), Vector2(20, 60), Vector2(1.5, 3.0), 0.25)
