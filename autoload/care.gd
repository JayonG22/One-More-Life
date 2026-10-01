extends Node

## CARE — getting help is a process, and sometimes the process is the illness.
##
## Until now a doctor was a menu item that cost money and either found the
## problem or did not. Real care has stages: a GP who may take you seriously or
## may not, a referral, a waiting list whose length depends on what kind of
## country you live in, a specialist who may be right, a second opinion when
## they are not, and then the long part — the medication you have to keep taking,
## the physio you have to keep doing, and the eyes and teeth that nobody thinks
## about until they fail.
##
## It sits on top of the existing medical record (Expansion): the same conditions
## and injuries, reached by a more honest route.

const SYSTEMS := {
	"free": {"gp": 0, "spec": 0, "wait": [0, 2], "label": "a public health service"},
	"public": {"gp": 35, "spec": 250, "wait": [0, 2], "label": "a mixed system"},
	"private": {"gp": 140, "spec": 1100, "wait": [0, 0], "label": "a private system"},
}


func _p() -> Dictionary:
	return GameState.player


func st() -> Dictionary:
	var p := _p()
	if p.is_empty():
		return {}
	if not p.has("medical") or not (p["medical"] is Dictionary) or not (p["medical"] as Dictionary).has("conditions"):
		Expansion.ensure()
	if not p.has("care") or not (p["care"] is Dictionary):
		p["care"] = {"referral": {}, "misdx": "", "second": 0, "meds": {}, "vision": 100.0, "aid": "none", "teeth": 100.0, "dentist_age": -99, "crowns": 0, "dentures": false, "gp": 0, "waited": 0, "physio": 0, "hearing": 100.0, "hearing_aid": false}
	return p["care"]


func system() -> String:
	var h := str(Places.law("healthcare"))
	return h if SYSTEMS.has(h) else "private"


func fee(kind: String) -> int:
	return Actions._cost(int(SYSTEMS[system()][kind]))


# ------------------------------------------------------------------ the pathway

func gp_visit() -> void:
	var s := st()
	var med: Dictionary = _p()["medical"]
	if not Actions._can_pay(fee("gp"), "GP") or Actions._out_of_time():
		return
	_p()["money"] = int(_p()["money"]) - fee("gp")
	s["gp"] = int(s["gp"]) + 1
	var pending := str(med.get("pending", ""))
	if pending == "":
		if not s["referral"].is_empty():
			Actions._done("🩺", "GP", "I asked after my referral. The receptionist said it was 'in the system'.", {"stress": 1})
		else:
			Actions._done("🩺", "GP", "The GP listened, checked my blood pressure and told me to keep doing whatever I was doing. It was five minutes and felt like fifty.", {"stress": -2, "health": 1})
		return
	# a symptom is on the table
	var r := randf()
	var dismiss := 0.22 - float(mini(int(s["gp"]), 4)) * 0.04
	if Expansion.CONDITIONS.has(pending) and int(Expansion.CONDITIONS[pending]["severity"]) >= 3:
		dismiss += 0.08
	if r < dismiss:
		GameState.add_log("The GP thought it was stress. It might have been, but I went home unconvinced.")
		Actions._done("🩺", "GP", "The GP said it was probably stress, and asked whether I had been sleeping. I had not, but that was not the point.", {"stress": 3, "happiness": -2})
		return
	if r < dismiss + 0.35 and Expansion.CONDITIONS.has(pending) and int(Expansion.CONDITIONS[pending]["severity"]) <= 1:
		_diagnose(pending, false)
		return
	refer()


func refer() -> void:
	var s := st()
	var med: Dictionary = _p()["medical"]
	if str(med.get("pending", "")) == "":
		return
	var w: Array = SYSTEMS[system()]["wait"]
	var wait := randi_range(int(w[0]), int(w[1]))
	s["referral"] = {"for": str(med["pending"]), "wait": wait, "made": int(_p()["age"])}
	if wait <= 0:
		GameState.add_log("The GP referred me and there was a slot the following week.")
		_specialist(false)
	else:
		GameState.add_log("The GP referred me to a specialist. The wait is %d year%s." % [wait, "" if wait == 1 else "s"])
		Actions._done("📋", "Referral", "I was put on a waiting list. A letter will arrive, eventually, in an envelope I'll be afraid of.", {"stress": 4})


