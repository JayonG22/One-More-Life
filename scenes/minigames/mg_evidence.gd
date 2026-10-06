extends Minigame

## Evidence Board: read a case note, then connect the clue to the most defensible
## inference. Wrong links stay on the board and cost credibility; fast correct
## links build a coherent theory without rewarding random clicking.

const ROUNDS := 7
const CASES := [
	["Door camera skips 02:13–02:17", ["Someone disabled or bypassed the camera", "The victim forgot the password", "It proves the suspect was inside"], 0],
	["A receipt is timestamped across town", ["It is an alibi worth checking", "It automatically clears the suspect", "It proves the receipt is fake"], 0],
	["The witness changes one detail", ["Re-interview and compare the timeline", "Charge the witness with lying", "Discard everything they said"], 0],
	["A phone ping lands near the scene", ["Corroborate it with other evidence", "Treat the phone owner as guilty", "Ignore digital records entirely"], 0],
	["Two shoe prints overlap", ["Separate the impressions before comparing", "Assume they came from one person", "Arrest both shoe owners"], 0],
	["A deleted message is recovered", ["Verify sender, time and context", "Read motive into one sentence", "Publish it to pressure a confession"], 0],
	["A suspect knows a fact not released publicly", ["Document how they could know it", "Call it a confession immediately", "Tell the media before checking"], 0],
	["A DNA trace is only a partial match", ["Treat it as supporting, not conclusive", "Call it certain identification", "Throw it away as useless"], 0],
	["Cash deposits begin after the incident", ["Trace the source and timing", "Assume every deposit is criminal", "Freeze the account without paperwork"], 0],
	["The timeline has a twelve-minute gap", ["Look for records that can fill the gap", "Invent the most likely sequence", "Ignore it because the rest fits"], 0],
]

var deck: Array = []
var round_i := 0
var correct := 0
var wrong := 0
var time_left := 32.0
var prompt: Label
var buttons: Array[Button] = []
var history: Array = []


func build() -> void:
	make_status()
	var title := label("🧩  "+str(params.get("title","EVIDENCE BOARD")).to_upper(), 30, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(title, Vector2(0, 48), Vector2(W, 44))
	var tip := label("Connect each clue to the strongest defensible inference.  1 / 2 / 3", 17)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(tip, Vector2(0, 94), Vector2(W, 30))
	prompt = label("", 23, true)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place(prompt, Vector2(110, 150), Vector2(780, 72))
	for i in range(3):
		var b := button("", _choose.bind(i), "Primary")
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		place(b, Vector2(170, 250 + i * 78), Vector2(660, 60))
		buttons.append(b)
	deck = (params.get("cases",CASES) as Array).duplicate(true)
	deck.shuffle()
	deck = deck.slice(0, ROUNDS)
	_next()


func _next() -> void:
	if round_i >= deck.size():
		_finish_board()
		return
	var row: Array = deck[round_i]
	prompt.text = "📌  " + str(row[0])
	var choices: Array = row[1].duplicate()
	var correct_text: String = choices[int(row[2])]
	choices.shuffle()
	for i in range(3):
		buttons[i].text = "%d  ·  %s" % [i + 1, choices[i]]
		buttons[i].set_meta("correct", choices[i] == correct_text)
		buttons[i].disabled = false
	status.text = "Link %d / %d   ·   Correct %d   ·   Time %.0fs" % [round_i + 1, ROUNDS, correct, time_left]


func _choose(i: int) -> void:
	if done or i < 0 or i >= buttons.size():
		return
	for b in buttons:
		b.disabled = true
	var ok := bool(buttons[i].get_meta("correct", false))
	if ok:
		correct += 1
		history.append("solid")
		Fx.play("good")
		flash_text("✓ defensible link", col("good"), Vector2(W / 2, 205), 27)
	else:
		wrong += 1
		history.append("forced")
		time_left = maxf(0.0, time_left - 2.0 * difficulty)
		Fx.play("bad")
		flash_text("× weak inference", col("bad"), Vector2(W / 2, 205), 27)
	round_i += 1
	get_tree().create_timer(0.55).timeout.connect(_next)


func _finish_board() -> void:
	var accuracy := float(correct) / maxf(1.0,float(deck.size()))
	var speed_bonus := clampf(time_left / 32.0, 0.0, 1.0) * 0.15
	var penalty := float(wrong) * 0.025
	finish(clampf(accuracy * 0.85 + speed_bonus - penalty, 0.0, 1.0), {"correct":correct,"wrong":wrong,"links":history})


func _process(delta: float) -> void:
	if done:
		return
	time_left -= delta * difficulty
	status.text = "Link %d / %d   ·   Correct %d   ·   Time %.0fs" % [mini(round_i + 1, ROUNDS), ROUNDS, correct, maxf(0,time_left)]
	if time_left <= 0.0:
		_finish_board()


func _unhandled_input(event: InputEvent) -> void:
	var keys := [KEY_1, KEY_2, KEY_3]
	for i in range(3):
		if key_pressed(event, [keys[i]]):
			_choose(i)
			get_viewport().set_input_as_handled()
			return
