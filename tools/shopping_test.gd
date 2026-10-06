extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, reason: String) -> void:
	checks+=1
	if not value: failures.append(reason)
func fresh(age: int = 30) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=age
	GameState.player["money"]=100000000
	EventEngine.pending.clear()
	EventEngine.displayed.clear()
func _ready() -> void:
	seed(3133)
	fresh()
	var root: Dictionary=Shop.menu("root")
	ok(root["rows"].size()==11,"shopping categories missing")
	var byte_tags: Array=[]
	var swoon_tags: Array=[]
	for d in Shop.retail_stock("best_byte"): byte_tags.append(d[3])
	for d in Shop.retail_stock("samswoon"): swoon_tags.append(d[3])
	ok(byte_tags.has("console") and not swoon_tags.has("console"),"different electronics retailers have identical stock")
	ok(swoon_tags.has("camera") and not byte_tags.has("camera"),"specialist camera inventory absent")
	for sid in Shop.retail_data():
		var menu: Dictionary=Shop.menu(sid)
		ok(menu["rows"].size()>0,"empty retailer: "+sid)
		for i in range(Shop.retail_stock(sid).size()):
			fresh()
			var d: Array=Shop.item_data(sid,i)
			var house: String=Shop.houses_for(sid)[0]
			# Restricted stock is tested through its disabled row, not bought illegally.
			if Shop._need(d)!="":
				ok(not Shop.menu(sid)["rows"][i]["on"],"restricted item enabled")
				continue
			var before: int=GameState.player["money"]
			Shop.act("buy_version",[sid,i,house,0])
			ok(GameState.player["possessions"].size()==1,"purchase failed: "+sid)
			ok(before-int(GameState.player["money"])==Actions._cost(int(d[2])),"retail price mismatch")
			var it: Dictionary=GameState.player["possessions"][0]
			ok(it["tag"]==d[3] and it["house"]==house,"model lost functional tag or brand")
			GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict())))
			ok(GameState.player["possessions"][0]["name"]==it["name"],"model name lost on reload")
			Shop.act("sell",0)
			ok(GameState.player["possessions"].is_empty(),"retail model cannot be sold")
	fresh(5)
	Shop.act("buy_version",["best_byte",0,"byte",0])
	ok(GameState.player["possessions"].is_empty(),"underage direct retail action charged")
	fresh()
	Shop.act("buy_version",["best_byte",0,"bespoke",0])
	ok(GameState.player["possessions"].is_empty(),"retailer sold unavailable brand")
	Shop.act("buy_version",["best_byte",999,"byte",0])
	ok(GameState.player["possessions"].is_empty(),"invalid product mutated possessions")
	for id in Actions.HOME_MODELS:
		fresh()
		var before: int=GameState.player["money"]
		Shop.act("house",id)
		var price := Actions.house_price(id)
		ok(GameState.player["house_model"]==id,"wrong home model")
		ok(GameState.player["house_value"]==price,"wrong home value")
		ok(before-int(GameState.player["money"])==int(price*0.2),"wrong down payment")
		ok(GameState.player["mortgage"]==int((price-int(price*0.2))*1.35),"wrong mortgage")
		ok(Icons.for_housing("house",price)==Actions.HOME_MODELS[id]["icon"],"home silhouette mismatch")
		GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict())))
		ok(GameState.player["house_model"]==id,"home model lost on reload")
		Actions.sell_house()
		ok(not GameState.player.has("house_model") and GameState.player["mortgage"]==0,"home sale left stale model or debt")
	fresh()
	GameState.player["money"]=30000
	var before: int=GameState.player["money"]
	Shop.act("house","studio")
	ok(GameState.player["housing"]!="house" and GameState.player["money"]==before,"denied mortgage charged cash")
	for id in GameState.CARS:
		fresh()
		GameState.player["licenses"].append("driver")
		before=GameState.player["money"]
		Shop.act("car",id)
		ok(GameState.player["car"]==id,"wrong purchased car")
		ok(before-int(GameState.player["money"])==Actions._cost(GameState.CARS[id]["price"]),"wrong car price")
		ok(Icons.has(Icons.for_car(id)),"missing vehicle icon")
		GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict())))
		ok(GameState.player["car"]==id,"car model lost on reload")
		Actions.sell_car()
		ok(GameState.player["car"]=="","car sale failed")
	fresh()
	Shop.act("car","electric")
	ok(GameState.player["car"]=="","unlicensed car purchase allowed")
	var breeds := 0
	for sp in Companions.KINDS:
		for breed in Companions.breeds(sp):
			fresh()
			breeds+=1
			var price := Companions.purchase_price(sp,"shop",breed["name"])
			before=GameState.player["money"]
			Companions.act("get",[sp,"shop",1,breed["name"]])
			var pets: Array=Companions.pets()
			ok(pets.size()==1,"animal variety acquisition failed")
			var n: Dictionary=GameState.npc(pets[0])
			ok(n["breed"]==breed["name"],"selected breed not retained")
			ok(before-int(GameState.player["money"])==price,"client-supplied animal price trusted")
			ok(Companions.status_line(pets[0]).contains(breed["name"]),"breed invisible in animal panel")
			GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict())))
			ok(GameState.npc(pets[0])["breed"]==breed["name"],"breed lost on reload")
			ok(Companions.purchase_price(sp,"shelter",breed["name"])==Actions._cost(Companions.KINDS[sp]["adopt"]),"pedigree inflated adoption fee")
	ok(breeds==37,"breed catalogue incomplete")
	fresh(7)
	Companions.act("get",["dog","shop",0,"Shiba Inu"])
	ok(Companions.pets().is_empty(),"underage animal purchase allowed")
	fresh()
	for i in range(6): Companions.acquire("dog")
	before=GameState.player["money"]
	Companions.act("get",["cat","shop",0,"Bengal"])
	ok(Companions.pets().size()==6 and GameState.player["money"]==before,"pet capacity bypassed")
	GameState.npc(Companions.pets()[0])["alive"]=false
	ok(Companions.available_slots()==1,"deceased pet blocks adoption forever")
	var old: String=Companions.pets()[1]
	GameState.npc(old).erase("breed")
	ok(Companions.ensure(old).has("breed"),"old animal save did not gain default breed")
	print("SHOPPING TEST checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: print("FAIL: "+str(failure))
	get_tree().quit(0 if failures.is_empty() else 1)
