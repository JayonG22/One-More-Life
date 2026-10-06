extends Node
var fails: Array = []
var checks := 0
func ok(value:bool, message:String) -> void:
	checks += 1
	if not value: fails.append(message)
func fresh() -> void:
	EventEngine.pending.clear()
	GameState.new_life({"first":"Morgan","last":"Vale","gender":"female","country":"us"})
	GameState.player["age"] = 40
func _ready() -> void:
	seed(2828)
	fresh()
	var child := GameState.create_npc("child",{"first":"Ari","age":20,"money":1234})
	var partner := GameState.create_npc("partner",{"first":"Robin","age":40})
	GameState.player["partner"] = partner
	FamilyChronicle.sync()
	var parent_uid := FamilyChronicle.identity(GameState.player)
	var child_uid := FamilyChronicle.identity(GameState.npcs[child])
	var partner_uid := FamilyChronicle.identity(GameState.npcs[partner])
	FamilyChronicle.remember(child,"We planned my future together.")
	GameState.set_flag("parent_story")
	GameState.player["job"]={"id":"teacher","title":"Teacher","salary":40000}
	GameState.player["personal_history"]=[{"year":GameState.year_now(),"text":"My own childhood memory."}]
	GameState.player["money"]=60000
	GameState.player["mortgage"]=1000
	GameState.player["mortgage_payment"]=700
	ok(Dynasty.switch_to(child),"switch failed")
	ok(GameState.player["person_uid"]==child_uid,"child identity changed")
	ok(GameState.player["personal_history"][0]["text"]=="We planned my future together.","child memory disappeared")
	ok(GameState.player["parent_uids"].has(parent_uid) and not GameState.player["parent_uids"].has(partner_uid),"unknown partner was invented as biological parent")
	ok(GameState.npcs[partner]["relation"]=="family_friend","unknown parent acquired a parent label")
	var parent_id := GameState.first_of("mother")
	ok(GameState.npcs[parent_id]["person_uid"]==parent_uid,"parent identity changed")
	ok(GameState.npcs[parent_id]["personal_history"][0]["text"]=="My own childhood memory." and GameState.npcs[parent_id]["job"]["key"]=="teacher","parent history or occupation perks lost")
	ok(GameState.npcs[parent_id]["personal_story"]["flags"].has("parent_story") and not GameState.flags.has("parent_story"),"parent story mixed into child's story")
	GameState.player["age"]+=1
	GameState.npcs[parent_id]["age"]+=1
	FamilyChronicle.yearly()
	var after := int(GameState.npcs[parent_id]["money"])
	ok(after==77300,"former player annual ledger incorrect")
	ok(GameState.npcs[parent_id]["playable_player"]["age"]==41 and GameState.npcs[parent_id]["playable_player"]["money"]==after,"former snapshot frozen in time")
	ok(GameState.npcs[parent_id]["playable_player"]["mortgage"]==300,"former mortgage not reduced")
	FamilyChronicle.yearly()
	ok(GameState.npcs[parent_id]["money"]==after,"former budget applied twice in same year")
	GameState.player["age"]+=1
	FamilyChronicle.yearly()
	ok(GameState.npcs[parent_id]["playable_player"]["mortgage"]==0 and GameState.npcs[parent_id]["playable_player"]["mortgage_payment"]==0,"paid mortgage continues charging")
	var data := GameState.to_dict().duplicate(true)
	GameState.from_dict(data)
	ok(GameState.player["person_uid"]==child_uid and FamilyChronicle.book()["people"].has(parent_uid),"save roundtrip lost family identities")
	for i in range(45): FamilyChronicle.remember(parent_id,"Memory %d" % i)
	ok(GameState.npcs[parent_id]["personal_history"].size()==32 and FamilyChronicle.book()["people"][parent_uid]["history"].size()==32,"history bound broken")
	FamilyChronicle.before_year()
	GameState.player["money"]+=99
	ok(FamilyChronicle.summary().size()>=3 and str(FamilyChronicle.summary()[1]).contains("99"),"annual financial summary is stale")
	fresh()
	partner=GameState.create_npc("partner",{"age":40})
	GameState.player["partner"]=partner
	EventEngine._have_baby()
	child=GameState.first_of("child")
	FamilyChronicle.sync()
	ok(GameState.npcs[child]["parent_uids"].size()==2,"new baby lost known parents")
	# Every outcome must retain its branch and original person, including death.
	var roots := 0
	var scenes := 0
	for def in ContentDB.events:
		if not str(def["id"]).begins_with("chronicle."): continue
		scenes+=1
		if def.get("followup_only",false): continue
		roots+=1
		for choice in def["choices"]:
			for outcome in choice["outcomes"]:
				fresh()
				GameState.player["age"]=40
				var person := GameState.create_npc("child",{"age":20})
				EventEngine._apply_outcome(outcome,{"person":person},def)
				ok(GameState.followups.size()==1,"consequence not scheduled: "+def["id"])
				var echo: Dictionary = ContentDB.events_by_id.get(outcome["schedule"]["event"],{})
				ok(not echo.is_empty() and echo["roles"]["person"].get("bound",false),"missing bound consequence")
				ok(GameState.npcs[person]["personal_history"][0]["text"]==outcome["family_memory"]["memory"],"memory does not match decision")
				GameState.npcs[person]["alive"]=false
				GameState.create_npc("child",{"age":20})
				var roles := EventEngine._build_roles(echo,{"person":person})
				ok(roles.get("person","")==person,"consequence replaced deceased person")
				GameState.player["age"] = GameState.followups[0]["age"]
				EventEngine._due_followups()
				ok(EventEngine.has_pending() and EventEngine.pending[-1]["def"]["id"]==echo["id"] and EventEngine.pending[-1]["roles"]["person"]==person,"yearly flow dropped or changed deceased-person reflection")
				ok(EventEngine._build_roles(echo,{"person":"missing"}).get("__fail",false),"missing bound person replaced with a stranger")
				for response in echo["choices"]:
					for result in response["outcomes"]:
						EventEngine._apply_outcome(result,roles,echo)
						ok(GameState.is_alive(),"reflection killed active character")
	ok(roots==14 and scenes==56,"authored scene/arc counts changed")
	fresh()
	ok(not EventEngine._eligible(ContentDB.events_by_id["chronicle.boundary"],false),"unemployed character receives a work interruption")
	fresh()
	child=GameState.create_npc("child",{"age":20})
	var sibling := GameState.create_npc("child",{"age":18,"money":4321,"health":61,"smarts":73})
	var grandchild := GameState.create_npc("grandchild",{"age":2})
	GameState.npcs[grandchild]["parent_id"] = sibling
	partner=GameState.create_npc("partner",{"age":40})
	GameState.npcs[partner]["grudge"]=100
	GameState.player["partner"]=partner
	GameState.player["partner_status"]="married"
	FamilyChronicle.sync()
	var sibling_uid: String = GameState.npcs[sibling]["person_uid"]
	var grandchild_uid: String = GameState.npcs[grandchild]["person_uid"]
	parent_uid=GameState.player["person_uid"]
	child_uid=GameState.npcs[child]["person_uid"]
	FamilyChronicle.remember(child,"An existing child's memory.")
	GameState.player["job"]={"id":"teacher","title":"Teacher","salary":45678}
	GameState.player["money"]=10000
	GameState.player["alive"]=false
	GameState.continue_as(child)
	ok(GameState.player["person_uid"]==child_uid and GameState.player["personal_history"][0]["text"]=="An existing child's memory.","death succession lost child history")
	ok(not FamilyChronicle.book()["people"][parent_uid]["alive"],"deceased parent alive in family book")
	ok(FamilyChronicle.book()["people"][parent_uid]["job"]=="Teacher" and FamilyChronicle.book()["people"][parent_uid]["money"]==10000,"death succession replaced parent's recorded life")
	var new_sibling := ""
	for id in GameState.npcs:
		if GameState.npcs[id].get("person_uid","")==sibling_uid: new_sibling=id
	ok(new_sibling!="" and GameState.npcs[new_sibling]["money"]==4321 and GameState.npcs[new_sibling]["health"]==61 and GameState.npcs[new_sibling]["smarts"]==73,"death succession rerolled surviving relatives")
	for n in GameState.npcs.values():
		if n.get("person_uid","")==grandchild_uid: ok(n["parent_id"]==new_sibling,"death succession left stale parent links")
	var identities: Array = [GameState.player["person_uid"]]
	for n in GameState.npcs.values():
		if n.get("species","human")!="human": continue
		ok(not identities.has(n["person_uid"]),"duplicate family identity after succession")
		identities.append(n["person_uid"])
	print("V28 TEST checks=%d failures=%d" % [checks,fails.size()])
	for fail in fails: print("FAIL: ",fail)
	get_tree().quit(1 if not fails.is_empty() else 0)
