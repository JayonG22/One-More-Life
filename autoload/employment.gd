extends Node

## Career records belong to the current person. Prompts carry serial/step guards.
var briefs: Dictionary = {}
var programs: Dictionary = {}
var growth
const SCHEDULES := {"regular":["Regular hours",1.0,1.0,1.0],"reduced":["Shorter hours",0.85,-1.0,-4.0],"overtime":["Overtime",1.10,4.0,8.0]}
const TERMS := {"permanent":["Permanent",1.0],"fixed":["Three-year contract",1.05],"flexible":["Flexible contract",0.92]}

func _ready() -> void:
	growth=load("res://systems/career_growth.gd").new(self)
	briefs=JSON.parse_string(FileAccess.get_file_as_string("res://data/work_projects.json"))
	programs=JSON.parse_string(FileAccess.get_file_as_string("res://data/work_training.json"))

func st() -> Dictionary:
	var p := GameState.player
	if not p.has("employment") or not p["employment"] is Dictionary:
		p["employment"]={"serial":0,"active":{},"prompt":{},"training":{},"certificates":{},"records":{},"specialties":{},"clients":[],"history":[],"used":{},"relations":{},"booked":0,"booked_sources":{},"last_year":-1,"recovery":""}
		# A veteran save keeps evidence of its actual years worked, not a new diploma.
		if GameState.has_job() and int(p["job"].get("years",0))>0:
			var field := str(p["job"].get("field","General"))
			record(field)["samples"]=mini(4,int(p["job"]["years"]))
			Market.learn(field,maxi(0,mini(6,int(p["job"]["years"])+int(p["job"].get("rank",0)))-Market.skill(field)))
	return p["employment"]

func record(field: String) -> Dictionary:
	var s := st()
	if not s["records"].has(field): s["records"][field]={"samples":0,"finished":0,"good":0,"reputation":50.0}
	return s["records"][field]

func serial() -> int:
	st()["serial"]=int(st()["serial"])+1
	return int(st()["serial"])

func job_session() -> int:
	if not GameState.has_job(): return -1
	var j: Dictionary=GameState.player["job"]
	if not j.has("work_session"):
		j["work_session"]=serial()
	return int(j["work_session"])

func on_hire() -> void:
	job_session()
	var j: Dictionary=GameState.player["job"]
	j["work_contract"]="permanent"
	j["work_schedule"]="regular"
	j["contract_end"]=-1
	j["probation_end"]=GameState.year_now()+1
	st()["recovery"]=""

func setup_team() -> void:
	var ids := Workplace.crew()
	for i in range(mini(3,ids.size())): GameState.npc(ids[i])["work_role"]=["mentor","rival","friend"][i]

func on_leave(reason: String) -> void:
	close_coaching("Ended after " + reason)
	growth.close("Ended after "+reason+"; no award.")
	var active: Dictionary=st()["active"]
	if not active.is_empty(): close_project("Cancelled after "+reason,false,false)
	st()["recovery"]=reason
	# Course assessments survive job loss; job prompts do not.
	if str(st()["prompt"].get("kind","")) in ["project","mentor","client","growth"]: st()["prompt"]={}

func blocked() -> String:
	if not GameState.is_alive() or Lives.separate() or Lives.is_type("tv"): return "Needs an active human life"
	if GameState.in_prison(): return "Unavailable in custody"
	if EventEngine.has_pending() or EventEngine.displayed.has("def"): return "Finish the current event"
	if not Depth.state()["active"].is_empty(): return "Finish the current challenge"
	return ""

func stamp(key: String) -> String: return "%d:%s" % [GameState.year_now(),key]
func used(key: String) -> bool: return st()["used"].has(stamp(key))
func mark(key: String) -> void: st()["used"][stamp(key)]=true

func project_reason() -> String:
	var why := blocked()
	if why!="": return why
	if not GameState.has_job(): return "Get a job first"
	if not st()["active"].is_empty(): return "Finish your current project"
	if used("project"): return "Project started this year"
	if int(GameState.player["time_left"])<1: return "Needs 1 time"
	return ""

func start_project(index: int) -> void:
	if project_reason()!="": return
	var j: Dictionary=GameState.player["job"]
	var list: Array=briefs.get(str(j["id"]),[])
	if index<0 or index>=list.size(): return
	if not project_unseen(list[index]): return
	var field := str(j["field"])
	var client := client_for(field,index)
	var active := {"token":serial(),"session":job_session(),"job":str(j["id"]),"field":field,"brief":list[index].duplicate(true),"stage":0,"quality":35.0,"due":GameState.year_now()+1,"client":client["id"],"contact":client.get("contact",""),"support":0,"dishonest":false,"salary":int(j["salary"]),"started":GameState.year_now()}
	st()["active"]=active
	active["quality"]=35.0+(float(client["trust"])-50.0)/10.0
	mark("project")
	resume_project()
	if list[index].has("stages"): Novelty.note(project_scene(list[index]))

func project_scene(brief: Dictionary) -> Dictionary:
	return {"id":"work.project:"+str(GameState.player["job"]["id"])+":"+str(brief["name"]),"text":"Project: "+str(brief["name"])+". "+str(brief["brief"]),"family":"work.project:"+str(GameState.player["job"]["id"])}

func project_unseen(brief: Dictionary) -> bool:
	if not brief.has("stages"): return true
	for history in st()["history"]:
		if str(history["name"])==str(brief["name"]): return false
	return Novelty.eligible(project_scene(brief))

func client_for(field: String, variant: int) -> Dictionary:
	var key := field+":"+str(variant)
	for client in st()["clients"]:
		if client["id"]==key: return client
	var name := str(Market.CO_A[randi()%Market.CO_A.size()])+" "+str(Market.CO_B[randi()%Market.CO_B.size()])
	var client := {"id":key,"name":name,"field":field,"trust":50.0,"completed":0,"contact_completed":0,"last_year":GameState.year_now()}
	var contact := GameState.create_npc("professional_contact",{"age":randi_range(25,65),"closeness":45})
	client["contact"]=FamilyChronicle.identity(GameState.npc(contact))
	st()["clients"].append(client)
	if st()["clients"].size()>20: st()["clients"].pop_front()
	return client

func find_client(id: String) -> Dictionary:
	for client in st()["clients"]:
		if client["id"]==id: return client
	return {}

func project_valid() -> bool:
	var a: Dictionary=st()["active"]
	return not a.is_empty() and GameState.has_job() and int(a["session"])==job_session() and str(a["job"])==str(GameState.player["job"]["id"])

func choice(label: String, kind: String, token: int, step: int, answer: int, extra: int = 0) -> Dictionary:
	return {"label":label,"requires":{"time":extra},"outcomes":[{"text":"","no_friction":true,"employment":{"kind":kind,"token":token,"step":step,"answer":answer}}]}

func push_prompt(kind: String, token: int, step: int, title: String, text: String, choices: Array, context: Dictionary = {}) -> void:
	var def := {"id":"_employment","title":title,"icon":"💼","text":text,"choices":choices,"no_friction":true}
	st()["prompt"]={"kind":kind,"token":token,"step":step,"def":def}
	st()["prompt"].merge(context,true)
	EventEngine.push_decision(def)

