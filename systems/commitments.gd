extends RefCounted
var h
var scenes: Array=[]
const KINDS := {"visit":["Be there",0],"help":["Help with a task",120],"support":["Offer practical support",350]}
const REQUESTS := ["wants company during a difficult week","needs help preparing for an important interview","asks for support moving to a new home","wants to celebrate a small personal success","needs someone to listen after a disappointment","asks for company at a community event"]
const GOALS := {"learning":["Learn something new","help"],"belonging":["Find more company","visit"],"stability":["Get practical life in order","support"],"quiet":["Protect time and energy","visit"]}
const RIVAL_SCENES := [
	["A shared friend invites us both. The rivalry has made every gathering awkward.",["Attend, keeping clear boundaries","Ask for separate visits","Turn the gathering into a confrontation"],[2,1,-5]],
	["An old rival takes credit for an idea we both discussed. The record is incomplete.",["Compare the dated work privately","Let this claim go and protect my time","Make an accusation without checking"],[3,0,-6]],
	["The person I fell out with asks whether we could start with a small shared task.",["Agree to one limited task","Decline without another insult","Demand an instant apology in public"],[4,1,-5]],
	["A rival has a setback and asks a mutual friend for support.",["Offer limited practical help","Keep a respectful distance","Celebrate their misfortune"],[4,0,-8]],
	["Our old disagreement has changed as our responsibilities changed.",["Explain what changed and listen","Keep the distance without hostility","Repeat the old argument"],[5,1,-4]],
	["A shared project needs both of our skills, but trust is still weak.",["Write down separate duties and review them","Take a smaller independent role","Promise cooperation, then exclude them"],[4,1,-7]]
]
const RIVAL_ALTERNATIVES := ["Leave early and contact the host later","Keep my own dated work public","Suggest a neutral person join the task","Send a brief message without taking on more","Write down my boundary before discussing it","Ask for a small trial before committing"]
func _init(hub):
	h=hub; scenes=ContentDB._load_json("res://data/social_scenes.json",[])
func st() -> Dictionary: return h.section("people",{"promises":[],"repair":{},"agreements":{},"requests":{},"moments":[],"reliability":50.0})
func valid(id: String) -> bool: return GameState.npcs.has(id) and bool(GameState.npcs[id]["alive"]) and GameState.npcs[id].get("species","human")=="human"
func action_reason(key: String, time: int, price: int, age: int = 0) -> String:
	var blocked_text: String = h.blocked(age)
	if blocked_text!="": return blocked_text
	if h.used(key): return "Used this year"
	if int(GameState.player["time_left"])<time: return "Needs %d time" % time
	if int(GameState.player["money"])<price: return "Needs "+GameState.fmt_money(price)
	return ""
func motive(id: String) -> Dictionary:
	var n := GameState.npc(id)
	if not n.has("motive"): n["motive"]={"goal":GOALS.keys().pick_random(),"space":randi_range(0,2),"progress":0,"last_contact":GameState.year_now(),"favours":0}
	return n["motive"]
func apply_person_effects(id: String, effects: Dictionary) -> String:
	if not valid(id) or effects.is_empty(): return ""
	var n := GameState.npc(id)
	var saved: Dictionary=n.get("playable_player",{})
	var saved_stats: Dictionary=saved.get("stats",{})
	var labels := {"health":"health","happiness":"mood","smarts":"smarts","stress":"stress"}
	var changes: Array=[]
	for stat in labels:
		if not effects.has(stat): continue
		var before := int(n.get(stat,60))
		var after := clampi(int(round(float(before)+float(effects[stat]))),0,100)
		if after==before: continue
		n[stat]=after
		if not saved.is_empty():
			saved_stats[stat]=after
		changes.append("%s %+d" % [labels[stat],after-before])
	if not saved.is_empty():
		saved["stats"]=saved_stats
		n["playable_player"]=saved
	return " · "+", ".join(changes) if not changes.is_empty() else ""
func profile_lines(id: String) -> Array:
	if not valid(id) or int(GameState.npc(id)["age"])<6: return []
	var m := motive(id)
	var goal := str(m.get("goal", "belonging"))
	var goal_name := str(GOALS.get(goal, GOALS["belonging"])[0])
	var lines: Array=["🧭 Current aim · %s · %d/3 progress" % [goal_name, int(m.get("progress", 0))]]
	if str(m.get("last_action", ""))!="": lines.append("Recently · "+str(m["last_action"]))
	return lines
