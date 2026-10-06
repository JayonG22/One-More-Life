extends RefCounted
var h
var units: Dictionary={}
var capstones: Dictionary={}
var placements: Dictionary={}
const ROUTES := {"college":["Community college",2,3200,2],"campus":["Community course",2,1600,2],"part_time":["Part-time course",3,900,1],"distance":["Distance course",3,600,1]}
func _init(hub):
	h=hub
	units=ContentDB._load_json("res://data/course_units.json",{})
	capstones=ContentDB._load_json("res://data/college_capstones.json",{})
	placements=ContentDB._load_json("res://data/placement_scenes.json",{})
func st() -> Dictionary:
	var s: Dictionary=h.section("learning",{"course":{},"completed":[],"internship":{},"history":[],"grant_year":-1,"placement_awards":{}})
	# Old successful placements already awarded their evidence. Trimming the
	# visible history must not make a completed field eligible for it again.
	for record in s["history"]:
		var field := str(record.get("field",""))
		if not s["placement_awards"].has(field) and int(record.get("steps",0))>=2 and int(record.get("honest_shifts",2 if int(record.get("paid",0))>=Actions._cost(160) else 0))>=2:
			s["placement_awards"][field]={"year":record.get("started",-1),"mentor":record.get("mentor",""),"legacy":true}
	return s
func college_reason() -> String:
	if GameState.player["country"] not in ["us","ca"]: return "College diploma route available in the US and Canada"
	if int(GameState.player["age"])<18: return "Age 18+"
	if not GameState.player["education"].get("hs_graduated",false): return "High school diploma required"
	return ""
func completed(field: String, route: String) -> bool:
	if route=="college":
		return st()["completed"].any(func(c): return c["field"]==field and c["route"]=="college") or GameState.player["education"]["degrees"].any(func(d): return d.get("level","")=="associate" and d.get("field","")==field)
	return st()["completed"].any(func(c): return c["field"]==field)
func prior_course(field: String) -> Dictionary:
	for c in st()["completed"]:
		if c["field"]==field and c["route"]!="college" and int(c.get("units",0))>=3: return c
	return {}
func enrol(field: String, route: String) -> void:
	if not Employment.programs.has(field) or not ROUTES.has(route) or not st()["course"].is_empty(): return
	if route=="college" and college_reason()!="": return
	if completed(field,route): return
	var prior := prior_course(field) if route=="college" else {}
	var fee := Actions._cost(int(ROUTES[route][2]))
	if not prior.is_empty(): fee=int(fee*0.6)
	var grant := GameState.in_school() and int(GameState.player["money"])<Actions._cost(3000) and int(st()["grant_year"])!=GameState.year_now()
	if grant: fee=int(fee*0.25)
	if not h.pay("course_enrol",1,fee,16): return
	if grant: st()["grant_year"]=GameState.year_now()
	st()["course"]={"field":field,"route":route,"country":GameState.player["country"],"started":GameState.year_now(),"earliest":GameState.year_now()+int(ROUTES[route][1]),"units":0,"points":0,"paused":false,"paid":fee,"unit_year":-1,"unit_ids":[]}
	if not prior.is_empty():
		st()["course"]["units"]=2; st()["course"]["points"]=mini(2,int(prior.get("points",0)))
		st()["course"]["unit_ids"]=prior.get("unit_ids",[]).duplicate(true)
		st()["course"]["credited"]=2; st()["course"]["earliest"]=GameState.year_now()+1
	h.done("📚","Learning alongside life",str(ROUTES[route][0])+" · "+field+(". Prior study credits 2 units; complete a new capstone and assessment. One year minimum." if not prior.is_empty() else ". Three practical units and an assessment.")+" Fee "+GameState.fmt_money(fee)+(" after student support." if grant else ".")+(" Earn an associate-level diploma; related bachelor study can accept credit. Professional licences stay separate." if route=="college" else "Earn practical skills and work evidence; degrees and licences stay separate."))
