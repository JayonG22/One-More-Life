extends Node
var checks := 0
var failures: Array=[]
var r
var w
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func clear() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear(); Journey.state()["prompt"]={}
func fresh(age: int = 35) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false,"born_year":1980})
	GameState.player["age"]=age; GameState.player["time_left"]=200; GameState.player["money"]=100000
	GameState.player["stats"]["stress"]=20
	GameState.settings["recovery_stories"]="standard"
	r=Journey.modules["resilience"]; w=Journey.modules["wellbeing"]; clear()
func habit(id: String, level: float = 85, active: bool = true) -> void:
	GameState.player["habits"][id]={"level":level,"active":active,"clean":-1,"touched":GameState.player["age"]}
func reload() -> void:
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
func next_year() -> void:
	GameState.player["age"]+=1; GameState.player["time_left"]=200; clear()
func packet(id: String, answer: int = 0, roll: float = 0.0) -> Dictionary:
	return {"owner":Journey.uid(),"year":GameState.year_now(),"id":id,"effects":{"money":-500,"health":-5,"stress":8},"chance":0.5,"roll":roll,"answer":answer}
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; GameState.settings["effects"]=false; Fx.apply_volumes()
	fresh(); var endings: Dictionary={}; var texts: Dictionary={}
	ok(r.scenes.size()==24,"Recovery scene pool missing")
	for scene in r.scenes:
		texts[scene["text"]]=true
		for ending in scene["results"]: endings[ending]=true
	ok(texts.size()==24 and endings.size()==72,"Pressure stories or endings repeat")
	for id in Grit.HABITS:
		for route in ["community","outpatient","residential"]:
			fresh(); habit(id); var cash: int=GameState.player["money"]; var time: int=GameState.player["time_left"]
			r.begin(id,route); clear()
			ok(r.plan(id)["route"]==route and GameState.player["habits"][id]["active"],"Intake acts as instant cure: "+id+route)
			ok(GameState.player["money"]==cash-Actions._cost({"community":40,"outpatient":700,"residential":8000}[route]) and GameState.player["time_left"]==time-(4 if route=="residential" else 2),"Missing intake payment/time: "+id+route)
			var paid: int=GameState.player["money"]; r.begin(id,"outpatient" if route!="outpatient" else "community"); clear()
			ok(GameState.player["money"]==paid,"Repeated intake in same year")
			r.session(id); clear(); var level: float=GameState.player["habits"][id]["level"]; cash=GameState.player["money"]; time=GameState.player["time_left"]
			r.session(id); clear(); ok(GameState.player["money"]==cash and GameState.player["time_left"]==time and GameState.player["habits"][id]["level"]==level,"Repeated session farm")
			reload(); ok(r.plan(id)["sessions"]==1 and r.plan(id)["route"]==route,"Reload loses ongoing programme")
		fresh(); habit(id,30); r.yearly(); ok(GameState.player["habits"][id]["active"] and r.plan(id)["stable"]==1,"Recovery requires more than one stable year")
		var hist: int=r.st()["history"].size(); r.yearly(); ok(r.plan(id)["stable"]==1 and r.st()["history"].size()==hist,"Annual milestone settles twice")
		next_year(); r.yearly(); ok(not GameState.player["habits"][id]["active"] and r.plan(id)["milestones"]==1,"Two stable years do not recover: "+id)
		r.plan(id)["route"]="residential"; r.aftercare(id); clear(); ok(r.plan(id)["route"]=="self-led" and r.plan(id)["milestones"]==1,"Aftercare loses milestone")
		var beaten: int=GameState.player["counters"].get("habits_beaten",0)
		Grit.habit(id,100); clear(); ok(GameState.player["habits"][id]["active"] and r.plan(id)["relapses"]==1 and r.plan(id)["milestones"]==1,"Exposure erases progress instead of retaining setback")
		habit(id,30); r.plan(id)["exposed"]=-99; next_year(); r.yearly(); next_year(); r.yearly()
		ok(r.plan(id)["milestones"]==2 and GameState.player["counters"].get("habits_beaten",0)==beaten,"Repeated recovery milestone farms achievement count")
		fresh(); habit(id); var seen: Dictionary={}
		for i in range(4):
			r.compulsion("🌱","","",{"money":-500,"health":-3},id)
			ok(EventEngine.pending.size()==1,"Pressure scene was not queued: "+id)
			if EventEngine.pending.is_empty(): break
			var inst: Dictionary=EventEngine.pending.pop_front(); var title: String=inst["def"]["title"]
			ok(not seen.has(title),"Pressure scene repeats within life"); seen[title]=true
			var cost: int=Actions._cost(40); var money: int=GameState.player["money"]; var health: float=GameState.stat("health")
			var resolved: Dictionary=EventEngine.resolve(inst,2); clear()
			ok(GameState.player["money"]==money-cost and GameState.stat("health")==health and resolved["text"]!="","Support decision misses fee, harm prevention or conclusion")
			reload(); next_year()
		ok(seen.size()==4,"Missing habit-specific scene coverage")
		r.plan(id)["boundary"]="help"; r.compulsion("🌱","","",{"money":-500},id)
		ok(EventEngine.pending.is_empty() and Journey.used("recovery_pressure:"+id),"Exhausted pool repeats instead of using saved boundary")
	fresh(14); habit("drinking"); GameState.player["money"]=17; var covered: int=Childhood.st()["covered"]
	r.begin("drinking","community"); clear(); r.session("drinking"); clear()
	ok(GameState.player["money"]==17 and Childhood.st()["covered"]==covered+Actions._cost(80),"Minor recovery drains personal gifts")
	var old_route: String=r.plan("drinking")["route"]; r.begin("drinking","residential"); ok(r.plan("drinking")["route"]==old_route,"Minor residential eligibility bypass")
	var result: String=r.outcome(packet("drinking",1)); ok(GameState.player["money"]==0 and result!="","Child annual setback creates personal debt")
	fresh(13); habit("gambling"); r.session("gambling"); r.begin("gambling","community"); ok(r.plan("gambling")["sessions"]==0 and r.plan("gambling")["route"]=="self-led","Underage recovery bypass")
	fresh(); habit("gambling"); GameState.player["money"]=0; var time: int=GameState.player["time_left"]; r.begin("gambling","residential"); r.session("gambling"); clear()
	ok(GameState.player["time_left"]==time and r.plan("gambling")["sessions"]==0,"Unfunded appointment consumes time")
	GameState.player["money"]=100000; GameState.player["time_left"]=0; r.session("gambling"); clear(); ok(r.plan("gambling")["sessions"]==0,"No-time session is accepted")
	fresh(); habit("gambling"); var friend := GameState.create_npc("friend",{"age":30,"closeness":80}); var uid: String=FamilyChronicle.identity(GameState.npc(friend))
	r.set_buddy("gambling",uid); clear(); ok(r.buddy_available("gambling") and not GameState.npc(friend)["personal_history"].is_empty(),"Actual contact agreement missing")
	var resistance: float=r.resistance("gambling"); GameState.npc(friend)["alive"]=false; ok(not r.buddy_available("gambling") and r.resistance("gambling")<resistance,"Dead contact still helps")
	fresh(); habit("gambling"); GameState.player["stats"]["health"]=100; GameState.player["stats"]["happiness"]=100; GameState.player["stats"]["stress"]=0; GameState.player["hidden"]["willpower"]=100
	r.session("gambling"); clear(); var high: float=85-GameState.player["habits"]["gambling"]["level"]
	fresh(); habit("gambling"); GameState.player["stats"]["health"]=20; GameState.player["stats"]["happiness"]=10; GameState.player["stats"]["stress"]=90; GameState.player["hidden"]["willpower"]=0
	r.session("gambling"); clear(); ok(85-GameState.player["habits"]["gambling"]["level"]<high,"Readiness does not change session progress")
	fresh(); habit("shopping"); var cash: int=GameState.player["money"]; var health: float=GameState.stat("health"); var p := packet("shopping",0,0.9)
	result=r.outcome(p); ok(GameState.player["money"]==cash-500 and GameState.stat("health")==health-5 and result.contains("did not hold"),"Failed pause has false success text or absent consequences")
	cash=GameState.player["money"]; r.outcome(p); ok(GameState.player["money"]==cash,"Replayed packet charges twice")
	fresh(); habit("shopping"); p=packet("shopping",2,0.0); GameState.player["time_left"]=0; cash=GameState.player["money"]; result=r.outcome(p)
	ok(GameState.player["money"]==cash and result.contains("unavailable") and Journey.used("recovery_pressure:shopping"),"Unavailable automatic support stalls without fallback")
	fresh(); habit("shopping"); p=packet("shopping",1); p["owner"]="someone else"; cash=GameState.player["money"]; r.outcome(p); ok(GameState.player["money"]==cash,"Foreign owner's prompt changes new life")
	p=packet("shopping",1); p["year"]-=1; r.outcome(p); ok(GameState.player["money"]==cash,"Old-year pressure applies")
	fresh(); habit("shopping"); Grit._habits_yearly(); var count: int=EventEngine.pending.size(); var level: float=GameState.player["habits"]["shopping"]["level"]; Grit._habits_yearly()
	ok(EventEngine.pending.size()==count and GameState.player["habits"]["shopping"]["level"]==level,"Annual habit harm repeats"); clear()
	fresh(); habit("shopping"); r.compulsion("🌱","","",{"money":-500},"shopping"); var choice: Dictionary=EventEngine.pending[0]["def"]["choices"][2]; GameState.player["time_left"]=0
	ok(not EventEngine.choice_state(choice)["enabled"],"Support time requirement invisible"); GameState.player["time_left"]=5; GameState.player["money"]=0
	ok(not EventEngine.choice_state(choice)["enabled"],"Support fee requirement invisible"); clear()
	fresh(); habit("shopping"); r.support("shopping","therapy",12); var pressure: float=GameState.player["habits"]["shopping"]["level"]; r.support("shopping","therapy",12)
	ok(GameState.player["habits"]["shopping"]["level"]==pressure and GameState.player["habits"]["shopping"]["active"],"Therapy repeats or instantly cures")
	var child := GameState.create_npc("child",{"age":23,"money":3000,"health":80}); var child_n: Dictionary=GameState.npc(child)
	child_n["habits"]={"shopping":{"level":30.0,"active":true,"clean":-1,"touched":23}}
	r.plan("shopping",child_n)["boundary"]="help"; var child_history: Dictionary=child_n["journey"].duplicate(true)
	ok(Dynasty.switch_to(child),"Recovery child cannot become playable")
	ok(GameState.player["habits"]["shopping"]["level"]==30 and Journey.state()["resilience"]==child_history["resilience"],"Living transfer invents habit or loses child plan")
	reload(); ok(r.plan("shopping")["boundary"]=="help","Saved successor loses pressure plan")
	var former_ids: Array=GameState.npcs_with("mother").filter(func(id): return GameState.npc(id).has("playable_player")); ok(not former_ids.is_empty(),"Former player's recovery snapshot missing")
	if not former_ids.is_empty():
		var n: Dictionary=GameState.npc(former_ids[0]); n["money"]=10000; r.plan("shopping",n)["boundary"]="help"
		var future := GameState.year_now()+1; r.background(n,future); var cash_n: int=n["money"]; var snapshot := JSON.stringify(n["journey"]["resilience"])
		ok(cash_n==10000-Actions._cost(40) and n["habits"]["shopping"]["level"]<pressure,"Off-screen support does not affect real money and pressure")
		r.background(n,future); ok(n["money"]==cash_n and JSON.stringify(n["journey"]["resilience"])==snapshot,"Background support settles twice")
		ok(n["playable_player"]["habits"]==n["habits"] and n["playable_player"]["journey"]["resilience"]==n["journey"]["resilience"],"Recovery snapshot diverges off screen")
	fresh(); var heir := GameState.create_npc("child",{"age":23,"money":1000}); GameState.npc(heir)["habits"]={"drinking":{"level":20.0,"active":false,"clean":22,"touched":20}}
	r.plan("drinking",GameState.npc(heir))["milestones"]=1; GameState.player["alive"]=false; clear(); GameState.continue_as(heir)
	ok(GameState.player["habits"]["drinking"]["clean"]==22 and r.plan("drinking")["milestones"]==1,"Inheritance loses actual recovery history")
	fresh(); habit("gambling"); GameState.player["habits"]["gambling"]["active"]=false; GameState.player["habits"]["gambling"]["clean"]=30
	ok(r.plan("gambling")["milestones"]==1 and r.plan("gambling")["status"]=="maintaining","Legacy recovered habit loses prior recovery")
	fresh(); habit("gambling"); r.compulsion("🌱","","",{"money":-500},"gambling"); r.compulsion("🌱","","",{"money":-500},"gambling")
	ok(EventEngine.pending.size()==1,"A queued pressure prompt duplicates before resolution"); clear()
	fresh(); habit("gambling"); r.begin("gambling","community"); clear(); next_year(); r.begin("gambling","outpatient"); clear()
	ok(r.plan("gambling")["route"]=="outpatient" and r.plan("gambling")["sessions"]==0,"A new year cannot change programme")
	fresh(); habit("shopping"); var prof := GameState.create_npc("child",{"age":14,"money":77,"health":80,"parent_uids":[Journey.uid()]}); var minor: Dictionary=GameState.npc(prof)
	minor["habits"]={"shopping":{"level":80.0,"active":true,"clean":-1,"touched":14}}; r.plan("shopping",minor)["boundary"]="help"
	cash=GameState.player["money"]; r.background(minor,GameState.year_now()+1)
	ok(minor["money"]==77 and GameState.player["money"]==cash-Actions._cost(40),"Minor background support misses household funding")
	ok(r.st(minor)["household_covered"]==Actions._cost(40),"Minor background funding has no record")
	fresh(); habit("gambling"); r.plan("gambling")["route"]="outpatient"; GameState.player["stats"]["happiness"]=50; GameState.player["stats"]["health"]=50; GameState.player["stats"]["stress"]=50; GameState.player["hidden"]["willpower"]=50
	GameState.player["difficulty"]="classic"; r.session("gambling"); clear(); var classic: float=85-GameState.player["habits"]["gambling"]["level"]
	fresh(); habit("gambling"); r.plan("gambling")["route"]="outpatient"; GameState.player["stats"]["happiness"]=50; GameState.player["stats"]["health"]=50; GameState.player["stats"]["stress"]=50; GameState.player["hidden"]["willpower"]=50
	GameState.player["difficulty"]="gritty"; r.session("gambling"); clear(); ok(85-GameState.player["habits"]["gambling"]["level"]<classic,"Difficulty does not affect recovery effort")
	GameState.player["difficulty"]="real"
	fresh(); habit("gambling"); GameState.player["stats"]["stress"]=100; GameState.player["habits"]["gambling"]["active"]=false; GameState.player["habits"]["gambling"]["clean"]=30
	var found := false
	for trial in range(200):
		w.st()["seed"]=trial
		if w.roll("Recovery setback:gambling")<0.2: found=true; break
	ok(found,"Cannot exercise annual setback fixture"); r.plan("gambling")["sessions"]=4; r.yearly()
	ok(GameState.player["habits"]["gambling"]["active"] and r.plan("gambling")["relapses"]==1 and r.plan("gambling")["sessions"]==4 and r.plan("gambling")["milestones"]==1,"Annual setback resets earlier recovery record")
	fresh(); habit("workaholic"); var partner := GameState.create_npc("partner",{"age":35,"closeness":80}); var trust: float=BondStats.ensure(partner)["trust"]
	r.outcome(packet("workaholic",1)); ok(BondStats.ensure(partner)["trust"]<trust,"Overwork setback has no family consequence")
	fresh(); habit("gambling"); GameState.player["alive"]=false; cash=GameState.player["money"]; r.session("gambling"); r.outcome(packet("gambling",1)); r.support("gambling","therapy")
	ok(GameState.player["money"]==cash and GameState.player["habits"]["gambling"]["level"]==85,"Finished life still accepts recovery changes")
	fresh(); habit("gambling"); r.plan("gambling")["boundary"]="help"; r.act("stories","quiet"); cash=GameState.player["money"]
	r.compulsion("🌱","","",{"money":-500},"gambling")
	ok(EventEngine.pending.is_empty() and GameState.player["money"]==cash-Actions._cost(40),"Quiet recovery fails to use saved plan")
	ok(Novelty.state()["ids"].keys().filter(func(id): return str(id).begins_with("recovery.pressure.")).is_empty(),"Quiet plan consumes an unseen story")
	fresh(); GameState.settings["recovery_stories"]="often"
	for id in Grit.HABITS:
		habit(id); r.compulsion("🌱","","",{"money":-500},id)
	ok(EventEngine.pending.size()==3,"Often recovery exceeds its three-scene budget"); clear()
	GameState.settings["recovery_stories"]="standard"
	fresh(); habit("gambling"); Expansion.mental_action("therapy"); clear()
	ok(GameState.player["habits"]["gambling"]["level"]==73 and r.st()["history"][0]["text"].begins_with("therapy"),"Actual therapy uses the wrong support record")
	Expansion.mental_action("support"); clear()
	ok(GameState.player["habits"]["gambling"]["level"]==61 and r.st()["history"][0]["text"].begins_with("group"),"Actual support group has no distinct effect/record")
	var previous: float=GameState.player["habits"]["gambling"]["level"]; Expansion.mental_action("support"); clear(); Grit.therapy_helps()
	ok(GameState.player["habits"]["gambling"]["level"]==previous,"Older therapy/group routes repeat pressure rewards")
	print("RESILIENCE TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
