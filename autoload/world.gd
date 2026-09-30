extends Node

## The living world (multi-year world events) and the billionaire endgame.

const EVENTS := {
	"recession": {"name": "Global recession", "icon": "📉", "years": [2, 3], "weight": 8, "news": "Markets tumble as the world slides into recession. Layoffs everywhere.", "not": ["boom"]},
	"boom": {"name": "Economic boom", "icon": "📈", "years": [2, 4], "weight": 8, "news": "The economy is roaring. Hiring signs in every window.", "not": ["recession"]},
	"war": {"name": "War", "icon": "⚔️", "years": [2, 5], "weight": 4, "news": "War has broken out. Draft offices are opening their doors."},
	"pandemic": {"name": "Pandemic", "icon": "🦠", "years": [1, 2], "weight": 3, "news": "A new virus is spreading across borders. Masks are back."},
	"tech": {"name": "AI revolution", "icon": "🤖", "years": [3, 6], "weight": 5, "news": "AI is rewriting every industry. Tech is booming; whole professions are vanishing."},
	"housing": {"name": "Housing bubble", "icon": "🏘️", "years": [2, 4], "weight": 5, "news": "House prices are climbing faster than anyone can explain."},
	"crypto": {"name": "Crypto mania", "icon": "🪙", "years": [1, 2], "weight": 5, "news": "Everyone's cousin is a crypto millionaire this week."},
	"climate": {"name": "Climate disaster", "icon": "🌊", "years": [1, 1], "weight": 5, "news": "Record floods and fires. Insurance companies are panicking."},
	"space": {"name": "New space race", "icon": "🚀", "years": [3, 6], "weight": 3, "news": "Nations and billionaires are racing back to the Moon."},
	"medicine": {"name": "Medical breakthrough", "icon": "🧬", "years": [5, 10], "weight": 3, "news": "A new generation of treatments is adding years to people's lives."},
	"election": {"name": "Election year", "icon": "🗳️", "years": [1, 1], "weight": 6, "news": "A bitter election is splitting families down the middle."},
	"sports": {"name": "World Cup fever", "icon": "⚽", "years": [1, 1], "weight": 5, "news": "The whole planet is glued to the World Cup."},
}

const TEAMS := [["⚽", "soccer club"], ["🏀", "basketball team"], ["🏈", "football franchise"], ["⚾", "baseball team"], ["🏒", "hockey club"]]
const TEAM_NAMES := ["Thunder", "Royals", "Comets", "Wolves", "Titans", "Harbor FC", "United", "Knights", "Storm", "Falcons"]


func _w() -> Dictionary:
	var w := GameState.world
	if not w.has("events"):
		w["events"] = {}
	if not w.has("news"):
		w["news"] = []
	return w


func active(id: String) -> bool:
	return int(_w()["events"].get(id, 0)) > 0


func active_list() -> Array:
	var out: Array = []
	for id in _w()["events"].keys():
		if int(_w()["events"][id]) > 0:
			out.append(id)
	return out


func news() -> Array:
	return _w()["news"]


func _headline(text: String) -> void:
	var w := _w()
	w["news"].push_front({"year": GameState.year_now(), "text": text})
	if w["news"].size() > 14:
		w["news"].resize(14)
	GameState.add_log("🌍 " + text)


# ================================================================ effects other systems read

func mortality() -> float:
	var m := 1.0
	if active("pandemic"):
		m *= 1.25
	if active("medicine"):
		m *= 0.8
	return m


func market_shock() -> float:
	var s := 0.0
	if active("recession"):
		s -= 0.12
	if active("boom"):
		s += 0.1
	if active("war"):
		s -= 0.04
	return s


func biz_mult(ind: String) -> float:
	var m := 1.0
	if active("recession"):
		m *= 0.8
	if active("boom"):
		m *= 1.15
	if active("war") and ind in ["security", "aerospace", "construction"]:
		m *= 1.4
	if active("pandemic"):
		if ind in ["restaurant", "gym", "studio"]:
			m *= 0.55
		elif ind in ["clinic", "tech"]:
			m *= 1.3
	if active("tech") and ind == "tech":
		m *= 1.6
	if active("space") and ind == "aerospace":
		m *= 1.8
	if active("sports") and ind == "gym":
		m *= 1.2
	return m


