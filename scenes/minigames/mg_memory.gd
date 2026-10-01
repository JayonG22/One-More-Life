extends Minigame

## MEMORY TEST. Nine tiles light up in a sequence; repeat it. Every sequence you
## get right adds one more. Two slips are allowed; the third ends the test. Your
## score is how long a sequence you held, out of ten.

const START_LEN := 3
const MAX_LEN := 10
const LIVES := 3

var seq: Array = []
var length := START_LEN
var best := 0
var lives := LIVES
var input_i := 0
var phase := "show"        # show, input, gap
var phase_t := 0.8
var show_i := 0
var tiles: Array = []
var hint_l: Label
var lit := -1


func build() -> void:
	make_status()
	hint_l = label("", 22, true)
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(hint_l, Vector2(40, 50), Vector2(W - 80, 40))
	for i in range(9):
		var b := button(str(i + 1), _press.bind(i), "Row")
		b.add_theme_font_size_override("font_size", 34)
		place(b, Vector2(W / 2.0 - 190 + (i % 3) * 130, 120 + (i / 3) * 110), Vector2(120, 100))
		tiles.append(b)
	var legend := label("Watch the tiles light up, then press them in the same order: click, or keys 1–9 (numpad too).", 15, true)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(legend, Vector2(0, 490), Vector2(W, 30))
	_new_sequence()


func _new_sequence() -> void:
	seq.clear()
	var last := -1
	for _i in range(length):
		var n := randi() % 9
		while n == last:
			n = randi() % 9
		seq.append(n)
		last = n
	phase = "show"
	show_i = 0
	phase_t = 0.9
	input_i = 0
	hint_l.text = "Watch…"
	_set_lit(-1)


func _set_lit(i: int) -> void:
	lit = i
	for k in range(tiles.size()):
		var b: Button = tiles[k]
		b.modulate = Color(1.6, 1.4, 0.4) if k == i else Color(1, 1, 1)


func _process(delta: float) -> void:
	if done:
		return
	status.text = "Sequence of %d  ·  best %d  ·  slips left %d" % [length, best, lives - 1]
	phase_t -= delta
	if phase_t > 0.0:
		return
	match phase:
		"show":
			if lit == -1 and show_i < seq.size():
				_set_lit(int(seq[show_i]))
				phase_t = 0.55 / difficulty
			elif lit != -1:
				_set_lit(-1)
				show_i += 1
				phase_t = 0.2
			else:
				phase = "input"
				hint_l.text = "Your turn."
				phase_t = 99.0
		"gap":
			_set_lit(-1)
			_new_sequence()


func _press(i: int) -> void:
	if done or phase != "input":
		return
	_set_lit(i)
	var t := create_tween()
	t.tween_interval(0.12)
	t.tween_callback(func(): if phase == "input": _set_lit(-1))
	if i == int(seq[input_i]):
		Fx.play("tap")
		input_i += 1
		if input_i >= seq.size():
			best = length
			if length >= MAX_LEN:
				finish(1.0, {"length": best})
				return
			length += 1
			phase = "gap"
			phase_t = 0.9
			hint_l.text = "Right. One longer…"
	else:
		Fx.play("bad", 0.05)
		lives -= 1
		if lives <= 0:
			finish(clampf(float(maxi(0, best - START_LEN + 1)) / float(MAX_LEN - START_LEN + 1), 0.0, 1.0), {"length": best})
			return
		hint_l.text = "Not that one. Again."
		phase = "gap"
		phase_t = 1.0


func _unhandled_input(event: InputEvent) -> void:
	for k in range(9):
		if key_pressed(event, [KEY_1 + k, KEY_KP_1 + k]):
			_press(k)
			get_viewport().set_input_as_handled()
			return
