extends MinigameGamble

## SCRATCH CARD. Nine squares under foil. Find three of the same symbol to win
## what it pays. The result is printed on the card before you touch it; the fun is
## in the scratching, and in two out of three being the cruelest sight in gambling.

const SYM := ["🍀", "🍒", "💎", "👑", "🔔", "⭐"]
const PAY := {"🍀": 2.0, "🍒": 3.0, "🔔": 5.0, "⭐": 10.0, "💎": 25.0, "👑": 100.0}
const WEIGHT := {"🍀": 40, "🍒": 28, "🔔": 16, "⭐": 10, "💎": 5, "👑": 1}

var cells: Array = []
var symbols: Array = []
var revealed: Array = []
var win_sym := ""
var msg_l: Label
var all_btn: Button


func build() -> void:
	header("🎟️  Scratch card")
	msg_l = label("Scratch the squares: click, or press 1–9. Three of a kind wins.", 18, true)
	msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(msg_l, Vector2(0, 44), Vector2(W, 30))
	_print_card()
	for i in range(9):
		var b := button("", _scratch.bind(i), "Row")
		b.text = "🪙"
		b.add_theme_font_size_override("font_size", 52)
		place(b, Vector2(W / 2.0 - 250 + (i % 3) * 170, 88 + (i / 3) * 110), Vector2(160, 100))
		cells.append(b)
		revealed.append(false)
	all_btn = button("Scratch all  [Space]", _all, "Accent")
	place(all_btn, Vector2(W / 2.0 - 140, 440), Vector2(280, 56))


func _print_card() -> void:
	symbols.clear()
	var wins := rolled(0.155)
	if wins:
		var tot := 0
		for k in WEIGHT.keys():
			tot += int(WEIGHT[k])
		var r := randi() % tot
		var acc := 0
		for k in WEIGHT.keys():
			acc += int(WEIGHT[k])
			if r < acc:
				win_sym = k
				break
		for _i in range(3):
			symbols.append(win_sym)
	var pool: Dictionary = {}
	while symbols.size() < 9:
		var s: String = SYM[randi() % SYM.size()]
		if s == win_sym:
			continue
		if int(pool.get(s, 0)) >= 2:
			continue
		pool[s] = int(pool.get(s, 0)) + 1
		symbols.append(s)
	symbols.shuffle()


func _scratch(i: int) -> void:
	if done or revealed[i]:
		return
	revealed[i] = true
	var b: Button = cells[i]
	b.pivot_offset = Vector2(80, 50)
	var tw := create_tween()
	tw.tween_property(b, "scale:x", 0.0, 0.1)
	tw.tween_callback(func(): b.text = str(symbols[i]))
	tw.tween_property(b, "scale:x", 1.0, 0.1)
	Fx.play("tap", 0.12)
	var n := 0
	for r in revealed:
		if r:
			n += 1
	# the tease
	var counts: Dictionary = {}
	for k in range(9):
		if revealed[k]:
			counts[symbols[k]] = int(counts.get(symbols[k], 0)) + 1
	for k2 in counts.keys():
		if int(counts[k2]) == 2:
			msg_l.text = "Two %s… " % k2
	if n >= 9:
		_end()


func _all() -> void:
	for i in range(9):
		if not revealed[i]:
			_scratch(i)


func _end() -> void:
	if win_sym != "":
		for i in range(9):
			if symbols[i] == win_sym:
				(cells[i] as Button).modulate = Color(1.5, 1.4, 0.5)
		var m: float = float(PAY[win_sym])
		msg_l.text = "Three %s!  %s×" % [win_sym, str(m)]
		settle(int(bet * m), "Three %s on the scratch card." % win_sym)
	else:
		msg_l.text = "No match."
		settle(0, "The scratch card was a dud.")


func _unhandled_input(event: InputEvent) -> void:
	for k in range(9):
		if key_pressed(event, [KEY_1 + k, KEY_KP_1 + k]):
			_scratch(k)
			get_viewport().set_input_as_handled()
			return
	if key_pressed(event, [KEY_SPACE, KEY_ENTER]):
		_all()
		get_viewport().set_input_as_handled()
