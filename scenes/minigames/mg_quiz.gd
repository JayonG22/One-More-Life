extends Minigame

## Licence theory test.
##
## Deliberately untimed. Every other minigame here asks for reflexes; this one
## asks whether you actually know the thing you are claiming a licence for, and
## a clock would only measure reading speed.
##
## You must answer every question correctly to pass. Getting one wrong does not
## end the attempt — you finish the paper and are told the right answer each
## time, because being told what you got wrong is the part that teaches anything.

var bank: Array = []
var needed := 5
var idx := 0
var correct := 0
var wrong: Array = []
var answered := false
var title_text := "LICENCE TEST"

var sign_box: Control
var q_label: Label
var progress: Label
var feedback: Label
var buttons: Array[Button] = []
var current_sign: Dictionary = {}


func build() -> void:
	bank = params.get("bank", [])
	needed = mini(int(params.get("needed", bank.size())), bank.size())
	title_text = str(params.get("title", "LICENCE TEST")).to_upper()

	var title := label("📋  " + title_text, 28, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(title, Vector2(0, 14), Vector2(W, 38))

	progress = label("", 16)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(progress, Vector2(0, 54), Vector2(W, 24))

	sign_box = Control.new()
	sign_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sign_box.draw.connect(_draw_sign)
	place(sign_box, Vector2(0, 80), Vector2(W, 120))

	q_label = label("", 22, true)
	q_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place(q_label, Vector2(90, 202), Vector2(820, 58))

	for i in range(4):
		var b := button("", _answer.bind(i), "Primary")
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		place(b, Vector2(150, 268 + i * 52), Vector2(700, 46))
		buttons.append(b)

	feedback = label("", 16)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place(feedback, Vector2(70, 478), Vector2(860, 56))

	_show_question()


func _show_question() -> void:
	answered = false
	if idx >= needed:
		_finish_paper()
		return
	var q: Dictionary = bank[idx]
	current_sign = q.get("sign", {})
	sign_box.visible = not current_sign.is_empty()
	sign_box.queue_redraw()
	q_label.position.y = 202.0 if sign_box.visible else 150.0
	progress.text = "Question %d of %d   ·   %d correct so far   ·   every answer must be right" % [idx + 1, needed, correct]
	q_label.text = str(q.get("q", ""))
	var opts: Array = q.get("a", [])
	for i in range(buttons.size()):
		var b := buttons[i]
		b.visible = i < opts.size()
		b.disabled = false
		b.remove_theme_color_override("font_color")
		if i < opts.size():
			b.text = "%d.   %s" % [i + 1, str(opts[i])]
	feedback.text = ""


func _answer(choice: int) -> void:
	if answered or idx >= needed:
		return
	answered = true
	var q: Dictionary = bank[idx]
	var right := int(q.get("correct", 0))
	var opts: Array = q.get("a", [])
	for b in buttons:
		b.disabled = true
	if choice == right:
		correct += 1
		feedback.text = "Correct.   %s" % str(q.get("why", ""))
		Fx.play("good", 0.01)
	else:
		wrong.append(str(q.get("q", "")))
		feedback.text = "Not quite — the answer was \"%s\".   %s" % [str(opts[right]), str(q.get("why", ""))]
		Fx.play("bad", 0.01)
	if right < buttons.size():
		buttons[right].add_theme_color_override("font_color", col("good"))
	if choice != right and choice < buttons.size():
		buttons[choice].add_theme_color_override("font_color", col("bad"))
	await get_tree().create_timer(2.4).timeout
	if done:
		return
	idx += 1
	_show_question()


func _finish_paper() -> void:
	# Pass is everything correct. A theory test you can fail a question on is not
	# a test — and the player was shown the right answer either way.
	var passed := correct >= needed
	finish(1.0 if passed else float(correct) / maxf(1.0, float(needed)) * 0.6,
		{"correct": correct, "asked": needed, "wrong": wrong, "passed": passed})


func _unhandled_input(event: InputEvent) -> void:
	if answered:
		return
	for i in range(4):
		if key_pressed(event, [KEY_1 + i, KEY_KP_1 + i]):
			if i < buttons.size() and buttons[i].visible:
				_answer(i)
				accept_event()
			return


# ---------------------------------------------------------------- sign drawing

func _hex(s: String, fallback: Color) -> Color:
	if s == "":
		return fallback
	return Color(s)


## Signs are drawn rather than imported, so they stay crisp at any interface size
## and the shape itself carries the meaning the question is testing.
func _draw_sign() -> void:
	if current_sign.is_empty():
		return
	var shape := str(current_sign.get("shape", "circle"))
	var fill := _hex(str(current_sign.get("fill", "#c0392b")), col("bad"))
	var border := _hex(str(current_sign.get("border", "#ffffff")), Color.WHITE)
	var text := str(current_sign.get("text", ""))
	var tcol := _hex(str(current_sign.get("text_color", "#ffffff")), Color.WHITE)

	var c := Vector2(W * 0.5, 58.0)
	var r := 50.0
	var pts := PackedVector2Array()
	match shape:
		"octagon":
			for i in range(8):
				var a := deg_to_rad(22.5 + i * 45.0)
				pts.append(c + Vector2(cos(a), sin(a)) * r)
		"triangle_down":
			pts.append(c + Vector2(-r * 1.08, -r * 0.72))
			pts.append(c + Vector2(r * 1.08, -r * 0.72))
			pts.append(c + Vector2(0.0, r * 0.98))
		"triangle_up":
			pts.append(c + Vector2(0.0, -r * 0.98))
			pts.append(c + Vector2(r * 1.08, r * 0.72))
			pts.append(c + Vector2(-r * 1.08, r * 0.72))
		"diamond":
			pts.append(c + Vector2(0.0, -r))
			pts.append(c + Vector2(r, 0.0))
			pts.append(c + Vector2(0.0, r))
			pts.append(c + Vector2(-r, 0.0))
		"rect":
			pts.append(c + Vector2(-r * 0.76, -r))
			pts.append(c + Vector2(r * 0.76, -r))
			pts.append(c + Vector2(r * 0.76, r))
			pts.append(c + Vector2(-r * 0.76, r))
		_:
			for i in range(40):
				var a2 := deg_to_rad(i * 9.0)
				pts.append(c + Vector2(cos(a2), sin(a2)) * r)

	sign_box.draw_colored_polygon(pts, fill)
	var outline := PackedVector2Array(pts)
	outline.append(pts[0])
	sign_box.draw_polyline(outline, border, 5.0, true)

	if text != "":
		var size := 26 if text.length() <= 4 else 18
		var f := ThemeManager.font_bold
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		sign_box.draw_string(f, c + Vector2(-w * 0.5, 9.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tcol)
