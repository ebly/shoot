extends Node
## SaveManager — 存档/读档，保存金币、背包格数、关卡进度。

const SAVE_PATH: String = "user://save.cfg"


func _ready() -> void:
	load_game()


## 保存所有持久化数据
func save_game() -> void:
	var cfg: ConfigFile = ConfigFile.new()

	# ── 进度 ──
	for ch in range(1, ProgressManager.total_chapters + 1):
		for st in range(1, ProgressManager.STAGE_COUNTS[ch] + 1):
			var key: String = ProgressManager.stage_key(ch, st)
			cfg.set_value("unlocked", key, ProgressManager.is_unlocked(ch, st))
			cfg.set_value("completed", key, ProgressManager.is_completed(ch, st))

	# ── 元数据 ──
	cfg.set_value("meta", "gold", GameManager.gold)
	cfg.set_value("meta", "unlocked_backpack_slots", GameManager.unlocked_backpack_slots)

	var err: int = cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("保存失败: ", err)


## 读取持久化数据
func load_game() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(SAVE_PATH)
	if err != OK:
		return  # 首次运行，无存档

	# ── 进度 ──
	for ch in range(1, ProgressManager.total_chapters + 1):
		for st in range(1, ProgressManager.STAGE_COUNTS[ch] + 1):
			var key: String = ProgressManager.stage_key(ch, st)
			if cfg.has_section_key("unlocked", key):
				ProgressManager.unlocked[key] = cfg.get_value("unlocked", key)
			if cfg.has_section_key("completed", key):
				ProgressManager.completed[key] = cfg.get_value("completed", key)

	# ── 元数据 ──
	GameManager.gold = cfg.get_value("meta", "gold", 0)
	GameManager.unlocked_backpack_slots = cfg.get_value("meta", "unlocked_backpack_slots", 10)
