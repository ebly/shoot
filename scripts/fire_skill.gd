class_name Skill
extends Node2D
## 技能基类 — 所有被动技能继承此节点，挂载到玩家身上后按 CD 自动发射。
## 配置数据从 config/skill.gd (SkillConfig) 读取。

var skill_id: String = ""
var skill_name: String = ""
var skill_desc: String = ""
var skill_icon: Color = Color.WHITE
var cfg: Dictionary = {}   # 来自 SkillConfig.LIST 的完整配置

## 从配置初始化（子类覆写此方法设置具体行为参数）
func apply_config(config: Dictionary) -> void:
	cfg = config
	skill_id = config.get("id", "")
	skill_name = config.get("name", "")
	skill_desc = config.get("desc", "")
	skill_icon = config.get("color", Color.WHITE)


# ═══════════════════════════════════════════════════════════════
#  SKILL 01 — 旋转飞弹 (spinning_orb)
#  围绕玩家旋转的火焰弹，碰触敌人造成伤害。
# ═══════════════════════════════════════════════════════════════
class SpinningOrb extends Skill:
	var orb_count: int = 2
	var orbs: Array = []
	var angle: float = 0.0
	var radius: float = 45.0
	var damage: float = 8.0
	var orb_scene = preload("res://scenes/bullet.tscn")

	func apply_config(config: Dictionary) -> void:
		super(config)
		orb_count = config.get("count", 2)
		radius = config.get("range", 45.0)
		damage = config.get("damage", 8.0)

	func _ready() -> void: _spawn_orbs()
	func level_up() -> void: orb_count += 1; _spawn_orbs()
	func _spawn_orbs() -> void:
		for o in orbs:
			if is_instance_valid(o): o.queue_free()
		orbs.clear()
		for i in range(orb_count):
			var b = orb_scene.instantiate()
			b.damage = damage; b.speed = 0; b.scale = Vector2(0.5, 0.5)
			if b.has_node("Sprite2D"): b.get_node("Sprite2D").modulate = skill_icon
			b.collision_mask = 4
			add_child(b); orbs.append(b)
	func _process(delta: float) -> void:
		angle += delta * 2.5
		var p: Vector2 = owner.global_position if owner else Vector2.ZERO
		for i in range(orbs.size()):
			if is_instance_valid(orbs[i]):
				var a: float = angle + i * TAU / orbs.size()
				orbs[i].global_position = p + Vector2(cos(a), sin(a)) * radius


# ═══════════════════════════════════════════════════════════════
#  SKILL 02 — 扩散冲击波 (shockwave)
#  每 3 秒向外扩散一圈冲击波，对触碰到的敌人造成伤害并击退。
# ═══════════════════════════════════════════════════════════════
class Shockwave extends Skill:
	var damage: float = 15.0
	var max_radius: float = 150.0
	var expand_speed: float = 300.0
	var cd: float = 3.0
	var timer: float = 0.0
	var wave_radius: float = 0.0
	var expanding: bool = false

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 15.0)
		max_radius = config.get("range", 150.0)
		cd = config.get("cd", 3.0)

	func _process(delta: float) -> void:
		if expanding:
			wave_radius += expand_speed * delta
			if wave_radius >= max_radius: expanding = false; queue_redraw()
			else: _damage_in_ring(wave_radius - 10, wave_radius); queue_redraw()
		else:
			timer -= delta
			if timer <= 0: expanding = true; wave_radius = 10.0; timer = cd
	func _damage_in_ring(inner: float, outer: float) -> void:
		var p: Vector2 = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			var d: float = e.global_position.distance_to(p)
			if d > inner and d < outer:
				if e.has_method("take_damage"): e.take_damage(damage)
				if e.has_method("apply_knockback"):
					e.apply_knockback((e.global_position - p).normalized(), 150)
	func _draw() -> void:
		if expanding:
			var a = 1.0 - wave_radius / max_radius
			draw_arc(Vector2.ZERO, wave_radius, 0, TAU, 32, Color(0.6, 0.6, 1.0, a * 0.5), 3)


