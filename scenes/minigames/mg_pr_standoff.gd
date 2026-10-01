extends Minigame

## TALKING SOMEONE DOWN. He has someone, or something, and he is not going to put
## it down because you ask. Each turn he says one thing, and what he says tells
## you what he needs: to be LISTENED to, to be given a REASON, or to be OFFERED
## something he can have. Give him that and the temperature falls. Give him the
## wrong thing, or threaten him, and it climbs. Eight turns.

const TURNS := 8
const LINES := {
	"listen": ["Nobody in this place has ever listened to me. Not once.", "You people don't hear a word. I've been saying it for a year.", "I'm not talking to the ones with the keys. They never listen.", "Just let me say it. Let me say the whole thing."],
	"reason": ["Why should I believe a word you tell me?", "How do I know you're not going to rush me the second I put it down?", "What's the point? Give me one good reason why it ends well.", "Prove it. Prove to me you're not lying."],
	"offer": ["I want to speak to my daughter. That's all I want.", "Give me a phone. Give me ten minutes with my brother and it's over.", "I want a transfer, and I want it in writing, right now.", "Get the chaplain. I'll talk to the chaplain, nobody else."],
}
const MOVES := ["listen", "reason", "offer", "threaten"]
const NAMES := ["👂  Listen  [1]", "🧠  Give a reason  [2]", "🎁  Offer something  [3]", "⚠️  Threaten  [4]"]

var agitation := 72.0
var trust := 8.0
var turn := 0
var need := "listen"
var quote_l: Label
var hint_l: Label
var ag_rect := Rect2(80, 170, 400, 22)
var tr_rect := Rect2(520, 170, 400, 22)
var locked := false
var history: Array = []


func build() -> void:
	make_status()
	hint_l = label("Listen to what he says. It tells you what he needs: to be heard, given a reason, or offered something.", 18, true)
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place(hint_l, Vector2(50, 40), Vector2(W - 100, 54))
	var a := label("🔥 Agitation (needs to fall)", 17, true)
	place(a, Vector2(80, 138), Vector2(400, 26))
	var t := label("🤝 Trust (needs to rise)", 17, true)
	place(t, Vector2(520, 138), Vector2(400, 26))
	quote_l = label("", 26, true)
	quote_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place(quote_l, Vector2(70, 212), Vector2(W - 140, 100))
	for i in range(4):
		var b := button(NAMES[i], _move.bind(i), "Primary" if i < 3 else "Row")
		place(b, Vector2(40 + i * 236, 390), Vector2(224, 64))
		b.tooltip_text = ["For someone who has not been heard", "For someone who is afraid it's a trick", "For someone who wants a specific thing", "Almost never works"][i]
	var legend := label("1 / A listen  ·  2 / S reason  ·  3 / D offer  ·  4 / F threaten.   Match your move to what he is asking for.", 15, true)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(legend, Vector2(0, 512), Vector2(W, 24))
	_next()


func _next() -> void:
	if turn >= TURNS or agitation <= 10.0 and trust >= 60.0:
		_end()
		return
	turn += 1
	locked = false
	need = ["listen", "reason", "offer"][randi() % 3]
	quote_l.text = "“%s”" % str((LINES[need] as Array)[randi() % 4])
	status.text = "Turn %d of %d" % [turn, TURNS]
	queue_redraw()


func _move(i: int) -> void:
	if done or locked:
		return
	locked = true
	var m: String = MOVES[i]
	if m == "threaten":
		agitation = minf(100.0, agitation + 22.0)
		trust = maxf(0.0, trust - 14.0)
		Fx.play("bad")
	elif m == need:
		agitation = maxf(0.0, agitation - 17.0 * (1.0 if difficulty <= 1.0 else 0.85))
		trust = minf(100.0, trust + 16.0)
		Fx.play("tap")
	else:
		agitation = minf(100.0, agitation + 5.0)
		trust = maxf(0.0, trust - 2.0)
		Fx.play("bad", 0.05)
	queue_redraw()
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_callback(_next)


func _end() -> void:
	var s := clampf((100.0 - agitation) / 100.0 * 0.5 + trust / 100.0 * 0.5, 0.0, 1.0)
	finish(s, {"agitation": agitation, "trust": trust, "calm": agitation <= 25.0 and trust >= 55.0})


func _draw() -> void:
	bar_rect(ag_rect, agitation / 100.0, col("bad"), col("track"))
	bar_rect(tr_rect, trust / 100.0, col("good"), col("track"))


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_1, KEY_A]):
		_move(0)
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_2, KEY_S]):
		_move(1)
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_3, KEY_D]):
		_move(2)
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_4, KEY_F]):
		_move(3)
		get_viewport().set_input_as_handled()