func pay_to_skip() -> void:
	var s := st()
	if s["referral"].is_empty():
		return
	var priv := Actions._cost(int(SYSTEMS["private"]["spec"]))
	if not Actions._can_pay(priv, "Private specialist"):
		return
	_p()["money"] = int(_p()["money"]) - priv
	_specialist(true)


func _specialist(paid: bool) -> void:
	var s := st()
	var med: Dictionary = _p()["medical"]
	var pending := str(med.get("pending", ""))
	s["referral"] = {}
	if pending == "":
		EventEngine.push_info("🏥", "Specialist", "By the time my appointment came round the symptoms had gone. The specialist found nothing, and I felt a little fraudulent.", {"stress": -2})
		return
	if not paid and system() != "private":
		s["waited"] = int(s["waited"]) + 1
	if randf() < 0.08 and int(Expansion.CONDITIONS.get(pending, {"severity": 1})["severity"]) >= 2:
		# the wrong answer, delivered with confidence
		var wrong := "viral" if pending != "viral" else "migraine"
		s["misdx"] = wrong
		med["conditions"][wrong] = {"years": 0, "treated": 0, "controlled": false, "flares": 0}
		med["symptoms"] = []
		med["pending"] = ""
		GameState.add_log("I was told it was %s. I took the tablets and the symptoms stayed." % str(Expansion.CONDITIONS[wrong]["name"]))
		EventEngine.push_info("🏥", "A diagnosis", "The specialist was sure it was %s, and gave me a leaflet. I wanted to believe them. A second opinion might be worth the money." % str(Expansion.CONDITIONS[wrong]["name"]), {"stress": 2})
		s["hidden"] = pending
		return
	_diagnose(pending, true)


func _diagnose(id: String, specialist: bool) -> void:
	var med: Dictionary = _p()["medical"]
	var d: Dictionary = Expansion.CONDITIONS[id]
	med["conditions"][id] = {"years": 0, "treated": 0, "controlled": false, "flares": 0}
	med["pending"] = ""
	med["symptoms"] = []
	_p()["illness"] = d["name"]
	GameState.counter("diagnoses")
	LifeThreads.remember("illness", "The diagnosis", "A doctor put a name to the symptoms: %s." % d["name"], "", 58 + int(d["severity"]) * 7, ["health", id])
	Actions._done(d["icon"], "Diagnosis", "%s %s. There was a leaflet, a pause, and a plan." % ["The specialist confirmed" if specialist else "The GP thought it was", d["name"]], {"stress": 3 + int(d["severity"])})


func second_opinion() -> void:
	var s := st()
	var med: Dictionary = _p()["medical"]
	var cost := Actions._cost(int(SYSTEMS["private"]["spec"]) / 2 + 200)
	if str(s.get("misdx", "")) == "" and med["conditions"].is_empty():
		return
	if not Actions._can_pay(cost, "Second opinion") or Actions._out_of_time():
		return
	_p()["money"] = int(_p()["money"]) - cost
	s["second"] = int(s["second"]) + 1
	if str(s.get("misdx", "")) != "":
		var wrong := str(s["misdx"])
		var truth := str(s.get("hidden", ""))
		med["conditions"].erase(wrong)
		if truth != "" and Expansion.CONDITIONS.has(truth):
			med["conditions"][truth] = {"years": 0, "treated": 0, "controlled": false, "flares": 0}
			_p()["illness"] = Expansion.CONDITIONS[truth]["name"]
		s["misdx"] = ""
		s["hidden"] = ""
		GameState.add_log("A second doctor looked at the same scans and said something different. They were right.")
		EventEngine.push_info("🩺", "Second opinion", "The second doctor looked at the notes and then at me and said 'I'm not sure that was right.' It wasn't. Now there is a plan that fits.", {"stress": -2, "health": 3})
	else:
		EventEngine.push_info("🩺", "Second opinion", "The second doctor agreed with the first, which was both a relief and a disappointment.", {"stress": -2})


# ------------------------------------------------------------------ the long part

func meds_cost() -> int:
	var total := 0
	for id in st().get("meds", {}).keys():
		if bool(st()["meds"][id]):
			total += Actions._cost(240 * int(Expansion.CONDITIONS.get(id, {"severity": 1})["severity"])) if system() != "free" else Actions._cost(60)
	return total


