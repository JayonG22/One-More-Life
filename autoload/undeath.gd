extends Node

## UNDEATH — the vampire and revenant lives, given something to do.
##
## Both already changed the rules and the whole look of the game. What they had
## was seven buttons and three buttons respectively, which is not a life, it is a
## costume. The design document promised a sire, hunters and a rise to Lord for
## vampires, and failing body parts, a necromancer master, blending in and a
## crypt for the undead. None of it existed.
##
## The shape here is deliberately the same as the v0.8 detective: persistent
## named people, state that accumulates across decades, a rank you climb, and an
## antagonist who builds a case on you slowly enough that you can feel it coming.

# ============================================================================
# VAMPIRE

## Clans are a doctrine, not a badge: each one makes a different part of the
## life easier and a different part harder.
const CLANS := {
	"ash": {"name": "House of Ash", "icon": "🜂", "creed": "Burn what you were. Nothing from the living life comes with you.",
		"boon": "Thirst grows slower", "cost": "Your living family forgets you faster"},
	"veil": {"name": "The Veil", "icon": "🝊", "creed": "Be unremarkable. A vampire noticed is a vampire finished.",
		"boon": "Hunters build a case far more slowly", "cost": "Standing rises slowly; the Veil rewards patience"},
	"crimson": {"name": "Crimson Court", "icon": "🜃", "creed": "We are the older thing. Behave accordingly.",
		"boon": "Standing rises fast and compulsion lands harder", "cost": "Hunters notice you quickly"},
	"quiet": {"name": "The Quiet Ones", "icon": "🜄", "creed": "Feed without killing. It is harder. That is the point.",
		"boon": "Karma and standing both rise when you feed without killing", "cost": "Feeding clears less of the Thirst"},
}

const RANKS := [
	["Fledgling", 0, 0],
	["Kindred", 12, 25],
	["Elder", 45, 55],
	["Lord", 90, 85],
]


func _p() -> Dictionary:
	return GameState.player


func vl() -> Dictionary:
	return Lives.life()


func ensure_vampire() -> Dictionary:
	var l := vl()
	if l.get("type", "") != "vampire":
		return {}
	if not l.has("clan"):
		l["clan"] = ""
		l["standing"] = 10.0
		l["rank"] = 0
		l["sire"] = ""
		l["sire_favor"] = 50.0
		l["territory"] = 0
		l["discipline"] = 0.0
		l["hunter"] = {}
		l["spared"] = 0
		l["court_year"] = -99
	return l


## The one who turned you. Created lazily so an existing save gains a sire the
## first time it needs one, rather than never having had a maker at all.
func sire_id() -> String:
	var l := ensure_vampire()
	if l.is_empty():
		return ""
	var sid := str(l.get("sire", ""))
	if sid != "" and GameState.npcs.has(sid):
		return sid
	sid = GameState.create_npc("sire", {"age": randi_range(40, 70), "closeness": 45})
	GameState.npcs[sid]["vampire"] = true
	l["sire"] = sid
	GameState.add_log("%s is the one who turned me. That is not a debt you finish paying." % GameState.full_name(sid))
	return sid


func rank_name() -> String:
	var l := ensure_vampire()
	return str(RANKS[clampi(int(l.get("rank", 0)), 0, RANKS.size() - 1)][0])


func years_turned() -> int:
	var l := ensure_vampire()
	return int(_p()["age"]) - int(l.get("turned", _p()["age"]))


func _check_rise() -> void:
	var l := ensure_vampire()
	var r := int(l.get("rank", 0))
	if r >= RANKS.size() - 1:
		return
	var nxt: Array = RANKS[r + 1]
	if years_turned() >= int(nxt[1]) and float(l["standing"]) >= float(nxt[2]):
		l["rank"] = r + 1
		GameState.counter("vampire_ranks")
		GameState.add_milestone(int(_p()["age"]), "was recognised as %s among the kindred" % str(nxt[0]))
		LifeThreads.remember("career", "The night they named me %s" % str(nxt[0]),
			"The older ones stopped talking when I entered. That was the whole ceremony.", "", 66, ["vampire", "rank"])
		Fx.play("crown", 0.01)
		EventEngine.push_info("🧛", str(nxt[0]), "I am %s now. The ones who were here before me have started to watch what they say." % str(nxt[0]))


# ---------------------------------------------------------------- the hunter

