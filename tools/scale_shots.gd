extends Node

## Screenshots of the game at the largest interface sizes (run under xvfb).

func _ready() -> void:
	var dir := OS.get_environment("SHOT_DIR")
	if dir == "":
		dir = "user://scale"
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1600, 900)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(3)
	GameState.new_life({"gender": "female", "country": "us", "first": "Ada", "last": "Lovelace"})
	GameState.player["age"] = 34
	GameState.player["money"] = 90000
	main._show("game")
	await _f(4)
	for sc in [1.15, 1.3, 1.5]:
		GameState.settings["ui_scale"] = sc
		main._apply_display()
		await _f(4)
		main._open_panel(main._panel_occupation, true)
		await _f(4)
		get_viewport().get_texture().get_image().save_png("%s/scale_%d.png" % [dir, int(sc * 100)])
	print("SCALE SHOTS DONE")
	get_tree().quit()


func _f(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
