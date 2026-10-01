extends Node

## Plays Pets Life through the REAL main screen: pick the mode on the title screen,
## be born, use every tab and a row from every menu, grow old, die, and be born
## again into the same house.

var main: Control
var failures: Array = []


func _ready() -> void:
	seed(1919)
	get_window().size = Vector2i(1600, 900)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(6)
	var t: Control = main.screens["title"]
	_ok(t.find_child("PetsBtn", true, false) != null, "the title screen has no Pets Life mode card")
	_ok(t.find_child("NewLifeBtn", true, false) != null, "the title screen has no Human Life mode card")
	_ok(t.find_child("PrisonBtn", true, false) != null, "the title screen has no Prison Life mode card")
	(t.find_child("PetsBtn", true, false) as Button).emit_signal("pressed")
	await _frames(4)
	_ok(main.popup_open, "the Pets Life setup did not open")
	main.pn["species"] = "dog"
	main.pn["origin"] = "loving"
	main.pn["name"] = "Pickle"
	var go := main.overlay_box.find_child("Choice1", true, false) as Button
	_ok(go != null, "no Be born button")
	go.emit_signal("pressed")
	await _frames(5)
	_ok(Pets.active() and main._current_screen() == "game", "starting a pet did not reach the game screen")
	var rows_run := 0
	var years := 0
	while GameState.is_alive() and years < 40:
		years += 1
		main._age_up()
		await _frames(2)
		await _clear()
		for i in range(6):
			main._tab_press(i)
			await _frames(1)
		for key in ["care", "play", "train", "wild", "house", "calling"]:
			var m: Dictionary = Pets.menu(key)
			main.MP.open("pet:" + key)
			await _frames(1)
			for r in m["rows"]:
				if bool(r.get("on", true)) and r.has("act") and r["act"] != "pet:game" and rows_run % 3 == years % 3:
					GameState.player["time_left"] = 12
					main.MP.run(str(r["act"]), r.get("arg", null))
					await _frames(1)
					await _clear()
					break
			rows_run += 1
		main._refresh_side()
	_ok(not GameState.is_alive(), "the pet never died")
	await _frames(8)
	_ok(main._current_screen() == "death", "no death screen (on %s)" % main._current_screen())
	var found := false
	for b in main.screens["death"].find_children("*", "Button", true, false):
		if str(b.text).find("same house") != -1:
			found = true
			b.emit_signal("pressed")
			break
	_ok(found, "the death screen has no next-life button")
	await _frames(4)
	_ok(main.popup_open, "the next-life setup did not open")
	main.pn["species"] = "cat"
	(main.overlay_box.find_child("Choice1", true, false) as Button).emit_signal("pressed")
	await _frames(5)
	_ok(Pets.active() and GameState.is_alive() and main._current_screen() == "game", "the next life did not start")
	print("V19 UI TEST DONE years=%d rows=%d failures=%d" % [years, rows_run, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _ok(c: bool, msg: String) -> void:
	if not c:
		failures.append(msg)
		push_error("V19UI: " + msg)


func _clear() -> void:
	var guard := 0
	while main.popup_open and guard < 25:
		guard += 1
		var ch: Array = main.overlay_box.find_children("Choice*", "Button", true, false)
		var pressed := false
		for b in ch:
			if not b.disabled:
				b.emit_signal("pressed")
				pressed = true
				break
		if not pressed:
			var ok := main.overlay_box.find_child("OkButton", true, false) as Button
			if ok:
				ok.emit_signal("pressed")
		await _frames(1)


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
