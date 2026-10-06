extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh(ind: String = "restaurant") -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30; GameState.player["money"]=10000000; GameState.player["time_left"]=100
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes(); clear()
	Empires.start_business(ind); clear()
func answer(index: int) -> Dictionary:
	var spec: Dictionary=Journey.state()["prompt"]["def"]["choices"][index]["outcomes"][0]["journey"].duplicate(true)
	clear(); Journey.outcome(spec); clear(); return spec
func reload_life() -> void: GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
func _ready() -> void:
	seed(7272)
	var operations=Journey.modules["operations"]
	var scene_ids: Array=[]
	for ind in Empires.INDUSTRIES:
		fresh(ind)
		var data: Dictionary=operations.catalog[ind]
		ok(data["products"].size()==2,"No distinct product lines: "+ind)
		for scene in data["scenes"]:
			ok(not scene_ids.has(scene["id"]),"Duplicate industry issue")
			scene_ids.append(scene["id"])
			ok(scene["choices"].size()==3 and scene["choices"].all(func(choice): return not str(choice["result"]).is_empty()),"Unfinished issue consequences: "+ind)
		var s: Dictionary=operations.st(); var baseline: Dictionary=operations.modifiers()
		s["pricing"]="premium"; GameState.player["business"]["quality"]=35
		ok(operations.modifiers()["premium_penalty"] and float(operations.modifiers()["revenue"])<float(baseline["revenue"]),"Premium pricing ignores quality: "+ind)
		GameState.player["business"]["quality"]=80
		ok(not operations.modifiers()["premium_penalty"],"Good quality cannot support premium: "+ind)
		s["pay"]="invest"; ok(float(operations.modifiers()["payroll"])>1,"Staff investment has no payroll cost")
		s["supplier"]="value"; ok(float(operations.modifiers()["quality"])<0,"Cheap supplier has no quality consequence")
		s["scale"]="stretch"; s["morale"]=70
		Empires._business_yearly(); clear()
		var report: Dictionary=operations.st()["report"]
		ok(int(report["revenue"])-int(report["operating_cost"])-int(report["payroll"])-int(report["interest"])==int(report["profit"]),"Accounts do not reconcile: "+ind)
		ok(operations.st()["morale"]==71,"Stretch/training morale effects missing: "+ind)
		var money := int(GameState.player["money"]); var records: int=operations.st()["history"].size()
		reload_life(); Empires._business_yearly(); clear()
		ok(GameState.player["money"]==money and operations.st()["history"].size()==records,"Reload repeats annual draw: "+ind)
		var booked := Employment.take_income()
		ok(int(booked["sources"].get("Business drawings",0))==maxi(0,int(report["draw"])),"Business draw absent from household income: "+ind)
		ok(int(Employment.take_income()["amount"])==0,"Booked income repeats")
	fresh(); var s: Dictionary=operations.st(); var time := int(GameState.player["time_left"])
	operations.set_option("product",1); clear()
	ok(s["product"]==1 and GameState.player["time_left"]==time-1,"Product plan not applied or free")
	operations.set_option("product",0); clear()
	ok(s["product"]==1,"Product switch repeat not limited")
	operations.set_option("unknown","unlimited"); ok(not s.has("unknown"),"Invalid option enters save")
	operations.order(); clear()
	var order: Dictionary=s["active"].duplicate(true); reload_life(); s=operations.st()
	ok(absf(float(s["active"]["roll"])-float(order["roll"]))<0.00001 and s["active"]["customer"]["uid"]==order["customer"]["uid"],"Order rerolls/customer replaced on load")
	GameState.player["age"]+=1; operations.set_option("product",0); clear()
	ok(s["product"]==1,"Changing year allows product swap during signed order")
	GameState.player["age"]-=1; s["active"]["roll"]=0
	operations.work(); var spec := answer(0); Journey.outcome(spec)
	ok(s["active"]["stage"]==1,"Replayed prompt advances order twice")
	reload_life(); s=operations.st(); operations.work(); answer(0)
	ok(s["active"].is_empty() and s["orders"][0]["success"],"Completed customer order has no closure")
	var customer: String=s["orders"][0]["customer"]["uid"]
	var cash := int(GameState.player["money"])
	operations.order(); clear(); ok(s["active"].is_empty() and int(GameState.player["money"])==cash,"Order reward/acceptance repeats same year")
	GameState.player["age"]+=1; operations.order(); clear()
	ok(s["active"]["customer"]["uid"]==customer,"Reliable customer never returns")
	cash=int(GameState.player["money"]); GameState.player["age"]+=1; operations.yearly()
	ok(s["active"].is_empty() and s["orders"][0]["result"]=="Deadline missed" and int(GameState.player["money"])<cash,"Missed order has no financial aftermath")
	cash=int(GameState.player["money"]); operations.yearly(); ok(int(GameState.player["money"])==cash,"Missed order penalty repeats")
	fresh(); operations.incident(); var original: Dictionary=Journey.state()["prompt"].duplicate(true)
	reload_life(); Journey.restore(); ok(Journey.state()["prompt"]["args"]["scene"]["id"]==original["args"]["scene"]["id"],"Issue rerolls on save")
	s=operations.st(); cash=int(GameState.player["money"]); answer(0)
	ok(int(GameState.player["money"])==cash-Actions._cost(int(original["args"]["scene"]["choices"][0]["cost"])),"Issue cost missing")
	operations.incident(); ok(Journey.state()["prompt"].is_empty(),"Industry issue repeats in one year")
	GameState.player["age"]+=1; operations.incident()
	ok(Journey.state()["prompt"]["args"]["scene"]["id"]!=original["args"]["scene"]["id"],"Same issue repeats next year")
	answer(1); GameState.player["age"]+=1; operations.incident()
	ok(Journey.state()["prompt"].is_empty(),"Exhausted industry pool replays old text")
	GameState.player["business"]={}; ok(operations.menu("")["rows"].is_empty(),"Operations remain actionable after company closed")
	# Already-paid losses must appear in bills without being charged twice.
	fresh(); GameState.player["housing"]="parents"; GameState.player["money"]=50000
	Employment.take_income(); Employment.record_expense("Business loss coverage",1000)
	EventEngine._yearly_finances(); var ledger: Dictionary=GameState.player["household_ledger"]
	ok(ledger["lines"]["Business loss coverage"]==1000,"Business loss absent from household bills")
	ok(GameState.player["money"]==50000-int(ledger["expenses"])+1000,"Already-paid business loss charged twice")
	# Real operating ownership passes once, and remains active off screen.
	fresh(); var child := GameState.create_npc("child",{"age":25,"money":1000})
	var junior := GameState.create_npc("child",{"age":12,"money":100})
	var crew := GameState.create_npc("friend",{"age":35,"money":500})
	GameState.player["business"]["crew"]=[crew]; GameState.player["business"]["debt"]=1000
	operations.st(); var company_uid: String=str(GameState.player["business"]["uid"])
	operations.handover(junior); ok(not GameState.player["business"].is_empty(),"Minor takes operating ownership")
	operations.handover(child); clear()
	ok(GameState.player["business"].is_empty() and GameState.npc(child)["business"]["uid"]==company_uid,"Live handover duplicates or replaces company")
	ok(GameState.npc(child)["business"]["debt"]==1000 and GameState.npc(child)["business"]["crew_uids"].size()==1,"Handover erases debt/staff")
	cash=int(GameState.npc(child)["money"]); GameState.player["age"]+=1
	Journey.background_companies(GameState.year_now())
	ok(GameState.npc(child)["business"]["years"]==1 and GameState.npc(child)["business"]["operations"]["supply"]["ledger"]["year"]==GameState.year_now() and GameState.npc(child)["money"]==cash+int(GameState.npc(child)["business"]["operations"]["report"]["draw"]),"NPC operating company freezes off screen")
	cash=int(GameState.npc(child)["money"]); Journey.background_companies(GameState.year_now())
	ok(GameState.npc(child)["money"]==cash,"Background company repeats draw")
	ok(Dynasty.switch_to(child),"Cannot enter actual successor life"); clear()
	ok(GameState.player["business"]["uid"]==company_uid and GameState.player["business"]["crew"].size()==1,"Live switch loses company or staff binding")
	reload_life(); ok(GameState.player["business"]["operations"]["history"].size()==1,"Transferred company history lost on reload")
	# A named sibling gets the whole business; cash does not also include its value.
	fresh(); GameState.player["money"]=100000; GameState.player["business"]["value"]=40000; GameState.player["business"]["debt"]=5000
	child=GameState.create_npc("child",{"age":25,"money":111}); var sibling := GameState.create_npc("child",{"age":24,"money":222})
	crew=GameState.create_npc("friend",{"age":35}); GameState.player["business"]["crew"]=[crew]
	operations.successor(sibling); clear(); var source := Journey.uid(); company_uid=str(GameState.player["business"]["uid"])
	GameState.player["alive"]=false; GameState.continue_as(child); clear()
	var receipt: Dictionary=GameState.world["estate_register"][source]; var total := 0
	for allocation in receipt["allocations"]: total+=int(allocation["cash"])+int(allocation["physical"])
	ok(total==130000,"Operating-company estate double counts equity or debt")
	var sibling_id := Journey.person(str(receipt["allocations"].filter(func(it): return it.get("business",false))[0]["uid"]))
	ok(GameState.player["business"].is_empty() and GameState.npc(sibling_id)["business"]["uid"]==company_uid,"Named sibling does not receive sole ownership")
	GameState.player["age"]+=1; Journey.background_companies(GameState.year_now())
	ok(GameState.npc(sibling_id)["business"]["years"]==1,"Inherited NPC company never operates")
	# Selected heir restores the existing company rather than a new scaffold.
	fresh(); child=GameState.create_npc("child",{"age":25,"money":100}); crew=GameState.create_npc("friend",{"age":35})
	GameState.player["business"]["crew"]=[crew]; operations.st()["product"]=1
	company_uid=str(GameState.player["business"]["uid"]); GameState.player["alive"]=false; GameState.continue_as(child); clear()
	ok(GameState.player["business"]["uid"]==company_uid and GameState.player["business"]["operations"]["product"]==1,"Heir company is reset")
	ok(GameState.player["business"]["crew"].size()==1,"Heir loses named staff when NPC identifiers change")
	reload_life(); ok(GameState.player["business"]["uid"]==company_uid,"Inherited business disappears after load")
	fresh(); child=GameState.create_npc("child",{"age":12,"money":321})
	GameState.player["money"]=100000; GameState.player["business"]["value"]=40000; GameState.player["business"]["debt"]=5000
	source=Journey.uid(); GameState.player["alive"]=false; GameState.continue_as(child); clear()
	ok(GameState.player["business"].is_empty() and GameState.player["money"]==128571,"Minor receives an operating business instead of net sale cash")
	fresh(); child=GameState.create_npc("child",{"age":25,"money":321}); GameState.player["will"]="charity"
	GameState.player["money"]=100000; GameState.player["business"]["value"]=40000; GameState.player["business"]["debt"]=5000
	source=Journey.uid(); GameState.player["alive"]=false; GameState.continue_as(child); clear()
	ok(GameState.player["business"].is_empty() and GameState.player["money"]==321 and GameState.world["estate_register"][source]["charity"]==128250,"Charity awards duplicate company/cash")
	fresh(); child=GameState.create_npc("child",{"age":25,"money":321})
	GameState.player["money"]=0; GameState.player["loan"]=50000; GameState.player["business"]["value"]=40000; GameState.player["business"]["debt"]=5000
	source=Journey.uid(); GameState.player["alive"]=false; GameState.continue_as(child); clear()
	ok(GameState.player["business"].is_empty() and GameState.player["money"]==321 and GameState.world["estate_register"][source]["unpaid"]==15000,"Estate hands over business before settling insolvency")
	fresh(); var company: Dictionary=GameState.player["business"]
	company["quality"]=80; s=operations.st(); s["morale"]=80
	seed(22); var capable := Empires.business_numbers(company,0,0,1.0,1.0,1.0,0)
	company["quality"]=20; s["morale"]=20
	seed(22); var weak := Empires.business_numbers(company,0,0,1.0,1.0,1.0,0)
	ok(int(capable["profit"])>int(weak["profit"]),"Maintaining quality/staff has no actual income benefit")
	s["supplier"]="value"; var cheap: Dictionary=operations.modifiers(); s["supplier"]="specialist"; var specialist: Dictionary=operations.modifiers()
	ok(float(cheap["margin"])>float(specialist["margin"]) and float(cheap["quality"])<float(specialist["quality"]),"Supplier price/quality tradeoff missing")
	company_uid=str(company["uid"]); Empires._close_business(); Empires.start_business("restaurant"); clear()
	ok(GameState.player["business"]["uid"]!=company_uid,"Two founded companies share an ownership identity")
	print("OPERATIONS TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
