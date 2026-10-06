extends RefCounted
var h
const PROJECTS := {"library":["Local library","Education",0],"clinic":["Community care network","Care",80],"transit":["Accessible transport group","Logistics",40]}
const ADAPT := {"children":["Child-friendly home",600],"accessible":["Accessible home",2200],"workspace":["Home workspace",1200]}
func _init(hub): h=hub
func st() -> Dictionary: return h.section("places",{"project":{},"history":[],"moving":{},"migration":{},"language":0,"adaptations":[],"home":"","ties":{},"last_region":"","language_year":-1,"languages":{},"language_home":""})
func key() -> String: return str(GameState.player["country"])+":"+str(GameState.player.get("region",""))
func institution() -> Dictionary:
	if not GameState.world.has("community_institutions"): GameState.world["community_institutions"]={}
	var b: Dictionary=GameState.world["community_institutions"]
	if not b.has(key()): b[key()]={"quality":35.0,"projects":[],"library":0,"clinic":0,"transit":0,"trust":50.0}
	return b[key()]
func contribution(amount: int) -> void: institution()["trust"]=clampf(float(institution()["trust"])+amount,0,100)
func hiring_bonus(field: String) -> float:
	var bonus := 0.0
	for id in PROJECTS:
		if PROJECTS[id][1]==field: bonus+=mini(3,int(institution()[id]))*0.01
	return minf(0.03,bonus)*clampf(float(institution()["quality"])/50.0,0.2,1.0)
func start(kind: String) -> void:
	if not PROJECTS.has(kind) or not st()["project"].is_empty() or not h.pay("community_start",1,Actions._cost(int(PROJECTS[kind][2])),6): return
	st()["project"]={"kind":kind,"place":key(),"stage":0,"last":GameState.year_now()-1,"quality":35.0,"started":GameState.year_now()}
	h.done("🏘️","Joined a community project",PROJECTS[kind][0]+" · listen, organise and follow through across years. Being useful can matter more than a prize.")
func step() -> void:
	var p: Dictionary=st()["project"]
	if p.is_empty() or p["place"]!=key() or int(p["last"])==GameState.year_now() or not h.pay("community_step",1,0,6): return
	var stage := int(p["stage"])
	var prompts := ["People with different access needs want different things from this project.","The volunteer rota is full of names but short of confirmed availability.","The opening went well. Who will keep it working when the first volunteers leave?"]
	var options := [["Ask residents and publish the priorities","Choose only what suits me","Make promises without a budget"],["Confirm realistic shifts and shared duties","Assign people without asking","Do everything alone"],["Train replacements and review access","Count the opening as permanent success","Use the funds for publicity"]]
	h.decision("places","project",{"stage":stage},PROJECTS[p["kind"]][0],prompts[stage],options[stage])
func resolve(op: String, args: Dictionary, answer: int) -> void:
	if op!="project": return
	var p: Dictionary=st()["project"]
	if p.is_empty() or p["place"]!=key() or int(p["stage"])!=int(args["stage"]): return
	p["quality"]=clampf(float(p["quality"])+[18,-3,3][answer]+Aptitude.score("work")/40.0,0,100); p["last"]=GameState.year_now(); p["stage"]=int(p["stage"])+1
	if int(p["stage"])<3: h.done("🏘️","Community progress","Quality %d/100. The next stage opens next year." % p["quality"]); return
	var kind := str(p["kind"]); var good := float(p["quality"])>=65
	if good:
		institution()[kind]=int(institution()[kind])+1; institution()["quality"]=minf(100,float(institution()["quality"])+5); contribution(4)
		var age := int(GameState.player["age"])
		var id := GameState.create_npc("friend",{"age":maxi(6,age+randi_range(-4,4)),"closeness":50})
		FamilyChronicle.remember(id,"Met through "+str(PROJECTS[kind][0]),"good")
	institution()["projects"].append({"name":PROJECTS[kind][0],"owner":h.uid(),"year":GameState.year_now(),"quality":p["quality"]})
	if institution()["projects"].size()>30: institution()["projects"].pop_front()
	st()["history"].push_front(p.duplicate(true)); st()["project"]={}
	if st()["history"].size()>20: st()["history"].resize(20)
	h.done("🏘️","A lasting local contribution","Quality %d/100. %s" % [p["quality"],"The institution, local opportunity and a new friendship reflect the work." if good else "The effort is recorded, but the institution still needs support."],{"happiness":4})
func prepare_move(rid: String) -> void:
	if not Places.regions(str(GameState.player["country"])).any(func(r): return r["id"]==rid) or rid==str(GameState.player.get("region","")): return
	if not h.pay("move_plan",1,Actions._cost(250),18): return
	st()["moving"]={"dest":rid,"year":GameState.year_now(),"prepared":true}
	h.done("🚚","Move prepared","I checked work and contact arrangements. Job-loss risk on this move falls from 60% to 35%; moving still costs money and may end the job.")
