extends Node

## Achievements, daily/weekly/monthly missions, Stars, titles and boons.
## Everything is earned by playing and stored across lives in user://meta.json.

signal unlocked(a: Dictionary)
signal mission_done(m: Dictionary)

const TIER_STARS := {"bronze": 5, "silver": 10, "gold": 20, "platinum": 40}
const TIER_COLORS := {"bronze": Color("#c98a4b"), "silver": Color("#b8c2cc"), "gold": Color("#f2c94c"), "platinum": Color("#9be7ff")}
const CATEGORIES := [["life", "🌱", "Life"], ["family", "👪", "Family & Love"], ["wealth", "💰", "Wealth"], ["career", "💼", "Career"],
	["fame", "⭐", "Fame"], ["crime", "🦹", "Crime"], ["empires", "🏢", "Empires"], ["outdoors", "🌲", "Outdoors"],
	["minigames", "🎮", "Minigames"], ["grit", "🩸", "Grit"], ["legacy", "🏛️", "Legacy"], ["paths", "🌙", "Other Lives"], ["pets", "🐾", "Pets Life"], ["prison", "⛓️", "Prison Life"], ["secret", "❔", "Secret"]]
const PERIODS := {"daily": {"count": 3, "stars": 5, "bonus": 5, "name": "Daily"}, "weekly": {"count": 5, "stars": 15, "bonus": 20, "name": "Weekly"}, "monthly": {"count": 8, "stars": 50, "bonus": 75, "name": "Monthly"}}

const TITLES := {
	"rookie": {"name": "The Rookie", "cost": 0}, "survivor": {"name": "The Survivor", "cost": 20}, "wanderer": {"name": "The Wanderer", "cost": 20},
	"romantic": {"name": "Hopeless Romantic", "cost": 25}, "menace": {"name": "Menace to Society", "cost": 30}, "mogul": {"name": "The Mogul", "cost": 40},
	"legend": {"name": "Living Legend", "cost": 60}, "phoenix": {"name": "The Phoenix", "cost": 50}, "saint": {"name": "Patron Saint", "cost": 45},
	"chaos": {"name": "Agent of Chaos", "cost": 35}, "angler": {"name": "Master Angler", "cost": 25}, "prophet": {"name": "The Prophet", "cost": 40},
	"immortal": {"name": "The Immortal", "cost": 100}, "gambler": {"name": "Lady Luck's Favorite", "cost": 30}, "heartless": {"name": "Heartless", "cost": 30},
	"dynasty": {"name": "Head of the Dynasty", "cost": 70},
}

var achievements: Array = []
var by_id: Dictionary = {}
var missions_pool: Array = []
var _checking := false
var life_unlocks: Array = []


func _ready() -> void:
	achievements = ContentDB._load_json("res://data/achievements.json", [])
	for a in achievements:
		by_id[a["id"]] = a
	missions_pool = ContentDB._load_json("res://data/missions.json", [])
	_g()


func _g() -> Dictionary:
	if not Meta.meta.has("goals"):
		Meta.meta["goals"] = {}
	var g: Dictionary = Meta.meta["goals"]
	for k in ["ach", "titles", "boons", "missions", "stats"]:
		if not g.has(k):
			g[k] = {}
	for k in ["stars", "stars_total"]:
		if not g.has(k):
			g[k] = 0
	if not g.has("title"):
		g["title"] = ""
	g["titles"]["rookie"] = true
	return g


func stars() -> int:
	return int(_g()["stars"])


func add_stars(n: int) -> void:
	var g := _g()
	g["stars"] = int(g["stars"]) + n
	g["stars_total"] = int(g["stars_total"]) + n


func stat_total(k: String) -> int:
	return int(_g()["stats"].get(k, 0))


# ================================================================ facts

func _ms(word: String) -> bool:
	for m in GameState.milestones:
		if str(m["text"]).find(word) != -1:
			return true
	return false


