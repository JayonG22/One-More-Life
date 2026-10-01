extends Node

## v0.8 — Ambition & Society
## Deep professional identities: pro sports, police/detective work, medicine,
## pets, enterprise ownership and the justice system. This module layers onto
## the existing career/job/business/NPC systems instead of replacing them.

const POLICE_CASES := {
	"burglary": {"icon":"🏠","name":"Burglary series","difficulty":42,"clues":["partial shoe print","pawn-shop receipt","doorbell-camera frame","fiber from a window latch","phone location ping"]},
	"fraud": {"icon":"💳","name":"Fraud ring","difficulty":54,"clues":["shell-company filing","bank-transfer trail","forged invoice","burner-phone record","accounting discrepancy"]},
	"missing": {"icon":"🧭","name":"Missing person","difficulty":48,"clues":["last-known-location receipt","witness timeline","vehicle camera image","discarded backpack","cell-tower ping"]},
	"arson": {"icon":"🔥","name":"Arson investigation","difficulty":62,"clues":["accelerant residue","security-camera gap","insurance policy change","melted timer fragment","fuel purchase"]},
	"robbery": {"icon":"🏦","name":"Armed robbery","difficulty":66,"clues":["getaway route","spent casing","witness description","cash-band serial number","traffic-camera image"]},
	"homicide": {"icon":"🕯️","name":"Homicide","difficulty":78,"clues":["time-of-death window","DNA trace","contradictory alibi","weapon residue","deleted message"]},
	"cyber": {"icon":"💻","name":"Cybercrime case","difficulty":70,"clues":["login anomaly","crypto transfer","malware signature","IP handoff","recovered chat log"]},
	"corruption": {"icon":"🧾","name":"Public corruption","difficulty":82,"clues":["cash deposit pattern","procurement email","hidden ownership record","whistleblower note","meeting calendar"]},
}

const MED_SPECIALTIES := {
	"family": ["🩺","Family Medicine","Broad diagnosis · strong patient relationships"],
	"emergency": ["🚑","Emergency Medicine","Trauma and urgent cases · high stress"],
	"surgery": ["🔪","General Surgery","Operations · complication and malpractice risk"],
	"cardio": ["🫀","Cardiology","Heart disease and procedures"],
	"oncology": ["🎗️","Oncology","Cancer treatment and long care arcs"],
	"psych": ["🧠","Psychiatry","Mental-health treatment and recovery"],
	"peds": ["🧸","Pediatrics","Children and family-centered care"],
	"neuro": ["🧠","Neurology","Brain, seizure and nerve cases"],
}

const PET_TEMPERAMENTS := ["Gentle","Curious","Bold","Shy","Goofy","Protective","Stubborn","Social"]
const PET_TRICKS := ["sit","stay","come","heel","fetch","spin","speak","find it","high five","leave it"]
const PET_BUSINESSES := {
	"training": ["🎓","Pet Training School",30000,0.22],
	"grooming": ["🧼","Grooming Studio",45000,0.18],
	"daycare": ["🏡","Pet Daycare",65000,0.16],
	"breeding": ["🐾","Ethical Breeding Program",80000,0.20],
	"rescue": ["🛟","Animal Rescue",50000,0.06],
}

const SPORTS_AWARDS := ["Rookie of the Year","All-League Team","Player of the Year","Scoring Title","Defensive Award","Finals MVP"]
const SPORTS_CITIES := ["Riverport","Northfield","Bay City","Kingsbridge","Sunvale","Ironwood","Lakeshore","Redcliff","Harborview","Pinecrest","Stonehaven","Clearwater"]
const SPORTS_NAMES := ["Hawks","Titans","Comets","Wolves","Stingers","Mariners","Lions","Rockets","Foxes","Vipers","Falcons","Guardians"]


func _p() -> Dictionary:
	return GameState.player


func ensure() -> void:
	if _p().is_empty():
		return
	var p := _p()
	if not p.has("ambition") or not (p["ambition"] is Dictionary):
		p["ambition"] = {}
	var a: Dictionary = p["ambition"]
	for kv in [
		["justice", {"history":[],"probation":0,"parole":0,"appeals":0,"pleas":0}],
		["pets", {"shows":0,"titles":0,"litters":0,"business":{},"legacy_pets":0}],
		["enterprise", {"portfolio":[],"acquisitions":0,"bankruptcies":0,"succession":"","dividends":0}],
		["career_rivals", {}],
	]:
		if not a.has(kv[0]):
			a[kv[0]] = kv[1].duplicate(true)
	if GameState.has_job():
		ensure_job()
	for id in GameState.npcs_with("pet"):
		ensure_pet(id)
	if Careers.has_career("athlete"):
		ensure_sports(Careers.career())


func ensure_job() -> void:
	if not GameState.has_job():
		return
	var j: Dictionary = _p()["job"]
	var id := str(j.get("id", ""))
	if not j.has("career_story") or not (j["career_story"] is Dictionary):
		j["career_story"] = {"reputation":50.0,"network":15.0,"projects":0,"wins":0,"mentor":"","rival":"","training":0.0,"last_project":-99}
	var cs: Dictionary = j["career_story"]
	for kv in [["reputation",50.0],["network",15.0],["projects",0],["wins",0],["mentor",""],["rival",""],["training",0.0],["last_project",-99]]:
		if not cs.has(kv[0]): cs[kv[0]] = kv[1]
	if id == "police":
		if not j.has("police") or not (j["police"] is Dictionary):
			j["police"] = {"reputation":50.0,"integrity":70.0,"cases_solved":0,"cases_failed":0,"current":{},"cold":[],"patrols":0,"complaints":0,"ia":0,"commendations":0}
		var d: Dictionary = j["police"]
		for kv in [["reputation",50.0],["integrity",70.0],["cases_solved",0],["cases_failed",0],["current",{}],["cold",[]],["patrols",0],["complaints",0],["ia",0],["commendations",0]]:
			if not d.has(kv[0]): d[kv[0]] = kv[1].duplicate(true) if kv[1] is Array or kv[1] is Dictionary else kv[1]
	elif id in ["doctor","nurse"]:
		if not j.has("medicine") or not (j["medicine"] is Dictionary):
			j["medicine"] = {"specialty":"","reputation":50.0,"patients":0,"saves":0,"complications":0,"malpractice":0,"current":{},"research":0.0,"burnout":0.0,"mentored":0}
		var m: Dictionary = j["medicine"]
		for kv in [["specialty",""],["reputation",50.0],["patients",0],["saves",0],["complications",0],["malpractice",0],["current",{}],["research",0.0],["burnout",0.0],["mentored",0]]:
			if not m.has(kv[0]): m[kv[0]] = kv[1].duplicate(true) if kv[1] is Dictionary else kv[1]


func ensure_pet(id: String) -> void:
	if not GameState.npcs.has(id): return
	var n: Dictionary = GameState.npcs[id]
	if n.get("species", "human") == "human": return
	if not n.has("pet_profile") or not (n["pet_profile"] is Dictionary):
		n["pet_profile"] = {
			"training": randi_range(0, 18), "health": randi_range(75, 100), "temperament": PET_TEMPERAMENTS[randi() % PET_TEMPERAMENTS.size()],
			"tricks": [], "titles": 0, "shows": 0, "litter": 0, "bred_age": -99, "pedigree": randi_range(20, 90), "groomed": false,
			"therapy": false, "business_star": false, "vet_due": int(_p().get("age",0)) + 1,
		}


func ensure_sports(c: Dictionary) -> void:
	if c.is_empty() or c.get("id", "") != "athlete": return
	for kv in [
		["season",0],["wins",0],["losses",0],["playoffs",0],["finals",0],["awards",[]],["contract_years",0],["free_agent",false],
		["trade_requested",false],["salary_history",[]],["teams",[]],["standings",[]],["season_form",50.0],["agent_quality",0],["rival",""],["legacy_points",0],["league_titles",0],
	]:
		if not c.has(kv[0]): c[kv[0]] = kv[1].duplicate(true) if kv[1] is Array else kv[1]
	if c.get("team", "") != "" and not c["teams"].has(c["team"]):
		c["teams"].append(c["team"])


func yearly() -> void:
	ensure()
	_job_yearly()
	_pets_yearly()
	_enterprise_yearly()
	_justice_yearly()


func _spend_time() -> bool:
	if not GameState.spend_time():
		EventEngine.push_info("⏳", "Out of time", "You've used all your time this year.")
		return false
	return true


func _done(icon: String, title: String, text: String, effects: Dictionary = {}) -> void:
	var ch := GameState.apply_effects(effects)
	EventEngine.push_info(icon, title, text, ch)
	GameState.emit_changed()


func _row(icon: String, name: String, sub: String, act: String, arg = null, on: bool = true) -> Dictionary:
	return {"icon":icon,"name":name,"sub":sub,"act":"amb:" + act,"arg":arg,"on":on}


func _sub(icon: String, name: String, sub: String, key: String, on: bool = true) -> Dictionary:
	return {"icon":icon,"name":name,"sub":sub,"menu":"amb:" + key,"on":on}


# ============================================================================
# MENUS

func menu(key: String) -> Dictionary:
	ensure()
	if key == "work": return _work_menu()
	if key == "career_story": return _career_story_menu()
	if key == "police": return _police_menu()
	if key == "police_case": return _police_case_menu()
	if key == "medicine": return _medicine_menu()
	if key == "patient": return _patient_menu()
	if key == "pets": return _pets_menu()
	if key.begins_with("pet/"): return _pet_menu(key.trim_prefix("pet/"))
	if key == "pet_business": return _pet_business_menu()
	if key == "enterprise": return _enterprise_menu()
	if key == "enterprise_start": return _enterprise_start_menu()
	if key == "justice": return _justice_menu()
	return {"icon":"⭐","title":"Ambition & Society","info":["Professional life becomes a story, not only a paycheck."],"rows":[]}


func act(key: String, arg) -> void:
	ensure()
	match key:
		"career_project": career_project()
		"career_network": career_network()
		"career_mentor": career_mentor()
		"career_rival": career_rival()
		"career_train": career_train()
		"patrol": police_patrol()
		"new_case": police_new_case()
		"scene": police_scene()
		"evidence": police_evidence_board()
		"witness": police_witness()
		"interrogate": police_interrogate()
		"warrant": police_warrant()
		"arrest": police_arrest()
		"cold": police_cold_case()
		"case_drop": police_drop_case()
		"rounds": medical_rounds()
		"specialty": medical_specialty(str(arg))
		"new_patient": medical_new_patient()
		"diagnose": medical_diagnose()
		"second_opinion": medical_second_opinion()
		"treat_patient": medical_treat()
		"surgery": medical_surgery()
		"research": medical_research()
		"mentor": medical_mentor()
		"pet_train": pet_train(str(arg))
		"pet_show": pet_show(str(arg))
		"pet_vet": pet_vet(str(arg))
		"pet_groom": pet_groom(str(arg))
		"pet_breed": pet_breed(str(arg))
		"pet_therapy": pet_therapy(str(arg))
		"petbiz_start": pet_business_start(str(arg))
		"petbiz_market": pet_business_action("market")
		"petbiz_expand": pet_business_action("expand")
		"petbiz_feature": pet_business_action("feature")
		"enterprise_start": enterprise_start(str(arg))
		"enterprise_acquire": enterprise_acquire()
		"enterprise_dividend": enterprise_dividend()
		"enterprise_succession": enterprise_succession()
		"appeal": justice_appeal()
		"probation_check": justice_probation_check()


func _work_menu() -> Dictionary:
	if not GameState.has_job():
		return {"icon":"💼","title":"Professional Life","info":["You are not currently employed."],"rows":[]}
	var id := str(_p()["job"].get("id", ""))
	var rows: Array = []
	rows.append(_sub("📈","Career Development","Projects, mentors, rivals, skills and professional network","career_story"))
	if id == "police": rows.append(_sub("🕵️","Police & Detective Work","Patrol, cases, evidence and internal affairs","police"))
	if id in ["doctor","nurse"]: rows.append(_sub("🏥","Clinical Practice","Patients, diagnosis, specialties and malpractice","medicine"))
	rows.append(_sub("⚖️","Justice Record","Cases, probation, parole and appeals","justice"))
	return {"icon":"💼","title":"Professional Life","info":["Your institution remembers what you do here. Reputation, mistakes and relationships can follow you for years."],"rows":rows}


