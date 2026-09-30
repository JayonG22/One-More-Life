extends Minigame

const MARKS := 3
const MARK_TIME := 9.0
const DANGER := 0.7
const FACES := ["🧔", "👩‍🦰", "👨‍💼", "👵", "🧑‍🎤", "👱"]

var mark_i := 0
var attention := 0.2
var target_att := 0.2
var retarget := 0.0
var progress := 0.0
var holding := false
var mark_time := MARK_TIME
var results: Array = []
var caught := 0
var between := false
var face_l: Label
var eye_l: Label
var hold_b: Button


func build() -> void:
	make_status()
	face_l = label("", 110)
	face_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(face_l, Vector2(W / 2 - 150, 50), Vector2(300, 140))
	eye_l = label("", 26, true)
	eye_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(eye_l, Vector2(0, 200), Vector2(W, 36))
	var wal := label("👛", 48)
	place(wal, Vector2(130, 330), Vector2(60, 60))
	hold_b = button("✋ Hold to lift  [Space]", func(): pass, "Accent")
	hold_b.button_down.connect(func(): holding = true)
	hold_b.button_up.connect(func(): holding = false)
	place(hold_b, Vector2(W / 2 - 170, 430), Vector2(340, 70))
	_new_mark()


func _new_mark() -> void:
	if mark_i >= MARKS:
		var s := 0.0
		for r in results:
			s += float(r)
		finish(s / MARKS, {"lifted": results.filter(func(r): return float(r) > 0).size(), "caught": caught})
		return
	mark_i += 1
	progress = 0.0
	attention = randf_range(0.1, 0.4)
	target_att = attention
	mark_time = MARK_TIME
	holding = false
	between = false
	face_l.text = FACES[randi() % FACES.size()]


func _end_mark(result: float, msg: String, good: bool) -> void:
	between = true
	holding = false
	results.append(result)
	Fx.play("coin" if good else "bad")
	flash_text(msg, col("good") if good else col("bad"), Vector2(W / 2, 280))
	get_tree().create_timer(1.0).timeout.connect(_new_mark)


func _process(delta: float) -> void:
	if done:
		return
	if between:
		queue_redraw()
		return
	mark_time -= delta
	retarget -= delta
	if retarget <= 0:
		retarget = randf_range(0.4, 1.2) / difficulty
		target_att = randf_range(0.05, 0.6)
		if randf() < 0.28 * difficulty:
			target_att = randf_range(0.8, 1.0)
	attention = move_toward(attention, target_att, delta * 1.8 * difficulty)
	if holding:
		progress += delta * 0.42
		if attention > DANGER:
			caught += 1
			_end_mark(-0.3, "😠 \"Hey! Thief!\"", false)
			return
	if progress >= 1.0:
		_end_mark(1.0, "💰 Got it!", true)
		return
	if mark_time <= 0:
		_end_mark(0.0, "🚶 The mark walked away.", false)
		return
	eye_l.text = ["😴 Distracted", "🙂 Relaxed", "🤨 Suspicious!", "👀 LOOKING!"][clampi(int(attention * 4), 0, 3)]
	eye_l.add_theme_color_override("font_color", col("bad") if attention > DANGER else (col("warn") if attention > 0.5 else col("good")))
	status.text = "Mark %d of %d   ·   %.0fs" % [mark_i, MARKS, maxf(0.0, mark_time)]
	queue_redraw()


func _draw() -> void:
	var r := Rect2(200, 350, 640, 26)
	bar_rect(r, progress, col("gold"), col("track"))
	var ar := Rect2(200, 250, 640, 16)
	draw_rect(ar, col("track"))
	draw_rect(Rect2(ar.position.x + ar.size.x * DANGER, ar.position.y, ar.size.x * (1 - DANGER), ar.size.y), Color(col("bad"), 0.35))
	draw_rect(Rect2(ar.position.x + ar.size.x * attention - 5, ar.position.y - 6, 10, ar.size.y + 12), col("text"))


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_SPACE]):
		holding = true
		get_viewport().set_input_as_handled()
	elif key_released(event, [KEY_SPACE]):
		holding = false
