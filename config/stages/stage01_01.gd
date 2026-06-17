extends RefCounted
static var mode = "kill_all"

static var spawn_stage_ratio = 0.7
static var max_spawn_stage = 60.0

static var waves = [
	{zombie = "basic",   interval = 1.2, hp_mult = 1.0, count = 1},
	{zombie = "fast",    interval = 0.8, hp_mult = 1.2, count = 1},
	{zombie = "spitter", interval = 0.5, hp_mult = 1.5, count = 1},
	{zombie = "boss", interval = 0.5, hp_mult = 1.5, count = 1}
]
