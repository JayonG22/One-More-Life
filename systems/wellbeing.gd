extends RefCounted
## A saved care course augments the existing conditions, not a parallel illness list.
var h
var scenes: Array=[]
func _init(hub):
	h=hub; scenes=ContentDB._load_json("res://data/health_course.json",[])
func st(patient: Dictionary = {}) -> Dictionary:
	var p := GameState.player if patient.is_empty() else patient
	if p==GameState.player: Expansion.ensure()
	if not p.has("medical"): p["medical"]={}
	var med: Dictionary=p["medical"]
	if not med.has("course"): med["course"]={"seed":randi(),"visits":{},"record":[],"plans":{},"access":{},"caregiving":{},"last_medical":-1,"last_year":-1}
	if not med["course"].has("followups"): med["course"]["followups"]=[]
	return med["course"]
func period() -> String:
	return "%d:%d" % [GameState.year_now(),int(LifeCourse.state()["months"])%12 if LifeCourse.monthly_mode() else 0]
func used(key: String) -> bool: return st()["visits"].has(period()+":"+key)
func record(kind: String, text: String, cost: int = 0, patient: Dictionary = {}) -> void:
	var s := st(patient)
	s["record"].push_front({"year":GameState.year_now(),"age":int(GameState.player["age"] if patient.is_empty() else patient.get("age",0)),"kind":kind,"text":text,"cost":cost})
	if s["record"].size()>120: s["record"].resize(120)
func charge(price: int, reason: String) -> void:
	if price<=0: return
	if Childhood.supported(): Childhood.cover(price,reason)
	else:
		GameState.player["money"]=int(GameState.player["money"])-price
		Employment.record_expense(reason,price)
func pay_visit(key: String, price: int, time: int = 1, automatic: bool = false) -> bool:
	if (not automatic and h.blocked(0,false,true)!="") or not GameState.is_alive() or Lives.separate() or used(key): return false
	if int(GameState.player["time_left"])<time:
		if not automatic: EventEngine.push_info("⏳","Care time","This needs %d time. Your cash was not charged." % time)
		return false
	if not Childhood.supported() and price>0 and price>int(GameState.player["money"]):
		if not automatic: EventEngine.push_info("🩺","Care cost","This appointment needs "+GameState.fmt_money(price)+". Your cash was not charged.")
		return false
	Actions._clear_dur()
	GameState.spend_time(time); charge(price,"Healthcare")
	st()["visits"][period()+":"+key]=true
	record("Appointment",key+" · "+("household funded" if Childhood.supported() else "personal payment"),price)
	return true
func roll(key: String) -> float:
	var rng := RandomNumberGenerator.new(); rng.seed=absi((str(int(st()["seed"]))+":"+period()+":"+key).hash())
	return rng.randf()
func plan(id: String, patient: Dictionary = {}) -> Dictionary:
	var s := st(patient)
	if not s["plans"].has(id): s["plans"][id]={"control":25.0,"reviewed":-99,"managed":-99,"pace":"balanced","history":[]}
	return s["plans"][id]
func reviewed(id: String, source: String) -> void:
	var p := plan(id)
	if int(p["reviewed"])==GameState.year_now(): return
	p["reviewed"]=GameState.year_now(); p["control"]=minf(85,float(p["control"])+20)
	record("Review",str(Expansion.CONDITIONS.get(id,{"name":id})["name"])+" · "+source)
func manage(id: String, pace: String) -> void:
	if pace not in ["balanced","supported","push"] or not GameState.player["medical"]["conditions"].has(id): return
	var price := Actions._cost(100 if pace=="supported" else 0)
	if not pay_visit("routine:"+id,price,1): return
	var p := plan(id); p["managed"]=GameState.year_now(); p["pace"]=pace
	p["control"]=clampf(float(p["control"])+(8 if pace=="supported" else 5 if pace=="balanced" else -5),0,100)
	h.done("🌿","Care routine",{"balanced":"A manageable schedule is recorded.","supported":"Practical support shares the workload.","push":"The extra demands increase strain."}[pace],{"stress":3 if pace=="push" else -2})