func prepared(rid: String) -> bool: return st()["moving"].get("dest","")==rid and int(st()["moving"].get("year",-99))>=GameState.year_now()-1
func adapt(kind: String) -> void:
	if not ADAPT.has(kind) or GameState.player["housing"]!="house": return
	var home := str(GameState.player.get("house_uid",""))
	if home=="": home=h.uid()+":"+str(GameState.year_now()); GameState.player["house_uid"]=home
	if st()["home"]!=home: st()["home"]=home; st()["adaptations"]=[]
	if st()["adaptations"].has(kind) or not h.pay("adapt:"+kind,2,Actions._cost(int(ADAPT[kind][1])),18): return
	st()["adaptations"].append(kind)
	h.done("🏠","Home adapted",str(ADAPT[kind][0])+". It belongs to this home, not every future house.")
func prepare_migration(country: String) -> void:
	if country==str(GameState.player["country"]) or not ContentDB.countries.any(func(c): return c["id"]==country): return
	if not h.pay("migration_plan",2,Actions._cost(300),18): return
	st()["migration"]={"country":country,"year":GameState.year_now(),"arrived":false,"reviewed":false}
	h.done("🌍","Migration prepared","Work, housing and document checks add 5% to this game's application chance for two years. Approval is still uncertain; local licences still need review.")
func migration_bonus(country: String) -> float:
	var m: Dictionary=st()["migration"]
	return 0.05 if m.get("country","")==country and int(m.get("year",-99))>=GameState.year_now()-2 and not m.get("arrived",false) else 0.0
func arrived(country: String) -> void:
	var prepared0: bool=migration_bonus(country)>0
	st()["migration"]={"country":country,"year":GameState.year_now(),"arrived":true,"reviewed":false,"prepared":prepared0}
func review_credentials() -> void:
	var m: Dictionary=st()["migration"]
	if not m.get("arrived",false) or m.get("reviewed",false) or not h.pay("credential_review",1,Actions._cost(150),18): return
	m["reviewed"]=true
	var recognized := 0
	var country := str(GameState.player["country"])
	if country in ["us","ca"]:
		for diploma in GameState.player["education"]["degrees"]:
			if diploma.get("level","")!="associate" or diploma.get("country","") not in ["us","ca"]: continue
			if not diploma.has("recognized_countries"): diploma["recognized_countries"]=[]
			if not diploma["recognized_countries"].has(country): diploma["recognized_countries"].append(country); recognized+=1
	h.done("📋","Credentials reviewed","Education records retained."+(" %d associate diploma(s) now recognized for local bachelor credit." % recognized if recognized>0 else " No new degree credit granted.")+" Missing local licences need a separate test in Legal → Licences.",{"stress":-2})
func language_level() -> int:
	var s := st(); var country := str(GameState.player["country"])
	if str(s["language_home"])=="": s["language_home"]=country; s["languages"][country]=int(s["language"])
	s["language"]=int(s["languages"].get(country,0))
	return int(s["language"])
func maintain(kind: String) -> void:
	if not PROJECTS.has(kind) or int(institution()[kind])<=0 or not h.pay("community_maintenance",1,Actions._cost(30),12): return
	institution()["maintained"]=GameState.year_now()
	institution()["quality"]=minf(100,float(institution()["quality"])+2); contribution(1)
	h.done("🏘️","The work continues",PROJECTS[kind][0]+" has a reviewed rota and upkeep. Quality +2; local services are preserved this year.")
func review_institution(year: int) -> void:
	var i := institution()
	if not i.has("review_year"): i["review_year"]=year; return
	if int(i["review_year"])>=year: return
	var elapsed := mini(10,year-int(i["review_year"]))
	i["review_year"]=year
	if int(i.get("maintained",-99))<year-1: i["quality"]=maxf(10,float(i["quality"])-elapsed)
func language() -> void:
	if not h.pay("language",1,Actions._cost(40),12): return
	language_level()
	st()["language_year"]=GameState.year_now()
	st()["language_country"]=GameState.player["country"]
	st()["language"]=mini(10,int(st()["language"])+1); st()["languages"][str(GameState.player["country"])]=int(st()["language"]); GameState.change_stat("smarts",0.5)
	h.done("🗣️","Language practice","Community language skill %d/10. Practice helps belonging after a move; it is not an immigration permit." % st()["language"])
