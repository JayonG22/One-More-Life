extends Node

## Screenshots of Pets Life, rendered for real (run under xvfb).

var main: Control
var dir := ""


func _ready() -> void:
	seed(1919)
	dir = OS.get_environment("SHOT_DIR")
	if dir == "":
		dir = "user://v19"
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1600, 900)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(6)
	_shot("title")
	main._open_pet_setup()
	await _f(6)
	_shot("setup")
	main.pn["species"] = "dog"
	main.pn["origin"] = "loving"
	main.pn["name"] = "Pickle"
	main._start_pet()
	await _f(6)
	for i in range(3):
		EventEngine.age_up()
		EventEngine.pending.clear()
	main._refresh_side()
	await _f(5)
	_shot("game")
	for k in ["pet:home", "pet:care", "pet:train", "pet:wild", "pet:house", "pet:calling", "real:arc"]:
		main.MP.open(k)
		await _f(4)
		_shot(k.replace(":", "_"))
	main._panel_more_pet()
	await _f(3)
	# a decision popup
	EventEngine._enqueue(ContentDB.events_by_id["pl.street_winter"], {})
	main._pump()
	await _f(5)
	_shot("event")
	main._close_popup()
	await _f(2)
	EventEngine.kill("a car on the wet road")
	await _f(6)
	_shot("death")
	print("V19 SHOTS DONE")
	get_tree().quit(0)


func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [dir, name])


func _f(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
