extends Node

var stats := {}
var seen_ids := {}


func _bump(k: String, v: int = 1) -> void:
	stats[k] = int(stats.get(k, 0)) + v


func _drain() -> void:
	var guard := 0
	while EventEngine.has_pending() and guard < 40 and GameState.is_alive():
		guard += 1
		var inst := EventEngine.pop_next()
		if inst.get("info", false):
			continue
		var ch: Array = inst["def"].get("choices", [])
		var opts: Array = []
		for i in range(ch.size()):
			var st := EventEngine.choice_state(ch[i], inst.get("roles", {}))
			if st["visible"] and st["enabled"]:
				opts.append(i)
		if not opts.is_empty():
			_bump("decision:" + str(inst["def"].get("id", "?")))
			EventEngine.resolve(inst, opts[randi() % opts.size()])


func _ready() -> void:
	seed(777)
	var n := int(OS.get_environment("EMP_LIVES")) if OS.get_environment("EMP_LIVES") != "" else 6
	for i in range(n):
		_life(i)
	var fired := 0
	var total := 0
	var never: Array = []
	for e in ContentDB.events:
		var pre: String = e["id"].split(".")[0]
		if pre in ["biz", "cult", "zoo", "heat", "bm", "out", "web", "x"]:
			total += 1
			if GameState.event_history.has(e["id"]) or seen_ids.has(e["id"]):
				fired += 1
			else:
				never.append(e["id"])
	print("empire/web events fired %d / %d, never: %s" % [fired, total, str(never)])
	var keys := stats.keys()
	keys.sort()
	for k in keys:
		print("%-34s %s" % [k, str(stats[k])])
	get_tree().quit()


func _life(i: int) -> void:
	GameState.new_life({"gender": "male" if i % 2 else "female", "country": "us", "stats": {"health": 90, "smarts": 70, "looks": 70}})
	while GameState.player["age"] < 18 and GameState.is_alive():
		EventEngine.age_up()
		_drain()
	var p := GameState.player
	p["money"] = int(p["money"]) + 3000000
	p["licenses"].append("motorcycle")
	p["licenses"].append("boating")
	p["record"].append("theft")
	var inds: Array = Empires.INDUSTRIES.keys()
	Empires.start_business(inds[i % inds.size()])
	_drain()
	var yrs := 0
	while GameState.is_alive() and yrs < 60:
		yrs += 1
		p["time_left"] = 12
		if int(p["age"]) >= 21 and p["cult"].is_empty() and yrs % 7 == 3:
			var dk: Array = Empires.DOCTRINES.keys()
			Empires.start_cult(dk[randi() % dk.size()])
		if int(p["age"]) >= 21 and p["zoo"].is_empty() and yrs % 9 == 4:
			Empires.open_zoo()
		if p["business"].is_empty() and yrs % 5 == 0:
			Empires.start_business(inds[randi() % inds.size()])
		for k in range(6):
			_random_empire_action()
			_drain()
		if not GameState.in_prison():
			p["money"] = maxi(int(p["money"]), 0)
		EventEngine.age_up()
		_drain()
		if not p["business"].is_empty():
			_bump("biz_years")
			stats["max_biz_value"] = maxi(int(stats.get("max_biz_value", 0)), int(p["business"]["value"]))
			stats["max_biz_profit"] = maxi(int(stats.get("max_biz_profit", 0)), int(p["business"]["profit"]))
			if p["business"]["public"]:
				_bump("public_years")
		if not p["cult"].is_empty():
			_bump("cult_years")
			stats["max_cult"] = maxi(int(stats.get("max_cult", 0)), int(p["cult"]["members"]))
		if not p["zoo"].is_empty():
			_bump("zoo_years")
			stats["max_zoo_visitors"] = maxi(int(stats.get("max_zoo_visitors", 0)), int(p["zoo"]["visitors"]))
			stats["min_zoo_profit"] = mini(int(stats.get("min_zoo_profit", 0)), int(p["zoo"]["profit"]))
			stats["max_zoo_profit"] = maxi(int(stats.get("max_zoo_profit", 0)), int(p["zoo"]["profit"]))
		stats["max_heat"] = maxi(int(stats.get("max_heat", 0)), int(p["heat"]))
		if GameState.in_prison():
			_bump("prison_years")
	for k in GameState.event_history.keys():
		seen_ids[k] = true
	_bump("lives")
	stats["journal_species_max"] = maxi(int(stats.get("journal_species_max", 0)), int(Empires.journal_progress()[0]))
	_bump("net_worth_total_k", GameState.net_worth() / 1000)


