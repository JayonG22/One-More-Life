extends Node

signal changed
signal log_added(age: int, text: String)
signal year_started(age: int)

const STAT_KEYS := ["happiness", "health", "smarts", "looks", "stress"]
const TIME_PER_YEAR := 12
const START_YEAR := 2026

const HOUSING := {
	"parents": {"name": "Living with family", "rent": 0, "happiness": 0},
	"dorm": {"name": "University dorm", "rent": 0, "happiness": 2},
	"apartment": {"name": "Rented apartment", "rent": 14000, "happiness": 3},
	"house": {"name": "Your own house", "rent": 0, "happiness": 6},
	"homeless": {"name": "No fixed address", "rent": 0, "happiness": -10},
}

const CARS := {
	"used": {"name": "Used hatchback", "price": 8000, "upkeep": 1500, "happiness": 3},
	"new": {"name": "New sedan", "price": 32000, "upkeep": 2500, "happiness": 5},
	"sports": {"name": "Sports car", "price": 95000, "upkeep": 6000, "happiness": 9},
}

const HOUSE_PRICE := 260000
const MORTGAGE_YEARS := 25

var player: Dictionary = {}
var npcs: Dictionary = {}
var log_years: Array = []
var flags: Dictionary = {}
var followups: Array = []
var event_history: Dictionary = {}
var milestones: Array = []
var interacted: Dictionary = {}
var job_listings: Dictionary = {}
var next_npc_id: int = 1
var settings: Dictionary = {"theme": "dark", "celeb_theme": true, "units": "metric", "mg_pace": "relaxed"}
var world: Dictionary = {}

const PLAYER_DEFAULTS := {
	"career": {}, "fame": 0.0, "followers": 0, "celebrity": false,
	"savings": 0, "stocks": {}, "crypto": {}, "properties": [], "possessions": [],
	"licenses": [], "modifiers": [], "modified": false, "challenge": "", "badge": "",
	"jail_card_year": -1, "expecting": false, "hospitalized": false, "legacy": {},
	"heat": 0.0, "business": {}, "cult": {}, "zoo": {}, "journal": {}, "museum": false, "past_careers": [],
	"difficulty": "real", "boons": [], "scars": [], "habits": {}, "credit": 650, "nursing_home": false,
	"life": {"type": "human"}, "billionaire": {}, "hidden": {},
	"medical": {}, "home": {}, "casino": {}, "threads": {}, "ambition": {},
}

const ALL_RIBBONS := [
	["Outlaw", "⛓️"], ["Tycoon", "💰"], ["Big Family", "👨‍👩‍👧‍👦"], ["Scholar", "🎓"], ["Heartbreaker", "💔"],
	["High Roller", "🎰"], ["Globetrotter", "✈️"], ["Gone Too Soon", "🕯️"], ["Ancient", "🐢"], ["Kind Soul", "🕊️"],
	["Peaceful Life", "👑"], ["Ordinary", "🎗️"], ["Famous", "⭐"], ["Commander in Chief", "🏛️"], ["Godfather", "🕴️"],
	["Rock Star", "🎸"], ["Silver Screen", "🎬"], ["Champion", "🏆"], ["Landlord", "🏘️"], ["Street Legend", "🎲"],
	["Market Wizard", "📈"], ["Monarch", "👑"], ["Immortal", "🧛"], ["At Peace", "🕊️"], ["Hero", "🦸"], ["Supervillain", "🦹"],
	["Coven Mother", "🧙"], ["Philanthropist", "🤲"], ["Houdini", "🔓"], ["Kingpin", "💊"], ["Cat Burglar", "🥷"],
	["Decorated", "🎖️"], ["Influencer", "📱"], ["Jackpot", "🍀"], ["Big Spender", "🛍️"], ["Fertile", "🍼"],
	["Generous", "🎁"], ["Mooch", "🪣"], ["Rowdy", "🥊"], ["Model Citizen", "🏅"], ["Mediocre", "😐"],
	["Lazy", "🛋️"], ["Loner", "🌑"], ["Black Belt", "🥋"], ["Prom Royalty", "👑"],
	["Sea Legend", "🏴‍☠️"], ["Mars Pioneer", "🪐"], ["Chrononaut", "⌛"], ["Homekeeper", "🏡"], ["Recovery Path", "🌱"],
]


func ensure_defaults() -> void:
	for k in PLAYER_DEFAULTS.keys():
		if not player.has(k):
			var v = PLAYER_DEFAULTS[k]
			player[k] = v.duplicate(true) if (v is Dictionary or v is Array) else v
	if player.get("career", {}).has("heat"):
		player["heat"] = maxf(float(player["heat"]), float(player["career"]["heat"]))
		player["career"].erase("heat")
	if world.is_empty():
		Finance.init_world()


func has_life() -> bool:
	return not player.is_empty()


func is_alive() -> bool:
	return has_life() and player.get("alive", false)


func emit_changed() -> void:
	changed.emit()


# ---------------------------------------------------------------- creation

func hidden(k: String) -> float:
	var h: Dictionary = player.get("hidden", {})
	if not h.has(k):
		h[k] = clampf(randfn(50.0, 18.0), 5.0, 95.0)
		player["hidden"] = h
	return float(h[k])