## A hunter works the way the v0.8 detective works, from the other side of the
## glass: evidence accrues year on year, and you can feel it coming.
func hunter() -> Dictionary:
	var l := ensure_vampire()
	return l.get("hunter", {})


func _hunter_start() -> void:
	var l := ensure_vampire()
	var hid := GameState.create_npc("enemy", {"age": randi_range(26, 58), "closeness": 0})
	l["hunter"] = {"id": hid, "evidence": 12.0, "since": int(_p()["age"]), "close_calls": 0}
	Grit.grudge(hid, 60)
	GameState.add_log("Somebody has started asking the kind of questions that do not have innocent answers. Their name is %s." % GameState.full_name(hid))
	LifeThreads.remember("regret", "The one who is looking for me",
		"%s does not know what I am yet. They know something is wrong, and they are patient." % GameState.full_name(hid), hid, 70, ["vampire", "hunter"])


func _hunter_yearly() -> void:
	var l := ensure_vampire()
	var h: Dictionary = l.get("hunter", {})
	var clan := str(l.get("clan", ""))
	if h.is_empty():
		var kills := GameState.get_counter("vamp_kills")
		var risk := 0.05 + kills * 0.035 + float(_p().get("heat", 0)) / 500.0 + float(l.get("territory", 0)) * 0.02
		if clan == "veil":
			risk *= 0.45
		elif clan == "crimson":
			risk *= 1.6
		if randf() < clampf(risk, 0.0, 0.5):
			_hunter_start()
		return
	if not GameState.npcs.has(str(h["id"])) or not GameState.npcs[str(h["id"])].get("alive", true):
		l["hunter"] = {}
		return
	var gain := randf_range(4.0, 11.0) + GameState.get_counter("vamp_kills") * 0.8
	if clan == "veil":
		gain *= 0.5
	gain -= float(l.get("discipline", 0.0)) / 18.0
	h["evidence"] = clampf(float(h["evidence"]) + maxf(gain, 0.0), 0.0, 100.0)
	var ev := float(h["evidence"])
	if ev >= 90.0:
		_hunter_strike()
	elif ev >= 65.0 and randf() < 0.5:
		GameState.add_log("%s was outside the building again last night. They did not come in." % GameState.full_name(str(h["id"])))
		GameState.apply_effects({"stress": 8})
	elif ev >= 35.0 and randf() < 0.35:
		GameState.add_log("Someone has been asking my neighbours how long I have lived here.")
		GameState.apply_effects({"stress": 4})


func _hunter_strike() -> void:
	var l := ensure_vampire()
	var h: Dictionary = l["hunter"]
	var hid := str(h["id"])
	var nm := GameState.full_name(hid)
	EventEngine.push_decision({
		"id": "_vamp_hunt_strike", "icon": "🏹", "title": "They came for me",
		"text": "%s came through the door before sundown with everything they needed and no intention of talking. There is no version of tonight where this stays unresolved." % nm,
		"choices": [
			{"label": "Fight", "outcomes": [
				{"weight": 3, "text": "It was not a fight so much as a correction. I buried what was left before dawn.",
				 "effects": {"health": -20, "stress": 18, "karma": -25, "heat": 20}, "undeath": {"kind": "hunter_killed"}},
				{"weight": 2, "text": "They were better prepared than I was. I got out with most of myself.",
				 "effects": {"health": -45, "stress": 30}, "undeath": {"kind": "hunter_wound"}},
			]},
			{"label": "Disappear tonight — new city, new name", "outcomes": [
				{"text": "I left everything in the flat and was three hundred miles away by morning. It works, and it costs.",
				 "effects": {"money": -8000, "happiness": -12, "stress": 10}, "undeath": {"kind": "hunter_flee"}},
			]},
			{"label": "Let them in and talk", "requires": {"stat": {"smarts": 60}}, "outcomes": [
				{"weight": 2, "text": "I told them the truth. All of it. They listened, and then they left, and they have not come back yet.",
				 "effects": {"stress": 14, "karma": 6}, "undeath": {"kind": "hunter_truce"}},
				{"weight": 2, "text": "They let me finish speaking. Then they reached into their coat.",
				 "effects": {"health": -40, "stress": 28}, "undeath": {"kind": "hunter_wound"}},
			]},
		]})


# ---------------------------------------------------------------- actions