func _police_menu() -> Dictionary:
	if not GameState.has_job() or _p()["job"].get("id", "") != "police":
		return {"icon":"👮","title":"Police & Detective","info":["You need to be employed by the police department."],"rows":[]}
	ensure_job()
	var j: Dictionary = _p()["job"]
	var d: Dictionary = j["police"]
	var info := ["%s · Department reputation %d%% · Integrity %d%%" % [j["title"], int(d["reputation"]), int(d["integrity"])], "%d cases solved · %d failed · %d commendations" % [int(d["cases_solved"]), int(d["cases_failed"]), int(d["commendations"])]]
	var rows: Array = [_row("🚓","Work patrol","Calls, stops and unpredictable encounters","patrol")]
	if int(j.get("rank",0)) >= 1:
		if d["current"].is_empty():
			rows.append(_row("📁","Take a new case","A named suspect, witnesses and evidence","new_case"))
		else:
			var c: Dictionary = d["current"]
			rows.append(_sub(POLICE_CASES[c["kind"]]["icon"],"Current case: " + POLICE_CASES[c["kind"]]["name"],"Evidence %d%% · %d clue%s" % [int(c["evidence"]), c["clues"].size(), "" if c["clues"].size() == 1 else "s"],"police_case"))
		if not d["cold"].is_empty(): rows.append(_row("🧊","Reopen a cold case","%d unresolved case%s" % [d["cold"].size(), "" if d["cold"].size() == 1 else "s"],"cold"))
	else:
		rows.append({"icon":"🔒","name":"Detective cases","sub":"Promote to Detective to lead investigations","on":false})
	if int(d["ia"]) > 0:
		rows.append({"icon":"🧾","name":"Internal Affairs review","sub":"%d active concern%s" % [int(d["ia"]), "" if int(d["ia"]) == 1 else "s"],"on":false})
	return {"icon":"👮","title":"Police & Detective","info":info,"rows":rows}


func _police_case_menu() -> Dictionary:
	var d: Dictionary = _p().get("job",{}).get("police",{})
	var c: Dictionary = d.get("current",{})
	if c.is_empty(): return _police_menu()
	var def: Dictionary = POLICE_CASES[c["kind"]]
	var suspect := GameState.full_name(c["suspect"]) if GameState.npcs.has(c["suspect"]) else "Unknown suspect"
	var witness := GameState.full_name(c["witness"]) if GameState.npcs.has(c["witness"]) else "No witness"
	var clue_text := ", ".join(c["clues"]) if not c["clues"].is_empty() else "nothing solid yet"
	var info := ["%s · difficulty %d" % [def["name"], int(def["difficulty"])], "Suspect: %s · Witness: %s" % [suspect,witness], "Evidence %d%% · Known: %s" % [int(c["evidence"]),clue_text]]
	var rows := [
		_row("🔦","Process the scene","Search for physical and digital evidence","scene"),
		_row("🧩","Evidence board","Minigame · connect the case without forcing the facts","evidence"),
		_row("🗣️","Interview the witness","Memory can help—or muddy the timeline","witness",null,not c.get("witness_done",false)),
		_row("🚪","Interrogate the suspect","Pressure, rapport or patience","interrogate",null,not c.get("interrogated",false)),
		_row("📜","Request a warrant","Needs a defensible case","warrant",null,not c.get("warrant",false)),
		_row("🚓","Make the arrest","Send the case to prosecutors","arrest",null,float(c["evidence"]) >= 35.0),
		_row("🧊","Mark as cold","Keep the file for a future break","case_drop"),
	]
	return {"icon":def["icon"],"title":def["name"],"info":info,"rows":rows}


func _medicine_menu() -> Dictionary:
	if not GameState.has_job() or not ["doctor","nurse"].has(_p()["job"].get("id", "")):
		return {"icon":"🏥","title":"Clinical Practice","info":["You need a healthcare job to use this professional system."],"rows":[]}
	ensure_job()
	var j: Dictionary = _p()["job"]
	var m: Dictionary = j["medicine"]
	var sp: Array = MED_SPECIALTIES.get(m["specialty"], ["🩺","Unspecified","General practice"])
	var info := ["%s · %s" % [j["title"],sp[1]], "Clinical reputation %d%% · %d patients · %d major saves" % [int(m["reputation"]),int(m["patients"]),int(m["saves"])], "Complications %d · malpractice cases %d · burnout %d%%" % [int(m["complications"]),int(m["malpractice"]),int(m["burnout"])]]
	var rows: Array = [_row("🩺","Work rounds","See patients and strengthen performance","rounds")]
	if m["specialty"] == "":
		for sid in MED_SPECIALTIES.keys():
			var s: Array = MED_SPECIALTIES[sid]
			rows.append(_row(s[0],"Choose " + s[1],s[2],"specialty",sid))
	else:
		if m["current"].is_empty(): rows.append(_row("🧑‍⚕️","Take a patient","Symptoms first; diagnosis is not guaranteed","new_patient"))
		else: rows.append(_sub("📋","Current patient",_patient_summary(m["current"]),"patient"))
		rows.append(_row("🔬","Clinical research","Build knowledge; may improve difficult cases","research"))
		if int(j.get("rank",0)) >= 2: rows.append(_row("🎓","Mentor a resident","Leadership, reputation and a named colleague","mentor"))
	return {"icon":"🏥","title":"Clinical Practice","info":info,"rows":rows}


func _patient_menu() -> Dictionary:
	var m: Dictionary = _p().get("job",{}).get("medicine",{})
	var c: Dictionary = m.get("current",{})
	if c.is_empty(): return _medicine_menu()
	var patient := GameState.full_name(c["patient"]) if GameState.npcs.has(c["patient"]) else "Patient"
	var symptoms := ", ".join(c["symptoms"])
	var diagnosis: String = Expansion.CONDITIONS[c["condition"]]["name"] if c.get("diagnosed",false) else "not confirmed"
	var info := [patient + " · age " + str(GameState.npc(c["patient"]).get("age", "?")), "Symptoms: " + symptoms, "Diagnosis: " + diagnosis + " · Stability %d%%" % int(c["stability"])]
	var rows := [
		_row("🧪","Order tests","Reason from symptoms and available evidence","diagnose",null,not c.get("diagnosed",false)),
		_row("👥","Request a second opinion","Can catch a mistake before treatment","second_opinion",null,not c.get("second",false)),
		_row("💊","Treat the patient","Medication, monitoring or referral","treat_patient",null,c.get("diagnosed",false)),
	]
	var med: Dictionary = _p()["job"]["medicine"]
	if med.get("specialty","") == "surgery" or int(_p()["job"].get("rank",0)) >= 3:
		rows.append(_row("🔪","Operate","Minigame · stabilize, control bleeding and close","surgery",null,c.get("diagnosed",false) and int(Expansion.CONDITIONS[c["condition"]]["severity"]) >= 2))
	return {"icon":"📋","title":"Patient: " + patient,"info":info,"rows":rows}


func _pets_menu() -> Dictionary:
	var rows: Array = []
	for id in GameState.npcs_with("pet"):
		ensure_pet(id)
		var n := GameState.npc(id)
		var pp: Dictionary = n["pet_profile"]
		rows.append(_sub("🐾",n["first"],"%s · %s · training %d%% · health %d%%" % [str(n.get("species","pet")).capitalize(),pp["temperament"],int(pp["training"]),int(pp["health"])],"pet/" + id))
	var pb: Dictionary = _p()["ambition"]["pets"]["business"]
	rows.append(_sub("🏪","Pet Business",("Open a pet-centered business" if pb.is_empty() else "%s · level %d" % [pb["name"],int(pb["level"]) ]),"pet_business"))
	return {"icon":"🐾","title":"Pets","info":["Pets have temperament, health, training, show history and family lines. Their lives continue whether or not you click them every year."],"rows":rows}


func _pet_menu(id: String) -> Dictionary:
	if not GameState.npcs.has(id): return _pets_menu()
	ensure_pet(id)
	var n := GameState.npc(id)
	var pp: Dictionary = n["pet_profile"]
	var tricks := ", ".join(pp["tricks"]) if not pp["tricks"].is_empty() else "none yet"
	var info := ["%s the %s · age %d · %s" % [n["first"],str(n.get("species","pet")),int(n["age"]),pp["temperament"]], "Training %d%% · health %d%% · closeness %d%%" % [int(pp["training"]),int(pp["health"]),int(n["closeness"])], "Tricks: %s · %d show title%s" % [tricks,int(pp["titles"]),"" if int(pp["titles"]) == 1 else "s"]]
	var breed_ok := int(n["age"]) >= 2 and int(n["age"]) <= 10 and int(_p()["age"]) - int(pp["bred_age"]) >= 2 and str(n.get("species","")) in ["dog","cat"]
	var rows := [
		_row("🎓","Train", "Teach behavior and tricks","pet_train",id),
		_row("🏅","Enter a pet show","Training, temperament and closeness matter","pet_show",id,int(pp["training"]) >= 25),
		_row("🩺","Veterinary care","Health check, vaccines and treatment","pet_vet",id),
		_row("🧼","Groom","Looks, comfort and show preparation","pet_groom",id),
		_row("🐾","Breed responsibly","A litter becomes real family pets","pet_breed",id,breed_ok),
		_row("🫂","Therapy-animal training","Helps stress and some recovery arcs","pet_therapy",id,int(pp["training"]) >= 55 and not pp["therapy"]),
	]
	return {"icon":"🐾","title":n["first"],"info":info,"rows":rows}


func _pet_business_menu() -> Dictionary:
	var b: Dictionary = _p()["ambition"]["pets"]["business"]
	var rows: Array = []
	if b.is_empty():
		for id in PET_BUSINESSES.keys():
			var d: Array = PET_BUSINESSES[id]
			rows.append(_row(d[0],"Start " + d[1],GameState.fmt_money(Actions._cost(int(d[2]))) + " · connected to your pets","petbiz_start",id,int(_p()["age"]) >= 18))
		return {"icon":"🏪","title":"Pet Business","info":["A pet business is tied to your animals, reputation and staff—not a passive money button."],"rows":rows}
	var info := ["%s · level %d · reputation %d%%" % [b["name"],int(b["level"]),int(b["reputation"])], "Last profit %s · %d staff" % [GameState.fmt_money(int(b["profit"])),int(b["staff"])]]
	rows.append(_row("📣","Local campaign","Bring in customers; costs cash","petbiz_market"))
	rows.append(_row("🏗️","Expand","More capacity, higher overhead","petbiz_expand"))
	rows.append(_row("🌟","Feature one of your pets","A trained pet becomes the face of the business","petbiz_feature",null,not GameState.npcs_with("pet").is_empty()))
	return {"icon":"🏪","title":b["name"],"info":info,"rows":rows}


func _enterprise_menu() -> Dictionary:
	var e: Dictionary = _p()["ambition"]["enterprise"]
	var rows: Array = []
	var info := ["%d company holding%s · lifetime dividends %s" % [e["portfolio"].size(),"" if e["portfolio"].size() == 1 else "s",GameState.fmt_money(int(e["dividends"]))]]
	if not _p().get("business",{}).is_empty():
		var b: Dictionary = _p()["business"]
		info.append("Operating company: %s · value %s" % [b["name"],GameState.fmt_money(int(b["value"]))])
	rows.append(_sub("➕","Start another company","Create a subsidiary without abandoning the operating company","enterprise_start",int(_p()["age"]) >= 18))
	rows.append(_row("🤝","Acquire a competitor","Buy an operating company into your portfolio","enterprise_acquire",null,int(_p()["money"]) >= Actions._cost(100000)))
	if not e["portfolio"].is_empty():
		rows.append(_row("💸","Take a special dividend","Pull cash out now; weakens the companies","enterprise_dividend"))
		rows.append(_row("📜","Set succession plan","Choose a child to inherit control","enterprise_succession",null,not GameState.npcs_with("child").is_empty()))
		for co in e["portfolio"]:
			rows.append({"icon":co["icon"],"name":co["name"],"sub":"%s · value %s · profit %s · you own %d%%" % [co["industry"],GameState.fmt_money(int(co["value"])),GameState.fmt_money(int(co["profit"])),int(float(co["stake"])*100)],"on":false})
	return {"icon":"🏢","title":"Company Portfolio","info":info,"rows":rows}


func _enterprise_start_menu() -> Dictionary:
	var rows: Array = []
	for id in Empires.INDUSTRIES.keys():
		var d: Dictionary = Empires.INDUSTRIES[id]
		var cost := Actions._cost(int(d["cost"]) * 2)
		rows.append(_row(d["icon"],d["name"],"Subsidiary startup · " + GameState.fmt_money(cost),"enterprise_start",id,int(_p()["money"]) >= cost))
	return {"icon":"➕","title":"New Subsidiary","info":["Subsidiaries are lighter to manage than your operating company, but they still face demand, debt, staff and bad years."],"rows":rows}


