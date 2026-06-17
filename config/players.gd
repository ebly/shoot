# ============================================================
# 👤 玩家角色定义
# 每个元素 = 一个可选角色，继承 BaseRole.COMMON。
# ============================================================
class_name Players
extends RefCounted

# ── 玩家专属属性默认值 ──────────────────────────────────────
const DEFAULTS = {
	hp_regen          = 0.0,
	damage_mult       = 1.0,
	fire_rate_mult    = 1.0,
	bullet_speed_mult = 1.0,
	bullet_size_mult  = 1.0,
	extra_projectiles = 1,
	magnet_radius     = 60.0,
	xp_mult           = 1.0,
}

# 默认选中的角色索引
const DEFAULT_INDEX: int = 0


## 构建玩家属性（COMMON + DEFAULTS + overrides）。
static func make(overrides: Dictionary) -> Dictionary:
	var result: Dictionary = BaseRole.COMMON.duplicate()
	for k in DEFAULTS:
		result[k] = DEFAULTS[k]
	for k in overrides:
		result[k] = overrides[k]
	return result


# ── 原始角色数据（仅覆盖值，不调用函数） ───────────────────
const RAW: Array = [
	{ id = "survivor", name = "幸存者", max_hp = 100.0, speed = 280.0, hp_regen = 0.5, body_size = 1.0 },
]


## 按索引获取角色属性（运行时构建完整字典）。
static func get_data(index: int) -> Dictionary:
	if index < 0 or index >= RAW.size():
		return make(RAW[0])
	return make(RAW[index])


## 获取当前使用的角色属性。
static func get_current() -> Dictionary:
	return get_data(DEFAULT_INDEX)
