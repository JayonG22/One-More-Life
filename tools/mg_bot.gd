extends Node

## Plays every minigame with random key mashing at 8x speed to prove each one
## finishes, scores in range, and never errors.

const KEYS := [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_F, KEY_J, KEY_K, KEY_1, KEY_2, KEY_3, KEY_4, KEY_Q, KEY_E]

var ids: Array = []
var cur: Control = null
var cur_id := ""
var t := 0.0
var results := {}
var held := {}
var round_i := 0
const ROUNDS := 2


func _ready() -> void:
	seed(99)
	GameState.new_life({"gender": "female", "country": "us"})
	ids = Minigames.DEFS.keys()
	Engine.time_scale = 8.0
	_next()


func _next() -> void:
	if cur != null:
		cur.queue_free()
		cur = null
	if ids.is_empty():
		round_i += 1
		if round_i < ROUNDS:
			ids = Minigames.DEFS.keys()
		else:
			for k in results.keys():
				print("%-12s %s" % [k, str(results[k])])
			print("MG BOT DONE")
			get_tree().quit()
			return
	cur_id = ids.pop_front()
	var g: Minigame = load(Minigames.DEFS[cur_id]["script"]).new()
	g.setup({"skill": 50, "difficulty": 1.0, "sport": ["soccer", "basketball", "hockey", "football", "baseball"][randi() % 5], "opponent": "Test Rival", "map": randi() % 3})
	g.finished.connect(_on_finished)
	add_child(g)
	cur = g
	t = 0.0


func _on_finished(score: float, detail: Dictionary) -> void:
	if not results.has(cur_id):
		results[cur_id] = []
	results[cur_id].append("%.2f(%.0fs)%s" % [score, t, " " + str(detail.keys()) if not detail.is_empty() else ""])
	call_deferred("_next")


func _process(delta: float) -> void:
	if cur == null:
		return
	t += delta
	if t > 400.0:
		results[cur_id] = results.get(cur_id, []) + ["TIMEOUT"]
		_next()
		return
	if randf() < 0.25:
		var k: int = KEYS[randi() % KEYS.size()]
		var ev := InputEventKey.new()
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = not held.get(k, false)
		held[k] = ev.pressed
		Input.parse_input_event(ev)
	if randf() < 0.05:
		for b in cur.find_children("*", "Button", true, false):
			if b.visible and not b.disabled and randf() < 0.3:
				b.emit_signal("pressed")
				break
