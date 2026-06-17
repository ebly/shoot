class_name UpgradeCatalog
extends RefCounted
## Static helper that returns the full array of available upgrades.
## All data is sourced from config/items.gd (ItemsData).

static func all() -> Array[UpgradeResource]:
	var list: Array[UpgradeResource] = []
	for cfg in ItemsData.all():
		var upg = UpgradeResource.ItemUpgrade.new()
		upg.setup_from_config(cfg)
		list.append(upg)
	return list