func unit() -> void:
	var c: Dictionary=st()["course"]
	if c.is_empty() or c["paused"] or int(c["units"])>=3: return
	var time := int(ROUTES[c["route"]][3])
	if h.blocked(16)!="" or h.used("course_unit"): return
	var pool: Array=[]
	var bank: Array=units.get(str(c["field"]),[])
	if c["route"]=="college" and int(c["units"])==2:
		bank=[capstones[str(c["field"])]]
	for i in range(bank.size()):
		var row: Array=bank[i]
		var id := "course_capstone:"+str(c["field"]) if c["route"]=="college" and int(c["units"])==2 else "course_unit:"+str(c["field"])+":"+str(i)
		if c.get("unit_ids",[]).has(id): continue
		pool.append({"id":id,"family":"course:"+str(c["field"]),"name":row[0],"question":row[1],"text":row[1],"answers":[row[2],row[3],row[4]],"why":row[5]})
	# Required coursework has its own completion record. Optional job/event
	# exhaustion must never make an already-paid qualification impossible.
	var fresh := Novelty.prefer(pool)
	var task: Dictionary={} if fresh.is_empty() else fresh.pick_random().duplicate(true)
	if task.is_empty():
		h.done("📚","No fresh unit","The available practical questions have been completed. No time was spent. Existing training and other fields remain available."); return
	if not h.pay("course_unit",time,0,16): return
	Novelty.note(task)
	var order: Array=[0,1,2]; order.shuffle()
	h.decision("learning","unit",{"units":c["units"],"order":order,"task":task},str(task["name"]),str(task["question"]),order.map(func(i): return task["answers"][i]))
func assess() -> void:
	var c: Dictionary=st()["course"]
	if c.is_empty() or c["paused"] or int(c["units"])<3 or GameState.year_now()<int(c["earliest"]) or not h.pay("course_assess",2,0,16): return
	var chance := Aptitude.chance(0.40+int(c["points"])*0.10+Market.skill(str(c["field"]))*0.02,"education")
	var passed := randf()<chance
	if passed:
		var r := c.duplicate(true); r["year"]=GameState.year_now(); r["state"]="completed"
		st()["completed"].push_front(r); st()["course"]={}
		Market.learn(str(c["field"]),1 if int(c.get("credited",0))>0 else 2); Employment.record(str(c["field"]))["samples"]+=1
		if c["route"]=="college":
			var name := "Associate diploma in "+str(c["field"])
			GameState.player["education"]["degrees"].append({"major":"college:"+str(c["field"]),"field":c["field"],"level":"associate","name":name,"country":c.get("country",GameState.player["country"]),"year":GameState.year_now()})
			GameState.counter("degrees"); GameState.add_milestone(GameState.player["age"],"earned an "+name.to_lower())
		# Qualifications are permanent evidence, not a rolling event history.
		# Trimming them would let an older field be enrolled and rewarded again.
		h.done("📚","Course completed","%d%% assessment chance. Added field skill and one work sample." % int(chance*100)+(" Your associate diploma is recorded; it is separate from a bachelor's degree or professional licence." if c["route"]=="college" else " Professional qualifications stay separate."))
	else: h.done("📚","A return route remains","%d%% assessment chance. The course and completed units are retained. Improve readiness and retry next year; there is no new enrolment fee." % int(chance*100),{"stress":2})
func internship() -> void:
	var c: Dictionary=st()["course"]
	if c.is_empty() or c["paused"] or st()["placement_awards"].has(str(c["field"])) or not st()["internship"].is_empty() or not h.pay("internship_start",1,0,16): return
	var id := GameState.create_npc("professional_contact",{"age":randi_range(25,60),"closeness":40})
	st()["internship"]={"field":c["field"],"mentor":FamilyChronicle.identity(GameState.npc(id)),"mentor_name":GameState.full_name(id),"started":GameState.year_now(),"due":GameState.year_now()+2,"steps":0,"paid":0,"decisions":[]}
	h.done("🧰","Supervised placement","Two supervised shifts across years build an honest reference. Each costs 2 time and pays a small stipend. You can leave if the workload does not fit; no job is guaranteed.")
func shift() -> void:
	var i: Dictionary=st()["internship"]
	if i.is_empty() or int(i["steps"])>=2 or GameState.year_now()>int(i["due"]) or (int(i["steps"])==1 and GameState.year_now()==int(i["started"])): return
	var id: String=h.person(str(i["mentor"]))
	if id=="" or not GameState.npc(id).get("alive",false): finish_intern("Supervisor unavailable"); return
	if not h.pay("internship_shift",2,0,16): return
	var scene: Array=placements.get(str(i["field"]),[["A supervised shift","A task goes beyond my training.",["Ask for supervision","Keep to my trained tasks","Promise unsupported work"],["Supervised work completed.","My limits were recorded.","The unsupported promise reduced trust."]],["A second supervised shift","The handover needs a qualified review.",["Ask the supervisor to review it","Record the unresolved question","Mark the handover complete"],["The supervisor reviewed the handover.","The remaining question was clearly recorded.","An unsupported completion reduced trust."]]])[int(i["steps"])]
	h.decision("learning","shift",{"mentor":i["mentor"],"step":i["steps"],"field":i["field"],"scene":scene},str(i["field"])+" · "+str(scene[0]),str(scene[1])+"\nSupervisor · "+GameState.full_name(id),scene[2],"🧰")
