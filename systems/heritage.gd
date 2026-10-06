extends RefCounted
var h
var duties
func _init(hub):
	h=hub
	duties=preload("res://systems/estate_duties.gd").new(h)
func st() -> Dictionary: return h.section("heritage",{"plan":{},"memoir":{"chapters":[],"published":false},"care":{},"mentored":{},"phased":false,"estate_dispute":{}})
func plan(will: String, executor: String = "") -> void:
	if will not in ["equal","charity"]:
		if not will.begins_with("heir:") or will.substr(5) not in GameState.npcs_with("child"): return
	if not h.pay("estate_plan",1,Actions._cost(150),18): return
	GameState.player["will"]=will
	st()["plan"]={"will":will,"executor":FamilyChronicle.identity(GameState.npc(executor)) if GameState.npcs.has(executor) else "","year":GameState.year_now(),"discussed":false}
	if will.begins_with("heir:"): st()["plan"]["heir_uid"]=FamilyChronicle.identity(GameState.npc(will.substr(5)))
	h.done("📜","Estate prepared","The chosen will is used by the existing inheritance system. Gifts, estate transfers and live viewpoint changes remain different transactions.")
func discuss() -> void:
	if st()["plan"].is_empty() or not h.pay("estate_talk",1,0,18): return
	st()["plan"]["discussed"]=true
	for id in GameState.npcs_with("child"): BondStats.apply(str(id),{"trust":2,"respect":2})
	h.done("👪","Family conversation","I explained the plan and recorded questions. Unequal distributions may still cause a dispute after death.")
func executor(id: String) -> void:
	if st()["plan"].is_empty() or not GameState.npcs.has(id) or not GameState.npc(id).get("alive",false) or int(GameState.npc(id)["age"])<18 or not h.pay("executor",1,0,18): return
	st()["plan"]["executor"]=FamilyChronicle.identity(GameState.npc(id))
	h.done("📜","Executor recorded",str(GameState.npc(id)["first"])+" is recorded as the intended executor. A discussed, documented plan can reduce family uncertainty.")
func handover(id: String) -> void:
	if id not in GameState.npcs_with("child") or int(GameState.npc(id)["age"])<18: return
	Ambition.ensure()
	var e: Dictionary=GameState.player["ambition"]["enterprise"]
	if e["portfolio"].is_empty() or not h.pay("business_handover",2,Actions._cost(500),18): return
	var n := GameState.npc(id)
	if not n.has("ambition"): n["ambition"]={}
	if not n["ambition"].has("enterprise"): n["ambition"]["enterprise"]={"portfolio":[],"acquisitions":0,"bankruptcies":0,"succession":"","dividends":0}
	var target: Dictionary=n["ambition"]["enterprise"]
	for company in e["portfolio"]:
		var moved: Dictionary=company.duplicate(true)
		moved["ceo"]=""; moved["family_handover"]={"from":h.uid(),"to":FamilyChronicle.identity(n),"year":GameState.year_now()}
		target["portfolio"].append(moved)
	e["portfolio"]=[]; e["succession"]=""
	if n.has("playable_player"): n["playable_player"]["ambition"]=n["ambition"].duplicate(true)
	BondStats.apply(id,{"respect":4,"trust":3})
	FamilyChronicle.remember(id,"Took ownership of the family company portfolio.","good")
	h.done("🏢","Ownership handed over","The portfolio now belongs to "+str(n["first"])+". The family business is theirs to manage now.")
func gift(id: String, index: int) -> void:
	if id not in GameState.npcs_with("child") or index<0 or index>=GameState.player.get("possessions",[]).size(): return
	if not h.pay("heirloom_gift",1,0,18): return
	var item: Dictionary=GameState.player["possessions"].pop_at(index)
	var n := GameState.npc(id); var target := FamilyChronicle.identity(n)
	if not item.has("heirloom_history"): item["heirloom_history"]=[]
	item["heirloom_history"].append({"from":h.uid(),"to":target,"year":GameState.year_now(),"kind":"gift"})
	if item["heirloom_history"].size()>16: item["heirloom_history"].pop_front()
	item["heirloom"]=true
	if not n.has("possessions"): n["possessions"]=[]
	n["possessions"].append(item)
	if n.has("playable_player"): n["playable_player"]["possessions"]=n["possessions"].duplicate(true)
	FamilyChronicle.remember(id,"Received the family possession "+str(item.get("name","an heirloom")),"good")
	h.done("🎁","A gift, not duplication",str(item.get("name","The heirloom"))+" now belongs to "+str(n["first"])+". It was removed from my possessions.")
