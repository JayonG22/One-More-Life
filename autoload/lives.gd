extends Node

## Life Paths: Royalty, Vampire, Revenant (Undead), Super (hero or villain), Witch.

const TYPES := {
	"human": {"name": "Human", "icon": "🧑", "desc": "An ordinary life. For now."},
	"royal": {"name": "Royal", "icon": "👑", "desc": "Born into a royal house. The crown might be yours one day."},
	"vampire": {"name": "Vampire", "icon": "🧛", "desc": "You'll be turned at 18. Ageless, and always thirsty."},
	"witch": {"name": "Witch", "icon": "🧙", "desc": "Born into a family of witches. Your magic wakes at 13."},
	"super": {"name": "Gifted", "icon": "🦸", "desc": "Powers manifest at 13. Hero or villain is up to you."},
	"revenant": {"name": "Undead", "icon": "🧟", "desc": "Death won't hold you. When you die, you'll rise again."},
	"pirate": {"name": "Pirate Life", "icon": "🏴‍☠️", "desc": "Command a ship and a named crew. Raids, treasure, bounty and mutiny can rewrite the life."},
	"colonist": {"name": "Space Colonist", "icon": "🪐", "desc": "Live on Mars where oxygen, rations, settlers and colony decisions matter every year."},
	"traveler": {"name": "Time Traveler", "icon": "⌛", "desc": "Begin in 1850, 1920 or 1970. Jobs, technology, prices and events move with history."},
}
signal transformed(kind: String)

const KINDS := ["royal_speech", "feed", "patrol", "heist", "nemesis", "brew", "revenge"]
const POWERS := {
	"strength": {"name": "Super strength", "icon": "💪"}, "flight": {"name": "Flight", "icon": "🦅"},
	"speed": {"name": "Super speed", "icon": "⚡"}, "telekinesis": {"name": "Telekinesis", "icon": "🌀"},
	"invisibility": {"name": "Invisibility", "icon": "👻"}, "mind": {"name": "Mind reading", "icon": "🧠"},
	"fire": {"name": "Pyrokinesis", "icon": "🔥"}, "healing": {"name": "Regeneration", "icon": "💚"},
}
const ALIAS_A := ["Crimson", "Silent", "Iron", "Night", "Storm", "Golden", "Shadow", "Neon", "Scarlet", "Obsidian", "Solar", "Frost"]
const ALIAS_B := ["Falcon", "Wraith", "Tempest", "Warden", "Comet", "Viper", "Sentinel", "Phantom", "Blaze", "Spark", "Jackal", "Nova"]


func life() -> Dictionary:
	var p := GameState.player
	if not p.has("life") or not (p["life"] is Dictionary):
		p["life"] = {"type": "human"}
	return p["life"]


func kind() -> String:
	return str(life().get("type", "human"))


func is_type(t: String) -> bool:
	return kind() == t


func handles(k: String) -> bool:
	return KINDS.has(k)


func _t() -> bool:
	return Careers._t()


func _done(icon: String, title_txt: String, text: String, effects: Dictionary = {}) -> void:
	Careers._done(icon, title_txt, text, effects)


func _info(icon: String, title_txt: String, text: String) -> void:
	EventEngine.push_info(icon, title_txt, text)


func _cost(v: float) -> int:
	return Actions._cost(int(v))


func title() -> String:
	var l := life()
	var g: String = GameState.player.get("gender", "male")
	match kind():
		"royal":
			if l.get("crowned", false):
				return "King" if g == "male" else ("Queen" if g == "female" else "Monarch")
			if l.get("consort", false):
				return "Prince Consort" if g == "male" else ("Queen Consort" if g == "female" else "Royal Consort")
			if int(l.get("line", 9)) == 1:
				return "Crown Prince" if g == "male" else ("Crown Princess" if g == "female" else "Heir to the Throne")
			return "Prince" if g == "male" else ("Princess" if g == "female" else "Royal Highness")
		"vampire": return "Vampire"
		"revenant": return "Revenant"
		"witch": return "Witch" if g != "male" else "Warlock"
		"super": return str(l.get("alias", "Masked Hero"))
		"pirate", "colonist", "traveler": return Expansion.life_title()
	return ""


# ================================================================ start & transform

func apply_start(opts: Dictionary) -> void:
	var p := GameState.player
	p["life"] = {"type": "human"}
	var path: String = opts.get("life_path", "human")
	if path != "human":
		GameState.counter("life_paths")
	match path:
		"royal":
			setup_royal(true)
			GameState.counter("life_royal")
		"vampire", "witch", "super":
			life()["destiny"] = path
			if path == "witch":
				var mom := GameState.first_of("mother")
				if mom != "":
					GameState.npcs[mom]["witch"] = true
					GameState.npcs[mom]["title"] = "Witch"
		"revenant":
			life()["destiny_rise"] = true
		"pirate", "colonist", "traveler":
			Expansion.setup_life(path, opts)
			GameState.counter("life_" + path)


func become(t: String, opts: Dictionary = {}) -> void:
	var p := GameState.player
	var old := life()
	var keep := {}
	if old.has("destiny_rise"):
		keep["destiny_rise"] = true
	match t:
		"vampire":
			p["life"] = {"type": "vampire", "thirst": 30, "turned": int(p["age"]), "kills": 0, "starve": 0, "fledglings": []}
			p["stats"]["health"] = 100.0
			GameState.change_stat("looks", 10)
			GameState.add_milestone(p["age"], "was turned into a vampire")
		"witch":
			p["life"] = {"type": "witch", "mana": 60, "spells": 0, "coven": [], "familiar": "", "exposure": 0, "potions": {}, "masterwork": {}}
			GameState.add_milestone(p["age"], "discovered they were a %s" % ("warlock" if p["gender"] == "male" else "witch"))
		"super":
			var pw: Array = POWERS.keys()
			pw.shuffle()
			p["life"] = {"type": "super", "powers": [pw[0], pw[1]], "side": opts.get("side", "hero"), "alias": "The %s %s" % [ALIAS_A[randi() % ALIAS_A.size()], ALIAS_B[randi() % ALIAS_B.size()]],
				"revealed": false, "suspicion": 0, "saves": 0, "heists": 0, "nemesis": "", "nemesis_wins": 0, "power": 20, "lair": false, "rep": 0}
			GameState.add_milestone(p["age"], "developed superpowers: %s and %s" % [POWERS[pw[0]]["name"].to_lower(), POWERS[pw[1]]["name"].to_lower()])
		"royal_consort":
			setup_royal(false)
			life()["consort"] = true
			life()["line"] = 99
			GameState.add_milestone(p["age"], "married into the royal family")
	life().merge(keep)
	GameState.counter("life_" + t)
	Fx.play({"vampire": "bite", "witch": "magic", "super": "power", "royal_consort": "crown"}.get(t, "twist"))
	transformed.emit(t)
	GameState.emit_changed()


func setup_royal(born: bool) -> void:
	var p := GameState.player
	var countries := {"uk": "the United Kingdom", "jp": "Japan"}
	p["life"] = {"type": "royal", "house": "House of " + str(p["last"]), "respect": 60, "line": 1, "crowned": false, "reign": 0, "decrees": 0, "consort": false, "realm": countries.get(p["country"], ContentDB.country(p["country"])["name"])}
	if not born:
		return
	var parents := [GameState.first_of("mother"), GameState.first_of("father")]
	var mid: String = parents[randi() % 2] if parents[0] != "" and parents[1] != "" else (parents[0] if parents[0] != "" else parents[1])
	if mid != "":
		var m: Dictionary = GameState.npcs[mid]
		m["royal"] = true
		m["monarch"] = true
		m["title"] = "King" if m["gender"] == "male" else "Queen"
		for other in parents:
			if other != "" and other != mid:
				GameState.npcs[other]["royal"] = true
				GameState.npcs[other]["title"] = "Prince Consort" if GameState.npcs[other]["gender"] == "male" else "Queen Consort"
	var sibs := GameState.npcs_with("sibling")
	sibs.sort_custom(func(a, b): return int(GameState.npcs[a]["age"]) > int(GameState.npcs[b]["age"]))
	var line := 1
	for sid in sibs:
		var s: Dictionary = GameState.npcs[sid]
		s["royal"] = true
		s["line"] = line
		s["title"] = "Prince" if s["gender"] == "male" else "Princess"
		line += 1
	life()["line"] = line
	p["fame"] = maxf(float(p.get("fame", 0)), 40.0)
	GameState.add_milestone(0, "was born %s of the %s" % ["heir to the throne" if line == 1 else "a royal", life()["house"]])


func on_continue(old: Dictionary) -> void:
	var ol: Dictionary = old.get("life", {"type": "human"})
	var p := GameState.player
	match str(ol.get("type", "human")):
		"royal":
			p["life"] = {"type": "royal", "house": ol.get("house", "House of " + str(p["last"])), "respect": int(ol.get("respect", 60)), "line": 1, "crowned": false, "reign": 0, "decrees": 0, "consort": false, "realm": ol.get("realm", "the realm")}
			p["fame"] = maxf(float(p.get("fame", 0)), 40.0)
			if ol.get("crowned", false):
				GameState.add_log("With my %s gone, the crown passes to me." % ("father" if old["gender"] == "male" else "mother"))
		"witch":
			if int(p["age"]) >= 13:
				become("witch")
			else:
				life()["destiny"] = "witch"
		"super":
			if randf() < 0.35:
				if int(p["age"]) >= 13:
					become("super", {"side": ol.get("side", "hero")})
				else:
					life()["destiny"] = "super"
		"pirate", "colonist", "traveler":
			LifeThreads.remember("family", "A strange family legacy", "The previous generation left behind stories from a life that did not fit ordinary history.", "", 58, [str(ol.get("type", ""))])


# ================================================================ yearly