# ═══════════════════════════════════════════════════════════════
#  SKILL 03 — 自动跟踪箭 (homing_arrow)
#  每 2 秒射出一枚自动跟踪最近敌人的箭矢。
# ═══════════════════════════════════════════════════════════════
class HomingArrow extends Skill:
	var damage: float = 12.0
	var cd: float = 2.0
	var timer: float = 0.0
	var bullet_scene = preload("res://scenes/bullet.tscn")

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 12.0)
		cd = config.get("cd", 2.0)

	func _process(delta: float) -> void:
		timer -= delta
		if timer <= 0: timer = cd; _fire()
	func _fire() -> void:
		var t = _nearest_enemy()
		if t == null: return
		var b = bullet_scene.instantiate()
		b.damage = damage; b.speed = 350
		b.global_position = owner.global_position if owner else Vector2.ZERO
		b.direction = (t.global_position - b.global_position).normalized()
		if b.has_node("Sprite2D"): b.get_node("Sprite2D").modulate = skill_icon
		b.collision_mask = 4; get_parent().add_child(b)
	func _nearest_enemy():
		var best = null; var best_d = INF
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			var d = p.distance_squared_to(e.global_position)
			if d < best_d: best_d = d; best = e
		return best


# ═══════════════════════════════════════════════════════════════
#  SKILL 04 — 天雷 (lightning_strike)
#  每 4 秒对周围最近的敌人降下雷电，高额单体伤害。
# ═══════════════════════════════════════════════════════════════
class LightningStrike extends Skill:
	var damage: float = 30.0
	var range: float = 250.0
	var cd: float = 4.0
	var timer: float = 0.0

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 30.0)
		range = config.get("range", 250.0)
		cd = config.get("cd", 4.0)

	func _process(delta: float) -> void:
		timer -= delta
		if timer <= 0: timer = cd; _strike()
	func _strike() -> void:
		var t = _nearest_enemy_in_range()
		if t == null: return
		t.take_damage(damage)
		if t.has_method("apply_knockback"): t.apply_knockback(Vector2.UP, 250)
	func _nearest_enemy_in_range():
		var best = null; var best_d = INF
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			var d = p.distance_squared_to(e.global_position)
			if d < best_d and d <= range * range: best_d = d; best = e
		return best


# ═══════════════════════════════════════════════════════════════
#  SKILL 05 — 冰环 (frost_ring)
#  每 5 秒释放冰环，冻结减速周围敌人，持续 2 秒。
# ═══════════════════════════════════════════════════════════════
class FrostRing extends Skill:
	var damage: float = 5.0
	var range: float = 180.0
	var cd: float = 5.0
	var timer: float = 0.0
	var slow_factor: float = 0.4

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 5.0)
		range = config.get("range", 180.0)
		cd = config.get("cd", 5.0)
		slow_factor = config.get("slow", 0.4)

	func _process(delta: float) -> void:
		timer -= delta
		if timer <= 0: timer = cd; _freeze()
	func _freeze() -> void:
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			if e.global_position.distance_to(p) <= range:
				e.take_damage(damage)
				e.speed *= (1.0 - slow_factor)
				e.modulate = skill_icon
				get_tree().create_timer(cfg.get("slow_dur", 2.0)).timeout.connect(_restore_speed.bind(e))
	func _restore_speed(e) -> void:
		if is_instance_valid(e):
			e.speed = e.speed / (1.0 - slow_factor)
			e.modulate = Color.WHITE


# ═══════════════════════════════════════════════════════════════
#  SKILL 06 — 毒雾光环 (poison_aura)
#  持续对周围敌人造成中毒伤害（每秒 1 次）。
# ═══════════════════════════════════════════════════════════════
class PoisonAura extends Skill:
	var damage_per_sec: float = 8.0
	var range: float = 90.0
	var tick: float = 0.0

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage_per_sec = config.get("damage", 8.0)
		range = config.get("range", 90.0)

	func _process(delta: float) -> void:
		tick += delta
		if tick >= 1.0: tick -= 1.0; _poison()
	func _poison() -> void:
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			if e.global_position.distance_to(p) <= range:
				e.take_damage(damage_per_sec); e.modulate = skill_icon


