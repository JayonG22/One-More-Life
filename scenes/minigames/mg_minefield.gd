extends Minigame

const CELL := 58.0
const COLS := 14
const ROWS := 7
const OX := 94.0
const OY := 50.0
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var mines := {}
var seen := {}
var flags := {}
var me := Vector2i.ZERO
var sweeps := 3
var limit := 45.0
var boom := false


func build() -> void:
	make_status()
	sweeps = 3 if difficulty < 1.3 else 2
	limit = 50.0 / difficulty
	for attempt in range(50):
		_generate()
		if _safe_path():
			break
	_reveal(me)
	var sb := button("📡 Sweep [Space]", _sweep, "Primary")
	place(sb, Vector2(94, 470), Vector2(200, 48))
	var dirs := [["⬅", Vector2i(-1, 0)], ["⬆", Vector2i(0, -1)], ["⬇", Vector2i(0, 1)], ["➡", Vector2i(1, 0)]]
	for i in range(4):
		var b := button(dirs[i][0], _move.bind(dirs[i][1]), "Row")
		place(b, Vector2(640 + i * 66, 470), Vector2(60, 48))


func _generate() -> void:
	mines.clear()
	me = Vector2i(0, randi() % ROWS)
	var n := int(22 * difficulty)
	var tries := 0
	while mines.size() < n and tries < 500:
		tries += 1
		var c := Vector2i(randi_range(1, COLS - 2), randi() % ROWS)
		if absi(c.x - me.x) <= 1 and absi(c.y - me.y) <= 1:
			continue
		mines[c] = true


func _safe_path() -> bool:
	return not safe_route().is_empty()


func safe_route() -> Array:
	var q: Array = [me]
	var prev := {me: me}
	var head := 0
	while head < q.size():
		var c: Vector2i = q[head]
		head += 1
		if c.x == COLS - 1:
			var path: Array = []
			var s := c
			while s != me:
				path.push_front(s - prev[s])
				s = prev[s]
			return path
		for d in DIRS:
			var nx: Vector2i = c + d
			if _inside(nx) and not mines.has(nx) and not prev.has(nx):
				prev[nx] = c
				q.append(nx)
	return []


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS


func count(c: Vector2i) -> int:
	var n := 0
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if (dx != 0 or dy != 0) and mines.has(c + Vector2i(dx, dy)):
				n += 1
	return n


func _reveal(c: Vector2i) -> void:
	seen[c] = true
	if count(c) == 0:
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var n := c + Vector2i(dx, dy)
				if _inside(n) and not seen.has(n) and not mines.has(n):
					_reveal(n)


func _sweep() -> void:
	if done or sweeps <= 0:
		Fx.play("error")
		return
	sweeps -= 1
	Fx.play("whoosh")
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var c := me + Vector2i(dx, dy)
			if mines.has(c):
				flags[c] = true
			elif _inside(c):
				seen[c] = true
	queue_redraw()


func _move(d: Vector2i) -> void:
	if done:
		return
	var n := me + d
	if not _inside(n) or d == Vector2i.ZERO:
		return
	if flags.has(n):
		Fx.play("error")
		flash_text("🚩 Marked mine", col("warn"), Vector2(OX + n.x * CELL + 30, OY + n.y * CELL), 20)
		return
	me = n
	Fx.play("page", 0.2)
	if mines.has(me):
		boom = true
		Fx.play("bad")
		flash_text("💥 BOOM", col("bad"), Vector2(W / 2, 230), 48)
		queue_redraw()
		finish(0.05, {"success": false, "boom": true, "cleared": me.x})
		return
	_reveal(me)
	if me.x == COLS - 1:
		Fx.play("fanfare")
		finish(0.6 + 0.4 * clampf((limit - elapsed) / limit, 0.0, 1.0), {"success": true, "sweeps": sweeps})
	queue_redraw()


func _process(delta: float) -> void:
	if done:
		return
	elapsed += delta
	status.text = "Cross to the far side 🏁   ·   %ds   ·   Sweeps left %d   ·   Numbers count nearby mines" % [int(ceil(limit - elapsed)), sweeps]
	if elapsed >= limit:
		Fx.play("siren")
		flash_text("📻 \"Fall back!\"", col("bad"), Vector2(W / 2, 230), 32)
		finish(0.2 + 0.2 * float(me.x) / float(COLS - 1), {"success": false, "timeout": true, "cleared": me.x})


func _draw() -> void:
	var fnt := ThemeManager.font_bold
	for x in range(COLS):
		for y in range(ROWS):
			var c := Vector2i(x, y)
			var r := Rect2(OX + x * CELL, OY + y * CELL, CELL - 2, CELL - 2)
			var base := col("surface2").lightened(0.12) if seen.has(c) else col("track")
			if x == COLS - 1:
				base = Color(col("good"), 0.3) if not seen.has(c) else Color(col("good"), 0.45)
			draw_rect(r, base)
			if flags.has(c):
				draw_string(fnt, r.position + Vector2(12, 42), "🚩", HORIZONTAL_ALIGNMENT_LEFT, -1, 38)
			elif seen.has(c) and c != me:
				var n := count(c)
				if n > 0:
					var nc: Color = [col("good"), col("warn"), col("bad"), col("bad")][mini(n - 1, 3)]
					draw_string(fnt, r.position + Vector2(20, 40), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, nc)
			if boom and mines.has(c):
				draw_string(fnt, r.position + Vector2(10, 42), "💣", HORIZONTAL_ALIGNMENT_LEFT, -1, 38)
	var here := count(me)
	draw_string(fnt, Vector2(OX + me.x * CELL + 9, OY + me.y * CELL + 42), "💥" if boom else "🪖", HORIZONTAL_ALIGNMENT_LEFT, -1, 42)
	if not boom:
		draw_string(fnt, Vector2(OX + me.x * CELL + 40, OY + me.y * CELL + 18), str(here), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col("warn") if here > 0 else col("good"))


func _unhandled_input(event: InputEvent) -> void:
	var map := {KEY_UP: Vector2i(0, -1), KEY_W: Vector2i(0, -1), KEY_DOWN: Vector2i(0, 1), KEY_S: Vector2i(0, 1), KEY_LEFT: Vector2i(-1, 0), KEY_A: Vector2i(-1, 0), KEY_RIGHT: Vector2i(1, 0), KEY_D: Vector2i(1, 0)}
	if key_pressed(event, [KEY_SPACE]):
		_sweep()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and map.has(event.keycode):
		_move(map[event.keycode])
		get_viewport().set_input_as_handled()
