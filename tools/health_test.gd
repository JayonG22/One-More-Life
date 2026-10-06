extends Node
var checks := 0
var failures: Array=[]
var w
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func same(a: Variant, b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float): return absf(float(a)-float(b))<0.00001
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not same(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size(): return false
		for i in range(a.size()):
			if not same(a[i],b[i]): return false
		return true
	return a==b
func clear() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear(); Journey.state()["prompt"]={}
func fresh(age: int = 35) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false,"born_year":1980})
	GameState.player["age"]=age; GameState.player["time_left"]=200; GameState.player["money"]=100000
	w=Journey.modules["wellbeing"]; clear()
func diagnose(id: String) -> void:
	GameState.player["medical"]["conditions"][id]={"years":0,"treated":0,"controlled":false,"flares":0}
	GameState.player["illness"]=Expansion.CONDITIONS[id]["name"]
func reload() -> void:
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
func next_year() -> void:
	GameState.player["age"]=int(GameState.player["age"])+1; clear()
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; GameState.settings["effects"]=false; Fx.apply_volumes()
	fresh(); var original_seed: int=w.st()["seed"]; var roll: float=w.roll("saved diagnosis"); reload()
	ok(w.st()["seed"]==original_seed and w.roll("saved diagnosis")==roll,"Clinic roll changes on save reload")
	for id in Expansion.CONDITIONS:
		fresh(); diagnose(id); var money: int=GameState.player["money"]; var time: int=GameState.player["time_left"]
		Expansion.treat_condition(id); clear()
		ok(GameState.player["money"]<money and GameState.player["time_left"]==time-1,"Treatment misses bill/time: "+id)
		var after := GameState.to_dict().duplicate(true); Expansion.treat_condition(id); clear()
		ok(GameState.player["money"]==after["player"]["money"] and GameState.player["time_left"]==after["player"]["time_left"],"Repeat treatment farm: "+id)
		if Expansion.CONDITIONS[id]["chronic"]:
			Actions.do_activity("doctor"); clear(); Daily._doctor("er"); clear()
			ok(GameState.player["medical"]["conditions"].has(id) and GameState.player["illness"]!="","Older doctor erased chronic diagnosis: "+id)
			next_year(); w.before_medical()
			ok(not GameState.player["medical"]["conditions"][id]["controlled"],"Single visit leaves permanent chronic control: "+id)
			w.reviewed(id,"review"); Care.toggle_meds(id); w.manage(id,"balanced"); clear(); next_year(); w.before_medical()
			ok(GameState.player["medical"]["conditions"][id]["controlled"],"Routine/review/medication do not control condition: "+id)
			var snapshot := JSON.stringify(w.plan(id)); w.before_medical()
			ok(JSON.stringify(w.plan(id))==snapshot,"Annual control settles twice: "+id)
			GameState.player["age"]+=3; w.before_medical()
			ok(not GameState.player["medical"]["conditions"][id]["controlled"],"Outdated review stays effective: "+id)
		else:
			ok(w.st()["record"].size()>=2,"Treatment not recorded: "+id)
		ok(w.scenes.filter(func(scene): return scene["condition"]==id).size()==2,"Missing condition-specific care scenes: "+id)
	fresh(); diagnose("diabetes"); Care.toggle_meds("diabetes"); var bill := Care.meds_cost(); GameState.player["medical"]["conditions"].erase("diabetes")
	ok(bill>0 and Care.meds_cost()==0,"Inactive diagnosis keeps generating prescription bills")
	Care.toggle_meds("invented"); ok(not Care.st()["meds"].has("invented"),"Invalid prescription accepted")
	fresh(1); GameState.player["money"]=17; Care.gp_visit(); clear()
	ok(GameState.player["money"]==17 and Childhood.st()["covered"]==Care.fee("gp"),"Child appointment consumes savings or creates personal debt")
	var covered: int=Childhood.st()["covered"]; Care.gp_visit(); clear()
	ok(Childhood.st()["covered"]==covered,"Same month repeated child bill")
	LifeCourse.state()["months"]+=1; Care.gp_visit(); clear()
	ok(Childhood.st()["covered"]==covered+Care.fee("gp"),"Next infancy month cannot access care")
	diagnose("asthma"); Care.toggle_meds("asthma"); var gift: int=GameState.player["money"]; Care.yearly(); clear()
	ok(GameState.player["money"]==gift,"Child prescription drains personal gift")
	var care_after := JSON.stringify(Care.st()); Care.yearly()
	ok(JSON.stringify(Care.st())==care_after and GameState.player["money"]==gift,"Annual care settles twice")
	fresh(); GameState.player["medical"]["pending"]="heart"; Care.st()["referral"]={"for":"heart","wait":2,"made":34}
	var referral: Dictionary=Care.st()["referral"].duplicate(true); Care.gp_visit(); clear()
	ok(Care.st()["referral"]==referral,"GP resets existing waiting-list position")
	var before_money: int=GameState.player["money"]; var before_time: int=GameState.player["time_left"]; Care.pay_to_skip(); clear()
	ok(GameState.player["money"]==before_money-Actions._cost(1100) and GameState.player["time_left"]==before_time-1,"Private specialist has missing/double bill or time")
	ok(Care.st()["referral"].is_empty() and GameState.player["medical"]["pending"]=="","Specialist did not resolve actual referral")
	var found_wrong := false
	for trial in range(200):
		w.st()["seed"]=trial
		if w.roll("Specialist diagnosis:heart")<0.08: found_wrong=true; break
	ok(found_wrong,"Cannot exercise misdiagnosis fixture")
	GameState.player["medical"]["conditions"].clear(); GameState.player["medical"]["pending"]="heart"; Care.st()["referral"]={"for":"heart","wait":0}
	Care._specialist(true); clear(); ok(Care.st()["misdx"]!="","Wrong diagnosis not retained for second opinion")
	Care.second_opinion(); clear()
	ok(GameState.player["medical"]["conditions"].has("heart") and not GameState.player["medical"]["conditions"].has("viral") and Care.st()["hidden"]=="","Second opinion does not correct actual diagnosis")
	before_money=GameState.player["money"]; Care.second_opinion(); clear(); ok(GameState.player["money"]==before_money,"Repeat second-opinion billing")
	next_year(); GameState.player["medical"]["pending"]="asthma"; Care.st()["referral"]={"for":"heart","wait":0}; Care._specialist(false); clear()
	ok(GameState.player["medical"]["pending"]=="asthma","Older referral erases unrelated new symptoms")
	fresh(); Expansion.add_injury("sprain","sport"); clear(); GameState.player["medical"]["injuries"]["sprain"]["left"]=1
	Care.physio(); clear(); ok(not GameState.player["medical"]["injuries"].has("sprain"),"Completed physiotherapy leaves active injury")
	Care.st()["teeth"]=40; Actions.do_activity("dentist"); clear(); ok(Care.st()["teeth"]==54,"Older dentist does not update actual teeth")
	before_money=GameState.player["money"]; Care.dentist(); clear(); ok(GameState.player["money"]==before_money,"Two dentist routes bypass visit guard")
	Care.buy_aid("laser"); clear(); var vision: float=Care.st()["vision"]; before_money=GameState.player["money"]; Care.buy_aid("laser"); clear()
	ok(Care.st()["vision"]==vision and GameState.player["money"]==before_money,"Repeated laser surgery farm")
	Expansion._add_mental("depression"); clear(); Actions.do_activity("therapy"); clear()
	ok(GameState.player["medical"]["mental"]["depression"]["progress"]>0,"Old therapy route ignores actual recovery")
	before_money=GameState.player["money"]; Expansion.mental_action("therapy"); clear(); ok(GameState.player["money"]==before_money,"Two therapy routes bypass period guard")
	fresh(); GameState.player["job"]={"id":"coder","title":"Developer","salary":10000,"employer_name":"First company"}; GameState.player["stats"]["health"]=35
	var baseline := Aptitude.score("work"); w.request_access("work"); clear(); var adjusted := Aptitude.score("work")
	ok(adjusted>baseline and GameState.stat("health")==35,"Work adjustment has no functional readiness or grants health")
	GameState.player["job"]["employer_name"]="Second company"; ok(Aptitude.score("work")==baseline,"Old employer agreement applies to new employer")
	next_year(); w.request_access("work"); clear(); ok(w.active_access("work") and Aptitude.score("work")>baseline,"Cannot renew adjustments at changed employer")
	fresh(12); GameState.player["education"]["stage"]="secondary"; GameState.player["stats"]["health"]=30
	baseline=Aptitude.score("education"); w.request_access("school"); clear(); ok(Aptitude.score("education")>baseline,"School access does not affect education")
	GameState.player["education"]["stage"]="graduated"; ok(w.readiness("education")==0,"School adjustment outlives the actual course")
	fresh(); GameState.player["housing"]="apartment"; GameState.player["household"]={"fatigue":60}; w.request_access("home"); clear(); next_year(); w.yearly(); clear()
	ok(GameState.player["household"]["fatigue"]==58,"Home access does not reduce fatigue")
	GameState.player["region"]="Another place"; next_year(); w.yearly(); clear(); ok(GameState.player["household"]["fatigue"]==58,"Home access carries to a different dwelling")
	fresh(); var patient := GameState.create_npc("mother",{"age":75,"health":40}); var helper := GameState.create_npc("sibling",{"age":30,"health":90,"closeness":90})
	for id in GameState.npcs:
		if id!=helper: GameState.npc(id)["relation"]="mother" if id==patient else "friend"
	before_money=GameState.player["money"]; before_time=GameState.player["time_left"]; w.caregiver(patient,"shared"); clear()
	var patient_uid := FamilyChronicle.identity(GameState.npc(patient)); var helper_uid := FamilyChronicle.identity(GameState.npc(helper))
	ok(GameState.player["money"]==before_money-Actions._cost(60) and GameState.player["time_left"]==before_time-1,"Shared care has wrong bill/time")
	ok(w.st()["caregiving"][patient_uid]["helper"]==helper_uid,"Shared care does not remember actual helper")
	reload(); next_year(); var health: float=GameState.npc(patient)["health"]; w.yearly(); clear(); ok(GameState.npc(patient)["health"]==health+2,"Saved shared care has no follow-up")
	w.yearly(); ok(GameState.npc(patient)["health"]==health+2,"Family care rewards twice")
	next_year(); w.yearly(); clear(); ok(w.st()["caregiving"][patient_uid]["state"]=="lapsed","Care schedule does not lapse")
	w.caregiver(patient,"shared"); clear(); GameState.npc(helper)["alive"]=false; next_year(); health=GameState.npc(patient)["health"]; w.yearly(); clear()
	ok(GameState.npc(patient)["health"]==health and w.st()["caregiving"][patient_uid]["state"]=="needs replanning","Dead helper still supplies shared care")
	var stranger := GameState.create_npc("friend",{"age":80,"health":10}); before_money=GameState.player["money"]; w.caregiver(stranger,"professional"); ok(GameState.player["money"]==before_money,"Unrelated target bypasses family-care eligibility")
	fresh(5); for id in Expansion.CONDITIONS: diagnose(id)
	ok(w.available_scenes().is_empty(),"Older care scenarios appear before school age")
	fresh(12); for id in Expansion.CONDITIONS: diagnose(id)
	ok(not w.available_scenes().any(func(scene): return scene.get("work_only",false)),"Work rota/commute care events appear for a schoolchild")
	fresh(); GameState.player["job"]={"id":"software","title":"Developer","salary":10000}; for id in Expansion.CONDITIONS: diagnose(id)
	var conclusions: Dictionary={}
	for scene in w.scenes:
		for choice in scene["choices"]: conclusions[choice["result"]]=true
	ok(conclusions.size()==108,"Care conclusions repeat across the authored pool")
	var seen: Dictionary={}
	for i in range(36):
		w.story(); var prompt: Dictionary=Journey.state()["prompt"].duplicate(true)
		ok(not prompt.is_empty(),"Available scene not delivered")
		if prompt.is_empty(): break
		var scene: Dictionary=prompt["args"]["scene"]; ok(not seen.has(scene["id"]),"Repeated care scene"); seen[scene["id"]]=true
		var previous_control: float=w.plan(scene["condition"])["control"]; clear(); w.resolve("story",prompt["args"],0); clear()
		ok(float(w.plan(scene["condition"])["control"])>=previous_control,"Care choice has no actual plan effect")
		reload(); next_year()
	ok(seen.size()==36 and w.available_scenes().is_empty(),"Health scenes replay after reload or exhaustion")
	w.story(); ok(Journey.state()["prompt"].is_empty(),"Exhausted pool repeats a scene")
	fresh(); diagnose("diabetes"); w.reviewed("diabetes","review"); Care.toggle_meds("diabetes"); w.manage("diabetes","balanced"); clear()
	var clinical: Dictionary=GameState.player["medical"].duplicate(true); var care_packet := Care.st().duplicate(true)
	var child := GameState.create_npc("child",{"age":22,"money":500}); GameState.npc(child)["medical"]=clinical.duplicate(true); GameState.npc(child)["care"]=care_packet.duplicate(true)
	ok(Dynasty.switch_to(child),"Clinical living-child fixture cannot transfer")
	ok(GameState.player["medical"]==clinical and Care.st()==care_packet,"Child switch reinvents medical/prescription history")
	reload(); ok(same(GameState.player["medical"],clinical) and same(Care.st(),care_packet),"Clinical history changes after transferred save reload")
	var parent := GameState.npcs_with("mother").filter(func(id): return GameState.npc(id).has("playable_player"))
	ok(not parent.is_empty() and GameState.npc(parent[0])["medical"]["conditions"].has("diabetes"),"Former viewpoint loses diagnosis for family care")
	var former: Dictionary=GameState.npc(parent[0]); former["money"]=10000
	GameState.player["age"]+=1; var future := GameState.year_now(); w.background(former,future)
	ok(former["money"]==10000-Actions._cost(480) and former["medical"]["conditions"]["diabetes"]["years"]==1,"Former patient care/billing freezes off-screen")
	var former_cash: int=former["money"]; var former_health: float=former["health"]; w.background(former,future)
	ok(former["money"]==former_cash and former["health"]==former_health,"Background care settles twice")
	ok(former["playable_player"]["medical"]==former["medical"] and former["playable_player"]["stats"]["health"]==former["health"],"Off-screen medical state diverges from playable snapshot")
	GameState.player=former["playable_player"].duplicate(true); GameState.player["age"]=future-int(GameState.player["born_year"])
	var settled: Dictionary=GameState.player["medical"].duplicate(true); before_money=GameState.player["money"]
	Expansion.medical_yearly(); Care.yearly(); clear()
	ok(GameState.player["medical"]==settled and GameState.player["money"]==before_money,"Returning viewpoint settles the same clinical year twice")
	fresh(); diagnose("asthma"); GameState.player["stats"]["health"]=60; EventEngine._yearly_body()
	ok(GameState.player["illness"]!="" and GameState.stat("health")==60,"Legacy yearly body clears/double-charges a recorded condition")
	diagnose("viral"); w.event_recovery()
	ok(GameState.player["medical"]["conditions"].has("asthma") and not GameState.player["medical"]["conditions"].has("viral") and GameState.player["illness"]!="","Event cure bypasses chronic care or leaves acute condition active")
	var minor := GameState.create_npc("child",{"age":12,"money":99,"parent_uids":[Journey.uid()]}); var minor_npc := GameState.npc(minor)
	minor_npc["medical"]={"conditions":{"asthma":{"years":0,"controlled":false}},"pending":"","injuries":{},"mental":{}}; minor_npc["care"]={"meds":{"asthma":true}}
	before_money=GameState.player["money"]; w.background(minor_npc,GameState.year_now()+1)
	ok(minor_npc["money"]==99 and GameState.player["money"]==before_money-Actions._cost(480),"Background child prescription drains child gifts instead of household")
	fresh(); GameState.player["country"]="uk"; GameState.player["money"]=-500; before_time=GameState.player["time_left"]; Care.gp_visit(); clear()
	ok(GameState.player["money"]==-500 and GameState.player["time_left"]==before_time-1,"Personal debt blocks a free public GP visit")
	fresh(); var heir := GameState.create_npc("child",{"age":23,"money":100}); GameState.npc(heir)["medical"]=clinical.duplicate(true); GameState.npc(heir)["care"]=care_packet.duplicate(true)
	GameState.player["alive"]=false; clear(); GameState.continue_as(heir)
	ok(GameState.player["medical"]==clinical and Care.st()==care_packet,"Inheritance loses heir medical and prescription packet")
	print("HEALTH TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
