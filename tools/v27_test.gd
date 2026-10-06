extends Node
var fails: Array = []
var checks := 0
func ok(value: bool, message: String) -> void:
	checks += 1
	if not value: fails.append(message)
func fresh() -> void:
	EventEngine.pending.clear()
	GameState.new_life({"gender":"female","country":"us","first":"Parent","last":"Quill"})
	GameState.player["age"] = 40
	GameState.player["money"] = 75000
func _ready() -> void:
	seed(2727)
	fresh()
	var child_id := GameState.create_npc("child",{"first":"Ari","last":"Quill","gender":"nonbinary","age":23,"money":4321,"smarts":82,"health":71,"looks":63,"happiness":58})
	var sibling_id := GameState.create_npc("child",{"first":"Sam","last":"Quill","age":16})
	var grandchild_id := GameState.create_npc("grandchild",{"first":"Kit","age":2})
	GameState.npcs[grandchild_id]["parent_id"] = child_id
	GameState.npcs[child_id]["education"] = {"stage":"graduated","performance":88,"hs_graduated":true,"degrees":[{"major":"english","level":"bachelor"}]}
	GameState.npcs[child_id]["job"] = {"id":"teacher","key":"teacher","title":"Teacher","salary":45678}
	var year := GameState.year_now()
	var price := float(GameState.world["stocks"]["NMB"])
	var grave_count := SaveManager.graveyard.size()
	ok(Dynasty.switch_to(child_id),"live switch failed")
	ok(GameState.player["age"]==23 and GameState.player["first"]=="Ari","switch reset age or identity")
	ok(GameState.player["money"]==4321,"switch transferred estate or changed personal money")
	ok(GameState.stat("health")==71 and GameState.stat("smarts")==82 and GameState.stat("looks")==63 and GameState.stat("happiness")==58,"switch rerolled recorded stats")
	ok(GameState.player["education"]["degrees"][0]["major"]=="english","switch lost recorded education")
	ok(GameState.player["job"]["id"]=="teacher" and GameState.player["job"]["salary"]==45678,"switch lost recorded employment")
	ok(GameState.npcs[sibling_id]["relation"]=="sibling" and GameState.npcs[grandchild_id]["relation"]=="child","switch broke family relations")
	var parent_id := GameState.first_of("mother")
	ok(parent_id!="" and GameState.npcs[parent_id]["alive"] and GameState.npcs[parent_id]["money"]==75000,"living parent was killed or stripped of money")
	ok(GameState.year_now()==year and float(GameState.world["stocks"]["NMB"])==price,"switch reset the world or advanced time")
	ok(SaveManager.graveyard.size()==grave_count,"live parent was put in graveyard")
	var save := GameState.to_dict().duplicate(true)
	GameState.from_dict(save)
	ok(GameState.player["age"]==23 and GameState.npcs[parent_id]["alive"],"live switch failed save roundtrip")
	EventEngine.pending=[{"def":{"id":"_trial"}}]
	ok(not Dynasty.switch_to(grandchild_id),"switch bypasses pending legal decision")
	fresh()
	child_id=GameState.create_npc("child",{"age":7,"money":20,"smarts":64})
	GameState.npcs[child_id]["school"]=77
	ok(Dynasty.switch_to(child_id) and GameState.player["age"]==7 and GameState.player["education"]["stage"]=="primary" and GameState.player["education"]["performance"]==77,"young child's current school was reset")
	fresh()
	child_id = GameState.create_npc("child", {"age":25,"money":4321,"health":71,"smarts":82})
	GameState.npcs[child_id]["job"] = {"id":"teacher","key":"teacher","title":"Teacher","salary":45678}
	GameState.npcs[child_id]["education"] = {"stage":"graduated","hs_graduated":true,"degrees":[{"major":"english","level":"bachelor"}]}
	GameState.player["alive"] = false
	GameState.continue_as(child_id)
	ok(GameState.is_alive() and GameState.player["age"]==25 and GameState.stat("health")==71 and GameState.stat("smarts")==82,"death succession rerolls the child")
	ok(GameState.player["money"]==75571,"death succession loses personal money or miscalculates estate share")
	ok(GameState.player["job"]["salary"]==45678 and GameState.player["education"]["degrees"][0]["major"]=="english","death succession loses recorded education or employment")
	for definition in ContentDB.events:
		if not definition.get("mature",false): continue
		fresh()
		GameState.player["age"]=17
		ok(not EventEngine._eligible(definition,false) and not EventEngine._eligible(definition,true),"mature scene eligible below adulthood: "+definition["id"])
		GameState.player["age"]=30
		GameState.settings["mature_arcs"]=false
		if not definition.get("followup_only",false): ok(not EventEngine._eligible(definition,false),"content setting ignored")
		GameState.settings["mature_arcs"]=true
		for choice in definition.get("choices",[]):
			for outcome in choice["outcomes"]:
				fresh()
				var partner:=GameState.create_npc("partner",{"age":30})
				GameState.player["partner"]=partner
				EventEngine._apply_outcome(outcome,{"partner":partner},definition)
				ok(GameState.is_alive(),"adult scene unexpectedly killed active character")
				if outcome.has("jail"): ok(GameState.in_prison() and not GameState.player["record"].is_empty(),"serious crime lacks prison/record consequence")
				if outcome.has("schedule"): ok(ContentDB.events_by_id.has(outcome["schedule"]["event"]) and not GameState.followups.is_empty(),"mature delayed consequence missing")
	fresh()
	GameState.player["age"]=30
	GameState.player["prison"]=5
	GameState.set_flag("mature_murder_offer")
	GameState.settings["mature_arcs"]=false
	ok(EventEngine._eligible(ContentDB.events_by_id["mature.murder_offer.echo"],true),"turning off new mature arcs erases a prison consequence")
	GameState.settings["mature_arcs"]=true
	for mode in ThemeManager.PALETTES:
		ThemeManager.apply(mode)
		for surface in ["bg","surface","surface2","event_bg"]:
			ok(ThemeManager.c(surface).srgb_to_linear().get_luminance()<0.10,"bright surface in "+mode+"/"+surface)
		ok(ThemeManager.theme.get_stylebox("panel","PanelContainer").border_width_left==0,"default panels have borders")
		for kind in ["Card","HubPanel","EventCard","EventFrame","Tomb","Banner","Halo"]:
			var style: StyleBoxFlat = ThemeManager.theme.get_stylebox("panel",kind)
			ok(style.bg_color.srgb_to_linear().get_luminance()<0.10,"bright panel in "+mode+"/"+kind)
		var stone := Tombstone.new()
		stone.setup({"age":60},{},{"money":6000000,"life":{"type":"human"}})
		ok(stone.stone_col.srgb_to_linear().get_luminance()<0.10,"bright custom memorial in "+mode)
		stone.free()
	ThemeManager.apply("ink")
	print("V27 TEST checks=%d failures=%d" % [checks,fails.size()])
	for fail in fails: print("FAIL: ",fail)
	get_tree().quit(1 if not fails.is_empty() else 0)