func _justice_menu() -> Dictionary:
	var j: Dictionary = _p()["ambition"]["justice"]
	var hist: Array = j["history"]
	var info := ["Court history: %d case%s · %d plea%s · %d appeal%s" % [hist.size(),"" if hist.size()==1 else "s",int(j["pleas"]),"" if int(j["pleas"])==1 else "s",int(j["appeals"]),"" if int(j["appeals"])==1 else "s"]]
	if int(j["probation"]) > 0: info.append("Probation: %d year%s remaining" % [int(j["probation"]),"" if int(j["probation"])==1 else "s"])
	if int(j["parole"]) > 0: info.append("Parole: %d year%s remaining" % [int(j["parole"]),"" if int(j["parole"])==1 else "s"])
	var rows: Array = []
	if not hist.is_empty():
		var last: Dictionary = hist[-1]
		rows.append({"icon":"📄","name":"Latest case: " + str(last.get("crime","case")).capitalize(),"sub":str(last.get("result","recorded")),"on":false})
		if last.get("result","") == "convicted" and not last.get("appealed",false): rows.append(_row("🏛️","File an appeal","Costs money and depends on the record","appeal"))
	if int(j["probation"]) > 0 or int(j["parole"]) > 0: rows.append(_row("✅","Check in","Meet supervision conditions and lower violation risk","probation_check"))
	return {"icon":"⚖️","title":"Justice Record","info":info,"rows":rows}


func _career_story_menu() -> Dictionary:
	if not GameState.has_job(): return _work_menu()
	ensure_job()
	var j: Dictionary = _p()["job"]
	var cs: Dictionary = j["career_story"]
	var mentor_name := "none yet" if str(cs["mentor"]) == "" else GameState.full_name(str(cs["mentor"]))
	var rival_name := "none yet" if str(cs["rival"]) == "" else GameState.full_name(str(cs["rival"]))
	var info := ["%s · professional reputation %d%% · network %d%%" % [j["title"],int(cs["reputation"]),int(cs["network"])], "%d major project%s · mentor: %s · rival: %s" % [int(cs["projects"]),"" if int(cs["projects"]) == 1 else "s",mentor_name,rival_name]]
	var rows := [
		_row("📊","Lead a major project","Higher risk than Work Harder; success builds a real career story","career_project"),
		_row("🤝","Build your network","Meet people in the field; opportunities can surface years later","career_network"),
		_row("🧭","Find or meet your mentor","Advice, sponsorship and sometimes disagreement","career_mentor"),
		_row("⚔️","Deal with your professional rival","Compete, reconcile or let the work speak","career_rival"),
		_row("📚","Professional training","Spend time and money building durable skill","career_train"),
	]
	return {"icon":"📈","title":"Career Development","info":info,"rows":rows}


func career_project() -> void:
	if not GameState.has_job() or not _spend_time(): return
	ensure_job(); var j:Dictionary=_p()["job"]; var cs:Dictionary=j["career_story"]
	var skill := GameState.stat("smarts") * 0.35 + float(j.get("perf",50)) * 0.45 + float(cs["training"]) * 0.20
	var chance := clampf(0.28 + skill / 150.0 + float(cs["network"]) / 500.0,0.2,0.92)
	cs["projects"] = int(cs["projects"]) + 1; cs["last_project"] = int(_p()["age"]); GameState.counter("career_projects")
	if randf() < chance:
		cs["wins"] = int(cs["wins"]) + 1; cs["reputation"] = minf(100,float(cs["reputation"])+randf_range(5,10)); GameState.counter("career_projects_won")
		_done("📊","Project landed","I owned a difficult piece of work from the messy first meeting to the result. People remembered who made it work.",{"job_perf":8,"happiness":4,"stress":5})
	else:
		cs["reputation"] = maxf(0,float(cs["reputation"])-3)
		_done("📉","Project missed","The project slipped, and I had to explain what I underestimated instead of hiding behind the team.",{"job_perf":-4,"stress":8,"smarts":1})


func career_network() -> void:
	if not GameState.has_job() or not _spend_time(): return
	ensure_job(); var cs:Dictionary=_p()["job"]["career_story"]
	cs["network"] = minf(100,float(cs["network"])+randf_range(5,11)); GameState.counter("career_connections")
	var contact := GameState.create_npc("coworker",{"age":maxi(18,int(_p()["age"])+randi_range(-8,14)),"closeness":35})
	if not _p()["job"]["coworkers"].has(contact): _p()["job"]["coworkers"].append(contact)
	_done("🤝","A useful connection","I met %s through work. We did not become instant friends, but now we know each other well enough for a future phone call." % GameState.full_name(contact),{"happiness":2,"stress":1})


func career_mentor() -> void:
	if not GameState.has_job() or not _spend_time(): return
	ensure_job(); var j:Dictionary=_p()["job"]; var cs:Dictionary=j["career_story"]
	if str(cs["mentor"]) == "" or not GameState.npcs.has(str(cs["mentor"])):
		var mid := str(j.get("boss",""))
		if mid == "" or not GameState.npcs.has(mid): mid = GameState.create_npc("coworker",{"age":int(_p()["age"])+randi_range(5,18),"closeness":55})
		cs["mentor"] = mid
		_done("🧭","A mentor","%s agreed to be the person I can call before a career decision gets expensive." % GameState.full_name(mid),{"happiness":4,"smarts":1})
	else:
		var mid:String=str(cs["mentor"]); GameState.change_closeness(mid,5); cs["training"] = minf(100,float(cs["training"])+5); cs["reputation"] = minf(100,float(cs["reputation"])+2)
		_done("🧭","Mentor meeting","%s challenged one of my assumptions and gave me a better way to handle the next promotion conversation." % GameState.full_name(mid),{"smarts":1,"stress":-2})


func career_rival() -> void:
	if not GameState.has_job() or not _spend_time(): return
	ensure_job(); var j:Dictionary=_p()["job"]; var cs:Dictionary=j["career_story"]
	if str(cs["rival"]) == "" or not GameState.npcs.has(str(cs["rival"])):
		var rid := GameState.create_npc("coworker",{"age":maxi(18,int(_p()["age"])+randi_range(-5,7)),"closeness":20})
		cs["rival"] = rid; j["coworkers"].append(rid)
		_done("⚔️","A professional rival","%s and I keep reaching for the same visible work. It is not hatred—yet—but every win is being counted." % GameState.full_name(rid),{"stress":3})
		return
	var rid:String=str(cs["rival"]); var win:=randf()<clampf(0.35+float(j.get("perf",50))/180.0+GameState.stat("smarts")/300.0,0.25,0.86)
	if win:
		cs["reputation"] = minf(100,float(cs["reputation"])+4); GameState.change_closeness(rid,-3)
		_done("⚔️","Rivalry point","I made the stronger case in front of the people who mattered. %s noticed." % GameState.npc(rid)["first"],{"job_perf":4,"happiness":3,"stress":2})
	else:
		GameState.change_closeness(rid,-2)
		_done("⚔️","Outplayed","%s got the assignment I wanted. I can either learn why or spend the year resenting it." % GameState.npc(rid)["first"],{"happiness":-3,"stress":5,"smarts":1})


func career_train() -> void:
	if not GameState.has_job(): return
	var fee:=Actions._cost(900); if int(_p()["money"]) < fee: EventEngine.push_info("💸","Professional training","You need %s for the course and materials." % GameState.fmt_money(fee)); return
	if not _spend_time(): return
	ensure_job(); var cs:Dictionary=_p()["job"]["career_story"]; _p()["money"] = int(_p()["money"]) - fee; cs["training"] = minf(100,float(cs["training"])+randf_range(7,13))
	_done("📚","Professional training","I spent part of the year learning something my job actually uses. It was less exciting than a promotion and more durable.",{"smarts":2,"job_perf":3,"stress":2})


# ============================================================================
# CROSS-SYSTEM ECHOES
# A system is not finished when its menu opens. It is finished when it changes
# something else. These helpers let the v0.8 careers reach relationships,
# money, standing, law and memory instead of only writing into player["job"].

func _partner_id() -> String:
	var pid: String = str(_p().get("partner", ""))
	if pid != "" and GameState.npcs.has(pid) and GameState.npcs[pid]["alive"]:
		return pid
	return ""


func _home_ids() -> Array:
	var out: Array = []
	var pid := _partner_id()
	if pid != "":
		out.append(pid)
	for k in GameState.npcs_with("child"):
		if int(GameState.npc(k).get("age", 99)) < 25:
			out.append(k)
	return out


## Long hours, danger and obsession cost something at home.
func _strain_home(amount: int, why: String = "") -> void:
	var ids := _home_ids()
	if ids.is_empty() or amount <= 0:
		return
	for id in ids:
		GameState.change_closeness(id, -amount)
	var pid := _partner_id()
	if pid != "" and why != "" and randf() < 0.4:
		Bonds.remember(pid, why, false)


## Someone attached to an NPC, who now has their own reason to resent me.
func _relative_of(id: String, relation: String) -> String:
	if not GameState.npcs.has(id):
		return ""
	var n := GameState.npc(id)
	return GameState.create_npc(relation, {"age": maxi(18, int(n.get("age", 40)) + randi_range(-22, 22)), "closeness": 6, "last": str(n.get("last", ""))})


func _echo(kind: String, title: String, text: String, npc_id: String = "", strength: int = 60, tags: Array = []) -> void:
	LifeThreads.remember(kind, title, text, npc_id, strength, tags)


## A death close enough to grieve. Feeds the v0.7 mental-health system.
func _bereave(text: String) -> void:
	GameState.set_flag("lost_close_person")
	GameState.apply_effects({"happiness": -10, "stress": 8})
	GameState.add_log(text)


# ============================================================================
# POLICE / DETECTIVE

func _police() -> Dictionary:
	ensure_job()
	return _p()["job"].get("police",{})


func police_patrol() -> void:
	if not _spend_time(): return
	Fx.play("siren", 0.01)
	var d := _police()
	if d.is_empty(): return
	d["patrols"] = int(d["patrols"]) + 1
	var call := randi() % 6
	match call:
		0:
			var calm := 0.45 + float(d["integrity"]) / 250.0 + GameState.stat("smarts") / 500.0
			if randf() < calm:
				d["reputation"] = minf(100,float(d["reputation"])+3)
				_done("🚓","Domestic call","I slowed things down, separated everyone and got the family through the night without an arrest.",{"job_perf":5,"stress":4,"karma":2})
			else:
				d["complaints"] = int(d["complaints"])+1; d["ia"] = int(d["ia"])+1
				_done("📋","Complaint filed","The call escalated and a civilian filed a complaint about how I handled it.",{"job_perf":-5,"stress":8})
		1:
			_done("🚗","Traffic stop","A routine stop turned into a long conversation and a warning instead of a ticket.",{"job_perf":2,"karma":1})
		2:
			if randf() < 0.2:
				Expansion.add_injury(["sprain","shoulder","concussion"][randi()%3],"police patrol")
				_strain_home(3,"Came home hurt again and told me it was nothing.")
				_done("🚨","Foot pursuit","I caught the runner, but the chase ended hard on the pavement.",{"job_perf":8,"health":-4,"stress":8})
			else:
				_done("🏃","Foot pursuit","I chased a shoplifting suspect through two blocks and made the arrest cleanly.",{"job_perf":7,"health":1,"stress":5})
		3:
			var bribe := Actions._cost(randi_range(300,1800))
			EventEngine.push_decision({"id":"_police_bribe","icon":"💵","title":"An envelope","text":"A business owner quietly offers %s to make a citation disappear." % GameState.fmt_money(bribe),"choices":[
				{"label":"Refuse and document it","outcomes":[{"text":"I logged the attempted bribe and walked out clean.","effects":{"karma":4,"job_perf":5},"ambition":{"kind":"police_integrity","value":6}}]},
				{"label":"Take it","outcomes":[{"weight":3,"text":"I pocketed the money. Nobody seemed to notice.","effects":{"money":bribe,"karma":-8,"heat":4},"ambition":{"kind":"police_integrity","value":-12}},{"weight":1,"text":"Internal Affairs already knew about the envelope.","effects":{"money":bribe,"karma":-10,"job_perf":-15},"ambition":{"kind":"police_ia","value":2}}]},
				{"label":"Walk away without writing it up","outcomes":[{"text":"I refused the cash, but didn't create a paper trail either.","ambition":{"kind":"police_integrity","value":-2}}]},
			]})
		4:
			_done("🫂","Welfare check","I found an older resident alone and confused. I stayed until family arrived.",{"job_perf":4,"karma":4,"stress":2})
		5:
			var found := randi_range(50,500)
			_done("🔎","Lost property","I tracked down the owner of a wallet holding %s instead of letting it disappear into evidence storage." % GameState.fmt_money(found),{"job_perf":3,"karma":3})


