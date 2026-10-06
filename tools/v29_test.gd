extends Node
var failures: Array = []
var checks := 0
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func fresh() -> void:
	EventEngine.pending.clear()
	GameState.new_life({"first":"Morgan","last":"Vale","gender":"female","country":"us"})
	GameState.player["age"]=35
	GameState.player["money"]=10000000
	GameState.player["time_left"]=100
func _ready() -> void:
	seed(2929)
	fresh()
	for kind in Ventures.TYPES:
		var before := int(GameState.player["money"])
		ok(Ventures.acquire(kind),"acquisition failed "+kind)
		ok(int(GameState.player["money"])==before-int(Ventures.TYPES[kind]["cost"]),"purchase debit "+kind)
		before=int(GameState.player["money"])
		ok(not Ventures.acquire(kind) and int(GameState.player["money"])==before,"duplicate acquisition "+kind)
	Ventures.act("room","cards")
	var cash := int(GameState.player["money"])
	Ventures.act("room","cards")
	ok(GameState.player["money"]==cash and Ventures.book()["casino"]["rooms"].size()==1,"duplicate room charged")
	Ventures.act("exhibit","local")
	Ventures.act("fee",0)
	Ventures.act("recruit","agency")
	ok(Ventures.book()["agency"]["agents"].size()==1,"operative not recruited")
	Ventures.act("train",1)
	cash=int(GameState.player["money"])
	Ventures.act("train",1)
	ok(GameState.player["money"]==cash,"training repeated in same year")
	Ventures.act("operation","audit")
	cash=int(GameState.player["money"])
	Ventures.act("operation","audit")
	ok(GameState.player["money"]==cash,"contract repeated")
	GameState.player["age"]+=1
	Ventures.yearly()
	for kind in Ventures.TYPES:
		var v: Dictionary = Ventures.book()[kind]
		ok(int(v["report"]["profit"])==int(v["report"]["revenue"])-int(v["report"]["cost"]),"report inconsistent "+kind)
	var worth := GameState.net_worth()
	Ventures.book()["agency"]["agents"][0]["skill"]=95
	Ventures.book()["agency"]["agents"][0]["training_year"]=-1
	cash=int(GameState.player["money"])
	Ventures.act("train",1)
	ok(int(GameState.player["money"])==cash,"capped training still charged")
	cash=int(GameState.player["money"])
	var reserve := int(Ventures.book()["casino"]["reserve"])
	Ventures.act("withdraw","casino")
	ok(int(GameState.player["money"])==cash+reserve and GameState.net_worth()==worth,"withdrawal changes net worth")
	cash=int(GameState.player["money"])
	Ventures.yearly()
	ok(GameState.player["money"]==cash,"operating year settled twice")
	var saved := JSON.parse_string(JSON.stringify(GameState.to_dict())) as Dictionary
	GameState.from_dict(saved)
	ok(Ventures.book()["casino"]["rooms"].has("cards") and Ventures.book()["agency"]["agents"].size()==1,"venue save/load")
	GameState.set_flag("owns_casino")
	Ventures.sell("casino")
	Ventures.migrate()
	ok(not Ventures.book().has("casino"),"sold casino was recreated")
	fresh()
	GameState.set_flag("owns_casino")
	cash=int(GameState.player["money"])
	Ventures.migrate()
	Ventures.migrate()
	ok(Ventures.book().has("casino") and GameState.player["money"]==cash,"legacy migration charged again")
	GameState.set_flag("luxury_life")
	Ventures.migrate()
	Ventures.luxury_act("lux_gather",null)
	cash=int(GameState.player["money"])
	Ventures.luxury_act("lux_gather",null)
	ok(GameState.player["money"]==cash,"gathering repeated")
	Ventures.luxury_act("lux_leave",null)
	Ventures.migrate()
	ok(not GameState.player.has("luxury_club"),"left society recreated")
	fresh()
	GameState.player["age"]=17
	Creator.act("fan_open")
	Creator.act("start","Pop")
	ok(not GameState.player.has("creator"),"minor opened adult creator system")
	GameState.player["age"]=35
	GameState.player["money"]=0
	Creator.act("start","Pop")
	ok(Creator.state()["project"].is_empty() and not EventEngine.pending.is_empty(),"unaffordable project gave no feedback")
	GameState.player["money"]=10000000
	GameState.player["time_left"]=0
	Creator.act("start","Pop")
	ok(Creator.state()["project"].is_empty(),"project starts without time")
	GameState.player["time_left"]=100
	Creator.act("start","Pop")
	Creator.act("collab")
	var s := Creator.state()
	s["project"]["mixing"]=true
	Creator._mix_done(0.8,{},1)
	Creator.act("release")
	Creator.act("release")
	ok(s["catalog"].size()==1 and int(s["listeners"])>0,"release missing or duplicated")
	var track: Dictionary = s["catalog"][0]
	cash=int(GameState.player["money"])
	Creator.license_track({"title":track["title"],"offer":500})
	Creator.license_track({"title":track["title"],"offer":500})
	ok(GameState.player["money"]==cash+500,"license paid twice")
	Creator.act("fan_open")
	for i in range(4): Creator.act("fan_post","Art & essays")
	ok(int(s["fanclub"]["posts"])==3,"subscription posting cap")
	GameState.player["age"]+=1
	Creator.yearly()
	cash=int(GameState.player["money"])
	Creator.yearly()
	ok(GameState.player["money"]==cash and int(s["fanclub"]["posts"])==0,"creator annual payout repeated")
	Creator.act("fan_close")
	GameState.player["age"]+=1
	Creator.yearly()
	ok(GameState.player["money"]==cash,"closed channel still pays or licensed track royalties continued")
	fresh()
	Household.act("plan","balanced")
	ok(GameState.player["routines"]["family"] and GameState.player["routines"]["walk"] and not GameState.player["routines"]["study"],"routine preset incorrect")
	Household.act("complete")
	GameState.player["age"]+=1
	var time := int(GameState.player["time_left"])
	Household.yearly()
	ok(GameState.player["time_left"]==time,"completed chores charged twice")
	Household.act("chores","service")
	GameState.player["age"]+=1
	ok(Household.service_cost()==1200,"service price incorrect")
	EventEngine._yearly_finances()
	var ledger: Dictionary = GameState.player["household_ledger"]
	var total := 0
	for amount in ledger["lines"].values(): total+=int(amount)
	ok(total==int(ledger["expenses"]) and total==int(GameState.player["last_expenses"]),"household ledger differs from actual bills")
	fresh()
	Ventures.acquire("casino")
	ok(not bool(Become.check("casino")[0]),"owned casino still charges another application")
	var child := GameState.create_npc("child",{"age":21,"money":500})
	ok(Dynasty.switch_to(child),"viewpoint switch failed")
	ok(Ventures.book().is_empty(),"child stole living parent's venue")
	var parent := GameState.first_of("mother")
	ok(GameState.npcs[parent]["playable_player"]["ventures"].has("casino"),"former owner lost venue")
	GameState.player["age"]+=1
	FamilyChronicle.yearly()
	ok(not GameState.npcs[parent]["playable_player"]["ventures"]["casino"]["report"].is_empty(),"dormant venue never operates")
	for key in ["root","casino","museum","agency","luxury","history:casino"]:
		ok(not Ventures.menu(key).is_empty(),"venue menu missing "+key)
	for key in ["studio","catalog","fans"]: ok(not Creator.menu(key).is_empty(),"creator menu missing "+key)
	ok(not Household.menu("root").is_empty(),"household menu missing")
	var former: Dictionary = GameState.npcs[parent]["playable_player"]
	former["money"]=-1000000
	former["ventures"]["casino"]["reserve"]=0
	former["ventures"]["casino"]["quality"]=0
	former["ventures"]["casino"]["reputation"]=0
	Ventures.operate(former,GameState.year_now()+1,false)
	ok(not former["ventures"].has("casino"),"insolvent former player's venue stays open")
	var reloaded := GameState.to_dict()
	reloaded["player"]=former.duplicate(true)
	reloaded["flags"]={"owns_casino":true}
	GameState.from_dict(reloaded)
	Ventures.migrate()
	ok(not Ventures.book().has("casino"),"closed legacy venue recreated on returning to owner")
	fresh()
	Ventures.acquire("casino")
	var heir := GameState.create_npc("child",{"age":21,"money":500})
	var estate := maxi(0,GameState.net_worth()-Finance.properties_value()-Finance.possessions_value())
	var tx: Array = GameState.ESTATE_TAX["us"]
	var tax := int(maxi(0,estate-int(tx[1]))*float(tx[0]))
	var expected_share := int((estate-tax)*0.95)+int(GameState.npcs[heir]["money"])
	GameState.player["alive"]=false
	GameState.continue_as(heir)
	ok(int(GameState.player["money"])==expected_share,"venue estate value lost or paid twice: got %d expected %d estate %d" % [int(GameState.player["money"]),expected_share,estate])
	ok(Ventures.book().is_empty(),"estate both paid and copied a venue")
	print("V29 TEST checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: print("FAIL: "+str(failure))
	get_tree().quit(0 if failures.is_empty() else 1)
