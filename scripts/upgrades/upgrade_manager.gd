extends Node
## UpgradeManager — singleton that holds the upgrade catalog and offers
## random choices when the player levels up.

signal choices_ready(upgrades: Array)  # Array of UpgradeResource

var _upgrade_pool: Array = []          # filled from UpgradeCatalog in _ready
var _offered_ids: Array = []           # already picked this run → no repeats


func _ready() -> void:
	_upgrade_pool = UpgradeCatalog.all()


## Called by GameManager on level-up. Returns 3 random non-duplicate upgrades.
func generate_choices(count: int = 3) -> Array:
	var available: Array = []
	for u in _upgrade_pool:
		if u.id not in _offered_ids:
			available.append(u)

	if available.size() < count:
		_offered_ids.clear()
		available = _upgrade_pool.duplicate()

	available.shuffle()
	var picks: Array = available.slice(0, min(count, available.size()))

	for u in picks:
		_offered_ids.append(u.id)

	choices_ready.emit(picks)
	return picks


## Apply an upgrade to the player.
func apply_upgrade(upgrade_id: String, player: Node2D) -> void:
	for u in _upgrade_pool:
		if u.id == upgrade_id:
			u.apply(player)
			return
	push_warning("UpgradeManager: unknown upgrade id '%s'" % upgrade_id)