func facts() -> Dictionary:
	var f := {}
	var g := _g()
	f["lives_total"] = stat_total("lives")
	f["years_total"] = stat_total("years")
	f["ach_count"] = g["ach"].size()
	f["missions_done"] = stat_total("missions")
	f["stars_total"] = int(g["stars_total"])
	f["gritty_lives"] = stat_total("gritty_lives")
	var rib := {}
	for k in ["ribbons", "ribbons_modified"]:
		for r in Meta.meta.get(k, {}).keys():
			rib[r] = true
	f["ribbons_distinct"] = rib.size()
	f["challenges_done"] = Meta.meta.get("challenges_done", {}).size()
	f["grimoire_recipes"] = 2 + Meta.meta.get("grimoire", {}).get("recipes", {}).keys().filter(func(r): return r != "healing" and r != "glamour").size()
	var col := heirloom_collection()
	f["heirlooms_found"] = col.size()
	f["heirlooms_legendary"] = col.values().filter(func(v): return v.get("tier", "") == "legendary").size()
	if not GameState.has_life():
		return f
	var p := GameState.player
	var c: Dictionary = p.get("career", {})
	f["age"] = int(p["age"])
	f["dead"] = not p["alive"]
	f["cause"] = str(p.get("cause", ""))
	for k in GameState.STAT_KEYS:
		f[k] = int(GameState.stat(k))
	f["karma"] = int(p["karma"])
	f["money"] = int(p["money"])
	f["net_worth"] = GameState.net_worth()
	f["savings"] = int(p.get("savings", 0))
	f["investments"] = Finance.investments_value()
	f["fame"] = int(p.get("fame", 0))
	f["followers"] = Careers.followers() if p.has("fame") else 0
	f["celebrity"] = bool(p.get("celebrity", false))
	f["degrees"] = p["education"]["degrees"].size()
	var grad := false
	for dg in p["education"]["degrees"]:
		if str(dg.get("level", "bachelor")) != "bachelor":
			grad = true
	f["grad_degree"] = grad
	f["children"] = GameState.npcs_with("child", false).size()
	f["pets"] = GameState.npcs_with("pet", false).size()
	f["married"] = p["partner_status"] == "married" or GameState.has_flag("married_once") or GameState.get_counter("marriages") > 0
	f["widowed"] = GameState.has_flag("widowed")
	f["species_lived"] = Dictionary(Meta.meta.get("pets_species", {})).size()
	f["roles_lived"] = Dictionary(Meta.meta.get("prison_roles", {})).size()
	f["generation"] = int(p["generation"])
	f["prison_total"] = int(p["prison_total"])
	f["record"] = p["record"].size()
	f["heat"] = int(p.get("heat", 0))
	f["properties"] = p["properties"].size()
	f["possessions"] = p["possessions"].size()
	f["island"] = GameState.has_flag("island_owner")
	f["jobs_held"] = p["job_history"].size()
	f["retired"] = bool(p["retired"])
	for k in p["counters"].keys():
		f[k] = int(p["counters"][k])
	var tried := 0
	var best := -1
	for id in Careers.CAREERS.keys():
		var on: bool = c.get("id", "") == id
		var was: bool = on or Careers.past(id)
		f["career_" + id] = was
		if was:
			tried += 1
		f["rank_" + id] = int(c.get("rank", -1)) if on else int(p.get("career_best", {}).get(id, -1))
		best = maxi(best, int(f["rank_" + id]))
	f["careers_tried"] = tried
	f["best_rank"] = best
	f["belts"] = int(c.get("belts", 0))
	f["missions_flown"] = int(c.get("missions", 0))
	f["films"] = c.get("films", []).size() if c.get("films", []) is Array else 0
	f["ops"] = int(c.get("ops", 0))
	f["fighter_wins"] = int(c.get("wins", 0))
	var b: Dictionary = p.get("business", {})
	f["business_value"] = int(b.get("value", 0))
	f["biz_public"] = bool(b.get("public", false))
	var cu: Dictionary = p.get("cult", {})
	f["cult_members"] = maxi(int(cu.get("members", 0)), int(cu.get("peak", 0)))
	var z: Dictionary = p.get("zoo", {})
	f["zoo_species"] = z.get("animals", {}).size()
	f["zoo_visitors"] = int(z.get("visitors", 0))
	var j: Dictionary = p.get("journal", {})
	f["journal_species"] = j.get("species", {}).size()
	f["journal_fish"] = j.get("fish", {}).size()
	f["trips"] = int(j.get("trips", 0))
	f["finds"] = int(j.get("finds", 0))
	f["museum_donations"] = int(j.get("donated", 0))
	f["scars"] = p.get("scars", []).size()
	f["grudges"] = Grit.grudge_holders().size()
	f["credit"] = Grit.credit()
	f["gritty"] = Grit.key() == "gritty"
	f["gritty_age"] = int(p["age"]) if Grit.key() == "gritty" else 0
	f["active_habits"] = Grit.active_habits().size()
	f["nursing_home"] = bool(p.get("nursing_home", false))
	f["witness_protection"] = GameState.has_flag("witness_protection")
	f["fugitive"] = GameState.has_flag("fugitive")
	f["forged_passport"] = GameState.has_flag("forged_passport") or GameState.has_flag("fled_country")
	f["fled_country"] = GameState.has_flag("fled_country")
	f["pardoned"] = _ms("pardoned")
	f["exonerated"] = _ms("exonerated")
	f["coma"] = _ms("coma")
	f["beat_cancer"] = _ms("beat cancer")
	f["lottery"] = _ms("lottery")
	f["space"] = GameState.has_flag("been_to_space")
	f["modified"] = bool(p.get("modified", false))
	f["challenge_done_life"] = GameState.has_flag("challenge_done")
	f["comeback"] = GameState.get_counter("bankruptcies") > 0 and GameState.net_worth() >= 1000000
	f["broke_old"] = int(p["age"]) >= 80 and GameState.net_worth() <= 0
	f["rich_inmate"] = GameState.in_prison() and GameState.net_worth() >= 1000000
	var closest := 0
	var feuds := 0
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if n["alive"] and n.get("species", "human") == "human":
			closest = maxi(closest, int(n["closeness"]))
		if n.get("feud", false):
			feuds += 1
	f["closest"] = closest
	f["feuds"] = feuds
	var lf: Dictionary = p.get("life", {})
	f["life_type"] = str(lf.get("type", "human"))
	f["reign"] = int(lf.get("reign", 0)) if lf.get("crowned", false) else 0
	f["decrees"] = int(lf.get("decrees", 0))
	f["overthrown"] = _ms("overthrown")
	f["vamp_years"] = int(p["age"]) - int(lf.get("turned", p["age"])) if f["life_type"] == "vampire" else 0
	f["vamp_cured"] = bool(lf.get("cured", false))
	f["revealed"] = bool(lf.get("revealed", false))
	f["licenses"] = p.get("licenses", []).size()
	var bb: Dictionary = p.get("billionaire", {})
	f["team_owner"] = bb.has("team")
	f["team_titles"] = int(bb.get("team", {}).get("titles", 0))
	f["giving_pledge"] = GameState.has_flag("giving_pledge")
	f["micronation"] = GameState.has_flag("micronation")
	return f