func toggle_meds(id: String) -> void:
	var s := st()
	s["meds"][id] = not bool(s["meds"].get(id, false))
	GameState.add_log("I %s taking medication for my %s." % ["started" if s["meds"][id] else "stopped", str(Expansion.CONDITIONS.get(id, {"name": id})["name"])])


func physio() -> void:
	var med: Dictionary = _p()["medical"]
	if med["injuries"].is_empty():
		return
	var cost := Actions._cost(120)
	if system() == "free":
		cost = 0
	if not Actions._can_pay(cost, "Physiotherapy") or Actions._out_of_time():
		return
	_p()["money"] = int(_p()["money"]) - cost
	var id: String = med["injuries"].keys()[0]
	med["injuries"][id]["left"] = maxi(0, int(med["injuries"][id]["left"]) - 1)
	st()["physio"] = int(st()["physio"]) + 1
	Actions._done("🤸", "Physiotherapy", "I did the exercises on the sheet every morning for a month. They were dull, and they worked.", {"health": 2, "stress": -1})


func test_eyes() -> void:
	var s := st()
	var cost := Actions._cost(0 if system() == "free" else 55)
	if not Actions._can_pay(cost, "Eye test"):
		return
	_p()["money"] = int(_p()["money"]) - cost
	EventEngine.push_info("👓", "Eye test", "The optician clicked lenses into a frame. 'Better, or worse?' I'm now told my eyes are %s." % ("fine" if vision() >= 75 else ("starting to slip" if vision() >= 50 else "quite bad")), {})


func buy_aid(kind: String) -> void:
	var s := st()
	var price: int = {"glasses": 160, "contacts": 320, "laser": 2900}[kind]
	var cost := Actions._cost(price)
	if not Actions._can_pay(cost, "Eyes"):
		return
	_p()["money"] = int(_p()["money"]) - cost
	s["aid"] = kind
	if kind == "laser":
		s["vision"] = minf(100.0, float(s["vision"]) + 28.0)
	Actions._done("👓", "New eyes", {"glasses": "The frames made me look like somebody who knows things.", "contacts": "They went in on the fourth try. I saw a leaf on a tree from across the street.", "laser": "The surgeon talked the whole time, and then I could read the clock across the room. It felt like cheating."}[kind], {"happiness": 4})


func vision() -> float:
	var s := st()
	var aid: float = {"none": 0.0, "glasses": 35.0, "contacts": 40.0, "laser": 0.0}.get(str(s["aid"]), 0.0)
	return clampf(float(s["vision"]) + float(aid), 0.0, 100.0)


func dentist() -> void:
	var s := st()
	var cost := Actions._cost(0 if system() == "free" else 85)
	if not Actions._can_pay(cost, "Dentist") or Actions._out_of_time():
		return
	_p()["money"] = int(_p()["money"]) - cost
	s["dentist_age"] = int(_p()["age"])
	var before := float(s["teeth"])
	s["teeth"] = minf(100.0, float(s["teeth"]) + 14.0)
	Actions._done("🦷", "Dentist", "The hygienist scolded me gently about flossing. She was right. %s" % ("There was a small filling." if before < 70.0 else "Nothing needed doing, which felt like a prize."), {"stress": 1, "happiness": 1})


func crown() -> void:
	var s := st()
	var cost := Actions._cost(900 if system() != "free" else 250)
	if float(s["teeth"]) > 55.0 or not Actions._can_pay(cost, "Dental work"):
		return
	_p()["money"] = int(_p()["money"]) - cost
	s["teeth"] = minf(100.0, float(s["teeth"]) + 30.0)
	s["crowns"] = int(s["crowns"]) + 1
	Actions._done("🦷", "Dental work", "A crown, three appointments and a long-running quarrel with the receptionist about the bill.", {"health": 1, "stress": 2})


