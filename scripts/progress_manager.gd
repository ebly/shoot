extends Node
## ProgressManager — tracks chapter/stage progress and provides map data.

signal stage_selected(chapter: int, stage: int)

# Stage counts per chapter
const STAGE_COUNTS: Dictionary = {
	1: 5,
	2: 4,
	3: 5,
	4: 4,
	5: 5,
}

var total_chapters: int = 5

var unlocked: Dictionary = {}
var completed: Dictionary = {}

var current_chapter: int = 1
var current_stage: int = 1

var _stage_cache: Dictionary = {}


func _ready() -> void:
	_reset_progress()


func _reset_progress() -> void:
	unlocked.clear()
	completed.clear()
	for ch in range(1, total_chapters + 1):
		for st in range(1, STAGE_COUNTS[ch] + 1):
			var key = _key(ch, st)
			unlocked[key] = (ch == 1 and st == 1)
			completed[key] = false


func stage_key(chapter: int, stage: int) -> String:
	return _key(chapter, stage)


func is_unlocked(chapter: int, stage: int) -> bool:
	return unlocked.get(_key(chapter, stage), false)


func is_completed(chapter: int, stage: int) -> bool:
	return completed.get(_key(chapter, stage), false)


func complete_stage(chapter: int, stage: int) -> void:
	var key = _key(chapter, stage)
	completed[key] = true

	var max_st = STAGE_COUNTS[chapter]
	if stage < max_st:
		unlocked[_key(chapter, stage + 1)] = true
	else:
		if chapter < total_chapters:
			unlocked[_key(chapter + 1, 1)] = true


func _load_stage_config(chapter: int, stage: int):
	var key = _key(chapter, stage)
	if key in _stage_cache:
		return _stage_cache[key]
	var path: String = "res://config/stages/stage%02d_%02d.gd" % [chapter, stage]
	var script = load(path)
	if script:
		_stage_cache[key] = script
	return script


## 获取关卡过关模式。
func get_stage_mode(chapter: int, stage: int) -> String:
	var script = _load_stage_config(chapter, stage)
	if script and script.get("mode") != null:
		return script.mode
	return "survive"


## 获取关卡生存时长（survive 模式用）。
func get_stage_duration(chapter: int, stage: int) -> float:
	var script = _load_stage_config(chapter, stage)
	if script and script.get("duration") != null:
		return float(script.duration)
	return 60.0


## 获取关卡每波对应的僵尸 ID 列表。
func get_stage_waves(chapter: int, stage: int) -> Array:
	var script = _load_stage_config(chapter, stage)
	if script and script.get("waves") != null:
		var val = script.waves
		if typeof(val) == TYPE_ARRAY:
			return val
	return []


## 获取关卡级配置常量（如 spawn_stage_ratio）。
func get_stage_config(chapter: int, stage: int, key: String, default):
	var script = _load_stage_config(chapter, stage)
	if script and script.get(key) != null:
		return script.get(key)
	return default


## 获取第 N 波（从1开始）的单项属性。
func get_wave_prop(chapter: int, stage: int, wave_index: int, key: String, default):
	var waves: Array = get_stage_waves(chapter, stage)
	var idx: int = wave_index - 1
	if idx >= 0 and idx < waves.size() and typeof(waves[idx]) == TYPE_DICTIONARY:
		if waves[idx].has(key):
			return waves[idx][key]
	return default


func select_stage(chapter: int, stage: int) -> void:
	if is_unlocked(chapter, stage):
		current_chapter = chapter
		current_stage = stage
		stage_selected.emit(chapter, stage)


func get_selected_stage_key() -> String:
	return _key(current_chapter, current_stage)


func _key(ch: int, st: int) -> String:
	return str(ch) + "-" + str(st)
