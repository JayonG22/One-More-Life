extends Node

const LICENSES := {
	"driver": {"name": "Driver's license", "icon": "🚗", "age": 16, "fee": 50, "difficulty": 0.25},
	"motorcycle": {"name": "Motorcycle license", "icon": "🏍️", "age": 16, "fee": 80, "difficulty": 0.3},
	"boating": {"name": "Boating license", "icon": "🚤", "age": 16, "fee": 150, "difficulty": 0.3},
	"firearms": {"name": "Firearms license", "icon": "🎯", "age": 21, "fee": 120, "difficulty": 0.2, "clean": true},
	"pilot": {"name": "Pilot's license", "icon": "✈️", "age": 18, "fee": 12000, "difficulty": 0.55},
	"fishing": {"name": "Fishing license", "icon": "🎣", "age": 12, "fee": 30, "difficulty": 0.02},
	"hunting": {"name": "Hunting license", "icon": "🦌", "age": 16, "fee": 150, "difficulty": 0.3},
	"scuba": {"name": "Scuba certification", "icon": "🤿", "age": 15, "fee": 450, "difficulty": 0.2},
}


func banned_until(id: String) -> int:
	return int(GameState.player.get("license_bans", {}).get(id, -1))


func suspend(id: String, years: int, why: String) -> void:
	var p := GameState.player
	if not p.has("license_bans"):
		p["license_bans"] = {}
	p["license_bans"][id] = int(p["age"]) + years
	p["licenses"].erase(id)
	if id == "driver":
		GameState.clear_flag("drivers_license")
	GameState.counter("license_suspensions")
	var nm: String = LICENSES.get(id, {}).get("name", id)
	GameState.add_log("My %s was suspended for %d year%s: %s." % [nm.to_lower(), years, "" if years == 1 else "s", why])


func yearly() -> void:
	var p := GameState.player
	if has_license("pilot") and GameState.stat("health") < 30 and randf() < 0.5:
		suspend("pilot", 2, "I failed my flight medical")
	var bans: Dictionary = p.get("license_bans", {})
	for id in bans.keys():
		if int(bans[id]) == int(p["age"]):
			GameState.add_log("My %s ban is over. I can retake the test." % LICENSES.get(id, {}).get("name", id).to_lower())


func min_age(id: String) -> int:
	if id == "driver":
		return int(Places.law("drive"))
	return int(LICENSES[id]["age"])


func has_license(id: String) -> bool:
	var p := GameState.player
	if id == "driver" and GameState.has_flag("drivers_license"):
		return true
	return p.get("licenses", []).has(id)


func take_test(id: String) -> void:
	var p := GameState.player
	var l: Dictionary = LICENSES[id]
	if has_license(id):
		EventEngine.push_info(l["icon"], l["name"], "You already have this license.")
		return
	if int(p["age"]) < min_age(id):
		EventEngine.push_info(l["icon"], l["name"], "In %s you must be %d." % [ContentDB.country(p["country"])["name"], min_age(id)])
		return
	if banned_until(id) > int(p["age"]):
		EventEngine.push_info(l["icon"], l["name"], "Your %s is suspended until you're %d." % [l["name"].to_lower(), banned_until(id)])
		return
	if id == "firearms" and str(Places.law("guns")) == "banned":
		EventEngine.push_info(l["icon"], l["name"], "Civilian gun ownership is banned in %s." % ContentDB.country(p["country"])["name"])
		return
	if id == "hunting" and not Places.law("hunting"):
		EventEngine.push_info(l["icon"], l["name"], "Hunting isn't allowed in %s." % ContentDB.country(p["country"])["name"])
		return
	if l.get("clean", false) and not p["record"].is_empty():
		EventEngine.push_info(l["icon"], l["name"], "Denied: you have a criminal record.")
		return
	if int(p["money"]) < int(l["fee"]):
		EventEngine.push_info("💸", l["name"], "The test fee is %s." % GameState.fmt_money(int(l["fee"])))
		return
	if not GameState.spend_time():
		EventEngine.push_info("⏳", "Out of time", "You've used all your time this year.")
		return
	p["money"] = int(p["money"]) - int(l["fee"])
	# A licence is knowledge, so it is tested as knowledge. The old version rolled
	# dice against Smarts, which meant a clever character could hold a firearms
	# licence without ever knowing which way to point it.
	var spec: Dictionary = ContentDB.licenses.get(id, {})
	var bank: Array = (spec.get("bank", []) as Array).duplicate(true)
	if bank.is_empty():
		_grant_license(id)
		return
	bank.shuffle()
	var difficulty_nudge := 1.0 + (0.25 if id == "firearms" and str(Places.law("guns")) == "strict" else 0.0)
	Minigames.play("quiz", {
		"bank": bank,
		"needed": int(spec.get("needed", 5)),
		"title": l["name"],
		# Smarts no longer decides the result, but it still decides how well the
		# headless auto-player does when the test is skipped.
		"skill": GameState.stat("smarts"),
		"difficulty": difficulty_nudge,
	}, Callable(self, "_quiz_done").bind(id))


