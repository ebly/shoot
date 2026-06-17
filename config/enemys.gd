# ============================================================
# 🧟 僵尸类型定义
# 每个僵尸类型使用 BaseRole.COMMON + 僵尸专属字段。
# ============================================================
class_name Enemys
extends RefCounted

# ── 僵尸专属属性默认值 ──────────────────────────────────────
const DEFAULTS = {
	grab_damage = 0.0,
	xp_value    = 0,
	texture_key = "",
}

const ID = {
	BASIC   = "basic",
	FAST    = "fast",
	SPITTER = "spitter",
	BOSS    = "boss",
}


## 构建僵尸属性（COMMON + DEFAULTS + overrides）。
static func make(overrides: Dictionary) -> Dictionary:
	var result: Dictionary = BaseRole.COMMON.duplicate()
	for k in DEFAULTS:
		result[k] = DEFAULTS[k]
	for k in overrides:
		result[k] = overrides[k]
	return result


# ── 原始僵尸数据（仅覆盖值，make() 在运行时调用） ──────────
const RAW: Dictionary = {
	basic = {
		id = "basic", name = "普通僵尸", max_hp = 10.0, speed = 100.0,
		grab_damage = 6.0, xp_value = 5, body_size = 1.0, texture_key = "enemy_texture",
	},
	fast = {
		id = "fast", name = "快速僵尸", max_hp = 8.0, speed = 180.0,
		grab_damage = 4.0, xp_value = 3, body_size = 0.5, texture_key = "fast_enemy_texture",
	},
	spitter = {
		id = "spitter", name = "喷射僵尸", max_hp = 15.0, speed = 70.0,
		grab_damage = 0.0, xp_value = 8, body_size = 0.7, texture_key = "spitter_texture",
		_is_spitter = true,
	},
	boss = {
		id = "boss", name = "BOSS僵尸", max_hp = 300.0, speed = 60.0,
		grab_damage = 15.0, xp_value = 50, body_size = 3.0, texture_key = "boss_texture",
		_is_boss = true,
	},
}


## 按 ID 获取僵尸数据（运行时构建完整字典）。
static func get_data(id: String) -> Dictionary:
	var raw: Dictionary = RAW.get(id, RAW.basic)
	return make(raw)


## 按波次获取对应僵尸 ID。
static func id_for_wave(wave: int) -> String:
	match wave:
		1: return ID.BASIC
		2: return ID.FAST
		3: return ID.SPITTER
	return ID.BASIC
