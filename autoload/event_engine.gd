extends Node

signal event_queued
signal died(entry: Dictionary)
signal year_done

const ILLNESSES_YOUNG := ["the flu", "bronchitis", "a stomach bug", "chickenpox", "an ear infection"]
const ILLNESSES_ADULT := ["the flu", "bronchitis", "migraines", "back pain", "high blood pressure", "insomnia", "pneumonia"]
const ILLNESSES_OLD := ["arthritis", "high blood pressure", "heart disease", "pneumonia", "diabetes", "failing eyesight"]
const SERIOUS := ["high blood pressure", "heart disease", "pneumonia", "diabetes", "arthritis", "cancer"]
const AGENCY_RELATIONS := ["sibling", "friend", "best_friend", "partner", "rival", "coworker", "boss", "mother", "father", "child", "neighbor", "ex", "grandparent"]

var pending: Array = []
var displayed: Dictionary = {}
var _token_re := RegEx.new()
var _money_token_re := RegEx.new()


func _ready() -> void:
	_token_re.compile("\\{([a-z_]+)\\.([a-zA-Z]+)\\}")
	_money_token_re.compile("\\{money:([0-9]+)\\}")


func has_pending() -> bool:
	return not pending.is_empty()


func pop_next() -> Dictionary:
	if pending.is_empty():
		return {}
	var it: Dictionary = pending.pop_front()
	displayed = it.duplicate(true)
	if it.has("def"):
		Director.note(it["def"])
		if not Meta.meta.has("recent"): Meta.meta["recent"] = {}
		Meta.meta["recent"][it["def"]["id"]] = Goals.stat_total("lives")
	return it


# ---------------------------------------------------------------- the year

func progress() -> void:
	if Journey.busy(): return
	if not GameState.is_alive() or has_pending() or displayed.has("def"): return
	if LifeCourse.monthly_mode():
		if LifeCourse.advance_month():
			Goals.check()
			GameState.emit_changed()
			SaveManager.save_game()
			if has_pending(): event_queued.emit()
			return
	age_up()


func age_up() -> void:
	if not GameState.is_alive():
		return
	if Lives.is_type("tv"):
		TVLife.advance()
		return
	if Lives.separate():
		_age_up_separate()
		return
	Childhood.protect()
	pending.clear()
	Items.snapshot()
	FamilyChronicle.before_year()
	GameState.begin_year()
	LifeCourse.yearly()
	_run_routines()
	Lifestyle.advance(false)
	_yearly_body()
	_yearly_npcs()
	_yearly_school()
	Employment.yearly()
	_yearly_job()
	Careers.yearly()
	Finance.yearly()
	Empires.yearly()
	Ventures.yearly()
	Web.yearly()
	Grit.yearly()
	Fights.yearly()
	Lives.yearly()
	World.yearly()
	Places.yearly()
	Bonds.yearly()
	Companions.yearly()
	Workforce.yearly()
	Romance.yearly()
	NpcWorld.yearly()
	Lore.yearly()
	Daily.yearly()
	Depth.yearly()
	Insight.yearly()
	Shop.yearly()
	Social.yearly()
	Creator.yearly()
	Dealer.yearly()
	Expansion.yearly()
	Ambition.yearly()
	LifeThreads.yearly()
	Law.yearly()
	Wanted.yearly()
	Decline.yearly()
	Real.yearly()
	Household.yearly()
	FamilyChronicle.yearly()
	Journey.yearly()
	_yearly_finances()
	Employment.after_finances()
	Journey.modules["funds"].settle_active_after_finances()
	Stewardship.finish_year()
	Journey.modules["fresh"].after_finances()
	_yearly_prison()
	var cause := _death_check()
	if cause != "":
		kill(cause)
		if not GameState.is_alive():
			return
	_due_followups()
	_random_events()
	Twists.yearly()
	_npc_agency()
	Meta.check_challenge()
	Goals.bump("years")
	Goals.check()
	Director.curate()
	GameState.emit_changed()
	year_done.emit()
	SaveManager.save_game()
	if not pending.is_empty():
		event_queued.emit()


## Modes that are not a human life (Pets Life, later Prison Life) run only their
## own pass: none of school, jobs, money or the human systems apply to them.
func _age_up_separate() -> void:
	pending.clear()
	GameState.begin_year()
	Lives.yearly()
	if not GameState.is_alive():
		return
	var cause := _death_check()
	if cause != "":
		kill(cause)
		if not GameState.is_alive():
			return
	_due_followups()
	_random_events()
	Goals.bump("years")
	Goals.check()
	Director.curate()
	GameState.emit_changed()
	year_done.emit()
	SaveManager.save_game()
	if not pending.is_empty():
		event_queued.emit()


func _run_routines() -> void:
	var p := GameState.player
	if GameState.in_prison():
		return
	var r: Dictionary = p["routines"]
	var age: int = p["age"]
	var done: Array = []
	if r.get("gym", false) and age >= 12 and GameState.spend_time():
		GameState.apply_effects({"health": 2, "looks": 1, "stress": -2})
		done.append("gym")
	if r.get("study", false) and (GameState.in_school() or GameState.in_university()) and GameState.spend_time():
		GameState.apply_effects({"school": 5, "smarts": 1, "stress": 1})
		p["education"]["studied"] = true
		done.append("studying")
	if r.get("meditate", false) and age >= 8 and GameState.spend_time():
		GameState.apply_effects({"stress": -5, "happiness": 2})
		done.append("meditation")
	if r.get("walk", false) and age >= 6 and GameState.spend_time():
		GameState.apply_effects({"health": 1, "happiness": 1})
		done.append("daily walks")
	if r.get("family", false) and GameState.spend_time():
		for rel in ["mother", "father", "sibling", "partner", "child", "grandparent"]:
			for id in GameState.npcs_with(rel):
				GameState.change_closeness(id, 3)
		done.append("family time")
	for habit in done:
		Lifestyle.note({"studying":"library","meditation":"meditate","daily walks":"walk","family time":"social"}.get(habit,habit))
	if not done.is_empty():
		GameState.add_log("I kept up my routines: %s." % ", ".join(done))


func _yearly_body() -> void:
	var p := GameState.player
	var age: int = p["age"]
	var ag := Grit.d("age") * (0.0 if Lives.ageless() else 1.0)
	if age >= 35:
		GameState.change_stat("looks", -randf_range(0.0, 1.2) * ag)
	if age >= 45:
		GameState.change_stat("health", -randf_range(0.3, 1.5) * ag)
	if age >= 65:
		GameState.change_stat("health", -randf_range(1.0, 3.0) * ag)
	if age >= 75:
		GameState.change_stat("smarts", -randf_range(0.0, 1.0) * ag)
	GameState.change_stat("stress", -7 - maxf(0.0, GameState.stat("happiness") - 60.0) * 0.1)
	var h := GameState.stat("happiness")
	GameState.change_stat("happiness", (58.0 - h) * 0.08)
	if GameState.stat("stress") > 75:
		GameState.change_stat("health", -1.5)
		GameState.change_stat("happiness", -3)
		GameState.add_log("I've been under a lot of stress lately.")
	if p["housing"] == "homeless":
		GameState.apply_effects({"health": -5, "happiness": -5, "stress": 5})
	var recorded_illness: bool=Care.course().recorded_illness()
	if p["illness"] != "" and not recorded_illness:
		var serious: bool = SERIOUS.has(p["illness"])
		if randf() < (0.2 if serious else 0.65):
			GameState.add_log("I finally got over %s." % p["illness"])
			p["illness"] = ""
		else:
			GameState.apply_effects({"health": -3 if serious else -2, "happiness": -2})
			GameState.add_log("I'm still dealing with %s." % p["illness"])
	elif recorded_illness or Lives.no_healing():
		pass
	elif age < 45 and GameState.stat("health") < 85:
		GameState.change_stat("health", 2.0 * Grit.d("heal"))
	elif age < 65 and GameState.stat("health") < 70:
		GameState.change_stat("health", 0.8 * Grit.d("heal"))
	if p["illness"] == "" and age >= 3 and not recorded_illness:
		var chance := 0.04 + age * 0.0012
		if p["illness"] == "" and randf() < chance:
			var pool := ILLNESSES_YOUNG if age < 18 else (ILLNESSES_ADULT if age < 60 else ILLNESSES_OLD)
			p["illness"] = pool[randi() % pool.size()]
			GameState.apply_effects({"health": -6 if SERIOUS.has(p["illness"]) else -3, "happiness": -3})
			GameState.add_log("I came down with %s." % p["illness"])
	if GameState.has_trait("Anxious"):
		GameState.change_stat("stress", 3)
	if p["car"] != "":
		GameState.change_stat("happiness", GameState.CARS[p["car"]]["happiness"] * 0.2)
	GameState.change_stat("happiness", GameState.HOUSING[p["housing"]]["happiness"] * 0.3)


