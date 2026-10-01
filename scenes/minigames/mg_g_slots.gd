extends MinigameGamble

## SLOTS. Three reels that spin and stop one at a time. Two matching with the third
## still to come makes the whole table lean in. A near-miss offers a respin of the
## odd reel for half the bet again. Three 🎁 open a bonus: pick three chests.

const SYM := ["🍒", "🍋", "🔔", "⭐", "💎", "7️⃣"]
const WEIGHTS := [30, 25, 18, 13, 9, 5]
const PAY := {"🍒": 5.0, "🍋": 8.0, "🔔": 12.0, "⭐": 20.0, "💎": 50.0, "7️⃣": 100.0}
const GIFT := "🎁"

var reels: Array = []        # three Labels (the visible middle symbol)
var upper: Array = []
var lower: Array = []
var final_syms: Array = []
var stop_at: Array = []
var stopped: Array = [false, false, false]
var spin_t := 0.0
var spinning := false
var tick := 0.0
var msg_l: Label
var respin_btn: Button
var spin_btn: Button
var bonus_open := false
var chest_btns: Array = []
var chest_vals: Array = []
var picks_left := 0
var bonus_total := 0.0
var respun := false


func build() -> void:
	header("🎰  Slots")
	msg_l = label("Press SPIN or Space.", 20, true)
	msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(msg_l, Vector2(0, 52), Vector2(W, 30))
	for i in range(3):
		var frame := ColorRect.new()
		frame.color = Color(0.06, 0.07, 0.13)
		place(frame, Vector2(250 + i * 170, 100), Vector2(150, 300))
		var line := ColorRect.new()
		line.color = Color(1, 0.8, 0.2, 0.18)
		place(line, Vector2(250 + i * 170, 205), Vector2(150, 90))
		var u := label("", 54)
		u.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		u.modulate.a = 0.4
		place(u, Vector2(250 + i * 170, 112), Vector2(150, 80))
		var m := label("", 80)
		m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		place(m, Vector2(250 + i * 170, 205), Vector2(150, 90))
		var d := label("", 54)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.modulate.a = 0.4
		place(d, Vector2(250 + i * 170, 305), Vector2(150, 80))
		upper.append(u)
		reels.append(m)
		lower.append(d)
		(reels[i] as Label).text = SYM[randi() % SYM.size()]
	spin_btn = button("SPIN  [Space]", _spin, "Primary")
	place(spin_btn, Vector2(W / 2.0 - 150, 430), Vector2(300, 66))
	respin_btn = button("Respin the odd reel  (+%s)" % GameState.fmt_money(int(bet * 0.5)), _respin, "Accent")
	place(respin_btn, Vector2(W / 2.0 - 190, 430), Vector2(380, 66))
	respin_btn.visible = false
	var legend := label("7️⃣ 100×  ·  💎 50×  ·  ⭐ 20×  ·  🔔 12×  ·  🍋 8×  ·  🍒 5×   |   any pair pays 1.5×   |   🎁🎁🎁 bonus chests", 14, true)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(legend, Vector2(0, 508), Vector2(W, 24))


func _roll_sym() -> String:
	var r := randi() % 100
	var acc := 0
	for i in range(WEIGHTS.size()):
		acc += WEIGHTS[i]
		if r < acc:
			return SYM[i]
	return SYM[0]


func _spin() -> void:
	if spinning or done or bonus_open:
		return
	spin_btn.visible = false
	respin_btn.visible = false
	stopped = [false, false, false]
	final_syms.clear()
	for _i in range(3):
		var s := _roll_sym()
		if randf() < 0.02:
			s = GIFT
		final_syms.append(s)
	if randf() < (luck - 1.0) * 0.05:
		final_syms[0] = final_syms[1]
		final_syms[2] = final_syms[1]
	stop_at = [0.9, 1.6, 2.4]
	# the tease: a pair showing slows the last reel
	if final_syms[0] == final_syms[1]:
		stop_at[2] = 3.4
	spin_t = 0.0
	spinning = true
	msg_l.text = "Spinning…"
	Fx.play("whoosh")


