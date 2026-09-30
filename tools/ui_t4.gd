extends Node

var main: Control
var shot_dir := ""


func _ready() -> void:
	seed(77)
	shot_dir = OS.get_environment("SHOT_DIR")
	if shot_dir == "":
		shot_dir = "user://shots4"
	DirAccess.make_dir_recursive_absolute(shot_dir)
	get_window().size = Vector2i(1920, 1080)
	Goals.add_stars(260)
	Goals.buy_boon("second_wind")
	Goals.buy_boon("trust_fund")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(4)
	main._refresh_title()
	await _frames(2)
	await _shot("t01_title")
	main._open_new_life()
	main.nl["difficulty"] = "gritty"
	main.nl["boons"] = ["second_wind"]
	var fresh: Control = main._build_new_life()
	fresh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.screens["new"].get_parent().add_child(fresh)
	main.screens["new"].queue_free()
	main.screens["new"] = fresh
	main._show("new")
	await _frames(3)
	await _shot("t02_new_life")
	main.nl["first"] = "Mara"
	main.nl["last"] = "Quinn"
	main._start_life()
	await _frames(2)
	for i in range(30):
		main._age_up()
		await _frames(1)
		await _clear_popups()
	var p := GameState.player
	p["money"] = 80000
	Twists.fire("tw.house_fire")
	main._pump()
	await _frames(4)
	await _shot("t03_twist")
	var ch: Array = main.overlay_box.find_children("Choice*", "Button", true, false)
	ch[0].emit_signal("pressed")
	await _frames(4)
	await _shot("t04_twist_result")
	await _clear_popups()
	Grit.add_scar("bad_knee")
	Grit.habit("gambling", 70)
	await _clear_popups()
	var foe := ""
	for id in GameState.npcs.keys():
		if GameState.npcs[id]["relation"] in ["friend", "sibling", "mother", "father"] and GameState.npcs[id]["alive"]:
			foe = id
			break
	if foe != "":
		GameState.npcs[foe]["grudge"] = 60
	main._refresh_side()
	main._open_panel(main._panel_activities, true)
	await _frames(2)
	Goals.unlocked.emit(Goals.achievements[5])
	await _frames(20)
	await _shot("t05_game_grit_toast")
	if foe != "":
		main._open_panel(func(): main._panel_person(foe), true)
		await _frames(2)
		await _shot("t06_grudge_person")
	main._open_panel(func(): main._panel_activity_group("health"), true)
	await _frames(2)
	await _shot("t07_health")
	main._show_trophies()
	await _frames(3)
	await _shot("t08_trophies")
	main.trophy_cat = "grit"
	main._show_trophies()
	await _frames(3)
	await _shot("t09_trophies_grit")
	main._close_popup()
	await _frames(2)
	main._show_missions()
	await _frames(3)
	await _shot("t10_missions")
	main._close_popup()
	main._show_star_shop()
	await _frames(3)
	await _shot("t11_star_shop")
	main._close_popup()
	await _frames(2)
	EventEngine.kill("a test")
	await _frames(2)
	await _clear_popups()
	EventEngine.kill("heart failure")
	await _frames(6)
	main._show_death()
	await _frames(4)
	await _shot("t12_death")
	print("UI T4 DONE alive=", GameState.is_alive())
	get_tree().quit()


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _clear_popups() -> void:
	var guard := 0
	while (main.popup_open or main.mg_open) and guard < 30:
		guard += 1
		if main.mg_open:
			if is_instance_valid(main.mg_default):
				main.mg_default.emit_signal("pressed")
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
