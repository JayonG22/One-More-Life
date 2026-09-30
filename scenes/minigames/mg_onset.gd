extends Minigame

const TAKE := 20.0
const GAUGES := [["💡", "Lighting", KEY_Q, KEY_A], ["🎭", "Performance", KEY_W, KEY_S], ["🎥", "Camera", KEY_E, KEY_D]]

var vals := [50.0, 50.0, 50.0]
var vel := [0.0, 0.0, 0.0]
var in_green := [0.0, 0.0, 0.0]
var all_green := 0.0
var t := 0.0
var zone := 12.0
var retarget := 0.0


func build() -> void:
	make_status()
	zone = 13.0 / difficulty
	for i in range(3):
		vals[i] = randf_range(30, 70)
		var name_l := label("%s  %s" % [GAUGES[i][0], GAUGES[i][1]], 22, true)
		place(name_l, Vector2(60 + i * 310, 60), Vector2(280, 30))
		var up := button("+  [%s]" % OS.get_keycode_string(GAUGES[i][2]), _nudge.bind(i, 9.0), "Row")
		place(up, Vector2(60 + i * 310, 400), Vector2(135, 56))
		var dn := button("−  [%s]" % OS.get_keycode_string(GAUGES[i][3]), _nudge.bind(i, -9.0), "Row")
		place(dn, Vector2(205 + i * 310, 400), Vector2(135, 56))
	var take := label("🎬 ACTION!", 18, true, col("dim"))
	place(take, Vector2(60, 475), Vector2(400, 24))


func _nudge(i: int, amt: float) -> void:
	if done:
		return
	vals[i] = clampf(vals[i] + amt, 0, 100)
	vel[i] *= 0.4
	Fx.play("tap", 0.1)


func _process(delta: float) -> void:
	if done:
		return
	t += delta
	retarget -= delta
	if retarget <= 0:
		retarget = randf_range(0.5, 1.1)
		for i in range(3):
			vel[i] = randf_range(-22, 22) * difficulty
	var green_now := 0
	for i in range(3):
		vals[i] = clampf(vals[i] + vel[i] * delta, 0, 100)
		if absf(vals[i] - 50) <= zone:
			in_green[i] += delta
			green_now += 1
	if green_now == 3:
		all_green += delta
	status.text = "Take %.0fs left   ·   All green %d%%" % [maxf(0.0, TAKE - t), int(all_green / maxf(t, 0.01) * 100)]
	queue_redraw()
	if t >= TAKE:
		var each: float = (in_green[0] + in_green[1] + in_green[2]) / (3.0 * TAKE)
		var sc: float = each * 0.45 + all_green / TAKE * 0.55
		Fx.play("good" if sc > 0.5 else "bad")
		finish(sc, {"all_green": all_green / TAKE})


func _draw() -> void:
	for i in range(3):
		var x := 60.0 + i * 310
		var r := Rect2(x + 100, 100, 80, 280)
		draw_rect(r, col("track"))
		var gy0 := r.position.y + r.size.y * (1.0 - (50 + zone) / 100.0)
		var gh := r.size.y * (zone * 2 / 100.0)
		draw_rect(Rect2(r.position.x, gy0, r.size.x, gh), Color(col("good"), 0.45))
		var y: float = r.position.y + r.size.y * (1.0 - vals[i] / 100.0)
		var ok := absf(vals[i] - 50) <= zone
		draw_rect(Rect2(r.position.x - 14, y - 5, r.size.x + 28, 10), col("good") if ok else col("bad"))
	bar_rect(Rect2(60, 505, W - 120, 10), t / TAKE, col("primary"), col("track"))


func _unhandled_input(event: InputEvent) -> void:
	for i in range(3):
		if key_pressed(event, [GAUGES[i][2]]):
			_nudge(i, 9.0)
			get_viewport().set_input_as_handled()
		elif key_pressed(event, [GAUGES[i][3]]):
			_nudge(i, -9.0)
			get_viewport().set_input_as_handled()
