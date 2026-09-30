extends Node

## Consequences: difficulty, scars, habits, credit and debt, grudges, old-age
## care and neglect. Comfort is never guaranteed.

const DIFFICULTY := {
	"classic": {"name": "Classic", "icon": "🌤️", "desc": "Forgiving, like BitLife. Rare twists and soft landings.",
		"twist": 0.45, "harsh": 0.7, "cost": 0.9, "sentence": 0.8, "acquit": 1.25, "age": 0.85, "heal": 1.3, "grudge": 0.5, "habit": 0.7, "credit_min": 520},
	"real": {"name": "Real", "icon": "⚖️", "desc": "The default. Twists happen and choices cost something.",
		"twist": 1.0, "harsh": 1.0, "cost": 1.0, "sentence": 1.0, "acquit": 1.0, "age": 1.0, "heal": 1.0, "grudge": 1.0, "habit": 1.0, "credit_min": 580},
	"gritty": {"name": "Gritty", "icon": "🩸", "desc": "Life fights back. More twists, harder falls, slower recovery.",
		"twist": 1.6, "harsh": 1.35, "cost": 1.15, "sentence": 1.3, "acquit": 0.8, "age": 1.2, "heal": 0.7, "grudge": 1.6, "habit": 1.3, "credit_min": 620},
}

const SCARS := {
	"bad_knee": {"name": "Bad knee", "icon": "🦵", "caps": {"health": 15}, "fix": true, "desc": "It aches when it rains."},
	"back_injury": {"name": "Back injury", "icon": "🦴", "caps": {"health": 20}, "fix": true, "desc": "Some mornings you can't get up."},
	"limp": {"name": "A limp", "icon": "🦯", "caps": {"health": 10, "looks": 5}, "fix": true, "desc": "You'll never run again."},
	"facial_scar": {"name": "Facial scar", "icon": "🩹", "caps": {"looks": 20}, "fix": true, "desc": "People stare, then pretend not to."},
	"burns": {"name": "Burn scars", "icon": "🔥", "caps": {"looks": 15, "health": 5}, "fix": false, "desc": "A reminder of the fire."},
	"concussions": {"name": "Old concussions", "icon": "🧠", "caps": {"smarts": 15}, "fix": false, "desc": "Words slip away sometimes."},
	"weak_heart": {"name": "Weak heart", "icon": "❤️‍🩹", "caps": {"health": 25}, "fix": false, "desc": "The doctors say take it easy."},
	"lungs": {"name": "Damaged lungs", "icon": "🫁", "caps": {"health": 15}, "fix": false, "desc": "Stairs are harder than they used to be."},
	"hearing": {"name": "Hearing loss", "icon": "👂", "caps": {"health": 5}, "fix": false, "desc": "Everyone mumbles now."},
	"missing_finger": {"name": "Missing finger", "icon": "✋", "caps": {"looks": 5}, "fix": false, "desc": "You count to nine now."},
	"haunted": {"name": "Haunted", "icon": "👻", "caps": {"happiness": 15}, "fix": true, "desc": "Something you lived through still keeps you up at night."},
	"broken_trust": {"name": "Broken trust", "icon": "💔", "caps": {"happiness": 10}, "fix": true, "desc": "It's hard to let anyone in."},
	"surgery": {"name": "Surgical scar", "icon": "🩺", "caps": {"looks": 10, "health": 8}, "fix": true, "desc": "A long line somebody closed carefully."},
	"public_shame": {"name": "Publicly shamed", "icon": "📰", "caps": {"happiness": 12}, "fix": true, "heals_by": "years of it quietly going away", "desc": "Strangers decided who you were, and it stuck."},
}

const HABITS := {
	"gambling": {"name": "Gambling", "icon": "🎰", "desc": "The next bet always feels like the one."},
	"shopping": {"name": "Shopping", "icon": "🛍️", "desc": "Buying things feels good for about a day."},
	"workaholic": {"name": "Workaholism", "icon": "💼", "desc": "Rest feels like falling behind."},
	"partying": {"name": "Partying", "icon": "🪩", "desc": "Every night is a good night to go out."},
}

