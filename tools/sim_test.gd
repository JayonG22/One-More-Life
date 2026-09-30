extends Node

var lives := 0
var years := 0
var popups := 0
var deaths_by_age := {}
var causes := {}
var max_money := 0
var ribbons := {}
var event_counts := {}
var stat_married := 0
var stat_kids := 0
var stat_prison := 0
var stat_degrees := 0
var stat_jobs := 0
var career_counts := {}
var grit_stats := {}
var life_types := {}
var stat100 := {}
var lived_years_by_type := {}
var max_money_by_age := {}


func _ready() -> void:
	seed(12345)
	var n := int(OS.get_environment("SIM_LIVES")) if OS.get_environment("SIM_LIVES") != "" else 60
	for i in range(n):
		_run_life(i)
	print("SIM DONE lives=%d years=%d popups=%d avg_age=%.1f" % [lives, years, popups, float(years) / maxf(1, lives)])
	print("causes: ", causes)
	print("ribbons: ", ribbons)
	var keys := deaths_by_age.keys()
	keys.sort()
	var line := "deaths by decade: "
	for k in keys:
		line += "%d0s:%d  " % [int(k) / 10, deaths_by_age[k]]
	print(line)
	print("max money: ", max_money)
	print("grit totals: ", grit_stats)
	print("achievements unlocked: %d / %d, stars %d" % [Meta.meta["goals"]["ach"].size(), Goals.achievements.size(), Goals.stars()])
	print("careers started: ", career_counts)
	print("challenge badges: ", Meta.meta["challenges_done"])
	print("marriages: %d  kids: %d  prison lives: %d  degrees: %d  jobs: %d" % [stat_married, stat_kids, stat_prison, stat_degrees, stat_jobs])
	print("life types at death: ", life_types)
	print("years lived by type: ", lived_years_by_type)
	print("stat-at-100 years: ", stat100)
	print("max net worth by age: ", max_money_by_age)
	var miss5: Array = []
	for a in Goals.achievements:
		if int(a.get("v", 0)) == 5 and not Goals.has(a["id"]):
			miss5.append(a["id"])
	print("v0.5 achievements still locked: ", miss5)
	var fired := event_counts.keys().size()
	print("distinct events fired: %d / %d" % [fired, ContentDB.events.size()])
	var never: Array = []
	for e in ContentDB.events:
		if not event_counts.has(e["id"]):
			never.append(e["id"])
	print("never fired: ", never)
	get_tree().quit()


func _run_life(i: int) -> void:
	var genders := ["male", "female", "nonbinary"]
	var mods: Array = []
	if i % 5 == 0:
		var mk: Array = Meta.MODIFIERS.keys()
		mods = [mk[i % mk.size()], mk[(i + 2) % mk.size()]]
	var chal: String = Meta.challenges[i % Meta.challenges.size()]["id"] if i % 2 == 0 else ""
	var diff := OS.get_environment("SIM_DIFF") if OS.get_environment("SIM_DIFF") != "" else "real"
	var paths := ["human", "royal", "vampire", "witch", "super", "revenant"]
	var lp: String = paths[i % paths.size()] if OS.get_environment("SIM_PATHS") != "" else "human"
	GameState.new_life({"gender": genders[i % 3], "country": ContentDB.countries[i % ContentDB.countries.size()]["id"], "modifiers": mods, "challenge": chal, "difficulty": diff, "life_path": lp})
	lives += 1
	if OS.get_environment("SIM_HEIR") != "":
		Meta.meta["goals"]["daily_last"] = ""
		Goals.claim_daily()
	var guard := 0
	while GameState.is_alive() and guard < 130:
		guard += 1
		_random_actions()
		_drain()
		if not GameState.is_alive():
			break
		EventEngine.age_up()
		years += 1
		_drain()
		_year_stats()
		max_money = maxi(max_money, int(GameState.player["money"]))
		if guard == 60 and i % 4 == 0 and GameState.is_alive():
			SaveManager.current_slot = SaveManager.SLOTS
			SaveManager.save_game()
			SaveManager.load_slot(SaveManager.SLOTS)
	if GameState.is_alive():
		push_error("life never ended")
		return
	for k in GameState.event_history.keys():
		event_counts[k] = int(event_counts.get(k, 0)) + 1
	var p := GameState.player
	if p.get("life", {}).get("can_rise", false) and randf() < 0.7:
		Lives.rise()
		var g3 := 0
		while GameState.is_alive() and g3 < 60:
			g3 += 1
			_random_actions()
			_drain()
			if not GameState.is_alive():
				break
			EventEngine.age_up()
			years += 1
			_drain()
			_year_stats()
	var lt: String = Lives.kind()
	life_types[lt] = int(life_types.get(lt, 0)) + 1
	causes[p["cause"]] = int(causes.get(p["cause"], 0)) + 1
	var bucket := int(p["age"]) / 10 * 10
	deaths_by_age[bucket] = int(deaths_by_age.get(bucket, 0)) + 1
	if GameState.has_flag("married_once") or p["partner_status"] == "married": stat_married += 1
	stat_kids += GameState.npcs_with("child", false).size()
	if int(p["prison_total"]) > 0: stat_prison += 1
	stat_degrees += p["education"]["degrees"].size()
	if not p["job_history"].is_empty() or GameState.has_job(): stat_jobs += 1
	for h in p["job_history"]:
		career_counts[h] = 1
	for k in ["twists", "scars", "habits_formed", "bankruptcies", "retaliations", "repossessions", "estranged", "nursing_home"]:
		grit_stats[k] = int(grit_stats.get(k, 0)) + GameState.get_counter(k)
	for sc in p.get("scars", []):
		grit_stats["scar_" + sc] = int(grit_stats.get("scar_" + sc, 0)) + 1
	var rn: String = p["ribbon"].get("name", "?")
	ribbons[rn] = int(ribbons.get(rn, 0)) + 1
	var heirs := GameState.heirs()
	if not heirs.is_empty() and i % 3 == 0:
		GameState.continue_as(heirs[0])
		var guard2 := 0
		while GameState.is_alive() and guard2 < 130:
			guard2 += 1
			_random_actions()
			_drain()
			if not GameState.is_alive():
				break
			EventEngine.age_up()
			years += 1
			_drain()
		lives += 1