func vampire_extra_actions() -> Array:
	var l := ensure_vampire()
	if l.is_empty():
		return []
	var out: Array = []
	if str(l.get("clan", "")) == "":
		out.append({"id": "vx_clan", "icon": "🜂", "name": "Seek out a clan", "sub": "Four of them. Each wants something different from you."})
	else:
		var c: Dictionary = CLANS[str(l["clan"])]
		out.append({"id": "vx_court", "icon": str(c["icon"]), "name": "Attend %s court" % str(c["name"]), "sub": "Standing %d%% · %s" % [int(l["standing"]), rank_name()]})
	out.append({"id": "vx_sire", "icon": "🩸", "name": "Present yourself to your sire", "sub": "They made you. They have opinions about what you have done with it."})
	out.append({"id": "vx_territory", "icon": "🗺️", "name": "Claim a few streets", "sub": "%d held · territory feeds you and exposes you" % int(l.get("territory", 0))})
	out.append({"id": "vx_cover", "icon": "🧹", "name": "Cover your tracks", "sub": "Discipline %d · makes a hunter's case fall apart" % int(l.get("discipline", 0))})
	var h := hunter()
	if not h.is_empty() and GameState.npcs.has(str(h.get("id", ""))):
		out.append({"id": "vx_hunter", "icon": "🏹", "name": "Deal with %s" % GameState.full_name(str(h["id"])), "sub": "They have %d%% of what they need" % int(float(h["evidence"]))})
	if int(l.get("rank", 0)) >= 2:
		out.append({"id": "vx_daywalk", "icon": "🌇", "name": "Test the dawn", "sub": "Elders say it can be survived. Elders say many things."})
	return out