func _respin() -> void:
	if spinning or done or respun:
		return
	extra_stake = int(bet * 0.5)
	respun = true
	respin_btn.visible = false
	var odd := 0
	if final_syms[0] == final_syms[1]:
		odd = 2
	elif final_syms[1] == final_syms[2]:
		odd = 0
	else:
		odd = 1
	var s := _roll_sym()
	final_syms[odd] = s
	if randf() < (luck - 1.0) * 0.05:
		final_syms[odd] = final_syms[1] if odd != 1 else final_syms[0]
	stopped = [true, true, true]
	stopped[odd] = false
	stop_at = [0.0, 0.0, 0.0]
	stop_at[odd] = 1.2
	spin_t = 0.0
	spinning = true
	msg_l.text = "Respin…"
	Fx.play("whoosh")


func _process(delta: float) -> void:
	if done or not spinning:
		return
	spin_t += delta
	tick -= delta
	var blur := tick <= 0.0
	if blur:
		tick = 0.06
	var all := true
	for i in range(3):
		if stopped[i]:
			continue
		if spin_t >= float(stop_at[i]):
			stopped[i] = true
			(reels[i] as Label).text = str(final_syms[i])
			(upper[i] as Label).text = SYM[randi() % SYM.size()]
			(lower[i] as Label).text = SYM[randi() % SYM.size()]
			var b := create_tween()
			(reels[i] as Label).pivot_offset = Vector2(75, 45)
			b.tween_property(reels[i], "scale", Vector2(1.25, 1.25), 0.07)
			b.tween_property(reels[i], "scale", Vector2(1, 1), 0.12)
			Fx.play("tap", 0.06)
		else:
			all = false
			if blur:
				(reels[i] as Label).text = SYM[randi() % SYM.size()]
				(upper[i] as Label).text = SYM[randi() % SYM.size()]
				(lower[i] as Label).text = SYM[randi() % SYM.size()]
	if all:
		spinning = false
		_evaluate()


func _evaluate() -> void:
	var a: String = final_syms[0]
	var b: String = final_syms[1]
	var c: String = final_syms[2]
	var gifts := 0
	for s in final_syms:
		if s == GIFT:
			gifts += 1
	if gifts == 3:
		msg_l.text = "🎁🎁🎁  BONUS!"
		_open_bonus()
		return
	var mult := 0.0
	var txt := "%s  %s  %s" % [a, b, c]
	if a == b and b == c and PAY.has(a):
		mult = float(PAY[a])
		msg_l.text = "THREE %s !" % a
	elif (a == b or b == c) and b != GIFT:
		mult = 1.5 if b != "🍒" else 2.0
		msg_l.text = "A pair…"
		# a pair offers the respin once
		if not respun and money_now >= int(bet * 2.0):
			respin_btn.visible = true
			respin_btn.disabled = false
			spin_btn.visible = false
			var t := create_tween()
			t.tween_interval(3.2)
			t.tween_callback(func(): if not done and not spinning and respin_btn.visible: respin_btn.visible = false; _finish(mult, txt))
			return
	elif final_syms.has("🍒"):
		mult = 0.5
		msg_l.text = "A cherry."
	else:
		msg_l.text = "Nothing."
	_finish(mult, txt)


func _finish(mult: float, txt: String) -> void:
	if done:
		return
	settle(int(float(bet) * mult), txt)


func _open_bonus() -> void:
	bonus_open = true
	picks_left = 3
	chest_vals = [0.0, 0.0, 0.5, 0.5, 1.0, 1.0, 2.0, 4.0, 10.0]
	chest_vals.shuffle()
	for i in range(9):
		var b := button("🎁", _chest.bind(i), "Row")
		b.add_theme_font_size_override("font_size", 40)
		place(b, Vector2(240 + (i % 3) * 190, 110 + (i / 3) * 105), Vector2(170, 95))
		chest_btns.append(b)
	for r in reels:
		(r as Label).visible = false


func _chest(i: int) -> void:
	if picks_left <= 0 or done:
		return
	var b: Button = chest_btns[i]
	if b.disabled:
		return
	b.disabled = true
	picks_left -= 1
	var v: float = chest_vals[i]
	bonus_total += v
	b.text = "%sx" % str(v) if v > 0.0 else "💨"
	Fx.play("coin" if v > 0.0 else "tap")
	msg_l.text = "Picks left: %d  ·  bonus %s×" % [picks_left, str(bonus_total)]
	if picks_left <= 0:
		var t := create_tween()
		t.tween_interval(0.8)
		t.tween_callback(func(): settle(int(float(bet) * bonus_total), "Bonus chests: %s×" % str(bonus_total)))


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_SPACE, KEY_ENTER]):
		if spin_btn.visible:
			_spin()
		elif respin_btn.visible:
			_respin()
		get_viewport().set_input_as_handled()