func before_medical() -> void:
	var s := st(); var year := GameState.year_now()
	if int(s["last_medical"])==year: return
	s["last_medical"]=year
	var med: Dictionary=GameState.player["medical"]
	for id in med["conditions"]:
		if not Expansion.CONDITIONS.get(id,{}).get("chronic",false): continue
		var p := plan(id); var regular := int(p["managed"])>=year-1
		var recent := int(p["reviewed"])>=year-2
		var meds := bool(Care.st()["meds"].get(id,false))
		var gain := (7 if regular and p["pace"]!="push" else -9)+(3 if meds else -3)+(2 if recent else -4)
		p["control"]=clampf(float(p["control"])+gain,0,100)
		med["conditions"][id]["controlled"]=float(p["control"])>=45 and (regular or meds) and recent
		p["history"].push_front({"year":year,"control":p["control"],"routine":regular,"review":recent,"prescription":meds})
		if p["history"].size()>24: p["history"].resize(24)
		record("Annual care",str(Expansion.CONDITIONS[id]["name"])+" · control %d/100 · %s" % [p["control"],"supported" if med["conditions"][id]["controlled"] else "needs review"])
func request_access(where: String) -> void:
	if where not in ["home","school","work"]: return
	if where=="school" and not GameState.in_school(): return
	if where=="work" and not GameState.has_job(): return
	if where=="home" and GameState.player.get("housing","") in ["homeless","street"]: return
	if active_access(where) or not pay_visit("access:"+where,Actions._cost(500 if where=="home" else 0),1): return
	st()["access"][where]={"year":GameState.year_now(),"context":access_context(where)}
	record("Access",where+" · agreed practical adjustments")
	h.done("♿","Access arranged",{"home":"Practical home adjustments reduce daily fatigue.","school":"A flexible learning setup supports participation.","work":"Agreed work adjustments help manage fatigue."}[where]+" My diagnosis and talents remain my own.")
func access_context(where: String) -> String:
	var p := GameState.player
	if where=="work": return str(p["job"].get("id",""))+":"+str(p["job"].get("employer_name",p["job"].get("boss","")))
	if where=="school": return str(p["education"].get("stage",""))+":"+str(p["education"].get("major",""))+":"+str(p.get("country",""))+":"+str(p.get("region",""))
	return str(p.get("house_uid",""))+":"+str(p.get("housing",""))+":"+str(p.get("region",""))
func active_access(where: String) -> bool:
	return st()["access"].has(where) and str(st()["access"][where]["context"])==access_context(where)
func readiness(context: String) -> float:
	if GameState.player.is_empty(): return 0
	var access: Dictionary=st()["access"]; var where := "school" if context=="education" else "work" if context in ["work","technical","creative"] else ""
	if where=="" or not access.has(where): return 0
	if not active_access(where): return 0
	return minf(8,maxf(0,(80-GameState.stat("health"))/8.0)+maxf(0,float(GameState.player.get("household",{}).get("fatigue",0))-25)/15.0)
func available_scenes() -> Array:
	return scenes.filter(func(scene): return int(GameState.player["age"])>=int(scene.get("min_age",6)) and (not scene.get("work_only",false) or GameState.has_job()) and (not scene.get("school_only",false) or GameState.in_school()) and (not scene.get("followup",false) or open_reviews()<24) and GameState.player["medical"]["conditions"].has(scene["condition"]) and Novelty.eligible(scene))
func story() -> void:
	if GameState.in_school(): h.modules["campus"].ensure_roster()
	var available := available_scenes()
	if available.is_empty() or not pay_visit("care_story",0,1): return
	var scene: Dictionary=Novelty.pick(available)
	if scene.is_empty(): return
	Novelty.note(scene); var choices: Array=[]
	for option in scene["choices"]:
		var entry := {"label":str(option["label"]).replace("$100",GameState.fmt_money(Actions._cost(100)))}
		if option["cost"]>0 and not Childhood.supported(): entry["requires"]={"money":Actions._cost(int(option["cost"]))}
		choices.append(entry)
	var actor := story_person(scene)
	var context := {"scene":scene,"actor":FamilyChronicle.identity(GameState.npc(actor)) if actor!="" else "","actor_name":GameState.full_name(actor) if actor!="" else "","roll":roll("story_review:"+str(scene["id"])),"work":Employment.job_session() if GameState.has_job() else -1,"school":review_school_context() if GameState.in_school() else ""}
	var text: String=str(scene["text"])+("\nWith "+GameState.full_name(actor)+"." if actor!="" else "")
	if scene.get("followup",false): text+="\nFollow-up next year · routines and control affect the outcome."
	h.decision("wellbeing","story",context,scene["title"],text,choices)