func autonomously_progress(year: int) -> void:
	var reported := 0
	var contacts: Array=[]; var alive_uids: Dictionary={}
	for id0 in GameState.npcs:
		if valid(str(id0)) and int(GameState.npc(id0)["age"])>=6:
			contacts.append(str(id0)); alive_uids[FamilyChronicle.identity(GameState.npc(id0))]=true
	for id0 in GameState.npcs:
		var id := str(id0); var n := GameState.npc(id)
		if not valid(id) or int(n["age"])<6 or int(n.get("prison",0))>0: continue
		var m := motive(id)
		if int(m.get("last_auto",-1))>=year: continue
		m["last_auto"]=year
		var goal := str(m["goal"])
		var action := {"learning":"Practised something they wanted to learn.","belonging":"Made time for their own social circle.","stability":"Sorted a practical task they had been putting off.","quiet":"Protected an evening for themselves."}
		m["progress"]=mini(3,int(m["progress"])+1); m["last_action"]=action[goal]
		if goal=="belonging":
			if m.has("circle"): m["circle"]=m["circle"].filter(func(uid0): return alive_uids.has(uid0))
			var contact_id := ""
			var offset := absi((FamilyChronicle.identity(n)+str(year)).hash())
			# Bounded search avoids a quadratic family scan on long saves.
			for j in range(mini(16,contacts.size())):
				var candidate := str(contacts[(offset+j)%contacts.size()])
				if candidate!=id and absi(int(GameState.npc(candidate)["age"])-int(n["age"]))<=12: contact_id=candidate; break
			if contact_id!="":
				if not m.has("circle"): m["circle"]=[]
				var contact_uid := FamilyChronicle.identity(GameState.npc(contact_id))
				if not m["circle"].has(contact_uid): m["circle"].append(contact_uid)
				if m["circle"].size()>8: m["circle"].pop_front()
				m["last_action"]="Spent time with "+str(GameState.npc(contact_id)["first"])+" in their own social circle."
		elif goal=="learning" or goal=="quiet":
			var stat := "smarts" if goal=="learning" else "happiness"
			n[stat]=minf(100,float(n.get(stat,50))+1)
			if not n.get("playable_player",{}).is_empty(): n["playable_player"]["stats"][stat]=n[stat]
		if int(m["progress"])>=3:
			m["last_completed"]=goal; m["completed_year"]=year
			var alternatives: Array=GOALS.keys().filter(func(g): return g!=goal)
			m["goal"]=alternatives[absi((FamilyChronicle.identity(n)+":"+str(year)).hash())%alternatives.size()]; m["progress"]=0
			m["last_action"]+=" Their next priority: "+str(GOALS[m["goal"]][0]).to_lower()+"."
		FamilyChronicle.remember(id,str(m["last_action"]))
		if reported<2 and n["relation"] in ["partner","friend","best_friend","child","sibling"]:
			h.note(str(n["first"])+" · their own plans",str(m["last_action"])); reported+=1
func moment(id: String) -> void:
	if not valid(id) or int(GameState.npc(id)["age"])<6 or h.blocked(6)!="": return
	var n := GameState.npc(id); var uid := FamilyChronicle.identity(n)
	var age := mini(int(n["age"]),int(GameState.player["age"]))
	var scene := Novelty.pick(scenes.filter(func(s): return int(s["min_age"])<=age))
	if scene.is_empty() or not h.pay("moment:"+uid,1,0,6): return
	Novelty.note(scene)
	var order: Array=[0,1,2]; order.shuffle()
	h.decision("people","moment",{"uid":uid,"scene":scene,"order":order},str(n["first"])+" · "+str(scene["title"]),str(scene["text"]).replace("{name}",str(n["first"])),order.map(func(i): return scene["answers"][i]))
func settle_moments(year: int) -> void:
	for entry in st()["moments"]:
		if entry["state"]!="open" or year<int(entry["due"]): continue
		var id: String=h.person(str(entry["uid"]))
		if not valid(id):
			entry["state"]="ended"; entry["conclusion"]="The person was no longer available; no relationship effect was applied."
			h.note("A shared moment ended",str(entry.get("name", "The person"))+" was no longer available. The follow-up closed without blame.")
			if id!="": FamilyChronicle.remember(id,"A planned shared moment ended when life changed.")
			continue
		entry["state"]="closed"
		var suited := bool(entry.get("fit",true))
		entry["conclusion"]=str(entry["later"])+(" They remembered the time together." if suited else " They remembered the visit, though it did not match what they needed.")
		if suited: BondStats.apply(id,{"trust":1,"affection":1})
		FamilyChronicle.remember(id,str(entry["conclusion"]))
		h.note(str(GameState.npc(id)["first"])+" · a year later",str(entry["conclusion"]))
