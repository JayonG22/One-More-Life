extends Node

## WORKFORCE — a job is a standing, and a standing can go either way.
##
## Every year your performance is reviewed against what you did, how you were
## treated, how the firm is doing and how the economy is. The review can end in a
## promotion, a raise, a warning, a demotion or a dismissal, and each one comes with
## the real reason: nobody is promoted "by luck" or fired "by chance". Losing a job
## has an economic consequence too: the economy pays severance and a benefit for a
## while, reference letters follow you, and the sector you work in feels the world.

## How much each kind of world event moves a sector's fortunes (+ is good).
const EXPOSURE := {
	"recession": {"Retail": -0.14, "Food": -0.12, "Recreation": -0.14, "Aviation": -0.14, "Transport": -0.08, "Finance": -0.10, "Business": -0.08, "Tech": -0.06, "Trades": -0.08, "Media": -0.08, "Design": -0.10, "Healthcare": 0.02, "Education": 0.0, "Government": 0.02, "Care": 0.02, "Security": 0.01, "Military": 0.03},
	"boom": {"Retail": 0.07, "Food": 0.07, "Recreation": 0.08, "Aviation": 0.08, "Finance": 0.08, "Business": 0.07, "Tech": 0.08, "Trades": 0.08, "Media": 0.05, "Design": 0.06},
	"tech": {"Tech": 0.12, "Design": 0.04, "Media": -0.03, "Office": -0.07, "Retail": -0.03, "Transport": -0.03},
	"pandemic": {"Food": -0.18, "Recreation": -0.2, "Aviation": -0.22, "Retail": -0.1, "Healthcare": 0.1, "Care": 0.08, "Logistics": 0.06, "Tech": 0.04},
}


func _p() -> Dictionary:
	return GameState.player


## The sector's weather this year: world events summed over this field.
func climate(field: String) -> float:
	var total := 0.0
	for ev in EXPOSURE.keys():
		if World.active(str(ev)):
			total += float(EXPOSURE[ev].get(field, 0.0))
	return total


## The annual review. Called once a year by the job pass, after performance moves.
func review() -> void:
	var p := _p()
	var j: Dictionary = p["job"]
	var jd := ContentDB.job(str(j["id"]))
	var ranks: Array = jd.get("ranks", [j["title"]])
	var field := str(jd.get("field", ""))
	var ww := Workplace.w()
	var perf := float(j["perf"])
	var firm := float(ww.get("health", 0.7)) + climate(field)
	var boss_id := str(j.get("boss", ""))
	var boss_close := float(GameState.npcs[boss_id]["closeness"]) if boss_id != "" and GameState.npcs.has(boss_id) else 40.0
	var why: Array = _drivers(j, ww, boss_close, firm)
	var rank := int(j["rank"])
	var yrs_rank := int(j["years_in_rank"])
	var co := str(j.get("employer_name", "the firm"))
	var inflation := 0.02 + (0.015 if World.active("recession") else 0.0) - (0.005 if World.active("boom") else 0.0)
	# --- dismissal for cause
	if perf < 15.0:
		_fire("performance", co, why)
		return
	# --- a warning, then the consequence
	if perf < 45.0:
		if int(j.get("warned", 0)) >= 1:
			j["warned"] = 0
			if rank > 0:
				_demote(j, ranks, co, why)
			else:
				_fire("a second warning", co, why)
			return
		j["warned"] = 1
		var reason := _say(why, false)
		GameState.add_log("My review at %s was poor. %s I was put on a performance plan." % [co, reason])
		GameState.counter("warnings")
		EventEngine.push_info("📋", "A formal warning", "%s put me on a performance plan.\n\n%s\n\nIf it is not better next year, it will cost me the job, or my rank." % [co, reason], {"stress": 6, "happiness": -4})
		GameState.apply_effects({"stress": 6, "happiness": -4})
		j["salary"] = int(int(j["salary"]) * (1.0 + inflation * 0.3))
		return
	j["warned"] = 0
	# --- promotion needs merit, tenure, a post to move into, and someone to back you
	if perf >= 70.0 and rank < ranks.size() - 1 and Employment.promotion_reason()=="":
		var vacancy := 0.30 + firm * 0.35 + (0.12 if str(ww.get("boss_kind", "")) == "supportive" else 0.0) + (boss_close - 40.0) / 300.0
		vacancy += (float(ww.get("politics", 50.0)) - 50.0) / 400.0 if str(ww.get("boss_kind", "")) == "political" else 0.0
		if yrs_rank >= 2 and randf() < clampf(vacancy, 0.1, 0.9):
			_promote(j, ranks, co, why)
			return
		if yrs_rank >= 2:
			var blocker := "the company is not hiring above you" if firm < 0.45 else ("the manager is keeping you where you are" if boss_close < 35.0 else "there is simply nobody leaving above you")
			GameState.add_log("My review at %s was glowing, but %s. I got a raise, not a title." % [co, blocker])
			j["salary"] = int(int(j["salary"]) * (1.0 + inflation + 0.03))
			return
	# --- an ordinary year
	var raise := inflation + (0.02 if perf >= 60.0 else 0.0) + (0.01 if firm > 0.65 else (-0.01 if firm < 0.35 else 0.0))
	j["salary"] = int(int(j["salary"]) * (1.0 + raise))


