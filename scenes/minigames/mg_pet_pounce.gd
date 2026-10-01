extends Minigame

## STALK AND POUNCE. The prey peeks out of one of three holes. A hole rustles
## just before it shows, so the hunter who watches always has time to be there.
## Pounce on the right hole while it is out. Pounce on an empty one and the
## prey gets wary: it stays out for less time.

const ROUNDS := 8
const HOLES := 3

var prey_icon := "🐭"
var hunter_icon := "🐈"
var round_i := 0
var state := "wait"          # wait, rustle, up
var cur := 0
var state_t := 1.2
var caught := 0
var missed := 0
var wary := 0.0
var holes: Array = []
var hint_l: Label
var tally_l: Label
var btns: Array = []


func build() -> void:
	var sp: Dictionary = Pets.SPECIES.get(str(params.get("species", "cat")), Pets.SPECIES["cat"])
	hunter_icon = str(sp["icon"])
	prey_icon = {"dog": "🐿️", "cat": "🐭", "rabbit": "🌼", "parrot": "🌰", "horse": "🍎"}.get(str(params.get("species", "cat")), "🐭")
	make_status()
	hint_l = label("", 21, true)
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(hint_l, Vector2(40, 52), Vector2(W - 80, 60))
	for i in range(HOLES):
		var l := label("🕳️", 84)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		place(l, Vector2(130 + i * 280, 180), Vector2(200, 120))
		holes.append(l)
		var b := button("%s  Pounce  [%s]" % [["◀", "▼", "▶"][i], ["A", "S", "D"][i]], _pounce.bind(i), "Accent")
		place(b, Vector2(130 + i * 280, 360), Vector2(200, 64))
		b.tooltip_text = "Pounce on this hole"
		btns.append(b)
	var hl := label(hunter_icon, 56)
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(hl, Vector2(W / 2 - 40, 440), Vector2(80, 70))
	tally_l = label("", 18, false, col("dim"))
	tally_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(tally_l, Vector2(0, 8), Vector2(W, 28))
	var legend := label("A / ← left hole   ·   S / ↓ middle   ·   D / → right.   A hole that shakes is about to open.", 15, true)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(legend, Vector2(0, 510), Vector2(W, 24))
	_next()


func _next() -> void:
	if round_i >= ROUNDS:
		finish(float(caught) / float(ROUNDS), {"caught": caught, "missed": missed})
		return
	round_i += 1
	state = "wait"
	state_t = randf_range(0.7, 1.4) / difficulty
	cur = randi() % HOLES
	for h in holes:
		(h as Label).text = "🕳️"
		(h as Label).position.x = (h as Label).position.x
	hint_l.text = "Crouch. Something is nearby. Watch the holes."


func _pounce(i: int) -> void:
	if done:
		return
	if state == "up" and i == cur:
		caught += 1
		Fx.play("tap")
		flash_text("Got it!", col("good"), Vector2(130 + i * 280 + 100, 140))
		(holes[cur] as Label).text = "🕳️"
		state = "wait"
		state_t = 0.01
		_after()
	elif state == "up" or state == "wait" or state == "rustle":
		wary += 0.12
		Fx.play("bad", 0.05)
		flash_text("Nothing there", col("warn"), Vector2(130 + i * 280 + 100, 140), 24)


func _after() -> void:
	status.text = "Prey %d of %d  ·  caught %d" % [round_i, ROUNDS, caught]
	_next()


func _process(delta: float) -> void:
	if done:
		return
	state_t -= delta
	status.text = "Prey %d of %d  ·  caught %d" % [round_i, ROUNDS, caught]
	match state:
		"wait":
			if state_t <= 0.0:
				state = "rustle"
				state_t = 0.55 / difficulty
				hint_l.text = "A hole is shaking…"
		"rustle":
			var h: Label = holes[cur]
			h.text = "〰️"
			if state_t <= 0.0:
				state = "up"
				state_t = maxf(0.55, (1.15 - wary - 0.12 * (difficulty - 0.7)) / difficulty)
				h.text = prey_icon
				hint_l.text = "NOW! Pounce on the hole with the %s." % prey_icon
		"up":
			if state_t <= 0.0:
				missed += 1
				(holes[cur] as Label).text = "💨"
				hint_l.text = "It got away."
				state = "wait"
				state_t = 0.01
				_after()


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_A, KEY_LEFT, KEY_1]):
		_pounce(0)
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_S, KEY_DOWN, KEY_2]):
		_pounce(1)
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_D, KEY_RIGHT, KEY_3]):
		_pounce(2)
		get_viewport().set_input_as_handled()
