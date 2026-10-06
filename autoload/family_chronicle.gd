extends Node

## Persistent identities and compact histories live in the shared world. Detailed
## playable snapshots remain on NPCs, avoiding recursive copies of the family.
const LIMIT := 32
const JOB_IDS := {"cop":"police", "programmer":"software", "realtor":"real_estate", "vet":"veterinarian"}

func book() -> Dictionary:
	if not GameState.world.get("family_book", {}) is Dictionary or GameState.world.get("family_book", {}).is_empty():
		GameState.world["family_book"] = {"next":1,"people":{}}
	return GameState.world["family_book"]

func identity(person: Dictionary) -> String:
	if str(person.get("person_uid","")) == "":
		var root := book()
		person["person_uid"] = "person_%d" % int(root["next"])
		root["next"] = int(root["next"])+1
	return str(person["person_uid"])

func parents(person: Dictionary, uids: Array) -> void:
	if not person.has("parent_uids"): person["parent_uids"] = []
	for uid in uids:
		if uid != "" and uid != identity(person) and not person["parent_uids"].has(uid): person["parent_uids"].append(uid)

func ensure_npc(id: String) -> void:
	if not GameState.npcs.has(id): return
	var n: Dictionary = GameState.npcs[id]
	if n.get("species","human") != "human": return
	identity(n)
	Avatar.appearance(n)
	if not n.has("education"):
		n["education"] = GameState._blank_education()
		n["education"]["stage"] = "graduated" if int(n["age"])>=18 else "secondary" if int(n["age"])>=12 else "primary" if int(n["age"])>=5 else "none"
		n["education"]["performance"] = float(n.get("school",n.get("smarts",50)))
		n["education"]["hs_graduated"] = int(n["age"])>=18 and float(n.get("school",50))>=45
		n["education"]["npc_degree_recorded"] = bool(n.get("degree",false))
		n["education"]["source"] = "legacy scaffold"
	if not n.has("record"): n["record"] = []
	if not n.has("prison"): n["prison"] = 0
	if not n.has("illness"): n["illness"] = ""
	if not n.has("personal_history"): n["personal_history"] = []
	# Preserve known occupations. Only missing job details are estimated.
	if n.has("job") and n["job"] is Dictionary:
		var job: Dictionary = n["job"]
		if not job.has("salary"):
			var match_id := str(job.get("id",JOB_IDS.get(job.get("key",""),job.get("key",""))))
			var jd := ContentDB.job(match_id)
			if jd.is_empty():
				for candidate in ContentDB.jobs:
					if Array(candidate.get("ranks",[])).has(str(job.get("title",""))): jd = candidate; break
			job["salary"] = int(jd.get("salary",35000)) if not str(job.get("key","none")) in ["none","student","retired"] else 0
			job["salary_source"] = "estimated"
			if not jd.is_empty(): job["id"] = jd["id"]

func sync() -> void:
	if not GameState.has_life() or Lives.separate(): return
	var p := GameState.player
	var me := identity(p)
	var parent_ids := GameState.npcs_with("mother",false)+GameState.npcs_with("father",false)
	var parent_uids: Array = []
	for id in GameState.npcs.keys(): ensure_npc(id)
	for id in parent_ids: parent_uids.append(identity(GameState.npcs[id]))
	if not p.has("parent_uids"): parents(p,parent_uids)
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if n.get("species","human") != "human": continue
		if not n.has("parent_uids"):
			match str(n["relation"]):
				"child": parents(n,[me])
				"sibling": parents(n,parent_uids)
				"grandchild", "niece_nephew":
					if GameState.npcs.has(str(n.get("parent_id",""))): parents(n,[identity(GameState.npcs[n["parent_id"]])])
		_update_record(n, id)
	_update_record(p,"player")

func _update_record(person: Dictionary, id: String) -> void:
	var uid := identity(person)
	var records: Dictionary = book()["people"]
	var old: Dictionary = records.get(uid,{})
	var work: Dictionary = person.get("job",{})
	var new := {"uid":uid,"id":id,"name":"%s %s" % [person.get("first",""),person.get("last","")],"age":int(person.get("age",0)),"alive":bool(person.get("alive",true)),"parents":person.get("parent_uids",[]).duplicate(),"gender":person.get("gender","nonbinary"),"money":int(person.get("money",0)),"job":work.get("title","Unemployed" if id=="player" else "No occupation recorded"),"salary":int(work.get("salary",0)),"salary_source":work.get("salary_source","recorded" if id=="player" or not work.is_empty() else "unrecorded"),"education":person.get("education",{}).duplicate(true),"record":person.get("record",[]).duplicate(),"illness":person.get("illness",""),"relation":person.get("relation","You"),"year":GameState.year_now(),"history":old.get("history",[]),"generation":person.get("generation",old.get("generation",0))}
	if not old.is_empty():
		for key in ["job","alive","illness"]:
			if old.get(key) != new.get(key): new["history"].append({"year":new["year"],"text":"%s: %s" % [key.capitalize(),str(new[key])]})
	new["history"] = Array(new["history"]).slice(-LIMIT)
	records[uid] = new