func _meets(a: Dictionary, f: Dictionary, at_death: bool) -> bool:
	if a.get("at_death", false) and not at_death:
		return false
	for k in a.get("req", {}).keys():
		var want = a["req"][k]
		var have = f.get(k, 0)
		if want is bool:
			if bool(have) != want:
				return false
		elif want is String:
			if str(have) != want:
				return false
		elif float(have) < float(want):
			return false
	for k in a.get("req_max", {}).keys():
		if float(f.get(k, 0)) > float(a["req_max"][k]):
			return false
	return true


func has(id: String) -> bool:
	return _g()["ach"].has(id)


func prereqs_met(a: Dictionary) -> bool:
	for n in a.get("needs", []):
		if not has(n):
			return false
	return true


func check(at_death: bool = false) -> void:
	if _checking or not GameState.has_life():
		return
	if not at_death:
		deliver_stash()
	_checking = true
	var f := facts()
	var g := _g()
	var got: Array = []
	var changed_any := true
	var guard := 0
	while changed_any and guard < 5:
		guard += 1
		changed_any = false
		var mode := Lives.kind() if Lives.separate() else ""
		for a in achievements:
			if has(a["id"]) or not prereqs_met(a):
				continue
			# a separate mode is judged only by its own achievements, and the
			# human game never is
			var am = a.get("mode", "")
			if not ((am is Array and Array(am).has(mode)) or (not (am is Array) and str(am) == mode)):
				continue
			if _meets(a, f, at_death):
				g["ach"][a["id"]] = {"when": Time.get_unix_time_from_system(), "who": "%s %s" % [GameState.player["first"], GameState.player["last"]]}
				add_stars(int(TIER_STARS.get(a.get("tier", "bronze"), 5)))
				if a.has("title"):
					g["titles"][a["title"]] = true
				got.append(a)
				life_unlocks.append("%s %s" % [a["icon"], a["name"]])
				changed_any = true
				f["ach_count"] = g["ach"].size()
	_check_missions(f)
	if not got.is_empty():
		Meta.save()
		for a in got:
			GameState.add_log("🏆 Achievement unlocked: %s" % a["name"])
			unlocked.emit(a)
	_checking = false