func police_new_case() -> void:
	Fx.play("page", 0.01)
	var d := _police(); if d.is_empty() or not d["current"].is_empty(): return
	if not _spend_time(): return
	var keys := POLICE_CASES.keys(); var kind: String = keys[randi()%keys.size()]
	var suspect := GameState.create_npc("suspect",{"age":randi_range(18,70),"closeness":10})
	var witness := GameState.create_npc("witness",{"age":randi_range(16,80),"closeness":35})
	d["current"] = {"kind":kind,"opened":int(_p()["age"]),"evidence":8.0,"clues":[],"suspect":suspect,"witness":witness,"witness_done":false,"interrogated":false,"warrant":false,"confession":false,"mistakes":0}
	GameState.add_log("I caught a new case: %s." % POLICE_CASES[kind]["name"].to_lower())
	LifeThreads.remember("relationship", "A case landed on my desk", "The %s investigation put %s in my path." % [POLICE_CASES[kind]["name"].to_lower(), GameState.full_name(suspect)], suspect, 58, ["career", "police", kind])
	_done(POLICE_CASES[kind]["icon"],"New case", "%s. The file is thin, and a real person's future depends on what I do next." % POLICE_CASES[kind]["name"],{"stress":3})


func police_scene() -> void:
	var d := _police(); var c: Dictionary = d.get("current",{}); if c.is_empty(): return
	if not _spend_time(): return
	var def: Dictionary = POLICE_CASES[c["kind"]]
	var available: Array = []
	for clue in def["clues"]:
		if not c["clues"].has(clue): available.append(clue)
	if available.is_empty():
		_done("🔦","Scene processed","There was nothing new left to recover from the scene.",{"stress":1}); return
	var clue: String = available[randi()%available.size()]
	var skill := GameState.stat("smarts") + float(_p()["job"].get("perf",50))*0.25
	if randf() < clampf(skill/130.0,0.25,0.92):
		c["clues"].append(clue); c["evidence"] = minf(100,float(c["evidence"])+randf_range(10,18))
		_done("🔎","Evidence recovered","I documented a %s and added it to the chain of custody." % clue,{"job_perf":4,"stress":2})
	else:
		c["mistakes"] = int(c["mistakes"])+1; d["integrity"] = maxf(0,float(d["integrity"])-2)
		_done("🧤","Nothing clean","I spent hours processing the scene, but the useful trace was too contaminated to trust.",{"stress":4})


func police_evidence_board() -> void:
	var c: Dictionary = _police().get("current",{}); if c.is_empty(): return
	if not _spend_time(): return
	Minigames.play("evidence",{"skill":GameState.stat("smarts")*0.55+float(_p()["job"].get("perf",50))*0.45,"difficulty":float(POLICE_CASES[c["kind"]]["difficulty"])/65.0},Callable(self,"_evidence_done"))


func _evidence_done(score: float, detail: Dictionary) -> void:
	var d := _police(); var c: Dictionary = d.get("current",{}); if c.is_empty(): return
	var gain := int(6 + score*24)
	c["evidence"] = minf(100,float(c["evidence"])+gain)
	if score >= 0.8:
		d["reputation"] = minf(100,float(d["reputation"])+4); _done("🧩","The board clicks","The timeline finally fits. I found a connection the file had been hiding.",{"job_perf":7,"smarts":1})
	elif score >= 0.4:
		_done("🧩","A working theory","I tightened the timeline and cut away a few bad assumptions.",{"job_perf":3})
	else:
		c["mistakes"] = int(c["mistakes"])+1; _done("🧩","Theory fell apart","I tried to force a pattern that wasn't there and had to unwind it.",{"job_perf":-2,"stress":5})


func police_witness() -> void:
	var c: Dictionary = _police().get("current",{}); if c.is_empty() or c.get("witness_done",false): return
	if not _spend_time(): return
	c["witness_done"] = true
	var w := GameState.npc(c["witness"])
	var reliable := randf() < 0.65 + float(w.get("closeness",35))/400.0
	if reliable:
		c["evidence"] = minf(100,float(c["evidence"])+14); GameState.change_closeness(c["witness"],8)
		_done("🗣️","Witness interview","%s remembered a small detail that lined up with the physical evidence." % w["first"],{"job_perf":4})
	else:
		c["evidence"] = maxf(0,float(c["evidence"])-3)
		_done("🗣️","Messy memory","%s was certain—then changed the story twice. I documented the contradictions instead of pretending they helped." % w["first"],{"stress":3,"karma":1})


func police_interrogate() -> void:
	var c: Dictionary = _police().get("current",{}); if c.is_empty() or c.get("interrogated",false): return
	if not _spend_time(): return
	c["interrogated"] = true
	var nm := GameState.full_name(c["suspect"])
	var base := clampf(float(c["evidence"])/120.0 + GameState.stat("smarts")/300.0,0.08,0.86)
	EventEngine.push_decision({"id":"_interrogate","icon":"🗣️","title":"Interview room","text":"%s sits across the table. Evidence is at %d%%. How do you conduct the interrogation?" % [nm,int(c["evidence"])],"choices":[
		{"label":"Build rapport","outcomes":[{"weight":base+0.18,"text":"The conversation loosened something. The suspect gave a detail only the offender should know.","ambition":{"kind":"case_confession","evidence":18,"integrity":3}},{"weight":1.0-base,"text":"They stayed polite and gave me nothing useful.","ambition":{"kind":"case_evidence","value":2}}]},
		{"label":"Confront with evidence","outcomes":[{"weight":base+0.08,"text":"The contradictions piled up. The suspect cracked.","ambition":{"kind":"case_confession","evidence":22,"integrity":1}},{"weight":1.0-base,"text":"They asked for a lawyer and the interview ended.","ambition":{"kind":"case_evidence","value":0}}]},
		{"label":"Push hard","outcomes":[{"weight":base-0.12,"text":"The pressure worked, but the confession will be attacked in court.","ambition":{"kind":"case_confession","evidence":12,"integrity":-8}},{"weight":1.12-base,"text":"I crossed the line. The interview became a complaint instead of evidence.","ambition":{"kind":"police_ia","value":1}}]},
	]},{"suspect":c["suspect"]})


func police_warrant() -> void:
	var c: Dictionary = _police().get("current",{}); if c.is_empty() or c.get("warrant",false): return
	if not _spend_time(): return
	var ch := clampf((float(c["evidence"])-22.0)/70.0,0.05,0.95)
	if randf() < ch:
		c["warrant"] = true; c["evidence"] = minf(100,float(c["evidence"])+10)
		_done("📜","Warrant signed","A judge found probable cause. The search turned up evidence that can actually be used in court.",{"job_perf":5})
	else:
		_done("📜","Warrant denied","The judge sent me back: suspicion isn't enough. Build the case.",{"stress":3})


func police_arrest() -> void:
	var d := _police(); var c: Dictionary = d.get("current",{}); if c.is_empty(): return
	if not _spend_time(): return
	var def: Dictionary = POLICE_CASES[c["kind"]]
	var strength := float(c["evidence"]) + (18.0 if c.get("confession",false) else 0.0) + (8.0 if c.get("warrant",false) else 0.0) - int(c.get("mistakes",0))*8.0
	var convict := clampf((strength-float(def["difficulty"])+45.0)/90.0,0.04,0.96)
	var suspect: String = c["suspect"]
	if randf() < convict:
		d["cases_solved"] = int(d["cases_solved"])+1; d["reputation"] = minf(100,float(d["reputation"])+7); d["commendations"] = int(d["commendations"]) + (1 if strength > 88 else 0)
		if GameState.npcs.has(suspect):
			GameState.npcs[suspect]["relation"] = "enemy"
			GameState.npcs[suspect]["convicted_by_me"] = true
			Grit.grudge(suspect, 55)
			Bonds.remember(suspect, "Built the case that put me away.", false)
		GameState.counter("cases_solved")
		GameState.add_milestone(_p()["age"],"solved a %s case" % def["name"].to_lower())
		# A conviction has a family on the other side of it.
		if randf() < 0.5:
			var kin := _relative_of(suspect, "enemy")
			if kin != "":
				Grit.grudge(kin, 32)
				GameState.add_log("%s blames me for what happened to their family." % GameState.full_name(kin))
		_echo("career","The case that stuck","I built the %s case that sent %s away. Some families never stop counting the years." % [def["name"].to_lower(), GameState.full_name(suspect)], suspect, 70, ["police","conviction"])
		_done("⚖️","Case closed","Prosecutors took the case to court and won. The evidence held up under attack.",{"job_perf":12,"happiness":6,"stress":-4,"karma":3})
	else:
		d["cases_failed"] = int(d["cases_failed"])+1; d["reputation"] = maxf(0,float(d["reputation"])-9)
		if strength < 45:
			d["ia"] = int(d["ia"])+1; d["integrity"] = maxf(0,float(d["integrity"])-6)
			# Arresting on thin evidence is not a free reset. It follows me.
			if GameState.npcs.has(suspect):
				Grit.grudge(suspect, 70)
				Bonds.remember(suspect, "Arrested me without the evidence to back it up.", false)
			var claim := Actions._cost(randi_range(4000,26000))
			_p()["money"] = int(_p()["money"]) - claim
			Grit.change_credit(-12)
			_echo("regret","The arrest I rushed","I wanted %s to be guilty more than I could prove it. The city paid %s and I kept the file in my head." % [GameState.full_name(suspect), GameState.fmt_money(claim)], suspect, 78, ["police","mistake"])
			_done("⚠️","Case collapsed","The prosecutor dropped it. I moved too soon, the city settled a wrongful-arrest claim for %s, and the department is reviewing me." % GameState.fmt_money(claim),{"job_perf":-12,"stress":10,"happiness":-5,"karma":-3})
		else:
			_done("⚖️","Reasonable doubt","The case was defensible, but not strong enough for a conviction. The file comes back with hard questions.",{"job_perf":-4,"stress":7})
	d["current"] = {}


func police_drop_case() -> void:
	var d := _police(); var c: Dictionary = d.get("current",{}); if c.is_empty(): return
	c["cold_age"] = int(_p()["age"]); d["cold"].append(c); d["current"] = {}
	_done("🧊","Cold case","I boxed the file instead of manufacturing certainty. It can come back if something new surfaces.",{"stress":2,"karma":2})


func police_cold_case() -> void:
	var d := _police(); if d["cold"].is_empty() or not d["current"].is_empty(): return
	if not _spend_time(): return
	var c: Dictionary = d["cold"].pop_front(); c["evidence"] = minf(100,float(c["evidence"])+randf_range(5,18)); d["current"] = c
	_done("🧊","Cold case reopened","A new tip gave the old file another pulse. I put the photographs back on the wall.",{"stress":4,"job_perf":3})


# ============================================================================
# MEDICINE

func _med() -> Dictionary:
	ensure_job(); return _p()["job"].get("medicine",{})


func medical_rounds() -> void:
	if not _spend_time(): return
	var m := _med(); if m.is_empty(): return
	m["burnout"] = minf(100,float(m["burnout"])+randf_range(2,6))
	m["reputation"] = minf(100,float(m["reputation"])+2)
	_done("🩺","Rounds","I worked the floor, caught small problems early and handed over clean notes to the next shift.",{"job_perf":6,"stress":5,"smarts":1})


func medical_specialty(id: String) -> void:
	var m := _med(); if m.is_empty() or not MED_SPECIALTIES.has(id): return
	m["specialty"] = id
	GameState.add_milestone(_p()["age"],"chose %s as a medical specialty" % MED_SPECIALTIES[id][1])
	_done(MED_SPECIALTIES[id][0],"Specialty chosen","I committed to %s. From here on, the cases and risks change with it." % MED_SPECIALTIES[id][1],{"happiness":4,"stress":3})


func _patient_summary(c: Dictionary) -> String:
	var n := GameState.npc(c.get("patient","")); if n.is_empty(): return "No patient"
	return "%s · %s · stability %d%%" % [n["first"],", ".join(c.get("symptoms",[])),int(c.get("stability",50))]


