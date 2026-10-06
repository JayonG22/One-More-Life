extends Node

const GENRES := ["Lo-fi", "Pop", "Electronic", "Soul", "Rock", "Hip-hop"]
const TITLES := ["The Rent Is Too High", "Unread at Midnight", "Velvet Problems", "Bus Stop Symphony", "Terms and Conditions", "One More Chorus"]

func state() -> Dictionary:
	var p := GameState.player
	if not p.get("creator",{}) is Dictionary or not p.has("creator"):
		p["creator"]={}
	var s: Dictionary = p["creator"]
	for pair in [["skill",15.0],["catalog",[]],["project",{}],["listeners",0],["year",GameState.year_now()],["report",{}],["fanclub",{}]]:
		if not s.has(pair[0]): s[pair[0]]=pair[1]
	return s

func allowed() -> bool:
	return GameState.is_alive() and int(GameState.player["age"])>=18 and not Lives.separate() and not GameState.in_prison()

func _row(name: String, sub: String, act_key: String, arg = null, on: bool = true) -> Dictionary:
	return {"icon":"•","name":name,"sub":sub,"act":"creator:"+act_key,"arg":arg,"on":on}

func _pay(cost: int, time: int = 1) -> bool:
	if not allowed(): return false
	if int(GameState.player["money"])<cost:
		EventEngine.push_info("💵","Not enough cash","This needs %s available." % GameState.fmt_money(cost))
		return false
	if not GameState.spend_time(time):
		EventEngine.push_info("⏳","No time left","Make room for this next year.")
		return false
	GameState.player["money"]=int(GameState.player["money"])-cost
	return true

func menu(key: String) -> Dictionary:
	var s := state()
	var rows: Array = []
	if key=="fans": return _fans_menu()
	if key=="catalog":
		for track in s["catalog"]:
			rows.append({"icon":"💿","name":track["title"],"sub":"%s · quality %d · released %d · %s" % [track["genre"],int(track["quality"]),int(track["year"]),"licensed" if track["licensed"] else "on CloudCrowd"],"on":false})
		return {"icon":"💿","title":"My production catalog","rows":rows,"info":["Your most recent 40 releases. A license sale ends that track's independent royalty income."]}
	var project: Dictionary = s["project"]
	if project.is_empty():
		for genre in GENRES: rows.append(_row("Produce a "+genre+" track","%s studio cost · 2 time" % GameState.fmt_money(500),"start",genre,allowed()))
	else:
		rows.append(_row("Mix "+str(project["title"]),"Interactive studio session · 1 time · once per project","mix",null,allowed() and not project["mixed"]))
		rows.append(_row("Invite a collaborator","%s · 1 time · once per project · quality +8" % GameState.fmt_money(300),"collab",null,allowed() and project["collaborator"]==""))
		rows.append(_row("Release on CloudCrowd","Free upload · listeners and ongoing royalties","release",null,allowed() and project["mixed"]))
		rows.append(_row("Shelve this project","The studio cost stays spent","shelve",null,allowed()))
	rows.append(_row("Practice production","1 time · skill +4 · once per year","practice",null,allowed() and int(s.get("practice_year",-1))!=GameState.year_now()))
	rows.append({"icon":"🎼","name":"Arrangement challenge","sub":"Short rhythm practice · scoring and feedback","menu":"journey:skills:creative"})
	rows.append(_row("Offer latest track to a label","License offer depends on quality · royalties end if sold","license",null,allowed() and not s["catalog"].is_empty() and not s["catalog"][-1]["licensed"]))
	rows.append({"icon":"💿","name":"Release catalog","sub":"Tracks, genres, quality and licensing","menu":"creator:catalog"})
	rows.append({"icon":"🔒","name":"OnlyPals","sub":"Adult subscription creator business","menu":"creator:fans"})
	var info: Array = ["Production skill %d · CloudCrowd listeners %d" % [int(s["skill"]),int(s["listeners"])],"A project needs mixing before release. Each track can be sold once; you keep a release history."]
	if not s["report"].is_empty(): info.append("Last year royalties: "+GameState.fmt_money(int(s["report"]["royalties"])))
	return {"icon":"🎛️","title":"Producer studio & CloudCrowd","rows":rows,"info":info}

