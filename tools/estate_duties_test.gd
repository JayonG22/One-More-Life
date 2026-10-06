extends Node
var checks := 0
var failures: Array=[]
var duties
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear()
func reload_life() -> void:
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
func fixture(executor_other: bool=false, minor: bool=false, insolvent: bool=false, charity: bool=false) -> String:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=65; GameState.player["money"]=1000 if insolvent else 100000; GameState.player["loan"]=5000 if insolvent else 0
	GameState.player["possessions"]=[{"name":"Family watch","value":1000}]
	if charity: GameState.player["will"]="charity"
	var heir := GameState.create_npc("child",{"first":"Ari","age":12 if minor else 25,"money":321})
	var other := GameState.create_npc("child",{"first":"Bo","age":23,"money":222})
	Journey.modules["heritage"].st()["plan"]={"executor":FamilyChronicle.identity(GameState.npc(other if executor_other else heir)),"discussed":true}
	var source := Journey.uid(); GameState.player["alive"]=false; GameState.continue_as(heir); clear()
	GameState.player["time_left"]=12
	return source
func answer(chosen: int) -> Dictionary:
	var p: Dictionary=Journey.state()["prompt"]
	if p.is_empty(): ok(false,"Missing executor question"); return {}
	var index: int=p["args"]["order"].map(func(i): return int(i)).find(chosen)
	var spec: Dictionary=p["def"]["choices"][index]["outcomes"][0]["journey"].duplicate(true)
	clear(); Journey.outcome(spec); clear(); return spec
func _ready() -> void:
	seed(8130); GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	duties=Journey.modules["heritage"].duties
	for scenario in ["solvent","insolvent","charity"]:
		var source := fixture(false,false,scenario=="insolvent",scenario=="charity")
		var receipt: Dictionary=GameState.world["estate_register"][source]
		var original: Dictionary=JSON.parse_string(JSON.stringify(receipt))
		var money := int(GameState.player["money"]); var possessions: Array=GameState.player["possessions"].duplicate(true)
		ok(duties.ensure(source)["executor"]==Journey.uid(),"Actual named heir not assigned executor")
		ok(not duties.rows().is_empty() and not Journey.modules["heritage"].menu("estate:"+source)["rows"].is_empty(),"Executor route unreachable")
		for stage in range(3):
			var time := int(GameState.player["time_left"])
			duties.start(source)
			ok(GameState.player["time_left"]==time-1,"Executor duty missing time cost")
			var prompt: Dictionary=JSON.parse_string(JSON.stringify(Journey.state()["prompt"]))
			reload_life()
			ok(Journey.state()["prompt"]==prompt,"Saved executor question changed")
			var spec := answer(0)
			ok(duties.ensure(source)["stage"]==stage+1,"Correct executor step did not advance")
			Journey.outcome(spec); clear()
			ok(duties.ensure(source)["stage"]==stage+1,"Executor replay advanced twice")
		ok(duties.ensure(source)["closed"],"Estate report never concludes")
		reload_life(); duties.start(source); duties.yearly(); clear()
		ok(duties.ensure(source)["history"].size()==3,"Closed report reopened or duplicated")
		ok(GameState.player["money"]==money and GameState.player["possessions"]==JSON.parse_string(JSON.stringify(possessions)),"Estate review changed real cash or ownership")
		receipt=GameState.world["estate_register"][source]
		for key in ["status","cash","allocations","fees","tax","charity","unpaid","liquidated"]:
			ok(receipt[key]==original[key] or JSON.parse_string(JSON.stringify(receipt[key]))==original[key],"Executor changed original settlement: "+key)
	var source := fixture(); var money := int(GameState.player["money"])
	duties.start(source); answer(1)
	ok(duties.ensure(source)["stage"]==0 and duties.ensure(source)["corrected"]==1,"Incorrect claim handling accepted")
	var time := int(GameState.player["time_left"]); duties.start(source)
	ok(Journey.state()["prompt"].is_empty() and GameState.player["time_left"]==time,"Correction replay consumed time")
	GameState.player["age"]+=1; duties.start(source); answer(0)
	ok(duties.ensure(source)["stage"]==1 and GameState.player["money"]==money,"Next-year correction lost cash or failed")
	duties.start(source); answer(2)
	ok(duties.ensure(source)["stage"]==1,"Wrong estate account total accepted")
	for report in [1,2]:
		source=fixture()
		var sibling: String=GameState.npcs_with("sibling")[0]
		var trust := BondStats.get_stat(sibling,"trust")
		for stage in range(3): duties.start(source); answer(report if stage==2 else 0)
		ok(duties.ensure(source)["closed"] and duties.ensure(source)["report"]==report,"Alternative executor report never concludes")
		ok(BondStats.get_stat(sibling,"trust")==trust+(0 if report==1 else -3),"Executor report has no matching family consequence")
	source=fixture(); money=int(GameState.player["money"])
	duties.delegate(source); clear(); var time0 := int(GameState.player["time_left"])
	duties.delegate(source); clear()
	ok(duties.ensure(source)["delegated"] and duties.ensure(source)["executor"]=="" and GameState.player["time_left"]==time0,"Delegation repeats or reassigns itself to the active heir")
	for i in range(3): GameState.player["age"]+=1; duties.yearly(); reload_life()
	ok(duties.ensure(source)["closed"] and GameState.player["money"]==money,"Delegated estate cannot conclude or pays again")
	source=fixture(true); money=int(GameState.player["money"]); time=int(GameState.player["time_left"])
	duties.start(source)
	ok(Journey.state()["prompt"].is_empty() and GameState.player["time_left"]==time,"Wrong person took executor duties")
	for i in range(3):
		GameState.player["age"]+=1; duties.yearly(); duties.yearly(); reload_life()
		ok(duties.ensure(source)["stage"]==i+1,"Background executor missed/doubled annual work")
	ok(duties.ensure(source)["closed"] and GameState.player["money"]==money,"NPC executor stranded report or charged active heir")
	source=fixture(true); var executor := Journey.person(str(duties.ensure(source)["executor"]))
	GameState.npc(executor)["alive"]=false
	ok(duties.ensure(source)["executor"]==Journey.uid(),"Unavailable executor did not hand over to actual adult heir")
	source=fixture(false,true); money=int(GameState.player["money"])
	ok(duties.ensure(source)["executor"]!=Journey.uid(),"Minor was assigned executor")
	GameState.player["time_left"]=0; duties.start(source)
	ok(Journey.state()["prompt"].is_empty() and GameState.player["money"]==money,"Child executor route charged or created debt")
	source=fixture(); GameState.player["time_left"]=0; duties.start(source)
	ok(Journey.state()["prompt"].is_empty(),"Executor route ignores time limit")
	GameState.player["time_left"]=12; EventEngine.push_info("📋","Busy","Resolve first."); duties.start(source)
	ok(Journey.state()["prompt"].is_empty(),"Executor route overrides an unresolved decision")
	clear()
	for player in Fx.find_children("*","AudioStreamPlayer",true,false): player.stop(); player.stream=null
	await get_tree().create_timer(0.2).timeout
	print("ESTATE DUTIES checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
