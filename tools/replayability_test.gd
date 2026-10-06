extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear_events() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh(age: int = 30) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=age; GameState.player["money"]=100000; GameState.player["time_left"]=100
	GameState.settings["volume"]=0; GameState.settings["minigames"]=false; Fx.apply_volumes()
	clear_events()
func answer_journey() -> void:
	var event := EventEngine.pop_next()
	var choice: int=Journey.state()["prompt"]["args"]["order"].find(0)
	EventEngine.resolve(event,choice); clear_events()
func job(id: String) -> void:
	var jd := ContentDB.job(id)
	GameState.player["job"]={"id":id,"field":jd["field"],"title":jd["ranks"][0],"salary":jd["salary"],"perf":50.0,"years":0,"rank":0}
	Employment.on_hire()
func _ready() -> void:
	seed(4141); fresh(5)
	var scene := {"id":"test.scene","text":"A shared question","family":"test.family"}
	Novelty.note(scene)
	ok(not Novelty.eligible(scene),"Scene repeats within one life")
	ok(not Novelty.eligible({"id":"other.id","text":"A shared question"}),"Renamed duplicate text repeats")
	var shared := Novelty.familiarity(scene)
	fresh(5)
	ok(Novelty.familiarity(scene)==shared and Novelty.eligible(scene),"Shared history lost across lives")
	ok(Novelty.pick([scene,{"id":"unseen","text":"A new question","family":"fresh"}])["id"]=="unseen","Unseen scene not preferred")
	Novelty.note(scene)
	ok(Novelty.pick([scene]).is_empty(),"Exhausted pool silently resets")
	var persisted: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Meta.META_PATH))
	ok(persisted.get("scene_history",{}).get("texts",{}).has(Novelty.fingerprint(scene)),"Shared history not saved to disk")
	GameState.player.erase("novelty")
	GameState.player["director"]={"seen":{"legacy.scene":1},"recent":[]}
	ok(not Novelty.eligible({"id":"legacy.scene","text":"An old scene"}),"Existing event history ignored")
	fresh(5); GameState.player["education"]["stage"]="primary"
	var school=Journey.modules["school"]
	var seen: Array=[]
	for age in range(5,9):
		GameState.player["age"]=age; GameState.player["time_left"]=100
		for index in range(2):
			school.lesson(index)
			var prompt: Dictionary=Journey.state()["prompt"]
			var selected: Dictionary=prompt["args"]["scene"]
			ok(int(selected["band"])==0 and not seen.has(selected["question"]),"Age-five band repeats or uses wrong content")
			seen.append(selected["question"])
			if age==5 and index==0:
				var snapshot: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
				GameState.from_dict(snapshot)
				ok(Journey.state()["prompt"]["args"]["scene"]["id"]==selected["id"] and EventEngine.pending.size()==1,"Reload rerolls or duplicates a selected lesson")
			answer_journey()
	ok(seen.size()==8,"School exercises unavailable across childhood years")
	GameState.player["age"]=9; school.lesson(0)
	ok(int(Journey.state()["prompt"]["args"]["scene"]["band"])==1,"Curriculum did not progress with age")
	answer_journey()
	fresh(5); GameState.player["education"]["stage"]="primary"
	for q in school.curriculum:
		if int(q["band"])==0: Novelty.note(q)
	var before := int(GameState.player["time_left"])
	school.lesson(0)
	ok(Journey.state()["prompt"].is_empty() and int(GameState.player["time_left"])==before,"Exhausted lessons charge time or repeat")
	clear_events()
	var age_ok := true
	for q in Depth.lessons["Arithmetic"]:
		if q.has("min_age") and int(q["min_age"])>5:
			age_ok=age_ok and not (int(GameState.player["age"])>=int(q["min_age"]))
	ok(age_ok,"Older assessment units leak into early childhood")
	fresh(); job("developer")
	var case: Dictionary=Depth.career_cases.filter(func(c): return c["job"]=="developer")[0]
	var active := {"job":"developer","session":Employment.job_session(),"task":case}
	var money := int(GameState.player["money"])
	var health := GameState.stat("health")
	Depth.resolve_career_case(active,0); clear_events()
	ok(GameState.stat("health")<health and int(GameState.player["money"])==money,"Extra effort lacks its cost or pays employer wages")
	ok(Depth.state()["work_reviews"].size()==1 and not Depth.state()["work_reviews"][0]["closed"],"Work decision lacks a pending review")
	GameState.player["age"]+=1
	Depth.settle_work_reviews()
	var reputation := float(Employment.record("Tech")["reputation"])
	ok(Depth.state()["work_reviews"][0]["closed"],"Work review remains a cliffhanger")
	Depth.settle_work_reviews()
	ok(float(Employment.record("Tech")["reputation"])==reputation,"Work review pays twice")
	Depth.resolve_career_case(active,1); clear_events(); GameState.player["age"]+=1
	job("teacher"); var performance := float(GameState.player["job"]["perf"])
	Depth.settle_work_reviews()
	ok(float(GameState.player["job"]["perf"])==performance,"Old employer's review changes new job performance")
	fresh(); job("developer")
	for key in GameState.player["stats"]: GameState.player["stats"][key]=0 if key!="stress" else 100
	Depth.resolve_career_case({"job":"developer","session":Employment.job_session(),"task":case,"execution_roll":0.70},0); clear_events()
	var low_performance := float(GameState.player["job"]["perf"])
	ok(not Depth.state()["work_reviews"][0]["success"],"Very low readiness succeeds at a difficult execution roll")
	fresh(); job("developer")
	for key in GameState.player["stats"]: GameState.player["stats"][key]=100 if key!="stress" else 0
	Depth.resolve_career_case({"job":"developer","session":Employment.job_session(),"task":case,"execution_roll":0.70},0); clear_events()
	ok(Depth.state()["work_reviews"][0]["success"] and float(GameState.player["job"]["perf"])>low_performance,"High readiness does not improve success and reward")
	fresh(); job("doctor")
	var cases_covered := true
	for jd in ContentDB.jobs:
		cases_covered=cases_covered and Depth.career_cases.any(func(c): return c["job"]==jd["id"] and c["answers"].size()==3 and c["approaches"].size()==3)
	ok(cases_covered,"Occupation lacks its authored dilemma")
	var titles: Array=[]
	for index in range(2):
		Depth.job_task(index)
		titles.append(Depth.state()["active"]["task"]["question"])
		var event := EventEngine.pop_next(); EventEngine.resolve(event,0); clear_events()
	ok(titles[0]!=titles[1],"Work encounter buttons show the same task")
	fresh(30)
	var start: Dictionary=ContentDB.events_by_id["depthlife.first_budget"]
	ok(EventEngine._eligible(start,false)==false,"Young-adult story has incorrect age range")
	GameState.player["age"]=24
	ok(EventEngine._eligible(start,false),"Eligible new story cannot start")
	EventEngine._enqueue(start,{})
	var event := EventEngine.pop_next(); EventEngine.resolve(event,1); clear_events()
	ok(Novelty.state()["stories"][start["id"]]["state"]=="open" and GameState.followups.size()==1,"Story does not record choice and followup")
	money=int(GameState.player["money"]); GameState.player["age"]+=1
	EventEngine._due_followups(); clear_events()
	ok(Novelty.state()["stories"][start["id"]]["state"]=="closed" and int(GameState.player["money"])==money,"Story conclusion failed or created money")
	Novelty.story_outcome({"id":start["id"],"state":"closed","effects":{"money":40}})
	ok(int(GameState.player["money"])==money,"Conclusion reward paid twice")
	ok(not EventEngine._eligible(start,false),"Optional authored event repeats after completion")
	ok(EventEngine._eligible(ContentDB.events_by_id["depthlife.first_budget.end.1"],true),"Novelty blocks required consequences")
	ok(not EventEngine._eligible(ContentDB.events_by_id["depthlife.owned_car"],false),"Vehicle story offered without a car")
	fresh(35)
	var chapter := {"id":"test.transfer","title":"A continuing hobby","state":"open","choice":"Finish a commission","ending":"The commission was delivered.","effects":{"money":70},"field":"Business","due":1}
	Novelty.story_outcome(chapter)
	var child := GameState.create_npc("child",{"age":18,"closeness":70})
	ok(Dynasty.switch_to(child),"Child transfer blocked by a settled story choice")
	var parent_id: String = str(GameState.npcs_with("mother")[0])
	var parent: Dictionary=GameState.npc(str(parent_id))
	var former: Dictionary=parent["playable_player"]
	var child_cash := int(GameState.player["money"])
	money=int(parent["money"])
	GameState.player["age"]+=1
	Novelty.background(parent,GameState.year_now())
	ok(former["novelty"]["stories"][chapter["id"]]["state"]=="closed" and int(parent["money"])==money+70,"Transferred parent's story did not finish for that person")
	ok(int(GameState.player["money"])==child_cash,"Parent's story reward leaked to the child")
	ok(parent["professional_skills"]==former["professional_skills"],"Background learning lost when restoring the former player")
	Novelty.background(parent,GameState.year_now())
	ok(int(parent["money"])==money+70,"Background conclusion paid twice")
	fresh(35); Novelty.story_outcome(chapter); GameState.finalize_death("natural causes")
	ok(Novelty.state()["stories"][chapter["id"]]["state"]=="closed" and str(Novelty.state()["stories"][chapter["id"]]["ending"]).contains("No completion reward"),"Death leaves an unresolved or falsely completed story")
	fresh(15); GameState.player["education"]["stage"]="secondary"
	for key in GameState.player["stats"]: GameState.player["stats"][key]=0 if key!="stress" else 100
	school.start("science"); clear_events()
	for i in range(3):
		school.step(); var project_event := EventEngine.pop_next(); EventEngine.resolve(project_event,0); clear_events(); GameState.player["age"]+=1
	ok(float(school.st()["completed"][0]["quality"])<65 and school.career_bonus("Tech")==0,"Very low readiness guarantees the same school award")
	fresh(5); LifeCourse._scene(5)
	var age_scene: Dictionary=EventEngine.pending[0]["def"]
	ok(not LifeCourse.state()["seen"].has(age_scene["id"]),"Unshown age scene consumed by yearly curation")
	EventEngine.pop_next(); clear_events()
	ok(LifeCourse.state()["seen"].has(age_scene["id"]) and not Novelty.eligible(age_scene),"Displayed age scene was not remembered")
	var ids: Dictionary={}; var valid := true
	for jd in ContentDB.jobs:
		var icon := Icons.for_job(str(jd["id"]))
		valid=valid and Icons.has(icon) and not ids.has(icon); ids[icon]=true
	ok(valid,"Occupation icon coverage or identity incomplete")
	valid=true
	for major in ContentDB.majors: valid=valid and Icons.has("study:"+str(major["id"]))
	ok(valid,"Education icon coverage incomplete")
	for message in failures: print("FAIL: "+str(message))
	print("REPLAYABILITY TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
