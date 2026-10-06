extends RefCounted
var h
var scenes: Array=[]
const LABELS := {"school":"School connections","work":"Work connections","enterprise":"Client & public connections","people":"Remembered help"}
func _init(hub):
	h=hub; scenes=ContentDB._load_json("res://data/pathway_scenes.json",[])
func st() -> Dictionary:
	return h.section("pathways",{"serial":0,"seen":{},"cases":[],"contacts":{},"last_year":-1})
func valid(id: String) -> bool:
	return GameState.npcs.has(id) and GameState.npc(id).get("alive",false) and GameState.npc(id).get("species","human")=="human"
func contact(domain: String, field: String, witness: String) -> String:
	var id: String=h.person(witness)
	if valid(id): return id
	var key := domain+":"+field
	id=h.person(str(st()["contacts"].get(key,"")))
	if valid(id): return id
	var peers: Array=Workplace.crew() if domain=="work" else []
	for other in peers:
		if valid(str(other)) and int(GameState.npc(str(other))["age"])>=18:
			id=str(other); break
	if not valid(id): id=GameState.create_npc("friend",{"age":int(GameState.player["age"]),"closeness":55})
	var n := GameState.npc(id); n["pathway_field"]=field; n["pathway_role"]=domain
	st()["contacts"][key]=FamilyChronicle.identity(n)
	return id
func record(domain: String, source: String, field: String, quality: float, honest: bool=true, witness: String="") -> void:
	if not LABELS.has(domain) or Lives.separate() or not GameState.is_alive(): return
	if witness!="" and not valid(h.person(witness)): return
	var key := domain+":"+source
	if st()["seen"].has(key): return
	st()["seen"][key]=true
	# Keep pending decisions; trim only concluded history.
	if st()["cases"].size()>=64:
		for i in range(st()["cases"].size()-1,-1,-1):
			if st()["cases"][i]["state"] in ["closed","expired","ended"]: st()["cases"].remove_at(i); break
	if st()["cases"].size()>=64: return
	var id := contact(domain,field,witness)
	st()["serial"]=int(st()["serial"])+1
	var year := GameState.year_now()
	st()["cases"].push_front({"id":int(st()["serial"]),"domain":domain,"source":source,"field":field,"quality":quality,"honest":honest,"uid":FamilyChronicle.identity(GameState.npc(id)),"name":GameState.npc(id)["first"],"year":year,"due":year+1,"expires":year+3,"state":"open","support_until":-1,"conclusion":""})
	FamilyChronicle.remember(id,"Discussed an earlier "+LABELS[domain].to_lower()+" commitment in "+field+".")
	h.note("A connection carries forward",str(GameState.npc(id)["first"])+" remembers the work. A follow-up opens next year in Connections.")
func find_case(serial: int) -> Dictionary:
	for entry in st()["cases"]:
		if int(entry["id"])==serial: return entry
	return {}
func price(entry: Dictionary) -> int:
	return 0 if Childhood.supported() or entry["domain"] in ["school","people"] else Actions._cost(120)
func follow(serial: int) -> void:
	var entry := find_case(serial)
	if entry.is_empty() or entry["state"]!="open" or GameState.year_now()<int(entry["due"]) or GameState.year_now()>int(entry["expires"]): return
	var id: String=h.person(str(entry["uid"]))
	if not valid(id):
		entry["state"]="ended"; entry["conclusion"]="The person is no longer available."
		h.done("🤝","Connection ended","%s is no longer available. No time or relationship change was applied." % str(entry.get("name", "This person")))
		return
	var pool := scenes.filter(func(scene): return scene["domain"]==entry["domain"] and (scene.get("fields",[]).is_empty() or scene["fields"].has(entry["field"])) and bool(scene["repair"])==(not entry["honest"] or float(entry["quality"])<65))
	var scene := Novelty.pick(pool)
	if scene.is_empty():
		entry["state"]="closed"; entry["conclusion"]="There is no new follow-up today. Your earlier work remains in your history."
		return
	if not h.pay("pathway_follow",1,price(entry),6): return
	if price(entry)>0: Employment.record_expense("Connection follow-up",price(entry))
	Novelty.note(scene)
	var chance := Aptitude.chance(0.48+float(entry["quality"])/500.0,"education" if entry["domain"]=="school" else "work")
	entry["scene"]=scene; entry["chance"]=chance
	var order: Array=[0,1,2]; order.shuffle()
	var contact_name: String = h.person_name(str(entry["uid"]),str(entry.get("name", "The contact")))
	h.decision("pathways","follow",{"id":serial,"order":order},contact_name+" · "+str(scene["title"]),str(scene["text"]).replace("{name}",contact_name)+"\nReady to follow through: %d%%." % int(chance*100),order.map(func(i): return scene["answers"][i]))