func background(n: Dictionary, year: int) -> void:
	var saved: Dictionary=n.get("playable_player",{})
	var people: Dictionary=saved.get("journey",{}).get("people",{})
	for entry in people.get("moments",[]):
		if entry["state"]!="open" or year<int(entry["due"]): continue
		var target_status: Dictionary=h.person_status(str(entry["uid"]))
		var target_id := str(target_status.get("id", ""))
		var target: Dictionary=GameState.player if target_id=="player" else GameState.npc(target_id)
		if str(target_status.get("state", "missing"))!="alive" or target.is_empty() or not target.get("alive",false):
			entry["state"]="ended"; entry["conclusion"]="The person was no longer available; no relationship effect was applied."
			h.background_note(saved,year,str(n["first"])+" · follow-up closed",str(entry.get("name", "A friend"))+" was no longer available. The shared moment ended without blame.")
			var maker_id := str(n.get("id", ""))
			if maker_id!="": FamilyChronicle.remember(maker_id,"A planned shared moment ended when life changed.")
			if target_id not in ["", "player"]: FamilyChronicle.remember(target_id,"A planned shared moment with "+str(n["first"])+" ended when life changed.")
			continue
		entry["state"]="closed"
		var suited := bool(entry.get("fit",true))
		entry["conclusion"]=str(entry["later"])+(" They remembered the time together." if suited else " They remembered the visit, though it did not match what they needed.")
		# The old viewpoint's friendship must not reward the new viewpoint's bond.
		if target_id=="player": h.note(str(n["first"])+" · a shared memory",str(entry["conclusion"]))
		elif target_id!="": FamilyChronicle.remember(target_id,str(entry["conclusion"]))
		h.background_note(saved,year,str(n["first"])+" · shared memory",str(entry["conclusion"]))
func help_goal(id: String, approach: int) -> void:
	if not valid(id) or approach not in [0,1,2] or not h.pay("goal:"+FamilyChronicle.identity(GameState.npc(id)),1,Actions._cost(40 if approach==0 else 0),6): return
	var m := motive(id); var helpful: bool = approach==1 if m["goal"]=="quiet" else approach==0
	m["last_contact"]=GameState.year_now()
	if helpful: m["progress"]=mini(3,int(m["progress"])+1); m["favours"]=mini(2,int(m["favours"])+1)
	BondStats.apply(id,{"trust":3 if helpful else 1,"respect":2})
	GameState.apply_effects([{"stress":1},{"stress":-1},{"smarts":1,"stress":1}][approach])
	FamilyChronicle.remember(id,"Their goal was "+str(GOALS[m["goal"]][0])+"; I "+["helped with the task","respected their need for space","suggested another approach"][approach]+".")
	h.done("🤝","Their own priorities","Goal progress %d/3. %s" % [m["progress"],"They appreciated this kind of support." if helpful else "They accepted my limits." if approach==1 else "My approach did not fit what they wanted."],{"happiness":1})
func favour(id: String) -> void:
	if not valid(id) or int(motive(id)["favours"])<=0 or not h.pay("favour:"+FamilyChronicle.identity(GameState.npc(id)),0,0,6): return
	var m := motive(id); m["favours"]-=1
	# Favors return practical help, not endlessly recyclable money or time.
	Household.state()["fatigue"]=maxi(0,int(Household.state()["fatigue"])-5)
	BondStats.apply(id,{"affection":1}); FamilyChronicle.remember(id,"Returned practical help after my earlier support.")
	h.done("🤝","Help returned","They took a task off my hands. Fatigue −5.")
func rivalry(id: String) -> void:
	if not valid(id) or GameState.npc(id)["relation"] not in ["rival","enemy","ex","friend","best_friend"] or h.blocked(6)!="": return
	var pool: Array=[]
	for i in range(RIVAL_SCENES.size()): pool.append({"id":"people.rival:"+str(i),"family":"people.rival","text":RIVAL_SCENES[i][0],"scene":i})
	var scene := Novelty.pick(pool)
	if scene.is_empty(): h.done("🤝","A quiet boundary","No new rivalry scene is available. Promises, repair and practical support remain; no time was spent."); return
	if not h.pay("rival:"+FamilyChronicle.identity(GameState.npc(id)),1,0,6): return
	Novelty.note(scene)
	var choices: Array=RIVAL_SCENES[int(scene["scene"])][1].duplicate(); choices[2]=RIVAL_ALTERNATIVES[int(scene["scene"])]
	h.decision("people","rival",{"uid":FamilyChronicle.identity(GameState.npc(id)),"scene":scene["scene"],"choices":choices},str(GameState.npc(id)["first"])+" · old friction",str(scene["text"]),choices)
