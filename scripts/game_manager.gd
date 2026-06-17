extends Node
## GameManager — central game-state singleton (autoload).
## Tracks score, XP, level, gold, game-over, wave/state; emits signals for the HUD.

signal xp_changed(current_xp: int, xp_to_next: int)
signal xp_gained(amount: int)
signal level_up(new_level: int)
signal game_over(survival_time: float, score: int)
signal game_started()
signal gold_changed(amount: int)
signal wave_changed(wave: int, total: int)
signal stage_complete()
signal enemies_remaining_changed(count: int)

# ── state ────────────────────────────────────────────────────────────────────

var score: int = 0
var current_xp: int = 0
var level: int = 1
var survival_time: float = 0.0
var is_game_over: bool = false
var enemies_killed: int = 0
var gold: int = 0

# ── wave / stage system ──────────────────────────────────────────────────────

var total_waves: int = 3
var current_wave: int = 1
var wave_active: bool = true      # 当前波次是否在生成僵尸
var spawn_phase_over: bool = false  # 所有波次生成结束
var is_stage_clear: bool = false   # 关卡完成

var stage_mode: String = "survive"    # "survive" | "kill_all"
var stage_duration: float = 60.0      # survive 模式的总时长
var enemies_alive: int = 0            # 当前存活僵尸数
var spawn_stage_end_time: float = 0.0 # 生成阶段结束时间（秒）
var boss_pending: bool = false        # 有待出 Boss

# 商店购买的临时增益
var shop_buffs: Dictionary = {}

const XP_BASE: float = ConfigData.XP_CURVE.base
const XP_MULTIPLIER: float = ConfigData.XP_CURVE.multiplier

# backpack slot config
const TOTAL_BACKPACK_SLOTS: int = ConfigData.BACKPACK.total_slots
const DEFAULT_UNLOCKED_SLOTS: int = ConfigData.BACKPACK.default_unlocked
const SLOT_UNLOCK_COST: int = ConfigData.BACKPACK.slot_unlock_cost
var unlocked_backpack_slots: int = DEFAULT_UNLOCKED_SLOTS


# ── public API ───────────────────────────────────────────────────────────────

func xp_to_next() -> int:
	return int(XP_BASE * pow(XP_MULTIPLIER, level - 1))


func gain_xp(amount: int) -> void:
	if is_game_over:
		return
	current_xp += amount
	xp_gained.emit(amount)

	var needed: int = xp_to_next()
	while current_xp >= needed:
		current_xp -= needed
		level += 1
		needed = xp_to_next()
		level_up.emit(level)
	xp_changed.emit(current_xp, xp_to_next())


func add_score(pts: int) -> void:
	score += pts


func add_gold(amount: int) -> void:
	if is_game_over:
		return
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false


func can_unlock_slot() -> bool:
	return unlocked_backpack_slots < TOTAL_BACKPACK_SLOTS and gold >= SLOT_UNLOCK_COST


func unlock_slot() -> bool:
	if not can_unlock_slot():
		return false
	if not spend_gold(SLOT_UNLOCK_COST):
		return false
	unlocked_backpack_slots += 1
	SaveManager.save_game()
	return true


func on_enemy_spawned() -> void:
	enemies_alive += 1


func on_enemy_killed() -> void:
	if is_game_over or is_stage_clear:
		return
	enemies_killed += 1
	enemies_alive = max(0, enemies_alive - 1)
	enemies_remaining_changed.emit(enemies_alive)

	# kill_all 模式：生成结束后，全部消灭则过关
	if stage_mode == "kill_all" and spawn_phase_over and enemies_alive <= 0:
		# Boss 待出 → 先出 Boss，暂不过关
		if boss_pending:
			boss_pending = false
			return
		_complete_stage()


