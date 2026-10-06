extends RefCounted
## Emotional strain is a life course, not a second diagnostic or moral score.
var h
var scenes: Array=[]
const TOPICS := {"stress":"Stress","grief":"Remembering a loss","loneliness":"Connection","burnout":"Rest & boundaries"}
func _init(hub):
	h=hub; scenes=ContentDB._load_json("res://data/coping_scenes.json",[])
func st(patient: Dictionary = {}) -> Dictionary:
	return h.section("coping",{"losses":[],"contacts":{},"loneliness":0.0,"burnout":0.0,"routine":"none","routine_year":-99,"supported":-99,"last_year":-1,"last_clinical":-1,"history":[],"followup":{},"legacy_loss":false},patient)
func note(text: String) -> void:
	st()["history"].push_front({"year":GameState.year_now(),"text":text})
	if st()["history"].size()>100: st()["history"].resize(100)
	Care.course().record("Coping",text)
func lost(id: String, clinical_record: bool = true) -> void:
	if not GameState.npcs.has(id) or Lives.separate(): return
	family_loss(id)
	var n := GameState.npc(id); var uid0 := FamilyChronicle.identity(n)
	if int(n.get("closeness",0))<35 or n.get("relation","") not in ["mother","father","stepmother","stepfather","child","stepchild","partner","sibling","stepsibling","grandparent","pet","best_friend","friend"]: return
	if st()["losses"].any(func(entry): return entry["uid"]==uid0): return
	st()["losses"].push_front({"uid":uid0,"name":GameState.full_name(id),"year":GameState.year_now(),"relation":n["relation"],"burden":clampf(float(n.get("closeness",50))*0.65,15,65),"remembered":-99})
	if st()["losses"].size()>32: st()["losses"].resize(32)
	var text := "Remembering "+GameState.full_name(id)+" · grief has its own pace"
	if clinical_record: note(text)
	else:
		st()["history"].push_front({"year":GameState.year_now(),"text":text})
		if st()["history"].size()>100: st()["history"].resize(100)
		GameState.add_log(text)
func family_loss(id: String) -> void:
	var departed := GameState.npc(id)
	if departed.get("species","human")!="human": return
	var uid0 := FamilyChronicle.identity(departed)
	var parents: Array=departed.get("parent_uids",[])
	for n in GameState.npcs.values():
		if n==departed or not n.get("alive",false) or n.get("species","human")!="human": continue
		var relation := ""
		var own_parents: Array=n.get("parent_uids",[])
		if own_parents.has(uid0): relation="father" if departed["gender"]=="male" else "mother" if departed["gender"]=="female" else "parent"
		elif parents.has(FamilyChronicle.identity(n)): relation="child"
		elif own_parents.any(func(uid): return parents.has(uid)): relation="sibling"
		if relation=="": continue
		var former: Dictionary=n.get("playable_player",{})
		if not n.has("journey") and former.has("journey"): n["journey"]=former["journey"].duplicate(true)
		var s := st(n)
		if s["losses"].any(func(loss): return str(loss["uid"])==uid0): continue
		# The known family link establishes the loss. Closeness to the active
		# player is not a substitute for this pair's own relationship.
		s["losses"].push_front({"uid":uid0,"name":GameState.full_name(id),"year":GameState.year_now(),"relation":relation,"burden":40.0,"remembered":-99})
		if s["losses"].size()>32: s["losses"].resize(32)
		s["history"].push_front({"year":GameState.year_now(),"text":"Lost my "+relation+" "+GameState.full_name(id)+"."})
		if s["history"].size()>100: s["history"].resize(100)
		n["stress"]=clampf(float(n.get("stress",former.get("stats",{}).get("stress",30)))+5,0,100)
		n["happiness"]=clampf(float(n.get("happiness",60))-6,0,100)
		if not former.is_empty():
			former["journey"]=n["journey"].duplicate(true)
			former["stats"]["stress"]=n["stress"]; former["stats"]["happiness"]=n["happiness"]
func contact(id: String) -> void:
	if not GameState.npcs.has(id) or not GameState.is_alive() or Lives.separate(): return
	var n := GameState.npc(id)
	if not n.get("alive",false) or n.get("species","human")!="human": return
	var uid0 := FamilyChronicle.identity(n)
	if int(st()["contacts"].get(uid0,-99))==GameState.year_now(): return
	st()["contacts"][uid0]=GameState.year_now(); st()["loneliness"]=maxf(0,float(st()["loneliness"])-6)
func connection_count() -> int:
	var count := 0
	for uid0 in st()["contacts"]:
		var who: String=h.person(str(uid0))
		if who!="" and GameState.npc(who).get("alive",false) and int(GameState.npc(who).get("closeness",0))>=35 and int(st()["contacts"][uid0])>=GameState.year_now()-1: count+=1
	return count