const BOONS := {
	"trust_fund": {"name": "Trust Fund", "icon": "💰", "cost": 40, "desc": "$25,000 waiting for you at 18"},
	"extra_trait": {"name": "Gifted", "icon": "✨", "cost": 50, "desc": "Start with a third trait"},
	"second_wind": {"name": "Second Wind", "icon": "💨", "cost": 80, "desc": "Survive one fatal moment per life"},
	"lucky_star": {"name": "Lucky Star", "icon": "🍀", "cost": 60, "desc": "Turning Points lean your way"},
	"iron_will": {"name": "Iron Will", "icon": "🧱", "cost": 45, "desc": "Habits form half as fast"},
	"family_ties": {"name": "Family Ties", "icon": "🫂", "cost": 35, "desc": "Family closeness fades slower"},
	"clean_slate": {"name": "Clean Slate", "icon": "🧽", "cost": 55, "desc": "Your first conviction each life is probation"},
	"street_smarts": {"name": "Street Smarts", "icon": "🕶️", "cost": 40, "desc": "Black Market open from the start, fewer undercover cops"},
}


# ================================================================ difficulty

func key() -> String:
	return str(GameState.player.get("difficulty", "real"))


func d(k: String) -> float:
	return float(DIFFICULTY.get(key(), DIFFICULTY["real"])[k])


func has_boon(b: String) -> bool:
	return GameState.player.get("boons", []).has(b)


func apply_start(opts: Dictionary) -> void:
	var p := GameState.player
	p["difficulty"] = opts.get("difficulty", "real")
	p["boons"] = Array(opts.get("boons", []))
	if has_boon("extra_trait"):
		var more := GameState._random_traits(4)
		for t in more:
			if not p["traits"].has(t):
				p["traits"].append(t)
				break
	if has_boon("street_smarts"):
		GameState.set_flag("bm_known")


# ================================================================ scars

func add_scar(id: String, quiet: bool = false) -> String:
	var p := GameState.player
	if not SCARS.has(id) or p["scars"].has(id):
		return ""
	p["scars"].append(id)
	var s: Dictionary = SCARS[id]
	for k in s["caps"].keys():
		if GameState.stat(k) > cap(k):
			p["stats"][k] = float(cap(k))
	var kind := "a lasting mark" if id in ["haunted", "broken_trust", "public_shame"] else "a lasting injury"
	GameState.add_milestone(p["age"], "was left with %s: %s" % [kind, s["name"].to_lower()])
	GameState.counter("scars")
	var line := "\n\n%s Lasting mark: %s. %s" % [s["icon"], s["name"], s["desc"]]
	if not quiet:
		GameState.add_log("I'll carry this forever: %s." % s["name"].to_lower())
	return line


func cap(stat_key: String) -> float:
	var p := GameState.player
	var c := 100.0
	for id in p.get("scars", []):
		c -= float(SCARS.get(id, {}).get("caps", {}).get(stat_key, 0))
	return maxf(10.0, c)


func scar_chance(id: String, chance: float) -> String:
	if randf() < chance * d("harsh"):
		return add_scar(id)
	return ""


func treat_scar() -> void:
	var p := GameState.player
	var fixable: Array = p["scars"].filter(func(x): return SCARS[x]["fix"])
	if fixable.is_empty():
		EventEngine.push_info("🩺", "Treatment", "Nothing the doctors can fix. You've learned to live with it.")
		return
	var price := Actions._cost(15000)
	if not Actions._can_pay(price, "Treatment"): return
	if Actions._out_of_time(): return
	var id: String = fixable[0]
	var s: Dictionary = SCARS[id]
	p["money"] = int(p["money"]) - price
	var what := str(s.get("heals_by", "months of therapy" if id in ["haunted", "broken_trust"] else "surgery"))
	if randf() < 0.45 * d("heal"):
		p["scars"].erase(id)
		GameState.counter("scars_healed")
		Actions._done(s["icon"], "Healed", "After %s, my %s is finally behind me." % [what, s["name"].to_lower()], {"happiness": 12})
	else:
		Actions._done(s["icon"], "Still there", "I went through %s for my %s. It didn't take. Maybe next time." % [what, s["name"].to_lower()], {"happiness": -5, "stress": 5})


# ================================================================ habits

