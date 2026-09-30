extends Node

## Drives Fight Night through the REAL main scene with REAL input events, to
## find out whether the boxing controls actually reach the game.

var main: Control
var log_lines: Array = []


func _ready() -> void:
	seed(808)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(4)
	main._open_new_life()
	main.nl["country"] = "us"
	main.nl["first"] = "Ring"
	main.nl["last"] = "Test"
	main._start_life()
	await _frames(3)

	# open it the way the game does: through Minigames.play
	var got := {"score": -1.0}
	Minigames.play("fight", {"skill": 55.0, "difficulty": 1.0, "opponent": "The Challenger"},
		func(s: float, d: Dictionary) -> void: got["score"] = s; got["detail"] = d)
	await _frames(4)
	print("popup open=%s playing=%s default_button=%s" % [str(main.mg_open), str(main.mg_playing), str(is_instance_valid(main.mg_default))])

	# press Enter, the way the hint says, to start playing
	_key(KEY_ENTER)
	await _frames(6)
	print("after Enter: playing=%s game=%s" % [str(main.mg_playing), str(is_instance_valid(main.mg_game))])
	if not is_instance_valid(main.mg_game):
		print("MG INPUT PROBE FAIL: Enter did not start the game")
		get_tree().quit(1)
		return
	var g = main.mg_game
	print("focus owner=%s  game has focus=%s" % [str(main.get_viewport().gui_get_focus_owner()), str(g.has_focus())])

	# now play: wait for a telegraph, block it, then strike
	var blocks := 0
	var strikes := 0
	var opp_start: float = g.opp_hp
	var me_start: float = g.me_hp
	for i in range(900):
		if g.done:
			break
		if g.state == "tele" and g.tele != "FEINT":
			_key(KEY_W if g.tele == "HIGH" else KEY_S)
			blocks += 1
			await _frames(1)
			if g.state == "counter":
				_key(KEY_SPACE)
				strikes += 1
		await _frames(1)
	print("blocks attempted=%d  counters struck=%d" % [blocks, strikes])
	print("opp hp %.0f -> %.0f    me hp %.0f -> %.0f" % [opp_start, g.opp_hp, me_start, g.me_hp])
	print("clicking a button instead of a key, then trying Space again:")
	var btns: Array = g.find_children("*", "Button", true, false)
	print("  buttons on the board: %d, focus modes: %s" % [btns.size(), str(btns.map(func(b): return b.focus_mode))])
	var ok: bool = (float(g.opp_hp) < opp_start) and strikes > 0
	print("MG INPUT PROBE %s" % ("PASS — keyboard reaches the game and damage lands" if ok else "FAIL — input did not affect the fight"))
	get_tree().quit(0 if ok else 1)


func _key(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	var u := InputEventKey.new()
	u.keycode = code
	u.physical_keycode = code
	u.pressed = false
	Input.parse_input_event(u)


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
