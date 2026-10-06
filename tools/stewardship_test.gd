extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func clear() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh() -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30; GameState.player["money"]=200000; GameState.player["time_left"]=100
	GameState.settings["volume"]=0; GameState.settings["minigames"]=false; Fx.apply_volumes(); clear(); Expansion.ensure()
func job() -> void:
	GameState.player["job"]={"id":"baker","field":"Food","title":"Baker","salary":29000,"perf":50.0,"years":0,"rank":0}
	Employment.on_hire(); clear()
func _ready() -> void:
	seed(6060); fresh()
	var d := GameState.to_dict(); var sealed := SaveManager.seal(d)
	ok(SaveManager.valid(d),"Legacy save rejected")
	ok(SaveManager.valid(sealed),"Sealed save invalid")
	ok(SaveManager.valid(JSON.parse_string(JSON.stringify(sealed))),"Checksum fails after serialization")
	sealed["save_payload"]+=" "
	ok(not SaveManager.valid(sealed),"Changed checksum accepted")
	ok(not SaveManager.valid({"player":"bad"}),"Malformed player accepted")
	var malformed := d.duplicate(true); malformed["player"]["money"]={}
	ok(not SaveManager.valid(malformed),"Malformed cash accepted")
	var future := SaveManager.seal(d); future["save_format"]=999
	ok(not SaveManager.valid(future),"Unknown future format accepted")
	SaveManager.current_slot=1
	GameState.player["money"]=100; SaveManager.save_game()
	GameState.player["money"]=200; SaveManager.save_game()
	GameState.player["money"]=300; SaveManager.save_game()
	ok(SaveManager.valid(SaveManager._read(SaveManager.older_path(1),null)),"Second recovery generation missing")
	ok(SaveManager._read(SaveManager.older_path(1),{}).get("player",{}).get("money",-1)==100,"Older backup has wrong chronology")
	SaveManager._write(SaveManager.slot_path(1),{"broken":true})
	ok(SaveManager.load_slot(1) and GameState.player["money"]==200,"Primary corruption did not recover last backup")
	clear(); SaveManager._write(SaveManager.backup_path(1),{"broken":true})
	ok(SaveManager.load_slot(1) and GameState.player["money"]==100,"Both primary and newest backup corruption loses older backup")
	clear(); SaveManager.act("keep"); clear()
	GameState.player["money"]=400
	ok(SaveManager.restore_checkpoint() and GameState.player["money"]==100,"Checkpoint failed")
	ok(SaveManager._read(SaveManager.backup_path(1),{})["player"]["money"]==400,"Checkpoint restore loses previous current progress")
	ok(SaveManager.duplicate_slot(1)>1,"Recovered life cannot be duplicated")
	var kept := FileAccess.get_file_as_string(SaveManager.slot_path(1))
	ok(not SaveManager._write(SaveManager.DIR+"/missing-parent/slot.json",d),"Write unexpectedly succeeded in missing directory")
	ok(FileAccess.get_file_as_string(SaveManager.slot_path(1))==kept,"Failed write changed existing life")
	fresh(); job()
	var client := Employment.client_for("Food",0); client["trust"]=80; client["completed"]=2
	var time := int(GameState.player["time_left"])
	Stewardship.accept(client["id"]); clear()
	ok(Stewardship.st()["retainers"].size()==1 and GameState.player["time_left"]==time-1,"Retainer has no entry cost")
	Stewardship.accept(client["id"]); clear()
	ok(Stewardship.st()["retainers"].size()==1,"Duplicate retainer")
	var agreement: Dictionary=Stewardship.st()["retainers"][0]; agreement["roll"]=0
	var cash := int(GameState.player["money"])
	Stewardship.deliver(0,0); clear()
	ok(GameState.player["money"]>cash and agreement["delivered"]==1,"Delivery did not pay or record")
	cash=int(GameState.player["money"]); Stewardship.deliver(0,0); clear()
	ok(GameState.player["money"]==cash,"Retainer paid twice")
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
	ok(Stewardship.st()["retainers"][0]["delivered"]==1,"Retainer lost on reload")
	GameState.player["age"]+=1; Stewardship.finish_year()
	ok(Stewardship.st()["retainers"][0]["missed"]==0,"Completed year treated as missed")
	GameState.player["age"]+=1; Stewardship.finish_year()
	ok(Stewardship.st()["retainers"][0]["missed"]==1,"Missing yearly work has no consequence")
	GameState.player["age"]+=1; Stewardship.finish_year()
	ok(Stewardship.st()["retainers"].is_empty() and Stewardship.st()["history"].size()==1,"Retainer never closes")
	fresh(); job(); client=Employment.client_for("Food",0); client["trust"]=80; client["completed"]=2
	Stewardship.accept(client["id"]); clear()
	var dormant: Dictionary=Stewardship.st().duplicate(true)
	Stewardship.review_contracts(dormant,Employment.st()["clients"],GameState.year_now()+1)
	ok(dormant["retainers"][0]["missed"]==1,"Inactive owner retainer freezes")
	Stewardship.review_contracts(dormant,Employment.st()["clients"],GameState.year_now()+1)
	ok(dormant["retainers"][0]["missed"]==1,"Inactive deadline reviewed twice")
	Stewardship.review_contracts(dormant,Employment.st()["clients"],GameState.year_now()+2)
	ok(dormant["retainers"].is_empty(),"Inactive missed contract never ends")
	fresh(); GameState.player["last_income"]=10000; GameState.player["last_expenses"]=6000
	Stewardship.st()["saving"]=20
	var wealth := GameState.net_worth(); Stewardship.finish_year()
	ok(GameState.player["savings"]==800 and GameState.player["money"]==199200,"Surplus saving wrong amount")
	ok(GameState.net_worth()==wealth,"Saving created or destroyed wealth")
	Stewardship.finish_year()
	ok(GameState.player["savings"]==800,"Surplus saved twice")
	GameState.player["age"]+=1; GameState.player["last_expenses"]=20000; Stewardship.finish_year()
	ok(GameState.player["savings"]==800,"Deficit saved imaginary money")
	GameState.player["age"]=5
	ok(Stewardship.forecast()["bills"]==0,"Child forecast charges adult bills")
	fresh(); job()
	Household.state()["fatigue"]=0; var rested := Aptitude.score("work")
	Household.state()["fatigue"]=100
	ok(Aptitude.score("work")<rested,"Fatigue does not affect readiness")
	Household.act("rest"); clear()
	ok(Household.state()["fatigue"]==85,"Rest does not reduce fatigue")
	Household.act("rest"); clear()
	ok(Household.state()["fatigue"]==85,"Rest repeat exploit")
	GameState.player["job"]["work_schedule"]="overtime"; Household.state()["year"]=GameState.year_now()-1
	var fatigue: int=Household.state()["fatigue"]; Household.yearly()
	ok(Household.state()["fatigue"]>fatigue,"Overtime adds no fatigue")
	fatigue=int(Household.state()["fatigue"]); Household.yearly()
	ok(Household.state()["fatigue"]==fatigue,"Workload applied twice")
	fresh()
	var tenant := GameState.create_npc("tenant",{"age":30})
	GameState.player["properties"]=[{"type":"Townhouse","value":100000,"rent":12000,"condition":60.0,"tenant":tenant,"icon":"🏠"}]
	var total := GameState.net_worth()
	Expansion.home_action("move_property",0); clear()
	ok(Holdings.primary_index()==0 and GameState.player["properties"][0]["tenant"]=="","Moving in leaves tenant")
	ok(GameState.net_worth()==total and GameState.player["house_value"]==0,"Moving in counts property twice")
	Finance.find_tenant(GameState.player["properties"][0],false)
	ok(GameState.player["properties"][0]["tenant"]=="","Occupied home rented out")
	GameState.player["home"]["condition"]=40; Holdings.sync_home()
	ok(GameState.player["properties"][0]["condition"]==40,"Primary home repair state detached")
	Finance.sell_property(0); clear()
	ok(GameState.player["properties"].is_empty() and GameState.player["housing"]=="apartment","Selling primary home leaves occupied ghost property")
	cash=int(GameState.player["money"]); Finance.sell_property(0)
	ok(GameState.player["money"]==cash,"Primary property sold twice")
	fresh()
	var skills=Journey.modules["skills"]
	GameState.player["martial"]={"karate":{"belt":3}}; skills.st()["assist"]=true
	skills.start("tactics",true); clear()
	ok(skills.st()["records"].is_empty(),"Practice tactical challenge produces rewards")
	fresh()
	var market := Stewardship.used_market()
	var offer: Dictionary=market[0]
	var saved_condition: float=offer["condition"]; var offer_price: int=offer["asking"]
	cash=int(GameState.player["money"]); Stewardship.used_action(0,true); clear()
	ok(offer["inspected"] and offer["condition"]==saved_condition and GameState.player["money"]<cash,"Inspection is free or rerolls wear")
	cash=int(GameState.player["money"]); Stewardship.used_action(0,true); clear()
	ok(GameState.player["money"]==cash,"Inspection charged twice")
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
	ok(Stewardship.used_market()[0]["condition"]==saved_condition and Stewardship.used_market()[0]["asking"]==offer_price,"Used listing rerolled on reload")
	cash=int(GameState.player["money"]); Stewardship.used_action(0,false); clear()
	ok(GameState.player["money"]==cash-offer_price and Holdings.car()["condition"]==saved_condition,"Used purchase payment or record wrong")
	ok(Holdings.resale()<offer_price,"Used purchase can instantly flip for profit")
	cash=int(GameState.player["money"]); Stewardship.used_action(0,false); clear()
	ok(GameState.player["money"]==cash,"Sold listing purchased twice")
	for failure in failures: print("FAIL: "+failure)
	print("STEWARDSHIP TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
