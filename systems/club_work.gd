extends RefCounted
var hub
var scenes: Array=[]
var GAMES := {"chess":"evidence","drama":"audition","robotics":"docking","debate":"debate","art":"onset","band":"rhythm","council":"debate","yearbook":"onset","science":"evidence","volunteer":"debate"}
func _init(depth):
	hub=depth; scenes=ContentDB._load_json("res://data/club_scenes.json",[])
	for c in ContentDB._load_json("res://data/school_club_catalog.json",[]): GAMES[c["id"]]=c["game"]
func peer(club: String) -> String:
	var s: Dictionary=hub.state()
	if not s.has("club_partners"): s["club_partners"]={}
	var who: String=Journey.person(str(s["club_partners"].get(club,"")))
	if who!="" and GameState.npc(who).get("alive",false): return who
	var peers: Array=(GameState.npcs_with("classmate")+GameState.npcs_with("friend")).filter(func(id): return abs(int(GameState.npc(id)["age"])-int(GameState.player["age"]))<=2 and GameState.npc(id).get("species","human")=="human")
	who=str(peers.pick_random()) if not peers.is_empty() else GameState.create_npc("classmate",{"age":GameState.player["age"],"closeness":50})
	s["club_partners"][club]=FamilyChronicle.identity(GameState.npc(who))
	return who
func icon(club: String) -> String:
	for row in Daily.SCHOOL_CLUBS:
		if row[0]==club: return str(row[1])
	return "🏫"
func start(club: String) -> void:
	var a: Dictionary=hub.state()["active"]
	var who := peer(club); a["club_peer"]=FamilyChronicle.identity(GameState.npc(who))
	var scene := Novelty.pick(scenes.filter(func(s): return s["club"]==club))
	if scene.is_empty(): play(); return
	Novelty.note(scene); a["club_scene"]=scene
	hub._push(Daily._club_name(club)+" · "+str(scene["title"]),str(scene["text"])+"\nWorking with "+str(GameState.npc(who)["first"])+". Choose your plan before the challenge.",scene["choices"].map(func(choice): return hub._choice(choice,"club_plan",scene["choices"].find(choice))),icon(club))
func plan(answer: int) -> void:
	var a: Dictionary=hub.state()["active"]
	if a.get("kind","")!="school_activity" or a.get("mode","")!="club" or not a.has("club_scene") or answer not in [0,1,2]: return
	a["club_plan"]=answer; play()
func play() -> void:
	var a: Dictionary=hub.state()["active"]
	var club := str(a["id"])
	Minigames.play(GAMES[club],{"skill":Aptitude.score("education"),"title":Daily._club_name(club)+" challenge","cases":hub._practice_cases("Chess" if club=="chess" else "Science")},Callable(hub,"_school_activity_result"))
func finish(a: Dictionary, score: float) -> float:
	var scene: Dictionary=a.get("club_scene",{})
	var who: String=Journey.person(str(a.get("club_peer","")))
	var plan := int(a.get("club_plan",-1))
	var adjusted := clampf(score,0,1)
	var result := "Practice recorded; earlier club decisions stay in my history."
	if not scene.is_empty() and plan in [0,1,2]:
		adjusted=clampf(adjusted+float(scene["bonus"][plan])/100.0,0,1)
		result=str(scene["ends"][plan]); GameState.change_stat("stress",int(scene["stress"][plan]))
		if who!="" and GameState.npc(who).get("alive",false):
			BondStats.apply(who,{"trust":scene["trust"][plan],"respect":1 if adjusted>=0.7 else 0})
			FamilyChronicle.remember(who,Daily._club_name(str(a["id"]))+": "+str(scene["choices"][plan])+". "+result,"bad" if int(scene["trust"][plan])<0 else "good")
			Journey.modules["pathways"].record("school",str(scene["id"]),str(scene["field"]),adjusted*100.0,int(scene["trust"][plan])>=0,str(a["club_peer"]))
	var s: Dictionary=hub.state()
	if not s.has("club_work"): s["club_work"]=[]
	s["club_work"].push_front({"year":GameState.year_now(),"club":a["id"],"peer":a.get("club_peer",""),"task":scene.get("title","Practice round"),"choice":scene["choices"][plan] if not scene.is_empty() and plan in [0,1,2] else "Practice","result":result,"raw_score":score,"plan_bonus":scene["bonus"][plan] if not scene.is_empty() and plan in [0,1,2] else 0,"score":adjusted})
	if s["club_work"].size()>64: s["club_work"].resize(64)
	a["club_summary"]=result+(" Plan %+.0f points." % float(scene["bonus"][plan]) if not scene.is_empty() and plan in [0,1,2] else "")
	return adjusted
func records() -> Dictionary:
	var info: Array=["Club decisions, classmates and results. Participation still helps relevant adult paths."]
	for entry in hub.state().get("club_work",[]):
		var who: String=Journey.person(str(entry["peer"]))
		info.append("%d · %s · %s · %d%%" % [entry["year"],Daily._club_name(str(entry["club"])),entry["task"],int(float(entry["score"])*100)])
		if who!="": info.append("With "+GameState.full_name(who))
		info.append(str(entry["choice"])+" · "+str(entry["result"]))
	if hub.state().get("club_work",[]).is_empty(): info.append("No completed club work yet.")
	return {"icon":"📁","title":"Club work record","info":info,"rows":[]}
