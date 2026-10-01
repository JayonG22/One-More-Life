extends Node
## Queues four achievements of rising tier and captures the first two cards.
func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in range(4): await get_tree().process_frame
	SaveManager.begin_new_life()
	GameState.new_life({"first": "Ada", "last": "Quill", "gender": "female", "country": "uk", "modifiers": [], "difficulty": "real", "boons": [], "challenge": ""})
	main._show("game")
	for i in range(6): await get_tree().process_frame
	var by_tier := {}
	for a in Goals.achievements:
		if not by_tier.has(a["tier"]): by_tier[a["tier"]] = a
	for t in ["bronze", "gold", "legendary"]:
		if by_tier.has(t): main._toast_ach(by_tier[t])
	await get_tree().create_timer(0.9).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/gshots/ach1.png")
	await get_tree().create_timer(3.4).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/gshots/ach2.png")
	await get_tree().create_timer(2.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/gshots/ach3.png")
	print("ACH DONE queue_left=", main.ach_queue.size())
	get_tree().quit()
