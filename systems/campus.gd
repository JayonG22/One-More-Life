extends RefCounted
var h
var classes: Array=[]
var situations: Array=[]
const LEVELS := {"preschool":["Preschool",3,2],"kindergarten":["Kindergarten",5,1],"elementary":["Elementary school",6,5],"middle":["Middle school",11,3],"high":["High school",14,4],"college":["College",18,4]}
func _init(hub):
	h=hub; classes=ContentDB._load_json("res://data/grade_classes.json",[]); situations=ContentDB._load_json("res://data/community_situations.json",[])
func level() -> String:
	if GameState.in_university(): return "college"
	var age := int(GameState.player["age"])
	if age<3 or age>=18 or str(GameState.player["education"]["stage"]) in ["dropout","graduated"]: return ""
	if age<5: return "preschool"
	if age==5: return "kindergarten"
	if age<11: return "elementary"
	if age<14: return "middle"
	return "high"
func st() -> Dictionary:
	var e: Dictionary=GameState.player["education"]
	if not e.has("community"): e["community"]={"level":"","roster":[],"history":[],"attendance":100.0,"last_year":-1,"subject_work":{},"decisions":[]}
	return e["community"]
func title() -> String:
	var band := level()
	if band=="": return "School record"
	if band=="college": return str(ContentDB.major(GameState.player["education"]["uni"]["major"]).get("name","College"))
	return grade_name()
func grade_name() -> String:
	var band := level(); var age := int(GameState.player["age"])
	if band=="preschool": return "Preschool · year "+str(age-2)
	if band=="kindergarten": return "Kindergarten"
	if band in ["elementary","middle","high"]: return str(LEVELS[band][0])+" · Grade "+str(age-5)
	return "School record"
func ensure_roster() -> void:
	var band := level()
	if band=="" or Lives.separate() or GameState.in_prison(): return
	var s := st(); var key := band
	if band!="college": key+="/"+grade_name()
	if band=="college":
		var u: Dictionary=GameState.player["education"]["uni"]
		if not u.has("campus_id"): u["campus_id"]=GameState.year_now()-int(u["year"])
		key+="/"+str(int(u["campus_id"]))
	if str(s["level"])!=key:
		# Upgrade older band-only saves in place. From the next grade onward, each
		# classroom gets its own people and prior classmates remain in the world.
		if str(s["level"])!=band:
			var retained_staff: Array=[]
			var same_school := band!="college" and str(s["level"]).get_slice("/",0)==band
			for uid in s["roster"]:
				var old: String=h.person(str(uid))
				if old=="": continue
				var n := GameState.npc(old)
				if same_school and str(n["relation"]) in ["principal","school_nurse"] and n.get("alive",false):
					if retained_staff.is_empty(): retained_staff=["",""]
					retained_staff[0 if n["relation"]=="principal" else 1]=uid
					continue
				if str(n["relation"])=="classmate": n["relation"]="friend" if float(n["closeness"])>=65 else "former_classmate"
				elif str(n["relation"]) in ["teacher","principal","school_nurse"]: n["relation"]="former_teacher"
			s["roster"]=retained_staff
		s["level"]=key
	var roles: Array=["principal","school_nurse","teacher","teacher","teacher"]
	for i in range(8): roles.append("classmate")
	for i in range(roles.size()):
		var who: String=h.person(str(s["roster"][i])) if i<s["roster"].size() else ""
		if who!="" and GameState.npc(who).get("alive",false):
			GameState.npc(who)["campus"]=key
			continue
		var role := str(roles[i]); var age := int(GameState.player["age"])
		who=GameState.create_npc(role,{"age":age if role=="classmate" else randi_range(28,60),"closeness":randi_range(35,60)})
		var n := GameState.npc(who); n["campus"]=key; n["school_role"]=role
		if role!="classmate": n["job"]={"title":{"principal":"Principal","teacher":"Teacher","school_nurse":"School nurse"}[role],"key":"teacher" if role!="school_nurse" else "nurse"}
		var uid := FamilyChronicle.identity(n)
		if i<s["roster"].size(): s["roster"][i]=uid
		else: s["roster"].append(uid)