func _year_stats() -> void:
	if not GameState.is_alive():
		return
	var p := GameState.player
	var lt: String = Lives.kind()
	lived_years_by_type[lt] = int(lived_years_by_type.get(lt, 0)) + 1
	for k in ["happiness", "health", "smarts", "looks"]:
		if GameState.stat(k) >= 99.5:
			stat100[k] = int(stat100.get(k, 0)) + 1
			if not p.has("_hit_" + k):
				p["_hit_" + k] = true
				stat100[k + "_lives"] = int(stat100.get(k + "_lives", 0)) + 1
				stat100[k + "_ages"] = str(stat100.get(k + "_ages", "")) + "%d(%s) " % [int(p["age"]), Lives.kind()]
	var b := int(p["age"]) / 10 * 10
	max_money_by_age[b] = maxi(int(max_money_by_age.get(b, 0)), int(GameState.net_worth()))


func _drain_first() -> void:
	while EventEngine.has_pending() and GameState.is_alive():
		var inst := EventEngine.pop_next()
		if inst.get("info", false):
			continue
		var choices: Array = inst["def"].get("choices", [])
		for ci in range(choices.size()):
			var st := EventEngine.choice_state(choices[ci], inst.get("roles", {}))
			if st["visible"] and st["enabled"]:
				EventEngine.resolve(inst, ci)
				break


func _drain() -> void:
	var guard := 0
	while EventEngine.has_pending() and guard < 20 and GameState.is_alive():
		guard += 1
		var inst := EventEngine.pop_next()
		popups += 1
		if inst.get("info", false):
			continue
		var def: Dictionary = inst["def"]
		event_counts[def.get("id", "?")] = int(event_counts.get(def.get("id", "?"), 0)) + 1
		var options: Array = []
		var choices: Array = def.get("choices", [])
		for ci in range(choices.size()):
			var st := EventEngine.choice_state(choices[ci], inst.get("roles", {}))
			if st["visible"] and st["enabled"]:
				options.append(ci)
		if options.is_empty():
			continue
		var res := EventEngine.resolve(inst, options[randi() % options.size()])
		if res.get("died", false):
			return


