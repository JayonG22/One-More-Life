extends Node
## Screenshots: the game screen with an avatar, the Star Shop tabs, the avatar editor, the creator.
func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in range(4): await get_tree().process_frame
	Meta.meta["goals"]["stars"] = 200
	SaveManager.begin_new_life()
	GameState.new_life({"first": "Ada", "last": "Quill", "gender": "female", "country": "uk", "modifiers": [], "difficulty": "real", "boons": [], "challenge": ""})
	for y in range(24):
		EventEngine.age_up()
		var g := 0
		while EventEngine.has_pending() and g < 30 and GameState.is_alive():
			g += 1
			var inst := EventEngine.pop_next()
			if inst.get("info", false): continue
			var chs: Array = inst["def"].get("choices", [])
			for ci in range(chs.size()):
				var st: Dictionary = EventEngine.choice_state(chs[ci], inst.get("roles", {}))
				if st["visible"] and st["enabled"]:
					EventEngine.resolve(inst, ci); break
	main._show("game")
	for i in range(8): await get_tree().process_frame
	for c in main.fx_layer.get_children(): c.queue_free()
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/gshots/game.png")
	for tab in ["items", "avatar"]:
		main.star_tab = tab
		main._show_star_shop()
		for i in range(6): await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("/tmp/gshots/star_%s.png" % tab)
		main._close_popup()
	main._open_avatar_editor(Avatar.for_player(), "female", 24, func(a): pass)
	for i in range(6): await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/gshots/editor.png")
	main._close_popup()
	GameState.settings["ui_scale"] = 1.5
	main._apply_display()
	for i in range(8): await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/gshots/single1.png")
	main._set_column(0)
	for i in range(6): await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/gshots/single0.png")
	print("V23 DONE")
	get_tree().quit()