func vampire_extra(aid: String, arg = null) -> bool:
	var l := ensure_vampire()
	if l.is_empty():
		return false
	match aid:
		"vx_clan":
			var choices: Array = []
			for key in CLANS.keys():
				var c: Dictionary = CLANS[key]
				choices.append({"label": "%s  %s" % [str(c["icon"]), str(c["name"])],
					"outcomes": [{"text": "%s\n\n%s\n\nUpside: %s\nCost: %s" % [str(c["creed"]), "They accepted me.", str(c["boon"]), str(c["cost"])],
						"no_friction": true, "undeath": {"kind": "join_clan", "clan": key}}]})
			choices.append({"label": "Stay unaligned", "outcomes": [{"text": "I owe nobody anything. That is worth something, and it is worth less every decade.", "no_friction": true}]})
			EventEngine.push_decision({"id": "_vamp_clan", "icon": "🜂", "title": "The four houses",
				"text": "There are four of them in this city. None of them are welcoming. All of them are watching to see which way I lean.", "choices": choices})
			return true
		"vx_court":
			if not Actions._out_of_time():
				var clan := str(l["clan"])
				var gain := randf_range(4.0, 9.0) * (1.4 if clan == "crimson" else (0.7 if clan == "veil" else 1.0))
				gain += float(l.get("territory", 0)) * 0.8
				l["standing"] = clampf(float(l["standing"]) + gain, 0.0, 100.0)
				l["court_year"] = int(_p()["age"])
				if randf() < 0.25:
					var rival := GameState.create_npc("rival", {"age": randi_range(30, 90), "closeness": 12})
					GameState.npcs[rival]["vampire"] = true
					Grit.grudge(rival, 25)
					Lives._done("🜂", "Court", "I stood in a room of people older than the building and said very little. %s decided they did not care for me." % GameState.full_name(rival), {"stress": 6})
				else:
					Lives._done("🜂", "Court", "I stood in a room of people older than the building and said the right amount. Standing is not given here; it is noticed.", {"stress": 4, "happiness": 2})
				_check_rise()
			return true
		"vx_sire":
			if not Actions._out_of_time():
				var sid := sire_id()
				var pleased := float(l["standing"]) / 130.0 + float(l.get("discipline", 0)) / 200.0 + randf() * 0.4
				if pleased > 0.55:
					l["sire_favor"] = clampf(float(l["sire_favor"]) + 10.0, 0.0, 100.0)
					l["standing"] = clampf(float(l["standing"]) + 5.0, 0.0, 100.0)
					GameState.change_closeness(sid, 6)
					Lives._done("🩸", "Your sire", "%s looked at what I had made of the gift and did not correct me once. From them that is a standing ovation." % GameState.npc(sid)["first"], {"happiness": 6})
				else:
					l["sire_favor"] = clampf(float(l["sire_favor"]) - 12.0, 0.0, 100.0)
					GameState.change_closeness(sid, -5)
					Lives._done("🩸", "Your sire", "%s listened to the whole account and then asked one question I could not answer. I left feeling like a fledgling again." % GameState.npc(sid)["first"], {"happiness": -6, "stress": 8})
				_check_rise()
			return true
		"vx_territory":
			if not Actions._out_of_time():
				var odds := clampf(0.35 + float(l["standing"]) / 220.0 + float(l.get("rank", 0)) * 0.08, 0.2, 0.9)
				if randf() < odds:
					l["territory"] = int(l.get("territory", 0)) + 1
					l["standing"] = clampf(float(l["standing"]) + 6.0, 0.0, 100.0)
					Lives._done("🗺️", "Territory", "A few more streets answer to me now. Feeding is easier here, and so is being found.", {"happiness": 5, "heat": 4})
				else:
					l["standing"] = maxf(0.0, float(l["standing"]) - 4.0)
					Lives._done("🗺️", "Territory", "Somebody older already had a claim on those streets, and made the point without raising their voice.", {"stress": 9, "happiness": -4})
				_check_rise()
			return true
		"vx_cover":
			if not Actions._out_of_time():
				var fee := Actions._cost(randi_range(400, 2600))
				_p()["money"] = int(_p()["money"]) - fee
				l["discipline"] = clampf(float(l.get("discipline", 0.0)) + randf_range(8.0, 16.0), 0.0, 100.0)
				var h := hunter()
				if not h.is_empty():
					h["evidence"] = maxf(0.0, float(h["evidence"]) - randf_range(6.0, 16.0))
				GameState.apply_effects({"heat": -6})
				Lives._done("🧹", "Covering tracks", "Records altered, a landlord paid, a face changed in a photograph. It cost %s and it buys years." % GameState.fmt_money(fee), {"stress": 3})
			return true
		"vx_hunter":
			_hunter_menu()
			return true
		"vx_daywalk":
			if not Actions._out_of_time():
				var survive := clampf(0.18 + float(l.get("rank", 0)) * 0.14 + float(l["standing"]) / 400.0, 0.1, 0.7)
				if randf() < survive:
					GameState.set_flag("daywalker")
					GameState.add_milestone(int(_p()["age"]), "stood in daylight and did not burn")
					LifeThreads.remember("career", "The morning I stood in the sun", "It hurt in a way I have no word for, and then it simply stopped hurting.", "", 78, ["vampire", "daywalk"])
					Lives._done("🌇", "Dawn", "I stood in it. It hurt in a way I have no word for, and then it stopped. Not one of them believes me.", {"happiness": 18, "health": -10})
				else:
					Lives._done("🌇", "Dawn", "I lasted four seconds. I will be healing for a year and I will not be trying that again soon.", {"health": -35, "stress": 20, "looks": -8})
			return true
	return false


func _hunter_menu() -> void:
	var l := ensure_vampire()
	var h := hunter()
	if h.is_empty():
		return
	var hid := str(h["id"])
	var nm := GameState.full_name(hid)
	EventEngine.push_decision({
		"id": "_vamp_hunter", "icon": "🏹", "title": nm,
		"text": "%s has %d%% of what they would need to be certain. They are not certain yet." % [nm, int(float(h["evidence"]))],
		"choices": [
			{"label": "Feed them something false", "outcomes": [
				{"weight": 3, "text": "I built them a trail that goes somewhere else entirely. They took it.", "undeath": {"kind": "hunter_evidence", "value": -22}, "effects": {"stress": 5}},
				{"weight": 1, "text": "They checked it. Of course they checked it. Now they know somebody is managing them.", "undeath": {"kind": "hunter_evidence", "value": 14}, "effects": {"stress": 10}},
			]},
			{"label": "Compel them to forget", "outcomes": [
				{"weight": 2, "text": "I took the last four years out of their head. They looked so relieved.", "undeath": {"kind": "hunter_evidence", "value": -45}, "effects": {"karma": -8, "stress": 6}},
				{"weight": 2, "text": "Something in them would not move. They have been hunting us long enough to have learned that trick.", "undeath": {"kind": "hunter_evidence", "value": 8}, "effects": {"stress": 14}},
			]},
			{"label": "Let them find me on my terms", "outcomes": [
				{"weight": 2, "text": "I chose the room and the hour. We talked until it got light behind the blinds, and something between us changed.", "undeath": {"kind": "hunter_truce"}, "effects": {"stress": 12, "karma": 4}},
				{"weight": 2, "text": "I chose the room. They had chosen it first.", "undeath": {"kind": "hunter_evidence", "value": 30}, "effects": {"health": -18, "stress": 20}},
			]},
			{"label": "Leave them alone", "outcomes": [{"text": "I did nothing, and the file on me got one year thicker.", "no_friction": true}]},
		]})


