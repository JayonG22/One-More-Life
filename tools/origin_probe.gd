extends Node
func _ready() -> void:
	seed(4242)
	var counts := {}
	var bad := 0
	var only := 0
	for i in range(400):
		GameState.new_life({"gender": "male", "country": "us"})
		var o := Origins.kind()
		counts[o] = int(counts.get(o, 0)) + 1
		if Origins.only_child():
			only += 1
		var m := GameState.first_of("mother")
		var d := GameState.first_of("father")
		if m != "" and d != "" and o in ["together", "adopted"]:
			if str(GameState.npcs[m].get("spouse_id","")) != d:
				bad += 1
	print("origins over 400 lives: ", counts)
	print("only children: %d / 400" % only)
	print("parents not linked when they should be: %d" % bad)

	# now the actual bug: run a married parent through 60 years of NPC life
	seed(77)
	var remarried := 0
	for i in range(120):
		GameState.new_life({"gender": "female", "country": "us"})
		if Origins.kind() != "together":
			continue
		var dad := GameState.first_of("father")
		if dad == "":
			continue
		var start_spouse := str(GameState.npcs[dad].get("spouse", ""))
		for y in range(40):
			GameState.player["age"] = y
			Bonds._npc_life(dad, GameState.npcs[dad])
		var now_spouse := str(GameState.npcs[dad].get("spouse", ""))
		if now_spouse != "" and start_spouse != "" and now_spouse != start_spouse:
			remarried += 1
	print("married fathers who acquired a different spouse: %d" % remarried)
	get_tree().quit()