func _grant_license(id: String) -> void:
	var p := GameState.player
	var l: Dictionary = LICENSES[id]
	if not p["licenses"].has(id):
		p["licenses"].append(id)
	GameState.counter("licenses_earned")
	if id == "driver":
		GameState.set_flag("drivers_license")
	GameState.add_log("I passed the test and got my %s." % l["name"].to_lower())
	EventEngine.push_info(l["icon"], "Passed!", "I got my %s." % l["name"].to_lower(), GameState.apply_effects({"happiness": 5}))


func _quiz_done(score: float, detail: Dictionary, id: String) -> void:
	var l: Dictionary = LICENSES[id]
	var passed: bool = detail.get("passed", score >= 0.999)
	# If the player has minigames switched off, the test is resolved for them.
	# Requiring a perfect paper from an auto-player would lock them out of every
	# licence in the game, so it falls back to a study check against Smarts.
	if detail.get("auto", false):
		var diff := float(l["difficulty"]) + (0.25 if id == "firearms" and str(Places.law("guns")) == "strict" else 0.0)
		passed = randf() < clampf(1.0 - diff + (GameState.stat("smarts") - 50.0) / 200.0, 0.05, 0.95)
	if passed:
		_grant_license(id)
		return
	var got := int(detail.get("correct", 0))
	var asked := int(detail.get("asked", 0))
	var missed: Array = detail.get("wrong", [])
	var body := "I got %d of %d right, and you need every one." % [got, asked] if asked > 0 else "I did not pass."
	if not missed.is_empty():
		body += "\n\nThe one that caught me: \"%s\"" % str(missed[0])
	body += "\n\nThe fee is gone, but I can sit it again."
	GameState.add_log("I failed the theory test for my %s." % l["name"].to_lower())
	EventEngine.push_info(l["icon"], "Failed", body, GameState.apply_effects({"happiness": -3}))


func _lawyer_cost(tier: int) -> int:
	var cost := float(ContentDB.country(GameState.player["country"]).get("cost", 1.0))
	return [0, int(8000 * cost), int(80000 * cost)][tier]