func yearly() -> void:
	var s := st()
	if s.is_empty() or GameState.in_prison():
		return
	var p := _p()
	var age := int(p["age"])
	# the waiting list moves, slowly
	if not s["referral"].is_empty():
		s["referral"]["wait"] = int(s["referral"]["wait"]) - 1
		if int(s["referral"]["wait"]) <= 0:
			_specialist(false)
		else:
			GameState.apply_effects({"stress": 3})
			GameState.add_log("Still waiting for the specialist. The symptoms haven't gone away.")
	# medication: pay for it, benefit from it, or pay for not taking it
	var med: Dictionary = p["medical"]
	for id in med["conditions"].keys():
		var d: Dictionary = Expansion.CONDITIONS.get(id, {})
		if not bool(d.get("chronic", false)):
			continue
		if bool(s["meds"].get(id, false)):
			GameState.apply_effects({"health": absf(float(d.get("health", -2))) * 0.55})
			if randf() < 0.12:
				GameState.add_log("The medication has side effects. I've decided they're worth it, most days.")
				GameState.apply_effects({"happiness": -1})
		elif int(med["conditions"][id].get("years", 0)) >= 2:
			GameState.apply_effects({"health": -1.2})
			if randf() < 0.12:
				GameState.add_log("I've let the prescription lapse for my %s, and my body noticed before I did." % str(d.get("name", id)))
	p["money"] = int(p["money"]) - meds_cost()
	# eyes, ears and teeth go quietly
	var drift := 0.25 if age < 40 else (1.0 if age < 60 else 1.8)
	s["vision"] = maxf(0.0, float(s["vision"]) - drift * (0.5 if str(s["aid"]) == "laser" else 1.0))
	var hd := 0.0 if age < 45 else (0.9 if age < 65 else 1.8)
	s["hearing"] = maxf(0.0, float(s["hearing"]) - hd)
	var td := 1.8 + (1.4 if str(Keeping.st().get("diet", "mixed")) == "takeaway" else 0.0) - (0.8 if str(Keeping.st().get("diet", "mixed")) == "cook" else 0.0)
	if age - int(s["dentist_age"]) > 4:
		td += 1.6
	s["teeth"] = clampf(float(s["teeth"]) - td, 0.0, 100.0)
	if vision() < 50.0 and age >= 10:
		GameState.apply_effects({"happiness": -1.0, "stress": 1.0})
		if vision() < 30.0:
			GameState.apply_effects({"health": -0.8})
			if randf() < 0.2:
				GameState.add_log("I can't read menus any more without help, and I've started pretending I'm not hungry.")
	if float(s["teeth"]) < 40.0:
		GameState.apply_effects({"happiness": -1.0})
		if randf() < 0.3:
			var bill := Actions._cost(240)
			p["money"] = int(p["money"]) - bill
			GameState.add_log("A tooth gave up in the night. The emergency appointment cost %s." % GameState.fmt_money(bill))
			GameState.apply_effects({"stress": 3, "happiness": -2})
	if float(s["teeth"]) < 18.0 and not bool(s["dentures"]) and age >= 50:
		GameState.change_stat("looks", -2)
		GameState.add_log("I lost enough teeth that I started smiling with my mouth closed.")
	if float(s["hearing"]) < 55.0 and not bool(s["hearing_aid"]) and age >= 55:
		GameState.apply_effects({"happiness": -1.0})
		if randf() < 0.2:
			GameState.add_log("I've started saying 'pardon' more than I'd like, and my family have started noticing.")


func hearing_aid() -> void:
	var s := st()
	var cost := Actions._cost(1800 if system() != "free" else 300)
	if bool(s["hearing_aid"]) or not Actions._can_pay(cost, "Hearing aid"):
		return
	_p()["money"] = int(_p()["money"]) - cost
	s["hearing_aid"] = true
	s["hearing"] = minf(100.0, float(s["hearing"]) + 30.0)
	Actions._done("👂", "Hearing", "The first morning I heard the birds again, and cried over the kettle.", {"happiness": 6})


func dentures() -> void:
	var s := st()
	var cost := Actions._cost(1600 if system() != "free" else 400)
	if bool(s["dentures"]) or not Actions._can_pay(cost, "Dentures"):
		return
	_p()["money"] = int(_p()["money"]) - cost
	s["dentures"] = true
	s["teeth"] = maxf(float(s["teeth"]), 70.0)
	Actions._done("🦷", "Dentures", "They felt like a stranger's in my mouth for a month. By spring I'd forgotten.", {"happiness": 3, "looks": 1})


# ------------------------------------------------------------------ menu

func _row(icon: String, name: String, sub: String, act: String, arg = null, on: bool = true) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "act": "real:" + act, "arg": arg, "on": on}


