extends RefCounted
## Recovery augments the established habit record; no second dependence list.
var h
var scenes: Array=[]
func _init(hub):
	h=hub; scenes=ContentDB._load_json("res://data/recovery_pressure.json",[])
func st(patient: Dictionary = {}) -> Dictionary:
	return h.section("resilience",{"plans":{},"history":[],"last_year":-1,"pressure_year":-1,"queued":{},"scene_year":-1,"scene_count":0},patient)
func plan(id: String, patient: Dictionary = {}) -> Dictionary:
	var state := st(patient)
	if not state["plans"].has(id): state["plans"][id]={"route":"self-led","started":GameState.year_now(),"sessions":0,"stable":0,"milestones":0,"relapses":0,"last_support":-99,"last_session":-99,"exposed":-99,"buddy":"","boundary":"pause","status":"working"}
	var habit: Dictionary=(GameState.player if patient.is_empty() else patient).get("habits",{}).get(id,{})
	if int(habit.get("clean",-1))>=0 and int(state["plans"][id]["milestones"])==0:
		state["plans"][id]["milestones"]=1; state["plans"][id]["status"]="maintaining"
	return state["plans"][id]
func record(id: String, text: String) -> void:
	st()["history"].push_front({"year":GameState.year_now(),"habit":id,"text":text})
	if st()["history"].size()>100: st()["history"].resize(100)
	Journey.modules["wellbeing"].record("Recovery",Grit.HABITS[id]["name"]+" · "+text)
func known(id: String) -> bool: return Grit.HABITS.has(id) and GameState.player.get("habits",{}).has(id)
func exposure(id: String, amount: float, activated: bool = false) -> void:
	if not known(id): return
	var p := plan(id)
	if amount>0: p["exposed"]=GameState.year_now(); p["stable"]=0
	if activated:
		if p["status"]=="maintaining": p["relapses"]+=1; record(id,"A setback renewed the need for support; earlier progress remains recorded.")
		p["status"]="working"
func buddy_available(id: String) -> bool:
	var who: String=h.person(str(plan(id)["buddy"]))
	if who=="": return false
	var n := GameState.npc(who)
	return n.get("alive",false) and int(n.get("age",0))>=18 and int(n.get("closeness",0))>=50 and int(n.get("prison",0))==0
func support(id: String, source: String, strength: float = 12) -> void:
	if not known(id) or not GameState.is_alive() or Lives.separate() or int(GameState.player["age"])<14: return
	var p := plan(id); var key := "recovery_support:"+source+":"+id
	if h.used(key): return
	h.mark(key); p["last_support"]=GameState.year_now()
	var habit: Dictionary=GameState.player["habits"][id]
	habit["level"]=maxf(0,float(habit["level"])-strength)
	record(id,source+" support · pressure %.0f/100; sustained recovery still needs time" % habit["level"])
func begin(id: String, route: String) -> void:
	if not known(id) or route not in ["community","outpatient","residential"] or int(GameState.player["age"])<14 or (route=="residential" and int(GameState.player["age"])<18): return
	var p := plan(id)
	if p["route"]==route: return
	var cost := Actions._cost({"community":40,"outpatient":700,"residential":8000}[route])
	if not Journey.modules["wellbeing"].pay_visit("Recovery intake:"+id,cost,4 if route=="residential" else 2): return
	p["route"]=route; p["started"]=GameState.year_now(); p["last_support"]=GameState.year_now()
	support(id,"intake",22 if route=="residential" else 14 if route=="outpatient" else 8)
	h.done("🌱","Recovery plan","Support begins. Two stable years can mark recovery; the record keeps earlier progress.",{"stress":-3})