func grief() -> float:
	var total := 0.0
	for loss in st()["losses"]: total+=float(loss["burden"])
	return minf(100,total)
func grief_risk() -> bool:
	return int(GameState.player["age"])>=10 and st()["losses"].any(func(loss): return GameState.year_now()-int(loss["year"])<=2 and float(loss["burden"])>=25)
func clinical() -> void:
	var s := st(); var year := GameState.year_now()
	if int(s["last_clinical"])==year: return
	s["last_clinical"]=year
	if GameState.has_flag("lost_close_person"):
		if s["losses"].is_empty() and not s["legacy_loss"]:
			s["legacy_loss"]=true; note("An earlier loss remains part of my life.")
		GameState.clear_flag("lost_close_person")
func relieve(amount: float) -> void:
	st()["loneliness"]=maxf(0,float(st()["loneliness"])-amount)
	st()["burnout"]=maxf(0,float(st()["burnout"])-amount)
	for loss in st()["losses"]: loss["burden"]=maxf(0,float(loss["burden"])-amount*0.65)
func clinical_support(kind: String) -> void:
	if kind not in ["therapy","support","rest"]: return
	st()["supported"]=GameState.year_now(); relieve(8 if kind=="therapy" else 6 if kind=="support" else 4)
	note({"therapy":"Therapy added a coping plan.","support":"Peer support made room for the difficult parts.","rest":"A quiet week reduced immediate demands."}[kind])
func routine(kind: String) -> void:
	if kind not in ["gentle","boundaries","push"] or int(GameState.player["age"])<6: return
	if not Care.course().pay_visit("Coping routine",0,2 if kind=="boundaries" else 1): return
	st()["routine"]=kind; st()["routine_year"]=GameState.year_now()
	if kind=="push": st()["burnout"]=minf(100,float(st()["burnout"])+8)
	else: relieve(6 if kind=="boundaries" else 4)
	note("Routine: "+kind); h.done("🌿","Routine recorded",{"gentle":"A manageable routine fits my current health. It needs renewal each year.","boundaries":"I protected rest time and set a limit on demands. The next year reviews it.","push":"I kept the demands high. The record will show the strain as well as the effort."}[kind],{"stress":4 if kind=="push" else -5})
func talk(uid0: String) -> void:
	var who: String=h.person(uid0)
	if who=="" or int(GameState.player["age"])<6: return
	var n := GameState.npc(who)
	if not n.get("alive",false) or int(n.get("closeness",0))<50 or n.get("relation","") not in ["mother","father","stepmother","stepfather","sibling","stepsibling","partner","child","stepchild","friend","best_friend"] or int(n.get("prison",0))>0: return
	if not Care.course().pay_visit("Coping conversation",0,1): return
	contact(who); relieve(4); st()["supported"]=GameState.year_now()
	BondStats.apply(who,{"trust":2,"affection":2}); FamilyChronicle.remember(who,"Made time for a difficult conversation.","good")
	note("Talked with "+GameState.full_name(who)); h.done("🤝","A real conversation",GameState.full_name(who)+" made time. It helped; it did not erase the difficult chapter.",{"stress":-4,"happiness":2})
func remember(uid0: String) -> void:
	var selected: Dictionary={}
	for loss in st()["losses"]:
		if str(loss["uid"])==uid0: selected=loss; break
	if selected.is_empty() or int(GameState.player["age"])<6 or not Care.course().pay_visit("Remembering:"+uid0,0,1): return
	selected["remembered"]=GameState.year_now(); selected["burden"]=maxf(0,float(selected["burden"])-8)
	note("Made room to remember "+str(selected["name"])); h.done("🕯️","A remembered person",str(selected["name"])+" remains part of my story. Making room for the memory eased some strain.",{"stress":-3})
func pressure(topic: String) -> float:
	return GameState.stat("stress") if topic=="stress" else grief() if topic=="grief" else float(st()[topic]) if topic in ["loneliness","burnout"] else 0.0
func readiness(context: String) -> float:
	if int(GameState.player.get("age",0))<6 or context not in ["work","education","creative","technical"]: return 0
	return -minf(8,maxf(0,float(st()["burnout"])-35)/10.0)
func available_scenes(topic: String) -> Array:
	return scenes.filter(func(scene): return scene["topic"]==topic and int(GameState.player["age"])>=int(scene["min_age"]) and pressure(topic)>=25 and (not scene.get("work_only",false) or GameState.has_job()) and (not scene.get("school_only",false) or GameState.in_school() or GameState.in_university()) and Novelty.eligible(scene))
