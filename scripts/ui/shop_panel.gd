extends Panel
## 商店面板 — 购买临时Buff和解锁背包格。

signal closed

# 商品列表
var _items: Array = []


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_refresh()


func _refresh() -> void:
	_items = [
		{"name": "力量药水",   "desc": "下一关伤害 +20%",  "cost": 30, "type": "buff_damage",    "effect": 0.2},
		{"name": "疾跑药水",   "desc": "下一关移速 +30",  "cost": 30, "type": "buff_speed",    "effect": 30},
		{"name": "护盾药水",   "desc": "下一关生命+50",   "cost": 30, "type": "buff_hp",       "effect": 50},
		{"name": "幸运金币",   "desc": "下一关经验+20%",  "cost": 30, "type": "buff_xp",       "effect": 0.2},
		{"name": "背包扩容卡", "desc": "永久+1背包格",    "cost": 80, "type": "slot_unlock",  "effect": 1},
	]

	# 清空旧商品
	var container: VBoxContainer = $VBox/Scroll/Grid
	for c in container.get_children():
		c.queue_free()

	for item in _items:
		var row: HBoxContainer = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 40)
		container.add_child(row)

		var name_lbl: Label = Label.new()
		name_lbl.text = item["name"]
		name_lbl.size_flags_horizontal = 3
		name_lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(name_lbl)

		var desc_lbl: Label = Label.new()
		desc_lbl.text = item["desc"]
		desc_lbl.size_flags_horizontal = 3
		desc_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(desc_lbl)

		var cost_lbl: Label = Label.new()
		cost_lbl.text = "💰%d" % item["cost"]
		cost_lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(cost_lbl)

		var buy_btn: Button = Button.new()
		buy_btn.text = "购买"
		buy_btn.pressed.connect(_on_buy_pressed.bind(item))
		# 金币不足时禁用
		if GameManager.gold < item["cost"]:
			buy_btn.disabled = true
		row.add_child(buy_btn)

	# 顶部金币
	$VBox/GoldLabel.text = "💰 金币: %d" % GameManager.gold


func _on_buy_pressed(item: Dictionary) -> void:
	if item["type"] == "slot_unlock":
		if GameManager.gold >= item["cost"]:
			GameManager.spend_gold(item["cost"])
			GameManager.unlocked_backpack_slots += 1
			SaveManager.save_game()
			_refresh()
		return

	# 临时Buff — 存入 GameManager 供下一关使用
	if GameManager.gold >= item["cost"]:
		GameManager.spend_gold(item["cost"])
		# 用偏移量形式记录 buff，进入关卡时应用
		if not GameManager.has("shop_buffs"):
			GameManager.set("shop_buffs", {})
		var buffs = GameManager.get("shop_buffs")
		if buffs == null:
			buffs = {}
		buffs[item["type"]] = buffs.get(item["type"], 0) + item["effect"]
		GameManager.set("shop_buffs", buffs)
		SaveManager.save_game()
		_refresh()


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