func members(role: String="") -> Array:
	ensure_roster(); var out: Array=[]
	for uid in st()["roster"]:
		var who: String=h.person(str(uid))
		if who!="" and GameState.npc(who).get("alive",false) and (role=="" or GameState.npc(who).get("school_role","")==role): out.append(who)
	return out
func homeroom_teacher() -> String:
	var teachers: Array=members("teacher")
	if teachers.is_empty(): return ""
	var seed := FamilyChronicle.identity(GameState.player)+":"+str(st()["level"])
	return str(teachers[absi(seed.hash())%teachers.size()])
func performance() -> float:
	return float(GameState.player["education"]["uni"]["performance"]) if GameState.in_university() else float(GameState.player["education"]["performance"])
func progress() -> float:
	var band := level()
	if band=="": return 0
	var elapsed := float(int(GameState.player["age"])-int(LEVELS[band][1])); var length := float(LEVELS[band][2])
	if band=="college":
		elapsed=float(GameState.player["education"]["uni"]["year"]); length=maxf(1,float(GameState.player["education"]["uni"]["years"]))
	var readiness := (performance()*0.7+float(st()["attendance"])*0.3)/100.0
	return clampf((elapsed+readiness)/length*100.0,0,100)
func bars() -> Array:
	return [{"name":"Stage progress","value":progress()},{"name":"Academic performance","value":performance()},{"name":"Attendance","value":st()["attendance"]}]
func subjects() -> Array: return classes.filter(func(c): return c["level"]==level())
func revision_work() -> Dictionary:
	if not st().has("revisions"): st()["revisions"]={}
	return st()["revisions"]
func subject_progress(subject: String) -> float:
	return float(st()["subject_work"].get(level()+":"+subject,0.0))
func review(subject: String) -> void:
	var key := level()+":"+subject
	if not revision_work().has(key): return
	if not h.pay("class_review:"+key,1,0,3): return
	var teachers: Array=members("teacher")
	if teachers.is_empty(): return
	var teacher := str(teachers[absi(subject.hash())%teachers.size()])
	var lesson: Dictionary=revision_work()[key]
	var gain := 0.5+Aptitude.score("education")/150.0
	GameState.apply_effects({"school":gain,"stress":1})
	GameState.player["education"]["studied"]=true
	st()["subject_work"][key]=minf(100,subject_progress(subject)+2.0)
	BondStats.apply(teacher,{"respect":1,"trust":1})
	record(subject,"Reviewed an earlier mistake",teacher,str(lesson["why"]))
	revision_work().erase(key)
	h.done("📚","Revision completed",str(lesson["why"])+" Performance +%.1f. Class progress +2; this correction cannot be claimed again." % gain)
func class_work(subject: String, assessment: bool) -> void:
	var pool := subjects().filter(func(c): return str(c["subject"])==subject)
	if pool.is_empty(): return
	if assessment and not pool[0]["questions"].any(func(q): return Novelty.eligible(q)):
		h.done("📚","Assessment bank complete","Try another subject or class practice. No time spent."); return
	if not h.pay("class:"+level()+":"+subject+str(assessment),1,0,3): return
	ensure_roster(); var teachers: Array=members("teacher"); var teacher: String=teachers[absi(subject.hash())%teachers.size()]
	if not assessment:
		var gain := 0.5+Aptitude.score("education")/80.0
		GameState.apply_effects({"school":gain,"stress":1}); st()["attendance"]=minf(100,float(st()["attendance"])+2)
		st()["subject_work"][level()+":"+subject]=minf(100,subject_progress(subject)+1.0+Aptitude.score("education")/80.0)
		GameState.player["education"]["studied"]=true
		BondStats.apply(teacher,{"respect":1}); GameState.npc(teacher)["happiness"]=minf(100,float(GameState.npc(teacher).get("happiness",60))+1)
		record(subject,"Class practice",teacher,"Practised "+str(pool[0]["practice"])+".")
		h.done(str(pool[0]["icon"]),subject,"Practised "+str(pool[0]["practice"])+" with "+GameState.full_name(teacher)+". Performance +%.1f." % gain); return
	var questions: Array=pool[0]["questions"]
	var scene := Novelty.pick(questions)
	if scene.is_empty():
		h.done("📚","Assessment bank complete","New authored questions for this subject are complete. Class practice and other subjects remain available; no grade reward."); return
	Novelty.note(scene)
	var order: Array=[0,1,2]; order.shuffle()
	h.decision("campus","class",{"subject":subject,"scene":scene,"order":order,"teacher":FamilyChronicle.identity(GameState.npc(teacher))},title()+" · "+subject,str(scene["q"])+"\nTeacher · "+GameState.full_name(teacher),order.map(func(i): return scene["a"][i]),str(pool[0]["icon"]))