func restore() -> void:
	# Earlier saves keep their culture/union/manager while gaining the new team roles.
	if GameState.has_job():
		var j: Dictionary=GameState.player["job"]
		var ww := Workplace.w()
		var ids := Workplace.crew()
		for id in j.get("coworkers",[]):
			if GameState.npcs.has(id) and bool(GameState.npcs[id]["alive"]) and not ids.has(id): ids.append(id)
		while ids.size()<3:
			ids.append(GameState.create_npc("coworker",{"age":clampi(int(GameState.player["age"])+randi_range(-8,14),18,64),"closeness":45}))
		j["coworkers"]=ids; ww["crew"]=ids
		setup_team()
	var prompt: Dictionary=st()["prompt"]
	if prompt.is_empty(): return
	if str(prompt["kind"])=="project" and not project_valid(): st()["prompt"]={}; return
	if not EventEngine.pending.any(func(it): return str(it.get("def",{}).get("id",""))=="_employment"):
		EventEngine.push_decision(prompt["def"])

func resume_project() -> void:
	if blocked()!="" or not project_valid() or not st()["prompt"].is_empty(): return
	if not GameState.spend_time(1): return
	var a: Dictionary=st()["active"]
	var brief: Dictionary=a["brief"]
	var stage := int(a["stage"])
	var options: Array=[]
	var text := ""
	if brief.has("stages"):
		var scene: Dictionary=brief["stages"][stage]
		var order: Array=[0,1,2]; order.shuffle()
		if stage==1 and not a.has("execution_roll"): a["execution_roll"]=randf()
		for index in order:
			var option: Dictionary=scene["options"][index]
			var extra := int(option.get("time",0))
			var label := str(option["label"])+( " · +%d time" % extra if extra>0 else "")
			if option.has("chance"):
				var quality_gain := int(float(option["gain"])*(0.75+Aptitude.score("work")/200.0))
				label+=" · +%d quality · %d%%" % [quality_gain,int(project_chance(a,option)*100)]
			options.append(choice(label,"project",int(a["token"]),stage,int(index),extra))
		text=str(scene["question"])+"\nQuality %d/100 · readiness %d/100 · field skill %d/10." % [int(a["quality"]),int(Aptitude.score("work")),Market.skill(str(a["field"]))]
		push_prompt("project",int(a["token"]),stage,["Plan","Do the work","Handover"][stage]+" · "+str(brief["name"]),text,options)
		return
	if stage==0:
		text="%s asks for: %s\nAgree the scope before starting." % [find_client(str(a["client"])).get("name","Your client"),brief["name"]]
		options=[choice("Check needs · +1 time","project",int(a["token"]),stage,0,1),choice("Use the standard plan","project",int(a["token"]),stage,1),choice("Promise it this year","project",int(a["token"]),stage,2)]
	elif stage==1:
		var task: Dictionary=brief["work"]
		text=str(task["question"])+"\nReadiness %d/100 · field skill %d/10." % [int(Aptitude.score("work")),Market.skill(str(a["field"]))]
		var order: Array=[0,1,2]; order.shuffle()
		for index in order: options.append(choice(str(task["answers"][index]),"project",int(a["token"]),stage,int(index)))
	else:
		text="Quality %d/100. Check %s before handover." % [int(a["quality"]),brief["standard"]]
		options=[choice("Check and share credit · +1 time","project",int(a["token"]),stage,0,1),choice("Send an honest summary","project",int(a["token"]),stage,1),choice("Hide faults; claim all credit","project",int(a["token"]),stage,2)]
	push_prompt("project",int(a["token"]),stage,["Plan","Do the work","Handover"][stage]+" · "+str(brief["name"]),text,options)

func project_chance(a: Dictionary, option: Dictionary) -> float:
	var base: float=Journey.modules["pathways"].support(str(a["field"]))+float(option.get("chance",0.64))+Market.skill(str(a["field"]))*0.025+float(a.get("support",0))/100.0
	if st()["specialties"].get(str(a["field"]),"")=="specialist": base+=0.05
	return Aptitude.chance(base,"work")

func outcome(ops: Dictionary) -> void:
	var prompt: Dictionary=st()["prompt"]
	if prompt.is_empty() or int(prompt["token"])!=int(ops.get("token",-1)) or int(prompt["step"])!=int(ops.get("step",-1)) or str(prompt["kind"])!=str(ops.get("kind","")): return
	var answer := int(ops.get("answer",-1))
	if answer<0 or answer>2: return
	var kind := str(prompt["kind"])
	if kind=="project" and not project_valid(): st()["prompt"]={}; return
	var extra := 1 if kind=="project" and answer==0 and int(prompt["step"]) in [0,2] else 0
	if kind=="client" and answer==0: extra=1
	if kind=="project" and st()["active"]["brief"].has("stages"):
		extra=int(st()["active"]["brief"]["stages"][int(prompt["step"])]["options"][answer].get("time",0))
	if extra>int(GameState.player["time_left"]): return
	if extra>0: GameState.spend_time(extra)
	st()["prompt"]={}
	match kind:
		"project": project_step(answer)
		"unit", "assessment": training_step(kind,answer)
		"client": client_response(prompt,answer)
		"mentor": mentor_response(prompt,answer)
		"growth": growth.resolve(prompt,answer)

func client_meeting(id: String) -> void:
	var c := find_client(id)
	if c.is_empty() or blocked()!="" or used("client:"+id) or not GameState.has_job() or str(GameState.player["job"]["field"])!=str(c["field"]): return
	var contact := Journey.person(str(c.get("contact","")))
	if contact=="" or not GameState.npc(contact).get("alive",false): return
	var scenes: Array=ContentDB._load_json("res://data/client_scenes.json",[])
	var scene := Novelty.pick(scenes)
	if scene.is_empty():
		EventEngine.push_info("🤝","Reviews complete","All current client meeting scenes have been encountered. Projects and existing contacts remain available.")
		return
	if not GameState.spend_time(1): return
	mark("client:"+id); Novelty.note(scene)
	var options: Array=[]
	var token := serial()
	for i in range(3): options.append(choice(str(scene["answers"][i]),"client",token,0,i,1 if i==0 else 0))
	push_prompt("client",token,0,str(c["name"])+" · review",str(scene["question"])+"\nContact: "+str(GameState.npc(contact)["first"])+" · trust "+str(int(c["trust"]))+"/100.",options,{"client":id,"roll":randf(),"session":job_session(),"contact":c["contact"],"scene":scene.duplicate(true)})

func client_response(prompt: Dictionary, answer: int) -> void:
	var c := find_client(str(prompt.get("client","")))
	if c.is_empty(): return
	var contact := Journey.person(str(c.get("contact","")))
	if contact=="" or not GameState.npc(contact).get("alive",false) or not GameState.has_job() or int(prompt.get("session",-1))!=job_session() or str(prompt.get("contact",c.get("contact","")))!=str(c.get("contact","")):
		EventEngine.push_info("🤝","Meeting ended","The contact or job changed. No reference or completed-work reward was created.")
		return
	var success := float(prompt["roll"])<Aptitude.chance(0.65,"social")
	var change := 8 if answer==0 else 3 if answer==1 and success else -2 if answer==1 else -3
	c["trust"]=clampf(float(c["trust"])+change,0,100)
	BondStats.apply(contact,{"trust":change,"respect":2 if answer==0 else 0})
	if answer==1 and success and int(c.get("contact_completed",c["completed"]))>=2 and float(c["trust"])>=65: c["reference"]=true
	GameState.change_stat("stress",2 if answer==0 else -4 if answer==2 else 1)
	var scene: Dictionary=prompt.get("scene",{})
	var choice_text: String=str(scene.get("answers",["Joint review","Reference request","Declined extra work"])[answer])
	FamilyChronicle.remember(contact,str(scene.get("question","Client review"))+" · "+choice_text,"good" if change>0 else "neutral")
	if not c.has("meetings"): c["meetings"]=[]
	c["meetings"].push_front({"year":GameState.year_now(),"contact":c["contact"],"scene":scene.get("id","legacy"),"choice":choice_text,"trust":c["trust"],"reference":c.get("reference",false)})
	while c["meetings"].size()>12: c["meetings"].pop_back()
	EventEngine.push_info("🤝","Client response","Trust %d/100. %s" % [int(c["trust"]),"An earned reference supports future applications in this field." if c.get("reference",false) else "The contact remembers this response; a reference needs two projects witnessed by this contact and trust 65+."])

