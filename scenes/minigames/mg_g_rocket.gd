extends MinigameGamble

## ROCKET. A multiplier climbs. Cash out before it blows. The point where it
## crashes is drawn up front from a fair curve (the house keeps 8%), and everyone
## who has ever played knows exactly how it feels to watch it go past 3x and wait.

var crash_at := 2.0
var mult := 1.0
var running := false
var t := 0.0
var cashed := false
var cash_mult := 0.0
var hist: Array = []
var msg_l: Label
var mult_l: Label
var go_btn: Button
var cash_btn: Button
var exploded := false
var auto_at := 0.0
var auto_l: Label
var prev: Array = []


func build() -> void:
	header("🚀  Rocket")
	msg_l = label("Launch, then cash out before it crashes.", 20, true)
	msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(msg_l, Vector2(0, 44), Vector2(W, 30))
	mult_l = label("1.00×", 80, true)
	mult_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(mult_l, Vector2(0, 150), Vector2(W, 100))
	go_btn = button("LAUNCH  [Space]", _go, "Primary")
	place(go_btn, Vector2(W / 2.0 - 170, 440), Vector2(340, 64))
	cash_btn = button("CASH OUT  [Space]", _cash, "Accent")
	place(cash_btn, Vector2(W / 2.0 - 170, 440), Vector2(340, 64))
	cash_btn.visible = false
	auto_l = label("Auto cash-out:  ← → to set  (off)", 16, true)
	auto_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(auto_l, Vector2(0, 510), Vector2(W, 24))
	var u := randf()
	crash_at = maxf(1.0, snappedf(0.92 / maxf(0.0001, 1.0 - u), 0.01))
	if luck > 1.0 and randf() < (luck - 1.0) * 0.04:
		crash_at *= 1.6
	crash_at = minf(crash_at, 500.0)


func _go() -> void:
	if running or done:
		return
	running = true
	go_btn.visible = false
	cash_btn.visible = true
	msg_l.text = "Climbing…"
	Fx.play("whoosh")
	t = 0.0


func _cash() -> void:
	if not running or cashed or done:
		return
	cashed = true
	running = false
	cash_mult = mult
	cash_btn.visible = false
	msg_l.text = "Cashed out at %.2f×" % mult
	Fx.play("coin")
	# let the rocket fly on, so you see what you left behind
	var t2 := create_tween()
	t2.tween_interval(0.5)
	t2.tween_callback(func(): _reveal())


func _reveal() -> void:
	exploded = false
	settle(int(float(bet) * cash_mult), "Cashed out at %.2fx (it crashed at %.2fx)." % [cash_mult, crash_at])


func _process(delta: float) -> void:
	if done:
		return
	if running:
		t += delta
		mult = exp(0.14 * t * (1.0 + t * 0.03))
		if auto_at > 1.0 and mult >= auto_at:
			_cash()
		if mult >= crash_at:
			mult = crash_at
			running = false
			exploded = true
			cash_btn.visible = false
			msg_l.text = "CRASHED at %.2f×" % crash_at
			Fx.play("bad", 0.04)
			shake(14.0)
			var t3 := create_tween()
			t3.tween_interval(0.9)
			t3.tween_callback(func(): settle(0, "The rocket crashed at %.2fx." % crash_at))
	mult_l.text = "%.2f×" % mult
	mult_l.modulate = Color(1, 0.4, 0.3) if exploded else (Color(0.5, 1, 0.5) if cashed else Color(1, 1, 1))
	if running or cashed:
		hist.append(mult)
	elif hist.is_empty():
		hist.append(1.0)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(70, 250, W - 140, 170)
	draw_rect(r, Color(0.04, 0.05, 0.1))
	if hist.size() < 2:
		return
	var top := maxf(2.0, float(hist[hist.size() - 1]) * 1.2)
	var pts := PackedVector2Array()
	for i in range(hist.size()):
		var x := r.position.x + r.size.x * float(i) / float(maxi(hist.size() - 1, 1)) * 0.92
		var y := r.end.y - (float(hist[i]) - 1.0) / (top - 1.0) * r.size.y
		pts.append(Vector2(x, y))
	draw_polyline(pts, Color(0.4, 0.9, 1.0), 3.0, true)
	var tip := pts[pts.size() - 1]
	draw_string(ThemeManager.font_bold, tip + Vector2(-14, -8), "💥" if exploded else "🚀", HORIZONTAL_ALIGNMENT_LEFT, -1, 30)


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_SPACE, KEY_ENTER]):
		if not running and not cashed and not exploded:
			_go()
		else:
			_cash()
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_RIGHT, KEY_D]) and not running:
		auto_at = 1.5 if auto_at < 1.5 else minf(auto_at + 0.5, 20.0)
		auto_l.text = "Auto cash-out at %.1f×   ← → to change" % auto_at
	elif key_pressed(event, [KEY_LEFT, KEY_A]) and not running:
		auto_at = 0.0 if auto_at <= 1.5 else auto_at - 0.5
		auto_l.text = ("Auto cash-out at %.1f×   ← → to change" % auto_at) if auto_at > 0.0 else "Auto cash-out:  ← → to set  (off)"
