extends Node

## SEEDED LIVES — the same life for everyone, today and this week.
##
## A seeded life fixes the start (the mode, the person, the family, the place) from
## the date, and sets one goal. Everything after that is yours. When it ends it is
## scored, the best score for the day is kept, and the share card says which day it
## was, so two people can compare how the same start went.

const GOALS := {
	"human": [
		{"id": "h_clean70", "text": "Reach 70 with a clean record", "bonus": 600},
		{"id": "h_rich", "text": "Reach a net worth of $1,000,000", "bonus": 700},
		{"id": "h_family", "text": "Raise three children", "bonus": 500},
		{"id": "h_famous", "text": "Become famous (fame 60)", "bonus": 700},
		{"id": "h_old", "text": "Live to 85", "bonus": 600},
	],
	"pet": [
		{"id": "p_bond", "text": "End with a bond of 80 or more", "bonus": 600},
		{"id": "p_hero", "text": "Do something brave", "bonus": 600},
		{"id": "p_old", "text": "Live a long, full life (beyond the species' average)", "bonus": 500},
		{"id": "p_tricks", "text": "Learn five tricks", "bonus": 500},
	],
	"prisoner": [
		{"id": "r_out", "text": "Walk out alive: paroled, cleared, served or escaped", "bonus": 700},
		{"id": "r_respect", "text": "Reach a respect of 70", "bonus": 600},
		{"id": "r_clean", "text": "Never be put in segregation, and walk out", "bonus": 800},
	],
	"guard": [
		{"id": "g_sergeant", "text": "Become a Sergeant", "bonus": 600},
		{"id": "g_clean", "text": "Retire without ever taking money", "bonus": 800},
		{"id": "g_commend", "text": "Earn two commendations", "bonus": 600},
	],
}
const MODES := ["human", "pet", "prisoner", "guard"]


func day_index() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


func week_index() -> int:
	return int((Time.get_unix_time_from_system() / 86400.0 + 3.0) / 7.0)


func key_for(kind: String) -> String:
	if kind == "weekly":
		var d := Time.get_date_dict_from_system()
		return "W%d" % week_index() if d != null else "W"
	var dd := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [dd["year"], dd["month"], dd["day"]]


func index_for(kind: String) -> int:
	return week_index() if kind == "weekly" else day_index()


## Everything about the seeded life of this kind. Pure function of the date.
func spec(kind: String, idx: int = -1) -> Dictionary:
	var i := index_for(kind) if idx < 0 else idx
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("oml-%s-%d" % [kind, i])
	var mode: String = MODES[(i + (2 if kind == "weekly" else 0)) % MODES.size()]
	var goals: Array = GOALS[mode]
	var goal: Dictionary = goals[rng.randi() % goals.size()].duplicate()
	if kind == "weekly":
		goal["bonus"] = int(goal["bonus"]) * 2
	var gender := "male" if rng.randf() < 0.5 else "female"
	var s := {"kind": kind, "index": i, "key": key_for(kind) if idx < 0 else "#%d" % i, "mode": mode, "goal": goal, "seed": int(rng.randi()), "gender": gender}
	match mode:
		"pet":
			s["species"] = Pets.SPECIES.keys()[rng.randi() % 5]
			s["origin"] = Pets.ORIGINS.keys()[rng.randi() % 7]
		"prisoner":
			s["story"] = Prison.PRISONER_STORIES.keys()[rng.randi() % Prison.PRISONER_STORIES.size()]
		"guard":
			s["story"] = Prison.GUARD_STORIES.keys()[rng.randi() % Prison.GUARD_STORIES.size()]
		_:
			s["country"] = ContentDB.countries[rng.randi() % ContentDB.countries.size()]["id"]
	return s


func describe(s: Dictionary) -> String:
	match str(s["mode"]):
		"pet": return "%s from %s" % [str(Pets.SPECIES[s["species"]]["name"]).to_lower(), str(Pets.ORIGINS[s["origin"]]["name"]).to_lower()]
		"prisoner": return "prisoner: %s" % str(Prison.PRISONER_STORIES[s["story"]]["name"]).to_lower()
		"guard": return "guard: %s" % str(Prison.GUARD_STORIES[s["story"]]["name"]).to_lower()
	return "a person born in %s" % str(ContentDB.country(str(s["country"]))["name"])


func label(kind: String) -> String:
	var s := spec(kind)
	var best: Dictionary = Meta.meta.get("seeded", {}).get(str(s["key"]), {})
	return "%s · %s%s" % ["Today" if kind == "daily" else "This week", describe(s), ("  ·  best %d" % int(best["score"])) if not best.is_empty() else ""]