func project_step(answer: int) -> void:
	var a: Dictionary=st()["active"]
	var stage := int(a["stage"])
	var feedback := ""
	if a["brief"].has("stages"):
		var option: Dictionary=a["brief"]["stages"][stage]["options"][answer]
		if not a.has("choices"): a["choices"]=[]
		a["choices"].append(str(option["label"]))
		var gain := float(option["gain"])
		if option.has("chance"):
			var chance := project_chance(a,option)
			var success := float(a.get("execution_roll",1.0))<chance
			gain=gain*(0.75+Aptitude.score("work")/200.0) if success else 4.0
			feedback="The approach passed its check." if success else "The approach needs further work."
			feedback+=" Chance %d%%." % int(chance*100)
		GameState.change_stat("stress",float(option.get("stress",0)))
		var team := int(option.get("team",0))
		if team!=0: remember_team(team)
		a["quality"]=clampf(float(a["quality"])+gain,0,100)
		if bool(option.get("dishonest",false)): a["dishonest"]=true
		if stage==2:
			close_project("Delivered",true,true)
			return
		a["stage"]=stage+1
		EventEngine.push_info("🧰","Step complete",feedback+"\n"+str(option["label"])+". Quality %d/100. Continue when ready." % int(a["quality"]))
		return
	if stage==0:
		a["quality"]=float(a["quality"])+[12,6,2][answer]
		feedback="The plan is recorded. Continue the project when you are ready."
		if answer==2: a["due"]=GameState.year_now(); GameState.change_stat("stress",5)
	elif stage==1:
		var base := 0.54+Market.skill(str(a["field"]))*0.025+float(a["support"])/100.0
		if st()["specialties"].get(str(a["field"]),"")=="specialist": base+=0.05
		var chance := Aptitude.chance(base,"work")
		var success := answer==0 and randf()<chance
		a["quality"]=float(a["quality"])+(26 if success else 6 if answer==0 else 3 if answer==1 else -8)
		feedback="%s\n%s Chance %d%%. Quality %d/100." % [str(a["brief"]["work"]["answers"][0]),"The work passed its check." if success else "The work needs improvement.",int(chance*100),int(a["quality"])]
		GameState.apply_effects({"stress":2,"health":-1 if GameState.stat("stress")>80 else 0})
	else:
		a["quality"]=clampf(float(a["quality"])+[12,4,-10][answer],0,100)
		a["dishonest"]=answer==2
		if answer==0: remember_team(4)
		elif answer==2: remember_team(-12)
		close_project("Delivered",true,true)
		return
	a["stage"]=stage+1
	EventEngine.push_info("🧰","Step complete",feedback)

func remember_team(amount: int) -> void:
	for id in Workplace.crew():
		GameState.change_closeness(id,amount)
		var key := FamilyChronicle.identity(GameState.npc(id))
		st()["relations"][key]=clampi(int(st()["relations"].get(key,0))+amount,-40,40)
	while st()["relations"].size()>100: st()["relations"].erase(st()["relations"].keys()[0])

func close_project(reason: String, delivered: bool, pay: bool) -> void:
	var a: Dictionary=st()["active"]
	if a.is_empty(): return
	var field := str(a["field"])
	var quality := float(a["quality"])
	var good := delivered and quality>=70 and not bool(a["dishonest"])
	var r := record(field)
	var bonus := 0
	if delivered:
		r["finished"]=int(r["finished"])+1
		r["samples"]=int(r["samples"])+(1 if quality>=60 and not bool(a["dishonest"]) else 0)
		r["good"]=int(r["good"])+(1 if good else 0)
		Market.learn(field,1 if quality>=60 and not bool(a["dishonest"]) else 0)
	if pay:
		var client_factor := clampf(0.9+float(find_client(str(a["client"])).get("trust",50))/500.0,0.9,1.1)
		var gross := int(minf(8000,float(a["salary"])*0.04)*(quality/100.0)*Aptitude.reward("work")*client_factor)
		bonus=maxi(0,int(gross*(1.0-Places.tax())))
		GameState.player["money"]=int(GameState.player["money"])+bonus
		record_income("Project bonuses",bonus)
	var change := 6 if good else -12 if not delivered or bool(a["dishonest"]) else -3
	r["reputation"]=clampf(float(r["reputation"])+change,0,100)
	var client := find_client(str(a["client"]))
	if not client.is_empty():
		client["trust"]=clampf(float(client["trust"])+change,0,100)
		client["completed"]=int(client["completed"])+(1 if delivered else 0)
		if delivered and str(a.get("contact",client.get("contact","")))==str(client.get("contact","")):
			client["contact_completed"]=int(client.get("contact_completed",int(client["completed"])-1))+1
		client["last_year"]=GameState.year_now()
	if project_valid(): GameState.apply_effects({"job_perf":6 if good else -5 if not delivered else 1,"stress":-2 if good else 3})
	var history := {"name":a["brief"]["name"],"field":field,"year":GameState.year_now(),"quality":quality,"result":reason,"bonus":bonus,"dishonest":a["dishonest"],"audit_due":GameState.year_now()+1 if bool(a["dishonest"]) and delivered else -1,"audited":false}
	history["job"]=a["job"]; history["session"]=a["session"]; history["choices"]=a.get("choices",[]).duplicate()
	Journey.modules["pathways"].record("work",str(a["job"])+":"+str(a["session"])+":"+str(history["name"])+":"+str(history["year"]),field,quality if delivered else 0.0,delivered and not bool(a["dishonest"]))
	st()["history"].push_front(history)
	if st()["history"].size()>50: st()["history"].resize(50)
	st()["active"]={}
	if str(st()["prompt"].get("kind",""))=="project": st()["prompt"]={}
	GameState.add_log("Work project: %s · %s · quality %d · bonus %s." % [history["name"],reason,int(quality),GameState.fmt_money(bonus)])
	EventEngine.push_info("📁",reason,"%s\nQuality %d/100 · bonus %s after tax.\nField reputation %d/100. %s" % [history["name"],int(quality),GameState.fmt_money(bonus),int(r["reputation"]),"False claims may be checked later." if bool(a["dishonest"]) else "Your work record stays with you."])

func note_task(field: String, correct: bool) -> void:
	if correct: record(field)["samples"]=int(record(field)["samples"])+1; Market.learn(field,1)
	else: record(field)["reputation"]=maxf(0,float(record(field)["reputation"])-2)

func hiring_bonus(field: String) -> float:
	var r := record(field)
	var reference: bool = st()["clients"].any(func(c): return str(c["field"])==field and c.get("reference",false) and float(c["trust"])>=65 and Journey.person(str(c.get("contact","")))!="" and GameState.npc(Journey.person(str(c.get("contact","")))).get("alive",false))
	return clampf(mini(4,int(r["good"]))*0.012+(float(r["reputation"])-50)/500.0+(0.04 if st()["certificates"].has(field) else 0.0)+(0.03 if reference else 0.0),-0.10,0.14)