func promise(id: String, kind: String) -> void:
	if not valid(id) or not KINDS.has(kind): return
	var uid := FamilyChronicle.identity(GameState.npc(id))
	var existing := pending_promise(uid, kind)
	if not existing.is_empty():
		EventEngine.push_info("🤝", "Already promised", "%s is still waiting on this promise, due by %d." % [GameState.npc(id)["first"], int(existing["due"])])
		return
	if st()["promises"].size()>=40:
		var closed := -1
		for i in range(st()["promises"].size()-1,-1,-1):
			if st()["promises"][i]["state"]!="open": closed=i; break
		if closed==-1: return
		st()["promises"].remove_at(closed)
	if not h.pay("promise:"+uid+kind,0,0,6): return
	st()["promises"].push_front({"uid":uid,"name":GameState.npc(id)["first"],"kind":kind,"due":GameState.year_now()+1,"state":"open"})
	if st()["promises"].size()>40: st()["promises"].resize(40)
	h.done("🤝","Promise recorded","%s · %s. Keep it by %d; fulfilling it costs 1 time and %s." % [GameState.npc(id)["first"],KINDS[kind][0],GameState.year_now()+1,GameState.fmt_money(Actions._cost(int(KINDS[kind][1])))])
func pending_promise(uid: String, kind: String) -> Dictionary:
	for item in st()["promises"]:
		if str(item.get("uid", ""))==uid and str(item.get("kind", ""))==kind and str(item.get("state", ""))=="open": return item
	return {}
func fulfil(index: int) -> void:
	if index<0 or index>=st()["promises"].size(): return
	var p: Dictionary=st()["promises"][index]
	if str(p.get("state", ""))!="open": return
	var kind := str(p.get("kind", ""))
	if not KINDS.has(kind):
		p["state"]="ended"; p["conclusion"]="Closed because this saved promise has no recognised type."
		h.done("🤝","Promise record closed","This older promise could not be safely fulfilled.")
		return
	var id: String=h.person(str(p.get("uid", "")))
	if not valid(id):
		p["state"]="ended"; p["conclusion"]="Closed because the person was no longer available; no trust penalty was applied."
		h.done("🤝","Promise closed","%s is no longer available. The promise ended without blame or a trust penalty." % str(p.get("name", "This person")))
		return
	var person_label: String = h.person_name(str(p.get("uid", "")),str(p.get("name", "They")))
	if GameState.year_now()>int(p.get("due", -1)):
		p["state"]="broken"; p["conclusion"]="The deadline passed before it was fulfilled."
		st()["reliability"]=maxf(0,float(st()["reliability"])-5)
		BondStats.apply(id,{"trust":-8,"respect":-4,"resentment":5})
		FamilyChronicle.remember(id,"A promise was not kept.","bad")
		h.modules["pathways"].record("people","broken:"+str(p.get("uid",""))+":"+kind+":"+str(p.get("due",0)),"General",30,false,str(p.get("uid","")))
		h.done("🤝","Deadline passed",person_label+" remembers the missed commitment. Reliability −5; trust and respect fell.")
		return
	if not h.pay("fulfil:"+str(p.get("uid", ""))+kind,1,Actions._cost(int(KINDS[kind][1])),6): return
	p["state"]="kept"; st()["reliability"]=minf(100,float(st()["reliability"])+3)
	BondStats.apply(id,{"trust":5,"respect":3,"resentment":-2})
	p["conclusion"]="Kept by following through."
	FamilyChronicle.remember(id,"Kept a promise: "+str(KINDS[kind][0]),"good")
	h.modules["pathways"].record("people",str(p.get("uid", ""))+":"+kind+":"+str(p.get("due",0)),"General",80,true,str(p.get("uid", "")))
	h.done("🤝","Kept my word",person_label+" remembers that I followed through. Trust grows through actions.",{"happiness":2})
func repair(id: String) -> void:
	if not valid(id) or (BondStats.get_stat(id,"trust")>=65 and BondStats.get_stat(id,"resentment")<10): return
	var uid := FamilyChronicle.identity(GameState.npc(id))
	if not h.pay("repair:"+uid,1,0,6): return
	var r: Dictionary=st()["repair"].get(uid,{"steps":0,"last":-1})
	r["steps"]=int(r["steps"])+1; r["last"]=GameState.year_now(); st()["repair"][uid]=r
	var gain := 2 if int(r["steps"])<3 else 5
	BondStats.apply(id,{"trust":gain,"resentment":-gain,"respect":1})
	FamilyChronicle.remember(id,"Tried to repair trust through listening and consistent behaviour.")
	h.done("🌿","Repair takes time","%s · %d conversations across years. Trust +%d; resentment −%d. They do not owe me forgiveness." % [GameState.npc(id)["first"],r["steps"],gain,gain])