func resolve(op: String, args: Dictionary, answer: int) -> void:
	if op!="story" or not args.has("scene"): return
	var scene: Dictionary=args["scene"]
	if answer<0 or answer>=scene["choices"].size() or not GameState.player["medical"]["conditions"].has(scene["condition"]): return
	var choice: Dictionary=scene["choices"][answer]; var fee := Actions._cost(int(choice["cost"]))
	if not Childhood.supported() and fee>int(GameState.player["money"]): return
	charge(fee,"Practical health support"); var p := plan(scene["condition"])
	p["control"]=clampf(float(p["control"])+float(choice["control"]),0,100)
	p["managed"]=GameState.year_now(); p["pace"]="push" if float(choice["control"])<0 else "supported" if fee>0 else "balanced"
	record("Care decision",str(scene["title"])+" · "+str(choice["result"]),fee)
	var actor: String=h.person(str(args.get("actor","")))
	if story_person_valid(actor,scene):
		BondStats.apply(actor,{"trust":choice.get("trust",0)})
		var n := GameState.npc(actor)
		n["stress"]=clampf(float(n.get("stress",0))+float(choice.get("npc_stress",0)),0,100)
		FamilyChronicle.remember(actor,str(scene["title"])+" · "+str(choice["result"]),"good" if int(choice.get("trust",0))>0 else "neutral")
	if scene.get("followup",false):
		st()["followups"].push_front({"scene":scene.duplicate(true),"choice":answer,"actor":args.get("actor",""),"actor_name":args.get("actor_name",""),"roll":args.get("roll",1.0),"work":args.get("work",-1),"school":args.get("school",""),"due":GameState.year_now()+1,"state":"open"})
		trim_reviews()
	h.done("🌿",scene["title"],str(choice["result"])+" Control %d/100." % p["control"]+(" Follow-up next year." if scene.get("followup",false) else ""),{"stress":choice["stress"]})
func eligible_patient(n: Dictionary) -> bool:
	return n.get("alive",false) and n.get("species","human")=="human" and (int(n.get("age",0))>=65 or float(n.get("health",100))<60 or not n.get("medical",n.get("playable_player",{}).get("medical",{})).get("conditions",{}).is_empty() or str(n.get("illness",""))!="")
func eligible_helper(candidate: Dictionary) -> bool:
	return candidate.get("relation","") in ["sibling","partner","stepsibling"] and candidate.get("alive",false) and int(candidate.get("age",0))>=18 and int(candidate.get("closeness",0))>=50 and float(candidate.get("health",100))>=55 and int(candidate.get("prison",0))==0
func helper_for(id: String) -> String:
	for other in GameState.npcs:
		var candidate := GameState.npc(other)
		if other!=id and eligible_helper(candidate): return str(other)
	return ""
func caregiver(id: String, kind: String) -> void:
	var n := GameState.npc(id)
	if kind not in ["self","shared","professional"] or n.get("relation","") not in ["mother","father","stepparent","stepmother","stepfather","sibling","stepsibling","partner","child","stepchild"] or not eligible_patient(n) or int(GameState.player["age"])<18: return
	var helper := ""
	if kind=="shared":
		helper=helper_for(id)
		if helper=="": return
	var fee := Actions._cost({"self":80,"shared":60,"professional":800}[kind]); var uid := FamilyChronicle.identity(n)
	if not pay_visit("caregiving:"+uid,fee,2 if kind=="self" else 1): return
	st()["caregiving"][uid]={"uid":uid,"helper":FamilyChronicle.identity(GameState.npc(helper)) if helper!="" else "","kind":kind,"year":GameState.year_now(),"last":-1,"state":"arranged"}
	FamilyChronicle.remember(id,"Care arranged: "+kind+" · actual time and cost shared.","good")
	if helper!="": FamilyChronicle.remember(helper,"Shared care responsibilities for "+str(n["first"])+".","good")
	record("Family care",str(n["first"])+" · "+kind,fee)
	h.done("🫂","Care arranged","The year's care has real time and costs. Renew it next year; practical support helps without erasing a condition.")
func respite(uid: String, kind: String) -> void:
	var p: Dictionary=st()["caregiving"].get(uid,{})
	if p.is_empty() or kind not in ["shared","professional"] or int(p["year"])!=GameState.year_now(): return
	var id: String=h.person(uid)
	if id=="" or not eligible_patient(GameState.npc(id)): return
	var helper := helper_for(id) if kind=="shared" else ""
	if kind=="shared" and helper=="": return
	var fee := Actions._cost(60 if kind=="shared" else 250)
	if not pay_visit("respite:"+uid,fee,1): return
	p["respite_year"]=GameState.year_now(); p["respite_kind"]=kind
	p["respite_helper"]=FamilyChronicle.identity(GameState.npc(helper)) if helper!="" else ""
	record("Caregiver respite",str(GameState.npc(id)["first"])+" · "+kind+" cover",fee)
	h.done("🫖","A break with cover","Care continues with agreed cover. Stress eased by 3; this year's follow-up checks availability.",{"stress":-3})