func yearly() -> void:
	Undeath.yearly()
	Destiny.yearly()
	var p := GameState.player
	var l := life()
	var age: int = p["age"]
	if kind() != "human":
		GameState.counter("path_years")
	if l.has("destiny"):
		var d: String = l["destiny"]
		var at := 18 if d == "vampire" else 13
		if age >= at:
			l.erase("destiny")
			var tw: String = {"vampire": "tw.embrace", "witch": "tw.awakening", "super": "tw.manifest"}[d]
			Twists.fire(tw)
	match kind():
		"royal": _royal_yearly()
		"vampire": _vampire_yearly()
		"revenant": _revenant_yearly()
		"super": _super_yearly()
		"witch": _witch_yearly()
		"pirate", "colonist", "traveler": Expansion.life_yearly()


func ageless() -> bool:
	return is_type("vampire")


func no_healing() -> bool:
	return is_type("revenant")


## Returns "__natural" to run normal death checks, "" for no death, or a cause.
func death_check() -> String:
	var l := life()
	match kind():
		"vampire":
			if int(l.get("starve", 0)) >= 3:
				return "the Thirst"
			if GameState.stat("health") <= 0:
				return "a stake through the heart"
			return ""
		"revenant":
			if int(l.get("rot", 0)) >= 100:
				return "crumbling to dust"
			return ""
		"pirate", "colonist", "traveler":
			return Expansion.life_death_check()
	return "__natural"


func can_rise() -> bool:
	var p := GameState.player
	var l := life()
	if l.get("risen_before", false) or is_type("vampire") or is_type("revenant"):
		return false
	if l.get("destiny_rise", false):
		return true
	if not Grit.grudge_holders(60).is_empty():
		return true
	for cid in GameState.npcs_with("child"):
		if int(GameState.npcs[cid]["age"]) < 16:
			return true
	return int(p["karma"]) <= -50


func rise() -> void:
	var p := GameState.player
	var business := {"kind": "atone", "target": "", "goal": maxi(10, int(p["karma"]) + 40)}
	var holders := Grit.grudge_holders(60)
	var kids: Array = GameState.npcs_with("child").filter(func(c): return int(GameState.npcs[c]["age"]) < 16)
	if not holders.is_empty():
		holders.sort_custom(func(a, b): return int(GameState.npcs[a]["grudge"]) > int(GameState.npcs[b]["grudge"]))
		business = {"kind": "revenge", "target": holders[0]}
	elif not kids.is_empty():
		business = {"kind": "protect", "target": kids[0]}
	p["alive"] = true
	p["cause"] = ""
	p["stats"]["health"] = 60.0
	p["stats"]["happiness"] = 30.0
	p["stats"]["looks"] = minf(GameState.stat("looks"), 55.0)
	p["hospitalized"] = true
	p["life"] = {"type": "revenant", "rot": 10, "business": business, "risen": int(p["age"]), "done": false, "risen_before": true}
	if GameState.has_job():
		Actions.lose_job("died")
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if n["alive"] and n.get("species", "human") == "human" and n["relation"] in ["mother", "father", "sibling", "child", "partner", "friend", "best_friend"]:
			n["closeness"] = maxi(0, int(n["closeness"]) - 20)
	if p["partner"] != "" and GameState.npcs.has(p["partner"]) and randf() < 0.5:
		GameState.npcs[p["partner"]]["relation"] = "ex"
		p["partner"] = ""
		p["partner_status"] = ""
	GameState.log_years.append({"age": int(p["age"]), "lines": []})
	GameState.add_log("I clawed my way out of the grave. I have unfinished business.")
	GameState.add_milestone(p["age"], "rose from the dead")
	GameState.counter("life_revenant")
	var what := ""
	match business["kind"]:
		"revenge": what = "Revenge on %s, who never forgave you." % GameState.full_name(business["target"])
		"protect": what = "Protect %s until they're grown." % GameState.full_name(business["target"])
		_: what = "Atone for what you did. Reach %d karma." % int(business["goal"])
	EventEngine.push_info("🧟", "You rose from the grave", "The dirt was cold. The world was loud. You remember everything.\n\nUnfinished business: %s\n\nYour body is rotting. Settle it before there's nothing left of you." % what)
	GameState.emit_changed()


# ================================================================ ROYALTY

func royals() -> Array:
	var out: Array = []
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if n["alive"] and n.get("royal", false) and n.has("line") and not n.get("monarch", false):
			out.append(id)
	return out


func monarch() -> String:
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if n["alive"] and n.get("monarch", false):
			return id
	return ""


func _reline() -> void:
	var l := life()
	var entries: Array = []
	for id in royals():
		entries.append([id, int(GameState.npcs[id]["line"])])
	if not l.get("crowned", false) and not l.get("consort", false) and not l.get("abdicated", false):
		entries.append(["me", int(l["line"])])
	entries.sort_custom(func(a, b): return int(a[1]) < int(b[1]))
	for i in range(entries.size()):
		if entries[i][0] == "me":
			l["line"] = i + 1
		else:
			GameState.npcs[entries[i][0]]["line"] = i + 1


func _royal_yearly() -> void:
	var p := GameState.player
	var l := life()
	for sid in GameState.npcs_with("sibling"):
		var s: Dictionary = GameState.npcs[sid]
		if not s.get("royal", false) and not l.get("consort", false):
			s["royal"] = true
			s["line"] = 50
			s["title"] = "Prince" if s["gender"] == "male" else "Princess"
	if not l.get("consort", false):
		for cid in GameState.npcs_with("child"):
			var c: Dictionary = GameState.npcs[cid]
			if not c.get("royal", false):
				c["royal"] = true
				c["title"] = "Prince" if c["gender"] == "male" else "Princess"
	var r := float(l["respect"])
	r += float(p["karma"]) / 25.0 - 1.0
	r = lerpf(r, 50.0, 0.04)
	l["respect"] = clampf(r, 0.0, 100.0)
	p["fame"] = maxf(float(p.get("fame", 0)), 35.0 if int(p["age"]) >= 10 else float(p.get("fame", 0)))
	if int(p["age"]) >= 18:
		var allowance := _cost(1500000 if l.get("crowned", false) else 180000)
		p["money"] = int(p["money"]) + allowance
		p["last_income"] = int(p.get("last_income", 0))
		GameState.add_log("The Crown paid me an allowance of %s." % GameState.fmt_money(allowance))
	if l.get("crowned", false):
		l["reign"] = int(l["reign"]) + 1
		if int(l["reign"]) == 25:
			GameState.add_milestone(p["age"], "celebrated a silver jubilee")
		return
	if l.get("consort", false) or l.get("abdicated", false):
		return
	if monarch() == "":
		_reline()
		if int(l["line"]) == 1:
			_coronation()
		else:
			var heirs := royals()
			heirs.sort_custom(func(a, b): return int(GameState.npcs[a]["line"]) < int(GameState.npcs[b]["line"]))
			if not heirs.is_empty():
				var h: Dictionary = GameState.npcs[heirs[0]]
				h["monarch"] = true
				h["title"] = "King" if h["gender"] == "male" else "Queen"
				h.erase("line")
				_reline()
				GameState.add_log("My %s %s was crowned. I am now %s in line to the throne." % [GameState.relation_label(heirs[0]).to_lower().split(" (")[0], h["first"], _ordinal(int(l["line"]))])
	else:
		_reline()


func _ordinal(n: int) -> String:
	var suf := "th"
	if n % 100 < 11 or n % 100 > 13:
		match n % 10:
			1: suf = "st"
			2: suf = "nd"
			3: suf = "rd"
	return "%d%s" % [n, suf]


func _coronation() -> void:
	var p := GameState.player
	var l := life()
	Fx.play("crown")
	transformed.emit("crowned")
	l["crowned"] = true
	l["reign"] = 0
	l["respect"] = maxf(float(l["respect"]), 55.0)
	GameState.counter("coronations")
	GameState.add_milestone(p["age"], "was crowned %s of %s" % [title(), l.get("realm", "the realm")])
	EventEngine.push_info("👑", "Coronation", "The bells rang across the capital. Under the eyes of the whole nation, the crown was placed on my head.\n\nI am %s of %s." % [title(), l.get("realm", "the realm")], GameState.apply_effects({"fame": 30, "happiness": 20}))


func royal_actions() -> Array:
	var p := GameState.player
	var l := life()
	var out: Array = []
	var adult: bool = int(p["age"]) >= 16
	out.append({"id": "r_appear", "icon": "👋", "name": "Public appearance", "sub": "Respect · fame"})
	if adult:
		out.append({"id": "r_speech", "icon": "🎙️", "name": "Address the nation", "sub": "Minigame · big swing in Respect"})
		out.append({"id": "r_charity", "icon": "🎗️", "name": "Become patron of a charity", "sub": "%s · karma · Respect" % GameState.fmt_money(_cost(50000))})
		out.append({"id": "r_tour", "icon": "✈️", "name": "Royal tour abroad", "sub": "Paid by the Crown · Respect · happiness"})
		out.append({"id": "r_banquet", "icon": "🍽️", "name": "Host a banquet", "sub": "Everyone you know gets closer"})
		out.append({"id": "r_knight", "icon": "🗡️", "name": "Knight someone", "sub": "Honor a friend or family member", "pick": true})
		out.append({"id": "r_banish", "icon": "🚪", "name": "Banish someone", "sub": "Gone from court · they won't forget", "pick": true})
	if adult and not l.get("crowned", false) and not l.get("consort", false) and int(l["line"]) > 1:
		out.append({"id": "r_scheme", "icon": "🐍", "name": "Scheme against a sibling", "sub": "Move up the line of succession · risky"})
	if l.get("crowned", false):
		out.append({"id": "r_decree", "icon": "📜", "name": "Issue a decree", "sub": "Taxes, monuments, pardons, holidays"})
		out.append({"id": "r_abdicate", "icon": "🏳️", "name": "Abdicate", "sub": "Give up the throne"})
	return out


