extends Node
## ProgressManager — tracks chapter/stage progress and provides map data.

signal stage_selected(chapter: int, stage: int)

# Stage counts per chapter
const STAGE_COUNTS: Dictionary = {
	1: 5,  # 5 stages in chapter 1
	2: 4,  # 4 stages in chapter 2
	3: 5,  # 5 stages in chapter 3
	4: 4,  # 4 stages in chapter 4
	5: 5,  # 5 stages in chapter 5
}

var total_chapters: int = 5

# Which stage IDs are unlocked / completed
var unlocked: Dictionary = {}   # "ch-st" → bool
var completed: Dictionary = {}  # "ch-st" → bool

var current_chapter: int = 1
var current_stage: int = 1


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

	# Unlock next stage in same chapter
	var max_st = STAGE_COUNTS[chapter]
	if stage < max_st:
		unlocked[_key(chapter, stage + 1)] = true
	else:
		# Last stage of chapter → unlock first stage of next chapter
		if chapter < total_chapters:
			unlocked[_key(chapter + 1, 1)] = true


func select_stage(chapter: int, stage: int) -> void:
	if is_unlocked(chapter, stage):
		current_chapter = chapter
		current_stage = stage
		stage_selected.emit(chapter, stage)


func get_selected_stage_key() -> String:
	return _key(current_chapter, current_stage)


func _key(ch: int, st: int) -> String:
	return str(ch) + "-" + str(st)
