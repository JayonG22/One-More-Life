extends Node

## WORKPLACE — who you work with, and what the place does to you.
##
## A job was a salary, a boss with a name and one coworker. Now it is a place:
## a manager with a temperament, colleagues with opinions about you and about
## each other, a company whose health can turn, a union you may or may not join,
## and an office whose politics decide who gets noticed. It is also where the
## ways out live: resigning well, retraining, and going it alone.

const ROLES := {
	"mentor": {"name": "Mentor", "desc": "Takes an interest in how you are doing, not just what you are doing."},
	"gossip": {"name": "Gossip", "desc": "Knows everything, and will tell you, and will tell others about you."},
	"rival": {"name": "Rival", "desc": "Is competing with you for something, and has decided not to tell you."},
	"friend": {"name": "Ally", "desc": "Sits near you and has your back."},
	"slacker": {"name": "Slacker", "desc": "Does the minimum and somehow gets away with it."},
	"climber": {"name": "Climber", "desc": "Will be your manager in five years and is already acting like it."},
}


func _p() -> Dictionary:
	return GameState.player


func w() -> Dictionary:
	var p := _p()
	if p.is_empty() or not GameState.has_job():
		return {}
	var j: Dictionary = p["job"]
	if not j.has("w") or not (j["w"] is Dictionary):
		j["w"] = {"boss_kind": "absent", "culture": "sleepy", "health": 0.7, "union": false, "politics": 50.0, "crew": [], "promotions": 0}
	return j["w"]


func begin(l: Dictionary) -> void:
	var ww := w()
	if ww.is_empty():
		return
	ww["boss_kind"] = str(l["boss"])
	ww["culture"] = str(l["culture"])
	ww["health"] = float(l["health"])
	ww["union"] = false
	ww["politics"] = 50.0
	ww["crew"] = []
	var j: Dictionary = _p()["job"]
	var existing: Array = Array(j.get("coworkers", []))
	var keys: Array = ROLES.keys()
	keys.shuffle()
	var need := 3 - existing.size()
	for i in range(maxi(0, need)):
		var id := GameState.create_npc("coworker", {"age": clampi(int(_p()["age"]) + randi_range(-8, 14), 18, 64), "closeness": randi_range(30, 55)})
		existing.append(id)
	j["coworkers"] = existing
	for i2 in range(existing.size()):
		var cid: String = existing[i2]
		if GameState.npcs.has(cid):
			GameState.npcs[cid]["work_role"] = keys[i2 % keys.size()]
			ww["crew"].append(cid)
	Employment.setup_team()


func crew() -> Array:
	var out: Array = []
	for id in w().get("crew", []):
		if GameState.npcs.has(id) and GameState.npcs[id]["alive"]:
			out.append(id)
	return out