# ═══════════════════════════════════════════════════════════════
#  SKILL 07 — 回旋镖 (boomerang)
#  每 3 秒掷出回旋镖飞向最近敌人，飞出一定距离后返回，
#  去程和回程都能造成伤害。
# ═══════════════════════════════════════════════════════════════
class Boomerang extends Skill:
	var damage: float = 12.0
	var speed: float = 260.0
	var max_dist: float = 220.0
	var cd: float = 3.0
	var timer: float = 0.0
	var _proj: Node2D = null; var _dir: Vector2 = Vector2.RIGHT
	var _traveled: float = 0.0; var _returning: bool = false

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 12.0)
		max_dist = config.get("range", 200.0)
		cd = config.get("cd", 3.0)

	func _process(delta: float) -> void:
		if _proj != null and is_instance_valid(_proj):
			if not _returning:
				_proj.global_position += _dir * speed * delta
				_traveled += speed * delta; _proj.rotation += delta * 8
				if _traveled >= max_dist: _returning = true
			else:
				var p = owner.global_position if owner else Vector2.ZERO
				var d = (p - _proj.global_position).normalized()
				_proj.global_position += d * speed * delta; _proj.rotation += delta * 8
				if _proj.global_position.distance_to(p) < 12: _proj.queue_free(); _proj = null
			_hit_check()
		else:
			timer -= delta
			if timer <= 0: timer = cd; _throw()
	func _throw() -> void:
		var t = _nearest_enemy(); if t == null: return
		var p = owner.global_position if owner else Vector2.ZERO
		_dir = (t.global_position - p).normalized(); _traveled = 0; _returning = false
		var s = Sprite2D.new(); var r = ColorRect.new(); r.size = Vector2(14, 6); r.color = skill_icon
		s.add_child(r); s.global_position = p; _proj = s; get_parent().add_child(s)
	func _hit_check() -> void:
		if _proj == null: return
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e.global_position.distance_to(_proj.global_position) < 24:
				e.take_damage(damage)
	func _nearest_enemy():
		var best = null; var best_d = INF
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			var d = p.distance_squared_to(e.global_position)
			if d < best_d: best_d = d; best = e
		return best


# ═══════════════════════════════════════════════════════════════
#  SKILL 08 — 地刺 (ground_spike)
#  每 3 秒在周围多个随机位置冒出地刺，对站上去的敌人造成伤害。
# ═══════════════════════════════════════════════════════════════
class GroundSpike extends Skill:
	var damage: float = 14.0; var spike_range: float = 130.0
	var count: int = 2; var cd: float = 3.0; var timer: float = 0.0

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 14.0)
		spike_range = config.get("range", 130.0)
		count = config.get("count", 2); cd = config.get("cd", 3.0)

	func _process(delta: float) -> void:
		timer -= delta; if timer <= 0: timer = cd; _spawn()
	func _spawn() -> void:
		var p = owner.global_position if owner else Vector2.ZERO
		for i in range(count):
			var a = randf_range(0, TAU); var d = randf_range(30, spike_range)
			var pos = p + Vector2(cos(a), sin(a)) * d
			for e in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and e.global_position.distance_to(pos) < 28:
					e.take_damage(damage)


# ═══════════════════════════════════════════════════════════════
#  SKILL 09 — 火焰光环 (flame_aura)
#  持续灼烧光环范围内的所有敌人（每秒 2 次判定）。
# ═══════════════════════════════════════════════════════════════
class FlameAura extends Skill:
	var damage_per_tick: float = 6.0; var range: float = 70.0
	var tick: float = 0.0; var interval: float = 0.5

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage_per_tick = config.get("damage", 6.0)
		range = config.get("range", 70.0)
		interval = config.get("cd", 0.5)

	func _process(delta: float) -> void:
		tick += delta; if tick >= interval: tick -= interval; _burn()
	func _burn() -> void:
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e.global_position.distance_to(p) <= range:
				e.take_damage(damage_per_tick); e.modulate = skill_icon


