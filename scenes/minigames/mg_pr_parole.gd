extends Minigame

## THE BOARD. Five questions from three people who have read your file. Each
## question is listened to for one thing: that you own what you did (remorse), that
## you have used the time (evidence), or that you know where you will sleep on the
## first night (a plan). The board's face shows which. Say that thing, in your own
## words, and you are believed. Say the wrong thing well and you are only politely
## heard. The file you bring (conduct, programmes, denials) sets how far a good
## answer carries.

const ROUNDS := 5
const TONES := ["remorse", "evidence", "plan"]
const CUES := {
	"remorse": [
		"The chair puts her pen down and looks at you for a long time.",
		"The second member turns to the photographs in the file and then up at you.",
		"A woman from the victims' office has not taken her eyes from your hands.",
		"The chair asks, quite softly, whether there is anything you would like to say about that night.",
	],
	"evidence": [
		"The second member turns the pages to your certificates and taps them.",
		"A member asks what, specifically, you have done with the last few years.",
		"The chair has your conduct record open and is running a finger down it.",
		"One of them says, 'Show me, don't tell me.'",
	],
	"plan": [
		"The third member asks where you will sleep on the first night.",
		"The chair wants to know who is waiting, and what they do for a living.",
		"A member says, 'And on the Monday morning?'",
		"The chair leans back and asks what is different about the place you are going to.",
	],
}
const ANSWERS := {
	"remorse": ["I did it. There is no version of it where I didn't, and I have thought about the person every day.", "I was wrong. It isn't an excuse, but I was young and I did not understand what I was doing."],
	"evidence": ["I finished the course, and then the next one. I worked the whole time. The officer on my wing will tell you.", "Four years clean, two certificates, and nothing on my record since the second year."],
	"plan": ["My sister has a room. There is a job with her husband's firm, starting the week after.", "A bed at the hostel, a trade certificate, and a probation officer I have already met."],
}

var round_i := 0
var score_sum := 0.0
var cue_tone := "remorse"
var hint_l: Label
var cue_l: Label
var file_l: Label
var ans_l: Label
var buttons: Array = []
var file_bonus := 0.0
var cues: Array = []
var locked := false
var results: Array = []


func build() -> void:
	make_status()
	hint_l = label("Three people have read your file. Listen to what each is waiting for, then answer that.", 18, true)
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place(hint_l, Vector2(60, 40), Vector2(W - 120, 56))
	var conduct := float(params.get("conduct", 50.0))
	var programs := int(params.get("programs", 0))
	var denied := int(params.get("denied", 0))
	file_bonus = clampf(conduct / 100.0 * 0.12 + float(programs) * 0.03 + float(denied) * 0.01, 0.0, 0.28)
	file_l = label("Your file: conduct %d  ·  %d programme%s  ·  denied %d time%s" % [int(conduct), programs, "" if programs == 1 else "s", denied, "" if denied == 1 else "s"], 16, false, col("dim"))
	file_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(file_l, Vector2(0, 98), Vector2(W, 24))
	cue_l = label("", 24, true)
	cue_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cue_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place(cue_l, Vector2(70, 140), Vector2(W - 140, 90))
	ans_l = label("", 17, false, col("warn"))
	ans_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ans_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place(ans_l, Vector2(70, 238), Vector2(W - 140, 56))
	var names := ["🪞  Own it  [1]", "📄  Show the evidence  [2]", "🏠  Give the plan  [3]"]
	for i in range(3):
		var b := button(names[i], _answer.bind(i), "Primary")
		place(b, Vector2(60 + i * 300, 330), Vector2(280, 74))
		b.tooltip_text = ["Remorse: you own what you did", "Evidence: what you've used the time for", "Plan: where you sleep on the first night"][i]
		buttons.append(b)
	var legend := label("1 or A: remorse  ·  2 or S: evidence  ·  3 or D: plan.   Match the answer to what the board is waiting for.", 15, true)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(legend, Vector2(0, 512), Vector2(W, 24))
	_next()


func _next() -> void:
	if round_i >= ROUNDS:
		var s := clampf(score_sum / float(ROUNDS) + file_bonus * 0.5, 0.0, 1.0)
		finish(s, {"results": results})
		return
	round_i += 1
	locked = false
	cue_tone = TONES[randi() % 3]
	cues.append(cue_tone)
	cue_l.text = str((CUES[cue_tone] as Array)[randi() % (CUES[cue_tone] as Array).size()])
	ans_l.text = ""
	status.text = "Question %d of %d" % [round_i, ROUNDS]


func _answer(i: int) -> void:
	if done or locked:
		return
	locked = true
	var said: String = TONES[i]
	var gain := 0.0
	if said == cue_tone:
		gain = 1.0
		ans_l.text = "“%s”" % str((ANSWERS[said] as Array)[randi() % 2])
		ans_l.add_theme_color_override("font_color", col("good"))
		Fx.play("tap")
	else:
		gain = 0.15 + file_bonus
		ans_l.text = "A polite nod. They write something down. It was not what they were listening for."
		ans_l.add_theme_color_override("font_color", col("warn"))
		Fx.play("bad", 0.05)
	score_sum += gain
	results.append(gain)
	var t := create_tween()
	t.tween_interval(1.1)
	t.tween_callback(_next)


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_1, KEY_A, KEY_LEFT]):
		_answer(0)
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_2, KEY_S, KEY_DOWN]):
		_answer(1)
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_3, KEY_D, KEY_RIGHT]):
		_answer(2)
		get_viewport().set_input_as_handled()