func menu() -> Dictionary:
	var s := st()
	var med: Dictionary = _p()["medical"]
	var rows: Array = []
	var info: Array = []
	info.append("You live in %s. GP visits cost %s here; specialists %s." % [str(SYSTEMS[system()]["label"]), GameState.fmt_money(fee("gp")), GameState.fmt_money(fee("spec"))])
	if not s["referral"].is_empty():
		info.append("On a waiting list: %d year%s to go." % [int(s["referral"]["wait"]), "" if int(s["referral"]["wait"]) == 1 else "s"])
	if str(s.get("misdx", "")) != "":
		info.append("Something about your diagnosis doesn't feel right.")
	info.append("Eyes %d%%  ·  teeth %d%%  ·  hearing %d%%" % [int(vision()), int(s["teeth"]), int(s["hearing"])])
	rows.append(_row("@pulse", "See your GP", "%s · describe a symptom, ask for a referral" % GameState.fmt_money(fee("gp")), "gp"))
	rows.append(_row("@hospital", "Pay to see a specialist privately", "%s · skips the waiting list" % GameState.fmt_money(Actions._cost(int(SYSTEMS["private"]["spec"]))), "skip", null, not s["referral"].is_empty()))
	rows.append(_row("@handshake", "Get a second opinion", "%s · when something doesn't add up" % GameState.fmt_money(Actions._cost(int(SYSTEMS["private"]["spec"]) / 2 + 200)), "second", null, str(s.get("misdx", "")) != "" or not med["conditions"].is_empty()))
	for id in med["conditions"].keys():
		var d: Dictionary = Expansion.CONDITIONS.get(id, {"name": id, "chronic": false})
		if bool(d.get("chronic", false)):
			var on: bool = bool(s["meds"].get(id, false))
			rows.append(_row("@pill", "%s — medication %s" % [str(d["name"]).capitalize(), "ON" if on else "off"], "Tap to %s. Skipping it has a price that arrives late" % ("stop" if on else "start"), "meds", id))
	rows.append(_row("@gym", "Physiotherapy", "%s · speeds up an injury's recovery" % GameState.fmt_money(Actions._cost(120) if system() != "free" else 0), "physio", null, not med["injuries"].is_empty()))
	rows.append(_row("@eye", "Eye test", "Find out how your eyes are really doing", "eyes"))
	for k in ["glasses", "contacts", "laser"]:
		rows.append(_row("@eye", {"glasses": "Get glasses", "contacts": "Get contact lenses", "laser": "Laser surgery"}[k], "Helps now%s" % (" and keeps helping" if k == "laser" else ""), "aid", k, str(s["aid"]) != k))
	rows.append(_row("@tooth", "Dentist", "A check-up, and a scolding if you've earned it", "dentist"))
	rows.append(_row("@tooth", "Crown or major dental work", "For teeth that have had enough", "crown", null, float(s["teeth"]) <= 55.0))
	rows.append(_row("@tooth", "Dentures", "When there isn't much left to save", "dentures", null, float(s["teeth"]) <= 25.0 and int(_p()["age"]) >= 45 and not bool(s["dentures"])))
	rows.append(_row("@ear", "Hearing aid", "For when 'pardon' has become a habit", "hearing", null, float(s["hearing"]) <= 70.0 and not bool(s["hearing_aid"])))
	return {"icon": "🏥", "title": "Getting care", "rows": rows, "info": info}


func act(key: String, arg) -> void:
	match key:
		"gp": gp_visit()
		"skip": pay_to_skip()
		"second": second_opinion()
		"meds": toggle_meds(str(arg))
		"physio": physio()
		"eyes": test_eyes()
		"aid": buy_aid(str(arg))
		"dentist": dentist()
		"crown": crown()
		"dentures": dentures()
		"hearing": hearing_aid()


func tag(t: String) -> bool:
	var s := st()
	if s.is_empty():
		return false
	match t:
		"waiting_list": return not s["referral"].is_empty()
		"misdiagnosed": return str(s.get("misdx", "")) != ""
		"on_meds":
			for id in s["meds"].keys():
				if bool(s["meds"][id]): return true
			return false
		"poor_vision": return vision() < 50.0
		"bad_teeth": return float(s["teeth"]) < 45.0
		"poor_hearing": return float(s["hearing"]) < 60.0 and not bool(s["hearing_aid"])
		"chronic": 
			for id in _p()["medical"]["conditions"].keys():
				if bool(Expansion.CONDITIONS.get(id, {}).get("chronic", false)): return true
			return false
		"symptoms": return str(_p()["medical"].get("pending", "")) != ""
	return false