# ============================================================================
# REVENANT / UNDEAD

const PARTS := {
	"hand": {"name": "a hand", "icon": "🖐️", "loss": "Fine work is impossible", "stat": "looks"},
	"jaw": {"name": "your jaw", "icon": "🦷", "loss": "Speaking clearly takes effort", "stat": "looks"},
	"eye": {"name": "an eye", "icon": "👁️", "loss": "Depth and distance stopped agreeing", "stat": "smarts"},
	"leg": {"name": "a leg", "icon": "🦿", "loss": "Everything takes longer now", "stat": "health"},
	"ear": {"name": "an ear", "icon": "👂", "loss": "Half the room is a rumour", "stat": "smarts"},
}

const CRYPT := [
	["A drainage culvert", 0, "Dry most months. Most."],
	["A forgotten mausoleum", 4000, "Stone, a door that locks, and company who do not talk."],
	["A deconsecrated chapel", 22000, "Room to work. Nobody comes up the path any more."],
	["A private vault", 120000, "Climate controlled. The rot slows to almost nothing."],
]


func rl() -> Dictionary:
	return Lives.life()


func ensure_revenant() -> Dictionary:
	var l := rl()
	if l.get("type", "") != "revenant":
		return {}
	if not l.has("parts"):
		l["parts"] = {}
		l["disguise"] = 45.0
		l["master"] = ""
		l["bound"] = 60.0
		l["crypt"] = 0
		l["orders_done"] = 0
		l["orders_refused"] = 0
		l["exposed"] = 0
	return l


func master_id() -> String:
	var l := ensure_revenant()
	if l.is_empty():
		return ""
	var mid := str(l.get("master", ""))
	if mid != "" and GameState.npcs.has(mid):
		return mid
	mid = GameState.create_npc("mentor", {"age": randi_range(35, 75), "closeness": 30})
	l["master"] = mid
	GameState.add_log("%s is the reason I am walking around. They have never once let me forget it." % GameState.full_name(mid))
	LifeThreads.remember("relationship", "The one who called me back",
		"%s did not ask whether I wanted to come back. They only asked whether it had worked." % GameState.full_name(mid), mid, 72, ["undead", "necromancer"])
	return mid


func lost_parts() -> Array:
	return (ensure_revenant().get("parts", {}) as Dictionary).keys()


func _lose_part() -> void:
	var l := ensure_revenant()
	var pool: Array = []
	for k in PARTS.keys():
		if not (l["parts"] as Dictionary).has(k):
			pool.append(k)
	if pool.is_empty():
		return
	var key: String = pool[randi() % pool.size()]
	l["parts"][key] = {"since": int(_p()["age"]), "replaced": false}
	var d: Dictionary = PARTS[key]
	GameState.apply_effects({str(d["stat"]): -8, "happiness": -6})
	GameState.counter("parts_lost")
	GameState.add_log("I lost %s this year. It did not hurt, which was somehow the worst part. %s." % [str(d["name"]), str(d["loss"])])
	LifeThreads.remember("injury", "The year I lost %s" % str(d["name"]),
		"It came away in my hand and I felt nothing at all.", "", 60, ["undead", "decay"])


