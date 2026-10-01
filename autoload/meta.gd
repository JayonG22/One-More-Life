extends Node

const MODIFIERS := {
	"golden_passport": {"name": "Golden Passport", "icon": "🛂", "desc": "Emigrate anywhere, free, always approved"},
	"piggy_bank": {"name": "Golden Piggy Bank", "icon": "🐷", "desc": "Start life with $1,000,000"},
	"star_power": {"name": "Star Power", "icon": "🌟", "desc": "Auditions, drafts and record deals always succeed"},
	"golden_diploma": {"name": "Golden Diploma", "icon": "📜", "desc": "Skip education requirements for jobs and schools"},
	"brass_knuckles": {"name": "Brass Knuckles", "icon": "🥊", "desc": "Win every fight"},
	"jail_card": {"name": "Get Out of Jail Card", "icon": "🃏", "desc": "Once a year, walk free and wipe your record"},
}

var meta: Dictionary = {}
var challenges: Array = []

var META_PATH: String = (OS.get_environment("OML_USER_DIR") if OS.get_environment("OML_USER_DIR") != "" else "user:/") + "/meta.json"


func _ready() -> void:
	challenges = ContentDB._load_json("res://data/challenges.json", [])
	if FileAccess.file_exists(META_PATH):
		var d = JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
		if d is Dictionary:
			meta = d
	for k in ["ribbons", "ribbons_modified", "challenges_done", "badges"]:
		if not meta.has(k):
			meta[k] = {}


func save() -> void:
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(meta))
		f.close()


func has_mod(m: String) -> bool:
	return GameState.player.get("modifiers", []).has(m)


func record_death(entry: Dictionary) -> void:
	var key := "ribbons_modified" if entry.get("modified", false) else "ribbons"
	var rn: String = entry.get("ribbon", {}).get("name", "")
	if rn != "":
		meta[key][rn] = int(meta[key].get(rn, 0)) + 1
	check_challenge(true)
	save()


func challenge(id: String) -> Dictionary:
	for c in challenges:
		if c["id"] == id:
			return c
	return {}


func goal_progress(goal: Dictionary) -> Array:
	var p := GameState.player
	var car: Dictionary = p.get("career", {})
	var v := 0.0
	var target := float(goal.get("value", 1))
	match goal["type"]:
		"net_worth": v = GameState.net_worth()
		"career_rank":
			if car.get("id", "") == goal["career"]:
				v = float(car.get("rank", 0))
			target = float(goal["rank"])
		"president": v = GameState.get_counter("president")
		"awards": v = GameState.get_counter("awards")
		"diamond": v = GameState.get_counter("diamond")
		"titles": v = GameState.get_counter("titles")
		"children": v = GameState.npcs_with("child", false).size()
		"degrees": v = p["education"]["degrees"].size()
		"properties": v = p.get("properties", []).size()
		"age": v = int(p["age"])
		"karma": v = int(p["karma"])
		"clean_record": v = 1.0 if p["record"].is_empty() and int(p["prison_total"]) == 0 else 0.0
		"max_age":
			return [int(p["age"]) <= int(goal["value"]), "%d / %d" % [int(p["age"]), int(goal["value"])]]
		"fame": v = float(p.get("fame", 0))
		"married": v = 1.0 if p["partner_status"] == "married" or GameState.has_flag("married_once") else 0.0
		"countries": v = GameState.get_counter("emigrated")
	var shown := ""
	if goal["type"] == "net_worth":
		shown = "%s / %s" % [GameState.fmt_money(int(v)), GameState.fmt_money(int(target))]
	elif goal["type"] in ["clean_record", "married"]:
		shown = "yes" if v >= 1 else "no"
	else:
		shown = "%d / %d" % [int(v), int(target)]
	return [v >= target, shown]


func check_challenge(at_death: bool = false) -> void:
	var p := GameState.player
	var cid: String = p.get("challenge", "")
	if cid == "" or GameState.has_flag("challenge_done"):
		return
	var c := challenge(cid)
	if c.is_empty():
		return
	for g in c["goals"]:
		if g.get("at_death", false) and not at_death:
			return
		if not goal_progress(g)[0]:
			return
	GameState.set_flag("challenge_done")
	meta["challenges_done"][cid] = int(meta["challenges_done"].get(cid, 0)) + 1
	meta["badges"][c["badge"]] = true
	p["badge"] = c["badge"]
	GameState.add_log("🏅 Challenge complete: %s!" % c["name"])
	GameState.add_milestone(p["age"], "completed the \"%s\" challenge" % c["name"])
	save()
	if not at_death:
		EventEngine.push_info(c["badge"], "Challenge complete!", "You completed %s.\n\nReward: the %s badge now appears next to your name, in this life and any life you pick it for." % [c["name"], c["badge"]])


func apply_challenge_start(cid: String, opts: Dictionary) -> void:
	var c := challenge(cid)
	if c.is_empty():
		return
	var st: Dictionary = c.get("start", {})
	if st.has("countries"):
		var list: Array = st["countries"]
		opts["country"] = list[randi() % list.size()]
