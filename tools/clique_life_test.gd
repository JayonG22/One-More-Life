extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh(group: String) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=13; GameState.player["time_left"]=12
	GameState.player["education"]["stage"]="secondary"; Daily._ss()["clique"]=group; clear()
func answer(index: int) -> Dictionary:
	var event := EventEngine.pop_next()
	var spec: Dictionary=event["def"]["choices"][index]["outcomes"][0]["depth"].duplicate(true)
	EventEngine.resolve(event,index); clear(); return spec
func _ready() -> void:
	seed(1828); GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	var life=Depth.clique_life; var bank: Array=life.scenes.duplicate(true)
	var texts: Dictionary={}; var ends: Dictionary={}
	for scene in bank:
		texts[scene["text"]]=true
		ok(Daily.CLIQUES.has(scene["clique"]) and scene["choices"].size()==3,"Invalid clique scene")
		for end in scene["ends"]: ends[end]=true
		for choice in range(3):
			fresh(str(scene["clique"])); life.scenes=[scene]
			var time := int(GameState.player["time_left"]); Depth.school_activity("clique",str(scene["clique"]))
			ok(GameState.player["time_left"]==time-1,"Clique decision not charged once")
			var uid := str(Depth.state()["active"]["clique_peer"]); var peer := Journey.person(uid)
			ok(peer!="" and GameState.npc(peer)["alive"] and GameState.npc(peer)["age"]==13,"Clique has no age-appropriate classmate")
			var trust := BondStats.get_stat(peer,"trust"); var popularity := float(Daily._ss()["popularity"])
			GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear(); Depth.restore()
			ok(Depth.state()["active"]["clique_scene"]==scene and str(Depth.state()["active"]["clique_peer"])==uid,"Saved clique decision rerolled")
			var spec := answer(choice)
			ok(is_equal_approx(BondStats.get_stat(peer,"trust"),clampf(trust+float(scene["trust"][choice]),0,100)),"Clique choice did not affect the named classmate")
			ok(is_equal_approx(float(Daily._ss()["popularity"]),clampf(popularity+float(scene["popularity"][choice]),0,100)),"Clique choice has no popularity consequence")
			var record: Dictionary=Depth.state()["clique_work"][0]
			ok(record["choice"]==scene["choices"][choice] and record["result"]==scene["ends"][choice] and record["peer"]==uid,"Clique ending or actual person lost")
			var follow: Dictionary=Journey.modules["pathways"].st()["cases"][0]
			ok(follow["uid"]==uid and follow["honest"]==scene["honest"][choice],"Clique follow-up fabricates someone or removes dishonest conduct")
			var count: int=Depth.state()["clique_work"].size(); var history: Dictionary=Depth.state()["school_history"].duplicate(true)
			Depth.outcome(spec); life.finish(choice); clear()
			ok(Depth.state()["clique_work"].size()==count and Depth.state()["school_history"]==history,"Clique reward replays")
			ok(Journey.modules["school"].menu("cliques")["info"].any(func(line): return str(line).contains(str(scene["title"]))),"Clique decision has no readable record")
	life.scenes=bank; ok(texts.size()==27 and ends.size()>=57,"Clique content repeats")
	for group in Daily.CLIQUES:
		var total: int=bank.filter(func(scene): return scene["clique"]==group).size()
		ok(total>=1,"Clique lacks distinct scenes")
		fresh(str(group)); var seen: Array=[]; var uid := ""
		for year in range(3):
			Depth.school_activity("clique",str(group))
			if year<total:
				seen.append(Depth.state()["active"]["clique_scene"]["id"])
				if year==0: uid=str(Depth.state()["active"]["clique_peer"])
				else: ok(uid==str(Depth.state()["active"]["clique_peer"]),"Clique forgot its recurring classmate")
				answer(0)
			else: ok(Depth.state()["active"].is_empty() and Depth.state()["clique_work"][0]["task"]=="Quiet meetup","Clique repeated an exhausted authored decision")
			clear(); var time := int(GameState.player["time_left"]); Depth.school_activity("clique",str(group)); clear()
			ok(time==int(GameState.player["time_left"]),"Clique ignored annual activity limit")
			GameState.player["age"]+=1; GameState.player["time_left"]=12
		ok(seen.size()==total and (total==1 or seen[0]!=seen[1]),"Clique repeats next year")
	fresh("nerds"); Depth.school_activity("clique","nerds"); answer(0)
	var old := str(Depth.state()["clique_work"][0]["peer"]); GameState.npc(Journey.person(old))["alive"]=false
	GameState.player["age"]+=1; GameState.player["time_left"]=12; Depth.school_activity("clique","nerds")
	ok(str(Depth.state()["active"]["clique_peer"])!=old,"Clique selected a deceased classmate"); answer(0)
	ok(Depth.state()["clique_work"][1]["peer"]==old,"Replacement overwrote the previous relationship")
	fresh("unknown"); Depth.school_activity("clique","unknown"); ok(GameState.player["time_left"]==12,"Invalid clique consumed time")
	print("CLIQUE LIFE TEST checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: print("FAIL: "+str(failure))
	get_tree().quit(0 if failures.is_empty() else 1)