func session(id: String) -> void:
	if not known(id) or int(GameState.player["age"])<14: return
	var p := plan(id); var cost := Actions._cost(40 if p["route"] in ["community","self-led"] else 140)
	if not Journey.modules["wellbeing"].pay_visit("Recovery session:"+id,cost,1): return
	p["sessions"]+=1; p["last_session"]=GameState.year_now()
	var readiness := clampf((GameState.stat("happiness")+GameState.stat("health")+GameState.hidden("willpower")+(100-GameState.stat("stress")))/4.0,0,100)
	support(id,"session",(8+readiness/12.0+(5 if p["route"] in ["outpatient","residential"] else 0)+(6 if buddy_available(id) and p["route"]=="community" else 3 if buddy_available(id) else 0))*Grit.d("heal"))
	h.done("🌱","Session recorded","Pressure %.0f/100. Health, mood, stress and available support affect the progress; the plan survives setbacks." % float(GameState.player["habits"][id]["level"]),{"stress":-4})
func set_buddy(id: String, uid0: String) -> void:
	if not known(id) or int(GameState.player["age"])<14: return
	var who: String=h.person(uid0)
	if who=="" or GameState.npc(who).get("relation","") not in ["mother","father","stepmother","stepfather","sibling","stepsibling","partner","friend","best_friend"]: return
	var previous := str(plan(id)["buddy"]); plan(id)["buddy"]=uid0
	if not buddy_available(id): plan(id)["buddy"]=previous; return
	if not Journey.modules["wellbeing"].pay_visit("Recovery buddy:"+id,0,1): plan(id)["buddy"]=previous; return
	FamilyChronicle.remember(who,"Agreed to be a recovery support contact for "+Grit.HABITS[id]["name"]+".","good")
	record(id,"Support contact: "+GameState.full_name(who)); h.done("🤝","Support agreed","The named person must remain alive, available and on speaking terms to help.")
func resistance(id: String) -> float:
	if not known(id): return 0
	var p := plan(id)
	return (0.08 if int(p["last_support"])>=GameState.year_now()-1 else 0.0)+(0.06 if buddy_available(id) else 0.0)
func compulsion(icon: String, _title: String, _text: String, effects: Dictionary, id: String) -> void:
	if not known(id) or h.used("recovery_pressure:"+id) or int(st()["queued"].get(id,-1))==GameState.year_now(): return
	var pool: Array=scenes.filter(func(scene): return scene["habit"]==id)
	var chance := clampf((0.12+GameState.stat("happiness")/300.0+GameState.stat("health")/600.0+GameState.hidden("willpower")/400.0-GameState.stat("stress")/250.0+resistance(id))/Grit.d("harsh"),0.05,0.85)
	var packet := {"owner":h.uid(),"year":GameState.year_now(),"id":id,"effects":effects.duplicate(true),"chance":chance,"roll":Journey.modules["wellbeing"].roll("Recovery pressure:"+id),"answer":0}
	var scene := Novelty.pick(pool)
	var scene_limit: int={"quiet":0,"standard":2,"often":3}.get(GameState.settings.get("recovery_stories","standard"),2)
	if int(st()["scene_year"])!=GameState.year_now(): st()["scene_year"]=GameState.year_now(); st()["scene_count"]=0
	var waiting: int=st()["scene_count"]
	if scene.is_empty() or waiting>=scene_limit:
		packet["answer"]={"pause":0,"open":1,"help":2}[plan(id)["boundary"]]
		var text := outcome(packet); GameState.add_log(Grit.HABITS[id]["name"]+": "+text); return
	st()["queued"][id]=GameState.year_now(); st()["scene_count"]+=1; Novelty.note(scene); packet["results"]=scene["results"].duplicate(); var choices: Array=[]
	for answer in range(3):
		var copy := packet.duplicate(true); copy["answer"]=answer
		var label: String=["Pause · %d%% chance" % int(chance*100),"Give in · recorded costs","Use support · 1 time, "+GameState.fmt_money(Actions._cost(40))][answer]
		var choice := {"label":label,"outcomes":[{"text":"","no_friction":true,"recovery_choice":copy}]}
		if answer==2:
			choice["requires"]={"time":1}
			if not Childhood.supported(): choice["requires"]["money"]=Actions._cost(40)
		choices.append(choice)
	EventEngine.push_decision({"id":"_recovery_pressure_"+id,"icon":icon,"title":scene["title"],"text":scene["text"]+" Potential spending: "+GameState.fmt_money(maxi(0,-int(effects.get("money",0))))+".","no_friction":true,"choices":choices})