func yearly() -> void:
	var p := _p()
	var ww := w()
	if ww.is_empty() or GameState.in_prison():
		return
	var j: Dictionary = p["job"]
	# the manager
	match str(ww["boss_kind"]):
		"supportive":
			GameState.apply_effects({"stress": -1.5, "job_perf": 1.5})
		"micromanager":
			GameState.apply_effects({"stress": 2.5, "job_perf": 1.0, "happiness": -1})
		"absent":
			j["perf"] = clampf(float(j["perf"]) - 0.8, 0.0, 100.0)
		"brilliant":
			GameState.apply_effects({"smarts": 0.6, "stress": 1.5})
			Market.add_experience(str(j.get("field", "")), 0)
		"political":
			GameState.apply_effects({"stress": 1.0})
			ww["politics"] = clampf(float(ww["politics"]) + randf_range(-6.0, 6.0), 0.0, 100.0)
	# the culture
	match str(ww["culture"]):
		"friendly": GameState.apply_effects({"happiness": 1.2})
		"cutthroat": GameState.apply_effects({"stress": 2.0, "job_perf": 1.0})
		"chaotic": GameState.apply_effects({"stress": 1.5})
	# colleagues
	for id in crew():
		var n: Dictionary = GameState.npcs[id]
		match str(n.get("work_role", "friend")):
			"mentor":
				GameState.apply_effects({"smarts": 0.4, "job_perf": 0.8})
				GameState.change_closeness(id, 2)
			"gossip":
				if randf() < 0.3:
					GameState.add_log("%s told me something about the office I'd rather not have known." % n["first"])
					GameState.apply_effects({"stress": 1})
			"rival":
				if randf() < 0.2:
					GameState.add_log("%s took credit for something in a meeting. We smiled at each other." % n["first"])
					GameState.apply_effects({"stress": 2.5, "job_perf": -1.5})
					GameState.change_closeness(id, -4)
			"friend":
				GameState.apply_effects({"happiness": 0.8})
			"slacker":
				if randf() < 0.15:
					GameState.apply_effects({"stress": 1.5})
			"climber":
				ww["politics"] = clampf(float(ww["politics"]) - 1.0, 0.0, 100.0)
	# the union
	j["union_dues_due"] = 0
	if bool(ww["union"]):
		j["salary"] = int(float(j["salary"]) * 1.01)
		j["union_dues_due"] = int(float(j["salary"]) * 0.01)
	# the company
	var h := float(ww["health"])
	h += randf_range(-0.12, 0.10)
	if World.active("recession"):
		h -= 0.08
	if World.active("boom"):
		h += 0.05
	h += Workforce.climate(str(j.get("field", ""))) * 0.5
	ww["health"] = clampf(h, 0.0, 1.0)
	if float(ww["health"]) < 0.3 and randf() < (0.22 if not bool(ww["union"]) else 0.12):
		_redundancy()
		return
	if float(ww["health"]) < 0.4 and randf() < 0.25:
		GameState.add_log("There was a hiring freeze at %s, and then a restructuring. The coffee machine went." % str(j.get("employer_name", "work")))
		GameState.apply_effects({"stress": 3})


func _redundancy() -> void:
	var p := _p()
	var j: Dictionary = p["job"]
	var ww := w()
	var months := clampi(int(j.get("years", 1)) + 2, 2, 14) * (2 if bool(ww.get("union", false)) else 1)
	var sev := int(float(j["salary"]) / 12.0 * float(mini(months, 18)) * 0.5)
	p["money"] = int(p["money"]) + sev
	var title: String = str(j["title"])
	var co: String = str(j.get("employer_name", "the company"))
	_reference_on_leaving(true)
	Actions.lose_job("laid_off")
	GameState.add_log("%s made my role redundant. The severance was %s and a leaving card I've kept." % [co, GameState.fmt_money(sev)])
	GameState.add_milestone(int(p["age"]), "was made redundant")
	GameState.apply_effects({"stress": 9, "happiness": -8})
	EventEngine.push_info("📦", "Made redundant", "%s said the role no longer existed. I carried a box to my car with a colleague pretending not to watch. Severance: %s." % [co, GameState.fmt_money(sev)], {"stress": 9, "happiness": -8})


func _reference_on_leaving(good: bool) -> void:
	if not good:
		return
	var j: Dictionary = _p()["job"]
	var boss: String = str(j.get("boss", ""))
	var strength := clampf(float(j.get("perf", 50.0)) / 100.0 + (0.15 if boss != "" and GameState.npcs.has(boss) and int(GameState.npcs[boss]["closeness"]) > 55 else 0.0), 0.1, 1.0)
	if bool(j.get("probation_passed",false)): strength=minf(1.0,strength+0.05)
	if strength >= 0.45:
		Market.st()["refs"].append({"who": boss, "strength": strength, "co": str(j.get("employer_name", ""))})


# ------------------------------------------------------------------ the ways out

