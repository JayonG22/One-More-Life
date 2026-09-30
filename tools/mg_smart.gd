extends Node

## A competent bot for each minigame, to prove they can be won.

var ids: Array = []
var cur = null
var cur_id := ""
var t := 0.0
var cool := 0.0
var results := {}


func _ready() -> void:
	seed(5)
	GameState.new_life({"gender": "male", "country": "us"})
	ids = Minigames.DEFS.keys()
	ids = ids + ids + ["infiltrate", "infiltrate", "escape", "escape", "escape", "burglary", "burglary", "burglary", "minefield", "minefield"]
	Engine.time_scale = 2.0
	_next()


func _next() -> void:
	if cur != null:
		cur.queue_free()
		cur = null
	if ids.is_empty():
		for k in results.keys():
			print("%-12s %s" % [k, str(results[k])])
		print("SMART DONE")
		get_tree().quit()
		return
	cur_id = ids.pop_front()
	if OS.get_environment("MG_ONLY") != "" and cur_id != OS.get_environment("MG_ONLY"):
		call_deferred("_next")
		return
	plan = []
	plan_for = ""
	pass
	var g = load(Minigames.DEFS[cur_id]["script"]).new()
	g.setup({"skill": 60, "difficulty": 1.0, "sport": "basketball", "opponent": "Rival", "map": randi() % 3})
	g.finished.connect(func(score: float, detail: Dictionary):
		results[cur_id] = results.get(cur_id, []) + ["%.2f" % score + (str(detail) if cur_id == "potion" else "")]
		call_deferred("_next"))
	add_child(g)
	cur = g
	t = 0.0
	cool = 0.3


func _process(delta: float) -> void:
	if cur == null or cur.done:
		return
	t += delta
	cool -= delta
	if t > 150.0:
		print("TIMEOUT ", cur_id)
		results[cur_id] = results.get(cur_id, []) + ["TIMEOUT"]
		_next()
		return
	var g = cur
	match cur_id:
		"audition":
			g.move = 0.0 if absf(g.light_x - g.me_x) < 25.0 else signf(g.light_x - g.me_x)
			for c in g.cues:
				if not c["done"] and absf(float(c["t"]) - g.elapsed) < 0.04:
					g._cue(int(c["k"]))
		"blackjack":
			if g.phase == "play" and cool <= 0:
				cool = 0.3
				if g.total(g.me) < 17:
					g._hit()
				else:
					g._stand()
		"escape":
			if cool <= 0:
				cool = 0.08
				if plan_for != "esc":
					plan_for = "esc"
					plan = g.solution.duplicate()
				if not plan.is_empty():
					g._move(plan.pop_front())
		"minefield":
			if cool <= 0:
				cool = 0.1
				if plan_for != "mine":
					plan_for = "mine"
					plan = g.safe_route()
				if not plan.is_empty():
					g._move(plan.pop_front())
		"burglary":
			if cool <= 0:
				cool = 0.05
				_burgle(g)
		"rhythm":
			for n in g.notes:
				if not n["done"] and absf(float(n["t"]) - g.elapsed) < 0.03:
					g._hit(int(n["lane"]))
		"clutch":
			if g.needs_aim and g.aim < 0:
				g._set_aim(randi() % 3)
			elif not g.locked and absf(g.pos - g.zone_c) < g.zone_w * 0.2:
				g._shoot()
		"debate":
			if g.zinging and g.zing_t >= g.zing_len * 0.62:
				g._rebut()
			elif g.breath >= g.COST and cool <= 0 and g.mood_t > 0.25:
				cool = 0.3
				g._argue(g.mood)
		"safecrack":
			if cool <= 0:
				cool = 0.12
				if g._dist() == 0:
					g._lock()
				else:
					var cur_v := int(round(g.value)) % 40
					var tgt := int(g.combo[g.found])
					var fwd := posmod(tgt - cur_v, 40)
					g._step(1 if fwd <= 20 else -1)
		"pickpocket":
			g.holding = g.attention < 0.42 and not g.between
		"docking":
			var port: Rect2 = g.PORT
			var to: Vector2 = port.get_center() - g.p
			var want: Vector2 = to.normalized() * clampf(to.length() * 0.4, 8.0, 38.0)
			var diff: Vector2 = want - g.v
			g.held.clear()
			if diff.length() > 4.0:
				g.held["x"] = diff.normalized()
		"runway":
			if not g.showing and cool <= 0 and g.input_i < g.seq.size():
				cool = 0.35
				g._press(int(g.seq[g.input_i]))
		"fight":
			if g.state == "tele" and g.tele != "FEINT" and not g.blocked_ok and cool <= 0:
				cool = 0.2
				g._block(g.tele)
			elif g.state == "counter" and cool <= 0:
				cool = 0.2
				g._strike()
		"onset":
			if cool <= 0:
				cool = 0.14
				for i in range(3):
					if g.vals[i] > 50.0 + g.zone * 0.4:
						g._nudge(i, -9.0)
					elif g.vals[i] < 50.0 - g.zone * 0.4:
						g._nudge(i, 9.0)
		"fishing":
			g.holding = g.tension < 0.7
		"potion":
			match g.phase:
				1:
					if g.chosen.is_empty():
						g._pick_target("healing")
						for ing in ["clover", "moonstone", "frogeye"]:
							g._toggle_ing(ing)
						g._start_brew()
				2:
					if cool <= 0:
						cool = 0.1
						if g.stir_dir != 0:
							g._stir(g.stir_dir)
						elif g.temp < 52.0:
							g._stoke()
				3:
					var mid: float = (g.band.x + g.band.y) / 2.0
					if not g.pouring and g.fill < 0.01:
						g.pouring = true
					elif g.pouring and g.fill >= mid:
						g._release()
		"infiltrate":
			if cool <= 0:
				cool = 0.05
				_infil(g)