func yearly() -> void:
	if Lives.separate(): return
	var s := st(); var year := GameState.year_now()
	if int(s["last_year"])==year: return
	s["last_year"]=year
	review_stories(GameState.player,year,true)
	for key in s["visits"].keys():
		if int(str(key).get_slice(":",0))<year-3: s["visits"].erase(key)
	for n in GameState.npcs.values(): background(n,year)
	if active_access("home"):
		var house: Dictionary=GameState.player.get("household",{})
		if house.has("fatigue"): house["fatigue"]=maxf(0,float(house["fatigue"])-2)
	for p in s["caregiving"].values():
		var id: String=h.person(p["uid"])
		if id=="" or not GameState.npc(id).get("alive",false):
			if p["state"]!="ended": p["state"]="ended"; record("Care ended","The care recipient is no longer available.")
			continue
		if int(p["year"])==year-1 and int(p["last"])!=year:
			p["last"]=year
			if p["kind"]=="shared":
				var helper_id: String=h.person(str(p["helper"]))
				if helper_id=="" or helper_id==id or not eligible_helper(GameState.npc(helper_id)):
					p["state"]="needs replanning"; record("Care interrupted","The agreed helper is unavailable; arrange a new schedule."); continue
			p["state"]="supported"; var n := GameState.npc(id)
			for condition in n.get("medical",{}).get("conditions",{}):
				var care_plan := plan(str(condition),n); care_plan["managed"]=year; care_plan["pace"]="supported"
				care_plan["control"]=minf(100,float(care_plan["control"])+5)
			n["health"]=minf(100,float(n.get("health",50))+2)
			if not n.get("playable_player",{}).is_empty(): n["playable_player"]["stats"]["health"]=n["health"]
			BondStats.apply(id,{"trust":2,"affection":2}); GameState.change_stat("stress",care_strain(p,year))
			record("Care follow-up",str(n["first"])+" · practical needs supported; condition remains on their record")
		elif int(p["year"])<year-1 and p["state"]!="lapsed": p["state"]="lapsed"; record("Care lapsed",str(GameState.npc(id)["first"])+" · the schedule needs renewing")
	if GameState.settings.get("health_stories","quiet")!="quiet" and not EventEngine.has_pending() and h.blocked()=="" and roll("care_story")<(0.35 if GameState.settings["health_stories"]=="standard" else 0.65): story()
func care_strain(p: Dictionary, year: int) -> int:
	if int(p.get("respite_year",-99))==year-1:
		var helper: String=h.person(str(p.get("respite_helper","")))
		if p.get("respite_kind","")=="professional" or (helper!="" and eligible_helper(GameState.npc(helper))): return 0
	return 3 if p["kind"]=="self" else 1
