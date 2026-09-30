extends Minigame

const TYPES := [
	["🤓", "Facts", ["Actually, the numbers say the opposite, and here they are.", "My plan is costed to the last cent. Theirs is a napkin.", "Three independent studies back this up."]],
	["🥺", "Heart", ["Let me tell you about a family I met last week.", "This isn't about politics. It's about our kids.", "I grew up on a street just like yours."]],
	["😤", "Attack", ["My opponent has changed their mind four times this year.", "That's rich coming from someone who skipped every vote.", "Where were you when this town needed you?"]],
]
const JABS := [
	"\"My opponent has no real plan for jobs.\"", "\"Taxes will go up if they win.\"", "\"They don't understand working people.\"",
	"\"Crime doubled on their watch.\"", "\"They're a puppet for big donors.\"", "\"Their experience is a joke.\"",
	"\"Nobody even knows what they stand for.\"",
]
const CROWD_WANTS := [
	[["🤓", "\"Show me the numbers.\""], ["🧐", "\"Facts, please.\""], ["📊", "\"How will you pay for it?\""]],
	[["🥺", "\"Talk to us like people.\""], ["❤️", "\"Do you even care?\""], ["😢", "\"My family's struggling.\""]],
	[["😤", "\"Hit back!\""], ["🔥", "\"Don't let them walk over you!\""], ["👊", "\"Fight for us!\""]],
]
const FLAVORS := {
	"pitch": {"who": "💼  Investor:", "jabs": ["\"What's your burn rate?\"", "\"Why won't a big company just copy you?\"", "\"Your valuation is a fantasy.\"", "\"Who's actually buying this?\"", "\"I've seen a hundred pitches like this.\"", "\"What happens if you fail?\""],
		"types": [["📊", "Numbers", ["Revenue grew every quarter. Here's the chart.", "Our margins beat the industry average.", "Customer cost is falling, lifetime value is rising."]],
			["✨", "Vision", ["Picture a world where everyone uses this.", "This isn't a product. It's a movement.", "I built this because my family needed it."]],
			["🦈", "Hardball", ["Take it or leave it. Another fund wants in.", "The price goes up tomorrow.", "You'll regret passing on this."]]],
		"wants": [[["🧐", "\"Show me the numbers.\""], ["📈", "\"What's the growth?\""], ["🧮", "\"Margins?\""]], [["🤔", "\"Why does this matter?\""], ["💭", "\"What's the big picture?\""], ["❤️", "\"Why you?\""]], [["😏", "\"Convince me you're serious.\""], ["⏱️", "\"Is there a deadline?\""], ["🦈", "\"Prove you can negotiate.\""]]]},
	"royal": {"who": "📰  The tabloids:", "jabs": ["\"Is the monarchy worth what it costs us?\"", "\"Your family is out of touch.\"", "\"Why should anyone bow to you?\"", "\"The palace is hiding something.\"", "\"Abolish the crown!\""],
		"types": [["📜", "Tradition", ["Our history is your history. It belongs to all of us.", "A thousand years of continuity, in a changing world.", "The crown stands above politics, for everyone."]],
			["🤝", "Service", ["I will spend my life serving you.", "Last year we raised millions for children's hospitals.", "I have met your nurses, your soldiers, your teachers."]],
			["👑", "Authority", ["The crown does not answer to gossip.", "Order and dignity are not negotiable.", "I will not be lectured by the press."]]],
		"wants": [[["🏛️", "\"Respect our history.\""], ["🎖️", "\"Honor the veterans.\""], ["📜", "\"Keep the traditions.\""]], [["🙋", "\"What do you actually do for us?\""], ["❤️", "\"Show you care.\""], ["🏥", "\"Help the people.\""]], [["😠", "\"Stand up to the critics!\""], ["👑", "\"Lead!\""], ["🦁", "\"Show some strength!\""]]]},
	"sermon": {"who": "🙋  A doubter:", "jabs": ["\"How do we know you're telling the truth?\"", "\"My family says this is a cult.\"", "\"Where does the money go?\"", "\"The prophecy didn't come true.\"", "\"Why do you get the big house?\"", "\"I'm thinking about leaving.\""],
		"types": [["📜", "Scripture", ["It is written in the first teaching. Read it with me.", "The signs were foretold, and they are here.", "Our doctrine has never been wrong."]],
			["🤗", "Love", ["You are family here. You were alone before.", "I see you. I have always seen you.", "Nobody out there loves you like we do."]],
			["🔥", "Fear", ["Out there, only darkness waits.", "Those who leave are lost forever.", "The end is closer than you think."]]],
		"wants": [[["📖", "\"Teach us.\""], ["🧐", "\"Explain the signs.\""], ["🕯️", "\"What does it say?\""]], [["🥺", "\"I feel so alone.\""], ["🫂", "\"Hold us close.\""], ["😢", "\"I need comfort.\""]], [["😨", "\"What happens to us?\""], ["⚡", "\"Warn us!\""], ["🙏", "\"Save us!\""]]]},
}
const LENGTH := 42.0
const COLORS := [Color("4a90e2"), Color("e85d9a"), Color("e2493b")]
const COST := 30.0