func royal_action(aid: String, arg = null) -> void:
	var p := GameState.player
	var l := life()
	match aid:
		"r_appear":
			if _t(): return
			var gain := randi_range(2, 7) + (3 if GameState.has_trait("Charmer") else 0)
			l["respect"] = minf(100.0, float(l["respect"]) + gain)
			_done("👋", "Public appearance", "I %s. The crowds waved flags." % ["opened a hospital wing", "visited a school", "cut a ribbon at a new bridge", "shook hands along a rope line for two hours", "attended a regatta"][randi() % 5], {"fame": 1, "happiness": 2})
		"r_speech":
			if _t(): return
			Minigames.play("debate", {"skill": GameState.stat("smarts") * 0.5 + float(l["respect"]) * 0.4, "difficulty": 1.0, "flavor": "royal"}, Callable(Careers, "resolve_play").bind({"kind": "royal_speech"}))
		"r_charity":
			var cost := _cost(50000)
			if int(p["money"]) < cost:
				_info("💸", "Charity", "Patronage costs %s." % GameState.fmt_money(cost))
				return
			if _t(): return
			p["money"] = int(p["money"]) - cost
			l["respect"] = minf(100.0, float(l["respect"]) + 6)
			_done("🎗️", "Royal patron", "I became patron of a %s charity." % ["children's hospital", "wildlife", "veterans'", "literacy", "homeless"][randi() % 5], {"karma": 6, "happiness": 4})
		"r_tour":
			if _t(): return
			l["respect"] = minf(100.0, float(l["respect"]) + 4)
			GameState.counter("vacations")
			_done("✈️", "Royal tour", "I toured %s. State dinners, parades and far too many handshakes." % ["the Commonwealth", "Southeast Asia", "South America", "West Africa", "Scandinavia"][randi() % 5], {"happiness": 8, "stress": -4, "fame": 2})
		"r_banquet":
			if _t(): return
			for id in GameState.npcs.keys():
				var n: Dictionary = GameState.npcs[id]
				if n["alive"] and n.get("species", "human") == "human" and int(n["closeness"]) >= 25:
					GameState.change_closeness(id, 8)
			_done("🍽️", "Banquet", "I hosted a banquet in the great hall. Seven courses, one international incident.", {"happiness": 6})
		"r_knight":
			var id: String = arg
			if _t(): return
			var n: Dictionary = GameState.npcs[id]
			n["title"] = "Sir" if n["gender"] == "male" else "Dame"
			GameState.change_closeness(id, 25)
			_done("🗡️", "Arise", "I knighted %s. %s cried on the steps of the palace." % [GameState.full_name(id), n["first"]], {"karma": 2})
		"r_banish":
			var bid: String = arg
			if _t(): return
			var b: Dictionary = GameState.npcs[bid]
			b["relation"] = "banished"
			Grit.grudge(bid, 90)
			l["respect"] = maxf(0.0, float(l["respect"]) - 4)
			_done("🚪", "Banished", "I banished %s from court and from the realm. The tabloids called it cruel." % GameState.full_name(bid), {"karma": -6})
		"r_scheme":
			if _t(): return
			var ahead: Array = royals().filter(func(x): return int(GameState.npcs[x].get("line", 99)) < int(l["line"]))
			if ahead.is_empty():
				_info("🐍", "Scheme", "Nobody stands between you and the throne except the monarch.")
				return
			ahead.sort_custom(func(a, b): return int(GameState.npcs[a]["line"]) > int(GameState.npcs[b]["line"]))
			var tid: String = ahead[0]
			var tn: Dictionary = GameState.npcs[tid]
			if randf() < 0.45 + GameState.stat("smarts") / 400.0:
				tn["line"] = 90
				_reline()
				GameState.counter("schemes")
				_done("🐍", "Disgraced", "I leaked a scandal about %s to the press. %s was pushed down the line of succession. I'm now %s in line." % [tn["first"], GameState.pron(tn["gender"], "he").capitalize(), _ordinal(int(l["line"]))], {"karma": -12})
				Grit.grudge(tid, 50)
			else:
				l["respect"] = maxf(0.0, float(l["respect"]) - 20)
				Grit.grudge(tid, 80)
				_done("🐍", "Exposed", "The scheme against %s was traced back to me. The whole country knows what I tried." % tn["first"], {"karma": -8, "fame": 5, "happiness": -10})
		"r_decree":
			if _t(): return
			var choices: Array = [
				{"label": "Lower taxes", "outcomes": [{"text": "I lowered taxes. The people cheered. The treasury didn't.", "royal": 10, "effects": {"money": -_cost(1000000)}}]},
				{"label": "Raise taxes for the Crown", "outcomes": [{"text": "I raised taxes. My coffers grew. So did the protests.", "royal": -14, "effects": {"money": _cost(3000000), "karma": -6}}]},
				{"label": "Build a monument", "outcomes": [{"text": "A grand monument now bears my name.", "royal": 8, "effects": {"money": -_cost(5000000), "fame": 4}, "milestone": "built a monument to their reign"}]},
				{"label": "Declare a national holiday", "outcomes": [{"text": "A new national holiday. Everyone loves a day off.", "royal": 6}]},
				{"label": "Pardon yourself", "outcomes": [{"text": "I pardoned myself. Legally questionable. Politically disastrous.", "clear_record": true, "royal": -15, "effects": {"heat": -40}}]},
				{"label": "Muzzle the press", "outcomes": [{"text": "Newspapers must now clear royal stories with the palace.", "royal": -8, "effects": {"karma": -8}, "flags": ["press_muzzled"]}]},
			]
			l["decrees"] = int(l["decrees"]) + 1
			EventEngine.push_decision({"id": "_decree", "icon": "📜", "title": "Royal decree", "text": "The ministers wait with their pens. What is your decree?", "choices": choices})
		"r_abdicate":
			l["crowned"] = false
			l["abdicated"] = true
			var heirs := royals()
			for cid in GameState.npcs_with("child"):
				heirs.push_front(cid)
			if not heirs.is_empty():
				var h: Dictionary = GameState.npcs[heirs[0]]
				h["monarch"] = true
				h["royal"] = true
				h["title"] = "King" if h["gender"] == "male" else "Queen"
			GameState.add_milestone(p["age"], "abdicated the throne")
			_done("🏳️", "Abdication", "I gave up the crown. For the first time in years, I slept through the night.", {"happiness": 10, "stress": -20, "fame": 5})


# ================================================================ VAMPIRE

func _vampire_yearly() -> void:
	var p := GameState.player
	var l := life()
	l["thirst"] = mini(100, int(l["thirst"]) + 22)
	p["stats"]["health"] = maxf(GameState.stat("health"), 70.0)
	if int(l["thirst"]) >= 100:
		l["starve"] = int(l.get("starve", 0)) + 1
		GameState.apply_effects({"health": -25, "happiness": -15})
		GameState.add_log("The Thirst is unbearable. My body is withering.")
		var left := 3 - int(l["starve"])
		if left > 0:
			EventEngine.push_info("🩸", "Starving", "I haven't fed in too long. My skin is paper and my hands shake. If I don't feed, I have %s left." % ("one more year" if left == 1 else "two years"))
	else:
		l["starve"] = 0
	if GameState.has_job():
		GameState.apply_effects({"job_perf": -8})
	if int(l["thirst"]) >= 80 and randf() < 0.35:
		EventEngine.push_decision({"id": "_frenzy", "icon": "🩸", "title": "Frenzy", "text": "The Thirst takes over. You're in a crowded street and you can hear every heartbeat.", "choices": [
			{"label": "Feed on the nearest stranger", "outcomes": [{"weight": 2, "text": "I fed in an alley. They'll wake up confused.", "thirst": -60, "effects": {"heat": 10, "karma": -5}}, {"weight": 1, "text": "I couldn't stop in time. They didn't wake up.", "thirst": -80, "effects": {"heat": 30, "karma": -20}, "counter": {"vamp_kills": 1}}]},
			{"label": "Run home and lock the door", "outcomes": [{"text": "I clawed at the inside of the door until dawn.", "effects": {"health": -15, "stress": 15}}]},
		]})
	var kills := GameState.get_counter("vamp_kills")
	if (kills >= 2 or float(p.get("heat", 0)) >= 45) and randf() < 0.12 + kills * 0.03:
		Twists.fire("tw.hunters")
	var age_now: int = p["age"]
	if age_now >= 150 and not GameState.has_flag("vamp_150"):
		GameState.set_flag("vamp_150")
		GameState.add_milestone(age_now, "passed their 150th birthday without aging a day")


func vampire_actions() -> Array:
	var l := life()
	var out: Array = [
		{"id": "v_hunt", "icon": "🌒", "name": "Hunt a stranger", "sub": "Minigame · thirst -60 · don't be seen"},
		{"id": "v_animal", "icon": "🐀", "name": "Feed on animals", "sub": "Thirst -25 · humiliating"},
		{"id": "v_bank", "icon": "🏥", "name": "Raid a blood bank", "sub": "Thirst -50 · needs a medical or underworld contact"},
		{"id": "v_loved", "icon": "💔", "name": "Feed on someone you know", "sub": "Thirst -70 · they'll never see you the same", "pick": true},
		{"id": "v_turn", "icon": "🧛", "name": "Turn someone", "sub": "Make them ageless, like you", "pick": true},
		{"id": "v_compel", "icon": "👁️", "name": "Compel someone", "sub": "Take their money or their heart", "pick": true},
		{"id": "v_coffin", "icon": "⚰️", "name": "Rest in your coffin", "sub": "Health · stress"},
	]
	if int(GameState.player["age"]) - int(l.get("turned", 0)) >= 50:
		out.append({"id": "v_sun", "icon": "🌅", "name": "Walk into the sunrise", "sub": "End it on your own terms"})
	return out