func new_life(opts: Dictionary) -> void:
	npcs.clear()
	log_years.clear()
	flags.clear()
	followups.clear()
	event_history.clear()
	milestones.clear()
	interacted.clear()
	job_listings.clear()
	next_npc_id = 1
	var country_id: String = opts.get("country", "us")
	var gender: String = opts.get("gender", "male")
	var traits: Array = opts.get("traits", [])
	if traits.is_empty():
		traits = _random_traits(2)
	var stats := {
		"happiness": randi_range(65, 95),
		"health": randi_range(75, 100),
		"smarts": randi_range(15, 95),
		"looks": randi_range(15, 95),
		"stress": randi_range(0, 12),
	}
	var custom: Dictionary = opts.get("stats", {})
	for k in custom.keys():
		stats[k] = clampi(int(custom[k]), 0, 100)
	player = {
		"first": opts.get("first", ContentDB.random_first(gender, country_id)),
		"last": opts.get("last", ContentDB.random_last(country_id)),
		"gender": gender,
		"age": 0,
		"country": country_id,
		"alive": true,
		"stats": stats,
		"karma": 0,
		"money": int(opts.get("money", 0)),
		"traits": traits,
		"face": int(opts.get("face", randi() % 5)),
		"avatar": Dictionary(opts.get("avatar", Avatar.random(str(opts.get("gender", "male"))))).duplicate(),
		"education": _blank_education(),
		"job": {},
		"retired": false,
		"pension": 0,
		"job_history": [],
		"housing": "parents",
		"car": "",
		"house_value": 0,
		"mortgage": 0,
		"mortgage_payment": 0,
		"loan": 0,
		"partner": "",
		"partner_status": "",
		"record": [],
		"prison": 0,
		"prison_total": 0,
		"illness": "",
		"time_left": TIME_PER_YEAR,
		"routines": {"gym": false, "study": false, "meditate": false, "family": false, "walk": false},
		"generation": int(opts.get("generation", 1)),
		"born_year": int(opts.get("born_year", START_YEAR)),
		"cause": "",
		"ribbon": {},
		"counters": {},
		"last_income": 0,
		"last_expenses": 0,
		"special": opts.get("special", "standard"),
	}
	ensure_defaults()
	Grit.apply_start(opts)
	player["modifiers"] = Array(opts.get("modifiers", []))
	player["modified"] = not player["modifiers"].is_empty()
	player["challenge"] = opts.get("challenge", "")
	if not opts.get("keep_world", false):
		world = {}
		Finance.init_world()
	if player["modifiers"].has("piggy_bank"):
		player["money"] = int(player["money"]) + 1000000
	if not opts.get("keep_family", false):
		_generate_family()
	log_years.append({"age": 0, "lines": []})
	var mom := first_of("mother")
	var dad := first_of("father")
	var line := "I was born in %s." % ContentDB.country(country_id)["name"]
	if mom != "" and dad != "":
		line = "I was born in %s to %s and %s." % [ContentDB.country(country_id)["name"], full_name(mom), full_name(dad)]
	elif mom != "":
		line = "I was born in %s to %s." % [ContentDB.country(country_id)["name"], full_name(mom)]
	elif dad != "":
		line = "I was born in %s to %s." % [ContentDB.country(country_id)["name"], full_name(dad)]
	add_log(line)
	add_milestone(0, "was born in %s" % ContentDB.country(country_id)["name"])
	# The circumstance is told, not left to be inferred from who is missing.
	var ol := Origins.opening_line()
	if ol != "" and str(player.get("origin", "together")) != "together":
		add_log(ol)
		add_milestone(0, Origins.name_of().to_lower())
	var rid: String = str(opts.get("region", ""))
	player["region"] = rid if rid != "" else Places.random_region(country_id)
	Lives.apply_start(opts)
	Goals.on_new_life()
	if not opts.get("keep_family", false) or Lives.separate():
		Legacy.on_new_life()
		Goals.apply_mantel()
	changed.emit()


func _blank_education() -> Dictionary:
	return {
		"stage": "none",
		"performance": 50.0,
		"gpa_sum": 0.0,
		"gpa_years": 0,
		"grade": "",
		"hs_graduated": false,
		"uni": {},
		"degrees": [],
		"studied": false,
	}


func _random_traits(n: int) -> Array:
	var pool: Array = ContentDB.trait_names().duplicate()
	pool.shuffle()
	return pool.slice(0, n)


func _generate_family() -> void:
	# Who is in the house when you arrive is rolled, not fixed. Origins also
	# records who is married to whom, which is what stops a married parent
	# being married off again by the yearly pass.
	Origins.build(str(player["last"]))
	Bonds.starting_family()


func create_npc(relation: String, opts: Dictionary = {}) -> String:
	var id := "n%d" % next_npc_id
	next_npc_id += 1
	var c: String = player.get("country", "us")
	var gender: String = opts.get("gender", "male" if randf() < 0.5 else "female")
	var nf: String = opts.get("first", "")
	var nl: String = opts.get("last", "")
	var tries := 0
	while tries < 12:
		var f2: String = nf if nf != "" else ContentDB.random_first(gender, c)
		var l2: String = nl if nl != "" else ContentDB.random_last(c)
		if not _name_taken(f2, l2) or tries == 11:
			nf = f2
			nl = l2
			break
		if nf != "" and nl != "":
			break
		tries += 1
	var n := {
		"id": id,
		"relation": relation,
		"first": nf,
		"last": nl,
		"gender": gender,
		"age": int(opts.get("age", player.get("age", 20))),
		"alive": true,
		"closeness": int(opts.get("closeness", 50)),
		"looks": int(opts.get("looks", randi_range(20, 95))),
		"money": int(opts.get("money", randi_range(500, 40000))),
		"face": randi() % 5,
		"species": opts.get("species", "human"),
		"trait": _random_traits(1)[0],
		# Everyone gets the same stat set the player has. Other people are not a
		# closeness bar attached to a name; they have a life going on too, and
		# these are what it runs on.
		"health": int(opts.get("health", randi_range(45, 98))),
		"smarts": int(opts.get("smarts", randi_range(15, 95))),
		"happiness": int(opts.get("happiness", randi_range(35, 90))),
	}
	npcs[id] = n
	return id


func _name_taken(f: String, l: String) -> bool:
	if str(player.get("first", "")) == f and str(player.get("last", "")) == l:
		return true
	for k in npcs.keys():
		var o: Dictionary = npcs[k]
		if str(o.get("first", "")) == f and (str(o.get("last", "")) == l or o.get("alive", true)):
			return true
	return false


# ---------------------------------------------------------------- queries

func npc(id: String) -> Dictionary:
	return npcs.get(id, {})


func full_name(id: String) -> String:
	var n := npc(id)
	if n.is_empty():
		return "someone"
	if n.get("species", "human") != "human":
		return n["first"]
	return "%s %s" % [n["first"], n["last"]]


