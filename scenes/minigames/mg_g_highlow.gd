extends MinigameGamble

## HIGH OR LOW, as a ladder. Guess whether the next card is higher or lower. Each
## right call multiplies the pot by what the odds say it should (less 4%), and you
## can take the pot at any time. A tie keeps the pot where it is.

var card := 8
var pot := 0.0
var streak := 0
var card_l: Label
var next_l: Label
var pot_l: Label
var hi_btn: Button
var lo_btn: Button
var take_btn: Button
var msg_l: Label
var busy := false
const NAMES := {11: "J", 12: "Q", 13: "K", 14: "A"}


func build() -> void:
	header("🂠  High or Low")
	pot = float(bet)
	msg_l = label("Will the next card be higher, or lower?", 20, true)
	msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(msg_l, Vector2(0, 44), Vector2(W, 30))
	card_l = label("", 96, true)
	card_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(card_l, Vector2(250, 120), Vector2(200, 140))
	next_l = label("?", 96, true)
	next_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(next_l, Vector2(550, 120), Vector2(200, 140))
	pot_l = label("", 30, true, col("gold"))
	pot_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(pot_l, Vector2(0, 280), Vector2(W, 42))
	hi_btn = button("⬆ HIGHER  [W]", _guess.bind(true), "Primary")
	place(hi_btn, Vector2(230, 350), Vector2(240, 66))
	lo_btn = button("⬇ LOWER  [S]", _guess.bind(false), "Primary")
	place(lo_btn, Vector2(530, 350), Vector2(240, 66))
	take_btn = button("TAKE THE POT  [Space]", _take, "Accent")
	place(take_btn, Vector2(W / 2.0 - 160, 440), Vector2(320, 56))
	take_btn.disabled = true
	card = randi_range(2, 14)
	_refresh()


func _name(v: int) -> String:
	return str(NAMES.get(v, v))


func _refresh() -> void:
	card_l.text = _name(card)
	pot_l.text = "Pot  %s    ·    streak %d" % [GameState.fmt_money(int(pot)), streak]
	take_btn.disabled = streak == 0 or busy


func _odds(high: bool) -> float:
	var n := 0.0
	for v in range(2, 15):
		if (high and v > card) or (not high and v < card):
			n += 1.0
	return n / 13.0


func _guess(high: bool) -> void:
	if done or busy:
		return
	var p := _odds(high)
	if p <= 0.0:
		msg_l.text = "No card can be %s than that." % ("higher" if high else "lower")
		return
	busy = true
	var nxt := randi_range(2, 14)
	if randf() < (luck - 1.0) * 0.04:
		nxt = clampi(card + (1 if high else -1) * randi_range(1, 3), 2, 14)
	var tw := create_tween()
	next_l.text = "…"
	tw.tween_interval(0.4)
	tw.tween_callback(func():
		next_l.text = _name(nxt)
		var win := (nxt > card and high) or (nxt < card and not high)
		if nxt == card:
			msg_l.text = "A tie. The pot stays."
			Fx.play("tap")
		elif win:
			var f := 0.92 / p
			pot *= f
			streak += 1
			msg_l.text = "Right!  ×%.2f" % f
			Fx.play("coin")
			confetti(6)
		else:
			msg_l.text = "Wrong."
			card = nxt
			_refresh()
			settle(0, "I called %s on a %s and the next card was a %s." % ["higher" if high else "lower", _name(card), _name(nxt)])
			return
		card = nxt
		busy = false
		var t2 := create_tween()
		t2.tween_interval(0.5)
		t2.tween_callback(func(): next_l.text = "?")
		_refresh())


func _take() -> void:
	if done or busy or streak == 0:
		return
	busy = true
	settle(int(pot), "I took the pot after a streak of %d." % streak)


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_W, KEY_UP]):
		_guess(true)
	elif key_pressed(event, [KEY_S, KEY_DOWN]):
		_guess(false)
	elif key_pressed(event, [KEY_SPACE, KEY_ENTER]):
		_take()
