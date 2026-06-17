extends Node
## AssetDB — generates all placeholder pixel-art textures at runtime.
## Each sprite is a small ImageTexture built from a string pattern.

var player_texture: ImageTexture
var enemy_texture: ImageTexture
var fast_enemy_texture: ImageTexture
var spitter_texture: ImageTexture
var boss_texture: ImageTexture
var spit_texture: ImageTexture
var bullet_texture: ImageTexture
var xp_orb_texture: ImageTexture
var gold_coin_texture: ImageTexture
var star_texture: ImageTexture


func _ready() -> void:
	player_texture = _make_from_pattern(PLAYER_PATTERN, PLAYER_COLORS)
	enemy_texture = _make_from_pattern(ENEMY_PATTERN, ENEMY_COLORS)
	fast_enemy_texture = _make_from_pattern(FAST_ENEMY_PATTERN, FAST_ENEMY_COLORS)
	spitter_texture = _make_from_pattern(SPITTER_PATTERN, SPITTER_COLORS)
	boss_texture = _make_dot(14, Color(0.65, 0.15, 0.15, 1.0))
	bullet_texture = _make_dot(4, Color(0.55, 0.55, 0.58, 1.0))
	spit_texture = _make_dot(6, Color(0.3, 0.85, 0.25, 1.0))
	xp_orb_texture = _make_from_pattern(XP_PATTERN, XP_COLORS)
	gold_coin_texture = _make_dot(8, Color(1.0, 0.80, 0.10, 1.0))
	star_texture = _make_dot(3, Color(0.9, 0.9, 0.95, 0.7))


func get_texture(key: String) -> ImageTexture:
	match key:
		"enemy_texture": return enemy_texture
		"fast_enemy_texture": return fast_enemy_texture
		"spitter_texture": return spitter_texture
		"boss_texture": return boss_texture
		"spit_texture": return spit_texture
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


# ── PLAYER — 16×16 top-down human survivor facing right ───────────────────

const PLAYER_COLORS := {
	"#": Color(0.18, 0.55, 0.85, 1.0),   # shirt blue
	"@": Color(1.0, 0.78, 0.55, 1.0),    # skin / face
	"$": Color(0.25, 0.20, 0.18, 1.0),   # pants / shoes
	"%": Color(0.35, 0.30, 0.28, 1.0),   # hat / hair
	"!": Color(0.15, 0.15, 0.15, 1.0),   # gun
	"&": Color(0, 0, 0, 0.0),            # unused
	".": Color(0, 0, 0, 0),
}

const PLAYER_PATTERN: Array[String] = [
	"................",
	"....%%%%%.......",
	"...%%%%%%%......",
	"..%%@%@@%%......",
	"..%%@%@@%%......",
	"...%%%%%%%......",
	"..#########.....",
	".##......##.....",
	".##..###.##.....",
	".##..###.##!....",
	"..####.####!....",
	"...#.....##.....",
	"$$.##....##.....",
	"$$.##....##.....",
	"..$##..##$......",
	"................",
]


# ── ZOMBIE — 16×16 slow shambling zombie ────────────────────────────────────

const ENEMY_COLORS := {
	"#": Color(0.30, 0.45, 0.25, 1.0),   # body green-brown
	"@": Color(0.50, 0.65, 0.30, 1.0),   # skin undead green
	"$": Color(0.40, 0.25, 0.20, 1.0),   # tattered clothes
	"%": Color(0.25, 0.15, 0.10, 1.0),   # hair
	"!": Color(0.90, 0.10, 0.05, 1.0),   # eyes (red)
	".": Color(0, 0, 0, 0),
}

const ENEMY_PATTERN: Array[String] = [
	"................",
	"....%%%%%.......",
	"...%%@%@@%%.....",
	"..%%@!@!@%%.....",
	"..%%@@@@@%%.....",
	"...%%@%@%%......",
	"..$$$$$$$$$.....",
	".$$......$$.....",
	".$$..$$$.$$.....",
	".$$..$$$..$$....",
	"..$$$.$$$.......",
	"...@....@.......",
	"..@......@......",
	".@........@.....",
	"................",
	"................",
]


# ── SPITTER ZOMBIE — 16×16 green spitter with boils ─────────────────────────

const SPITTER_COLORS := {
	"#": Color(0.35, 0.50, 0.20, 1.0),
	"@": Color(0.55, 0.70, 0.30, 1.0),
	"!": Color(0.95, 0.20, 0.10, 1.0),
	"$": Color(0.60, 0.80, 0.20, 1.0),  # toxic spit
	".": Color(0, 0, 0, 0),
}

const SPITTER_PATTERN: Array[String] = [
	"................",
	".....######.....",
	"....##....##....",
	"...#..$$..#.#...",
	"...#!$..$!.#....",
	"...##$$$$.##....",
	"..$$....$$$.....",
	".$$..##..$$......",
	".$..####..$$....",
	"..$$$$$$$.......",
	"...##..##.......",
	"...#....#.......",
	"..#......#......",
	".#........#.....",
	"................",
	"................",
]


# ── FAST ZOMBIE — 12×12 smaller, faster, orange-brown ───────────────────────

const FAST_ENEMY_COLORS := {
	"#": Color(0.60, 0.30, 0.10, 1.0),
	"@": Color(0.75, 0.45, 0.20, 1.0),
	"!": Color(0.95, 0.25, 0.05, 1.0),
	".": Color(0, 0, 0, 0),
}

const FAST_ENEMY_PATTERN: Array[String] = [
	".....##.....",
	"....####....",
	"...##@@##...",
	"..##@!@##...",
	"..########..",
	"..##@@@##...",
	"...######...",
	"....####....",
	"...$$$$$....",
	".$$....$$...",
	"$........$..",
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