func outcome(packet: Dictionary) -> String:
	var id := str(packet.get("id","")); var key := "recovery_pressure:"+id
	if not known(id) or not GameState.is_alive() or Lives.separate() or str(packet.get("owner",""))!=h.uid() or int(packet.get("year",-1))!=GameState.year_now() or h.used(key): return ""
	var answer := int(packet.get("answer",-1))
	if answer<0 or answer>2: return ""
	var helped := false; var fallback := false
	if answer==2:
		var cost := Actions._cost(40)
		if int(GameState.player["time_left"])<1 or (not Childhood.supported() and int(GameState.player["money"])<cost):
			answer=0; fallback=true
		else:
			GameState.spend_time(1); Journey.modules["wellbeing"].charge(cost,"Recovery support")
			support(id,"pressure check-in",6); helped=true
	h.mark(key); plan(id)["boundary"]=["pause","open","help"][int(packet["answer"])]
	var resisted: bool=helped or (answer==0 and float(packet["roll"])<float(packet["chance"]))
	if resisted: GameState.apply_effects({"stress":2 if answer==0 else -2}); record(id,"A pressure episode was managed using "+plan(id)["boundary"]+" boundaries")
	else:
		var fx: Dictionary=packet["effects"].duplicate(true)
		if Childhood.supported() and int(fx.get("money",0))<0: fx["money"]=-mini(-int(fx["money"]),maxi(0,int(GameState.player["money"])))
		if not GameState.has_job(): fx.erase("job_perf")
		GameState.apply_effects(fx); exposure(id,1)
		if id=="workaholic":
			for relation in ["partner","child"]:
				for who in GameState.npcs_with(relation): GameState.change_closeness(who,-6)
		record(id,"Pressure led to a setback; recorded costs and consequences applied")
	var prefix := "Support was unavailable; I used the pause instead. " if fallback else ""
	var result_index := 2 if helped else 0 if resisted else 1
	var results: Array=packet.get("results",["The pause held.","The boundary did not hold; recorded consequences applied.","Support helped me keep the boundary."])
	return prefix+str(results[result_index])
func boundary(id: String, kind: String) -> void:
	if not known(id) or kind not in ["pause","help"] or int(GameState.player["age"])<14: return
	if not Journey.modules["wellbeing"].pay_visit("Recovery boundary:"+id,0,1): return
	plan(id)["boundary"]=kind; record(id,"Pressure plan: "+kind)
	h.done("🌱","Boundary saved","Future pressure uses this plan when a new scene is not shown. Support needs available time and money; otherwise I try a pause.")
func aftercare(id: String) -> void:
	if not known(id) or GameState.player["habits"][id]["active"] or plan(id)["route"]=="self-led": return
	if not Journey.modules["wellbeing"].pay_visit("Recovery aftercare:"+id,0,1): return
	plan(id)["route"]="self-led"; record(id,"Moved to self-led aftercare; earlier care remains recorded")
	h.done("🌱","Aftercare","The programme history stays. A check-in costs less; I can request more support again.")