# ================================================================ bumps

func bump(key: String, n: int = 1) -> void:
	var g := _g()
	match key:
		"years", "lives", "deaths", "missions":
			g["stats"][key] = int(g["stats"].get(key, 0)) + n
	_mission_count(key, n)


func on_new_life() -> void:
	life_unlocks.clear()
	bump("lives")
	if Grit.key() == "gritty":
		bump("gritty_lives")
		_g()["stats"]["gritty_lives"] = int(_g()["stats"].get("gritty_lives", 0)) + 1
	Meta.save()


func on_death() -> void:
	bump("deaths")
	check(true)
	Meta.save()


func on_minigame(id: String, score: float, auto: bool) -> void:
	if auto or not GameState.has_life():
		return
	GameState.counter("minigames")
	if score >= 0.7:
		GameState.counter("mg_great")
	if score >= 0.9:
		GameState.counter("mg_perfect")
		GameState.counter("mgp_" + id)
	check()


# ================================================================ missions

func period_key(period: String) -> String:
	var d := Time.get_date_dict_from_system()
	match period:
		"daily":
			return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]
		"weekly":
			var unix := int(Time.get_unix_time_from_system())
			var days := int(unix / 86400)
			var monday := days - ((days + 3) % 7)
			return "W%d" % monday
	return "%04d-%02d" % [d["year"], d["month"]]


func seconds_left(period: String) -> int:
	var now := int(Time.get_unix_time_from_system())
	var tz := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var local := now + tz
	var day_end := (int(local / 86400) + 1) * 86400
	match period:
		"daily":
			return day_end - local
		"weekly":
			var days := int(local / 86400)
			var next_monday := days + (7 - ((days + 3) % 7))
			return next_monday * 86400 - local
	var d := Time.get_date_dict_from_system()
	var ny: int = d["year"] + (1 if d["month"] == 12 else 0)
	var nm: int = 1 if d["month"] == 12 else d["month"] + 1
	var first := Time.get_unix_time_from_datetime_dict({"year": ny, "month": nm, "day": 1, "hour": 0, "minute": 0, "second": 0})
	return maxi(0, int(first) - local)


static func fmt_left(sec: int) -> String:
	var dd := sec / 86400
	var hh := (sec % 86400) / 3600
	var mm := (sec % 3600) / 60
	if dd > 0:
		return "%dd %dh" % [dd, hh]
	if hh > 0:
		return "%dh %dm" % [hh, mm]
	return "%dm" % mm


func board(period: String) -> Dictionary:
	var g := _g()
	var k := period_key(period)
	var b: Dictionary = g["missions"].get(period, {})
	if b.get("key", "") != k:
		b = {"key": k, "ids": _pick_missions(period, k), "prog": {}, "claimed": {}, "bonus": false}
		g["missions"][period] = b
		Meta.save()
	return b


func _pick_missions(period: String, k: String) -> Array:
	var pool: Array = missions_pool.filter(func(m): return Array(m["periods"]).has(period))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(k + period)
	var out: Array = []
	var guard := 0
	while out.size() < int(PERIODS[period]["count"]) and not pool.is_empty() and guard < 200:
		guard += 1
		var m: Dictionary = pool[rng.randi() % pool.size()]
		pool.erase(m)
		out.append(m["id"])
	return out


func mission(id: String) -> Dictionary:
	for m in missions_pool:
		if m["id"] == id:
			return m
	return {}


func target(m: Dictionary, period: String) -> float:
	var t = m["target"]
	if t is Dictionary:
		return float(t.get(period, t.values()[0]))
	return float(t)


func progress(period: String, id: String) -> float:
	return float(board(period)["prog"].get(id, 0))


func is_done(period: String, id: String) -> bool:
	var m := mission(id)
	return not m.is_empty() and progress(period, id) >= target(m, period)


func _mission_count(key: String, n: int) -> void:
	for period in PERIODS.keys():
		var b := board(period)
		for id in b["ids"]:
			var m := mission(id)
			if m.is_empty() or m.get("kind", "count") != "count" or m["key"] != key:
				continue
			var before := float(b["prog"].get(id, 0))
			var t := target(m, period)
			if before >= t:
				continue
			b["prog"][id] = before + n
			if before + n >= t:
				_complete(period, m)