func resolve(op: String, args: Dictionary, answer: int) -> void:
	if op!="follow" or answer not in [0,1,2]: return
	answer=int(args.get("order",[0,1,2])[answer])
	var entry := find_case(int(args["id"]))
	if entry.is_empty() or entry["state"]!="open" or not entry.has("scene"): return
	var id: String=h.person(str(entry["uid"]))
	if not valid(id):
		entry["state"]="ended"; entry["conclusion"]="Contact ended before the decision."
		h.done("🤝","Connection ended","%s is no longer available. Your choice had no relationship effect." % str(entry.get("name", "This person")))
		return
	var success: bool=answer==0 and randf()<float(entry["chance"])
	var trust := (5 if success else 2) if answer==0 else 1 if answer==1 else -7
	BondStats.apply(id,{"trust":trust,"respect":2 if answer<2 else -4,"resentment":3 if answer==2 else -1})
	GameState.apply_effects({"stress":2 if answer==0 else -1 if answer==1 else 4})
	entry["answer"]=answer; entry["success"]=success; entry["state"]="followup"; entry["settle"]=GameState.year_now()+1
	entry["choice"]=entry["scene"]["answers"][answer]
	FamilyChronicle.remember(id,str(entry["choice"]),"bad" if answer==2 else "good")
	h.done("🤝","A decision remembered","Trust %+.0f. The follow-up settles next year; support is earned through the result." % trust)
func settle(p: Dictionary, year: int) -> void:
	var id: String=h.person(str(p["uid"]))
	if not valid(id):
		p["state"]="ended"; p["conclusion"]="The person is no longer available. This connection has ended without a follow-up effect."
		h.note(str(p.get("name", "Connection"))+" · follow-up ended",str(p["conclusion"]))
		if id!="": FamilyChronicle.remember(id,str(p["conclusion"]))
		return
	var scene: Dictionary=p["scene"]; var answer := int(p["answer"])
	p["conclusion"]=str(scene["endings"][answer]) if answer!=0 or p["success"] else str(scene["partial"])
	p["state"]="closed"; p["closed"]=year
	if p["success"]:
		p["support_until"]=int(p["settle"])+2
		if p["field"]!="General": Market.learn(str(p["field"]),1)
		BondStats.apply(id,{"trust":2})
		var motive: Dictionary=h.modules["people"].motive(id)
		motive["progress"]=mini(3,int(motive["progress"])+1)
	elif answer==2: BondStats.apply(id,{"trust":-3})
	FamilyChronicle.remember(id,str(p["conclusion"]),"bad" if answer==2 else "good")
	h.note(h.person_name(str(p.get("uid", "")),str(p.get("name", "Connection")))+" · follow-up",str(p["conclusion"]))
func yearly() -> void:
	if Lives.separate(): return
	var year := GameState.year_now()
	if int(st()["last_year"])>=year: return
	st()["last_year"]=year
	for p in st()["cases"]:
		if p["state"] in ["open","followup"] and not valid(h.person(str(p["uid"]))):
			p["state"]="ended"; p["conclusion"]="The contact ended before the follow-up. No relationship effect was applied."
			h.note(str(p.get("name", "Connection"))+" · connection ended",str(p["conclusion"]))
			continue
		if p["state"]=="followup" and year>=int(p["settle"]): settle(p,year)
		elif p["state"]=="open" and year>int(p["expires"]):
			p["state"]="expired"; p["conclusion"]="The invitation passed; you had not committed to attending."
func support(field: String) -> float:
	if Lives.separate() or GameState.in_prison(): return 0.0
	for p in st()["cases"]:
		if p["state"]!="closed" or not p.get("success",false) or str(p["field"])!=field or int(p["support_until"])<=GameState.year_now(): continue
		var id: String=h.person(str(p["uid"]))
		if valid(id) and BondStats.get_stat(id,"trust")>=60: return 0.04
	return 0.0
