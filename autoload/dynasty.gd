extends Node

## A change of viewpoint, not a death or an early inheritance.
func candidates() -> Array:
	if not GameState.is_alive() or Lives.separate(): return []
	return GameState.heirs().filter(func(id): return GameState.npcs[id].get("species", "human") == "human")

func switch_to(child_id: String) -> bool:
	if not candidates().has(child_id) or EventEngine.has_pending() or Journey.busy() or EventEngine.displayed.has("def") or not Depth.state()["active"].is_empty() or not Employment.st()["prompt"].is_empty(): return false
	FamilyChronicle.sync()
	var child: Dictionary = GameState.npcs[child_id].duplicate(true)
	var parent := GameState.player.duplicate(true)
	parent["estate_child_uids"]={}
	for id in GameState.npcs_with("child"): parent["estate_child_uids"][id]=FamilyChronicle.identity(GameState.npc(str(id)))
	var personal_story := {"flags":GameState.flags.duplicate(true),"followups":GameState.followups.duplicate(true),"events":GameState.event_history.duplicate(true),"log":GameState.log_years.duplicate(true),"milestones":GameState.milestones.duplicate(true)}
	var family := GameState.npcs.duplicate(true)
	var year := GameState.year_now()
	var next_id := GameState.next_npc_id
	var child_links: Array = []
	for link in parent.get("npc_links", []):
		if str(link.get("a", "")) == child_id or str(link.get("b", "")) == child_id:
			child_links.append(link.duplicate(true))
	GameState.new_life({"first":child["first"],"last":child["last"],"gender":child["gender"],
		"country":child.get("country", parent["country"]),"born_year":year-int(child["age"]),
		"generation":int(parent["generation"])+1,"keep_family":true,"keep_world":true,
		"life_path":"human","difficulty":parent.get("difficulty", "real"),
		"traits":[child.get("trait", "Loyal")],"money":int(child.get("money",0))})
	GameState.npcs = family
	GameState.npcs.erase(child_id)
	GameState.next_npc_id = next_id
	var p := GameState.player
	# Recorded NPC values override the scaffold; no inherited parent stats or money.
	if child.get("playable_player", {}) is Dictionary and not child.get("playable_player", {}).is_empty():
		p.merge(child["playable_player"].duplicate(true), true)
	p["age"] = int(child["age"])
	p["person_uid"] = child["person_uid"]
	for key in ["upbringing_style","upbringing","journey","possessions","properties","professional_skills","business","ambition","medical","care","debts","lending_year","finances_year","loan_serial","loan_record","credit","habits"]:
		if child.has(key): p[key]=child[key].duplicate(true) if child[key] is Dictionary or child[key] is Array else child[key]
	if child.has("estate_home"): Estate.restore_home(p,child["estate_home"])
	p["parent_uids"] = child.get("parent_uids",[]).duplicate()
	p["personal_history"] = child.get("personal_history",[]).duplicate(true)
	p["alive"] = true
	p["born_year"] = year-int(child["age"])
	p["first"] = child["first"]
	p["last"] = child["last"]
	p["money"] = int(child.get("money", 0))
	p["face"] = child.get("face", 0)
	p["region"] = child.get("region", parent.get("region", ""))
	p["legacy"] = {}
	for stat in ["health","happiness","smarts","looks","stress"]:
		p["stats"][stat] = float(child.get(stat, p["stats"][stat]))
	if child.has("avatar"): p["avatar"] = child["avatar"].duplicate(true)
	if child.has("education"):
		p["education"].merge(child["education"].duplicate(true), true)
	else:
		var age := int(p["age"])
		p["education"]["performance"] = float(child.get("school", child.get("smarts",50)))
		p["education"]["stage"] = "graduated" if age >= 18 else "secondary" if age >= 12 else "primary" if age >= 5 else "none"
		p["education"]["hs_graduated"] = age >= 18 and float(child.get("school",50)) >= 45
		# Old NPCs store a broad degree marker, not an invented major or licence.
		p["education"]["npc_degree_recorded"] = bool(child.get("degree",false))
	p["illness"] = str(child.get("illness",p.get("illness","")))
	p["record"] = child.get("record",p.get("record",[])).duplicate()
	p["prison"] = int(child.get("prison",p.get("prison",0)))
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		match str(n["relation"]):
			"child": n["relation"] = "sibling"
			"stepchild": n["relation"] = "stepsibling"
			"mother", "father": n["relation"] = "grandparent"
			"sibling", "stepsibling": n["relation"] = "auntuncle"
			"niece_nephew": n["relation"] = "cousin"
			"grandchild": n["relation"] = "child" if str(n.get("parent_id","")) == child_id else "niece_nephew"
			"partner": n["relation"] = ("father" if n["gender"]=="male" else "mother") if p["parent_uids"].has(n.get("person_uid","")) else "family_friend"
			"boss", "coworker": n["relation"] = "family_friend"
			"friend", "best_friend", "classmate", "neighbor", "rival", "enemy": n["relation"] = "family_friend"
	var parent_rel := "father" if parent["gender"] == "male" else "mother"
	var parent_id := GameState.create_npc(parent_rel,{"first":parent["first"],"last":parent["last"],"gender":parent["gender"],"age":parent["age"],"closeness":child.get("closeness",70),"money":parent["money"],"health":parent["stats"]["health"],"smarts":parent["stats"]["smarts"],"looks":parent["stats"]["looks"],"happiness":parent["stats"]["happiness"]})
	var parent_npc: Dictionary = GameState.npcs[parent_id]
	parent_npc["alive"] = true
	parent_npc["avatar"] = parent.get("avatar",{}).duplicate(true)
	parent_npc["playable_player"] = parent
	for key in ["debts","lending_year","finances_year","loan_serial","loan_record","credit"]:
		if parent.has(key): parent_npc[key]=parent[key].duplicate(true) if parent[key] is Dictionary or parent[key] is Array else parent[key]
	parent_npc["country"] = parent["country"]
	parent_npc["region"] = parent.get("region","")
	parent_npc["medical"] = parent.get("medical",{}).duplicate(true)
	parent_npc["care"] = parent.get("care",{}).duplicate(true)
	parent_npc["habits"] = parent.get("habits",{}).duplicate(true)
	parent_npc["journey"] = parent.get("journey",{}).duplicate(true)
	parent_npc["personal_story"] = personal_story
	parent_npc["personal_history"] = parent.get("personal_history",[]).duplicate(true)
	parent_npc["person_uid"] = parent["person_uid"]
	parent_npc["parent_uids"] = parent.get("parent_uids",[]).duplicate()
	parent_npc["education"] = parent["education"].duplicate(true)
	parent_npc["record"] = parent["record"].duplicate()
	parent_npc["illness"] = parent["illness"]
	parent_npc["prison"] = parent["prison"]
	parent_npc["finance_year"] = year
	parent_npc["job"] = parent["job"].duplicate(true)
	parent_npc["job"]["key"] = "employee" if not parent["job"].is_empty() else "none"
	for known_job in Web.JOBS:
		if str(FamilyChronicle.JOB_IDS.get(known_job[1],known_job[1])) == str(parent["job"].get("id","")):
			parent_npc["job"]["key"] = known_job[1]
			break
	parent_npc["job"]["title"] = parent["job"].get("title","Unemployed")
	for n in GameState.npcs.values():
		if str(n.get("parent_id","")) == child_id: n["parent_id"] = "player"
	p["partner"] = ""
	p["partner_status"] = ""
	if child.get("married",false) and str(child.get("spouse","")) != "":
		var spouse_name := str(child["spouse"])
		var spouse_id := ""
		for id in GameState.npcs.keys():
			if GameState.full_name(id) == spouse_name and GameState.npcs[id].get("alive",true): spouse_id = id; break
		if spouse_id == "":
			var parts := spouse_name.split(" ",false,1)
			spouse_id = GameState.create_npc("partner",{"first":parts[0],"last":parts[1] if parts.size()>1 else "","gender":child.get("spouse_gender","female"),"age":maxi(18,int(child.get("spouse_age",p["age"]))),"closeness":child.get("spouse_closeness",70)})
		GameState.npcs[spouse_id]["relation"] = "partner"
		p["partner"] = spouse_id
		p["partner_status"] = "married"
		p["living_together"] = true
	if child.has("job") and p["job"].is_empty() and int(p["age"])>=18:
		var occupation: Dictionary = child["job"]
		var key := str(occupation.get("key","none"))
		if key == "retired":
			p["retired"] = true
		elif not key in ["none","student"]:
			var job_id := str(occupation.get("id",""))
			for jd in ContentDB.jobs:
				if job_id != "": break
				for title in jd.get("ranks",[]):
					if str(title).to_lower().contains(str(occupation.get("title","")).to_lower()): job_id = str(jd["id"]); break
			if ContentDB.job(job_id).is_empty(): job_id = "family_role"
			var jd := ContentDB.job(job_id)
			p["job"]={"id":job_id,"title":occupation.get("title",jd["ranks"][0]),"field":jd.get("field","General"),"salary":int(occupation.get("salary",jd["salary"])),"rank":0,"perf":float(child.get("job_perf",55)),"years":int(child.get("job_years",0)),"years_in_rank":0,"boss":"","coworkers":[],"part_time":false,"worked_hard":false}
	p["npc_links"] = []
	if parent.get("life",{}).get("type","")=="royal" and child.get("playable_player",{}).is_empty():
		var royal: Dictionary = parent["life"]
		var children: Array = []
		for id in GameState.npcs:
			if str(GameState.npcs[id].get("parent_id",""))==parent_id: children.append(id)
		p["life"]={"type":"royal","house":royal.get("house","Royal house"),"respect":50,"line":int(child.get("line",1)),"crowned":false,"reign":0,"decrees":0,"consort":false,"realm":royal.get("realm","the realm"),"succession_rule":royal.get("succession_rule","eldest_child"),"noble":royal.get("noble",false),"noble_title":royal.get("noble_title","Noble")}
		p["birth_class"]="Nobility" if p["life"]["noble"] else "Royal family"
		parent_npc["royal"]=true
		parent_npc["monarch"]=royal.get("crowned",false)
		parent_npc["title"]="King" if parent["gender"]=="male" else "Queen"
		Lives._reline()
	for link in child_links:
		var other := str(link["b"] if str(link["a"])==child_id else link["a"])
		if GameState.npcs.has(other) and str(link.get("kind","")) in ["friends","close","rivals","fell_out"]:
			GameState.npcs[other]["relation"] = "rival" if str(link["kind"]) in ["rivals","fell_out"] else "friend"
	GameState.flags.clear()
	GameState.followups.clear()
	GameState.event_history.clear()
	GameState.job_listings.clear()
	GameState.interacted.clear()
	GameState.milestones.clear()
	GameState.log_years = [{"age":p["age"],"lines":[]}]
	var own_story: Dictionary = child.get("personal_story",{})
	if not own_story.is_empty():
		GameState.flags = own_story.get("flags",{}).duplicate(true)
		GameState.followups = own_story.get("followups",[]).duplicate(true)
		GameState.event_history = own_story.get("events",{}).duplicate(true)
		GameState.log_years = own_story.get("log",[]).duplicate(true)
		GameState.milestones = own_story.get("milestones",[]).duplicate(true)
		GameState.log_years.append({"age":p["age"],"lines":[]})
	Journey.modules["operations"].rebind()
	GameState.add_log("My story continues from the life I already had. %s is still alive; this is a change of viewpoint, not an inheritance." % parent["first"])
	GameState.add_milestone(p["age"],"became the viewpoint of the family story")
	FamilyChronicle.sync()
	GameState.emit_changed()
	return true
