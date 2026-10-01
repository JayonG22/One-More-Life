extends Node

## Screenshots of Prison Life, rendered for real (run under xvfb).

var main: Control
var dir := ""


func _ready() -> void:
	seed(2020)
	dir = OS.get_environment("SHOT_DIR")
	if dir == "":
		dir = "user://v20"
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1600, 900)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(6)
	_shot("title")
	main._open_prison_setup()
	await _f(6)
	_shot("setup")
	main.pz["role"] = "prisoner"
	main.pz["story"] = "gang"
	main._start_prison()
	await _f(6)
	for i in range(3):
		EventEngine.age_up()
		EventEngine.pending.clear()
	GameState.player["time_left"] = 12
	main._refresh_side()
	main._tab_press(0)
	await _f(5)
	_shot("prisoner_game")
	for k in ["pr:routine", "pr:hustle", "pr:people", "pr:gang", "pr:case", "pr:plan"]:
		main.MP.open(k)
		await _f(4)
		_shot(k.replace(":", "_"))
	EventEngine._enqueue(ContentDB.events_by_id["pr.riot.1"], {})
	main._pump()
	await _f(5)
	_shot("riot")
	main._close_popup()
	await _f(2)
	main.pz["role"] = "guard"
	main.pz["story"] = "idealist"
	GameState.player["alive"] = false
	main._start_prison()
	await _f(6)
	for i in range(4):
		EventEngine.age_up()
		EventEngine.pending.clear()
	GameState.player["time_left"] = 12
	main._refresh_side()
	main._tab_press(0)
	await _f(5)
	_shot("guard_game")
	for k in ["pr:post", "pr:block", "pr:career", "pr:integrity"]:
		main.MP.open(k)
		await _f(4)
		_shot(k.replace(":", "_"))
	Prison.conclude("retired")
	await _f(8)
	_shot("guard_end")
	print("V20 SHOTS DONE")
	get_tree().quit(0)


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])


func _f(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