func menu(_key: String) -> Dictionary:
	var rows: Array=[]; var info: Array=["One follow-up a year. Named people, choices and conclusions stay saved.","Trusted support: a small relevant chance bonus for two years. Never stacks."]
	for p in st()["cases"]:
		if p["state"]=="open":
			var contact_name: String = h.person_name(str(p.get("uid", "")),str(p.get("name", "The contact")))
			rows.append(h.row("pathways",contact_name+" · "+LABELS[p["domain"]],"Due %d · 1 time · %s" % [p["due"],GameState.fmt_money(price(p))],"follow",p["id"],GameState.year_now()>=int(p["due"]) and not h.used("pathway_follow") and h.blocked(6)=="" and GameState.player["time_left"]>=1 and GameState.player["money"]>=price(p)))
		else: info.append(h.person_name(str(p.get("uid", "")),str(p.get("name", "Connection")))+" · "+str(p["state"])+" · "+("Conclusion due "+str(p.get("settle", "")) if p["state"]=="followup" else str(p.get("conclusion", "Recorded in history."))))
		if p.get("success",false) and int(p.get("support_until",-1))>GameState.year_now():
			var id: String=h.person(str(p["uid"]))
			if valid(id): info.append(str(p["field"])+" support · trust %d/60 · until %d" % [BondStats.get_stat(id,"trust"),p["support_until"]])
	return {"icon":"🤝","title":"Connections & follow-through","info":info,"rows":rows}
func act(key: String, arg: Variant) -> void:
	if key=="follow": follow(int(arg))

func background(n: Dictionary, year: int) -> void:
	var saved: Dictionary=n.get("playable_player",{})
	var plans: Dictionary=saved.get("journey",{}).get("pathways",{})
	if plans.is_empty() or int(plans.get("last_year",-1))>=year: return
	plans["last_year"]=year
	for p in plans.get("cases",[]):
		if str(p.get("state", "")) not in ["open", "followup"]: continue
		var target_status: Dictionary=h.person_status(str(p.get("uid", "")))
		var id := str(target_status.get("id", ""))
		var target_available := str(target_status.get("state", "missing"))=="alive" and (id=="player" or valid(id))
		if not target_available:
			p["state"]="ended"; p["conclusion"]="The contact ended while life continued; no follow-up effect was applied."
			var contact_name: String = h.person_name(str(p.get("uid", "")),str(p.get("name", "The contact")))
			h.background_note(saved,year,str(n["first"])+" · follow-up ended",contact_name+" is no longer available. The connection ended without blame.")
			var maker_id := str(n.get("id", ""))
			if maker_id!="": FamilyChronicle.remember(maker_id,"A connection with "+contact_name+" ended when life changed.")
			if id not in ["", "player"]: FamilyChronicle.remember(id,"A follow-up with "+str(n["first"])+" ended when life changed.")
			continue
		if p["state"]=="open":
			if year>int(p.get("expires",-1)):
				p["state"]="expired"; p["conclusion"]="The invitation passed; you had not committed to attending."
				h.background_note(saved,year,str(n["first"])+" · invitation passed",h.person_name(str(p.get("uid", "")),str(p.get("name", "The contact")))+" did not receive a commitment before the invitation expired.")
				if str(n.get("id", ""))!="": FamilyChronicle.remember(str(n["id"]),"An invitation passed without a commitment.")
			continue
		if year<int(p.get("settle",year+1)): continue
		p["state"]="closed"; p["closed"]=year
		var scene: Dictionary=p.get("scene",{})
		var answer := clampi(int(p.get("answer",0)),0,2)
		if scene.has("endings") and scene["endings"].size()>answer and (answer!=0 or p.get("success",false)):
			p["conclusion"]=str(scene["endings"][answer])
		elif scene.has("partial"):
			p["conclusion"]=str(scene["partial"])
		else: p["conclusion"]="The connection settled after the earlier choice."
		if p.get("success",false):
			p["support_until"]=int(p.get("settle",year))+2
			if str(p.get("field", "General"))!="General":
				if not saved.has("professional_skills"): saved["professional_skills"]={}
				var field: String=str(p["field"])
				saved["professional_skills"][field]=mini(10,int(saved["professional_skills"].get(field,0))+1)
				n["professional_skills"]=saved["professional_skills"].duplicate(true)
		var log: Array=saved["journey"].get("journal",[])
		log.push_front({"year":year,"title":h.person_name(str(p.get("uid", "")),str(p.get("name", "Connection")))+" · follow-up","text":p["conclusion"]})
		if log.size()>80: log.resize(80)
		saved["journey"]["journal"]=log
		if id=="player": h.note(str(n["first"])+" · follow-up",str(p["conclusion"]))
		else: FamilyChronicle.remember(id,str(p["conclusion"]),"good" if p.get("success",false) else "neutral")
