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
	GameState.settings["volume"]=0; GameState.settings["minigames"]=false; Fx.apply_volumes(); clear()
func _ready() -> void:
	seed(5050); fresh()
	var model: String=GameState.CARS.keys()[0]
	GameState.player["car"]=model
	var r := Holdings.car()
	ok(r["mileage"]==60000 and r["condition"]==75,"Legacy car migration")
	var uid: String=r["uid"]
	ok(Holdings.car()["uid"]==uid,"Migration created duplicate car")
	Holdings.new_car(model,10000); r=Holdings.car()
	ok(r["condition"]==100 and r["mileage"]==0,"New car retained old wear")
	ok(Holdings.resale()==8000,"New-car resale")
	r["condition"]=30
	var worn := Holdings.resale()
	r["condition"]=90
	ok(Holdings.resale()>worn,"Condition has no resale consequence")
	r["mileage"]=200000
	ok(Holdings.resale()<7400,"Mileage has no depreciation")
	r["condition"]=10
	ok(not Holdings.drivable(),"Unsafe vehicle available")
	var before := int(GameState.player["money"])
	Holdings.service(true); clear()
	ok(r["condition"]==48 and GameState.player["money"]<before,"Repair failed to cost and restore")
	ok(Transit.st()["serviced"],"Repair protection missing")
	before=int(GameState.player["money"]); Holdings.service(); clear()
	ok(GameState.player["money"]==before,"Duplicate routine service charged")
	GameState.player["age"]+=1
	Holdings.yearly_vehicle({},false)
	ok(r["mileage"]==201000 and r["years"]==1,"Parked car annual wear")
	var condition: float=r["condition"]
	Holdings.yearly_vehicle({},false)
	ok(r["condition"]==condition and r["history"].size()==1,"Vehicle wore twice in same year")
	ok(r["history"][0]["serviced"],"Service lost before annual check")
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
	ok(Holdings.car()["mileage"]==201000,"Car record lost on reload")
	GameState.player["housing"]="house"; GameState.player["house_model"]="studio"
	GameState.create_npc("child",{"age":5}); GameState.create_npc("child",{"age":8})
	ok(Holdings.occupants()==3,"Children excluded from home space")
	var happy := GameState.stat("happiness"); var stress := GameState.stat("stress")
	Holdings.home_yearly()
	ok(GameState.stat("happiness")<happy and GameState.stat("stress")>stress,"Crowding has no consequence")
	var studio := Holdings.home_costs(); var commute := Holdings.commute_factor()
	GameState.player["house_model"]="estate"
	ok(Holdings.home_costs()>studio and Holdings.commute_factor()>commute,"Home models do not affect costs and travel")
	fresh()
	var museum=Journey.modules["collection"]
	GameState.player["possessions"].append({"id":"art_test","name":"Original landscape","value":10000,"fake":true})
	museum.open(); clear()
	ok(museum.st()["open"] and GameState.player["money"]<200000,"Museum opening has no cost")
	before=int(GameState.player["money"]); museum.open(); clear()
	ok(GameState.player["money"]==before,"Museum charged opening twice")
	var wealth := GameState.net_worth(); museum.exhibit(0); clear()
	ok(GameState.player["possessions"].is_empty() and museum.st()["items"].size()==1,"Exhibit retained duplicate ownership")
	ok(GameState.net_worth()<=wealth and GameState.net_worth()>wealth-1000,"Exhibit disappeared from net worth")
	museum.document(0); clear()
	ok(museum.st()["items"][0]["museum_disclosed"] and museum.st()["items"][0]["fake"],"Research erased forgery")
	before=int(GameState.player["money"]); museum.document(0); clear()
	ok(GameState.player["money"]==before,"Research repeated reward or charge")
	GameState.player["age"]+=1; museum.yearly(); clear()
	ok(museum.st()["history"].size()==1 and museum.st()["visitors"]>0,"Museum has no operating loop")
	before=int(GameState.player["money"]); museum.yearly(); clear()
	ok(GameState.player["money"]==before,"Museum paid twice in same year")
	var free: Dictionary=museum.st().duplicate(true); free["ticket"]=0; free["last_year"]=-1
	var owner := {"money":10000}; museum.review(free,owner,9999)
	ok(free["profit"]<0 and owner["money"]<10000,"Free admission ignores expenses")
	var premium: Dictionary=museum.st().duplicate(true); premium["ticket"]=75; premium["last_year"]=-1
	museum.review(premium,{"money":10000},9999)
	ok(premium["visitors"]<free["visitors"],"Ticket prices do not affect attendance")
	museum.act("close",null); clear()
	ok(not museum.st()["open"] and GameState.player["possessions"].size()==1 and museum.st()["items"].is_empty(),"Closing duplicates or loses exhibits")
	before=int(GameState.player["money"]); museum.act("maintain",null)
	ok(GameState.player["money"]==before,"Closed museum charged maintenance")
	fresh()
	GameState.player["job"]={"id":"baker","field":"Food","title":"Baker","salary":29000,"perf":50.0,"years":0,"rank":0}
	Employment.on_hire(); clear()
	var client := Employment.client_for("Food",0)
	ok(Journey.person(client["contact"])!="","Client lacks real identity")
	client["completed"]=2; client["trust"]=80
	Employment.client_meeting(client["id"])
	var prompt: Dictionary=Employment.st()["prompt"]
	ok(prompt.has("roll") and prompt.has("client") and prompt.has("session"),"Client prompt missing persisted context")
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict())))
	prompt=Employment.st()["prompt"]
	ok(prompt.has("roll") and prompt["client"]==client["id"],"Client review lost on reload")
	prompt["roll"]=0; Employment.client_response(prompt,1); clear()
	client=Employment.find_client(client["id"])
	ok(client.get("reference",false),"Earned reference missing")
	var bonus := Employment.hiring_bonus("Food")
	GameState.npc(Journey.person(client["contact"]))["alive"]=false
	ok(Employment.hiring_bonus("Food")<bonus,"Dead contact supplies reference")
	for id in ["baker","mortician","exorcist","marines","coast_guard","adult_performer"]:
		var job := ContentDB.job(id)
		ok(not job.is_empty() and job["ranks"].size()>=3,"Missing occupation progression "+id)
		ok(Employment.briefs.get(id,[]).size()>=2,"Missing profession projects "+id)
	GameState.settings["mature_arcs"]=false
	ok(Actions.job_requirement(ContentDB.job("adult_performer"))!="","Mature career bypasses setting")
	GameState.settings["mature_arcs"]=true; GameState.player["age"]=18
	ok(Actions.job_requirement(ContentDB.job("adult_performer"))!="","Adult career bypasses age gate")
	var scenarios: Array=ContentDB._load_json("res://data/enterprise_scenes.json",[])
	ok(scenarios.size()==12 and scenarios.all(func(s): return s["stages"].size()==3),"Enterprise stage catalogue incomplete")
	fresh()
	var heir := GameState.create_npc("child",{"age":25,"money":0})
	GameState.player["housing"]="house"; GameState.player["house_value"]=50000; GameState.player["mortgage"]=10000
	GameState.player["home"]={"condition":43.0,"upgrades":{"garden":true}}
	GameState.player["alive"]=false; GameState.continue_as(heir); clear()
	ok(GameState.player["housing"]=="house" and GameState.player["house_value"]==50000,"Inherited home lost")
	ok(GameState.player["home"]["condition"]==43,"Inherited home rerolled condition")
	ok(GameState.player["money"]==190000,"Home equity paid again as cash")
	fresh(); heir=GameState.create_npc("child",{"age":25,"money":123})
	GameState.player["housing"]="house"; GameState.player["house_value"]=50000; GameState.player["will"]="charity"
	GameState.player["possessions"].append({"name":"Charitable painting","value":1000})
	GameState.player["alive"]=false; GameState.continue_as(heir); clear()
	ok(GameState.player["money"]==123,"Charity took child's own cash")
	ok(GameState.player["housing"]!="house" and GameState.player["possessions"].is_empty(),"Charity gave physical estate to child")
	fresh(); museum=Journey.modules["collection"]; museum.st()["open"]=true
	museum.st()["items"]=[{"name":"Gifted exhibit","value":1000}]
	heir=GameState.create_npc("child",{"age":25,"money":10000})
	museum.handover(heir); clear()
	ok(not museum.st()["open"] and museum.st()["items"].is_empty(),"Handover retains active owner")
	ok(GameState.npc(heir)["journey"]["collection"]["items"].size()==1,"Handover loses collection")
	GameState.player["age"]+=1; Journey.background_commitments(GameState.year_now())
	var background_cash: int=GameState.npc(heir)["money"]
	ok(GameState.npc(heir)["journey"]["collection"]["history"].size()==1,"Inactive child museum stops operating")
	Journey.background_commitments(GameState.year_now())
	ok(GameState.npc(heir)["money"]==background_cash,"Background museum pays twice")
	fresh(); GameState.player["age"]=5; GameState.player["money"]=120
	var parent := GameState.first_of("mother")
	GameState.npc(parent)["money"]=500
	GameState.apply_effects({"money":-300},true)
	ok(GameState.player["money"]==120 and GameState.npc(parent)["money"]==200,"Child event charged personal savings")
	ok(Childhood.st()["covered"]==300,"Household costs not recorded")
	for id in Childhood.parents(): GameState.npc(id)["money"]=0
	GameState.apply_effects({"money":-1000},true)
	ok(GameState.player["money"]==120 and Childhood.st()["assistance"]==1000,"Poor household creates child debt")
	GameState.player["money"]=-100; Childhood.protect()
	ok(GameState.player["money"]==0,"Existing childhood deficit not protected")
	GameState.player["age"]=10; GameState.player["money"]=200; clear()
	Childhood.contribute(FamilyChronicle.identity(GameState.npc(parent)),50); clear()
	ok(GameState.player["money"]==100 and GameState.npc(parent)["money"]==100,"Contribution does not move real money")
	Childhood.contribute(FamilyChronicle.identity(GameState.npc(parent)),50); clear()
	ok(GameState.player["money"]==100,"Contribution repeat bypasses annual limit")
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
	ok(Childhood.st()["contributed"]==100,"Family budget lost on reload")
	Childhood.st()["independence_age"]=16; GameState.player["age"]=16
	Childhood.protect()
	ok(not Childhood.supported() and GameState.player["money"]==100,"Independence erases earned savings")
	GameState.apply_effects({"money":-200},true); Childhood.protect()
	ok(GameState.player["money"]==-100,"Adult receives free child cost coverage")
	GameState.player["age"]=20; Childhood.st()["independence_age"]=21
	ok(Childhood.supported(),"Age-21 household support fails")
	for failure in failures: print("FAIL: "+failure)
	print("COMBINED DEPTH TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
