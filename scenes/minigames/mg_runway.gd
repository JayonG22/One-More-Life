extends Minigame

const POSES := [["⬆", "💁", "Hair flip"], ["⬇", "🙇", "Look down"], ["⬅", "🤳", "Over the shoulder"], ["➡", "💃", "Twirl"]]
const KEYS := [[KEY_UP, KEY_W], [KEY_DOWN, KEY_S], [KEY_LEFT, KEY_A], [KEY_RIGHT, KEY_D]]
const MAX_ROUNDS := 6

var seq: Array = []
var input_i := 0
var rounds_done := 0
var showing := true
var show_i := 0
var show_t := 0.0
var input_time := 3.0
var model_l: Label
var cap_l: Label
var btns: Array[Button] = []


func build() -> void:
	make_status()
	model_l = label("🧍", 120)
	model_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(model_l, Vector2(W / 2 - 120, 60), Vector2(240, 160))
	cap_l = label("", 26, true)
	cap_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(cap_l, Vector2(0, 240), Vector2(W, 36))
	for i in range(4):
		var b := button("%s\n%s %s" % [POSES[i][0], POSES[i][1], POSES[i][2]], _press.bind(i), "Primary")
		b.add_theme_font_size_override("font_size", 18)
		place(b, Vector2(80 + i * 215, 330), Vector2(200, 110))
		btns.append(b)
	for i in range(2):
		seq.append(randi() % 4)
	_new_round()


func _new_round() -> void:
	if rounds_done >= MAX_ROUNDS:
		finish(1.0, {"rounds": rounds_done})
		return
	seq.append(randi() % 4)
	showing = true
	show_i = 0
	show_t = 0.0
	input_i = 0
	for b in btns:
		b.disabled = true
	cap_l.text = "Watch the sequence..."


func _press(i: int) -> void:
	if showing or done:
		return
	model_l.text = POSES[i][1]
	if i == seq[input_i]:
		Fx.play("tap")
		input_i += 1
		input_time = 3.0
		if input_i >= seq.size():
			rounds_done += 1
			Fx.play("crowd")
			flash_text("📸 Flawless walk!", col("good"), Vector2(W / 2, 290))
			for b in btns:
				b.disabled = true
			showing = true
			get_tree().create_timer(0.9).timeout.connect(_new_round)
	else:
		Fx.play("bad")
		flash_text("😬 Wrong pose!", col("bad"), Vector2(W / 2, 290))
		finish(rounds_done / float(MAX_ROUNDS) + input_i / float(seq.size()) / MAX_ROUNDS, {"rounds": rounds_done})


func _process(delta: float) -> void:
	if done:
		return
	status.text = "Walk %d of %d   ·   Sequence length %d" % [rounds_done + 1, MAX_ROUNDS, seq.size()]
	if showing and show_i <= seq.size():
		show_t += delta
		var step := maxf(0.35, 0.7 / difficulty)
		if show_t >= step:
			show_t = 0.0
			if show_i < seq.size():
				var pz: Array = POSES[seq[show_i]]
				model_l.text = pz[1]
				cap_l.text = "%s  %s" % [pz[0], pz[2]]
				Fx.play("page", 0.2)
				show_i += 1
			else:
				show_i += 1
				showing = false
				model_l.text = "🧍"
				cap_l.text = "Your turn! Repeat the %d poses." % seq.size()
				input_time = 3.0
				for b in btns:
					b.disabled = false
	elif not showing:
		input_time -= delta
		if input_time <= 0:
			Fx.play("bad")
			flash_text("⏰ You froze on the runway!", col("bad"), Vector2(W / 2, 290))
			finish(rounds_done / float(MAX_ROUNDS), {"rounds": rounds_done})
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(W / 2 - 60, 220, 120, 8), col("gold"))
	for i in range(seq.size()):
		var cc := col("track")
		if not showing and i < input_i:
			cc = col("good")
		draw_circle(Vector2(W / 2 - seq.size() * 14 + i * 28 + 14, 480), 9, cc)


func _unhandled_input(event: InputEvent) -> void:
	for i in range(4):
		if key_pressed(event, KEYS[i]):
			_press(i)
			get_viewport().set_input_as_handled()