func medical_new_patient() -> void:
	Fx.play("monitor", 0.01)
	var m := _med(); if m.is_empty() or not m["current"].is_empty(): return
	if not _spend_time(): return
	var keys := Expansion.CONDITIONS.keys(); var cond: String = keys[randi()%keys.size()]
	var spec := str(m.get("specialty",""))
	var age := randi_range(18,85)
	if spec == "peds": age = randi_range(2,17)
	var patient := GameState.create_npc("patient",{"age":age,"closeness":30})
	var symptoms: Array = Expansion.SYMPTOMS.get(cond,["fatigue","pain"]).duplicate()
	symptoms.shuffle(); symptoms = symptoms.slice(0,mini(2,symptoms.size()))
	m["current"] = {"patient":patient,"condition":cond,"symptoms":symptoms,"diagnosed":false,"second":false,"stability":clampf(88.0-float(Expansion.CONDITIONS[cond]["severity"])*10.0+randf_range(-10,10),20,95),"attempts":0,"wrong":false}
	_done("🧑‍⚕️","New patient","%s came in with %s. The chart has symptoms, not an answer." % [GameState.full_name(patient),", ".join(symptoms)],{"stress":2})


func medical_diagnose() -> void:
	var m := _med(); var c: Dictionary = m.get("current",{}); if c.is_empty() or c.get("diagnosed",false): return
	if not _spend_time(): return
	c["attempts"] = int(c["attempts"])+1
	var diff := 35.0+float(Expansion.CONDITIONS[c["condition"]]["severity"])*10.0
	var skill := GameState.stat("smarts")*0.55+float(_p()["job"].get("perf",50))*0.25+float(m["research"])*0.2
	var ok := randf() < clampf((skill-diff+60.0)/100.0,0.12,0.94)
	if ok:
		c["diagnosed"] = true; m["reputation"] = minf(100,float(m["reputation"])+3)
		_done("🧪","Diagnosis","The tests fit: %s. I explained what we know, what we don't, and what happens next." % Expansion.CONDITIONS[c["condition"]]["name"],{"job_perf":5,"smarts":1})
	else:
		c["wrong"] = true
		_done("🧪","Unclear result","The first interpretation doesn't fit the whole picture. I can seek another opinion instead of pretending certainty.",{"stress":4})


func medical_second_opinion() -> void:
	var m := _med(); var c: Dictionary = m.get("current",{}); if c.is_empty() or c.get("second",false): return
	if not _spend_time(): return
	c["second"] = true
	if c.get("wrong",false) or not c.get("diagnosed",false):
		c["diagnosed"] = true; c["wrong"] = false; m["reputation"] = minf(100,float(m["reputation"])+2)
		_done("👥","Second opinion","A colleague caught what I was missing. We changed course before the patient paid for my pride.",{"job_perf":3,"karma":2,"stress":-2})
	else:
		_done("👥","Second opinion","The consultant agreed with the plan. The patient looked relieved to hear two people say the same thing.",{"job_perf":2,"stress":-1})


func medical_treat() -> void:
	var m := _med(); var c: Dictionary = m.get("current",{}); if c.is_empty() or not c.get("diagnosed",false): return
	if not _spend_time(): return
	var sev := int(Expansion.CONDITIONS[c["condition"]]["severity"])
	var chance := clampf(0.83-float(sev)*0.08+float(m["reputation"])/500.0+GameState.stat("smarts")/600.0,0.25,0.96)
	m["patients"] = int(m["patients"])+1
	if randf() < chance:
		var major := sev >= 3
		if major: m["saves"] = int(m["saves"])+1; GameState.counter("patients_saved")
		m["reputation"] = minf(100,float(m["reputation"])+(5 if major else 2))
		var pid: String = c["patient"]; GameState.change_closeness(pid,18)
		if major:
			# Someone whose life I saved does not forget me.
			Bonds.remember(pid,"Saved my life when it mattered.",true)
			GameState.npc(pid)["relation"] = "friend"
			_echo("career","The patient who lived","%s walked out of the hospital because of a decision I made. That stays with both of us." % GameState.full_name(pid), pid, 66, ["medicine","saved"])
		_done("💊","Treatment worked","%s responded to treatment. The numbers moved in the right direction and the room finally exhaled." % GameState.npc(pid)["first"],{"job_perf":8 if major else 4,"happiness":3,"stress":-3,"karma":2})
		m["current"] = {}
	else:
		c["stability"] = maxf(5,float(c["stability"])-20); m["complications"] = int(m["complications"])+1
		_done("⚠️","Complication","The patient deteriorated despite treatment. Now every decision is being documented twice.",{"job_perf":-4,"stress":10})
		if float(c["stability"]) <= 10 and randf() < 0.45:
			medical_malpractice("treatment complication")


func medical_surgery() -> void:
	var m := _med(); var c: Dictionary = m.get("current",{}); if c.is_empty() or not c.get("diagnosed",false): return
	if not _spend_time(): return
	var sev := int(Expansion.CONDITIONS[c["condition"]]["severity"])
	Minigames.play("surgery",{"skill":GameState.stat("smarts")*0.45+float(_p()["job"].get("perf",50))*0.3+float(m["reputation"])*0.25,"difficulty":0.8+sev*0.12},Callable(self,"_surgery_done"))


func _surgery_done(score: float, detail: Dictionary) -> void:
	Fx.play("monitor", 0.01)
	var m := _med(); var c: Dictionary = m.get("current",{}); if c.is_empty(): return
	m["patients"] = int(m["patients"])+1
	if score >= 0.72:
		m["saves"] = int(m["saves"])+1; m["reputation"] = minf(100,float(m["reputation"])+8); GameState.counter("surgeries_success")
		_done("🔪","Successful operation","The last monitor tone steadied. The operation went cleanly, and %s made it through." % GameState.npc(c["patient"])["first"],{"job_perf":12,"happiness":5,"stress":5,"karma":2})
		m["current"] = {}
	elif score >= 0.4:
		m["complications"] = int(m["complications"])+1; c["stability"] = maxf(10,float(c["stability"])-18)
		_done("🫀","Complicated operation","We got through it, but not cleanly. Recovery will be harder and the chart is going to be reviewed.",{"job_perf":2,"stress":12})
		if randf() < 0.25: medical_malpractice("surgical complication")
	else:
		m["complications"] = int(m["complications"])+1; c["stability"] = 5
		var pid2: String = str(c["patient"])
		if randf() < 0.35 and GameState.npcs.has(pid2):
			# Losing a patient on the table is not a stat change.
			GameState.npcs[pid2]["alive"] = false
			m["lost"] = int(m.get("lost",0)) + 1
			GameState.counter("patients_lost")
			m["burnout"] = minf(100,float(m["burnout"])+14)
			_bereave("%s died on the table. I wrote the time down myself." % GameState.full_name(pid2))
			var kin2 := _relative_of(pid2,"enemy")
			if kin2 != "":
				Grit.grudge(kin2, 45)
				GameState.add_log("%s wants to know exactly what happened in that room." % GameState.full_name(kin2))
			_echo("regret","The one I lost","%s did not survive an operation I led. I still go back over the order of it." % GameState.full_name(pid2), pid2, 82, ["medicine","death"])
			m["current"] = {}
		else:
			_done("🚨","Operating-room crisis","The procedure went badly. The team stabilized the patient, but the case is headed to review.",{"job_perf":-12,"stress":18,"happiness":-6})
		medical_malpractice("surgical error")


func medical_research() -> void:
	var m := _med(); if m.is_empty() or not _spend_time(): return
	var gain := 4.0+GameState.stat("smarts")/20.0
	m["research"] = minf(100,float(m["research"])+gain); m["burnout"] = minf(100,float(m["burnout"])+4)
	_done("🔬","Research","I spent the year contributing to a clinical project. It made me sharper—and stole some evenings.",{"smarts":2,"job_perf":4,"stress":4})


func medical_mentor() -> void:
	var m := _med(); if m.is_empty() or not _spend_time(): return
	var trainee := GameState.create_npc("coworker",{"age":randi_range(25,36),"closeness":55})
	_p()["job"]["coworkers"].append(trainee); m["mentored"] = int(m["mentored"])+1; m["reputation"] = minf(100,float(m["reputation"])+3); GameState.counter("medical_mentees")
	_done("🎓","Mentoring","%s became the resident I supervise. Teaching exposed gaps in both of us—and made the team better." % GameState.full_name(trainee),{"job_perf":5,"happiness":3})


func medical_malpractice(reason: String) -> void:
	var m := _med(); if m.is_empty(): return
	m["malpractice"] = int(m["malpractice"])+1; m["reputation"] = maxf(0,float(m["reputation"])-10)
	var claim := Actions._cost(randi_range(15000,120000))
	var defend := clampf(float(m["reputation"])/160.0+GameState.stat("smarts")/300.0,0.15,0.85)
	if randf() < defend:
		_done("⚖️","Malpractice review","A claim followed the %s. The review found the care defensible, but it changed how I practice." % reason,{"stress":12,"job_perf":-3})
	else:
		_p()["money"] = int(_p()["money"])-claim
		Grit.change_credit(-18)
		_strain_home(4,"A lawsuit moved into our house for a year.")
		_echo("regret","The claim that stuck","A %s became a lawsuit I settled for %s. I practice differently now, and not only for the better." % [reason,GameState.fmt_money(claim)],"",64,["medicine","malpractice"])
		# A pattern, not a single bad night, is what ends a licence.
		if int(m["malpractice"]) >= 3 and GameState.has_job():
			m["reputation"] = maxf(0,float(m["reputation"])-20)
			GameState.player["job"]["perf"] = maxf(0.0,float(GameState.player["job"].get("perf",50))-25.0)
			GameState.counter("medical_board_reviews")
			GameState.add_log("The medical board opened a review into a pattern of claims against me.")
			GameState.add_milestone(_p()["age"],"faced a medical board review")
		_done("⚖️","Malpractice settlement","The %s became a lawsuit. My share of the settlement was %s." % [reason,GameState.fmt_money(claim)],{"stress":15,"happiness":-8,"job_perf":-8})


# ============================================================================
# PETS

func pet_train(id: String) -> void:
	if not GameState.npcs.has(id) or not _spend_time(): return
	ensure_pet(id); var n := GameState.npc(id); var pp: Dictionary = n["pet_profile"]
	var gain := randi_range(5,12)+(4 if pp["temperament"] in ["Curious","Social"] else 0)
	pp["training"] = minf(100,float(pp["training"])+gain); GameState.change_closeness(id,6)
	var learned := ""
	if pp["tricks"].size() < PET_TRICKS.size() and randf() < float(pp["training"])/110.0:
		var pool := PET_TRICKS.duplicate(); pool.shuffle()
		for t in pool:
			if not pp["tricks"].has(t): learned=t; pp["tricks"].append(t); break
	_done("🎓","Training " + n["first"],"%s focused for almost the whole session.%s" % [n["first"],(" New trick: %s." % learned) if learned!="" else ""],{"happiness":3,"stress":-2})


func pet_show(id: String) -> void:
	if not GameState.npcs.has(id) or not _spend_time(): return
	Fx.play("crowd", 0.01)
	ensure_pet(id); var n:=GameState.npc(id); var pp:Dictionary=n["pet_profile"]
	pp["shows"] = int(pp["shows"])+1; _p()["ambition"]["pets"]["shows"] = int(_p()["ambition"]["pets"]["shows"])+1
	var score := float(pp["training"])*0.48+float(n["closeness"])*0.28+float(pp["health"])*0.12+float(pp["pedigree"])*0.12+randf_range(-12,12)
	if pp.get("groomed",false): score += 8; pp["groomed"] = false
	if score >= 80:
		pp["titles"] = int(pp["titles"])+1; _p()["ambition"]["pets"]["titles"] = int(_p()["ambition"]["pets"]["titles"])+1; GameState.counter("pet_titles")
		var prize := Actions._cost(randi_range(800,4000)); _p()["money"] = int(_p()["money"])+prize
		_done("🏆","Best in class","%s won a title and %s in prize money. The ribbon is going on the wall." % [n["first"],GameState.fmt_money(prize)],{"happiness":9,"fame":1})
	elif score >= 55:
		_done("🏅","Good showing","%s placed well. A judge complimented the training even without a trophy." % n["first"],{"happiness":5})
	else:
		_done("🐾","Long day","%s was far more interested in the smells under the table than the judges." % n["first"],{"happiness":2})


func pet_vet(id:String) -> void:
	if not GameState.npcs.has(id) or not _spend_time(): return
	ensure_pet(id); var n:=GameState.npc(id); var pp:Dictionary=n["pet_profile"]
	var fee:=Actions._cost(280); if int(_p()["money"]) < fee: EventEngine.push_info("💸","Vet","You need %s."%GameState.fmt_money(fee)); return
	_p()["money"] = int(_p()["money"])-fee; pp["health"] = minf(100,float(pp["health"])+randi_range(12,28)); pp["vet_due"] = int(_p()["age"])+2
	_done("🩺","Vet visit","%s got a full checkup, vaccines and whatever treatment was needed." % n["first"],{"happiness":1})


