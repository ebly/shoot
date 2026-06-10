extends Node2D
## Scrolling starfield — stars fill the camera view and drift downward.

@export var star_count: int = 200
@export var scroll_speed: float = 30.0

var _stars: Array[Dictionary] = []
var _cam_size: Vector2 = Vector2(1152, 648)


func _ready() -> void:
	z_index = -5
	_update_cam_size()
	_spawn_stars()


func _update_cam_size() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam:
		var vp: Rect2 = get_viewport_rect()
		_cam_size = vp.size / cam.zoom


func _spawn_stars() -> void:
	_stars.clear()
	for _i in star_count:
		_stars.append({
			pos = Vector2(
				randf_range(-_cam_size.x * 0.6, _cam_size.x * 0.6),
				randf_range(-_cam_size.y * 0.6, _cam_size.y * 0.6)
			),
			alpha = randf_range(0.25, 0.85),
			size = randf_range(1.0, 2.2),
		})


func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam:
		global_position = cam.global_position
		_update_cam_size()

	for s in _stars:
		s.pos.y += scroll_speed * delta
		if s.pos.y > _cam_size.y * 0.55:
			s.pos.y = -_cam_size.y * 0.55
			s.pos.x = randf_range(-_cam_size.x * 0.6, _cam_size.x * 0.6)
	queue_redraw()


func _draw() -> void:
	for s in _stars:
		draw_circle(s.pos, s.size, Color(0.9, 0.9, 1.0, s.alpha))