func zoo_mult() -> float:
	return 0.5 if active("pandemic") else (0.85 if active("recession") else 1.0)


func cost_mult() -> float:
	return 1.1 if active("war") else 1.0


func crime_mult() -> float:
	var m := 1.0
	if active("war"):
		m *= 1.25
	if active("recession"):
		m *= 1.15
	if active("boom"):
		m *= 0.9
	return m


func pay_mult(field: String) -> float:
	var m := 1.0
	if active("recession"):
		m *= 0.94
	if active("boom"):
		m *= 1.06
	if active("tech") and field in ["Tech", "Science", "Engineering"]:
		m *= 1.18
	if active("pandemic") and field == "Healthcare":
		m *= 1.12
	if active("war") and field == "Military":
		m *= 1.15
	return m


## Why an activity is impossible right now because of a world event, or "".
func blocked(id: String) -> String:
	if active("pandemic"):
		match id:
			"vacation", "emigrate":
				return "The borders are closed because of the pandemic. Nobody is going anywhere."
			"concert", "nightlife", "party", "movie", "casino":
				return "Everything is shut because of the pandemic."
	return ""


func begin(id: String) -> void:
	if EVENTS.has(id) and not active(id):
		_start(id)


# ================================================================ yearly

func yearly() -> void:
	var p := GameState.player
	var w := _w()
	for id in w["events"].keys():
		if int(w["events"][id]) <= 0:
			continue
		w["events"][id] = int(w["events"][id]) - 1
		_ongoing(id)
		if int(w["events"][id]) == 0:
			_ended(id)
	if randf() < 0.4:
		var pool: Array = []
		for id in EVENTS.keys():
			if active(id):
				continue
			var blocked := false
			for other in EVENTS[id].get("not", []):
				if active(other):
					blocked = true
			if not blocked:
				pool.append({"id": id, "w": float(EVENTS[id]["weight"])})
		if not pool.is_empty():
			var pick := EventEngine._weighted_pick(pool, "w")
			_start(pick["id"])
	if p.get("billionaire", {}).size() > 0 or GameState.net_worth() >= 1000000000:
		_billionaire_yearly()


func _start(id: String) -> void:
	var e: Dictionary = EVENTS[id]
	_w()["events"][id] = randi_range(int(e["years"][0]), int(e["years"][1]))
	GameState.counter("world_" + id)
	GameState.counter("world_events")
	Fx.play("news")
	_headline("%s %s. %s" % [e["icon"], e["name"], e["news"]])
	var p := GameState.player
	match id:
		"crypto":
			for c in GameState.world.get("crypto", {}).keys():
				GameState.world["crypto"][c] = float(GameState.world["crypto"][c]) * randf_range(1.8, 3.5)
		"climate":
			if randf() < 0.35 and int(p["age"]) >= 6:
				EventEngine.push_decision({"id": "_climate", "icon": "🌊", "title": "It reached your town", "text": "Flood water is rising in your street. You have minutes.", "choices": [
					{"label": "Save what you can", "outcomes": [{"text": "I carried boxes until the water reached my chest. Half of it was ruined anyway.", "lose_possessions": 0.3, "effects": {"health": -5}}]},
					{"label": "Help the neighbors evacuate", "outcomes": [{"text": "I helped get the old couple next door into a rescue boat.", "effects": {"karma": 8}, "lose_possessions": 0.5}]},
					{"label": "Just get out", "outcomes": [{"text": "I got out with my phone and my shoes.", "lose_possessions": 0.6}]},
				]})
		"election":
			if Careers.has_career("politician"):
				GameState.apply_effects({"approval": randi_range(-8, 8)})
		"war":
			for id2 in GameState.npcs.keys():
				var n: Dictionary = GameState.npcs[id2]
				if n["alive"] and n.get("job", {}).get("key", "") == "soldier" and randf() < 0.25:
					n["alive"] = false
					GameState.add_log("%s was killed in the war." % GameState.full_name(id2))
					GameState.apply_effects({"happiness": -int(n["closeness"]) / 8})


