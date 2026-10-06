extends RefCounted
var h
var curriculum: Array=[]
var project_scenes: Dictionary={}
const PROJECTS := {"science":["Science exhibition","Tech",120],"arts":["School production","Arts",80],"community":["Community reading club","Care",0],"team":["School season","Sports",60],"leadership":["Student council promise","Politics",25]}
const BANDS := [[5,8,"First discoveries"],[9,11,"Making connections"],[12,14,"Independent thinking"],[15,17,"Preparing for adult life"]]
const QUESTIONS := [
	[["You have three blocks and add two. How many?",["Five","Two","Six"]],["A classmate cannot join your game. What helps?",["Ask what would make it accessible","Leave them out","Decide what they need without asking"]]],
	[["A plant grows toward a window. What is a fair experiment?",["Change light while keeping other conditions similar","Change everything at once","Choose the result first"]],["Your story uses a claim from a website. What should you do?",["Check and credit its source","Copy it without checking","Assume every page is accurate"]]],
	[["A chart's scale starts at 90. What should you check?",["Whether the scale exaggerates the difference","Only the tallest bar","The colour of the bars"]],["A team member is missing practice. What is a useful first step?",["Ask what support or schedule change is needed","Remove them immediately","Spread a rumour"]]],
	[["A course promises guaranteed wealth after a large fee. What matters?",["Check independent evidence, costs and alternatives","Borrow immediately","Trust the loudest testimonial"]],["Your council promised accessible activities. How do you show progress?",["Publish what was funded, delivered and still missing","Rename the promise","Count every speech as delivery"]]]
]
func _init(hub):
	h=hub
	curriculum=ContentDB._load_json("res://data/curriculum_scenes.json",[])
	project_scenes=ContentDB._load_json("res://data/school_projects.json",{})
func st() -> Dictionary: return h.section("school",{"project":{},"completed":[],"started":[],"subjects":{},"mentor":"","background":{},"alumni":false,"last_band":-1,"paused":{},"left":{}})
func band() -> int:
	var age := int(GameState.player["age"])
	for i in range(BANDS.size()):
		if age>=BANDS[i][0] and age<=BANDS[i][1]: return i
	return 3
func lesson(index: int) -> void:
	if not GameState.in_school() or index<0 or index>1 or h.blocked(5)!="" or h.used("curriculum:"+str(index)): return
	var b := band()
	var scene := Novelty.pick(curriculum.filter(func(q): return int(q["band"])==b))
	if scene.is_empty():
		h.done("📚","Curriculum complete","No new lesson is available in this age band. Subject practice and school projects remain open; no time was spent.")
		return
	if not h.pay("curriculum:"+str(index),1,0,5): return
	Novelty.note(scene)
	var order: Array=[0,1,2]; order.shuffle()
	h.decision("school","lesson",{"band":b,"index":index,"order":order,"scene":scene},str(scene["subject"])+" · "+str(BANDS[b][2]),scene["question"],order.map(func(i): return scene["answers"][i]))
func start(kind: String) -> void:
	if not PROJECTS.has(kind) or not GameState.in_school() or not st()["project"].is_empty(): return
	if kind=="leadership" and int(GameState.player["age"])<13: return
	if st()["started"].has(kind) or st()["completed"].any(func(record): return record["kind"]==kind): return
	if not h.pay("school_start",1,Actions._cost(int(PROJECTS[kind][2])),5): return
	st()["started"].append(kind)
	var teachers: Array=h.modules["campus"].members("teacher")
	var teacher := str(teachers[0]) if not teachers.is_empty() else GameState.create_npc("teacher",{"age":randi_range(30,60),"closeness":45})
	st()["mentor"]=FamilyChronicle.identity(GameState.npc(teacher))
	st()["project"]={"kind":kind,"stage":0,"started":GameState.year_now(),"last":GameState.year_now()-1,"quality":35.0,"promise":-1,"peer":"","choices":[]}
	var peers: Array=h.modules["campus"].members("classmate")
	var peer := str(peers[0]) if not peers.is_empty() else GameState.create_npc("friend",{"age":int(GameState.player["age"]),"closeness":55})
	st()["project"]["peer"]=FamilyChronicle.identity(GameState.npc(peer))
	h.done("🏫","A longer project",str(PROJECTS[kind][0])+" will take at least two years. Work through planning, collaboration and presentation; the record follows me into adulthood.")
func archive(paused: bool) -> void:
	var p: Dictionary=st()["project"]
	if p.is_empty() or h.blocked(5)!="": return
	var record := p.duplicate(true); record["mentor"]=st()["mentor"]; record["closed_year"]=GameState.year_now()
	st()["paused" if paused else "left"][str(p["kind"])]=record
	st()["project"]={}
	var who: String=h.person(str(p.get("peer","")))
	if who!="" and GameState.npc(who).get("alive",false): FamilyChronicle.remember(who,"We paused the school project." if paused else "We closed the unfinished school project.")
	h.done("📁","Project paused" if paused else "Project closed","Choices and paid costs stay recorded. No completion award."+(" Resume with 1 time." if paused else ""))