func habit(id: String, amount: float) -> void:
	var p := GameState.player
	if not HABITS.has(id) or int(p["age"]) < 14:
		return
	var h: Dictionary = p["habits"].get(id, {"level": 0.0, "active": false, "clean": -1})
	var mult := d("habit") * (0.5 if has_boon("iron_will") else 1.0)
	if id == "gambling" and GameState.has_trait("Gambler"):
		mult *= 1.5
	if amount > 0:
		mult *= lerpf(1.4, 0.6, GameState.hidden("willpower") / 100.0)
	h["level"] = clampf(float(h["level"]) + amount * mult, 0.0, 100.0)
	h["touched"] = int(p["age"])
	p["habits"][id] = h
	if not h["active"] and float(h["level"]) >= 60.0:
		h["active"] = true
		var relapse: bool = int(h.get("clean", -1)) >= 0
		h["clean"] = -1
		GameState.add_milestone(p["age"], ("relapsed into " if relapse else "developed a ") + HABITS[id]["name"].to_lower() + (" habit" if not relapse else ""))
		GameState.counter("habits_formed")
		EventEngine.push_info(HABITS[id]["icon"], "Relapse" if relapse else "A habit took hold", ("I slipped back into old %s habits." if relapse else "I have a %s problem. I can't stop.") % HABITS[id]["name"].to_lower() + "\n\n" + HABITS[id]["desc"] + "\nIt will cost me every year until I break it: Therapy or Rehab under Activities → Health.")


func active_habits() -> Array:
	var out: Array = []
	for id in GameState.player.get("habits", {}).keys():
		if GameState.player["habits"][id]["active"]:
			out.append(id)
	return out


func rehab() -> void:
	var p := GameState.player
	var list := active_habits()
	if list.is_empty():
		EventEngine.push_info("🏥", "Rehab", "You don't have a habit that needs rehab.")
		return
	var price := Actions._cost(8000)
	if not Actions._can_pay(price, "Rehab"): return
	if int(p["time_left"]) < 4:
		EventEngine.push_info("⏳", "Rehab", "Rehab takes 4 time points. Try again next year.")
		return
	GameState.spend_time(4)
	p["money"] = int(p["money"]) - price
	var id: String = list[0]
	var h: Dictionary = p["habits"][id]
	var support := 0.0
	if p["partner"] != "" and GameState.npcs.has(p["partner"]) and int(GameState.npcs[p["partner"]]["closeness"]) >= 60:
		support = 0.15
	if randf() < 0.55 + support:
		h["level"] = 20.0
		h["active"] = false
		h["clean"] = int(p["age"])
		GameState.counter("habits_beaten")
		GameState.add_milestone(p["age"], "beat a %s habit" % HABITS[id]["name"].to_lower())
		Actions._done("🏥", "Clean", "Rehab worked. I haven't felt this clear in years.%s" % (" My partner's support made the difference." if support > 0 else ""), {"happiness": 12, "stress": -15, "health": 6})
	else:
		h["level"] = maxf(60.0, float(h["level"]) - 15.0)
		Actions._done("🏥", "Not yet", "I left rehab early. The pull was too strong.", {"happiness": -8, "stress": 6})


func therapy_helps() -> void:
	for id in active_habits():
		var h: Dictionary = GameState.player["habits"][id]
		h["level"] = float(h["level"]) - 12.0
		if float(h["level"]) < 45.0:
			h["active"] = false
			h["clean"] = int(GameState.player["age"])
			GameState.counter("habits_beaten")
			GameState.add_log("Therapy helped me get my %s under control." % HABITS[id]["name"].to_lower())


func _habits_yearly() -> void:
	var p := GameState.player
	for id in p["habits"].keys():
		var h: Dictionary = p["habits"][id]
		if int(h.get("touched", -99)) < int(p["age"]) - 1:
			h["level"] = maxf(0.0, float(h["level"]) - (4.0 if h["active"] else 8.0))
		if not h["active"]:
			continue
		match id:
			"gambling":
				var lose := maxi(Actions._cost(500), int(maxi(0, int(p["money"])) * randf_range(0.1, 0.3)))
				_compulsion("🎰", "The itch", "I told myself one more hand. I lost %s at the tables this year." % GameState.fmt_money(lose), {"money": -lose, "stress": 8, "happiness": -4}, id)
			"shopping":
				var spend := maxi(Actions._cost(1500), int(maxi(0, int(p["money"])) * randf_range(0.06, 0.15)))
				_compulsion("🛍️", "Retail therapy", "Boxes keep arriving. I spent %s on things I didn't need." % GameState.fmt_money(spend), {"money": -spend, "happiness": 2}, id)
			"workaholic":
				GameState.apply_effects({"stress": 12, "health": -4, "job_perf": 6})
				for rel in ["partner", "child"]:
					for nid in GameState.npcs_with(rel):
						GameState.change_closeness(nid, -6)
				GameState.add_log("I worked through birthdays and weekends again. My family barely sees me.")
			"partying":
				var cost := Actions._cost(3000)
				GameState.apply_effects({"money": -cost, "health": -6, "looks": -2})
				GameState.add_log("Another year of late nights. My body is starting to notice.")
				if randf() < 0.08 * d("harsh"):
					p["record"].append("public intoxication")
					GameState.add_log("I got arrested after a party got out of hand.")
					if Law.has_license("driver") and randf() < 0.5:
						Law.suspend("driver", 2, "caught driving home drunk")
					Law.trial("disorderly conduct", 1, 1)


