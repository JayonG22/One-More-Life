extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func _ready() -> void:
	seed(8150); GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	var learning=Journey.modules["learning"]; var questions: Array=[]
	for bank in learning.units.values():
		for row in bank: questions.append(row[1])
	for field in Employment.programs:
		GameState.new_life({"country":"us","gender":"female","random_royalty":false}); clear()
		GameState.player["age"]=25; GameState.player["money"]=100000; GameState.player["time_left"]=12
		GameState.player["education"]["hs_graduated"]=true
		learning.st()["completed"]=[{"field":field,"route":"distance","units":3,"points":3,"year":GameState.year_now()-1,"unit_ids":["course_unit:"+field+":0","course_unit:"+field+":1","course_unit:"+field+":2"]}]
		Market.learn(field,2); Employment.record(field)["samples"]=1
		ok(learning.capstones.has(field) and learning.capstones[field].size()==6,"Missing field-specific college capstone")
		questions.append(learning.capstones[field][1])
		ok(not learning.completed(field,"college") and learning.completed(field,"distance"),"Practical diploma blocks college upgrade or repeats itself")
		var cash := int(GameState.player["money"]); learning.enrol(field,"college"); clear()
		var course: Dictionary=learning.st()["course"]
		ok(course["units"]==2 and course["points"]==2 and course["earliest"]==GameState.year_now()+1,"Upgrade loses credit or grants immediate graduation")
		ok(cash-GameState.player["money"]==int(Actions._cost(3200)*0.6),"Upgrade fee disagrees with preview")
		learning.assess(); ok(not learning.st()["course"].is_empty(),"Upgrade skips advanced unit")
		learning.unit(); var prompt: Dictionary=JSON.parse_string(JSON.stringify(Journey.state()["prompt"]))
		ok(prompt["args"]["task"]["id"]=="course_capstone:"+field,"Upgrade repeats a completed basic unit")
		GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
		ok(Journey.state()["prompt"]==prompt,"Saved college capstone rerolls")
		var idx: int=prompt["args"]["order"].map(func(i): return int(i)).find(0)
		var spec: Dictionary=prompt["def"]["choices"][idx]["outcomes"][0]["journey"]
		Journey.outcome(spec); clear(); Journey.outcome(spec)
		ok(learning.st()["course"]["units"]==3 and learning.st()["course"]["points"]==3,"Upgrade loses evidence or awards unit twice")
		for attempt in range(30):
			GameState.player["age"]+=1; GameState.player["time_left"]=12; learning.assess(); clear()
			if learning.st()["course"].is_empty(): break
		ok(learning.st()["completed"].size()==2 and GameState.edu_level()=="associate","Completed prior course cannot progress to a diploma")
		ok(Market.skill(field)==3 and Employment.record(field)["samples"]==2,"Upgrade duplicates prior skill or omits its new work evidence")
		cash=int(GameState.player["money"]); learning.enrol(field,"college"); learning.enrol(field,"campus")
		ok(GameState.player["money"]==cash and learning.st()["course"].is_empty(),"Completed diploma can be rewarded again")
	ok(questions.size()==112 and questions.all(func(text): return questions.count(text)==1),"College capstone text repeats a course question")
	for player in Fx.find_children("*","AudioStreamPlayer",true,false): player.stop(); player.stream=null
	await get_tree().create_timer(0.2).timeout
	print("COLLEGE UPGRADE checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
