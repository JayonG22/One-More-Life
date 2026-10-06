extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func _ready() -> void:
	seed(8180); GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	for named in [false,true]:
		GameState.new_life({"country":"us","gender":"male","random_royalty":false}); clear()
		GameState.player["age"]=50; GameState.player["money"]=100000; GameState.player["loan"]=1000
		GameState.player["savings"]=0; GameState.player["time_left"]=12
		var stock: String=GameState.world["stocks"].keys()[0]
		GameState.player["stocks"]={stock:10}; var investment := Finance.investments_value()
		GameState.player["possessions"]=[{"name":"Parent's watch","value":1000}]
		Journey.section("collection",{})
		GameState.player["journey"]["collection"]={"items":[{"name":"Old family letter","value":0}],"history":["Letter saved"]}
		var source := Journey.uid()
		var heir := GameState.create_npc("child",{"first":"Ari","age":25,"money":321})
		var sibling := GameState.create_npc("child",{"first":"Bo","age":23,"money":222})
		var sibling_uid := FamilyChronicle.identity(GameState.npc(sibling))
		if named: Journey.modules["heritage"].plan("heir:"+heir); clear()
		var original_money := int(GameState.player["money"])
		ok(Dynasty.switch_to(heir),"Cannot enter child's existing life")
		clear(); GameState.player["loan"]=1000000; GameState.player["stocks"]={stock:999}; GameState.player["savings"]=6000
		var child_investments := Finance.investments_value(); var child_money := int(GameState.player["money"])
		var parent: String=Journey.person(source)
		ok(parent!="" and GameState.npc(parent)["alive"],"Live transfer lost original parent")
		GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
		EventEngine._npc_died(parent); clear()
		var receipt: Dictionary=GameState.world["estate_register"].get(source,{})
		ok(receipt.get("status","")=="executed" and receipt["allocations"].size()==2,"Former player's death bypassed actual estate")
		var transferred := 0; var selected := 0; var other_cash := 0
		for allocation in receipt["allocations"]:
			transferred+=int(allocation["cash"])+int(allocation["physical"])
			if allocation["uid"]==Journey.uid(): selected=int(allocation["cash"])
			if allocation["uid"]==sibling_uid: other_cash=int(allocation["cash"])
		var estate_cash := original_money+investment-1000
		var fees := int(estate_cash*0.05)
		ok(transferred==estate_cash-fees+1000,"Estate included active child's stocks/debt or lost parent wealth")
		ok(GameState.player["money"]==child_money+selected,"Active heir cash missing or duplicated")
		ok(GameState.npc(sibling)["money"]==222+other_cash,"Real sibling receives no estate")
		ok(GameState.player["loan"]==1000000 and GameState.player["savings"]==6000 and Finance.investments_value()==child_investments,"Parent settlement touched child-owned finances")
		ok(GameState.player["possessions"].size()+GameState.npc(sibling).get("possessions",[]).size()==2,"Former parent's watch or letter lost or duplicated")
		if named: ok(selected>other_cash,"Named actual heir lost priority after ID/viewpoint change")
		ok(GameState.npc(sibling)["relation"]=="sibling" and not GameState.player.has("relation"),"Estate rewired active family roles")
		ok(GameState.npc(parent)["money"]==0 and GameState.npc(parent)["playable_player"]["stocks"].is_empty(),"Settled former player retained distributed assets")
		var settled: Dictionary=GameState.npc(parent)["playable_player"]
		ok(not settled["alive"] and settled["car"]=="" and settled["car_record"].is_empty(),"Former player snapshot retained life or vehicle ownership")
		ok(settled["journey"]["collection"]["items"].is_empty() and settled["journey"]["collection"]["history"]==["Letter saved"],"Collection ownership duplicated or provenance erased")
		GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
		var money := int(GameState.player["money"]); EventEngine._npc_died(parent); clear()
		ok(GameState.player["money"]==money,"Reloaded death duplicated inheritance")
		ok(not Journey.modules["heritage"].duties.rows().is_empty(),"Former parent estate has no receipt/duty route")
	# A residence with negative equity cannot saddle an heir with the shortfall.
	GameState.new_life({"country":"us","gender":"male","random_royalty":false}); clear()
	GameState.player["age"]=50; GameState.player["money"]=1000
	GameState.player["housing"]="house"; GameState.player["house_value"]=100000; GameState.player["mortgage"]=105000
	var source := Journey.uid(); var heir := GameState.create_npc("child",{"age":25,"money":321})
	ok(Dynasty.switch_to(heir),"Underwater-house fixture could not enter child life"); clear()
	var parent: String=Journey.person(source); EventEngine._npc_died(parent); clear()
	var receipt: Dictionary=GameState.world["estate_register"][source]
	ok(receipt["unpaid"]==4000 and receipt["allocations"][0]["physical"]==0,"Secured shortfall omitted or house awarded at zero equity")
	ok(GameState.player["money"]==321 and GameState.player["mortgage"]==0 and GameState.player["housing"]!="house","Negative-equity residence or debt inherited by child")
	for player in Fx.find_children("*","AudioStreamPlayer",true,false): player.stop(); player.stream=null
	await get_tree().create_timer(0.2).timeout
	print("INACTIVE ESTATE checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
