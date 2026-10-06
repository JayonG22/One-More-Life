extends Node
var checks := 0
var failures: Array=[]
var learning
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh(field: String) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=20; GameState.player["money"]=10000; GameState.player["time_left"]=12
	learning=Journey.modules["learning"]; clear()
	learning.st()["course"]={"field":field,"route":"campus","paused":false}
func choose(index: int) -> Dictionary:
	var spec: Dictionary=Journey.state()["prompt"]["def"]["choices"][index]["outcomes"][0]["journey"].duplicate(true)
	clear(); Journey.outcome(spec); clear(); return spec
func _ready() -> void:
	seed(8400); GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	learning=Journey.modules["learning"]
	var texts: Dictionary={}; var choices: Dictionary={}; var results: Dictionary={}
	for field in Employment.programs:
		ok(learning.placements.has(field) and learning.placements[field].size()==2,"Missing field-specific placement: "+str(field))
		for scene in learning.placements[field]:
			texts[scene[1]]=true
			ok(scene.size()==4 and scene[2].size()==3 and scene[3].size()==3,"Incomplete placement scenario")
			for result in scene[3]: results[result]=true
			choices[str(field)+":"+str(scene[2])]=true
		fresh(str(field)); learning.internship(); clear()
		var mentor: String=Journey.person(str(learning.st()["internship"]["mentor"]))
		BondStats.ensure(mentor)["trust"]=70
		var initial_money := int(GameState.player["money"])
		var initial_samples := int(Employment.record(str(field))["samples"])
		for step in range(2):
			var time := int(GameState.player["time_left"]); learning.shift()
			var prompt: Dictionary=JSON.parse_string(JSON.stringify(Journey.state()["prompt"]))
			ok(GameState.player["time_left"]==time-2 and prompt["args"]["scene"]==learning.placements[field][step],"Placement did not use its own paid task")
			GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
			ok(Journey.state()["prompt"]==prompt,"Saved placement question changed")
			var replay := choose(step)
			var money := int(GameState.player["money"]); Journey.outcome(replay); clear()
			ok(GameState.player["money"]==money,"Placement answer paid twice")
			if step==0:
				time=int(GameState.player["time_left"]); learning.shift()
				ok(GameState.player["time_left"]==time and Journey.state()["prompt"].is_empty(),"Both placement years compressed into one")
				GameState.player["age"]+=1; GameState.player["time_left"]=12
		ok(learning.st()["internship"].is_empty() and learning.st()["history"][0]["decisions"].size()==2,"Placement lacks a concluded decision record")
		ok(GameState.player["money"]==initial_money+Actions._cost(200) and Employment.record(str(field))["samples"]==initial_samples+1,"Placement stipend or earned work evidence incorrect")
		ok(learning.st()["placement_awards"].has(field) and learning.st()["placement_awards"][field]["reference"],"Completed honest placement has no permanent evidence")
		ok(Journey.modules["pathways"].st()["cases"].any(func(entry): return entry["source"]=="placement:"+str(field) and entry["uid"]==FamilyChronicle.identity(GameState.npc(mentor))),"Supervisor never follows through into future work")
		ok(learning.menu("placements")["info"].any(func(line): return str(line).contains(str(learning.placements[field][0][0]))),"Actual placement tasks hidden from readable history")
		GameState.player["age"]+=1; GameState.player["time_left"]=12
		learning.st()["history"].clear(); GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
		var time := int(GameState.player["time_left"]); learning.internship(); clear()
		ok(learning.st()["internship"].is_empty() and GameState.player["time_left"]==time and Employment.record(str(field))["samples"]==initial_samples+1,"Trimming history reopened placement reward farming")
	ok(texts.size()==56 and choices.size()==56 and results.size()==168,"Placement scenarios or outcomes repeat")
	# High existing trust cannot manufacture a reference from unsupported work.
	fresh("Tech"); learning.internship(); clear()
	var mentor: String=Journey.person(str(learning.st()["internship"]["mentor"])); BondStats.ensure(mentor)["trust"]=100
	for step in range(2):
		learning.shift(); choose(2); GameState.player["age"]+=1; GameState.player["time_left"]=12
	ok(learning.st()["history"][0]["result"]=="Completed without a reference" and learning.st()["placement_awards"].is_empty(),"Unsupported work awarded a reference from unrelated trust")
	ok(Employment.record("Tech")["samples"]==0 and Market.st()["interview_xp"]==0,"Unsupported shifts manufacture career evidence")
	learning.internship(); clear(); ok(not learning.st()["internship"].is_empty(),"Failed work has no paid-effort recovery route")
	# Saved older prompts still resolve without the new scene payload.
	fresh("Care"); learning.internship(); clear()
	var i: Dictionary=learning.st()["internship"]
	learning.resolve("shift",{"mentor":i["mentor"],"step":0},1); clear()
	ok(i["steps"]==1 and i["decisions"].size()==1,"Older pending placement choice became a dead end")
	# Supervisor loss closes the work without a final payment or invented reference.
	fresh("Trades"); learning.internship(); clear(); i=learning.st()["internship"]
	mentor=Journey.person(str(i["mentor"])); GameState.npc(mentor)["alive"]=false
	var money := int(GameState.player["money"]); learning.shift(); clear()
	ok(learning.st()["internship"].is_empty() and learning.st()["history"][0]["result"]=="Supervisor unavailable" and GameState.player["money"]==money,"Dead supervisor still pays or has no conclusion")
	# A wary supervisor can withhold a reference without erasing honest experience.
	fresh("Food"); learning.internship(); clear()
	mentor=Journey.person(str(learning.st()["internship"]["mentor"])); BondStats.ensure(mentor)["trust"]=0
	for step in range(2):
		learning.shift(); choose(0); GameState.player["age"]+=1; GameState.player["time_left"]=12
	ok(Employment.record("Food")["samples"]==1 and not learning.st()["placement_awards"]["Food"]["reference"] and Market.st()["interview_xp"]==0,"Honest experience erased or wary supervisor fabricated a reference")
	ok(Journey.modules["pathways"].st()["cases"][0]["quality"]==60,"Wary supervisor has no repair follow-up")
	# Legacy evidence is recognized without adding another work sample on load.
	fresh("Science"); Employment.record("Science")["samples"]=1
	learning.st()["history"]=[{"field":"Science","steps":2,"paid":200,"honest_shifts":2,"started":GameState.year_now()-2,"result":"Placement completed"}]
	ok(learning.st()["placement_awards"].has("Science") and Employment.record("Science")["samples"]==1,"Legacy completed work lost its guard or gained a sample on migration")
	learning.internship(); clear(); ok(learning.st()["internship"].is_empty(),"Legacy completed field reopened its placement reward")
	# Missing a deadline keeps the earned first stipend, without completing work.
	fresh("Retail"); learning.internship(); clear(); learning.shift(); choose(1)
	money=int(GameState.player["money"]); GameState.player["age"]+=3; learning.yearly(); clear()
	ok(learning.st()["internship"].is_empty() and learning.st()["history"][0]["result"]=="Placement deadline missed" and GameState.player["money"]==money and learning.st()["placement_awards"].is_empty(),"Missed placement has no honest closure or awards extra pay")
	print("PLACEMENT DEPTH checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
