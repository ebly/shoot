extends RefCounted
static var mode = "survive"
static var duration = 120

static var spawn_stage_ratio = 0.7
static var max_spawn_stage = 60.0

static var waves = [
	{zombie = "basic",   interval = 1.0, hp_mult = 1.5, count = 12},
	{zombie = "fast",    interval = 0.8, hp_mult = 1.8, count = 15},
	{zombie = "spitter", interval = 0.6, hp_mult = 2.0, count = 18},
]

static var boss = "boss"