func promotion_reason() -> String:
	if not GameState.has_job(): return "Get a job first"
	var j: Dictionary=GameState.player["job"]
	var jd := ContentDB.job(str(j["id"]))
	if int(j.get("rank",0))>=jd.get("ranks",[j["title"]]).size()-1: return "Top rank · develop your speciality"
	if int(j.get("years_in_rank",0))<2: return "Needs two years in this rank"
	if float(j["perf"])<70: return "Needs performance 70+"
	var field := str(j["field"])
	var skill_need := mini(6,2+int(j.get("rank",0)))
	if Market.skill(field)<skill_need: return "Field skill %d/%d" % [Market.skill(field),skill_need]
	var samples_need := mini(4,2+int(j.get("rank",0)))
	if int(record(field)["samples"])<samples_need: return "Work samples %d/%d" % [int(record(field)["samples"]),samples_need]
	return ""

func ask_promotion() -> void:
	if blocked()!="" or promotion_reason()!="" or used("promotion") or not GameState.spend_time(1): return
	mark("promotion")
	var j: Dictionary=GameState.player["job"]
	var chance := clampf(0.35+float(Workplace.w().get("health",0.7))*0.25+(GameState.stat("happiness")-50)/400.0,0.15,0.85)
	if randf()<chance:
		Workforce._promote(j,ContentDB.job(str(j["id"]))["ranks"],str(j.get("employer_name","your employer")),[[1.0,"completed work and practical skills"]])
	else: EventEngine.push_info("📋","No opening","Your work is ready, but no post is available. Your skills and samples remain.")

func mentor() -> void:
	if blocked()!="" or not GameState.has_job() or used("mentor") or not st()["prompt"].is_empty(): return
	if not coaching().is_empty():
		EventEngine.push_info("🤝","Current coaching","Complete the agreed duty first. Advice is not another skill award.")
		return
	var mentors := Workplace.crew().filter(func(id): return str(GameState.npc(id).get("work_role",""))=="mentor")
	var tasks := Depth.job_tasks()
	if mentors.is_empty() or tasks.is_empty() or not GameState.spend_time(1): return
	mark("mentor")
	var id: String=mentors[0]
	var token := serial()
	var options: Array=[]
	for i in range(mini(2,tasks.size())):
		options.append(choice("Focus: "+str(tasks[i]["name"]),"mentor",token,0,i))
	options.append(choice("Review my current project","mentor",token,0,2))
	push_prompt("mentor",token,0,"Coaching · "+GameState.npc(id)["first"],
		"Choose a goal. A coached duty costs its normal 1 time; learning comes from following through.\n"+Bonds.quick_line(id), options,
		{"session":job_session(),"mentor":FamilyChronicle.identity(GameState.npc(id)),"tasks":tasks.duplicate(true)})

func coaching() -> Dictionary:
	if not st().has("coaching"): st()["coaching"]={}
	return st()["coaching"]

func mentor_response(prompt: Dictionary, answer: int) -> void:
	if not GameState.has_job() or int(prompt["session"])!=job_session(): return
	var id := Journey.person(str(prompt["mentor"]))
	if id=="" or not GameState.npc(id).get("alive",false):
		EventEngine.push_info("🤝","Contact ended","The mentor is no longer available. No skill award.")
		return
	if answer==2:
		var active: Dictionary=st()["active"]
		if project_valid(): active["support"]=8; active["quality"]=minf(100,float(active["quality"])+4)
		BondStats.apply(id,{"respect":1})
		FamilyChronicle.remember(id,"Discussed a project approach; feedback alone did not award a skill.")
		EventEngine.push_info("🤝","Project feedback","Project support improved." if project_valid() else "No active project to review. No skill award.")
		return
	var tasks: Array=prompt["tasks"]
	if answer<0 or answer>=tasks.size(): return
	st()["coaching"]={"session":job_session(),"mentor":prompt["mentor"],"duty":answer,"name":tasks[answer]["name"],"field":GameState.player["job"]["field"],"started":GameState.year_now(),"expires":GameState.year_now()+1,"state":"open"}
	FamilyChronicle.remember(id,"Coaching goal: "+str(tasks[answer]["name"])+". Learning requires follow-through.")
	EventEngine.push_info("🧰","Coaching goal",str(tasks[answer]["name"])+" · finish this duty by next year. No skill awarded yet.")

func close_coaching(reason: String) -> void:
	var plan := coaching()
	if plan.is_empty(): return
	plan["conclusion"]=reason; plan["closed"]=GameState.year_now(); plan["state"]="closed"
	if not st().has("coaching_history"): st()["coaching_history"]=[]
	st()["coaching_history"].push_front(plan.duplicate(true))
	if st()["coaching_history"].size()>40: st()["coaching_history"].resize(40)
	st()["coaching"]={}

func complete_coaching(duty: int) -> float:
	var plan := coaching()
	if plan.is_empty() or not GameState.has_job(): return 0.0
	if int(plan["session"])!=job_session(): close_coaching("Job changed"); return 0.0
	if GameState.year_now()>int(plan["expires"]): close_coaching("Goal expired without a skill award"); return 0.0
	if int(plan["duty"])!=duty: return 0.0
	var id := Journey.person(str(plan["mentor"]))
	if id=="" or not GameState.npc(id).get("alive",false): close_coaching("Mentor unavailable"); return 0.0
	Market.learn(str(plan["field"]),1)
	BondStats.apply(id,{"trust":3,"respect":3})
	FamilyChronicle.remember(id,"Completed the coaching goal: "+str(plan["name"])+".","good")
	var quality := clampf(50.0+Aptitude.score("work")*0.4,0.0,100.0)
	Journey.modules["pathways"].record("work","coaching:"+str(plan["session"])+":"+str(plan["started"]),str(plan["field"]),quality,true,id)
	close_coaching("Completed · field skill +1; a named follow-up was recorded")
	return 0.5+Aptitude.score("work")/100.0

func enrol(field: String, kind: String) -> void:
	if blocked()!="" or not programs.has(field) or not st()["training"].is_empty() or st()["certificates"].has(field): return
	if int(GameState.player["age"])<16 or kind not in ["apprentice","retrain"] or (kind=="apprentice" and not programs[field]["apprentice"]): return
	var fee := Actions._cost(1200 if kind=="apprentice" else 4500)
	if int(GameState.player["money"])<fee or not GameState.spend_time(1): return
	GameState.player["money"]=int(GameState.player["money"])-fee
	st()["training"]={"field":field,"kind":kind,"started":GameState.year_now(),"years":2 if kind=="apprentice" else 1,"units":0,"token":serial(),"round":0,"points":0,"questions":[]}
	EventEngine.push_info("🧰","Training started","%s · %s. Complete two practical units, then pass the assessment after %d year(s).\nRegulated jobs still need their degrees and licences." % [field,GameState.fmt_money(fee),st()["training"]["years"]])

func training_task(field: String, index: int) -> Dictionary:
	var ids: Array=programs[field]["jobs"]
	var id: String=ids[index%ids.size()]
	return Depth.jobs[id][index%Depth.jobs[id].size()]

