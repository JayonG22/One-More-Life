extends Minigame

const CELL := 58.0
const COLS := 11
const ROWS := 7
const OX := 181.0
const OY := 48.0
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i.ZERO]

var walls := {}
var guards: Array = []
var me := Vector2i.ZERO
var exit_c := Vector2i.ZERO
var solution: Array = []
var turns := 0
var par := 20
var caught := false
var steps := 2


func build() -> void:
	make_status()
	steps = 2
	var n_guards := 1 if difficulty < 0.85 else (3 if difficulty > 1.3 else 2)
	for attempt in range(60):
		_generate(n_guards if attempt < 40 else maxi(1, n_guards - 1))
		solution = solve()
		if solution.size() >= 6:
			break
	if solution.is_empty():
		walls.clear()
		guards = [Vector2i(COLS - 1, 0)]
		me = Vector2i(0, ROWS - 1)
		exit_c = Vector2i(COLS - 1, ROWS - 1)
		solution = solve()
	par = solution.size() * 2 + 10
	var wait_b := button("⏸ Wait [Space]", _move.bind(Vector2i.ZERO), "Row")
	place(wait_b, Vector2(181, 470), Vector2(180, 48))
	var dirs := [["⬅", Vector2i(-1, 0)], ["⬆", Vector2i(0, -1)], ["⬇", Vector2i(0, 1)], ["➡", Vector2i(1, 0)]]
	for i in range(4):
		var b := button(dirs[i][0], _move.bind(dirs[i][1]), "Row")
		place(b, Vector2(560 + i * 66, 470), Vector2(60, 48))


func _generate(n_guards: int) -> void:
	walls.clear()
	guards.clear()
	for x in range(COLS):
		for y in range(ROWS):
			if randf() < 0.2:
				walls["%d,%d" % [x, y]] = true
	me = Vector2i(randi() % 3, randi() % ROWS)
	var side := randi() % 3
	exit_c = Vector2i(COLS - 1, randi() % ROWS) if side == 0 else Vector2i(COLS - 1 - randi() % 4, 0 if side == 1 else ROWS - 1)
	walls.erase("%d,%d" % [me.x, me.y])
	walls.erase("%d,%d" % [exit_c.x, exit_c.y])
	var tries := 0
	while guards.size() < n_guards and tries < 100:
		tries += 1
		var g := Vector2i(randi_range(4, COLS - 1), randi() % ROWS)
		if walls.has("%d,%d" % [g.x, g.y]) or g == exit_c or guards.has(g) or absi(g.x - me.x) + absi(g.y - me.y) < 5:
			continue
		guards.append(g)


func open_cell(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS and not walls.has("%d,%d" % [c.x, c.y])


func guard_step(g: Vector2i, target: Vector2i) -> Vector2i:
	if g.x != target.x:
		var h := g + Vector2i(signi(target.x - g.x), 0)
		if open_cell(h):
			return h
	if g.y != target.y:
		var v := g + Vector2i(0, signi(target.y - g.y))
		if open_cell(v):
			return v
	return g


func advance(pos: Vector2i, gs: Array) -> Array:
	var cur: Array = gs.duplicate()
	for s in range(steps):
		for i in range(cur.size()):
			cur[i] = guard_step(cur[i], pos)
		var merged: Array = []
		for g in cur:
			if not merged.has(g):
				merged.append(g)
		cur = merged
		if cur.has(pos):
			return [true, cur]
	return [false, cur]


func solve() -> Array:
	var q: Array = [[me, guards.duplicate(), []]]
	var seen := {}
	var head := 0
	while head < q.size() and head < 25000:
		var s: Array = q[head]
		head += 1
		var path: Array = s[2]
		if path.size() > 40:
			continue
		for d in DIRS:
			var n: Vector2i = s[0] + d
			if not open_cell(n) or (s[1] as Array).has(n):
				continue
			var np: Array = path.duplicate()
			np.append(d)
			if n == exit_c:
				return np
			var r := advance(n, s[1])
			if r[0]:
				continue
			var gs: Array = r[1]
			var key := "%d,%d|%s" % [n.x, n.y, str(gs)]
			if seen.has(key):
				continue
			seen[key] = true
			q.append([n, gs, np])
	return []


func _move(d: Vector2i) -> void:
	if done:
		return
	var n := me + d
	if not open_cell(n):
		Fx.play("error")
		return
	if guards.has(n):
		me = n
		_caught()
		return
	me = n
	turns += 1
	Fx.play("page", 0.2)
	if me == exit_c:
		Fx.play("fanfare")
		flash_text("🏃 Over the wall!", col("good"), Vector2(W / 2, 230))
		queue_redraw()
		finish(0.6 + 0.4 * clampf(float(solution.size()) / maxf(1.0, float(turns)), 0.0, 1.0), {"success": true, "turns": turns})
		return
	var before := guards.size()
	var r := advance(me, guards)
	guards = r[1]
	if guards.size() < before:
		flash_text("💥 The guards collided!", col("warn"), Vector2(W / 2, 230), 26)
	if r[0]:
		_caught()
		return
	if turns >= par:
		Fx.play("siren")
		flash_text("🔦 Lights on! Headcount!", col("bad"), Vector2(W / 2, 230))
		finish(0.1, {"success": false, "timeout": true})
	queue_redraw()


func _caught() -> void:
	caught = true
	Fx.play("siren")
	flash_text("🚨 CAUGHT!", col("bad"), Vector2(W / 2, 230))
	queue_redraw()
	finish(0.05, {"success": false, "caught": true})


func _process(_delta: float) -> void:
	if done:
		return
	status.text = "Moves %d/%d   ·   Guards move twice: sideways first, then up or down. Lure them into walls." % [turns, par]


func _draw() -> void:
	var fnt := ThemeManager.font_regular
	for x in range(COLS):
		for y in range(ROWS):
			var r := Rect2(OX + x * CELL, OY + y * CELL, CELL - 2, CELL - 2)
			draw_rect(r, col("border") if walls.has("%d,%d" % [x, y]) else col("surface2"))
	draw_rect(Rect2(OX + exit_c.x * CELL, OY + exit_c.y * CELL, CELL - 2, CELL - 2), Color(col("good"), 0.35))
	draw_string(fnt, Vector2(OX + exit_c.x * CELL + 11, OY + exit_c.y * CELL + 42), "🕳️", HORIZONTAL_ALIGNMENT_LEFT, -1, 42)
	for g in guards:
		draw_string(fnt, Vector2(OX + g.x * CELL + 9, OY + g.y * CELL + 42), "👮", HORIZONTAL_ALIGNMENT_LEFT, -1, 42)
	draw_string(fnt, Vector2(OX + me.x * CELL + 9, OY + me.y * CELL + 42), "😱" if caught else "🧍", HORIZONTAL_ALIGNMENT_LEFT, -1, 42)


func _unhandled_input(event: InputEvent) -> void:
	var map := {KEY_UP: Vector2i(0, -1), KEY_W: Vector2i(0, -1), KEY_DOWN: Vector2i(0, 1), KEY_S: Vector2i(0, 1), KEY_LEFT: Vector2i(-1, 0), KEY_A: Vector2i(-1, 0), KEY_RIGHT: Vector2i(1, 0), KEY_D: Vector2i(1, 0), KEY_SPACE: Vector2i.ZERO}
	if event is InputEventKey and event.pressed and not event.echo and map.has(event.keycode):
		_move(map[event.keycode])
		get_viewport().set_input_as_handled()
