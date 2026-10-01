extends Minigame

const ROUND_LEN := 22.0
const ROUNDS := 3

var me_hp := 100.0
var opp_hp := 100.0
var stamina := 100.0
var round_i := 1
var round_t := ROUND_LEN
var state := "idle"
var state_t := 1.2
var tele := ""
var blocked_ok := false
var opp_l: Label
var me_l: Label
var call_l: Label
var opp_name := "The Challenger"
var hint_l: Label
var tell_l: Label
var btn_high: Button
var btn_low: Button
var btn_strike: Button
var learned := 0     # clean blocks so far; the first few telegraphs are slower


func build() -> void:
	opp_name = str(params.get("opponent", "The Challenger"))
	make_status()
	opp_l = label("🥊😠", 90)
	opp_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(opp_l, Vector2(W / 2 + 60, 110), Vector2(300, 130))
	me_l = label("😤🥊", 90)
	me_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(me_l, Vector2(W / 2 - 360, 110), Vector2(300, 130))
	call_l = label("", 36, true)
	call_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(call_l, Vector2(0, 260), Vector2(W, 50))
	tell_l = label("", 64, true)
	tell_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(tell_l, Vector2(W / 2 + 60, 230), Vector2(300, 74))
	hint_l = label("", 20, true)
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(hint_l, Vector2(40, 318), Vector2(W - 80, 60))
	var names := [["⬆ Block high  [W]", _block.bind("HIGH")], ["⬇ Block low  [S]", _block.bind("LOW")], ["👊 Strike  [Space]", _strike]]
	for i in range(3):
		var b := button(names[i][0], names[i][1], "Accent" if i == 2 else "Primary")
		place(b, Vector2(110 + i * 270, 440), Vector2(250, 66))
		b.tooltip_text = ["Guard against a punch to the head", "Guard against a punch to the body", "Hit back — only lands hard right after a block"][i]
		match i:
			0: btn_high = b
			1: btn_low = b
			_: btn_strike = b
	var legend := label("W / ↑ block high   ·   S / ↓ block low   ·   Space strike, but only after a block lands", 15, true)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(legend, Vector2(0, 512), Vector2(W, 24))
	var nl := label("You", 18, true)
	place(nl, Vector2(60, 46), Vector2(200, 24))
	var ol := label(opp_name, 18, true)
	ol.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	place(ol, Vector2(W - 460, 46), Vector2(400, 24))


func _telegraph() -> void:
	var r := randf()
	if r < 0.14:
		tele = "FEINT"
	else:
		tele = "HIGH" if randf() < 0.5 else "LOW"
	state = "tele"
	state_t = maxf(0.38, 0.8 - 0.14 * difficulty - (round_i - 1) * 0.06)
	# until the player has the idea, the tell lasts long enough to read
	if learned < 3 and not bool(GameState.settings.get("fight_learned", false)):
		state_t = maxf(state_t, 1.5)
	blocked_ok = false
	call_l.text = {"HIGH": "⬆ HIGH!", "LOW": "⬇ LOW!", "FEINT": "↔ ..."}[tele]
	call_l.add_theme_color_override("font_color", col("warn"))
	opp_l.text = "🥊😤"


func _block(where: String) -> void:
	if done:
		return
	if state == "tele":
		if tele == "FEINT":
			stamina = maxf(0.0, stamina - 12)
			call_l.text = "Fooled you!"
			Fx.play("tap")
			_to_idle()
		elif where == tele:
			blocked_ok = true
			learned += 1
			if learned >= 3:
				GameState.settings["fight_learned"] = true
			Fx.play("tap")
			state = "counter"
			# The counter window is the whole game. At the relaxed default it is
			# generous; only Brisk makes it a real test of reflexes.
			state_t = 1.15 / difficulty
			call_l.text = "🛡️ Blocked! STRIKE NOW!"
			call_l.add_theme_color_override("font_color", col("good"))
		else:
			_hit_me("Wrong guard!")
	else:
		stamina = maxf(0.0, stamina - 4)


func _strike() -> void:
	if done:
		return
	if state == "counter":
		var dmg := randf_range(12, 18) * (0.6 + 0.4 * stamina / 100.0)
		opp_hp = maxf(0.0, opp_hp - dmg)
		stamina = maxf(0.0, stamina - 8)
		Fx.play("bad", 0.1)
		call_l.text = "💥 Counter! -%d" % int(dmg)
		opp_l.text = "😵"
		_to_idle()
	elif state == "idle" or state == "tele":
		if stamina < 15:
			call_l.text = "Too tired — wait for the stamina bar"
			call_l.add_theme_color_override("font_color", col("warn"))
			return
		stamina -= 15
		if randf() < 0.5:
			var dmg2 := randf_range(4, 8)
			opp_hp = maxf(0.0, opp_hp - dmg2)
			Fx.play("tap", 0.1)
			call_l.text = "👊 Jab landed! -%d" % int(dmg2)
			call_l.add_theme_color_override("font_color", col("good"))
		else:
			# Say WHY. A bare "Blocked." reads as the button not working.
			call_l.text = "He blocked the jab — wait for his wind-up, then counter"
			call_l.add_theme_color_override("font_color", col("dim"))
	_check_end()


