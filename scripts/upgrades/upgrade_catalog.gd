class_name UpgradeCatalog
extends RefCounted
## Static helper that returns the full array of available upgrades.

static func all() -> Array[UpgradeResource]:
	var list: Array[UpgradeResource] = []

	list.append(_make(UpgradeResource.MaxHpUp.new(),       "max_hp",       "防弹衣",           "生命上限 +20",              5))
	list.append(_make(UpgradeResource.RegenUp.new(),       "regen",        "急救包",           "生命恢复 +0.3/秒",         5))
	list.append(_make(UpgradeResource.SpeedUp.new(),       "speed",        "跑鞋",             "移速 +30",                  5))
	list.append(_make(UpgradeResource.DamageUp.new(),      "damage",       "穿甲弹",           "伤害 +20%",                 5))
	list.append(_make(UpgradeResource.FireRateUp.new(),    "fire_rate",    "快速换弹",         "射速 +15%",                 5))
	list.append(_make(UpgradeResource.BulletSpeedUp.new(), "bullet_speed", "膛线改造",         "子弹速度 +20%",             5))
	list.append(_make(UpgradeResource.BulletSizeUp.new(),  "bullet_size",  "重型弹药",         "子弹大小 +15%",             5))
	list.append(_make(UpgradeResource.MultiShotUp.new(),   "multishot",    "双持",             "弹道 +1",                   3))
	list.append(_make(UpgradeResource.MagnetUp.new(),      "magnet",       "生存直觉",         "拾取范围 +40",             5))
	list.append(_make(UpgradeResource.XpBoostUp.new(),     "xp_boost",     "狩猎经验",         "经验获取 +20%",             5))
	list.append(_make(UpgradeResource.RangeUp.new(),       "range",        "瞄准镜",           "射程 +40",                  5))

	return list


static func _make(res: UpgradeResource, id: String, lbl: String, desc: String, max_lvl: int) -> UpgradeResource:
	res.id = id
	res.label = lbl
	res.description = desc
	res.max_level = max_lvl
	return res