func npcs_with(relation: String, alive_only: bool = true) -> Array:
	var out: Array = []
	for id in npcs.keys():
		var n: Dictionary = npcs[id]
		if n["relation"] == relation and (not alive_only or n["alive"]):
			out.append(id)
	return out


func first_of(relation: String) -> String:
	var l := npcs_with(relation)
	return l[0] if not l.is_empty() else ""


func random_of(relations: Array) -> String:
	var pool: Array = []
	for r in relations:
		pool.append_array(npcs_with(r))
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]


func relation_label(id: String) -> String:
	var base := _relation_base(id)
	var t: String = npc(id).get("title", "")
	if t != "" and t != base:
		return "%s (%s)" % [base, t]
	return base


func _relation_base(id: String) -> String:
	var n := npc(id)
	var g: String = n.get("gender", "male")
	if Lives.separate():
		var pn: String = Lives.mode().relation_name(str(n.get("relation", "")), g)
		if pn != "":
			return pn
	var extra := Bonds.relation_name(str(n.get("relation", "")), g)
	if extra != "":
		return extra
	match n.get("relation", ""):
		"mother": return "Mother"
		"father": return "Father"
		"sibling": return "Brother" if g == "male" else ("Sister" if g == "female" else "Sibling")
		"grandparent": return "Grandfather" if g == "male" else "Grandmother"
		"auntuncle": return "Uncle" if g == "male" else "Aunt"
		"child": return "Son" if g == "male" else ("Daughter" if g == "female" else "Child")
		"partner":
			match player.get("partner_status", ""):
				"married": return "Husband" if g == "male" else ("Wife" if g == "female" else "Spouse")
				"engaged": return "Fiancé" if g == "male" else ("Fiancée" if g == "female" else "Fiancé(e)")
				_: return "Boyfriend" if g == "male" else ("Girlfriend" if g == "female" else "Partner")
		"ex": return "Ex"
		"friend": return "Friend"
		"best_friend": return "Best Friend"
		"rival": return "Rival"
		"teacher": return "Teacher"
		"boss": return "Boss"
		"coworker": return "Coworker"
		"classmate": return "Classmate"
		"crush": return "Crush"
		"neighbor": return "Neighbor"
		"crewmate": return "Crewmate"
		"pirate_rival": return "Rival Captain"
		"colonist": return str(n.get("title", "Colonist"))
		"cellmate": return "Cellmate"
		"pet": return n.get("species", "Pet").capitalize()
		"mentor": return "Mentor"
		"nemesis": return "Nemesis"
		"bio_parent": return "Birth parent"
		"banished": return "Banished"
	return n.get("relation", "").capitalize()


func pron(gender: String, kind: String) -> String:
	var table := {
		"male": {"he": "he", "him": "him", "his": "his"},
		"female": {"he": "she", "him": "her", "his": "her"},
		"nonbinary": {"he": "they", "him": "them", "his": "their"},
	}
	var row: Dictionary = table.get(gender, table["nonbinary"])
	return row.get(kind, "")


func stat(key: String) -> float:
	return float(player["stats"].get(key, 0))


func edu_level() -> String:
	var e: Dictionary = player["education"]
	for d in e["degrees"]:
		if d["level"] == "graduate":
			return "graduate"
	if not e["degrees"].is_empty():
		return "bachelor"
	if e["hs_graduated"]:
		return "high_school"
	return "none"


func gpa() -> float:
	var e: Dictionary = player["education"]
	if e["gpa_years"] == 0:
		return 0.0
	return e["gpa_sum"] / float(e["gpa_years"])


func in_school() -> bool:
	var s: String = player["education"]["stage"]
	return s == "primary" or s == "secondary"


func in_university() -> bool:
	return not player["education"]["uni"].is_empty()


func has_job() -> bool:
	return not player["job"].is_empty()


func in_prison() -> bool:
	return player.get("prison", 0) > 0


func has_trait(t: String) -> bool:
	return player["traits"].has(t)


func year_now() -> int:
	return int(player["born_year"]) + int(player["age"])


func net_worth() -> int:
	if Pets.active():
		return 0
	if Prison.active():
		return int(player["money"])
	var w: int = int(player["money"]) - int(player["loan"]) - int(player["mortgage"]) - Lending.total_owed()
	w += int(player["house_value"])
	if player["car"] != "":
		w += int(CARS[player["car"]]["price"] * 0.5)
	w += int(player.get("savings", 0))
	w += Finance.investments_value() + Finance.properties_value() + Finance.possessions_value()
	w += Empires.net_value()
	return w


func occupation_label() -> String:
	if Lives.separate():
		return Lives.mode().header_occ()
	if in_prison():
		return "Inmate"
	if not player.get("career", {}).is_empty():
		return Careers.title()
	if has_job():
		return player["job"]["title"]
	if in_university():
		return "University Student"
	if in_school():
		return "Student"
	if player["retired"]:
		return "Retired"
	if player["age"] < 5:
		return "Child"
	return "Unemployed"


func life_stage() -> String:
	if Pets.active():
		return Pets.stage_name()
	if Prison.active():
		return Prison.rank_name()
	var a: int = player["age"]
	if a < 5: return "Infant"
	if a < 13: return "Child"
	if a < 18: return "Teen"
	if a < 30: return "Young adult"
	if a < 60: return "Adult"
	return "Elder"


# ---------------------------------------------------------------- mutation

func counter(key: String, delta: int = 1) -> void:
	player["counters"][key] = int(player["counters"].get(key, 0)) + delta
	Goals.bump(key, delta)


func get_counter(key: String) -> int:
	return int(player["counters"].get(key, 0))


func change_stat(key: String, delta: float) -> int:
	var before := int(round(stat(key)))
	var hi := Grit.cap(key) if player.has("scars") else 100.0
	var cur := stat(key)
	var after := cur
	if delta > 0 and key != "stress":
		var left := delta
		while left > 0.0:
			var step := minf(1.0, left)
			after += step * (clampf((100.0 - after) / 20.0 + 0.1, 0.12, 1.0) if after > 80.0 else 1.0)
			left -= step
	else:
		after = cur + delta
	after = clampf(after, 0.0, hi)
	player["stats"][key] = after
	return int(round(after)) - before


