extends Node
## UpgradeManager — 升级管理器，持有升级池并提供「拾取→背包」「装备→角色」功能。

signal choices_ready(upgrades: Array)

var _upgrade_pool: Array = []
var _offered_ids: Array = []
# 背包：upgrade_id → 已拾取次数
var backpack: Dictionary = {}
# 已装备：upgrade_id → 已装备次数
var equipped: Dictionary = {}


func _ready() -> void:
	_upgrade_pool = UpgradeCatalog.all()


## 生成 count 个随机非重复升级选项。
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


## 装备到角色身上（立即生效）。
func apply_upgrade(upgrade_id: String, player) -> void:
	for u in _upgrade_pool:
		if u.id == upgrade_id:
			u.apply(player)
			# 记录已装备
			if equipped.has(upgrade_id):
				equipped[upgrade_id] += 1
			else:
				equipped[upgrade_id] = 1
			return
	push_warning("UpgradeManager: 未知升级 id '%s'" % upgrade_id)


## 存入背包（暂不生效）。
func store_in_backpack(upgrade_id: String) -> void:
	if backpack.has(upgrade_id):
		backpack[upgrade_id] += 1
	else:
		backpack[upgrade_id] = 1


## 从背包中取出并装备到角色。
func equip_from_backpack(upgrade_id: String, player) -> bool:
	if not backpack.has(upgrade_id) or backpack[upgrade_id] <= 0:
		return false
	backpack[upgrade_id] -= 1
	if backpack[upgrade_id] <= 0:
		backpack.erase(upgrade_id)
	apply_upgrade(upgrade_id, player)
	return true


## 获取背包中该升级的已堆叠次数。
func get_backpack_count(upgrade_id: String) -> int:
	return backpack.get(upgrade_id, 0)


## 获取已装备的升级次数。
func get_equipped_count(upgrade_id: String) -> int:
	return equipped.get(upgrade_id, 0)


## 获取已装备列表（供角色面板显示）。
func get_equipped_list() -> Array:
	var list: Array = []
	for u in _upgrade_pool:
		var cnt: int = get_equipped_count(u.id)
		if cnt > 0:
			list.append({"id": u.id, "count": cnt})
	return list


## 背包是否为空。
func is_backpack_empty() -> bool:
	return backpack.is_empty()


## 重置背包（新游戏用）。
func reset_backpack() -> void:
	backpack.clear()
	equipped.clear()
	_offered_ids.clear()


## 清除已装备（游戏结束返回地图时调用）。
func clear_equipped() -> void:
	equipped.clear()


## 将全部已装备升级重新应用到玩家身上（进入新关卡时）。
func reapply_equipped(player) -> void:
	for u in _upgrade_pool:
		var cnt: int = equipped.get(u.id, 0)
		for _i in range(cnt):
			u.apply(player)
			u._applied_count -= 1  # 防重复计数


## 获取升级池（供背包面板遍历）。
func get_upgrade_pool() -> Array:
	return _upgrade_pool


## 按 ID 查找升级资源。
func find_upgrade(upgrade_id: String):
	for u in _upgrade_pool:
		if u.id == upgrade_id:
			return u
	return null