func record(task: String, choice: String, who: String, ending: String) -> void:
	st()["decisions"].push_front({"year":GameState.year_now(),"level":level(),"task":task,"choice":choice,"uid":FamilyChronicle.identity(GameState.npc(who)) if who!="" else "","name":GameState.full_name(who) if who!="" else "","ending":ending})
	if st()["decisions"].size()>80: st()["decisions"].resize(80)
func situation(who: String) -> void:
	if not members().has(who): return
	var role := str(GameState.npc(who).get("school_role","classmate"))
	var school_level := level()
	var age := int(GameState.player["age"])
	var pool := situations.filter(func(s):
		var levels: Array = Array(s.get("levels", []))
		return (
			str(s.get("context", "")) == role
			and age >= int(s.get("min_age", 3))
			and age <= int(s.get("max_age", 120))
			and (levels.is_empty() or levels.has(school_level))
		)
	)
	var scene := Novelty.pick(pool)
	if scene.is_empty(): h.done("💬","No new situation","Their profile, conversations and shared activities remain available. No time spent."); return
	if not h.pay("school_person:"+FamilyChronicle.identity(GameState.npc(who)),1,0,3): return
	Novelty.note(scene)
	h.decision("campus","person",{"uid":FamilyChronicle.identity(GameState.npc(who)),"scene":scene},GameState.full_name(who)+" · "+str(scene["title"]),str(scene["text"]).replace("{name}",GameState.npc(who)["first"])+"\n"+Bonds.quick_line(who),scene["choices"])
func resolve(op: String,args: Dictionary,answer: int) -> void:
	if answer not in [0,1,2]: return
	var who: String=h.person(str(args.get("teacher",args.get("uid",""))))
	if who=="" or not GameState.npc(who).get("alive",false): h.done("📁","Contact ended","The person is no longer available. No reward."); return
	if op=="class":
		var scene: Dictionary=args["scene"]; var right := int(args["order"][answer])==0
		var gain := (1.0+Aptitude.score("education")/50.0) if right else -1.0
		GameState.apply_effects({"school":gain,"stress":1}); GameState.player["education"]["studied"]=true
		var key := level()+":"+str(args["subject"])
		st()["subject_work"][key]=clampf(float(st()["subject_work"].get(key,0))+(4 if right else 1),0,100)
		if not right: revision_work()[key]={"q":scene["q"],"why":scene["why"],"year":GameState.year_now()}
		BondStats.apply(who,{"respect":1 if right else 0})
		record(str(args["subject"]),str(scene["a"][int(args["order"][answer])]),who,"Correct" if right else "Needs revision")
		h.done("📚","Assessment feedback",str(scene["why"])+" Performance %+.1f. Earlier learning remains in your record." % gain)
	elif op=="person":
		var scene: Dictionary=args["scene"]; var n := GameState.npc(who)
		BondStats.apply(who,scene["bonds"][answer])
		for stat in scene["npc"][answer]: n[stat]=clampf(float(n.get(stat,50))+float(scene["npc"][answer][stat]),0,100)
		GameState.apply_effects(scene["player"][answer]); st()["attendance"]=clampf(float(st()["attendance"])+float(scene.get("attendance",[0,0,0])[answer]),0,100)
		var ending := str(scene["ends"][answer]).replace("{name}",str(n["first"]))
		FamilyChronicle.remember(who,str(scene["choices"][answer])+". "+ending,"bad" if answer==2 else "good")
		record(str(scene["title"]),str(scene["choices"][answer]),who,ending)
		var pathways: Array = Array(scene.get("pathways", []))
		if answer < pathways.size() and pathways[answer] is Dictionary:
			var pathway: Dictionary = pathways[answer]
			if not pathway.is_empty():
				Journey.modules["pathways"].record("school",str(scene["id"]),str(pathway.get("field","General")),float(pathway.get("quality",60.0)),bool(pathway.get("honest",true)),who)
		h.done("👥",str(scene["title"]),ending+"\n"+Bonds.quick_line(who))
