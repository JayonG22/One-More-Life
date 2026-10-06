extends MinigameGamble

## PLINKO. A ball falls through eight rows of pegs, going left or right at each
## one, and lands in a bucket. Pick the risk before the drop: Low keeps most of
## your stake, High is nearly all-or-nothing with a big prize at either edge.

const ROWS := 8
const TABLES := {
	"low": [5.6, 2.0, 1.1, 0.9, 0.4, 0.9, 1.1, 2.0, 5.6],
	"med": [12.0, 3.0, 1.3, 0.6, 0.35, 0.6, 1.3, 3.0, 12.0],
	"high": [22.0, 3.5, 1.4, 0.3, 0.2, 0.3, 1.4, 3.5, 22.0],
}

var risk := "med"
var ball: Label
var buckets: Array = []
var risk_btns: Dictionary = {}
var drop_btn: Button
var dropping := false
var msg_l: Label
const OX := 500.0
const DX := 54.0
const TOP := 90.0
const DY := 36.0


func build() -> void:
	header("🔵  Plinko")
	msg_l = label("Pick a risk, then drop the ball.", 20, true)
	msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(msg_l, Vector2(0, 44), Vector2(W, 30))
	for r in range(ROWS):
		for k in range(r + 2):
			var x := OX + (float(k) - float(r + 1) / 2.0) * DX
			var peg := ColorRect.new()
			peg.color = Color(0.75, 0.8, 0.95)
			place(peg, Vector2(x - 4, TOP + 20 + r * DY), Vector2(8, 8))
	for b in range(ROWS + 1):
		var l := label("", 18, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var x2 := OX + (float(b) - float(ROWS) / 2.0) * DX
		place(l, Vector2(x2 - 25, TOP + 20 + ROWS * DY + 4), Vector2(50, 28))
		buckets.append(l)
	ball = label("🔵", 28)
	place(ball, Vector2(OX - 14, TOP - 6), Vector2(30, 34))
	var i := 0
	for rk in ["low", "med", "high"]:
		var bt := button({"low": "Low", "med": "Medium", "high": "High"}[rk] + " risk", _set_risk.bind(rk), "Row")
		place(bt, Vector2(60, 120 + i * 70), Vector2(210, 56))
		risk_btns[rk] = bt
		i += 1
	drop_btn = button("DROP  [Space]", _drop, "Primary")
	place(drop_btn, Vector2(740, 200), Vector2(220, 70))
	_set_risk("med")


func _set_risk(rk: String) -> void:
	if dropping:
		return
	risk = rk
	for k in risk_btns.keys():
		(risk_btns[k] as Button).modulate = Color(1.4, 1.3, 0.6) if k == rk else Color(1, 1, 1)
	var tab: Array = TABLES[risk]
	for b in range(buckets.size()):
		var m := float(tab[b])
		var l: Label = buckets[b]
		l.text = ("%s×" % str(m))
		l.add_theme_color_override("font_color", Color(0.4, 1, 0.5) if m >= 1.5 else (Color(1, 0.8, 0.3) if m >= 0.9 else Color(1, 0.4, 0.4)))


func _drop() -> void:
	if dropping or done:
		return
	dropping = true
	drop_btn.visible = false
	for rk in risk_btns.keys():
		(risk_btns[rk] as Button).disabled = true
	var path: Array = []
	var right := 0
	for _r in range(ROWS):
		var go_right := randf() < 0.5
		path.append(go_right)
		if go_right:
			right += 1
	# fair binomial; luck adds a small chance to nudge one step toward the middle
	var tab: Array = TABLES[risk]
	var tw := create_tween()
	var x := OX
	var rr := 0
	for r in range(ROWS):
		var dir := 1.0 if path[r] else -1.0
		x += dir * DX / 2.0
		var y := TOP + 20 + r * DY + DY * 0.55
		tw.tween_property(ball, "position", Vector2(x - 14, y - 10), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(Fx.play.bind("tap", 0.15))
		if path[r]:
			rr += 1
	tw.tween_property(ball, "position", Vector2(OX + (float(right) - float(ROWS) / 2.0) * DX - 14, TOP + 20 + ROWS * DY - 6), 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		var m := float(tab[right])
		(buckets[right] as Label).scale = Vector2(1.5, 1.5)
		settle(int(float(bet) * m), "The ball dropped into the %s× bucket on %s risk." % [str(m), risk]))


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_SPACE, KEY_ENTER]):
		_drop()
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_1]):
		_set_risk("low")
	elif key_pressed(event, [KEY_2]):
		_set_risk("med")
	elif key_pressed(event, [KEY_3]):
		_set_risk("high")