func co_parent(id: String, kind: String) -> void:
	if not valid(id): h.done("👪","Care plan unavailable","This child is no longer available. No plan or cost was changed."); return
	if kind not in ["shared","primary","weekends"] or GameState.npc(id)["relation"] not in ["child","stepchild"] or int(GameState.npc(id)["age"])>=18: return
	if not h.pay("coparent:"+FamilyChronicle.identity(GameState.npc(id)),1,0,18): return
	var uid := FamilyChronicle.identity(GameState.npc(id))
	st()["agreements"][uid]={"kind":kind,"year":GameState.year_now(),"reviewed":GameState.year_now(),"visits":0}
	h.done("👪","Care plan",str(GameState.npc(id)["first"])+" · "+kind+" care. Annual child-support costs and contact follow this plan; regular review matters.")
func support_factor(id: String) -> float:
	var uid := str(GameState.npc(id).get("person_uid","")); var a: Dictionary=st()["agreements"].get(uid,{})
	return {"shared":0.65,"primary":1.0,"weekends":0.4}.get(str(a.get("kind","primary")),1.0)
func contact(id: String) -> void:
	if not valid(id): return
	var uid := FamilyChronicle.identity(GameState.npc(id))
	if not st()["agreements"].has(uid) or not h.pay("contact:"+uid,1,0,18): return
	st()["agreements"][uid]["reviewed"]=GameState.year_now(); st()["agreements"][uid]["visits"]=int(st()["agreements"][uid]["visits"])+1
	BondStats.apply(id,{"trust":3,"affection":4}); h.done("👪","Time together","The care plan was reviewed and time together recorded.")
func yearly() -> void:
	if Lives.separate(): return
	var year := GameState.year_now()
	settle_moments(year); autonomously_progress(year)
	for id in GameState.npcs:
		var n: Dictionary=GameState.npc(id)
		if n.get("alive",false) and n.has("motive") and n["relation"] in ["friend","best_friend"] and year>int(n["motive"]["last_contact"])+3: BondStats.apply(id,{"affection":-1})
	for p in st()["promises"]:
		if str(p.get("state", ""))!="open": continue
		var id: String=h.person(str(p.get("uid", "")))
		var promise_name: String = h.person_name(str(p.get("uid", "")),str(p.get("name", "The person")))
		if not valid(id):
			p["state"]="ended"; p["conclusion"]="Closed because the person was no longer available; no trust penalty was applied."
			h.note("Promise closed",promise_name+" was no longer available. No trust penalty was applied.")
			continue
		if year>int(p.get("due", -1)):
			p["state"]="broken"; p["conclusion"]="The deadline passed before it was fulfilled."
			st()["reliability"]=maxf(0,float(st()["reliability"])-5)
			BondStats.apply(id,{"trust":-8,"respect":-4,"resentment":5}); FamilyChronicle.remember(id,"A promise was not kept.","bad")
			h.modules["pathways"].record("people","broken:"+str(p.get("uid", ""))+":"+str(p.get("kind", ""))+":"+str(p.get("due",0)),"General",30,false,str(p.get("uid", "")))
			h.note("Broken promise",promise_name+" remembers the missed commitment.")
	for uid in st()["agreements"]:
		var id: String=h.person(str(uid)); var a: Dictionary=st()["agreements"][uid]
		if valid(id) and int(GameState.npc(id)["age"])<18 and year>int(a["reviewed"])+1:
			BondStats.apply(id,{"affection":-2,"trust":-2}); h.note("Care plan needs attention",str(GameState.npc(id)["first"])+" has had little planned contact recently.")
	if int(GameState.player["age"])<6 or not h.state()["prompt"].is_empty(): return
	var friends := GameState.npcs_with("friend")+GameState.npcs_with("best_friend")
	if friends.is_empty() or randf()>0.18: return
	var id := str(friends.pick_random()); var uid := FamilyChronicle.identity(GameState.npc(id))
	if year-int(st()["requests"].get(uid,year-4))<3: return
	st()["requests"][uid]=year
	var pool: Array=[]
	for i in range(REQUESTS.size()):
		if i==1 and int(GameState.npc(id)["age"])<18: continue
		pool.append({"id":"people.invitation:"+str(i),"family":"people.invitation","text":REQUESTS[i]})
	var scene := Novelty.pick(pool)
	if scene.is_empty(): return
	Novelty.note(scene)
	var context: String=scene["text"]
	h.decision("people","invitation",{"uid":uid,"name":str(GameState.npc(id)["first"]),"context":context},"A friend reaches out",str(GameState.npc(id)["first"])+" "+context+". They have a life beyond my story.",[{"label":"Make time","requires":{"time":1}},"Explain my limits","Ignore the message"])
