extends Node

## Screenshots of the five pet minigames in the real overlay (run under xvfb).

func _ready() -> void:
	var dir := OS.get_environment("SHOT_DIR")
	if dir == "":
		dir = "user://v19mg"
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1600, 900)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(3)
	GameState.new_life({"first": "Pickle", "last": "", "gender": "female", "country": "uk", "life_path": "pet", "keep_family": true, "species": "dog", "origin": "loving"})
	main._show("game")
	await _f(3)
	for id in (OS.get_environment("MG_IDS").split(",") if OS.get_environment("MG_IDS") != "" else ["pet_pounce", "pet_scent", "pet_sneak", "pet_agility", "pet_herd"]):
		Minigames.play(id, {"skill": 60.0, "difficulty": 1.0, "species": "dog"}, func(_s, _d): pass)
		await _f(4)
		get_viewport().get_texture().get_image().save_png("%s/%s_intro.png" % [dir, id])
		var k := InputEventKey.new()
		k.keycode = KEY_ENTER
		k.pressed = true
		Input.parse_input_event(k)
		await _f(60)
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, id])
		main.mg_game.finish(0.5, {})
		await _f(10)
	print("V19 MG SHOTS DONE")
	get_tree().quit()


func _f(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
