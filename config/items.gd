# ============================================================
# 📦 道具配置（可拾取属性提升道具）
# 每个道具通过 stat 字段关联到 PlayerStats 的属性，
# 运行时用 ItemsData.apply(id, player) 生效。
# ============================================================
class_name ItemsData
extends RefCounted

# ── 道具列表 ────────────────────────────────────────────────
const LIST: Array[Dictionary] = [
	{
		id          = "max_hp",
		name        = "防弹衣",
		desc        = "生命上限 +20",
		icon_color  = Color(0.2, 0.8, 0.3),
		stat        = "max_hp",
		value       = 20.0,
		max_level   = 5,
	},
	{
		id          = "regen",
		name        = "急救包",
		desc        = "生命恢复 +0.3/秒",
		icon_color  = Color(0.2, 0.6, 0.2),
		stat        = "hp_regen",
		value       = 0.3,
		max_level   = 5,
	},
	{
		id          = "speed",
		name        = "跑鞋",
		desc        = "移速 +30",
		icon_color  = Color(0.2, 0.5, 0.9),
		stat        = "move_speed",
		value       = 30.0,
		max_level   = 5,
	},
	{
		id          = "damage",
		name        = "穿甲弹",
		desc        = "伤害 +20%",
		icon_color  = Color(0.9, 0.2, 0.2),
		stat        = "damage_mult",
		value       = 0.2,
		max_level   = 5,
	},
	{
		id          = "fire_rate",
		name        = "快速换弹",
		desc        = "射速 +15%",
		icon_color  = Color(0.9, 0.6, 0.1),
		stat        = "fire_rate_mult",
		value       = 0.15,
		max_level   = 5,
	},
	{
		id          = "bullet_speed",
		name        = "膛线改造",
		desc        = "子弹速度 +20%",
		icon_color  = Color(0.6, 0.6, 0.8),
		stat        = "bullet_speed_mult",
		value       = 0.2,
		max_level   = 5,
	},
	{
		id          = "bullet_size",
		name        = "重型弹药",
		desc        = "子弹大小 +15%",
		icon_color  = Color(0.7, 0.5, 0.3),
		stat        = "bullet_size_mult",
		value       = 0.15,
		max_level   = 5,
	},
	{
		id          = "multishot",
		name        = "双持",
		desc        = "弹道 +1",
		icon_color  = Color(0.5, 0.3, 0.8),
		stat        = "extra_projectiles",
		value       = 1.0,
		max_level   = 3,
	},
	{
		id          = "magnet",
		name        = "生存直觉",
		desc        = "拾取范围 +40",
		icon_color  = Color(0.3, 0.7, 0.7),
		stat        = "magnet_radius",
		value       = 40.0,
		max_level   = 5,
	},
	{
		id          = "xp_boost",
		name        = "狩猎经验",
		desc        = "经验获取 +20%",
		icon_color  = Color(0.8, 0.7, 0.2),
		stat        = "xp_mult",
		value       = 0.2,
		max_level   = 5,
	},
]


# ── 按 ID 查找 ──────────────────────────────────────────────
static func find(id: String) -> Dictionary:
	for d in LIST:
		if d.id == id:
			return d.duplicate()
	return {}


# ── 获取全部（浅拷贝） ──────────────────────────────────────
static func all() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d in LIST:
		out.append(d.duplicate())
	return out


# ── 将道具效果应用到玩家身上 ────────────────────────────────
static func apply(id: String, player, level: int = 1) -> bool:
	var cfg = find(id)
	if cfg.is_empty():
		return false
	var stats = player.stats
	if stats == null:
		return false

	var stat_name: String = cfg.stat
	var val: float = cfg.value * level

	# 特殊处理：max_hp 同时加当前血量
	if stat_name == "max_hp":
		stats.max_hp += val
		stats.hp = min(stats.hp + val, stats.max_hp)
		return true

	# 常规属性累加
	if stat_name in stats:
		stats.set(stat_name, stats.get(stat_name) + val)
		return true

	return false
