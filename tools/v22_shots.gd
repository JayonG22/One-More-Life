extends Node
## Screenshots of the family tree, the graveyard and the heirloom attic (run under xvfb).
func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in range(4): await get_tree().process_frame
	SaveManager.begin_new_life()
	GameState.new_life({"first": "Ada", "last": "Quill", "gender": "female", "country": "uk", "modifiers": [], "difficulty": "real", "boons": [], "challenge": ""})
	for y in range(46):
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
	for i in range(6): await get_tree().process_frame
	main._show_family_tree()
	for i in range(8): await get_tree().process_frame
	for c in main.fx_layer.get_children(): c.queue_free()
	for i in range(4): await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/gshots/tree.png")
	main._close_popup()
	# a graveyard with some lives in it
	SaveManager.graveyard.clear()
	var names := ["Ada Quill", "Tom Reed", "Baby Joe", "Marcus Vane", "Old Hester", "Priya Nair", "Lord Ashby", "Mick Doyle", "Sister Agnes", "Kit Arden"]
	for i in range(names.size()):
		SaveManager.graveyard.append({"name": names[i], "born": 1900 + i * 7, "died": 1950 + i * 9, "age": [72, 61, 3, 88, 95, 52, 80, 44, 91, 33][i], "generation": 1 + i % 3, "cause": "old age", "ribbon": {"icon": "🌟", "name": "A Life"}, "story": "A life.", "net_worth": [3000, 60, 0, 6000000, 200, 90000, 900000, 10, 40000, 500][i], "karma": [10, -40, 0, -60, 30, 5, 0, -10, 60, 0][i]})
	main._show("graveyard")
	main._fill_graveyard()
	for i in range(12): await get_tree().process_frame
	for c in main.fx_layer.get_children(): c.queue_free()
	for i in range(4): await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/gshots/grave.png")
	main._show("title")
	for i in range(4): await get_tree().process_frame
	var col := Goals.heirloom_collection()
	for t in Goals.HEIR_TIERS:
		for it in t[4]:
			if randf() < 0.55:
				col[it[1]] = {"count": 1 + randi() % 3, "tier": t[0], "icon": it[0]}
	Goals.mantel().append(col.keys()[0])
	Goals.mantel().append(col.keys()[3])
	main.SP.show_heirloom()
	for i in range(10): await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/gshots/attic.png")
	print("V22 SHOTS DONE")
	get_tree().quit()