func _hit_me(msg: String) -> void:
	var dmg := randf_range(10, 16) * difficulty
	me_hp = maxf(0.0, me_hp - dmg)
	Fx.play("bad")
	call_l.text = "😖 %s -%d" % [msg, int(dmg)]
	call_l.add_theme_color_override("font_color", col("bad"))
	me_l.text = "😵🥊"
	_to_idle()
	_check_end()


func _to_idle() -> void:
	state = "idle"
	state_t = randf_range(0.7, 1.5) / difficulty


func _check_end() -> void:
	if done:
		return
	if opp_hp <= 0:
		Fx.play("fanfare")
		finish(0.6 + 0.4 * me_hp / 100.0, {"won": true, "ko": true, "me_hp": me_hp})
	elif me_hp <= 0:
		finish(0.35 * (1.0 - opp_hp / 100.0), {"won": false, "ko": true, "opp_hp": opp_hp})


## Say exactly what to do right now, and light up the button that does it.
func _coach() -> void:
	var pulse := 0.65 + 0.35 * sin(Time.get_ticks_msec() / 1000.0 * 9.0)
	for b in [btn_high, btn_low, btn_strike]:
		if is_instance_valid(b):
			(b as Button).modulate = Color(1, 1, 1, 1)
	match state:
		"tele":
			match tele:
				"HIGH":
					hint_l.text = "He's swinging at your HEAD.\nBlock HIGH now: press W or ⬆."
					tell_l.text = "⬆"
					btn_high.modulate = Color(1, 1, 1, pulse)
				"LOW":
					hint_l.text = "He's swinging at your BODY.\nBlock LOW now: press S or ⬇."
					tell_l.text = "⬇"
					btn_low.modulate = Color(1, 1, 1, pulse)
				_:
					hint_l.text = "A feint — he's only pretending.\nDon't react. Wait."
					tell_l.text = "↔"
			tell_l.add_theme_color_override("font_color", col("warn"))
		"counter":
			hint_l.text = "You blocked it. He's open.\nSTRIKE NOW: press Space."
			tell_l.text = "👊"
			tell_l.add_theme_color_override("font_color", col("good"))
			btn_strike.modulate = Color(1, 1, 1, pulse)
		_:
			hint_l.text = "Watch his gloves. When he winds up, block the same height.\nA block opens a counter — that is where the damage comes from."
			tell_l.text = ""
	hint_l.add_theme_color_override("font_color", col("text"))


func _process(delta: float) -> void:
	if done:
		return
	_coach()
	stamina = minf(100.0, stamina + 9.0 * delta)
	round_t -= delta
	state_t -= delta
	if state_t <= 0:
		match state:
			"idle":
				_telegraph()
			"tele":
				if tele == "FEINT":
					_to_idle()
				else:
					_hit_me("Hit!")
			"counter":
				call_l.text = ""
				_to_idle()
	if state == "idle" and state_t < 0.3:
		opp_l.text = "🥊😠"
		me_l.text = "😤🥊"
	if round_t <= 0:
		if round_i >= ROUNDS:
			var won := opp_hp < me_hp
			finish((0.55 + 0.35 * (me_hp - opp_hp) / 100.0) if won else maxf(0.05, 0.4 - (opp_hp - me_hp) / 200.0), {"won": won, "decision": true})
			return
		round_i += 1
		round_t = ROUND_LEN
		stamina = 100.0
		Fx.play("levelup")
		call_l.text = "🔔 Round %d" % round_i
		_to_idle()
	status.text = "Round %d of %d   ·   %ds" % [round_i, ROUNDS, int(maxf(0.0, round_t))]
	queue_redraw()


func _draw() -> void:
	bar_rect(Rect2(60, 74, 380, 20), me_hp / 100.0, col("good"), col("track"))
	bar_rect(Rect2(60, 98, 380, 8), stamina / 100.0, col("primary"), col("track"))
	bar_rect(Rect2(W - 440, 74, 380, 20), opp_hp / 100.0, col("bad"), col("track"))
	draw_rect(Rect2(60, 400, W - 120, 4), col("border"))


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_W, KEY_UP]):
		_block("HIGH")
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_S, KEY_DOWN]):
		_block("LOW")
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_SPACE, KEY_J]):
		_strike()
		get_viewport().set_input_as_handled()
