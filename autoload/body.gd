extends Node

## BODY — what decades do.
##
## Health used to be a bar that went up when you went to the gym and down when
## something bad happened. A body is not like that. It is four slow accounts —
## how much you have moved, slept, eaten well and drunk — that are paid into or
## drawn on every year and cash out decades later, and the same lifestyle means
## something different at forty, at sixty and at eighty.
##
## Nothing here is dramatic in any single year. That is the point.

const STAGES := {
	40: {"title": "Forty", "line": "The body has started sending small, specific invoices: a knee, a back, the third reading glasses.", "fx": {"stress": 2}},
	60: {"title": "Sixty", "line": "I am no longer surprised by what hurts. I am surprised by what doesn't.", "fx": {"happiness": -1}},
	80: {"title": "Eighty", "line": "A day is a thing to plan around. The stairs are a decision.", "fx": {"stress": 2}},
}


func _p() -> Dictionary:
	return GameState.player


func st() -> Dictionary:
	var p := _p()
	if p.is_empty():
		return {}
	if not p.has("body") or not (p["body"] is Dictionary):
		p["body"] = {"fitness": 55.0, "sleep": 70.0, "diet": 55.0, "drink": 0.0, "wear": 45.0, "stages": [], "falls": 0}
	return p["body"]


func wear() -> float:
	var s := st()
	if s.is_empty():
		return 45.0
	return clampf((100.0 - float(s["fitness"])) * 0.32 + (100.0 - float(s["sleep"])) * 0.28 + (100.0 - float(s["diet"])) * 0.25 + float(s["drink"]) * 0.15, 0.0, 100.0)


## Multiplier on the chance of developing a condition.
func risk_mult() -> float:
	return 0.75 + wear() / 100.0 * 0.85


func yearly() -> void:
	var s := st()
	var p := _p()
	if s.is_empty() or GameState.in_prison():
		return
	var age := int(p["age"])
	if age < 6:
		return
	var r: Dictionary = p.get("routines", {})
	# movement
	var move := -2.0 if age < 40 else (-3.2 if age < 65 else -4.5)
	if r.get("gym", false): move += 6.0
	if r.get("walk", false): move += 3.0
	if Transit.commuting() and Transit.current() in ["walk", "bike"]: move += 2.0
	if GameState.has_job() and str(p["job"].get("field", "")) in ["Trades", "Transport", "Logistics", "Care", "Recreation"]: move += 1.5
	s["fitness"] = clampf(float(s["fitness"]) + move, 5.0, 100.0)
	# sleep
	var target := 76.0 - maxf(0.0, GameState.stat("stress") - 40.0) * 0.45
	for kid in GameState.npcs_with("child"):
		if int(GameState.npcs[kid]["age"]) < 4:
			target -= 6.0
	if r.get("meditate", false): target += 4.0
	if str(Keeping.st().get("plan", "standard")) == "unlimited" and Phrases.tech_level() >= 3: target -= 3.0
	if bool(p.get("retired", false)): target += 3.0
	s["sleep"] = clampf(float(s["sleep"]) + (target - float(s["sleep"])) * 0.3, 5.0, 100.0)
	# food
	var dt: float = {"cook": 76.0, "mixed": 56.0, "takeaway": 30.0}.get(str(Keeping.st().get("diet", "mixed")), 55.0)
	s["diet"] = clampf(float(s["diet"]) + (dt - float(s["diet"])) * 0.25, 5.0, 100.0)
	# drink
	var d := 0.0
	if Grit.active_habits().has("partying"): d += 8.0
	if age >= 18 and str(Keeping.st().get("diet", "")) == "takeaway": d += 1.0
	if GameState.has_trait("Party Animal") or GameState.has_trait("Hothead"): d += 1.0
	s["drink"] = clampf(float(s["drink"]) * 0.88 + d, 0.0, 100.0)
	# the account pays out
	var net := (50.0 - wear()) / 38.0
	net = clampf(net, -1.6, 1.0)
	GameState.change_stat("health", net)
	if age >= 40 and float(s["fitness"]) < 35.0 and randf() < 0.25:
		GameState.change_stat("looks", -0.6)
	if wear() > 72.0 and randf() < 0.15:
		GameState.add_log("I feel the years of not looking after myself. It is a dull ache, like a bill I've been ignoring.")
	elif wear() < 30.0 and randf() < 0.1:
		GameState.add_log("People tell me I look well. I think it's the years of small, dull, sensible choices.")
	# stage reckonings
	for a in STAGES.keys():
		if age == int(a) and not s["stages"].has(int(a)):
			s["stages"].append(int(a))
			var stg: Dictionary = STAGES[a]
			GameState.add_log("%s: %s" % [str(stg["title"]), str(stg["line"])])
			GameState.apply_effects(stg["fx"])
			GameState.add_milestone(age, "turned %d" % int(a))
	# late-life falls depend on how strong you stayed
	if age >= 70:
		var fall := 0.04 + (0.11 if float(s["fitness"]) < 30.0 else 0.0) + (0.06 if Care.vision() < 40.0 else 0.0) + (0.04 if age >= 80 else 0.0)
		if randf() < fall:
			s["falls"] = int(s["falls"]) + 1
			Expansion.add_injury(["fracture", "sprain", "back"][randi() % 3], "a fall at home")
			EventEngine.push_info("🪜", "A fall", "I went down in the kitchen and lay there for a while, deciding whether to call out. The recovery is long, and it is my first real fear of being alone.", {"stress": 6})


