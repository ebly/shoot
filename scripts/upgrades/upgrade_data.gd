class_name UpgradeResource
extends Resource
## A single upgrade definition — delegate to ItemsData config.
## Subclasses override _do_apply; the generic class reads from config/items.gd.

@export var id: String = ""
@export var label: String = ""
@export var description: String = ""
@export var max_level: int = 5
var _applied_count: int = 0

## Override in subclasses or set via Callable.
func apply(player) -> void:
	_do_apply(player)
	_applied_count += 1

func _do_apply(_player) -> void:
	pass

func is_maxed() -> bool:
	return _applied_count >= max_level


# ── 通用道具升级（所有配置来自 ItemsData） ──────────────────
class ItemUpgrade extends UpgradeResource:
	## 从 ItemsData 配置初始化
	func setup_from_config(cfg: Dictionary) -> void:
		id = cfg.get("id", "")
		label = cfg.get("name", "")
		description = cfg.get("desc", "")
		max_level = cfg.get("max_level", 5)

	func _do_apply(player) -> void:
		ItemsData.apply(id, player)
