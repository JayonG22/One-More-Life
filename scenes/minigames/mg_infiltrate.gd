extends Minigame

const CELL := 60.0
const COLS := 13
const ROWS := 7
const OX := 110.0
const OY := 50.0

const MAPS := [
	{"walls": ["2,1", "2,2", "2,3", "5,3", "5,4", "5,5", "8,1", "8,2", "8,3", "10,4", "10,5", "11,4"],
	 "guards": [[[4, 1], [4, 2], [4, 3], [4, 4], [4, 5], [4, 4], [4, 3], [4, 2]], [[7, 5], [8, 5], [9, 5], [9, 4], [9, 5], [8, 5]], [[11, 2], [11, 1], [12, 1], [12, 2]]],
	 "intel": [12, 0], "start": [0, 6]},
	{"walls": ["1,1", "1,2", "3,4", "3,5", "3,6", "6,0", "6,1", "6,2", "6,4", "9,2", "9,3", "9,4", "9,5", "11,1"],
	 "guards": [[[2, 3], [3, 3], [4, 3], [5, 3], [4, 3], [3, 3]], [[7, 1], [8, 1], [8, 2], [8, 3], [7, 3], [7, 2]], [[10, 6], [11, 6], [12, 6], [12, 5], [11, 5], [10, 5]]],
	 "intel": [12, 3], "start": [0, 0]},
	{"walls": ["2,2", "3,2", "4,2", "6,4", "7,4", "8,4", "10,1", "10,2", "10,3", "4,5", "4,6", "8,0"],
	 "guards": [[[1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [4, 4], [3, 4], [2, 4]], [[6, 1], [7, 1], [7, 2], [7, 3], [6, 3], [6, 2]], [[11, 5], [11, 4], [12, 4], [12, 5]], [[9, 6], [9, 5], [10, 5], [10, 6]]],
	 "intel": [12, 1], "start": [0, 6]},
]

var walls := {}
var guards: Array = []
var me := Vector2i.ZERO
var start := Vector2i.ZERO
var intel := Vector2i.ZERO
var has_intel := false
var turns := 0
var par := 30
var caught := false
var ic := {"me": "🕵️", "guard": "💂", "goal": "📁", "exit": "🚪", "got": "📁 Intel secured! Get out!", "find": "Find the intel 📁"}


func build() -> void:
	make_status()
	if params.get("flavor", "") == "hunt":
		ic = {"me": "🧛", "guard": "🔦", "goal": "🩸", "exit": "🦇", "got": "🩸 You fed. Now vanish!", "find": "Reach your victim 🩸"}
	var m: Dictionary = MAPS[int(params.get("map", randi() % MAPS.size())) % MAPS.size()]
	for w in m["walls"]:
		walls[w] = true
	for path in m["guards"]:
		var pts: Array = []
		for pt in path:
			pts.append(Vector2i(pt[0], pt[1]))
		guards.append({"path": pts, "i": randi() % pts.size(), "dir": Vector2i(1, 0)})
	if difficulty < 0.9 and guards.size() > 2:
		guards.pop_back()
	for g in guards:
		_update_dir(g)
	start = Vector2i(m["start"][0], m["start"][1])
	me = start
	intel = Vector2i(m["intel"][0], m["intel"][1])
	par = int(absi(intel.x - start.x) + absi(intel.y - start.y)) * 2 + 8
	var wait_b := button("⏸ Wait [Space]", _move.bind(Vector2i.ZERO), "Row")
	place(wait_b, Vector2(110, 475), Vector2(180, 48))
	var dirs := [["⬅", Vector2i(-1, 0)], ["⬆", Vector2i(0, -1)], ["⬇", Vector2i(0, 1)], ["➡", Vector2i(1, 0)]]
	for i in range(4):
		var b := button(dirs[i][0], _move.bind(dirs[i][1]), "Row")
		place(b, Vector2(620 + i * 66, 475), Vector2(60, 48))


func _pos(g: Dictionary) -> Vector2i:
	return g["path"][g["i"]]


func _update_dir(g: Dictionary) -> void:
	var nxt: Vector2i = g["path"][(int(g["i"]) + 1) % g["path"].size()]
	var d: Vector2i = nxt - _pos(g)
	if d != Vector2i.ZERO:
		g["dir"] = d


func _vision(g: Dictionary) -> Array:
	var out: Array = []
	var p := _pos(g)
	for step in range(1, 3):
		var c: Vector2i = p + g["dir"] * step
		if c.x < 0 or c.y < 0 or c.x >= COLS or c.y >= ROWS or walls.has("%d,%d" % [c.x, c.y]):
			break
		out.append(c)
	return out


func _seen() -> bool:
	for g in guards:
		if _pos(g) == me or _vision(g).has(me):
			return true
	return false


func _move(d: Vector2i) -> void:
	if done:
		return
	var n := me + d
	if n.x < 0 or n.y < 0 or n.x >= COLS or n.y >= ROWS or walls.has("%d,%d" % [n.x, n.y]):
		Fx.play("error")
		return
	me = n
	turns += 1
	Fx.play("page", 0.2)
	if _seen():
		_caught()
		return
	for g in guards:
		g["i"] = (int(g["i"]) + 1) % g["path"].size()
		_update_dir(g)
	if _seen():
		_caught()
		return
	if me == intel and not has_intel:
		has_intel = true
		Fx.play("coin")
		flash_text(ic["got"], col("good"), Vector2(W / 2, 230))
	if has_intel and me == start:
		Fx.play("fanfare")
		finish(0.6 + 0.4 * clampf(float(par) / maxf(1.0, float(turns)), 0.0, 1.0), {"success": true, "turns": turns})
	elif turns >= par * 3:
		Fx.play("siren")
		flash_text("⏰ Shift change! Abort!", col("bad"), Vector2(W / 2, 230))
		finish(0.3 if has_intel else 0.15, {"success": false, "timeout": true, "intel": has_intel})
	queue_redraw()


func _caught() -> void:
	caught = true
	Fx.play("siren")
	flash_text("🚨 SPOTTED!", col("bad"), Vector2(W / 2, 230))
	queue_redraw()
	finish(0.35 if has_intel else 0.1, {"success": false, "caught": true, "intel": has_intel})


func _process(_delta: float) -> void:
	if done:
		return
	status.text = "Turns %d/%d   ·   %s" % [turns, par * 3, ("Head back to the exit " + ic["exit"]) if has_intel else ic["find"]]


func _draw() -> void:
	for x in range(COLS):
		for y in range(ROWS):
			var r := Rect2(OX + x * CELL, OY + y * CELL, CELL - 2, CELL - 2)
			draw_rect(r, col("border") if walls.has("%d,%d" % [x, y]) else col("surface2"))
	for g in guards:
		for c in _vision(g):
			draw_rect(Rect2(OX + c.x * CELL, OY + c.y * CELL, CELL - 2, CELL - 2), Color(col("bad"), 0.35))
	var fnt := ThemeManager.font_regular
	draw_string(fnt, Vector2(OX + start.x * CELL + 12, OY + start.y * CELL + 42), ic["exit"], HORIZONTAL_ALIGNMENT_LEFT, -1, 32)
	if not has_intel:
		draw_string(fnt, Vector2(OX + intel.x * CELL + 12, OY + intel.y * CELL + 42), ic["goal"], HORIZONTAL_ALIGNMENT_LEFT, -1, 32)
	for g in guards:
		var p := _pos(g)
		draw_string(fnt, Vector2(OX + p.x * CELL + 10, OY + p.y * CELL + 44), ic["guard"], HORIZONTAL_ALIGNMENT_LEFT, -1, 34)
	draw_string(fnt, Vector2(OX + me.x * CELL + 10, OY + me.y * CELL + 44), ic["me"] if not caught else "😱", HORIZONTAL_ALIGNMENT_LEFT, -1, 34)


func _unhandled_input(event: InputEvent) -> void:
	var map := {KEY_UP: Vector2i(0, -1), KEY_W: Vector2i(0, -1), KEY_DOWN: Vector2i(0, 1), KEY_S: Vector2i(0, 1), KEY_LEFT: Vector2i(-1, 0), KEY_A: Vector2i(-1, 0), KEY_RIGHT: Vector2i(1, 0), KEY_D: Vector2i(1, 0), KEY_SPACE: Vector2i.ZERO}
	if event is InputEventKey and event.pressed and not event.echo and map.has(event.keycode):
		_move(map[event.keycode])
		get_viewport().set_input_as_handled()