# ═══════════════════════════════════════════════════════════════
#  SKILL 10 — 闪电链 (chain_lightning)
#  每 3 秒释放一道闪电击中最近敌人，然后弹射到附近其他敌人。
# ═══════════════════════════════════════════════════════════════
class ChainLightning extends Skill:
	var damage: float = 18.0; var chain_count: int = 3
	var chain_range: float = 110.0; var cd: float = 3.0; var timer: float = 0.0

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 18.0)
		chain_count = config.get("count", 3)
		chain_range = config.get("range", 110.0); cd = config.get("cd", 3.0)

	func _process(delta: float) -> void:
		timer -= delta; if timer <= 0: timer = cd; _cast()
	func _cast() -> void:
		var first = _nearest_enemy(); if first == null: return
		var hit = [first]; first.take_damage(damage)
		for i in range(chain_count - 1):
			var nxt = _chain_target(hit); if nxt == null: break
			nxt.take_damage(damage * 0.6); hit.append(nxt)
	func _nearest_enemy():
		var best = null; var best_d = INF
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			var d = p.distance_squared_to(e.global_position)
			if d < best_d: best_d = d; best = e
		return best
	func _chain_target(hit: Array):
		var last = hit[-1]; if not is_instance_valid(last): return null
		var best = null; var best_d = INF
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and not e in hit:
				var d = last.global_position.distance_squared_to(e.global_position)
				if d < best_d and d <= chain_range * chain_range: best_d = d; best = e
		return best


# ═══════════════════════════════════════════════════════════════
#  SKILL 11 — 黑洞 (black_hole)
#  每 6 秒在敌人方向创造一个小黑洞，持续吸引周围敌人并造成伤害。
# ═══════════════════════════════════════════════════════════════
class BlackHole extends Skill:
	var damage_per_tick: float = 4.0; var pull_range: float = 120.0
	var duration: float = 2.5; var cd: float = 6.0; var timer: float = 0.0
	var _hole: Node2D = null; var _life: float = 0.0

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage_per_tick = config.get("damage", 4.0)
		pull_range = config.get("range", 120.0); cd = config.get("cd", 6.0)

	func _process(delta: float) -> void:
		if _hole != null and is_instance_valid(_hole):
			_life -= delta
			if _life <= 0: _hole.queue_free(); _hole = null; return
			_pull_and_damage()
		else:
			timer -= delta; if timer <= 0: timer = cd; _create_hole()
	func _create_hole() -> void:
		var p = owner.global_position if owner else Vector2.ZERO
		var forward = Vector2.RIGHT; var t = _nearest_enemy()
		if t != null: forward = (t.global_position - p).normalized()
		var pos = p + forward * 60
		var s = Sprite2D.new(); var r = ColorRect.new(); r.size = Vector2(30, 30); r.color = skill_icon
		s.add_child(r); s.global_position = pos; _hole = s; _life = duration; get_parent().add_child(s)
	func _pull_and_damage() -> void:
		if _hole == null: return
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			var d = e.global_position.distance_to(_hole.global_position)
			if d <= pull_range:
				e.take_damage(damage_per_tick)
				e.global_position += (_hole.global_position - e.global_position).normalized() * 100 * get_process_delta_time()
	func _nearest_enemy():
		var best = null; var best_d = INF
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			var d = p.distance_squared_to(e.global_position)
			if d < best_d: best_d = d; best = e
		return best


# ═══════════════════════════════════════════════════════════════
#  SKILL 12 — 圣光弹 (holy_bolt)
#  每 3 秒召唤一道从天而降的光柱，对大范围内敌人造成伤害。
# ═══════════════════════════════════════════════════════════════
class HolyBolt extends Skill:
	var damage: float = 20.0; var blast_range: float = 60.0
	var cd: float = 3.0; var timer: float = 0.0

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 20.0)
		blast_range = config.get("range", 60.0); cd = config.get("cd", 3.0)

	func _process(delta: float) -> void:
		timer -= delta; if timer <= 0: timer = cd; _strike()
	func _strike() -> void:
		var t = _nearest_enemy(); if t == null: return
		var pos = t.global_position
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e.global_position.distance_to(pos) <= blast_range:
				e.take_damage(damage)
	func _nearest_enemy():
		var best = null; var best_d = INF
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			var d = p.distance_squared_to(e.global_position)
			if d < best_d: best_d = d; best = e
		return best