func resolve(op: String, args: Dictionary, answer: int) -> void:
	if op=="moment":
		var id: String=h.person(str(args["uid"]))
		if not valid(id): h.done("🤝","Moment ended","That person is no longer available. No relationship effect was applied."); return
		if answer not in [0,1,2]: return
		answer=int(args["order"][answer])
		var scene: Dictionary=args["scene"]; var m := motive(id)
		var fit: bool=answer==({"learning":0,"stability":0,"quiet":1,"belonging":2}.get(str(m["goal"]),2))
		BondStats.apply(id,{"trust":3 if fit else 1,"affection":1 if answer==0 else 2})
		GameState.apply_effects(scene["effects"][answer])
		var person_effects: Array=scene.get("person_effects",scene.get("effects",[]))
		var person_change := apply_person_effects(id,person_effects[answer] if answer<person_effects.size() else {})
		m["last_contact"]=GameState.year_now()
		if fit: m["progress"]=mini(3,int(m["progress"])+1)
		FamilyChronicle.remember(id,str(scene["endings"][answer]),"good")
		st()["moments"].append({"uid":args["uid"],"name":str(GameState.npc(id)["first"]),"due":GameState.year_now()+1,"later":scene["later"][answer],"fit":fit,"state":"open"})
		if st()["moments"].size()>24: st()["moments"].pop_front()
		h.done("🤝","Time together",str(scene["endings"][answer])+" "+("That suited their current priority." if fit else "Their own priority is still "+str(GOALS[m["goal"]][0]).to_lower()+".")+person_change)
		return
	if op=="rival":
		var id: String=h.person(str(args["uid"]))
		if not valid(id): h.note("Contact ended","The person is no longer available; no relationship reward was applied."); return
		var gain := int(RIVAL_SCENES[int(args["scene"])][2][answer])
		if args.has("choices") and answer==2: gain=1
		BondStats.apply(id,{"trust":gain,"respect":3 if args.has("choices") and answer==2 else gain,"resentment":-gain})
		if args.has("choices"): GameState.change_stat("stress",1 if answer==0 else -1 if answer==1 else 0)
		FamilyChronicle.remember(id,str(args.get("choices",RIVAL_SCENES[int(args["scene"])][1])[answer])+" after an earlier disagreement.")
		var repair0: Dictionary=st()["repair"].get(str(args["uid"]),{"steps":0,"last":-1})
		if gain>1: repair0["steps"]+=1; repair0["last"]=GameState.year_now(); st()["repair"][str(args["uid"])]=repair0
		if GameState.npc(id)["relation"] in ["rival","enemy"] and int(repair0["steps"])>=3 and BondStats.get_stat(id,"trust")>=60 and BondStats.get_stat(id,"resentment")<25: GameState.npc(id)["relation"]="friend"
		h.done("🤝","A continuing relationship","Trust %+.0f. Three consistent repairs and sufficient trust can turn a rivalry into a friendship; one conversation cannot guarantee it." % gain)
		return
	if op!="invitation": return
	var id: String=h.person(str(args["uid"]))
	if not valid(id): h.done("🤝","Invitation ended",str(args.get("name", "That person"))+" is no longer available. Your choice had no relationship effect."); return
	if answer==0 and int(GameState.player["time_left"])>0:
		GameState.spend_time(1); BondStats.apply(id,{"affection":4,"trust":3}); h.done("🤝","Showed up","Time together strengthened the friendship.",{"happiness":2})
	elif answer==0:
		BondStats.apply(id,{"affection":-2,"trust":-1}); h.done("🤝","Could not make it","I ran out of time before I could show up. The missed invitation disappointed them.")
	elif answer==1: BondStats.apply(id,{"respect":2}); h.done("🤝","An honest limit","I explained what I could manage. We left the invitation open.")
	else: BondStats.apply(id,{"affection":-3,"trust":-2}); h.done("📭","Silence","The unanswered message remains part of this friendship.")