func finish_intern(reason: String) -> void:
	var i: Dictionary=st()["internship"]
	if i.is_empty(): return
	i["result"]=reason; st()["history"].push_front(i.duplicate(true)); st()["internship"]={}
	if st()["history"].size()>20: st()["history"].resize(20)
	h.note("Placement closed",reason+". Recorded experience and payments remain; no extra payment is awarded for leaving.")
func resolve(op: String, args: Dictionary, answer: int) -> void:
	if op=="unit":
		var c: Dictionary=st()["course"]
		if c.is_empty() or int(c["units"])!=int(args["units"]): return
		var good := int(args["order"][answer])==0
		c["units"]+=1; c["points"]+=1 if good else 0; c["unit_year"]=GameState.year_now()
		if not c.has("unit_ids"): c["unit_ids"]=[]
		c["unit_ids"].append(str(args["task"]["id"]))
		h.done("📚","Practical feedback",str(args["task"].get("why",args["task"]["answers"][0]))+" Units %d/3 · demonstrated %d/3. Readiness and field skill affect the final assessment." % [c["units"],c["points"]])
	elif op=="shift":
		var i: Dictionary=st()["internship"]
		if answer not in [0,1,2] or i.is_empty() or int(i["steps"])!=int(args["step"]) or str(i["mentor"])!=str(args["mentor"]) or str(args.get("field",i["field"]))!=str(i["field"]): return
		var id: String=h.person(str(i["mentor"]))
		if id=="" or not GameState.npc(id).get("alive",false): finish_intern("Supervisor unavailable"); return
		var payment := Actions._cost(120 if answer==0 else 80 if answer==1 else 0)
		GameState.player["money"]+=payment; Employment.record_income("Placement stipends",payment)
		i["honest_shifts"]=int(i.get("honest_shifts",1 if int(i["paid"])>0 else 0))+(1 if answer<2 else 0)
		i["paid"]+=payment; i["steps"]+=1
		var scene: Array=args.get("scene",[])
		var result: String=str(scene[3][answer]) if scene.size()>=4 else ["Supervised work completed.","My limits were recorded.","Unsupported work reduced trust."][answer]
		if not i.has("decisions"): i["decisions"]=[]
		i["decisions"].append({"year":GameState.year_now(),"task":scene[0] if not scene.is_empty() else "Supervised shift","choice":scene[2][answer] if scene.size()>=3 else str(answer),"result":result,"paid":payment})
		BondStats.apply(id,{"trust":3 if answer<2 else -8,"respect":2 if answer<2 else -4})
		FamilyChronicle.remember(id,"Supervised my placement; I "+["asked for support","kept within my training","overpromised the task"][answer]+".")
		if int(i["steps"])>=2:
			# Demonstrated work is evidence even when a new supervisor starts wary.
			# Their trust separately determines whether they provide a reference.
			var first: bool=not st()["placement_awards"].has(str(i["field"]))
			var reference: bool=int(i["honest_shifts"])>=2 and BondStats.get_stat(id,"trust")>=45
			if int(i["honest_shifts"])>=2 and first:
				Employment.record(str(i["field"]))["samples"]+=1
				st()["placement_awards"][str(i["field"])]={"year":GameState.year_now(),"mentor":i["mentor"],"reference":reference}
				h.modules["pathways"].record("work","placement:"+str(i["field"]),str(i["field"]),75.0 if reference else 60.0,true,str(i["mentor"]))
			if reference and first: Market.st()["interview_xp"]=minf(0.15,float(Market.st()["interview_xp"])+0.02)
			finish_intern("Placement completed" if reference else "Completed without a reference")
		h.done("🧰","Shift recorded",result+" Stipend "+GameState.fmt_money(payment)+".",{"stress":2 if answer<2 else 6})