func _yearly_npcs() -> void:
	var p := GameState.player
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"]:
			continue
		n["age"] = int(n["age"]) + 1
		var decay := 3
		match n["relation"]:
			"mother", "father", "sibling", "grandparent", "child":
				decay = 1 if Grit.has_boon("family_ties") else 2
			"friend", "best_friend":
				decay = 4
			"pet":
				decay = 0
		# Affection is what fades when nobody tends it; trust and respect hold on
		# far longer. BondStats.yearly() does that properly, so the old flat
		# closeness decay only applies to bonds that have not been built yet.
		if not n.has("bond"):
			n["closeness"] = maxi(0, int(n["closeness"]) - decay)
		_npc_stats_drift(n)
		var dies := false
		if n.get("vampire", false):
			continue
		if n.get("species", "human") != "human":
			dies = n["age"] >= 10 and randf() < (n["age"] - 9) * 0.12
		elif n["age"] >= 60:
			# Their health is their own, so it decides how long they last.
			var frail := clampf(1.6 - float(n.get("health", 70)) / 100.0, 0.55, 1.6)
			dies = randf() < pow((n["age"] - 60) / 42.0, 3) * 0.6 * frail
		elif n["age"] >= 18:
			dies = randf() < 0.0012 * (2.0 if int(n.get("health", 70)) < 30 else 1.0)
		if dies:
			_npc_died(id)
	var partner: String = p["partner"]
	if partner != "" and GameState.npcs.has(partner) and GameState.npcs[partner]["alive"]:
		var pn: Dictionary = GameState.npcs[partner]
		if int(pn["closeness"]) < 15 and randf() < 0.4:
			if p["partner_status"] == "married":
				var loss: int = maxi(0, int(int(p["money"]) * 0.35))
				p["money"] = int(p["money"]) - loss
				GameState.add_log("%s filed for divorce. The settlement cost me %s." % [pn["first"], GameState.fmt_money(loss)])
				GameState.add_milestone(p["age"], "went through a divorce")
				LifeThreads.remember("relationship", "The marriage that ended", "%s chose to end our marriage. The settlement made the ending concrete." % pn["first"], partner, 68, ["divorce"])
			else:
				GameState.add_log("%s broke up with me." % pn["first"])
			GameState.apply_effects({"happiness": -12, "stress": 8})
			pn["relation"] = "ex"
			p["partner"] = ""
			p["partner_status"] = ""
	if p.get("expecting", false):
		p["expecting"] = false
		_have_baby()
	if p["age"] < 12:
		var mom := GameState.first_of("mother")
		var dad := GameState.first_of("father")
		if mom != "" and dad != "" and int(GameState.npcs[mom]["age"]) <= 42 and randf() < 0.08:
			var sid := GameState.create_npc("sibling", {"age": 0, "last": p["last"], "closeness": 60})
			var s: Dictionary = GameState.npcs[sid]
			GameState.add_log("My parents had a baby %s named %s." % ["boy" if s["gender"] == "male" else "girl", s["first"]])


func _have_baby() -> void:
	var p := GameState.player
	var count := 1
	var roll := randf()
	if roll < 0.02:
		count = 3
	elif roll < 0.07:
		count = 2
	var named: Array = []
	var parent_uids: Array = [FamilyChronicle.identity(p)]
	if GameState.npcs.has(str(p.get("partner",""))): parent_uids.append(FamilyChronicle.identity(GameState.npcs[p["partner"]]))
	for i in range(count):
		var cid := GameState.create_npc("child", {"age": 0, "last": p["last"], "closeness": 90,"parent_uids":parent_uids})
		named.append(GameState.npcs[cid]["first"])
	if count == 1:
		GameState.add_log("I became a parent! We named the baby %s." % named[0])
	elif count == 2:
		GameState.add_log("Twins! We named them %s and %s." % [named[0], named[1]])
	else:
		GameState.add_log("Triplets! Welcome %s, %s and %s." % [named[0], named[1], named[2]])
	GameState.add_milestone(p["age"], "welcomed %s" % (named[0] if count == 1 else "%d babies at once" % count))
	GameState.counter("babies", count)
	if count >= 2:
		GameState.counter("multiples")
	GameState.apply_effects({"happiness": 12, "stress": 6})


## Other people age the way the player does: bodies wear down, minds keep
## growing for a while, moods follow how their life is actually going.
func _npc_stats_drift(n: Dictionary) -> void:
	var age := int(n["age"])
	var h := float(n.get("health", 70))
	if age > 45:
		h -= randf_range(0.4, 1.6) * (1.0 + float(age - 45) / 55.0)
	elif age < 18:
		h += randf_range(0.0, 1.2)
	else:
		h += randf_range(-0.8, 0.8)
	n["health"] = int(clampf(h, 0.0, 100.0))

	var sm := float(n.get("smarts", 50))
	if age < 25:
		sm += randf_range(0.0, 1.4)
	elif age > 78:
		sm -= randf_range(0.0, 0.9)
	n["smarts"] = int(clampf(sm, 0.0, 100.0))

	var lk := float(n.get("looks", 55))
	if age > 30:
		lk -= randf_range(0.0, 0.7)
	elif age < 20:
		lk += randf_range(0.0, 0.8)
	n["looks"] = int(clampf(lk, 0.0, 100.0))

	# How they feel about their life tracks how close they are to yours, plus
	# whatever else is going on for them.
	var hp := float(n.get("happiness", 60))
	hp += (float(n.get("closeness", 50)) - 50.0) / 45.0 + randf_range(-3.0, 3.0)
	if int(n.get("grudge", 0)) > 40:
		hp -= 1.5
	n["happiness"] = int(clampf(hp, 0.0, 100.0))


func _npc_died(id: String) -> void:
	if GameState.npc(id).get("death_settled",false): return
	GameState.npc(id)["death_settled"]=true
	Journey.modules["coping"].lost(id)
	Novelty.close_person(GameState.npc(id).get("playable_player",{}),"this person's life ended")
	var p := GameState.player
	var n: Dictionary = GameState.npcs[id]
	n["alive"] = false
	var full_estate := Estate.settle_inactive(id)
	var rel := GameState.relation_label(id).to_lower()
	var close: int = n["closeness"]
	var hit := -int(close / 6.0)
	if n["relation"] in ["mother", "father", "child", "partner"]:
		hit -= 8
	if n["relation"] in ["mother", "father", "child", "partner", "sibling", "grandparent", "pet", "best_friend"]:
		GameState.add_log("My %s %s passed away at %d." % [rel, n["first"], int(n["age"])])
		GameState.apply_effects({"happiness": hit, "stress": 5})
	Keeping.on_death(id)
	if n["relation"] in ["mother", "father", "partner", "child"]:
		GameState.add_milestone(p["age"], "lost %s %s, %s" % [GameState.pron(p["gender"], "his"), rel, n["first"]])
	if n["relation"] in ["mother", "father", "child", "partner", "sibling", "grandparent", "pet", "best_friend"] and close >= 35:
		GameState.set_flag("lost_close_person")
		LifeThreads.remember("grief", "Losing %s" % n["first"], "My %s %s died at %d. Some years will carry that absence more loudly than others." % [rel, n["first"], int(n["age"])], id, clampi(45 + close / 2, 50, 95), ["loss", n["relation"]])
	if p["partner"] == id:
		p["partner"] = ""
		p["partner_status"] = ""
		GameState.set_flag("widowed")
		if not full_estate and int(n["money"]) > 0:
			p["money"] = int(p["money"]) + int(n["money"])


func _yearly_school() -> void:
	var p := GameState.player
	var e: Dictionary = p["education"]
	var age: int = p["age"]
	if GameState.in_prison():
		return
	if age == 5 and e["stage"] == "none":
		e["stage"] = "primary"
		GameState.add_log("I started kindergarten.")
		return
	if age == 12 and e["stage"] == "primary":
		e["stage"] = "secondary"
		GameState.add_log("My secondary-school record continues through middle and high school.")
	if GameState.in_school():
		_update_performance(e, "performance")
		e["performance"]=clampf(float(e["performance"])+(float(Journey.modules["campus"].st()["attendance"])-95.0)*0.12,0,100)
		var letter := grade_letter(float(e["performance"]))
		e["grade"] = letter
		if e["stage"] == "secondary" and age>=14:
			e["gpa_sum"] = float(e["gpa_sum"]) + grade_points(letter)
			e["gpa_years"] = int(e["gpa_years"]) + 1
		GameState.change_stat("smarts", randf_range(0.2, 1.2))
		GameState.add_log("My report card came back: %s." % letter)
	if age == 18 and e["stage"] == "secondary":
		if GameState.gpa() >= 1.0:
			e["hs_graduated"] = true
			e["stage"] = "graduated"
			GameState.add_log("I graduated from high school with a %.1f GPA!" % GameState.gpa())
			GameState.add_milestone(age, "graduated from high school")
			GameState.apply_effects({"happiness": 8})
			push_info("🎓", "Graduation Day", "You graduated from high school with a %.1f GPA.\n\nOpen Occupation → Education to apply to university, or Full-Time Jobs to start working." % GameState.gpa())
			# This is a transition scene, not a random school encounter. Queue it
			# immediately and keep the classroom people who were actually there.
			var campus = Journey.modules["campus"]
			var graduation_roles: Dictionary = {}
			var teacher_id: String = str(campus.homeroom_teacher())
			if teacher_id != "": graduation_roles["teacher"] = teacher_id
			var classmates: Array = campus.members("classmate")
			if not classmates.is_empty(): graduation_roles["classmate"] = str(classmates.pick_random())
			GameState.followups.append({"event":"sch.graduation","age":age,"roles":graduation_roles,"retries":0})
		else:
			e["stage"] = "dropout"
			GameState.add_log("My grades were too low to graduate high school.")
			GameState.add_milestone(age, "left high school without a diploma")
	if GameState.in_university():
		var u: Dictionary = e["uni"]
		var cost_mult: float = ContentDB.country(p["country"]).get("cost", 1.0)
		var base := 25000 if u["level"] == "graduate" else 12000
		var tuition := int(base * cost_mult * float(Places.law("tuition")) * (1.0 - float(u.get("scholarship", 0.0))))
		if tuition > 0:
			if int(p["money"]) >= tuition:
				p["money"] = int(p["money"]) - tuition
			else:
				p["loan"] = int(p["loan"]) + tuition
		_update_performance(u, "performance")
		u["performance"]=clampf(float(u["performance"])+(float(Journey.modules["campus"].st()["attendance"])-95.0)*0.12,0,100)
		u["year"] = int(u["year"]) + 1
		if float(u["performance"]) >= 45.0:
			for field in Market.MAJOR_FIELDS.get(str(u["major"]), []): Market.learn(str(field))
		if float(u["performance"]) < 18 and randf() < 0.5:
			GameState.add_log("I was expelled from university for failing grades.")
			GameState.add_milestone(age, "was expelled from university")
			GameState.apply_effects({"happiness": -12, "stress": 8})
			e["uni"] = {}
			if p["housing"] == "dorm":
				p["housing"] = "parents"
			return
		if int(u["year"]) >= int(u["years"]) and float(u["performance"])<45:
			u["resits"]=int(u.get("resits",0))+1
			if int(u["resits"])<=2:
				u["year"]=int(u["years"])-1
				GameState.add_log("My final grades were below the passing standard. I need a repeat year before earning this qualification.")
			else:
				GameState.add_log("I left my course without the qualification after repeated unsuccessful final assessments.")
				e["uni"]={}
				if p["housing"]=="dorm": p["housing"]="parents"
			return
		if int(u["year"]) >= int(u["years"]):
			var m := ContentDB.major(u["major"])
			e["degrees"].append({"major": u["major"], "level": u["level"], "name": m.get("degree", m.get("name", ""))})
			GameState.counter("degrees")
			GameState.add_log("I graduated with a %s!" % m.get("degree", "degree"))
			GameState.add_milestone(age, "earned a %s" % m.get("degree", "degree"))
			GameState.apply_effects({"happiness": 12, "smarts": 4})
			e["uni"] = {}
			if p["housing"] == "dorm":
				p["housing"] = "parents"
		else:
			GameState.add_log("I finished year %d of %s (%s)." % [int(u["year"]), ContentDB.major(u["major"]).get("name", ""), grade_letter(float(u["performance"]))])