func yearly() -> void:
	if Lives.separate(): return
	language_level(); review_institution(GameState.year_now())
	if st()["last_region"]!=key():
		if st()["last_region"]!="": h.note("A new place","Old relationships remain; community work stays with its actual location.")
		st()["last_region"]=key()
	if GameState.player["housing"]=="house" and st()["home"]==str(GameState.player.get("house_uid","")):
		if st()["adaptations"].has("accessible"): GameState.apply_effects({"stress":-2,"happiness":1})
		if st()["adaptations"].has("children") and not GameState.npcs_with("child").is_empty(): GameState.change_stat("stress",-1)
		if st()["adaptations"].has("workspace") and GameState.has_job(): GameState.change_stat("job_perf",1)
	if language_level()>=3 and st().get("language_country",GameState.player["country"])==GameState.player["country"] and int(st().get("language_year",-99))==GameState.year_now()-1: contribution(1)
func menu(page: String) -> Dictionary:
	language_level()
	var info: Array=Places.summary(); var rows: Array=[]
	if page=="migration":
		info=["Compare the destination before applying. Preparation costs time and money; approval is uncertain and local licences still matter.","Language skill %d/10" % st()["language"]]
		rows.append(h.row("places","Apply to emigrate","Existing fees and approval risk","emigrate",null,int(GameState.player["age"])>=18))
		rows.append(h.row("places","Review local credentials","1 time · local licences must still be renewed","credentials",null,st()["migration"].get("arrived",false) and not st()["migration"].get("reviewed",false)))
		for c in ContentDB.countries:
			if c["id"]!=GameState.player["country"]: rows.append(h.row("places","Prepare: "+str(c["name"]),"2 time · "+GameState.fmt_money(Actions._cost(300))+" · no guarantee","migration",c["id"],int(GameState.player["age"])>=18))
	elif page.begins_with("region:"):
		var rid := page.substr(7)
		for r in Places.regions(str(GameState.player["country"])):
			if r["id"]!=rid: continue
			info=[str(r.get("city",r.get("name",rid))),str(r.get("blurb","")),"Living costs ×%.2f · pay ×%.2f · job loss risk %d%%" % [r.get("cost",1.0),r.get("pay",1.0),35 if prepared(rid) else 60]]
			rows=[h.row("places","Prepare the move","1 time · "+GameState.fmt_money(Actions._cost(250)),"prepare",rid),h.row("places","Move here","1 time · "+GameState.fmt_money(Actions._cost(3000))+" · leaving an owned home sells it","move",rid,rid!=str(GameState.player.get("region","")))]
	else:
		for kind in PROJECTS:
			if int(institution()[kind])>0: rows.append(h.row("places","Maintain "+str(PROJECTS[kind][0]).to_lower(),"1 time · "+GameState.fmt_money(Actions._cost(30))+" · once per year","maintain",kind,not h.used("community_maintenance")))
		info.append("Language in this country %d/10 · skills in earlier countries stay saved." % language_level())
		info.append("Local institution quality %d · trust %d" % [institution()["quality"],institution()["trust"]])
		if st()["project"].is_empty():
			for kind in PROJECTS: rows.append(h.row("places",PROJECTS[kind][0],"Three annual stages · start "+GameState.fmt_money(Actions._cost(int(PROJECTS[kind][2]))),"start",kind))
		else:
			var p: Dictionary=st()["project"]
			info.append("Project: %s · stage %d/3 · place %s" % [PROJECTS[p["kind"]][0],int(p["stage"])+1,p["place"]])
			rows.append(h.row("places","Continue community work","1 time · next stage next year","step",null,p["place"]==key() and int(p["last"])!=GameState.year_now()))
			rows.append(h.row("places","Leave this local project","It remains in the journal; no completion benefit","cancel"))
		rows.append(h.nav("places","Moving abroad","Preparation, applications and local credentials","migration"))
		rows.append(h.row("places","Community language practice","1 time · "+GameState.fmt_money(Actions._cost(40)),"language"))
		for kind in ADAPT: rows.append(h.row("places",ADAPT[kind][0],"Owned home · 2 time · "+GameState.fmt_money(Actions._cost(int(ADAPT[kind][1]))),"adapt",kind,GameState.player["housing"]=="house"))
		for r in Places.regions(str(GameState.player["country"])): rows.append(h.nav("places",str(r.get("city",r.get("name",r["id"]))),"Compare costs, work and preparation","region:"+str(r["id"])))
	return {"icon":"🏘️","title":"Places & community","info":info,"rows":rows}
func act(key0: String, arg: Variant) -> void:
	match key0:
		"start": start(str(arg))
		"step": step()
		"prepare": prepare_move(str(arg))
		"move": if h.blocked(18)=="": Places.relocate(str(arg))
		"adapt": adapt(str(arg))
		"language": language()
		"maintain": maintain(str(arg))
		"migration": prepare_migration(str(arg))
		"credentials": review_credentials()
		"emigrate": if h.blocked(18)=="": Actions._emigrate()
		"cancel": if h.blocked(6)=="": h.note("Community work ended","I left this local project; the community can continue without claiming my work was complete."); st()["project"]={}
