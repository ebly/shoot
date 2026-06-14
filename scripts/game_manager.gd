extends Node
## GameManager — central game-state singleton (autoload).
## Tracks score, XP, level, gold, game-over, wave state; emits signals for the HUD.

signal xp_changed(current_xp: int, xp_to_next: int)
signal xp_gained(amount: int)
signal level_up(new_level: int)
signal game_over(survival_time: float, score: int)
signal game_started()
signal gold_changed(amount: int)
signal wave_changed(wave: int, total: int, kills: int, target: int)
signal wave_complete(wave: int)
signal stage_complete()
signal spawn_stop()
signal spawn_resume()

# ── state ────────────────────────────────────────────────────────────────────

var score: int = 0
var current_xp: int = 0
var level: int = 1
var survival_time: float = 0.0
var is_game_over: bool = false
var enemies_killed: int = 0
var gold: int = 0

# ── wave system ──────────────────────────────────────────────────────────────

var total_waves: int = 3
var current_wave: int = 1
var wave_kills: int = 0          # 当前波已击杀数
var wave_target: int = 15         # 当前波需要击杀数
var wave_active: bool = true      # 当前波是否仍在生成僵尸
var is_stage_clear: bool = false  # 全部波次完成
var between_waves: bool = false   # 波次间隙

const WAVE_BASE: int = 15
const WAVE_INCREMENT: int = 5

# tweakable XP curve: base × multiplier^level
const XP_BASE: float = 10.0
const XP_MULTIPLIER: float = 1.25

# backpack slot config
const TOTAL_BACKPACK_SLOTS: int = 30
const DEFAULT_UNLOCKED_SLOTS: int = 10
const SLOT_UNLOCK_COST: int = 50
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
	return true


func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	wave_active = false
	game_over.emit(survival_time, score)


# ── wave system ──────────────────────────────────────────────────────────────

func setup_waves(stage_waves: int = 3) -> void:
	total_waves = stage_waves
	current_wave = 1
	wave_kills = 0
	wave_target = WAVE_BASE
	wave_active = true
	is_stage_clear = false
	between_waves = false
	wave_changed.emit(current_wave, total_waves, wave_kills, wave_target)
	spawn_resume.emit()


func on_enemy_killed() -> void:
	if is_game_over or is_stage_clear or not wave_active:
		return
	enemies_killed += 1
	wave_kills += 1
	wave_changed.emit(current_wave, total_waves, wave_kills, wave_target)

	if wave_kills >= wave_target:
		_complete_wave()


func _complete_wave() -> void:
	wave_active = false
	wave_complete.emit(current_wave)
	spawn_stop.emit()

	if current_wave >= total_waves:
		# 全部波次完成 — 短延迟后弹出过关
		var t: Timer = Timer.new()
		t.one_shot = true
		t.process_mode = PROCESS_MODE_ALWAYS
		t.wait_time = 1.0
		t.timeout.connect(func():
			is_stage_clear = true
			stage_complete.emit()
			t.queue_free()
		)
		add_child(t)
		t.start()
	else:
		# 波次间隙 — 2 秒后开始下一波
		between_waves = true
		var t: Timer = Timer.new()
		t.one_shot = true
		t.process_mode = PROCESS_MODE_ALWAYS
		t.wait_time = 2.0
		t.timeout.connect(func():
			_start_next_wave()
			t.queue_free()
		)
		add_child(t)
		t.start()


func _start_next_wave() -> void:
	current_wave += 1
	wave_kills = 0
	wave_target = WAVE_BASE + (current_wave - 1) * WAVE_INCREMENT
	wave_active = true
	between_waves = false
	wave_changed.emit(current_wave, total_waves, wave_kills, wave_target)
	spawn_resume.emit()


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
	wave_kills = 0
	wave_target = WAVE_BASE
	wave_active = true
	is_stage_clear = false
	between_waves = false
	UpgradeManager.reset_backpack()
	xp_changed.emit(0, xp_to_next())
	game_started.emit()


# ── input-map setup (one-shot) ──────────────────────────────────────────────

func _ready() -> void:
	_setup_input_actions()


func _process(delta: float) -> void:
	if not is_game_over:
		survival_time += delta


func _setup_input_actions() -> void:
	# Only add if they haven't been defined in the project settings already.
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
