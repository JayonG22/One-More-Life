extends Minigame

const NUMS := 40
const LIMIT := 45.0
const CENTER := Vector2(360, 290)
const RADIUS := 170.0

var combo: Array = []
var found := 0
var value := 0.0
var spin := 0.0
var alarm := 0.0
var time_left := LIMIT
var hold_dir := 0
var feel_l: Label
var val_l: Label
var locked: Array = []


func build() -> void:
	make_status()
	for i in range(3):
		var n := randi() % NUMS
		while combo.has(n):
			n = randi() % NUMS
		combo.append(n)
	value = float(randi() % NUMS)
	val_l = label("", 44, true)
	val_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(val_l, Vector2(CENTER.x - 80, CENTER.y - 30), Vector2(160, 60))
	feel_l = label("", 20, true)
	place(feel_l, Vector2(620, 170), Vector2(340, 30))
	var l := button("◀", func(): _step(-1), "Row")
	l.add_theme_font_size_override("font_size", 30)
	place(l, Vector2(620, 380), Vector2(100, 70))
	var r := button("▶", func(): _step(1), "Row")
	r.add_theme_font_size_override("font_size", 30)
	place(r, Vector2(860, 380), Vector2(100, 70))
	var lk := button("🔓 Lock", _lock, "Accent")
	place(lk, Vector2(730, 380), Vector2(120, 70))
	var hint := label("Hold ◀ ▶ or A / D to spin.\nPress Space to lock the number.", 15, false, col("dim"))
	place(hint, Vector2(620, 470), Vector2(340, 50))


func _step(d: int) -> void:
	value = fposmod(round(value) + d, NUMS)
	Fx.play("tap", 0.1)


func _dist() -> int:
	if found >= 3:
		return 99
	var cur := int(round(value)) % NUMS
	var d := absi(cur - int(combo[found]))
	return mini(d, NUMS - d)


func _lock() -> void:
	if done:
		return
	if _dist() == 0:
		locked.append(int(combo[found]))
		found += 1
		Fx.play("coin")
		flash_text("🔒 Click!", col("good"), Vector2(790, 110))
		if found >= 3:
			Fx.play("fanfare")
			finish(0.7 + 0.3 * time_left / LIMIT, {"found": 3, "alarm": alarm})
	else:
		alarm += 26.0 * difficulty
		Fx.play("error")
		flash_text("🚨 Wrong!", col("bad"), Vector2(790, 110))
		if alarm >= 100:
			Fx.play("siren")
			finish(found / 3.0 * 0.5, {"found": found, "alarm": 100, "tripped": true})


func _process(delta: float) -> void:
	if done:
		return
	time_left -= delta
	if hold_dir != 0:
		spin += delta
		if spin > 0.09:
			spin = 0.0
			_step(hold_dir)
	var d := _dist()
	var feel := clampf(1.0 - d / 8.0, 0.0, 1.0)
	feel_l.text = "Tumbler: " + ("●".repeat(int(feel * 8)) + "○".repeat(8 - int(feel * 8)))
	feel_l.add_theme_color_override("font_color", col("good") if d == 0 else (col("warn") if d <= 2 else col("dim")))
	val_l.text = "%02d" % (int(round(value)) % NUMS)
	val_l.position.x = CENTER.x - 80 + (randf_range(-2.0, 2.0) if d <= 1 else 0.0)
	status.text = "Numbers %d / 3   ·   Alarm %d%%   ·   %.0fs" % [found, int(alarm), maxf(0.0, time_left)]
	queue_redraw()
	if time_left <= 0:
		Fx.play("siren")
		finish(found / 3.0 * 0.55, {"found": found, "alarm": alarm, "timeout": true})


func _draw() -> void:
	draw_circle(CENTER, RADIUS + 16, col("border"))
	draw_circle(CENTER, RADIUS, col("surface2"))
	for i in range(NUMS):
		var ang := TAU * i / NUMS - PI / 2 - TAU * value / NUMS
		var inner := RADIUS - (22.0 if i % 5 == 0 else 12.0)
		var a := CENTER + Vector2(cos(ang), sin(ang)) * inner
		var b := CENTER + Vector2(cos(ang), sin(ang)) * (RADIUS - 2)
		draw_line(a, b, col("text"), 3.0 if i % 5 == 0 else 1.5)
	draw_colored_polygon(PackedVector2Array([CENTER + Vector2(-12, -RADIUS - 30), CENTER + Vector2(12, -RADIUS - 30), CENTER + Vector2(0, -RADIUS - 6)]), col("accent"))
	for i in range(3):
		var cc := col("good") if i < found else col("track")
		draw_rect(Rect2(620 + i * 116, 230, 100, 60), cc)
		if i < locked.size():
			draw_string(ThemeManager.font_bold, Vector2(648 + i * 116, 272), "%02d" % locked[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 30, col("accent_text"))
	bar_rect(Rect2(620, 320, 340, 16), alarm / 100.0, col("bad"), col("track"))


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_A, KEY_LEFT]):
		hold_dir = -1
		_step(-1)
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_D, KEY_RIGHT]):
		hold_dir = 1
		_step(1)
		get_viewport().set_input_as_handled()
	elif key_released(event, [KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT]):
		hold_dir = 0
	elif key_pressed(event, [KEY_SPACE, KEY_ENTER]):
		_lock()
		get_viewport().set_input_as_handled()