var plan: Array = []
var plan_for := ""


func _burgle(g) -> void:
	if g.noise > 72.0 and not g.awake:
		g._move(Vector2i.ZERO)
		return
	var goal: Vector2i = g.start
	if not g.awake and g._loot_value() < g.target:
		var best := 999
		for l in g.loot:
			if not l.get("taken", false):
				var d: int = g._dist(l["c"], g.me)
				if d < best:
					best = d
					goal = l["c"]
	var path := _bfs(g, goal)
	if path.is_empty():
		path = _bfs(g, g.start)
	if path.is_empty():
		g._move(Vector2i.ZERO)
	else:
		g._move(path[0])


func _bfs(g, goal: Vector2i) -> Array:
	var q: Array = [g.me]
	var prev := {g.me: g.me}
	var head := 0
	while head < q.size():
		var c: Vector2i = q[head]
		head += 1
		if c == goal:
			var out: Array = []
			var s := c
			while s != g.me:
				out.push_front(s - prev[s])
				s = prev[s]
			return out
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if not g._open(n) or prev.has(n) or g.sleepers.has(n) or n == g.dog:
				continue
			var near := false
			for s2 in g.sleepers:
				if g._dist(s2, n) <= 1 and n != goal:
					near = true
			if near:
				continue
			prev[n] = c
			q.append(n)
	return []


func _infil(g) -> void:
	var key := "intel" if not g.has_intel else "exit"
	if plan_for != key or plan.is_empty():
		plan_for = key
		plan = _plan(g, g.start if g.has_intel else g.intel)
		if plan.is_empty():
			print("  no plan found for ", key)
			g._move(Vector2i.ZERO)
			return
	g._move(plan.pop_front())


func _free(g, c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < g.COLS and c.y < g.ROWS and not g.walls.has("%d,%d" % [c.x, c.y])


func _gstate(g, gd: Dictionary, t: int) -> Array:
	var path: Array = gd["path"]
	var n := path.size()
	var i := (int(gd["i"]) + t) % n
	var d: Vector2i = gd["dir"]
	for back in range(n):
		var j := (i - back + n) % n
		var dd: Vector2i = path[(j + 1) % n] - path[j]
		if dd != Vector2i.ZERO:
			d = dd
			break
	return [path[i], d]


func _seen_at(g, me: Vector2i, t: int) -> bool:
	for gd in g.guards:
		var st := _gstate(g, gd, t)
		var gp: Vector2i = st[0]
		if gp == me:
			return true
		for step in range(1, 3):
			var c: Vector2i = gp + st[1] * step
			if not _free(g, c):
				break
			if c == me:
				return true
	return false


func _plan(g, goal: Vector2i) -> Array:
	var start_s := [g.me, 0, []]
	var q: Array = [start_s]
	var seen := {}
	while not q.is_empty():
		var s0: Array = q.pop_front()
		var pos: Vector2i = s0[0]
		var t: int = s0[1]
		if pos == goal and t > 0:
			return s0[2]
		if t > 90:
			continue
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i.ZERO]:
			var n: Vector2i = pos + d
			if not _free(g, n):
				continue
			if _seen_at(g, n, t) or _seen_at(g, n, t + 1):
				continue
			var k := "%d,%d,%d" % [n.x, n.y, (t + 1) % 840]
			if seen.has(k):
				continue
			seen[k] = true
			var moves: Array = s0[2].duplicate()
			moves.append(d)
			q.append([n, t + 1, moves])
	return []