func _drivers(j: Dictionary, ww: Dictionary, boss_close: float, firm: float) -> Array:
	var out: Array = []
	if bool(j.get("worked_hard", false)):
		out.append([0.8, "you put in the hours this year"])
	else:
		out.append([-0.2, "you did not go beyond what was asked"])
	if GameState.stat("stress") > 70.0:
		out.append([-0.9, "your stress was showing in the work"])
	if GameState.stat("happiness") < 30.0:
		out.append([-0.6, "you looked checked out"])
	if GameState.stat("smarts") >= 70.0:
		out.append([0.5, "you are good at the thing itself"])
	if boss_close < 30.0:
		out.append([-0.7, "you and your manager do not get on"])
	elif boss_close > 65.0:
		out.append([0.6, "your manager rates you"])
	if firm < 0.35:
		out.append([-0.5, "the firm itself is struggling"])
	if str(ww.get("culture", "")) == "cutthroat":
		out.append([-0.2, "the place measures everyone against everyone"])
	if GameState.has_trait("Lazy"):
		out.append([-0.8, "you coast"])
	if GameState.has_trait("Ambitious"):
		out.append([0.6, "you are visibly ambitious"])
	if GameState.get_counter("warnings") > 0:
		out.append([-0.2, "there is a warning on your file"])
	return out


func _say(drivers: Array, positive: bool) -> String:
	var ds := drivers.duplicate()
	ds.sort_custom(func(a, b): return float(a[0]) > float(b[0]) if positive else float(a[0]) < float(b[0]))
	var picks: Array = []
	for d in ds:
		if (positive and float(d[0]) > 0.0) or (not positive and float(d[0]) < 0.0):
			picks.append(str(d[1]))
		if picks.size() >= 2:
			break
	if picks.is_empty():
		return "There was no single reason, which is a reason of its own." if not positive else "It was a steady year."
	return "The reason: " + " and ".join(picks) + "."


func _promote(j: Dictionary, ranks: Array, co: String, why: Array) -> void:
	var p := _p()
	j["rank"] = int(j["rank"]) + 1
	j["title"] = ranks[int(j["rank"])]
	var bump := 1.18 + (0.05 if float(j["perf"]) >= 85.0 else 0.0)
	j["salary"] = int(int(j["salary"]) * bump)
	j["years_in_rank"] = 0
	j["warned"] = 0
	GameState.counter("promotions")
	var reason := _say(why, true)
	GameState.add_log("I was promoted to %s at %s. %s" % [j["title"], co, reason])
	EventEngine.push_info("📈", "Promoted", "%s at %s.\n\n%s\n\nThe salary is now %s." % [j["title"], co, reason, GameState.fmt_money(int(j["salary"]))], {"happiness": 8, "stress": 2}, true)
	GameState.apply_effects({"happiness": 8})
	if int(j["rank"]) == ranks.size() - 1:
		GameState.add_milestone(int(p["age"]), "rose to %s" % j["title"])


func _demote(j: Dictionary, ranks: Array, co: String, why: Array) -> void:
	var p := _p()
	j["rank"] = maxi(0, int(j["rank"]) - 1)
	j["title"] = ranks[int(j["rank"])]
	j["salary"] = int(int(j["salary"]) * 0.82)
	j["years_in_rank"] = 0
	GameState.counter("demotions")
	var reason := _say(why, false)
	GameState.add_log("%s moved me back down to %s. %s" % [co, j["title"], reason])
	GameState.add_milestone(int(p["age"]), "was demoted to %s" % str(j["title"]).to_lower())
	EventEngine.push_info("📉", "Demoted", "%s moved me down to %s on %s.\n\n%s" % [co, j["title"], GameState.fmt_money(int(j["salary"])), reason], {"happiness": -10, "stress": 6}, true)
	GameState.apply_effects({"happiness": -10, "stress": 6})
	var boss: String = str(j.get("boss", ""))
	if boss != "" and GameState.npcs.has(boss):
		GameState.change_closeness(boss, -8)


func _fire(cause: String, co: String, why: Array) -> void:
	var p := _p()
	var j: Dictionary = p["job"]
	var reason := _say(why, false)
	var title := str(j["title"])
	var yrs := int(j.get("years", 1))
	GameState.counter("fired")
	GameState.add_milestone(int(p["age"]), "was fired from %s" % co)
	Actions.lose_job("fired")
	EventEngine.push_info("🔥", "Fired", "%s let me go as %s after %d year%s, for %s.\n\n%s\n\nA box, a lanyard, a security escort. It will be on the CV." % [co, title.to_lower(), yrs, "" if yrs == 1 else "s", cause, reason], {"happiness": -10, "stress": 8}, true)


## Called by Actions.lose_job before the record is cleared.
func on_leave(reason: String, salary: int, years: int) -> void:
	var p := _p()
	var months := 0
	var share := 0.0
	match reason:
		"laid_off":
			months = clampi(years * 1 + 3, 3, 12)
			share = 0.4
		"fired":
			months = clampi(years + 1, 2, 6)
			share = 0.22
		_:
			return
	p["benefit"] = {"left": int(p.get("age", 0)), "months": months, "amt": int(float(salary) / 12.0 * share)}


## Yearly: the benefit pays while you are out of work, and runs out.
func yearly() -> void:
	var p := _p()
	var b: Dictionary = p.get("benefit", {})
	if b.is_empty():
		return
	if GameState.has_job():
		p.erase("benefit")
		return
	var m := mini(12, int(b["months"]))
	var paid := int(b["amt"]) * m
	p["money"] = int(p["money"]) + paid
	Employment.record_income("Unemployment support",paid)
	b["months"] = int(b["months"]) - m
	GameState.add_log("Unemployment support paid %s this year. It runs out in %d month%s." % [GameState.fmt_money(paid), maxi(0, int(b["months"])), "" if int(b["months"]) == 1 else "s"] if int(b["months"]) > 0 else "The unemployment support ran out this year. I stopped being able to ignore the numbers.")
	if int(b["months"]) <= 0:
		p.erase("benefit")