func vampire_action(aid: String, arg = null) -> void:
	var p := GameState.player
	var l := life()
	match aid:
		"v_hunt":
			if _t(): return
			Minigames.play("infiltrate", {"skill": 55, "difficulty": 0.9, "flavor": "hunt"}, Callable(Careers, "resolve_play").bind({"kind": "feed"}))
		"v_animal":
			if _t(): return
			l["thirst"] = maxi(0, int(l["thirst"]) - 25)
			_done("🐀", "Animal blood", "I fed on %s. It kept me going. It did not make me happy." % ["a stray dog", "a deer in the park", "a pair of rats", "a farmer's goat"][randi() % 4], {"happiness": -3})
		"v_bank":
			var contact := Web.contact(["doctor", "nurse"], 30)
			if contact == "" and Empires.bm_access() != "":
				_info("🏥", "Blood bank", "You need a doctor or nurse you know, or a way into the Black Market.")
				return
			if _t(): return
			l["thirst"] = maxi(0, int(l["thirst"]) - 50)
			if contact != "":
				GameState.change_closeness(contact, -8)
				_done("🏥", "Blood bags", "%s slipped me bags from the hospital fridge and asked no questions. Yet." % GameState.npc(contact)["first"], {"karma": -2})
			else:
				_done("🏥", "Blood bags", "A Black Market dealer sold me bags of blood out of a cooler.", {"money": -_cost(2000), "heat": 4})
		"v_loved":
			var id: String = arg
			if _t(): return
			var n: Dictionary = GameState.npcs[id]
			var starving: bool = int(l["thirst"]) >= 80
			l["thirst"] = maxi(0, int(l["thirst"]) - 70)
			GameState.change_closeness(id, -35)
			if starving and randf() < 0.12:
				n["alive"] = false
				GameState.counter("vamp_kills")
				GameState.add_milestone(p["age"], "killed %s while feeding" % n["first"])
				_done("🩸", "Too far", "I was too hungry. %s didn't survive it." % n["first"], {"karma": -30, "happiness": -25, "heat": 25})
			elif randf() < 0.2:
				n["vampire"] = true
				l["fledglings"].append(id)
				_done("🩸", "The change", "I fed on %s. Days later, %s eyes turned red. I made another one of us." % [n["first"], GameState.pron(n["gender"], "his")], {"karma": -8})
			else:
				_done("🩸", "Betrayal", "I fed on %s. %s screamed, then went quiet. %s knows what I am now." % [n["first"], GameState.pron(n["gender"], "he").capitalize(), GameState.pron(n["gender"], "he").capitalize()], {"karma": -10, "heat": 5})
		"v_turn":
			var tid: String = arg
			var tn: Dictionary = GameState.npcs[tid]
			if int(tn["closeness"]) < 55:
				_info("🧛", "Turn someone", "%s doesn't trust you enough to let you close." % tn["first"])
				return
			if _t(): return
			tn["vampire"] = true
			l["fledglings"].append(tid)
			GameState.set_flag("has_fledgling")
			GameState.change_closeness(tid, 15)
			GameState.counter("fledglings")
			var eternal: bool = tid == p["partner"]
			_done("🧛", "Eternity", "I turned %s.%s" % [tn["first"], " We'll never grow old. Not ever." if eternal else " %s will outlive everyone %s knows. Just like me." % [GameState.pron(tn["gender"], "he").capitalize(), GameState.pron(tn["gender"], "he")]], {"karma": -5, "happiness": 8})
		"v_compel":
			var cid: String = arg
			if _t(): return
			var cn: Dictionary = GameState.npcs[cid]
			if randf() < 0.15:
				Grit.grudge(cid, 50)
				_done("👁️", "Resisted", "%s shook off my gaze and backed away, horrified." % cn["first"], {"heat": 10})
				return
			var take := int(int(cn.get("money", 5000)) * 0.3)
			cn["money"] = int(cn.get("money", 0)) - take
			GameState.counter("compels")
			_done("👁️", "Compelled", "I looked into %s's eyes and told %s to give me %s. %s did, smiling." % [cn["first"], GameState.pron(cn["gender"], "him"), GameState.fmt_money(take), GameState.pron(cn["gender"], "he").capitalize()], {"money": take, "karma": -6})
		"v_coffin":
			if _t(): return
			_done("⚰️", "The coffin", "I slept a full day and night in my coffin, lid shut.", {"health": 15, "stress": -15})
		"v_sun":
			GameState.add_log("I watched one last sunrise.")
			EventEngine.kill("walking into the sunrise")


# ================================================================ REVENANT

func _revenant_yearly() -> void:
	var p := GameState.player
	var l := life()
	l["rot"] = int(l["rot"]) + 9 + (3 if Grit.key() == "gritty" else 0)
	p["stats"]["looks"] = minf(GameState.stat("looks"), maxf(0.0, 100.0 - float(l["rot"])))
	if int(l["rot"]) >= 70 and not GameState.has_flag("rot_warned"):
		GameState.set_flag("rot_warned")
		EventEngine.push_info("🦴", "Falling apart", "A finger came off this morning. There isn't much time left.")
	if not l.get("done", false) and _business_done():
		l["done"] = true
		GameState.counter("business_done")
		GameState.add_milestone(p["age"], "settled their unfinished business")
		EventEngine.push_decision({"id": "_rest", "icon": "🕊️", "title": "It's finished", "text": "Your unfinished business is settled. The pull of the grave is gentle now.", "choices": [
			{"label": "Rest in peace", "outcomes": [{"text": "I lay down and closed my eyes, for good this time.", "die": "peace at last"}]},
			{"label": "Stay a little longer", "outcomes": [{"text": "Not yet. There's still a sunrise or two I want to see.", "effects": {"happiness": 4}}]},
		]})


func _business_done() -> bool:
	var b: Dictionary = life().get("business", {})
	match str(b.get("kind", "")):
		"revenge":
			var t := GameState.npc(b["target"])
			return t.is_empty() or not t["alive"] or int(t.get("grudge", 0)) <= 0 or b.get("won", false)
		"protect":
			var c := GameState.npc(b["target"])
			return c.is_empty() or not c["alive"] or int(c["age"]) >= 18
		"atone":
			return int(GameState.player["karma"]) >= int(b.get("goal", 20))
	return false


func revenant_actions() -> Array:
	var l := life()
	var b: Dictionary = l.get("business", {})
	var out: Array = [{"id": "rev_preserve", "icon": "🧴", "name": "Embalm yourself", "sub": "%s · rot -20" % GameState.fmt_money(_cost(5000))}]
	match str(b.get("kind", "")):
		"revenge":
			out.append({"id": "rev_revenge", "icon": "⚔️", "name": "Confront %s" % GameState.npc(b["target"]).get("first", "them"), "sub": "Minigame · settle it"})
		"protect":
			out.append({"id": "rev_protect", "icon": "🛡️", "name": "Watch over %s" % GameState.npc(b["target"]).get("first", "them"), "sub": "From the shadows"})
		"atone":
			out.append({"id": "rev_atone", "icon": "🕯️", "name": "Atone", "sub": "Karma · %d / %d" % [int(GameState.player["karma"]), int(b.get("goal", 20))]})
	out.append({"id": "rev_haunt", "icon": "👻", "name": "Haunt someone", "sub": "Scare them senseless", "pick": true})
	if l.get("done", false):
		out.append({"id": "rev_rest", "icon": "🕊️", "name": "Rest in peace", "sub": "It's over"})
	return out


func revenant_action(aid: String, arg = null) -> void:
	var l := life()
	var b: Dictionary = l.get("business", {})
	match aid:
		"rev_preserve":
			var cost := _cost(5000)
			if int(GameState.player["money"]) < cost:
				_info("💸", "Embalming", "It costs %s." % GameState.fmt_money(cost))
				return
			if _t(): return
			GameState.player["money"] = int(GameState.player["money"]) - cost
			l["rot"] = maxi(0, int(l["rot"]) - 20)
			_done("🧴", "Preserved", "A nervous mortician embalmed me after hours. I smell like a museum.", {})
		"rev_revenge":
			if _t(): return
			var t := GameState.npc(b["target"])
			Minigames.play("fight", {"skill": 60, "difficulty": 0.9, "opponent": t.get("first", "Them")}, Callable(Careers, "resolve_play").bind({"kind": "revenge"}))
		"rev_protect":
			if _t(): return
			var cid: String = b["target"]
			GameState.change_closeness(cid, 10)
			_done("🛡️", "Guardian", "I watched over %s from the shadows. A bully found a very cold hand on his shoulder." % GameState.npc(cid)["first"], {"karma": 4, "happiness": 4})
		"rev_atone":
			if _t(): return
			_done("🕯️", "Atonement", "I %s, unseen." % ["left money on a struggling family's doorstep", "cleaned a graveyard all night", "pulled a drowning dog from the river", "returned everything I ever stole"][randi() % 4], {"karma": 9})
		"rev_haunt":
			var hid: String = arg
			if _t(): return
			var hn: Dictionary = GameState.npcs[hid]
			GameState.change_closeness(hid, -20)
			if b.get("kind", "") == "revenge" and b.get("target", "") == hid:
				hn["grudge"] = maxi(0, int(hn.get("grudge", 0)) - 30)
			_done("👻", "Haunting", "I stood at the foot of %s's bed at 3 a.m. %s hasn't slept since." % [hn["first"], GameState.pron(hn["gender"], "he").capitalize()], {"fame": 1, "karma": -2})
		"rev_rest":
			GameState.add_log("I lay down and closed my eyes, for good this time.")
			EventEngine.kill("peace at last")


# ================================================================ SUPER

