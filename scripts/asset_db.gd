extends Node
## AssetDB — generates all placeholder pixel-art textures at runtime.
## Each sprite is a small ImageTexture built from a string pattern.

var player_texture: ImageTexture
var enemy_texture: ImageTexture
var fast_enemy_texture: ImageTexture
var bullet_texture: ImageTexture
var xp_orb_texture: ImageTexture
var star_texture: ImageTexture


func _ready() -> void:
	player_texture = _make_from_pattern(PLAYER_PATTERN, PLAYER_COLORS)
	enemy_texture = _make_from_pattern(ENEMY_PATTERN, ENEMY_COLORS)
	fast_enemy_texture = _make_from_pattern(FAST_ENEMY_PATTERN, FAST_ENEMY_COLORS)
	bullet_texture = _make_dot(6, Color(1.0, 0.85, 0.2, 1.0))
	xp_orb_texture = _make_from_pattern(XP_PATTERN, XP_COLORS)
	star_texture = _make_dot(3, Color(0.9, 0.9, 0.95, 0.7))


func get_texture(key: String) -> ImageTexture:
	match key:
		"enemy_texture": return enemy_texture
		"fast_enemy_texture": return fast_enemy_texture
		"player_texture": return player_texture
		"bullet_texture": return bullet_texture
		"xp_orb_texture": return xp_orb_texture
	return null


# ── pixel-art pattern helpers ────────────────────────────────────────────────

func _make_from_pattern(rows: Array, palette: Dictionary) -> ImageTexture:
	var h: int = rows.size()
	var w: int = (rows[0] as String).length()
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # transparent background
	for y in h:
		var line: String = rows[y]
		for x in w:
			var ch: String = line[x]
			if palette.has(ch):
				img.set_pixel(x, y, palette[ch])
	return ImageTexture.create_from_image(img)


func _make_dot(size: int, color: Color) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


# ── PLAYER — 16×16 top-down fighter jet ─────────────────────────────────────

const PLAYER_COLORS := {
	"#": Color(0.18, 0.45, 0.85, 1.0),  # main body blue
	"@": Color(0.40, 0.75, 1.0, 1.0),   # cockpit highlight
	".": Color(0, 0, 0, 0),             # transparent
}

const PLAYER_PATTERN: Array[String] = [
	"................",
	"......@@........",
	".....####.......",
	"....######......",
	"....#@##@#......",
	"...########.....",
	"..##########....",
	"..##########....",
	"...########.....",
	"....######......",
	".....####.......",
	"......##........",
	".....####.......",
	"....#@##@#......",
	"....######......",
	"................",
]


# ── ENEMY (basic) — 16×16 red blob / crab ───────────────────────────────────

const ENEMY_COLORS := {
	"#": Color(0.85, 0.18, 0.18, 1.0),  # body red
	"@": Color(0.95, 0.40, 0.20, 1.0),  # eye / accent
	".": Color(0, 0, 0, 0),
}

const ENEMY_PATTERN: Array[String] = [
	"................",
	".....####.......",
	"...########.....",
	"..##########....",
	".############...",
	".####@##@####...",
	".############...",
	".############...",
	"..##########....",
	"...########.....",
	"....######......",
	".....#..##......",
	"....#....##.....",
	"....#.....#.....",
	"................",
	"................",
]


# ── FAST ENEMY — 12×12 smaller, spikier, orange ─────────────────────────────

const FAST_ENEMY_COLORS := {
	"#": Color(0.90, 0.35, 0.10, 1.0),
	"@": Color(1.0, 0.60, 0.20, 1.0),
	".": Color(0, 0, 0, 0),
}

const FAST_ENEMY_PATTERN: Array[String] = [
	".....##.....",
	"....####....",
	"...######...",
	"..########..",
	"..##@##@#...",
	"..########..",
	"..########..",
	"...######...",
	"....####....",
	"....#..#....",
	"...#....#...",
	"............",
]


# ── XP ORB — 10×10 green diamond ────────────────────────────────────────────

const XP_COLORS := {
	"#": Color(0.15, 0.88, 0.25, 1.0),
	"@": Color(0.50, 1.0, 0.55, 1.0),
	".": Color(0, 0, 0, 0),
}

const XP_PATTERN: Array[String] = [
	"....##....",
	"...####...",
	"..######..",
	".########.",
	".##@##@##.",
	".##@##@##.",
	".########.",
	"..######..",
	"...####...",
	"....##....",
]
