extends Node
## Renders the share card for a human, a pet and a prisoner (run under xvfb).
func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in range(4): await get_tree().process_frame
	GameState.new_life({"first": "Pickle", "last": "", "gender": "female", "country": "uk", "life_path": "pet", "keep_family": true, "species": "dog", "origin": "loving"})
	for y in range(8):
		EventEngine.age_up(); EventEngine.pending.clear()
	var e1 := GameState.finalize_death("old age, asleep in the sun")
	main._share_life(e1)
	for i in range(8): await get_tree().process_frame
	GameState.new_life({"first": "Sam", "last": "Reed", "gender": "male", "country": "us", "life_path": "prisoner", "keep_family": true, "story": "innocent"})
	for y in range(4):
		EventEngine.age_up(); EventEngine.pending.clear()
	Prison.conclude("exonerated", true)
	main._share_life(GameState.player["legacy"])
	for i in range(8): await get_tree().process_frame
	print("CARDS DONE ", main.last_share)
	get_tree().quit()