func menu(page: String) -> Dictionary:
	var s := st(); var med: Dictionary=GameState.player["medical"]; var rows: Array=[]; var info: Array=[]
	if page=="followups":
		info=["Choices carry into next year. Recovery ends a condition-specific review; it never recreates an illness."]
		for entry in s["followups"].slice(0,24): info.append(str(entry["scene"]["title"])+" · "+("due "+str(entry["due"]) if entry["state"]=="open" else str(entry.get("result","Closed"))))
		if s["followups"].is_empty(): info.append("Later outcomes appear after new care decisions.")
	elif page=="record":
		for entry in s["record"]: info.append("%d · %s · %s%s" % [entry["year"],entry["kind"],entry["text"]," · "+GameState.fmt_money(entry["cost"]) if int(entry["cost"])>0 else ""])
		if info.is_empty(): info.append("Appointments, diagnoses, changes and follow-ups appear here.")
	elif page=="plans":
		info=["Control needs recent review, a workable routine and ongoing support. Chronic conditions can still flare."]
		for id in med["conditions"]:
			var p := plan(id)
			rows.append(h.nav("wellbeing",str(Expansion.CONDITIONS.get(id,{"name":id})["name"]).capitalize(),"Control %d/100 · routine and support" % p["control"],"plan:"+str(id)))
		rows.append({"icon":"🩺","name":"Treatment & review","sub":"Existing diagnoses and rehabilitation","menu":"exp:medical"})
	elif page.begins_with("plan:"):
		var id := page.substr(5)
		if med["conditions"].has(id):
			var p := plan(id)
			info=[str(Expansion.CONDITIONS.get(id,{"name":id})["name"]).capitalize(),"Control %d/100 · last review %s" % [p["control"],str(p["reviewed"]) if int(p["reviewed"])>-99 else "none"],"Choose one routine this period. Ongoing care supports control; it does not guarantee recovery."]
			for pace in ["balanced","supported","push"]: rows.append(h.row("wellbeing",{"balanced":"Pace my routine","supported":"Arrange practical help","push":"Take on extra demands"}[pace],"1 time · "+GameState.fmt_money(Actions._cost(100 if pace=="supported" else 0)),"manage",{"id":id,"pace":pace},not used("routine:"+id)))
			rows.append({"icon":"🩺","name":"Treatment & review","sub":"A clinical review costs time and money","menu":"exp:medical"})
			info.append("Review due: "+str(int(p["reviewed"])+3) if int(p["reviewed"])>-99 else "No clinical review recorded")
			return {"title":"Care routine","icon":"🌿","info":info,"rows":rows,"bars":[{"name":"Condition control","value":p["control"]}]}
	elif page=="access":
		info=["Practical access helps participation; it does not change talents or moral worth.","School/work adjustments fit the current course/job; a new setting needs a new agreement."]
		for where in ["home","school","work"]: rows.append(h.row("wellbeing",where.capitalize()+" adjustments"+(" ✓" if active_access(where) else ""),"1 time · "+GameState.fmt_money(Actions._cost(500 if where=="home" else 0)),"access",where,not active_access(where) and (GameState.in_school() if where=="school" else GameState.has_job() if where=="work" else true)))
	elif page=="family":
		info=["Open a person to arrange care, see their helper or renew a schedule."]
		for id in GameState.npcs:
			var n := GameState.npc(id)
			if not family_patient(n): continue
			var uid := FamilyChronicle.identity(n)
			var care: Dictionary=s["caregiving"].get(uid,{})
			rows.append(h.nav("wellbeing",GameState.full_name(id),"Health %d · %s" % [int(n.get("health",50)),str(care.get("state","No care arranged"))],"family:"+uid))
		if rows.is_empty(): info.append("No current family member needs this support.")
	elif page.begins_with("family:"):
		var uid := page.substr(7)
		var id: String=h.person(uid)
		if id=="" or not family_patient(GameState.npc(id)):
			info=["This person no longer needs an active care arrangement. Their history remains."]
		else:
			var n := GameState.npc(id)
			var care: Dictionary=s["caregiving"].get(uid,{})
			info=[GameState.full_name(id)+" · "+Bonds.quick_line(id),"Pay now · practical support next year · renew yearly"]
			rows.append({"icon":Bonds.U_face(n),"name":"Profile","sub":"Their life and health record","menu":"bond:"+id})
			if not care.is_empty():
				info.append(str(care["kind"])+" care · "+str(care["state"])+" · arranged "+str(care["year"]))
				var helper: String=h.person(str(care.get("helper","")))
				if helper!="": rows.append({"icon":Bonds.U_face(GameState.npc(helper)),"name":GameState.full_name(helper),"sub":"Agreed helper · "+Bonds.quick_line(helper),"menu":"bond:"+helper})
			for kind in ["self","shared","professional"]:
				rows.append(h.row("wellbeing",{"self":"Care personally","shared":"Share family care","professional":"Arrange paid care"}[kind],"%d time · %s" % [2 if kind=="self" else 1,GameState.fmt_money(Actions._cost({"self":80,"shared":60,"professional":800}[kind]))],"care",{"id":id,"kind":kind},int(GameState.player["age"])>=18 and (kind!="shared" or helper_for(id)!="") and not used("caregiving:"+uid)))
			if not care.is_empty() and int(care["year"])==GameState.year_now():
				for kind in ["shared","professional"]: rows.append(h.row("wellbeing","Family respite" if kind=="shared" else "Paid respite","1 time · "+GameState.fmt_money(Actions._cost(60 if kind=="shared" else 250)),"respite",[uid,kind],not used("respite:"+uid) and (kind!="shared" or helper_for(id)!="")))
			return {"title":"Family care","icon":"🫂","info":info,"rows":rows,"bars":[{"name":"Health","value":n.get("health",50)}]}

	else:
		info=["One medical record, remembered care and practical support."]
		rows.append(h.nav("coping","Mood, grief & stress","Grief, connection and manageable routines"))
		rows.append(h.nav("resilience","Recovery & support","Dependence, aftercare and lasting progress"))
		rows.append(h.nav("wellbeing","Care follow-ups","Pending reviews and later outcomes","followups"))
		for section in ["record","plans","access","family"]: rows.append(h.nav("wellbeing",{"record":"Care history","plans":"Ongoing care","access":"Access & adjustments","family":"Family caregiving"}[section],{"record":"Appointments, reviews and costs","plans":"Routines and condition control","access":"Home, school and work participation","family":"Share time, costs and responsibility"}[section],section))
		rows.append({"icon":"🩺","name":"Appointments & prescriptions","sub":"GP, referrals and existing treatments","menu":"real:care"})
		rows.append({"icon":"🧠","name":"Mental health & support","sub":"Therapy, groups and existing recovery","menu":"exp:mental"})
		rows.append(h.row("wellbeing","A care decision","1 time · each scene appears once","story",null,not used("care_story") and not available_scenes().is_empty()))
		for mode in ["quiet","standard","often"]: rows.append(h.row("wellbeing","Care stories: "+mode+(" ✓" if GameState.settings.get("health_stories","quiet")==mode else ""),"Random care scenes; requested appointments still report results","stories",mode,GameState.settings.get("health_stories","quiet")!=mode))
	return {"title":{"record":"Care history","plans":"Ongoing care","access":"Access & adjustments","family":"Family caregiving","followups":"Care follow-ups"}.get(page,"Appointments & family care"),"icon":"🌿","rows":rows,"info":info}