func practical() -> void:
	var t: Dictionary=st()["training"]
	if blocked()!="" or t.is_empty() or not st()["prompt"].is_empty() or int(t["units"])>=2 or used("unit:"+str(t["units"])): return
	if not GameState.spend_time(1): return
	mark("unit:"+str(t["units"]))
	t["token"]=serial()
	var task := training_task(str(t["field"]),int(t["units"])+GameState.year_now()%3)
	t["task"]=task
	var options: Array=[]
	var order: Array=[0,1,2]; order.shuffle()
	for answer in order: options.append(choice(str(task["answers"][answer]),"unit",int(t["token"]),int(t["units"]),answer))
	push_prompt("unit",int(t["token"]),int(t["units"]),"Practical · "+str(task["name"]),str(task["question"]),options)

func assessment_reason() -> String:
	var t: Dictionary=st()["training"]
	if t.is_empty(): return "Start training first"
	if int(t["units"])<2: return "Complete two practical units"
	if GameState.year_now()<int(t["started"])+int(t["years"]): return "Assessment opens in %d" % [int(t["started"])+int(t["years"])]
	if used("assessment"): return "Assessment used this year"
	return ""

func assess() -> void:
	if blocked()!="" or assessment_reason()!="" or not st()["prompt"].is_empty() or not GameState.spend_time(2): return
	mark("assessment")
	var t: Dictionary=st()["training"]
	t["token"]=serial(); t["round"]=0; t["points"]=0
	t["questions"]=[]
	for i in range(3): t["questions"].append(training_task(str(t["field"]),i+GameState.year_now()%7))
	assessment_prompt()

func assessment_prompt() -> void:
	var t: Dictionary=st()["training"]
	var task: Dictionary=t["questions"][int(t["round"])]
	var order: Array=[0,1,2]; order.shuffle()
	var options: Array=[]
	for answer in order: options.append(choice(str(task["answers"][answer]),"assessment",int(t["token"]),int(t["round"]),answer))
	push_prompt("assessment",int(t["token"]),int(t["round"]),"Assessment · %d/3" % [int(t["round"])+1],task["question"],options)

func training_step(kind: String, answer: int) -> void:
	var t: Dictionary=st()["training"]
	if t.is_empty(): return
	if kind=="unit":
		if answer==0: t["units"]=int(t["units"])+1; Market.learn(str(t["field"]),1)
		EventEngine.push_info("🧰","Practical result","%s\nUnits passed: %d/2. %s" % [t["task"]["answers"][0],int(t["units"]),"Try the next unit." if answer==0 else "Review this approach and try next year."])
		return
	t["points"]=int(t["points"])+(1 if answer==0 else 0)
	t["round"]=int(t["round"])+1
	if int(t["round"])<3: assessment_prompt(); return
	var passed := int(t["points"])>=2
	if passed:
		st()["certificates"][str(t["field"])]={"year":GameState.year_now(),"kind":t["kind"],"score":t["points"]}
		Market.learn(str(t["field"]),2)
		GameState.add_milestone(int(GameState.player["age"]),"qualified in "+str(t["field"]))
	EventEngine.push_info("🎓","Passed" if passed else "Not passed","%s · %d/3. %s" % [t["field"],int(t["points"]),"Qualification recorded. Browse eligible jobs; degrees and licences still apply." if passed else "Keep your practical progress and try next year."])
	if passed: st()["training"]={}

func has_certificate(field: String) -> bool: return st()["certificates"].has(field)

func specialise(kind: String) -> void:
	if blocked()!="" or not GameState.has_job() or kind not in ["specialist","leadership"] or used("specialty"): return
	var field := str(GameState.player["job"]["field"])
	if st()["specialties"].get(field,"")==kind: return
	if Market.skill(field)<4 or int(record(field)["samples"])<2: return
	var fee := Actions._cost(800)
	if int(GameState.player["money"])<fee or not GameState.spend_time(1): return
	mark("specialty"); st()["specialties"][field]=kind
	GameState.player["money"]=int(GameState.player["money"])-fee
	EventEngine.push_info("🧭","Speciality set","%s · %s. %s" % [field,kind.capitalize(),"More reliable project work." if kind=="specialist" else "Teamwork and reviews improve; this is not an automatic management post."])

func set_term(kind: String) -> void:
	if blocked()!="" or not GameState.has_job() or not TERMS.has(kind) or used("terms"): return
	mark("terms")
	var j: Dictionary=GameState.player["job"]
	j["work_contract"]=kind
	j["contract_end"]=GameState.year_now()+3 if kind=="fixed" else -1
	EventEngine.push_info("📝","Contract set","%s. Pay ×%.2f; fixed terms can expire. This year's wages use the selected terms." % [TERMS[kind][0],TERMS[kind][1]])

func set_schedule(kind: String) -> void:
	if blocked()!="" or not GameState.has_job() or not SCHEDULES.has(kind) or used("schedule"): return
	mark("schedule"); GameState.player["job"]["work_schedule"]=kind
	EventEngine.push_info("🕒","Hours set","%s · pay ×%.2f. Yearly performance %+.0f; stress %+.0f." % SCHEDULES[kind])

func pay_factor() -> float:
	if not GameState.has_job(): return 1.0
	var j: Dictionary=GameState.player["job"]
	return (0.5 if Journey.modules["heritage"].st()["phased"] else 1.0)*float(SCHEDULES.get(str(j.get("work_schedule","regular")),SCHEDULES["regular"])[1])*float(TERMS.get(str(j.get("work_contract","permanent")),TERMS["permanent"])[1])*(0.9 if int(j.get("leave_year",-1))==GameState.year_now()-1 else 1.0)

func yearly() -> void:
	var s := st()
	var year := GameState.year_now()
	if int(s["last_year"])==year: return
	s["last_year"]=year
	growth.yearly()
	for key in s["used"].keys():
		if int(str(key).get_slice(":",0))<year-2: s["used"].erase(key)
	if not s["active"].is_empty() and (not project_valid() or year>int(s["active"]["due"])): close_project("Missed deadline",false,false)
	for history in s["history"]:
		if int(history.get("audit_due",-1))>0 and not bool(history.get("audited",false)) and year>=int(history["audit_due"]):
			history["audited"]=true
			GameState.player["money"]=int(GameState.player["money"])-int(history["bonus"])
			record(str(history["field"]))["reputation"]=maxf(0,float(record(str(history["field"]))["reputation"])-10)
			GameState.add_log("A check found false claims on %s. I repaid the %s bonus." % [history["name"],GameState.fmt_money(int(history["bonus"]))])
			var same_post := GameState.has_job() and str(GameState.player["job"]["id"])==str(history.get("job","")) and job_session()==int(history.get("session",-1))
			GameState.apply_effects({"job_perf":-8 if same_post else 0,"stress":6})
	if not GameState.has_job() or GameState.in_prison(): return
	var j: Dictionary=GameState.player["job"]
	var schedule: Array=SCHEDULES.get(str(j.get("work_schedule","regular")),SCHEDULES["regular"])
	GameState.apply_effects({"job_perf":schedule[2],"stress":schedule[3],"health":-2 if j.get("work_schedule","regular")=="overtime" else 0})
	if int(j.get("leave_year",-1))==year-1: GameState.apply_effects({"stress":-8,"health":3,"happiness":4})
	if st()["specialties"].get(str(j["field"]),"")=="leadership": GameState.apply_effects({"job_perf":1}); remember_team(1)

