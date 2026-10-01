extends MinigameGamble

## LUCKY WHEEL. Sixteen slices, a flapper that ticks past them, and a long slowing
## spin. The slice is drawn first; the wheel is built to stop there.

const SEG := [0.0, 2.0, 0.0, 1.0, 0.0, 0.5, 0.0, 3.0, 0.0, 1.0, 0.5, 0.0, 1.5, 0.0, 2.0, 3.5]
var a := 0.0
var spinning := false
var t := 0.0
var dur := 6.5
var a0 := 0.0
var a1 := 0.0
var spin_btn: Button
var msg_l: Label
var center := Vector2(500, 290)
var last_tick := -1


func build() -> void:
	header("🎡  Lucky Wheel")
	msg_l = label("Spin the wheel.", 20, true)
	msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(msg_l, Vector2(0, 44), Vector2(W, 30))
	spin_btn = button("SPIN  [Space]", _spin, "Primary")
	place(spin_btn, Vector2(W / 2.0 - 140, 462), Vector2(280, 56))
	queue_redraw()


func _spin() -> void:
	if spinning or done:
		return
	spinning = true
	spin_btn.visible = false
	var idx := randi() % SEG.size()
	if luck > 1.0 and float(SEG[idx]) < 1.0 and randf() < (luck - 1.0) * 0.05:
		idx = 15
	var seg := TAU / float(SEG.size())
	# the flapper is at the top (-PI/2); slice idx must end up there
	a1 = -PI / 2.0 - (float(idx) + 0.5) * seg - TAU * 6.0
	a0 = a
	t = 0.0
	Fx.play("whoosh")


func _process(delta: float) -> void:
	if spinning and not done:
		t += delta
		var k := clampf(t / dur, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.4)
		a = lerpf(a0, a1, e)
		var tickn := int(floor(-a / (TAU / float(SEG.size()))))
		if tickn != last_tick:
			last_tick = tickn
			Fx.play("tap", 0.2)
		if k >= 1.0:
			spinning = false
			var seg := TAU / float(SEG.size())
			var pos := fposmod((-PI / 2.0 - a) / seg, float(SEG.size()))
			var idx := int(floor(pos)) % SEG.size()
			var m: float = float(SEG[idx])
			msg_l.text = "%s×" % str(m) if m > 0.0 else "Nothing"
			settle(int(float(bet) * m), "The wheel stopped on %s×." % str(m))
	queue_redraw()


func _draw() -> void:
	var n := SEG.size()
	var seg := TAU / float(n)
	for i in range(n):
		var m: float = float(SEG[i])
		var c := Color(0.55, 0.1, 0.12) if m == 0.0 else (Color(0.2, 0.45, 0.25) if m < 1.0 else (Color(0.2, 0.4, 0.75) if m < 3.0 else Color(0.85, 0.65, 0.15)))
		if i % 2 == 1:
			c = c.darkened(0.15)
		var pts := PackedVector2Array([center])
		for s in range(7):
			var ang := a + seg * float(i) + seg * float(s) / 6.0
			pts.append(center + Vector2(cos(ang), sin(ang)) * 190.0)
		draw_colored_polygon(pts, c)
		var mid := a + seg * (float(i) + 0.5)
		var tp := center + Vector2(cos(mid), sin(mid)) * 150.0
		draw_string(ThemeManager.font_bold, tp - Vector2(16, -6), ("%s×" % str(m)) if m > 0.0 else "✖", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1))
	draw_circle(center, 28, Color(0.9, 0.8, 0.3))
	var tri := PackedVector2Array([center + Vector2(0, -204), center + Vector2(-14, -226), center + Vector2(14, -226)])
	draw_colored_polygon(tri, Color(1, 0.9, 0.3))
