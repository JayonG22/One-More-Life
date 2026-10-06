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
	GameState.player["age"]=21; GameState.player["money"]=10000; GameState.player["loan"]=17000; GameState.player["time_left"]=20
	GameState.player["education"]["uni"]={"major":"computer_science","level":"bachelor","years":4,"year":3,"performance":72.0,"scholarship":0.5}
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes(); clear()
func _ready() -> void:
	fresh()
	var related := Actions.major_change_preview("game_dev")
	var other := Actions.major_change_preview("culinary")
	ok(related["credit"]==2 and related["lost"]==1,"Related subject credit incorrect")
	ok(other["credit"]==1 and other["lost"]==2,"Unrelated subject credit incorrect")
	ok(Actions.major_change_preview("computer_science").is_empty() and Actions.major_change_preview("medicine").is_empty() and Actions.major_change_preview("invalid").is_empty(),"Invalid/no-op/postgraduate transfer offered")
	var money: int=GameState.player["money"]; var time: int=GameState.player["time_left"]
	Actions.change_major("game_dev"); clear()
	var u: Dictionary=GameState.player["education"]["uni"]
	ok(u["major"]=="game_dev" and u["year"]==2 and u["years"]==4,"New subject did not preserve approved credit")
	ok(GameState.player["money"]==money-int(related["fee"]) and GameState.player["time_left"]==time-1,"Transfer fee/time incorrect")
	ok(GameState.player["loan"]==17000 and u["scholarship"]==0.5 and u["performance"]==72,"Transfer lost debt/scholarship/grades")
	ok(GameState.player["education"]["degrees"].is_empty(),"Transfer awarded a degree early")
	var saved: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.from_dict(saved); clear(); money=GameState.player["money"]
	Actions.change_major("culinary")
	ok(GameState.player["money"]==money and GameState.player["education"]["uni"]["major"]=="game_dev","Reload bypassed annual transfer guard")
	ok(GameState.player["education"]["study_changes"].size()==1,"Transfer history missing/duplicated")
	GameState.player["age"]+=1; clear(); Actions.change_major("culinary"); clear()
	ok(GameState.player["education"]["uni"]["year"]==1 and GameState.player["education"]["study_changes"].size()==2,"Later unrelated transfer incorrect")
	fresh(); GameState.player["money"]=0; Actions.change_major("game_dev")
	ok(GameState.player["education"]["uni"]["major"]=="computer_science" and GameState.player["time_left"]==20,"Unaffordable transfer changed student")
	fresh(); GameState.player["time_left"]=0; Actions.change_major("game_dev")
	ok(GameState.player["money"]==10000 and GameState.player["education"]["uni"]["year"]==3,"No-time transfer changed student")
	fresh(); Journey.decision("learning","unit",{"units":0,"order":[0,1,2],"task":{}},"An unfinished lesson","Choose first",["One","Two","Three"])
	Actions.change_major("game_dev")
	ok(GameState.player["money"]==10000 and GameState.player["education"]["uni"]["major"]=="computer_science","Transfer bypassed pending decision")
	# Every pair retains fewer credits than the new degree requires.
	fresh()
	for old in ContentDB.majors_of_level("bachelor"):
		GameState.player["education"]["uni"]["major"]=old["id"]
		GameState.player["education"]["uni"]["year"]=int(old["years"])-1
		for target in ContentDB.majors_of_level("bachelor"):
			if old["id"]==target["id"]: continue
			var p := Actions.major_change_preview(str(target["id"]))
			ok(not p.is_empty() and int(p["remaining"])>=1 and int(p["credit"])<=int(old["years"])-1,"Transfer creates a free graduation: "+str(old["id"])+" to "+str(target["id"]))
	print("STUDY TRANSFER checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