func finish_work_year() -> void:
	if not GameState.has_job(): return
	var j: Dictionary=GameState.player["job"]
	var year := GameState.year_now()
	var plan := coaching()
	if not plan.is_empty():
		var mentor_id := Journey.person(str(plan["mentor"]))
		if mentor_id=="" or not GameState.npc(mentor_id).get("alive",false): close_coaching("Mentor unavailable; no skill award")
		elif int(plan["session"])!=job_session(): close_coaching("Job changed; no skill award")
		elif year>int(plan["expires"]): close_coaching("Goal expired without a skill award")
	if j.get("probation_reviewed",false) and not j.get("probation_passed",false) and float(j["perf"])>=55:
		j["probation_passed"]=true
		GameState.add_log("My follow-up review confirmed improvement. The probation performance plan is complete.")
	if not bool(j.get("probation_reviewed",false)) and year>=int(j.get("probation_end",year+1)):
		j["probation_reviewed"]=true
		if float(j["perf"])>=55:
			j["probation_passed"]=true
			GameState.change_closeness(str(j["boss"]),3)
			GameState.add_log("I passed probation. My manager can now provide a stronger reference.")
		else:
			j["warned"]=maxi(1,int(j.get("warned",0)))
			GameState.add_log("Probation ended on a performance plan. I need to improve before the next review.")
	if j.get("work_contract","")=="fixed" and year>=int(j.get("contract_end",year+1)):
		if float(j["perf"])>=55 and float(Workplace.w().get("health",0.7))>=0.4:
			j["contract_end"]=year+3; GameState.add_log("My fixed contract was renewed for three years.")
		else: Actions.lose_job("contract ended"); GameState.add_log("My fixed contract ended after the final wages were paid.")

func record_income(source: String, amount: int) -> void:
	if amount==0: return
	if amount<0:
		record_expense(source+" shortfall",-amount)
		return
	st()["booked"]=int(st()["booked"])+amount
	st()["booked_sources"][source]=int(st()["booked_sources"].get(source,0))+amount

func record_expense(source: String, amount: int) -> void:
	if amount<=0: return
	var s := st()
	if not s.has("booked_expenses"): s["booked_expenses"]={}
	s["booked_expenses"][source]=int(s["booked_expenses"].get(source,0))+amount

func take_income() -> Dictionary:
	var result := {"amount":int(st()["booked"]),"sources":st()["booked_sources"].duplicate(true),"paid_expenses":st().get("booked_expenses",{}).duplicate(true)}
	st()["booked"]=0; st()["booked_sources"]={}; st()["booked_expenses"]={}
	return result

func after_finances() -> void:
	var p := GameState.player
	var year := GameState.year_now()
	if not GameState.is_alive() or int(st().get("finances_year",-1))>=year: return
	st()["finances_year"]=year
	var before := int(p["money"])
	Lending.yearly()
	var paid := maxi(0,before-int(p["money"]))
	p["last_expenses"]=int(p["last_expenses"])+paid
	if p.has("household_ledger"):
		p["household_ledger"]["expenses"]=int(p["household_ledger"]["expenses"])+paid
		if paid>0: p["household_ledger"]["lines"]["Personal loan payments"]=paid
	finish_work_year()

func repay(index: int, amount: int) -> void:
	if not GameState.is_alive() or Childhood.supported() or Lives.separate(): return
	if index<0 or index>=Lending.debts().size() or amount<=0 or int(GameState.player["money"])<amount: return
	var d: Dictionary=Lending.debts()[index]
	amount=mini(amount,int(d["left"]))
	GameState.player["money"]=int(GameState.player["money"])-amount
	d["left"]=int(d["left"])-amount
	record_expense("Early loan repayment",amount)
	Lending.remember(GameState.player,d,"Extra payment",GameState.year_now(),amount)
	if int(d["left"])==0: Lending.debts().remove_at(index); Grit.change_credit(30)
	GameState.add_log("I paid %s extra towards a personal loan." % GameState.fmt_money(amount))
	EventEngine.push_info("🏦","Payment made","Paid %s. Remaining %s. The contracted annual payment stays the same until the balance is cleared." % [GameState.fmt_money(amount),GameState.fmt_money(int(d["left"]))])

func recovery() -> void:
	if blocked()!="" or GameState.has_job() or int(GameState.player["age"])<18 or used("recovery") or not GameState.spend_time(2): return
	mark("recovery")
	Market.st()["interview_xp"]=minf(0.15,float(Market.st()["interview_xp"])+0.04)
	Market.st()["gap"]=maxi(0,int(Market.st()["gap"])-1)
	GameState.apply_effects({"stress":-3,"happiness":2})
	EventEngine.push_info("🔎","Search plan ready","Your CV explains the gap, and you practised interviews. Browse openings next; a job is not guaranteed.")

func row(name: String, sub: String, act: String, arg: Variant = null, on: bool = true, icon: String = "💼") -> Dictionary:
	return {"name":name,"sub":sub,"act":"employment:"+act,"arg":arg,"on":on,"icon":icon}
func nav(name: String, sub: String, key: String, icon: String = "📁") -> Dictionary:
	return {"name":name,"sub":sub,"menu":"employment:"+key,"on":true,"icon":icon}