func act(key: String, arg: Variant) -> void:
	match key:
		"manage": if arg is Dictionary: manage(str(arg["id"]),str(arg["pace"]))
		"access": request_access(str(arg))
		"care": if arg is Dictionary: caregiver(str(arg["id"]),str(arg["kind"]))
		"story": story()
		"respite": if arg is Array: respite(str(arg[0]),str(arg[1]))
		"stories": if str(arg) in ["quiet","standard","often"]: GameState.settings["health_stories"]=str(arg)

func adopt_legacy() -> void:
	var p := GameState.player; var med: Dictionary=p["medical"]
	var label := str(p.get("illness","")).to_lower()
	if label=="migraines": label="migraine"
	if label=="": return
	for id in Expansion.CONDITIONS:
		if label in [str(id),str(Expansion.CONDITIONS[id]["name"]).to_lower()] and not med["conditions"].has(id):
			med["conditions"][id]={"years":0,"treated":0,"controlled":false,"flares":0}
			record("Previous diagnosis",str(Expansion.CONDITIONS[id]["name"])); return
func event_recovery() -> void:
	adopt_legacy(); var med: Dictionary=GameState.player["medical"]
	for id in med["conditions"].keys():
		if Expansion.CONDITIONS.get(id,{}).get("chronic",false): reviewed(str(id),"Event care review")
		else: med["conditions"].erase(id); Care.st()["meds"].erase(id); record("Recovery",str(id)+" · event treatment completed")
	GameState.player["illness"]=""; Expansion._sync_primary_illness()