func _ongoing(id: String) -> void:
	var p := GameState.player
	match id:
		"recession":
			if GameState.has_job() and randf() < 0.1:
				Actions.lose_job("fired")
				GameState.add_log("I was laid off in the recession.")
		"tech":
			if GameState.has_job() and randf() < 0.05 and str(p["job"].get("field", "")) not in ["Tech", "Science", "Healthcare", "Engineering"]:
				Actions.lose_job("fired")
				GameState.add_log("My job was automated away.")
		"pandemic":
			if int(p["age"]) >= 5:
				GameState.apply_effects({"health": -4, "happiness": -4})
			if GameState.in_school() or GameState.in_university():
				GameState.apply_effects({"school": -6})
				GameState.add_log("School was online all year. I learned about half of what I should have.")
		"housing":
			for pr in p["properties"]:
				pr["value"] = int(int(pr["value"]) * 1.12)
			if p["housing"] == "house":
				p["house_value"] = int(int(p["house_value"]) * 1.12)
		"sports":
			if Careers.has_career("athlete"):
				GameState.apply_effects({"fame": 3})
		"space":
			if Careers.has_career("astronaut"):
				GameState.apply_effects({"fame": 2})


func _ended(id: String) -> void:
	var p := GameState.player
	match id:
		"housing":
			for pr in p["properties"]:
				pr["value"] = int(int(pr["value"]) * 0.62)
			if p["housing"] == "house":
				p["house_value"] = int(int(p["house_value"]) * 0.62)
			_headline("🏚️ The housing bubble burst. Prices crashed overnight.")
		"crypto":
			for c in GameState.world.get("crypto", {}).keys():
				GameState.world["crypto"][c] = float(GameState.world["crypto"][c]) * randf_range(0.1, 0.35)
			_headline("💥 The crypto bubble popped. Fortunes vanished in a week.")
		"war":
			_headline("🕊️ The war is over. The world counts its losses.")
		"pandemic":
			_headline("😷 The pandemic is officially over.")
		"recession":
			_headline("🌤️ The recession is over. Hiring is picking up again.")


# ================================================================ billionaire endgame

func billionaire_open() -> bool:
	return GameState.net_worth() >= 1000000000 or GameState.has_flag("billionaire")


func _bb() -> Dictionary:
	var p := GameState.player
	if not p.has("billionaire") or not (p["billionaire"] is Dictionary):
		p["billionaire"] = {}
	return p["billionaire"]


func _billionaire_yearly() -> void:
	var p := GameState.player
	var b := _bb()
	if GameState.net_worth() >= 1000000000 and not GameState.has_flag("billionaire"):
		GameState.set_flag("billionaire")
		GameState.add_milestone(p["age"], "became a billionaire")
		EventEngine.push_info("💎", "Billionaire", "Your net worth just crossed a billion. The rules are different up here.\n\nThe Billionaire panel is open under Assets.")
	if b.has("team"):
		_team_season(b["team"])
	if b.has("nation"):
		_nation_yearly(b["nation"])
	if b.has("offshore"):
		b["offshore"] = int(int(b["offshore"]) * 1.04)
		GameState.apply_effects({"heat": 6})
	if b.get("media", false):
		GameState.apply_effects({"heat": -5})
	if randf() < 0.15:
		var envious := GameState.random_of(["sibling", "friend", "auntuncle", "coworker"])
		if envious != "":
			Grit.grudge(envious, 30)
			GameState.add_log("%s has been saying I think I'm better than everyone now." % GameState.full_name(envious))


const PAYROLL := ["Shoestring", "Mid-table", "Contender", "Galácticos"]
const CAUSES := {
	"malaria": ["🦟", "Malaria vaccines", "Saves lives far away · karma"],
	"schools": ["🏫", "Schools", "Better schools where you live"],
	"cancer": ["🧬", "Cancer research", "Might spark a medical breakthrough"],
	"homeless": ["🏠", "Housing the homeless", "Less crime in your city"],
	"climate": ["🌱", "Climate", "Might head off the next disaster"],
}
const NATION_LAWS := {
	"tax_haven": ["🏦", "Become a tax haven", "Income every year · heat · legitimacy -"],
	"casino": ["🎰", "Legalize casinos", "Tourist income · respect -"],
	"passports": ["🛂", "Sell citizenship", "Big money · scandal risk"],
	"democracy": ["🗳️", "Hold free elections", "Legitimacy + · your powers shrink"],
}