func _compulsion(icon: String, title_txt: String, text: String, fx: Dictionary, id: String) -> void:
	var resist := clampf(0.25 + GameState.stat("happiness") / 250.0 - GameState.stat("stress") / 250.0, 0.05, 0.6)
	EventEngine.push_decision({"id": "_habit_" + id, "icon": icon, "title": title_txt, "text": "The %s pull is back." % HABITS[id]["name"].to_lower(), "choices": [
		{"label": "Fight it", "outcomes": [
			{"weight": resist, "text": "I white-knuckled through it. One day at a time.", "effects": {"stress": 6, "happiness": 2}},
			{"weight": 1.0 - resist, "text": "I couldn't hold on. " + text, "effects": fx}]},
		{"label": "Give in", "outcomes": [{"text": text, "effects": fx}]},
	]})


# ================================================================ credit & debt

func credit() -> int:
	return int(GameState.player.get("credit", 650))


func credit_label(c: int = -1) -> String:
	if c < 0:
		c = credit()
	if c >= 780: return "Excellent"
	if c >= 700: return "Good"
	if c >= 620: return "Fair"
	if c >= 540: return "Poor"
	return "Terrible"


func credit_ok() -> bool:
	return credit() >= int(d("credit_min"))


func change_credit(delta: int) -> void:
	var p := GameState.player
	p["credit"] = clampi(credit() + delta, 300, 850)


func _credit_yearly() -> void:
	var p := GameState.player
	if int(p["age"]) < 18:
		return
	var money := int(p["money"])
	if int(p.get("bankrupt_until", -1)) > int(p["age"]):
		change_credit(5)
		return
	if money < 0:
		p["debt_years"] = int(p.get("debt_years", 0)) + 1
		change_credit(-randi_range(35, 70))
		_collectors()
	else:
		p["debt_years"] = 0
		change_credit(12 if money > 5000 else 6)
	if int(p["loan"]) > 0 and int(p["last_income"]) == 0:
		change_credit(-15)
		GameState.add_log("I missed my student loan payments again.")


func _collectors() -> void:
	var p := GameState.player
	var owed := -int(p["money"])
	var yrs := int(p.get("debt_years", 0))
	var fees := int(owed * 0.12 * d("cost"))
	p["money"] = int(p["money"]) - fees
	if GameState.has_job():
		GameState.add_log("Debt collectors garnished my wages. Interest and fees added another %s." % GameState.fmt_money(fees))
	else:
		GameState.add_log("The collectors keep calling. Interest and fees added another %s." % GameState.fmt_money(fees))
	GameState.apply_effects({"stress": 8, "happiness": -3})
	if yrs >= 2:
		var seized := ""
		if p["car"] != "":
			var cv := int(GameState.CARS[p["car"]]["price"] * 0.4)
			p["money"] = int(p["money"]) + cv
			seized = "my car"
			p["car"] = ""
		elif not p["possessions"].is_empty():
			var best := 0
			for i in range(p["possessions"].size()):
				if int(p["possessions"][i]["value"]) > int(p["possessions"][best]["value"]):
					best = i
			var it: Dictionary = p["possessions"][best]
			p["money"] = int(p["money"]) + int(int(it["value"]) * 0.5)
			seized = "my " + str(it["name"]).to_lower()
			p["possessions"].remove_at(best)
		if seized != "":
			GameState.counter("repossessions")
			GameState.add_log("The repo man came and took %s." % seized)
			GameState.apply_effects({"happiness": -8, "stress": 8})
	if owed >= Actions._cost(40000) and yrs >= 2 and int(p.get("bankrupt_until", -1)) < int(p["age"]):
		EventEngine.push_decision({"id": "_bankruptcy", "icon": "📉", "title": "Drowning in debt", "text": "You owe %s and the letters are getting angrier. A lawyer says you could declare bankruptcy." % GameState.fmt_money(owed), "choices": [
			{"label": "Declare bankruptcy", "outcomes": [{"text": "I declared bankruptcy. The debt is gone, and so is my credit for a long time.", "effects": {"stress": -10, "happiness": -6}, "grit": "bankruptcy"}]},
			{"label": "Keep fighting it", "outcomes": [{"text": "I'll dig myself out. Somehow.", "effects": {"stress": 10}}]},
		]})


