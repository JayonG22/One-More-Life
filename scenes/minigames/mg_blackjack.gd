extends Minigame

const SUITS := ["♠", "♥", "♦", "♣"]
const RANKS := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

var shoe: Array = []
var me: Array = []
var dealer: Array = []
var phase := "play"
var doubled := false
var can_double := true
var hit_b: Button
var stand_b: Button
var dbl_b: Button
var msg := ""
var reveal_t := 0.0


func build() -> void:
	make_status()
	can_double = bool(params.get("can_double", true))
	for d in range(4):
		for s in range(4):
			for r in range(13):
				shoe.append([r, s])
	shoe.shuffle()
	me = [_draw_card(), _draw_card()]
	dealer = [_draw_card(), _draw_card()]
	hit_b = button("Hit  [H / 1]", _hit, "Primary")
	place(hit_b, Vector2(160, 460), Vector2(210, 60))
	stand_b = button("Stand  [S / 2]", _stand, "Row")
	place(stand_b, Vector2(395, 460), Vector2(210, 60))
	dbl_b = button("Double  [D / 3]", _double, "Row")
	place(dbl_b, Vector2(630, 460), Vector2(210, 60))
	dbl_b.disabled = not can_double
	if total(me) == 21 or total(dealer) == 21:
		_settle()
	queue_redraw()


func _draw_card() -> Array:
	if shoe.is_empty():
		for s in range(4):
			for r in range(13):
				shoe.append([r, s])
		shoe.shuffle()
	return shoe.pop_back()


static func value(c: Array) -> int:
	var r := int(c[0])
	if r == 0:
		return 11
	return mini(r + 1, 10)


static func total(hand: Array) -> int:
	var t := 0
	var aces := 0
	for c in hand:
		t += value(c)
		if int(c[0]) == 0:
			aces += 1
	while t > 21 and aces > 0:
		t -= 10
		aces -= 1
	return t


func _hit() -> void:
	if done or phase != "play":
		return
	me.append(_draw_card())
	dbl_b.disabled = true
	Fx.play("page", 0.3)
	if total(me) > 21:
		_settle()
	elif total(me) == 21:
		_stand()
	queue_redraw()


func _double() -> void:
	if done or phase != "play" or me.size() != 2 or not can_double:
		return
	doubled = true
	me.append(_draw_card())
	Fx.play("coin", 0.4)
	_stand()


func _stand() -> void:
	if done or phase != "play":
		return
	phase = "dealer"
	reveal_t = 0.6
	for b in [hit_b, stand_b, dbl_b]:
		b.disabled = true
	queue_redraw()


func _process(delta: float) -> void:
	if done:
		return
	status.text = "Bet %s%s   ·   Dealer stands on 17   ·   Blackjack pays 3:2" % [GameState.fmt_money(int(params.get("bet", 0))), " (doubled)" if doubled else ""]
	if phase == "dealer":
		reveal_t -= delta
		if reveal_t <= 0:
			if total(dealer) < 17 and total(me) <= 21:
				dealer.append(_draw_card())
				Fx.play("page", 0.3)
				reveal_t = 0.6
			else:
				_settle()
			queue_redraw()
	elif phase == "over":
		reveal_t -= delta
		if reveal_t <= 0:
			_finish_now()


func _settle() -> void:
	phase = "over"
	reveal_t = 1.6
	for b in [hit_b, stand_b, dbl_b]:
		b.disabled = true
	var mt := total(me)
	var dt := total(dealer)
	var me_bj := mt == 21 and me.size() == 2
	var d_bj := dt == 21 and dealer.size() == 2
	if me_bj and not d_bj:
		msg = "blackjack"
	elif mt > 21:
		msg = "lose"
	elif d_bj and not me_bj:
		msg = "lose"
	elif dt > 21 or mt > dt:
		msg = "win"
	elif mt == dt:
		msg = "push"
	else:
		msg = "lose"
	Fx.play("fanfare" if msg in ["win", "blackjack"] else ("coin" if msg == "push" else "bad"))
	queue_redraw()


func _finish_now() -> void:
	var s: float = {"blackjack": 1.0, "win": 0.85, "push": 0.5, "lose": 0.1}[msg]
	finish(s, {"result": msg, "doubled": doubled, "me": total(me), "dealer": total(dealer)})


func _card(pos: Vector2, c: Array, hidden: bool) -> void:
	var fnt := ThemeManager.font_bold
	var r := Rect2(pos, Vector2(84, 118))
	draw_rect(r, col("surface2") if hidden else Color.WHITE)
	draw_rect(r, col("border"), false, 2.0)
	if hidden:
		draw_string(fnt, pos + Vector2(26, 72), "🂠", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, col("dim"))
		return
	var red := int(c[1]) in [1, 2]
	var cc := Color("c0392b") if red else Color("1b2433")
	draw_string(fnt, pos + Vector2(8, 30), RANKS[int(c[0])], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, cc)
	draw_string(fnt, pos + Vector2(28, 88), SUITS[int(c[1])], HORIZONTAL_ALIGNMENT_LEFT, -1, 40, cc)


func _draw() -> void:
	var fnt := ThemeManager.font_regular
	var hide := phase == "play"
	draw_string(fnt, Vector2(160, 70), "Dealer" + ("" if hide else "  ·  %d" % total(dealer)), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col("dim"))
	for i in range(dealer.size()):
		_card(Vector2(160 + i * 96, 84), dealer[i], hide and i == 1)
	draw_string(fnt, Vector2(160, 250), "You  ·  %d" % total(me), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col("dim"))
	for i in range(me.size()):
		_card(Vector2(160 + i * 96, 264), me[i], false)
	if phase == "over":
		var t: String = {"blackjack": "🃏 BLACKJACK!", "win": "✅ You win", "push": "🤝 Push", "lose": "❌ Dealer wins"}[msg]
		draw_string(ThemeManager.font_bold, Vector2(640, 240), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, col("good") if msg in ["win", "blackjack"] else (col("warn") if msg == "push" else col("bad")))


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_H, KEY_1, KEY_KP_1]):
		_hit()
	elif key_pressed(event, [KEY_S, KEY_2, KEY_KP_2, KEY_SPACE]):
		_stand()
	elif key_pressed(event, [KEY_D, KEY_3, KEY_KP_3]):
		_double()
	else:
		return
	get_viewport().set_input_as_handled()