func menu(key: String) -> Dictionary:
	if key in ["", "root"]:
		var open_count := 0
		for promise in st()["promises"]:
			if str(promise.get("state", ""))=="open": open_count+=1
		var rows: Array=[h.nav("people","Promises & plans","%d open · recent outcomes" % open_count,"promises"),h.nav("parenting","Parenting & childcare","Age-specific decisions and yearly routines"),h.nav("pathways","Connections","Named people and next-year follow-ups")]
		return {"title":"People & commitments","icon":"🤝","info":["Relationships stay on the People screen.","Reliability %d/100 · %d open promise(s)." % [int(st()["reliability"]),open_count]],"rows":rows}
	if key=="promises": return _promise_menu()
	if not key.begins_with("person:"): return menu("")
	var rows: Array=[h.nav("people","Promises & plans","Open commitments and recent outcomes","promises")]
	var info: Array=[]
	if key.begins_with("person:"):
		var id := key.substr(7)
		if valid(id):
			info=[str(GameState.npc(id)["first"])+" · trust %d · respect %d · resentment %d" % [BondStats.get_stat(id,"trust"),BondStats.get_stat(id,"respect"),BondStats.get_stat(id,"resentment")]]
			var m := motive(id)
			info.append("Their goal: %s · progress %d/3 · practical favours %d. %s" % [GOALS[m["goal"]][0],m["progress"],m["favours"],"They value space." if m["goal"]=="quiet" else "They welcome a limited offer of help."])
			if m.has("last_action"): info.append(str(m["last_action"]))
			var person_uid := FamilyChronicle.identity(GameState.npc(id))
			if int(GameState.npc(id)["age"])>=6:
				var moment_key := "moment:"+person_uid
				var moment_scene_available := scenes.any(func(s): return int(s["min_age"])<=mini(int(GameState.npc(id)["age"]),int(GameState.player["age"])) and Novelty.eligible(s))
				var moment_reason := action_reason(moment_key,1,0,6)
				var moment_sub := "1 time · a fresh scene · preferences matter" if moment_scene_available else "No fresh moment available"
				if moment_reason!="": moment_sub=moment_reason
				rows.append(h.row("people","Share a moment",moment_sub,"moment",id,moment_scene_available and moment_reason==""))
			for approach in range(3):
				var goal_cost := Actions._cost(40) if approach==0 else 0
				var goal_reason := action_reason("goal:"+person_uid,1,goal_cost,6)
				if int(GameState.npc(id)["age"])<6: goal_reason="Available when they are 6+"
				var goal_sub: String = "1 time · "+GameState.fmt_money(goal_cost)+" · "+["effort helps their goal","less stress; some prefer space","new ideas; more effort"][approach]
				if goal_reason!="": goal_sub=goal_reason
				rows.append(h.row("people",["Help with their goal","Give them space","Suggest another approach"][approach],goal_sub,"goal",[id,approach],goal_reason==""))
			var favour_reason := action_reason("favour:"+person_uid,0,0,6)
			var favour_sub := "Use one saved favour · fatigue −5" if int(m["favours"])>0 else "No saved favours"
			if favour_reason!="": favour_sub=favour_reason
			rows.append(h.row("people","Ask for practical help",favour_sub,"favour",id,int(m["favours"])>0 and favour_reason==""))
			if GameState.npc(id)["relation"] in ["rival","enemy","ex","friend","best_friend"]:
				var fresh_rival := false
				for i in range(RIVAL_SCENES.size()):
					var candidate_scene := {"id":"people.rival:"+str(i),"family":"people.rival","text":RIVAL_SCENES[i][0]}
					if Novelty.eligible(candidate_scene): fresh_rival=true; break
				var rival_reason := action_reason("rival:"+person_uid,1,0,6)
				var rival_sub := "1 time · a fresh disagreement or repair" if fresh_rival else "No fresh scene available"
				if rival_reason!="": rival_sub=rival_reason
				rows.append(h.row("people","Address old friction",rival_sub,"rival",id,fresh_rival and rival_reason==""))
			for kind in KINDS:
				var pending := pending_promise(person_uid,str(kind))
				var promise_sub := "Promise now; fulfil by next year" if pending.is_empty() else "Already promised · due %d" % int(pending["due"])
				var promise_reason := action_reason("promise:"+person_uid+str(kind),0,0,6)
				if promise_reason!="" and pending.is_empty(): promise_sub=promise_reason
				rows.append(h.row("people",KINDS[kind][0],promise_sub,"promise",[id,kind],pending.is_empty() and promise_reason==""))
			var repair_reason := action_reason("repair:"+person_uid,1,0,6)
			var repair_needed := BondStats.get_stat(id,"trust")<65 or BondStats.get_stat(id,"resentment")>=10
			var repair_sub := "1 time · steady effort builds trust" if repair_needed else "No repair needed; trust is steady"
			if repair_reason!="": repair_sub=repair_reason
			rows.append(h.row("people","Repair trust",repair_sub,"repair",id,repair_needed and repair_reason==""))
			if GameState.npc(id)["relation"] in ["child","stepchild"] and int(GameState.npc(id)["age"])<18:
				var child_uid := FamilyChronicle.identity(GameState.npc(id))
				var care_plan: Dictionary=st()["agreements"].get(child_uid,{})
				var shares := {"shared":65,"primary":100,"weekends":40}
				var plan_reason := action_reason("coparent:"+child_uid,1,0,18)
				var plan_change_available := plan_reason==""
				if care_plan.is_empty(): info.append("Care plan · standard support share · no custom contact plan")
				else: info.append("Care plan · %s · %d%% support share · reviewed %d · %d visits" % [str(care_plan.get("kind", "primary")).capitalize(),int(shares.get(str(care_plan.get("kind", "primary")),100)),int(care_plan.get("reviewed",GameState.year_now())),int(care_plan.get("visits",0))])
				for kind in ["shared","primary","weekends"]:
					var selected: bool = str(care_plan.get("kind", ""))==kind
					var plan_sub := "1 time · "+str(shares[kind])+"% support share"
					if plan_reason!="": plan_sub=plan_reason
					rows.append(h.row("people",("Current · " if selected else "Set ")+kind.capitalize()+" care",plan_sub,"care",[id,kind],not selected and plan_change_available))
				var visit_reason := action_reason("contact:"+child_uid,1,0,18)
				var visit_available := not care_plan.is_empty() and visit_reason==""
				var visit_sub := "1 time · review plan and maintain the bond" if not care_plan.is_empty() else "Set a care plan first"
				if visit_reason!="": visit_sub=visit_reason
				rows.append(h.row("people","Review care & visit",visit_sub,"contact",id,visit_available))
	var page_title := "People & commitments"
	if valid(key.substr(7)): page_title="Commitments · "+str(GameState.npc(key.substr(7)).get("first", "Person"))
	return {"title":page_title,"icon":"🤝","info":info,"rows":rows}