# ═══════════════════════════════════════════════════════════════
#  SKILL 13 — 刀刃风暴 (blade_storm)
#  刀片围绕玩家旋转，周期性向外甩出飞刀。
# ═══════════════════════════════════════════════════════════════
class BladeStorm extends Skill:
	var blade_count: int = 3; var damage: float = 10.0; var throw_cd: float = 1.5
	var throw_timer: float = 0.0; var blades: Array = []
	var angle: float = 0.0; var radius: float = 35.0; var spin_speed: float = 3.0

	func apply_config(config: Dictionary) -> void:
		super(config)
		blade_count = config.get("count", 3); damage = config.get("damage", 10.0)
		throw_cd = config.get("cd", 1.5)

	func _process(delta: float) -> void:
		angle += delta * spin_speed
		var p = owner.global_position if owner else Vector2.ZERO
		for i in range(blades.size()):
			if is_instance_valid(blades[i]):
				var a = angle + i * TAU / max(blades.size(), 1)
				blades[i].global_position = p + Vector2(cos(a), sin(a)) * radius
		throw_timer -= delta
		if throw_timer <= 0: throw_timer = throw_cd; _throw_blade()
	func _throw_blade() -> void:
		var t = _nearest_enemy(); if t == null: return
		var p = owner.global_position if owner else Vector2.ZERO
		var dir = (t.global_position - p).normalized()
		var b = preload("res://scenes/bullet.tscn").instantiate()
		b.damage = damage; b.speed = 300; b.direction = dir
		b.global_position = p; b.scale = Vector2(0.6, 0.6)
		if b.has_node("Sprite2D"): b.get_node("Sprite2D").modulate = skill_icon
		b.collision_mask = 4; get_parent().add_child(b)
	func level_up() -> void: blade_count += 1
	func _nearest_enemy():
		var best = null; var best_d = INF
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			var d = p.distance_squared_to(e.global_position)
			if d < best_d: best_d = d; best = e
		return best


# ═══════════════════════════════════════════════════════════════
#  SKILL 14 — 追踪地雷 (mine_field)
#  每 4 秒布设一颗地雷，敌人踩到后爆炸造成范围伤害。
# ═══════════════════════════════════════════════════════════════
class MineField extends Skill:
	var damage: float = 25.0; var blast_range: float = 50.0
	var cd: float = 4.0; var timer: float = 0.0; var mines: Array = []

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 25.0)
		blast_range = config.get("range", 50.0); cd = config.get("cd", 4.0)

	func _process(delta: float) -> void:
		for m in mines:
			if not is_instance_valid(m): continue
			for e in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and e.global_position.distance_to(m.global_position) < 15:
					for e2 in get_tree().get_nodes_in_group("enemies"):
						if is_instance_valid(e2) and e2.global_position.distance_to(m.global_position) <= blast_range:
							e2.take_damage(damage)
					m.queue_free(); break
		mines = mines.filter(func(x): return is_instance_valid(x))
		timer -= delta; if timer <= 0: timer = cd; _place_mine()
	func _place_mine() -> void:
		var p = owner.global_position if owner else Vector2.ZERO
		var a = randf_range(0, TAU); var d = randf_range(30, 80)
		var pos = p + Vector2(cos(a), sin(a)) * d
		var s = Sprite2D.new(); var r = ColorRect.new(); r.size = Vector2(10, 10); r.color = skill_icon
		s.add_child(r); s.global_position = pos; mines.append(s); get_parent().add_child(s)


