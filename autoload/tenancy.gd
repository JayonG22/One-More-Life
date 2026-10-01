extends Node

## TENANCY — renting a place to live, and everything that comes with it.
##
## Being an adult in a rented flat used to be one number: a rent line in the
## yearly bill. Nobody owned the flat, nobody owned you, and nothing ever broke.
## Now there is a landlord with a temperament, a deposit you may or may not see
## again, rent that rises, a boiler with an age, damp that spreads when it is
## ignored, flatmates who help with the bills and sometimes become the problem,
## and the chance of a letter telling you the owner is selling.
##
## It starts itself: when the player's housing becomes "apartment" a tenancy
## opens, and when it stops being one the deposit is settled.

const LANDLORDS := {
	"kind": {"name": "Kind", "desc": "Fixes things without being asked and forgets to put the rent up.", "repair": 0.95, "deposit": 1.0, "rise": 0.4, "notice": 0.01},
	"fair": {"name": "Fair", "desc": "Sensible, a little slow, will do right by you if you are reasonable.", "repair": 0.75, "deposit": 0.9, "rise": 1.0, "notice": 0.03},
	"absent": {"name": "Absent", "desc": "Lives abroad. Answers email in the third week. The boiler is your problem.", "repair": 0.35, "deposit": 0.75, "rise": 0.8, "notice": 0.04},
	"grasping": {"name": "Grasping", "desc": "Every clause is a lever. Finds a reason to keep the deposit.", "repair": 0.5, "deposit": 0.45, "rise": 2.0, "notice": 0.09},
}
const KIND_WEIGHTS := {"kind": 0.2, "fair": 0.4, "absent": 0.25, "grasping": 0.15}


func _p() -> Dictionary:
	return GameState.player


func renting() -> bool:
	var p := _p()
	return not p.is_empty() and str(p.get("housing", "")) == "apartment"


func st() -> Dictionary:
	var p := _p()
	if p.is_empty():
		return {}
	if not p.has("tenancy") or not (p["tenancy"] is Dictionary):
		p["tenancy"] = {"active": false}
	return p["tenancy"]


func active() -> bool:
	return bool(st().get("active", false))


## Open or close the tenancy to match where the player actually lives.
func sync() -> void:
	var t := st()
	if t.is_empty():
		return
	if renting() and not bool(t.get("active", false)):
		_start()
	elif not renting() and bool(t.get("active", false)):
		_end("moved out")


func _market_rent() -> int:
	var h := float(Places.region().get("housing", 1.0))
	return int(round(14000.0 * (0.55 + 0.45 * h) / 500.0)) * 500


func _roll_kind() -> String:
	var r := randf()
	var acc := 0.0
	for k in KIND_WEIGHTS.keys():
		acc += float(KIND_WEIGHTS[k])
		if r <= acc:
			return str(k)
	return "fair"


func _start(rent_mult: float = 1.0) -> void:
	var t := st()
	var g := "male" if randf() < 0.5 else "female"
	var c := str(_p().get("country", "us"))
	t.clear()
	t["active"] = true
	t["since"] = int(_p().get("age", 18))
	t["rent"] = int(round(float(_market_rent()) * rent_mult / 100.0)) * 100
	t["deposit"] = int(float(t["rent"]) / 12.0 * 1.5)
	t["kind"] = _roll_kind()
	t["landlord"] = "%s %s" % [ContentDB.random_first(g, c), ContentDB.random_last(c)]
	t["boiler_age"] = randi_range(1, 14)
	t["damp"] = float(randi_range(0, 20))
	t["insulated"] = false
	t["insured"] = false
	t["mates"] = []
	t["years"] = 0
	t["rises"] = 0
	GameState.add_log("I signed a lease on a flat. The landlord, %s, seemed %s." % [t["landlord"], str(LANDLORDS[t["kind"]]["name"]).to_lower()])