func revenant_extra_actions() -> Array:
	var l := ensure_revenant()
	if l.is_empty():
		return []
	var out: Array = []
	var lost := lost_parts()
	if not lost.is_empty():
		out.append({"id": "rx_parts", "icon": "🦿", "name": "Find replacements", "sub": "Missing: " + ", ".join(lost.map(func(k): return str(PARTS[k]["name"])))})
	out.append({"id": "rx_disguise", "icon": "💄", "name": "Work on passing", "sub": "Passing for living: %d%%" % int(float(l.get("disguise", 45)))})
	out.append({"id": "rx_master", "icon": "🕯️", "name": "Answer your necromancer", "sub": "Bound %d%% · they always have something for me" % int(float(l.get("bound", 60)))})
	var ci := int(l.get("crypt", 0))
	if ci < CRYPT.size() - 1:
		var nxt: Array = CRYPT[ci + 1]
		out.append({"id": "rx_crypt", "icon": "⚰️", "name": "Move somewhere better", "sub": "%s · %s" % [str(nxt[0]), GameState.fmt_money(Actions._cost(int(nxt[1])))]})
	if float(l.get("bound", 60)) <= 25.0:
		out.append({"id": "rx_free", "icon": "⛓️", "name": "Break the binding", "sub": "They are not holding the leash as tightly as they think"})
	return out


func revenant_extra(aid: String, arg = null) -> bool:
	var l := ensure_revenant()
	if l.is_empty():
		return false
	match aid:
		"rx_parts":
			if not Actions._out_of_time():
				var lost := lost_parts()
				if lost.is_empty():
					return true
				var key: String = lost[0]
				var fee := Actions._cost(randi_range(600, 4000))
				if int(_p()["money"]) < fee:
					EventEngine.push_info("🦿", "Replacements", "A decent one costs %s, and the indecent ones come with somebody else's history attached." % GameState.fmt_money(fee))
					return true
				_p()["money"] = int(_p()["money"]) - fee
				(l["parts"] as Dictionary).erase(key)
				var d: Dictionary = PARTS[key]
				GameState.apply_effects({str(d["stat"]): 6, "happiness": 5})
				GameState.counter("parts_replaced")
				Lives._done("🦿", "Replaced", "I found a replacement for %s. It is not mine and it works, and I have stopped asking whose it was." % str(d["name"]), {"karma": -2})
			return true
		"rx_disguise":
			if not Actions._out_of_time():
				var fee2 := Actions._cost(randi_range(80, 600))
				_p()["money"] = int(_p()["money"]) - fee2
				l["disguise"] = clampf(float(l["disguise"]) + randf_range(9.0, 18.0), 0.0, 100.0)
				Lives._done("💄", "Passing", "Powder, wax, a scarf, a pair of gloves and a practised way of breathing that I do not need to do. People look straight through me now, which is the goal.", {"happiness": 4, "looks": 2})
			return true
		"rx_master":
			_master_order()
			return true
		"rx_crypt":
			if not Actions._out_of_time():
				var ci2 := int(l.get("crypt", 0))
				if ci2 >= CRYPT.size() - 1:
					return true
				var nxt: Array = CRYPT[ci2 + 1]
				var cost := Actions._cost(int(nxt[1]))
				if not Actions._can_pay(cost, str(nxt[0])):
					return true
				_p()["money"] = int(_p()["money"]) - cost
				l["crypt"] = ci2 + 1
				GameState.counter("crypt_upgrades")
				Lives._done("⚰️", str(nxt[0]), "%s I sleep somewhere that slows what is happening to me." % str(nxt[2]), {"happiness": 8, "stress": -6})
			return true
		"rx_free":
			if not Actions._out_of_time():
				var mid := master_id()
				var odds := clampf(0.3 + (25.0 - float(l["bound"])) / 60.0 + float(l.get("crypt", 0)) * 0.08, 0.15, 0.85)
				if randf() < odds:
					l["bound"] = 0.0
					l["free"] = true
					GameState.set_flag("unbound_revenant")
					GameState.add_milestone(int(_p()["age"]), "broke free of the one who raised them")
					if GameState.npcs.has(mid):
						GameState.npcs[mid]["relation"] = "enemy"
						Grit.grudge(mid, 70)
					LifeThreads.remember("career", "The night I stopped answering",
						"%s called and I did not go. Nothing happened. That was the whole revelation." % GameState.full_name(mid), mid, 80, ["undead", "freedom"])
					Lives._done("⛓️", "Unbound", "%s called and I did not go. I waited all night for something to happen to me. Nothing did." % GameState.full_name(mid), {"happiness": 22, "stress": -14})
				else:
					l["bound"] = clampf(float(l["bound"]) + 18.0, 0.0, 100.0)
					GameState.apply_effects({"health": -12, "stress": 22, "happiness": -10})
					Lives._done("⛓️", "Still bound", "I tried. Something in the back of my skull turned me around and walked me home, and I watched it happen from behind my own eyes.", {})
			return true
	return false


