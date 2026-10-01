extends Minigame
class_name MinigameGamble

## Shared base for the casino games: a stake, a luck modifier, a payout banner and
## a confetti burst. Subclasses call settle(won, text) once; `won` is the money
## paid back (0 for a loss), so the net is won - stake. Score is won / (2 x bet).

var bet := 100
var luck := 1.0
var bank_l: Label
var win_l: Label
var extra_stake := 0
var money_now := 0


func setup(p: Dictionary) -> void:
	super.setup(p)
	bet = int(p.get("bet", 100))
	luck = float(p.get("luck", 1.0))
	money_now = int(p.get("money", bet * 3))


func header(title: String) -> void:
	var t := label(title, 24, true, col("gold"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(t, Vector2(0, 6), Vector2(W, 34))
	bank_l = label("Bet  %s" % GameState.fmt_money(bet), 20, true)
	place(bank_l, Vector2(24, 10), Vector2(300, 30))
	win_l = label("", 20, true, col("good"))
	win_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	place(win_l, Vector2(W - 324, 10), Vector2(300, 30))


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
		confetti(46)
		flash_text("BIG WIN  %s" % GameState.fmt_money(won), col("gold"), Vector2(W / 2.0, 200), 54)
	elif won > bet + extra_stake:
		Fx.play("coin")
		confetti(18)
		flash_text("+%s" % GameState.fmt_money(net), col("good"), Vector2(W / 2.0, 220), 44)
	elif won > 0:
		Fx.play("tap")
		flash_text("Paid %s" % GameState.fmt_money(won), col("dim"), Vector2(W / 2.0, 220), 36)
	else:
		Fx.play("bad", 0.05)
		shake(6.0)
		flash_text("Nothing", col("bad"), Vector2(W / 2.0, 220), 40)
	if win_l:
		win_l.text = "Paid  %s" % GameState.fmt_money(won)
	var t := create_tween()
	t.tween_interval(1.9)
	t.tween_callback(func(): finish(clampf(float(won) / (2.0 * float(maxi(1, bet))), 0.0, 1.0), {"won": won, "text": text, "extra": extra_stake}))
