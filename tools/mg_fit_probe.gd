extends Node

## Proves the minigame board fits the window at every size the game runs at,
## and that the controls at the very bottom (Fight Night's blocks) are inside it.

var main: Control
var shot_dir := ""


func _ready() -> void:
	seed(1414)
	shot_dir = OS.get_environment("SHOT_DIR")
	if shot_dir == "":
		shot_dir = "user://mgfit"
	DirAccess.make_dir_recursive_absolute(shot_dir)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(4)
	main._open_new_life()
	main.nl["country"] = "us"
	main.nl["first"] = "Fit"
	main.nl["last"] = "Test"
	main._start_life()
	await _frames(3)
	var fails := 0
	for res in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720), Vector2i(1024, 640)]:
		get_window().size = res
		await _frames(4)
		main.mg_game = null
		main.mg_holder = null
		main.mg_layer.visible = true
		main._mg_play("fight", {"skill": 55.0, "opponent": "The Challenger"}, func(_s, _d): pass)
		await _frames(6)
		var g: Minigame = main.mg_game
		var holder: Control = main.mg_holder
		var scaled := Vector2(Minigame.W, Minigame.H) * g.scale
		var frame_rect: Rect2 = main.mg_frame.get_global_rect()
		var win := Vector2(res)
		var ok_w := frame_rect.position.x >= -1.0 and frame_rect.end.x <= win.x + 1.0
		var ok_h := frame_rect.position.y >= -1.0 and frame_rect.end.y <= win.y + 1.0
		# the bottom row of Fight Night's buttons, in board space, must land inside
		var btn_bottom_board := 440.0 + 66.0
		var btn_bottom_screen := holder.get_global_rect().position.y + btn_bottom_board * g.scale.y
		var ok_btn := btn_bottom_screen <= holder.get_global_rect().end.y + 1.0 and btn_bottom_screen <= win.y
		if not (ok_w and ok_h and ok_btn):
			fails += 1
		print("%dx%d  scale=%.3f  board=%.0fx%.0f  frame=%.0f,%.0f..%.0f,%.0f  fits_w=%s fits_h=%s buttons_visible=%s" % [
			res.x, res.y, g.scale.x, scaled.x, scaled.y,
			frame_rect.position.x, frame_rect.position.y, frame_rect.end.x, frame_rect.end.y,
			str(ok_w), str(ok_h), str(ok_btn)])
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/fight_%dx%d.png" % [shot_dir, res.x, res.y])
		if is_instance_valid(main.mg_game) and not main.mg_game.done:
			main.mg_game.set_process(false)
			main.mg_game.done = true
		main.mg_layer.visible = false
		main.mg_open = false
		main.mg_playing = false
		await _frames(2)
	print("MG FIT PROBE fails=%d" % fails)
	get_tree().quit(1 if fails > 0 else 0)


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