func mentor(id: String) -> void:
	if int(GameState.player["age"])<50 or not GameState.npcs.has(id) or not GameState.npc(id).get("alive",false) or int(GameState.npc(id)["age"])<6: return
	if not h.pay("elder_mentor",1,0,50): return
	var field := "General"; var best := 0
	for f in GameState.player.get("professional_skills",{}):
		if int(GameState.player["professional_skills"][f])>best: field=str(f); best=int(GameState.player["professional_skills"][f])
	var n := GameState.npc(id)
	if not n.has("professional_skills"): n["professional_skills"]={}
	n["professional_skills"][field]=mini(10,int(n["professional_skills"].get(field,0))+1)
	if n.has("playable_player"): n["playable_player"]["professional_skills"]=n["professional_skills"].duplicate(true)
	st()["mentored"][FamilyChronicle.identity(n)]=GameState.year_now()
	BondStats.apply(id,{"respect":4,"trust":2}); FamilyChronicle.remember(id,"Learned practical "+field+" experience from an older relative.","good")
	h.done("🌳","Experience passed on",str(n["first"])+" gained a recorded point of "+field+" skill. Their own life, choices and circumstances still matter.",{"happiness":2})
func circle() -> void:
	if not h.pay("older_circle",1,Actions._cost(60),50): return
	var friends: Array=GameState.npcs_with("friend").filter(func(id): return int(GameState.npc(id)["age"])>=50)
	var id := str(friends.pick_random()) if not friends.is_empty() else GameState.create_npc("friend",{"age":clampi(int(GameState.player["age"])+randi_range(-6,6),50,90),"closeness":50})
	BondStats.apply(id,{"affection":4,"trust":2})
	FamilyChronicle.remember(id,"Shared later-life company and experiences.","good")
	h.done("🫖","Company in later life","I spent time with "+str(GameState.npc(id)["first"])+". Friendship does not stop when work does.",{"happiness":3,"stress":-2})
func memoir() -> void:
	if st()["memoir"]["published"] or not h.pay("memoir",1,0,50): return
	var m: Dictionary=st()["memoir"]
	var topics: Array=["The people who helped me","A choice I would make differently","What mattered beyond money"]
	h.decision("heritage","memoir",{},"A chapter of my life","A memoir can hold ambiguity without turning a person into a score.",topics)
func care(id: String, supported: bool) -> void:
	if not GameState.npcs.has(id): return
	h.modules["wellbeing"].caregiver(id,"professional" if supported else "self")
	# This route now uses the shared care schedule, avoiding duplicate annual relief.
	if h.modules["wellbeing"].used("caregiving:"+FamilyChronicle.identity(GameState.npc(id))): st()["care"]={}
func settle() -> void:
	var d: Dictionary=st()["estate_dispute"]
	if d.is_empty() or d.get("resolved",false) or not h.pay("estate_dispute",1,Actions._cost(250),18): return
	h.decision("heritage","dispute",{},"An estate is disputed","A sibling questions the unequal distribution. The estate record can be reviewed; this is about an actual transfer, not another inheritance payout.",["Mediate and share 10% of the cash bequest","Explain the recorded will and evidence","Refuse to discuss it"])