func bankruptcy() -> void:
	var p := GameState.player
	p["money"] = 0
	p["possessions"] = p["possessions"].filter(func(it): return it.get("heirloom", false))
	if not p["business"].is_empty():
		Empires._close_business()
	p["credit"] = 330
	p["bankrupt_until"] = int(p["age"]) + 7
	p["debt_years"] = 0
	GameState.counter("bankruptcies")
	GameState.add_milestone(p["age"], "declared bankruptcy")


# ================================================================ grudges

func grudge(id: String, amount: int) -> void:
	if not GameState.npcs.has(id) or amount <= 0:
		return
	var n: Dictionary = GameState.npcs[id]
	if n.get("species", "human") != "human" or not n["alive"]:
		return
	var before := int(n.get("grudge", 0))
	n["grudge"] = clampi(before + int(amount * d("grudge")), 0, 100)
	if before < 40 and int(n["grudge"]) >= 40:
		GameState.add_log("%s isn't going to forget what I did." % GameState.full_name(id))


func on_closeness(id: String, delta: int) -> void:
	if not GameState.npcs.has(id):
		return
	var n: Dictionary = GameState.npcs[id]
	if delta <= -25:
		grudge(id, -delta - 10)
	elif delta > 0 and n.has("grudge"):
		n["grudge"] = maxi(0, int(n["grudge"]) - delta * 2)


func grudge_holders(min_g: int = 40) -> Array:
	var out: Array = []
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if n["alive"] and int(n.get("grudge", 0)) >= min_g:
			out.append(id)
	return out


func make_amends(id: String) -> void:
	if Actions._out_of_time(): return
	var n := GameState.npc(id)
	if n.is_empty():
		return
	var ch := clampf(0.3 + int(n["closeness"]) / 150.0 + (0.15 if GameState.has_trait("Charmer") else 0.0) - int(n.get("grudge", 0)) / 300.0, 0.05, 0.85)
	if randf() < ch:
		n["grudge"] = maxi(0, int(n.get("grudge", 0)) - 50)
		GameState.change_closeness(id, 12)
		GameState.counter("amends")
		Actions._done("🤝", "Amends", "I apologized to %s, properly this time. %s actually listened." % [n["first"], GameState.pron(n["gender"], "he").capitalize()], {"happiness": 6, "karma": 3})
	else:
		n["grudge"] = mini(100, int(n.get("grudge", 0)) + 5)
		Actions._done("🚪", "Door slammed", "%s wasn't ready to hear it." % n["first"], {"happiness": -4})


func _grudges_yearly() -> void:
	var p := GameState.player
	var acted := false
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"] or not n.has("grudge"):
			continue
		n["grudge"] = maxi(0, int(n["grudge"]) - 6)
		if acted or int(n["grudge"]) < 40 or int(p["age"]) < 12:
			continue
		if randf() < float(n["grudge"]) / 550.0 * d("grudge"):
			acted = true
			_retaliate(id)


