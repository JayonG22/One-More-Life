extends Node

## The connection web: gives the people in your life occupations that help (or
## hurt) you in other systems, and runs the shared Heat meter.

const JOBS := [
	["Lawyer", "lawyer", 6], ["Doctor", "doctor", 5], ["Nurse", "nurse", 6], ["Police Officer", "cop", 6],
	["Teacher", "teacher", 8], ["Journalist", "journalist", 4], ["Talent Agent", "agent", 3], ["Film Producer", "producer", 2],
	["Banker", "banker", 4], ["Accountant", "accountant", 5], ["Mechanic", "mechanic", 6], ["Chef", "chef", 5],
	["Engineer", "engineer", 6], ["Programmer", "programmer", 6], ["Nurse", "nurse", 3], ["Real Estate Agent", "realtor", 3],
	["Veterinarian", "vet", 3], ["Retail Worker", "retail", 10], ["Electrician", "electrician", 5], ["Pilot", "pilot", 2],
	["Soldier", "soldier", 3], ["Artist", "artist", 4], ["Firefighter", "firefighter", 3], ["Unemployed", "none", 6],
]

const PERKS := {
	"lawyer": "Can defend you in court for free",
	"doctor": "Treats you for free, better odds",
	"nurse": "Free checkups",
	"cop": "Might make a charge disappear, warns you about investigations",
	"teacher": "Helps with your grades (parents only)",
	"journalist": "Can soften a scandal",
	"agent": "Opens doors in acting and music",
	"producer": "Opens doors in acting and directing",
	"banker": "Gets your business loans approved",
	"accountant": "Protects you in tax audits",
	"mechanic": "Fixes your car cheaply",
	"realtor": "Finds you property deals",
	"vet": "Treats your pets for free",
}


# ---------------------------------------------------------------- jobs

func ensure_job(id: String) -> void:
	if not GameState.npcs.has(id):
		return
	var n: Dictionary = GameState.npcs[id]
	if n.get("species", "human") != "human":
		return
	var age: int = n["age"]
	if n.has("job") and not (str(n["job"]["key"]) == "student" and age >= 22):
		if age >= 67 and n["job"]["key"] != "retired" and randf() < 0.3:
			var old: String = n["job"]["title"]
			n["job"] = {"title": "Retired" if n["job"]["key"] in ["none", "student", "employee"] else "Retired " + old.to_lower(), "key": "retired"}
		return
	if age < 22:
		n["job"] = {"title": "Student" if age >= 5 else "Kid", "key": "student"}
		return
	if age >= 67:
		n["job"] = {"title": "Retired", "key": "retired"}
		return
	match n["relation"]:
		"boss", "coworker":
			if GameState.has_job():
				n["job"] = {"title": GameState.player["job"]["field"] + " worker", "key": "colleague"}
				return
		"bandmate":
			n["job"] = {"title": "Musician", "key": "musician"}
			return
		"mafia_boss":
			n["job"] = {"title": "Crime Boss", "key": "mafia"}
			return
		"tenant":
			pass
	var total := 0
	for j in JOBS:
		total += int(j[2])
	var r := randi() % total
	for j in JOBS:
		r -= int(j[2])
		if r < 0:
			n["job"] = {"title": j[0], "key": j[1]}
			return


func job_of(id: String) -> String:
	var n := GameState.npc(id)
	if n.is_empty() or not n.has("job"):
		return ""
	return n["job"]["key"]


func job_title(id: String) -> String:
	var n := GameState.npc(id)
	if n.is_empty() or not n.has("job"):
		return ""
	return n["job"]["title"]


func perk_text(id: String) -> String:
	return PERKS.get(job_of(id), "")


## The closest living person with one of these jobs, or "".
func contact(keys: Array, min_close: int = 55) -> String:
	var best := ""
	var best_c := min_close - 1
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"] or n.get("species", "human") != "human":
			continue
		if n["relation"] in ["ex", "rival", "enemy", "former_tenant", "cellmate"]:
			continue
		if not n.has("job") or not keys.has(n["job"]["key"]):
			continue
		if int(n["closeness"]) > best_c:
			best_c = int(n["closeness"])
			best = id
	return best


func contact_line(id: String) -> String:
	return "%s (your %s, %s)" % [GameState.full_name(id), GameState.relation_label(id).to_lower(), job_title(id).to_lower()]


# ---------------------------------------------------------------- yearly

func yearly() -> void:
	for id in GameState.npcs.keys():
		ensure_job(id)
	_heat_yearly()


func _heat_yearly() -> void:
	var p := GameState.player
	var heat := float(p.get("heat", 0.0))
	if heat <= 0:
		return
	var decay := 7.0
	if Careers.past("agent") or Careers.has_career("agent"):
		decay += 4.0
	if p.get("flags_island", false) or GameState.has_flag("island_owner"):
		decay += 3.0
	heat = maxf(0.0, heat - decay)
	p["heat"] = heat
	if GameState.in_prison() or heat < 35:
		return
	var chance := (heat - 30.0) / 180.0
	if randf() >= chance:
		return
	var cop := contact(["cop"], 60)
	if cop != "" and randf() < 0.5:
		GameState.add_log("%s quietly warned me that detectives are asking about me." % GameState.full_name(cop))
		EventEngine.push_info("👮", "A friendly warning", "%s pulled you aside: \"Detectives are building a case on you. Lay low.\"\n\nYour heat dropped." % contact_line(cop), GameState.apply_effects({"heat": -20, "stress": 6}))
		return
	var crime := _likely_crime()
	GameState.add_log("Detectives came to my door. They'd been building a case for %s." % crime)
	p["heat"] = heat * 0.4
	Law.trial(crime, 1, 6 if heat < 70 else 12)


func _likely_crime() -> String:
	var p := GameState.player
	var c: Dictionary = p.get("career", {})
	match c.get("id", ""):
		"mafia": return "racketeering"
		"hustler": return "fraud"
	if not p.get("cult", {}).is_empty():
		return "fraud"
	if GameState.has_flag("black_market_buyer"):
		return "trafficking stolen goods"
	if not p.get("business", {}).is_empty() and GameState.has_flag("cooked_books"):
		return "tax evasion"
	if not p["record"].is_empty():
		return p["record"][-1]
	return "theft"