func resume(kind: String) -> void:
	if not st()["paused"].has(kind) or not st()["project"].is_empty(): return
	var p: Dictionary=st()["paused"][kind]
	if not GameState.in_school() and (int(GameState.player["age"])>20 or int(p["stage"])!=2): return
	if not h.pay("school_resume:"+kind,1,0,5): return
	st()["project"]=p.duplicate(true); st()["mentor"]=str(p.get("mentor","")); st()["paused"].erase(kind)
	if not st()["project"].has("returns"): st()["project"]["returns"]=[]
	st()["project"]["returns"].append(GameState.year_now())
	h.done("📁","Project resumed","Earlier choices, quality and yearly limits stay. Complete the remaining stages to earn evidence.")
func step() -> void:
	var p: Dictionary=st()["project"]
	if p.is_empty() or (not GameState.in_school() and (int(GameState.player["age"])>20 or int(p["stage"])!=2)) or int(p["last"])==GameState.year_now() or (int(p["stage"])==2 and GameState.year_now()<int(p["started"])+2): return
	if not h.pay("school_step",1,0,5): return
	ensure_team(p)
	var stage := int(p["stage"]); var kind := str(p["kind"])
	var scene: Array=project_scenes[kind][stage]
	var peer: String=h.person(str(p.get("peer","")))
	var context: String=str(scene[0])+(("\nWorking with "+str(GameState.npc(peer)["first"])+".") if peer!="" else "")
	var teacher: String=h.person(str(st()["mentor"]))
	if teacher!="": context+=" Mentor · "+GameState.full_name(teacher)
	h.decision("school","project",{"kind":kind,"stage":stage,"gains":scene[2],"stress":scene[3]},PROJECTS[kind][0]+" · "+str(stage+1)+"/3",context,scene[1])
func ensure_team(p: Dictionary) -> void:
	if not p.has("team_changes"): p["team_changes"]=[]
	for role in ["mentor","peer"]:
		var old := str(st()["mentor"] if role=="mentor" else p.get("peer",""))
		var who: String=h.person(old)
		if who!="" and GameState.npc(who).get("alive",false): continue
		var candidates: Array=h.modules["campus"].members("teacher" if role=="mentor" else "classmate")
		who=str(candidates[0]) if not candidates.is_empty() else GameState.create_npc("teacher" if role=="mentor" else "friend",{"age":randi_range(30,60) if role=="mentor" else int(GameState.player["age"]),"closeness":45 if role=="mentor" else 50})
		var uid := FamilyChronicle.identity(GameState.npc(who))
		p["team_changes"].append({"year":GameState.year_now(),"role":role,"from":old,"to":uid})
		if role=="mentor": st()["mentor"]=uid
		else: p["peer"]=uid
