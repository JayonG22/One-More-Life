extends Minigame

const CELL := 60.0
const COLS := 13
const ROWS := 7
const OX := 110.0
const OY := 50.0
const LOOT := [
	["💵", "Cash", 150, 900, false, true], ["💍", "Ring", 1500, 6000, false, false], ["⌚", "Watch", 900, 4000, false, false],
	["💻", "Laptop", 500, 1400, false, true], ["📺", "TV", 400, 1200, true, true], ["🖼️", "Painting", 1000, 9000, true, false],
	["🎮", "Console", 250, 500, false, true], ["🪙", "Coins", 400, 2500, false, false], ["📿", "Necklace", 1200, 5000, false, false],
]
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var walls := {}
var loot: Array = []
var sleepers: Array = []
var dog := Vector2i(-1, -1)
var me := Vector2i.ZERO
var start := Vector2i.ZERO
var bag: Array = []
var noise := 0.0
var awake := false
var police := 10
var turns := 0
var max_turns := 70
var sight := 2
var target := 3000
var heavy := 0
var caught := false


func build() -> void:
	make_status()
	var gear: Dictionary = params.get("gear", {})
	sight = 4 if gear.get("nightvision", false) else 2
	noise = 0.0 if gear.get("lockpick", false) else 18.0
	_generate()
	var total := 0
	for l in loot:
		total += int(l["value"])
	target = maxi(800, int(total * 0.55))
	var wait_b := button("🤫 Hold still [Space]", _move.bind(Vector2i.ZERO), "Row")
	place(wait_b, Vector2(110, 486), Vector2(220, 48))
	var dirs := [["⬅", Vector2i(-1, 0)], ["⬆", Vector2i(0, -1)], ["⬇", Vector2i(0, 1)], ["➡", Vector2i(1, 0)]]
	for i in range(4):
		var b := button(dirs[i][0], _move.bind(dirs[i][1]), "Row")
		place(b, Vector2(620 + i * 66, 486), Vector2(60, 48))


func _generate() -> void:
	for wx in [4, 8]:
		var rows_ok := [0, 1, 2, 4, 5, 6]
		var gaps: Array = [rows_ok[randi() % 6]]
		if randf() < 0.6:
			gaps.append(rows_ok[randi() % 6])
		for y in range(ROWS):
			if not gaps.has(y):
				walls["%d,%d" % [wx, y]] = true
	for seg in [[0, 3], [5, 7], [9, 12]]:
		var gap := randi_range(seg[0], seg[1])
		for x in range(seg[0], seg[1] + 1):
			if x != gap:
				walls["%d,%d" % [x, 3]] = true
	start = Vector2i(0, [0, 2, 4, 6][randi() % 4])
	walls.erase("%d,%d" % [start.x, start.y])
	me = start
	var cells: Array = []
	for x in range(COLS):
		for y in range(ROWS):
			var c := Vector2i(x, y)
			if not walls.has("%d,%d" % [x, y]) and c != start and absi(c.x - start.x) + absi(c.y - start.y) > 2:
				cells.append(c)
	cells.shuffle()
	var picks: Array = LOOT.duplicate()
	picks.shuffle()
	for i in range(mini(6, cells.size())):
		var l: Array = picks[i % picks.size()]
		loot.append({"c": cells.pop_back(), "icon": l[0], "name": l[1], "value": randi_range(int(l[2]), int(l[3])), "heavy": l[4], "cash": l[5]})
	var n_sleep := 1 if difficulty < 1.1 else 2
	for c in cells:
		if sleepers.size() >= n_sleep:
			break
		if c.x >= 5 and c.x != 8 and c.y != 3:
			sleepers.append(c)
	for c in cells:
		if c.x >= 5 and not sleepers.has(c) and randf() < 0.6 * difficulty:
			dog = c
			break
	if dog.x >= 0:
		cells.erase(dog)


