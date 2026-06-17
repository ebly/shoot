# ============================================================
# ⚙️ 游戏配置文件 — 修改这里即可调整游戏数值，无需改代码
# ============================================================
class_name ConfigData
extends RefCounted

# ── 玩家基础属性 → 已移至 players.gd / BaseRole 体系
# ── 武器（自动左轮） ──────────────────────────────────────────
const WEAPON: Dictionary = {
	fire_rate = 1.2,
	base_damage = 15.0,
	bullet_speed = 420.0,
}

# ── 子弹 ──────────────────────────────────────────────────────
const BULLET: Dictionary = {
	lifetime = 5.0,                   # 存活秒数
	knockback_per_damage = 3.0,
}

# ── 升级经验曲线 ──────────────────────────────────────────────
const XP_CURVE: Dictionary = {
	base = 10.0,
	multiplier = 1.25,
}

# ── 背包 ──────────────────────────────────────────────────────
const BACKPACK: Dictionary = {
	total_slots = 25,
	default_unlocked = 10,
	slot_unlock_cost = 50,
}

# ── 关卡过关条件 → 已拆分到 config/stages/stageXX_XX.gd 各自文件
# 每个文件包含: const mode="survive"|"kill_all", const duration=N