func story(topic: String) -> void:
	var pool := available_scenes(topic)
	if pool.is_empty() or not Care.course().pay_visit("Coping story",0,1): return
	var scene: Dictionary=Novelty.pick(pool); Novelty.note(scene)
	var options: Array=[]
	for option in scene["choices"]:
		var entry := {"label":str(option["label"])+(" · "+GameState.fmt_money(Actions._cost(int(option["cost"]))) if int(option["cost"])>0 else "")}
		if int(option["cost"])>0 and not Childhood.supported(): entry["requires"]={"money":Actions._cost(int(option["cost"]))}
		options.append(entry)
	h.decision("coping","story",{"scene":scene,"year":GameState.year_now(),"owner":h.uid()},scene["title"],str(scene["text"]).replace("{person}",str(st()["losses"][0]["name"]) if not st()["losses"].is_empty() else "the person I remember"),options)
func resolve(op: String, args: Dictionary, answer: int) -> void:
	if op!="story" or not args.has("scene") or int(args.get("year",-1))!=GameState.year_now() or str(args.get("owner",""))!=h.uid() or answer<0 or answer>=3 or not GameState.is_alive(): return
	var scene: Dictionary=args["scene"]
	if h.used("coping_result:"+str(scene["id"])): return
	var option: Dictionary=scene["choices"][answer]; var fee := Actions._cost(int(option["cost"]))
	if fee>0 and not Childhood.supported() and int(GameState.player["money"])<fee: h.done("🌿","Support cost","The planned support could not be funded; no fee or benefit applied."); return
	h.mark("coping_result:"+str(scene["id"])); Care.course().charge(fee,"Practical coping support")
	var topic: String=scene["topic"]; var gain := float(option["ease"])
	if topic=="grief":
		for loss in st()["losses"]: loss["burden"]=clampf(float(loss["burden"])-gain,0,100)
	elif topic in ["loneliness","burnout"]: st()[topic]=clampf(float(st()[topic])-gain,0,100)
	if gain>0: st()["supported"]=GameState.year_now()
	st()["followup"]={"due":GameState.year_now()+1,"topic":topic,"result":option["followup"],"gain":gain}
	note(scene["title"]+" · "+option["result"]); h.done("🌿",scene["title"],option["result"],{"stress":option["stress"],"happiness":option["happy"]})
func yearly() -> void:
	if Lives.separate() or not GameState.is_alive() or int(GameState.player["age"])<6: return
	clinical(); var s := st(); var year := GameState.year_now()
	if int(s["last_year"])==year: return
	s["last_year"]=year
	for n in GameState.npcs.values(): background(n,year)
	for uid0 in s["contacts"].keys():
		if int(s["contacts"][uid0])<year-3: s["contacts"].erase(uid0)
	var contacts := connection_count(); var support: bool=int(s["supported"])>=year-1
	s["loneliness"]=clampf(float(s["loneliness"])+(7 if contacts==0 else 1 if contacts==1 else -5)-(4 if support else 0),0,100)
	var regular: bool=int(s["routine_year"])>=year-1
	var demand: bool= GameState.stat("stress")>=65 or Grit.active_habits().has("workaholic") or GameState.player["medical"]["mental"].has("burnout")
	s["burnout"]=clampf(float(s["burnout"])+(8 if demand else -4)+(5 if regular and s["routine"]=="push" else -8 if regular else 0)-(3 if support else 0),0,100)
	for loss in s["losses"]:
		var since := year-int(loss["year"])
		var reminder: bool=since>0 and float(loss["burden"])>0 and Care.course().roll("Loss anniversary:"+str(loss["uid"]))<0.2
		loss["burden"]=clampf(float(loss["burden"])-(5 if support else 3)+(3 if reminder else 0),0,100)
	if regular and s["routine"]!="push":
		GameState.apply_effects({"stress":-3,"health":1}); note("The manageable routine held across the year.")
	if float(s["loneliness"])>=55: GameState.apply_effects({"happiness":-2}); note("Connection strain %.0f/100 · limited contact affected my mood." % s["loneliness"])
	if float(s["burnout"])>=55: GameState.apply_effects({"stress":3}); note("Rest strain %.0f/100 · demands added stress." % s["burnout"])
	var follow: Dictionary=s["followup"]
	if not follow.is_empty() and int(follow["due"])<=year:
		var held: bool=support or (regular and s["routine"]!="push")
		note(str(follow["result"])+(" The support continued." if held else " I need to renew support; the earlier choice remains recorded."))
		if held and float(follow["gain"])>0: relieve(3); GameState.apply_effects({"stress":-2})
		s["followup"]={}