func _end(reason: String) -> void:
	var t := st()
	if not bool(t.get("active", false)):
		return
	var kd: Dictionary = LANDLORDS.get(str(t.get("kind", "fair")), LANDLORDS["fair"])
	var back := int(float(t.get("deposit", 0)) * float(kd["deposit"]) * (1.0 - float(t.get("damp", 0)) / 250.0))
	if int(t.get("deposit", 0)) > 0:
		_p()["money"] = int(_p()["money"]) + back
		if back < int(t.get("deposit", 0)) * 0.6:
			GameState.add_log("My landlord kept most of the deposit: %s of %s came back." % [GameState.fmt_money(back), GameState.fmt_money(int(t["deposit"]))])
		else:
			GameState.add_log("I got %s of my deposit back." % GameState.fmt_money(back))
	t["active"] = false
	t["mates"] = []


func mates() -> Array:
	var out: Array = []
	for id in st().get("mates", []):
		if GameState.npcs.has(id) and GameState.npcs[id]["alive"]:
			out.append(id)
	return out


## What the rent costs this year, split with whoever lives there.
func annual_rent() -> int:
	if not renting():
		return 0
	sync()
	var t := st()
	return int(float(t.get("rent", _market_rent())) / float(1 + mates().size()))


## Gas, electric and water. Insulation and climate both move it.
func utilities() -> int:
	if not renting():
		return 0
	var t := st()
	var base := 2200.0
	var hz := str(Places.region().get("hazard", ""))
	if hz in ["blizzard", "heatwave", "frostbite"]:
		base *= 1.25
	if bool(t.get("insulated", false)):
		base *= 0.85
	return int(base / float(1 + mates().size() * 0.5))


func yearly() -> void:
	sync()
	var t := st()
	if t.is_empty() or not bool(t.get("active", false)):
		return
	if GameState.in_prison():
		return
	var kd: Dictionary = LANDLORDS[str(t["kind"])]
	t["years"] = int(t["years"]) + 1
	t["boiler_age"] = int(t["boiler_age"]) + 1
	# rent moves with the market and with the landlord
	var pressure := float(Places.region().get("housing", 1.0))
	var rate := (0.015 + pressure * 0.02 + randf() * 0.03) * float(kd["rise"])
	if rate > 0.0:
		t["rent"] = int(round(float(t["rent"]) * (1.0 + rate) / 50.0)) * 50
		t["rises"] = int(t["rises"]) + 1
		if rate >= 0.045:
			GameState.add_log("My rent went up %d%%. %s" % [int(round(rate * 100.0)), "I couldn't say it was a surprise." if str(t["kind"]) == "grasping" else "The letter called it 'in line with the market'."])
	# the boiler
	var bp := 0.25 if int(t["boiler_age"]) > 9 else 0.04
	if randf() < bp:
		if randf() < float(kd["repair"]):
			t["boiler_age"] = 1
			GameState.add_log("The boiler died in winter. %s had it replaced within the week." % str(t["landlord"]))
		else:
			GameState.apply_effects({"health": -3, "stress": 5, "happiness": -3})
			GameState.add_log("The boiler died and %s took six weeks to do anything about it. I wore my coat indoors." % str(t["landlord"]))
	# damp spreads when nobody deals with it
	t["damp"] = clampf(float(t["damp"]) + randf() * 9.0 - (6.0 if bool(t.get("insulated", false)) else 0.0) * 0.5, 0.0, 100.0)
	if float(t["damp"]) > 55.0:
		GameState.apply_effects({"health": -2, "stress": 3})
		if randf() < 0.3:
			GameState.add_log("There is black mould behind the wardrobe. I breathe it in every night.")
			if randf() < 0.15:
				Expansion.ensure()
	# flatmates
	for id in mates():
		var n: Dictionary = GameState.npcs[id]
		var r := randf()
		if r < 0.12:
			GameState.add_log("%s moved out. My share of the rent went back up." % n["first"])
			t["mates"].erase(id)
		elif r < 0.2:
			GameState.add_log("%s left the dishes for a fortnight and ate my leftovers. We had words." % n["first"])
			GameState.change_closeness(id, -8)
			GameState.apply_effects({"stress": 3})
		else:
			GameState.change_closeness(id, 2)
	# the letter
	var np := float(kd["notice"]) + (0.05 if int(_p().get("money", 0)) < 0 else 0.0)
	if randf() < np:
		_move_out_forced()


func _move_out_forced() -> void:
	var p := _p()
	_end("notice")
	var fee := Actions._cost(1800)
	p["money"] = int(p["money"]) - fee
	GameState.apply_effects({"stress": 8, "happiness": -4})
	GameState.add_log("My landlord sold up. I had sixty days to find somewhere, and a van cost %s." % GameState.fmt_money(fee))
	GameState.add_milestone(int(p["age"]), "was given notice on a flat")
	_start()


