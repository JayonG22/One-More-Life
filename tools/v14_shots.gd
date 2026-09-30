extends Node

var main: Control
var dir := ""


func _ready() -> void:
	seed(1414)
	dir = OS.get_environment("SHOT_DIR")
	if dir == "":
		dir = "user://v14"
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1600, 900)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(4)
	main._open_new_life()
	main.nl["country"] = "us"
	main.nl["first"] = "Nadia"
	main.nl["last"] = "Okonkwo"
	main._start_life()
	await _f(3)

	# a life with enough going on that the panels have something to show
	var p := GameState.player
	p["age"] = 34
	p["money"] = 3200000
	p["stats"]["smarts"] = 88.0
	p["stats"]["health"] = 74.0
	p["fame"] = 46.0
	p["housing"] = "house"
	p["house_value"] = 3100000
	p["car"] = "sports"
	p["last_income"] = 120000
	p["credit"] = 745
	for i in range(8):
		Become.note_activity("library")
	for i in range(4):
		Become.note_activity("nightlife")
	Wanted.commit("burglary", false)
	Wanted.commit("burglary", true)
	Wanted.commit("assault", false)
	var who := GameState.create_npc("crush", {"age": 33, "closeness": 66, "first": "Iris"})
	Actions.start_dating(who, false)
	Romance.st()["years"] = 6
	Lending.borrow("bank", 40000)
	GameState.emit_changed()
	main._refresh_side()
	main._render_top_panel()
	await _f(4)
	_shot("01_status_panel")

	main._open_panel(main._panel_become)
	await _f(4)
	_shot("02_become")

	main._panel_back()
	await _f(2)
	main._open_panel(main._panel_loans)
	await _f(4)
	_shot("03_loans")

	main._panel_back()
	await _f(2)
	main._open_panel(main._panel_fight_bets)
	await _f(4)
	_shot("04_fights")

	main._panel_back()
	await _f(2)
	main._open_panel(func(): main._panel_person(who))
	await _f(4)
	_shot("05_person")

	# the comic background
	main._panel_back()
	await _f(2)
	ThemeManager.apply("superhero")
	await _f(8)
	_shot("06_superhero")
	ThemeManager.apply("dark")
	await _f(3)

	print("V14 SHOTS DONE")
	get_tree().quit()


func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [dir, name])


func _f(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
