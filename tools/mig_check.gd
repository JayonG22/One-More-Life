extends Node

## Loads a save made by an OLDER build and keeps playing it. Run by mig_check.sh.

var failures: Array = []
var checks := 0


func ok(c: bool, m: String) -> void:
	checks += 1
	if not c:
		failures.append(m)
		push_error("MIG: " + m)


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
	seed(99)
	var slot := SaveManager.latest_slot()
	ok(slot > 0 and SaveManager.load_slot(slot), "the old save would not load: %s" % SaveManager.last_error)
	var p := GameState.player
	ok(not p.is_empty() and int(p["age"]) >= 30, "the loaded life has no age")
	var name := "%s %s" % [p.get("first", "?"), p.get("last", "?")]
	var npcs0 := GameState.npcs.size()
	var age0 := int(p["age"])
	# the older save has none of the new state; every new system must cope
	ok(not p.has("tenancy") and not p.has("market") and not p.has("care") and not p.has("body"), "the old save already has new-version keys (it is not an old save)")
	for key in ["home", "go", "keep", "work", "care", "body", "arc"]:
		var d: Dictionary = Real.menu(key)
		ok(d.has("title"), "menu %s did not build on an old save" % key)
	ok(Market.openings("full") is Array, "job market failed on an old save")
	Fixtures.named("pub")
	# thirty more years, with every popup answered
	var years := 0
	while GameState.is_alive() and years < 30:
		years += 1
		GameState.player["money"] = maxi(int(GameState.player["money"]), 20000)
		EventEngine.age_up()
		_drain()
	ok(GameState.is_alive() or int(GameState.player["age"]) > age0 + 5, "the loaded life died almost at once")
	ok(int(GameState.player["age"]) > age0, "the loaded life never aged")
	# and it can save and load again in the new format
	SaveManager.save_game()
	ok(SaveManager.load_slot(slot), "the migrated life would not re-load")
	ok(GameState.player.has("tenancy") or GameState.player.has("body") or GameState.player.has("care"), "the new systems never wrote any state")
	print("MIGRATION FROM OLD SAVE: %s aged %d -> %d, %d people, %d checks, %d failures" % [name, age0, int(GameState.player["age"]), npcs0, checks, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)