func has_power(pw: String) -> bool:
	return is_type("super") and life().get("powers", []).has(pw)


func _super_yearly() -> void:
	var p := GameState.player
	var l := life()
	l["suspicion"] = maxi(0, int(l["suspicion"]) - (10 if l.get("lair", false) else 5))
	if has_power("healing"):
		GameState.apply_effects({"health": 8})
	if not l.get("revealed", false) and int(l["suspicion"]) >= 70:
		Twists.fire("tw.unmasked")
	if l.get("revealed", false):
		p["fame"] = maxf(float(p.get("fame", 0)), minf(100.0, float(l["rep"])))
	if l["nemesis"] == "" and int(l["saves"]) + int(l["heists"]) >= 5:
		var nid := GameState.create_npc("nemesis", {"age": int(p["age"]) + randi_range(-5, 10), "closeness": 0})
		var n: Dictionary = GameState.npcs[nid]
		n["title"] = "The %s %s" % [ALIAS_A[randi() % ALIAS_A.size()], ALIAS_B[randi() % ALIAS_B.size()]]
		n["grudge"] = 70
		l["nemesis"] = nid
		EventEngine.push_info("🦹", "A nemesis rises", "Someone new is making headlines: %s. They know about me, and they want me finished." % n["title"])
	elif l["nemesis"] != "" and GameState.npcs.has(l["nemesis"]) and GameState.npcs[l["nemesis"]]["alive"] and randf() < 0.25:
		var nm: String = GameState.npcs[l["nemesis"]]["title"]
		GameState.add_log("%s struck again, and left a message for me." % nm)
		GameState.apply_effects({"stress": 8})


func super_actions() -> Array:
	var l := life()
	var hero: bool = l.get("side", "hero") == "hero"
	var out: Array = []
	if hero:
		out.append({"id": "s_patrol", "icon": "🌃", "name": "Patrol the city", "sub": "Minigame · stop thugs · saves %d" % int(l["saves"])})
		out.append({"id": "s_rescue", "icon": "🚒", "name": "Answer a disaster call", "sub": "Save lives · your powers matter"})
	else:
		out.append({"id": "s_heist", "icon": "💰", "name": "Pull a heist", "sub": "Minigame · heists %d" % int(l["heists"])})
		out.append({"id": "s_ransom", "icon": "💣", "name": "Hold the city for ransom", "sub": "Huge money · huge heat"})
	if l["nemesis"] != "" and GameState.npcs.has(l["nemesis"]) and GameState.npcs[l["nemesis"]]["alive"]:
		out.append({"id": "s_nemesis", "icon": "⚔️", "name": "Face %s" % GameState.npcs[l["nemesis"]]["title"], "sub": "Minigame · %d/3 wins to end it" % int(l["nemesis_wins"])})
	out.append({"id": "s_train", "icon": "🏋️", "name": "Train your powers", "sub": "Power %d" % int(l["power"])})
	if not l.get("revealed", false):
		out.append({"id": "s_cover", "icon": "🕶️", "name": "Cover your tracks", "sub": "Suspicion %d%%" % int(l["suspicion"])})
		out.append({"id": "s_reveal", "icon": "📣", "name": "Reveal your identity", "sub": "Fame · danger to your family"})
	if not l.get("lair", false):
		out.append({"id": "s_lair", "icon": "🏰", "name": "Build a %s" % ("headquarters" if hero else "lair"), "sub": "%s · safer, faster training" % GameState.fmt_money(_cost(2000000))})
	out.append({"id": "s_side", "icon": "🔄", "name": "Become a %s" % ("villain" if hero else "hero"), "sub": "Switch sides"})
	out.append({"id": "s_sidekick", "icon": "🤝", "name": "Recruit a %s" % ("sidekick" if hero else "henchman"), "sub": "Someone you know", "pick": true})
	return out


func super_action(aid: String, arg = null) -> void:
	var p := GameState.player
	var l := life()
	var pw := float(l["power"])
	match aid:
		"s_patrol":
			if _t(): return
			Minigames.play("fight", {"skill": 40 + pw * 0.5, "difficulty": clampf(1.0 - pw / 250.0 - (0.15 if has_power("strength") else 0.0), 0.6, 1.3), "opponent": "Street thugs"}, Callable(Careers, "resolve_play").bind({"kind": "patrol"}))
		"s_rescue":
			if _t(): return
			var bonus := 0.2 if has_power("flight") or has_power("strength") or has_power("telekinesis") or has_power("speed") else 0.0
			var disaster: String = ["a burning apartment block", "a bus hanging off a bridge", "a collapsing stadium", "a flooded subway", "a runaway train"][randi() % 5]
			l["suspicion"] = int(l["suspicion"]) + 4
			if randf() < 0.55 + bonus + pw / 400.0:
				l["saves"] = int(l["saves"]) + 3
				l["rep"] = int(l["rep"]) + 6
				GameState.counter("saves", 3)
				_done("🚒", "Heroic rescue", "%s arrived at %s and pulled everyone out. The news called it a miracle." % [l["alias"], disaster], {"karma": 8, "happiness": 10})
			else:
				_done("🚒", "Too late", "I got to %s too late for some of them. I can't stop seeing their faces." % disaster, {"happiness": -12, "health": -10})
				Grit.scar_chance("haunted", 0.3)
		"s_heist":
			if _t(): return
			Minigames.play("safecrack", {"skill": 40 + pw * 0.5, "difficulty": clampf(1.1 - (0.25 if has_power("telekinesis") else 0.0) - pw / 300.0, 0.6, 1.4)}, Callable(Careers, "resolve_play").bind({"kind": "heist"}))
		"s_ransom":
			if _t(): return
			var take := _cost(randi_range(2, 10) * 1000000)
			l["heists"] = int(l["heists"]) + 1
			l["rep"] = int(l["rep"]) + 12
			if randf() < 0.3:
				p["record"].append("extortion")
				_done("💣", "Stopped", "%s held the city hostage, until the military got involved." % l["alias"], {"heat": 40})
				Law.trial("extortion", 5, 20)
			else:
				GameState.counter("heists")
				_done("💣", "Ransom paid", "%s held the power grid hostage. The city paid %s to turn the lights back on." % [l["alias"], GameState.fmt_money(take)], {"money": take, "heat": 40 if not has_power("invisibility") else 20, "karma": -20, "fame": 5})
		"s_nemesis":
			if _t(): return
			Minigames.play("fight", {"skill": 45 + pw * 0.5, "difficulty": 1.15, "opponent": GameState.npcs[l["nemesis"]]["title"]}, Callable(Careers, "resolve_play").bind({"kind": "nemesis"}))
		"s_train":
			if _t(): return
			l["power"] = mini(100, int(l["power"]) + (12 if l.get("lair", false) else 8))
			_done("🏋️", "Training", "I pushed my %s to the limit. Power %d." % [POWERS[l["powers"][randi() % l["powers"].size()]]["name"].to_lower(), int(l["power"])], {"health": 2, "stress": 3})
		"s_cover":
			if _t(): return
			l["suspicion"] = maxi(0, int(l["suspicion"]) - 18)
			_done("🕶️", "Alibi", "I built an airtight alibi and made sure I was seen in public while %s was spotted across town." % l["alias"], {})
		"s_reveal":
			l["revealed"] = true
			p["fame"] = minf(100.0, maxf(float(p.get("fame", 0)), float(l["rep"]) + 30.0))
			GameState.set_flag("family_targeted")
			GameState.add_milestone(p["age"], "revealed that they are %s" % l["alias"])
			_done("📣", "Unmasked", "I stepped up to the microphones and took off the mask. \"I am %s.\"" % l["alias"], {"happiness": 8, "stress": 10})
		"s_lair":
			var cost := _cost(2000000)
			if int(p["money"]) < cost:
				_info("💸", "Too expensive", "It costs %s." % GameState.fmt_money(cost))
				return
			p["money"] = int(p["money"]) - cost
			l["lair"] = true
			_done("🏰", "Base of operations", "I built a secret %s under an abandoned factory." % ("headquarters" if l["side"] == "hero" else "lair"), {"happiness": 6})
		"s_side":
			l["side"] = "villain" if l["side"] == "hero" else "hero"
			GameState.add_milestone(p["age"], "became a %s" % l["side"])
			_done("🔄", "Changed sides", "%s is a %s now." % [l["alias"], l["side"]], {"karma": -10 if l["side"] == "villain" else 5})
		"s_sidekick":
			var sid: String = arg
			if _t(): return
			var sn: Dictionary = GameState.npcs[sid]
			sn["title"] = "Sidekick" if l["side"] == "hero" else "Henchman"
			GameState.change_closeness(sid, 15)
			_done("🤝", "Partner in %s" % ("justice" if l["side"] == "hero" else "crime"), "%s is now my %s." % [GameState.full_name(sid), str(sn["title"]).to_lower()], {})


# ================================================================ WITCH

func _witch_yearly() -> void:
	var l := life()
	var regen: int = 30 + l.get("coven", []).size() * 5 + (10 if l.get("familiar", "") != "" else 0)
	l["mana"] = mini(100, int(l["mana"]) + regen)
	l["exposure"] = maxi(0, int(l["exposure"]) - 5)
	if int(l["exposure"]) >= 60 and randf() < 0.4:
		Twists.fire("tw.witch_hunt")


