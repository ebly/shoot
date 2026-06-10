extends Node
## GameManager — central game-state singleton (autoload).
## Tracks score, XP, level, game-over state; emits signals for the HUD.

signal xp_changed(current_xp: int, xp_to_next: int)
signal xp_gained(amount: int)
signal level_up(new_level: int)
signal game_over(survival_time: float, score: int)
signal game_started()

# ── state ────────────────────────────────────────────────────────────────────

var score: int = 0
var current_xp: int = 0
var level: int = 1
var survival_time: float = 0.0
var is_game_over: bool = false
var enemies_killed: int = 0

# tweakable XP curve: base × multiplier^level
const XP_BASE: float = 10.0
const XP_MULTIPLIER: float = 1.25


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


func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over.emit(survival_time, score)


func reset() -> void:
	score = 0
	current_xp = 0
	level = 1
	survival_time = 0.0
	is_game_over = false
	enemies_killed = 0
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
