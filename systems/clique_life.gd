extends RefCounted
var hub
var scenes: Array=[]
func _init(depth):
	hub=depth; scenes=ContentDB._load_json("res://data/clique_scenes.json",[])
func start(group: String) -> void:
	var a: Dictionary=hub.state()["active"]
	var who: String=hub.club_work.peer("clique:"+group)
	a["clique_peer"]=FamilyChronicle.identity(GameState.npc(who))
	var scene := Novelty.pick(scenes.filter(func(s): return s["clique"]==group))
	if scene.is_empty():
		hub.state()["active"]={}
		GameState.change_closeness(who,1); GameState.change_stat("happiness",1)
		hub.school_record("clique:"+group,0.35)
		record(a,{},-1,"A quiet meetup kept the friendship going. Earlier decisions stay recorded.")
		EventEngine.push_info(str(Daily.CLIQUES[group][0]),"Time together","A quiet meetup with "+GameState.full_name(who)+". Friendship +1; happiness +1.")
		GameState.emit_changed(); return
	Novelty.note(scene); a["clique_scene"]=scene
	hub._push(str(Daily.CLIQUES[group][1])+" · "+str(scene["title"]),str(scene["text"])+"\nWith "+str(GameState.npc(who)["first"])+".",scene["choices"].map(func(choice): return hub._choice(choice,"clique_plan",scene["choices"].find(choice))),str(Daily.CLIQUES[group][0]))
func finish(answer: int) -> void:
	var a: Dictionary=hub.state()["active"]
	if a.get("kind","")!="school_activity" or a.get("mode","")!="clique" or not a.has("clique_scene") or answer not in [0,1,2]: return
	var scene: Dictionary=a["clique_scene"]
	hub.state()["active"]={}
	var trust := int(scene["trust"][answer]); var honest: bool=scene["honest"][answer]
	var who: String=Journey.person(str(a["clique_peer"]))
	var result := str(scene["ends"][answer])
	Daily._ss()["popularity"]=clampf(float(Daily._ss()["popularity"])+float(scene["popularity"][answer]),0,100)
	GameState.apply_effects({"happiness":2 if trust>=0 else -2,"karma":1 if honest else -2,"stress":scene["stress"][answer]})
	hub.school_record("clique:"+str(a["id"]),float(scene["quality"][answer])/100.0)
	if who!="" and GameState.npc(who).get("alive",false):
		BondStats.apply(who,{"trust":trust,"affection":2 if trust>0 else -2})
		FamilyChronicle.remember(who,str(scene["choices"][answer])+". "+result,"good" if honest else "bad")
		Journey.modules["pathways"].record("school",str(scene["id"]),str(scene["field"]),float(scene["quality"][answer]),honest,str(a["clique_peer"]))
	record(a,scene,answer,result)
	EventEngine.push_info(str(Daily.CLIQUES[str(a["id"])][0]),str(scene["title"]),result+"\nTrust %+.0f · popularity %+.0f" % [float(trust),float(scene["popularity"][answer])])
	GameState.emit_changed()
func record(a: Dictionary,scene: Dictionary,answer: int,result: String) -> void:
	var s: Dictionary=hub.state()
	if not s.has("clique_work"): s["clique_work"]=[]
	s["clique_work"].push_front({"year":GameState.year_now(),"clique":a["id"],"peer":a["clique_peer"],"task":scene.get("title","Quiet meetup"),"choice":scene["choices"][answer] if answer>=0 else "Spend time together","result":result})
	if s["clique_work"].size()>64: s["clique_work"].resize(64)
func records() -> Dictionary:
	var info: Array=["Group decisions and the classmates who remember them."]
	for entry in hub.state().get("clique_work",[]):
		info.append("%d · %s · %s" % [entry["year"],Daily.CLIQUES[str(entry["clique"])][1],entry["task"]])
		var who: String=Journey.person(str(entry["peer"]))
		if who!="": info.append("With "+GameState.full_name(who))
		info.append(str(entry["choice"])+" · "+str(entry["result"]))
	if hub.state().get("clique_work",[]).is_empty(): info.append("No group decisions yet.")
	return {"icon":"👥","title":"Clique memories","info":info,"rows":[]}