# ═══════════════════════════════════════════════════════════════
#  SKILL 15 — 生命汲取 (life_drain)
#  每 3 秒吸取周围所有敌人的生命，每命中一个恢复玩家生命。
# ═══════════════════════════════════════════════════════════════
class LifeDrain extends Skill:
	var damage: float = 10.0; var range: float = 100.0
	var heal_per_hit: float = 5.0; var cd: float = 3.0; var timer: float = 0.0

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 10.0); range = config.get("range", 100.0)
		cd = config.get("cd", 3.0); heal_per_hit = config.get("heal", 5.0)

	func _process(delta: float) -> void:
		timer -= delta; if timer <= 0: timer = cd; _drain()
	func _drain() -> void:
		var p = owner.global_position if owner else Vector2.ZERO; var healed: float = 0
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e.global_position.distance_to(p) <= range:
				e.take_damage(damage); healed += heal_per_hit
		if healed > 0 and owner != null and is_instance_valid(owner):
			if "stats" in owner and owner.stats != null:
				owner.stats.hp = min(owner.stats.hp + healed, owner.stats.max_hp)


# ═══════════════════════════════════════════════════════════════
#  SKILL 16 — 能量护盾 (energy_shield)
#  每 8 秒生成一次护盾，持续 3 秒，期间受伤减免 50%。
# ═══════════════════════════════════════════════════════════════
class EnergyShield extends Skill:
	var cd: float = 8.0; var duration: float = 3.0; var timer: float = 0.0
	var shield_active: bool = false; var _shield_node: Node2D = null

	func apply_config(config: Dictionary) -> void:
		super(config)
		cd = config.get("cd", 8.0)
		duration = config.get("shield_dur", 3.0)

	func _process(delta: float) -> void:
		if shield_active:
			if _shield_node != null and is_instance_valid(_shield_node):
				_shield_node.global_position = owner.global_position if owner else Vector2.ZERO
		else:
			timer -= delta; if timer <= 0: timer = cd; _activate_shield()
	func _activate_shield() -> void:
		shield_active = true
		var s = Sprite2D.new(); var r = ColorRect.new(); r.size = Vector2(26, 26); r.color = skill_icon; r.color.a = 0.4
		s.add_child(r); s.global_position = owner.global_position if owner else Vector2.ZERO
		_shield_node = s; get_parent().add_child(s)
		get_tree().create_timer(duration).timeout.connect(_deactivate_shield)
	func _deactivate_shield() -> void:
		shield_active = false
		if _shield_node != null and is_instance_valid(_shield_node): _shield_node.queue_free(); _shield_node = null


# ═══════════════════════════════════════════════════════════════
#  SKILL 17 — 时空裂隙 (time_rift)
#  每 8 秒释放一个时空裂隙，持续 3 秒，大幅减速范围内所有敌人。
# ═══════════════════════════════════════════════════════════════
class TimeRift extends Skill:
	var slow_factor: float = 0.7; var range: float = 150.0
	var cd: float = 8.0; var duration: float = 3.0; var timer: float = 0.0
	var active: bool = false; var _rift_node: Node2D = null

	func apply_config(config: Dictionary) -> void:
		super(config)
		slow_factor = config.get("slow", 0.7); range = config.get("range", 150.0)
		cd = config.get("cd", 8.0); duration = config.get("rift_dur", 3.0)

	func _process(delta: float) -> void:
		if active:
			if _rift_node != null and is_instance_valid(_rift_node):
				_rift_node.global_position = owner.global_position if owner else Vector2.ZERO
				_apply_slow()
		else:
			timer -= delta; if timer <= 0: timer = cd; _open_rift()
	func _open_rift() -> void:
		active = true
		var s = Sprite2D.new(); var r = ColorRect.new(); r.size = Vector2(40, 40); r.color = skill_icon; r.color.a = 0.25
		s.add_child(r); _rift_node = s; get_parent().add_child(s)
		get_tree().create_timer(duration).timeout.connect(_close_rift)
	func _close_rift() -> void:
		active = false
		if _rift_node != null and is_instance_valid(_rift_node):
			_rift_node.queue_free()
			_rift_node = null
	func _apply_slow() -> void:
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e.global_position.distance_to(p) <= range:
				e.speed *= (1.0 - slow_factor * get_process_delta_time() * 3)


