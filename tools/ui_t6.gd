extends Node

var main: Control
var shot_dir := ""


func _ready() -> void:
	seed(606)
	shot_dir = OS.get_environment("SHOT_DIR")
	if shot_dir == "":
		shot_dir = "user://shots6"
	DirAccess.make_dir_recursive_absolute(shot_dir)
	var res := OS.get_environment("RES")
	var sz := Vector2i(1920, 1080)
	if res != "":
		var parts := res.split("x")
		sz = Vector2i(int(parts[0]), int(parts[1]))
	get_window().size = sz
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(4)
	main._open_new_life()
	main.nl["country"] = "us"
	_rebuild_new()
	await _frames(2)
	main.nl["first"] = "Maya"
	main.nl["last"] = "Okafor"
	main._start_life()
	await _frames(2)
	for i in range(15):
		main._age_up()
		await _frames(1)
		await _clear_popups()
	var p := GameState.player
	p["money"] = 3000
	main._open_panel(main._panel_activities, true)
	await _frames(3)
	await _shot("b01_activities")
	main.MP.open("daily:school")
	await _frames(3)
	await _shot("b02_school_life")
	var mom := GameState.first_of("mother")
	if mom != "":
		Bonds.remember(mom, "drove me to every soccer game", true)
		main._open_panel(func(): main._panel_person(mom), true)
		await _frames(3)
		await _shot("b03_person_mom")
		main.MP.open("bond:%s:family" % mom)
		await _frames(3)
		await _shot("b04_mom_family_menu")
	for i in range(11):
		main._age_up()
		await _frames(1)
		await _clear_popups()
	p["money"] = 250000
	p["housing"] = "apartment"
	main.MP.open("shop:root")
	await _frames(3)
	await _shot("b05_shop")
	main.MP.open("shop:jeweler")
	await _frames(3)
	await _shot("b06_jeweler")
	Shop.act("buy", ["electronics", 1])
	Shop.act("buy", ["electronics", 5])
	await _clear_popups()
	Social.act("join", "snapgram")
	Social.act("join", "chirp")
	await _clear_popups()
	Social.socials()["snapgram"]["followers"] = 48210
	Social._sync()
	main.MP.open("social:root")
	await _frames(3)
	await _shot("b07_social")
	main.MP.open("daily:lottery")
	await _frames(3)
	await _shot("b08_lottery")
	main.MP.open("daily:casino")
	await _frames(3)
	await _shot("b09_casino")
	Dealer.act("start", null)
	await _clear_popups()
	main.MP.open("dealer:root")
	await _frames(3)
	await _shot("b10_dealer")
	var pid := GameState.create_npc("partner", {"age": 26, "closeness": 80})
	Actions.start_dating(pid, false)
	main._open_panel(func(): main._panel_person(pid), true)
	await _frames(3)
	await _shot("b11_partner")
	var n := 12
	for g in ["audition", "debate", "blackjack", "escape", "burglary", "minefield"]:
		Minigames.play(g, {"skill": 60, "difficulty": 1.0, "bet": 500, "gear": {"nightvision": true}}, func(_s, _d): pass)
		await _frames(3)
		await _shot("b%02d_%s_intro" % [n, g])
		n += 1
		main.mg_default.emit_signal("pressed")
		await _frames(4)
		var game: Node = main.mg_box.get_child(0).get_child(0)
		if g in ["escape", "burglary", "minefield"]:
			game._move(Vector2i(1, 0))
			game._move(Vector2i(0, 1))
		elif g == "audition":
			game.move = 1.0
		for i in range(90):
			await _frames(1)
		await _shot("b%02d_%s_play" % [n, g])
		n += 1
		if is_instance_valid(game) and not game.done:
			game.finish(0.7, {})
		for i in range(70):
			await _frames(1)
		await _clear_popups()
	print("UI6 DONE")
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
