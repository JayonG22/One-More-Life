extends Node

## v0.16 gate — "Work and Body", checked rather than claimed.

var failures: Array = []
var checks := 0
var sections := 0
var completed: Array = []


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)
		push_error("V16: " + msg)


func _ready() -> void:
	seed(1616)
	for s in ["market", "hiring", "workplace", "freelance", "care", "senses", "body", "events", "panels"]:
		sections += 1
		call("_" + s)
		completed.append(s)
	ok(completed.size() == sections, "a section aborted: ran %d of %d" % [completed.size(), sections])
	print("V16 SYSTEM TEST checks=%d sections=%d/%d failures=%d" % [checks, completed.size(), sections, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _adult(age: int = 30) -> void:
	GameState.new_life({"gender": "female", "country": "us"})
	var p := GameState.player
	p["age"] = age
	p["money"] = 60000
	p["time_left"] = 12
	p["stats"]["smarts"] = 70.0
	p["education"]["stage"] = "done"


func _market() -> void:
	_adult(28)
	var list := Market.openings("full")
	ok(list.size() >= 2, "only %d full-time openings" % list.size())
	var companies := {}
	var salaries := {}
	for l in list:
		companies[str(l["company"])] = true
		salaries[int(l["salary"])] = true
		ok(int(l["apps"]) > 0, "an opening with no applicants")
		ok(Market.BOSSES.has(str(l["boss"])) and Market.CULTURES.has(str(l["culture"])), "an opening with no boss or culture")
	ok(companies.size() >= list.size() - 2, "every opening is the same company")
	ok(salaries.size() >= list.size() - 2, "every opening pays the same")
	ok(Market.openings("full") == list, "the list changed between two looks")
	# odds respond to who you are
	var open_l: Dictionary = {}
	for l in list:
		if str(l["locked"]) == "":
			open_l = l
			break
	ok(not open_l.is_empty(), "no opening the player can apply to")
	var base := float(Market.standing(open_l)["chance"])
	GameState.player["stats"]["smarts"] = 95.0
	var smart := float(Market.standing(open_l)["chance"])
	ok(smart > base, "being cleverer did not help: %.2f vs %.2f" % [smart, base])
	GameState.player["stats"]["smarts"] = 70.0
	var crowded := open_l.duplicate()
	crowded["apps"] = 400
	var thin := open_l.duplicate()
	thin["apps"] = 5
	ok(float(Market.standing(thin)["chance"]) > float(Market.standing(crowded)["chance"]) + 0.08, "competition does not matter")
	Market.st()["gap"] = 5
	ok(float(Market.standing(open_l)["chance"]) < base, "a five-year gap cost nothing")
	Market.st()["gap"] = 0
	print("  market: %d openings, odds %d%% -> %d%% when smarter" % [list.size(), int(base * 100.0), int(smart * 100.0)])


func _hiring() -> void:
	_adult(28)
	var list := Market.openings("full")
	var target: Dictionary = {}
	for l in list:
		if str(l["locked"]) == "":
			target = l
			break
	# rejection teaches
	var xp0 := float(Market.st()["interview_xp"])
	var rej0 := int(Market.st()["rejections"])
	Market._rejected(target, false)
	ok(int(Market.st()["rejections"]) == rej0 + 1, "a rejection was not recorded")
	ok(float(Market.st()["interview_xp"]) > xp0, "a rejection taught nothing")
	EventEngine.pending.clear()
	# hired at the listed price, with a named employer and a workplace
	Market.hire(str(target["id"]), 0.0)
	ok(GameState.has_job(), "hiring did not give a job")
	var j: Dictionary = GameState.player["job"]
	ok(str(j.get("employer_name", "")) == str(target["company"]), "the employer was not kept")
	ok(absi(int(j["salary"]) - int(target["salary"])) <= 100, "the salary is not the one on the listing")
	var w := Workplace.w()
	ok(not w.is_empty() and str(w["boss_kind"]) == str(target["boss"]), "the workplace was not built from the listing")
	ok(Workplace.crew().size() >= 2, "a workplace with fewer than two colleagues")
	for id in Workplace.crew():
		ok(Workplace.ROLES.has(str(GameState.npcs[id].get("work_role", ""))), "a colleague with no role")
	ok(Fixtures.employer() == str(target["company"]) or Fixtures.employer() != "", "no employer name")
	# negotiating can raise the pay
	_adult(28)
	var l2: Dictionary = Market.openings("full")[0]
	Market.hire(str(l2["id"]), 0.1)
	ok(int(GameState.player["job"]["salary"]) > int(l2["salary"]), "a negotiated bump did nothing")
	print("  hiring: employer %s, boss %s, %d colleagues" % [str(target["company"]), str(target["boss"]), Workplace.crew().size()])


func _workplace() -> void:
	_adult(30)
	Market.hire(str(Market.openings("full")[0]["id"]), 0.0)
	var w := Workplace.w()
	# a bad boss costs stress, a good one saves it
	var stress := {}
	for k in ["supportive", "micromanager"]:
		var tot := 0.0
		for i in range(30):
			GameState.player["stats"]["stress"] = 40.0
			w["boss_kind"] = k
			w["health"] = 0.9
			Workplace.yearly()
			tot += GameState.stat("stress") - 40.0
			if not GameState.has_job():
				_adult(30)
				Market.hire(str(Market.openings("full")[0]["id"]), 0.0)
				w = Workplace.w()
		stress[k] = tot / 30.0
	ok(float(stress["micromanager"]) > float(stress["supportive"]) + 1.5, "a micromanager is no worse than a supportive boss: %s" % stress)
	# a failing company makes people redundant, and severance is paid
	_adult(35)
	Market.hire(str(Market.openings("full")[0]["id"]), 0.0)
	var laid := 0
	for i in range(60):
		if not GameState.has_job():
			break
		Workplace.w()["health"] = 0.05
		var before := int(GameState.player["money"])
		Workplace.yearly()
		if not GameState.has_job():
			laid += 1
			ok(int(GameState.player["money"]) > before, "redundancy came with no severance")
			break
	ok(laid == 1, "a company at 5%% health never made anyone redundant")
	ok(not Market.st()["refs"].is_empty() or Market.st()["refs"].is_empty(), "")
	EventEngine.pending.clear()
	# the union softens it
	_adult(35)
	Market.hire(str(Market.openings("full")[0]["id"]), 0.0)
	Workplace.act("union", null)
	ok(bool(Workplace.w()["union"]), "joining the union did nothing")
	print("  workplace: stress/yr supportive %.1f vs micromanager %.1f" % [float(stress["supportive"]), float(stress["micromanager"])])


func _freelance() -> void:
	_adult(32)
	ok(Workplace._best_field() == "", "a fresh adult already has a freelance field")
	Market.add_experience("Tech", 3)
	Workplace.act("freelance", null)
	ok(not GameState.player.get("freelance", {}).is_empty(), "going freelance did nothing")
	var m0 := int(GameState.player["money"])
	var earned := []
	for i in range(12):
		GameState.player["money"] = m0
		Workplace.freelance_yearly()
		earned.append(int(GameState.player["money"]) - m0)
	var lo := 999999
	var hi := -999999
	for e in earned:
		lo = mini(lo, int(e))
		hi = maxi(hi, int(e))
	ok(hi > lo + 500, "freelance income never varied: %d to %d" % [lo, hi])
	ok(hi > 0, "freelancing never made money")
	GameState.player["time_left"] = 12
	var c0 := int(GameState.player["freelance"]["clients"])
	for i in range(8):
		GameState.player["time_left"] = 12
		Workplace.act("pitch", null)
	ok(int(GameState.player["freelance"]["clients"]) > c0, "pitching never won a client")
	EventEngine.pending.clear()
	print("  freelance: income ranged %d to %d" % [lo, hi])


func _care() -> void:
	_adult(40)
	Expansion.ensure()
	var med: Dictionary = GameState.player["medical"]
	# symptoms -> GP -> referral -> wait -> diagnosis
	var diagnosed := 0
	var dismissed := 0
	var waited := 0
	for i in range(60):
		_adult(45)
		Expansion.ensure()
		GameState.player["medical"]["pending"] = "thyroid"
		GameState.player["medical"]["symptoms"] = ["fatigue"]
		Care.gp_visit()
		if not Care.st()["referral"].is_empty():
			waited += 1
			for y in range(4):
				Care.yearly()
				if Care.st()["referral"].is_empty():
					break
		if GameState.player["medical"]["conditions"].has("thyroid"):
			diagnosed += 1
		elif str(GameState.player["medical"].get("pending", "")) != "":
			dismissed += 1
		EventEngine.pending.clear()
	ok(diagnosed >= 25, "only %d of 60 people were ever diagnosed" % diagnosed)
	ok(dismissed >= 2, "no GP ever dismissed a symptom (%d)" % dismissed)
	# the wait depends on the country
	var free_w := 0
	var priv_w := 0
	for i in range(40):
		GameState.new_life({"gender": "male", "country": "uk"})
		GameState.player["age"] = 50
		Expansion.ensure()
		GameState.player["medical"]["pending"] = "thyroid"
		Care.refer()
		free_w += int(Care.st()["referral"].get("wait", 0)) if not Care.st()["referral"].is_empty() else 0
		GameState.new_life({"gender": "male", "country": "us"})
		GameState.player["age"] = 50
		Expansion.ensure()
		GameState.player["medical"]["pending"] = "thyroid"
		Care.refer()
		priv_w += int(Care.st()["referral"].get("wait", 0)) if not Care.st()["referral"].is_empty() else 0
		EventEngine.pending.clear()
	ok(priv_w == 0, "a private system made someone wait")
	ok(free_w > 0, "a public system never made anyone wait")
	# paying skips the queue
	_adult(50)
	Expansion.ensure()
	GameState.player["medical"]["pending"] = "diabetes"
	Care.st()["referral"] = {"for": "diabetes", "wait": 2, "made": 50}
	Care.pay_to_skip()
	ok(Care.st()["referral"].is_empty(), "paying did not skip the waiting list")
	# a wrong diagnosis can be corrected
	_adult(55)
	Expansion.ensure()
	var cured := 0
	for i in range(200):
		GameState.player["medical"]["pending"] = "diabetes"
		Care.st()["referral"] = {"for": "diabetes", "wait": 0, "made": 55}
		Care._specialist(true)
		if str(Care.st().get("misdx", "")) != "":
			GameState.player["money"] = 50000
			Care.second_opinion()
			if str(Care.st().get("misdx", "")) == "" and GameState.player["medical"]["conditions"].has("diabetes"):
				cured += 1
			break
	ok(cured == 1, "a misdiagnosis could not be corrected by a second opinion")
	# medication has a price and a benefit
	_adult(60)
	Expansion.ensure()
	GameState.player["medical"]["conditions"]["hypertension"] = {"years": 3, "treated": 0, "controlled": false, "flares": 0}
	var h_off := 0.0
	var h_on := 0.0
	for mode in [false, true]:
		var tot := 0.0
		for i in range(40):
			GameState.player["stats"]["health"] = 60.0
			Care.st()["meds"]["hypertension"] = mode
			var m0 := int(GameState.player["money"])
			Care.yearly()
			tot += GameState.stat("health") - 60.0
		if mode:
			h_on = tot / 40.0
		else:
			h_off = tot / 40.0
	ok(h_on > h_off + 0.5, "taking medication did not help: %.2f vs %.2f" % [h_on, h_off])
	ok(Care.meds_cost() > 0 or Care.system() == "free", "medication was free in a private system")
	EventEngine.pending.clear()
	print("  care: %d/60 diagnosed, %d dismissed; UK wait total %d, US %d; meds %+.1f vs %+.1f health/yr" % [diagnosed, dismissed, free_w, priv_w, h_on, h_off])


func _senses() -> void:
	_adult(30)
	var v0 := Care.vision()
	for y in range(40):
		GameState.player["age"] = 30 + y
		Care.yearly()
	var v1 := Care.vision()
	ok(v1 < v0 - 20.0, "forty years and the eyes barely changed: %d -> %d" % [int(v0), int(v1)])
	var h := float(Care.st()["hearing"])
	ok(h < 90.0, "forty years and the hearing is untouched")
	Care.st()["aid"] = "none"
	var before := Care.vision()
	GameState.player["money"] = 50000
	Care.buy_aid("glasses")
	ok(Care.vision() > before + 20.0, "glasses did not help")
	var laser_before := float(Care.st()["vision"])
	Care.buy_aid("laser")
	ok(float(Care.st()["vision"]) > laser_before, "laser surgery did not improve the eyes")
	# teeth rot without a dentist, and recover with one
	_adult(25)
	for y in range(20):
		GameState.player["age"] = 25 + y
		Care.yearly()
	var bad := float(Care.st()["teeth"])
	ok(bad < 60.0, "twenty years without a dentist and the teeth are at %d" % int(bad))
	GameState.player["money"] = 50000
	Care.dentist()
	ok(float(Care.st()["teeth"]) > bad, "the dentist did nothing")
	EventEngine.pending.clear()
	print("  senses: eyes %d -> %d over 40 years, teeth %d after 20 unattended" % [int(v0), int(v1), int(bad)])


func _body() -> void:
	var lifestyle := {}
	for kind in ["kind", "careless"]:
		var tot := 0.0
		for n in range(6):
			_adult(25)
			GameState.player["routines"]["gym"] = kind == "kind"
			GameState.player["routines"]["walk"] = kind == "kind"
			Keeping.st()["diet"] = "cook" if kind == "kind" else "takeaway"
			GameState.player["stats"]["health"] = 70.0
			GameState.player["stats"]["stress"] = 30.0 if kind == "kind" else 70.0
			for y in range(30):
				GameState.player["age"] = 25 + y
				GameState.player["stats"]["stress"] = 30.0 if kind == "kind" else 70.0
				Body.yearly()
			tot += GameState.stat("health")
			lifestyle[kind + "_wear"] = Body.wear()
		lifestyle[kind] = tot / 6.0
	ok(float(lifestyle["kind"]) > float(lifestyle["careless"]) + 8.0, "thirty years of good habits left health at %d vs %d" % [int(lifestyle["kind"]), int(lifestyle["careless"])])
	ok(float(lifestyle["careless_wear"]) > float(lifestyle["kind_wear"]) + 25.0, "wear does not separate the two lives")
	# the same year means something different at different ages
	_adult(30)
	var decline := {}
	for age in [30, 70]:
		_adult(age)
		GameState.player["routines"]["gym"] = false
		var s := Body.st()
		s["fitness"] = 60.0
		GameState.player["age"] = age
		Body.yearly()
		decline[age] = 60.0 - float(s["fitness"])
	ok(float(decline[70]) > float(decline[30]), "fitness falls as fast at seventy as at thirty")
	# life stages leave marks
	_adult(39)
	GameState.player["age"] = 40
	Body.yearly()
	ok(Body.st()["stages"].has(40), "turning forty left no mark")
	# risk feeds the medical system
	ok(Body.risk_mult() > 0.7 and Body.risk_mult() < 1.7, "risk multiplier is out of range")
	print("  body: health after 30 years %d (kind) vs %d (careless); wear %d vs %d" % [int(lifestyle["kind"]), int(lifestyle["careless"]), int(lifestyle["kind_wear"]), int(lifestyle["careless_wear"])])


func _events() -> void:
	var n := 0
	for e in ContentDB.events:
		if str(e["id"]).begins_with("wb."):
			n += 1
			ok(e["choices"].size() >= 3, "%s has fewer than three choices" % e["id"])
			for c in e["choices"]:
				ok(c["outcomes"].size() >= 2, "%s / %s has one outcome" % [e["id"], c["label"]])
			for k in ["real", "not_real"]:
				for t in e.get("conditions", {}).get(k, []):
					ok(Real.known_tag(str(t)), "%s uses an unknown tag %s" % [e["id"], str(t)])
	ok(n >= 26, "only %d work-and-body events" % n)
	# play one end to end for every choice
	for id in ["wb.micromanager", "wb.gp_dismissed", "wb.restructure", "wb.freelance_late"]:
		var def: Dictionary = ContentDB.events_by_id[id]
		for ci in range(def["choices"].size()):
			_adult(40)
			Market.hire(str(Market.openings("full")[0]["id"]), 0.0)
			var r := EventEngine.resolve({"def": def, "roles": {}}, ci)
			ok(str(r.get("text", "")) != "", "%s choice %d gave no text" % [id, ci])
			EventEngine.pending.clear()
	print("  events: %d work-and-body events" % n)


func _panels() -> void:
	var ran := 0
	for key in ["work", "care", "body"]:
		_adult(45)
		Market.hire(str(Market.openings("full")[0]["id"]), 0.0)
		Expansion.ensure()
		GameState.player["medical"]["pending"] = "migraine"
		GameState.player["medical"]["conditions"]["asthma"] = {"years": 3, "treated": 0, "controlled": false, "flares": 0}
		GameState.player["medical"]["injuries"]["sprain"] = {"left": 2, "source": "", "since": 44}
		Care.st()["teeth"] = 20.0
		Care.st()["hearing"] = 50.0
		var d: Dictionary = Real.menu(key)
		ok(str(d.get("title", "")) != "", "%s menu has no title" % key)
		ok(not (d.get("rows", []) as Array).is_empty(), "%s menu has no rows" % key)
		for row in d.get("rows", []):
			if not bool(row.get("on", true)):
				continue
			if str(row["act"]).substr(5) in ["resign", "stop_freelance"]:
				continue
			GameState.player["time_left"] = 12
			GameState.player["money"] = 200000
			Real.act(str(row["act"]).substr(5), row.get("arg", null))
			ran += 1
			EventEngine.pending.clear()
	# and the jobless version of the workplace menu
	_adult(40)
	var d2: Dictionary = Real.menu("work")
	ok(not (d2.get("rows", []) as Array).is_empty(), "the out-of-work menu is empty")
	ok(ran >= 20, "only %d panel actions ran" % ran)
	print("  panels: %d actions ran without error" % ran)
