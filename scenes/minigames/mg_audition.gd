extends Minigame

const EMO := [["😢", Color("4a90e2")], ["😡", Color("e2493b")], ["😂", Color("f2c14e")], ["😱", Color("9b59d0")]]
const LENGTH := 36.0
const HIT_X := 150.0
const TRACK_Y := 150.0
const STAGE_Y := 360.0

var cues: Array = []
var travel := 2.3
var me_x := 500.0
var light_x := 500.0
var light_to := 500.0
var light_w := 170.0
var light_timer := 0.0
var move := 0.0
var interest := 80.0
var presence := 0.0
var hits := 0.0
var total := 0
var combo := 0
var best := 0


func build() -> void:
	make_status()
	travel = 2.4 / difficulty
	var t := 1.6
	while t < LENGTH - 0.5:
		var k := randi() % 4
		cues.append({"t": t, "k": k, "done": false})
		total += 1
		var gap := lerpf(1.25, 0.55, t / LENGTH) / difficulty
		if randf() < 0.2 and t > 8.0:
			gap *= 0.5
		t += gap
	light_w = 190.0 / difficulty
	for i in range(4):
		var b := button("%s  [%d]" % [EMO[i][0], i + 1], _cue.bind(i), "Row")
		b.add_theme_font_size_override("font_size", 26)
		place(b, Vector2(80 + i * 215, 460), Vector2(200, 64))
	var lb := button("◀", func(): me_x -= 60.0, "Row")
	place(lb, Vector2(10, 360), Vector2(56, 56))
	var rb := button("▶", func(): me_x += 60.0, "Row")
	place(rb, Vector2(934, 360), Vector2(56, 56))


func _cue(k: int) -> void:
	if done:
		return
	var best_i := -1
	var best_d := 99.0
	for i in range(cues.size()):
		var c: Dictionary = cues[i]
		if c["done"]:
			continue
		var d := absf(float(c["t"]) - elapsed)
		if d < best_d:
			best_d = d
			best_i = i
	if best_i < 0 or best_d > 0.32:
		interest -= 4.0
		combo = 0
		Fx.play("error")
		return
	var c2: Dictionary = cues[best_i]
	c2["done"] = true
	if int(c2["k"]) != k:
		_miss("Wrong feeling!")
		return
	var q := 1.0 if best_d < 0.09 else (0.7 if best_d < 0.18 else 0.4)
	hits += q
	combo += 1
	best = maxi(best, combo)
	interest = minf(100.0, interest + 3.0 + q * 3.0 + minf(combo, 10) * 0.3)
	Fx.play("good", 0.4)
	flash_text("Perfect!" if q >= 1.0 else ("Good" if q >= 0.7 else "Late"), col("good") if q >= 0.7 else col("warn"), Vector2(HIT_X + 40, TRACK_Y - 80), 26)


func _miss(txt: String) -> void:
	combo = 0
	interest -= 9.0
	Fx.play("bad", 0.5)
	flash_text(txt, col("bad"), Vector2(HIT_X + 40, TRACK_Y - 80), 26)


func _process(delta: float) -> void:
	if done:
		return
	elapsed += delta
	me_x = clampf(me_x + move * 420.0 * delta, 90.0, 910.0)
	light_timer -= delta
	if light_timer <= 0:
		light_timer = randf_range(1.2, 2.6) / difficulty
		light_to = randf_range(140.0, 860.0)
	light_x = move_toward(light_x, light_to, (150.0 + elapsed * 5.0) * difficulty * delta)
	var lit := absf(me_x - light_x) < light_w * 0.5
	if lit:
		presence += delta
	else:
		interest -= 5.0 * delta
	for c in cues:
		if not c["done"] and elapsed - float(c["t"]) > 0.32:
			c["done"] = true
			_miss("Missed cue")
	interest = clampf(interest, 0.0, 100.0)
	status.text = "Director's interest %d%%   ·   Combo %d   ·   %ds left" % [int(interest), combo, int(ceil(LENGTH - elapsed))]
	queue_redraw()
	if interest <= 0.0:
		Fx.play("bad")
		flash_text("\"NEXT!\"", col("bad"), Vector2(W / 2, 250), 48)
		finish(_score() * 0.5, {"hits": int(hits), "cut": true})
	elif elapsed >= LENGTH:
		Fx.play("fanfare")
		finish(_score(), {"hits": int(hits), "combo": best})


func _score() -> float:
	var acc := hits / maxf(1.0, float(total))
	var pres := presence / maxf(1.0, elapsed)
	return clampf(acc * 0.6 + pres * 0.25 + interest / 100.0 * 0.15, 0.0, 1.0)


func _draw() -> void:
	var fnt := ThemeManager.font_regular
	draw_rect(Rect2(40, TRACK_Y - 36, 920, 72), col("surface2"))
	draw_circle(Vector2(HIT_X, TRACK_Y), 38, col("track"))
	draw_arc(Vector2(HIT_X, TRACK_Y), 38, 0, TAU, 40, col("text"), 3)
	draw_string(fnt, Vector2(880, TRACK_Y - 44), "🎬", HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	for c in cues:
		if c["done"]:
			continue
		var dt := float(c["t"]) - elapsed
		if dt > travel:
			continue
		var x := HIT_X + dt / travel * (900.0 - HIT_X)
		var e: Array = EMO[int(c["k"])]
		draw_circle(Vector2(x, TRACK_Y), 32, e[1])
		draw_string(fnt, Vector2(x - 20, TRACK_Y + 14), e[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 44)
	var floor_y := STAGE_Y + 50
	draw_rect(Rect2(40, floor_y, 920, 8), col("border"))
	var lc := Color(col("gold"), 0.28)
	draw_colored_polygon(PackedVector2Array([Vector2(light_x - 20, 240), Vector2(light_x + 20, 240), Vector2(light_x + light_w * 0.5, floor_y), Vector2(light_x - light_w * 0.5, floor_y)]), lc)
	draw_string(fnt, Vector2(me_x - 24, floor_y - 4), "🧑‍🎤", HORIZONTAL_ALIGNMENT_LEFT, -1, 60)
	bar_rect(Rect2(40, 250, 180, 12), interest / 100.0, col("good") if interest > 35 else col("bad"), col("track"))
	draw_string(fnt, Vector2(40, 282), "Stay in the spotlight", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col("dim"))


func _unhandled_input(event: InputEvent) -> void:
	for i in range(4):
		if key_pressed(event, [KEY_1 + i, KEY_KP_1 + i]):
			_cue(i)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and not event.echo and event.keycode in [KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D]:
		var l := Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
		var r := Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
		move = (1.0 if r else 0.0) - (1.0 if l else 0.0)
		get_viewport().set_input_as_handled()