func background(n: Dictionary, year: int) -> void:
	if not n.get("alive",false) or n.get("species","human")!="human": return
	var former: Dictionary=n.get("playable_player",{})
	var source: Dictionary=n.get("journey",former.get("journey",{}))
	if not source.has("coping"): return
	if not n.has("journey"): n["journey"]=source.duplicate(true)
	var s := st(n)
	if int(s["last_year"])==year: return
	s["last_year"]=year; s["last_clinical"]=year
	var supported: bool=int(s["supported"])>=year-1; var regular: bool=int(s["routine_year"])>=year-1 and s["routine"]!="push"
	var stress: float=float(n.get("stress",former.get("stats",{}).get("stress",30)))
	var contacts := 0
	for uid0 in s["contacts"].keys():
		var who: String=h.person(str(uid0)); var alive: bool=GameState.is_alive() if str(uid0)==h.uid() else who!="" and GameState.npc(who).get("alive",false)
		if int(s["contacts"][uid0])>=year-1 and alive: contacts+=1
		if int(s["contacts"][uid0])<year-3: s["contacts"].erase(uid0)
	s["loneliness"]=clampf(float(s["loneliness"])+(7 if contacts==0 else 1 if contacts==1 else -5)-(4 if supported else 0),0,100)
	s["burnout"]=clampf(float(s["burnout"])+(8 if stress>=65 else -4)-(8 if regular else 0)-(3 if supported else 0),0,100)
	for loss in s["losses"]: loss["burden"]=maxf(0,float(loss["burden"])-(5 if supported else 3))
	if regular: stress=maxf(0,stress-3)
	n["stress"]=stress
	var follow: Dictionary=s["followup"]
	if not follow.is_empty() and int(follow["due"])<=year:
		s["history"].push_front({"year":year,"text":str(follow["result"])+(" The routine continued." if regular else " Support needs renewing.")})
		s["followup"]={}
	if s["history"].size()>100: s["history"].resize(100)
	if not former.is_empty(): former["journey"]=n["journey"].duplicate(true); former["stats"]["stress"]=stress
func menu(page: String) -> Dictionary:
	var rows: Array=[]; var info: Array=["Support and manageable routines help over time. Memories stay; strain is not a measure of worth."]
	if page=="history":
		for entry in st()["history"]: info.append("%d · %s" % [entry["year"],entry["text"]])
	elif page=="contacts":
		for n in GameState.npcs.values():
			if n.get("alive",false) and int(n.get("closeness",0))>=50 and n.get("relation","") in ["mother","father","stepmother","stepfather","sibling","stepsibling","partner","child","stepchild","friend","best_friend"] and int(n.get("prison",0))==0:
				rows.append(h.row("coping",GameState.full_name(str(n["id"])),"1 time · a real conversation","talk",FamilyChronicle.identity(n),not Care.course().used("Coping conversation")))
		if rows.is_empty(): info.append("No available trusted contact. Groups and quiet activities remain open.")
	elif page=="losses":
		for loss in st()["losses"]: rows.append(h.row("coping",str(loss["name"]),"1 time · remembered since "+str(loss["year"]),"remember",loss["uid"],not Care.course().used("Remembering:"+str(loss["uid"]))))
		if rows.is_empty(): info.append("No named loss has been recorded in this life.")
	elif TOPICS.has(page):
		info.append(TOPICS[page]+" · strain %.0f/100" % pressure(page))
		rows.append(h.row("coping","A personal moment","1 time · choices and next-year follow-up","story",page,not available_scenes(page).is_empty() and not Care.course().used("Coping story")))
		for kind in ["gentle","boundaries","push"]: rows.append(h.row("coping",{"gentle":"A gentle routine","boundaries":"Protect rest time","push":"Keep pushing"}[kind],"%d time · renew each year" % (2 if kind=="boundaries" else 1),"routine",kind,not Care.course().used("Coping routine")))
		rows.append(h.nav("coping","Talk with someone","Trusted family and friends","contacts"))
		if page=="grief": rows.append(h.nav("coping","Remember a person","The actual people on my record","losses"))
		rows.append({"icon":"🫂","name":"Therapy & groups","sub":"Existing clinical support","menu":"exp:mental"})
		rows.append(h.nav("leisure","Hobbies & quiet goals","Manageable activity and real collaborators"))
	else:
		for topic in TOPICS: rows.append(h.nav("coping",TOPICS[topic],"Strain %.0f/100" % pressure(topic),topic))
		rows.append(h.nav("coping","Support history","Choices and annual follow-ups","history"))
	return {"title":"Mood, grief & stress","icon":"🌿","rows":rows,"info":info}
func act(key: String, arg: Variant) -> void:
	match key:
		"routine": routine(str(arg))
		"talk": talk(str(arg))
		"remember": remember(str(arg))
		"story": story(str(arg))
