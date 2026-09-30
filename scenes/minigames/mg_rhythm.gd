extends Minigame

const LANES := 4
const KEYS := [KEY_D, KEY_F, KEY_J, KEY_K]
const LANE_W := 150.0
const LEFT := 200.0
const HIT_Y := 440.0
const NOTE_ICONS := ["🎵", "🎶", "🎵", "🎶"]

var notes: Array = []
var speed := 360.0
var total := 0
var perfect := 0
var good := 0
var miss := 0
var combo := 0
var best_combo := 0
var song_len := 18.0
var lane_flash := [0.0, 0.0, 0.0, 0.0]


func build() -> void:
	make_status()
	speed = 330.0 * difficulty
	var t := 1.2
	var beat := 0.52 / difficulty
	while t < song_len:
		var lane := randi() % LANES
		_add_note(t, lane)
		if randf() < 0.15:
			_add_note(t, (lane + 2) % LANES)
		t += beat * [1.0, 1.0, 0.5, 1.5, 1.0][randi() % 5]
	total = notes.size()
	for i in range(LANES):
		var b := button(["D", "F", "J", "K"][i], _hit.bind(i), "Row")
		place(b, Vector2(LEFT + i * LANE_W + 10, 480), Vector2(LANE_W - 20, 48))


func _add_note(t: float, lane: int) -> void:
	var l := label(NOTE_ICONS[lane], 38)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(l, Vector2(LEFT + lane * LANE_W, -60), Vector2(LANE_W, 50))
	notes.append({"t": t, "lane": lane, "node": l, "done": false})


func _process(delta: float) -> void:
	if done:
		return
	elapsed += delta
	for i in range(LANES):
		lane_flash[i] = maxf(0.0, lane_flash[i] - delta * 4.0)
	var remaining := 0
	for n in notes:
		if n["done"]:
			continue
		remaining += 1
		var y: float = HIT_Y - (float(n["t"]) - elapsed) * speed
		n["node"].position.y = y - 25
		if elapsed - float(n["t"]) > 0.16:
			n["done"] = true
			n["node"].modulate = Color(1, 0.3, 0.3, 0.4)
			miss += 1
			combo = 0
	status.text = "Combo %d   ·   Perfect %d   Good %d   Miss %d" % [combo, perfect, good, miss]
	queue_redraw()
	if remaining == 0 and elapsed > song_len + 0.5:
		var sc := (perfect + good * 0.6) / maxf(1.0, float(total))
		finish(sc, {"perfect": perfect, "good": good, "miss": miss, "best_combo": best_combo})


func _hit(lane: int) -> void:
	if done:
		return
	lane_flash[lane] = 1.0
	var best: Dictionary = {}
	var best_dt := 99.0
	for n in notes:
		if n["done"] or int(n["lane"]) != lane:
			continue
		var dt: float = absf(float(n["t"]) - elapsed)
		if dt < best_dt:
			best_dt = dt
			best = n
	if best.is_empty() or best_dt > 0.16:
		combo = 0
		return
	best["done"] = true
	best["node"].visible = false
	combo += 1
	best_combo = maxi(best_combo, combo)
	if best_dt < 0.07:
		perfect += 1
		Fx.play("tap", 0.0)
		flash_text("Perfect", col("gold"), Vector2(LEFT + lane * LANE_W + LANE_W / 2, HIT_Y - 70), 22)
	else:
		good += 1
		Fx.play("tap", 0.08)
		flash_text("Good", col("good"), Vector2(LEFT + lane * LANE_W + LANE_W / 2, HIT_Y - 70), 20)


func _draw() -> void:
	for i in range(LANES):
		var x := LEFT + i * LANE_W
		draw_rect(Rect2(x + 4, 40, LANE_W - 8, 440), Color(col("surface2"), 0.9))
		if lane_flash[i] > 0:
			draw_rect(Rect2(x + 4, 40, LANE_W - 8, 440), Color(col("accent"), 0.25 * lane_flash[i]))
	draw_rect(Rect2(LEFT, HIT_Y - 3, LANE_W * LANES, 6), col("accent"))
	bar_rect(Rect2(LEFT, 30, LANE_W * LANES, 6), elapsed / song_len, col("primary"), col("track"))


func _unhandled_input(event: InputEvent) -> void:
	for i in range(LANES):
		if key_pressed(event, [KEYS[i]]):
			_hit(i)
			get_viewport().set_input_as_handled()