func _promise_menu() -> Dictionary:
	var rows: Array=[]; var info: Array=["Reliability %d/100 · keep promises by their due year." % int(st()["reliability"])]
	var closed_count := 0; var open_count := 0
	for i in range(st()["promises"].size()):
		var p: Dictionary=st()["promises"][i]
		var status := str(p.get("state", "open"))
		var kind := str(p.get("kind", ""))
		var kind_info: Array=KINDS.get(kind,["Promise",0])
		if status!="open":
			closed_count+=1
			if closed_count>4: continue
			var past_name: String = h.person_name(str(p.get("uid", "")),str(p.get("name", "Someone")))
			info.append(past_name+" · "+str(kind_info[0])+" · "+status+" · "+str(p.get("conclusion", "Recorded in history.")))
			continue
		open_count+=1
		var target_id: String = h.person(str(p.get("uid", "")))
		var available := valid(target_id)
		var due := int(p.get("due", -1))
		var cost := Actions._cost(int(kind_info[1]))
		var action_ready: bool = available and GameState.year_now()<=due and h.blocked(6)=="" and not h.used("fulfil:"+str(p.get("uid", ""))+kind) and int(GameState.player["time_left"])>=1 and int(GameState.player["money"])>=cost
		var subtitle := "Due by %d · 1 time · %s" % [due,GameState.fmt_money(cost)]
		if not available: subtitle="Person unavailable · closes without blame"
		elif GameState.year_now()>due: subtitle="Overdue · trust and reliability at risk"
		elif int(GameState.player["time_left"])<1: subtitle="Due by %d · need 1 time" % due
		elif int(GameState.player["money"])<cost: subtitle="Due by %d · need %s" % [due,GameState.fmt_money(cost)]
		var promise_name: String = h.person_name(str(p.get("uid", "")),str(p.get("name", "Someone")))
		rows.append(h.row("people",promise_name+" · "+str(kind_info[0]),subtitle,"fulfil",i,action_ready or (available and GameState.year_now()>due and h.blocked(6)=="")))
	if open_count==0: info.append("No open promises. Choose a person on the People screen to make one.")
	return {"title":"Promises & plans","icon":"🤝","info":info,"rows":rows}
func act(key: String, arg: Variant) -> void:
	match key:
		"moment": moment(str(arg))
		"goal": help_goal(str(arg[0]),int(arg[1]))
		"favour": favour(str(arg))
		"rival": rivalry(str(arg))
		"promise": promise(str(arg[0]),str(arg[1]))
		"fulfil": fulfil(int(arg))
		"repair": repair(str(arg))
		"care": co_parent(str(arg[0]),str(arg[1]))
		"contact": contact(str(arg))