func act(key: String, arg = null) -> void:
	if not allowed(): return
	var s := state()
	var project: Dictionary = s["project"]
	if key.begins_with("fan_"): _fans_act(key,arg); return
	match key:
		"start":
			if not project.is_empty() or not GENRES.has(str(arg)) or not _pay(500,2): return
			s["project"]={"title":TITLES[randi()%TITLES.size()]+" #"+str(int(s.get("projects",0))+1),"genre":arg,"mixed":false,"mixing":false,"collaborator":"","quality":float(s["skill"])}
			s["projects"]=int(s.get("projects",0))+1
		"practice":
			if int(s.get("practice_year",-1))==GameState.year_now() or not _pay(0): return
			s["practice_year"]=GameState.year_now()
			s["skill"]=minf(100,float(s["skill"])+4)
		"mix":
			if project.is_empty() or project["mixed"] or project["mixing"] or not _pay(0): return
			project["mixing"]=true
			Minigames.play("rhythm",{"skill":float(s["skill"]),"difficulty":0.9},Callable(self,"_mix_done").bind(int(s["projects"])))
		"collab":
			if project.is_empty() or project["collaborator"]!="" or not _pay(300): return
			var id := GameState.first_of("friend")
			if id=="": id=GameState.create_npc("friend",{"age":randi_range(18,45),"closeness":55})
			project["collaborator"]=GameState.full_name(id)
			project["quality"]=minf(100,float(project["quality"])+8)
			FamilyChronicle.remember(id,"We collaborated on "+str(project["title"])+".")
		"release":
			if project.is_empty() or not project["mixed"] or project["mixing"]: return
			var track := project.duplicate(true)
			track["year"]=GameState.year_now()
			track["licensed"]=false
			s["catalog"].append(track)
			s["catalog"]=Array(s["catalog"]).slice(-40)
			s["listeners"]=mini(1000000,int(s["listeners"])+int(float(track["quality"])*randf_range(8,18)))
			s["skill"]=minf(100,float(s["skill"])+2)
			s["project"]={}
			GameState.add_log("I released %s on CloudCrowd. My work has a life outside the studio now." % track["title"])
		"license":
			if s["catalog"].is_empty() or s["catalog"][-1]["licensed"]: return
			var track: Dictionary = s["catalog"][-1]
			var offer := int(float(track["quality"])*60+int(s["listeners"])*0.05)
			EventEngine.push_decision({"id":"_license_track","icon":"💿","title":"License "+str(track["title"])+"?","text":"Receive %s once. This track stops earning independent royalties." % GameState.fmt_money(offer),"choices":[{"label":"Keep the rights","outcomes":[{"text":"I kept the track independent."}]},{"label":"Sell this license","outcomes":[{"text":"The label licensed my track.","creator_license":{"title":track["title"],"offer":offer}}]}]})
		"shelve":
			if project.is_empty() or project["mixing"]: return
			s["project"]={}
		_: return
	GameState.emit_changed()

func _mix_done(score: float, _detail: Dictionary, project_id: int) -> void:
	var s := state()
	var project: Dictionary = s["project"]
	if project.is_empty() or int(s["projects"])!=project_id or not project["mixing"]: return
	project["mixed"]=true
	project["mixing"]=false
	project["quality"]=clampf(float(project["quality"])*0.5+clampf(score,0,1)*50+float(s["skill"])*0.2,1,100)
	GameState.add_log("The mix of %s came out at quality %d." % [project["title"],int(project["quality"])])
	GameState.emit_changed()

