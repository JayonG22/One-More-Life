extends Node
## Runs on the ORIGINAL v0.14 code: lives 45 years with plenty of state, then saves.

func _drain() -> void:
	var guard := 0
	while EventEngine.has_pending() and guard < 25 and GameState.is_alive():
		guard += 1
		var inst := EventEngine.pop_next()
		if inst.get("info", false):
			continue
		var choices: Array = inst["def"].get("choices", [])
		var opts: Array = []
		for ci in range(choices.size()):
			var st := EventEngine.choice_state(choices[ci], inst.get("roles", {}))
			if st["visible"] and st["enabled"]:
				opts.append(ci)
		if opts.is_empty():
			continue
		var res := EventEngine.resolve(inst, opts[randi() % opts.size()])
		if res.get("died", false):
			return

func _ready() -> void:
	seed(4242)
	SaveManager.begin_new_life()
	GameState.new_life({"gender": "female", "country": "us", "first": "Mira", "last": "Okafor"})
	var tries := 0
	while int(GameState.player["age"]) < 44 and GameState.is_alive() and tries < 80:
		tries += 1
		GameState.player["money"] = maxi(int(GameState.player["money"]), 30000)
		EventEngine.age_up()
		_drain()
	if not GameState.is_alive():
		print("MIG MAKE: the life died early at ", GameState.player["age"])
	Lending.borrow("bank", 10000)
	SaveManager.save_game()
	var p := GameState.player
	print("MIG MAKE DONE age=%d alive=%s npcs=%d money=%d slot=%d housing=%s" % [int(p["age"]), str(GameState.is_alive()), GameState.npcs.size(), int(p["money"]), SaveManager.current_slot, str(p["housing"])])
	get_tree().quit()