func _master_order() -> void:
	var l := ensure_revenant()
	var mid := master_id()
	var nm := GameState.full_name(mid)
	var orders := [
		["fetch something out of a grave that is not empty", -4, 6.0],
		["stand outside a house all night and report who leaves", -2, 5.0],
		["carry a locked box across the city and not open it", -1, 5.0],
		["frighten somebody badly enough that they move away", -8, 8.0],
		["dig, for three nights, and not ask what for", -3, 6.0],
	]
	var o: Array = orders[randi() % orders.size()]
	EventEngine.push_decision({
		"id": "_rev_order", "icon": "🕯️", "title": nm,
		"text": "%s wants me to %s. There is no version of this where they ask nicely, and no version where they forget they asked." % [nm, str(o[0])],
		"choices": [
			{"label": "Do it", "outcomes": [
				{"text": "I did it and did not ask. It is easier than the alternative and I dislike how easy it has become.",
				 "effects": {"karma": int(o[1]), "stress": 6}, "undeath": {"kind": "order_done", "value": float(o[2])}},
			]},
			{"label": "Refuse", "outcomes": [
				{"weight": 2, "text": "I said no. The word came out of me and stayed said. Something behind my eyes went very quiet.",
				 "effects": {"stress": 16, "health": -8, "happiness": 6}, "undeath": {"kind": "order_refused"}},
				{"weight": 1, "text": "I meant to refuse. I got halfway through the sentence and then I was already walking.",
				 "effects": {"stress": 20, "happiness": -12}, "undeath": {"kind": "order_done", "value": float(o[2])}},
			]},
			{"label": "Do it, and keep something back", "requires": {"stat": {"smarts": 55}}, "outcomes": [
				{"weight": 2, "text": "I did what was asked and kept one detail to myself. It is not much of a rebellion. It is mine.",
				 "effects": {"karma": int(o[1]) / 2, "stress": 10}, "undeath": {"kind": "order_sly"}},
				{"weight": 1, "text": "They noticed the gap immediately. I do not know how.",
				 "effects": {"stress": 22, "health": -10}, "undeath": {"kind": "order_caught"}},
			]},
		]})


# ============================================================================
# YEARLY + OUTCOME BRIDGE

func yearly() -> void:
	match Lives.kind():
		"vampire":
			var l := ensure_vampire()
			if l.is_empty():
				return
			if str(l.get("clan", "")) == "quiet":
				l["standing"] = clampf(float(l["standing"]) + float(l.get("spared", 0)) * 0.4, 0.0, 100.0)
			if str(l.get("clan", "")) == "ash":
				l["thirst"] = maxi(0, int(l.get("thirst", 0)) - 6)
			l["discipline"] = maxf(0.0, float(l.get("discipline", 0.0)) - 2.5)
			_hunter_yearly()
			_check_rise()
			if years_turned() >= 20 and str(l.get("sire", "")) != "" and GameState.npcs.has(str(l["sire"])) and randf() < 0.1:
				GameState.add_log("My sire sent word. No request in it, which is how I know one is coming.")
		"revenant":
			var l2 := ensure_revenant()
			if l2.is_empty():
				return
			var slow := 1.0 - float(l2.get("crypt", 0)) * 0.18
			l2["disguise"] = maxf(0.0, float(l2["disguise"]) - randf_range(6.0, 12.0) * slow)
			if randf() < 0.14 * slow:
				_lose_part()
			if float(l2["disguise"]) < 25.0 and randf() < 0.4:
				l2["exposed"] = int(l2.get("exposed", 0)) + 1
				GameState.apply_effects({"happiness": -8, "stress": 10, "heat": 6})
				GameState.add_log("Somebody looked at me a second too long today, and then looked away far too quickly.")
			if float(l2.get("bound", 60)) > 0.0 and randf() < 0.3:
				_master_order()


