extends Node

## v0.7 — Life Gets Complicated
## Health, injuries, mental-health/recovery, home life, expanded gambling,
## Pirate Life, Space Colonist, Time Traveler, and the Life Threads bridges.
## This module only adds to the v0.6 systems; it uses the same money, NPC, save,
## event and relationship state so consequences cross menus instead of living in silos.

const CONDITIONS := {
	"viral": {"name":"a viral infection","icon":"🤒","severity":1,"chronic":false,"health":-3,"stress":2},
	"migraine": {"name":"recurring migraines","icon":"🤕","severity":1,"chronic":true,"health":-1,"stress":4},
	"asthma": {"name":"asthma","icon":"🫁","severity":2,"chronic":true,"health":-2,"stress":2},
	"anemia": {"name":"anemia","icon":"🩸","severity":1,"chronic":true,"health":-2,"stress":2},
	"thyroid": {"name":"a thyroid disorder","icon":"🦋","severity":2,"chronic":true,"health":-2,"stress":3},
	"gastritis": {"name":"gastritis","icon":"🩺","severity":1,"chronic":false,"health":-3,"stress":3},
	"mono": {"name":"mononucleosis","icon":"😷","severity":2,"chronic":false,"health":-5,"stress":3},
	"hypertension": {"name":"high blood pressure","icon":"🫀","severity":2,"chronic":true,"health":-3,"stress":2},
	"diabetes": {"name":"diabetes","icon":"🩸","severity":2,"chronic":true,"health":-3,"stress":2},
	"pneumonia": {"name":"pneumonia","icon":"🫁","severity":3,"chronic":false,"health":-8,"stress":4},
	"ulcer": {"name":"a stomach ulcer","icon":"🩺","severity":2,"chronic":false,"health":-4,"stress":4},
	"epilepsy": {"name":"epilepsy","icon":"🧠","severity":3,"chronic":true,"health":-4,"stress":4},
	"autoimmune": {"name":"an autoimmune condition","icon":"🧬","severity":3,"chronic":true,"health":-5,"stress":4},
	"heart": {"name":"heart disease","icon":"❤️","severity":4,"chronic":true,"health":-8,"stress":5},
	"cancer": {"name":"cancer","icon":"🎗️","severity":4,"chronic":true,"health":-9,"stress":7},
	"kidney": {"name":"kidney disease","icon":"🩺","severity":3,"chronic":true,"health":-6,"stress":4},
	"arthritis": {"name":"arthritis","icon":"🦴","severity":2,"chronic":true,"health":-2,"stress":3},
	"copd": {"name":"chronic lung disease","icon":"🫁","severity":4,"chronic":true,"health":-7,"stress":5},
}

const SYMPTOMS := {
	"viral":["fever","aches","fatigue"], "migraine":["head pain","light sensitivity"],
	"asthma":["shortness of breath","wheezing"], "anemia":["fatigue","dizziness"],
	"thyroid":["fatigue","temperature sensitivity"], "gastritis":["stomach pain","nausea"],
	"mono":["deep fatigue","sore throat"], "hypertension":["headaches","dizziness"],
	"diabetes":["thirst","fatigue"], "pneumonia":["cough","fever","breathlessness"],
	"ulcer":["burning stomach pain","nausea"], "epilepsy":["blackouts","confusion"],
	"autoimmune":["joint pain","unusual fatigue"], "arthritis":["joint pain","stiffness"],
	"kidney":["fatigue","swelling"], "heart":["chest discomfort","breathlessness"],
	"cancer":["unexplained fatigue","persistent pain"], "copd":["persistent cough","breathlessness"],
}

const INJURIES := {
	"sprain":{"name":"a sprained ankle","icon":"🦶","years":1,"health":-4},
	"fracture":{"name":"a broken bone","icon":"🩻","years":2,"health":-9},
	"concussion":{"name":"a concussion","icon":"🧠","years":1,"health":-8},
	"back":{"name":"a back injury","icon":"🦴","years":3,"health":-6},
	"burn":{"name":"serious burns","icon":"🔥","years":2,"health":-10},
	"knee":{"name":"a knee injury","icon":"🦵","years":3,"health":-6},
	"shoulder":{"name":"a shoulder injury","icon":"💪","years":2,"health":-5},
	"laceration":{"name":"a deep cut","icon":"🩹","years":1,"health":-6},
	"whiplash":{"name":"whiplash","icon":"🩼","years":2,"health":-5},
	"hearing":{"name":"hearing damage","icon":"👂","years":4,"health":-3},
	"eye":{"name":"an eye injury","icon":"👁️","years":3,"health":-5},
	"frostbite":{"name":"frostbite","icon":"🥶","years":2,"health":-8},
}

const MENTAL := {
	"anxiety":{"name":"anxiety","icon":"😰","stress":5,"happy":-3},
	"depression":{"name":"depression","icon":"🌧️","stress":2,"happy":-6},
	"panic":{"name":"panic symptoms","icon":"💓","stress":6,"happy":-2},
	"grief":{"name":"complicated grief","icon":"🕯️","stress":4,"happy":-5},
	"burnout":{"name":"burnout","icon":"🪫","stress":7,"happy":-4},
	"trauma":{"name":"trauma-related stress","icon":"🫂","stress":5,"happy":-4},
}

const HOME_UPGRADES := {
	"kitchen":["🍳","Renovated kitchen",18000,"Happiness at home and resale value"],
	"bath":["🛁","New bathroom",14000,"Condition and resale value"],
	"security":["🔒","Security system",9000,"Lowers burglary and break-in risk"],
	"garden":["🌻","Garden",6000,"Happiness and stress relief"],
	"solar":["☀️","Solar panels",22000,"Lower yearly household costs"],
	"office":["💻","Home office",12000,"Better work performance"],
	"nursery":["🍼","Nursery",10000,"Family happiness and fertility support"],
	"studio":["🎙️","Creative studio",15000,"Helps music, acting and social content"],
	"access":["♿","Accessibility renovation",16000,"Reduces recovery time from injuries"],
	"pool":["🏊","Pool",28000,"Fun, upkeep and resale value"],
	"workshop":["🧰","Workshop",11000,"Repairs and hands-on hobbies"],
	"guest":["🛏️","Guest room",9500,"Family visits and hosting"],
}

const CASINO_GAMES := {
	"baccarat":["🂡","Baccarat","Player, banker or tie"],
	"craps":["🎲","Craps","Pass line, don't pass, field or hard eight"],
	"videopoker":["🃏","Video poker","Jacks or Better — one five-card draw"],
	"keno":["🔢","Keno","Pick how many spots to cover"],
	"poker":["♠️","Poker tournament","Buy in and outplay a full table"],
	"sicbo":["🎲","Sic Bo","Three dice, several ways to bet"],
}

const PIRATE_RANKS := ["Deckhand","Raider","Quartermaster","Captain","Sea Legend"]
const COLONY_RANKS := ["New Arrival","Habitat Specialist","Expedition Lead","Council Member","Colony Founder"]
const PIRATE_ROLES := ["Navigator","Gunner","Carpenter","Surgeon","Cook","Quartermaster"]
const COLONY_ROLES := ["Engineer","Medic","Agronomist","Geologist","Systems Tech","Council Liaison"]
const PIRATE_UPGRADES := {"guns":["💣","Long guns",12000],"sails":["⛵","Fast sails",9000],"hull":["🪵","Reinforced hull",15000],"hold":["📦","Hidden hold",10000],"charts":["🗺️","Chart room",8000],"sickbay":["🩺","Ship sickbay",11000]}
const COLONY_UPGRADES := {"water":["💧","Water recycler",14000],"greenhouse":["🌱","Expanded greenhouse",16000],"solar":["☀️","Solar bank",18000],"medbay":["🏥","Medbay",22000],"comms":["📡","Deep-space array",26000]}
const TRAVEL_ERAS := {
	1850:{"name":"1850","desc":"Steam, telegraphs, dangerous medicine and slow travel."},
	1920:{"name":"1920","desc":"Radio, jazz, early cars and a world between wars."},
	1970:{"name":"1970","desc":"Analog tech, changing culture and the space-age hangover."},
}


func _p() -> Dictionary:
	return GameState.player


func ensure() -> void:
	if _p().is_empty():
		return
	var p := _p()
	if not p.has("medical") or not (p["medical"] is Dictionary):
		p["medical"] = {}
	var med: Dictionary = p["medical"]
	for kv in [["conditions",{}],["injuries",{}],["mental",{}],["symptoms",[]],["pending",""],["therapy_streak",0],["recovery_years",0],["medication",{}],["last_checkup",-99],["insurance","basic"]]:
		if not med.has(kv[0]):
			med[kv[0]] = kv[1].duplicate(true) if kv[1] is Dictionary or kv[1] is Array else kv[1]
	if not p.has("home") or not (p["home"] is Dictionary):
		p["home"] = {}
	var home: Dictionary = p["home"]
	for kv in [["condition",82.0],["upgrades",{}],["hoa",false],["hoa_score",55.0],["primary_property",-1],["neighbors",[]],["flips",0],["renovations",0],["years",0]]:
		if not home.has(kv[0]):
			home[kv[0]] = kv[1].duplicate(true) if kv[1] is Dictionary or kv[1] is Array else kv[1]
	if not p.has("casino") or not (p["casino"] is Dictionary):
		p["casino"] = {}
	var casino: Dictionary = p["casino"]
	for kv in [["won",0],["lost",0],["largest_win",0],["hands",0],["poker_titles",0],["largest_bet",0]]:
		if not casino.has(kv[0]):
			casino[kv[0]] = kv[1]
	LifeThreads.ensure()