func _update_performance(d: Dictionary, key: String) -> void:
	var perf := float(d.get(key, 50.0))
	var smarts := Aptitude.score("education")
	perf += (smarts - perf) * 0.25 + randf_range(-8.0, 8.0) + (GameState.hidden("discipline") - 50.0) * 0.08
	if GameState.player["education"]["studied"]:
		perf += 8
	if GameState.has_trait("Bookworm"):
		perf += 4
	if GameState.has_trait("Lazy"):
		perf -= 5
	for rel in ["mother", "father"]:
		for pid in GameState.npcs_with(rel):
			if Web.job_of(pid) == "teacher" and int(GameState.npcs[pid]["closeness"]) >= 50:
				perf += 4
	if GameState.stat("stress") > 70:
		perf -= 4
	d[key] = clampf(perf, 0.0, 100.0)


static func grade_letter(perf: float) -> String:
	if perf >= 85: return "A"
	if perf >= 70: return "B"
	if perf >= 55: return "C"
	if perf >= 40: return "D"
	return "F"


static func grade_points(letter: String) -> float:
	return {"A": 4.0, "B": 3.0, "C": 2.0, "D": 1.0, "F": 0.0}.get(letter, 0.0)


func _yearly_job() -> void:
	var p := GameState.player
	if not GameState.has_job():
		return
	var j: Dictionary = p["job"]
	var jd := ContentDB.job(j["id"])
	j["years"] = int(j["years"]) + 1
	j["years_in_rank"] = int(j["years_in_rank"]) + 1
	var perf := float(j["perf"]) + randf_range(-7.0,5.0)+(Aptitude.score("work")-50.0)*0.16+(GameState.hidden("discipline")-50.0)*0.05
	if j.get("worked_hard", false):
		perf += 10
	if GameState.has_trait("Ambitious"):
		perf += 3
	if GameState.has_trait("Lazy"):
		perf -= 4
	j["perf"] = clampf(perf, 0.0, 100.0)
	GameState.change_stat("stress", float(jd.get("stress", 4)) * 0.6)
	Workforce.review()


func _yearly_finances() -> void:
	var p := GameState.player
	var year := GameState.year_now()
	if not GameState.is_alive() or int(p.get("finances_year",-1))>=year: return
	p["finances_year"]=year
	var age: int = p["age"]
	var c := ContentDB.country(p["country"])
	var cost: float = c.get("cost", 1.0)
	var income := 0
	var expenses := 0
	var bill_lines := {}
	var booked := Employment.take_income()
	income += int(booked["amount"])
	var income_sources: Dictionary=booked["sources"].duplicate(true)
	var already_paid := 0
	for category in booked.get("paid_expenses",{}): already_paid+=int(booked["paid_expenses"][category])
	if GameState.has_job():
		var wages := int(int(p["job"]["salary"]) * Employment.pay_factor() * (1.0 - Places.tax()))
		income += wages
		income_sources["Work pay"]=wages
		var union_dues := int(p["job"].get("union_dues_due",0))
		if union_dues>0: bill_lines["Union dues"]=union_dues
	if p["retired"]:
		var pension := int(p["pension"])
		income += pension
		if pension>0: income_sources["Pension"]=pension
	if not Childhood.supported() and not GameState.in_prison():
		match p["housing"]:
			"parents": bill_lines["Living costs at home"]=int(2500*cost)
			"dorm": bill_lines["Dorm and living costs"]=int(6000*cost)
			"apartment":
				bill_lines["Living costs"]=int(11000*cost)
				bill_lines["My rent share"]=int(Tenancy.annual_rent()*cost)
			"house": bill_lines["Living costs"]=int(11000*cost)
		if int(p["mortgage"]) > 0:
			var pay := mini(int(p["mortgage"]), int(p["mortgage_payment"]))
			p["mortgage"] = int(p["mortgage"]) - pay
			bill_lines["Mortgage payment"]=pay
			if int(p["mortgage"]) == 0:
				GameState.add_log("I paid off my mortgage!")
				GameState.add_milestone(age, "paid off the house")
		if p["car"] != "":
			bill_lines["Vehicle upkeep"]=int(GameState.CARS[p["car"]]["upkeep"]*cost)
		bill_lines["Transport, utilities and keeping in touch"]=int(Real.extra_costs()*cost)
		bill_lines["Household service"]=int(Household.service_cost()*cost)
		for cid in GameState.npcs_with("child")+GameState.npcs_with("stepchild"):
			if int(GameState.npcs[cid]["age"]) < 18:
				bill_lines["Dependent support"]=int(bill_lines.get("Dependent support",0))+int(7000*cost*Journey.modules["people"].support_factor(cid))
		if int(p["loan"]) > 0 and income > 0:
			var lp := mini(int(p["loan"]), maxi(1500, int(p["loan"]) / 8))
			p["loan"] = int(p["loan"]) - lp
			bill_lines["Education loan repayment"]=lp
	for category in bill_lines:
		if category not in ["Mortgage payment","Education loan repayment","Union dues"]: bill_lines[category]=int(int(bill_lines[category])*Grit.d("cost")*World.cost_mult()*Places.cost_mult())
		expenses+=int(bill_lines[category])
	for category in booked.get("paid_expenses",{}):
		bill_lines[category]=int(bill_lines.get(category,0))+int(booked["paid_expenses"][category])
	expenses+=already_paid
	p["household_ledger"]={"year":GameState.year_now(),"income":income,"expenses":expenses,"lines":bill_lines,"income_sources":income_sources}
	p["money"] = int(p["money"]) + income - expenses - int(booked["amount"]) + already_paid
	Childhood.protect()
	if GameState.in_university() and int(p["money"]) < 0:
		p["loan"] = int(p["loan"]) - int(p["money"])
		p["money"] = 0
	# Only the negative-cash increase attributable to current recurring home
	# bills is eligible for reserve cover. Older debt and student-loan financing
	# do not manufacture a second household reimbursement allowance.
	var home_bills: int = Journey.modules["funds"].bill_cost(bill_lines)
	var negative_cash := maxi(0,-int(p["money"]))
	p["household_ledger"]["reserve_shortfall"]=maxi(0,negative_cash-maxi(0,negative_cash-int(home_bills)))
	p["last_income"] = income
	p["last_expenses"] = expenses
	if income > 0 and expenses > 0:
		GameState.add_log("I earned %s; living costs and bills came to %s." % [GameState.fmt_money(income), GameState.fmt_money(expenses)])
	elif income > 0:
		GameState.add_log("I earned %s this year." % GameState.fmt_money(income))
	elif expenses > 0:
		GameState.add_log("Living costs and bills came to %s%s." % [GameState.fmt_money(expenses), " (added to my student loans)" if GameState.in_university() else ""])
	if int(p["money"]) < 0 and age >= 18:
		GameState.apply_effects({"stress": 6, "happiness": -4})
		if int(p["money"]) < -15000 and p["housing"] == "apartment":
			var fam := GameState.first_of("mother")
			if fam == "":
				fam = GameState.first_of("father")
			p["housing"] = "parents" if fam != "" else "homeless"
			GameState.add_log("I couldn't pay rent and was evicted." + (" I moved back in with family." if fam != "" else " I have nowhere to go."))
			GameState.add_milestone(age, "was evicted")
		elif int(p["money"]) < -60000 and p["housing"] == "house":
			GameState.add_log("The bank foreclosed on my house.")
			GameState.add_milestone(age, "lost the house to foreclosure")
			p["housing"] = "apartment"
			p["house_value"] = 0
			p["mortgage"] = 0
			p["mortgage_payment"] = 0
	elif p["housing"] == "homeless" and int(p["money"]) > 20000:
		p["housing"] = "apartment"
		GameState.add_log("I finally saved enough to rent an apartment.")