func _team_season(t: Dictionary) -> void:
	var p := GameState.player
	var pay := int(t.get("payroll", 1))
	var coach := int(t.get("coach", 0))
	var strength := 0.25 + pay * 0.17 + coach * 0.07 + (0.06 if Careers.past("athlete") else 0.0) + randf_range(-0.18, 0.18)
	var wins := clampi(int(round(82.0 * clampf(strength, 0.1, 0.92))), 8, 76)
	var cost := Actions._cost([15, 45, 110, 240][pay] * 1000000)
	var gate := Actions._cost(int((30 + wins * 0.9 + int(t.get("titles", 0)) * 6) * 1000000 * (1.2 if active("sports") else 1.0)))
	var net := gate - cost
	p["money"] = int(p["money"]) + net
	t["value"] = int(int(t["value"]) * clampf(1.0 + (wins - 41) * 0.004, 0.9, 1.2))
	t["last"] = "%d–%d" % [wins, 82 - wins]
	t["seasons"] = int(t.get("seasons", 0)) + 1
	var champ := 0.0
	if wins >= 50:
		champ = 0.1 + (wins - 50) * 0.02
	var line := "The %s went %s this season (%s %s)." % [t["name"], t["last"], "profit" if net >= 0 else "loss", GameState.fmt_money(absi(net))]
	if randf() < champ:
		t["titles"] = int(t.get("titles", 0)) + 1
		GameState.counter("titles")
		GameState.add_milestone(p["age"], "owned a championship-winning %s" % t["kind"])
		EventEngine.push_info(t["icon"], "Champions!", line + " Then they won the whole thing. I lifted the trophy with the players.", GameState.apply_effects({"fame": 5, "happiness": 15}))
	elif wins <= 25:
		t["fans"] = int(t.get("fans", 50)) - 15
		GameState.add_log(line + " The fans chanted my name, and not kindly.")
		GameState.apply_effects({"happiness": -4})
		if int(t["fans"]) <= 0 and randf() < 0.5:
			EventEngine.push_info(t["icon"], "Sell the team!", "Fans have flown a banner over the stadium: SELL THE TEAM. Attendance has collapsed.", GameState.apply_effects({"fame": -3, "stress": 8}))
	else:
		t["fans"] = mini(100, int(t.get("fans", 50)) + (5 if wins >= 45 else 0))
		GameState.add_log(line)


func _nation_yearly(n: Dictionary) -> void:
	var p := GameState.player
	var laws: Dictionary = n.get("laws", {})
	var income := 0
	if laws.get("tax_haven", false):
		income += Actions._cost(60000000)
		GameState.apply_effects({"heat": 5})
		n["legitimacy"] = int(n["legitimacy"]) - 3
	if laws.get("casino", false):
		income += Actions._cost(25000000)
	if laws.get("passports", false):
		income += Actions._cost(40000000)
		if randf() < 0.15:
			n["legitimacy"] = int(n["legitimacy"]) - 12
			EventEngine.push_info("🛂", "Passport scandal", "A wanted arms dealer was caught traveling on one of %s's passports." % n["name"], GameState.apply_effects({"heat": 15, "karma": -8}))
	if laws.get("democracy", false):
		n["legitimacy"] = int(n["legitimacy"]) + 4
	n["legitimacy"] = clampi(int(n["legitimacy"]) + randi_range(-2, 2), 0, 100)
	p["money"] = int(p["money"]) + income
	if income > 0:
		GameState.add_log("%s paid its monarch %s this year." % [n["name"], GameState.fmt_money(income)])
	if int(n["legitimacy"]) >= 60 and not n.get("recognized", false):
		n["recognized"] = true
		GameState.add_milestone(p["age"], "won UN recognition for %s" % n["name"])
		EventEngine.push_info("🇺🇳", "Recognized", "%s now has a seat at the United Nations. A real country, with a flag, a stamp and an anthem." % n["name"], GameState.apply_effects({"fame": 12, "happiness": 12}))
	elif int(n["legitimacy"]) <= 5 and randf() < 0.3:
		var b := _bb()
		b.erase("nation")
		GameState.clear_flag("island_owner")
		if Lives.is_type("royal"):
			p["life"] = {"type": "human", "exroyal": true}
		GameState.add_milestone(p["age"], "lost %s when a neighbor annexed it" % n["name"])
		EventEngine.push_info("⚓", "Annexed", "A neighboring navy landed on %s at dawn. Nobody objected. My island, and my crown, are gone." % n["name"], GameState.apply_effects({"happiness": -20, "fame": 5}))