func _retaliate(id: String) -> void:
	var p := GameState.player
	var n: Dictionary = GameState.npcs[id]
	var nm := GameState.full_name(id)
	var opts: Array = ["vandal", "rumor", "family"]
	if int(p["age"]) >= 18:
		opts.append("sue")
	if GameState.has_job():
		opts.append("sabotage")
	if float(p.get("heat", 0)) >= 20 or not p["record"].is_empty() or not p["cult"].is_empty() or GameState.has_flag("cooked_books"):
		opts.append("snitch")
		opts.append("snitch")
	if int(p["age"]) >= 14:
		opts.append("fight")
	GameState.counter("retaliations")
	n["grudge"] = maxi(0, int(n["grudge"]) - 25)
	match opts[randi() % opts.size()]:
		"vandal":
			var cost := Actions._cost(1500 if p["car"] != "" else 800)
			EventEngine.push_info("🔑", "Payback", "Someone keyed my %s and smashed the windows. I know it was %s." % ["car" if p["car"] != "" else "front door", nm], GameState.apply_effects({"money": -cost, "stress": 6}))
		"rumor":
			for rel in ["friend", "best_friend", "coworker"]:
				for fid in GameState.npcs_with(rel):
					GameState.change_closeness(fid, -6)
			if Lives.is_type("royal"):
				Lives.life()["respect"] = maxf(0.0, float(Lives.life()["respect"]) - 8.0)
			EventEngine.push_info("🗣️", "Poisoned well", "%s has been telling everyone what I'm really like.%s" % [nm, " The tabloids ran with it." if Lives.is_type("royal") else " My friends are looking at me differently."], GameState.apply_effects({"happiness": -6}))
		"family":
			var fam := GameState.random_of(["mother", "father", "sibling", "child", "partner"])
			if fam != "":
				GameState.change_closeness(fam, -15)
				EventEngine.push_info("🐍", "Turned against me", "%s got to my %s with stories about me. Things are cold at home now." % [nm, GameState.relation_label(fam).to_lower()], GameState.apply_effects({"happiness": -5}))
		"sue":
			var claim := Actions._cost(randi_range(8000, 60000))
			var choices: Array = []
			var lw := Web.contact(["lawyer"], 30)
			if lw != "":
				choices.append({"label": "Have %s handle it" % Web.contact_line(lw), "outcomes": [{"weight": 0.75, "text": "%s got the case thrown out." % GameState.npc(lw)["first"], "relationship": {"lw": 4}}, {"weight": 0.25, "text": "Even %s couldn't win this one. I paid %s." % [GameState.npc(lw)["first"], GameState.fmt_money(claim)], "effects": {"money": -claim}}]})
			choices.append({"label": "Settle for %s" % GameState.fmt_money(claim / 2), "outcomes": [{"text": "I paid {g.first} to go away.", "effects": {"money": -claim / 2}}]})
			choices.append({"label": "Fight it in court", "outcomes": [{"weight": 0.45, "text": "I won. The judge called it petty.", "effects": {"stress": 5}}, {"weight": 0.55, "text": "I lost and paid {g.first} %s." % GameState.fmt_money(claim), "effects": {"money": -claim, "stress": 10}}]})
			var roles := {"g": id}
			if lw != "":
				roles["lw"] = lw
			EventEngine.push_decision({"id": "_grudge_sue", "icon": "⚖️", "title": "Sued", "text": "{g.first} {g.last} is suing me for %s. This is about what I did, and we both know it." % GameState.fmt_money(claim), "choices": choices}, roles)
		"sabotage":
			GameState.apply_effects({"job_perf": -25})
			var fired := float(p["job"]["perf"]) < 25 and randf() < 0.5
			EventEngine.push_info("🗃️", "Sabotage", "%s sent my boss screenshots and a list of my mistakes.%s" % [nm, " I was fired." if fired else " My performance review was brutal."], GameState.apply_effects({"stress": 10}))
			if fired:
				Actions.lose_job("fired")
		"snitch":
			var hit := 20
			EventEngine.push_info("📞", "Anonymous tip", "%s called the police about me. Detectives are asking questions." % nm, GameState.apply_effects({"heat": hit, "stress": 10}))
			GameState.set_flag("hostile_witness")
		"fight":
			var roles2 := {"g": id}
			EventEngine.push_decision({"id": "_grudge_fight", "icon": "👊", "title": "Confrontation", "text": "{g.first} is waiting outside. Still angry. Fists clenched.", "choices": [
				{"label": "Fight", "outcomes": [{"text": "", "play": {"id": "fight", "kind": "brawl", "params": {"difficulty": 0.9, "opponent": nm}}}]},
				{"label": "Apologize", "outcomes": [{"weight": 1, "text": "I apologized. {g.first} spat at my feet and left.", "effects": {"happiness": -3}}, {"weight": 1, "text": "I apologized. {g.first} broke down. We're not friends, but it's over.", "grudge_clear": "g"}]},
				{"label": "Walk away", "outcomes": [{"text": "I walked away. {g.first} shouted after me for a block.", "effects": {"stress": 4}}]},
			]}, roles2)


# ================================================================ yearly

func yearly() -> void:
	var p := GameState.player
	_habits_yearly()
	_credit_yearly()
	_grudges_yearly()
	_neglect()
	_old_age()
	if p.get("nursing_home", false):
		GameState.apply_effects({"happiness": -5, "money": -Actions._cost(30000)})
		GameState.add_log("Another year in the nursing home. The food is beige.")
	if has_boon("trust_fund") and int(p["age"]) == 18 and not GameState.has_flag("trust_paid"):
		GameState.set_flag("trust_paid")
		p["money"] = int(p["money"]) + 25000
		GameState.add_log("My trust fund paid out $25,000.")


func _neglect() -> void:
	var p := GameState.player
	if int(p["age"]) < 30:
		return
	for cid in GameState.npcs_with("child"):
		var c: Dictionary = GameState.npcs[cid]
		if int(c["age"]) >= 18 and int(c["closeness"]) < 15 and not c.get("estranged", false) and randf() < 0.3:
			c["estranged"] = true
			GameState.counter("estranged")
			GameState.add_log("%s stopped returning my calls. My own child." % c["first"])
			GameState.apply_effects({"happiness": -10})
		elif c.get("estranged", false) and int(c["closeness"]) >= 40:
			c.erase("estranged")
			GameState.add_log("%s and I are talking again." % c["first"])