func outcome(data: Dictionary) -> void:
	var kind := str(data.get("kind", ""))
	match kind:
		"join_clan":
			var l := ensure_vampire()
			if l.is_empty():
				return
			l["clan"] = str(data.get("clan", "veil"))
			l["standing"] = clampf(float(l["standing"]) + 8.0, 0.0, 100.0)
			GameState.counter("vampire_clan")
			GameState.add_milestone(int(_p()["age"]), "was taken in by %s" % str(CLANS[str(l["clan"])]["name"]))
		"hunter_evidence":
			var h := hunter()
			if not h.is_empty():
				h["evidence"] = clampf(float(h["evidence"]) + float(data.get("value", 0.0)), 0.0, 100.0)
		"hunter_killed":
			var l2 := ensure_vampire()
			var h2 := hunter()
			if not h2.is_empty() and GameState.npcs.has(str(h2["id"])):
				GameState.npcs[str(h2["id"])]["alive"] = false
			l2["hunter"] = {}
			GameState.counter("hunters_killed")
			LifeThreads.remember("regret", "The hunter I buried", "They were right about me, which is the part I keep returning to.", "", 74, ["vampire"])
		"hunter_wound":
			var h3 := hunter()
			if not h3.is_empty():
				h3["evidence"] = clampf(float(h3["evidence"]) - 25.0, 0.0, 100.0)
				h3["close_calls"] = int(h3.get("close_calls", 0)) + 1
		"hunter_flee":
			var l3 := ensure_vampire()
			l3["hunter"] = {}
			l3["territory"] = 0
			l3["standing"] = maxf(0.0, float(l3["standing"]) - 20.0)
			Places.relocate(Places.random_region(str(_p().get("country", "us"))))
		"hunter_truce":
			var l4 := ensure_vampire()
			var h4 := hunter()
			if not h4.is_empty() and GameState.npcs.has(str(h4["id"])):
				GameState.npcs[str(h4["id"])]["relation"] = "friend"
				GameState.change_closeness(str(h4["id"]), 35)
				LifeThreads.remember("relationship", "The hunter who stopped",
					"They know exactly what I am and they have not come back. I do not know what to do with that.", str(h4["id"]), 78, ["vampire", "truce"])
			l4["hunter"] = {}
			GameState.counter("hunter_truces")
		"order_done":
			var l5 := ensure_revenant()
			l5["bound"] = clampf(float(l5["bound"]) + float(data.get("value", 5.0)), 0.0, 100.0)
			l5["orders_done"] = int(l5.get("orders_done", 0)) + 1
			GameState.counter("necro_orders")
		"order_refused":
			var l6 := ensure_revenant()
			l6["bound"] = clampf(float(l6["bound"]) - randf_range(10.0, 20.0), 0.0, 100.0)
			l6["orders_refused"] = int(l6.get("orders_refused", 0)) + 1
			GameState.counter("necro_refusals")
		"order_sly":
			var l7 := ensure_revenant()
			l7["bound"] = clampf(float(l7["bound"]) - randf_range(4.0, 9.0), 0.0, 100.0)
		"order_caught":
			var l8 := ensure_revenant()
			l8["bound"] = clampf(float(l8["bound"]) + 14.0, 0.0, 100.0)


## Extra lines for the left-hand info panel, so the state is visible.
func status_lines() -> Array:
	match Lives.kind():
		"vampire":
			var l := ensure_vampire()
			if l.is_empty():
				return []
			var out: Array = [["🧛 %s" % rank_name(), ""]]
			if str(l.get("clan", "")) != "":
				out.append([str(CLANS[str(l["clan"])]["icon"]) + " " + str(CLANS[str(l["clan"])]["name"]), int(l["standing"])])
			if int(l.get("territory", 0)) > 0:
				out.append(["🗺️ %d streets" % int(l["territory"]), ""])
			var h := hunter()
			if not h.is_empty():
				out.append(["🏹 Hunted", int(float(h["evidence"]))])
			return out
		"revenant":
			var l2 := ensure_revenant()
			if l2.is_empty():
				return []
			var out2: Array = [["💄 Passing", int(float(l2.get("disguise", 45)))]]
			if float(l2.get("bound", 0)) > 0.0:
				out2.append(["⛓️ Bound", int(float(l2["bound"]))])
			elif l2.get("free", false):
				out2.append(["⛓️ Unbound", ""])
			var lost := lost_parts()
			if not lost.is_empty():
				out2.append(["🦿 Missing %d" % lost.size(), ""])
			out2.append([str(CRYPT[int(l2.get("crypt", 0))][0]), ""])
			return out2
	return []