func billionaire_actions() -> Array:
	var b := _bb()
	var out: Array = []
	if not b.has("team"):
		out.append({"id": "bb_team", "icon": "🏟️", "name": "Buy a sports team", "sub": GameState.fmt_money(Actions._cost(800000000)) + " · revenue, fame, championships"})
	else:
		var t: Dictionary = b["team"]
		var pay := int(t.get("payroll", 1))
		out.append({"id": "bb_payroll", "icon": "💰", "name": "Payroll: %s" % PAYROLL[pay], "sub": "Tap to change · more money, more wins · last season %s" % t.get("last", "not played")})
		if int(t.get("coach", 0)) < 3:
			out.append({"id": "bb_coach", "icon": "📋", "name": "Hire a better coach", "sub": "%s · coaching level %d/3" % [GameState.fmt_money(Actions._cost(20000000 * (int(t.get("coach", 0)) + 1))), int(t.get("coach", 0))]})
		out.append({"id": "bb_sell_team", "icon": "🤝", "name": "Sell the %s" % t["name"], "sub": "Worth about %s" % GameState.fmt_money(int(t["value"]))})
	var risky := "" if Careers.past("astronaut") else " · rockets fail"
	out.append({"id": "bb_space", "icon": "🚀", "name": "Fly to space", "sub": ("Free for a former astronaut" if Careers.past("astronaut") else GameState.fmt_money(Actions._cost(55000000))) + " · %d trips%s" % [int(b.get("space", 0)), risky]})
	if int(b.get("space", 0)) >= 2 and not b.get("moon", false):
		out.append({"id": "bb_moon", "icon": "🌕", "name": "Fund a crewed Moon mission", "sub": GameState.fmt_money(Actions._cost(3000000000)) + " · history, or a very public failure"})
	for cid in CAUSES.keys():
		var cd: Array = CAUSES[cid]
		out.append({"id": "bb_found", "arg": cid, "icon": cd[0], "name": "Foundation: " + cd[1], "sub": "%s · %s · given %s" % [GameState.fmt_money(100000000), cd[2], GameState.fmt_money(int(b.get("causes", {}).get(cid, 0)))]})
	if not b.get("media", false):
		out.append({"id": "bb_media", "icon": "📰", "name": "Buy a media empire", "sub": GameState.fmt_money(Actions._cost(1500000000)) + " · bad press gets buried"})
	out.append({"id": "bb_politics", "icon": "🗳️", "name": "Fund a political campaign", "sub": GameState.fmt_money(50000000) + " · buy influence"})
	out.append({"id": "bb_mega", "icon": "🏙️", "name": "Build a megaproject", "sub": GameState.fmt_money(Actions._cost(2000000000)) + " · a monument to yourself"})
	out.append({"id": "bb_offshore", "icon": "🏝️", "name": "Move money offshore", "sub": "Hidden %s · grows 4%% a year · heat" % GameState.fmt_money(int(b.get("offshore", 0)))})
	if not b.get("pledge", false):
		out.append({"id": "bb_pledge", "icon": "🤲", "name": "Take the Giving Pledge", "sub": "90% of your fortune goes to charity when you die"})
	if GameState.has_flag("island_owner") and not b.has("nation") and not (Lives.is_type("royal") and Lives.life().get("crowned", false)):
		out.append({"id": "bb_nation", "icon": "🏳️", "name": "Found a micronation", "sub": "Declare your island a kingdom and crown yourself"})
	if b.has("nation"):
		var n: Dictionary = b["nation"]
		for lid in NATION_LAWS.keys():
			if not n.get("laws", {}).get(lid, false):
				var ld: Array = NATION_LAWS[lid]
				out.append({"id": "bb_law", "arg": lid, "icon": ld[0], "name": ld[1], "sub": ld[2]})
		out.append({"id": "bb_recognize", "icon": "🇺🇳", "name": "Lobby for recognition", "sub": "%s · legitimacy %d/100" % [GameState.fmt_money(Actions._cost(150000000)), int(n["legitimacy"])]})
	return out