func _check_missions(f: Dictionary) -> void:
	for period in PERIODS.keys():
		var b := board(period)
		for id in b["ids"]:
			var m := mission(id)
			if m.is_empty() or m.get("kind", "count") != "reach":
				continue
			var t := target(m, period)
			if float(b["prog"].get(id, 0)) >= t:
				continue
			var ok := true
			for rk in m.get("also", {}).keys():
				if bool(f.get(rk, false)) != bool(m["also"][rk]):
					ok = false
			var v := float(f.get(m["key"], 0)) if ok else 0.0
			if v > float(b["prog"].get(id, 0)):
				b["prog"][id] = minf(v, t)
				if v >= t:
					_complete(period, m)


func _complete(period: String, m: Dictionary) -> void:
	GameState.add_log("🎯 %s mission complete: %s" % [PERIODS[period]["name"], text(m, period)])
	mission_done.emit({"period": period, "m": m})
	Meta.save()


func text(m: Dictionary, period: String) -> String:
	var t := target(m, period)
	var shown := GameState.fmt_money(int(t)) if m.get("money", false) else str(int(t))
	var out := str(m["text"]).replace("{n}", shown)
	if int(t) == 1 and not m.get("money", false):
		out = out.replace("1 times", "once")
		for pair in [["businesses", "business"], ["children", "child"], ["degrees", "degree"], ["Turning Points", "Turning Point"], ["vacations", "vacation"], ["people", "person"], ["stolen items", "stolen item"], ["properties", "property"], ["habits", "habit"], ["scars", "scar"], ["championships or belts", "championship or belt"], ["acting awards", "acting award"], ["minigames", "minigame"], ["new lives", "new life"], ["kinds of animals", "kind of animal"], ["special careers", "special career"], ["years", "year"]]:
			out = out.replace("1 " + pair[0], "1 " + pair[1])
	return out


func claimable(period: String, id: String) -> bool:
	return is_done(period, id) and not board(period)["claimed"].has(id)


func claim(period: String, id: String) -> int:
	if not claimable(period, id):
		return 0
	var b := board(period)
	b["claimed"][id] = true
	var n := int(PERIODS[period]["stars"])
	add_stars(n)
	bump("missions")
	var all := true
	for mid in b["ids"]:
		if not b["claimed"].has(mid):
			all = false
	if all and not b["bonus"]:
		b["bonus"] = true
		n += int(PERIODS[period]["bonus"])
		add_stars(int(PERIODS[period]["bonus"]))
	Meta.save()
	check()
	return n


func unclaimed_count() -> int:
	var n := 0
	for period in PERIODS.keys():
		for id in board(period)["ids"]:
			if claimable(period, id):
				n += 1
	return n


# ================================================================ shop

func buy_title(id: String) -> bool:
	var g := _g()
	var cost := int(TITLES[id]["cost"])
	if g["titles"].has(id) or stars() < cost:
		return false
	g["stars"] = stars() - cost
	g["titles"][id] = true
	g["title"] = id
	Meta.save()
	return true


func owns_title(id: String) -> bool:
	return _g()["titles"].has(id)


func set_title(id: String) -> void:
	var g := _g()
	if id == "" or g["titles"].has(id):
		g["title"] = id
		Meta.save()


func title_name() -> String:
	var id: String = _g()["title"]
	if id == "":
		return ""
	if TITLES.has(id):
		return TITLES[id]["name"]
	for a in achievements:
		if a.get("title", "") == id:
			return a.get("title_name", id.capitalize())
	return id.capitalize()


func owns_boon(id: String) -> bool:
	return _g()["boons"].has(id)


func buy_boon(id: String) -> bool:
	var cost := int(Grit.BOONS[id]["cost"])
	if owns_boon(id) or stars() < cost:
		return false
	var g := _g()
	g["stars"] = stars() - cost
	g["boons"][id] = true
	Meta.save()
	return true


func count_in(cat: String) -> Array:
	var have := 0
	var total := 0
	for a in achievements:
		if a.get("cat", "") == cat:
			total += 1
			if has(a["id"]):
				have += 1
	return [have, total]


# ================================================================ daily heirloom

