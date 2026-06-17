# ============================================================
# 🧬 角色通用属性模板
# 只有所有角色共有的字段放在这里，玩家/僵尸专属属性各自定义。
# ============================================================
class_name BaseRole
extends RefCounted

# ── 通用属性（玩家和僵尸共有的） ────────────────────────────
const COMMON = {
	id        = "",
	name      = "",
	max_hp    = 100.0,
	speed     = 280.0,
	body_size = 1.0,
}


## 从 COMMON + 自定义覆盖构建属性字典。
static func build(overrides: Dictionary) -> Dictionary:
	var result: Dictionary = COMMON.duplicate()
	for k in overrides:
		result[k] = overrides[k]
	return result
