extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func clear_events() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh(age: int=30) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=age; GameState.player["money"]=10000; GameState.player["time_left"]=100
	clear_events()
func year() -> void:
	GameState.player["age"]=int(GameState.player["age"])+1; GameState.player["time_left"]=100; clear_events()
func answer(value: int) -> void:
	var prompt: Dictionary=Journey.state()["prompt"]
	var position: int=prompt["args"].get("order",[0,1,2]).map(func(i): return int(i)).find(value)
	var spec: Dictionary=prompt["def"]["choices"][position]["outcomes"][0]["journey"].duplicate(true)
	Journey.outcome(spec); clear_events()
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes(); seed(79)
	fresh()
	var paths=Journey.modules["pathways"]
	ok(paths.scenes.size()==48,"Authored pathway content missing")
	var titles: Dictionary={}
	for scene in paths.scenes:
		titles[scene["text"]]=true
		ok(scene["answers"].size()==3 and scene["endings"].size()==3 and str(scene["partial"])!="","A choice has no conclusion")
	ok(titles.size()==48,"Repeated authored situation")
	var friend := GameState.create_npc("friend",{"age":30,"closeness":90})
	var uid := FamilyChronicle.identity(GameState.npc(friend))
	paths.record("work","checked-brief","Tech",90,true,uid)
	var entry: Dictionary=paths.st()["cases"][0]
	paths.record("work","checked-brief","Tech",90,true,uid)
	ok(paths.st()["cases"].size()==1,"Duplicate source creates another follow-up")
	paths.follow(int(entry["id"]))
	ok(Journey.state()["prompt"].is_empty(),"Follow-up opens before its due year")
	year(); var cash := int(GameState.player["money"]); paths.follow(int(entry["id"]))
	ok(not Journey.state()["prompt"].is_empty(),"Due follow-up is not playable")
	ok(GameState.player["money"]==cash-paths.price(entry),"Cost is not charged once")
	ok(Employment.st()["booked_expenses"].get("Connection follow-up",0)==paths.price(entry),"Actual cost missing from ledger")
	var spec: Dictionary=Journey.state()["prompt"]["def"]["choices"][0]["outcomes"][0]["journey"].duplicate(true)
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict())))
	entry=paths.st()["cases"][0]; entry["chance"]=1.0
	ok(Journey.state()["prompt"]["args"]["id"]==entry["id"] and entry["uid"]==uid,"Reload rerolls case or named person")
	answer(0)
	var trust := BondStats.get_stat(friend,"trust"); cash=GameState.player["money"]
	Journey.outcome(spec)
	ok(BondStats.get_stat(friend,"trust")==trust and GameState.player["money"]==cash,"Stale answer applies rewards twice")
	ok(paths.support("Tech")==0,"Support awarded before actual follow-up")
	year(); paths.yearly(); entry=paths.st()["cases"][0]
	ok(entry["state"]=="closed" and str(entry["conclusion"])!="","Successful choice has no dated conclusion")
	ok(Journey.modules["people"].motive(friend)["favours"]==0,"New opportunity leaks into a shared NPC favour counter instead of its owner's record")
	ok(paths.support("Tech")>0 and paths.support("Care")==0,"Support is not field-specific")
	var sample := {"field":"Tech","support":0}; var option := {"chance":0.5}
	var supported := Employment.project_chance(sample,option)
	var job: Dictionary=ContentDB.jobs.filter(func(j): return j.get("field","")=="Tech")[0]
	var opening := {"job":job["id"],"exp":0,"apps":10}
	var fit: Dictionary=Market.standing(opening)
	ok(fit["lines"].any(func(line): return line[0]=="A trusted connection"),"Hiring does not explain actual support")
	BondStats.apply(friend,{"trust":-100})
	ok(paths.support("Tech")==0 and Employment.project_chance(sample,option)<supported,"Lost trust does not remove actual work benefit")
	ok(Market.standing(opening)["chance"]<fit["chance"],"Lost trust does not remove actual hiring benefit")
	BondStats.apply(friend,{"trust":100})
	var skill := Market.skill("Tech"); paths.yearly()
	ok(Market.skill("Tech")==skill,"Yearly replay gives extra skill")
	for i in range(2): year(); paths.yearly()
	ok(paths.support("Tech")==0,"Temporary support never expires")
	fresh(12); paths=Journey.modules["pathways"]
	friend=GameState.create_npc("friend",{"age":12,"closeness":70}); uid=FamilyChronicle.identity(GameState.npc(friend))
	paths.record("school","young-project","Tech",75,true,uid); year()
	GameState.player["money"]=0; paths.follow(1)
	ok(not Journey.state()["prompt"].is_empty() and GameState.player["money"]==0,"Child follow-up creates debt or requires adult funds")
	paths.st()["cases"][0]["chance"]=0; answer(0); year(); paths.yearly()
	ok(not paths.st()["cases"][0]["success"] and paths.support("Tech")==0,"Unsuccessful attempt grants support")
	fresh(); paths=Journey.modules["pathways"]
	friend=GameState.create_npc("friend",{"age":30,"closeness":90}); uid=FamilyChronicle.identity(GameState.npc(friend))
	paths.record("people","bad-promise","General",30,false,uid); year(); paths.follow(1)
	ok(paths.st()["cases"][0]["scene"]["repair"],"Broken commitment gets an unrelated success scene")
	answer(2); trust=BondStats.get_stat(friend,"trust"); year(); paths.yearly()
	ok(BondStats.get_stat(friend,"trust")<trust and paths.st()["cases"][0]["state"]=="closed","Dishonest choice has no lasting aftermath")
	paths.record("work","untaken","Tech",90,true,uid)
	trust=BondStats.get_stat(friend,"trust")
	for i in range(4): year()
	paths.yearly()
	ok(paths.st()["cases"][0]["state"]=="expired" and BondStats.get_stat(friend,"trust")==trust,"Optional invitation invents a promise penalty")
	paths.record("enterprise","lost-contact","Business",90,true,uid); year()
	GameState.npc(friend)["alive"]=false; cash=GameState.player["money"]; paths.follow(int(paths.st()["cases"][0]["id"]))
	ok(paths.st()["cases"][0]["state"]=="ended" and GameState.player["money"]==cash,"Dead contact charges a fee or awards support")
	# Real system hooks, not just direct record calls.
	fresh(15); paths=Journey.modules["pathways"]
	GameState.player["education"]["stage"]="secondary"
	var school=Journey.modules["school"]; school.start("science"); clear_events()
	var peer_uid: String=school.st()["project"]["peer"]
	ok(peer_uid!="" and Journey.person(peer_uid)!="","School project has no actual saved peer")
	for i in range(3):
		if i>0: year()
		school.step(); answer(0)
	ok(not paths.st()["cases"].is_empty() and paths.st()["cases"][0]["uid"]==peer_uid,"Actual school completion does not retain its classmate")
	fresh(); paths=Journey.modules["pathways"]
	var people=Journey.modules["people"]; friend=GameState.create_npc("friend",{"age":30,"closeness":75})
	people.promise(friend,"visit"); clear_events(); people.fulfil(0); clear_events()
	ok(paths.st()["cases"].size()==1 and paths.st()["cases"][0]["domain"]=="people","Kept promise does not connect to future help")
	var business=Journey.modules["enterprise"]; business.start("service"); clear_events()
	for i in range(3): business.step(); answer(0)
	ok(paths.st()["cases"].any(func(p): return p["domain"]=="enterprise"),"Actual enterprise delivery has no continuing client")
	paths.record("work","dormant-work","Tech",90,true)
	year(); paths.follow(int(paths.st()["cases"][0]["id"])); paths.st()["cases"][0]["chance"]=1.0; answer(0)
	var child := GameState.create_npc("child",{"age":24,"gender":"female"})
	var parent_cases: Array=paths.st()["cases"].duplicate(true)
	clear_events(); ok(Dynasty.switch_to(child),"Living child transfer fails")
	ok(Journey.modules["pathways"].st()["cases"].is_empty(),"Parent contacts were silently assigned to child")
	var former := GameState.npcs.values().filter(func(n): return not n.get("playable_player",{}).get("journey",{}).get("pathways",{}).get("cases",[]).is_empty())
	ok(not former.is_empty() and former[0]["playable_player"]["journey"]["pathways"]["cases"]==parent_cases,"Parent history lost on transfer")
	var child_cash := int(GameState.player["money"]); var child_skill := Market.skill("Tech")
	var parent_skill := int(former[0]["playable_player"].get("professional_skills",{}).get("Tech",0))
	year(); paths.background(former[0],GameState.year_now())
	var dormant: Dictionary=former[0]["playable_player"]["journey"]["pathways"]["cases"][0]
	ok(dormant["state"]=="closed" and int(former[0]["playable_player"]["professional_skills"]["Tech"])==mini(10,parent_skill+1),"Dormant parent's chosen follow-up does not settle for its owner")
	ok(GameState.player["money"]==child_cash and Market.skill("Tech")==child_skill,"Dormant parent's follow-up rewards the active child")
	paths.background(former[0],GameState.year_now())
	ok(int(former[0]["playable_player"]["professional_skills"]["Tech"])==mini(10,parent_skill+1),"Dormant follow-up pays twice")
	fresh(); paths=Journey.modules["pathways"]
	var used: Dictionary={}
	var supply: int=paths.scenes.filter(func(scene): return scene["domain"]=="work" and not scene["repair"]).size()
	for i in range(supply+1):
		paths.record("work","pool:"+str(i),"Tech",90,true)
		year(); var before_cash := int(GameState.player["money"]); var before_time := int(GameState.player["time_left"])
		paths.follow(int(paths.st()["cases"][0]["id"]))
		if i<supply:
			var scene: Dictionary=paths.st()["cases"][0]["scene"]
			ok(not used.has(scene["id"]),"Authored follow-up repeats within the same life")
			used[scene["id"]]=true; answer(1)
		else:
			ok(Journey.state()["prompt"].is_empty() and GameState.player["money"]==before_cash and GameState.player["time_left"]==before_time,"Exhausted scene pool replays or charges resources")
	var curriculum: Array=Journey.modules["school"].curriculum.filter(func(q): return str(q["id"]).begins_with("curriculum.connected."))
	ok(curriculum.size()==32,"New age-specific curriculum missing")
	for band in range(4): ok(curriculum.filter(func(q): return q["band"]==band).size()==8,"An age band has no new curriculum")
	print("PATHWAYS TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
