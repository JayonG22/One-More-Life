extends Node

## DIRECTOR — what happens this year, and how much of it you are asked to sit through.
##
## The yearly systems each have something to say, and left alone they say it all at
## once: a dozen log lines, a follow-up, two random events, a wedding invitation,
## a bank letter. That is a flood, and a flood is not a life. The Director does
## four things:
##
##  1. A BUDGET. Each year has room for a few popups (more at milestone ages, fewer
##     for a child). Critical ones always get through; the rest are ranked, and what
##     does not fit is either folded into the log, put back for next year, or dropped.
##  2. RELEVANCE. A random event is weighted by how much it fits this person now:
##     their stage of life, work, relationships, health, money, habits, place and
##     the state of the world. Events with nothing to do with you rarely come.
##  3. VARIETY. Events and whole themes fatigue: the more you have seen of one, the
##     less it comes, and a theme that just played sits out the next few years.
##  4. RATION. Each life gets its own slice of the library, so no two lives draw on
##     the same pool and the pool is never used up in one go.

const MILESTONES := [5, 12, 16, 18, 21, 25, 30, 35, 40, 50, 60, 65, 70, 80]
const PREFIX_THEME := {
	"adult": "life", "work": "work", "wb": "work", "school": "school", "teen": "school", "kid": "school", "child": "school",
	"fam": "family", "family": "family", "money": "money", "co": "pet", "real": "daily", "web": "social", "v07": "social",
	"v08": "ambition", "tod": "daily", "tw": "twist", "elder": "elder", "echo": "echo", "law": "law", "fame": "fame",
	"agency": "social", "cameo": "social", "career": "work", "emp": "money",
}
const COND_THEME := {"job_id": "work", "has_pet": "pet", "has_partner": "romance", "has_children": "family", "prison": "law", "police_case": "work", "pet_business": "pet", "min_companies": "money"}


func _p() -> Dictionary:
	return GameState.player


## How many popups this year can carry. Settings can turn it down or up.
func budget() -> int:
	var age := int(_p().get("age", 0))
	var b := 2
	if age <= 4:
		b = 1
	elif MILESTONES.has(age):
		b = 3
	match str(GameState.settings.get("event_density", "normal")):
		"calm": b = maxi(1, b - 1)
		"busy": b += 1
	return b


## Random events to try for this year, before the budget is applied.
func random_count() -> int:
	var age := int(_p().get("age", 0))
	if age <= 2:
		return 1 if randf() < 0.5 else 0
	var pick: Array = [0, 1, 1, 1, 2]
	match str(GameState.settings.get("event_density", "normal")):
		"calm": pick = [0, 0, 1, 1, 1]
		"busy": pick = [1, 1, 2, 2, 2]
	return int(pick[randi() % pick.size()])


# ---------------------------------------------------------------- the player

## Tags that describe this person right now: stage, work, bonds, body, means, habits, world.
func profile() -> Dictionary:
	var p := _p()
	var t: Dictionary = {}
	var age := int(p.get("age", 0))
	t["stage_" + ("child" if age < 13 else ("teen" if age < 18 else ("young" if age < 30 else ("adult" if age < 55 else ("mature" if age < 70 else "elder")))))] = 1.0
	if GameState.in_school():
		t["school"] = 1.0
	if GameState.has_job():
		t["work"] = 1.0
		t["field_" + str(p["job"].get("field", "")).to_lower()] = 1.0
	elif age >= 18 and age < 65:
		t["jobless"] = 1.0
	if str(p.get("partner", "")) != "":
		t["romance"] = 1.0
	elif age >= 16:
		t["single"] = 1.0
	if not GameState.npcs_with("child").is_empty():
		t["family"] = 1.0
	if not GameState.npcs_with("pet").is_empty():
		t["pet"] = 1.0
	if GameState.in_prison():
		t["law"] = 1.0
	var nw := GameState.net_worth()
	if nw >= 1000000:
		t["rich"] = 1.0
	elif nw < 0 or int(p.get("money", 0)) < 500:
		t["money"] = 1.0
	if GameState.stat("health") < 40.0 or str(p.get("illness", "")) != "":
		t["health"] = 1.0
	if GameState.stat("stress") > 70.0:
		t["stress"] = 1.0
	if float(p.get("fame", 0)) >= 30.0:
		t["fame"] = 1.0
	if GameState.get_counter("gambles") >= 5:
		t["gambling"] = 1.0
	if GameState.get_counter("crimes") + GameState.get_counter("arrests") >= 2:
		t["law"] = 1.0
	for id in World.active_list():
		t["world_" + str(id)] = 1.0
	return t


func themes_of(def: Dictionary) -> Array:
	if def.has("themes"):
		return def["themes"]
	var id := str(def.get("id", ""))
	var out: Array = []
	var pre := id.get_slice(".", 0) if "." in id else ""
	if PREFIX_THEME.has(pre):
		out.append(PREFIX_THEME[pre])
	for k in def.get("conditions", {}).keys():
		if COND_THEME.has(k):
			out.append(COND_THEME[k])
	if out.is_empty():
		out.append("life")
	return out


# ---------------------------------------------------------------- weighting

func _life_key() -> String:
	var p := _p()
	if not p.has("director_key"):
		p["director_key"] = str(randi())
	return str(p["director_key"])