func witch_actions() -> Array:
	var l := life()
	var out: Array = [
		{"id": "w_love", "icon": "💘", "name": "Love spell", "sub": "20 mana · win someone's heart", "pick": true, "mana": 20},
		{"id": "w_curse", "icon": "🪄", "name": "Curse", "sub": "30 mana · ruin someone · karma", "pick": true, "mana": 30},
		{"id": "w_heal", "icon": "💚", "name": "Healing spell", "sub": "25 mana · cure illness · health", "mana": 25},
		{"id": "w_fortune", "icon": "🪙", "name": "Fortune spell", "sub": "30 mana · money, maybe", "mana": 30},
		{"id": "w_glamour", "icon": "✨", "name": "Glamour", "sub": "15 mana · looks", "mana": 15},
		{"id": "w_luck", "icon": "🍀", "name": "Luck charm", "sub": "25 mana · your next Turning Point leans your way", "mana": 25},
		{"id": "w_truth", "icon": "⚖️", "name": "Truth spell", "sub": "20 mana · your next trial goes better", "mana": 20},
		{"id": "w_brew", "icon": "⚗️", "name": "Brew potions", "sub": "Minigame · %d in stock · %d recipes known" % [potion_total(), known_recipes().size()]},
	]
	var pot := potions()
	if potion_total() > 0:
		out.append({"id": "w_sell", "icon": "🛒", "name": "Sell your potions", "sub": "About %s · exposure" % GameState.fmt_money(_stock_value())})
	for rid in POTIONS.keys():
		if int(pot.get(rid, 0)) <= 0:
			continue
		var mw := int(l.get("masterwork", {}).get(rid, 0))
		var tag := " · %d masterwork" % mw if mw > 0 else ""
		if rid == "hex":
			out.append({"id": "w_hexbottle", "icon": POTIONS[rid][0], "name": "Uncork a %s" % POTIONS[rid][1], "sub": "×%d%s · on someone · karma" % [int(pot[rid]), tag], "pick": true})
		elif rid == "love":
			out.append({"id": "w_philter", "icon": POTIONS[rid][0], "name": "Slip someone a %s" % POTIONS[rid][1], "sub": "×%d%s · they fall for you" % [int(pot[rid]), tag], "pick": true})
		else:
			out.append({"id": "w_drink", "arg": rid, "icon": POTIONS[rid][0], "name": "Drink a %s" % POTIONS[rid][1], "sub": "×%d%s · %s" % [int(pot[rid]), tag, POTIONS[rid][3]]})
	if l.get("familiar", "") == "":
		out.append({"id": "w_familiar", "icon": "🐈‍⬛", "name": "Bind a familiar", "sub": "One of your pets · +10 mana a year", "pick": true})
	out.append({"id": "w_coven", "icon": "🌙", "name": "Invite someone to your coven", "sub": "Coven of %d · +5 mana a year each" % l.get("coven", []).size(), "pick": true})
	return out


const POTIONS := {
	"healing": ["💚", "Healing Draught", 1200, "health"],
	"glamour": ["💄", "Glamour Tonic", 1500, "looks"],
	"insight": ["🔮", "Insight Elixir", 2000, "smarts"],
	"fortune": ["🪙", "Fortune Brew", 3000, "luck and money"],
	"love": ["💘", "Love Philter", 2500, "romance"],
	"hex": ["☠️", "Hex in a Bottle", 4000, "ruin"],
	"mystery": ["❓", "Mystery Brew", 900, "who knows"],
}


func potions() -> Dictionary:
	var l := life()
	var v = l.get("potions", {})
	if not (v is Dictionary):
		v = {"healing": int(v)} if int(v) > 0 else {}
		l["potions"] = v
	if not l.has("masterwork"):
		l["masterwork"] = {}
	return v


func potion_total() -> int:
	var n := 0
	for v in potions().values():
		n += int(v)
	return n


func known_recipes() -> Array:
	var out: Array = ["healing", "glamour"]
	for r in Meta.meta.get("grimoire", {}).get("recipes", {}).keys():
		if not r in out:
			out.append(r)
	return out


func _stock_value() -> int:
	var l := life()
	var total := 0.0
	for rid in potions().keys():
		var n := int(potions()[rid])
		var mw := mini(n, int(l["masterwork"].get(rid, 0)))
		total += float(POTIONS.get(rid, POTIONS["mystery"])[2]) * (n + mw * 1.5)
	return _cost(total)


func _take_potion(rid: String) -> bool:
	var l := life()
	var pot := potions()
	pot[rid] = maxi(0, int(pot.get(rid, 0)) - 1)
	var mw := int(l["masterwork"].get(rid, 0))
	if pot[rid] == 0:
		pot.erase(rid)
	if mw > 0:
		l["masterwork"][rid] = mw - 1
		return true
	return false


func _spend(l: Dictionary, cost: int) -> bool:
	if int(l["mana"]) < cost:
		_info("🌙", "Not enough mana", "That spell needs %d mana. You have %d. Mana returns every year." % [cost, int(l["mana"])])
		return false
	if _t(): return false
	l["mana"] = int(l["mana"]) - cost
	l["spells"] = int(l["spells"]) + 1
	Fx.play("magic")
	GameState.counter("spells")
	return true


func witch_action(aid: String, arg = null) -> void:
	var p := GameState.player
	var l := life()
	match aid:
		"w_love":
			var id: String = arg
			if not _spend(l, 20): return
			var n: Dictionary = GameState.npcs[id]
			l["exposure"] = int(l["exposure"]) + 6
			if randf() < 0.15:
				n["grudge"] = 45
				GameState.change_closeness(id, 40)
				_done("💘", "Too well", "The spell worked too well. %s follows me everywhere and cries when I leave the room." % n["first"], {"stress": 10})
			else:
				GameState.change_closeness(id, 40)
				if p["partner"] == "" and int(n["age"]) >= 18 and int(p["age"]) >= 18 and n["relation"] not in ["mother", "father", "sibling", "child", "grandparent", "auntuncle"]:
					Actions.start_dating(id, false)
					_done("💘", "Enchanted", "I slipped a sprig of something into %s's tea. By evening we were holding hands." % n["first"], {"happiness": 8, "karma": -3})
				else:
					_done("💘", "Enchanted", "%s adores me now, and has no idea why." % n["first"], {"happiness": 4, "karma": -2})
		"w_curse":
			var cid: String = arg
			if not _spend(l, 30): return
			var cn: Dictionary = GameState.npcs[cid]
			l["exposure"] = int(l["exposure"]) + 10
			if randf() < 0.15:
				_done("🪄", "Rebound", "The curse bounced back on me. My hair fell out in clumps.", {"health": -15, "looks": -10})
				return
			GameState.counter("curses")
			if int(cn["age"]) >= 65 and randf() < 0.25:
				cn["alive"] = false
				_done("🪄", "The curse took", "%s fell ill the day I cursed %s, and never recovered." % [cn["first"], GameState.pron(cn["gender"], "him")], {"karma": -30})
			else:
				cn["money"] = int(int(cn.get("money", 0)) * 0.5)
				cn["grudge"] = maxi(0, int(cn.get("grudge", 0)) - 40)
				_done("🪄", "Cursed", "Nothing has gone right for %s since I cursed %s. Car, job, marriage, all of it." % [cn["first"], GameState.pron(cn["gender"], "him")], {"karma": -12})
		"w_heal":
			if not _spend(l, 25): return
			var what: String = p["illness"]
			p["illness"] = ""
			_done("💚", "Healing", ("The %s melted away under my hands." % what) if what != "" else "I felt years of aches lift out of my body.", {"health": 20})
		"w_fortune":
			if not _spend(l, 30): return
			if randf() < 0.6:
				var win := _cost(randi_range(20000, 200000))
				_done("🪙", "Fortune", "Money found its way to me: %s from a forgotten account, a lucky ticket, a stranger's mistake." % GameState.fmt_money(win), {"money": win})
			else:
				var lose := int(maxi(0, int(p["money"])) * 0.1)
				_done("🪙", "The price", "Magic always takes a price. I lost %s." % GameState.fmt_money(lose), {"money": -lose})
		"w_glamour":
			if not _spend(l, 15): return
			_done("✨", "Glamour", "A little glamour. Heads turn when I walk in.", {"looks": 15})
		"w_luck":
			if not _spend(l, 25): return
			GameState.set_flag("luck_spell")
			_done("🍀", "Luck charm", "I stitched a charm into my coat lining. Fate owes me one.", {})
		"w_truth":
			if not _spend(l, 20): return
			GameState.set_flag("truth_spell")
			_done("⚖️", "Truth spell", "Anyone who testifies against me will find the truth in their mouth.", {})
		"w_brew":
			if _t(): return
			Minigames.play("potion", {"skill": 45 + int(l["spells"]), "difficulty": 1.0}, Callable(Careers, "resolve_play").bind({"kind": "brew"}))
		"w_sell":
			var n2 := potion_total()
			var cash := _stock_value()
			var hexes := int(potions().get("hex", 0))
			l["potions"] = {}
			l["masterwork"] = {}
			l["exposure"] = int(l["exposure"]) + n2 * 3 + hexes * 6
			GameState.counter("potions_sold", n2)
			var who := "a hollow-eyed buyer who paid in cash and didn't blink at the hexes" if hexes > 0 else "the night market"
			_done("🛒", "Potion stall", "I sold %d potion%s to %s for %s. Don't ask what's in them." % [n2, "" if n2 == 1 else "s", who, GameState.fmt_money(cash)], {"money": cash})
		"w_drink":
			var rid: String = str(arg) if arg != null else ""
			if int(potions().get(rid, 0)) <= 0:
				return
			var mw := _take_potion(rid)
			var m := 2.0 if mw else 1.0
			var nm: String = POTIONS[rid][1]
			GameState.counter("potions_drunk")
			match rid:
				"healing":
					var ill: String = p.get("illness", "")
					if mw and ill != "":
						p["illness"] = ""
					_done("💚", nm, "Warm, green and faintly minty. My body stopped aching." + (" The %s is gone." % ill if mw and ill != "" else ""), {"health": 12 * m})
				"glamour":
					_done("💄", nm, "People keep looking at me twice. I let them.", {"looks": 8 * m})
				"insight":
					_done("🔮", nm, "For a few hours I could see how everything connects.", {"smarts": 6 * m, "stress": -4})
				"fortune":
					if randf() < 0.55 + 0.25 * (m - 1.0):
						var win := _cost(randi_range(3000, 40000) * m)
						_done("🪙", nm, "The next day a check arrived for %s. An insurance refund I'd never claimed." % GameState.fmt_money(win), {"money": win})
					else:
						GameState.set_flag("luck_spell")
						_done("🪙", nm, "Nothing happened. Yet. The luck is waiting for the right moment.", {})
				"mystery":
					var roll := randi() % 6
					var fx: Dictionary = [{"health": 15}, {"looks": 12}, {"smarts": 10}, {"happiness": 15, "stress": -12}, {"health": -12}, {"looks": -8, "happiness": 6}][roll]
					var txt: String = ["I felt twenty again.", "My skin glowed for a week.", "I finished the crossword in ink. In French.", "I laughed until I cried. At nothing.", "I spent the night on the bathroom floor.", "My hair turned green. It's kind of working for me."][roll]
					_done("❓", nm, "I drank the mystery brew. " + txt, fx)
		"w_philter":
			var lid: String = arg
			if int(potions().get("love", 0)) <= 0 or not GameState.npcs.has(lid):
				return
			var mw := _take_potion("love")
			var ln: Dictionary = GameState.npcs[lid]
			l["exposure"] = int(l["exposure"]) + 4
			GameState.counter("love_philters")
			if randf() < (0.9 if mw else 0.7):
				ln["closeness"] = mini(100, int(ln["closeness"]) + (40 if mw else 25))
				ln["charmed"] = true
				_done("💘", "Love Philter", "%s drank it without noticing. By dessert %s couldn't stop looking at me." % [ln["first"], GameState.pron(ln["gender"], "he")], {"karma": -6})
			else:
				ln["closeness"] = maxi(0, int(ln["closeness"]) - 20)
				ln["grudge"] = int(ln.get("grudge", 0)) + 20
				_done("💘", "Wrong glass", "%s tasted something off and pushed the glass away. %s's been looking at me strangely ever since." % [ln["first"], GameState.pron(ln["gender"], "he").capitalize()], {"stress": 6})
		"w_hexbottle":
			var hid: String = arg
			if int(potions().get("hex", 0)) <= 0 or not GameState.npcs.has(hid):
				return
			var mw := _take_potion("hex")
			var hn: Dictionary = GameState.npcs[hid]
			l["exposure"] = int(l["exposure"]) + 8
			GameState.counter("curses")
			hn["money"] = int(int(hn.get("money", 0)) * (0.3 if mw else 0.6))
			hn["closeness"] = maxi(0, int(hn["closeness"]) - 15)
			if mw and int(hn["age"]) >= 55 and randf() < 0.3:
				hn["alive"] = false
				_done("☠️", "The hex took", "I uncorked it outside %s's window. The smoke found %s. The funeral was on a Tuesday." % [hn["first"], GameState.pron(hn["gender"], "him")], {"karma": -30})
			else:
				_done("☠️", "Hexed", "Black smoke curled under %s's door. Since then: a flooded basement, a lost job, a dog that won't stop howling." % hn["first"], {"karma": -10})
		"w_familiar":
			var fid: String = arg
			var fn: Dictionary = GameState.npcs[fid]
			fn["familiar"] = true
			fn["title"] = "Familiar"
			l["familiar"] = fid
			_done("🐈‍⬛", "Bound", "%s looked at me with ancient eyes as the binding took. %s is my familiar now." % [fn["first"], fn["first"]], {"happiness": 6})
		"w_coven":
			var wid: String = arg
			if _t(): return
			var wn: Dictionary = GameState.npcs[wid]
			if randf() < clampf(int(wn["closeness"]) / 110.0, 0.1, 0.85):
				wn["witch"] = true
				wn["title"] = "Coven sister" if wn["gender"] != "male" else "Coven brother"
				l["coven"].append(wid)
				GameState.change_closeness(wid, 15)
				_done("🌙", "The coven grows", "Under the full moon, %s swore the old oath." % wn["first"], {"happiness": 6})
			else:
				l["exposure"] = int(l["exposure"]) + 15
				_done("🌙", "Refused", "%s laughed, then realized I wasn't joking, then stopped laughing." % wn["first"], {"stress": 6})