var jabs: Array = JABS
var types: Array = TYPES
var who := "🧑‍💼  Opponent"
var mood := 0
var next_mood := 1
var mood_t := 0.0
var meter := 50.0
var breath := 100.0
var zing_t := 0.0
var zing_in := 6.0
var zinging := false
var zing_len := 1.4
var rebut_ok := false
var said := ""
var said_t := 0.0
var landed := 0
var mood_cards: Array[Button] = []


func build() -> void:
	make_status()
	if FLAVORS.has(params.get("flavor", "")):
		var f: Dictionary = FLAVORS[params["flavor"]]
		jabs = f["jabs"]
		types = f["types"]
		who = str(f["who"]).trim_suffix(":")
	mood = randi() % 3
	next_mood = (mood + 1 + randi() % 2) % 3
	mood_t = randf_range(3.0, 4.5)
	zing_in = randf_range(4.0, 6.0)
	zing_len = 1.5 / difficulty
	for i in range(3):
		var tp: Array = types[i]
		var b := button("%s %s  [%d]" % [tp[0], tp[1], i + 1], _argue.bind(i), "Row")
		b.add_theme_font_size_override("font_size", 22)
		place(b, Vector2(60 + i * 300, 452), Vector2(280, 70))
		mood_cards.append(b)
	var rb := button("🛡️ Rebut  [Space]", _rebut, "Primary")
	place(rb, Vector2(380, 372), Vector2(240, 56))


func _argue(i: int) -> void:
	if done:
		return
	if breath < COST:
		meter -= 1.5
		Fx.play("error")
		flash_text("Out of breath…", col("warn"), Vector2(W / 2, 300), 24)
		return
	breath -= COST
	var lines: Array = types[i][2]
	said = lines[randi() % lines.size()]
	said_t = 2.0
	if i == mood:
		meter += 5.5
		landed += 1
		Fx.play("crowd", 0.5)
		flash_text("👏", COLORS[i], Vector2(W / 2 + randf_range(-200, 200), 250), 40)
	else:
		meter -= 5.0
		Fx.play("bad", 0.4)
		flash_text("😒", col("bad"), Vector2(W / 2 + randf_range(-200, 200), 250), 40)


func _rebut() -> void:
	if done:
		return
	if zinging and zing_t >= zing_len * 0.55:
		zinging = false
		zing_in = randf_range(4.5, 7.5) / difficulty
		meter += 9.0
		Fx.play("good")
		flash_text("🛡️ Shut down!", col("good"), Vector2(W / 2, 300), 30)
	elif zinging:
		zinging = false
		zing_in = randf_range(4.5, 7.5) / difficulty
		meter -= 6.0
		Fx.play("bad")
		flash_text("Too early!", col("bad"), Vector2(W / 2, 300), 28)
	else:
		breath = maxf(0.0, breath - 10.0)
		Fx.play("error")