func yearly() -> void:
	if Lives.separate() or GameState.player.is_empty(): return
	var year := GameState.year_now(); var s := st()
	if int(s["last_year"])==year: return
	s["last_year"]=year
	for n in GameState.npcs.values(): background(n,year)
	for id in GameState.player.get("habits",{}):
		if not Grit.HABITS.has(id): continue
		var p := plan(str(id)); var habit: Dictionary=GameState.player["habits"][id]
		var stable: bool=float(habit["level"])<45 and GameState.stat("stress")<70 and int(p["exposed"])<year-1
		p["stable"]=int(p["stable"])+1 if stable else 0
		if habit["active"] and int(p["stable"])>=2:
			habit["active"]=false; habit["clean"]=int(GameState.player["age"]); p["status"]="maintaining"
			if int(p["milestones"])==0: GameState.counter("habits_beaten")
			p["milestones"]+=1; GameState.add_milestone(GameState.player["age"],"reached a sustained "+Grit.HABITS[id]["name"].to_lower()+" recovery milestone")
			record(str(id),"Two stable years · recovery milestone; aftercare and exposure still matter")
		elif not habit["active"] and int(habit.get("clean",-1))>=0:
			p["status"]="maintaining"
			var risk := clampf(0.02+maxf(0,GameState.stat("stress")-55)/400.0+float(habit["level"])/600.0-resistance(str(id)),0,0.32)
			if int(p["exposed"])>=year-1 or (GameState.stat("stress")>=75 and int(p["last_support"])<year-1):
				if Journey.modules["wellbeing"].roll("Recovery setback:"+str(id))<risk:
					habit["active"]=true; habit["level"]=maxf(60,float(habit["level"])); habit["clean"]=-1; p["stable"]=0; p["relapses"]+=1; p["status"]="working"
					record(str(id),"A pressured year brought a setback; skills, sessions and milestones remain")
func background(n: Dictionary, year: int) -> void:
	if not n.get("alive",false) or n.get("species","human")!="human": return
	var former: Dictionary=n.get("playable_player",{})
	var habits: Dictionary=n.get("habits",former.get("habits",{}))
	if habits.is_empty(): return
	if not n.has("journey"): n["journey"]=former.get("journey",{}).duplicate(true)
	n["habits"]=habits; var s := st(n)
	if int(s["last_year"])==year: return
	s["last_year"]=year; s["pressure_year"]=year
	var stress: float=float(n.get("stress",former.get("stats",{}).get("stress",30)))
	for id in habits:
		if not Grit.HABITS.has(id): continue
		var p := plan(str(id),n); var habit: Dictionary=habits[id]
		var rng := RandomNumberGenerator.new(); rng.seed=absi((str(n.get("person_uid",""))+":"+str(year)+":"+str(id)).hash())
		var result := ""
		var stable: bool=float(habit["level"])<45 and stress<70 and int(p["exposed"])<year-1
		p["stable"]=int(p["stable"])+1 if stable else 0
		if habit["active"] and int(p["stable"])>=2:
			habit["active"]=false; habit["clean"]=int(n["age"]); p["status"]="maintaining"; p["milestones"]+=1
			result="Two stable years marked sustained recovery while another life was viewed."
		elif not habit["active"] and int(habit.get("clean",-1))>=0 and (int(p["exposed"])>=year-1 or stress>=75):
			var risk := clampf(0.02+maxf(0,stress-55)/400.0+float(habit["level"])/600.0-(0.08 if int(p["last_support"])>=year-1 else 0.0),0,0.32)
			if rng.randf()<risk:
				habit["active"]=true; habit["level"]=maxf(60,float(habit["level"])); habit["clean"]=-1; p["relapses"]+=1; p["stable"]=0; p["status"]="working"
				result="A pressured year renewed the need for recovery support."
		if habit["active"]:
			var price := Actions._cost(40)
			var supported: bool=int(n.get("age",0))<int(former.get("childhood_budget",{}).get("independence_age",18))
			var helped: bool=p["boundary"]=="help" and (supported or int(n.get("money",0))>=price)
			if helped:
				if supported:
					var left := price
					for uid0 in n.get("parent_uids",[]):
						var parent: Dictionary=GameState.player if str(uid0)==h.uid() else GameState.npc(h.person(str(uid0)))
						if parent.is_empty() or not parent.get("alive",false) or int(parent.get("age",0))<18: continue
						var paid := mini(left,maxi(0,int(parent.get("money",0))))
						parent["money"]=int(parent.get("money",0))-paid; left-=paid
						if parent==GameState.player: Employment.record_expense("Child recovery support",paid)
						elif not parent.get("playable_player",{}).is_empty(): parent["playable_player"]["money"]=parent["money"]
						if left==0: break
					s["household_covered"]=int(s.get("household_covered",0))+price; s["assistance"]=int(s.get("assistance",0))+left
				else: n["money"]=int(n.get("money",0))-price
				habit["level"]=maxf(0,float(habit["level"])-6); p["last_support"]=year
				result+=" A planned support check-in was funded."
			var chance := clampf(0.12+float(n.get("happiness",50))/300.0+float(n.get("health",50))/600.0+float(former.get("hidden",{}).get("willpower",50))/400.0-stress/250.0,0.05,0.85)
			if not helped and (p["boundary"]=="open" or rng.randf()>=chance):
				var cost := Actions._cost({"gambling":500,"shopping":1500,"workaholic":0,"drinking":2200,"drugs":5000,"partying":3000}[id])
				if supported: cost=mini(cost,maxi(0,int(n.get("money",0))))
				n["money"]=int(n.get("money",0))-cost; p["exposed"]=year; p["stable"]=0
				n["health"]=maxf(0,float(n.get("health",50))-float({"gambling":0,"shopping":0,"workaholic":4,"drinking":5,"drugs":8,"partying":6}[id]))
				stress=clampf(stress+(12 if id=="workaholic" else 8 if id=="gambling" else 0),0,100)
				result+=" Pressure brought recorded spending and wear."
			elif not helped: result+=" The saved pause kept the boundary."
		if int(habit.get("touched",-99))<int(n["age"])-1: habit["level"]=maxf(0,float(habit["level"])-(4 if habit["active"] else 8))
		if result!="":
			s["history"].push_front({"year":year,"habit":id,"text":result.strip_edges()}); Journey.modules["wellbeing"].record("Recovery",Grit.HABITS[id]["name"]+" · "+result.strip_edges(),0,n)
	if s["history"].size()>100: s["history"].resize(100)
	n["stress"]=stress
	if not former.is_empty():
		former["habits"]=habits.duplicate(true); former["journey"]=n["journey"].duplicate(true); former["money"]=n["money"]
		former["stats"]["health"]=n.get("health",50); former["stats"]["stress"]=stress
