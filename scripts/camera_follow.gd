extends Camera2D
## Simple camera that follows the player node.

@export var smooth_speed: float = 8.0

var target: Node2D = null
var _snapped: bool = false


func _process(delta: float) -> void:
	if target == null:
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0] as Node2D
		else:
			return

	if not _snapped:
		global_position = target.global_position
		_snapped = true

	global_position = global_position.lerp(target.global_position, smooth_speed * delta)
