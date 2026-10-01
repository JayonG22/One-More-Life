extends Node
## Renders each gambling minigame mid-play (run under xvfb).
func _ready() -> void:
	get_window().size = Vector2i(1100, 640)
	GameState.new_life({"gender": "male", "country": "us"})
	var ids := ["g_slots", "g_roulette", "g_horses", "g_rocket", "g_plinko", "g_scratch", "g_wheel", "g_highlow", "memory"]
	for id in ids:
		var g = load(Minigames.DEFS[id]["script"]).new()
		g.setup({"bet": 500, "luck": 1.0, "money": 5000, "choice": "red", "skill": 50, "difficulty": 1.0})
		add_child(g)
		await get_tree().process_frame
		match id:
			"g_slots": g._spin()
			"g_roulette": g._spin()
			"g_horses": g._go()
			"g_rocket": g._go()
			"g_scratch":
				for i in [0, 3, 5, 7]: g._scratch(i)
			"g_wheel": g._spin()
			"g_plinko": g._drop()
		var wait := {"g_slots": 1.2, "g_roulette": 2.0, "g_horses": 4.0, "g_rocket": 2.5, "g_plinko": 0.5, "g_wheel": 1.5}.get(id, 0.6)
		await get_tree().create_timer(wait).timeout
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("/tmp/gshots/%s.png" % id)
		g.queue_free()
		await get_tree().process_frame
	print("SHOTS DONE")
	get_tree().quit()
