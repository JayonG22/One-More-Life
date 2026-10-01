extends Node

## Plays both Prison Life roles through the REAL main screen: pick the mode on the
## title screen, choose a role and a story, use every tab and a row from every
## menu, and carry on until the story closes.

var main: Control
var failures: Array = []
const GAMES := ["trade", "hearing", "research", "recon", "rankup", "search", "breakout"]


func _ready() -> void:
	seed(2020)
	get_window().size = Vector2i(1600, 900)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(6)
	for role in ["prisoner", "guard"]:
		await _play(role)
	print("V20 UI TEST DONE failures=%d" % failures.size())
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _play(role: String) -> void:
	main._show("title")
	await _frames(3)
	var t: Control = main.screens["title"]
	var pb := t.find_child("PrisonBtn", true, false) as Button
	_ok(pb != null and not pb.disabled, "the title screen has no usable Prison Life card")
	pb.emit_signal("pressed")
	await _frames(4)
	_ok(main.popup_open, "the Prison Life setup did not open")
	main.pz["role"] = role
	main.pz["story"] = "gang" if role == "prisoner" else "military"
	var go := main.overlay_box.find_child("Choice1", true, false) as Button
	_ok(go != null, "no Begin button")
	go.emit_signal("pressed")
	await _frames(5)
	_ok(Prison.active() and Lives.kind() == role and main._current_screen() == "game", "starting %s did not reach the game screen" % role)
	var rows_run := 0
	var years := 0
	while GameState.is_alive() and years < 70 and Lives.kind() == role:
		years += 1
		main._age_up()
		await _frames(2)
		await _clear()
		if not GameState.is_alive():
			break
		for i in range(6):
			main._tab_press(i)
			await _frames(1)
		var keys: Array = ["routine", "hustle", "people", "gang", "case", "plan"] if role == "prisoner" else ["post", "block", "career", "integrity"]
		for key in keys:
			var m: Dictionary = Prison.menu(key)
			main.MP.open("pr:" + key)
			await _frames(1)
			for r in m["rows"]:
				var act := str(r.get("act", "")).substr(3)
				if bool(r.get("on", true)) and r.has("act") and not GAMES.has(act) and rows_run % 4 == years % 4:
					GameState.player["time_left"] = 12
					main.MP.run(str(r["act"]), r.get("arg", null))
					await _frames(1)
					await _clear()
					break
			rows_run += 1
		main._refresh_side()
	await _frames(8)
	_ok(main._current_screen() in ["death", "game"], "unexpected screen %s" % main._current_screen())
	if not GameState.is_alive():
		_ok(main._current_screen() == "death", "no death screen after the story closed (on %s)" % main._current_screen())
		var found := false
		for b in main.screens["death"].find_children("*", "Button", true, false):
			if str(b.text).find("Another") != -1:
				found = true
		_ok(found, "the end screen has no next-story button")
	print("  %s: %d years, %d rows used, ended: %s" % [role, years, rows_run, str(GameState.player.get("cause", ""))])


func _ok(c: bool, msg: String) -> void:
	if not c:
		failures.append(msg)
		push_error("V20UI: " + msg)


func _clear() -> void:
	var guard := 0
	while main.popup_open and guard < 40:
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
