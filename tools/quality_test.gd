extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh() -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30; GameState.player["money"]=200000; GameState.player["time_left"]=100
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes(); clear()
func reload_save() -> void: GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
func answer(canonical: int) -> Dictionary:
	var prompt: Dictionary=Journey.state()["prompt"]
	var displayed: int=prompt["args"]["order"].map(func(i): return int(i)).find(canonical)
	var spec: Dictionary=prompt["def"]["choices"][displayed]["outcomes"][0]["journey"].duplicate(true)
	clear(); Journey.outcome(spec); clear(); return spec
func frames() -> void:
	for i in range(2): await get_tree().process_frame
func _ready() -> void:
	seed(8181); fresh()
	var destinations: Array=[]
	for group in Journey.GROUPS:
		for row in Journey.menu("group:"+group)["rows"]: destinations.append(str(row["menu"]).get_slice(":",1))
	ok(Journey.menu("root")["rows"].size()==7,"Hub still presents an ungrouped wall of destinations")
	ok(Journey.DOMAINS.keys().all(func(key): return destinations.count(key)==1),"Grouped navigation hid or duplicated a destination")
	var people=Journey.modules["people"]; var parenting=Journey.modules["parenting"]
	var ids: Array=[]
	for scene in parenting.scenes+people.scenes:
		ids.append(scene["id"])
		ok(scene["answers"].size()==3 and scene["endings"].size()==3 and scene["later"].size()==3,"Scene lacks a choice/conclusion/callback: "+str(scene["id"]))
	ok(ids.size()==60 and ids.all(func(id): return ids.count(id)==1),"Distinct authored scene IDs missing")
	for band in range(3): ok(parenting.scenes.filter(func(s): return int(s["band"])==band).size()==14,"Parenting age-bank gap")
	var friend := GameState.create_npc("friend",{"age":30,"closeness":65,"smarts":40})
	var peer := GameState.create_npc("friend",{"age":29,"closeness":65})
	var m: Dictionary=people.motive(friend); m["goal"]="learning"; m["progress"]=0
	people.motive(peer)["goal"]="belonging"
	var cash: int=GameState.player["money"]; var stats: Dictionary=GameState.player["stats"].duplicate(true)
	var year := GameState.year_now()
	people.autonomously_progress(year)
	ok(int(m["progress"])==1 and GameState.npc(friend)["smarts"]==41,"NPC did not independently learn")
	ok(not people.motive(peer).get("circle",[]).is_empty(),"NPC has no independent social connections")
	people.autonomously_progress(year)
	ok(int(m["progress"])==1 and GameState.npc(friend)["smarts"]==41,"Same-year NPC progress duplicated")
	ok(GameState.player["money"]==cash and GameState.player["stats"]==stats,"NPC action changed active player rewards")
	reload_save(); m=people.motive(friend); people.autonomously_progress(year)
	ok(int(m["progress"])==1,"Reload repeated independent NPC progress")
	people.autonomously_progress(year+1); people.autonomously_progress(year+2)
	ok(m["last_completed"]=="learning" and m["goal"]!="learning" and m["progress"]==0,"NPC never completes or changes their own goal")
	GameState.npc(friend)["alive"]=false; var previous: Dictionary=m.duplicate(true)
	people.autonomously_progress(year+3); ok(m==previous,"Deceased NPC kept progressing")
	fresh(); friend=GameState.create_npc("friend",{"age":30,"closeness":65})
	people.motive(friend)["goal"]="quiet"; people.moment(friend)
	ok(Journey.state()["prompt"]["domain"]=="people","Social moment was not interactive")
	var original: Dictionary=JSON.parse_string(JSON.stringify(Journey.state()["prompt"]))
	reload_save(); ok(Journey.state()["prompt"]["args"]==original["args"],"Social choice rerolled on reload")
	var trust := BondStats.get_stat(friend,"trust"); var replay := answer(1)
	ok(BondStats.get_stat(friend,"trust")==trust+3,"Social preference had no relationship effect")
	var moments: Array=people.st()["moments"]; ok(moments.size()==1 and moments[0]["state"]=="open","Social choice has no later consequence")
	trust=BondStats.get_stat(friend,"trust"); Journey.outcome(replay)
	ok(BondStats.get_stat(friend,"trust")==trust and moments.size()==1,"Social result replayed")
	var time: int=GameState.player["time_left"]; people.moment(friend)
	ok(GameState.player["time_left"]==time and Journey.state()["prompt"].is_empty(),"Social moment repeated in same year")
	people.settle_moments(GameState.year_now()+1); trust=BondStats.get_stat(friend,"trust")
	people.settle_moments(GameState.year_now()+1)
	ok(moments[0]["state"]=="closed" and BondStats.get_stat(friend,"trust")==trust,"Callback duplicated or never concluded")
	fresh(); var child := GameState.create_npc("child",{"age":8,"closeness":65,"smarts":40})
	GameState.npc(child)["upbringing_style"]=2; parenting.activity(child); replay=answer(2)
	ok(parenting.st()["followups"].size()==1,"Parenting choice has no follow-up")
	var uid := FamilyChronicle.identity(GameState.npc(child)); var parent_uid := Journey.uid()
	ok(Dynasty.switch_to(child),"Cannot continue as actual child")
	ok(GameState.player["upbringing_style"]==2,"Child's own preference lost on transfer")
	var owner := GameState.npc(Journey.person(parent_uid)); year=GameState.year_now()+1
	cash=int(GameState.player["money"]); time=int(GameState.player["time_left"])
	parenting.background(owner,year)
	ok(GameState.player["upbringing"].size()==2,"Parenting callback did not follow actual child across transfer")
	parenting.background(owner,year)
	ok(GameState.player["upbringing"].size()==2 and GameState.player["money"]==cash and GameState.player["time_left"]==time,"Transferred callback duplicated or charged child")
	# Earlier pending parenting prompts retain their original consequences.
	fresh(); child=GameState.create_npc("child",{"age":8,"closeness":65,"happiness":50})
	uid=FamilyChronicle.identity(GameState.npc(child))
	var old_scene := {"title":"Old parenting prompt","endings":["Supported","Paused","The demand overwhelmed them."],"effects":[{}, {}, {"happiness":-2}]}
	Journey.decision("parenting","activity",{"uid":uid,"band":1,"scene":old_scene,"order":[0,1,2]},"Old parenting prompt","Saved before this update",["Support","Pause","Demand too much"])
	reload_save(); trust=BondStats.get_stat(child,"trust"); answer(2)
	ok(GameState.npc(child)["happiness"]==48 and BondStats.get_stat(child,"trust")==trust-3,"Legacy parenting consequence changed on upgrade")
	# Real boards score execution, preserve unfinished work, and finish only once.
	for kind in ["repair","music","negotiation"]:
		fresh(); var skills=Journey.modules["skills"]
		skills.st()["active"]={"kind":kind,"practice":false,"token":1,"owner":Journey.uid(),"format":"hands_on","board_seed":123}
		var mg=load("res://scenes/minigames/mg_hands_on.gd").new()
		mg.setup({"kind":kind,"skill":100,"board_seed":123,"progress_token":1,"progress_owner":Journey.uid()})
		var results: Array=[]; mg.finished.connect(func(score,detail): results.append([score,detail]))
		add_child(mg); await frames()
		if kind=="repair": mg.inspect(0)
		elif kind=="music": mg.note(int(mg.notes[0]))
		else: mg.offer_slider.value=84; mg.scope_slider.value=85
		var progress: Dictionary=JSON.parse_string(JSON.stringify(skills.st()["active"]["progress"]))
		reload_save(); mg.queue_free(); await frames()
		mg=load("res://scenes/minigames/mg_hands_on.gd").new()
		mg.setup({"kind":kind,"skill":100,"board_seed":123,"progress":skills.st()["active"]["progress"],"progress_token":1,"progress_owner":Journey.uid()})
		mg.finished.connect(func(score,detail): results.append([score,detail])); add_child(mg); await frames()
		ok(mg.target==progress["target"] and mg.played==progress["played"] and mg.effort==int(progress["effort"]) and mg.offer==float(progress["offer"]),"Board work rerolled on reload: "+kind)
		for round_i in range(5):
			if kind=="repair":
				for i in range(3):
					mg.inspect(i)
					if int(mg.current[i])!=int(mg.target[i]): mg.toggle(i)
			elif kind=="music":
				for i in range(mg.played.size(),mg.notes.size()): mg.note(int(mg.notes[i]))
			else: mg.offer_slider.value=80+round_i*4; mg.scope_slider.value=80
			mg.submit_round(); mg.next_round()
		mg.finish(0,{})
		ok(results.size()==1 and float(results[0][0])>=0.6 and results[0][1]["rounds"]==5,"Execution/result guard failed: "+kind)
		mg.queue_free(); await frames()
		# A wrong round gives actionable feedback and a smaller score.
		mg=load("res://scenes/minigames/mg_hands_on.gd").new(); mg.setup({"kind":kind,"skill":100,"rounds":1})
		var bad: Array=[]; mg.finished.connect(func(score,detail): bad.append(score)); add_child(mg); await frames()
		if kind=="music":
			for note in mg.notes: mg.note((int(note)+1)%5)
		elif kind=="negotiation": mg.offer_slider.value=35; mg.scope_slider.value=50
		mg.submit_round(); mg.next_round()
		ok(bad.size()==1 and float(bad[0])<0.6,"Wrong execution still receives full rewards: "+kind)
		mg.queue_free(); await frames()
	for message in failures: print("FAIL: "+str(message))
	print("QUALITY TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
