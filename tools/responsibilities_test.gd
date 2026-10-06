extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh(age: int=30) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=age; GameState.player["money"]=200000; GameState.player["time_left"]=100
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes(); clear()
func year() -> void:
	clear(); GameState.player["age"]=int(GameState.player["age"])+1; GameState.player["time_left"]=100
func answer(value: int) -> void:
	var prompt: Dictionary=Journey.state()["prompt"]
	var order: Array=prompt["args"].get("order",[0,1,2])
	var displayed := order.map(func(i): return int(i)).find(value)
	var spec: Dictionary=prompt["def"]["choices"][displayed]["outcomes"][0]["journey"].duplicate(true)
	clear(); Journey.outcome(spec); clear()
func _ready() -> void:
	seed(8080); fresh()
	var sport=Journey.modules["seasons"]
	ok(sport.scenes.size()==18,"Fixture narrative bank incomplete")
	sport.start(); clear()
	ok(not sport.st()["season"].is_empty(),"Adult amateur season absent")
	var fixture: Dictionary=sport.st()["season"]["fixtures"][0]
	fixture["roll"]=0.0; fixture["injury_roll"]=0.0
	sport.pace("push"); sport.fixture()
	ok(Journey.state()["prompt"]["def"]["text"].contains("push"),"Fixture pace not visible")
	var saved: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.from_dict(saved)
	fixture=sport.st()["season"]["fixtures"][0]
	ok(fixture.has("cue") and Journey.state()["prompt"]["domain"]=="seasons","Saved fixture cue/prompt missing")
	var plan: int={"pressing":1,"patient":2,"wide":0}[fixture["opponent"]]
	answer(plan)
	ok(GameState.player["medical"]["injuries"].has("sprain"),"League injury did not use real medical record")
	ok(int(sport.st()["season"]["stamina"])==68,"Push stamina trade-off absent")
	var chance := float(fixture["chance"])
	var injury_risk := float(fixture["injury_chance"])
	sport.rest(); clear()
	ok(int(sport.st()["season"]["stamina"])==93,"Rest did not restore bounded stamina")
	var time := int(GameState.player["time_left"])
	sport.rest(); ok(GameState.player["time_left"]==time,"Repeated rest charged")
	ok(GameState.player["medical"]["injuries"].has("sprain"),"Rest erased medical injury")
	sport.pace("safe"); sport.fixture(); answer(0)
	ok(sport.st()["season"]["fixtures"][1]["entered_injured"],"Existing injury ignored by fixture")
	ok(int(sport.st()["season"]["stamina"])==81,"Safe pace did not conserve stamina")
	var stage := int(sport.st()["season"]["stage"])
	sport.resolve("fixture",{"stage":0},0)
	ok(int(sport.st()["season"]["stage"])==stage,"Old fixture replayed")
	ok(injury_risk>=0.04 and chance>0,"Saved strain/chance absent")
	fresh()
	var funds=Journey.modules["funds"]
	var partner := GameState.create_npc("partner",{"age":32,"closeness":80,"money":5000})
	GameState.player["partner"]=partner; GameState.player["living_together"]=true
	var account: Dictionary=funds.account()
	funds.budget(100); clear(); funds.floor_amount(1000)
	var floor: int=funds.plan()["floor_cash"]
	GameState.player["money"]=floor+500
	var total: int= int(GameState.player["money"])+funds.value(Journey.uid())
	year(); funds.yearly()
	ok(GameState.player["money"]==floor and funds.value(Journey.uid())==500,"Budget did not protect cash floor")
	ok(int(GameState.player["money"])+funds.value(Journey.uid())==total,"Savings created/lost net worth")
	funds.yearly(); ok(funds.value(Journey.uid())==500,"Standing contribution duplicated")
	ok(GameState.npc(partner)["money"]==5000,"Budget took partner cash")
	GameState.player["money"]=-200; year(); funds.yearly()
	ok(GameState.player["money"]==-200 and funds.value(Journey.uid())==500,"Plan invented debt or contributions")
	funds.budget(0); clear(); GameState.player["money"]=10000; year(); funds.yearly()
	ok(funds.value(Journey.uid())==500,"Paused plan moved money")
	funds.budget(25); clear(); GameState.player["living_together"]=false; year(); funds.yearly()
	ok(funds.value(Journey.uid())==500,"Separated household still contributed")
	funds.withdraw(); clear(); ok(funds.value(Journey.uid())==0 and GameState.player["money"]==10500,"Owned reserve inaccessible after separation")
	fresh()
	var parenting=Journey.modules["parenting"]
	ok(parenting.scenes.size()==42 and parenting.scenes.filter(func(scene): return int(scene["band"])==2).size()==14,"Parenting age banks incomplete")
	var child := GameState.create_npc("child",{"age":8,"closeness":70,"smarts":40,"health":60})
	var uid := FamilyChronicle.identity(GameState.npc(child))
	var child_money := int(GameState.npc(child)["money"])
	parenting.activity(child)
	ok(Journey.state()["prompt"]["args"]["band"]==1,"Child question age band wrong")
	saved=JSON.parse_string(JSON.stringify(GameState.to_dict())); GameState.from_dict(saved)
	ok(Journey.state()["prompt"]["domain"]=="parenting","Parenting prompt lost on reload")
	answer(0)
	ok(GameState.npc(child).get("upbringing",[]).size()==1,"Child outcome not recorded on child")
	ok(GameState.npc(child)["money"]==child_money,"Parenting invented child cash")
	time=int(GameState.player["time_left"]); parenting.activity(child)
	ok(GameState.player["time_left"]==time and Journey.state()["prompt"].is_empty(),"Parenting activity farmed")
	parenting.arrange(child,"self"); clear()
	var health := float(GameState.npc(child)["health"])
	year(); parenting.yearly()
	ok(float(GameState.npc(child)["health"])==health+1,"Childcare did not develop actual child")
	parenting.yearly(); ok(float(GameState.npc(child)["health"])==health+1,"Childcare annual reward duplicated")
	year(); parenting.yearly(); ok(parenting.st()["plans"][uid]["state"]=="lapsed","Childcare never needed renewal")
	GameState.npc(child)["custody"]="ex"; time=int(GameState.player["time_left"])
	parenting.arrange(child,"professional"); ok(GameState.player["time_left"]==time,"Childcare overrode custody")
	GameState.npc(child).erase("custody")
	var helper := GameState.create_npc("sibling",{"age":31,"closeness":70,"health":80})
	parenting.arrange(child,"shared"); clear(); GameState.npc(helper)["alive"]=false
	# New lives can contain another available helper; invalidate the actual agreed one.
	var helper_id: String=Journey.person(str(parenting.st()["plans"][uid]["helper"]))
	if helper_id!="": GameState.npc(helper_id)["alive"]=false
	year(); parenting.yearly(); ok(parenting.st()["plans"][uid]["state"]=="interrupted","Missing childcare helper ignored")
	fresh()
	child=GameState.create_npc("child",{"age":9,"closeness":75,"health":60})
	uid=FamilyChronicle.identity(GameState.npc(child)); parenting.activity(child); answer(0)
	parenting.arrange(child,"self"); clear()
	var parent_uid := Journey.uid(); health=float(GameState.npc(child)["health"])
	ok(Dynasty.switch_to(child),"Actual child transfer rejected")
	ok(GameState.player.get("upbringing",[]).size()==1,"Child lost upbringing on transfer")
	var parent_id := Journey.person(parent_uid); year()
	var child_cash := int(GameState.player["money"]); time=int(GameState.player["time_left"])
	parenting.background(GameState.npc(parent_id),GameState.year_now())
	ok(GameState.stat("health")==health+1,"Dormant parent plan did not support actual active child")
	parenting.background(GameState.npc(parent_id),GameState.year_now())
	ok(GameState.stat("health")==health+1,"Dormant childcare rewarded twice")
	ok(GameState.player["money"]==child_cash and GameState.player["time_left"]==time,"Parent plan charged active child")
	ok(parenting.st()["plans"].is_empty(),"Child inherited parent obligations")
	fresh()
	partner=GameState.create_npc("partner",{"age":32,"closeness":80,"money":5000})
	GameState.player["partner"]=partner; GameState.player["living_together"]=true
	funds.account(); funds.budget(25); clear(); funds.floor_amount(500)
	child=GameState.create_npc("child",{"age":19,"closeness":75,"money":50})
	parent_uid=Journey.uid(); ok(Dynasty.switch_to(child),"Budget transfer rejected")
	parent_id=Journey.person(parent_uid); year()
	child_cash=int(GameState.player["money"]); time=int(GameState.player["time_left"])
	var parent_cash := int(GameState.npc(parent_id)["money"])
	funds.background(GameState.npc(parent_id),GameState.year_now())
	ok(GameState.npc(parent_id)["money"]==parent_cash-300 and funds.value(parent_uid)==300,"Dormant savings not charged to actual owner")
	ok(GameState.player["money"]==child_cash and funds.value(Journey.uid())==0,"Child inherited parent savings rule/share")
	funds.background(GameState.npc(parent_id),GameState.year_now())
	ok(funds.value(parent_uid)==300,"Dormant savings duplicated")
	fresh()
	var wellbeing=Journey.modules["wellbeing"]
	var mother := GameState.first_of("mother")
	GameState.npc(mother)["health"]=40
	wellbeing.caregiver(mother,"self"); clear(); uid=FamilyChronicle.identity(GameState.npc(mother))
	var money := int(GameState.player["money"])
	wellbeing.respite(uid,"professional"); clear()
	ok(GameState.player["money"]==money-Actions._cost(250),"Respite fee not charged once")
	money=int(GameState.player["money"]); wellbeing.respite(uid,"professional")
	ok(GameState.player["money"]==money,"Respite reward/cost replay")
	var schedule: Dictionary=wellbeing.st()["caregiving"][uid]
	ok(wellbeing.care_strain(schedule,GameState.year_now()+1)==0,"Respite does not affect caregiver strain")
	ok(wellbeing.care_strain(schedule,GameState.year_now()+2)==3,"Respite never expires")
	wellbeing.respite("missing","professional"); ok(GameState.player["money"]==money,"Missing schedule charged")
	fresh()
	var recovery=Journey.modules["recovery"]
	GameState.player["prison"]=8
	recovery.st()["history"]=[{"result":"convicted","appealed":false,"crime":"Theft","year":GameState.year_now(),"strength":60,"timeline":[{"step":"An exhibit supports one fact but not the whole allegation.","prepared":false}]}]
	money=int(GameState.player["money"]); time=int(GameState.player["time_left"])
	recovery.appeal()
	ok(GameState.player["money"]==money-Actions._cost(600) and GameState.player["time_left"]==time-2,"Appeal initial cost wrong")
	ok(Journey.state()["prompt"]["def"]["text"].contains("exhibit"),"Appeal ignored actual transcript")
	ok(Journey.busy(),"Pending appeal allows transfer/other commitments")
	recovery.st()["appeal"]["roll"]=0.0
	saved=JSON.parse_string(JSON.stringify(GameState.to_dict())); GameState.from_dict(saved)
	answer(0)
	ok(recovery.st()["appeal"]["stage"]==1 and not recovery.st()["history"][0]["appealed"],"Appeal did not retain second stage")
	answer(0)
	ok(GameState.player["prison"]==6 and recovery.st()["history"][0]["appealed"],"Appeal conclusion did not affect sentence")
	ok(recovery.st()["history"][0]["appeal_record"]["ground"].contains("missed"),"Appeal ground not remembered")
	money=int(GameState.player["money"]); recovery.appeal()
	ok(GameState.player["money"]==money and GameState.player["prison"]==6,"Appeal replayed")
	ok(not Journey.busy(),"Concluded appeal left player blocked")
	recovery.st()["appeal"]={"stage":0}; GameState.player["prison"]=0; recovery.yearly(); clear()
	ok(recovery.st()["appeal"].is_empty(),"Released player trapped by old appeal")
	recovery.st()["history"][0]["appealed"]=false; GameState.player["prison"]=4
	Journey.decision("recovery","appeal",{},"Legacy appeal","Old save pending choice",["Identify an error","Repeat dislike","Rely on fame"])
	answer(0)
	ok(recovery.st()["history"][0]["appealed"] and recovery.st()["appeal"].is_empty(),"Legacy pending appeal stranded")
	fresh()
	var community=Journey.modules["places"]
	community.st()["language"]=3
	ok(community.language_level()==3,"Legacy language progress lost")
	GameState.player["country"]="jp"; GameState.player["region"]="tokyo"
	ok(community.language_level()==0,"Language skill applied to unrelated destination")
	community.language(); clear(); ok(community.language_level()==1,"Destination language not recorded")
	GameState.player["country"]="us"; GameState.player["region"]="ca"
	ok(community.language_level()==3,"Earlier country language lost")
	var institution: Dictionary=community.institution(); institution["clinic"]=1; institution["quality"]=40
	var bonus := float(community.hiring_bonus("Care"))
	community.review_institution(GameState.year_now()); year(); community.review_institution(GameState.year_now())
	ok(institution["quality"]==39 and community.hiring_bonus("Care")<bonus,"Unmaintained institution did not affect opportunity")
	money=int(GameState.player["money"]); community.maintain("clinic"); clear()
	ok(institution["quality"]==41 and GameState.player["money"]==money-Actions._cost(30),"Community upkeep cost/result missing")
	community.maintain("clinic"); ok(institution["quality"]==41,"Upkeep farmed")
	year(); community.review_institution(GameState.year_now()); ok(institution["quality"]==41,"Maintained service decayed immediately")
	community.review_institution(GameState.year_now()); ok(institution["quality"]==41,"Institution reviewed twice in shared year")
	for message in failures: print("FAIL: "+str(message))
	print("RESPONSIBILITIES TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