func _random_empire_action() -> void:
	var p := GameState.player
	var r := randi() % 6
	match r:
		0:
			var acts := Empires.biz_actions()
			if acts.is_empty():
				return
			var a: Dictionary = acts[randi() % acts.size()]
			if a["id"] in ["b_close", "b_sell"] and randf() < 0.9:
				return
			_bump("biz:" + a["id"])
			Empires.biz_action(a["id"])
			if randf() < 0.3 and not p["business"].is_empty():
				var c := Empires.candidates(p["business"]["crew"])
				if not c.is_empty():
					Empires.hire_known(c[0])
		1:
			var acts2 := Empires.cult_actions()
			if acts2.is_empty():
				return
			var a2: Dictionary = acts2[randi() % acts2.size()]
			if a2["id"] == "c_disband" and randf() < 0.9:
				return
			_bump("cult:" + a2["id"])
			if a2["id"] == "c_compound":
				if p["properties"].is_empty():
					return
				Empires.cult_action("c_compound", 0)
			else:
				Empires.cult_action(a2["id"])
			if randf() < 0.2:
				var c2 := Empires.candidates()
				if not c2.is_empty():
					Empires.invite_to_cult(c2[randi() % c2.size()])
		2:
			if p["zoo"].is_empty():
				return
			var zk: Array = Empires.ZOO_ANIMALS.keys()
			var acts3 := ["buy", "buy", "land", "keeper", "event", "visit", "sell", "fire_keeper", "donate_pet"]
			var a3: String = acts3[randi() % acts3.size()]
			_bump("zoo:" + a3)
			match a3:
				"buy":
					var key: String = zk[randi() % zk.size()]
					if Empires.ZOO_ANIMALS[key].get("illegal", false) or key in ["petting", "rescue"]:
						return
					Empires.zoo_action("buy", key)
				"sell":
					if not p["zoo"]["animals"].is_empty():
						Empires.zoo_action("sell", p["zoo"]["animals"].keys()[0])
				"donate_pet":
					var pets := GameState.npcs_with("pet")
					if not pets.is_empty():
						Empires.zoo_action("donate_pet", pets[0])
				_:
					Empires.zoo_action(a3)
		3:
			var why := Empires.bm_access()
			if why != "":
				_bump("bm_blocked")
				return
			var opts := ["counterfeit", "fake_watch", "passport", "diploma", "exotic", "buy_hot", "fence", "flee"]
			var o: String = opts[randi() % opts.size()]
			_bump("bm:" + o)
			match o:
				"exotic":
					var ex := ["tiger", "chimp", "komodo", "python", "rhino", "redpanda"]
					Empires.bm_action("exotic", ex[randi() % ex.size()])
				"buy_hot":
					var goods := Empires.bm_goods()
					Empires.bm_action("buy_hot", goods[randi() % goods.size()])
				"fence":
					for idx in range(p["possessions"].size()):
						if p["possessions"][idx].get("stolen", false):
							Empires.bm_action("fence", idx)
							return
				"flee":
					if randf() < 0.1:
						Empires.bm_action("flee")
				_:
					Empires.bm_action(o)
		4, 5:
			var outs := ["camp", "hike", "fish", "sea_fish", "dirtbike", "cave", "museum"]
			var o2: String = outs[randi() % outs.size()]
			_bump("out:" + o2)
			match o2:
				"camp":
					var comp := Empires.outdoor_companions()
					Empires.outdoor("camp", comp[0] if not comp.is_empty() else null)
				"museum":
					for idx in range(p["possessions"].size()):
						if p["possessions"][idx].get("find", false):
							Empires.outdoor("museum", idx)
							return
				_:
					Empires.outdoor(o2)