func yearly() -> void:
	ensure()
	medical_yearly()
	home_yearly()


func symptoms() -> Array:
	if _p().is_empty() or not _p().has("medical"):
		return []
	return _p()["medical"].get("symptoms", [])


func any_condition() -> bool:
	if _p().is_empty() or not _p().has("medical"):
		return false
	return not (_p()["medical"].get("conditions", {}) as Dictionary).is_empty()


func any_injury() -> bool:
	if _p().is_empty() or not _p().has("medical"):
		return false
	return not (_p()["medical"].get("injuries", {}) as Dictionary).is_empty()


func has_condition(id: String) -> bool:
	ensure()
	return _p()["medical"]["conditions"].has(id)


func has_injury(id: String) -> bool:
	ensure()
	return _p()["medical"]["injuries"].has(id)


func has_mental(id: String) -> bool:
	ensure()
	return _p()["medical"]["mental"].has(id)


func home_owned() -> bool:
	return not _p().is_empty() and str(_p().get("housing", "")) == "house"


func home_has(id: String) -> bool:
	ensure()
	return _p()["home"]["upgrades"].has(id)


func era_year() -> int:
	if _p().is_empty() or Lives.kind() != "traveler":
		return GameState.START_YEAR + int(_p().get("age", 0)) if not _p().is_empty() else GameState.START_YEAR
	return int(Lives.life().get("era", 1970)) + int(_p().get("age", 0))


func era_cost_mult() -> float:
	if Lives.kind() != "traveler":
		return 1.0
	var y := era_year()
	if y < 1880: return 0.035
	if y < 1940: return 0.10
	if y < 1985: return 0.34
	if y < 2005: return 0.68
	return 1.0


func era_pay_mult() -> float:
	if Lives.kind() != "traveler":
		return 1.0
	var y := era_year()
	if y < 1880: return 0.045
	if y < 1940: return 0.12
	if y < 1985: return 0.36
	if y < 2005: return 0.70
	return 1.0


func era_item_block(tag: String, item_name: String = "") -> String:
	if Lives.kind() != "traveler":
		return ""
	var y := era_year()
	var min_years := {"phone":1995,"laptop":1985,"gaming_pc":1981,"console":1972,"webcam":1991,"vr":1995,"drone":2005,"tv":1930,"dj":1975,"scooter":1915,"motorcycle":1894,"dirtbike":1940,"scuba_gear":1943,"plane":1903,"jet":1952,"nightvision":1940,"spray":1980,"skate":1955,"karaoke":1970,"codebooks":1970}
	if min_years.has(tag) and y < int(min_years[tag]):
		return "%s does not exist in %d" % [item_name if item_name != "" else tag, y]
	return ""


func era_activity_block(id: String) -> String:
	if Lives.kind() != "traveler":
		return ""
	var y := era_year()
	var starts := {"social_media":2004,"course":1995,"games":1972,"dirtbike":1940,"sea_fish":1900,"casino":1850,"lottery":1850}
	if starts.has(id) and y < int(starts[id]):
		return "Not available in %d" % y
	return ""


func record_casino(net: int, bet: int) -> void:
	ensure()
	var c: Dictionary = _p()["casino"]
	c["hands"] = int(c.get("hands", 0)) + 1
	c["largest_bet"] = maxi(int(c.get("largest_bet", 0)), bet)
	if net > 0:
		c["won"] = int(c.get("won", 0)) + net
		c["largest_win"] = maxi(int(c.get("largest_win", 0)), net)
	elif net < 0:
		c["lost"] = int(c.get("lost", 0)) + absi(net)
	if net >= 100000:
		LifeThreads.remember("gambling", "The night luck felt personal", "I won %s gambling in one sitting. The dangerous part was how easy that made another bet feel." % GameState.fmt_money(net), "", 66, ["casino","win"])
	elif net <= -50000:
		LifeThreads.remember("gambling", "Money left on the table", "I lost %s gambling in one sitting. I remember the moment I stopped thinking in purchases and started thinking in bets." % GameState.fmt_money(-net), "", 72, ["casino","loss"])


func _row(icon: String, name: String, sub: String, act: String, arg = null, on: bool = true) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "act": "exp:" + act, "arg": arg, "on": on}


func _sub(icon: String, name: String, sub: String, key: String, on: bool = true) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "menu": "exp:" + key, "on": on}


func menu(key: String) -> Dictionary:
	ensure()
	var parts := key.split(":")
	var k: String = parts[0]
	var a1: String = parts[1] if parts.size() > 1 else ""
	match k:
		"medical": return _medical_menu()
		"mental": return _mental_menu()
		"home": return _home_menu()
		"casino": return _casino_menu()
		"casino_bet": return _casino_bet_menu(a1)
		"baccarat": return _baccarat_menu(int(a1))
		"craps": return _craps_menu(int(a1))
		"keno": return _keno_menu(int(a1))
		"sicbo": return _sicbo_menu(int(a1))
	return {"icon": "✨", "title": "More", "rows": []}


func act(key: String, arg) -> void:
	ensure()
	match key:
		"checkup": checkup(str(arg))
		"treat_condition": treat_condition(str(arg))
		"treat_injury": treat_injury(str(arg))
		"therapy": mental_action("therapy")
		"support": mental_action("support")
		"psychiatry": mental_action("psychiatry")
		"rest": mental_action("rest")
		"home_repair": home_action("repair")
		"home_upgrade": home_action("upgrade", str(arg))
		"home_hoa": home_action("hoa")
		"home_host": home_action("host")
		"home_flip": home_action("flip")
		"move_property": home_action("move_property", int(arg))
		"casino": casino_action(str(arg.get("game", "")), int(arg.get("bet", 0)), str(arg.get("pick", "")))


# ================================================================ medical + mental health

func _medical_menu() -> Dictionary:
	var med: Dictionary = _p()["medical"]
	var rows: Array = []
	var active: Dictionary = med["conditions"]
	var inj: Dictionary = med["injuries"]
	rows.append(_row("🩺", "Routine checkup", GameState.fmt_money(Actions._cost(180)) + " · can diagnose hidden problems", "checkup", "routine"))
	rows.append(_row("🏥", "See a specialist", GameState.fmt_money(Actions._cost(900)) + " · better for serious conditions", "checkup", "specialist"))
	rows.append(_row("🚑", "Emergency department", GameState.fmt_money(Actions._cost(1800)) + " · injuries and severe symptoms", "checkup", "er"))
	if not active.is_empty():
		for id in active.keys():
			var d: Dictionary = CONDITIONS.get(id, {"name": id, "icon": "🩺", "severity": 1})
			rows.append(_row(d["icon"], "Treat " + str(d["name"]), "Diagnosed · severity %d/4" % int(d.get("severity", 1)), "treat_condition", id))
	if not inj.is_empty():
		for id in inj.keys():
			var d2: Dictionary = INJURIES.get(id, {"name": id, "icon": "🩼"})
			rows.append(_row(d2["icon"], "Treat " + str(d2["name"]), "%d recovery year(s) left" % int(inj[id].get("left", 1)), "treat_injury", id))
	var info: Array = []
	if med["symptoms"].is_empty() and active.is_empty() and inj.is_empty():
		info.append("No active symptoms or diagnosed conditions.")
	else:
		if not med["symptoms"].is_empty(): info.append("Symptoms: " + ", ".join(med["symptoms"]))
		if not active.is_empty(): info.append("Diagnosed: " + ", ".join(active.keys().map(func(id): return CONDITIONS.get(id, {"name": id})["name"])))
		if not inj.is_empty(): info.append("Injuries: " + ", ".join(inj.keys().map(func(id): return INJURIES.get(id, {"name": id})["name"])))
	return {"icon": "🩺", "title": "Medical record", "rows": rows, "info": info}


func _mental_menu() -> Dictionary:
	var med: Dictionary = _p()["medical"]
	var mh: Dictionary = med["mental"]
	var rows: Array = [
		_row("🛋️", "Therapy session", GameState.fmt_money(Actions._cost(140)) + " · steady progress, not an instant fix", "therapy"),
		_row("🫂", "Support group", GameState.fmt_money(Actions._cost(40)) + " · especially helpful with habits and grief", "support"),
		_row("🧠", "Psychiatry appointment", GameState.fmt_money(Actions._cost(280)) + " · assessment and medication when appropriate", "psychiatry"),
		_row("🌿", "Take a quiet week", "2 time · lower stress and burnout", "rest"),
	]
	var info: Array = []
	if mh.is_empty():
		info.append("No active mental-health condition is on your record. Stress still matters, and asking for support is always available.")
	else:
		for id in mh.keys():
			var d: Dictionary = MENTAL.get(id, {"name": id, "icon": "🧠"})
			var r: Dictionary = mh[id]
			info.append("%s %s · recovery progress %d%%" % [d["icon"], d["name"], int(r.get("progress", 0))])
	if not Grit.active_habits().is_empty():
		info.append("Active habit support: " + ", ".join(Grit.active_habits().map(func(id): return Grit.HABITS[id]["name"])))
	return {"icon": "🧠", "title": "Mental health", "rows": rows, "info": info}


