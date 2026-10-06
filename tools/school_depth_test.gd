extends Node
var checks := 0
var failures: Array=[]
var clubs
var school
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func same(a: Variant,b: Variant) -> bool: return JSON.parse_string(JSON.stringify(a))==JSON.parse_string(JSON.stringify(b))
func fresh(age: int=13) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=age; GameState.player["money"]=10000; GameState.player["time_left"]=12
	GameState.player["education"]["stage"]="secondary" if age>=12 else "primary"
	GameState.settings["minigames"]=false; clear()
	clubs=Depth.club_work; school=Journey.modules["school"]
func plan(answer: int) -> Dictionary:
	var event := EventEngine.pop_next()
	var spec: Dictionary=event["def"]["choices"][answer]["outcomes"][0]["depth"].duplicate(true)
	EventEngine.resolve(event,answer); clear(); return spec
func project_answer(index: int) -> void:
	var event := EventEngine.pop_next(); EventEngine.resolve(event,index); clear()
func _ready() -> void:
	seed(8450); GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	clubs=Depth.club_work; school=Journey.modules["school"]
	fresh(); ok(Journey.person("")=="","Missing person identity resolves to an unassigned family member")
	var bank: Array=clubs.scenes.duplicate(true); var texts: Dictionary={}; var endings: Dictionary={}
	for scene in bank:
		texts[scene["text"]]=true
		ok(clubs.GAMES.has(scene["club"]) and scene["choices"].size()==3 and scene["ends"].size()==3,"Invalid club content")
		for end in scene["ends"]: endings[end]=true
		for answer in range(3):
			fresh(); clubs.scenes=[scene]; Daily._ss()["clubs"]=[scene["club"]]
			var time := int(GameState.player["time_left"]); Depth.school_activity("club",str(scene["club"]))
			ok(GameState.player["time_left"]==time-1 and Depth.state()["active"]["club_scene"]==scene,"Club plan missing or costs extra time")
			var peer: String=Journey.person(str(Depth.state()["active"]["club_peer"]))
			ok(peer!="" and GameState.npc(peer)["alive"],"Club has no actual classmate")
			var trust := BondStats.get_stat(peer,"trust")
			var snapshot: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
			GameState.from_dict(snapshot); clear()
			ok(Depth.state()["active"]["club_scene"]==scene and EventEngine.pending.is_empty(),"Saved scenario changed or fixture clearing failed")
			Depth.restore()
			var spec := plan(answer)
			var record: Dictionary=Depth.state()["club_work"][0]
			ok(record["choice"]==scene["choices"][answer] and record["result"]==scene["ends"][answer],"Choice has no matching lasting result")
			ok(is_equal_approx(float(record["score"]),clampf(float(record["raw_score"])+float(scene["bonus"][answer])/100.0,0,1)),"Club plan does not affect challenge result")
			ok(is_equal_approx(BondStats.get_stat(peer,"trust"),clampf(trust+float(scene["trust"][answer]),0,100)),"Club decision has no actual relationship consequence")
			ok(Journey.modules["pathways"].st()["cases"][0]["uid"]==FamilyChronicle.identity(GameState.npc(peer)) and Journey.modules["pathways"].st()["cases"][0]["honest"]==(int(scene["trust"][answer])>=0),"Club follow-up invents a contact or erases a harmful choice")
			var count: int=Depth.state()["club_work"].size(); var performance: Dictionary=Depth.state()["school_history"].duplicate(true)
			Depth.outcome(spec); Depth._school_activity_result(1.0,{}); clear()
			ok(Depth.state()["club_work"].size()==count and Depth.state()["school_history"]==performance,"Club replay grants another result")
			ok(school.menu("clubs")["info"].any(func(line): return str(line).contains(str(scene["title"]))),"Club work record is inaccessible")
	clubs.scenes=bank
	ok(texts.size()==44 and endings.size()>=84,"Club situations or outcomes repeat")
	for club in Daily.SCHOOL_CLUBS:
		var total: int=bank.filter(func(scene): return scene["club"]==club[0]).size()
		ok(total>=1,"Club lacks a distinct situation")
		fresh(); Daily._ss()["clubs"]=[club[0]]; var seen: Array=[]; var who := ""
		for year in range(3):
			Depth.school_activity("club",str(club[0]))
			if year<total:
				seen.append(Depth.state()["active"]["club_scene"]["id"])
				var peer_uid := str(Depth.state()["active"]["club_peer"])
				if year==0: who=peer_uid
				else: ok(peer_uid==who,"Club partner reset between years: "+str(club[0])+" "+who+" → "+peer_uid+" "+str(Depth.state()["club_partners"]))
				plan(0)
			else: ok(Depth.state()["active"].is_empty() and Depth.state()["club_work"][0]["task"]=="Practice round","Exhausted club pool repeats an authored event or blocks practice")
			clear(); var time := int(GameState.player["time_left"]); Depth.school_activity("club",str(club[0])); clear()
			ok(GameState.player["time_left"]==time,"Same-year club repeats charged time")
			GameState.player["age"]+=1; GameState.player["time_left"]=12
		ok(seen.size()==total and (total==1 or seen[0]!=seen[1]),"Club repeated the same situation next year")
	# Closing or pausing preserves actual work without giving it a completion award.
	for kind in school.PROJECTS:
		fresh(15); school.start(str(kind)); clear(); school.step(); project_answer(1)
		var p: Dictionary=JSON.parse_string(JSON.stringify(school.st()["project"]))
		var money := int(GameState.player["money"]); school.archive(true); clear()
		ok(school.st()["project"].is_empty() and same(school.st()["paused"][kind]["choices"],p["choices"]) and school.st()["completed"].is_empty(),"Pause erases choices or awards completion")
		GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
		var time := int(GameState.player["time_left"]); school.resume(str(kind)); clear()
		ok(GameState.player["time_left"]==time-1 and GameState.player["money"]==money and school.st()["project"]["stage"]==1 and school.st()["project"]["quality"]==p["quality"],"Resume resets work, refunds fees or lacks effort")
		time=int(GameState.player["time_left"]); school.step(); clear(); ok(GameState.player["time_left"]==time,"Resume bypasses same-year stage limit")
		school.archive(false); clear()
		ok(school.st()["left"][kind]["choices"]==p["choices"] and school.career_bonus(str(school.PROJECTS[kind][1]))==0,"Closed project loses record or awards career evidence")
		school.start(str(kind)); clear(); ok(school.st()["project"].is_empty(),"Closed project can reroll its start for a reward")
	fresh(9); var money := int(GameState.player["money"]); school.start("leadership"); clear()
	ok(school.st()["project"].is_empty() and GameState.player["money"]==money,"Teen council project starts in early childhood")
	# The project can conclude after a real collaborator's death; the change stays.
	fresh(15); school.start("science"); clear(); school.step(); project_answer(0)
	var old_peer := str(school.st()["project"]["peer"]); var old_mentor := str(school.st()["mentor"])
	ok(old_mentor!="" and GameState.npc(Journey.person(old_mentor))["relation"]=="teacher","School project has no actual teacher")
	GameState.npc(Journey.person(old_peer))["alive"]=false; GameState.npc(Journey.person(old_mentor))["alive"]=false
	for stage in range(2):
		GameState.player["age"]+=1; GameState.player["time_left"]=12; school.step(); project_answer(0)
	ok(school.st()["completed"].size()==1 and school.st()["completed"][0]["team_changes"].size()==2,"Lost collaborator leaves a dead end or its handover history disappears")
	ok(school.st()["completed"][0]["peer"]!=old_peer and school.st()["completed"][0]["mentor"]!=old_mentor,"Project retains dead people as active collaborators")
	# A paused final presentation can return in early adulthood, but not forever.
	fresh(17); school.start("arts"); clear(); school.step(); project_answer(0)
	GameState.player["age"]+=1; GameState.player["time_left"]=12; school.step(); project_answer(0); school.archive(true); clear()
	GameState.player["age"]=19; GameState.player["education"]["stage"]="graduated"; GameState.player["time_left"]=12
	school.resume("arts"); clear(); school.step(); project_answer(0)
	ok(school.st()["completed"].size()==1 and school.st()["completed"][0]["returns"].size()==1,"Paused final presentation cannot return after graduation")
	fresh(17); school.start("community"); clear(); school.archive(true); clear()
	GameState.player["age"]=21; GameState.player["education"]["stage"]="graduated"
	var time := int(GameState.player["time_left"]); school.resume("community"); clear()
	ok(school.st()["project"].is_empty() and GameState.player["time_left"]==time,"Expired unfinished project resumes outside its age/stage route")
	print("SCHOOL DEPTH checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
