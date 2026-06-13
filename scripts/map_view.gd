extends Node2D
## MapView — 绘制地图圆点、连线、玩家角色。

const DOT_RADIUS: float = 14.0

var stage_positions: Dictionary = {}
var selected_key: String = ""
var player_pos: Vector2 = Vector2.ZERO


func _draw() -> void:
	if stage_positions.is_empty():
		return

	# ── 连接线 ──
	for ch in range(1, ProgressManager.total_chapters + 1):
		var st_count: int = ProgressManager.STAGE_COUNTS[ch]

		for st in range(1, st_count):
			var k1: String = ProgressManager.stage_key(ch, st)
			var k2: String = ProgressManager.stage_key(ch, st + 1)
			if k1 in stage_positions and k2 in stage_positions:
				var col: Color = Color(0.2, 0.7, 0.35, 0.4) if ProgressManager.is_unlocked(ch, st + 1) else Color(0.2, 0.2, 0.25, 0.3)
				draw_line(stage_positions[k1], stage_positions[k2], col, 2.0)

		if ch < ProgressManager.total_chapters:
			var last_key: String = ProgressManager.stage_key(ch, st_count)
			var next_key: String = ProgressManager.stage_key(ch + 1, 1)
			if last_key in stage_positions and next_key in stage_positions:
				draw_line(stage_positions[last_key], stage_positions[next_key], Color(0.2, 0.2, 0.25, 0.4), 1.5, true)

	# ── 关卡圆点 ──
	for key in stage_positions:
		var pos: Vector2 = stage_positions[key]
		var parts: PackedStringArray = key.split("-")
		var ch: int = int(parts[0])
		var st: int = int(parts[1])
		var is_comp: bool = ProgressManager.is_completed(ch, st)
		var is_unl: bool = ProgressManager.is_unlocked(ch, st)

		var dot_color: Color
		if is_comp:
			dot_color = Color(0.2, 0.9, 0.35, 1.0)
		elif is_unl:
			dot_color = Color(0.25, 0.55, 0.95, 1.0)
		else:
			dot_color = Color(0.2, 0.2, 0.25, 0.45)

		if key == selected_key:
			draw_circle(pos, DOT_RADIUS + 6, Color(1.0, 1.0, 0.3, 0.18))
			draw_circle(pos, DOT_RADIUS + 3, Color(1.0, 0.9, 0.2, 0.35))

		draw_circle(pos, DOT_RADIUS, dot_color)
		draw_circle(pos, DOT_RADIUS - 3, Color(min(dot_color.r + 0.25, 1.0), min(dot_color.g + 0.25, 1.0), min(dot_color.b + 0.25, 1.0), 1.0))

	# ── 玩家角色（人类幸存者精灵）─
	var tex: ImageTexture = AssetDB.player_texture
	if tex:
		var scale: float = 2.5
		var tx_w: float = tex.get_width() * scale
		var tx_h: float = tex.get_height() * scale
		draw_texture_rect(tex, Rect2(player_pos.x - tx_w * 0.5, player_pos.y - tx_h * 0.5, tx_w, tx_h), false)
