extends Node

## Focused playthroughs for each Life Path and the billionaire endgame, to prove
## every v0.5 achievement can be earned by a player who pursues it.

var got := {}


func _ready() -> void:
	seed(4242)
	Goals.unlocked.connect(func(a): got[a["id"]] = true)
	for path in ["royal", "vampire", "witch", "super", "revenant"]:
		for i in range(4):
			_life(path, i)
	for i in range(3):
		_billionaire(i)
	_misc()
	var miss: Array = []
	for a in Goals.achievements:
		if int(a.get("v", 0)) == 5 and not Goals.has(a["id"]):
			miss.append(a["id"])
	print("REACH got this run: ", got.keys().filter(func(k): return k.begins_with("royal") or k.begins_with("vamp") or k.begins_with("witch") or k.begins_with("super") or k.begins_with("rev") or k.begins_with("bb") or k.begins_with("heir") or k.begins_with("world") or k == "mgp_potion"))
	print("REACH still locked: ", miss)
	get_tree().quit()


func _drain() -> void:
	var guard := 0
	while EventEngine.has_pending() and guard < 30 and GameState.is_alive():
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
		var pick: int = opts[0] if inst["def"].get("id", "").begins_with("tw.") else opts[randi() % opts.size()]
		if inst["def"].get("id", "") == "tw.revolution":
			pick = opts[0]
		EventEngine.resolve(inst, pick)


func _life(path: String, i: int) -> void:
	GameState.new_life({"country": ["uk", "us", "jp", "de"][i % 4], "life_path": path, "gender": ["male", "female"][i % 2]})
	var p := GameState.player
	var guard := 0
	while GameState.is_alive() and guard < 300:
		guard += 1
		if int(p["age"]) >= 18 and p["partner"] == "" and randf() < 0.3:
			Actions.do_activity("date")
			_drain()
		for k in range(6):
			var la: Array = Lives.actions()
			if la.is_empty() or not GameState.is_alive():
				break
			var a: Dictionary = la[randi() % la.size()]
			if a["id"] in ["v_sun", "r_abdicate", "rev_rest"] and randf() > 0.02:
				continue
			var arg = a.get("arg", null)
			if a.get("pick", false):
				var tg := Lives.pick_targets(a["id"])
				if tg.is_empty():
					continue
				arg = tg[randi() % tg.size()]
				if a["id"] == "v_turn":
					GameState.npcs[arg]["closeness"] = 80
			Lives.act(a["id"], arg)
			_drain()
		if path == "witch" and Lives.is_type("witch"):
			Lives.life()["mana"] = 100
		if path == "vampire" and Lives.is_type("vampire") and randf() < 0.5:
			Lives.life()["thirst"] = maxi(0, int(Lives.life()["thirst"]) - 30)
		if GameState.is_alive():
			EventEngine.age_up()
			_drain()
		if not GameState.is_alive() and p.get("life", {}).get("can_rise", false):
			Lives.rise()
			_drain()
	Goals.check(true)


func _billionaire(i: int) -> void:
	GameState.new_life({"country": "us"})
	var p := GameState.player
	p["age"] = 40
	p["money"] = 9000000000
	Goals.check()
	for y in range(40):
		if not GameState.is_alive():
			break
		p["money"] = maxi(int(p["money"]), 6000000000)
		for k in range(5):
			var ba: Array = World.billionaire_actions()
			if ba.is_empty():
				break
			World.billionaire_action(ba[randi() % ba.size()]["id"])
			_drain()
		EventEngine.age_up()
		_drain()
	Goals.check(true)


func _misc() -> void:
	GameState.new_life({"country": "us"})
	var p := GameState.player
	p["age"] = 25
	p["money"] = 100000
	for r in Places.regions("us"):
		if r["id"] != p["region"]:
			p["time_left"] = GameState.TIME_PER_YEAR
			Places.relocate(r["id"])
			break
	var days := 0
	while Goals.heirloom_collection().size() < 24 and days < 400:
		days += 1
		Meta.meta["goals"]["daily_last"] = ""
		Goals.claim_daily()
	print("REACH heirloom days to complete: ", days)
	Goals.on_minigame("potion", 0.95, false)
	Goals.check()
	p["money"] = 3000000000
	GameState.set_flag("island_owner")
	for k in range(3):
		var ba: Array = World.billionaire_actions().filter(func(x): return x["id"] == "bb_nation")
		if not ba.is_empty():
			World.billionaire_action("bb_nation")
			_drain()
	Goals.check()
	for k in range(6):
		GameState.new_life({"country": "us"})
		p = GameState.player
		p["age"] = 26
		Twists.fire("tw.royal_romance")
		_drain()
		Goals.check()
	GameState.new_life({"country": "uk", "life_path": "royal"})
	p = GameState.player
	p["age"] = 40
	Lives.life()["crowned"] = true
	Lives.life()["respect"] = 10
	Twists.fire("tw.revolution")
	_drain()
	Goals.check()
