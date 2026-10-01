extends Node

## TRANSIT — getting about, and what it costs in time, money and temper.
##
## A commute is where much of a working life is spent, and none of it used to
## exist. Now the way you get to work is a choice with consequences that depend
## on where you live: a pass that is a bargain in a city with trains is pointless
## in a county with none, walking is a pleasure at ten minutes and a chore at
## sixty, and a car is freedom with an insurance bill attached.
##
## The bill is honest. Premiums follow age, record and claims; driving without
## cover is a gamble with a fine at the end of it; and the first crash, which
## most drivers have before they are twenty-five, is a real event with a real
## shape rather than a line of text.

const MODES := {
	"walk": {"name": "Walk", "icon": "🚶", "speed": 0.35},
	"bike": {"name": "Cycle", "icon": "🚲", "speed": 0.75},
	"bus": {"name": "Bus", "icon": "🚌", "speed": 0.8},
	"train": {"name": "Train", "icon": "🚆", "speed": 1.0},
	"drive": {"name": "Drive", "icon": "🚗", "speed": 1.3},
	"remote": {"name": "Work from home", "icon": "🏠", "speed": 99.0},
}
const COVER := {
	"none": {"name": "No insurance", "icon": "🚫", "base": 0},
	"third": {"name": "Third party", "icon": "🛡️", "base": 650},
	"full": {"name": "Comprehensive", "icon": "🛡️", "base": 1500},
}


func _p() -> Dictionary:
	return GameState.player


func st() -> Dictionary:
	var p := _p()
	if p.is_empty():
		return {}
	if not p.has("transit") or not (p["transit"] is Dictionary):
		p["transit"] = {"mode": "auto", "cover": "third", "no_claims": 0, "crashes": [], "serviced": false, "fines": 0, "commute_min": 0}
	return p["transit"]


func transit_score() -> float:
	return float(Places.region().get("transit", 0.5))


func has_car() -> bool:
	return not _p().is_empty() and str(_p().get("car", "")) != ""


func commuting() -> bool:
	var p := _p()
	if p.is_empty() or GameState.in_prison() or int(p.get("age", 0)) < 12:
		return false
	return GameState.has_job() or GameState.in_school() or GameState.in_university()


func available(mode: String) -> bool:
	match mode:
		"walk", "bike": return true
		"bus": return transit_score() >= 0.25
		"train": return transit_score() >= 0.6
		"drive": return has_car() and int(_p().get("age", 0)) >= 16
		"remote": return GameState.has_job() and int(_p().get("age", 0)) >= 18 and (Phrases.tech_level() >= 2) and _remote_job()
	return false


## How you would actually get somewhere beyond the neighbourhood: the best way open to you.
func reach_mode() -> String:
	if int(_p().get("travel_pass", -9)) == int(_p().get("age", 0)):
		return "drive"
	if has_car() and int(_p().get("age", 0)) >= 16:
		return "drive"
	if available("train"):
		return "train"
	if available("bus"):
		return "bus"
	if Shop.has_any(["bike"]):
		return "bike"
	return "walk"


## How far a trip is (near · far · trip) against how you would get there. Returns the
## multiplier on the good outcomes and a line that tells the player why.
func reach(dist: String) -> Dictionary:
	var mode := reach_mode()
	var table := {
		"near": {"walk": 1.0, "bike": 1.05, "bus": 1.0, "train": 1.0, "drive": 1.05},
		"far": {"walk": 0.4, "bike": 0.8, "bus": 0.9, "train": 1.05, "drive": 1.2},
		"trip": {"walk": 0.12, "bike": 0.25, "bus": 0.7, "train": 1.0, "drive": 1.25},
	}
	var m: float = float(table.get(dist, table["near"]).get(mode, 1.0))
	var ic: String = str(MODES.get(mode, MODES["walk"])["icon"])
	var hint := ""
	if dist == "near":
		return {"mult": m, "mode": mode, "hint": ""}
	match mode:
		"walk": hint = "%s On foot this is a long way: slim odds. A bike, a pass or a car would help." % ic
		"bike": hint = "%s By bike it is doable but tiring." % ic if dist == "far" else "%s By bike it is too far to rely on." % ic
		"bus": hint = "%s The bus gets you there, slowly." % ic
		"train": hint = "%s The train gets you there on time." % ic
		"drive": hint = "%s You can drive it: good odds." % ic
	return {"mult": m, "mode": mode, "hint": hint}


