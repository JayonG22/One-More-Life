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
	GameState.player["age"]=age; GameState.player["money"]=200000; GameState.player["time_left"]=100
	GameState.settings["minigames"]=false; GameState.settings["volume"]=0; Fx.apply_volumes()
	clear_events()
func answer(value: int) -> void:
	var event := EventEngine.pop_next()
	while not event.is_empty() and str(event.get("def",{}).get("id",""))!="_journey": event=EventEngine.pop_next()
	if event.is_empty(): failures.append("Journey choice was not queued"); return
	EventEngine.resolve(event,value); EventEngine.displayed.clear()
	EventEngine.pending=EventEngine.pending.filter(func(it): return str(it.get("def",{}).get("id",""))=="_journey")
func correct() -> int:
	return Journey.state()["prompt"]["args"]["order"].find(0)
func year() -> void:
	clear_events(); GameState.player["age"]=int(GameState.player["age"])+1; GameState.player["time_left"]=100
func _ready() -> void:
	seed(4040); fresh()
	ok(Journey.modules.size()>=8,"Combined milestone modules missing")
	var destinations: Array=[]
	for group in Journey.GROUPS:
		for row in Journey.menu("group:"+group)["rows"]: destinations.append(row["menu"].get_slice(":",1))
	ok(destinations.size()==Journey.DOMAINS.size() and Journey.DOMAINS.keys().all(func(domain): return destinations.count(domain)==1),"Grouped hub lost or duplicated a destination")
	var people=Journey.modules["people"]
	var friend := GameState.create_npc("friend",{"age":30,"closeness":65})
	people.promise(friend,"visit"); clear_events()
	var promises: int = people.st()["promises"].size()
	people.promise(friend,"visit")
	ok(people.st()["promises"].size()==promises,"Duplicate promise")
	var trust := BondStats.get_stat(friend,"trust")
	people.fulfil(0); clear_events()
	ok(people.st()["promises"][0]["state"]=="kept" and BondStats.get_stat(friend,"trust")>trust,"Promise not remembered")
	trust=BondStats.get_stat(friend,"trust"); people.fulfil(0)
	ok(BondStats.get_stat(friend,"trust")==trust,"Promise replay reward")
	people.promise(friend,"help"); clear_events(); year(); year(); people.yearly(); clear_events()
	ok(people.st()["promises"][0]["state"]=="broken","Missed deadline not enforced")
	var child := GameState.create_npc("child",{"age":9,"closeness":65})
	people.co_parent(child,"shared"); clear_events()
	ok(is_equal_approx(people.support_factor(child),0.65),"Care cost not applied")
	people.contact(child); clear_events()
	ok(people.st()["agreements"][FamilyChronicle.identity(GameState.npc(child))]["visits"]==1,"Care review not recorded")
	fresh(15)
	GameState.player["education"]["stage"]="secondary"
	var school=Journey.modules["school"]
	school.lesson(0)
	var spec: Dictionary=Journey.state()["prompt"]["def"]["choices"][correct()]["outcomes"][0]["journey"].duplicate(true)
	var saved: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.from_dict(saved)
	ok(EventEngine.pending.filter(func(e): return e.get("def",{}).get("id","")=="_journey").size()==1,"Save restore duplicated decision")
	answer(correct()); var performance := float(GameState.player["education"]["performance"])
	Journey.outcome(spec)
	ok(GameState.player["education"]["performance"]==performance,"Stale decision replay")
	school.start("leadership"); clear_events()
	school.step(); answer(1); year(); school.step(); answer(0); year(); school.step(); answer(0)
	ok(school.st()["completed"].size()==1,"Multi-year project not completed")
	ok(school.st()["subjects"].has("funded:study support"),"Council promise only cosmetic")
	ok(school.career_bonus("Politics")>0 and school.career_bonus("Tech")==0,"School pathway not relevant")
	year(); school.yearly(); clear_events()
	ok(school.st()["alumni"],"School to adulthood failed")
	fresh(17); GameState.player["education"]["stage"]="secondary"
	school.start("science"); clear_events(); school.step(); answer(0); year()
	GameState.player["education"]["stage"]="graduated"
	school.st()["project"]["stage"]=2; year(); school.step(); answer(0)
	ok(school.st()["completed"].size()==1,"Final presentation lost at graduation")
	fresh()
	var skills=Journey.modules["skills"]
	var time0 := int(GameState.player["time_left"]); var money0 := int(GameState.player["money"])
	skills.st()["assist"]=true; skills.start("budget",true); clear_events()
	ok(GameState.player["time_left"]==time0 and GameState.player["money"]==money0 and skills.st()["records"].is_empty(),"Practice rewards or charges")
	skills.start("interview",false); clear_events()
	ok(skills.st()["records"].has("interview") and skills.st()["records"]["interview"]["attempts"]==1,"Challenge did not resolve")
	money0=int(GameState.player["money"]); skills.start("interview",false)
	ok(GameState.player["money"]==money0,"Same-year scored retry charged")
	var enterprise=Journey.modules["enterprise"]
	var normal: int=enterprise.startup_cost("service"); enterprise.st()["supplier"]="cheap"
	ok(enterprise.startup_cost("service")<normal,"Cheap supplier has no saving")
	enterprise.st()["supplier"]="reliable"; enterprise.start("service"); clear_events()
	for i in range(3): enterprise.step(); answer(0)
	ok(enterprise.st()["active"].is_empty() and enterprise.st()["history"].size()==1,"Contract not closed")
	money0=int(GameState.player["money"]); enterprise.finish(true)
	ok(GameState.player["money"]==money0,"Contract paid twice")
	enterprise.st()["cashflow"]=[{"due":GameState.year_now()+1,"amount":120,"kind":"service"}]
	year(); enterprise.yearly(); clear_events(); money0=int(GameState.player["money"])
	enterprise.yearly(); clear_events()
	ok(enterprise.st()["cashflow"].is_empty() and GameState.player["money"]==money0,"Late invoice paid twice")
	var places=Journey.modules["places"]
	var destination := ""
	for r in Places.regions("us"):
		if r["id"]!=GameState.player["region"]: destination=str(r["id"]); break
	places.prepare_move(destination); clear_events()
	ok(places.prepared(destination),"Move preparation missing")
	money0=int(GameState.player["money"]); Places.relocate("invalid")
	ok(GameState.player["money"]==money0,"Invalid region charged")
	places.prepare_migration("uk"); clear_events()
	ok(places.migration_bonus("uk")>0,"Migration preparation has no effect")
	places.arrived("uk"); places.review_credentials(); clear_events()
	ok(places.st()["migration"]["reviewed"] and not GameState.player["licenses"].has("doctor"),"Credential review granted fake licence")
	GameState.player["housing"]="house"; GameState.player["house_uid"]="houseA"
	places.adapt("workspace"); clear_events()
	ok(places.st()["adaptations"].has("workspace"),"Home adaptation missing")
	GameState.player["house_uid"]="houseB"; year(); places.adapt("accessible"); clear_events()
	ok(not places.st()["adaptations"].has("workspace"),"Adaptation moved to new home")
	places.start("library"); clear_events()
	for i in range(3): places.step(); answer(0); year()
	ok(places.institution()["library"]==1 and places.hiring_bonus("Education")>0,"Institution did not persist")
	var recovery=Journey.modules["recovery"]
	recovery.begin_trial("fictional allegation",1,3,70)
	answer(0)
	for i in range(3): answer(correct())
	ok(recovery.st()["case"].is_empty() and recovery.st()["history"].size()==1 and recovery.st()["history"][0]["answers"]==3,"Actual hearing sequence failed")
	money0=int(GameState.player["money"]); recovery.resolve("representation",{},2)
	ok(GameState.player["money"]==money0,"Court representation replay charged")
	GameState.player["prison"]=0; clear_events(); recovery.reentry("support"); clear_events()
	GameState.player["record"]=[]; recovery.reentry("housing")
	ok(not recovery.st()["reentry"]["housing"],"Re-entry available without history")
	clear_events(); Expansion.ensure(); GameState.player["medical"]["injuries"]["knee"]={"left":3}
	recovery.care("paced"); clear_events(); year(); recovery.yearly()
	recovery.care("supported"); clear_events(); year(); recovery.yearly()
	ok(GameState.player["medical"]["injuries"]["knee"]["left"]==2,"Consistent recovery did not affect actual injury")
	clear_events()
	var partner := GameState.create_npc("partner",{"age":30,"closeness":80})
	Journey.modules["identity"].discuss(partner)
	var partner_uid := FamilyChronicle.identity(GameState.npc(partner))
	var wanted: String=Journey.modules["identity"].st()["relationships"][partner_uid]["preference"]
	answer(1 if wanted=="exclusive" else 0)
	ok(Journey.modules["identity"].st()["relationships"][partner_uid]["agreement"]=="exclusive","Adult agreement overridden without consent")
	fresh(60)
	var heritage=Journey.modules["heritage"]
	child=GameState.create_npc("child",{"age":25,"closeness":75,"money":170,"smarts":72})
	GameState.player["possessions"]=[{"id":"watch","name":"Family watch","value":100}]
	heritage.gift(child,0); clear_events()
	ok(GameState.player["possessions"].is_empty() and GameState.npc(child)["possessions"].size()==1,"Heirloom duplicated")
	heritage.mentor(child); clear_events()
	ok(GameState.npc(child)["professional_skills"].values()[0]==1,"Mentor skill not owned by child")
	heritage.plan("heir:"+child); clear_events(); heritage.executor(child); clear_events()
	ok(heritage.st()["plan"]["executor"]==FamilyChronicle.identity(GameState.npc(child)),"Executor not identified")
	for i in range(3): heritage.memoir(); answer(i); year()
	ok(GameState.world["family_memoirs"].has(Journey.uid()),"Memoir lost outside viewpoint")
	Ambition.ensure(); GameState.player["ambition"]["enterprise"]["portfolio"]=[{"name":"Test company","ind":"tech","value":1000,"stake":1.0,"ceo":"","quality":50,"years":1}]
	heritage.handover(child); clear_events()
	ok(GameState.player["ambition"]["enterprise"]["portfolio"].is_empty() and GameState.npc(child)["ambition"]["enterprise"]["portfolio"].size()==1,"Company duplicated on handover")
	Journey.background_companies(GameState.year_now())
	var child_cash := int(GameState.npc(child)["money"])
	Journey.background_companies(GameState.year_now())
	ok(child_cash>170 and GameState.npc(child)["money"]==child_cash,"Dormant companies absent or paid twice")
	var parent_uid := Journey.uid(); var child_uid := FamilyChronicle.identity(GameState.npc(child))
	ok(Dynasty.switch_to(child),"Living viewpoint transfer failed")
	ok(Journey.uid()==child_uid and GameState.player["money"]==child_cash and GameState.player["possessions"].size()==1,"Living transfer invented inheritance or lost gift")
	ok(GameState.world["family_memoirs"].has(parent_uid),"Family memoir vanished")
	var parent_id := Journey.person(parent_uid)
	var former: Dictionary=GameState.npc(parent_id)["playable_player"]
	former["journey"]["people"]={"promises":[{"uid":Journey.uid(),"name":"My child","kind":"visit","state":"open","due":GameState.year_now()-1}],"reliability":50}
	Journey.background_commitments(GameState.year_now())
	ok(former["journey"]["people"]["promises"][0]["state"]=="broken","Dormant parent deadline froze")
	fresh(60); child=GameState.create_npc("child",{"age":25,"money":99,"smarts":72})
	var sibling := GameState.create_npc("child",{"age":23,"money":10})
	GameState.npc(child)["journey"]={"school":{"project":{},"completed":[{"field":"Tech","quality":80}],"subjects":{},"mentor":"","background":{},"alumni":true,"last_band":-1}}
	GameState.player["will"]="heir:"+child; parent_uid=Journey.uid(); GameState.player["alive"]=false
	GameState.continue_as(child)
	ok(GameState.world["estate_register"][parent_uid]["status"]=="executed","Estate not registered")
	ok(GameState.player["money"]==99+int(GameState.world["estate_register"][parent_uid]["cash"]),"Child cash duplicated by inheritance")
	ok(not Journey.modules["heritage"].st()["estate_dispute"].is_empty(),"Unequal estate has no sibling dispute")
	ok(Journey.modules["school"].career_bonus("Tech")>0 and GameState.stat("smarts")==72,"Heir lost personal progress")
	var identity=Journey.modules["identity"]
	GameState.settings["content_themes"]={"crime":false}
	ok(not TVLife.available("harbour_echoes") and TVLife.available("last_greenhouse"),"Theme opt-out ignored by original picker")
	GameState.settings["content_themes"]={}
	GameState.player["stats"]["health"]=20
	ok(identity.pose()["tint"]!=Color.WHITE,"Portrait health status missing")
	for type in identity.MODES:
		GameState.new_life({"country":"us","life_path":type,"random_royalty":false})
		GameState.player["age"]=30; GameState.player["time_left"]=100
		if type in ["witch","vampire","super"]: Lives.become(type)
		if type=="revenant": GameState.player["alive"]=false; Lives.rise()
		clear_events()
		for i in range(3): identity.mode_step(); answer(0); year()
		ok(identity.st()["mode_history"].size()==1,"Mode chapter outcome failed: "+type)
		clear_events(); time0=int(GameState.player["time_left"]); identity.mode_step()
		ok(GameState.player["time_left"]==time0,"Completed mode chapter charged again: "+type)
		ok(Journey.menu("root")["rows"].filter(func(row): return row["on"]).size()==1 if Lives.separate() else true,"Separate mode exposed human activities: "+type)
	for id in ["harbour_echoes","last_greenhouse","borrowed_crown","second_first_day"]:
		GameState.new_life({"country":"us","life_path":"tv","character":id}); clear_events()
		var steps := 0
		while GameState.is_alive() and steps<12:
			TVLife.advance(); var event := EventEngine.pop_next()
			EventEngine.resolve(event,0); clear_events(); steps+=1
		ok(not GameState.is_alive() and Lives.life().get("ending","")!="","Campaign has no actual ending: "+id)
		ok(Lives.life()["journal"].size()==steps and Fx.MUSIC.has(id),"Campaign journal/audio missing: "+id)
	for message in failures: print("FAIL: "+str(message))
	print("JOURNEY TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
