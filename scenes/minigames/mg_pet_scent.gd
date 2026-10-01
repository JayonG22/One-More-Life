extends Minigame

## SCENT WORK. Follow a trail eight steps long. At each fork the nose gives three
## readings — left, ahead, right — and every reading is noisy. Sniff again to
## average the noise away, but the clock is running. A wrong turn costs time, not
## the whole trail. Thinking beats twitching.

const STEPS := 8
const TIME := 55.0

var step := 0
var truth := 1
var readings: Array = []     # per sniff: [l, a, r]
var time_left := TIME
var wrong := 0
var bars: Array = []
var hint_l: Label
var trail_l: Label
var sniffs := 0


func build() -> void:
	make_status()
	hint_l = label("", 20, true)
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(hint_l, Vector2(40, 46), Vector2(W - 80, 60))
	trail_l = label("", 34)
	trail_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(trail_l, Vector2(0, 108), Vector2(W, 50))
	for i in range(3):
		var cap := label(["◀ Left", "▲ Ahead", "▶ Right"][i], 20, true)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		place(cap, Vector2(110 + i * 270, 340), Vector2(220, 28))
		var b := button("%s  [%s]" % [["Go left", "Go ahead", "Go right"][i], ["A", "W", "D"][i]], _go.bind(i), "Primary")
		place(b, Vector2(110 + i * 270, 372), Vector2(220, 56))
	var sn := button("👃 Sniff again  [Space]", _sniff, "Accent")
	place(sn, Vector2(W / 2 - 170, 444), Vector2(340, 60))
	var legend := label("Space sniffs (readings get clearer when you sniff more than once). A / W / D chooses the way.", 15, true)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(legend, Vector2(0, 512), Vector2(W, 24))
	_fork()


func _fork() -> void:
	if step >= STEPS:
		var t := clampf(time_left / TIME, 0.0, 1.0)
		finish(0.6 + 0.25 * t + 0.15 * maxf(0.0, 1.0 - wrong * 0.25), {"wrong": wrong, "sniffs": sniffs})
		return
	truth = randi() % 3
	readings.clear()
	_sniff()
	hint_l.text = "Fork %d of %d. Which way does the scent run strongest?" % [step + 1, STEPS]
	_trail()


func _trail() -> void:
	trail_l.text = "🐾".repeat(step) + "❔" + "·".repeat(maxi(0, STEPS - step - 1))


func _sniff() -> void:
	if done:
		return
	var r: Array = []
	for i in range(3):
		var base := 0.2 + randf() * 0.35
		if i == truth:
			base += 0.28
		r.append(base)
	readings.append(r)
	sniffs += 1
	time_left -= 0.9
	Fx.play("tap", 0.05)
	queue_redraw()


func _avg(i: int) -> float:
	var s := 0.0
	for r in readings:
		s += float(r[i])
	return s / float(maxi(1, readings.size()))


func _go(i: int) -> void:
	if done:
		return
	if i == truth:
		step += 1
		Fx.play("tap")
		hint_l.text = "Right way."
		_fork()
	else:
		wrong += 1
		time_left -= 4.0
		Fx.play("bad", 0.05)
		hint_l.text = "Wrong way: the scent goes cold. That cost four seconds."
		readings.clear()
		_sniff()


func _process(delta: float) -> void:
	if done:
		return
	time_left -= delta
	status.text = "Fork %d of %d  ·  %d s  ·  %d sniff%s here" % [mini(step + 1, STEPS), STEPS, int(maxf(0.0, time_left)), readings.size(), "" if readings.size() == 1 else "s"]
	if time_left <= 0.0:
		finish(0.55 * float(step) / float(STEPS), {"wrong": wrong, "sniffs": sniffs, "out_of_time": true})


func _draw() -> void:
	for i in range(3):
		var h := _avg(i) * 150.0
		draw_rect(Rect2(110 + i * 270, 330 - h, 220, h), col("primary").lerp(col("good"), _avg(i)))
		draw_rect(Rect2(110 + i * 270, 180, 220, 150), col("border"), false, 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_A, KEY_LEFT]):
		_go(0)
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_W, KEY_UP]):
		_go(1)
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_D, KEY_RIGHT]):
		_go(2)
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_SPACE, KEY_S, KEY_DOWN]):
		_sniff()
		get_viewport().set_input_as_handled()