func _remote_job() -> bool:
	if not GameState.has_job():
		return false
	var t := str(_p()["job"].get("title", "")).to_lower()
	for w in ["developer", "engineer", "analyst", "writer", "designer", "accountant", "consultant", "manager", "editor", "programmer", "teacher"]:
		if t.find(w) != -1:
			return true
	return false


func base_minutes() -> int:
	var sprawl := 1.0 - transit_score()
	var school_bonus := 0.5 if not GameState.has_job() else 1.0
	return int(round((18.0 + 42.0 * sprawl) * school_bonus))


func minutes(mode: String) -> int:
	if mode == "remote":
		return 0
	var traffic := 1.0 + (1.0 - transit_score()) * 0.3 if mode == "drive" else 1.0
	return int(round(float(base_minutes()) / float(MODES[mode]["speed"]) * 0.75 * traffic * (1.0 if mode != "walk" else 1.0)))


## The mode in effect: the chosen one if it still works, otherwise the best one left.
func current() -> String:
	var s := st()
	if s.is_empty():
		return "walk"
	var m := str(s.get("mode", "auto"))
	if m != "auto" and available(m):
		return m
	for cand in ["drive", "train", "bus"]:
		if available(cand):
			return cand
	if base_minutes() <= 55:
		return "bike"
	return "walk"


func time_points(mode: String) -> int:
	var mins := minutes(mode)
	if mins < 22: return 0
	if mins < 40: return 1
	if mins < 65: return 2
	return 3


func premium() -> int:
	if not has_car():
		return 0
	var s := st()
	var base := int(COVER[str(s.get("cover", "third"))]["base"])
	if base <= 0:
		return 0
	var age := int(_p().get("age", 18))
	var m := 1.0
	if age < 21: m = 2.8
	elif age < 25: m = 2.0
	elif age < 30: m = 1.3
	elif age >= 75: m = 1.5
	elif age >= 70: m = 1.25
	m *= maxf(0.45, 1.0 - 0.06 * float(mini(int(s.get("no_claims", 0)), 9)))
	m *= 1.0 + 0.4 * float(_recent_crashes())
	m *= 0.85 + 0.3 * float(Places.region().get("crime", 1.0))
	if Wanted.stars() >= 2:
		m *= 1.5
	return int(round(float(base) * m / 10.0)) * 10


func _recent_crashes() -> int:
	var n := 0
	var age := int(_p().get("age", 0))
	for a in st().get("crashes", []):
		if age - int(a) <= 4:
			n += 1
	return n


func _mode_cost(mode: String) -> int:
	match mode:
		"bus": return int(900.0 + 700.0 * transit_score())
		"train": return int(1400.0 + 900.0 * transit_score())
		"bike": return 120
		"drive":
			var parking := 1500 if transit_score() >= 0.7 else 0
			return 900 + base_minutes() * 18 + parking
	return 0


## Everything getting about adds to the yearly bill (before the country multiplier).
func costs() -> int:
	if not commuting() and not has_car():
		return 0
	var total := 0
	if commuting():
		total += _mode_cost(current())
	total += premium()
	return total


func yearly() -> void:
	var s := st()
	if s.is_empty() or GameState.in_prison():
		return
	s["serviced"] = false
	s["commute_min"] = 0
	# crashes drop off the record after a few clean years
	var keep: Array = []
	for a in s.get("crashes", []):
		if int(_p().get("age", 0)) - int(a) <= 6:
			keep.append(a)
	s["crashes"] = keep
	if has_car():
		s["no_claims"] = int(s.get("no_claims", 0)) + 1
	if commuting():
		var m := current()
		var mins := minutes(m)
		s["commute_min"] = mins
		var pts := time_points(m)
		if pts > 0:
			GameState.spend_time(mini(pts, int(_p().get("time_left", 0))))
		match m:
			"walk":
				GameState.apply_effects({"health": 1, "happiness": 1 if mins < 45 else -1, "stress": 0 if mins < 45 else 2})
			"bike":
				GameState.apply_effects({"health": 2, "stress": -1})
			"bus":
				GameState.apply_effects({"stress": 1 if mins < 45 else 3})
			"train":
				GameState.apply_effects({"stress": 1 if mins < 50 else 2, "smarts": 0.4})
			"drive":
				GameState.apply_effects({"stress": 1 if transit_score() >= 0.5 else 3, "happiness": 1})
			"remote":
				GameState.apply_effects({"stress": -1, "happiness": 1})
				GameState.change_stat("health", -0.5)
		if mins >= 60 and m != "remote":
			GameState.add_log("My commute is %d minutes each way. I've started to think of it as a second job." % mins)
	if has_car() and int(_p()["age"]) >= 16:
		_drive_year()