func checkup(kind: String) -> void:
	var med: Dictionary = _p()["medical"]
	var base_fee := 180 if kind == "routine" else (900 if kind == "specialist" else 1800)
	var fee := Actions._cost(base_fee)
	if not Actions._can_pay(fee, "Medical care"):
		return
	if Actions._out_of_time():
		return
	_p()["money"] = int(_p()["money"]) - fee
	med["last_checkup"] = int(_p()["age"])
	var found := ""
	if str(med.get("pending", "")) != "":
		var chance := 0.72 if kind == "routine" else (0.94 if kind == "specialist" else 0.88)
		if randf() < chance:
			found = str(med["pending"])
			med["conditions"][found] = {"years":0,"treated":0,"controlled":false,"flares":0}
			med["pending"] = ""
			med["symptoms"] = []
			GameState.counter("diagnoses")
	if found != "":
		var d: Dictionary = CONDITIONS[found]
		_p()["illness"] = d["name"]
		LifeThreads.remember("illness", "The diagnosis", "A doctor put a name to the symptoms: %s." % d["name"], "", 58 + int(d["severity"]) * 7, ["health", found])
		Actions._done(d["icon"], "Diagnosis", "The doctor diagnosed %s. We talked through treatment, uncertainty and what to watch for." % d["name"], {"stress":3})
	elif not med["injuries"].is_empty() and kind == "er":
		var iid: String = med["injuries"].keys()[0]
		med["injuries"][iid]["left"] = maxi(0, int(med["injuries"][iid]["left"]) - 1)
		Actions._done("🚑", "Emergency care", "The team treated my %s and got the immediate problem under control." % INJURIES[iid]["name"], {"health":5,"stress":-4})
	else:
		Actions._done("🩺", "Checkup", "The visit didn't uncover anything urgent. The doctor reviewed my symptoms, sleep, stress and family history.", {"health":2,"stress":-2})


func treat_condition(id: String) -> void:
	var med: Dictionary = _p()["medical"]
	if not med["conditions"].has(id):
		return
	var d: Dictionary = CONDITIONS.get(id,{})
	var sev := int(d.get("severity",1))
	var fee := Actions._cost(150 + sev * 650)
	if not Actions._can_pay(fee, "Treatment"):
		return
	if Actions._out_of_time():
		return
	_p()["money"] = int(_p()["money"]) - fee
	var c: Dictionary = med["conditions"][id]
	c["treated"] = int(c.get("treated",0)) + 1
	var chance := 0.62 - sev * 0.07 + GameState.stat("health") / 500.0
	if bool(d.get("chronic",false)):
		c["controlled"] = true
		Actions._done(d.get("icon","🩺"), "Treatment plan", "Treatment brought my %s under better control. It still needs attention over time." % d.get("name",id), {"health":4,"stress":-5})
	elif randf() < chance:
		med["conditions"].erase(id)
		_sync_primary_illness()
		GameState.counter("conditions_recovered")
		LifeThreads.remember("recovery", "Getting through %s" % d.get("name",id), "Treatment, rest and time finally cleared the condition.", "", 48, ["health","recovery"])
		Actions._done(d.get("icon","🩺"), "Recovered", "After treatment and rest, the doctor cleared my %s." % d.get("name",id), {"health":8,"happiness":6,"stress":-6})
	else:
		Actions._done(d.get("icon","🩺"), "Still recovering", "The treatment helped, but the %s hasn't fully cleared yet." % d.get("name",id), {"health":3,"stress":-2})


func treat_injury(id: String) -> void:
	var med: Dictionary = _p()["medical"]
	if not med["injuries"].has(id):
		return
	var fee := Actions._cost(300 + int(INJURIES.get(id,{}).get("health",-4)) * -180)
	if not Actions._can_pay(fee, "Injury treatment"):
		return
	if Actions._out_of_time():
		return
	_p()["money"] = int(_p()["money"]) - fee
	var x: Dictionary = med["injuries"][id]
	x["left"] = maxi(0, int(x.get("left",1)) - (2 if home_has("access") else 1))
	if int(x["left"]) <= 0:
		med["injuries"].erase(id)
		LifeThreads.remember("recovery", "My body healed", "Rehab finally closed the chapter on %s." % INJURIES[id]["name"], "", 45, ["injury","recovery"])
		Actions._done("🩹", "Rehab complete", "My %s finally healed." % INJURIES[id]["name"], {"health":6,"happiness":3})
	else:
		Actions._done("🩹", "Rehab", "Physical therapy moved my %s in the right direction." % INJURIES[id]["name"], {"health":3,"stress":-2})


func mental_action(kind: String) -> void:
	var med: Dictionary = _p()["medical"]
	var mh: Dictionary = med["mental"]
	var fee := Actions._cost({"therapy": 140, "support": 40, "psychiatry": 280, "rest": 0}[kind])
	if fee > 0 and not Actions._can_pay(fee, "Mental health care"): return
	var time := 2 if kind == "rest" else 1
	if int(_p()["time_left"]) < time:
		EventEngine.push_info("⏳", "No time left", "You need %d time point%s for this." % [time, "" if time == 1 else "s"])
		return
	GameState.spend_time(time)
	_p()["money"] = int(_p()["money"]) - fee
	match kind:
		"therapy":
			med["therapy_streak"] = int(med["therapy_streak"]) + 1
			for id in mh.keys(): mh[id]["progress"] = mini(100, int(mh[id].get("progress", 0)) + randi_range(10, 22))
			Grit.therapy_helps()
			Actions._done("🛋️", "Therapy", "I had a grounded session, worked on one problem at a time, and left with a plan for the next week.", {"stress": -10, "happiness": 4})
		"support":
			for id in mh.keys():
				mh[id]["progress"] = mini(100, int(mh[id].get("progress", 0)) + randi_range(5, 14))
			# Existing recovery logic handles active compulsive habits and can close them
			# once they have fallen far enough. Reuse it rather than only lowering a score.
			Grit.therapy_helps()
			Actions._done("🫂", "Support group", "I listened, talked when I was ready, and heard from people who understood the hard parts.", {"stress": -7, "happiness": 3})
		"psychiatry":
			for id in mh.keys():
				med["medication"][id] = true
				mh[id]["progress"] = mini(100, int(mh[id].get("progress", 0)) + randi_range(7, 16))
			Actions._done("🧠", "Psychiatry", "We reviewed symptoms, side effects and options. The plan is to track how I actually feel instead of chasing a perfect number.", {"stress": -6, "health": 1})
		"rest":
			if mh.has("burnout"): mh["burnout"]["progress"] = mini(100, int(mh["burnout"].get("progress", 0)) + 18)
			Actions._done("🌿", "A quiet week", "I cleared the calendar, slept, ate actual meals and let my nervous system settle.", {"stress": -14, "health": 2, "happiness": 3})
	_resolve_mental_recovery()


func medical_yearly() -> void:
	var p := _p()
	var med: Dictionary = p["medical"]
	var age := int(p["age"])
	if str(p.get("illness","")) != "" and med["conditions"].is_empty() and str(med.get("pending","")) == "":
		for id in CONDITIONS.keys():
			if CONDITIONS[id]["name"] == p["illness"]:
				med["conditions"][id] = {"years":0,"treated":0,"controlled":false,"flares":0}
	if str(med.get("pending","")) == "" and med["conditions"].size() < 3:
		var risk := 0.022 + maxi(0, age - 30) * 0.0012 + maxi(0.0, 55.0 - GameState.stat("health")) / 900.0 + GameState.stat("stress") / 2600.0
		if Lives.kind() == "traveler" and era_year() < 1940:
			risk *= 1.25
		if randf() < risk * Grit.d("harsh"):
			var pool: Array = ["viral","migraine","asthma","anemia","gastritis","mono"]
			if age >= 30: pool.append_array(["thyroid","hypertension","diabetes","ulcer"])
			if age >= 45: pool.append_array(["pneumonia","arthritis","kidney","autoimmune","epilepsy"])
			if age >= 60: pool.append_array(["heart","cancer","copd"])
			pool.shuffle()
			for candidate in pool:
				if not med["conditions"].has(candidate):
					med["pending"] = candidate
					med["symptoms"] = SYMPTOMS.get(candidate,["fatigue"]).duplicate()
					GameState.add_log("I started noticing %s. I should get it checked." % ", ".join(med["symptoms"]))
					break
	for id in med["conditions"].keys().duplicate():
		var d: Dictionary = CONDITIONS.get(id,{})
		var c: Dictionary = med["conditions"][id]
		c["years"] = int(c.get("years",0)) + 1
		var mult := 0.45 if c.get("controlled",false) else 1.0
		if d.get("chronic",false) and c.get("controlled",false) and randf() < 0.16:
			mult = 0.18
			GameState.add_log("My %s stayed quiet this year." % d.get("name",id))
		elif d.get("chronic",false) and randf() < 0.10 + int(d.get("severity",1)) * 0.025:
			c["flares"] = int(c.get("flares",0)) + 1
			mult *= 1.55
			GameState.add_log("My %s flared up and made ordinary days harder." % d.get("name",id))
		GameState.apply_effects({"health":float(d.get("health",-2))*mult,"stress":float(d.get("stress",2))*mult})
		if not d.get("chronic",false) and int(c["years"]) >= 2 and randf() < 0.45:
			med["conditions"].erase(id)
			GameState.add_log("My %s finally cleared." % d.get("name",id))
	for id in med["injuries"].keys().duplicate():
		var x: Dictionary = med["injuries"][id]
		x["left"] = int(x.get("left",1)) - 1
		if home_has("access"):
			x["left"] -= 1
		GameState.apply_effects({"health":-1,"stress":2})
		if id == "concussion":
			GameState.change_stat("smarts", -1)
		if int(x["left"]) <= 0:
			GameState.add_log("My %s healed." % INJURIES.get(id,{"name":id})["name"])
			med["injuries"].erase(id)
	_mental_yearly()
	_sync_primary_illness()


