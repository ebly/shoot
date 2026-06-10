class_name UpgradeCatalog
extends RefCounted
## Static helper that returns the full array of available upgrades.

static func all() -> Array[UpgradeResource]:
	var list: Array[UpgradeResource] = []

	list.append(_make(UpgradeResource.MaxHpUp.new(),       "max_hp",       "Hull Armor",      "+20 max HP",            5))
	list.append(_make(UpgradeResource.RegenUp.new(),       "regen",        "Nano Repair",     "+0.3 HP/sec regen",     5))
	list.append(_make(UpgradeResource.SpeedUp.new(),       "speed",        "Afterburner",     "+30 move speed",        5))
	list.append(_make(UpgradeResource.DamageUp.new(),      "damage",       "Armor-Piercing",  "+20% bullet damage",    5))
	list.append(_make(UpgradeResource.FireRateUp.new(),    "fire_rate",    "Auto-Feeder",     "+15% fire rate",        5))
	list.append(_make(UpgradeResource.BulletSpeedUp.new(), "bullet_speed", "Muzzle Booster",  "+20% bullet speed",     5))
	list.append(_make(UpgradeResource.BulletSizeUp.new(),  "bullet_size",  "Heavy Rounds",    "+15% bullet size",      5))
	list.append(_make(UpgradeResource.MultiShotUp.new(),   "multishot",    "Twin-Link",       "+1 extra projectile",   3))
	list.append(_make(UpgradeResource.MagnetUp.new(),      "magnet",       "Tractor Beam",    "+40 pickup radius",     5))
	list.append(_make(UpgradeResource.XpBoostUp.new(),     "xp_boost",     "Field Study",     "+20% XP gain",          5))

	return list


static func _make(res: UpgradeResource, id: String, lbl: String, desc: String, max_lvl: int) -> UpgradeResource:
	res.id = id
	res.label = lbl
	res.description = desc
	res.max_level = max_lvl
	return res
