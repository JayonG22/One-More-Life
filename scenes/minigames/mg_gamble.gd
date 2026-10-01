extends Minigame
class_name MinigameGamble

## Shared base for the casino games: a stake, a luck modifier, a payout banner and
## a confetti burst. Subclasses call settle(won, text) once; `won` is the money
## paid back (0 for a loss), so the net is won - stake. Score is won / (2 x bet).
##
## A visit is a session: after each round the player can play again at the same bet
## or leave ("Cash out" while there is money, "Give up" when there is not). The game
## only reports to the casino once, with the whole session's stake and winnings.
## Pass `single: true` to play one round and finish (tests and bots do).

var bet := 100
var luck := 1.0
var bank_l: Label
var win_l: Label
var extra_stake := 0
var money_now := 0
var total_stake := 0
var total_won := 0
var rounds := 0
var round_settled := false
var panel: Control
signal restarted(next: MinigameGamble)


func setup(p: Dictionary) -> void:
	super.setup(p)
	bet = int(p.get("bet", 100))
	luck = float(p.get("luck", 1.0))
	money_now = int(p.get("money", bet * 3))


func header(title: String) -> void:
	var t := label(title, 24, true, col("gold"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(t, Vector2(0, 6), Vector2(W, 34))
	bank_l = label(bank_text(), 20, true)
	place(bank_l, Vector2(24, 10), Vector2(300, 30))
	win_l = label("", 20, true, col("good"))
	win_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	place(win_l, Vector2(W - 324, 10), Vector2(300, 30))


func cash_now() -> int:
	return money_now + total_won - total_stake


func bank_text() -> String:
	if rounds == 0 and not bool(params.get("single", false)):
		return "Bet  %s" % GameState.fmt_money(bet)
	return "Bet  %s   ·   Cash  %s" % [GameState.fmt_money(bet), GameState.fmt_money(cash_now())]


func rolled(p: float) -> bool:
	return randf() < clampf(p * (1.0 + (luck - 1.0) * 0.12), 0.0, 1.0)


func confetti(n: int, emojis: Array = ["🪙", "✨", "💰", "🎉"], from: Vector2 = Vector2(W / 2.0, 120)) -> void:
	for i in range(n):
		var l := label(str(emojis[randi() % emojis.size()]), randi_range(22, 40))
		add_child(l)
		l.position = from + Vector2(randf_range(-40, 40), 0)
		l.z_index = 50
		var t := create_tween()
		var dest := Vector2(randf_range(60, W - 60), randf_range(H - 80, H - 10))
		t.tween_property(l, "position", Vector2(l.position.x + randf_range(-260, 260), randf_range(-60, 40)), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		t.tween_property(l, "position", dest, randf_range(0.7, 1.3)).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		t.parallel().tween_property(l, "modulate:a", 0.0, 1.6)
		t.tween_callback(l.queue_free)


func shake(amount: float = 10.0) -> void:
	var t := create_tween()
	for i in range(6):
		t.tween_property(self, "position:x", position.x + randf_range(-amount, amount), 0.04)
	t.tween_property(self, "position:x", position.x, 0.04)


func settle(won: int, text: String) -> void:
	if done:
		return
	var net := won - bet - extra_stake
	if won > 0 and won >= (bet + extra_stake) * 5:
		Fx.play("cash")
		Fx.voice("v_cheer")
		confetti(46)
		flash_text("BIG WIN  %s" % GameState.fmt_money(won), col("gold"), Vector2(W / 2.0, 200), 54)
	elif won > bet + extra_stake:
		Fx.play("coin")
		Fx.voice("v_woo", 0.6)
		confetti(18)
		flash_text("+%s" % GameState.fmt_money(net), col("good"), Vector2(W / 2.0, 220), 44)
	elif won > 0:
		Fx.play("tap")
		flash_text("Paid %s" % GameState.fmt_money(won), col("dim"), Vector2(W / 2.0, 220), 36)
	else:
		Fx.play("bad", 0.05)
		Fx.voice("v_ugh", 0.7)
		shake(6.0)
		flash_text("Nothing", col("bad"), Vector2(W / 2.0, 220), 40)
	if win_l:
		win_l.text = "Paid  %s" % GameState.fmt_money(won)
	total_stake += bet + extra_stake
	total_won += won
	rounds += 1
	round_settled = true
	var t := create_tween()
	t.tween_interval(1.9)
	t.tween_callback(func(): _round_end(text))


func _session_detail(text: String) -> Dictionary:
	return {"won": total_won, "text": text, "extra": total_stake - bet}


func _round_end(text: String) -> void:
	if done:
		return
	if bool(params.get("single", false)):
		finish(clampf(float(total_won) / (2.0 * float(maxi(1, bet))), 0.0, 1.0), _session_detail(text))
		return
	set_process_unhandled_input(false)
	var net := total_won - total_stake
	var can_play := cash_now() >= bet
	panel = Control.new()
	panel.z_index = 80
	add_child(panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.size = Vector2(W, H)
	panel.add_child(dim)
	var head := label("Round %d" % rounds, 18, true, col("dim"))
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(head)
	head.position = Vector2(0, 150)
	head.size = Vector2(W, 26)
	var sn := label("%s%s this visit" % ["+" if net > 0 else ("−" if net < 0 else ""), GameState.fmt_money(absi(net))], 44, true, col("good") if net > 0 else (col("bad") if net < 0 else col("text")))
	sn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(sn)
	sn.position = Vector2(0, 182)
	sn.size = Vector2(W, 60)
	var cl := label("In your pocket  %s" % GameState.fmt_money(cash_now()), 20, true)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(cl)
	cl.position = Vector2(0, 248)
	cl.size = Vector2(W, 30)
	if can_play:
		var again := button("Play again  ·  bet %s  [Enter]" % GameState.fmt_money(bet), _again, "Primary")
		panel.add_child(again)
		again.position = Vector2(W / 2.0 - 250, 310)
		again.size = Vector2(500, 60)
		var out := button("Cash out  [Esc]", func(): finish(clampf(float(total_won) / (2.0 * float(maxi(1, bet))), 0.0, 1.0), _session_detail(text)), "Row")
		panel.add_child(out)
		out.position = Vector2(W / 2.0 - 250, 384)
		out.size = Vector2(500, 52)
		again.grab_focus()
	else:
		var quit := button("Give up  [Enter]", func(): finish(0.0, _session_detail(text)), "Primary")
		panel.add_child(quit)
		quit.position = Vector2(W / 2.0 - 250, 330)
		quit.size = Vector2(500, 60)
		var note := label("You can't cover another bet.", 16, true, col("dim"))
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(note)
		note.position = Vector2(0, 400)
		note.size = Vector2(W, 24)
		quit.grab_focus()
	panel.set_meta("text", text)


func _again() -> void:
	if done or get_parent() == null:
		return
	var n: MinigameGamble = get_script().new()
	n.setup(params)
	n.total_stake = total_stake
	n.total_won = total_won
	n.rounds = rounds
	n.scale = scale
	n.position = position
	get_parent().add_child(n)
	restarted.emit(n)
	done = true
	queue_free()


func finish(score: float, detail: Dictionary = {}) -> void:
	if detail.get("quit", false) and not detail.has("won"):
		# walked out mid-round: the stake already in play is gone
		if not round_settled:
			total_stake += bet + extra_stake
		detail = _session_detail("I walked away mid-round.")
	super.finish(score, detail)


func _input(event: InputEvent) -> void:
	if panel == null or not is_instance_valid(panel) or done:
		return
	if key_pressed(event, [KEY_ESCAPE]) and cash_now() >= bet:
		finish(clampf(float(total_won) / (2.0 * float(maxi(1, bet))), 0.0, 1.0), _session_detail(str(panel.get_meta("text", ""))))
		get_viewport().set_input_as_handled()