## The opts for GameState.new_life, built under the seed so the family and name match.
func start(kind: String) -> Dictionary:
	var s := spec(kind)
	seed(int(s["seed"]))
	var opts := {"gender": s["gender"], "modifiers": [], "difficulty": "real", "boons": [], "challenge": ""}
	match str(s["mode"]):
		"pet":
			opts.merge({"first": ContentDB.random_pet_name(), "last": "", "country": ContentDB.countries[randi() % ContentDB.countries.size()]["id"], "life_path": "pet", "keep_family": true, "species": s["species"], "origin": s["origin"]})
		"prisoner", "guard":
			opts.merge({"first": ContentDB.random_first(str(s["gender"]), "us"), "last": ContentDB.random_last("us"), "country": "us", "life_path": s["mode"], "keep_family": true, "story": s["story"]})
		_:
			var cid: String = str(s["country"])
			opts.merge({"first": ContentDB.random_first(str(s["gender"]), cid), "last": ContentDB.random_last(cid), "country": cid, "face": randi() % 5})
	GameState.new_life(opts)
	GameState.player["seeded"] = {"kind": kind, "key": s["key"], "goal": s["goal"], "mode": s["mode"]}
	randomize()
	return s


func active() -> bool:
	return not GameState.player.is_empty() and GameState.player.has("seeded")


func goal_met() -> bool:
	if not active():
		return false
	var p := GameState.player
	var gid := str(p["seeded"]["goal"]["id"])
	var l := Lives.life()
	match gid:
		"h_clean70": return int(p["age"]) >= 70 and p["record"].is_empty() and int(p["prison_total"]) == 0
		"h_rich": return GameState.net_worth() >= 1000000 or GameState.get_counter("seeded_peak_rich") > 0
		"h_family": return GameState.npcs_with("child", false).size() >= 3
		"h_famous": return float(p.get("fame", 0)) >= 60.0
		"h_old": return int(p["age"]) >= 85
		"p_bond": return float(l.get("bond", 0)) >= 80.0
		"p_hero": return int(l.get("heroics", 0)) >= 1
		"p_old": return Lives.kind() == "pet" and int(p["age"]) >= int((int(Pets.SPECIES[Pets.species()]["life"][0]) + int(Pets.SPECIES[Pets.species()]["life"][1])) / 2)
		"p_tricks": return Array(l.get("tricks", [])).size() >= 5
		"r_out": return str(l.get("outcome", "")) in ["served", "paroled", "exonerated", "escaped"]
		"r_respect": return float(l.get("respect", 0)) >= 70.0
		"r_clean": return str(l.get("outcome", "")) in ["served", "paroled", "exonerated", "escaped"] and int(l.get("solitary_years", 0)) == 0
		"g_sergeant": return int(l.get("rank", 1)) >= 3
		"g_clean": return str(l.get("outcome", "")) in ["retired", "warden"] and int(l.get("corruption", 0)) == 0
		"g_commend": return int(l.get("commend", 0)) >= 2
	return false


func status_line() -> String:
	if not active():
		return ""
	var s: Dictionary = GameState.player["seeded"]
	return "%s %s goal: %s%s" % ["📅" if s["kind"] == "daily" else "🗓️", "Daily" if s["kind"] == "daily" else "Weekly", str(s["goal"]["text"]), "  ✓" if goal_met() else ""]


## Called at death, before the entry is stored. Returns what to put on the entry.
func evaluate(entry: Dictionary) -> Dictionary:
	if not active():
		return {}
	var s: Dictionary = GameState.player["seeded"]
	var met := goal_met()
	var score := int(entry.get("age", 0)) * 10
	if not entry.get("ending", {}).is_empty():
		score += 150
	if met:
		score += int(s["goal"]["bonus"])
	var out := {"kind": s["kind"], "key": s["key"], "goal": s["goal"]["text"], "met": met, "score": score}
	if not Meta.meta.has("seeded"):
		Meta.meta["seeded"] = {}
	var prev: Dictionary = Meta.meta["seeded"].get(str(s["key"]), {})
	if prev.is_empty() or score > int(prev.get("score", 0)):
		Meta.meta["seeded"][str(s["key"])] = {"score": score, "met": met, "name": str(entry.get("name", "")), "kind": s["kind"]}
	if met:
		Meta.meta["seeded_wins"] = int(Meta.meta.get("seeded_wins", 0)) + 1
	return out