## 进入新关卡时初始化。
func setup_stage(chapter: int, stage: int) -> void:
	stage_mode = ProgressManager.get_stage_mode(chapter, stage)
	stage_duration = ProgressManager.get_stage_duration(chapter, stage) if stage_mode == "survive" else 9999.0
	total_waves = max(1, ProgressManager.get_stage_waves(chapter, stage).size())
	current_wave = 1
	wave_active = true
	spawn_phase_over = false
	is_stage_clear = false
	enemies_alive = 0
	# 生成阶段持续到 stage_duration × ratio，或不超过 max_spawn_stage
	var ratio: float = ProgressManager.get_stage_config(chapter, stage, "spawn_stage_ratio", 0.7)
	var max_stage: float = ProgressManager.get_stage_config(chapter, stage, "max_spawn_stage", 60.0)
	# 生成阶段时长：survive 模式按比例，kill_all 模式按出怪总时间
	if stage_mode == "kill_all":
		var waves: Array = ProgressManager.get_stage_waves(chapter, stage)
		var total_spawn_time: float = 0.0
		for w in waves:
			if typeof(w) == TYPE_DICTIONARY:
				var cnt: float = float(w.get("count", 10))
				var interval: float = w.get("interval", 1.0)
				total_spawn_time += cnt * interval
		spawn_stage_end_time = min(total_spawn_time, 60.0)
	else:
		spawn_stage_end_time = min(stage_duration * ratio, max_stage)
	boss_pending = ProgressManager.get_stage_config(chapter, stage, "boss", "") != ""
	wave_changed.emit(current_wave, total_waves)


func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	wave_active = false
	game_over.emit(survival_time, score)


func _check_survive_complete() -> void:
	if stage_mode == "survive" and not is_stage_clear and survival_time >= stage_duration:
		_complete_stage()


func _complete_stage() -> void:
	is_stage_clear = true
	wave_active = false
	stage_complete.emit()


func reset() -> void:
	score = 0
	current_xp = 0
	level = 1
	survival_time = 0.0
	is_game_over = false
	enemies_killed = 0
	gold = 0
	unlocked_backpack_slots = DEFAULT_UNLOCKED_SLOTS
	total_waves = 3
	current_wave = 1
	wave_active = true
	spawn_phase_over = false
	is_stage_clear = false
	stage_mode = "survive"
	stage_duration = 60.0
	enemies_alive = 0
	spawn_stage_end_time = 60.0
	boss_pending = false
	shop_buffs.clear()
	UpgradeManager.reset_backpack()
	xp_changed.emit(0, xp_to_next())
	game_started.emit()


## 进入新关卡时重置（保留背包、金币、已装备）。
func reset_for_new_stage() -> void:
	score = 0
	current_xp = 0
	level = 1
	survival_time = 0.0
	is_game_over = false
	enemies_killed = 0
	total_waves = 3
	current_wave = 1
	wave_active = true
	spawn_phase_over = false
	is_stage_clear = false
	enemies_alive = 0
	xp_changed.emit(0, xp_to_next())
	game_started.emit()


# ── input-map setup (one-shot) ──────────────────────────────────────────────

func _ready() -> void:
	_setup_input_actions()


func _process(delta: float) -> void:
	if not is_game_over and not is_stage_clear:
		survival_time += delta
		if stage_mode == "survive":
			_check_survive_complete()

		# 波次推进由 Spawner 管理，此处不再按时间推进


func _update_wave() -> void:
	# 根据游戏时间决定当前波次（每波约占总时间的 1/3）
	var wave_time: float = spawn_stage_end_time / total_waves
	var new_wave: int = clamp(int(survival_time / wave_time) + 1, 1, total_waves)
	if new_wave != current_wave:
		current_wave = new_wave
		wave_changed.emit(current_wave, total_waves)


func _on_spawn_phase_end() -> void:
	wave_active = false
	spawn_phase_over = true
	wave_changed.emit(current_wave, total_waves)
	# kill_all 模式：检查当前是否已无僵尸
	if stage_mode == "kill_all" and enemies_alive <= 0:
		if boss_pending:
			boss_pending = false
		else:
			_complete_stage()


func _setup_input_actions() -> void:
	_create_action_if_missing("move_left", [KEY_A, KEY_LEFT])
	_create_action_if_missing("move_right", [KEY_D, KEY_RIGHT])
	_create_action_if_missing("move_up", [KEY_W, KEY_UP])
	_create_action_if_missing("move_down", [KEY_S, KEY_DOWN])


func _create_action_if_missing(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.5)
	for k in keys:
		var ev: InputEventKey = InputEventKey.new()
		ev.keycode = k
		InputMap.action_add_event(action, ev)