func background(n: Dictionary, year: int) -> void:
	if not n.get("alive",false) or n.get("species","human")!="human": return
	var former: Dictionary=n.get("playable_player",{})
	var med: Dictionary=n.get("medical",former.get("medical",{}))
	if med.get("conditions",{}).is_empty() and med.get("injuries",{}).is_empty() and med.get("mental",{}).is_empty() and med.get("course",{}).get("followups",[]).is_empty(): return
	for key in ["conditions","injuries","mental","medication"]:
		if not med.has(key): med[key]={}
	n["medical"]=med; var s := st(n)
	if int(s.get("background_year",-1))==year: return
	s["background_year"]=year
	review_stories(n,year,false)
	s["last_medical"]=year; med["last_course_year"]=year
	var care: Dictionary=n.get("care",former.get("care",{})); n["care"]=care
	care["last_year"]=year
	var system := str(Places.LAWS.get(n.get("country",GameState.player["country"]),Places.LAWS["us"])["healthcare"])
	var total := 0
	for id in med["conditions"]:
		var d: Dictionary=Expansion.CONDITIONS.get(id,{})
		if d.get("chronic",false) and care.get("meds",{}).get(id,false): total+=Actions._cost(60 if system=="free" else 240*int(d["severity"]))
	var supported := int(n.get("age",0))<int(former.get("childhood_budget",{}).get("independence_age",18))
	var funded := supported or int(n.get("money",0))>=total
	if supported and total>0:
		var left := total
		for uid0 in n.get("parent_uids",[]):
			var parent: Dictionary=GameState.player if str(uid0)==h.uid() else GameState.npc(h.person(str(uid0)))
			if parent.is_empty() or not parent.get("alive",false) or int(parent.get("age",0))<18: continue
			var paid := mini(left,maxi(0,int(parent.get("money",0))))
			parent["money"]=int(parent.get("money",0))-paid; left-=paid
			if parent==GameState.player: Employment.record_expense("Child prescriptions",paid)
			elif not parent.get("playable_player",{}).is_empty(): parent["playable_player"]["money"]=parent["money"]
			if left==0: break
		s["household_covered"]=int(s.get("household_covered",0))+total; s["assistance"]=int(s.get("assistance",0))+left
	elif funded: n["money"]=int(n.get("money",0))-total
	if total>0: record("Background prescription","Household care funded" if supported else "Ongoing care funded" if funded else "Prescription costs could not be met",total if funded else 0,n)
	var worst := ""; var severity := -1
	var had_physical: bool=not med["conditions"].is_empty()
	for id in med["conditions"].keys():
		var d: Dictionary=Expansion.CONDITIONS.get(id,{}); var c: Dictionary=med["conditions"][id]
		c["years"]=int(c.get("years",0))+1
		if not d.get("chronic",false):
			var rng := RandomNumberGenerator.new(); rng.seed=absi((str(int(s["seed"]))+":"+str(year)+":"+str(id)).hash())
			if int(c["years"])>=2 and rng.randf()<0.35+float(plan(str(id),n)["control"])/500.0:
				med["conditions"].erase(id); record("Recovery",str(d.get("name",id))+" · recovery continued while another life was viewed",0,n)
			else:
				n["health"]=maxf(0,float(n.get("health",50))+float(d.get("health",-2)))
				if int(d.get("severity",1))>severity: worst=str(d.get("name",id)); severity=int(d.get("severity",1))
			continue
		var p := plan(str(id),n); var meds: bool=funded and bool(care.get("meds",{}).get(id,false))
		var regular: bool=int(p["managed"])>=year-1 and p["pace"]!="push"
		var recent := int(p["reviewed"])>=year-2
		p["control"]=clampf(float(p["control"])+(7 if regular else -9)+(3 if meds else -3)+(2 if recent else -4),0,100)
		c["controlled"]=float(p["control"])>=45 and (regular or meds) and recent
		p["history"].push_front({"year":year,"control":p["control"],"routine":regular,"review":recent,"prescription":meds,"source":"background"})
		if p["history"].size()>24: p["history"].resize(24)
		n["health"]=clampf(float(n.get("health",50))+float(d.get("health",-2))*(0.45 if c["controlled"] else 1.0)+(absf(float(d.get("health",-2)))*0.55 if meds else 0.0),0,100)
		record("Background care",str(d.get("name",id))+" · control %d/100" % p["control"],0,n)
		if int(d.get("severity",1))>severity: worst=str(d.get("name",id)); severity=int(d.get("severity",1))
	if had_physical: n["illness"]=worst
	for id in med.get("injuries",{}).keys():
		var injury: Dictionary=med["injuries"][id]; injury["left"]=int(injury.get("left",1))-1
		n["health"]=maxf(0,float(n.get("health",50))-1)
		if int(injury["left"])<=0: med["injuries"].erase(id); record("Rehab complete",str(id)+" · recovery continued off-screen",0,n)
	var stress: float=float(n.get("stress",former.get("stats",{}).get("stress",30)))
	for id in med.get("mental",{}).keys():
		var d: Dictionary=Expansion.MENTAL.get(id,{})
		var relief := 0.35 if med.get("medication",{}).get(id,false) else 0.0
		stress=clampf(stress+float(d.get("stress",3))*(1.0-relief),0,100)
		n["happiness"]=clampf(float(n.get("happiness",50))+float(d.get("happy",-2))*(1.0-relief),0,100)
		med["mental"][id]["progress"]=clampi(int(med["mental"][id].get("progress",0))+(4 if stress<45 else -2),0,100)
		if int(med["mental"][id]["progress"])>=100:
			med["mental"].erase(id); med.get("medication",{}).erase(id); record("Recovery milestone",str(d.get("name",id))+" · continued off-screen",0,n)
	n["stress"]=stress
	var age := int(n.get("age",0))
	if care.has("vision"): care["vision"]=maxf(0,float(care["vision"])-(0.25 if age<40 else 1.0 if age<60 else 1.8)*(0.5 if care.get("aid","")=="laser" else 1.0))
	if care.has("hearing"): care["hearing"]=maxf(0,float(care["hearing"])-(0 if age<45 else 0.9 if age<65 else 1.8))
	if care.has("teeth"): care["teeth"]=maxf(0,float(care["teeth"])-1.8)
	if not former.is_empty():
		former["medical"]=med; former["care"]=care; former["money"]=n["money"]; former["stats"]["health"]=n["health"]; former["illness"]=n["illness"]
		former["stats"]["happiness"]=n["happiness"]; former["stats"]["stress"]=stress
	if n.has("last_budget") and int(n["last_budget"].get("year",-1))==year: n["last_budget"]["healthcare"]=total if funded else 0