func apply_effects(effects: Dictionary) -> Dictionary:
	var shown := {}
	for k in effects.keys():
		var v = effects[k]
		if STAT_KEYS.has(k):
			var mult := 1.0
			if k == "smarts" and v > 0 and has_trait("Bookworm"):
				mult = 1.5
			if k == "health" and v > 0 and has_trait("Athletic"):
				mult = 1.3
			if k == "stress" and v > 0 and has_trait("Anxious"):
				mult = 1.4
			if (k == "stress" and v > 0) or (k != "stress" and v < 0):
				mult *= Grit.d("harsh")
			var d := change_stat(k, float(v) * mult)
			if d != 0:
				shown[k] = d
		elif k == "popularity":
			var ssd: Dictionary = Daily._ss()
			ssd["popularity"] = clampf(float(ssd["popularity"]) + float(v), 0.0, 100.0)
		elif k == "karma":
			player["karma"] = clampi(int(player["karma"]) + int(v), -100, 100)
		elif k == "money":
			player["money"] = int(player["money"]) + int(v)
			if int(v) != 0:
				shown["money"] = int(v)
		elif k == "school":
			var e: Dictionary = player["education"]
			e["performance"] = clampf(float(e["performance"]) + float(v), 0.0, 100.0)
			if in_university():
				e["uni"]["performance"] = clampf(float(e["uni"].get("performance", 50)) + float(v), 0.0, 100.0)
		elif k == "job_perf":
			if has_job():
				player["job"]["perf"] = clampf(float(player["job"]["perf"]) + float(v), 0.0, 100.0)
		elif k == "fame":
			var before := int(player["fame"])
			player["fame"] = clampf(float(player["fame"]) + float(v), 0.0, 100.0)
			var df := int(player["fame"]) - before
			if df != 0:
				shown["fame"] = df
		elif k == "heat":
			var hb := float(player.get("heat", 0.0))
			var mult := 1.0
			if float(v) > 0 and Careers.past("agent"):
				mult = 0.7
			player["heat"] = clampf(hb + float(v) * mult, 0.0, 100.0)
			var dh := int(player["heat"]) - int(hb)
			if dh != 0:
				shown["heat"] = dh
		elif k in ["skill", "approval", "respect", "cred"]:
			if not player["career"].is_empty():
				var key: String = k
				if k == "respect" or k == "cred":
					key = "skill"
				var c: Dictionary = player["career"]
				var old := float(c.get(key, 0.0))
				c[key] = clampf(old + float(v), 0.0, 100.0)
				var dd := int(c[key]) - int(old)
				if dd != 0:
					shown[k] = dd
	changed.emit()
	return shown


## Kept because two hundred call sites use it and mean "we got on better or
## worse". It now feeds the bond model, which recomputes closeness from the
## underlying stats rather than storing it directly.
func change_closeness(id: String, delta: int) -> void:
	if not npcs.has(id):
		return
	BondStats.absorb_closeness(id, delta)
	Grit.on_closeness(id, delta)


## Move specific bond stats. This is what new code should call.
func bond(id: String, deltas: Dictionary) -> void:
	if not npcs.has(id):
		return
	BondStats.apply(id, deltas)


func spend_time(n: int = 1) -> bool:
	if int(player["time_left"]) < n:
		return false
	player["time_left"] = int(player["time_left"]) - n
	changed.emit()
	return true


func has_flag(f: String) -> bool:
	return flags.has(f)


func set_flag(f: String) -> void:
	flags[f] = int(player["age"])


func clear_flag(f: String) -> void:
	flags.erase(f)


func begin_year() -> void:
	player["age"] = int(player["age"]) + 1
	player["time_left"] = TIME_PER_YEAR
	player["education"]["studied"] = false
	if has_job():
		player["job"]["worked_hard"] = false
		player["job"]["suited"] = false
	interacted.clear()
	player["act_year"] = {}
	log_years.append({"age": player["age"], "lines": []})
	year_started.emit(player["age"])


func add_log(text: String) -> void:
	if log_years.is_empty():
		log_years.append({"age": player.get("age", 0), "lines": []})
	log_years[-1]["lines"].append(text)
	log_added.emit(int(player.get("age", 0)), text)


## Other people's news. A year keeps the two most interesting; the rest never mind.
func add_trivia(text: String) -> void:
	var n := int(player.get("trivia_year", 0))
	if int(player.get("trivia_age", -1)) != int(player.get("age", 0)):
		n = 0
		player["trivia_age"] = int(player.get("age", 0))
	if n >= 2:
		return
	player["trivia_year"] = n + 1
	add_log(text)


func add_milestone(age: int, text: String) -> void:
	milestones.append({"age": age, "text": text})


func mark_interacted(id: String, action: String) -> bool:
	var key := id + ":" + action
	if interacted.has(key):
		return false
	interacted[key] = true
	return true


func can_interact(id: String, action: String) -> bool:
	return not interacted.has(id + ":" + action)


## Money is stored in one internal unit and only ever DISPLAYED in the currency of
## the country the character lives in. Emigrating does not change what you own; it
## changes how the number is written, which is the point - a life in Lagos is
## counted in naira, not in dollars with a different sticker.
##
## `rate` is a nominal exchange rate: an illustrative snapshot, not a live feed.
## Purchasing power is handled separately by each country's `cost` and `wage`.
func currency() -> Dictionary:
	var c: Dictionary = ContentDB.country(str(player.get("country", "us"))) if not player.is_empty() else {}
	return {
		"code": str(c.get("currency", "USD")),
		"symbol": str(c.get("symbol", "$")),
		"rate": float(c.get("rate", 1.0)),
		"after": bool(c.get("symbol_after", false)),
	}