func _process(delta: float) -> void:
	if done:
		return
	elapsed += delta
	breath = minf(100.0, breath + 30.0 * delta)
	meter -= (2.0 + elapsed * 0.04) * difficulty * delta
	mood_t -= delta
	if mood_t <= 0:
		mood = next_mood
		next_mood = (mood + 1 + randi() % 2) % 3
		mood_t = randf_range(2.4, 4.4) / difficulty
		Fx.play("whoosh", 0.4)
	if zinging:
		zing_t += delta
		if zing_t >= zing_len:
			zinging = false
			zing_in = randf_range(4.5, 7.5) / difficulty
			meter -= 11.0
			said = jabs[randi() % jabs.size()]
			said_t = 2.2
			Fx.play("bad")
			flash_text("💥 Ouch.", col("bad"), Vector2(W / 2, 300), 30)
	else:
		zing_in -= delta
		if zing_in <= 0:
			zinging = true
			zing_t = 0.0
	said_t -= delta
	meter = clampf(meter, 0.0, 100.0)
	for i in range(3):
		mood_cards[i].modulate = Color(1, 1, 1, 1) if breath >= COST else Color(1, 1, 1, 0.55)
	status.text = "%ds left   ·   crowd wants %s %s   ·   next: %s" % [int(ceil(LENGTH - elapsed)), types[mood][0], types[mood][1], types[next_mood][0] if mood_t < 1.2 else "?"]
	queue_redraw()
	if meter >= 100.0:
		Fx.play("fanfare")
		finish(1.0, {"crowd": 100, "landed": landed})
	elif meter <= 0.0:
		Fx.play("bad")
		finish(0.0, {"crowd": 0, "landed": landed})
	elif elapsed >= LENGTH:
		finish(meter / 100.0, {"crowd": int(meter), "landed": landed})


func _draw() -> void:
	var fnt := ThemeManager.font_regular
	var cx := 500.0
	draw_rect(Rect2(40, 48, 920, 120), Color(COLORS[mood], 0.22))
	for i in range(14):
		var face: String = "😃" if meter > 60 else ("😐" if meter > 35 else "😠")
		draw_string(fnt, Vector2(70 + i * 64, 108 + (i % 2) * 18), face, HORIZONTAL_ALIGNMENT_LEFT, -1, 34)
	draw_string(fnt, Vector2(cx - 34, 160), types[mood][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 58)
	var ry := 205.0
	draw_rect(Rect2(90, ry - 3, 820, 6), col("track"))
	var kx := 90.0 + meter / 100.0 * 820.0
	draw_rect(Rect2(90, ry - 3, kx - 90, 6), col("good"))
	draw_circle(Vector2(kx, ry), 14, col("text"))
	draw_string(fnt, Vector2(30, ry + 14), "😰", HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	draw_string(fnt, Vector2(924, ry + 14), "🏆", HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	if said_t > 0:
		draw_string(fnt, Vector2(90, 262), said, HORIZONTAL_ALIGNMENT_LEFT, 820, 18, col("dim"))
	for i in range(3):
		draw_rect(Rect2(60 + i * 300, 524, 280, 8), COLORS[i])
		if i == mood:
			draw_rect(Rect2(56 + i * 300, 448, 288, 88), COLORS[i], false, 3.0)
	bar_rect(Rect2(60, 432, 880, 10), breath / 100.0, col("accent") if breath >= COST else col("warn"), col("track"))
	draw_string(fnt, Vector2(60, 426), "Breath", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col("dim"))
	if zinging:
		var zp := zing_t / zing_len
		var zc := col("good") if zp >= 0.55 else col("bad")
		draw_string(fnt, Vector2(640, 392), "%s is winding up… 💢" % who, HORIZONTAL_ALIGNMENT_LEFT, 320, 16, zc)
		bar_rect(Rect2(640, 404, 300, 14), zp, zc, col("track"))
		draw_rect(Rect2(640 + 300 * 0.55, 400, 2, 22), col("text"))


func _unhandled_input(event: InputEvent) -> void:
	for i in range(3):
		if key_pressed(event, [KEY_1 + i, KEY_KP_1 + i]):
			_argue(i)
			get_viewport().set_input_as_handled()
			return
	if key_pressed(event, [KEY_SPACE]):
		_rebut()
		get_viewport().set_input_as_handled()