## 0..1, stable for this life and this event.
func ration_roll(id: String) -> float:
	return float(hash(_life_key() + id) % 1000) / 1000.0


func state() -> Dictionary:
	var p := _p()
	if not p.has("director") or not (p["director"] is Dictionary):
		p["director"] = {"seen": {}, "recent": []}
	return p["director"]


func weight(def: Dictionary, base: float) -> float:
	var w := base
	var prof := profile()
	var themes := themes_of(def)
	# relevance
	var rel := 0.0
	for th in themes:
		if prof.has(th):
			rel += 0.5
	var c: Dictionary = def.get("conditions", {})
	if c.has("traits_any"):
		rel += 0.3
	if c.has("flags"):
		rel += 0.3
	if c.has("life") and not c.has("age"):
		rel += 0.0
	for k in prof.keys():
		if str(k).begins_with("world_") and str(def.get("id", "")).find(str(k).substr(6)) != -1:
			rel += 0.8
	w *= 0.8 + minf(rel, 1.6)
	# the thing you keep doing is the thing that keeps happening to you
	for th in themes:
		if th == "money" and GameState.get_counter("gambles") > 10:
			w *= 1.3
		if th == "law" and GameState.get_counter("crimes") > 3:
			w *= 1.4
	# variety: this event, and this theme
	var st := state()
	var seen: int = int(st["seen"].get(str(def.get("id", "")), 0))
	w *= 1.0 / (1.0 + 1.1 * float(seen))
	var recent: Array = st["recent"]
	var tail := recent.slice(maxi(0, recent.size() - 4))
	for th2 in themes:
		var n := 0
		for r in tail:
			if r == th2:
				n += 1
		w *= pow(0.6, float(n))
	# ration: each life sees most of the library but not all of it
	if def.get("once", false) == false and ration_roll(str(def.get("id", ""))) > 0.72:
		w *= 0.3
	return w


func note(def: Dictionary) -> void:
	var st := state()
	var id := str(def.get("id", ""))
	st["seen"][id] = int(st["seen"].get(id, 0)) + 1
	for th in themes_of(def):
		st["recent"].append(th)
	while st["recent"].size() > 10:
		st["recent"].remove_at(0)


# ---------------------------------------------------------------- the budget

## Called once the year's systems have all had their say. Trims EventEngine.pending
## to the budget and decides where each casualty goes.
func curate() -> void:
	var items: Array = EventEngine.pending
	if items.size() <= 1:
		return
	var bud := budget()
	var ranked: Array = []
	for i in range(items.size()):
		ranked.append({"i": i, "tier": _tier(items[i])})
	ranked.sort_custom(func(a, b): return int(a["tier"]) < int(b["tier"]) or (int(a["tier"]) == int(b["tier"]) and int(a["i"]) < int(b["i"])))
	var keep: Dictionary = {}
	var used := 0
	var echoes := 0
	for r in ranked:
		var it: Dictionary = items[int(r["i"])]
		var tier := int(r["tier"])
		if tier == 0:
			keep[int(r["i"])] = true      # never trimmed, and does not spend the budget
			continue
		if tier == 2 and used >= 1:
			# a year carries one follow-up echo at most, so they do not stack
			if it.get("def", {}).get("followup_only", false):
				echoes += 1
				if echoes > 1:
					continue
		if used < bud:
			keep[int(r["i"])] = true
			used += 1
	var out: Array = []
	for i in range(items.size()):
		if keep.has(i):
			out.append(items[i])
		else:
			_shelve(items[i])
	EventEngine.pending = out


# 0 critical (always shown) · 1 decisions the systems need answered · 2 follow-ups · 3 random events · 4 notices
func _tier(it: Dictionary) -> int:
	if it.get("info", false):
		return 0 if it.get("critical", false) else 4
	var def: Dictionary = it.get("def", {})
	if def.get("twist", false) or def.get("critical", false):
		return 0
	var id := str(def.get("id", ""))
	if id in ["_bankruptcy", "_settlement", "_arrest", "_trial", "_death"] or id.begins_with("arc."):
		return 0
	if id.begins_with("_"):
		return 1
	if def.get("followup_only", false):
		return 2
	return 3


## What happens to an event that did not fit the year.
func _shelve(it: Dictionary) -> void:
	if it.get("info", false):
		var t := str(it.get("text", "")).replace("\n\n", " ").replace("\n", " ")
		if t != "":
			GameState.add_log(str(it.get("icon", "")) + " " + (t if t.length() < 160 else t.substr(0, 157) + "…"))
		return
	var def: Dictionary = it.get("def", {})
	var id := str(def.get("id", ""))
	if def.get("followup_only", false):
		# an echo that did not fit comes back next year
		GameState.followups.append({"event": id, "age": int(_p().get("age", 0)) + 1, "roles": (it.get("roles", {}) as Dictionary).duplicate(), "retries": 0})
	elif not id.begins_with("_"):
		# a random event that did not fit never happened
		GameState.event_history.erase(id)
		var st := state()
		st["seen"][id] = maxi(0, int(st["seen"].get(id, 1)) - 1)
	# system decisions that do not fit are dropped; they are re-raised by their own yearly check
