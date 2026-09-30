extends Node

var main: Control
var shot_dir := ""


func _ready() -> void:
	seed(31)
	shot_dir = OS.get_environment("SHOT_DIR")
	if shot_dir == "":
		shot_dir = "user://shots3"
	DirAccess.make_dir_recursive_absolute(shot_dir)
	get_window().size = Vector2i(1920, 1080)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(4)
	main._open_new_life()
	await _frames(2)
	main.nl["first"] = "Riley"
	main.nl["last"] = "Vance"
	main.nl["gender"] = "female"
	main._start_life()
	await _frames(2)
	for i in range(24):
		main._age_up()
		await _frames(1)
		await _clear_popups()
	var p := GameState.player
	p["money"] = 6000000
	p["stats"]["looks"] = 85.0
	p["stats"]["smarts"] = 80.0
	p["stats"]["health"] = 90.0
	p["education"]["degrees"].append({"major": "engineering", "level": "bachelor", "name": "B.S. in Engineering"})
	p["licenses"].append("boating")
	p["record"] = []
	# minigame host: intro, play, result for each game
	var ids: Array = Minigames.DEFS.keys()
	for i in range(ids.size()):
		var id: String = ids[i]
		Minigames.play(id, {"skill": 55, "difficulty": 1.0, "sport": "soccer", "opponent": "Diego \"The Wall\" Reyes", "title": "Test run", "flavor": ["", "pitch", "sermon"][i % 3]}, func(s, d): pass)
		await _frames(3)
		if i < 2:
			await _shot("mg_%02d_%s_intro" % [i, id])
		main.mg_default.emit_signal("pressed")
		for k in range(40):
			await get_tree().process_frame
			if k % 3 == 0:
				var ev := InputEventKey.new()
				ev.keycode = [KEY_RIGHT, KEY_UP, KEY_D, KEY_SPACE, KEY_1][k % 5]
				ev.pressed = true
				Input.parse_input_event(ev)
		await _shot("mg_%02d_%s_play" % [i, id])
		var game = main.mg_box.find_children("*", "Control", true, false).filter(func(n): return n is Minigame)
		if not game.is_empty() and not game[0].done:
			game[0].finish(0.83, {})
		await get_tree().create_timer(1.1).timeout
		await _frames(2)
		if i == 0:
			await _shot("mg_%02d_%s_result" % [i, id])
		if main.mg_open and is_instance_valid(main.mg_default):
			main.mg_default.emit_signal("pressed")
		await _frames(2)
		await _clear_popups()
	# empires
	main._open_panel(main.ep.business, true)
	await _frames(2)
	await _shot("e01_business_pick")
	Empires.start_business("aerospace")
	await _clear_popups()
	for id in Empires.candidates().slice(0, 2):
		Empires.hire_known(id)
		await _clear_popups()
	Empires.biz_action("b_market")
	await _clear_popups()
	for i in range(3):
		main._age_up()
		await _frames(1)
		await _clear_popups()
	p["money"] = 6000000
	main._open_panel(main.ep.business, true)
	await _frames(2)
	await _shot("e02_business")
	p["record"].append("theft")
	p["possessions"].append({"name": "Stolen painting", "icon": "🖼️", "cat": "Stolen", "value": 9000, "vol": 0.1, "bought": 0, "heirloom": false, "stolen": true})
	main._open_panel(main.ep.black_market, true)
	await _frames(2)
	await _shot("e03_black_market")
	Empires.start_cult("stars")
	await _clear_popups()
	p["cult"]["members"] = 340
	main._open_panel(main.ep.cult, true)
	await _frames(2)
	await _shot("e04_cult")
	Empires.open_zoo()
	await _clear_popups()
	for k in ["penguin", "giraffe", "lion", "flamingo"]:
		Empires.zoo_action("buy", k)
		await _clear_popups()
	Empires.zoo_action("keeper")
	await _clear_popups()
	main._age_up()
	await _frames(1)
	await _clear_popups()
	p["money"] = 6000000
	main._open_panel(main.ep.zoo, true)
	await _frames(2)
	await _shot("e05_zoo")
	main._open_panel(func(): main._panel_activity_group("outdoors"), true)
	await _frames(2)
	await _shot("e06_outdoors")
	p["time_left"] = 12
	for a in ["hike", "hike", "hike", "cave"]:
		Empires.outdoor(a)
		await _clear_popups()
	main._open_panel(main.ep.journal, true)
	await _frames(2)
	await _shot("e07_journal")
	var friend := ""
	for id in GameState.npcs.keys():
		if GameState.npcs[id]["relation"] in ["mother", "father", "friend", "sibling"] and GameState.npcs[id]["alive"]:
			friend = id
			break
	if friend != "":
		main._open_panel(func(): main._panel_person(friend), true)
		await _frames(2)
		await _shot("e08_person")
	main._open_panel(main._panel_relationships, true)
	await _frames(2)
	await _shot("e09_relationships")
	p["heat"] = 48.0
	main._refresh_side()
	main._open_panel(main._panel_special_hub, true)
	await _frames(2)
	await _shot("e10_special_hub")
	print("UI T3 DONE")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _clear_popups() -> void:
	var guard := 0
	while (main.popup_open or main.mg_open) and guard < 25:
		guard += 1
		if main.mg_open:
			if is_instance_valid(main.mg_default):
				main.mg_default.emit_signal("pressed")
			else:
				var game = main.mg_box.find_children("*", "Control", true, false).filter(func(n): return n is Minigame)
				if not game.is_empty():
					game[0].finish(0.6, {})
				await get_tree().create_timer(1.1).timeout
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
