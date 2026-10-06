extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh() -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30; GameState.player["money"]=200000; GameState.player["time_left"]=100
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes(); clear()
func choose(answer: int) -> Dictionary:
	var p: Dictionary=Journey.state()["prompt"]
	var idx: int=p["args"]["order"].map(func(i): return int(i)).find(answer)
	var spec: Dictionary=p["def"]["choices"][idx]["outcomes"][0]["journey"].duplicate(true)
	clear(); Journey.outcome(spec); clear(); return spec
func next_year() -> void:
	GameState.player["age"]+=1; GameState.player["time_left"]=100; clear()
func _ready() -> void:
	seed(100100); fresh()
	var learning=Journey.modules["learning"]
	ok(learning.units.keys().size()==Employment.programs.keys().size(),"Course field coverage differs from available programmes")
	var questions: Array=[]
	for field in Employment.programs:
		fresh()
		ok(learning.units.has(field) and learning.units[field].size()==3,"Missing three dedicated units: "+str(field))
		for row in learning.units.get(field,[]):
			ok(row.size()==6 and row.slice(2,5).all(func(text): return str(text)!=""),"Invalid course choices: "+str(field))
			questions.append(str(row[1]))
		# Exhaust all optional job questions before starting this paid course.
		for job in Employment.programs[field]["jobs"]:
			for i in range(Depth.jobs.get(job,[]).size()):
				var task: Dictionary=Depth.jobs[job][i].duplicate(true)
				task["id"]="learning:"+str(job)+":"+str(i); task["text"]=task["question"]; Novelty.note(task)
		learning.enrol(str(field),"campus"); clear()
		var fee: int=GameState.player["money"]; var ids: Array=[]
		for i in range(3):
			learning.unit()
			var prompt: Dictionary=JSON.parse_string(JSON.stringify(Journey.state()["prompt"]))
			ok(not prompt.is_empty(),"Exhausted jobs blocked course unit: "+str(field))
			if prompt.is_empty(): break
			ids.append(str(prompt["args"]["task"]["id"]))
			var saved: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
			GameState.from_dict(saved); clear()
			ok(Journey.state()["prompt"]["args"]==prompt["args"],"Reload rerolled coursework: "+str(field))
			var replay := choose(0)
			Journey.outcome(replay)
			ok(int(learning.st()["course"]["units"])==i+1,"Course unit replayed: "+str(field))
			var time: int=GameState.player["time_left"]; learning.unit()
			ok(time==GameState.player["time_left"] and Journey.state()["prompt"].is_empty(),"Same-year unit repeat charged time: "+str(field))
			next_year()
		ok(ids.size()==3 and ids.all(func(id): return ids.count(id)==1),"Course repeated a practical: "+str(field))
		ok(learning.st()["course"]["points"]==3 and GameState.player["money"]==fee,"Course lost demonstrated learning or charged a second fee: "+str(field))
		# Assessment can fail; retain the work and finish on a later permitted attempt.
		for attempt in range(30):
			learning.assess(); clear()
			if learning.st()["course"].is_empty(): break
			next_year()
		ok(learning.st()["course"].is_empty() and learning.st()["completed"].size()==1,"Course cannot conclude: "+str(field))
	ok(questions.size()==84 and questions.all(func(q): return questions.count(q)==1),"Course questions repeat across fields")
	# Old saves already two units into a course gain the remaining fresh practical.
	fresh(); learning.st()["course"]={"field":"Beauty","route":"distance","started":GameState.year_now()-2,"earliest":GameState.year_now()+1,"units":2,"points":1,"paused":false,"paid":600,"unit_year":-1}
	learning.unit(); choose(1)
	ok(learning.st()["course"]["units"]==3 and learning.st()["course"]["points"]==1,"Legacy course progress changed during migration")
	print("COURSE COMPLETION checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