func resolve(op: String, _args: Dictionary, answer: int) -> void:
	if op=="estate_duty": duties.resolve(_args,answer)
	elif op=="memoir":
		var m: Dictionary=st()["memoir"]
		m["chapters"].append({"year":GameState.year_now(),"topic":["help","regret","meaning"][answer],"memory":GameState.player.get("personal_history",[]).slice(-3).duplicate(true)})
		if m["chapters"].size()>=3:
			m["published"]=true
			if not GameState.world.has("family_memoirs"): GameState.world["family_memoirs"]={}
			GameState.world["family_memoirs"][h.uid()]={"name":str(GameState.player["first"]),"chapters":m["chapters"].duplicate(true),"year":GameState.year_now()}
			h.done("📖","A memoir for the family","Three chapters are recorded on this person's life. The next generation can read them without inheriting a moral score.",{"happiness":4})
		else: h.done("📖","A chapter kept","Memoir chapters %d/3. Continue next year." % m["chapters"].size())
	elif op=="dispute":
		var d: Dictionary=st()["estate_dispute"]
		if d.is_empty() or d.get("resolved",false): return
		d["resolved"]=true; d["choice"]=answer
		var id: String=h.person(str(d["sibling"])); var paid := 0
		if answer==0 and id!="":
			paid=mini(maxi(0,int(GameState.player["money"])),maxi(0,int(d["cash"])/10)); GameState.player["money"]=int(GameState.player["money"])-paid
			GameState.npc(id)["money"]=int(GameState.npc(id).get("money",0))+paid; BondStats.apply(id,{"trust":5,"resentment":-5})
		elif id!="": BondStats.apply(id,{"trust":1 if answer==1 else -6,"resentment":-1 if answer==1 else 6})
		h.done("⚖️","Estate response recorded","Transferred %s; the original bequest was not paid again. The family's response remains in this person's record." % GameState.fmt_money(paid))
func record_inheritance(old: Dictionary, child: Dictionary, cash: int, inherited_items: Array = []) -> void:
	if not GameState.world.has("estate_register"): GameState.world["estate_register"]={}
	var source := FamilyChronicle.identity(old); var target := FamilyChronicle.identity(child)
	if not GameState.world["estate_register"].has(source): GameState.world["estate_register"][source]={"heir":target,"cash":cash,"year":GameState.year_now(),"status":"executed","will":old.get("will","equal")}
	var plan0: Dictionary=old.get("journey",{}).get("heritage",{}).get("plan",{})
	GameState.world["estate_register"][source]["executor"]=str(plan0.get("executor",""))
	GameState.world["estate_register"][source]["discussed"]=bool(plan0.get("discussed",false))
	GameState.world["estate_register"][source]["name"]=str(old.get("first","Earlier life"))
	duties.ensure(source)
	for item in inherited_items:
		if item.get("heirloom_history",[]).any(func(it): return it.get("from","")==source and it.get("kind","")=="inheritance"): continue
		if not item.has("heirloom_history"): item["heirloom_history"]=[]
		item["heirloom_history"].append({"from":source,"to":target,"year":GameState.year_now(),"kind":"inheritance"})
		if item["heirloom_history"].size()>16: item["heirloom_history"].pop_front()
	if str(old.get("will","equal")).begins_with("heir:"):
		for id in GameState.npcs_with("sibling"):
			if bool(GameState.npc(str(id)).get("alive",false)): st()["estate_dispute"]={"source":source,"sibling":FamilyChronicle.identity(GameState.npc(str(id))),"cash":cash,"resolved":false}; break
func yearly() -> void:
	if Lives.separate(): return
	duties.yearly()
	var c: Dictionary=st()["care"]
	if not c.is_empty() and int(c["year"])==GameState.year_now()-1:
		var id: String=h.person(str(c["uid"]))
		if id!="" and bool(GameState.npc(id)["alive"]):
			GameState.npc(id)["health"]=minf(100,float(GameState.npc(id).get("health",50))+1); BondStats.apply(id,{"affection":3,"trust":2})
			GameState.change_stat("stress",1 if c["supported"] else 4)
	if st()["phased"] and GameState.has_job(): GameState.change_stat("stress",-3)
