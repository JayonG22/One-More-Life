extends Node

## Screenshots of the v0.15/v0.16 panels, rendered for real (run under xvfb).

var main: Control
var dir := ""


func _ready() -> void:
	seed(1616)
	dir = OS.get_environment("SHOT_DIR")
	if dir == "":
		dir = "user://v16"
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1600, 900)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(4)
	main._open_new_life()
	main.nl["country"] = "us"
	main.nl["first"] = "Marta"
	main.nl["last"] = "Quinn"
	main._start_life()
	await _f(3)
	var p := GameState.player
	p["age"] = 46
	p["money"] = 82000
	p["stats"]["smarts"] = 76.0
	p["housing"] = "apartment"
	p["car"] = GameState.CARS.keys()[0]
	p["last_income"] = 54000
	Tenancy.sync()
	Tenancy.act("flatmate", null)
	Market.hire(str(Market.openings("full")[0]["id"]), 0.0)
	Expansion.ensure()
	p["medical"]["pending"] = "thyroid"
	p["medical"]["conditions"]["asthma"] = {"years": 3, "treated": 0, "controlled": false, "flares": 0}
	Care.st()["referral"] = {"for": "thyroid", "wait": 2, "made": 45}
	Care.st()["teeth"] = 38.0
	Care.st()["vision"] = 52.0
	Keeping._add_invite("wedding", GameState.create_npc("friend", {"age": 33, "closeness": 60, "first": "Hana"}), true)
	Keeping._add_invite("funeral", GameState.create_npc("friend", {"age": 71, "closeness": 55, "first": "Walter"}), false)
	EventEngine.pending.clear()
	GameState.emit_changed()
	main._refresh_side()
	await _f(4)
	for k in ["real:home", "real:go", "real:keep", "real:work", "real:care", "real:body"]:
		main.MP.open(k)
		await _f(5)
		_shot(k.replace(":", "_"))
		main._panel_back()
		await _f(2)
	main._open_panel(func(): main._panel_jobs("full"))
	await _f(5)
	_shot("jobs")
	main._panel_back()
	await _f(2)
	main._open_panel(main._panel_assets)
	await _f(5)
	_shot("assets")
	print("V16 SHOTS DONE")
	get_tree().quit()


func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [dir, name])


func _f(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