# ================================================================ panels support

func actions() -> Array:
	match kind():
		"royal": return royal_actions()
		"vampire":
			var v := vampire_actions()
			v.append_array(Undeath.vampire_extra_actions())
			return v
		"revenant":
			var r := revenant_actions()
			r.append_array(Undeath.revenant_extra_actions())
			return r
		"super": return super_actions()
		"witch": return witch_actions()
		"pirate", "colonist", "traveler": return Expansion.life_actions()
	return []


func act(aid: String, arg = null) -> void:
	var p := GameState.player
	var tl0 := int(p["time_left"])
	Careers.rep_begin("l_" + aid, 2, {"stress": 4})
	_act(aid, arg)
	if int(p["time_left"]) == tl0 and p.has("act_year"):
		p["act_year"]["l_" + aid] = maxi(0, int(p["act_year"].get("l_" + aid, 1)) - 1)
	Careers.rep_end()


func _act(aid: String, arg = null) -> void:
	if aid.begins_with("vx_") and Undeath.vampire_extra(aid, arg):
		return
	if aid.begins_with("rx_") and Undeath.revenant_extra(aid, arg):
		return
	match kind():
		"royal": royal_action(aid, arg)
		"vampire": vampire_action(aid, arg)
		"revenant": revenant_action(aid, arg)
		"super": super_action(aid, arg)
		"witch": witch_action(aid, arg)
		"pirate", "colonist", "traveler": Expansion.life_action(aid, arg)


func pick_targets(aid: String) -> Array:
	var out: Array = []
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"] or n["relation"] in ["banished", "zoo_animal"]:
			continue
		var human: bool = n.get("species", "human") == "human"
		match aid:
			"w_familiar":
				if n["relation"] == "pet" and human == false:
					out.append(id)
				continue
		if not human or int(n["age"]) < 6:
			continue
		if aid in ["v_turn", "v_loved", "w_coven", "s_sidekick", "r_knight", "w_philter", "w_love"] and int(n["age"]) < 18:
			continue
		if aid in ["w_philter", "w_love"] and n["relation"] in ["mother", "father", "sibling", "child", "grandparent", "grandchild", "stepparent", "stepsibling", "cousin", "aunt", "uncle", "niece", "nephew", "bio_parent"]:
			continue
		if aid == "v_turn" and n.get("vampire", false):
			continue
		if aid == "w_coven" and n.get("witch", false):
			continue
		out.append(id)
	out.sort_custom(func(a, b): return int(GameState.npcs[a]["closeness"]) > int(GameState.npcs[b]["closeness"]))
	return out.slice(0, 14)


func _resolve_brew(score: float, detail: Dictionary, grade: String) -> void:
	var l := life()
	var pot := potions()
	var rid: String = str(detail.get("recipe", ""))
	var variant: String = str(detail.get("variant", ""))
	var n := int(detail.get("bottled", 0))
	var found := ""
	if detail.get("auto", false):
		var known := known_recipes()
		var unknown: Array = POTIONS.keys().filter(func(r): return r != "mystery" and not known.has(r))
		known.erase("hex")
		rid = known[randi() % known.size()]
		if score >= 0.7 and not unknown.is_empty() and randf() < 0.35:
			found = unknown[randi() % unknown.size()]
			rid = found
			var gr: Dictionary = Meta.meta.get("grimoire", {"known": {}, "recipes": {}})
			gr["recipes"][found] = true
			Meta.meta["grimoire"] = gr
			Meta.save()
		n = clampi(int(round(score * 3.2)), 0, 3)
		variant = "explosion" if score < 0.15 else ("weak" if score < 0.35 else ("masterwork" if score >= 0.93 else ""))
	var nm: String = POTIONS.get(rid, POTIONS["mystery"])[1]
	var before := potion_total()
	if found != "":
		grade = grade + ". Experimenting, I stumbled onto a new recipe for the grimoire: " + nm
	GameState.counter("brews")
	match variant:
		"explosion":
			l["exposure"] = int(l["exposure"]) + 8
			_done("💥", "Kaboom", "Brewing: %s. The cauldron went up like a firework. The neighbors definitely noticed." % grade + Grit.scar_chance("burns", 0.08), {"health": -8, "looks": -4})
		"sludge":
			_done("🫗", "Grey sludge", "Brewing: %s. Whatever I made, it's the color of wet cement and it hissed at me. Down the drain. At least I learned what those ingredients do." % grade, {"stress": 3})
		"strange":
			pot["mystery"] = int(pot.get("mystery", 0)) + 1
			_done("❓", "Something... else", "Brewing: %s. It isn't any recipe I know. It shimmers and smells like thunder. I bottled it anyway." % grade, {})
		"weak":
			var w := maxi(1, n / 2)
			pot[rid] = int(pot.get(rid, 0)) + w
			_done("⚗️", "Cloudy batch", "Brewing: %s. The %s came out thin and cloudy. I saved %d bottle%s." % [grade, nm, w, "" if w == 1 else "s"], {})
		"masterwork":
			n = maxi(n, 2)
			pot[rid] = int(pot.get(rid, 0)) + n
			l["masterwork"][rid] = int(l["masterwork"].get(rid, 0)) + n
			l["mana"] = mini(100, int(l["mana"]) + 5)
			GameState.counter("masterworks")
			_done("🌟", "Masterwork", "Brewing: %s. The %s turned the exact color the old books describe. %d perfect bottles." % [grade, nm, n], {"happiness": 6})
		_:
			if n <= 0:
				_done("⚗️", "Spilled", "Brewing: %s. A decent %s, and then I knocked most of it over bottling it." % [grade, nm], {})
			else:
				pot[rid] = int(pot.get(rid, 0)) + n
				_done("⚗️", "Brewing", "Brewing: %s. %d bottle%s of %s." % [grade, n, "" if n == 1 else "s", nm], {})
	GameState.counter("potions_brewed", maxi(0, potion_total() - before))


