extends Node

var main: Control
var shot_dir := ""


func _ready() -> void:
	seed(505)
	shot_dir = OS.get_environment("SHOT_DIR")
	if shot_dir == "":
		shot_dir = "user://shots5"
	DirAccess.make_dir_recursive_absolute(shot_dir)
	var res := OS.get_environment("RES")
	var sz := Vector2i(1920, 1080)
	if res != "":
		var parts := res.split("x")
		sz = Vector2i(int(parts[0]), int(parts[1]))
	get_window().size = sz
	var only := OS.get_environment("ONLY")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(4)
	main._refresh_title()
	await _frames(2)
	await _shot("a01_title")
	if only == "title":
		get_tree().quit()
		return
	main._open_new_life()
	main.nl["path"] = "witch"
	main.nl["country"] = "uk"
	main.nl["region"] = "edi"
	_rebuild_new()
	await _frames(3)
	await _shot("a02_new_life")
	main.nl["first"] = "Isla"
	main.nl["last"] = "Morrow"
	main._start_life()
	await _frames(2)
	for i in range(16):
		main._age_up()
		await _frames(1)
		await _clear_popups()
	await _frames(3)
	var p := GameState.player
	Lives.life()["mana"] = 90
	Lives.potions()["healing"] = 3
	Lives.potions()["hex"] = 1
	Lives.life()["masterwork"]["healing"] = 1
	main._open_panel(main.LP.life_panel, true)
	await _frames(3)
	await _shot("a03_witch_life")
	if only == "game":
		get_tree().quit()
		return
	Minigames.play("potion", {"skill": 60, "difficulty": 1.0}, Callable(Careers, "resolve_play").bind({"kind": "brew"}))
	await _frames(3)
	await _shot("a04_potion_intro")
	main.mg_default.emit_signal("pressed")
	await _frames(4)
	var game: Node = main.mg_box.get_child(0).get_child(0)
	game._toggle_ing("toadstool")
	game._toggle_ing("nightshade")
	game._toggle_ing("clover")
	await _frames(3)
	await _shot("a05_potion_pick")
	game._start_brew()
	for i in range(40):
		await _frames(1)
	await _shot("a06_potion_brew")
	game.t = game.brew_len
	for i in range(30):
		await _frames(1)
	await _shot("a07_potion_bottle")
	game._end()
	for i in range(70):
		await _frames(1)
	await _shot("a08_potion_result")
	await _clear_popups()
	p["age"] = 30
	p["money"] = 60000
	main._open_panel(main.LP.places_panel, true)
	await _frames(3)
	await _shot("a09_places")
	World._start("war")
	World._start("pandemic")
	await _clear_popups()
	main._open_panel(main.LP.world_panel, true)
	await _frames(3)
	await _shot("a10_world")
	p["money"] = 2400000000
	main._refresh_side()
	main._open_panel(main.LP.billionaire_panel, true)
	await _frames(3)
	await _shot("a11_billionaire")
	main.SP.show_heirloom()
	await _frames(3)
	await _shot("a12_heirloom_ready")
	main.SP._open()
	await _frames(12)
	await _shot("a13_heirloom_reveal")
	main._close_popup()
	SaveManager.save_game()
	SaveManager.duplicate_current()
	SaveManager.set_label(SaveManager.current_slot, "Isla, witch of Edinburgh")
	SaveManager.toggle_fav(SaveManager.current_slot)
	main.SP.show_lives()
	await _frames(6)
	await _shot("a14_your_lives")
	main._close_popup()
	main._show_settings_popup()
	await _frames(3)
	await _shot("a15_settings")
	main._close_popup()
	main._open_panel(main._panel_activities, true)
	await _frames(3)
	await _shot("a16_game_activities")
	Lives.life()["destiny_rise"] = true
	EventEngine.kill("a curse gone wrong")
	main._pump()
	await _frames(6)
	await _clear_popups()
	await _frames(6)
	await _shot("a17_death_rise")
	main._rise()
	await _frames(4)
	await _clear_popups()
	main._open_panel(main.LP.life_panel, true)
	await _frames(4)
	await _shot("a18_revenant")
	print("UI5 DONE")
	get_tree().quit()


func _rebuild_new() -> void:
	var fresh: Control = main._build_new_life()
	fresh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.screens["new"].get_parent().add_child(fresh)
	main.screens["new"].queue_free()
	main.screens["new"] = fresh
	main._show("new")


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _clear_popups() -> void:
	var guard := 0
	while (main.popup_open or main.mg_open) and guard < 40:
		guard += 1
		if main.mg_open:
			if is_instance_valid(main.mg_default):
				main.mg_default.emit_signal("pressed")
			else:
				var ab: Array = main.mg_box.find_children("*", "Button", true, false)
				for b in ab:
					if "Auto" in b.text or "Continue" in b.text:
						b.emit_signal("pressed")
						break
			await _frames(1)
			continue
		var choices: Array = main.overlay_box.find_children("Choice*", "Button", true, false)
		var pressed := false
		for b in choices:
			if not b.disabled:
				b.emit_signal("pressed")
				pressed = true
				break
		if not pressed:
			var ok := main.overlay_box.find_child("OkButton", true, false) as Button
			if ok:
				ok.emit_signal("pressed")
		await _frames(1)


func _shot(name_key: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot_dir.path_join(name_key + ".png"))