func remember(id: String, text: String, tone: String = "neutral") -> void:
	if not GameState.npcs.has(id): return
	ensure_npc(id)
	var n: Dictionary = GameState.npcs[id]
	if n.get("species","human") != "human": return
	n["personal_history"].append({"year":GameState.year_now(),"text":text,"tone":tone})
	n["personal_history"] = Array(n["personal_history"]).slice(-LIMIT)
	_update_record(n,id)
	var r: Dictionary = book()["people"][identity(n)]
	r["history"].append({"year":GameState.year_now(),"text":text})
	r["history"] = Array(r["history"]).slice(-LIMIT)

func yearly() -> void:
	if Lives.separate(): return
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if n.get("species","human") != "human": continue
		ensure_npc(id)
		if n["education"].get("source","")=="legacy scaffold" and n["alive"]:
			n["education"]["stage"] = "graduated" if int(n["age"])>=18 else "secondary" if int(n["age"])>=12 else "primary" if int(n["age"])>=5 else "none"
			n["education"]["performance"] = float(n.get("school",n.get("smarts",50)))
			n["education"]["hs_graduated"] = int(n["age"])>=18 and float(n.get("school",50))>=45
			n["education"]["npc_degree_recorded"] = bool(n.get("degree",false))
		if n.has("playable_player"):
			var former: Dictionary = n["playable_player"]
			former["age"]=n["age"]
			if n["alive"] and int(n.get("finance_year",-1)) != GameState.year_now():
				# One transparent yearly ledger for dormant former players; ordinary
				# NPC money continues to be managed by the existing family simulation.
				var retired: bool = int(n["age"])>=67 or former.get("retired",false) or n.get("job",{}).get("key","")=="retired"
				var salary := int(former.get("pension",0)) if retired else int(former.get("job",{}).get("salary",0))
				var mortgage := mini(int(former.get("mortgage",0)),int(former.get("mortgage_payment",0)))
				former["mortgage"] = maxi(0,int(former.get("mortgage",0))-mortgage)
				if int(former["mortgage"])==0: former["mortgage_payment"] = 0
				var costs := int(GameState.HOUSING.get(former.get("housing","parents"),{}).get("rent",0)) + mortgage
				var living := 12000
				n["money"] = int(n.get("money",0)) + int(salary*0.75)-costs-living
				former["money"] = n["money"]
				Ventures.operate(former,GameState.year_now(),false)
				var loan_payments := Lending.service(former,GameState.year_now())
				n["money"] = int(former["money"])
				n["finance_year"] = GameState.year_now()
				former["finances_year"]=GameState.year_now()
				n["last_budget"] = {"income":salary,"tax":int(salary*0.25),"housing":costs,"living":living,"loans":loan_payments,"year":GameState.year_now()}
				for key in ["debts","lending_year","finances_year","loan_serial","loan_record","credit"]:
					if former.has(key): n[key]=former[key].duplicate(true) if former[key] is Dictionary or former[key] is Array else former[key]
			former["age"] = n["age"]
			former["money"] = n["money"]
			former["alive"] = n["alive"]
			for stat in ["health","happiness","smarts","looks"]: former["stats"][stat] = float(n[stat])
			former["illness"] = n.get("illness",former.get("illness",""))
			former["record"] = n["record"].duplicate()
			former["prison"] = int(n.get("prison",0))
	sync()

func outcome(spec: Dictionary, roles: Dictionary) -> void:
	var role := str(spec.get("role","person"))
	if roles.has(role): remember(str(roles[role]),EventEngine.tokens(str(spec.get("memory","A moment we remember.")),roles),str(spec.get("tone","neutral")))

func before_year() -> void:
	var p := GameState.player
	p["year_start"] = {"money":int(p["money"]),"health":GameState.stat("health"),"happiness":GameState.stat("happiness"),"occupation":GameState.occupation_label(),"age":int(p["age"])}

func summary() -> Array:
	var p := GameState.player
	var start: Dictionary = p.get("year_start",{})
	var lines: Array = ["%s · %d · %s" % [LifeCourse.age_label(),GameState.year_now(),GameState.occupation_label()]]
	if not start.is_empty():
		lines.append("Cash change: %s · Health %+.0f · Happiness %+.0f" % [GameState.fmt_money(int(p["money"])-int(start["money"])),GameState.stat("health")-float(start["health"]),GameState.stat("happiness")-float(start["happiness"])])
	lines.append("%d living children · %d scheduled consequences" % [GameState.heirs().size(),Insight.upcoming().size()])
	if not GameState.log_years.is_empty():
		var year: Dictionary = GameState.log_years[-1]
		for text in Array(year.get("lines",[])).slice(-8): lines.append(str(text))
	return lines