func _old_age() -> void:
	var p := GameState.player
	if int(p["age"]) < 78 or GameState.has_flag("care_decided") or GameState.in_prison():
		return
	if GameState.stat("health") > 45 and int(p["age"]) < 85:
		return
	GameState.set_flag("care_decided")
	var best := ""
	var best_c := 59
	for cid in GameState.npcs_with("child") + GameState.npcs_with("grandchild"):
		var c: Dictionary = GameState.npcs[cid]
		if not c.get("estranged", false) and int(c["closeness"]) > best_c and int(c["age"]) >= 21:
			best = cid
			best_c = int(c["closeness"])
	var partner: String = p["partner"]
	if partner != "" and GameState.npcs.has(partner) and int(GameState.npcs[partner]["closeness"]) >= 55:
		GameState.add_log("%s promised to take care of me as long as we both live." % GameState.npc(partner)["first"])
		GameState.apply_effects({"happiness": 8})
	elif best != "":
		GameState.add_milestone(p["age"], "moved in with %s in old age" % GameState.npc(best)["first"])
		EventEngine.push_info("🏡", "Family takes you in", "%s insisted I move in with them. The grandkids fight over who sits next to me." % GameState.full_name(best), GameState.apply_effects({"happiness": 12, "health": 5, "stress": -8}))
	else:
		p["nursing_home"] = true
		GameState.counter("nursing_home")
		GameState.add_milestone(p["age"], "spent their last years in a nursing home")
		EventEngine.push_info("🏥", "Nobody came", "There was no one to look after me. I moved into a nursing home.\n\nThe staff are kind. They are not family.", GameState.apply_effects({"happiness": -15, "stress": 6}))


# ================================================================ outcome hook

func outcome(o: Dictionary, roles: Dictionary) -> String:
	var p := GameState.player
	var extra := ""
	if o.has("scar"):
		extra += add_scar(str(o["scar"]))
	if o.has("habit"):
		habit(str(o["habit"][0]), float(o["habit"][1]))
	if o.has("credit"):
		change_credit(int(o["credit"]))
	if o.has("debt"):
		p["loan"] = int(p["loan"]) + int(o["debt"])
	if o.has("grudge"):
		for r in o["grudge"].keys():
			if roles.has(r):
				grudge(roles[r], int(o["grudge"][r]))
	if o.has("grudge_clear") and roles.has(o["grudge_clear"]) and GameState.npcs.has(roles[o["grudge_clear"]]):
		GameState.npcs[roles[o["grudge_clear"]]]["grudge"] = 0
	if o.get("grit", "") == "bankruptcy":
		bankruptcy()
	if o.has("lose_money_pct") and int(p["money"]) > 0:
		p["money"] = int(int(p["money"]) * (1.0 - float(o["lose_money_pct"])))
	if o.has("lose_savings_pct"):
		p["savings"] = int(int(p["savings"]) * (1.0 - float(o["lose_savings_pct"])))
	if o.has("lose_possessions"):
		var keep: Array = []
		for it in p["possessions"]:
			if randf() >= float(o["lose_possessions"]):
				keep.append(it)
		p["possessions"] = keep
	if o.get("lose_property", false) and not p["properties"].is_empty():
		var idx: int = randi() % p["properties"].size()
		var pr: Dictionary = p["properties"][idx]
		if pr.get("tenant", "") != "" and GameState.npcs.has(pr["tenant"]):
			GameState.npcs[pr["tenant"]]["relation"] = "former_tenant"
		p["properties"].remove_at(idx)
		extra += "\n\nI lost my %s." % str(pr["type"]).to_lower()
	if o.get("house_destroyed", false) and p["housing"] == "house":
		var payout := int(int(p["house_value"]) * (0.5 if key() != "gritty" else 0.3))
		p["money"] = int(p["money"]) + payout
		p["house_value"] = 0
		p["housing"] = "apartment"
		extra += "\n\nInsurance paid %s. The mortgage didn't go anywhere." % GameState.fmt_money(payout)
	if o.get("market_crash", false):
		var w := GameState.world
		for s in w.get("stocks", {}).keys():
			w["stocks"][s] = float(w["stocks"][s]) * randf_range(0.35, 0.6)
		for c in w.get("crypto", {}).keys():
			w["crypto"][c] = float(w["crypto"][c]) * randf_range(0.1, 0.5)
		w["market_mood"] = "crash"
		for pr in p["properties"]:
			pr["value"] = int(int(pr["value"]) * 0.75)
	if o.get("new_identity", false):
		_new_identity()
	if o.has("coma"):
		extra += _coma(randi_range(int(o["coma"][0]), int(o["coma"][1])))
	if o.get("clear_prison", false):
		p["prison"] = 0
	if o.get("nursing_home", false):
		p["nursing_home"] = true

	return extra