func add_injury(id: String, source: String = "") -> void:
	ensure()
	if not INJURIES.has(id):
		return
	var med: Dictionary = _p()["medical"]
	var d: Dictionary = INJURIES[id]
	med["injuries"][id] = {"left":int(d["years"]),"source":source,"since":int(_p()["age"])}
	GameState.apply_effects({"health":int(d["health"]),"stress":5})
	GameState.counter("injuries")
	GameState.add_log("I suffered %s%s." % [d["name"], " during " + source if source != "" else ""])
	LifeThreads.remember("injury", "The injury", "I suffered %s%s." % [d["name"], " during " + source if source != "" else ""], "", 50 + int(d["years"]) * 6, ["health",id])


func _mental_yearly() -> void:
	var p := _p()
	var med: Dictionary = p["medical"]
	var mh: Dictionary = med["mental"]
	var stress := GameState.stat("stress")
	var happy := GameState.stat("happiness")
	if stress >= 72 and not mh.has("anxiety") and randf() < 0.18: _add_mental("anxiety")
	if happy <= 28 and not mh.has("depression") and randf() < 0.14: _add_mental("depression")
	if stress >= 88 and not mh.has("panic") and randf() < 0.10: _add_mental("panic")
	if Grit.active_habits().has("workaholic") and not mh.has("burnout") and randf() < 0.22: _add_mental("burnout")
	if GameState.has_flag("lost_close_person") and not mh.has("grief") and randf() < 0.25: _add_mental("grief")
	for id in mh.keys():
		var d: Dictionary = MENTAL.get(id, {})
		var r: Dictionary = mh[id]
		var relief := 0.0
		if med["medication"].get(id, false): relief = 0.35
		GameState.apply_effects({"stress": float(d.get("stress", 3)) * (1.0 - relief), "happiness": float(d.get("happy", -2)) * (1.0 - relief)})
		if stress < 45: r["progress"] = mini(100, int(r.get("progress", 0)) + 4)
		else: r["progress"] = maxi(0, int(r.get("progress", 0)) - 2)
	_resolve_mental_recovery()


func _add_mental(id: String) -> void:
	var mh: Dictionary = _p()["medical"]["mental"]
	if mh.has(id):
		return
	mh[id] = {"progress":0,"since":int(_p()["age"]),"relapses":0}
	GameState.counter("mental_health_arcs")
	var d: Dictionary = MENTAL[id]
	GameState.add_log("I realized I was dealing with %s. I decided to treat it like health, not a character flaw." % d["name"])
	LifeThreads.remember("recovery", "A mental-health chapter", "I began dealing with %s and learning what actually helps." % d["name"], "", 58, ["mental",id])


func _resolve_mental_recovery() -> void:
	var med: Dictionary = _p()["medical"]
	var mh: Dictionary = med["mental"]
	for id in mh.keys().duplicate():
		if int(mh[id].get("progress",0)) >= 100:
			mh.erase(id)
			med["medication"].erase(id)
			med["recovery_years"] = int(med["recovery_years"]) + 1
			GameState.counter("recovery_milestones")
			GameState.add_milestone(_p()["age"], "reached a mental-health recovery milestone")
			LifeThreads.remember("recovery", "What recovery taught me", "I reached a recovery milestone with %s. I still know what helps if it returns." % MENTAL.get(id,{"name":id})["name"], "", 52, ["mental","recovery"])
			GameState.add_log("I reached a recovery milestone with my %s. I still know what helps if it returns." % MENTAL.get(id,{"name":id})["name"])


func _sync_primary_illness() -> void:
	var med: Dictionary = _p()["medical"]
	var worst := ""
	var sev := -1
	for id in med["conditions"].keys():
		var s := int(CONDITIONS.get(id, {}).get("severity", 1))
		if s > sev:
			sev = s
			worst = id
	_p()["illness"] = CONDITIONS.get(worst, {"name": ""})["name"] if worst != "" else ""


# ================================================================ home ownership

func _home_menu() -> Dictionary:
	var p := _p()
	var h: Dictionary = p["home"]
	var rows: Array = []
	if p["housing"] != "house":
		rows.append({"icon": "🏡", "name": "Buy a home", "sub": "Use Assets → Houses for the mortgage and purchase", "on": false})
	else:
		rows.append(_row("🔨", "Repair & maintain", "%s · condition %d%%" % [GameState.fmt_money(Actions._cost(3500)), int(h["condition"])], "home_repair"))
		for id in HOME_UPGRADES.keys():
			if h["upgrades"].has(id): continue
			var u: Array = HOME_UPGRADES[id]
			rows.append(_row(u[0], u[1], "%s · %s" % [GameState.fmt_money(Actions._cost(int(u[2]))), u[3]], "home_upgrade", id))
		rows.append(_row("🏘️", "Deal with the HOA", "Relationship %d/100 · fees and petty rules" % int(h["hoa_score"]), "home_hoa"))
		rows.append(_row("🍽️", "Host people at home", "Dinner, games and neighborhood gossip", "home_host"))
		if h["upgrades"].size() >= 3:
			rows.append(_row("🔁", "Flip this home", "Sell with renovation value added, then move to an apartment", "home_flip"))
	if not p.get("properties", []).is_empty():
		for i in range(p["properties"].size()):
			var pr: Dictionary = p["properties"][i]
			if int(h.get("primary_property", -1)) == i: continue
			rows.append(_row(pr.get("icon", "🏠"), "Move into " + str(pr.get("type", "property")), "Stops renting it out · value %s" % GameState.fmt_money(int(pr.get("value", 0))), "move_property", i))
	var info := ["Home condition %d%% · %d renovation%s · %d flip%s" % [int(h["condition"]), int(h["renovations"]), "" if int(h["renovations"]) == 1 else "s", int(h["flips"]), "" if int(h["flips"]) == 1 else "s"]]
	if not h["upgrades"].is_empty(): info.append("Upgrades: " + ", ".join(h["upgrades"].keys().map(func(id): return HOME_UPGRADES.get(id, ["", id])[1])))
	return {"icon": "🏡", "title": "Home", "rows": rows, "info": info}


func home_action(kind: String, arg = null) -> void:
	var p := _p()
	var h: Dictionary = p["home"]
	match kind:
		"repair":
			var fee := Actions._cost(3500)
			if not Actions._can_pay(fee, "Home repair") or Actions._out_of_time(): return
			p["money"] = int(p["money"]) - fee
			h["condition"] = minf(100.0,float(h["condition"])+28.0)
			Actions._done("🔨","Home repair","I fixed the things I had been ignoring: leaks, wiring, cracks and that one door that only closed if you kicked it.",{"happiness":3,"stress":-4})
		"upgrade":
			var id := str(arg)
			if not HOME_UPGRADES.has(id) or h["upgrades"].has(id): return
			var u: Array = HOME_UPGRADES[id]
			var fee2 := Actions._cost(int(u[2]))
			if not Actions._can_pay(fee2,u[1]) or Actions._out_of_time(): return
			p["money"] = int(p["money"]) - fee2
			h["upgrades"][id] = true
			h["renovations"] = int(h["renovations"]) + 1
			h["condition"] = minf(100.0,float(h["condition"])+8.0)
			if int(p.get("house_value",0)) > 0:
				p["house_value"] = int(int(p["house_value"]) * 1.05)
			GameState.counter("home_renovations")
			LifeThreads.remember("home", "The place I changed", "I added %s to the house. A room that used to be ordinary now belongs to this chapter of my life." % str(u[1]).to_lower(), "", 42, ["home",id])
			Actions._done(u[0],u[1],"The project is finished. For once, the contractor's final bill was close to the estimate.",{"happiness":6,"stress":-2})
		"hoa":
			if Actions._out_of_time(): return
			h["hoa"] = true
			var good := randf() < 0.72
			h["hoa_score"] = clampf(float(h["hoa_score"]) + (randi_range(5,14) if good else -randi_range(5,12)),0.0,100.0)
			Actions._done("🏘️","HOA meeting","I stayed civil and got something useful done." if good else "A ten-minute agenda became a two-hour argument about bins, hedges and parking.",{"stress":-2 if good else 6,"happiness":2 if good else -2})
		"host":
			if Actions._out_of_time(): return
			var guests := GameState.npcs_with("friend") + GameState.npcs_with("best_friend") + GameState.npcs_with("neighbor")
			guests.shuffle()
			for nid in guests.slice(0,5): GameState.change_closeness(nid,6)
			Actions._done("🍽️","At home","I opened the door, fed whoever showed up, and ended the night with dishes everywhere and people lingering in the kitchen.",{"happiness":8,"stress":-4,"money":-Actions._cost(180)})
		"flip":
			if p["housing"] != "house" or Actions._out_of_time(): return
			var base := int(p.get("house_value",0))
			if base <= 0:
				EventEngine.push_info("🏡","House flip","I don't have a sellable home selected.")
				return
			var bonus: float = 1.0 + float(h["upgrades"].size()) * 0.035 + float(h["condition"]) / 1000.0
			var sale := int(base * bonus)
			p["money"] = int(p["money"]) + sale - int(p.get("mortgage",0))
			p["house_value"] = 0
			p["mortgage"] = 0
			p["mortgage_payment"] = 0
			p["housing"] = "apartment"
			h["flips"] = int(h["flips"]) + 1
			h["upgrades"] = {}
			h["condition"] = 80.0
			GameState.counter("home_flips")
			LifeThreads.remember("home","The house I sold","I handed over the keys after changing the place room by room. The profit was real; so was the strange feeling of leaving.","",50,["home","move"])
			Actions._done("🔁","House flip","I staged the place, sold it for %s and handed over the keys." % GameState.fmt_money(sale),{"happiness":5})
		"move_property":
			var idx := int(arg)
			if idx < 0 or idx >= p["properties"].size(): return
			var pr: Dictionary = p["properties"][idx]
			var tid := str(pr.get("tenant",""))
			if tid != "" and GameState.npcs.has(tid):
				GameState.npcs[tid]["relation"] = "former_tenant"
				pr["tenant"] = ""
			p["housing"] = "house"
			h["primary_property"] = idx
			h["condition"] = float(pr.get("condition",80))
			Actions._done(pr.get("icon","🏠"),"Moved in","I made the %s my home." % str(pr.get("type","property")).to_lower(),{"happiness":7,"stress":-3})


