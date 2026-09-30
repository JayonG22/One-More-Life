extends Node

var main: Control
var shot_dir := ""


func _ready() -> void:
	seed(99)
	shot_dir = OS.get_environment("SHOT_DIR")
	if shot_dir == "":
		shot_dir = "user://shots"
	DirAccess.make_dir_recursive_absolute(shot_dir)
	get_window().size = Vector2i(1920, 1080)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(6)
	await _shot("01_title")
	main._open_new_life()
	await _frames(3)
	await _shot("02_new_life")
	main.nl["mods"] = ["piggy_bank"]
	main.nl["challenge"] = "rags"
	var fresh2: Control = main._build_new_life()
	fresh2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.screens["new"].get_parent().add_child(fresh2)
	main.screens["new"].queue_free()
	main.screens["new"] = fresh2
	main._show("new")
	await _frames(3)
	await _shot("02b_new_life_mods")
	main.nl["first"] = "Jordan"
	main.nl["last"] = "Lee"
	main.nl["gender"] = "male"
	main._start_life()
	await _frames(3)
	var shown_event := false
	for i in range(16):
		main._age_up()
		await _frames(2)
		if main.popup_open and not shown_event and main.overlay_box.find_children("Choice*", "Button", true, false).size() > 0 and GameState.player["age"] >= 9:
			await _shot("03_event_card")
			shown_event = true
		await _clear_popups()
	GameState.player["routines"]["gym"] = true
	main._open_panel(main._panel_activities, true)
	await _frames(3)
	await _shot("04_game_activities")
	main._open_panel(main._panel_relationships, true)
	await _frames(3)
	await _shot("05_relationships")
	main._open_panel(main._panel_occupation, true)
	await _frames(3)
	await _shot("06_occupation")
	for i in range(8):
		main._age_up()
		await _frames(1)
		await _clear_popups()
	main._open_panel(main._panel_education, true)
	await _frames(2)
	if Actions.can_enroll("bachelor") == "":
		Actions.enroll("game_dev")
		await _frames(1)
		await _clear_popups()
	for i in range(5):
		main._age_up()
		await _frames(1)
		await _clear_popups()
	main._open_panel(func(): main._panel_jobs("full"), true)
	await _frames(3)
	await _shot("07_jobs")
	main._open_panel(main._panel_assets, true)
	await _frames(3)
	await _shot("08_assets")
	main._show_family_tree()
	await _frames(3)
	await _shot("09_family_tree")
	main._close_popup()
	await _frames(2)
	# Tier 2 panels
	GameState.player["money"] = 4000000
	GameState.player["age"] = 28
	Careers.start("actor", "")
	await _clear_popups()
	Careers.career()["skill"] = 82.0
	GameState.player["fame"] = 74.0
	Careers.career()["roles"] = [{"title": "The Last Summer", "tier": "Studio blockbuster", "pay": 600000, "reception": "masterpiece"}]
	Careers.career()["awards"] = 2
	Careers._update_rank()
	main._open_panel(main._panel_career, true)
	await _frames(3)
	await _shot("13_career")
	main._open_panel(main._panel_special_hub, true)
	await _frames(3)
	await _shot("14_special_careers")
	Finance.buy("stock", "NMB", 200000)
	Finance.buy("crypto", "BYC", 100000)
	await _clear_popups()
	main._open_panel(main._panel_investments, true)
	await _frames(3)
	await _shot("15_investments")
	Finance.buy_property(0)
	await _clear_popups()
	if not GameState.player["properties"].is_empty():
		Finance.find_tenant(GameState.player["properties"][0])
		await _clear_popups()
	main._open_panel(main._panel_property, true)
	await _frames(3)
	await _shot("16_property")
	Finance.buy_item(2)
	Finance.buy_item(4)
	await _clear_popups()
	main._open_panel(main._panel_possessions, true)
	await _frames(3)
	await _shot("17_possessions")
	main._open_panel(main._panel_challenges, true)
	await _frames(3)
	await _shot("18_challenges")
	main._open_panel(main._panel_god, true)
	await _frames(3)
	await _shot("19_godmode")
	main._open_panel(main._panel_social, true)
	await _frames(3)
	await _shot("20_social")
	Law.trial("grand theft auto", 2, 6)
	await _frames(4)
	await _shot("21_trial")
	await _clear_popups()
	main._open_panel(main._panel_settings, true)
	await _frames(3)
	await _shot("22_settings")
	for t in ["vampire", "celebrity", "superhero", "light", "undead", "villain"]:
		main._set_theme(t)
		await _frames(4)
		await _clear_popups()
		main._open_panel(main._panel_activities, true)
		await _frames(3)
		await _shot("10_theme_" + t)
	main._set_theme("dark")
	await _frames(3)
	GameState.player["age"] = 81
	main._open_panel(main._panel_activities, true)
	await _frames(2)
	EventEngine.kill("old age")
	await _frames(4)
	await _clear_popups()
	await _frames(3)
	await _shot("11_death")
	main._open_graveyard()
	await _frames(3)
	await _shot("12_graveyard")
	print("UI TEST DONE, screen=", main._current_screen())
	get_tree().quit()


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _clear_popups() -> void:
	var guard := 0
	while main.popup_open and guard < 25:
		guard += 1
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