func menu() -> Dictionary:
	var p := _p()
	var rows: Array = []
	var info: Array = []
	var ww := w()
	if not ww.is_empty():
		var j: Dictionary = p["job"]
		info.append("%s at %s  ·  %s" % [str(j["title"]), str(j.get("employer_name", "the firm")), GameState.fmt_money(int(j["salary"]))])
		info.append("Boss: %s — %s" % [str(Market.BOSSES[str(ww["boss_kind"])]["name"]), str(Market.BOSSES[str(ww["boss_kind"])]["desc"])])
		info.append("Culture: %s — %s" % [str(Market.CULTURES[str(ww["culture"])]["name"]), str(Market.CULTURES[str(ww["culture"])]["desc"])])
		var hl := "thriving" if float(ww["health"]) > 0.7 else ("steady" if float(ww["health"]) > 0.45 else "wobbling")
		info.append("The company looks %s  ·  politics %d/100  ·  %s" % [hl, int(ww["politics"]), "union member" if bool(ww["union"]) else "not in the union"])
		for id in crew():
			var n: Dictionary = GameState.npcs[id]
			var r: Dictionary = ROLES.get(str(n.get("work_role", "friend")), ROLES["friend"])
			info.append("%s %s — %s. %s" % [n["first"], n["last"], str(r["name"]), str(r["desc"])])
		var lunch_fee := Actions._cost(28)
		var has_colleague := not crew().is_empty()
		var lunch_ready := has_colleague and int(p["money"])>=lunch_fee
		var lunch_sub := "No colleague available"
		if has_colleague:
			if lunch_ready:
				lunch_sub="1 time · %s · builds trust" % GameState.fmt_money(lunch_fee)
			else:
				lunch_sub="Need cash · %s" % GameState.fmt_money(lunch_fee)
		rows.append({"icon": "@handshake", "name": "Join the union" if not bool(ww["union"]) else "Leave the union", "sub": "End dues and union protections" if bool(ww["union"]) else "1% annual dues · lower layoff risk and longer severance", "act": "real:union", "arg": null, "on": true})
		rows.append({"icon": "@heart", "name": "Take a colleague to lunch", "sub": lunch_sub, "act": "real:lunch", "arg": null, "on": lunch_ready})
		rows.append({"icon": "@star", "name": "Play the politics", "sub": "Be seen. It can backfire", "act": "real:politics", "arg": null, "on": true})
		rows.append({"icon": "@envelope", "name": "Give notice", "sub": "A manager reference depends on your performance", "act": "real:resign", "arg": null, "on": true})
	else:
		var fl: Dictionary = p.get("freelance", {})
		if fl.is_empty():
			info.append("Not employed · openings are under Occupation → Find a job.")
			rows.append({"icon": "🧑‍💻", "name": "Go freelance", "sub": "2+ years in a field. Variable income", "act": "real:freelance", "arg": null, "on": _best_field() != ""})
		else:
			info.append("Freelancing in %s  ·  %d clients  ·  rate %s" % [str(fl["field"]), int(fl["clients"]), GameState.fmt_money(int(fl["rate"]))])
			rows.append({"icon": "📣", "name": "Pitch for new clients", "sub": "1 time · more clients, sometimes bigger ones", "act": "real:pitch", "arg": null, "on": true})
			rows.append({"icon": "🧾", "name": "Wind it down", "sub": "Stop freelancing", "act": "real:stop_freelance", "arg": null, "on": true})
	return {"icon": "🏢", "title": "Workplace & freelance", "rows": rows, "info": info}


func _best_field() -> String:
	var best := ""
	var yrs := 1
	for f in Market.st().get("exp", {}).keys():
		if int(Market.st()["exp"][f]) > yrs:
			yrs = int(Market.st()["exp"][f])
			best = str(f)
	return best