func resolve(op: String, args: Dictionary, answer: int) -> void:
	if op=="lesson":
		var good := int(args["order"][answer])==0; var b := int(args["band"]); var index := int(args["index"])
		st()["subjects"][str(args.get("scene",{}).get("subject",str(b)+":"+str(index)))]=int(st()["subjects"].get(str(args.get("scene",{}).get("subject",str(b)+":"+str(index))),0))+(1 if good else 0)
		var connection: float=h.modules["pathways"].support(lesson_field(str(args.get("scene",{}).get("subject",""))))
		var library := mini(3,int(h.modules["places"].institution()["library"]))
		var gain := (1.0+Aptitude.score("education")/50.0+library*0.15) if good else 0.25
		var circumstances: Dictionary=st()["background"].get(str(BANDS[b][0]),{})
		if good: gain+=connection*5.0
		if good and float(circumstances.get("support",50))>=60: gain+=0.15
		GameState.apply_effects({"school":gain,"smarts":1 if good else 0,"stress":1})
		Depth.school_record("curriculum",1.0 if good else 0.2)
		h.done("📚","Lesson feedback",str(args.get("scene",{}).get("why",QUESTIONS[b][index][1][0]))+" School performance %+.1f; readiness affects how well learning is retained." % gain)
	elif op=="project":
		var p: Dictionary=st()["project"]
		if p.is_empty() or str(p["kind"])!=str(args["kind"]) or int(p["stage"])!=int(args["stage"]): return
		var stage := int(p["stage"]); var leadership: bool = p["kind"]=="leadership"
		var good: bool = answer==0 or (leadership and stage==0)
		if leadership and stage==0: p["promise"]=answer
		var quality_gain: float = (12+Aptitude.score("education")/12.0 if good else -5)
		if args.has("gains"):
			quality_gain=float(args["gains"][answer])*0.55+Aptitude.score("education")*0.11+mini(6,Market.skill(str(PROJECTS[p["kind"]][1])))*0.6
			GameState.apply_effects({"stress":args["stress"][answer]})
			good=true
		if not p.has("choices"): p["choices"]=[]
		p["choices"].append({"year":GameState.year_now(),"answer":project_scenes[p["kind"]][stage][1][answer]})
		var peer: String=h.person(str(p.get("peer","")))
		if peer!="":
			BondStats.apply(peer,{"trust":2 if quality_gain>0 else -2})
			FamilyChronicle.remember(peer,"School project: "+str(p["choices"][-1]["answer"])+".")
		p["quality"]=clampf(float(p["quality"])+quality_gain,0,100)
		p["last"]=GameState.year_now(); p["stage"]=stage+1
		var mentor: String=h.person(str(st()["mentor"]))
		if mentor!="" and good: BondStats.apply(mentor,{"respect":2,"trust":2})
		if stage<2: h.done("📁","Project progress","Quality %d/100. Continue next year; consistent work matters." % p["quality"]); return
		var quality := float(p["quality"])
		var entry := {"kind":p["kind"],"field":PROJECTS[p["kind"]][1],"quality":quality,"year":GameState.year_now(),"promise":p["promise"],"mentor":st()["mentor"],"peer":p.get("peer",""),"choices":p.get("choices",[]).duplicate(true),"team_changes":p.get("team_changes",[]).duplicate(true),"returns":p.get("returns",[]).duplicate()}
		h.modules["pathways"].record("school",str(p["kind"])+":"+str(p["started"]),str(entry["field"]),quality,true,str(entry["peer"]))
		st()["completed"].append(entry); st()["project"]={}
		if st()["completed"].size()>12: st()["completed"].pop_front()
		Depth.school_record("project:"+str(entry["kind"]),quality/100.0)
		if entry["kind"]=="leadership" and quality>=65:
			var benefit: String=["accessible clubs","study support","team facilities"][int(entry["promise"])]
			st()["subjects"]["funded:"+benefit]=GameState.year_now()
			GameState.apply_effects({"happiness":2,"school":2 if int(entry["promise"])==1 else 0,"health":1 if int(entry["promise"])==2 else 0})
			h.modules["places"].contribution(2)
			h.note("Council promise delivered",benefit.capitalize()+" was delivered, not just promised.")
		if quality>=65: Market.learn(str(entry["field"]),1); GameState.add_milestone(int(GameState.player["age"]),"completed "+str(PROJECTS[entry["kind"]][0]))
		h.done("🏫","Completed project","Quality %d/100. The work is in my portfolio. %s" % [quality,"A future relevant application can use it." if quality>=65 else "It is experience, even without a prize."],{"happiness":4,"school":2 if quality>=65 else 0})
func career_bonus(field: String) -> float:
	var total := 0.0
	for p in st()["completed"]:
		if p["field"]==field and float(p["quality"])>=65: total+=0.02
	return minf(0.06,total)
func yearly() -> void:
	if Lives.separate(): return
	var age := int(GameState.player["age"])
	if age in [5,9,12,15] and int(st()["last_band"])!=age:
		st()["last_band"]=age
		var parents := GameState.npcs_with("mother")+GameState.npcs_with("father")
		var resources := 0
		for id in parents: resources+=int(GameState.npc(str(id)).get("money",0))
		st()["background"][str(age)]={"resources":resources,"support":GameState.stat("happiness"),"year":GameState.year_now()}
		h.note("New school chapter",str(BANDS[band()][2])+". Free community projects remain available alongside paid clubs.")
	if age>=18 and not st()["alumni"]:
		st()["alumni"]=true
		if not st()["project"].is_empty():
			var p: Dictionary=st()["project"]
			h.note("School work carried forward","The unfinished "+str(PROJECTS[p["kind"]][0])+" remains unfinished in my history.")
		if not st()["completed"].is_empty(): h.note("School pathways","My completed school projects now help relevant applications and remain in my record.")
