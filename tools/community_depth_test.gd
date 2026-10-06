extends Node
var checks := 0
var failures: Array=[]
var campus
func ok(value: bool,message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh(age: int) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=age; GameState.player["time_left"]=50; GameState.player["money"]=100000
	GameState.player["education"]["stage"]="none" if age<5 else "primary" if age<12 else "secondary" if age<18 else "graduated"
	if age==20:
		var major: Dictionary=ContentDB.majors.filter(func(m): return m["level"]=="bachelor")[0]
		GameState.player["education"]["uni"]={"major":major["id"],"level":"bachelor","year":1,"years":4,"performance":40,"scholarship":0}
	clear(); campus=Journey.modules["campus"]
func answer(index: int) -> Dictionary:
	var event := EventEngine.pop_next(); var spec: Dictionary=event["def"]["choices"][index]["outcomes"][0]["journey"].duplicate(true)
	EventEngine.resolve(event,index); clear(); return spec
func _ready() -> void:
	seed(8393); GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	var ages := {"preschool":3,"kindergarten":5,"elementary":8,"middle":12,"high":15,"college":20}
	var questions: Dictionary={}
	for level in ages:
		fresh(int(ages[level])); ok(campus.level()==level,"Incorrect school stage")
		campus.ensure_roster(); var roster: Array=campus.st()["roster"].duplicate()
		ok(campus.members().size()==13 and campus.members("classmate").size()==8 and campus.members("teacher").size()==3,"School people missing")
		ok(campus.members("principal").size()==1 and campus.members("school_nurse").size()==1,"School office is not an actual person")
		campus.ensure_roster(); ok(campus.st()["roster"]==roster,"Opening school rerolls people")
		GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear(); campus.ensure_roster()
		ok(campus.st()["roster"]==roster,"Reload loses school identities")
		for subject in campus.subjects():
			ok(subject["level"]==level and subject["questions"].size()>=2,"Subject has no appropriate assessments")
			var name := str(subject["subject"])
			for q in subject["questions"]: questions[q["q"]]=true
			var before: float=campus.performance(); var time := int(GameState.player["time_left"])
			campus.class_work(name,false); clear()
			ok(campus.performance()>before and GameState.player["time_left"]==time-1,"Class practice has no educational effort")
			time=int(GameState.player["time_left"]); campus.class_work(name,false); clear(); ok(GameState.player["time_left"]==time,"Repeated class gives free progress")
			campus.class_work(name,true)
			var prompt: Dictionary=Journey.state()["prompt"].duplicate(true)
			ok(prompt["args"]["scene"]["id"].begins_with("class."+str(level)),"Assessment is from wrong stage")
			var correct: int=prompt["args"]["order"].find(0); before=campus.performance()
			GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear(); Journey.restore()
			var spec := answer(correct); ok(campus.performance()>before,"Correct assessment has no grade effect")
			before=campus.performance(); Journey.outcome(spec); clear(); ok(campus.performance()==before,"Assessment rewards replay")
		var who: String=campus.members("principal")[0]
		ok(Bonds.menu(who)["bars"].size()==3 and Bonds.menu(who)["rows"].any(func(r): return r.get("menu","")=="bond:"+who+":profile"),"Compact person summary/profile missing")
		ok(Bonds.profile(who)["bars"].size()>=2,"Detailed trust/respect system removed")
		campus.yearly(); var count: int=campus.st()["history"].size(); campus.yearly(); ok(campus.st()["history"].size()==count,"School year recorded twice")
	ok(questions.size()==64,"New question pool duplicates text")
	fresh(10); campus.ensure_roster(); var old: Array=campus.st()["roster"].duplicate()
	GameState.player["education"]["performance"]=23; GameState.player["age"]=11; campus.ensure_roster()
	ok(campus.level()=="middle" and campus.performance()==23,"Moving to middle school resets weak grades")
	ok(campus.st()["roster"]!=old and old.all(func(uid): return Journey.person(str(uid))!=""),"Grade transition deletes past people")
	var dead: String=campus.members("principal")[0]; var uid := FamilyChronicle.identity(GameState.npc(dead)); GameState.npc(dead)["alive"]=false
	campus.ensure_roster(); ok(FamilyChronicle.identity(GameState.npc(campus.members("principal")[0]))!=uid,"School retains a deceased principal in office")
	# Actual named participants receive their own mood/stress changes and retain the chosen ending.
	var bank: Array=campus.situations.duplicate(true)
	for scene in bank:
		for choice in range(3):
			fresh(13); campus.ensure_roster(); campus.situations=[scene]
			var who: String=campus.members(str(scene["context"]))[0]
			var mood := float(GameState.npc(who).get("happiness",60)); campus.situation(who)
			var spec := answer(choice); var ending: Dictionary=campus.st()["decisions"][0]
			ok(ending["uid"]==FamilyChronicle.identity(GameState.npc(who)) and ending["choice"]==scene["choices"][choice],"Relationship situation lost actual person or choice")
			ok(is_equal_approx(float(GameState.npc(who)["happiness"]),clampf(mood+float(scene["npc"][choice].get("happiness",0)),0,100)),"NPC mood does not respond to decisions")
			var count: int=campus.st()["decisions"].size(); Journey.outcome(spec); clear(); ok(campus.st()["decisions"].size()==count,"Relationship ending replays")
	campus.situations=bank
	fresh(13); var snapshot: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
	campus.st()["attendance"]=100; seed(12); EventEngine._yearly_school(); var regular: float=campus.performance()
	GameState.from_dict(snapshot); campus.st()["attendance"]=50; seed(12); EventEngine._yearly_school()
	ok(campus.performance()<regular-4,"Attendance does not affect annual grades")
	clear(); var attendance := float(campus.st()["attendance"]); Actions.skip_class(); clear(); ok(float(campus.st()["attendance"])<attendance,"Skipping has no attendance cost")
	fresh(30); Actions.hire("appliance_repair"); clear()
	var duties := Employment.menu("duties"); ok(duties["bars"].size()==2 and duties["rows"].any(func(r): return r.get("name","")==Depth.job_tasks()[0]["name"]),"Job duties are generic or lack progress")
	var perf := float(GameState.player["job"]["perf"]); var cash := int(GameState.player["money"]); var time := int(GameState.player["time_left"])
	Depth.routine_duty(0); clear(); ok(float(GameState.player["job"]["perf"])>perf and GameState.player["money"]==cash and GameState.player["time_left"]==time-1,"Routine duty has no effort/performance or pays extra salary")
	perf=float(GameState.player["job"]["perf"]); Depth.routine_duty(0); clear(); ok(GameState.player["job"]["perf"]==perf,"Routine duty is a reward loop")
	for job in ContentDB.jobs: ok(Depth.jobs.get(str(job["id"]),[]).size()>=2,"A job lacks two distinct named duties")
	print("COMMUNITY DEPTH checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