func _open(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS and not walls.has("%d,%d" % [c.x, c.y])


func _dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _move(d: Vector2i) -> void:
	if done:
		return
	var n := me + d
	if d != Vector2i.ZERO and not _open(n):
		Fx.play("error")
		return
	if sleepers.has(n) or n == dog:
		Fx.play("error")
		return
	me = n
	turns += 1
	if d == Vector2i.ZERO:
		noise = maxf(0.0, noise - 5.0)
	else:
		noise += 2.0 * (2.0 if heavy > 0 else 1.0)
		Fx.play("page", 0.15)
	noise = maxf(0.0, noise - 1.0)
	if not awake:
		for s in sleepers:
			if _dist(s, me) <= 2 and d != Vector2i.ZERO:
				noise += 11.0
	for l in loot:
		if l["c"] == me and not l.get("taken", false):
			l["taken"] = true
			bag.append([l["icon"], l["name"], int(l["value"]), l["cash"]])
			if l["heavy"]:
				heavy += 1
			Fx.play("coin", 0.4)
			flash_text("%s +%s" % [l["icon"], GameState.fmt_money(int(l["value"]))], col("good"), Vector2(OX + me.x * CELL + 30, OY + me.y * CELL), 22)
	if me == start and turns > 1:
		_leave()
		return
	_dog_turn()
	if not awake and noise >= 100.0:
		awake = true
		Fx.play("siren")
		flash_text("💡 The lights came on!", col("bad"), Vector2(W / 2, 230), 30)
	elif not awake and turns >= max_turns:
		awake = true
		flash_text("☀️ Sunrise. They're waking up!", col("bad"), Vector2(W / 2, 230), 30)
	if awake:
		police -= 1
		for i in range(sleepers.size()):
			sleepers[i] = _chase(sleepers[i])
			if sleepers[i] == me:
				_bust(false)
				return
		if police <= 0:
			_bust(true)
			return
	queue_redraw()


func _dog_turn() -> void:
	if dog.x < 0:
		return
	var opts: Array = []
	for d in DIRS:
		var c: Vector2i = dog + d
		if _open(c) and c != me and not sleepers.has(c):
			opts.append(c)
	if not opts.is_empty() and randf() < 0.7:
		dog = opts[randi() % opts.size()]
	if _dist(dog, me) <= 1 and not awake:
		noise += 20.0
		Fx.play("bad", 0.5)
		flash_text("🐕 WOOF!", col("warn"), Vector2(OX + dog.x * CELL + 30, OY + dog.y * CELL), 24)


func _chase(from: Vector2i) -> Vector2i:
	var q: Array = [from]
	var prev := {from: from}
	var head := 0
	while head < q.size():
		var c: Vector2i = q[head]
		head += 1
		if c == me:
			break
		for d in DIRS:
			var n: Vector2i = c + d
			if _open(n) and not prev.has(n):
				prev[n] = c
				q.append(n)
	if not prev.has(me):
		return from
	var step := me
	while prev[step] != from:
		step = prev[step]
	return step


func _loot_value() -> int:
	var v := 0
	for b in bag:
		v += int(b[2])
	return v


func _leave() -> void:
	var v := _loot_value()
	Fx.play("fanfare" if v > 0 else "whoosh")
	finish(clampf(float(v) / float(target), 0.0, 1.0) * (0.85 if awake else 1.0) + (0.0 if v > 0 else 0.05), {"success": true, "loot": v, "items": bag, "woke": awake, "caught": false})


func _bust(cops: bool) -> void:
	caught = true
	Fx.play("siren")
	flash_text("🚓 Police!" if cops else "😠 Caught red-handed!", col("bad"), Vector2(W / 2, 230), 32)
	queue_redraw()
	finish(0.05, {"success": false, "loot": 0, "items": [], "woke": true, "caught": true})


func _process(_delta: float) -> void:
	if done:
		return
	if awake:
		status.text = "🚨 RUN to the window!  Police in %d moves   ·   Bag %s" % [police, GameState.fmt_money(_loot_value())]
	else:
		status.text = "Noise %d%%   ·   Bag %s / goal %s   ·   Dawn in %d" % [int(noise), GameState.fmt_money(_loot_value()), GameState.fmt_money(target), max_turns - turns]


func _visible(c: Vector2i) -> bool:
	return _dist(c, me) <= sight or awake


func _draw() -> void:
	var fnt := ThemeManager.font_regular
	for x in range(COLS):
		for y in range(ROWS):
			var c := Vector2i(x, y)
			var r := Rect2(OX + x * CELL, OY + y * CELL, CELL - 2, CELL - 2)
			if walls.has("%d,%d" % [x, y]):
				draw_rect(r, col("border"))
			else:
				draw_rect(r, col("surface2") if _visible(c) else Color(col("surface2"), 0.35))
	for s in sleepers:
		if _visible(s):
			draw_rect(Rect2(OX + (s.x - 2) * CELL, OY + s.y * CELL, CELL * 5 - 2, CELL - 2), Color(col("warn"), 0.08))
	draw_string(fnt, Vector2(OX + start.x * CELL + 12, OY + start.y * CELL + 42), "🪟", HORIZONTAL_ALIGNMENT_LEFT, -1, 42)
	for l in loot:
		if not l.get("taken", false) and _visible(l["c"]):
			var c: Vector2i = l["c"]
			draw_string(fnt, Vector2(OX + c.x * CELL + 12, OY + c.y * CELL + 42), l["icon"], HORIZONTAL_ALIGNMENT_LEFT, -1, 42)
	for s in sleepers:
		if _visible(s):
			draw_string(fnt, Vector2(OX + s.x * CELL + 10, OY + s.y * CELL + 44), "😠" if awake else "😴", HORIZONTAL_ALIGNMENT_LEFT, -1, 42)
	if dog.x >= 0 and _visible(dog):
		draw_string(fnt, Vector2(OX + dog.x * CELL + 10, OY + dog.y * CELL + 44), "🐕", HORIZONTAL_ALIGNMENT_LEFT, -1, 42)
	draw_string(fnt, Vector2(OX + me.x * CELL + 10, OY + me.y * CELL + 44), "😱" if caught else "🥷", HORIZONTAL_ALIGNMENT_LEFT, -1, 42)
	bar_rect(Rect2(OX, 30 + ROWS * CELL + 24, COLS * CELL - 2, 8), noise / 100.0, col("bad") if noise > 70 else col("warn"), col("track"))


func _unhandled_input(event: InputEvent) -> void:
	var map := {KEY_UP: Vector2i(0, -1), KEY_W: Vector2i(0, -1), KEY_DOWN: Vector2i(0, 1), KEY_S: Vector2i(0, 1), KEY_LEFT: Vector2i(-1, 0), KEY_A: Vector2i(-1, 0), KEY_RIGHT: Vector2i(1, 0), KEY_D: Vector2i(1, 0), KEY_SPACE: Vector2i.ZERO}
	if event is InputEventKey and event.pressed and not event.echo and map.has(event.keycode):
		_move(map[event.keycode])
		get_viewport().set_input_as_handled()