func pet_groom(id:String) -> void:
	if not GameState.npcs.has(id) or not _spend_time(): return
	ensure_pet(id); var n:=GameState.npc(id); n["pet_profile"]["groomed"] = true; GameState.change_closeness(id,3)
	_done("🧼","Fresh coat","%s came home clean, brushed and deeply suspicious of the dryer." % n["first"],{"happiness":2})


func pet_breed(id:String) -> void:
	if not GameState.npcs.has(id) or not _spend_time(): return
	ensure_pet(id); var n:=GameState.npc(id); var pp:Dictionary=n["pet_profile"]
	var count:=randi_range(1,3); pp["bred_age"]=int(_p()["age"]); pp["litter"]=int(pp["litter"])+count; _p()["ambition"]["pets"]["litters"] = int(_p()["ambition"]["pets"]["litters"])+1; GameState.counter("pet_litters")
	var names:Array=[]
	for i in range(count):
		var kid:=GameState.create_npc("pet",{"species":n.get("species","pet"),"first":ContentDB.random_pet_name(),"last":"","age":0,"closeness":55}); ensure_pet(kid); GameState.npcs[kid]["pet_profile"]["pedigree"] = int((float(pp["pedigree"])+randf_range(25,90))/2.0); names.append(GameState.npc(kid)["first"])
	_done("🐾","A litter","%s became the parent of %d little %ss: %s. They are real pets now, with their own health and temperaments." % [n["first"],count,str(n.get("species","pet")),", ".join(names)],{"happiness":8,"stress":5})


func pet_therapy(id:String) -> void:
	if not GameState.npcs.has(id) or not _spend_time(): return
	ensure_pet(id); var n:=GameState.npc(id); n["pet_profile"]["therapy"] = true; GameState.counter("therapy_pets")
	LifeThreads.remember("recovery", "%s became a trained support animal" % n["first"], "%s learned how to stay close when life got heavy." % n["first"], id, 62, ["pet", "support", "recovery"])
	var carrying := Expansion.has_mental("anxiety") or Expansion.has_mental("depression") or Expansion.has_mental("panic") or Expansion.has_mental("grief") or Expansion.has_mental("burnout")
	if carrying:
		_done("🫂","Therapy-animal certification","%s passed the temperament and obedience work. On the days I can't explain to anyone, they are already in the doorway." % n["first"],{"happiness":11,"stress":-16,"karma":3})
	else:
		_done("🫂","Therapy-animal certification","%s passed the temperament and obedience work. Quiet routines with them now help more during hard years." % n["first"],{"happiness":6,"stress":-8,"karma":3})


func pet_business_start(id:String) -> void:
	if not PET_BUSINESSES.has(id) or int(_p()["age"])<18: return
	var d:Array=PET_BUSINESSES[id]; var cost:=Actions._cost(int(d[2])); if int(_p()["money"])<cost: EventEngine.push_info("💸",d[1],"You need %s."%GameState.fmt_money(cost)); return
	if not _spend_time(): return
	_p()["money"] = int(_p()["money"])-cost; GameState.counter("pet_businesses"); _p()["ambition"]["pets"]["business"]={"id":id,"name":d[1],"level":1,"reputation":35.0,"staff":1,"profit":0,"marketing":10.0,"featured":"","value":cost}
	_done(d[0],"Open for paws","I opened %s. My pets stopped being a side activity and became part of how I make a living." % d[1],{"happiness":8,"stress":6})


func pet_business_action(kind:String) -> void:
	var b:Dictionary=_p()["ambition"]["pets"]["business"]; if b.is_empty(): return
	match kind:
		"market":
			var cost:=Actions._cost(2500*int(b["level"])); if int(_p()["money"])<cost: EventEngine.push_info("💸","Marketing","You need %s."%GameState.fmt_money(cost)); return
			if not _spend_time():return; _p()["money"]=int(_p()["money"])-cost; b["marketing"]=minf(100,float(b["marketing"])+20); _done("📣",b["name"],"I ran a local campaign built around actual client stories instead of stock photos.",{"stress":2})
		"expand":
			var cost:=Actions._cost(20000*int(b["level"])); if int(_p()["money"])<cost: EventEngine.push_info("💸","Expansion","You need %s."%GameState.fmt_money(cost)); return
			if not _spend_time():return; _p()["money"]=int(_p()["money"])-cost; b["level"]=int(b["level"])+1; b["staff"]=int(b["staff"])+1; b["value"]=int(b["value"])+cost; _done("🏗️",b["name"],"I expanded the business and hired another pair of hands.",{"stress":5,"happiness":4})
		"feature":
			var pets:=GameState.npcs_with("pet"); if pets.is_empty(): return
			var best:String=pets[0]
			for pid in pets:
				ensure_pet(pid)
				if float(GameState.npc(pid)["pet_profile"]["training"])>float(GameState.npc(best)["pet_profile"]["training"]): best=pid
			b["featured"]=best; GameState.npc(best)["pet_profile"]["business_star"]=true; b["reputation"]=minf(100,float(b["reputation"])+8)
			_done("🌟","Local mascot","%s became the face of %s. Customers started asking for them by name." % [GameState.npc(best)["first"],b["name"]],{"happiness":5,"fame":1})


# ============================================================================
# SPORTS PRO

func sports_actions(c:Dictionary) -> Array:
	ensure_sports(c)
	if c.get("id","")!="athlete": return []
	var out:Array=[]
	if c.get("team","")!="":
		out.append({"id":"v8_standings","name":"League standings","icon":"📋","sub":"Season table, record and postseason position"})
		out.append({"id":"v8_agent","name":"Meet with your agent","icon":"🤝","sub":"Contracts, free agency and leverage"})
		out.append({"id":"v8_trade","name":"Request a trade","icon":"🔄","sub":"Push for a new team · can anger management","off":c.get("trade_requested",false)})
		out.append({"id":"v8_media","name":"Face the media","icon":"🎙️","sub":"Shape reputation after the season"})
		out.append({"id":"v8_team","name":"Team chemistry","icon":"🫂","sub":"Spend time with teammates"})
	if int(c.get("injured",0))>0: out.append({"id":"v8_second_opinion","name":"Get a second opinion","icon":"🩻","sub":"Could shorten recovery or reveal something worse"})
	return out


func sports_action(aid:String,c:Dictionary) -> void:
	ensure_sports(c)
	match aid:
		"v8_standings":
			var table: Array = c.get("standings",[])
			if table.is_empty():
				EventEngine.push_info("📋","League standings","The season table has not been generated yet. Play through a season first.")
			else:
				var lines: Array = []
				for i in range(mini(8,table.size())):
					var row: Dictionary = table[i]
					lines.append("%d. %s  %d-%d%s" % [i+1,row["team"],int(row["wins"]),int(row["losses"]),"  ← you" if row.get("player",false) else ""])
				EventEngine.push_info("📋","League standings","\n".join(lines))
		"v8_agent":
			if not _spend_time():return
			c["agent_quality"] = mini(3,int(c["agent_quality"])+1)
			if int(c.get("contract_years",0))<=1 and c.get("team","")!="":
				var raise:=1.05+0.04*int(c["agent_quality"])+float(c["skill"])/1000.0; c["contract"]=int(int(c["contract"])*raise); c["contract_years"]=randi_range(2,5)
				_done("🤝","Contract meeting","My agent turned a good season into leverage. The new deal is %s a year for %d years." % [GameState.fmt_money(int(c["contract"])),int(c["contract_years"])],{"happiness":5})
			else:_done("🤝","Agent meeting","We mapped out endorsements, clauses and the next contract window.",{"stress":-2})
		"v8_trade":
			if not _spend_time():return
			c["trade_requested"]=true
			if randf()<clampf(float(c["skill"])/120.0+0.15,0.2,0.9):
				var old:String=c["team"]; var newt:=_random_team(old); c["team"]=newt; c["teams"].append(newt); c["trade_requested"]=false; GameState.counter("sports_trades")
				_done("🔄","Traded","Management found a deal. I left the %s for the %s; the locker room I knew became an opponent overnight." % [old,newt],{"happiness":3,"fame":2,"stress":7})
			else:_done("🔄","Trade denied","The front office said no. Now everyone in the building knows I wanted out.",{"happiness":-5,"stress":8})
		"v8_media":
			if not _spend_time():return
			EventEngine.push_decision({"id":"_sports_media","icon":"🎙️","title":"Postgame microphones","text":"A reporter asks whether the team is wasting your prime years.","choices":[
				{"label":"Defend the team","outcomes":[{"text":"I kept it about the locker room, not myself.","effects":{"happiness":2,"fame":1},"ambition":{"kind":"sports_form","value":4}}]},
				{"label":"Say what everyone is thinking","outcomes":[{"weight":2,"text":"The quote went everywhere. Fans loved the honesty; management didn't.","effects":{"fame":4,"stress":5},"ambition":{"kind":"sports_form","value":-2}},{"weight":1,"text":"The blunt answer lit a fire under the team.","effects":{"fame":2,"happiness":4},"ambition":{"kind":"sports_form","value":7}}]},
				{"label":"Refuse the premise","outcomes":[{"text":"I gave them nothing dramatic to clip.","effects":{"stress":-2},"ambition":{"kind":"sports_form","value":2}}]},
			]})
		"v8_team":
			if not _spend_time():return
			c["season_form"]=minf(100,float(c["season_form"])+8); _done("🫂","Locker room","I spent time with teammates away from cameras. The next practice felt less like eleven separate careers.",{"happiness":4,"stress":-2})
		"v8_second_opinion":
			if not _spend_time():return
			if randf()<0.65:
				c["injured"]=maxi(0,int(c["injured"])-1); _done("🩻","Second opinion","Another specialist found a better rehab plan. I may get a season back.",{"happiness":6,"stress":-3})
			else:
				c["injured"]=int(c["injured"])+1; Expansion.add_injury("knee" if c.get("sport","") in ["soccer","basketball","football"] else "shoulder","pro sports"); _done("🩻","Harder truth","The scan showed more damage than the team doctor first thought. Recovery will take longer.",{"happiness":-8,"stress":8})


func _random_team(exclude:String="") -> String:
	for i in range(20):
		var t := "%s %s" % [SPORTS_CITIES[randi()%SPORTS_CITIES.size()],SPORTS_NAMES[randi()%SPORTS_NAMES.size()]]
		if t!=exclude:return t
	return "Capital City Stars"