static func group_digits(raw: String) -> String:
	var out := ""
	var count := 0
	for i in range(raw.length() - 1, -1, -1):
		out = raw[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out


func fmt_money(v: int) -> String:
	var cur := currency()
	var amount := float(v) * float(cur["rate"])
	var neg := amount < 0.0
	amount = absf(amount)
	var body := ""
	# Weak currencies produce very long numbers at life-changing sums. Compact them
	# so the UI stays readable without hiding the scale.
	if amount >= 1000000000.0:
		body = "%.2fB" % (amount / 1000000000.0)
	elif amount >= 10000000.0:
		body = "%.1fM" % (amount / 1000000.0)
	else:
		body = group_digits(str(int(round(amount))))
	var sym := str(cur["symbol"])
	var text := (body + " " + sym) if bool(cur["after"]) else (sym + body)
	return ("-" + text) if neg else text


## The same amount in the player's currency and in USD, for the moments where the
## comparison is the interesting part (emigrating, world events).
func fmt_money_compare(v: int) -> String:
	var cur := currency()
	if str(cur["code"]) == "USD":
		return fmt_money(v)
	return "%s (about $%s)" % [fmt_money(v), group_digits(str(absi(v)))]


# ---------------------------------------------------------------- death & legacy

func compute_ribbon() -> Dictionary:
	if Lives.separate():
		return Lives.mode().ribbon()
	var p := player
	var age: int = p["age"]
	var lf: Dictionary = p.get("life", {})
	if p.get("billionaire", {}).get("pledge", false) or int(p.get("billionaire", {}).get("foundation", 0)) >= 1000000000:
		return {"name": "Philanthropist", "icon": "🤲", "desc": "You gave it all away, and the world is better for it."}
	match str(lf.get("type", "human")):
		"royal":
			if lf.get("crowned", false):
				return {"name": "Monarch", "icon": "👑", "desc": "You wore the crown. History will remember your reign."}
		"vampire":
			if age >= 120:
				return {"name": "Immortal", "icon": "🧛", "desc": "You outlived everyone. Eventually, even yourself."}
		"revenant":
			if lf.get("done", false):
				return {"name": "At Peace", "icon": "🕊️", "desc": "You came back to finish what you started, and then you rested."}
		"super":
			if lf.get("side", "hero") == "hero" and int(lf.get("saves", 0)) >= 10:
				return {"name": "Hero", "icon": "🦸", "desc": "The city built a statue of you."}
			if lf.get("side", "") == "villain" and int(lf.get("heists", 0)) >= 5:
				return {"name": "Supervillain", "icon": "🦹", "desc": "Parents still use your name to scare their children."}
		"witch":
			if lf.get("coven", []).size() >= 3:
				return {"name": "Coven Mother", "icon": "🧙", "desc": "Your coven still lights a candle for you every full moon."}
		"pirate":
			if int(lf.get("rank", 0)) >= 4 or int(lf.get("treasure", 0)) >= 500000:
				return {"name": "Sea Legend", "icon": "🏴‍☠️", "desc": "Your flag became a story sailors told in every port."}
		"colonist":
			if int(lf.get("rank", 0)) >= 4 or int(lf.get("discoveries", 0)) >= 12:
				return {"name": "Mars Pioneer", "icon": "🪐", "desc": "You helped turn a hostile outpost into somewhere people could call home."}
		"traveler":
			if int(lf.get("jumps", 0)) >= 4 or int(lf.get("artifacts", 0)) >= 12:
				return {"name": "Chrononaut", "icon": "⌛", "desc": "You carried memories from years that were never supposed to meet."}
	if int(p.get("home", {}).get("renovations", 0)) >= 7 and int(p.get("home", {}).get("years", 0)) >= 15:
		return {"name": "Homekeeper", "icon": "🏡", "desc": "You made four walls collect a lifetime of stories."}
	if int(p.get("medical", {}).get("recovery_years", 0)) >= 8:
		return {"name": "Recovery Path", "icon": "🌱", "desc": "You kept rebuilding a life around the hard parts."}
	var worth := net_worth()
	var car: Dictionary = p.get("career", {})
	if car.get("id", "") == "politician" and get_counter("president") > 0:
		return {"name": "Commander in Chief", "icon": "🏛️", "desc": "You led the nation."}
	if car.get("id", "") == "mafia" and int(car.get("rank", 0)) >= 5:
		return {"name": "Godfather", "icon": "🕴️", "desc": "Everyone owed you a favor."}
	var dealer: Dictionary = p.get("dealer", {})
	if int(dealer.get("rep", 0)) >= 80 or get_counter("zones_owned") >= 4:
		return {"name": "Kingpin", "icon": "💊", "desc": "Every corner in the city paid you."}
	if has_flag("fugitive"):
		return {"name": "Houdini", "icon": "🔓", "desc": "They never caught you. They're still looking."}
	if get_counter("jackpots") > 0:
		return {"name": "Jackpot", "icon": "🍀", "desc": "The numbers came up. Once was enough."}
	if get_counter("burglaries") >= 6:
		return {"name": "Cat Burglar", "icon": "🥷", "desc": "In through the window, out before dawn."}
	if int(p["prison_total"]) >= 10 or get_counter("crimes") >= 8:
		return {"name": "Outlaw", "icon": "⛓️", "desc": "You lived outside the law, and the law noticed."}
	if worth >= 10000000:
		return {"name": "Tycoon", "icon": "💰", "desc": "You built a fortune most people only dream of."}
	if get_counter("awards") > 0:
		return {"name": "Silver Screen", "icon": "🎬", "desc": "Your name is on a golden statue."}
	if get_counter("diamond") > 0 or (car.get("id", "") == "musician" and int(car.get("rank", 0)) >= 4):
		return {"name": "Rock Star", "icon": "🎸", "desc": "They'll be singing your songs for decades."}
	if get_counter("titles") >= 2:
		return {"name": "Champion", "icon": "🏆", "desc": "Rings, trophies, and a jersey in the rafters."}
	if float(p.get("fame", 0)) >= 85:
		return {"name": "Famous", "icon": "⭐", "desc": "Everyone knew your name."}
	if car.get("id", "") == "hustler" and int(car.get("rank", 0)) >= 3:
		return {"name": "Street Legend", "icon": "🎲", "desc": "The streets still tell your stories."}
	if p.get("properties", []).size() >= 4:
		return {"name": "Landlord", "icon": "🏘️", "desc": "Rent day was your favorite day."}
	if Finance.investments_value() >= 2000000:
		return {"name": "Market Wizard", "icon": "📈", "desc": "You bought low and sold high."}
	if get_counter("medals") >= 2:
		return {"name": "Decorated", "icon": "🎖️", "desc": "Your chest ran out of room for medals."}
	if Social.total() >= 1000000:
		return {"name": "Influencer", "icon": "📱", "desc": "A million people watched you live."}
	if npcs_with("child", false).size() >= 10:
		return {"name": "Fertile", "icon": "🍼", "desc": "Your family could field a sports team."}
	if npcs_with("child", false).size() >= 4:
		return {"name": "Big Family", "icon": "👨‍👩‍👧‍👦", "desc": "Your family tree has a lot of branches."}
	if p["education"]["degrees"].size() >= 3 or stat("smarts") >= 97:
		return {"name": "Scholar", "icon": "🎓", "desc": "You never stopped learning."}
	if get_counter("partners") >= 6:
		return {"name": "Heartbreaker", "icon": "💔", "desc": "So many loves, so little time."}
	if get_counter("gambles") >= 12:
		return {"name": "High Roller", "icon": "🎰", "desc": "The house always wins. You kept checking anyway."}
	if get_counter("spent") >= 1000000:
		return {"name": "Big Spender", "icon": "🛍️", "desc": "If it had a price tag, you bought it."}
	if get_counter("belts_earned") >= 8:
		return {"name": "Black Belt", "icon": "🥋", "desc": "Discipline, respect, and a very good roundhouse kick."}
	if get_counter("fights_won") >= 6:
		return {"name": "Rowdy", "icon": "🥊", "desc": "You never backed down from a fight."}
	if get_counter("generous") >= 15:
		return {"name": "Generous", "icon": "🎁", "desc": "You gave more than you ever took."}
	if get_counter("mooch") >= 10:
		return {"name": "Mooch", "icon": "🪣", "desc": "Family is there to help. You made sure of it."}
	if get_counter("prom_crowns") > 0 and age < 60:
		return {"name": "Prom Royalty", "icon": "👑", "desc": "Peaked in high school, and loved every minute."}
	if get_counter("vacations") >= 8:
		return {"name": "Globetrotter", "icon": "✈️", "desc": "You saw more of the world than most."}
	if age < 30:
		return {"name": "Gone Too Soon", "icon": "🕯️", "desc": "A short life, remembered by those who loved you."}
	if age >= 95:
		return {"name": "Ancient", "icon": "🐢", "desc": "You outlived nearly everyone you knew."}
	if p["record"].is_empty() and int(p["karma"]) >= 60 and age >= 50:
		return {"name": "Model Citizen", "icon": "🏅", "desc": "You paid your taxes, returned your library books, and never once jaywalked."}
	if int(p["karma"]) >= 40:
		return {"name": "Kind Soul", "icon": "🕊️", "desc": "People were better off for knowing you."}
	if stat("happiness") >= 75:
		return {"name": "Peaceful Life", "icon": "👑", "desc": "You lived a long and meaningful life."}
	if age >= 40 and get_counter("full_jobs") == 0 and not has_job() and p.get("career", {}).is_empty():
		return {"name": "Lazy", "icon": "🛋️", "desc": "You never worked a day in your life, and you were proud of it."}
	var friends := npcs_with("friend").size() + npcs_with("best_friend").size()
	if age >= 50 and friends == 0 and p["partner"] == "" and npcs_with("child").is_empty():
		return {"name": "Loner", "icon": "🌑", "desc": "You kept to yourself, all the way to the end."}
	var mid := true
	for k in ["happiness", "health", "smarts", "looks"]:
		if absf(stat(k) - 50.0) > 12.0:
			mid = false
	if mid and age >= 50:
		return {"name": "Mediocre", "icon": "😐", "desc": "Not great. Not terrible. Perfectly average in every way."}
	return {"name": "Ordinary", "icon": "🎗️", "desc": "A quiet life, fully lived."}


func build_story() -> String:
	if Lives.separate():
		return Lives.mode().story()
	var p := player
	var he := pron(p["gender"], "he").capitalize()
	var lines: Array = []
	var full := "%s %s" % [p["first"], p["last"]]
	var mom := first_of_any("mother")
	var dad := first_of_any("father")
	var opening := "%s was born in %s in %d" % [full, ContentDB.country(p["country"])["name"], int(p["born_year"])]
	if mom != "" and dad != "":
		opening += " to %s and %s" % [npc(mom)["first"], npc(dad)["first"]]
	lines.append(opening + ".")
	var seen_birth := false
	for m in milestones:
		if not seen_birth and m["text"].begins_with("was born"):
			seen_birth = true
			continue
		lines.append("At %d, %s %s." % [int(m["age"]), pron(p["gender"], "he"), m["text"]])
	var kids := npcs_with("child", false).size()
	if kids > 0:
		lines.append("%s raised %d %s." % [he, kids, "child" if kids == 1 else "children"])
	lines.append("%s died at %d of %s, leaving a net worth of %s." % [he, int(p["age"]), p["cause"], fmt_money(net_worth())])
	return "\n".join(lines)


func first_of_any(relation: String) -> String:
	var l := npcs_with(relation, false)
	return l[0] if not l.is_empty() else ""


func finalize_death(cause: String) -> Dictionary:
	player["alive"] = false
	player["cause"] = cause
	if not (Prison.active() and str(Prison.L().get("outcome", "")) != ""):
		add_log("I died of %s at age %d." % [cause, int(player["age"])])
	player["ribbon"] = compute_ribbon()
	var entry := {
		"name": "%s %s" % [player["first"], player["last"]],
		"gender": player["gender"],
		"face": player["face"],
		"avatar": player.get("avatar", {}),
		"born": int(player["born_year"]),
		"died": year_now(),
		"age": int(player["age"]),
		"cause": cause,
		"occupation": last_occupation(),
		"net_worth": net_worth(),
		"ribbon": player["ribbon"],
		"story": build_story(),
		"generation": int(player["generation"]),
		"modified": bool(player.get("modified", false)),
		"badge": player.get("badge", ""),
		"difficulty": player.get("difficulty", "real"),
		"consequences": Grit.consequences(),
	}
	if Lives.separate():
		var ex: Dictionary = Lives.mode().entry_extra()
		entry["mode"] = ex
		if Pets.active():
			entry["pet"] = ex
			entry["net_worth"] = 0
	var ending := Arcs.ending_entry()
	if not ending.is_empty():
		entry["ending"] = ending
		entry["story"] = str(entry["story"]) + "\n" + str(ending["text"])
	var sd: Dictionary = Seeded.evaluate(entry)
	if not sd.is_empty():
		entry["seeded"] = sd
	player["legacy"] = entry
	changed.emit()
	return entry


func last_occupation() -> String:
	if Pets.active():
		return str(Pets.ROLES[str(Pets.L().get("role", "companion"))]["name"])
	if Prison.active():
		return Prison.rank_name()
	if has_job():
		return player["job"]["title"]
	if player["retired"] and not player["job_history"].is_empty():
		return "Retired " + str(player["job_history"][-1])
	if not player["job_history"].is_empty():
		return str(player["job_history"][-1])
	return occupation_label()


func heirs() -> Array:
	return npcs_with("child")


const ESTATE_TAX := {"us": [0.40, 13000000], "uk": [0.40, 325000], "de": [0.30, 400000], "jp": [0.45, 300000], "fr": [0.40, 100000], "br": [0.08, 0], "mx": [0.0, 0], "ph": [0.06, 0], "ng": [0.0, 0]}


func continue_as(child_id: String) -> void:
	var old := player.duplicate(true)
	var old_npcs := npcs.duplicate(true)
	var child: Dictionary = old_npcs[child_id]
	var living_children: Array = npcs_with("child").filter(func(x): return not npcs[x].get("disowned", false))
	var estate: int = maxi(0, net_worth() - Finance.properties_value() - Finance.possessions_value())
	var tx: Array = ESTATE_TAX.get(str(old["country"]), [0.0, 0])
	var estate_tax := int(maxi(0, estate - int(tx[1])) * float(tx[0]))
	var net_estate := int((estate - estate_tax) * 0.95)
	var will: String = str(old.get("will", "equal"))
	var share := 0
	var sibs := maxi(1, living_children.size())
	if will == "charity":
		share = 0
	elif will.begins_with("heir:"):
		share = int(net_estate * 0.3 / sibs) + (int(net_estate * 0.7) if will.substr(5) == child_id else 0)
	elif living_children.has(child_id):
		share = int(net_estate / sibs)
	var heir_kids: Array = []
	for oid in old_npcs.keys():
		if str(old_npcs[oid].get("parent_id", "")) == child_id and old_npcs[oid]["relation"] == "grandchild":
			heir_kids.append(oid)
	var heir_props: Array = old.get("properties", []).duplicate(true)
	var heir_items: Array = old.get("possessions", []).duplicate(true)
	for it in heir_items:
		it["heirloom"] = true
	for pr in heir_props:
		pr["tenant"] = ""
	npcs.clear()
	next_npc_id = 1
	var inherit_traits: Array = []
	if not old["traits"].is_empty():
		inherit_traits.append(old["traits"][randi() % old["traits"].size()])
	var extra := _random_traits(3)
	for t in extra:
		if not inherit_traits.has(t) and inherit_traits.size() < 2:
			inherit_traits.append(t)
	log_years = []
	milestones.clear()
	flags.clear()
	followups.clear()
	event_history.clear()
	job_listings.clear()
	var age: int = child["age"]
	player = {}
	new_life({
		"first": child["first"], "last": child["last"], "gender": child["gender"],
		"country": old["country"], "traits": inherit_traits, "keep_family": true,
		"generation": int(old["generation"]) + 1,
		"born_year": int(old["born_year"]) + int(old["age"]) - age,
		"money": share,
		"keep_world": true,
		"difficulty": old.get("difficulty", "real"),
		"boons": old.get("boons", []),
		"life_path": "human",
	})
	player["properties"] = heir_props
	player["possessions"] = heir_items
	var old_ambition: Dictionary = old.get("ambition", {})
	var old_enterprise: Dictionary = old_ambition.get("enterprise", {})
	if str(old_enterprise.get("succession", "")) == child_id:
		player["ambition"]["enterprise"] = old_enterprise.duplicate(true)
		player["ambition"]["enterprise"]["succession"] = ""
	log_years.clear()
	milestones.clear()
	player["age"] = age
	player["face"] = child.get("face", 0)
	var oldav: Dictionary = old.get("avatar", {})
	var kidav := Avatar.random(str(player["gender"]))
	if not oldav.is_empty():
		kidav["skin"] = clampi(int(oldav["skin"]) + randi_range(-1, 1), 0, Avatar.SKIN.size() - 1)
		if randf() < 0.6:
			kidav["hair_col"] = oldav["hair_col"]
		if randf() < 0.5:
			kidav["eye_col"] = oldav["eye_col"]
	player["avatar"] = kidav
	player["stats"]["smarts"] = clampf((stat("smarts") + float(old["stats"]["smarts"])) / 2.0 + randf_range(-10, 10), 5, 100)
	var parent_rel := "father" if old["gender"] == "male" else "mother"
	if old["gender"] == "nonbinary":
		parent_rel = "mother" if randf() < 0.5 else "father"
	create_npc(parent_rel, {"first": old["first"], "last": old["last"], "gender": old["gender"], "age": old["age"], "closeness": child.get("closeness", 70)})
	npcs[npcs.keys()[-1]]["alive"] = false
	if old["partner"] != "" and old_npcs.has(old["partner"]) and old["partner_status"] == "married":
		var sp: Dictionary = old_npcs[old["partner"]]
		var sp_rel := "mother" if parent_rel == "father" else "father"
		var id := create_npc(sp_rel, {"first": sp["first"], "last": sp["last"], "gender": sp["gender"], "age": sp["age"], "closeness": 70})
		npcs[id]["alive"] = sp["alive"]
	if child.get("married", false) and str(child.get("spouse", "")) != "":
		var nm: PackedStringArray = str(child["spouse"]).split(" ", false, 1)
		var spid := create_npc("partner", {"first": nm[0], "last": nm[1] if nm.size() > 1 else child["last"], "gender": child.get("spouse_gender", "female"), "age": maxi(18, age + randi_range(-3, 3)), "closeness": 70})
		player["partner"] = spid
		player["partner_status"] = "married"
		player["married_at"] = maxi(18, age - randi_range(1, 8))
		player["living_together"] = true
	var feuds: Array = []
	for oid in old_npcs.keys():
		var o: Dictionary = old_npcs[oid]
		if oid == child_id:
			continue
		var rel := ""
		match o["relation"]:
			"child": rel = "sibling"
			"stepchild": rel = "stepsibling"
			"mother", "father": rel = "grandparent"
			"sibling": rel = "auntuncle"
			"niece_nephew": rel = "cousin"
			"grandchild": rel = "child" if heir_kids.has(oid) else "niece_nephew"
			"pet": rel = "pet" if o["alive"] and int(o.get("age", 0)) < 12 else ""
		if rel == "" and o["alive"] and int(o.get("grudge", 0)) >= 50 and o.get("species", "human") == "human":
			var fid := create_npc("rival", {"first": o["first"], "last": o["last"], "gender": o["gender"], "age": o["age"], "closeness": 5})
			npcs[fid]["grudge"] = int(int(o["grudge"]) * 0.6)
			npcs[fid]["feud"] = true
			feuds.append(o["first"] + " " + o["last"])
			continue
		if rel == "":
			continue
		if not o["alive"] and rel in ["cousin", "niece_nephew", "stepsibling", "pet"]:
			continue
		var opts := {"first": o["first"], "last": o["last"], "gender": o["gender"], "age": o["age"], "closeness": maxi(30, int(o["closeness"]) - 10)}
		if rel == "pet":
			opts["species"] = o.get("species", "dog")
		var nid := create_npc(rel, opts)
		npcs[nid]["alive"] = o["alive"]
		npcs[nid]["face"] = o.get("face", 0)
		if rel == "pet" and o.has("pet_profile"):
			npcs[nid]["pet_profile"] = o["pet_profile"].duplicate(true)
			player["ambition"]["pets"] = player["ambition"].get("pets", {"shows":0,"titles":0,"litters":0,"business":{},"legacy_pets":0})
			player["ambition"]["pets"]["legacy_pets"] = int(player["ambition"]["pets"].get("legacy_pets",0)) + 1
		if rel == "sibling" and will == "charity":
			npcs[nid]["closeness"] = maxi(0, int(npcs[nid]["closeness"]) - 20)
		elif rel == "sibling" and will.begins_with("heir:") and will.substr(5) == child_id:
			npcs[nid]["closeness"] = maxi(0, int(npcs[nid]["closeness"]) - 15)
			npcs[nid]["grudge"] = 20
	if old["housing"] == "house" and age >= 18:
		player["housing"] = "house"
		player["house_value"] = old["house_value"]
		player["mortgage"] = old["mortgage"]
		player["mortgage_payment"] = old["mortgage_payment"]
	if age >= 18:
		player["education"]["hs_graduated"] = true
		player["education"]["stage"] = "graduated"
		if player["housing"] == "parents":
			player["housing"] = "apartment"
	elif age >= 12:
		player["education"]["stage"] = "secondary"
	elif age >= 5:
		player["education"]["stage"] = "primary"
	log_years.append({"age": age, "lines": []})
	add_log("I carried on the family line as %s %s, age %d." % [player["first"], player["last"], age])
	if share > 0:
		add_log("I inherited %s from %s %s." % [fmt_money(share), old["first"], old["last"]])
	if estate_tax > 0:
		add_log("The government took %s in inheritance tax." % fmt_money(estate_tax))
	if will == "charity":
		add_log("%s left the entire estate to charity. The family is not taking it well." % old["first"])
	elif will.begins_with("heir:") and will.substr(5) == child_id and sibs > 1:
		add_log("The will named me the main heir. My siblings are furious.")
	if not heir_props.is_empty():
		add_log("I inherited %d propert%s." % [heir_props.size(), "y" if heir_props.size() == 1 else "ies"])
	if not heir_items.is_empty():
		add_log("I inherited the family heirlooms: %s." % ", ".join(heir_items.map(func(i): return i["name"])))
	if not feuds.is_empty():
		add_log("I inherited a family feud with %s." % ", ".join(feuds))
	Lives.on_continue(old)
	add_milestone(age, "took over the family legacy after losing %s %s" % [pron(player["gender"], "his"), relation_word(parent_rel)])
	changed.emit()


func relation_word(rel: String) -> String:
	return "father" if rel == "father" else "mother"


# ---------------------------------------------------------------- save data

func to_dict() -> Dictionary:
	return {
		"version": 1,
		"player": player,
		"npcs": npcs,
		"log_years": log_years,
		"flags": flags,
		"followups": followups,
		"event_history": event_history,
		"milestones": milestones,
		"job_listings": job_listings,
		"next_npc_id": next_npc_id,
		"world": world,
	}


func from_dict(d: Dictionary) -> void:
	player = d.get("player", {})
	npcs = d.get("npcs", {})
	log_years = d.get("log_years", [])
	flags = d.get("flags", {})
	followups = d.get("followups", [])
	event_history = d.get("event_history", {})
	milestones = d.get("milestones", [])
	job_listings = d.get("job_listings", {})
	next_npc_id = int(d.get("next_npc_id", 1))
	world = d.get("world", {})
	interacted.clear()
	ensure_defaults()
	_fix_numbers()
	changed.emit()


func _fix_numbers() -> void:
	for k in ["age", "money", "karma", "time_left", "prison", "prison_total", "generation", "born_year", "loan", "mortgage", "mortgage_payment", "house_value", "face", "pension", "origin"]:
		if player.has(k):
			player[k] = int(player[k])
	for id in npcs.keys():
		for k in ["age", "closeness", "money", "face"]:
			npcs[id][k] = int(npcs[id][k])
		# Saves made before NPCs had stats get sensible ones on load.
		for k in ["health", "smarts", "happiness", "looks"]:
			if not npcs[id].has(k):
				npcs[id][k] = randi_range(35, 90)
