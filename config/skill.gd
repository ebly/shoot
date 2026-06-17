# ============================================================
# 📦 被动技能配置
# 每个技能定义其 ID、名称、描述、触发方式、伤害、范围等。
# 运行时逻辑在 scripts/fire_skill.gd 中读取此配置。
# ============================================================
class_name SkillConfig
extends RefCounted

# ── 技能配置列表 ────────────────────────────────────────────
const LIST: Array[Dictionary] = [
	# ──────── 01 旋转飞弹 ────────
	{
		id          = "spinning_orb",
		name        = "旋转飞弹",
		desc        = "火焰弹围绕玩家旋转，碰触敌人造成伤害",
		trigger     = "持续环绕",
		cd          = 0.0,
		damage      = 8.0,
		range       = 45.0,        # 环绕半径
		count       = 2,           # 初始飞弹数
		color       = Color(1, 0.4, 0.1),
		style       = "火球环绕",
		type        = "orbit",
		max_level   = 5,
		per_level   = { damage = 2.0, count = 1 },
	},
	# ──────── 02 扩散冲击波 ────────
	{
		id          = "shockwave",
		name        = "扩散冲击波",
		desc        = "每 3 秒向外扩散一圈冲击波，造成伤害并击退",
		trigger     = "定时 3 秒",
		cd          = 3.0,
		damage      = 15.0,
		range       = 150.0,       # 最大扩散半径
		count       = 1,
		color       = Color(0.6, 0.6, 1.0),
		style       = "环形波",
		type        = "burst",
		max_level   = 5,
		per_level   = { damage = 3.0, range = 10.0 },
	},
	# ──────── 03 自动跟踪箭 ────────
	{
		id          = "homing_arrow",
		name        = "自动跟踪箭",
		desc        = "每 2 秒射出一枚自动跟踪最近敌人的箭矢",
		trigger     = "定时 2 秒",
		cd          = 2.0,
		damage      = 12.0,
		range       = 350.0,       # 子弹速度 px/s
		count       = 1,
		color       = Color(0.3, 0.8, 1.0),
		style       = "蓝色箭矢跟踪",
		type        = "projectile",
		max_level   = 5,
		per_level   = { damage = 2.0, cd = -0.1 },
	},
	# ──────── 04 天雷 ────────
	{
		id          = "lightning_strike",
		name        = "天雷",
		desc        = "每 4 秒对最近敌人降下雷电，高额单体伤害",
		trigger     = "定时 4 秒",
		cd          = 4.0,
		damage      = 30.0,
		range       = 200.0,       # 搜索范围
		count       = 1,
		color       = Color(1.0, 0.9, 0.3),
		style       = "闪电从天而降",
		type        = "single_target",
		max_level   = 5,
		per_level   = { damage = 5.0, range = 15.0 },
	},
	# ──────── 05 冰环 ────────
	{
		id          = "frost_ring",
		name        = "冰环",
		desc        = "每 5 秒释放冰环减速周围敌人，持续 2 秒",
		trigger     = "定时 5 秒",
		cd          = 5.0,
		damage      = 5.0,
		range       = 180.0,       # 冰环半径
		count       = 1,
		color       = Color(0.4, 0.6, 1.0),
		style       = "蓝色冰环扩散",
		type        = "debuff",
		max_level   = 5,
		per_level   = { damage = 1.0, range = 10.0, slow = 0.05 },
		slow        = 0.4,         # 减速幅度
		slow_dur    = 2.0,         # 减速持续秒
	},
	# ──────── 06 毒雾光环 ────────
	{
		id          = "poison_aura",
		name        = "毒雾光环",
		desc        = "持续对周围敌人造成中毒伤害，每秒 1 次",
		trigger     = "每秒",
		cd          = 1.0,
		damage      = 8.0,         # 每秒伤害
		range       = 90.0,
		count       = 1,
		color       = Color(0.2, 0.8, 0.2),
		style       = "绿色毒雾环绕",
		type        = "aura",
		max_level   = 5,
		per_level   = { damage = 2.0, range = 5.0 },
	},
	# ──────── 07 回旋镖 ────────
	{
		id          = "boomerang",
		name        = "回旋镖",
		desc        = "每 3 秒掷出回旋镖，去程回程都造成伤害",
		trigger     = "定时 3 秒",
		cd          = 3.0,
		damage      = 12.0,
		range       = 200.0,       # 最远飞行距离
		count       = 1,
		color       = Color(0.85, 0.65, 0.15),
		style       = "回旋镖飞行",
		type        = "boomerang",
		max_level   = 5,
		per_level   = { damage = 2.0, range = 10.0 },
	},
	# ──────── 08 地刺 ────────
	{
		id          = "ground_spike",
		name        = "地刺",
		desc        = "每 3 秒在周围多个随机位置冒出地刺",
		trigger     = "定时 3 秒",
		cd          = 3.0,
		damage      = 14.0,
		range       = 130.0,       # 地刺散布范围
		count       = 2,           # 每次地刺数
		color       = Color(0.55, 0.35, 0.15),
		style       = "地面尖刺冒出",
		type        = "random_aoe",
		max_level   = 5,
		per_level   = { damage = 2.0, count = 1 },
	},
	# ──────── 09 火焰光环 ────────
	{
		id          = "flame_aura",
		name        = "火焰光环",
		desc        = "持续灼烧光环范围内的所有敌人（每秒 2 次）",
		trigger     = "每秒 2 次",
		cd          = 0.5,
		damage      = 6.0,         # 每次判定伤害
		range       = 70.0,
		count       = 1,
		color       = Color(1.0, 0.4, 0.05),
		style       = "红色火焰光环",
		type        = "aura",
		max_level   = 5,
		per_level   = { damage = 1.5, range = 5.0 },
	},
	# ──────── 10 闪电链 ────────
	{
		id          = "chain_lightning",
		name        = "闪电链",
		desc        = "每 3 秒释放闪电击中最近敌人，然后弹射附近敌人",
		trigger     = "定时 3 秒",
		cd          = 3.0,
		damage      = 18.0,
		range       = 110.0,       # 弹射搜索范围
		count       = 3,           # 弹射次数
		color       = Color(0.6, 0.4, 1.0),
		style       = "紫色闪电弹射",
		type        = "chain",
		max_level   = 5,
		per_level   = { damage = 3.0, count = 1 },
	},
	# ──────── 11 黑洞 ────────
	{
		id          = "black_hole",
		name        = "黑洞",
		desc        = "每 6 秒创造黑洞持续 2.5 秒，吸引并伤害敌人",
		trigger     = "定时 6 秒",
		cd          = 6.0,
		damage      = 4.0,         # 每秒伤害
		range       = 120.0,       # 吸引范围
		count       = 1,
		color       = Color(0.15, 0.05, 0.35),
		style       = "紫色漩涡吸引",
		type        = "area_control",
		max_level   = 5,
		per_level   = { damage = 1.0, range = 5.0 },
	},
	# ──────── 12 圣光弹 ────────
	{
		id          = "holy_bolt",
		name        = "圣光弹",
		desc        = "每 3 秒召唤光柱，大范围伤害敌人",
		trigger     = "定时 3 秒",
		cd          = 3.0,
		damage      = 20.0,
		range       = 60.0,        # 爆炸半径
		count       = 1,
		color       = Color(0.9, 0.85, 0.5),
		style       = "金色光柱从天降",
		type        = "aoe",
		max_level   = 5,
		per_level   = { damage = 4.0, range = 5.0 },
	},
	# ──────── 13 刀刃风暴 ────────
	{
		id          = "blade_storm",
		name        = "刀刃风暴",
		desc        = "刀片围绕旋转，周期性向外甩出飞刀",
		trigger     = "每 1.5 秒甩出飞刀",
		cd          = 1.5,
		damage      = 10.0,
		range       = 300.0,       # 飞刀飞行速度 px/s
		count       = 3,           # 环绕刀片数
		color       = Color(0.7, 0.7, 0.7),
		style       = "银色刀片环绕",
		type        = "hybrid",
		max_level   = 5,
		per_level   = { damage = 1.5, count = 1 },
	},
	# ──────── 14 追踪地雷 ────────
	{
		id          = "mine_field",
		name        = "追踪地雷",
		desc        = "每 4 秒布设地雷，敌人踩到爆炸范围伤害",
		trigger     = "定时 4 秒",
		cd          = 4.0,
		damage      = 25.0,
		range       = 50.0,        # 爆炸半径
		count       = 1,
		color       = Color(0.9, 0.1, 0.1),
		style       = "红色地雷布置",
		type        = "trap",
		max_level   = 5,
		per_level   = { damage = 4.0, count = 1 },
	},
	# ──────── 15 生命汲取 ────────
	{
		id          = "life_drain",
		name        = "生命汲取",
		desc        = "每 3 秒吸取周围敌人生命，每命中一个恢复生命",
		trigger     = "定时 3 秒",
		cd          = 3.0,
		damage      = 10.0,
		range       = 100.0,
		count       = 1,
		color       = Color(0.8, 0.1, 0.3),
		style       = "红色血线吸取",
		type        = "lifesteal",
		max_level   = 5,
		per_level   = { damage = 2.0, range = 5.0 },
		heal        = 5.0,         # 每命中一个回复量
	},
	# ──────── 16 能量护盾 ────────
	{
		id          = "energy_shield",
		name        = "能量护盾",
		desc        = "每 8 秒生成护盾持续 3 秒，受伤减半",
		trigger     = "定时 8 秒",
		cd          = 8.0,
		damage      = 0.0,
		range       = 0.0,
		count       = 1,
		color       = Color(0.2, 0.6, 1.0),
		style       = "蓝色护盾包裹",
		type        = "defense",
		max_level   = 5,
		per_level   = { cd = -0.5, dur = 0.3 },
		shield_dur  = 3.0,         # 护盾持续秒
		shield_reduce = 0.5,       # 减伤比例
	},
	# ──────── 17 时空裂隙 ────────
	{
		id          = "time_rift",
		name        = "时空裂隙",
		desc        = "每 8 秒释放裂隙持续 3 秒，大幅减速敌人",
		trigger     = "定时 8 秒",
		cd          = 8.0,
		damage      = 0.0,
		range       = 150.0,
		count       = 1,
		color       = Color(0.4, 0.1, 0.7),
		style       = "紫色裂隙领域",
		type        = "debuff",
		max_level   = 5,
		per_level   = { cd = -0.3, range = 5.0 },
		slow        = 0.7,         # 减速幅度
		rift_dur    = 3.0,         # 裂隙持续秒
	},
	# ──────── 18 陨石 ────────
	{
		id          = "meteor",
		name        = "陨石",
		desc        = "每 5 秒召唤陨石砸向敌人密集区域，大范围高伤",
		trigger     = "定时 5 秒",
		cd          = 5.0,
		damage      = 35.0,
		range       = 80.0,        # 爆炸半径
		count       = 1,
		color       = Color(0.9, 0.5, 0.1),
		style       = "陨石从天而降",
		type        = "aoe",
		max_level   = 5,
		per_level   = { damage = 6.0, range = 5.0 },
	},
	# ──────── 19 激光射线 ────────
	{
		id          = "laser_beam",
		name        = "激光射线",
		desc        = "每 4 秒发射持续激光扫过前方扇形区域",
		trigger     = "定时 4 秒",
		cd          = 4.0,
		damage      = 8.0,         # 每次判定伤害
		range       = 200.0,       # 激光射程
		count       = 1,
		color       = Color(0.9, 0.1, 0.5),
		style       = "粉色激光扫射",
		type        = "beam",
		max_level   = 5,
		per_level   = { damage = 2.0, range = 10.0 },
		beam_dur    = 0.8,         # 激光持续秒
	},
	# ──────── 20 分身射击 ────────
	{
		id          = "after_image",
		name        = "分身射击",
		desc        = "每 5 秒生成分身自动射击附近敌人",
		trigger     = "定时 5 秒",
		cd          = 5.0,
		damage      = 8.0,
		range       = 300.0,
		count       = 2,           # 分身数量
		color       = Color(0.3, 0.6, 1.0),
		style       = "蓝色分身射击",
		type        = "summon",
		max_level   = 5,
		per_level   = { damage = 1.5, cd = -0.3 },
		clone_dur   = 2.0,         # 分身持续秒
	},
]


# ── 按 ID 查找 ──────────────────────────────────────────────
static func find(id: String) -> Dictionary:
	for s in LIST:
		if s.id == id:
			return s.duplicate()
	return {}


# ── 获取全部配置 ────────────────────────────────────────────
static func all() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in LIST:
		out.append(s.duplicate())
	return out


# ── 获取某类型的所有技能 ────────────────────────────────────
static func filter_by_type(type_name: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in LIST:
		if s.type == type_name:
			out.append(s.duplicate())
	return out