func menu(key: String) -> Dictionary:
	var p := GameState.player
	var s := st()
	var rows: Array=[]
	var info: Array=[]
	var title := "Work & career"
	if key in ["","root"]:
		rows=[nav("Career & growth","Assignments, qualifications and advancement","career","📈"),nav("Pay & conditions","Hours, leave, income and recovery","pay","🏦"),nav("Work record","Projects and client trust","history","📖")]
	elif key=="career":
		title="Career & growth"
		rows=[nav("Career projects","Client assignment · plan, work, handover","projects"),nav("Clients","Contacts and references","clients","🤝"),nav("Role & promotion","Requirements and specialities","progress","📈"),nav("Qualifications","Apprenticeship or retraining","training","🧰")]
		var job_id := str(p.get("job",{}).get("id",""))
		if GameState.has_job():
			rows.append({"icon":"📈","name":"Professional development","sub":"Internal initiative, network, mentor and rival","menu":"amb:career_story","on":true})
		if job_id in ["police","doctor","nurse"]:
			var specialist_label := "Police & detective work" if job_id=="police" else "Clinical practice"
			rows.append({"icon":"🧭","name":specialist_label,"sub":"Role-specific duties and cases","menu":"amb:work","on":true})
	elif key=="pay":
		title="Pay & conditions"
		rows=[nav("Hours & contract","Pay, workload and leave","terms","🕒"),nav("Money & recovery","Income, loans and personal savings","money","🏦")]
	elif key=="duties":
		title="Your job"
		if not GameState.has_job(): info=["Get a job to open its duties and team."]
		else:
			var j: Dictionary=p["job"]; info=[str(j["title"])+" · "+str(j["field"]),"Your work, people and career projects."]
			rows=[nav("Daily duties","Role-specific tasks · 1 time each","daily_duties","🧰"),nav("Workplace situations","Two new choices per year","situations","💬"),nav("Team & contacts","Boss and named colleagues","team","🤝"),{"icon":"🧰","name":"Work practice","sub":"Short challenges tied to practical skills","menu":"journey:skills:work"}]
			return {"icon":"💼","title":title,"info":info,"bars":[{"name":"Work performance","value":j["perf"]},{"name":"Field skill","value":Market.skill(str(j["field"]))*10}],"rows":rows}
	elif key=="daily_duties":
		title="Daily duties"
		if GameState.has_job():
			var j: Dictionary=p["job"]
			info=[str(j["title"])+" · routine tasks · 1 time each · stress +2"]
			var tasks := Depth.job_tasks()
			for i in range(tasks.size()): rows.append(row(str(tasks[i]["name"]),"Role-specific · modest performance · no extra salary","duty",i,not used("duty:"+str(job_session())+":"+str(i)),"🧰"))
		else: info=["Get a job to see its role-specific duties."]
	elif key=="situations":
		title="Workplace situations"
		if GameState.has_job():
			var j: Dictionary=p["job"]
			var unused_scenes := Depth.unused_job_scenes()
			var remaining_choices := 0
			for i in range(2):
				if not Depth.available("job:"+str(j["id"])+str(i)) or unused_scenes<=0: continue
				rows.append(row("Work situation" if i==0 else "Another situation","1 time · unique role scene","encounter",i,true,"💬"))
				unused_scenes-=1
				remaining_choices+=1
			if remaining_choices>0:
				info=["%d unused scene%s this year · choices affect work and relationships." % [remaining_choices,"" if remaining_choices==1 else "s"]]
			elif blocked()!="":
				info=[blocked()+"."]
			elif Depth.unused_job_scenes()==0:
				info=["No unused scenes remain for this role. Duties and projects are still available."]
			else:
				info=["Both work-situation choices have been used this year."]
		else: info=["Get a job to see its workplace situations."]
	elif key=="team":
		title="Team & contacts"
		if GameState.has_job():
			var crew: Array=Workplace.crew().duplicate()
			var boss: String=str(p["job"].get("boss",""))
			if boss!="" and GameState.npcs.has(boss) and GameState.npc(boss).get("alive",false): crew.push_front(boss)
			for who in crew: rows.append({"icon":Bonds.U_face(GameState.npc(who)),"name":GameState.full_name(who),"sub":str(GameState.npc(who).get("work_role",GameState.relation_label(who)))+" · "+Bonds.quick_line(who),"menu":"bond:"+str(who)})
		else: info=["Get a job to meet its boss and colleagues."]
		if GameState.has_job(): rows.append(nav("Coaching & goals","Named mentor, duties and follow-through","coaching","🧭"))
	elif key=="coaching":
		title="Coaching & goals"
		var plan := coaching()
		if not plan.is_empty():
			info=[str(plan["name"])+" · due "+str(plan["expires"]),"Complete its daily duty; no extra salary."]
			rows.append(nav("Daily duties","Finish the agreed task","daily_duties","🧰"))
		else:
			info=["Advice sets a goal. Completing its duty earns skill and a later connection."]
			rows.append(row("Ask your mentor","1 time · choose a goal","mentor",null,GameState.has_job() and not used("mentor") and blocked()=="","🤝"))
		for entry in st().get("coaching_history",[]).slice(0,6): info.append(str(entry["name"])+" · "+str(entry["conclusion"]))
	elif key=="projects":
		title="Work projects"
		var a: Dictionary=s["active"]
		if not a.is_empty():
			info=[str(a["brief"]["name"]),"Stage %d/3 · quality %d · due %d" % [int(a["stage"])+1,int(a["quality"]),int(a["due"])]]
			rows.append(row("Continue project","1 time · choices may need extra time","resume",null,project_valid() and blocked()==""))
			rows.append(row("Withdraw","No bonus · reputation falls","withdraw",null,blocked()==""))
		elif GameState.has_job():
			var list: Array=briefs.get(str(p["job"]["id"]),[])
			for i in range(list.size()):
				var unseen := project_unseen(list[i])
				var why := "Already encountered · practice remains available" if not unseen else project_reason() if project_reason()!="" else "One project per year"
				rows.append(row(str(list[i]["name"]),"3 steps · 1 time each · "+why,"start",i,project_reason()=="" and unseen))
		else: info=["Get a job to start a project."]
		rows.append(row("Ask your mentor","1 time · duty goal or project feedback","mentor",null,GameState.has_job() and not used("mentor") and coaching().is_empty() and blocked()=="","🤝"))
	elif key=="growth": return growth.menu()
	elif key=="progress":
		title="Role & promotion"
		if GameState.has_job():
			var field := str(p["job"]["field"])
			var r := record(field)
			info=["%s skill %d/10 · samples %d · good projects %d" % [field,Market.skill(field),r["samples"],r["good"]],"Promotion: "+(promotion_reason() if promotion_reason()!="" else "Ready · an opening is still needed"),"Speciality: "+str(s["specialties"].get(field,"none"))]
			rows.append(nav("Speciality decisions","Colleagues, choices and later reviews","growth","🧭"))
			rows.append(row("Ask for promotion","1 time · once a year","promote",null,promotion_reason()=="" and not used("promotion") and blocked()==""))
			for kind in ["specialist","leadership"]: rows.append(row("Specialist" if kind=="specialist" else "Team lead route","Skill 4+ · two samples · 1 time · "+GameState.fmt_money(Actions._cost(800)),"specialise",kind,Market.skill(field)>=4 and int(r["samples"])>=2 and not used("specialty")))
		else: info=["Skills and qualifications stay with you between jobs."]
		rows.append({"name":"Field practice","icon":"🧰","sub":"Short courses · 1 time","menu":"market:root","on":int(p["age"])>=16})
		for field in s["certificates"]: info.append("Qualified: "+str(field))
	elif key=="training":
		title="Training"
		var t: Dictionary=s["training"]
		if not t.is_empty():
			info=["%s · units %d/2" % [t["field"],int(t["units"])],assessment_reason() if assessment_reason()!="" else "Assessment ready"]
			rows=[row("Practical unit","1 time · answer a job scenario","unit",null,int(t["units"])<2 and not used("unit:"+str(t["units"]))),row("Take assessment","2 time · pass two of three questions","assess",null,assessment_reason()==""),row("Leave training","Fees are not refunded","leave_training")]
		else:
			info=["Two practical units and a three-question assessment. Qualifications help applications; regulated jobs still need degrees and licences."]
			for field in programs:
				rows.append(nav(str(field),"Qualified" if s["certificates"].has(field) else "Choose a route","enrol:"+str(field),"🧰"))
	elif key.begins_with("enrol:"):
		var field := key.substr(6); title=field+" training"
		if programs.has(field):
			for kind in ["apprentice","retrain"]:
				if kind=="apprentice" and not programs[field]["apprentice"]: continue
				rows.append(row("Apprenticeship" if kind=="apprentice" else "Retraining","%d year(s) · 1 time now · %s" % [2 if kind=="apprentice" else 1,GameState.fmt_money(Actions._cost(1200 if kind=="apprentice" else 4500))],"enrol",[field,kind],int(p["age"])>=16 and s["training"].is_empty() and not s["certificates"].has(field)))
	elif key=="terms":
		title="Hours & contract"
		if GameState.has_job():
			var j: Dictionary=p["job"]
			info=["Pay factor ×%.2f · probation ends %d" % [pay_factor(),int(j.get("probation_end",GameState.year_now()))]]
			for kind in SCHEDULES: rows.append(row(SCHEDULES[kind][0],"Pay ×%.2f · performance %+.0f · stress %+.0f/year" % [SCHEDULES[kind][1],SCHEDULES[kind][2],SCHEDULES[kind][3]],"schedule",kind,not used("schedule")))
			for kind in TERMS: rows.append(row(TERMS[kind][0],"Pay ×%.2f · once a year" % TERMS[kind][1],"term",kind,not used("terms")))
			rows.append(row("Take leave","1 time · this year's pay −10% · rest at next birthday","leave",null,not used("leave")))
		else: info=["Get a job to choose hours and terms."]
	elif key=="loan_support": return Lending.support_menu()
	elif key.begins_with("loan_support:"): return Lending.support_menu(key.substr(13))
	elif key=="loan_history": return Lending.history_menu()
	elif key=="money":
		title="Money & recovery"
		var wages := int(int(p.get("job",{}).get("salary",0))*pay_factor()*(1-Places.tax()))
		var due := 0
		for debt in Lending.debts(): due+=Lending.scheduled_payment(debt,GameState.year_now()+1)
		info=["Cash %s · savings %s" % [GameState.fmt_money(int(p["money"])),GameState.fmt_money(int(p["savings"]))],"Expected wages %s/year · personal loan payments %s/year" % [GameState.fmt_money(wages),GameState.fmt_money(due)],"Living bills, changes in work and one-off costs still apply. Loans are paid after wages at birthdays."]
		rows.append(nav("Payment support","Hardship review and scheduled repayments","loan_support","🏦"))
		rows.append({"icon":"🏦","name":"Personal savings plan","sub":"Set one savings rate and a cash floor","menu":"balance:root","on":true})
		rows.append(row("Job search plan","2 time · interview practice and explain your gap","recovery",null,not GameState.has_job() and int(p["age"])>=18 and not used("recovery")))
		for i in range(Lending.debts().size()): rows.append(nav(str(Lending.LENDERS[str(Lending.debts()[i]["lender"])]["name"]),"Owe "+GameState.fmt_money(int(Lending.debts()[i]["left"])),"repay:"+str(i),"🏦"))
		if p.has("benefit"): info.append("Existing job-loss benefit: "+GameState.fmt_money(int(p["benefit"]["amt"]))+"/month while eligible")
	elif key.begins_with("repay:"):
		var index := int(key.substr(6)); title="Extra loan payment"
		if index>=0 and index<Lending.debts().size(): return {"icon":"🏦","title":title,"info":["Choose an amount. Annual payments keep their original schedule until the balance is cleared."],"rows":[],"wager":{"title":"Pay extra","minimum":1,"act":"employment:repay","arg":{"index":index,"amount":0},"amount_key":"amount"}}
	elif key=="history":
		title="Work record"
		for history in s["history"]:
			info.append("%d · %s · %s · quality %d · %s" % [int(history["year"]),history["name"],history["result"],int(history["quality"]),GameState.fmt_money(int(history["bonus"]))])
			for selected in history.get("choices",[]): info.append("  "+str(selected))
		for client in s["clients"]: info.append("%s · %s · trust %d · %d projects" % [client["name"],client["field"],int(client["trust"]),int(client["completed"])])
		if info.is_empty(): info=["Finish projects to build your record."]
	elif key.begins_with("client_record:"):
		title="Client record"
		var c := find_client(key.substr(14))
		if not c.is_empty():
			info=[str(c["name"])+" · "+str(c["field"]),"Company projects %d · current contact witnessed %d" % [int(c["completed"]),int(c.get("contact_completed",c["completed"]))]]
			for entry in c.get("meetings",[]): info.append("%d · %s · trust %d" % [int(entry["year"]),str(entry["choice"]),int(entry["trust"])])
	elif key=="clients":
		title="Continuing clients"
		for c in s["clients"]:
			if not c.has("contact"):
				var contact := GameState.create_npc("professional_contact",{"age":randi_range(25,65),"closeness":45})
				c["contact"]=FamilyChronicle.identity(GameState.npc(contact))
			var id := Journey.person(str(c["contact"]))
			var active: bool = id!="" and GameState.npc(id).get("alive",false)
			rows.append(row(str(c["name"]),"Trust %d · completed %d · %s" % [c["trust"],c["completed"],str(GameState.npc(id)["first"]) if active else "Contact unavailable"],"client",c["id"],active and not used("client:"+str(c["id"])) and GameState.has_job() and str(p["job"]["field"])==str(c["field"])))
			rows.append(nav("Client record", "Completed work and past reviews", "client_record:"+str(c["id"]), "📖"))
			if active: rows.append({"icon":Bonds.U_face(GameState.npc(id)),"name":GameState.full_name(id),"sub":"Client contact · "+Bonds.quick_line(id),"menu":"bond:"+id})
			else: rows.append(row("Introduce a new contact","1 time · reference resets","client_replace",c["id"],replacement_reason(str(c["id"]))=="","🤝"))
		info=["Meeting: 1 time. Joint review costs another time. References need two projects witnessed by this contact, trust 65+ and a successful request. Finite meeting scenes do not repeat in this life."]
	return {"icon":"💼","title":title,"rows":rows,"info":info}