func menu(key: String) -> Dictionary:
	if key=="clubs": return Depth.club_work.records()
	if key=="cliques": return Depth.clique_life.records()
	var rows: Array=[]; var info: Array=[]
	if key in ["","root"]:
		rows=[h.nav("school","Lessons & curriculum","Age-appropriate lessons and schoolwork","curriculum"),h.nav("school","Projects & portfolio","Longer work, paused plans and achievements","projects"),h.nav("school","School records","Projects, groups and future pathways","records")]
		var age := int(GameState.player["age"])
		info=["School options open at age 5." if age<5 else "Schoolwork stays with you after graduation." if not GameState.in_school() else BANDS[band()][2]+" · study readiness %d/100" % Aptitude.score("education")]
		if not st()["project"].is_empty():
			var active: Dictionary=st()["project"]
			info.append(str(PROJECTS[active["kind"]][0])+" · stage %d/3" % (int(active["stage"])+1))
		return {"icon":"🏫","title":"School plans","info":info,"rows":rows}
	if key=="curriculum":
		if GameState.in_school():
			info=[BANDS[band()][2]+" · readiness %d/100" % Aptitude.score("education")]
			for i in range(2): rows.append(h.row("school","Lesson" if i==0 else "Another lesson","1 time · once a year · feedback follows","lesson",i,not h.used("curriculum:"+str(i))))
			rows.append(h.nav("campus","Classes & assessments","Subjects for this grade","classes"))
		else:
			info=["Lessons are available during school. Projects and completed work stay in your record."]
			rows.append(h.nav("campus","School record","Earlier grades, people and learning","record"))
		return {"icon":"📚","title":"Lessons & curriculum","info":info,"rows":rows}
	if key=="projects":
		if GameState.in_school():
			if st()["project"].is_empty():
				for kind in PROJECTS:
					var played: bool=st()["started"].has(kind) or st()["completed"].any(func(record): return record["kind"]==kind)
					var old_enough: bool=kind!="leadership" or int(GameState.player["age"])>=13
					rows.append(h.row("school",PROJECTS[kind][0],"Age 13+" if not old_enough else "Already undertaken" if played else "2+ years · "+GameState.fmt_money(Actions._cost(int(PROJECTS[kind][2])))+" to start","start",kind,not played and old_enough))
			else:
				var p: Dictionary=st()["project"]
				info=[str(PROJECTS[p["kind"]][0])+" · stage %d/3 · quality %d" % [int(p["stage"])+1,p["quality"]]]
				rows.append(h.row("school","Continue project","1 time · one step each year","step",null,int(p["last"])!=GameState.year_now()))
				rows.append(h.row("school","Pause project","Keep choices and quality; resume with 1 time","pause"))
				rows.append(h.row("school","Leave project","Keep the history; no completion award","quit"))
		else:
			info=["School projects begin at age 5." if int(GameState.player["age"])<5 else "Completed work stays in your record and can support relevant applications."]
			if not st()["project"].is_empty():
				rows.append(h.row("school","Present unfinished work","Final stage · age 18–20 · 1 time","step",null,int(st()["project"]["stage"])==2 and int(GameState.player["age"])<=20))
				rows.append(h.row("school","Close unfinished work","Keep participation; no completion reward","quit"))
		for kind in st()["paused"]:
			var p: Dictionary=st()["paused"][kind]
			rows.append(h.row("school","Resume "+str(PROJECTS[kind][0]),"1 time · earlier work retained","resume",kind,st()["project"].is_empty() and (GameState.in_school() or int(GameState.player["age"])<=20 and int(p["stage"])==2)))
			info.append(str(PROJECTS[kind][0])+" · paused at stage "+str(int(p["stage"])+1))
		return {"icon":"📁","title":"Projects & portfolio","info":info,"rows":rows}
	if key=="records":
		rows=[h.nav("pathways","Connections","Named people and future follow-ups"),h.nav("school","Club record","Choices, classmates and results","clubs"),h.nav("school","Clique record","Group decisions and memories","cliques"),h.nav("seasons","Teams & seasons","Selection and lasting participation"),h.nav("learning","Learning & placements","Courses and supervised experience"),h.nav("campus","School record","Grades, attendance and classroom people","record")]
		for kind in st()["left"]:
			var p: Dictionary=st()["left"][kind]
			info.append(str(PROJECTS[kind][0])+" · closed · quality "+str(int(p["quality"])))
		for p in st()["completed"]: info.append("%s · quality %d · %s" % [PROJECTS[p["kind"]][0],p["quality"],p["field"]])
		return {"icon":"📖","title":"School records","info":info,"rows":rows}
	return {"icon":"🏫","title":"School plans","info":[],"rows":[]}
func act(key: String, arg: Variant) -> void:
	match key:
		"lesson": lesson(int(arg))
		"start": start(str(arg))
		"step": step()
		"pause": archive(true)
		"resume": resume(str(arg))
		"quit": archive(false)

func lesson_field(subject: String) -> String:
	if subject in ["Algebra","Biology","Chemistry","Data","Discovery","Ecology","Environment","Experiment","Fractions","Geometry","Measuring","Nature","Numbers","Patterns","Physics","Probability","Research","Science","Statistics","Units"]: return "Tech"
	if subject in ["Design","Literature","Media","Music","Reading","Sources","Writing"]: return "Arts"
	if subject in ["Accessibility","Education","Health","Listening","Safety"]: return "Care"
	if subject in ["Arguments","Civics","Ethics","Evidence","Fairness","History","Public speaking"]: return "Politics"
	return "General"