func _drive_year() -> void:
	var s := st()
	var age := int(_p()["age"])
	var cover := str(s.get("cover", "third"))
	# uninsured driving is a gamble with a fine at the end
	if cover == "none" and randf() < 0.18:
		var fine := Actions._cost(700)
		_p()["money"] = int(_p()["money"]) - fine
		_p()["heat"] = float(_p().get("heat", 0)) + 3.0
		s["fines"] = int(s.get("fines", 0)) + 1
		GameState.add_log("I was pulled over with no insurance. The fine was %s and the officer wrote down my name twice." % GameState.fmt_money(fine))
	# breakdowns
	var bp := 0.03 if bool(s.get("serviced", false)) else 0.11
	if randf() < bp:
		var cost := Actions._cost(randi_range(600, 2400))
		_p()["money"] = int(_p()["money"]) - cost
		GameState.apply_effects({"stress": 4})
		GameState.add_log("The car broke down on the way home. The garage found three other things while they had it, and the bill was %s." % GameState.fmt_money(cost))
	# crashes
	var cp := 0.03
	if age < 25: cp *= 2.0
	if age >= 75: cp *= 1.6
	if current() != "drive": cp *= 0.45
	cp *= 1.0 + (1.0 - transit_score()) * 0.3
	if GameState.has_trait("Hothead"):
		cp *= 1.4
	if randf() < cp:
		var r := randf()
		crash("minor" if r < 0.68 else ("moderate" if r < 0.94 else "severe"))


func crash(severity: String) -> void:
	var s := st()
	var p := _p()
	if p.is_empty():
		return
	var cover := str(s.get("cover", "third")) if has_car() else "none"
	var at_fault := randf() < 0.55
	var repair: int = {"minor": 1500, "moderate": 6000, "severe": 16000}.get(severity, 1500)
	var liability: int = {"minor": 2000, "moderate": 9000, "severe": 30000}.get(severity, 2000)
	var own := Actions._cost(int(repair))
	var them := Actions._cost(int(liability)) if at_fault else 0
	var pay := 0
	if cover == "none":
		pay = own + them + (Actions._cost(600) if at_fault else 0)
	elif cover == "third":
		pay = own if at_fault or severity != "minor" else 0
	else:
		pay = Actions._cost(400)
	if not at_fault and cover != "none":
		pay = mini(pay, Actions._cost(400))
	p["money"] = int(p["money"]) - pay
	s["crashes"].append(int(p["age"]))
	s["no_claims"] = 0
	var effects := {"stress": 6 if severity == "minor" else 12, "happiness": -3}
	var inj := ""
	if severity == "moderate" and randf() < 0.6:
		inj = ["whiplash", "fracture", "sprain"][randi() % 3]
	elif severity == "severe":
		inj = ["concussion", "back", "fracture"][randi() % 3]
	if inj != "":
		Expansion.add_injury(inj, "a car crash")
	var txt := ""
	match severity:
		"minor": txt = "I clipped a bollard reversing out of a car park. Nobody was hurt; my pride took most of it."
		"moderate": txt = "A driver pulled out without looking. The car was a mess and so, for a while, was I."
		_: txt = "The crash happened very fast and then very slowly. The car was written off."
	if severity == "severe":
		p["car"] = ""
		if randf() < 0.08 and GameState.stat("health") < 60.0:
			EventEngine.kill("a car crash")
			return
	txt += " %s" % ("It was my fault, and the other driver's bill came to me." if at_fault and cover == "none" else ("It was my fault." if at_fault else "It wasn't my fault, but it was still my afternoon."))
	if pay > 0:
		txt += " It cost me %s." % GameState.fmt_money(pay)
	txt += " My insurance will remember it."
	GameState.add_milestone(int(p["age"]), "had a car crash")
	GameState.add_log(txt)
	EventEngine.push_info("🚗", "Crash", txt, effects)
	GameState.apply_effects(effects)