func yearly() -> void:
	if Lives.separate(): return
	var i: Dictionary=st()["internship"]
	if not i.is_empty() and GameState.year_now()>int(i["due"]): finish_intern("Placement deadline missed")
func menu(page: String) -> Dictionary:
	var rows: Array=[]; var info: Array=["Study alongside life. Pausing keeps your work. US/Canadian college routes award an associate diploma; other courses award practical evidence. Licences are separate."]
	if page=="placements":
		info=["Each field earns placement evidence once. Supervisors and choices stay in your record."]
		for record in st()["history"]:
			info.append(str(record["field"])+" · "+str(record.get("result","Earlier placement"))+" · "+str(record.get("started",-1)))
			info.append("Supervisor · "+str(record.get("mentor_name","Earlier supervisor"))+" · paid "+GameState.fmt_money(int(record.get("paid",0))))
			for decision in record.get("decisions",[]): info.append(str(decision["year"])+" · "+str(decision["task"])+" · "+str(decision["choice"])+" · "+str(decision["result"]))
		if st()["history"].is_empty(): info.append("No concluded placement yet.")
		return {"title":"Placement record","icon":"🧰","rows":[],"info":info}
	rows.append(h.nav("learning","Placement record","Supervisors, choices and earned evidence","placements"))
	var c: Dictionary=st()["course"]
	if c.is_empty():
		if page.begins_with("field:"):
			var field := page.substr(6)
			if Employment.programs.has(field):
				if completed(field,"campus"): info.append("Practical study is complete. An eligible college upgrade remains available until the diploma is earned.")
				for route in ROUTES:
					var why := college_reason() if route=="college" else ""
					var upgrade: bool=route=="college" and not prior_course(field).is_empty()
					rows.append(h.row("learning","College upgrade" if upgrade else ROUTES[route][0],why if why!="" else ("2 units credited · 1 year minimum · fee "+GameState.fmt_money(int(Actions._cost(int(ROUTES[route][2]))*0.6)) if upgrade else "%d years minimum · %d time/unit · fee %s" % [ROUTES[route][1],ROUTES[route][3],GameState.fmt_money(Actions._cost(int(ROUTES[route][2])))]),"enrol",[field,route],not completed(field,route) and why==""))
		else:
			for field in Employment.programs: rows.append(h.nav("learning",str(field),"Choose a practical course route","field:"+str(field)))
	else:
		info.append("%s · %s · %d/3 units · assessment from %d%s" % [c["field"],ROUTES[c["route"]][0],c["units"],c["earliest"]," · paused" if c["paused"] else ""])
		rows.append(h.row("learning","Complete a practical unit","Once a year · "+str(ROUTES[c["route"]][3])+" time","unit",null,not c["paused"] and int(c["units"])<3 and not h.used("course_unit")))
		rows.append(h.row("learning","Final assessment","2 time · three units · minimum course duration","assess",null,not c["paused"] and int(c["units"])>=3 and GameState.year_now()>=int(c["earliest"]) and not h.used("course_assess")))
		rows.append(h.row("learning","Resume learning" if c["paused"] else "Pause learning","Keep units and paid fees; no completion reward","pause"))
		var placed: bool=st()["placement_awards"].has(str(c["field"]))
		rows.append(h.row("learning","Start a supervised placement","Field evidence already earned" if placed else "1 time · two paid shifts across years","intern",null,not placed and st()["internship"].is_empty() and not c["paused"]))
	if not st()["internship"].is_empty():
		info.append("Placement · %d/2 shifts · deadline %d" % [st()["internship"]["steps"],st()["internship"]["due"]])
		rows.append(h.row("learning","Work a supervised shift","2 time · one per year · small stipend","shift",null,not h.used("internship_shift")))
		rows.append(h.row("learning","Leave the placement","Keep experience; no extra pay","leave"))
	for r in st()["completed"]: info.append("%d · %s · %s" % [r["year"],r["field"],ROUTES[r["route"]][0]])
	return {"title":"Learning & placements","icon":"📚","rows":rows,"info":info}
func act(key: String, arg: Variant) -> void:
	match key:
		"enrol": enrol(str(arg[0]),str(arg[1]))
		"unit": unit()
		"assess": assess()
		"intern": internship()
		"shift": shift()
		"pause": if not st()["course"].is_empty() and h.blocked(16)=="": st()["course"]["paused"]=not st()["course"]["paused"]
		"leave": if h.blocked(16)=="": finish_intern("Left by choice")