func _yearly_prison() -> void:
	var p := GameState.player
	if int(p["prison"]) <= 0:
		Actions.fugitive_yearly()
		return
	p["prison"] = int(p["prison"]) - 1
	if int(p["prison"]) > 0 and str(p.get("prison_gang", "")) == "" and int(p.get("prison_rep", 20)) < 40 and randf() < 0.18:
		GameState.apply_effects({"health": -10, "happiness": -5})
		GameState.add_log("An inmate jumped me in the yard. I need friends in here, or a reputation.")
	elif int(p.get("prison_job_years", 0)) > 0 and int(p["prison"]) > 1 and randf() < 0.08:
		p["prison"] = int(p["prison"]) - 1
		GameState.add_log("My work record earned me a year off for good conduct.")
	p["prison_total"] = int(p["prison_total"]) + 1
	GameState.apply_effects({"happiness": -6, "health": -2})
	if int(p["prison"]) == 0:
		p["prison_gang"] = ""
		p["prison_rep"] = 20
		p["prison_job_years"] = 0
		GameState.add_log("I was released from prison.")
		GameState.add_milestone(p["age"], "was released from prison")
		GameState.apply_effects({"happiness": 15})
	else:
		GameState.add_log("Another year behind bars. %d to go." % int(p["prison"]))


func _death_check() -> String:
	var lc := Lives.death_check()
	if lc != "__natural":
		return lc
	var p := GameState.player
	var age: int = p["age"]
	var health := GameState.stat("health")
	if health <= 0 and age < 65 and not p.get("hospitalized", false):
		p["hospitalized"] = true
		GameState.player["stats"]["health"] = 15.0
		GameState.add_log("I collapsed and was rushed to the hospital. The doctors pulled me through, barely.")
		var bill := int(Actions._cost(45000) * Places.healthcare_mult())
		if bill > 0:
			if Childhood.supported(): Childhood.cover(bill,"hospital care")
			else: p["money"] = int(p["money"]) - bill
			GameState.add_log("The hospital bill came to %s." % GameState.fmt_money(bill))
		Grit.scar_chance("weak_heart", 0.35)
		GameState.add_milestone(age, "survived a health scare")
		push_info("🚑", "Hospitalized", "You collapsed and spent weeks in the hospital.\n\nThe doctor says your body can't take much more. Rest, see a doctor, and lower your stress.")
		return ""
	if health <= 0:
		if SERIOUS.has(p["illness"]):
			return p["illness"]
		return "old age" if age >= 70 else "complications from poor health"
	var chance := 0.0
	if age >= 50:
		chance = pow((age - 50) / 48.0, 4)
		chance *= lerpf(2.2, 0.6, health / 100.0)
	if age >= 108:
		chance = maxf(chance, 0.5)
	chance *= World.mortality()
	if randf() < chance:
		var pool := ["old age", "heart failure", "a stroke", "pneumonia", "natural causes"]
		if SERIOUS.has(p["illness"]):
			pool.append(p["illness"])
		return pool[randi() % pool.size()]
	if age >= 16 and randf() < 0.0007:
		var acc := ["a car accident", "a freak accident", "a fall down the stairs"]
		return acc[randi() % acc.size()]
	return ""


