extends Node

## Screenshots of the Negotiation and Road Test minigames (run under xvfb).

func _ready() -> void:
	var dir := OS.get_environment("SHOT_DIR")
	if dir == "":
		dir = "user://mgnew"
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1600, 900)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(3)
	GameState.new_life({"gender": "female", "country": "us", "first": "Ada", "last": "Lovelace"})
	GameState.player["age"] = 30
	main._show("game")
	await _f(3)
	for id in OS.get_environment("MG_IDS").split(","):
		Minigames.play(id, {"skill": 60.0, "difficulty": 1.0, "subject": "your salary"}, func(_s, _d): pass)
		await _f(4)
		var k := InputEventKey.new()
		k.keycode = KEY_ENTER
		k.pressed = true
		Input.parse_input_event(k)
		await _f(8)
		var g = main.mg_game
		if id == "haggle":
			g.ask = 118
			g._make_ask()
			await _f(4)
		else:
			g.dist = 700.0
			await _f(10)
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, id])
		g.finish(0.5, {"passed": true})
		await _f(10)
	print("MG NEW SHOTS DONE")
	get_tree().quit()


func _f(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