func _new_identity() -> void:
	var p := GameState.player
	var others: Array = ContentDB.countries.filter(func(c): return c["id"] != p["country"])
	var c: Dictionary = others[randi() % others.size()]
	var old_name := "%s %s" % [p["first"], p["last"]]
	p["first"] = ContentDB.random_first(p["gender"] if p["gender"] != "nonbinary" else "female", c["id"])
	p["last"] = ContentDB.random_last(c["id"])
	Actions.finish_emigration(c["id"])
	if not p["career"].is_empty():
		Careers.quit("quit")
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if id == p["partner"] or n["relation"] == "child" or n.get("species", "human") != "human":
			n["last"] = p["last"] if n["relation"] == "child" else n["last"]
			continue
		n["closeness"] = mini(int(n["closeness"]), 5)
	p["heat"] = 0.0
	GameState.set_flag("witness_protection")
	GameState.add_milestone(p["age"], "entered witness protection and left %s behind" % old_name)


func _coma(years: int) -> String:
	var p := GameState.player
	if GameState.has_job():
		Actions.lose_job("fired")
	if not p["career"].is_empty():
		Careers.quit("quit")
	p["age"] = int(p["age"]) + years
	for id in GameState.npcs.keys():
		if GameState.npcs[id]["alive"]:
			GameState.npcs[id]["age"] = int(GameState.npcs[id]["age"]) + years
			GameState.npcs[id]["closeness"] = maxi(0, int(GameState.npcs[id]["closeness"]) - years * 4)
	if p["partner"] != "" and GameState.npcs.has(p["partner"]) and int(GameState.npcs[p["partner"]]["closeness"]) < 55 and randf() < 0.5:
		var pn: Dictionary = GameState.npcs[p["partner"]]
		pn["relation"] = "ex"
		p["partner"] = ""
		p["partner_status"] = ""
		GameState.add_log("%s moved on while I was asleep." % pn["first"])
	p["stats"]["health"] = minf(GameState.stat("health"), 35.0)
	p["stats"]["looks"] = GameState.stat("looks") - 8.0
	GameState.log_years.append({"age": int(p["age"]), "lines": []})
	GameState.add_log("I woke up. %d year%s of my life were gone." % [years, "" if years == 1 else "s"])
	GameState.add_milestone(p["age"], "woke from a %d-year coma" % years)
	return "\n\nI woke up in a hospital bed. It was %d. I had been asleep for %d year%s." % [GameState.year_now(), years, "" if years == 1 else "s"]


# ================================================================ summary

func consequences() -> Array:
	var p := GameState.player
	var out: Array = []
	for id in p.get("scars", []):
		out.append("%s %s" % [SCARS[id]["icon"], SCARS[id]["name"]])
	for id in active_habits():
		out.append("%s %s habit" % [HABITS[id]["icon"], HABITS[id]["name"]])
	if GameState.get_counter("bankruptcies") > 0:
		out.append("📉 Bankrupt %s" % ("once" if GameState.get_counter("bankruptcies") == 1 else "%d times" % GameState.get_counter("bankruptcies")))
	if int(p["prison_total"]) > 0:
		out.append("⛓️ %d year%s behind bars" % [int(p["prison_total"]), "" if int(p["prison_total"]) == 1 else "s"])
	var g := grudge_holders().size()
	if g > 0:
		out.append("😠 %d %s who never forgave you" % [g, "person" if g == 1 else "people"])
	var est := GameState.npcs_with("child", false).filter(func(x): return GameState.npcs[x].get("estranged", false)).size()
	if est > 0:
		out.append("🚪 %d estranged %s" % [est, "child" if est == 1 else "children"])
	if p.get("nursing_home", false):
		out.append("🏥 Died in a nursing home")
	if GameState.get_counter("twists") > 0:
		out.append("⚡ %d Turning Point%s survived" % [GameState.get_counter("twists"), "" if GameState.get_counter("twists") == 1 else "s"])
	return out