func recorded_illness() -> bool:
	adopt_legacy()
	return not GameState.player["medical"]["conditions"].is_empty()

func family_patient(n: Dictionary) -> bool:
	return n.get("relation","") in ["mother","father","stepparent","stepmother","stepfather","sibling","stepsibling","partner","child","stepchild"] and eligible_patient(n)
func open_reviews() -> int:
	return st()["followups"].filter(func(entry): return entry.get("state","")=="open").size()
func trim_reviews(patient: Dictionary = {}) -> void:
	var entries: Array=st(patient)["followups"]
	while entries.size()>40:
		var removable := -1
		for i in range(entries.size()-1,-1,-1):
			if entries[i].get("state","")!="open": removable=i; break
		if removable<0: break
		entries.remove_at(removable)
func story_person(scene: Dictionary) -> String:
	var candidates: Array=[]
	for id in GameState.npcs:
		if story_person_valid(str(id),scene): candidates.append(str(id))
	return "" if candidates.is_empty() else str(candidates.pick_random())
func story_person_valid(id: String, scene: Dictionary) -> bool:
	if id=="": return false
	var n := GameState.npc(id)
	if not n.get("alive",false): return false
	if scene.get("work_only",false): return id in Workplace.crew()
	if scene.get("school_only",false): return GameState.in_school() and n.get("relation","") in ["classmate","teacher"] and str(n.get("campus",""))==str(h.modules["campus"].st()["level"])
	return n.get("relation","") in ["partner","friend","sibling","stepsibling","mother","father","child","stepchild"]
func review_stories(patient: Dictionary, year: int, active: bool) -> void:
	var med: Dictionary=patient.get("medical",{})
	for entry in st(patient)["followups"]:
		if entry.get("state","")!="open" or year<int(entry["due"]): continue
		entry["state"]="closed"
		var scene: Dictionary=entry["scene"]
		var id: String=str(scene["condition"])
		var result := "Recovery closed this care review; no further condition effect."
		if med.get("conditions",{}).has(id):
			var p := plan(id,patient)
			var stats: Dictionary=patient.get("stats",{})
			var stress: float=GameState.stat("stress") if active else float(patient.get("stress",stats.get("stress",30)))
			var regular: bool=int(p["managed"])>=year-1 and p["pace"]!="push"
			var chance: float=clampf(0.35+float(p["control"])/250.0-stress/500.0+(0.15 if regular else 0.0),0.15,0.90)
			var success: bool=float(entry["roll"])<chance
			var choice: Dictionary=scene["choices"][int(entry["choice"])]
			result=str(choice["later_good"] if success else choice["later_bad"])
			entry["chance"]=chance
			p["control"]=clampf(float(p["control"])+(4 if success else -2),0,100)
			if active:
				GameState.apply_effects({"stress":-2 if success else 1,"health":1 if success else 0})
				if success and scene.get("work_only",false) and GameState.has_job() and int(entry["work"])==Employment.job_session(): GameState.apply_effects({"job_perf":2})
				if success and scene.get("school_only",false) and GameState.in_school() and str(entry["school"])==review_school_context(): GameState.apply_effects({"school":2})
			else:
				patient["stress"]=clampf(stress+(-2 if success else 1),0,100)
				patient["health"]=clampf(float(patient.get("health",50))+(1 if success else 0),0,100)
			var actor: String=h.person(str(entry.get("actor","")))
			if active and story_person_valid(actor,scene):
				BondStats.apply(actor,{"trust":2 if success else -1})
				FamilyChronicle.remember(actor,str(scene["title"])+": "+result,"good" if success else "neutral")
		entry["result"]=result
		entry["closed"]=year
		record("Care follow-up",str(scene["title"])+" · "+result,0,{} if active else patient)
		if active: GameState.add_log(str(scene["title"])+": "+result)
	trim_reviews(patient)

func review_school_context() -> String:
	return str(h.modules["campus"].level())+":"+access_context("school")+":"+str(GameState.player.get("education",{}).get("uni",{}).get("campus_id",""))