func sports_yearly(c:Dictionary,p:Dictionary,perf:float) -> void:
	ensure_sports(c)
	if c.get("team","")=="": return
	c["season"]=int(c["season"])+1; c["season_form"]=clampf(float(c["season_form"])*0.45+perf*0.55,0,100)
	var games:=82 if c.get("sport","") in ["basketball","hockey"] else (162 if c.get("sport","")=="baseball" else 34)
	if c.get("sport","") in ["football"]:games=17
	if c.get("sport","") in ["tennis","boxing","golf"]:games=24
	var winrate:=clampf(0.28+float(c["season_form"])/190.0+randf_range(-0.08,0.08),0.12,0.88)
	var wins:=int(round(games*winrate)); var losses:=games-wins; c["wins"]=int(c["wins"])+wins;c["losses"]=int(c["losses"])+losses
	var table: Array = [{"team":c["team"],"wins":wins,"losses":losses,"player":true}]
	var used: Dictionary = {str(c["team"]):true}
	while table.size() < 8:
		var other := _random_team()
		if used.has(other): continue
		used[other] = true
		var ow := int(round(games * clampf(randf_range(0.28,0.72),0.18,0.82)))
		table.append({"team":other,"wins":ow,"losses":games-ow,"player":false})
	table.sort_custom(func(a,b): return int(a["wins"]) > int(b["wins"]))
	c["standings"] = table
	c["salary_history"].append({"age":int(p["age"]),"team":c["team"],"salary":int(c["contract"]),"wins":wins,"losses":losses})
	if int(c["contract_years"])>0:c["contract_years"]=int(c["contract_years"])-1
	if int(c["contract_years"])==0:
		c["free_agent"]=true
		if perf>=55:
			var old: String = c["team"]; var newt: String = old if randf()<0.45 else _random_team(old); c["team"]=newt; c["contract"]=int(maxi(int(c["contract"]),100000)*randf_range(1.08,1.45)); c["contract_years"]=randi_range(2,5);c["free_agent"]=false
			if not c["teams"].has(newt):c["teams"].append(newt)
			var bonus := int(int(c["contract"]) * randf_range(0.15,0.4))
			p["money"] = int(p["money"]) + bonus
			GameState.add_log("Free agency ended with a %d-year deal from the %s worth %s a year, plus a %s signing bonus." % [int(c["contract_years"]),newt,GameState.fmt_money(int(c["contract"])),GameState.fmt_money(bonus)])
			if newt != old:
				_strain_home(6,"Moved the whole family for another team.")
				GameState.add_milestone(int(p["age"]),"signed with the %s" % newt)
				_echo("career","The city I was traded to","Signing with the %s meant a new house, a new school run and a family that had to start over with me."%newt,"",58,["sports","relocation"])
		else:
			GameState.add_log("My contract expired without a strong market. I signed a one-year prove-it deal.");c["contract_years"]=1;c["contract"]=int(int(c["contract"])*0.78)
	var playoff_ch:=clampf((winrate-0.42)*2.2,0.05,0.9)
	if randf()<playoff_ch:
		c["playoffs"]=int(c["playoffs"])+1; GameState.counter("sports_playoffs"); GameState.add_log("The %s reached the postseason at %d-%d." % [c["team"],wins,losses])
		if randf()<clampf((perf-35)/100.0,0.12,0.7):
			c["finals"]=int(c["finals"])+1; GameState.counter("sports_finals"); GameState.add_log("We made it all the way to the championship round.")
			if randf() < clampf((perf-20.0)/100.0,0.18,0.72):
				c["league_titles"] = int(c["league_titles"])+1; GameState.counter("sports_titles"); c["legacy_points"] = int(c["legacy_points"])+12; GameState.add_log("We won the league championship. The season ended under confetti instead of questions."); Fx.play("fanfare",0.01)
				var purse := int(maxi(int(c["contract"]),100000) * randf_range(0.2,0.5))
				p["money"] = int(p["money"]) + purse
				GameState.apply_effects({"fame":9,"happiness":14,"popularity":8})
				GameState.add_milestone(int(p["age"]),"won a league championship with the %s" % c["team"])
				for fid in _home_ids(): GameState.change_closeness(fid,6)
				_echo("career","The year we won it all","We won the championship with the %s. Everyone who ever drove me to practice was in that building."%c["team"],"",76,["sports","championship"])
	var hard_sport: bool = c.get("sport","") in ["football","hockey","boxing","basketball"]
	if randf() < (0.16 if hard_sport else 0.08):
		Expansion.add_injury(["knee","shoulder","concussion","sprain"][randi()%4],"a season in professional sport")
		c["season_form"] = maxf(0.0,float(c["season_form"])-12.0)
		GameState.counter("sports_injuries")
		GameState.add_log("An injury cost me part of the season and a piece of what I could do afterwards.")
		if randf() < 0.22:
			Grit.habit("workaholic", 8.0)
		_echo("health","The injury that changed my game","I came back from it, but never all the way back to what I was before.","",62,["sports","injury"])
	if perf>82 and randf()<0.45:
		var pool:=SPORTS_AWARDS.duplicate();pool.shuffle();var award:String=pool[0]
		if not c["awards"].has(award):c["awards"].append(award); c["legacy_points"]=int(c["legacy_points"])+8; GameState.counter("sports_awards"); GameState.add_log("I won %s." % award);GameState.apply_effects({"fame":4,"happiness":5})
	if c.get("rival","")=="" and int(c["season"])>=2 and randf()<0.25:
		c["rival"]=GameState.create_npc("rival",{"age":maxi(18,int(p["age"])+randi_range(-4,4)),"closeness":15});GameState.add_log("A rivalry with %s became part of every matchup." % GameState.full_name(c["rival"]))
		Grit.grudge(str(c["rival"]), 35)
		_echo("career","The one who pushed me","%s made me better by refusing to let me be comfortable."%GameState.full_name(c["rival"]),str(c["rival"]),60,["sports","rival"])


# ============================================================================
# ENTERPRISE / MULTIPLE COMPANIES

func enterprise_start(id:String) -> void:
	if not Empires.INDUSTRIES.has(id) or int(_p()["age"])<18:return
	var ind:Dictionary=Empires.INDUSTRIES[id];var cost:=Actions._cost(int(ind["cost"])*2)
	if int(_p()["money"])<cost:EventEngine.push_info("💸",ind["name"],"You need %s."%GameState.fmt_money(cost));return
	if not _spend_time():return
	_p()["money"]=int(_p()["money"])-cost
	var nm:String=ind["names"][randi()%ind["names"].size()];var ceo:=GameState.create_npc("coworker",{"age":randi_range(28,60),"closeness":50})
	_p()["ambition"]["enterprise"]["portfolio"].append({"ind":id,"industry":ind["name"],"icon":ind["icon"],"name":nm,"value":cost,"profit":0,"quality":45.0,"staff":4,"debt":0,"stake":1.0,"ceo":ceo,"years":0,"public":false})
	GameState.counter("businesses"); GameState.counter("portfolio_companies"); _done(ind["icon"],"Second company","I founded %s without closing my other ventures. %s is running day-to-day operations." % [nm,GameState.full_name(ceo)],{"happiness":7,"stress":7})


func enterprise_acquire() -> void:
	Fx.play("cash", 0.01)
	var e:Dictionary=_p()["ambition"]["enterprise"];var ids:=Empires.INDUSTRIES.keys();var id:String=ids[randi()%ids.size()];var ind:Dictionary=Empires.INDUSTRIES[id]
	var price:=Actions._cost(int(ind["cost"])*randi_range(3,10));if int(_p()["money"])<price:EventEngine.push_info("🤝","Acquisition","A target is available for about %s. You don't have enough liquid cash."%GameState.fmt_money(price));return
	if not _spend_time():return
	var nm:String=ind["names"][randi()%ind["names"].size()];var ceo:=GameState.create_npc("coworker",{"age":randi_range(30,65),"closeness":42})
	EventEngine.push_decision({"id":"_acquire","icon":"🤝","title":"Acquire " + nm,"text":"%s is willing to sell for %s. Its staff and customers come with the deal." % [nm,GameState.fmt_money(price)],"choices":[
		{"label":"Buy it outright","requires":{"money":price},"outcomes":[{"text":"I signed the acquisition papers. %s joined the portfolio."%nm,"effects":{"money":-price,"stress":6},"ambition":{"kind":"company_add","company":{"ind":id,"industry":ind["name"],"icon":ind["icon"],"name":nm,"value":price,"profit":0,"quality":55.0,"staff":randi_range(4,14),"debt":0,"stake":1.0,"ceo":ceo,"years":0,"public":false}}}]},
		{"label":"Finance half with debt","requires":{"money":price/2},"outcomes":[{"text":"I bought control using cash and debt. The portfolio got bigger—and less forgiving.","effects":{"money":-price/2,"stress":9},"ambition":{"kind":"company_add","company":{"ind":id,"industry":ind["name"],"icon":ind["icon"],"name":nm,"value":price,"profit":0,"quality":55.0,"staff":randi_range(4,14),"debt":price/2,"stake":1.0,"ceo":ceo,"years":0,"public":false}}}]},
		{"label":"Walk away","outcomes":[{"text":"I left the deal on the table."}]},
	]})


func enterprise_dividend() -> void:
	var e:Dictionary=_p()["ambition"]["enterprise"];if e["portfolio"].is_empty():return
	if not _spend_time():return
	var cash:=0
	for co in e["portfolio"]:
		var draw:=maxi(0,int(int(co["value"])*0.04*float(co["stake"])));cash+=draw;co["value"]=maxi(1000,int(co["value"])-draw);co["quality"]=maxf(5,float(co["quality"])-4)
	_p()["money"]=int(_p()["money"])+cash;e["dividends"]=int(e["dividends"])+cash
	_done("💸","Special dividend","I pulled %s out of the portfolio. Useful cash today, less cushion for the companies tomorrow."%GameState.fmt_money(cash),{"stress":-2})


func enterprise_succession() -> void:
	var kids:=GameState.npcs_with("child");if kids.is_empty():return
	kids.sort_custom(func(a,b):return int(GameState.npc(a).get("closeness",0))>int(GameState.npc(b).get("closeness",0)))
	var id:String=kids[0];_p()["ambition"]["enterprise"]["succession"]=id; GameState.counter("succession_plans")
	GameState.change_closeness(id,12)
	Bonds.remember(id,"Chose me to carry the family business.",true)
	for other in kids:
		if other != id: GameState.change_closeness(other,-6)
	_echo("family","The one I chose","I named %s as steward of everything I built. The others noticed which name was on the document."%GameState.full_name(id),id,70,["business","succession","family"])
	_done("📜","Succession plan","I named %s as the intended steward of my company portfolio. That promise may matter when the family tree continues."%GameState.full_name(id),{"happiness":2})


func _enterprise_yearly() -> void:
	var e:Dictionary=_p()["ambition"]["enterprise"]
	for co in e["portfolio"]:
		co["years"]=int(co["years"])+1
		var ind:Dictionary=Empires.INDUSTRIES.get(co["ind"],{})
		var demand:=0.55+float(co["quality"])/130.0+randf_range(-0.2,0.2);var rev:=Actions._cost(int(ind.get("rev",120000)*demand*(1.0+int(co["staff"])*0.12)));var profit:=int(rev*float(ind.get("margin",0.15)))-int(co["staff"])*Actions._cost(13000)-int(int(co["debt"])*0.07)
		co["profit"]=profit;co["quality"]=clampf(float(co["quality"])+randf_range(-4,3),8,100);co["value"]=maxi(Actions._cost(5000),int(lerpf(float(co["value"]),maxf(float(co["value"])*0.6,float(profit)*8.0),0.35)))
		var draw:=maxi(0,int(profit*float(co["stake"])*0.35));_p()["money"]=int(_p()["money"])+draw;e["dividends"]=int(e["dividends"])+draw
		if profit<0 and randf()<0.08:
			co["debt"]=int(co["debt"])+abs(profit);GameState.add_log("%s borrowed to cover a bad year."%co["name"])
		if int(co["debt"])>int(co["value"])*2 and randf()<0.35:
			GameState.add_log("%s entered bankruptcy after years of debt."%co["name"]);e["bankruptcies"]=int(e["bankruptcies"])+1;co["stake"]=0.0;co["value"]=0;co["profit"]=0
			GameState.counter("company_bankruptcies")
			Grit.change_credit(-45)
			GameState.apply_effects({"stress":14,"happiness":-8})
			_strain_home(4,"Lost a company and brought the whole year home with it.")
			var ceo_id := str(co.get("ceo",""))
			if ceo_id != "" and GameState.npcs.has(ceo_id):
				Grit.grudge(ceo_id, 30)
				Bonds.remember(ceo_id,"Let the company go under with me inside it.",false)
			_echo("money","The company I lost","%s collapsed under debt I signed for. Lenders remember that longer than people do."%co["name"],ceo_id,66,["business","bankruptcy"])
	var kept:Array=[]
	for co in e["portfolio"]:
		if float(co.get("stake",0))>0:kept.append(co)
	e["portfolio"]=kept


# ============================================================================
# JUSTICE

func record_case(crime:String,result:String,years:int=0,evidence:float=0.0,lawyer:int=0) -> void:
	ensure();var j:Dictionary=_p()["ambition"]["justice"];j["history"].append({"crime":crime,"result":result,"age":int(_p()["age"]),"years":years,"evidence":evidence,"lawyer":lawyer,"appealed":false})
	if result == "convicted":
		Grit.change_credit(-35)
		_strain_home(7,"Went to court and took the family reputation along.")
		GameState.counter("convictions")
		for rel in ["mother","father"]:
			for pid2 in GameState.npcs_with(rel):
				GameState.change_closeness(pid2,-5)
		_echo("justice","The conviction on my record","A %s conviction followed me into every application, every lease and every conversation about my past."%crime,"",74,["justice","record"])
	elif result in ["acquitted","dismissed"]:
		_echo("justice","The charge that nearly stuck","I was charged with %s and walked out without a conviction. Not everyone believed the verdict."%crime,"",58,["justice","acquittal"])
	if j["history"].size()>20:j["history"].pop_front()
	if result=="plea":j["pleas"]=int(j["pleas"])+1
	if result=="convicted" and years<=2 and years>0:j["probation"]=maxi(int(j["probation"]),years+1)


func justice_appeal() -> void:
	Fx.play("gavel", 0.01)
	var j:Dictionary=_p()["ambition"]["justice"];if j["history"].is_empty():return
	var c:Dictionary=j["history"][-1];if c.get("appealed",false):return
	var fee:=Actions._cost(12000);if int(_p()["money"])<fee:EventEngine.push_info("💸","Appeal","You need %s for appellate counsel."%GameState.fmt_money(fee));return
	if not _spend_time():return
	_p()["money"]=int(_p()["money"])-fee;c["appealed"]=true;j["appeals"]=int(j["appeals"])+1
	var chance:=clampf(0.12+GameState.stat("smarts")/500.0+(0.12 if float(c.get("evidence",50))<45 else 0.0),0.08,0.5)
	if randf()<chance:
		c["result"]="overturned"; _p()["record"].erase(c["crime"]); GameState.counter("appeals_won"); _done("🏛️","Conviction overturned","The appellate court found a serious error. The conviction was set aside.",{"happiness":14,"stress":-10})
	else:_done("🏛️","Appeal denied","The higher court left the conviction in place.",{"happiness":-4,"stress":5})