# ------------------------------------------------------------------ menu

func _row(icon: String, name: String, sub: String, act: String, arg = null, on: bool = true) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "act": "real:" + act, "arg": arg, "on": on}


func menu() -> Dictionary:
	sync()
	var t := st()
	var rows: Array = []
	var info: Array = []
	if not bool(t.get("active", false)):
		return {"icon": "🔑", "title": "Your tenancy", "rows": rows, "info": ["You are not renting a place at the moment."]}
	var kd: Dictionary = LANDLORDS[str(t["kind"])]
	info.append("Landlord %s — %s. %s" % [str(t["landlord"]), str(kd["name"]), str(kd["desc"])])
	info.append("Rent %s a year (%s a month)%s  ·  deposit held %s" % [GameState.fmt_money(annual_rent()), GameState.fmt_money(annual_rent() / 12), " shared with %d" % mates().size() if not mates().is_empty() else "", GameState.fmt_money(int(t["deposit"]))])
	info.append("Boiler %d years old  ·  damp %d%%  ·  bills %s a year%s" % [int(t["boiler_age"]), int(t["damp"]), GameState.fmt_money(utilities()), "  ·  insulated" if bool(t.get("insulated", false)) else ""])
	rows.append(_row("🛠️", "Ask for repairs", "Damp and the boiler. Chance depends on the landlord", "repairs"))
	rows.append(_row("🤝", "Negotiate the rent", "Bring evidence. A reasonable landlord may listen", "negotiate"))
	rows.append(_row("🧑‍🤝‍🧑", "Find a flatmate", "Halves the rent, and doubles the ways it can go wrong", "flatmate", null, mates().size() < 2))
	rows.append(_row("🧥", "Draught-proof and insulate", "%s · lower bills, less damp" % GameState.fmt_money(Actions._cost(1200)), "insulate", null, not bool(t.get("insulated", false))))
	rows.append(_row("📄", "Contents insurance", "%s a year · covers break-ins and fires" % GameState.fmt_money(Actions._cost(300)), "insure", null, not bool(t.get("insured", false))))
	rows.append(_row("📦", "Move to a smaller, cheaper place", "About a quarter off the rent; you feel it", "move", "small"))
	rows.append(_row("📦", "Move somewhere nicer", "About a third more; you also feel that", "move", "nice"))
	return {"icon": "🔑", "title": "Your tenancy", "rows": rows, "info": info}


func act(key: String, arg) -> void:
	var t := st()
	if not bool(t.get("active", false)):
		return
	var kd: Dictionary = LANDLORDS[str(t["kind"])]
	match key:
		"repairs":
			if Actions._out_of_time():
				return
			var ok := randf() < float(kd["repair"])
			if ok:
				t["damp"] = maxf(0.0, float(t["damp"]) - 45.0)
				if int(t["boiler_age"]) > 9:
					t["boiler_age"] = 2
				Actions._done("🛠️", "Repairs", "%s sent someone. The damp patch is gone and the boiler has a new lease of life." % str(t["landlord"]), {"stress": -4, "happiness": 2})
			else:
				Actions._done("🛠️", "Repairs", "%s said it would be 'looked at'. Nothing happened, and I kept the emails." % str(t["landlord"]), {"stress": 4})
		"negotiate":
			if Actions._out_of_time():
				return
			var skill := GameState.stat("smarts") * 0.5 + 25.0 + (15.0 if str(t["kind"]) == "kind" else 0.0) - (10.0 if str(t["kind"]) == "grasping" else 0.0)
			Minigames.play("haggle", {"subject": "the rent", "skill": skill, "difficulty": 1.0 + (0.2 if str(t["kind"]) == "grasping" else 0.0)},
				func(score: float, detail: Dictionary) -> void: _rent_haggle_done(score, detail))
		"flatmate":
			if mates().size() >= 2 or Actions._out_of_time():
				return
			var id := GameState.create_npc("friend", {"age": clampi(int(_p()["age"]) + randi_range(-5, 6), 18, 60), "closeness": randi_range(25, 55)})
			t["mates"].append(id)
			Actions._done("🧑‍🤝‍🧑", "A flatmate", "%s moved into the spare room. Our shared shelf lasted one week." % GameState.npcs[id]["first"], {"happiness": 2, "stress": 2})
		"insulate":
			var fee := Actions._cost(1200)
			if not Actions._can_pay(fee, "Insulation") or Actions._out_of_time():
				return
			_p()["money"] = int(_p()["money"]) - fee
			t["insulated"] = true
			t["damp"] = maxf(0.0, float(t["damp"]) - 20.0)
			Actions._done("🧥", "Insulation", "Foam strips, a door snake and a heavy curtain. The flat stopped whistling.", {"stress": -2, "happiness": 1})
		"insure":
			t["insured"] = true
			_p()["money"] = int(_p()["money"]) - Actions._cost(300)
			Actions._done("📄", "Contents insurance", "I read the small print and only partly understood it. I felt responsible.", {"stress": -2})
		"move":
			var fee2 := Actions._cost(1800)
			if not Actions._can_pay(fee2, "Moving") or Actions._out_of_time():
				return
			_p()["money"] = int(_p()["money"]) - fee2
			_end("moved")
			var small := str(arg) == "small"
			_start(0.75 if small else 1.33)
			Actions._done("📦", "New place", "I packed my life into boxes again. The new flat was %s." % ("smaller than the photos" if small else "lighter than the old one"), {"happiness": -1 if small else 3, "stress": 4})