func _random_actions() -> void:
	var p := GameState.player
	var age: int = p["age"]
	for _k in range(randi_range(1, 5)):
		if not GameState.is_alive():
			return
		if p["illness"] != "" and randf() < 0.6:
			Actions.do_activity("doctor")
			continue
		if age >= 20 and p["partner"] == "" and randf() < 0.25:
			Actions.do_activity("date")
			_drain_first()
			continue
		if p["partner"] != "" and randf() < 0.4:
			var pid: String = p["partner"]
			for want in ["date_night", "propose", "wedding", "baby"]:
				for a in Actions.person_actions(pid):
					if a["id"] == want and randf() < 0.5:
						Actions.interact(pid, want)
						_drain_first()
			continue
		var r := randi() % 21
		match r:
			0, 1:
				var grp: Dictionary = Actions.ACTIVITY_GROUPS[randi() % Actions.ACTIVITY_GROUPS.size()]
				var it: Dictionary = grp["items"][randi() % grp["items"].size()]
				if Actions.activity_available(it) and (it["id"] != "bank_robbery" or randf() < 0.1) and (not ["shoplift", "pickpocket", "burglary", "car_theft"].has(it["id"]) or randf() < 0.3):
					Actions.do_activity(it["id"])
			2:
				if GameState.in_prison():
					Actions.do_activity(Actions.PRISON_ACTIONS[randi() % Actions.PRISON_ACTIONS.size()]["id"])
			3:
				var ids := GameState.npcs.keys()
				if not ids.is_empty():
					var id: String = ids[randi() % ids.size()]
					var acts := Actions.person_actions(id)
					if not acts.is_empty():
						var a: Dictionary = acts[randi() % acts.size()]
						if a["id"] != "breakup" or randf() < 0.1:
							Actions.interact(id, a["id"])
			4:
				if age >= 13 and not GameState.has_job() and not GameState.in_prison():
					var kind: String = "part" if age < 18 else ["full", "full", "military", "part"][randi() % 4]
					var l := Actions.listings(kind)
					for jid in l:
						if Actions.job_requirement(ContentDB.job(jid)) == "":
							Actions.apply_job(jid)
							break
			5:
				if GameState.has_job():
					Actions.work_harder()
				elif GameState.in_school() or GameState.in_university():
					Actions.study_harder()
			6:
				if age >= 18 and Actions.can_enroll("bachelor") == "" and randf() < 0.6:
					var ms := ContentDB.majors_of_level("bachelor")
					Actions.enroll(ms[randi() % ms.size()]["id"])
				elif Actions.can_enroll("graduate") == "" and randf() < 0.3:
					var gs := ContentDB.majors_of_level("graduate")
					Actions.enroll(gs[randi() % gs.size()]["id"])
			7:
				if age >= 18 and randf() < 0.3:
					if p["housing"] == "parents":
						Actions.move_out()
					elif p["housing"] == "apartment" and int(p["money"]) > 80000:
						Actions.buy_house()
			8:
				if age >= 16 and p["car"] == "" and int(p["money"]) > 10000:
					Actions.buy_car("used")
			9:
				if age >= 5:
					p["routines"]["gym"] = randf() < 0.5
					p["routines"]["study"] = randf() < 0.5
			10:
				if GameState.has_job() and age >= 62 and randf() < 0.4:
					Actions.retire()
				elif GameState.has_job() and randf() < 0.05:
					Actions.ask_raise()
			11:
				if age >= 14:
					Actions.freelance()
			12:
				if not Careers.has_career() and randf() < 0.3:
					var ids: Array = Careers.CAREERS.keys()
					var cid: String = ids[randi() % ids.size()]
					if Careers.join_requirement(cid) == "":
						Careers.join(cid)
						_drain_first()
			13, 14:
				if Careers.has_career():
					var acts := Careers.actions()
					var a: Dictionary = acts[randi() % acts.size()]
					if not a.get("off", false) and (a["id"] != "retire" or randf() < 0.05) and (a["id"] != "rat" or randf() < 0.1):
						Careers.do_action(a["id"])
			15:
				if age >= 13:
					Careers.social_action(["photo", "video", "live", "brand"][randi() % 4])
				if age >= 18:
					var roll := randi() % 6
					if roll == 0 and int(p["money"]) > 2000:
						Finance.deposit(int(p["money"]) / 2)
					elif roll == 1 and int(p["money"]) > 1000:
						var syms: Array = Finance.STOCKS.keys()
						Finance.buy("stock", syms[randi() % syms.size()], 1000)
					elif roll == 2 and int(p["money"]) > 1000:
						Finance.buy("crypto", Finance.CRYPTO.keys()[randi() % 3], 1000)
					elif roll == 3:
						var ls := Finance.listings()
						for li in range(ls.size()):
							if int(p["money"]) >= int(ls[li]["price"]):
								Finance.buy_property(li)
								break
					elif roll == 4:
						var si := randi() % Finance.SHOP.size()
						Finance.buy_item(si)
					elif roll == 5 and not p["stocks"].is_empty():
						Finance.sell_all("stock", p["stocks"].keys()[0])
			16:
				var lk: Array = Law.LICENSES.keys()
				Law.take_test(lk[randi() % lk.size()])
				if age >= 18 and randf() < 0.1:
					var ids2 := GameState.npcs.keys()
					if not ids2.is_empty():
						Law.sue(ids2[randi() % ids2.size()])
			17:
				for pr in p["properties"]:
					match randi() % 4:
						0: Finance.renovate(pr)
						1: Finance.raise_rent(pr)
						2: Finance.find_tenant(pr)
						3: pass
				if not p["possessions"].is_empty() and randf() < 0.2:
					Finance.sell_item(0)
			18, 19:
				var la: Array = Lives.actions()
				if not la.is_empty():
					var a: Dictionary = la[randi() % la.size()]
					var arg = a.get("arg", null)
					var ok := true
					if a.get("pick", false):
						var tg := Lives.pick_targets(a["id"])
						ok = not tg.is_empty()
						if ok:
							arg = tg[randi() % tg.size()]
					if ok and (a["id"] not in ["v_sun", "r_abdicate", "rev_rest"] or randf() < 0.05):
						Lives.act(a["id"], arg)
						_drain_first()
			20:
				if World.billionaire_open():
					var ba: Array = World.billionaire_actions()
					if not ba.is_empty():
						World.billionaire_action(ba[randi() % ba.size()]["id"])
						_drain_first()
		_drain()