func act(key: String, arg) -> void:
	var p := _p()
	var ww := w()
	match key:
		"union":
			if ww.is_empty(): return
			ww["union"] = not bool(ww["union"])
			GameState.add_log("I %s the union." % ("joined" if ww["union"] else "left"))
		"lunch":
			var people := crew()
			var fee := Actions._cost(28)
			if people.is_empty(): return
			if int(p["money"])<fee:
				EventEngine.push_info("💸","Lunch","You need %s in cash before inviting a colleague." % GameState.fmt_money(fee))
				return
			if not GameState.spend_time(1): return
			var id: String = people[randi() % people.size()]
			p["money"] = int(p["money"]) - fee
			GameState.change_closeness(id, 10)
			var n: Dictionary = GameState.npcs[id]
			EventEngine.push_info("☕", "Lunch with %s" % n["first"], "We talked about everything except work, which is how I learned most of what I know about work.", {"happiness": 2})
			GameState.apply_effects({"happiness": 2})
		"politics":
			if ww.is_empty() or not GameState.spend_time(1): return
			if randf() < 0.55:
				ww["politics"] = clampf(float(ww["politics"]) + randf_range(8.0, 16.0), 0.0, 100.0)
				p["job"]["perf"] = clampf(float(p["job"]["perf"]) + 3.0, 0.0, 100.0)
				EventEngine.push_info("🎯", "Being seen", "I stayed late for the right meeting and said the right thing to the right person. It was uncomfortable how well it worked.", {"stress": 2})
			else:
				ww["politics"] = clampf(float(ww["politics"]) - randf_range(4.0, 10.0), 0.0, 100.0)
				EventEngine.push_info("🎯", "Being seen", "I was seen, and what they saw was somebody trying to be seen. A colleague sent me a small, knowing look.", {"stress": 4, "happiness": -2})
		"resign":
			if ww.is_empty(): return
			_reference_on_leaving(float(p["job"].get("perf", 50)) >= 45.0)
			Actions.lose_job("quit")
			GameState.add_log("I gave two weeks' notice and left on good terms. I kept the card.")
			GameState.apply_effects({"stress": -3, "happiness": 2})
		"retrain":
			EventEngine.push_info("🧰","Choose training","Open Work & independence → Training. Choose a field, complete practical units and pass its assessment.")
		"freelance":
			var f := _best_field()
			if f == "": return
			p["freelance"] = {"field": f, "clients": 1, "rate": int(2600 + 900 * Market.experience(f)), "since": int(p["age"]), "late": 0}
			GameState.add_log("I went freelance in %s. My first client paid late, which I have been told is tradition." % f)
			GameState.apply_effects({"stress": 3, "happiness": 3})
		"pitch":
			var fl: Dictionary = p.get("freelance", {})
			if fl.is_empty() or not GameState.spend_time(1): return
			if randf() < 0.6:
				fl["clients"] = int(fl["clients"]) + 1
				fl["rate"] = int(float(fl["rate"]) * 1.04)
				EventEngine.push_info("📣", "New client", "A reply at 11 p.m.: 'Can you start Monday?' I answered in under a minute.", {"happiness": 3})
			else:
				EventEngine.push_info("📣", "No reply", "Six pitches, one acknowledgement, and a polite no. I took a walk.", {"stress": 2})
		"stop_freelance":
			p["freelance"] = {}


## Self-employed income, taxed, variable and sometimes late.
func freelance_yearly() -> void:
	var p := _p()
	var fl: Dictionary = p.get("freelance", {})
	if fl.is_empty() or GameState.has_job():
		return
	Market.add_experience(str(fl["field"]), 1)
	var gross := int(float(fl["rate"]) * float(fl["clients"]) * randf_range(0.55, 1.35))
	var late := randf() < 0.25
	if late:
		gross = int(gross * 0.7)
		fl["late"] = int(fl.get("late", 0)) + 1
		GameState.add_log("A client paid three months late and then asked for a discount.")
	var tax := int(gross * 0.22)
	var paperwork := Actions._cost(600)
	var net := gross - tax - paperwork
	p["money"] = int(p["money"]) + net
	Employment.record_income("Freelance net income",net)
	p["last_income"] = net
	GameState.add_log("Freelancing brought in %s before tax, %s after tax and the accountant." % [GameState.fmt_money(gross), GameState.fmt_money(net)])
	GameState.apply_effects({"stress": 2.5 if late else 1.0})


func tag(t: String) -> bool:
	var ww := w()
	var p := _p()
	match t:
		"freelance": return not p.is_empty() and not p.get("freelance", {}).is_empty()
		"union": return not ww.is_empty() and bool(ww.get("union", false))
		"no_union": return not ww.is_empty() and not bool(ww.get("union", false))
		"company_shaky": return not ww.is_empty() and float(ww.get("health", 1.0)) < 0.45
		"political_office": return not ww.is_empty() and float(ww.get("politics", 0.0)) >= 60.0
	if t.begins_with("boss:"):
		return not ww.is_empty() and str(ww.get("boss_kind", "")) == t.substr(5)
	if t.begins_with("culture:"):
		return not ww.is_empty() and str(ww.get("culture", "")) == t.substr(8)
	if t.begins_with("colleague:"):
		for id in crew():
			if str(GameState.npcs[id].get("work_role", "")) == t.substr(10):
				return true
		return false
	return false