# ------------------------------------------------------------------ conditions and outcomes

func _rent_haggle_done(score: float, detail: Dictionary) -> void:
	var t := st()
	if not bool(t.get("active", false)):
		return
	if bool(detail.get("walked", false)) and not detail.get("auto", false):
		t["notice_risk"] = true
		Actions._done("🤝", "Negotiation", "I asked for too much and %s ended the conversation. I felt I had used up some goodwill." % str(t["landlord"]), {"stress": 4})
		return
	var pct := 2.0 + 9.0 * clampf(score, 0.0, 1.0)
	if detail.get("auto", false):
		pct = 0.0 if randf() < 0.55 else randf_range(3.0, 8.0)
	if pct < 1.0:
		Actions._done("🤝", "Negotiation", "%s was polite and immovable." % str(t["landlord"]), {"stress": 3})
		return
	t["rent"] = int(round(float(t["rent"]) * (1.0 - pct / 100.0) / 50.0)) * 50
	Actions._done("🤝", "Negotiation", "I made my case and %s came down by %d%%." % [str(t["landlord"]), int(round(pct))], {"happiness": 4})


func tag(t: String) -> bool:
	var s := st()
	var act_ := bool(s.get("active", false))
	match t:
		"renting": return act_
		"flatmate": return act_ and not mates().is_empty()
		"no_flatmate": return act_ and mates().is_empty()
		"damp": return act_ and float(s.get("damp", 0)) >= 40.0
		"boiler_old": return act_ and int(s.get("boiler_age", 0)) >= 9
		"insured_home": return act_ and bool(s.get("insured", false))
		"uninsured_home": return act_ and not bool(s.get("insured", false))
	if t.begins_with("landlord:"):
		return act_ and str(s.get("kind", "")) == t.substr(9)
	return false


func apply(ops: Dictionary) -> void:
	var t := st()
	if not bool(t.get("active", false)):
		return
	if ops.has("rent_pct"):
		t["rent"] = int(round(float(t["rent"]) * (1.0 + float(ops["rent_pct"]) / 100.0) / 50.0)) * 50
	if ops.has("deposit_loss"):
		t["deposit"] = int(float(t["deposit"]) * (1.0 - float(ops["deposit_loss"]) / 100.0))
	if ops.has("damp"):
		t["damp"] = clampf(float(t["damp"]) + float(ops["damp"]), 0.0, 100.0)
	if ops.has("boiler_age"):
		t["boiler_age"] = maxi(1, int(t["boiler_age"]) + int(ops["boiler_age"]))
	if ops.get("flatmate_leaves", false) and not mates().is_empty():
		t["mates"].erase(mates()[0])
	if ops.get("new_landlord", false):
		t["kind"] = _roll_kind()
	if ops.get("forced_move", false):
		_move_out_forced()