func menu(page: String) -> Dictionary:
	var rows: Array=[]; var info: Array=["Support reduces pressure. Recovery needs two stable years; setbacks keep earlier progress."]
	if page=="settings":
		for mode in ["quiet","standard","often"]: rows.append(h.row("resilience",mode.capitalize()+(" ✓" if GameState.settings.get("recovery_stories","standard")==mode else ""),{"quiet":"Follow the saved plan; no pressure popups","standard":"Up to 2 pressure scenes per year","often":"Up to 3 pressure scenes per year"}[mode],"stories",mode,GameState.settings.get("recovery_stories","standard")!=mode))
	elif page=="history":
		for entry in st()["history"]: info.append("%d · %s · %s" % [entry["year"],Grit.HABITS.get(entry["habit"],{"name":entry["habit"]})["name"],entry["text"]])
	elif known(page):
		var p := plan(page); var habit: Dictionary=GameState.player["habits"][page]
		info.append("%s · pressure %.0f/100 · %s" % [Grit.HABITS[page]["name"],habit["level"],"watching" if not habit["active"] and int(habit.get("clean",-1))<0 else p["status"]]); info.append("%d stable years · %d sessions · %d milestones · %d setbacks" % [p["stable"],p["sessions"],p["milestones"],p["relapses"]])
		info.append("Route: "+str(p["route"])+" · pressure plan: "+str(p["boundary"]))
		if not habit["active"] and p["route"]!="self-led": rows.append(h.row("resilience","Self-led aftercare","1 time · no fee · keep the record","aftercare",page))
		rows.append(h.row("resilience","Recovery session","1 time · "+GameState.fmt_money(Actions._cost(40 if p["route"] in ["community","self-led"] else 140)),"session",page,not Journey.modules["wellbeing"].used("Recovery session:"+page)))
		rows.append({"icon":"🫂","name":"Therapy & support groups","sub":"Existing mental-health and recovery support","menu":"exp:mental"})
		rows.append(h.nav("resilience","Change programme","Intake fee and time apply","routes:"+page))
		rows.append(h.nav("resilience","Pressure plan","Pause or paid support · 1 time","boundary:"+page))
		rows.append(h.nav("resilience","Choose a support contact","A real available person · 1 time","buddy:"+page))
	elif page.begins_with("routes:") and known(page.substr(7)):
		var id := page.substr(7)
		for route in ["community","outpatient","residential"]:
			rows.append(h.row("resilience",route.capitalize()+" programme","%d time · %s" % [4 if route=="residential" else 2,GameState.fmt_money(Actions._cost({"community":40,"outpatient":700,"residential":8000}[route]))],"begin",{"id":id,"route":route},plan(id)["route"]!=route and not Journey.modules["wellbeing"].used("Recovery intake:"+id) and int(GameState.player["age"])>=(18 if route=="residential" else 14)))
	elif page.begins_with("boundary:") and known(page.substr(9)):
		var id := page.substr(9)
		for kind in ["pause","help"]: rows.append(h.row("resilience","Pause first" if kind=="pause" else "Ask for support","1 time to plan · "+("no automatic fee" if kind=="pause" else "each check-in: 1 time, "+GameState.fmt_money(Actions._cost(40))),"boundary",{"id":id,"kind":kind},not Journey.modules["wellbeing"].used("Recovery boundary:"+id)))
	elif page.begins_with("buddy:") and known(page.substr(6)):
		var id := page.substr(6)
		for who in GameState.npcs:
			var n := GameState.npc(who)
			if n.get("alive",false) and int(n.get("age",0))>=18 and int(n.get("closeness",0))>=50 and n.get("relation","") in ["mother","father","stepmother","stepfather","sibling","stepsibling","partner","friend","best_friend"]: rows.append(h.row("resilience",GameState.full_name(str(who)),"Agree a support role · 1 time","buddy",{"id":id,"uid":FamilyChronicle.identity(n)},not Journey.modules["wellbeing"].used("Recovery buddy:"+id)))
	else:
		for id in GameState.player.get("habits",{}):
			if Grit.HABITS.has(id): rows.append(h.nav("resilience",Grit.HABITS[id]["name"],"Pressure %.0f/100 · %s" % [GameState.player["habits"][id]["level"],"active" if GameState.player["habits"][id]["active"] else "maintaining" if int(GameState.player["habits"][id].get("clean",-1))>=0 else "watching"],str(id)))
		rows.append({"icon":"🫂","name":"Therapy & support groups","sub":"Support is also available without an active habit","menu":"exp:mental"})
		rows.append(h.nav("resilience","Pressure scenes","Quiet, standard or often","settings"))
		rows.append(h.nav("resilience","Recovery history","Sessions, stable years and remembered setbacks","history"))
		if GameState.player.get("habits",{}).is_empty(): info.append("No dependence is on this life’s record. Mental-health support remains available.")
	return {"title":"Dependence & aftercare","icon":"🌱","rows":rows,"info":info}
func act(key: String, arg: Variant) -> void:
	match key:
		"stories": if str(arg) in ["quiet","standard","often"]: GameState.settings["recovery_stories"]=str(arg)
		"begin": if arg is Dictionary: begin(str(arg["id"]),str(arg["route"]))
		"session": session(str(arg))
		"aftercare": aftercare(str(arg))
		"boundary": if arg is Dictionary: boundary(str(arg["id"]),str(arg["kind"]))
		"buddy": if arg is Dictionary: set_buddy(str(arg["id"]),str(arg["uid"]))