func trial(crime: String, min_years: int, max_years: int) -> void:
	var p := GameState.player
	var yr := GameState.year_now()
	var sm := GameState.stat("smarts") / 600.0
	var evidence := clampf(32.0 + float(p.get("heat", 0)) * 0.32 + p.get("record", []).size() * 4.0 + Wanted.trial_bias() + (8.0 if max_years >= 10 else 0.0) + randf_range(-14.0, 18.0), 8.0, 96.0)
	var evidence_penalty := (evidence - 50.0) / 180.0
	var acq := Grit.d("acquit") / float(Places.law("police"))
	if GameState.has_flag("hostile_witness"):
		acq *= 0.8
		GameState.clear_flag("hostile_witness")
	if GameState.has_flag("truth_spell"):
		acq *= 1.35
		GameState.clear_flag("truth_spell")
	if Lives.has_power("mind"):
		acq *= 1.2
	var choices: Array = []
	var tiers := [["Public defender (free)", 0.15], ["Private attorney (%s)" % GameState.fmt_money(_lawyer_cost(1)), 0.35], ["Top law firm (%s)" % GameState.fmt_money(_lawyer_cost(2)), 0.6]]
	for i in range(3):
		var cost := _lawyer_cost(i)
		var ch := clampf((float(tiers[i][1]) + sm - evidence_penalty - (0.05 if max_years >= 15 else 0.0)) * acq, 0.03, 0.9)
		var ch_dict := {"label": tiers[i][0], "outcomes": [
			{"weight": ch, "text": "Not guilty! The jury acquitted me of %s." % crime, "effects": {"money": -cost, "happiness": 15, "stress": -10}, "milestone": "was acquitted of %s" % crime, "ambition": {"kind":"court_case","crime":crime,"result":"acquitted","evidence":evidence,"lawyer":i}},
			{"weight": 1.0 - ch, "text": "Guilty. I was convicted of %s." % crime, "effects": {"money": -cost}, "jail": [min_years, max_years], "crime": crime, "ambition": {"kind":"court_case","crime":crime,"result":"convicted","years":max_years,"evidence":evidence,"lawyer":i}},
		]}
		if cost > 0:
			ch_dict["requires"] = {"money": cost}
		choices.append(ch_dict)
	var lw := Web.contact(["lawyer"], 55)
	if lw != "":
		var chl := clampf((0.6 + sm - evidence_penalty) * acq, 0.05, 0.92)
		choices.push_front({"label": "Call %s" % Web.contact_line(lw), "outcomes": [
			{"weight": chl, "text": "%s tore the prosecution apart. Not guilty!" % GameState.npc(lw)["first"], "effects": {"happiness": 15}, "relationship": {"lw": 10}, "milestone": "was acquitted of %s" % crime, "ambition": {"kind":"court_case","crime":crime,"result":"acquitted","evidence":evidence,"lawyer":2}},
			{"weight": 1.0 - chl, "text": "%s did everything possible, but I was convicted of %s." % [GameState.npc(lw)["first"], crime], "jail": [min_years, max_years], "crime": crime, "ambition": {"kind":"court_case","crime":crime,"result":"convicted","years":max_years,"evidence":evidence,"lawyer":2}},
		]})
	var cop := Web.contact(["cop"], 70)
	if cop != "":
		choices.append({"label": "Ask %s to make it go away" % Web.contact_line(cop), "outcomes": [
			{"weight": 0.35, "text": "Evidence went missing. The charges were dropped. %s won't look me in the eye." % GameState.npc(cop)["first"], "effects": {"karma": -8, "happiness": 10}, "relationship": {"cop": -15}, "ambition": {"kind":"court_case","crime":crime,"result":"dismissed","evidence":evidence,"lawyer":0}},
			{"weight": 0.65, "text": "%s refused, and the judge heard about it. I was convicted of %s." % [GameState.npc(cop)["first"], crime], "jail": [min_years, max_years + 1], "crime": crime, "relationship": {"cop": -30}, "ambition": {"kind":"court_case","crime":crime,"result":"convicted","years":max_years + 1,"evidence":evidence,"lawyer":0}},
		]})
	var corr := float(Places.law("corruption"))
	if corr >= 0.1:
		var bribe := maxi(Actions._cost(5000), int(GameState.net_worth() * 0.05))
		var chb := clampf(corr * 2.2, 0.1, 0.85)
		choices.append({"label": "Bribe the judge (%s)" % GameState.fmt_money(bribe), "requires": {"money": bribe}, "outcomes": [
			{"weight": chb, "text": "An envelope changed hands. The case was dismissed for \"procedural errors.\"", "effects": {"money": -bribe, "karma": -10}, "ambition": {"kind":"court_case","crime":crime,"result":"dismissed","evidence":evidence,"lawyer":0}},
			{"weight": 1.0 - chb, "text": "The judge was honest, and furious. Bribery was added to my charges.", "effects": {"money": -bribe}, "jail": [min_years + 1, max_years + 3], "crime": "bribery", "ambition": {"kind":"court_case","crime":"bribery","result":"convicted","years":max_years + 3,"evidence":evidence,"lawyer":0}}]})
	var plea_lo := maxi(1, min_years / 2)
	var plea_hi := maxi(1, max_years / 2)
	choices.append({"label": "Take a plea deal (%d–%d years)" % [plea_lo, plea_hi], "outcomes": [
		{"text": "I pleaded guilty to %s in exchange for a shorter sentence." % crime, "jail": [plea_lo, plea_hi], "crime": crime, "effects": {"karma": 2}, "ambition": {"kind":"court_case","crime":crime,"result":"plea","years":plea_hi,"evidence":evidence,"lawyer":0}}]})
	if p.get("modifiers", []).has("jail_card") and int(p.get("jail_card_year", -1)) != yr:
		choices.append({"label": "Use your Get Out of Jail Card", "outcomes": [
			{"text": "I played my Get Out of Jail Card. Case dismissed, record wiped.", "use_jail_card": true, "effects": {"happiness": 10}, "ambition": {"kind":"court_case","crime":crime,"result":"dismissed","evidence":evidence,"lawyer":0}}]})
	var troles := {}
	if lw != "":
		troles["lw"] = lw
	if cop != "":
		troles["cop"] = cop
	EventEngine.push_decision({"id": "_trial", "icon": "⚖️", "title": "The People vs. %s %s" % [p["first"], p["last"]], "text": "You've been charged with %s. You face %d to %d years.\n\nDiscovery suggests the prosecution has a %s case (%d%% evidence strength).\nHow do you fight it?" % [crime, min_years, max_years, "strong" if evidence >= 70 else ("mixed" if evidence >= 45 else "thin"), int(evidence)], "choices": choices}, troles)