func home_yearly() -> void:
	var p := _p()
	var h: Dictionary = p["home"]
	if p["housing"] != "house":
		return
	h["years"] = int(h["years"]) + 1
	h["condition"] = maxf(0.0,float(h["condition"]) - randf_range(2.0,6.0))
	if int(h["years"]) == 1:
		LifeThreads.remember("home","The first year here","This stopped feeling like a property and started feeling like the place where my life happens.","",48,["home"])
	if h["upgrades"].has("garden"): GameState.apply_effects({"happiness":2,"stress":-2})
	if h["upgrades"].has("solar"): p["money"] = int(p["money"]) + Actions._cost(900)
	if h["upgrades"].has("office") and GameState.has_job(): GameState.apply_effects({"job_perf":2})
	if float(h["condition"]) < 35:
		GameState.apply_effects({"health":-2,"stress":5,"happiness":-3})
		GameState.add_log("The house is getting rough: something leaks, rattles or smells damp. Repairs are overdue.")
	if h.get("hoa",false):
		var dues := Actions._cost(1200)
		p["money"] = int(p["money"]) - dues
		if randf() < 0.12:
			h["hoa_score"] = maxf(0.0,float(h["hoa_score"])-8.0)
			GameState.add_log("The HOA sent a notice about something microscopic. I paid %s in dues and fines." % GameState.fmt_money(dues))
	if h["neighbors"].is_empty() and int(p["age"]) >= 18:
		for i in range(2):
			var nid := GameState.create_npc("neighbor", {"age":maxi(18,int(p["age"])+randi_range(-15,20)),"closeness":randi_range(35,65)})
			h["neighbors"].append(nid)
	if randf() < 0.10 and not h["neighbors"].is_empty():
		var nid2: String = h["neighbors"][randi() % h["neighbors"].size()]
		if GameState.npcs.has(nid2) and GameState.npcs[nid2]["alive"]:
			var delta := randi_range(-6,9)
			GameState.change_closeness(nid2,delta)
			GameState.add_log("My neighbor %s and I had another little chapter in the long story of fences, packages and parking." % GameState.npcs[nid2]["first"])
			if absi(delta) >= 6:
				LifeThreads.remember("neighbor","Next door to %s" % GameState.npcs[nid2]["first"],"Living beside someone creates a history one tiny favor or argument at a time.",nid2,45,["home","neighbor"])


func _casino_menu() -> Dictionary:
	var rows: Array = []
	for id in CASINO_GAMES.keys():
		var d: Array = CASINO_GAMES[id]
		rows.append(_sub(d[0], d[1], d[2], "casino_bet:" + id, int(_p()["age"]) >= 18))
	var c: Dictionary = _p()["casino"]
	return {"icon": "🎰", "title": "More casino games", "rows": rows, "info": ["All wins and losses use your normal cash balance — the same money you can spend in Shopping.", "Career casino total: won %s · lost %s · biggest win %s" % [GameState.fmt_money(int(c["won"])), GameState.fmt_money(int(c["lost"])), GameState.fmt_money(int(c["largest_win"]))]]}


func _casino_bet_menu(game: String) -> Dictionary:
	var rows: Array = []
	for amt in [10, 100, 1000, 10000, 100000, 1000000]:
		if int(_p()["money"]) < amt: continue
		match game:
			"baccarat": rows.append(_sub("💵", "Bet %s" % GameState.fmt_money(amt), "Choose Player, Banker or Tie", "baccarat:%d" % amt))
			"craps": rows.append(_sub("💵", "Bet %s" % GameState.fmt_money(amt), "Choose a wager", "craps:%d" % amt))
			"keno": rows.append(_sub("💵", "Bet %s" % GameState.fmt_money(amt), "Choose 1, 5 or 10 spots", "keno:%d" % amt))
			"sicbo": rows.append(_sub("💵", "Bet %s" % GameState.fmt_money(amt), "Choose a three-dice wager", "sicbo:%d" % amt))
			_:
				rows.append(_row("💵", "Bet %s" % GameState.fmt_money(amt), "", "casino", {"game": game, "bet": amt, "pick": ""}))
	if rows.is_empty(): rows.append({"icon": "💸", "name": "You need at least $10", "sub": "", "on": false})
	return {"icon": CASINO_GAMES.get(game, ["🎲", game])[0], "title": CASINO_GAMES.get(game, ["", game.capitalize()])[1], "rows": rows}


func _baccarat_menu(amt: int) -> Dictionary:
	return {"icon": "🂡", "title": "Baccarat · " + GameState.fmt_money(amt), "rows": [
		_row("🟦", "Player", "Pays 1:1", "casino", {"game": "baccarat", "bet": amt, "pick": "player"}),
		_row("🟥", "Banker", "Pays 0.95:1", "casino", {"game": "baccarat", "bet": amt, "pick": "banker"}),
		_row("🟨", "Tie", "Pays 8:1", "casino", {"game": "baccarat", "bet": amt, "pick": "tie"}),
	]}


func _craps_menu(amt: int) -> Dictionary:
	return {"icon": "🎲", "title": "Craps · " + GameState.fmt_money(amt), "rows": [
		_row("✅", "Pass line", "Simple even-money bet", "casino", {"game": "craps", "bet": amt, "pick": "pass"}),
		_row("🚫", "Don't pass", "Bet against the shooter", "casino", {"game": "craps", "bet": amt, "pick": "dont"}),
		_row("🌾", "Field", "2,3,4,9,10,11,12 on one roll", "casino", {"game": "craps", "bet": amt, "pick": "field"}),
		_row("8️⃣", "Hard eight", "4+4 pays 9:1", "casino", {"game": "craps", "bet": amt, "pick": "hard8"}),
	]}


func _keno_menu(amt: int) -> Dictionary:
	return {"icon": "🔢", "title": "Keno · " + GameState.fmt_money(amt), "rows": [
		_row("1️⃣", "One spot", "Frequent small hits", "casino", {"game": "keno", "bet": amt, "pick": "1"}),
		_row("5️⃣", "Five spots", "Longer odds, bigger pays", "casino", {"game": "keno", "bet": amt, "pick": "5"}),
		_row("🔟", "Ten spots", "Very long odds, huge top pay", "casino", {"game": "keno", "bet": amt, "pick": "10"}),
	]}


func _sicbo_menu(amt: int) -> Dictionary:
	return {"icon": "🎲", "title": "Sic Bo · " + GameState.fmt_money(amt), "rows": [
		_row("⬇️", "Small (4–10)", "Pays 1:1 unless triple", "casino", {"game": "sicbo", "bet": amt, "pick": "small"}),
		_row("⬆️", "Big (11–17)", "Pays 1:1 unless triple", "casino", {"game": "sicbo", "bet": amt, "pick": "big"}),
		_row("🎯", "Any triple", "Pays 24:1", "casino", {"game": "sicbo", "bet": amt, "pick": "triple"}),
	]}