func menu(page: String) -> Dictionary:
	if page.begins_with("estate:"): return duties.menu(page.substr(7))
	var rows: Array=[h.nav("parenting","Parenting & childcare","Age-specific decisions and actual child continuity"),h.nav("leisure","Hobbies & quiet goals","Retirement can include purpose without fame or wealth")]; var info: Array=["Living transfers keep ownership with each person. Gifts remove items from the giver; inheritance is recorded after death."]
	if page.begins_with("gift:"):
		var id := page.substr(5)
		for i in range(GameState.player.get("possessions",[]).size()): rows.append(h.row("heritage",str(GameState.player["possessions"][i].get("name","Heirloom")),"Gift ownership · 1 time · one gift per year","gift",[id,i]))
	else:
		rows.append_array(duties.rows())
		rows.append(h.row("heritage","Equal estate plan","1 time · "+GameState.fmt_money(Actions._cost(150)),"plan","equal"))
		rows.append(h.row("heritage","Charitable estate plan","1 time · cash estate goes to charity","plan","charity"))
		rows.append(h.row("heritage","Discuss the estate","1 time · keep a record of the conversation","discuss",null,not st()["plan"].is_empty()))
		for id in GameState.npcs_with("child"):
			rows.append(h.row("heritage","Name "+str(GameState.npc(str(id))["first"])+" as heir","70% named / 30% shared targets; whole assets have one owner","plan","heir:"+str(id)))
			rows.append(h.nav("heritage","Give "+str(GameState.npc(str(id))["first"])+" an heirloom","Transfer an owned possession","gift:"+str(id)))
			rows.append(h.row("heritage","Mentor "+str(GameState.npc(str(id))["first"]),"Age 50+ · 1 time · recorded practical skill","mentor",id,int(GameState.player["age"])>=50))
			rows.append(h.row("heritage","Executor: "+str(GameState.npc(str(id))["first"]),"Adult child · estate plan required · 1 time","executor",id,int(GameState.npc(str(id))["age"])>=18 and not st()["plan"].is_empty()))
			rows.append(h.row("heritage","Hand over companies to "+str(GameState.npc(str(id))["first"]),"Adult child · transfer portfolio · 2 time · "+GameState.fmt_money(Actions._cost(500)),"handover",id,int(GameState.npc(str(id))["age"])>=18 and not GameState.player.get("ambition",{}).get("enterprise",{}).get("portfolio",[]).is_empty()))
		rows.append(h.row("heritage","Write my memoir","Age 50+ · three chapters across years","memoir",null,int(GameState.player["age"])>=50 and not st()["memoir"]["published"]))
		rows.append(h.row("heritage","Later-life social circle","Age 50+ · 1 time · "+GameState.fmt_money(Actions._cost(60)),"circle",null,int(GameState.player["age"])>=50))
		rows.append(h.row("heritage","Phased work: "+("ON" if st()["phased"] else "OFF"),"Age 55+ · half wages · less annual stress","phased",null,int(GameState.player["age"])>=55 and GameState.has_job()))
		for id in GameState.npcs_with("mother")+GameState.npcs_with("father")+GameState.npcs_with("partner"):
			if int(GameState.npc(str(id))["age"])>=65 or float(GameState.npc(str(id)).get("health",100))<50:
				rows.append(h.row("heritage","Care for "+str(GameState.npc(str(id))["first"]),"2 time · "+GameState.fmt_money(Actions._cost(80)),"care",[id,false]))
				rows.append(h.row("heritage","Arrange care support","1 time · "+GameState.fmt_money(Actions._cost(800)),"care",[id,true]))
		if not st()["estate_dispute"].is_empty(): rows.append(h.row("heritage","Review the estate dispute","1 time · mediation cost "+GameState.fmt_money(Actions._cost(250)),"dispute",null,not st()["estate_dispute"].get("resolved",false)))
		if st()["memoir"]["published"]: info.append("My completed memoir: "+str(st()["memoir"]["chapters"].size())+" chapters.")
		for uid0 in GameState.world.get("family_memoirs",{}):
			if uid0==h.uid() or GameState.player.get("parent_uids",[]).has(uid0):
				var m: Dictionary=GameState.world["family_memoirs"][uid0]
				info.append(str(m["name"])+"'s memoir · "+str(m["year"]))
				for chapter in m["chapters"]: info.append(str(chapter["topic"]).capitalize()+" · "+str(chapter["memory"]))
	return {"icon":"🌳","title":"Generations & later life","info":info,"rows":rows}
func act(key: String, arg: Variant) -> void:
	match key:
		"plan": plan(str(arg))
		"discuss": discuss()
		"executor": executor(str(arg))
		"estate_duty": duties.start(str(arg))
		"estate_delegate": duties.delegate(str(arg))
		"handover": handover(str(arg))
		"gift": gift(str(arg[0]),int(arg[1]))
		"mentor": mentor(str(arg))
		"circle": circle()
		"memoir": memoir()
		"care": care(str(arg[0]),bool(arg[1]))
		"dispute": settle()
		"phased": if int(GameState.player["age"])>=55 and GameState.has_job() and h.blocked(55)=="": st()["phased"]=not st()["phased"]