const HEIR_TIERS := [
	["common", "Common", 58.0, Color("#9aa5b1"), [["🕰️", "Brass pocket watch", 400], ["🥄", "Silver spoon set", 600], ["🧭", "Old brass compass", 350], ["🧵", "Hand-stitched quilt", 500], ["💿", "First-pressing vinyl", 700], ["🪙", "Grandpa's coin jar", 300]]],
	["uncommon", "Uncommon", 26.0, Color("#4cc38a"), [["📿", "Pearl necklace", 4000], ["⏰", "Antique mantel clock", 3000], ["📕", "First-edition novel", 6000], ["🗿", "Jade figurine", 5000], ["📷", "Vintage camera", 2500]]],
	["rare", "Rare", 11.0, Color("#4c8dff"), [["🏺", "Porcelain vase", 30000], ["🎻", "Antique violin", 45000], ["⚔️", "Ceremonial sword", 25000], ["💍", "Sapphire brooch", 35000], ["🥚", "Jeweled egg", 60000]]],
	["epic", "Epic", 4.0, Color("#b067ff"), [["👸", "Diamond tiara", 250000], ["🖼️", "Old master sketch", 400000], ["🦴", "Fossilized dinosaur egg", 180000], ["☄️", "Iron meteorite", 150000]]],
	["legendary", "Legendary", 1.0, Color("#ffb020"), [["🪄", "Royal scepter", 3000000], ["🖼️", "A long-lost masterpiece", 8000000], ["🏴‍☠️", "Pirate treasure chest", 2000000], ["📜", "An emperor's signed letter", 1500000]]],
]
const QUALITY := ["", "Polished", "Restored", "Pristine", "Museum-grade"]


static func today_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


func daily_available() -> bool:
	return str(_g().get("daily_last", "")) != today_key()


func heirloom_collection() -> Dictionary:
	var g := _g()
	if not g.has("heirlooms"):
		g["heirlooms"] = {}
	return g["heirlooms"]


func claim_daily() -> Dictionary:
	if not daily_available():
		return {}
	var g := _g()
	g["daily_last"] = today_key()
	var pity := int(g.get("heir_pity", 0))
	var weights: Array = []
	var total := 0.0
	for t in HEIR_TIERS:
		var w := float(t[2])
		if t[0] == "epic":
			w += pity * 0.6
		elif t[0] == "legendary":
			w += pity * 0.25
		weights.append(w)
		total += w
	var roll := randf() * total
	var tier: Array = HEIR_TIERS[0]
	var acc := 0.0
	for ti in range(HEIR_TIERS.size()):
		acc += float(weights[ti])
		if roll < acc:
			tier = HEIR_TIERS[ti]
			break
	g["heir_pity"] = 0 if tier[0] in ["epic", "legendary"] else pity + 1
	var col := heirloom_collection()
	var items: Array = tier[4]
	var fresh: Array = items.filter(func(x): return not col.has(x[1]))
	var it: Array = fresh[randi() % fresh.size()] if not fresh.is_empty() and randf() < 0.7 else items[randi() % items.size()]
	var count := int(col.get(it[1], {}).get("count", 0)) + 1
	col[it[1]] = {"count": count, "tier": tier[0], "icon": it[0]}
	var q: String = QUALITY[mini(count - 1, QUALITY.size() - 1)]
	var value := int(float(it[2]) * minf(3.0, 1.0 + (count - 1) * 0.25) * randf_range(0.85, 1.2))
	var item := {"name": (q + " " + it[1].to_lower()).strip_edges().capitalize() if q != "" else it[1], "icon": it[0], "cat": "Heirlooms", "value": value, "vol": 0.04, "bought": 0, "heirloom": true, "rarity": tier[0]}
	var delivered := false
	if GameState.has_life() and GameState.player.get("alive", false):
		GameState.player["possessions"].append(item)
		GameState.add_log("I received a family heirloom: %s (%s)." % [item["name"], tier[1]])
		delivered = true
	else:
		if not g.has("heir_stash"):
			g["heir_stash"] = []
		g["heir_stash"].append(item)
	bump("heirlooms")
	Meta.save()
	check()
	return {"item": item, "tier": tier, "count": count, "delivered": delivered}


func deliver_stash() -> void:
	var g := _g()
	var stash: Array = g.get("heir_stash", [])
	if stash.is_empty() or not GameState.has_life() or int(GameState.player["age"]) < 16:
		return
	for it in stash:
		GameState.player["possessions"].append(it)
	GameState.add_log("A family lawyer delivered heirlooms held in trust for me: %s." % ", ".join(stash.map(func(i): return i["name"])))
	g["heir_stash"] = []
	Meta.save()
