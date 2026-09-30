extends Node

func _drain() -> void:
	var guard := 0
	while EventEngine.has_pending() and guard < 30 and GameState.is_alive():
		guard += 1
		var inst := EventEngine.pop_next()
		if inst.get("info", false):
			continue
		var ch: Array = inst["def"].get("choices", [])
		var opts: Array = []
		for i in range(ch.size()):
			var st := EventEngine.choice_state(ch[i], inst.get("roles", {}))
			if st["visible"] and st["enabled"] and not str(ch[i]["label"]).begins_with("Never") and not str(ch[i]["label"]).begins_with("Walk") and not str(ch[i]["label"]).begins_with("Drop") and not str(ch[i]["label"]).begins_with("Not"):
				opts.append(i)
		if opts.is_empty():
			for i in range(ch.size()):
				if EventEngine.choice_state(ch[i], inst.get("roles", {}))["enabled"]:
					opts.append(i)
		if not opts.is_empty():
			EventEngine.resolve(inst, opts[randi() % opts.size()])

func _ready() -> void:
	seed(4242)
	var fired := {}
	for cid in Careers.CAREERS.keys():
		for trial in range(1):
			GameState.new_life({"gender": "female" if trial % 2 else "male", "country": "us", "stats": {"health": 90, "smarts": 75, "looks": 80}, "traits": ["Charmer", "Athletic"]})
			var start_age: int = {"actor": 8, "musician": 12, "athlete": 16, "politician": 22, "mafia": 20, "hustler": 15, "astronaut": 24, "model": 18, "fighter": 18, "director": 22, "agent": 23}[cid]
			while GameState.player["age"] < start_age and GameState.is_alive():
				EventEngine.age_up(); _drain()
			if not GameState.is_alive():
				print("%-10s died before starting" % cid)
				continue
			var deg := {"astronaut": "engineering", "director": "communications", "agent": "criminal_justice"}
			if deg.has(cid):
				GameState.player["education"]["degrees"].append({"major": deg[cid], "level": "bachelor", "name": "test"})
				GameState.player["record"] = []
				GameState.player["prison_total"] = 0
				GameState.player["stats"]["smarts"] = 80.0
				GameState.player["stats"]["health"] = 85.0
			if cid in ["model", "fighter"]:
				GameState.player["stats"]["looks"] = 85.0
				GameState.player["stats"]["health"] = 85.0
			if GameState.in_prison():
				GameState.player["prison"] = 0
			if cid == "mafia":
				GameState.player["record"].append("theft")
			GameState.player["money"] = int(GameState.player["money"]) + 200000
			var why := Careers.join_requirement(cid)
			if why != "":
				print("%-10s blocked: %s" % [cid, why])
				continue
			Careers.join(cid)
			_drain()
			if not Careers.has_career(cid):
				print("%-10s did not start (audition/tryout failed)" % cid)
				continue
			var best := 0
			var peak_fame := 0.0
			var income := 0
			var yrs := 0
			while GameState.is_alive() and Careers.has_career(cid) and yrs < 30:
				for k in range(4):
					var acts := Careers.actions()
					if acts.is_empty():
						break
					var a: Dictionary = acts[randi() % acts.size()]
					if not a.get("off", false) and a["id"] != "retire" and a["id"] != "rat":
						Careers.do_action(a["id"])
						_drain()
				EventEngine.age_up(); _drain()
				yrs += 1
				if Careers.has_career(cid):
					best = maxi(best, int(Careers.career()["rank"]))
					income += int(Careers.career().get("income_last", 0))
				peak_fame = maxf(peak_fame, float(GameState.player["fame"]))
			for k in GameState.event_history.keys():
				fired[k] = true
			var ranks: Array = Careers.CAREERS[cid]["ranks"]
			var extra := ""
			if not GameState.player["career"].is_empty():
				var cc: Dictionary = GameState.player["career"]
				for key in ["missions", "shows", "wins", "losses", "belts", "films", "ops", "oscars"]:
					if cc.has(key):
						extra += " %s=%s" % [key, str(cc[key]) if not (cc[key] is Array) else str(cc[key].size())]
			print(extra)
			print("%-10s try %d: %2d yrs, best rank %-20s peak fame %3d, career income %s, ended: %s" % [cid, trial, yrs, ranks[best], int(peak_fame), GameState.fmt_money(income), "alive/in career" if Careers.has_career(cid) else ("dead" if not GameState.is_alive() else "left career")])
	var never: Array = []
	for e in ContentDB.events:
		if e["id"].split(".")[0] in ["actor", "music", "sport", "politics", "mafia", "hustle", "fame", "astro", "model", "fighter", "director", "agent"] and not fired.has(e["id"]):
			never.append(e["id"])
	print("career/fame events never fired: ", never)
	get_tree().quit()