# ═══════════════════════════════════════════════════════════════
#  SKILL 18 — 陨石 (meteor)
#  每 5 秒召唤陨石砸向敌人最密集区域，大范围高额伤害。
# ═══════════════════════════════════════════════════════════════
class Meteor extends Skill:
	var damage: float = 35.0; var blast_range: float = 80.0
	var cd: float = 5.0; var timer: float = 0.0

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 35.0)
		blast_range = config.get("range", 80.0); cd = config.get("cd", 5.0)

	func _process(delta: float) -> void:
		timer -= delta; if timer <= 0: timer = cd; _fall()
	func _fall() -> void:
		var pos = _dense_area()
		if pos == Vector2.ZERO: pos = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e.global_position.distance_to(pos) <= blast_range:
				e.take_damage(damage)
	func _dense_area() -> Vector2:
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.is_empty(): return Vector2.ZERO
		var avg = Vector2.ZERO; var cnt = 0
		for e in enemies:
			if is_instance_valid(e): avg += e.global_position; cnt += 1
		return avg / cnt if cnt > 0 else Vector2.ZERO


# ═══════════════════════════════════════════════════════════════
#  SKILL 19 — 激光射线 (laser_beam)
#  每 4 秒发射一束持续激光，扫过前方扇形区域，对命中敌人造成伤害。
# ═══════════════════════════════════════════════════════════════
class LaserBeam extends Skill:
	var damage: float = 8.0; var beam_length: float = 200.0
	var duration: float = 0.8; var cd: float = 4.0; var timer: float = 0.0
	var firing: bool = false; var fire_timer: float = 0.0

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 8.0); beam_length = config.get("range", 200.0)
		cd = config.get("cd", 4.0); duration = config.get("beam_dur", 0.8)

	func _process(delta: float) -> void:
		if firing:
			fire_timer -= delta; _scan()
			if fire_timer <= 0: firing = false; queue_redraw()
		else:
			timer -= delta; if timer <= 0: timer = cd; _start_fire()
	func _start_fire() -> void: firing = true; fire_timer = duration
	func _scan() -> void:
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			var d = e.global_position.distance_to(p)
			if d <= beam_length:
				if (e.global_position - p).normalized().dot(Vector2.RIGHT) > 0.6:
					e.take_damage(damage)


# ═══════════════════════════════════════════════════════════════
#  SKILL 20 — 分身射击 (after_image)
#  每 5 秒在玩家两侧各生成一个短暂的分身，自动射击附近敌人。
# ═══════════════════════════════════════════════════════════════
class AfterImage extends Skill:
	var damage: float = 8.0; var cd: float = 5.0; var duration: float = 2.0; var timer: float = 0.0

	func apply_config(config: Dictionary) -> void:
		super(config)
		damage = config.get("damage", 8.0); cd = config.get("cd", 5.0)
		duration = config.get("clone_dur", 2.0)

	func _process(delta: float) -> void:
		timer -= delta
		if timer <= 0: timer = cd; _summon()
	func _summon() -> void:
		var p = owner.global_position if owner else Vector2.ZERO
		for side in [-1, 1]:
			var s = Sprite2D.new(); var r = ColorRect.new(); r.size = Vector2(14, 14)
			r.color = skill_icon; r.color.a = 0.5
			s.add_child(r); s.global_position = p + Vector2(side * 20, 0)
			get_parent().add_child(s); _fire_loop(s)
			await get_tree().create_timer(duration).timeout; s.queue_free()
	func _fire_loop(s: Node2D) -> void:
		var remain: float = duration
		while remain > 0:
			var t = _nearest_enemy()
			if t != null:
				var b = preload("res://scenes/bullet.tscn").instantiate()
				b.damage = damage; b.speed = 300; b.global_position = s.global_position
				b.direction = (t.global_position - s.global_position).normalized()
				b.collision_mask = 4; get_parent().add_child(b)
			await get_tree().create_timer(0.8).timeout; remain -= 0.8
	func _nearest_enemy():
		var best = null; var best_d = INF
		var p = owner.global_position if owner else Vector2.ZERO
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			var d = p.distance_squared_to(e.global_position)
			if d < best_d: best_d = d; best = e
		return best
