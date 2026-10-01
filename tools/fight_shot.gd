extends Node

## A screenshot of the fight with its coaching on screen (run under xvfb).

func _ready() -> void:
	var dir := OS.get_environment("SHOT_DIR")
	if dir == "":
		dir = "user://fight"
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1600, 900)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(3)
	GameState.new_life({"gender": "male", "country": "us", "first": "Rocky", "last": "Vale"})
	GameState.player["age"] = 27
	main._show("game")
	await _f(3)
	Minigames.play("fight", {"skill": 55.0, "difficulty": 1.0, "opponent": "The Challenger"}, func(_s, _d): pass)
	await _f(4)
	var k := InputEventKey.new()
	k.keycode = KEY_ENTER
	k.pressed = true
	Input.parse_input_event(k)
	await _f(6)
	var g = main.mg_game
	for i in range(900):
		if g.state == "tele" and g.tele != "FEINT":
			break
		await _f(1)
	await _f(3)
	get_viewport().get_texture().get_image().save_png("%s/fight_tele.png" % dir)
	g._block(g.tele)
	await _f(4)
	get_viewport().get_texture().get_image().save_png("%s/fight_counter.png" % dir)
	print("FIGHT SHOT DONE")
	get_tree().quit()


func _f(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
