extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear_events() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh(job: String = "mechanic") -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30; GameState.player["money"]=200000; GameState.player["time_left"]=30
	Actions.hire(job); clear_events()
func answer(index: int) -> void:
	var op: Dictionary=Employment.st()["prompt"].duplicate(true)
	op["answer"]=index
	Employment.outcome(op); clear_events()
func _ready() -> void:
	seed(4242)
	var count := 0
	for id in ["doctor","pharmacist","vet","lawyer","mechanic","chef","executive","professor","scientist","army","navy","air_force"]:
		fresh(id)
		var list: Array=Employment.briefs[id]
		ok(list.size()==3,"Missing third project: "+id)
		for brief in list:
			count+=1
			ok(brief["stages"].size()==3 and brief["stages"].all(func(s): return s["options"].size()==3),"Missing contextual choices: "+id)
		Employment.start_project(2)
		ok(Employment.st()["active"]["brief"]["name"]==list[2]["name"],"Project not reachable: "+id)
	ok(count==36,"Unexpected refined project count")
	fresh(); Employment.start_project(0)
	var time := int(GameState.player["time_left"])
	answer(0)
	ok(GameState.player["time_left"]==time-1,"Extra planning time not charged")
	Employment.resume_project()
	var roll := float(Employment.st()["active"]["execution_roll"])
	var saved: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.from_dict(saved)
	ok(is_equal_approx(float(Employment.st()["active"]["execution_roll"]),roll),"Saved work roll changed")
	var active: Dictionary=Employment.st()["active"]
	var option: Dictionary=active["brief"]["stages"][1]["options"][0]
	for key in ["smarts","health","happiness"]: GameState.player["stats"][key]=95
	GameState.player["stats"]["stress"]=5
	var high := Employment.project_chance(active,option)
	for key in ["smarts","health","happiness"]: GameState.player["stats"][key]=5
	GameState.player["stats"]["stress"]=95
	ok(high>Employment.project_chance(active,option),"Wellbeing did not affect execution")
	active["execution_roll"]=0.0
	answer(1); Employment.resume_project(); answer(0)
	var history: Dictionary=Employment.st()["history"][0]
	ok(history["choices"].size()==3,"Choices missing from work record")
	ok(history["session"]==Employment.job_session(),"Record not tied to employer session")
	GameState.player["age"]=31; clear_events()
	time=int(GameState.player["time_left"])
	Employment.start_project(0)
	ok(Employment.st()["active"].is_empty() and GameState.player["time_left"]==time,"Consumed project repeated or charged")
	Employment.start_project(1)
	ok(not Employment.st()["active"].is_empty(),"Fresh project was blocked")
	answer(0); Employment.resume_project(); Employment.st()["active"]["execution_roll"]=0.0
	answer(0); Employment.resume_project(); answer(2)
	history=Employment.st()["history"][0]
	ok(history["dishonest"] and history["audit_due"]==GameState.year_now()+1,"False report lacks audit")
	Actions.lose_job("switch"); Actions.hire("mechanic"); clear_events()
	GameState.player["age"]=32; GameState.player["job"]["perf"]=75.0
	var cash := int(GameState.player["money"])
	Employment.yearly()
	ok(is_equal_approx(float(GameState.player["job"]["perf"]),76.0),"Old audit damaged new employer performance")
	ok(GameState.player["money"]==cash-int(history["bonus"]),"Audit did not recover original bonus")
	cash=int(GameState.player["money"]); Employment.yearly()
	ok(GameState.player["money"]==cash,"Audit recovered bonus twice")
	fresh(); Employment.start_project(0); answer(1); Employment.resume_project()
	GameState.player["time_left"]=0
	answer(0)
	ok(Employment.st()["active"]["stage"]==2,"Execution wrongly required extra time")
	Employment.st()["prompt"]={}; clear_events()
	Employment.st()["active"]={}
	GameState.player["time_left"]=0; GameState.player["age"]=31
	Employment.start_project(2)
	ok(Employment.st()["active"].is_empty(),"Project started without time")
	for message in failures: print("FAIL: "+str(message))
	print("GUIDE PROJECTS TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
