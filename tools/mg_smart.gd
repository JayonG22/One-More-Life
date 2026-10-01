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
	ids = ids + ids + ["infiltrate", "infiltrate", "escape", "escape", "escape", "burglary", "burglary", "burglary", "minefield", "minefield", "blackjack", "blackjack", "blackjack", "blackjack"]
	Engine.time_scale = 2.0
	_next()


func _next() -> void:
	if cur != null:
		cur.queue_free()
		cur = null
	if ids.is_empty():
		var lost: Array = []
		for k in results.keys():
			print("%-12s %s" % [k, str(results[k])])
			var best := 0.0
			for r in results[k]:
				if str(r) == "TIMEOUT":
					continue
				best = maxf(best, float(str(r).get_slice("{", 0)))
			if best < 0.6:
				lost.append(k)
		# every minigame must be winnable by a competent player: the best of the runs clears 0.6
		var missing: Array = []
		for k2 in Minigames.DEFS.keys():
			if not results.has(k2):
				missing.append(k2)
		if OS.get_environment("MG_ONLY") == "":
			print("MG GATE %s  (%d games, unwinnable: %s, no bot: %s)" % ["PASS" if lost.is_empty() and missing.is_empty() else "FAIL", results.size(), str(lost), str(missing)])
		print("SMART DONE")
		get_tree().quit(1 if (not lost.is_empty() or not missing.is_empty()) and OS.get_environment("MG_ONLY") == "" else 0)
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
		"evidence":
			if cool <= 0:
				cool = 0.3
				for i in range(3):
					if bool(g.buttons[i].get_meta("correct", false)) and not g.buttons[i].disabled:
						g._choose(i)
						break
		"surgery":
			if cool <= 0 and g.step_i < g.STEPS.size():
				cool = 0.8
				g._tool(int(g.STEPS[g.step_i][2]))
		"pr_parole":
			if cool <= 0 and not g.locked and g.round_i <= g.ROUNDS:
				cool = 0.25
				g._answer(g.TONES.find(g.cue_tone))
		"pr_shakedown":
			if cool <= 0 and not g.done:
				cool = 0.1
				for k in range(g.items.size()):
					if g.items[k]["tell"] and not g.picked.has(k):
						g._toggle(k)
						break
				if g.picked.size() >= g.NEED:
					g._seize()
		"pr_standoff":
			if cool <= 0 and not g.locked and not g.done:
				cool = 0.1
				g._move(["listen", "reason", "offer"].find(g.need))
		"pet_pounce":
			if g.state == "up" and cool <= 0:
				cool = 0.15
				g._pounce(g.cur)
		"pet_scent":
			if cool <= 0:
				cool = 0.1
				if g.readings.size() < 3:
					g._sniff()
				else:
					var best := 0
					for i in range(3):
						if g._avg(i) > g._avg(best):
							best = i
					g._go(best)
		"pet_sneak":
			g.creeping = not (g.looking or g.warn)
		"pet_agility":
			if cool <= 0:
				for o in g.obs:
					if not o["done"] and absf(float(o["x"]) - g.DOG_X) < 30.0:
						g._act(str(o["kind"]))
						cool = 0.1
						break
		"pet_herd":
			var tgt = null
			var bestd := 99999.0
			for s in g.sheep:
				if s["penned"]:
					continue
				var dd: float = (s["p"] as Vector2).distance_to(g.PEN.get_center())
				if dd < bestd:
					bestd = dd
					tgt = s
			if tgt != null:
				var pc: Vector2 = g.PEN.get_center()
				var sp: Vector2 = tgt["p"]
				var aim: Vector2 = sp - (pc - sp).normalized() * 90.0
				aim.x = clampf(aim.x, 30.0, 960.0)
				aim.y = clampf(aim.y, 110.0, 470.0)
				var dirv: Vector2 = aim - g.dog
				g.bot_move = dirv.normalized() if dirv.length() > 6.0 else Vector2.ZERO
		"haggle":
			if cool <= 0 and not g.closed:
				cool = 0.3
				# bisect the room: the cue after each counter says how much is left
				var lo := int(g.offer)
				var hi := int(g.HIGH)
				if g.steps.is_empty():
					g.ask = lo + 16
				elif "limit" in str(g.last_cue) or "nearly" in str(g.last_cue):
					g.ask = lo + 1
				elif "little left" in str(g.last_cue):
					g.ask = lo + 5
				else:
					g.ask = lo + 12
				g._make_ask()
		"road":
			var lane_free := true
			var brake := false
			for h in g.hazards:
				var ahead: float = float(h["y"]) - g.dist
				if h["cleared"] or ahead < -30.0:
					continue
				if h["kind"] == "cone" and ahead < 230.0 and int(h["lane"]) == g.lane:
					lane_free = false
				if (h["kind"] == "ped" or h["kind"] == "light") and ahead < 330.0 and ahead > -10.0 and g.clock < float(h["ped_until"]) + 0.15:
					brake = true
			g.braking = brake
			if not lane_free and cool <= 0:
				cool = 0.2
				var want: int = (g.lane + 1) % 3
				for cand in [g.lane - 1, g.lane + 1]:
					if cand >= 0 and cand < 3:
						var clear := true
						for h2 in g.hazards:
							var a2: float = float(h2["y"]) - g.dist
							if h2["kind"] == "cone" and int(h2["lane"]) == cand and a2 < 330.0 and a2 > -30.0:
								clear = false
						if clear:
							want = cand
							break
				g._move(want - g.lane)
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