func yearly() -> void:
	if Lives.separate() or GameState.in_prison() or level()=="": return
	var year := GameState.year_now(); var s := st()
	if int(s["last_year"])==year: return
	s["last_year"]=year
	s["history"].push_front({"year":year,"age":GameState.player["age"],"level":level(),"grade":title(),"performance":performance(),"attendance":s["attendance"],"progress":progress()})
	if s["history"].size()>60: s["history"].resize(60)
	s["attendance"]=100.0; ensure_roster()
func menu(key: String) -> Dictionary:
	var rows: Array=[]; var info: Array=[]
	if key=="record":
		for r in st()["history"]: info.append("%d · %s · performance %d%% · attendance %d%%" % [r["year"],str(r.get("grade",LEVELS[str(r["level"])][0])),r["performance"],r["attendance"]])
		for r in st()["decisions"]: info.append(str(r["year"])+" · "+str(r["task"])+" · "+str(r["name"])+" · "+str(r["choice"])+" · "+str(r["ending"]))
		if info.is_empty(): info=["School grades and decisions will appear here."]
		return {"icon":"📖","title":"School record","info":info,"rows":[]}
	if level()=="": return {"icon":"🏫","title":"School community","info":["Not currently enrolled."],"rows":[h.nav("campus","School record","Earlier grades, people and learning","record")]}
	ensure_roster()
	if key in ["classroom","people"]:
		info=[title()+" · current classroom","Stage progress %d%% · attendance %d%%" % [int(progress()),int(st()["attendance"])]]
		var teacher := homeroom_teacher()
		if teacher!="": rows.append({"icon":Bonds.U_face(GameState.npc(teacher)),"name":GameState.full_name(teacher)+" · Homeroom teacher","sub":Bonds.quick_line(teacher),"menu":"bond:"+teacher})
		for who in members("classmate"): rows.append({"icon":Bonds.U_face(GameState.npc(who)),"name":GameState.full_name(who),"sub":Bonds.quick_line(who),"menu":"bond:"+str(who)})
	elif key=="staff":
		info=[title()+" · teachers and student support"]
		for role in ["principal","school_nurse","teacher"]:
			for who in members(role): rows.append({"icon":Bonds.U_face(GameState.npc(who)),"name":GameState.full_name(who)+" · "+str(GameState.npc(who).get("job",{}).get("title",role.capitalize())),"sub":Bonds.quick_line(who),"menu":"bond:"+who})
	elif key=="activities":
		var social: Dictionary=Daily._ss()
		info=["Popularity %d%% · %d clubs" % [int(social["popularity"]),social["clubs"].size()]]
		if str(social["sport"])!="": info.append("Team · "+str(social["sport"]))
		rows=[{"icon":"🎭","name":"Clubs & showcases","sub":"Join groups and build something together","menu":"daily:clubs","on":int(GameState.player["age"])>=5},{"icon":"👥","name":"Cliques & classmates","sub":"Peer groups and changing relationships","menu":"daily:cliques","on":int(GameState.player["age"])>=11},{"icon":"🏅","name":"School sports","sub":"Teams, tryouts and seasons","menu":"daily:sports","on":int(GameState.player["age"])>=6},{"icon":"🎪","name":"School challenges","sub":"Projects, talent and team events","menu":"daily:depth","on":GameState.in_school()},{"icon":"📅","name":"School day & events","sub":"Leadership, staff visits and special days","menu":"daily:school","on":GameState.in_school()}]
	elif key=="day":
		info=[title()+" · school choices have lasting effects."]
		rows=[{"icon":"🧑‍🏫","name":"Visit the principal","sub":"Ask for help or discuss a problem","act":"daily:principal","on":GameState.in_school()},{"icon":"🩹","name":"Visit the school nurse","sub":"Get care or take a break","act":"daily:nurse","on":GameState.in_school()}]
		if int(GameState.player["age"])>=10: rows.append({"icon":"📝","name":"Cheat on a test","sub":"Risk your grade and teacher trust","act":"daily:cheat"})
		if int(GameState.player["age"])>=10: rows.append({"icon":"🎤","name":"Enter the talent show","sub":"One chance to perform","act":"daily:talent"})
		if int(GameState.player["age"])>=13 and int(GameState.player["age"])<=18: rows.append({"icon":"🗳️","name":"Run for class president","sub":"Campaign, make promises and lead","act":"daily:president"})
		if int(GameState.player["age"])>=13: rows.append({"icon":"💃","name":"Go to the school dance","sub":"Invite someone or go with friends","act":"daily:dance"})
		if int(GameState.player["age"])>=16: rows.append({"icon":"👑","name":"Prom","sub":"One school prom","act":"daily:prom","on":not Daily._ss()["prom"]})
	elif key=="classes":
		for c in subjects(): rows.append(h.nav("campus",str(c["subject"]),"Class progress %d%% · %s" % [int(subject_progress(str(c["subject"]))),str(c["practice"])],"class/"+str(c["subject"])))
	elif key.begins_with("class/"):
		var subject := key.substr(6)
		info=["Practice and assessments build this class record. Overall grades carry into the next stage."]
		rows=[h.row("campus","Attend "+subject,"1 time · practice and attendance","practice",subject,not h.used("class:"+level()+":"+subject+"false")),h.row("campus",subject+" assessment","1 time · feedback and grades","assess",subject,not h.used("class:"+level()+":"+subject+"true"))]
		var revision_key := level()+":"+subject
		if revision_work().has(revision_key):
			info.append("Needs revision · "+str(revision_work()[revision_key]["q"]))
			rows.append(h.row("campus","Review my mistake","1 time · teacher support · modest grade gain","review",subject,not h.used("class_review:"+revision_key)))
	else:
		rows=[h.nav("campus","Classroom","Your grade, teacher and classmates","classroom"),h.nav("campus","Classes & assessments","Subjects for this school stage","classes"),h.nav("campus","School life","Clubs, sports, events and daily choices","activities"),h.nav("school","Lessons & projects","Study, build a portfolio and keep schoolwork","root"),h.nav("campus","Staff & support","Principal, teachers and student support","staff"),h.nav("campus","School record","Earlier grades, attendance and decisions","record")]
		info=[title()+" · grades carry forward between stages. Attendance affects yearly performance."]
	var result := {"icon":"🏫","title":title(),"info":info,"rows":rows}
	if key in ["","root"]: result["bars"]=bars()
	elif key.begins_with("class/"): result["bars"]=[{"name":"Class progress","value":subject_progress(key.substr(6))}]
	return result
func act(key: String,arg: Variant) -> void:
	if key=="practice": class_work(str(arg),false)
	elif key=="assess": class_work(str(arg),true)
	elif key=="person": situation(str(arg))
	elif key=="review": review(str(arg))