func kill(cause: String, force: bool = false) -> void:
	var p := GameState.player
	if not force and Grit.has_boon("second_wind") and not GameState.has_flag("second_wind_used") and int(p["age"]) < 100:
		GameState.set_flag("second_wind_used")
		p["stats"]["health"] = maxf(25.0, GameState.stat("health"))
		GameState.add_log("I should have died of %s. Somehow, I didn't." % cause)
		GameState.add_milestone(p["age"], "cheated death (%s)" % cause)
		GameState.counter("cheated_death")
		push_info("💨", "Second Wind", "By every right you should have died of %s.

You didn't. Don't waste it." % cause)
		return
	p["life"]["can_rise"] = Lives.can_rise() and cause not in ["peace at last", "walking into the sunrise", "crumbling to dust"]
	pending.clear()
	var entry := GameState.finalize_death(cause)
	displayed.clear()
	Meta.record_death(entry)
	Legacy.record(entry)
	Goals.on_death()
	GameState.player["legacy"]["unlocks"] = Goals.life_unlocks.duplicate()
	entry = GameState.player["legacy"]
	entry["badge"] = GameState.player.get("badge", "")
	SaveManager.add_to_graveyard(entry)
	SaveManager.save_game()
	died.emit(entry)


# ---------------------------------------------------------------- event selection

func _due_followups() -> void:
	var age: int = GameState.player["age"]
	var keep: Array = []
	for f in GameState.followups:
		if int(f["age"]) > age:
			keep.append(f)
			continue
		var def: Dictionary = ContentDB.events_by_id.get(f["event"], {})
		if def.is_empty():
			continue
		var roles_alive := true
		for r in f["roles"].keys():
			var id: String = f["roles"][r]
			var spec: Dictionary = def.get("roles",{}).get(r,{})
			var remember_dead: bool = spec.get("bound",false) and spec.get("allow_dead",false)
			if not GameState.npcs.has(id) or (not GameState.npcs[id]["alive"] and not remember_dead):
				roles_alive = false
		if not roles_alive:
			continue
		if _eligible(def, true) and _enqueue(def, f["roles"]):
			continue
		if int(f.get("retries", 0)) < 15:
			f["age"] = age + 1
			f["retries"] = int(f.get("retries", 0)) + 1
			keep.append(f)
	GameState.followups = keep


func _random_events() -> void:
	if LifeCourse.monthly_mode(): return
	var count := Director.random_count()
	var pool: Array = []
	var recent: Dictionary = Meta.meta.get("recent", {})
	var life_no := Goals.stat_total("lives")
	for def in ContentDB.events:
		if def.get("followup_only", false) or def.get("twist", false) or def.get("conditions", {}).has("agency"):
			continue
		if _eligible(def, false):
			var w := float(def.get("weight", 1.0))
			if recent.has(def["id"]):
				var ago := life_no - int(recent[def["id"]])
				w *= [0.25, 0.25, 0.45, 0.7][clampi(ago, 0, 3)] if ago < 4 else 1.0
			w = Director.weight(def, w)
			pool.append({"def": def, "w": w})
	var picked := 0
	var guard := 0
	while picked < count and not pool.is_empty() and guard < 30:
		guard += 1
		var fresh_defs := Novelty.prefer(pool.map(func(e): return e["def"]))
		var fresh_pool := pool.filter(func(e): return fresh_defs.has(e["def"]))
		var focus_pool: Array = fresh_pool.filter(func(e): return Context.focus(e["def"]))
		var entry := _weighted_pick(focus_pool if picked == 0 and not focus_pool.is_empty() else fresh_pool, "w")
		if entry.is_empty():
			break
		pool.erase(entry)
		if _enqueue(entry["def"], {}):
			picked += 1


func _npc_agency() -> void:
	if GameState.in_prison() or GameState.player["age"] < 6 or randf() > 0.35:
		return
	# Agency only ever fired for closeness 72+ or 28-, which meant most of the
	# cast never did anything at all. The middle band gets something small.
	if randf() < 0.4 and NpcWorld.neutral_beat():
		return
	var candidates: Array = []
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if n["alive"] and AGENCY_RELATIONS.has(n["relation"]) and n.get("species", "human") == "human":
			var c: int = n["closeness"]
			if c >= 72 or c <= 28:
				candidates.append(id)
	if candidates.is_empty():
		return
	var id: String = candidates[randi() % candidates.size()]
	var n: Dictionary = GameState.npcs[id]
	var mood := "good" if int(n["closeness"]) >= 72 else "bad"
	var pool: Array = []
	for def in ContentDB.events:
		var cond: Dictionary = def.get("conditions", {})
		if cond.get("agency", "") != mood:
			continue
		var rels: Array = cond.get("them_relations", [])
		if not rels.is_empty() and not rels.has(n["relation"]):
			continue
		if _eligible(def, false):
			pool.append(def)
	if pool.is_empty():
		return
	_enqueue(_weighted_pick(Novelty.prefer(pool), "weight"), {"them": id})


func _eligible(def: Dictionary, followup: bool) -> bool:
	if not followup and not Journey.modules["identity"].definition_allowed(def): return false
	var p := GameState.player
	var cond: Dictionary = def.get("conditions", {})
	var age: int = p["age"]
	if def.get("mature", false):
		if age < 18: return false
		if not followup and not GameState.settings.get("mature_arcs", true): return false
	if not Context.world_matches(def) or not Context.matches(cond.get("context", {})):
		return false
	# A separate mode only ever sees the events written for it.
	if Lives.separate() and not cond.has("life"):
		return false
	if not followup:
		if Novelty.optional(def) and not Novelty.eligible(def): return false
		if Director.repeated(def): return false
		if cond.has("age"):
			var r: Array = cond["age"]
			if age < int(r[0]) or age > int(r[1]):
				return false
		var hist = GameState.event_history.get(def["id"], null)
		if hist != null:
			if def.get("once", false):
				return false
			if age - int(hist) < maxi(5, int(def.get("cooldown", 5))):
				return false
		if cond.has("chance") and randf() > float(cond["chance"]):
			return false
	if not cond.get("prison_any", false) and bool(cond.get("prison", false)) != GameState.in_prison():
		return false
	for f in cond.get("flags", []):
		if not GameState.has_flag(f):
			return false
	for f in cond.get("not_flags", []):
		if GameState.has_flag(f):
			return false
	if cond.has("traits_any"):
		var ok := false
		for t in cond["traits_any"]:
			if GameState.has_trait(t):
				ok = true
		if not ok:
			return false
	if cond.has("employed") and bool(cond["employed"]) != GameState.has_job():
		return false
	if cond.has("job"):
		var jid: String = str(p.get("job", {}).get("id", "")) if p.get("job", {}) is Dictionary else ""
		var want_job = cond["job"]
		if want_job is Array:
			if not Array(want_job).has(jid):
				return false
		elif str(want_job) != jid:
			return false
	if cond.has("job_id"):
		var current_job_id: String = str(p.get("job", {}).get("id", "")) if p.get("job", {}) is Dictionary else ""
		var required_job = cond["job_id"]
		if required_job is Array:
			if not Array(required_job).has(current_job_id):
				return false
		elif str(required_job) != current_job_id:
			return false
	if cond.has("habit_active"):
		for hid in Array(cond["habit_active"]):
			if not Grit.active_habits().has(str(hid)):
				return false
	if cond.has("habit_min"):
		for hid2 in cond["habit_min"].keys():
			if float(p.get("habits", {}).get(hid2, {}).get("level", 0.0)) < float(cond["habit_min"][hid2]):
				return false
	if cond.has("habit_max"):
		for hid3 in cond["habit_max"].keys():
			if float(p.get("habits", {}).get(hid3, {}).get("level", 0.0)) > float(cond["habit_max"][hid3]):
				return false
	if cond.has("in_school") and bool(cond["in_school"]) != GameState.in_school():
		return false
	if cond.has("hs_graduated") and bool(cond["hs_graduated"]) != bool(p.get("education", {}).get("hs_graduated", false)):
		return false
	if cond.has("university") and bool(cond["university"]) != GameState.in_university():
		return false
	if cond.has("has_partner") and bool(cond["has_partner"]) != (p["partner"] != ""):
		return false
	if cond.has("relationship_agreement"):
		var partner_id := str(p.get("partner", ""))
		if partner_id=="" or not GameState.npcs.has(partner_id) or not GameState.npc(partner_id).get("alive",false): return false
		var agreement: String=Journey.modules["identity"].agreement_for(partner_id)
		var expected = cond["relationship_agreement"]
		if expected is Array:
			if not Array(expected).has(agreement): return false
		elif str(expected)!=agreement: return false
	if cond.has("married") and bool(cond["married"]) != (p["partner_status"] == "married"):
		return false
	if cond.has("has_children") and bool(cond["has_children"]) != (not GameState.npcs_with("child").is_empty()):
		return false
	for rt in cond.get("real", []):
		if not Real.tag(str(rt)):
			return false
	for rt2 in cond.get("not_real", []):
		if Real.tag(str(rt2)):
			return false
	for pt in cond.get("pet", []):
		if not Pets.tag(str(pt)):
			return false
	for pt2 in cond.get("not_pet", []):
		if Pets.tag(str(pt2)):
			return false
	for prt in cond.get("pr", []):
		if not Prison.tag(str(prt)):
			return false
	for prt2 in cond.get("not_pr", []):
		if Prison.tag(str(prt2)):
			return false
	if cond.has("has_car") and bool(cond["has_car"]) != (p["car"] != ""):
		return false
	if cond.has("housing") and not Array(cond["housing"]).has(p["housing"]):
		return false
	if cond.has("min_money") and int(p["money"]) < int(cond["min_money"]):
		return false
	if cond.has("retired") and bool(cond["retired"]) != bool(p["retired"]):
		return false
	var car: Dictionary = p.get("career", {})
	if cond.has("career"):
		var want = cond["career"]
		var have: String = car.get("id", "none")
		if want is Array:
			if not Array(want).has(have):
				return false
		elif str(want) != have:
			return false
	if cond.has("career_rank_min") and int(car.get("rank", -1)) < int(cond["career_rank_min"]):
		return false
	if cond.has("in_office") and bool(cond["in_office"]) != bool(car.get("in_office", false)):
		return false
	if cond.has("min_fame") and float(p.get("fame", 0)) < float(cond["min_fame"]):
		return false
	if cond.has("celebrity") and bool(cond["celebrity"]) != bool(p.get("celebrity", false)):
		return false
	if cond.has("has_property") and bool(cond["has_property"]) != (not p.get("properties", []).is_empty()):
		return false
	if cond.has("has_investments") and bool(cond["has_investments"]) != (Finance.investments_value() > 0):
		return false
	if cond.has("has_possessions") and bool(cond["has_possessions"]) != (not p.get("possessions", []).is_empty()):
		return false
	if cond.has("license") and not Law.has_license(cond["license"]):
		return false
	if cond.has("min_stat"):
		for k in cond["min_stat"].keys():
			if GameState.stat(k) < float(cond["min_stat"][k]):
				return false
	if cond.has("life"):
		var lt = cond["life"]
		if lt is Array:
			if not Array(lt).has(Lives.kind()):
				return false
		elif str(lt) != Lives.kind():
			return false
	if cond.has("has_condition") and not Expansion.has_condition(str(cond["has_condition"])):
		return false
	if cond.has("has_injury") and not Expansion.has_injury(str(cond["has_injury"])):
		return false
	if cond.has("has_mental") and not Expansion.has_mental(str(cond["has_mental"])):
		return false
	if cond.has("home_owned") and bool(cond["home_owned"]) != Expansion.home_owned():
		return false
	if cond.has("home_upgrade") and not Expansion.home_has(str(cond["home_upgrade"])):
		return false
	if cond.has("min_casino_won") and int(GameState.player.get("casino", {}).get("won", 0)) < int(cond["min_casino_won"]):
		return false
	if cond.has("era_year_min") and Expansion.era_year() < int(cond["era_year_min"]):
		return false
	if cond.has("era_year_max") and Expansion.era_year() > int(cond["era_year_max"]):
		return false
	if cond.has("crowned") and bool(cond["crowned"]) != bool(Lives.life().get("crowned", false)):
		return false
	if cond.has("max_respect") and float(Lives.life().get("respect", 100)) > float(cond["max_respect"]):
		return false
	if cond.has("super_side") and str(Lives.life().get("side", "")) != str(cond["super_side"]):
		return false
	if cond.has("min_net_worth") and GameState.net_worth() < int(cond["min_net_worth"]):
		return false
	if cond.has("world") and not World.active(str(cond["world"])):
		return false
	if cond.has("region_hazard") and str(Places.region().get("hazard", "")) != str(cond["region_hazard"]):
		return false
	if cond.has("region_cost_min") and float(Places.region().get("cost", 1.0)) < float(cond["region_cost_min"]):
		return false
	if cond.has("max_stat"):
		for k in cond["max_stat"].keys():
			if GameState.stat(k) > float(cond["max_stat"][k]):
				return false
	if cond.has("has_business") and bool(cond["has_business"]) != (not p.get("business", {}).is_empty()):
		return false
	if cond.has("biz_ind") and not Array(cond["biz_ind"]).has(p.get("business", {}).get("ind", "")):
		return false
	if cond.has("public_company") and bool(cond["public_company"]) != bool(p.get("business", {}).get("public", false)):
		return false
	if cond.has("cooked_books") and bool(cond["cooked_books"]) != bool(p.get("business", {}).get("cooked", false)):
		return false
	if cond.has("has_cult") and bool(cond["has_cult"]) != (not p.get("cult", {}).is_empty()):
		return false
	if cond.has("min_members") and int(p.get("cult", {}).get("members", 0)) < int(cond["min_members"]):
		return false
	if cond.has("doctrine") and p.get("cult", {}).get("doctrine", "") != cond["doctrine"]:
		return false
	if cond.has("has_zoo") and bool(cond["has_zoo"]) != (not p.get("zoo", {}).is_empty()):
		return false
	if cond.has("zoo_animal") and not p.get("zoo", {}).get("animals", {}).has(cond["zoo_animal"]):
		return false
	if cond.has("min_heat") and float(p.get("heat", 0)) < float(cond["min_heat"]):
		return false
	if cond.has("max_heat") and float(p.get("heat", 0)) > float(cond["max_heat"]):
		return false
	if cond.has("past_career"):
		var any := false
		for pc in Array(cond["past_career"]):
			if Careers.past(pc):
				any = true
		if not any:
			return false
	if cond.has("min_trips") and int(p.get("journal", {}).get("trips", 0)) < int(cond["min_trips"]):
		return false
	if cond.has("has_pet") and bool(cond["has_pet"]) != (not GameState.npcs_with("pet").is_empty()):
		return false
	if cond.has("has_record") and bool(cond["has_record"]) != (not p["record"].is_empty()):
		return false
	if not Ambition.event_condition(cond):
		return false
	return true


func _weighted_pick(list: Array, key: String) -> Dictionary:
	if list.is_empty():
		return {}
	var total := 0.0
	for d in list:
		total += float(d.get(key, 1.0))
	var r := randf() * total
	for d in list:
		r -= float(d.get(key, 1.0))
		if r <= 0.0:
			return d
	return list[-1]


func _build_roles(def: Dictionary, preset: Dictionary) -> Dictionary:
	var roles := {}
	var specs: Dictionary = def.get("roles", {})
	var to_create: Array = []
	for role in specs.keys():
		var spec: Dictionary = specs[role]
		# A delayed family memory belongs to the original person, even after
		# death or a change of relationship. Never substitute another relative.
		if spec.get("bound", false):
			if preset.has(role) and GameState.npcs.has(preset[role]) and (GameState.npcs[preset[role]]["alive"] or spec.get("allow_dead",false)):
				roles[role] = preset[role]
				continue
			return {"__fail":true}
		if preset.has(role) and GameState.npcs.has(preset[role]) and GameState.npcs[preset[role]]["alive"]:
			roles[role] = preset[role]
			continue
		if spec.has("new"):
			to_create.append(role)
			continue
		if spec.has("from"):
			var pool: Array = []
			match str(spec["from"]):
				"biz_crew": pool = GameState.player.get("business", {}).get("crew", [])
				"cult_inner": pool = GameState.player.get("cult", {}).get("inner", [])
				"zoo_crew": pool = GameState.player.get("zoo", {}).get("crew", [])
				"exotic_pet":
					for pid in GameState.npcs_with("pet"):
						if GameState.npcs[pid].get("exotic", false):
							pool.append(pid)
			var alive_pool: Array = pool.filter(func(x): return GameState.npcs.has(x) and GameState.npcs[x]["alive"])
			if alive_pool.is_empty():
				if spec.get("optional", false):
					continue
				return {"__fail": true}
			roles[role] = alive_pool[randi() % alive_pool.size()]
			continue
		if spec.has("contact"):
			var cid := Web.contact(Array(spec["contact"]), int(spec.get("min_close", 50)))
			if cid != "":
				roles[role] = cid
			elif not spec.get("optional", false):
				return {"__fail": true}
			continue
		var rels: Array = spec.get("relation_any", [spec.get("relation", "")])
		var constrained := spec.has("min_age") or spec.has("max_age") or spec.has("min_close") or spec.has("max_close")
		var id := ""
		if constrained:
			var eligible_people: Array = []
			for candidate_id in GameState.npcs.keys():
				var candidate: Dictionary = GameState.npcs[candidate_id]
				if not candidate.get("alive", false) or not rels.has(str(candidate.get("relation", ""))): continue
				if spec.has("min_age") and int(candidate.get("age", 0)) < int(spec["min_age"]): continue
				if spec.has("max_age") and int(candidate.get("age", 0)) > int(spec["max_age"]): continue
				if spec.has("min_close") and float(candidate.get("closeness", 0)) < float(spec["min_close"]): continue
				if spec.has("max_close") and float(candidate.get("closeness", 100)) > float(spec["max_close"]): continue
				eligible_people.append(str(candidate_id))
			if not eligible_people.is_empty(): id = str(eligible_people.pick_random())
		else:
			id = GameState.random_of(rels)
		if id == "":
			if spec.get("or_new", false):
				to_create.append(role)
				continue
			return {"__fail": true}
		roles[role] = id
	for role in preset.keys():
		if not roles.has(role) and GameState.npcs.has(preset[role]):
			roles[role] = preset[role]
	var created: Array = []
	for role in to_create:
		var spec: Dictionary = specs[role]
		var rel: String = spec.get("new", spec.get("relation", "friend"))
		var age: int = GameState.player["age"]
		var a = spec.get("age", "same")
		if a is Array:
			age = randi_range(int(a[0]), int(a[1]))
		else:
			age = maxi(0, age + randi_range(-1, 1))
		var opts := {"age": age, "closeness": int(spec.get("closeness", 45))}
		if spec.has("gender"):
			opts["gender"] = spec["gender"]
		if spec.has("species"):
			opts["species"] = spec["species"]
			opts["first"] = ContentDB.random_pet_name()
			opts["last"] = ""
		roles[role] = GameState.create_npc(rel, opts)
		created.append(roles[role])
	roles["__created"] = created
	return roles


func _enqueue(def0: Dictionary, preset: Dictionary) -> bool:
	var def := def0
	if def0.get("text", "") is Array:
		def = def0.duplicate()
		var tv: Array = def0["text"]
		def["text"] = tv[randi() % tv.size()]
	var roles := _build_roles(def, preset)
	if roles.has("__fail"):
		return false
	var created: Array = roles.get("__created", [])
	roles.erase("__created")
	var previous_age = GameState.event_history.get(def["id"], null)
	GameState.event_history[def["id"]] = GameState.player["age"]
	if not def.has("choices"):
		Director.note(def)
		if def.has("outcomes"):
			_apply_outcome(_pick_outcome(def["outcomes"]), roles, def)
		else:
			GameState.apply_effects(def.get("effects", {}),true)
			GameState.add_log(tokens(def.get("text", ""), roles))
		return true
	pending.append({"def": def, "roles": roles, "created": created, "previous_age": previous_age})
	return true


# ---------------------------------------------------------------- resolving choices

func choice_state(choice: Dictionary, roles: Dictionary = {}) -> Dictionary:
	var req: Dictionary = choice.get("requires", {})
	var p := GameState.player
	if req.has("time") and int(p["time_left"]) < int(req["time"]):
		return {"visible":true,"enabled":false,"reason":"Needs %d time" % int(req["time"])}
	if req.has("role") and not roles.has(req["role"]):
		return {"visible": false, "enabled": false, "reason": ""}
	if req.has("trait") and not GameState.has_trait(req["trait"]):
		return {"visible": false, "enabled": false, "reason": ""}
	if req.has("money") and int(p["money"]) < int(req["money"]):
		return {"visible": true, "enabled": false, "reason": "Needs " + GameState.fmt_money(int(req["money"]))}
	if req.has("min_stat"):
		for k in req["min_stat"].keys():
			if GameState.stat(k) < float(req["min_stat"][k]):
				return {"visible": true, "enabled": false, "reason": "Needs more %s" % k.capitalize()}
	for k in ["business", "cult", "zoo"]:
		if req.has("has_" + k) and p.get(k, {}).is_empty():
			return {"visible": false, "enabled": false, "reason": ""}
	if req.has("has_car") and p["car"] == "":
		return {"visible": true, "enabled": false, "reason": "Needs a car"}
	var hint := ""
	if choice.has("travel"):
		hint = str(Transit.reach(str(choice["travel"]))["hint"])
	return {"visible": true, "enabled": true, "reason": req.get("trait", ""), "hint": hint}


func resolve(inst: Dictionary, index: int) -> Dictionary:
	displayed.clear()
	var def: Dictionary = inst["def"]
	var choice: Dictionary = def["choices"][index]
	var roles: Dictionary = inst.get("roles", {})
	var before := Insight.snapshot(roles.values())
	Depth.remember(def,index,inst.get("roles",{}))
	var outcome := _pick_outcome(choice.get("outcomes", [{"text": ""}]), str(choice.get("travel", "")))
	var fr := Friction.apply(choice, outcome, def)
	if outcome.has("tv_reflection"): TVLife.reflect(outcome["tv_reflection"])
	var res := _apply_outcome(outcome, roles, def, fr)
	if def.get("discard_unkept", false):
		var created: Array = inst.get("created", [])
		var kr = outcome.get("keep_role", "")
		var keeps: Array = kr if kr is Array else [kr]
		keeps.append_array(outcome.get("relation_change", {}).keys())
		if outcome.has("new_partner"):
			keeps.append(outcome["new_partner"])
		for r in roles.keys():
			if not keeps.has(r) and created.has(roles[r]) and GameState.npcs.has(roles[r]):
				GameState.npcs.erase(roles[r])
	GameState.emit_changed()
	Insight.record(before, tokens(str(def.get("title","Decision")), roles), str(res.get("text", "")), roles.values())
	Insight.remember_choice(def,index)
	SaveManager.save_game()
	return res


func _pick_outcome(outcomes: Array, travel: String = "") -> Dictionary:
	var weighted: Array = []
	var reach_m := float(Transit.reach(travel)["mult"]) if travel != "" else 1.0
	for o in outcomes:
		var w := float(o.get("weight", 1.0))
		if o.has("good") and travel != "":
			w *= reach_m if bool(o["good"]) else 1.0 / reach_m
		for t in o.get("trait_bonus", {}).keys():
			if GameState.has_trait(t):
				w *= float(o["trait_bonus"][t])
		for k in o.get("stat_bonus", {}).keys():
			var f := float(o["stat_bonus"][k])
			w *= maxf(0.1, 1.0 + (GameState.stat(k) - 50.0) / 50.0 * f)
		if o.get("fight_win", false) and GameState.player.get("modifiers", []).has("brass_knuckles"):
			w *= 1000.0
		if o.has("karma_bonus"):
			var kv := float(GameState.player["karma"]) + (40.0 if Grit.has_boon("lucky_star") else 0.0) + (60.0 if GameState.has_flag("luck_spell") else 0.0)
			w *= maxf(0.1, 1.0 + kv / 100.0 * float(o["karma_bonus"]))
		weighted.append({"o": o, "w": w})
	var pick := _weighted_pick(weighted, "w")
	return pick.get("o", {})


## A compact before-picture, so the engine can report what an outcome actually
## DID rather than leaving the UI to guess from the sentence. Moments turns
## these into sound and colour; see autoload/moments.gd.
func _snapshot() -> Dictionary:
	var p := GameState.player
	return {
		"kids": GameState.npcs_with("child", false).size(),
		"partner": str(p.get("partner", "")),
		"illness": str(p.get("illness", "")),
		"record": (p.get("record", []) as Array).size(),
		"fame": float(p.get("fame", 0.0)),
		"job": str(p.get("job", {}).get("id", "")) if p.get("job", {}) is Dictionary else "",
		"miles": (p.get("milestones", []) as Array).size(),
		"kind": Lives.kind(),
	}


## What happened, structurally. Never a reading of the prose.
func _signals(o: Dictionary, before: Dictionary) -> Array:
	var p := GameState.player
	var s: Array = []
	for key in ["crime", "fine", "trial", "jail", "illness", "cure", "marry", "fired", "quit_job", "milestone"]:
		if not o.has(key):
			continue
		var v = o[key]
		# A flag-style key is only a signal when it is switched on; a valued key
		# (an illness name, a fine amount) is a signal by being present at all.
		if v is bool and not v:
			continue
		s.append(key)
	if o.get("clear_record", false):
		s.append("cleared")
	if o.has("take_office"):
		s.append("office")
	if o.has("career_start"):
		s.append("hired")
	if GameState.npcs_with("child", false).size() > int(before.get("kids", 0)):
		s.append("baby")
	var partner_now := str(p.get("partner", ""))
	if partner_now != str(before.get("partner", "")):
		s.append("partner_lost" if partner_now == "" else "partner_gained")
	if str(p.get("illness", "")) != str(before.get("illness", "")) and str(p.get("illness", "")) != "":
		if not s.has("illness"):
			s.append("illness")
	if (p.get("record", []) as Array).size() > int(before.get("record", 0)) and not s.has("crime"):
		s.append("crime")
	if float(p.get("fame", 0.0)) - float(before.get("fame", 0.0)) >= 8.0:
		s.append("fame")
	if (p.get("milestones", []) as Array).size() > int(before.get("miles", 0)) and not s.has("milestone"):
		s.append("milestone")
	if Lives.kind() != str(before.get("kind", "human")):
		s.append("became_" + Lives.kind())
	if not GameState.is_alive():
		s.append("died")
	return s


func _apply_outcome(o: Dictionary, roles: Dictionary, def: Dictionary, fr: Dictionary = {}) -> Dictionary:
	if o.get("restore_checkpoint",false):
		return {"text":"Checkpoint restored." if SaveManager.restore_checkpoint() else "Checkpoint could not be restored; current progress was kept.","changes":{},"signals":[]}
	var p := GameState.player
	var _before := _snapshot()
	var raw = o.get("text", "")
	if raw is Array:
		raw = raw[randi() % raw.size()] if not raw.is_empty() else ""
	var text := tokens(str(raw), roles)
	var band := str(fr.get("band", "clean"))
	var scale := float(fr.get("scale", 1.0))
	var eff: Dictionary = Friction.scale_effects(o.get("effects", {}), scale)
	for k in fr.get("effects", {}).keys():
		eff[k] = float(eff.get(k, 0.0)) + float(fr["effects"][k])
	var changes := GameState.apply_effects(eff,not str(def.get("id", "")).begins_with("_"))
	if band != "clean" and str(fr.get("note", "")) != "":
		text = (text + " " if text != "" else "") + str(fr["note"])
	# Personal effects belong to the named person, independently of the bond.
	for person_role in o.get("npc_effects", {}).keys():
		var person_id := str(roles.get(person_role, ""))
		if not GameState.npcs.has(person_id): continue
		var person: Dictionary = GameState.npcs[person_id]
		if not person.get("alive", false): continue
		var personal_effects: Dictionary = o["npc_effects"][person_role]
		for stat in personal_effects.keys():
			if stat not in ["happiness", "stress", "health", "smarts"]: continue
			var delta := float(personal_effects[stat])
			if band == "backfire" and delta > 0.0 and stat != "stress": delta = -maxf(1.0, delta / 3.0)
			elif band == "snag": delta *= 0.6
			person[stat] = clampf(float(person.get(stat, 20.0 if stat == "stress" else 60.0)) + delta, 0.0, 100.0)
	# Track actual changes to relationship bonds and closeness together. This keeps
	# consequential scenes in NPC memory even when the authored choice changes
	# trust or resentment without moving the headline closeness number.
	var relationship_records: Dictionary = {}
	if o.has("bond"):
		var btarget := str(o.get("bond_role", "p"))
		if roles.has(btarget):
			var person_id := str(roles[btarget])
			for bk in (o["bond"] as Dictionary).keys():
				var stat := str(bk)
				var delta := float(o["bond"][bk])
				var favorable := (stat == "resentment" and delta < 0.0) or (stat not in ["resentment", "obligation"] and delta > 0.0)
				# Friction changes the bond in the same direction as the visible
				# relationship outcome; a backfire cannot quietly grant full trust.
				if favorable and band == "backfire":
					delta = maxf(1.0, absf(delta) / 3.0) if stat == "resentment" else -maxf(1.0, delta / 3.0)
				elif favorable and band == "snag":
					delta *= 0.6
				var before_bond := BondStats.get_stat(person_id, stat)
				BondStats.nudge(person_id, stat, delta)
				var actual := BondStats.get_stat(person_id, stat) - before_bond
				if absf(actual) > 0.001 and GameState.npcs.has(person_id):
					var entry: Dictionary = relationship_records.get(person_id, {"impact":0.0,"tone":0.0})
					entry["impact"] = float(entry["impact"]) + absf(actual)
					if stat != "obligation": entry["tone"] = float(entry["tone"]) + (actual * -1.0 if stat == "resentment" else actual)
					relationship_records[person_id] = entry
	for role in o.get("relationship", {}).keys():
		if roles.has(role):
			var d := int(o["relationship"][role])
			# A choice that did not land does not earn the closeness it promised.
			if band == "backfire" and d > 0:
				d = -maxi(1, d / 3)
			elif band == "snag" and d > 0:
				d = maxi(1, int(d * 0.6))
			var person_id := str(roles[role])
			var before_close := int(GameState.npc(person_id).get("closeness", 50)) if GameState.npcs.has(person_id) else 0
			GameState.change_closeness(person_id, d)
			if GameState.npcs.has(person_id):
				var actual_close := int(GameState.npc(person_id).get("closeness", 50)) - before_close
				if actual_close != 0:
					var entry: Dictionary = relationship_records.get(person_id, {"impact":0.0,"tone":0.0})
					entry["impact"] = float(entry["impact"]) + absf(float(actual_close))
					entry["tone"] = float(entry["tone"]) + actual_close
					relationship_records[person_id] = entry
	# One concise memory per affected person. Small incidental changes remain
	# quiet; substantial choices persist as memories and, for larger shifts, threads.
	var remember_relationship := bool(def.get("remember_relationship", false))
	if text.length() > 12:
		for person_id0 in relationship_records:
			var person_id := str(person_id0)
			var entry: Dictionary = relationship_records[person_id]
			var impact := int(round(float(entry["impact"])))
			if impact < 8 and not remember_relationship: continue
			var memory := text.substr(0, 220)
			var tone := float(entry["tone"])
			Bonds.remember(person_id, memory.substr(0, 140), tone >= 0.0, true)
			if (impact >= 20 or remember_relationship) and not o.has("thread") and not Lives.separate():
				var person_name := str(GameState.npcs[person_id].get("first", "them"))
				var thread_title := "A turning point with " if impact >= 20 else "A moment with "
				LifeThreads.remember("relationship", thread_title + person_name,
					memory, person_id, clampi(50 + impact, 55, 90), ["relationship", str(def.get("id", "choice"))])
	for f in o.get("flags", []):
		GameState.set_flag(f)
	for f in o.get("unflags", []):
		GameState.clear_flag(f)
	for role in o.get("relation_change", {}).keys():
		if roles.has(role) and GameState.npcs.has(roles[role]):
			GameState.npcs[roles[role]]["relation"] = o["relation_change"][role]
	if o.has("schedule"):
		var s: Dictionary = o["schedule"]
		var yrs: Array = s.get("years", [1, 3])
		GameState.followups.append({"event": s["event"], "age": int(p["age"]) + randi_range(int(yrs[0]), int(yrs[1])), "roles": roles.duplicate(), "retries": 0})
	if o.has("new_partner") and roles.has(o["new_partner"]):
		Actions.start_dating(roles[o["new_partner"]], false)
	if o.has("hire"):
		Actions.hire(o["hire"])
	if o.has("set_boss") and roles.has(o["set_boss"]) and GameState.has_job():
		var bid: String = roles[o["set_boss"]]
		var old_boss: String = p["job"].get("boss", "")
		if old_boss != "" and GameState.npcs.has(old_boss) and old_boss != bid:
			GameState.npcs[old_boss]["relation"] = "coworker"
		p["job"]["boss"] = bid
		GameState.npcs[bid]["relation"] = "boss"
	if o.has("appraise") and not p.get("possessions", []).is_empty():
		var best: Dictionary = p["possessions"][0]
		for it in p["possessions"]:
			if int(it["value"]) > int(best["value"]):
				best = it
		best["value"] = maxi(10, int(int(best["value"]) * float(o["appraise"])))
	if o.get("unpartner", false):
		p["partner"] = ""
		p["partner_status"] = ""
	if o.get("clear_record", false):
		p["record"] = []
		Wanted.clear_all("Whatever they had on me, they do not have it any more.")
	if o.has("play"):
		var pl: Dictionary = o["play"].duplicate(true)
		pl["roles"] = roles.duplicate()
		Minigames.play(pl["id"], pl.get("params", {}), Callable(Careers, "resolve_play").bind(pl))
	if o.has("real"):
		Real.apply(o["real"])
	if o.has("family_memory"):
		FamilyChronicle.outcome(o["family_memory"],roles)
	if o.has("market"):
		Market.outcome(o["market"])
	if o.has("arc"):
		Arcs.apply(o["arc"])
	if o.has("pet"):
		Pets.apply(o["pet"])
	if o.has("gain_pet"):
		Companions.gain(o["gain_pet"])
	if o.has("record"):
		p["record"].append(str(o["record"]))
	if o.get("license_suspend", false) and Law.has_license("driver"):
		Law.suspend("driver", 2, "caught driving after drinking")
	if o.has("pet_cure"):
		Companions.cure(str(o["pet_cure"]))
	if o.has("pet_harm"):
		Companions.harm(str(o["pet_harm"][0]), float(o["pet_harm"][1]))
	if o.has("pr"):
		Prison.apply(o["pr"])
	if o.has("empire"):
		Empires.outcome(o["empire"])
	if o.has("become"):
		Become.outcome(o["become"])
	if o.get("royal_match",false): Lives.royal_match()
	if o.has("venue_sale"):
		Ventures.sell(str(o["venue_sale"]))
	if o.has("creator_license"):
		Creator.license_track(o["creator_license"])
	if o.has("world_start"):
		World.begin(str(o["world_start"]))
	if o.has("family_bonus"):
		Bonds.family_bonus(int(o["family_bonus"]))
	if o.get("family_upset", false):
		Bonds.family_bonus(-12)
	if o.has("npc_owes") and roles.has("them") and GameState.npcs.has(roles["them"]):
		GameState.npcs[roles["them"]]["owes"] = int(GameState.npcs[roles["them"]].get("owes", 0)) + int(o["npc_owes"])
	if o.has("story"):
		Novelty.story_outcome(o["story"])
	if o.has("thread"):
		LifeThreads.from_outcome(o["thread"], roles)
	if o.has("thread_effect"):
		LifeThreads.outcome(o["thread_effect"])
	if o.has("depth"):
		Depth.outcome(o["depth"])
	if o.has("journey"):
		Journey.outcome(o["journey"])
	if o.has("tv_branch"):
		TVLife.branch(o["tv_branch"])
	if o.has("employment"):
		Employment.outcome(o["employment"])
	if o.has("pathway") and o["pathway"] is Dictionary:
		var pathway: Dictionary = o["pathway"]
		var witness := str(roles.get(str(pathway.get("role", "")), ""))
		var path_field := str(pathway.get("field", p.get("job", {}).get("field", "General")))
		var path_quality := float(pathway.get("quality", 60.0)) * scale
		if band == "backfire": path_quality = minf(path_quality, 45.0)
		Journey.modules["pathways"].record(
			str(pathway.get("domain", "work")),
			str(pathway.get("source", def.get("id", "decision"))),
			path_field,
			clampf(path_quality, 0.0, 100.0),
			bool(pathway.get("honest", true)),
			witness
		)
	if o.has("ambition"):
		Ambition.outcome(o["ambition"], roles)
	if o.has("routine_toggle"):
		var rk := str(o["routine_toggle"])
		var now: bool = not bool(p["routines"].get(rk, false))
		p["routines"][rk] = now
		GameState.add_log("I %s doing that every year without thinking about it." % ("started" if now else "stopped"))
	if o.has("shop_buy"):
		var sb: Dictionary = o["shop_buy"]
		Shop.act("buy_version", [str(sb.get("store", "")), int(sb.get("idx", 0)), str(sb.get("house", "solid")), int(sb.get("edition", 0))])
	if o.has("activity_for"):
		var af: Dictionary = o["activity_for"]
		Actions.do_activity_for(str(af.get("id", "")), int(af.get("index", -1)))
	text += Grit.outcome(o, roles)
	Lives.outcome(o, roles)
	if def.get("twist", false):
		GameState.clear_flag("luck_spell")
	if o.get("use_jail_card", false):
		Law.use_jail_card()
	if o.has("career_start"):
		Careers.start(o["career_start"], o.get("career_mode", ""))
	if o.has("actor_role") and Careers.has_career("actor"):
		var role: Dictionary = o["actor_role"]
		Careers.career()["roles"].append(role)
	if o.has("take_office") and Careers.has_career("politician"):
		Careers.take_office(int(o["take_office"]))
	if o.get("career_quit", false):
		Careers.quit("quit")
	if o.has("trial"):
		var tr: Array = o["trial"]
		Wanted.commit(str(tr[0]), true)
		Law.trial(tr[0], int(tr[1]), int(tr[2]))
	if o.has("emigrate"):
		Actions.finish_emigration(o["emigrate"])
	if o.get("marry", false):
		Actions.mark_married()
	if o.get("quit_job", false):
		Actions.lose_job("quit")
	if o.get("fired", false):
		Actions.lose_job("fired")
	if o.has("fine"):
		p["money"] = int(p["money"]) - int(o["fine"])
		changes["money"] = int(changes.get("money", 0)) - int(o["fine"])
	if o.has("illness"):
		p["illness"] = o["illness"]
		if not Lives.separate(): Care.course().adopt_legacy()
	if o.get("cure", false):
		if not Lives.separate(): Care.course().event_recovery()
		else: p["illness"] = ""
	if o.has("milestone"):
		GameState.add_milestone(p["age"], tokens(o["milestone"], roles))
	for k in o.get("counter", {}).keys():
		GameState.counter(k, int(o["counter"][k]))
	var logline: String = tokens(o.get("log", ""), roles) if o.has("log") else text
	if not o.has("log") and def.has("choices") and not str(def.get("id", "_")).begins_with("_") and logline != "":
		if not (logline.begins_with("I ") or logline.begins_with("I'") or logline.begins_with("My ")):
			var ttl := tokens(def.get("title", ""), roles)
			logline = ("%s %s" if ttl.ends_with("!") or ttl.ends_with("?") else "%s: %s") % [ttl, logline]
	if logline != "":
		GameState.add_log(logline)
	if o.has("jail"):
		var j: Array = o["jail"]
		Wanted.commit(str(o.get("crime", "a crime")), true)
		Actions.go_to_prison(randi_range(int(j[0]), int(j[1])), o.get("crime", "a crime"))
		if Places.maybe_death_row(int(j[1])):
			text += "\n\nThe judge didn't stop at prison. I was sentenced to death."
	if o.has("die"):
		kill(o["die"])
		if not GameState.is_alive():
			return {"text": text, "changes": changes, "died": true, "signals": _signals(o, _before)}
	return {"text": text, "changes": changes, "signals": _signals(o, _before)}


var _cameo_cache := {}


const MISC := {
	"trip": ["the aquarium", "the science museum", "a working farm", "the planetarium", "a chocolate factory", "the zoo", "the state capitol", "a fire station", "an old castle", "the botanical gardens", "a recycling plant", "the history museum"],
	"skill": ["drawing", "mental math", "chess", "juggling", "singing", "building things", "public speaking", "running", "memorizing things", "telling jokes", "coding", "the recorder"],
	"word": ["onomatopoeia", "rhythm", "chrysanthemum", "bureaucracy", "silhouette", "pharaoh", "mischievous", "liaison", "handkerchief", "conscientious", "entrepreneur", "quizzical"],
	"task": ["change a tire", "fix a leaky sink", "grill a steak", "tie a tie", "jump-start a car", "change the oil", "put up a shelf", "fish properly", "build a birdhouse", "do your taxes"],
	"n": ["10", "15", "20", "25", "30", "40"],
}
var _misc_cache := {}


func _misc(tag: String) -> String:
	var key := tag + ":" + str(GameState.player.get("age", 0))
	if not _misc_cache.has(key):
		if tag == "host":
			_misc_cache[key] = ContentDB.random_first("male" if randf() < 0.5 else "female", GameState.player["country"])
		else:
			var arr: Array = MISC[tag]
			_misc_cache[key] = arr[randi() % arr.size()]
	return _misc_cache[key]


func _cameo(kind: String) -> String:
	var key := kind + ":" + str(GameState.player.get("age", 0))
	if not _cameo_cache.has(key):
		_cameo_cache[key] = Social.celeb_name(kind)
	return _cameo_cache[key]


func tokens(text: String, roles: Dictionary) -> String:
	if text.find("{") == -1:
		return text
	var p := GameState.player
	var out := Phrases.expand(text)
	text = out
	for m in _token_re.search_all(text):
		var who := m.get_string(1)
		var field := m.get_string(2)
		var val := ""
		if who == "fx":
			val = Fixtures.employer() if field == "work" else Fixtures.named(field)
		elif who == "era":
			val = Phrases.era_word(field)
		elif who == "me":
			val = _field(p, field, "")
		elif roles.has(who) and GameState.npcs.has(roles[who]):
			val = _field(GameState.npcs[roles[who]], field, roles[who])
		else:
			val = "someone"
		out = out.replace(m.get_string(0), val)
	for money_match in _money_token_re.search_all(out):
		out = out.replace(money_match.get_string(0), GameState.fmt_money(int(money_match.get_string(1))))
	out = out.replace("{country}", ContentDB.country(p["country"])["name"])
	if out.find("{celeb") != -1 or out.find("{city}") != -1:
		out = out.replace("{city}", str(Places.region().get("city", "town")))
		for kind in ["pop", "rap", "actor", "athlete", "tech", "streamer", "influencer", "chef", "model", "tv", "author", "director", "dj", "country"]:
			var tag := "{celeb_%s}" % kind
			if out.find(tag) != -1:
				var cn := _cameo(kind)
				out = out.replace(tag, cn)
		if out.find("{celeb}") != -1:
			out = out.replace("{celeb}", _cameo(""))
	for tag in ["trip", "skill", "word", "task", "n", "host"]:
		if out.find("{" + tag + "}") != -1:
			out = out.replace("{" + tag + "}", _misc(tag))
	if not p.get("business", {}).is_empty():
		out = out.replace("{biz}", p["business"]["name"])
	if not p.get("cult", {}).is_empty():
		out = out.replace("{cult}", p["cult"]["name"])
	if not p.get("zoo", {}).is_empty():
		out = out.replace("{zoo}", p["zoo"]["name"])
	if not p.get("career", {}).is_empty():
		out = out.replace("{career}", Careers.title())
	if GameState.has_job():
		out = out.replace("{job}", p["job"]["title"])
	return out


func _field(d: Dictionary, field: String, id: String) -> String:
	var g: String = d.get("gender", "male")
	match field:
		"first": return d.get("first", "")
		"last": return d.get("last", "")
		"name": return (d.get("first", "") + " " + d.get("last", "")).strip_edges()
		"he": return GameState.pron(g, "he")
		"him": return GameState.pron(g, "him")
		"his": return GameState.pron(g, "his")
		"He": return GameState.pron(g, "he").capitalize()
		"His": return GameState.pron(g, "his").capitalize()
		"rel": return GameState.relation_label(id).to_lower() if id != "" else ""
		"age": return str(d.get("age", ""))
		"job": return str(d.get("job", ""))
	return ""


# ---------------------------------------------------------------- popups from actions

func push_info(icon: String, title: String, text: String, changes: Dictionary = {}, critical: bool = false) -> void:
	pending.push_front({"info": true, "icon": icon, "title": title, "text": text, "changes": changes, "critical": critical})
	event_queued.emit()


func push_decision(def: Dictionary, roles: Dictionary = {}) -> void:
	var created: Array = roles.values() if def.get("discard_unkept", false) else []
	pending.push_front({"def": def, "roles": roles, "created": created})
	event_queued.emit()