func justice_probation_check() -> void:
	var j:Dictionary=_p()["ambition"]["justice"];if int(j["probation"])<=0 and int(j["parole"])<=0:return
	if not _spend_time():return
	_done("✅","Supervision check-in","I showed up, answered the questions and kept the year uneventful. In this case, uneventful is progress.",{"stress":-2,"karma":1})


func _justice_yearly() -> void:
	var j:Dictionary=_p()["ambition"]["justice"]
	for k in ["probation","parole"]:
		if int(j[k])>0:
			j[k]=int(j[k])-1
			if float(_p().get("heat",0))>35 or not _p().get("record",[]).is_empty() and randf()<0.08:
				GameState.add_log("My %s officer warned me that another incident could send me back before a judge." % k)


# ============================================================================
# YEARLY JOB / PET CONSEQUENCES

func _job_yearly() -> void:
	if not GameState.has_job():return
	ensure_job();var j:Dictionary=_p()["job"]
	var cs: Dictionary = j["career_story"]
	cs["network"] = maxf(0,float(cs["network"])*0.985)
	cs["training"] = maxf(0,float(cs["training"])*0.94)
	# Professional reputation nudges performance but never replaces doing the work.
	j["perf"] = clampf(float(j.get("perf",50)) + (float(cs["reputation"])-50.0)/55.0, 0, 100)
	if str(cs.get("rival","")) != "" and GameState.npcs.has(str(cs["rival"])) and randf() < 0.12:
		var rival: Dictionary = GameState.npc(str(cs["rival"]))
		GameState.add_log("%s and I ended up competing for the same visible assignment again." % rival["first"])
		if randf() < clampf(float(j["perf"])/115.0,0.2,0.82): cs["reputation"] = minf(100,float(cs["reputation"])+2)
		else: cs["reputation"] = maxf(0,float(cs["reputation"])-1)
	if j.get("id","")=="police":
		var d:Dictionary=j["police"]
		if int(d["ia"])>0 and randf()<0.35:
			var clean:=randf()<clampf(float(d["integrity"])/100.0,0.1,0.9)
			if clean:
				d["ia"]=maxi(0,int(d["ia"])-1);GameState.add_log("Internal Affairs closed one complaint without discipline.")
			else:
				d["reputation"]=maxf(0,float(d["reputation"])-7);j["perf"]=maxf(0,float(j["perf"])-10);GameState.add_log("Internal Affairs sustained a complaint against me. My file got thicker.")
		if not d["current"].is_empty() and int(_p()["age"])-int(d["current"].get("opened",int(_p()["age"])))>=3:
			GameState.add_log("My open case is aging. Witnesses are getting harder to reach and supervisors are asking questions.");d["current"]["evidence"]=maxf(0,float(d["current"]["evidence"])-4)
	elif j.get("id","") in ["doctor","nurse"]:
		var m:Dictionary=j["medicine"];m["burnout"]=clampf(float(m["burnout"])+float(j.get("perf",50))/30.0+randf_range(-3,5),0,100)
		if float(m["burnout"])>75:
			GameState.apply_effects({"stress":6,"happiness":-4});GameState.add_log("Clinical burnout followed me home this year.")
			if randf()<0.18:Expansion._add_mental("burnout")
			_strain_home(3,"Was never really in the room, even at home.")
			if randf()<0.14:
				Grit.habit("workaholic", 10.0)
		elif float(m["burnout"])<35:GameState.apply_effects({"stress":-1})
		if not m["current"].is_empty():
			m["current"]["stability"]=maxf(0,float(m["current"]["stability"])-randf_range(0,8));if float(m["current"]["stability"])<=5:medical_malpractice("an unresolved patient crisis");m["current"]={}


func _pets_yearly() -> void:
	for id in GameState.npcs_with("pet"):
		ensure_pet(id);var n:=GameState.npc(id);var pp:Dictionary=n["pet_profile"]
		pass
		if int(_p()["age"])>=int(pp["vet_due"]):pp["health"]=maxf(0,float(pp["health"])-2)
		if pp.get("therapy",false):GameState.apply_effects({"stress":-1,"happiness":1})
		if float(pp["health"])<28 and randf()<0.15:
			GameState.add_log("%s has been slowing down. A vet visit would be a good idea."%n["first"])
		var old_enough := int(n["age"]) >= 11
		if float(pp["health"])<=0.0:
			n["alive"]=false
			GameState.counter("pets_lost")
			var years := int(n["age"])
			_bereave("%s died at %d. The house is the wrong kind of quiet."%[n["first"],years])
			for kid in GameState.npcs_with("child"):
				if int(GameState.npc(kid).get("age",99))<20: GameState.change_closeness(kid,-4)
			_echo("grief","Losing %s"%n["first"],"%s was with me for %d years. I still reach for the leash sometimes."%[n["first"],years],id,68,["pet","grief"])
	var b:Dictionary=_p()["ambition"]["pets"]["business"]
	if not b.is_empty():
		var featured_bonus:=0.0
		if b.get("featured","")!="" and GameState.npcs.has(b["featured"]):featured_bonus=float(GameState.npc(b["featured"])["pet_profile"]["training"])/200.0
		var base:float=PET_BUSINESSES[b["id"]][3];var revenue:=Actions._cost(int((40000+int(b["level"])*35000)*(0.6+float(b["reputation"])/100.0+float(b["marketing"])/150.0+featured_bonus)*randf_range(0.75,1.25)));var costs:=Actions._cost(int(b["staff"])*18000+int(b["level"])*8000);var profit:=int(revenue*base)-costs;b["profit"]=profit;b["value"]=maxi(Actions._cost(10000),int(lerpf(float(b["value"]),maxf(float(b["value"])*0.7,float(profit)*7),0.4)));b["marketing"]=maxf(0,float(b["marketing"])*0.72);b["reputation"]=clampf(float(b["reputation"])+randf_range(-2,3),5,100);_p()["money"]=int(_p()["money"])+profit
		GameState.add_log("%s %s %s this year." % [b["name"],"made" if profit>=0 else "lost",GameState.fmt_money(abs(profit))])


# ============================================================================
# EVENT BRIDGES / CONDITIONS

func event_condition(cond:Dictionary) -> bool:
	ensure()
	if cond.has("job_id"):
		if not GameState.has_job(): return false
		var want=cond["job_id"];var have=str(_p()["job"].get("id",""))
		if want is Array:
			if not Array(want).has(have):return false
		elif str(want)!=have:return false
	if cond.has("police_case") and bool(cond["police_case"]) != (GameState.has_job() and _p()["job"].get("id","")=="police" and not _p()["job"].get("police",{}).get("current",{}).is_empty()):return false
	if cond.has("medical_specialty"):
		if not GameState.has_job() or not ["doctor","nurse"].has(_p()["job"].get("id","")) or str(_p()["job"].get("medicine",{}).get("specialty",""))!=str(cond["medical_specialty"]):return false
	if cond.has("min_pet_training"):
		var ok:=false
		for id in GameState.npcs_with("pet"):
			ensure_pet(id);if float(GameState.npc(id)["pet_profile"]["training"])>=float(cond["min_pet_training"]):ok=true
		if not ok:return false
	if cond.has("pet_business") and bool(cond["pet_business"]) != (not _p()["ambition"]["pets"]["business"].is_empty()):return false
	if cond.has("min_companies") and _p()["ambition"]["enterprise"]["portfolio"].size()+ (1 if not _p().get("business",{}).is_empty() else 0)<int(cond["min_companies"]):return false
	if cond.has("on_probation") and bool(cond["on_probation"]) != (int(_p()["ambition"]["justice"]["probation"])>0):return false
	return true


func outcome(data:Dictionary,roles:Dictionary={}) -> void:
	ensure();var kind:=str(data.get("kind",""))
	match kind:
		"police_integrity":
			if GameState.has_job() and _p()["job"].get("id","")=="police":var d:=_police();d["integrity"]=clampf(float(d["integrity"])+float(data.get("value",0)),0,100)
		"police_ia":
			if GameState.has_job() and _p()["job"].get("id","")=="police":var d:=_police();d["ia"]=int(d["ia"])+int(data.get("value",1));d["integrity"]=maxf(0,float(d["integrity"])-5)
		"case_evidence":
			var d:=_police();if not d.is_empty() and not d["current"].is_empty():d["current"]["evidence"]=clampf(float(d["current"]["evidence"])+float(data.get("value",0)),0,100)
		"case_confession":
			var d:=_police();if not d.is_empty() and not d["current"].is_empty():d["current"]["confession"]=true;d["current"]["evidence"]=clampf(float(d["current"]["evidence"])+float(data.get("evidence",12)),0,100);d["integrity"]=clampf(float(d["integrity"])+float(data.get("integrity",0)),0,100)
		"sports_form":
			if Careers.has_career("athlete"):var c:=Careers.career();ensure_sports(c);c["season_form"]=clampf(float(c["season_form"])+float(data.get("value",0)),0,100)
		"company_add":
			var co:Dictionary=data.get("company",{}).duplicate(true);if not co.is_empty():_p()["ambition"]["enterprise"]["portfolio"].append(co);_p()["ambition"]["enterprise"]["acquisitions"]=int(_p()["ambition"]["enterprise"]["acquisitions"])+1; GameState.counter("company_acquisitions"); GameState.counter("portfolio_companies")
		"medical_reputation":
			if GameState.has_job() and ["doctor","nurse"].has(_p()["job"].get("id","")):var m:=_med();m["reputation"]=clampf(float(m["reputation"])+float(data.get("value",0)),0,100)
		"career_reputation":
			if GameState.has_job():
				ensure_job()
				var cs: Dictionary = _p()["job"]["career_story"]
				cs["reputation"] = clampf(float(cs["reputation"]) + float(data.get("value",0)), 0, 100)
		"career_network":
			if GameState.has_job():
				ensure_job()
				var cs: Dictionary = _p()["job"]["career_story"]
				cs["network"] = clampf(float(cs["network"]) + float(data.get("value",0)), 0, 100)
		"police_reputation":
			if GameState.has_job() and _p()["job"].get("id","") == "police":
				var pd := _police()
				pd["reputation"] = clampf(float(pd["reputation"]) + float(data.get("value",0)), 0, 100)
		"medical_burnout":
			if GameState.has_job() and ["doctor","nurse"].has(_p()["job"].get("id","")):
				var md := _med()
				md["burnout"] = clampf(float(md["burnout"]) + float(data.get("value",0)), 0, 100)
		"pet_training":
			var pets := GameState.npcs_with("pet")
			if not pets.is_empty():
				var pid: String = pets[randi() % pets.size()]
				ensure_pet(pid)
				GameState.npc(pid)["pet_profile"]["training"] = clampf(float(GameState.npc(pid)["pet_profile"]["training"]) + float(data.get("value",0)), 0, 100)
		"pet_health":
			var pets := GameState.npcs_with("pet")
			if not pets.is_empty():
				var pid: String = pets[randi() % pets.size()]
				ensure_pet(pid)
				GameState.npc(pid)["pet_profile"]["health"] = clampf(float(GameState.npc(pid)["pet_profile"]["health"]) + float(data.get("value",0)), 0, 100)
		"company_quality":
			var pf: Array = _p()["ambition"]["enterprise"]["portfolio"]
			if not pf.is_empty():
				var co: Dictionary = pf[randi() % pf.size()]
				co["quality"] = clampf(float(co.get("quality",50)) + float(data.get("value",0)), 0, 100)
		"company_debt":
			var pf: Array = _p()["ambition"]["enterprise"]["portfolio"]
			if not pf.is_empty():
				var co: Dictionary = pf[randi() % pf.size()]
				co["debt"] = maxi(0, int(co.get("debt",0)) + int(data.get("value",0)))
		"justice_probation":
			var js: Dictionary = _p()["ambition"]["justice"]
			js["probation"] = maxi(0, int(js["probation"]) + int(data.get("value",0)))
		"court_case":
			record_case(str(data.get("crime", "case")), str(data.get("result", "recorded")), int(data.get("years", 0)), float(data.get("evidence", 0.0)), int(data.get("lawyer", 0)))