func act(key: String, arg: Variant = null) -> void:
	match key:
		"duty": Depth.routine_duty(int(arg))
		"encounter": Depth.job_task(int(arg))
		"loan_support": if arg is Dictionary: Lending.request_support(str(arg["uid"]),str(arg["kind"]))
		"start": start_project(int(arg))
		"client": client_meeting(str(arg))
		"client_replace": replace_contact(str(arg))
		"growth": growth.start()
		"resume": resume_project()
		"withdraw": if blocked()=="": close_project("Withdrawn",false,false)
		"mentor": mentor()
		"promote": ask_promotion()
		"specialise": specialise(str(arg))
		"enrol": enrol(str(arg[0]),str(arg[1]))
		"unit": practical()
		"assess": assess()
		"leave_training": if blocked()=="": st()["training"]={}; st()["prompt"]={}
		"term": set_term(str(arg))
		"schedule": set_schedule(str(arg))
		"leave":
			if blocked()!="" or not GameState.has_job() or used("leave") or not GameState.spend_time(1): return
			mark("leave"); GameState.player["job"]["leave_year"]=GameState.year_now()
			EventEngine.push_info("🌿","Leave booked","Pay will be 10% lower at the next birthday; health, happiness and stress improve.")
		"repay": repay(int(arg["index"]),int(arg["amount"]))
		"recovery": recovery()

func replacement_reason(id: String) -> String:
	var why := blocked()
	if why!="": return why
	var c := find_client(id)
	if c.is_empty() or not GameState.has_job(): return "Needs a current client and job"
	if str(GameState.player["job"]["field"])!=str(c["field"]): return "Needs a job in this field"
	var person := Journey.person(str(c.get("contact","")))
	if person!="" and GameState.npc(person).get("alive",false): return "Contact is still available"
	if used("client_replace:"+id): return "Contact introduced this year"
	if int(GameState.player["time_left"])<1: return "Needs 1 time"
	return ""

func replace_contact(id: String) -> void:
	if replacement_reason(id)!="" or not GameState.spend_time(1): return
	var c := find_client(id)
	var old: String=str(c.get("contact",""))
	var person := GameState.create_npc("professional_contact",{"age":randi_range(25,65),"closeness":35})
	if not c.has("past_contacts"): c["past_contacts"]=[]
	if old!="": c["past_contacts"].append(old)
	c["contact"]=FamilyChronicle.identity(GameState.npc(person))
	c["reference"]=false
	c["contact_completed"]=0
	c["trust"]=clampf(50.0+(float(c["trust"])-50.0)*0.25,35,65)
	mark("client_replace:"+id)
	mark("client:"+id)
	FamilyChronicle.remember(person,"Introduced as the new contact for "+str(c["name"])+".")
	EventEngine.push_info("🤝","New client contact",GameState.full_name(person)+" handles the account. Company project history stays; personal trust starts nearer neutral. Earn a fresh reference from future work.")