func billionaire_action(aid: String, arg = null) -> void:
	var p := GameState.player
	var b := _bb()
	match aid:
		"bb_payroll":
			var t: Dictionary = b["team"]
			t["payroll"] = (int(t.get("payroll", 1)) + 1) % PAYROLL.size()
			Careers._done("💰", "Payroll", "I set the %s's budget to %s." % [t["name"], PAYROLL[int(t["payroll"])].to_lower()], {})
		"bb_coach":
			var t2: Dictionary = b["team"]
			if not _pay(Actions._cost(20000000 * (int(t2.get("coach", 0)) + 1))): return
			t2["coach"] = int(t2.get("coach", 0)) + 1
			var cn := "%s %s" % [ContentDB.random_first("male", "us"), ContentDB.random_last("us")]
			Careers._done("📋", "New coach", "I hired %s, the best coach money could buy. The players look scared, which is apparently good." % cn, {"fame": 2})
		"bb_sell_team":
			var t3: Dictionary = b["team"]
			if Actions._out_of_time(): return
			p["money"] = int(p["money"]) + int(t3["value"])
			b.erase("team")
			Careers._done("🤝", "Sold", "I sold the %s for %s. The fans threw a party." % [t3["name"], GameState.fmt_money(int(t3["value"]))], {"happiness": 4})
		"bb_moon":
			if not _pay(Actions._cost(3000000000)): return
			var roll := randf()
			if roll < 0.7:
				b["moon"] = true
				GameState.counter("moon_missions")
				GameState.add_milestone(p["age"], "put people on the Moon with a private mission")
				_headline("🌕 A private mission has landed on the Moon.")
				Careers._done("🌕", "One giant leap", "My crew planted a flag on the Moon. Billions watched. My logo was on the flag.", {"fame": 25, "happiness": 20})
			elif roll < 0.9:
				Careers._done("🌕", "Scrubbed", "The lander failed its final tests. Three billion dollars, and it never left the ground.", {"happiness": -10, "stress": 12})
			else:
				_headline("🔥 A private Moon mission exploded shortly after launch. There were no survivors.")
				Careers._done("🔥", "Disaster", "The rocket exploded forty seconds after launch. Four astronauts died on live television. The families are suing, and they should.", {"happiness": -25, "karma": -10, "fame": 10, "stress": 25})
				Grit.add_scar("haunted")
		"bb_team":
			var cost := Actions._cost(800000000)
			if not _pay(cost): return
			var t: Array = TEAMS[randi() % TEAMS.size()]
			var nm := "%s %s" % [["Capital City", "Harbor", "Northgate", "Riverside", "Summit", "Bay City", "Kingsport"][randi() % 7], TEAM_NAMES[randi() % TEAM_NAMES.size()]]
			b["team"] = {"icon": t[0], "kind": t[1], "name": nm, "value": cost, "titles": 0}
			GameState.add_milestone(p["age"], "bought the %s" % nm)
			Careers._done(t[0], "Team owner", "I bought the %s, a %s, for %s." % [nm, t[1], GameState.fmt_money(cost)], {"fame": 6, "happiness": 12})
		"bb_space":
			var cost2 := 0 if Careers.past("astronaut") else Actions._cost(55000000)
			if not _pay(cost2): return
			var r := randf()
			var fail := 0.0 if Careers.past("astronaut") else 0.1
			if r < fail * 0.15:
				GameState.add_milestone(p["age"], "died when their own rocket exploded")
				_headline("🔥 A billionaire's rocket exploded on the launch pad.")
				EventEngine.kill("a rocket explosion")
				return
			elif r < fail * 0.55:
				Careers._done("🚀", "Hard landing", "Something went wrong on re-entry. The capsule hit the ocean far too fast.", {"health": -30, "stress": 20})
				Grit.scar_chance("back_injury", 0.6)
				return
			elif r < fail:
				Careers._done("🚀", "Abort", "An engine warning aborted the launch two seconds before liftoff. I was strapped in for four hours.", {"stress": 10})
				return
			b["space"] = int(b.get("space", 0)) + 1
			GameState.set_flag("been_to_space")
			GameState.counter("space_trips")
			if int(b["space"]) == 1:
				GameState.add_milestone(p["age"], "flew to space on their own rocket")
			Careers._done("🚀", "Orbit", "I floated at the window of my own spacecraft and looked down at everything I own. It all looked very small.", {"happiness": 15, "fame": 5})
		"bb_found":
			var cause: String = str(arg) if arg != null and CAUSES.has(str(arg)) else "malaria"
			if not _pay(100000000): return
			b["foundation"] = int(b.get("foundation", 0)) + 100000000
			if not b.has("causes"):
				b["causes"] = {}
			b["causes"][cause] = int(b["causes"].get(cause, 0)) + 100000000
			GameState.counter("philanthropy")
			if int(b["foundation"]) >= 1000000000 and not GameState.has_flag("big_giver"):
				GameState.set_flag("big_giver")
				GameState.add_milestone(p["age"], "gave away a billion dollars")
			var extra := ""
			var fx := {"karma": 15, "fame": 2, "happiness": 6}
			match cause:
				"malaria":
					fx["karma"] = 25
					extra = "Health workers say it saved thousands of children."
				"schools":
					GameState.apply_effects({"school": 10})
					for cid in GameState.npcs_with("child"):
						GameState.npcs[cid]["smarts"] = minf(100.0, float(GameState.npcs[cid].get("smarts", 50)) + 5.0)
					extra = "Every public school in %s got new labs and better teachers, my kids' included." % Places.region().get("city", "my city")
				"cancer":
					if randf() < 0.12 and not active("medicine"):
						begin("medicine")
						extra = "A lab we funded just announced a breakthrough."
					else:
						extra = "Progress is slow, but it's progress."
				"homeless":
					GameState.apply_effects({"heat": -3})
					extra = "Thousands of people in %s have a roof now. The streets feel safer." % Places.region().get("city", "my city")
				"climate":
					if active("climate"):
						GameState.world["events"]["climate"] = 0
						extra = "The recovery effort we funded is working. The worst is over."
					else:
						extra = "Seawalls, forests and solar farms. The next disaster will hit softer."
			Careers._done(CAUSES[cause][0], "Foundation", "My foundation put %s into %s. %s" % [GameState.fmt_money(100000000), CAUSES[cause][1].to_lower(), extra], fx)
		"bb_law":
			var n: Dictionary = b.get("nation", {})
			var lid: String = str(arg)
			if n.is_empty() or not NATION_LAWS.has(lid) or Actions._out_of_time(): return
			if not n.has("laws"):
				n["laws"] = {}
			n["laws"][lid] = true
			match lid:
				"democracy":
					Careers._done("🗳️", "Free elections", "%s held its first free election. I kept the crown and lost most of the power. The world took us more seriously overnight." % n["name"], {"karma": 10})
					n["legitimacy"] = int(n["legitimacy"]) + 20
				"tax_haven":
					Careers._done("🏦", "Tax haven", "Zero percent tax, no questions asked. Money started arriving by the planeload.", {"karma": -8, "heat": 10})
				"casino":
					Careers._done("🎰", "Casinos", "Three casinos broke ground the same week.", {})
					if Lives.is_type("royal"):
						Lives.life()["respect"] = maxf(0.0, float(Lives.life()["respect"]) - 8.0)
				"passports":
					Careers._done("🛂", "Citizenship for sale", "A passport from %s now costs $250,000. The buyers don't like questions." % n["name"], {"karma": -6})
		"bb_recognize":
			var n2: Dictionary = b.get("nation", {})
			if n2.is_empty() or not _pay(Actions._cost(150000000)): return
			var gain := randi_range(4, 14) + (8 if n2.get("laws", {}).get("democracy", false) else 0) - (6 if n2.get("laws", {}).get("tax_haven", false) else 0)
			n2["legitimacy"] = clampi(int(n2["legitimacy"]) + gain, 0, 100)
			Careers._done("🇺🇳", "Diplomacy", "Embassies, lobbyists, a very expensive gala in Geneva. Legitimacy is now %d/100." % int(n2["legitimacy"]), {"stress": 4})
		"bb_media":
			var cost3 := Actions._cost(1500000000)
			if not _pay(cost3): return
			b["media"] = true
			GameState.set_flag("press_owned")
			GameState.add_milestone(p["age"], "bought a media empire")
			Careers._done("📰", "Media mogul", "I own the newspapers now. Funny how my coverage improved overnight.", {"fame": 5, "heat": -20, "karma": -5})
		"bb_politics":
			if not _pay(50000000): return
			GameState.counter("kingmaker")
			if Careers.has_career("politician"):
				Careers._done("🗳️", "War chest", "My own money flooded the airwaves.", {"approval": 15})
			elif randf() < 0.6:
				Careers._done("🗳️", "Kingmaker", "My candidate won. Tax policy is about to get very friendly.", {"money": Actions._cost(80000000), "karma": -5})
			else:
				Careers._done("🗳️", "Wasted", "My candidate lost badly. Fifty million dollars of attack ads, gone.", {"happiness": -5})
		"bb_mega":
			var cost4 := Actions._cost(2000000000)
			if not _pay(cost4): return
			var what: String = ["a mile-high skyscraper", "a new city in the desert", "a private spaceport", "the world's largest museum", "an underwater hotel"][randi() % 5]
			b["projects"] = b.get("projects", []) + [what]
			GameState.counter("megaprojects")
			GameState.add_milestone(p["age"], "built %s" % what)
			Careers._done("🏙️", "Megaproject", "I built %s. My name is on it in letters taller than a house." % what, {"fame": 10, "happiness": 12})
		"bb_offshore":
			var move := int(maxi(0, int(p["money"])) * 0.5)
			if move <= 0:
				Lives._info("🏝️", "Offshore", "You don't have cash to move.")
				return
			p["money"] = int(p["money"]) - move
			b["offshore"] = int(b.get("offshore", 0)) + move
			GameState.set_flag("offshore")
			Careers._done("🏝️", "Offshore", "I moved %s into a web of shell companies in three island nations." % GameState.fmt_money(move), {"heat": 12, "karma": -8})
		"bb_pledge":
			b["pledge"] = true
			GameState.set_flag("giving_pledge")
			GameState.add_milestone(p["age"], "took the Giving Pledge")
			Careers._done("🤲", "The Giving Pledge", "I signed the pledge. When I'm gone, nearly everything goes to people who need it. My family has thoughts about that.", {"karma": 40})
			for cid in GameState.npcs_with("child"):
				Grit.grudge(cid, 25)
		"bb_nation":
			var isle := "the Kingdom of %s" % ["Aurelia", "Solenne", "Marisca", "Veloria", "Nerida"][randi() % 5]
			var keep_type := Lives.kind()
			Lives.setup_royal(false)
			var l := Lives.life()
			l["crowned"] = true
			l["realm"] = isle
			l["house"] = "House of " + str(p["last"])
			l["respect"] = 55
			GameState.set_flag("micronation")
			b["nation"] = {"name": isle.substr(4), "legitimacy": 15, "laws": {}}
			GameState.counter("coronations")
			GameState.add_milestone(p["age"], "founded %s and crowned themselves" % isle)
			Careers._done("🏳️", "Long live the monarch", "I declared my island the sovereign nation of %s and crowned myself. Three countries recognized it. Two were joking." % isle, {"fame": 10, "happiness": 15})
			if keep_type != "human" and keep_type != "royal":
				GameState.add_log("I gave up my old life to rule.")


func _pay(cost: int) -> bool:
	if Actions._out_of_time():
		return false
	if int(GameState.player["money"]) < cost:
		Lives._info("💸", "Not enough cash", "You need %s in cash. Sell something first." % GameState.fmt_money(cost))
		GameState.player["time_left"] = int(GameState.player["time_left"]) + 1
		return false
	GameState.player["money"] = int(GameState.player["money"]) - cost
	return true


func offshore_value() -> int:
	return int(_bb().get("offshore", 0))