func status_lines() -> Array:
	var l := life()
	var out: Array = []
	match kind():
		"royal":
			out.append(["👑 " + title() + " · " + str(l.get("house", "")), ""])
			out.append(["Respect", float(l["respect"])])
			if l.get("crowned", false):
				out.append(["Reign: %d year%s · %d decrees" % [int(l["reign"]), "" if int(l["reign"]) == 1 else "s", int(l["decrees"])], ""])
			elif not l.get("consort", false) and not l.get("abdicated", false):
				out.append(["%s in line to the throne of %s" % [_ordinal(int(l["line"])), l.get("realm", "the realm")], ""])
		"vampire":
			out.append(["🧛 Turned at %d · looks %d forever" % [int(l["turned"]), int(l["turned"])], ""])
			out.append(["Thirst", float(l["thirst"])])
			out.append(["%d fledgling%s · %d kill%s" % [l["fledglings"].size(), "" if l["fledglings"].size() == 1 else "s", GameState.get_counter("vamp_kills"), "" if GameState.get_counter("vamp_kills") == 1 else "s"], ""])
		"revenant":
			var b: Dictionary = l.get("business", {})
			out.append(["🧟 Risen at %d" % int(l["risen"]), ""])
			out.append(["Rot", float(l["rot"])])
			var what := "Atone (%d / %d karma)" % [int(GameState.player["karma"]), int(b.get("goal", 20))]
			if b.get("kind", "") == "revenge":
				what = "Revenge on " + GameState.full_name(b["target"])
			elif b.get("kind", "") == "protect":
				what = "Protect " + GameState.full_name(b["target"])
			out.append(["Unfinished business: " + what + (" ✓" if l.get("done", false) else ""), ""])
		"super":
			out.append(["%s %s · %s" % ["🦸" if l["side"] == "hero" else "🦹", l["alias"], "Hero" if l["side"] == "hero" else "Villain"], ""])
			out.append(["Powers: " + ", ".join(l["powers"].map(func(x): return POWERS[x]["icon"] + " " + POWERS[x]["name"])), ""])
			out.append(["Power", float(l["power"])])
			if not l.get("revealed", false):
				out.append(["Suspicion", float(l["suspicion"])])
			out.append(["%d saves · %d heists · reputation %d" % [int(l["saves"]), int(l["heists"]), int(l["rep"])], ""])
		"witch":
			out.append(["🧙 Coven of %d%s" % [l["coven"].size(), (" · familiar: " + GameState.npc(l["familiar"]).get("first", "")) if l.get("familiar", "") != "" else ""], ""])
			out.append(["Mana", float(l["mana"])])
			out.append(["Exposure", float(l["exposure"])])
			out.append(["%d spells cast · %d potions" % [int(l["spells"]), potion_total()], ""])
		"pirate", "colonist", "traveler":
			out.append_array(Expansion.life_status())
	out.append_array(Undeath.status_lines())
	return out


# ================================================================ outcomes & minigames

func outcome(o: Dictionary, roles: Dictionary) -> void:
	if o.has("undeath"):
		Undeath.outcome(o["undeath"])
	if o.has("destiny"):
		Destiny.outcome(o["destiny"])
	var l := life()
	if o.has("life"):
		var what: String = o["life"]
		match what:
			"vampire", "witch", "royal_consort":
				become(what)
			"hero", "villain":
				become("super", {"side": what})
			"end_royal":
				GameState.player["life"] = {"type": "human", "exroyal": true}
				GameState.add_milestone(GameState.player["age"], "lost their royal title")
			"cure_vampire":
				GameState.player["life"] = {"type": "human", "cured": true}
				GameState.add_milestone(GameState.player["age"], "was cured of vampirism")
			"reveal":
				if is_type("super"):
					l["revealed"] = true
	l = life()
	if o.has("royal") and is_type("royal"):
		l["respect"] = clampf(float(l["respect"]) + float(o["royal"]), 0.0, 100.0)
	if o.has("thirst") and is_type("vampire"):
		l["thirst"] = clampi(int(l["thirst"]) + int(o["thirst"]), 0, 100)
	if o.has("rot") and is_type("revenant"):
		l["rot"] = maxi(0, int(l["rot"]) + int(o["rot"]))
	if o.has("mana") and is_type("witch"):
		l["mana"] = clampi(int(l["mana"]) + int(o["mana"]), 0, 100)
	if o.has("exposure") and is_type("witch"):
		l["exposure"] = maxi(0, int(l["exposure"]) + int(o["exposure"]))
	if o.has("suspicion") and is_type("super"):
		l["suspicion"] = maxi(0, int(l["suspicion"]) + int(o["suspicion"]))
	if o.has("rep") and is_type("super"):
		l["rep"] = int(l["rep"]) + int(o["rep"])


func resolve(k: String, score: float, detail: Dictionary, _pl: Dictionary) -> void:
	var p := GameState.player
	var l := life()
	var grade := Minigames.grade(score)
	match k:
		"royal_speech":
			var d := score * 26.0 - 9.0
			l["respect"] = clampf(float(l.get("respect", 50)) + d, 0.0, 100.0)
			var txt := "Speech: %s. " % grade
			if score >= 0.8:
				txt += "The nation stood still. People quoted it for weeks."
			elif score >= 0.45:
				txt += "A dignified address. The commentators approved."
			else:
				txt += "I stumbled over the words on live TV. The clip is everywhere."
			_done("🎙️", "Royal address", txt + " Respect %d." % int(l["respect"]), {"fame": 2})
		"feed":
			var ok: bool = detail.get("success", score >= 0.6)
			if ok:
				l["thirst"] = maxi(0, int(l["thirst"]) - 60)
				GameState.counter("feeds")
				_done("🌒", "The hunt", "Hunt: %s. I slipped through the dark, fed, and was gone before anyone saw a thing." % grade, {"happiness": 6})
			elif detail.get("intel", false):
				l["thirst"] = maxi(0, int(l["thirst"]) - 40)
				_done("🌒", "Seen", "Hunt: %s. I fed, but someone saw my face on the way out." % grade, {"heat": 15})
			else:
				_done("🌒", "Spotted", "Hunt: %s. A flashlight caught me before I reached anyone. I fled over the rooftops, still starving." % grade, {"heat": 10, "stress": 8})
		"patrol":
			if detail.get("won", score >= 0.5):
				l["saves"] = int(l["saves"]) + 1
				l["rep"] = int(l["rep"]) + 3
				l["suspicion"] = int(l["suspicion"]) + 3
				GameState.counter("saves")
				_done("🌃", "Justice", "Patrol: %s. %s left three muggers tied to a lamppost with a note for the police." % [grade, l["alias"]], {"karma": 3, "happiness": 6})
			else:
				_done("🌃", "Rough night", "Patrol: %s. They were tougher than they looked. %s limped home." % [grade, l["alias"]], {"health": -12} if not has_power("healing") else {"health": -4})
		"heist":
			var ok2 := score >= 0.5
			if ok2:
				var take := _cost(int((100000 + float(l["power"]) * 20000) * (0.5 + score) * (1.4 if has_power("fire") or has_power("telekinesis") else 1.0)))
				l["heists"] = int(l["heists"]) + 1
				l["rep"] = int(l["rep"]) + 4
				GameState.counter("heists")
				_done("💰", "Heist", "Heist: %s. %s cracked the vault and vanished with %s." % [grade, l["alias"], GameState.fmt_money(take)], {"money": take, "heat": 8 if has_power("invisibility") else 15, "karma": -8})
			else:
				_done("🚨", "Alarm", "Heist: %s. The alarms went off. I barely escaped." % grade, {"heat": 20, "stress": 10})
				if randf() < 0.25 and not has_power("invisibility"):
					p["record"].append("robbery")
					Law.trial("robbery", 3, 10)
		"nemesis":
			var nid: String = l.get("nemesis", "")
			if detail.get("won", score >= 0.5):
				l["nemesis_wins"] = int(l["nemesis_wins"]) + 1
				if int(l["nemesis_wins"]) >= 3 and GameState.npcs.has(nid):
					GameState.npcs[nid]["alive"] = false
					GameState.counter("nemesis_defeated")
					GameState.add_milestone(p["age"], "defeated their nemesis, %s" % GameState.npcs[nid]["title"])
					_done("🏆", "It's over", "Battle: %s. I defeated %s for the last time." % [grade, GameState.npcs[nid]["title"]], {"fame": 8, "happiness": 15})
				else:
					_done("⚔️", "Round to me", "Battle: %s. %s retreated. They'll be back." % [grade, GameState.npcs[nid]["title"] if GameState.npcs.has(nid) else "My nemesis"], {"fame": 3})
			else:
				_done("⚔️", "Defeated", "Battle: %s. My nemesis left me in the rubble." % grade + Grit.scar_chance("facial_scar", 0.2), {"health": -20})
		"brew":
			_resolve_brew(score, detail, grade)
		"revenge":
			var b: Dictionary = l.get("business", {})
			if detail.get("won", score >= 0.5):
				b["won"] = true
				var t := GameState.npc(b.get("target", ""))
				if not t.is_empty():
					t["grudge"] = 0
				_done("⚔️", "Vengeance", "Revenge: %s. %s looked into my dead eyes and begged. It's settled." % [grade, t.get("first", "They")], {"heat": 10, "karma": -3})
			else:
				l["rot"] = int(l["rot"]) + 10
				_done("⚔️", "Not yet", "Revenge: %s. I lost my grip, and a piece of my arm." % grade, {"health": -10})
	GameState.emit_changed()