func menu() -> Dictionary:
	var s := st()
	var rows: Array = []
	var info: Array = []
	var bars := [["Movement", float(s["fitness"])], ["Sleep", float(s["sleep"])], ["Diet", float(s["diet"])], ["Alcohol and excess", float(s["drink"])]]
	for b in bars:
		info.append("%s  %s  %d" % [str(b[0]), "█".repeat(int(float(b[1]) / 10.0)) + "░".repeat(10 - int(float(b[1]) / 10.0)), int(b[1])])
	var w := wear()
	info.append("Wear on the body: %d/100 — %s" % [int(w), "kind to yourself" if w < 35.0 else ("ordinary" if w < 60.0 else "paying for it")])
	info.append("These move slowly. They are the sum of years, not of any one of them.")
	var r: Dictionary = _p().get("routines", {})
	rows.append({"icon": "@gym", "name": "Gym routine: %s" % ("ON" if r.get("gym", false) else "off"), "sub": "Movement +6 a year", "act": "real:routine", "arg": "gym", "on": int(_p()["age"]) >= 12})
	rows.append({"icon": "@road", "name": "Daily walks: %s" % ("ON" if r.get("walk", false) else "off"), "sub": "Movement +3 a year", "act": "real:routine", "arg": "walk", "on": int(_p()["age"]) >= 6})
	rows.append({"icon": "@heart", "name": "Meditation: %s" % ("ON" if r.get("meditate", false) else "off"), "sub": "Sleep and stress", "act": "real:routine", "arg": "meditate", "on": int(_p()["age"]) >= 8})
	rows.append({"icon": "@hourglass", "name": "Take a proper break", "sub": "2 time · a week of early nights", "act": "real:rest", "arg": null, "on": true})
	return {"icon": "🫀", "title": "Your body over time", "rows": rows, "info": info}


func act(key: String, arg) -> void:
	var p := _p()
	match key:
		"routine":
			var k := str(arg)
			p["routines"][k] = not bool(p["routines"].get(k, false))
		"rest":
			if not GameState.spend_time(2): return
			var s := st()
			s["sleep"] = minf(100.0, float(s["sleep"]) + 12.0)
			EventEngine.push_info("🛌", "Early nights", "For a week I went to bed at ten with a book and woke before the alarm. I'd forgotten that was possible.", {"stress": -5, "health": 1})
			GameState.apply_effects({"stress": -5, "health": 1})


func tag(t: String) -> bool:
	var s := st()
	if s.is_empty():
		return false
	match t:
		"unfit": return float(s["fitness"]) < 32.0
		"fit": return float(s["fitness"]) > 70.0
		"sleep_poor": return float(s["sleep"]) < 45.0
		"worn": return wear() > 65.0
		"well_kept": return wear() < 32.0
		"fallen": return int(s["falls"]) > 0
	return false
