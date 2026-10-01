extends MinigameGamble

## ROULETTE. A drawn wheel and a ball that circles the other way, slows, hops and
## drops into a pocket. The winning pocket is decided first, then the ball is
## animated into it, so the maths is exactly the table's.

const REDS := [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
const ORDER := [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
const BETS := {
	"red": ["Red", 2], "black": ["Black", 2], "odd": ["Odd", 2], "even": ["Even", 2], "low": ["1–18", 2], "high": ["19–36", 2],
	"dozen": ["13–24", 3], "seven": ["Number 7", 36], "lucky": ["Number 17", 36], "zero": ["Zero", 36],
}

var choice := "red"
var wheel_a := 0.0
var ball_rel := 0.0
var ball_r := 150.0
var target := 0
var spinning := false
var t := 0.0
var dur := 6.0
var start_rel := 0.0
var end_rel := 0.0
var spin_btn: Button
var msg_l: Label
var center := Vector2(330, 290)


func build() -> void:
	choice = str(params.get("choice", "red"))
	if not BETS.has(choice):
		choice = "red"
	header("🎡  Roulette")
	msg_l = label("Your bet:  %s  (pays %d×)" % [BETS[choice][0], BETS[choice][1]], 22, true)
	msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(msg_l, Vector2(0, 44), Vector2(W, 32))
	spin_btn = button("SPIN  [Space]", _spin, "Primary")
	place(spin_btn, Vector2(640, 380), Vector2(300, 70))
	var info := label("The ball circles one way, the wheel the other. Watch it slow down; it can still hop a few pockets.", 17, true)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place(info, Vector2(640, 150), Vector2(310, 120))
	queue_redraw()


func _spin() -> void:
	if spinning or done:
		return
	spinning = true
	spin_btn.visible = false
	var n := randi() % 37
	if not _wins(n) and randf() < (luck - 1.0) * 0.04:
		for k in range(37):
			var cand := (n + k) % 37
			if _wins(cand):
				n = cand
				break
	target = n
	var idx := ORDER.find(n)
	var seg := TAU / 37.0
	end_rel = float(idx) * seg + seg * 0.5      # the ball's angle in the wheel's own frame
	start_rel = end_rel + TAU * 7.0 + randf() * TAU
	t = 0.0
	ball_r = 150.0
	msg_l.text = "No more bets…"
	Fx.play("whoosh")


func _wins(n: int) -> bool:
	var red := REDS.has(n)
	match choice:
		"red": return n != 0 and red
		"black": return n != 0 and not red
		"odd": return n != 0 and n % 2 == 1
		"even": return n != 0 and n % 2 == 0
		"low": return n >= 1 and n <= 18
		"high": return n >= 19
		"dozen": return n >= 13 and n <= 24
		"seven": return n == 7
		"lucky": return n == 17
		"zero": return n == 0
	return false


func _process(delta: float) -> void:
	wheel_a += delta * (1.2 if spinning else 0.25)
	if spinning and not done:
		t += delta
		var k := clampf(t / dur, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.0)
		ball_rel = lerpf(start_rel, end_rel, e)
		ball_r = lerpf(150.0, 112.0, clampf((k - 0.62) / 0.38, 0.0, 1.0)) + (sin(t * 40.0) * 3.0 * clampf((k - 0.8) * 5.0, 0.0, 1.0) if k < 1.0 else 0.0)
		if k >= 1.0:
			spinning = false
			var red := REDS.has(target)
			var cname := "green" if target == 0 else ("red" if red else "black")
			var win := _wins(target)
			msg_l.text = "%d  %s" % [target, cname.to_upper()]
			Fx.play("coin" if win else "bad")
			settle(int(bet * int(BETS[choice][1])) if win else 0, "The ball landed on %d %s." % [target, cname])
	queue_redraw()


func _draw() -> void:
	var seg := TAU / 37.0
	draw_circle(center, 178, Color(0.35, 0.22, 0.1))
	draw_circle(center, 168, Color(0.12, 0.09, 0.07))
	for i in range(37):
		var n: int = ORDER[i]
		var a0 := wheel_a + float(i) * seg
		var c := Color(0.1, 0.55, 0.25) if n == 0 else (Color(0.75, 0.12, 0.12) if REDS.has(n) else Color(0.08, 0.08, 0.1))
		var pts := PackedVector2Array([center])
		for s in range(5):
			var a := a0 + seg * float(s) / 4.0
			pts.append(center + Vector2(cos(a), sin(a)) * 138.0)
		draw_colored_polygon(pts, c)
		var mid := a0 + seg * 0.5
		var tp := center + Vector2(cos(mid), sin(mid)) * 122.0
		draw_string(ThemeManager.font_bold, tp - Vector2(7, -5), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1))
	draw_circle(center, 84, Color(0.2, 0.15, 0.1))
	draw_circle(center, 20, Color(0.8, 0.65, 0.2))
	var ba := wheel_a + ball_rel
	draw_circle(center + Vector2(cos(ba), sin(ba)) * ball_r, 7, Color(1, 1, 1))
	draw_circle(center + Vector2(cos(ba), sin(ba)) * ball_r, 7, Color(0.7, 0.7, 0.7), false, 1.5)


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_SPACE, KEY_ENTER]):
		_spin()
		get_viewport().set_input_as_handled()