# ------------------------------------------------------------------ menu

func _row(icon: String, name: String, sub: String, act: String, arg = null, on: bool = true) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "act": "real:" + act, "arg": arg, "on": on}


func menu() -> Dictionary:
	var s := st()
	var rows: Array = []
	var info: Array = []
	var cur := current()
	if commuting():
		info.append("Your commute: %s, about %d minutes each way%s" % [str(MODES[cur]["name"]).to_lower(), minutes(cur), "" if time_points(cur) == 0 else "  ·  costs %d time a year" % time_points(cur)])
	else:
		info.append("You have nowhere you have to be every morning.")
	if has_car():
		info.append("%s  ·  premium %s a year  ·  %d clean years  ·  %d recent crash%s" % [str(COVER[str(s["cover"])]["name"]), GameState.fmt_money(premium()), int(s["no_claims"]), _recent_crashes(), "" if _recent_crashes() == 1 else "es"])
	if commuting():
		for m in MODES.keys():
			var avail := available(str(m))
			var mm := minutes(str(m))
			var sub := "Not an option here" if not avail else "%d min · %s a year" % [mm, GameState.fmt_money(_mode_cost(str(m)))]
			rows.append(_row(str(MODES[m]["icon"]), "%s%s" % [str(MODES[m]["name"]), "  ✓" if str(m) == cur else ""], sub, "mode", str(m), avail))
	if has_car():
		for c in ["none", "third", "full"]:
			var cur_c: bool = str(s["cover"]) == c
			rows.append(_row("@scroll", "%s%s" % [str(COVER[c]["name"]), "  ✓" if cur_c else ""], "Third party covers the other driver; comprehensive covers you too" if c != "none" else "Saves money until the day it doesn't", "cover", c, not cur_c))
		rows.append(_row("@hatchback", "Service the car", "%s · far fewer breakdowns this year" % GameState.fmt_money(Actions._cost(450)), "service", null, not bool(s.get("serviced", false))))
	return {"icon": "🧭", "title": "Getting about", "rows": rows, "info": info}


func act(key: String, arg) -> void:
	var s := st()
	match key:
		"mode":
			s["mode"] = str(arg)
			GameState.add_log("I changed how I get to work: %s." % str(MODES[str(arg)]["name"]).to_lower())
		"cover":
			s["cover"] = str(arg)
		"service":
			var fee := Actions._cost(450)
			if not Actions._can_pay(fee, "Car service"):
				return
			_p()["money"] = int(_p()["money"]) - fee
			s["serviced"] = true
			EventEngine.push_info("🔧", "Service", "The mechanic showed me a filter the colour of tar. I felt looked after.")


func tag(t: String) -> bool:
	var s := st()
	if s.is_empty():
		return false
	match t:
		"drives": return has_car() and int(_p().get("age", 0)) >= 16
		"uninsured": return has_car() and str(s.get("cover", "third")) == "none"
		"insured": return has_car() and str(s.get("cover", "third")) != "none"
		"young_driver": return has_car() and int(_p().get("age", 99)) < 25
		"long_commute": return commuting() and int(s.get("commute_min", 0)) >= 50
		"clean_record": return int(s.get("no_claims", 0)) >= 3
		"recent_crash": return _recent_crashes() > 0
	if t.begins_with("commute:"):
		return commuting() and current() == t.substr(8)
	return false


func apply(ops: Dictionary) -> void:
	if ops.has("crash"):
		crash(str(ops["crash"]))
	if ops.has("premium_pct") and has_car():
		st()["no_claims"] = maxi(0, int(st()["no_claims"]) - int(ops["premium_pct"] / 10.0))
	if ops.has("cover"):
		st()["cover"] = str(ops["cover"])
	if ops.has("fine"):
		_p()["money"] = int(_p()["money"]) - int(ops["fine"])