func casino_action(game: String, bet: int, pick: String) -> void:
	if int(_p()["age"]) < 18 or bet <= 0: return
	if int(_p()["money"]) < bet:
		EventEngine.push_info("💸","Casino","You don't have enough cash for that bet.")
		return
	if Actions._out_of_time(): return
	GameState.counter("gambles")
	Grit.habit("gambling",5 + int(log(float(maxi(10,bet))) / log(10.0)))
	var net := -bet
	var text := ""
	match game:
		"baccarat":
			var r := randf()
			var result := "banker" if r < 0.4586 else ("player" if r < 0.9048 else "tie")
			if pick == result:
				net = int(bet * (8.0 if pick == "tie" else (0.95 if pick == "banker" else 1.0)))
			text = "The shoe came down %s." % result
		"craps":
			var d1 := randi_range(1,6)
			var d2 := randi_range(1,6)
			var total := d1 + d2
			if pick == "field": net = bet if total in [3,4,9,10,11] else (bet * 2 if total in [2,12] else -bet)
			elif pick == "hard8": net = bet * 9 if d1 == 4 and d2 == 4 else -bet
			elif pick == "pass": net = bet if total in [7,11] or (total not in [2,3,12] and randf() < 0.48) else -bet
			else: net = bet if total in [2,3] or (total not in [7,11] and randf() < 0.48) else -bet
			text = "The dice showed %d + %d = %d." % [d1,d2,total]
		"videopoker":
			var r2 := randf()
			if r2 < 0.00003: net = bet * 800; text = "Royal flush. The machine lights went wild."
			elif r2 < 0.0024: net = bet * 25; text = "Four of a kind."
			elif r2 < 0.013: net = bet * 9; text = "Full house."
			elif r2 < 0.06: net = bet * 4; text = "A straight or flush paid out."
			elif r2 < 0.28: net = bet; text = "A pair of jacks or better."
			else: text = "Nothing worth holding."
		"keno":
			var spots := int(pick)
			var r3 := randf()
			if spots == 1: net = bet * 2 if r3 < 0.22 else -bet
			elif spots == 5: net = bet * 12 if r3 < 0.045 else (bet * 2 if r3 < 0.18 else -bet)
			else: net = bet * 100 if r3 < 0.004 else (bet * 8 if r3 < 0.035 else -bet)
			text = "%d-spot keno finished." % spots
		"poker":
			var skill := GameState.stat("smarts") * 0.45 + GameState.hidden("discipline") * 0.25 + randf_range(0,45)
			if GameState.has_trait("Gambler"): skill += 5
			if skill >= 90:
				net = bet * randi_range(4,10)
				_p()["casino"]["poker_titles"] = int(_p()["casino"].get("poker_titles",0)) + 1
				text = "I won the whole tournament after a long final table."
			elif skill >= 65: net = bet * 2; text = "I made a deep run and cashed."
			elif skill >= 48: net = 0; text = "I scraped back my buy-in."
			else: text = "I got outplayed and busted."
		"sicbo":
			var a := randi_range(1,6)
			var b := randi_range(1,6)
			var c := randi_range(1,6)
			var total2 := a + b + c
			var triple := a == b and b == c
			if pick == "triple": net = bet * 24 if triple else -bet
			elif pick == "small": net = bet if total2 >= 4 and total2 <= 10 and not triple else -bet
			else: net = bet if total2 >= 11 and total2 <= 17 and not triple else -bet
			text = "The dice were %d, %d and %d." % [a,b,c]
	_p()["money"] = int(_p()["money"]) + net
	record_casino(net,bet)
	if net > 0:
		GameState.counter("gamble_wins")
		if net >= 1000000: GameState.add_milestone(_p()["age"],"won %s at the casino" % GameState.fmt_money(net))
	var mood := {"happiness":5,"stress":-1} if net > 0 else ({"happiness":-5,"stress":4} if net < 0 else {"stress":1})
	var title: String = CASINO_GAMES.get(game,["🎰",game.capitalize()])[1]
	Actions._done(CASINO_GAMES.get(game,["🎰"])[0],title,"%s %s" % [text,("I won %s." % GameState.fmt_money(net)) if net > 0 else (("I lost %s." % GameState.fmt_money(-net)) if net < 0 else "I broke even.")],mood)


func setup_life(path: String, opts: Dictionary) -> void:
	var p := _p()
	match path:
		"pirate":
			var crew_ids: Array = []
			for role in PIRATE_ROLES.slice(0,4):
				var nid := GameState.create_npc("crewmate", {"age":randi_range(18,45),"closeness":randi_range(45,78),"title":role})
				crew_ids.append(nid)
			var rival := GameState.create_npc("pirate_rival", {"age":randi_range(22,50),"closeness":randi_range(5,25),"title":"Rival Captain"})
			p["life"] = {"type":"pirate","ship":"The Wayward Star","hull":80,"crew":8,"crew_ids":crew_ids,"rival":rival,"morale":65,"bounty":0,"treasure":0,"rank":0,"raids":0,"maps":0,"upgrades":{},"mutinies":0}
			p["born_year"] = int(opts.get("born_year",1715))
			GameState.add_milestone(0,"was born into a life tied to the sea")
			LifeThreads.remember("pirate","The ship that raised me","The Wayward Star, her crew and the sea became the geography of my childhood.","",58,["pirate","ship"])
		"colonist":
			var settlers: Array = []
			for role in COLONY_ROLES.slice(0,5):
				var nid2 := GameState.create_npc("colonist", {"age":randi_range(18,55),"closeness":randi_range(40,75),"title":role})
				settlers.append(nid2)
			p["life"] = {"type":"colonist","colony":"Ares Haven","oxygen":85,"rations":80,"morale":62,"influence":10,"habitat":1,"discoveries":0,"rank":0,"contact":0,"missions":0,"settlers":settlers,"upgrades":{},"signal_found":false,"crises":0}
			p["born_year"] = int(opts.get("born_year",2085))
			GameState.add_milestone(0,"was born under a dome on Mars")
			LifeThreads.remember("colonist","Home under glass","Ares Haven was never just a backdrop. Every breath depended on people keeping the habitat alive.","",60,["mars","home"])
		"traveler":
			var era := int(opts.get("era",1970))
			if not TRAVEL_ERAS.has(era): era = 1970
			p["life"] = {"type":"traveler","era":era,"home_year":2026,"paradox":0,"charge":100,"artifacts":0,"jumps":0,"cover":60,"discoveries":0}
			p["born_year"] = era
			GameState.add_milestone(0,"began a life in %d with a secret from the future" % era)
			LifeThreads.remember("traveler","A year that was never mine","I began again in %d carrying knowledge that did not belong there." % era,"",62,["time",str(era)])


func life_title() -> String:
	var l: Dictionary = Lives.life()
	match str(l.get("type", "")):
		"pirate": return PIRATE_RANKS[clampi(int(l.get("rank", 0)), 0, PIRATE_RANKS.size()-1)]
		"colonist": return COLONY_RANKS[clampi(int(l.get("rank", 0)), 0, COLONY_RANKS.size()-1)]
		"traveler": return "Time Traveler"
	return ""


func life_status() -> Array:
	var l: Dictionary = Lives.life()
	match str(l.get("type","")):
		"pirate":
			return [["🏴‍☠️ %s · %s" % [l.get("ship","Ship"),life_title()],""],["Hull",float(l.get("hull",0))],["Morale",float(l.get("morale",0))],["Bounty",float(clampi(int(l.get("bounty",0)),0,100))],["Crew %d · treasure %s · %d ship upgrade%s" % [int(l.get("crew",0)),GameState.fmt_money(int(l.get("treasure",0))),l.get("upgrades",{}).size(),"" if l.get("upgrades",{}).size()==1 else "s"],""]]
		"colonist":
			return [["🪐 %s · %s" % [l.get("colony","Mars Colony"),life_title()],""],["Oxygen",float(l.get("oxygen",0))],["Rations",float(l.get("rations",0))],["Morale",float(l.get("morale",0))],["Influence %d · discoveries %d · habitat %d" % [int(l.get("influence",0)),int(l.get("discoveries",0)),int(l.get("habitat",1))],""]]
		"traveler":
			return [["⏳ Living in %d · home timeline %d" % [era_year(),int(l.get("home_year",2026))],""],["Charge",float(l.get("charge",0))],["Paradox",float(l.get("paradox",0))],["Cover",float(l.get("cover",0))],["%d jumps · %d artifacts" % [int(l.get("jumps",0)),int(l.get("artifacts",0))],""]]
	return []


func life_actions() -> Array:
	var l: Dictionary = Lives.life()
	match str(l.get("type","")):
		"pirate":
			var out: Array = [
				{"id":"x_p_raid","icon":"⚔️","name":"Raid a merchant ship","sub":"Big loot · bounty · crew consequences"},
				{"id":"x_p_map","icon":"🗺️","name":"Hunt buried treasure","sub":"Maps %d · explore an island" % int(l.get("maps",0))},
				{"id":"x_p_recruit","icon":"🍻","name":"Recruit crew","sub":"Crew %d · adds a named crewmate" % int(l.get("crew",0))},
				{"id":"x_p_repair","icon":"🪚","name":"Repair the ship","sub":"Hull %d%%" % int(l.get("hull",0))},
				{"id":"x_p_share","icon":"💰","name":"Share the loot","sub":"Pay crew and raise loyalty"},
				{"id":"x_p_smuggle","icon":"📦","name":"Smuggle cargo","sub":"Money · heat · bounty"},
			]
			for id in PIRATE_UPGRADES.keys():
				if not l.get("upgrades",{}).has(id):
					var u: Array = PIRATE_UPGRADES[id]
					out.append({"id":"x_p_upgrade","arg":id,"icon":u[0],"name":"Fit " + str(u[1]),"sub":GameState.fmt_money(Actions._cost(int(u[2])))})
			return out
		"colonist":
			var out2: Array = [
				{"id":"x_c_shift","icon":"🧑‍🚀","name":"Work a colony shift","sub":"Oxygen, rations and influence"},
				{"id":"x_c_repair","icon":"🛠️","name":"Repair life support","sub":"Keep the habitat alive"},
				{"id":"x_c_grow","icon":"🌱","name":"Work the greenhouse","sub":"Food and morale"},
				{"id":"x_c_explore","icon":"🚙","name":"Explore Mars","sub":"Discoveries · risk · fame"},
				{"id":"x_c_council","icon":"🗳️","name":"Join colony council","sub":"Influence %d" % int(l.get("influence",0))},
				{"id":"x_c_signal","icon":"📡","name":"Study the strange signal","sub":"%s · analysis %d%%" % ["Signal found" if l.get("signal_found",false) else "No confirmed signal yet",int(l.get("contact",0))]},
			]
			for id2 in COLONY_UPGRADES.keys():
				if not l.get("upgrades",{}).has(id2):
					var u2: Array = COLONY_UPGRADES[id2]
					out2.append({"id":"x_c_upgrade","arg":id2,"icon":u2[0],"name":"Build " + str(u2[1]),"sub":GameState.fmt_money(Actions._cost(int(u2[2])))})
			return out2
		"traveler":
			var out3: Array = [
				{"id":"x_t_blend","icon":"🎩","name":"Blend into the era","sub":"Protect your cover identity"},
				{"id":"x_t_work","icon":"🧰","name":"Take an era job","sub":"Earn money at period-scale wages"},
				{"id":"x_t_artifact","icon":"🏺","name":"Document an artifact","sub":"Collect history without stealing it"},
			]
			for y in TRAVEL_ERAS.keys():
				if int(y) != int(l.get("era",1970)):
					out3.append({"id":"x_t_jump","arg":int(y),"icon":"⚡","name":"Jump to %s" % TRAVEL_ERAS[y]["name"],"sub":"25 charge · paradox risk"})
			return out3
	return []


