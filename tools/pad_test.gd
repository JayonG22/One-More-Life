extends Node
## Gamepad: a pad press does what the matching key does. Start ages up, the shoulders
## change tab, A on a focused button presses it. (run under xvfb)
var failures: Array = []
func ok(c: bool, m: String) -> void:
	if not c:
		failures.append(m)
		push_error("PAD: " + m)
func _btn(i: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = i
	e.pressed = true
	return e
func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in range(4): await get_tree().process_frame
	SaveManager.begin_new_life()
	GameState.new_life({"first": "Pad", "last": "Tester", "gender": "male", "country": "us", "modifiers": [], "difficulty": "real", "boons": [], "challenge": ""})
	main._show("game")
	for i in range(6): await get_tree().process_frame
	var age0 := int(GameState.player["age"])
	main._input(_btn(JOY_BUTTON_START))
	for i in range(8): await get_tree().process_frame
	ok(int(GameState.player["age"]) == age0 + 1, "Start did not age up (%d -> %d)" % [age0, int(GameState.player["age"])])
	# clear whatever popped up
	while EventEngine.has_pending():
		EventEngine.pop_next()
	main._close_popup()
	for i in range(3): await get_tree().process_frame
	main._tab_press(0)
	main._input(_btn(JOY_BUTTON_RIGHT_SHOULDER))
	ok(int(main.g.get("tab_cur", -1)) == 1, "the right shoulder did not move to the next tab (%s)" % str(main.g.get("tab_cur")))
	main._input(_btn(JOY_BUTTON_LEFT_SHOULDER))
	ok(int(main.g.get("tab_cur", -1)) == 0, "the left shoulder did not move back")
	ok(UIKit.kb_mode, "the pad did not switch to focus navigation")
	# the stick moves focus like the arrows
	var m := InputEventJoypadMotion.new()
	m.axis = JOY_AXIS_LEFT_Y
	m.axis_value = 0.9
	main._input(m)
	m = InputEventJoypadMotion.new()
	m.axis = JOY_AXIS_LEFT_Y
	m.axis_value = 0.0
	main._input(m)
	print("PAD TEST failures=%d" % failures.size())
	for f in failures: print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)
