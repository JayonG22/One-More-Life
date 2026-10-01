extends Minigame

## NEGOTIATION. Three rounds. They open at 100. Somewhere above that is the most
## they will really pay, and you cannot see it. Ask too little and they say yes
## at once and you will never know what you left behind. Ask too much and they
## walk. Their replies tell you how much room is left, if you listen.
##
## The player's skill only decides how clearly they read the replies; it never
## decides the outcome. There is always a way to win it by thinking.

const ROUNDS := 3
const LOW := 100
const HIGH := 145

var limit := 120          # the hidden most they will pay
var offer := 100          # what they are currently offering
var ask := 112
var round_i := 1
var patience := 3
var closed := false
var log_l: Label
var ask_l: Label
var cue_l: Label
var subject := "the pay"
var last_cue := ""
var steps: Array = []     # [ask, reply] pairs, for the bot and the summary


func build() -> void:
	subject = str(params.get("subject", "the pay"))
	var room := randi_range(7, 24)
	limit = LOW + room
	make_status()
	var title := label("Negotiating %s" % subject, 26, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(title, Vector2(0, 46), Vector2(W, 36))
	log_l = label("", 19)
	log_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place(log_l, Vector2(60, 100), Vector2(W - 120, 150))
	cue_l = label("", 20, true, col("warn"))
	cue_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(cue_l, Vector2(60, 262), Vector2(W - 120, 56))
	ask_l = label("", 44, true)
	ask_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(ask_l, Vector2(W / 2 - 200, 332), Vector2(400, 60))
	var defs := [["−5", -5], ["−1", -1], ["+1", 1], ["+5", 5]]
	for i in range(4):
		var b := button(defs[i][0], _nudge.bind(int(defs[i][1])), "Row")
		b.tooltip_text = "Change your ask by %d" % int(defs[i][1])
		place(b, Vector2(W / 2 - 300 + i * 160, 392), Vector2(130, 52))
	var go := button("Make the ask  [Enter]", _make_ask, "Accent")
	place(go, Vector2(W / 2 - 150, 452), Vector2(300, 52))
	var hint := label("← → (A / D) change by 1  ·  ↑ ↓ (W / S) change by 5  ·  Enter or Space makes the ask", 15, false, col("dim"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(hint, Vector2(0, 512), Vector2(W, 20))
	_say("They open at 100. You have %d rounds. How much do you think there is in it?" % ROUNDS)
	_refresh()


func _say(t: String) -> void:
	log_l.text = t


func _nudge(d: int) -> void:
	if done or closed:
		return
	ask = clampi(ask + d, LOW, HIGH)
	Fx.play("tap", 0.05)
	_refresh()


func _refresh() -> void:
	ask_l.text = "Ask: %d" % ask
	status.text = "Round %d of %d   ·   %s" % [round_i, ROUNDS, "★".repeat(patience) + "☆".repeat(3 - patience)]
	queue_redraw()


func _make_ask() -> void:
	if done or closed:
		return
	steps.append([ask])
	if ask <= limit:
		_deal(ask)
		return
	var over := ask - limit
	# they move toward their limit, but not all the way, and never past it
	var move := maxi(1, int(round(float(limit - offer) * randf_range(0.35, 0.6))))
	if over > 12:
		patience -= 2
		cue_l.text = "They stiffen. \"That's not a serious number.\""
	elif over > 5:
		patience -= 1
		cue_l.text = "They frown. \"That's a stretch.\""
	else:
		cue_l.text = "\"Close. Not quite.\""
	offer = clampi(offer + move, LOW, limit)
	var room_left := limit - offer
	# the reply carries the information; a better read of the room (skill) makes it clearer
	var clarity := clampf(float(params.get("skill", 50.0)) / 100.0, 0.2, 1.0)
	var cue := ""
	if room_left <= 2:
		cue = "They look at the table. They are nearly at their limit."
	elif room_left <= 7:
		cue = "They glance at each other. There's a little left in it."
	else:
		cue = "They lean back, relaxed. There is plenty of room."
	if randf() > clarity and room_left > 2:
		cue = "They give nothing away."
	steps[-1].append(offer)
	_say("They counter at %d.\n%s" % [offer, cue])
	last_cue = cue
	if patience <= 0:
		_end(false, 0)
		return
	round_i += 1
	if round_i > ROUNDS:
		# out of rounds: they put their last offer on the table; take it or leave it
		_deal(offer, true)
		return
	ask = clampi(mini(ask, offer + (limit - offer) + 4), offer, HIGH)
	_refresh()


func _deal(price: int, last_offer: bool = false) -> void:
	closed = true
	var gap := maxi(1, limit - LOW)
	var score := clampf(float(price - LOW) / float(gap), 0.0, 1.0)
	var left := limit - price
	if last_offer:
		_say("You took their final number, %d. It was the best they would give." % price if left <= 2 else "You took their final number, %d. You'd read them badly: there was %d more." % [price, left])
	elif left > 4:
		_say("They said yes at once, at %d. They would have gone to %d. Quick agreement should make you ask what you left behind." % [price, limit])
	else:
		_say("\"Done.\" %d. You were within %d of the most they'd have paid." % [price, left])
	Fx.play("fanfare" if score > 0.7 else "coin")
	finish(clampf(score, 0.0, 1.0), {"price": price, "limit": limit, "rounds": round_i, "deal": true})


func _end(deal: bool, price: int) -> void:
	closed = true
	_say("They stand up. \"I think we're done here.\" The offer on the table was %d, and you left it." % offer)
	Fx.play("bad")
	finish(0.0, {"price": offer, "limit": limit, "rounds": round_i, "deal": false, "walked": true})


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_LEFT, KEY_A]):
		_nudge(-1)
	elif key_pressed(event, [KEY_RIGHT, KEY_D]):
		_nudge(1)
	elif key_pressed(event, [KEY_UP, KEY_W]):
		_nudge(5)
	elif key_pressed(event, [KEY_DOWN, KEY_S]):
		_nudge(-5)
	elif key_pressed(event, [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]):
		_make_ask()
	else:
		return
	get_viewport().set_input_as_handled()


func _draw() -> void:
	# a rule from 100 to 145: their offer, your ask
	var x0 := 160.0
	var x1 := W - 160.0
	draw_rect(Rect2(x0, 322, x1 - x0, 4), col("border"))
	var fx := func(v: float) -> float: return lerpf(x0, x1, (v - LOW) / float(HIGH - LOW))
	draw_circle(Vector2(fx.call(offer), 324), 9, col("warn"))
	draw_circle(Vector2(fx.call(ask), 324), 7, col("primary"))