func life_action(aid: String, arg = null) -> void:
	var p := _p()
	var l: Dictionary = Lives.life()
	match aid:
		"x_p_raid":
			if Actions._out_of_time(): return
			var bonus := 0.08 if l.get("upgrades",{}).has("guns") else 0.0
			bonus += 0.06 if l.get("upgrades",{}).has("sails") else 0.0
			var chance := 0.38 + int(l["crew"]) / 90.0 + int(l["morale"]) / 350.0 + int(l["hull"]) / 600.0 + bonus
			if randf() < chance:
				var loot := Actions._cost(randi_range(3000,30000) * (1 + int(l["rank"])))
				l["treasure"] = int(l["treasure"]) + loot
				l["raids"] = int(l["raids"]) + 1
				l["bounty"] = mini(100,int(l["bounty"]) + randi_range(6,15))
				l["morale"] = mini(100,int(l["morale"]) + 6)
				p["money"] = int(p["money"]) + loot
				GameState.counter("pirate_raids")
				LifeThreads.remember("pirate","A prize under our flag","We took cargo worth %s and every crewmate remembers the boarding differently." % GameState.fmt_money(loot),"",52,["pirate","raid"])
				Actions._done("🏴‍☠️","Prize taken","We boarded a merchant ship, took cargo worth %s and vanished over the horizon." % GameState.fmt_money(loot),{"happiness":7,"karma":-6})
			else:
				l["hull"] = maxi(0,int(l["hull"]) - randi_range(10,25))
				l["morale"] = maxi(0,int(l["morale"]) - 8)
				add_injury(["fracture","concussion","laceration"][randi()%3],"a sea raid")
				Actions._done("💥","Raid failed","The target was armed and ready. We limped away with holes in the hull.",{"stress":9,"health":-4})
		"x_p_map":
			if Actions._out_of_time(): return
			if int(l["maps"]) <= 0 and randf() < 0.55:
				l["maps"] = int(l["maps"]) + 1
				Actions._done("🗺️","A torn chart","An old sailor sold me half a map and swore the other half was eaten by a goat.",{"money":-Actions._cost(300),"happiness":3})
			else:
				l["maps"] = maxi(0,int(l["maps"]) - 1)
				var loot2 := Actions._cost(randi_range(5000,80000))
				p["money"] = int(p["money"]) + loot2
				l["treasure"] = int(l["treasure"]) + loot2
				LifeThreads.remember("pirate","The island on the chart","A ridiculous old map actually ended in buried coin worth %s." % GameState.fmt_money(loot2),"",55,["pirate","treasure"])
				Actions._done("💰","Buried treasure","The map ended at a crooked palm tree. Under it: %s in old coin and jewelry." % GameState.fmt_money(loot2),{"happiness":12})
		"x_p_recruit":
			if Actions._out_of_time(): return
			var fee := Actions._cost(300)
			if not Actions._can_pay(fee,"Recruiting crew"): return
			p["money"] = int(p["money"]) - fee
			var role: String = PIRATE_ROLES[randi() % PIRATE_ROLES.size()]
			var nid := GameState.create_npc("crewmate", {"age":randi_range(18,45),"closeness":randi_range(42,70),"title":role})
			l["crew_ids"].append(nid)
			l["crew"] = mini(40,int(l["crew"]) + randi_range(1,2))
			Actions._done("🍻","New hand","%s, a %s, signed the articles and joined the crew." % [GameState.npcs[nid]["first"],role.to_lower()],{"happiness":2})
		"x_p_repair":
			var fee2 := Actions._cost(500 + (100 - int(l["hull"])) * 55)
			if not Actions._can_pay(fee2,"Ship repair") or Actions._out_of_time(): return
			p["money"] = int(p["money"]) - fee2
			l["hull"] = mini(100,int(l["hull"]) + (45 if l.get("upgrades",{}).has("hull") else 35))
			Actions._done("🪚","Shipyard","New planks, tar, rope and a week of swearing. The hull is sound again.",{"stress":-3})
		"x_p_share":
			var share := mini(int(p["money"]),Actions._cost(maxi(500,int(l["crew"]) * 120)))
			if share <= 0: return
			p["money"] = int(p["money"]) - share
			l["morale"] = mini(100,int(l["morale"]) + 18)
			for cid in l.get("crew_ids",[]):
				if GameState.npcs.has(cid) and GameState.npcs[cid]["alive"]: GameState.change_closeness(cid,7)
			Actions._done("💰","Shares for the crew","I paid out %s by the articles. Nobody mutinied over the math." % GameState.fmt_money(share),{"happiness":4,"karma":2})
		"x_p_smuggle":
			if Actions._out_of_time(): return
			var pay := Actions._cost(randi_range(1500,12000))
			if l.get("upgrades",{}).has("hold"): pay = int(pay * 1.4)
			p["money"] = int(p["money"]) + pay
			l["bounty"] = mini(100,int(l["bounty"]) + 4)
			GameState.apply_effects({"heat":5})
			Actions._done("📦","Quiet cargo","No flags, no questions. The cargo paid %s." % GameState.fmt_money(pay),{"karma":-2})
		"x_p_upgrade":
			var uid := str(arg)
			if not PIRATE_UPGRADES.has(uid) or l.get("upgrades",{}).has(uid): return
			var u: Array = PIRATE_UPGRADES[uid]
			var price := Actions._cost(int(u[2]))
			if not Actions._can_pay(price,u[1]) or Actions._out_of_time(): return
			p["money"] = int(p["money"]) - price
			l["upgrades"][uid] = true
			if uid == "hull": l["hull"] = mini(100,int(l["hull"])+18)
			Actions._done(u[0],u[1],"The crew fitted the upgrade and immediately began arguing about who deserved credit.",{"happiness":4})
		"x_c_shift":
			if Actions._out_of_time(): return
			l["oxygen"] = mini(100,int(l["oxygen"]) + 5)
			l["rations"] = mini(100,int(l["rations"]) + 3)
			l["influence"] = mini(100,int(l["influence"]) + 3)
			Actions._done("🧑‍🚀","Colony shift","I patched seals, logged inventory and did the thousand small jobs that keep a settlement alive.",{"stress":2,"happiness":2})
		"x_c_repair":
			if Actions._out_of_time(): return
			l["oxygen"] = mini(100,int(l["oxygen"]) + (28 if l.get("upgrades",{}).has("water") else 22))
			if randf() < 0.25: l["habitat"] = mini(5,int(l["habitat"]) + 1)
			Actions._done("🛠️","Life support","I crawled through service ducts until the oxygen numbers stopped blinking red.",{"stress":-2,"smarts":1})
		"x_c_grow":
			if Actions._out_of_time(): return
			var food := 24 if l.get("upgrades",{}).has("greenhouse") else 18
			l["rations"] = mini(100,int(l["rations"]) + food)
			l["morale"] = mini(100,int(l["morale"]) + 5)
			Actions._done("🌱","Greenhouse","Fresh greens under pink grow lights tasted like luxury.",{"health":2,"happiness":5})
		"x_c_explore":
			if Actions._out_of_time(): return
			l["missions"] = int(l["missions"]) + 1
			if randf() < 0.76:
				l["discoveries"] = int(l["discoveries"]) + 1
				l["influence"] = mini(100,int(l["influence"]) + 6)
				Actions._done("🪨","Mars fieldwork","I brought back samples from a canyon nobody in the colony had walked before.",{"smarts":2,"fame":2,"happiness":5})
			else:
				l["oxygen"] = maxi(0,int(l["oxygen"]) - 15)
				add_injury(["sprain","fracture","concussion"][randi()%3],"a Mars expedition")
				Actions._done("🌪️","Dust storm","The horizon vanished. I made it back by following the rover tracks one meter at a time.",{"stress":10})
		"x_c_council":
			if Actions._out_of_time(): return
			var gain := randi_range(-3,9)
			l["influence"] = clampi(int(l["influence"]) + gain,0,100)
			l["morale"] = clampi(int(l["morale"]) + randi_range(-4,6),0,100)
			Actions._done("🗳️","Colony council","We argued about air, water, work rotations and who gets a window. Somehow, that counts as government.",{"stress":2,"happiness":1})
		"x_c_signal":
			if not l.get("signal_found",false):
				EventEngine.push_info("📡","Only noise","The array has not found a stable anomaly yet. Exploration, better communications and time may change that.")
				return
			if Actions._out_of_time(): return
			l["contact"] = mini(95,int(l["contact"]) + randi_range(5,12))
			GameState.counter("signal_work")
			Actions._done("📡","The signal","Another night of pattern matching. Something in the noise keeps repeating back at us.",{"smarts":2,"stress":2})
		"x_c_upgrade":
			var cuid := str(arg)
			if not COLONY_UPGRADES.has(cuid) or l.get("upgrades",{}).has(cuid): return
			var cu: Array = COLONY_UPGRADES[cuid]
			var cp := Actions._cost(int(cu[2]))
			if not Actions._can_pay(cp,cu[1]) or Actions._out_of_time(): return
			p["money"] = int(p["money"]) - cp
			l["upgrades"][cuid] = true
			l["influence"] = mini(100,int(l["influence"])+4)
			Actions._done(cu[0],cu[1],"The colony brought the new system online. Everyone felt the difference by morning.",{"happiness":4,"smarts":1})
		"x_t_blend":
			if Actions._out_of_time(): return
			l["cover"] = mini(100,int(l["cover"]) + 15)
			l["paradox"] = maxi(0,int(l["paradox"]) - 4)
			Actions._done("🎩","Period correct","I changed my slang, clothes and story until people stopped asking why I talked like a documentary narrator.",{"stress":-3})
		"x_t_work":
			if Actions._out_of_time(): return
			var now := era_year()
			var pay := maxi(1,int(randi_range(12000,48000) * era_pay_mult()))
			p["money"] = int(p["money"]) + pay
			l["cover"] = mini(100,int(l["cover"]) + 3)
			Actions._done("🧰","Era work","I took work that fit %d and earned %s without explaining what a spreadsheet is." % [now,GameState.fmt_money(pay)],{"happiness":2})
		"x_t_artifact":
			if Actions._out_of_time(): return
			l["artifacts"] = int(l["artifacts"]) + 1
			if randf() < 0.2: l["paradox"] = mini(100,int(l["paradox"]) + 8)
			LifeThreads.remember("traveler","An ordinary object from %d" % era_year(),"I documented something that would become historically interesting without taking it away from its own time.","",42,["time","artifact"])
			Actions._done("🏺","Artifact","I found something ordinary to them and priceless to a future museum. I documented it without stealing anyone's story.",{"smarts":2,"happiness":4})
		"x_t_jump":
			var y := int(arg)
			if int(l["charge"]) < 25:
				EventEngine.push_info("🔋","Not enough charge","A jump needs 25 charge.")
				return
			l["charge"] = int(l["charge"]) - 25
			l["jumps"] = int(l["jumps"]) + 1
			l["paradox"] = mini(100,int(l["paradox"]) + randi_range(4,12))
			l["era"] = y
			p["born_year"] = y
			GameState.job_listings.clear()
			LifeThreads.remember("traveler","The jump to %d" % y,"The room folded and the calendar changed while I stayed the same age.","",55,["time","jump"])
			Actions._done("⚡","Time jump","The machine screamed, the room folded, and the calendar now says %d." % (y + int(p["age"])),{"stress":5,"happiness":5})