func license_track(spec: Dictionary) -> void:
	if not allowed(): return
	for track in state()["catalog"]:
		if track["title"]!=spec.get("title","") or track["licensed"]: continue
		track["licensed"]=true
		GameState.player["money"]=int(GameState.player["money"])+int(spec["offer"])
		return

func _fans_menu() -> Dictionary:
	var club: Dictionary = state()["fanclub"]
	var rows: Array = []
	if club.is_empty(): rows.append(_row("Open OnlyPals","Adults only · %s setup · non-graphic creator stories" % GameState.fmt_money(200),"fan_open",null,allowed()))
	else:
		for fee in [5,10,20]: rows.append(_row("Monthly subscription: "+GameState.fmt_money(fee),"High prices reduce new subscriptions","fan_fee",fee,allowed() and int(club["fee"])!=fee))
		for style in ["Art & essays","Fashion & glamour","Adults-only discussions"]: rows.append(_row("Publish: "+style,"1 time · maximum 3 releases per year · non-graphic","fan_post",style,allowed() and int(club["posts"])<3))
		rows.append(_row("Privacy: "+("strict" if club["private"] else "public"),"Strict privacy reaches a smaller audience and slows subscriber growth","fan_privacy",null,allowed()))
		rows.append(_row("Close the channel","Subscribers leave and billing stops","fan_close",null,allowed()))
	return {"icon":"🔒","title":"OnlyPals","rows":rows,"info":["Consenting adults, boundaries and creative work. No explicit images or sexual scenes.","Subscribers %d · releases this year %d · last net income %s" % [int(club.get("subscribers",0)),int(club.get("posts",0)),GameState.fmt_money(int(club.get("net",0)))]]}

func _fans_act(key: String, arg) -> void:
	var s := state()
	var club: Dictionary = s["fanclub"]
	if key=="fan_open":
		if not club.is_empty() or not _pay(200): return
		s["fanclub"]={"fee":10,"subscribers":0,"posts":0,"private":true,"net":0}
	elif not club.is_empty():
		match key:
			"fan_fee":
				if arg in [5,10,20]: club["fee"]=arg
			"fan_post":
				if not arg in ["Art & essays","Fashion & glamour","Adults-only discussions"] or int(club["posts"])>=3 or not _pay(0): return
				club["posts"]=int(club["posts"])+1
				club["subscribers"]=mini(10000,int(club["subscribers"])+int(randf_range(15,35)*(1.0 if club["private"] else 1.5)*10.0/float(club["fee"])))
				GameState.add_log("I published %s on OnlyPals with my own boundaries." % str(arg).to_lower())
			"fan_privacy": club["private"]=not club["private"]
			"fan_close": s["fanclub"]={}; GameState.add_log("I closed OnlyPals. Subscription billing stopped.")
	GameState.emit_changed()

func yearly() -> void:
	if Lives.separate() or not GameState.player.has("creator"): return
	var s := state()
	if int(s["year"])>=GameState.year_now(): return
	s["year"]=GameState.year_now()
	var royalties := 0
	for track in s["catalog"]:
		if not track["licensed"]: royalties+=int(float(track["quality"])*maxf(0.10,1.0-(GameState.year_now()-int(track["year"]))*0.12)*4)
	var club: Dictionary = s["fanclub"]
	var net := 0
	if not club.is_empty():
		if GameState.in_prison() or int(club["posts"])==0: club["subscribers"]=int(club["subscribers"])*0.65
		else: club["subscribers"]=int(club["subscribers"])*0.90
		if GameState.in_prison(): net=0
		else: net=maxi(0,int(club["subscribers"])*int(club["fee"])*12*0.8-300)
		club["net"]=net
		club["posts"]=0
	GameState.player["money"]=int(GameState.player["money"])+royalties+net
	s["report"]={"year":GameState.year_now(),"royalties":royalties,"subscriptions":net}
	if royalties+net>0: GameState.add_log("My creator work paid %s in royalties and %s from subscriptions after platform costs." % [GameState.fmt_money(royalties),GameState.fmt_money(net)])