func use_jail_card() -> void:
	var p := GameState.player
	p["jail_card_year"] = GameState.year_now()
	p["record"] = []
	p["prison"] = 0


func sue(npc_id: String) -> void:
	var p := GameState.player
	var n := GameState.npc(npc_id)
	if n.is_empty():
		return
	if int(p["age"]) < 18:
		EventEngine.push_info("⚖️", "Lawsuit", "You must be 18 to file a lawsuit.")
		return
	var damages := clampi(int(int(n.get("money", 5000)) * 0.4), 1500, 250000)
	var reasons := ["emotional distress", "breach of contract", "a property dispute", "defamation", "an unpaid debt"]
	var why: String = reasons[randi() % reasons.size()]
	var choices: Array = []
	var tiers := [["Represent yourself (free)", 0.2], ["Hire a lawyer (%s)" % GameState.fmt_money(_lawyer_cost(1) / 2), 0.42], ["Hire a top firm (%s)" % GameState.fmt_money(_lawyer_cost(2) / 2), 0.62]]
	for i in range(3):
		var cost := _lawyer_cost(i) / 2
		var ch := clampf(float(tiers[i][1]) + (GameState.stat("smarts") - 50) / 300.0, 0.05, 0.9)
		var c := {"label": tiers[i][0], "outcomes": [
			{"weight": ch, "text": "I won the lawsuit against %s and was awarded %s." % [n["first"], GameState.fmt_money(damages)], "effects": {"money": damages - cost, "happiness": 8}, "relationship": {"them": -60}},
			{"weight": 1.0 - ch, "text": "I lost the lawsuit against %s and had to pay court costs." % n["first"], "effects": {"money": -cost - 1500, "happiness": -6}, "relationship": {"them": -40}},
		]}
		if cost > 0:
			c["requires"] = {"money": cost}
		choices.append(c)
	choices.append({"label": "Drop it", "outcomes": [{"text": ""}]})
	EventEngine.push_decision({"id": "_sue", "icon": "⚖️", "title": "Lawsuit", "text": "You're suing %s for %s, seeking %s." % [GameState.full_name(npc_id), why, GameState.fmt_money(damages)], "choices": choices}, {"them": npc_id})