func life_yearly() -> void:
	var p := _p()
	var l: Dictionary = Lives.life()
	match str(l.get("type","")):
		"pirate":
			l["hull"] = maxi(0,int(l["hull"]) - randi_range(2,7))
			l["morale"] = clampi(int(l["morale"]) + randi_range(-5,3),0,100)
			var pay := Actions._cost(maxi(200,int(l["crew"]) * 80))
			p["money"] = int(p["money"]) - pay
			var live_crew: Array = []
			for cid in l.get("crew_ids",[]):
				if GameState.npcs.has(cid) and GameState.npcs[cid]["alive"]: live_crew.append(cid)
			if int(l["morale"]) < 24 and not live_crew.is_empty() and randf() < 0.28:
				var mut: String = live_crew[randi() % live_crew.size()]
				l["mutinies"] = int(l.get("mutinies",0)) + 1
				GameState.change_closeness(mut,-18)
				LifeThreads.remember("pirate","A mutiny almost began","%s challenged my command when morale collapsed." % GameState.npcs[mut]["first"],mut,72,["pirate","mutiny"])
				EventEngine.push_decision({"id":"_pirate_mutiny_%d" % int(p["age"]),"icon":"⚔️","title":"Murmurs of mutiny","text":"%s has several sailors listening. They say the shares are bad and the captain is worse." % GameState.npcs[mut]["first"],"choices":[{"label":"Pay the crew now","outcomes":[{"weight":2,"text":"Coin cooled the argument before steel came out.","effects":{"money":-Actions._cost(1800),"happiness":2}},{"weight":1,"text":"They took the money and kept the resentment.","effects":{"money":-Actions._cost(1800),"stress":3}}]},{"label":"Face them down","outcomes":[{"weight":2,"text":"Nobody wanted to be first to draw a blade.","effects":{"stress":3,"happiness":2}},{"weight":1,"text":"The deck erupted into a brawl before the challenge broke.","effects":{"health":-8,"stress":8}}]},{"label":"Promise the next prize","outcomes":[{"weight":2,"text":"They gave me one more voyage to prove it.","effects":{"stress":2}},{"weight":1,"text":"The promise sounded thin even to me.","effects":{"happiness":-4,"stress":5}}]}]}, {"them":mut})
			if int(l["bounty"]) >= 55 and randf() < float(l["bounty"]) / 260.0:
				l["hull"] = maxi(0,int(l["hull"]) - (7 if l.get("upgrades",{}).has("sails") else 12))
				GameState.add_log("A navy patrol found us. We escaped, but the ship took damage.")
			var thresholds := [2,6,12,20]
			if int(l["rank"]) < 4 and int(l["raids"]) >= thresholds[int(l["rank"])]:
				l["rank"] = int(l["rank"]) + 1
				GameState.add_log("The crew started calling me %s." % life_title())
			if int(l["hull"]) <= 0:
				GameState.change_stat("health",-35)
				GameState.add_log("The ship is barely afloat. One more storm could finish us.")
		"colonist":
			var oxygen_loss := randi_range(7,12) - (2 if l.get("upgrades",{}).has("solar") else 0)
			var food_loss := randi_range(6,11) - (2 if l.get("upgrades",{}).has("greenhouse") else 0)
			l["oxygen"] = maxi(0,int(l["oxygen"]) - maxi(3,oxygen_loss))
			l["rations"] = maxi(0,int(l["rations"]) - maxi(3,food_loss))
			l["morale"] = clampi(int(l["morale"]) + randi_range(-5,3),0,100)
			if int(l["oxygen"]) < 25:
				GameState.apply_effects({"health":-10,"stress":10})
				GameState.add_log("Oxygen rationing made every corridor feel smaller.")
			if int(l["rations"]) < 20:
				GameState.apply_effects({"health":-5,"happiness":-6})
				GameState.add_log("The colony is stretching food stores. Everyone notices.")
			var thresholds2 := [20,40,65,85]
			if int(l["rank"]) < 4 and int(l["influence"]) >= thresholds2[int(l["rank"])]:
				l["rank"] = int(l["rank"]) + 1
				GameState.add_log("The colony promoted me to %s." % life_title())
			if not l.get("signal_found",false) and int(l["discoveries"]) >= 4:
				var signal_chance := 0.006 + (0.006 if l.get("upgrades",{}).has("comms") else 0.0)
				if randf() < signal_chance:
					l["signal_found"] = true
					LifeThreads.remember("colonist","The anomaly in the static","The deep-space array found a repeating pattern nobody could dismiss as ordinary noise.","",78,["mars","signal"])
					EventEngine.push_info("📡","A repeating anomaly","The same pattern returned three nights in a row. It is not first contact—not yet—but the colony has something real to study.")
			if l.get("signal_found",false) and int(l.get("contact",0)) >= 80 and not GameState.has_flag("first_contact") and randf() < 0.008:
				GameState.set_flag("first_contact")
				l["contact"] = 100
				GameState.add_milestone(p["age"],"helped confirm first contact")
				LifeThreads.remember("colonist","The answer","The signal answered. The room went silent because every person in it understood the same impossible thing.","",95,["mars","first_contact"])
				EventEngine.push_info("👽","First contact","The reply matched the structure of the colony's transmission. Not noise. Not us. Something answered.")
		"traveler":
			l["charge"] = mini(100,int(l["charge"]) + 12)
			l["paradox"] = maxi(0,int(l["paradox"]) - 3)
			l["cover"] = maxi(0,int(l["cover"]) - randi_range(1,5))
			if int(l["paradox"]) >= 65 and randf() < 0.2:
				GameState.apply_effects({"stress":12,"happiness":-5})
				GameState.add_log("Two versions of the same memory tried to exist at once. I spent days sorting out which one was mine.")
			if int(l["cover"]) < 20 and randf() < 0.2:
				l["paradox"] = mini(100,int(l["paradox"]) + 10)
				GameState.add_log("Someone noticed I know things I shouldn't. My cover story is fraying.")


func life_death_check() -> String:
	var l: Dictionary = Lives.life()
	if str(l.get("type", "")) == "colonist" and int(l.get("oxygen", 100)) <= 0:
		return "life-support failure on Mars"
	if str(l.get("type", "")) == "pirate" and int(l.get("hull", 100)) <= 0 and randf() < 0.25:
		return "a shipwreck"
	return "__natural"


func era_job_block(jd: Dictionary) -> String:
	if Lives.kind() != "traveler": return ""
	var year := era_year()
	if jd.has("era_min") and year < int(jd["era_min"]): return "Not available until %d" % int(jd["era_min"])
	if jd.has("era_max") and year > int(jd["era_max"]): return "No longer common after %d" % int(jd["era_max"])
	var field := str(jd.get("field",""))
	var jid := str(jd.get("id",""))
	if year < 1870 and field in ["Tech","Aviation","Media","Public Safety"]: return "That field does not exist in this form yet"
	if year < 1903 and field == "Aviation": return "Powered aviation has not arrived yet"
	if year < 1920 and field == "Media" and (jid.contains("radio") or jid.contains("tv")): return "That medium belongs to a later era"
	if year < 1950 and field == "Tech": return "Modern computing careers do not exist yet"
	if year < 1975 and (jid.contains("software") or jid.contains("developer") or jid.contains("program")): return "That job belongs to a later era"
	return ""


