extends RefCounted
## Plans belong to a parent; development and memories belong to the real child.
var h
var scenes: Array=[]
const PLANS := {"self":["Family routine",2,0],"shared":["Shared childcare",1,60],"professional":["Childcare support",1,400]}
func _init(hub):
	h=hub; scenes=ContentDB._load_json("res://data/parenting_scenes.json",[])
func st() -> Dictionary: return h.section("parenting",{"plans":{},"history":[],"followups":[],"last_year":-1})
func eligible(id: String) -> bool:
	var n := GameState.npc(id)
	return not n.is_empty() and n.get("relation","") in ["child","stepchild"] and n.get("alive",false) and n.get("species","human")=="human" and int(n["age"])<18
func preference(n: Dictionary) -> int:
	if not n.has("upbringing_style"): n["upbringing_style"]=absi(FamilyChronicle.identity(n).hash())%3
	return int(n["upbringing_style"])
func band(age: int) -> int: return 0 if age<6 else 1 if age<12 else 2
func helper() -> String:
	for id in GameState.npcs:
		var n := GameState.npc(id)
		if n.get("relation","") in ["partner","sibling","stepsibling"] and available(n): return str(id)
	return ""
func available(n: Dictionary) -> bool:
	return not n.is_empty() and n.get("alive",false) and int(n.get("age",0))>=18 and int(n.get("prison",0))==0 and float(n.get("health",100))>=55 and float(n.get("closeness",0))>=50
func arrange(id: String, kind: String) -> void:
	if not eligible(id) or not PLANS.has(kind): return
	var n := GameState.npc(id); var uid := FamilyChronicle.identity(n)
	# A practical schedule cannot overrule the existing custody arrangement.
	if n.get("custody","")=="ex": return
	var support := helper() if kind=="shared" else ""
	if kind=="shared" and support=="": return
	var fee := Actions._cost(int(PLANS[kind][2]))
	if not h.pay("childcare:"+uid,int(PLANS[kind][1]),fee,18): return
	Employment.record_expense("Childcare support",fee)
	st()["plans"][uid]={"uid":uid,"parent":h.uid(),"name":n["first"],"kind":kind,"helper":FamilyChronicle.identity(GameState.npc(support)) if support!="" else "","year":GameState.year_now(),"settled":-1,"state":"arranged","fee":fee}
	FamilyChronicle.remember(id,"Agreed a "+str(PLANS[kind][0]).to_lower()+".")
	h.done("👪","Childcare arranged","Paid for this year. Support is reviewed next year; renew yearly. Custody stays as agreed.")
func activity(id: String) -> void:
	if not eligible(id): return
	var n := GameState.npc(id); var uid := FamilyChronicle.identity(n)
	var scene := Novelty.pick(scene_pool(id))
	if scene.has("later") and not followup_space():
		h.done("👪","Follow-ups pending","Existing family follow-ups need their next yearly review. No time spent and no earlier commitment removed."); return
	if scene.is_empty() or not h.pay("parenting_activity:"+uid,1,0,18): return
	Novelty.note(scene)
	var order: Array=[0,1,2]; order.shuffle()
	var context: String=str(scene["text"]).replace("{name}",str(n["first"]))+"\nUsually prefers "+["clear routines","a flexible pace","their own choice"][preference(n)]+"."
	h.decision("parenting","activity",{"uid":uid,"band":band(int(n["age"])),"scene":scene,"order":order},str(n["first"])+" · "+str(scene["title"]),context,order.map(func(i): return scene["answers"][i]))
func scene_pool(id: String) -> Array:
	var n := GameState.npc(id)
	return scenes.filter(func(scene): return int(scene["band"])==band(int(n["age"])) and (n.get("custody","")!="ex" or not scene.get("requires_home",true)))
func followup_space() -> bool:
	var followups: Array=st()["followups"]
	while followups.size()>=32:
		var closed := -1
		for i in range(followups.size()-1,-1,-1):
			if str(followups[i].get("state","open"))!="open": closed=i; break
		if closed<0: return false
		followups.remove_at(closed)
	return true
func child_for(uid: String) -> Dictionary:
	return GameState.player if uid==h.uid() else GameState.npc(h.person(uid))
func develop(n: Dictionary, effects: Dictionary, text: String, parent: String, year: int) -> void:
	for key in effects:
		if n==GameState.player: GameState.change_stat(str(key),float(effects[key]))
		else:
			n[key]=clampf(float(n.get(key,50))+float(effects[key]),0,100)
			if not n.get("playable_player",{}).is_empty(): n["playable_player"]["stats"][key]=n[key]
	if not n.has("upbringing"): n["upbringing"]=[]
	n["upbringing"].push_front({"year":year,"parent":parent,"text":text})
	if n["upbringing"].size()>40: n["upbringing"].resize(40)
	if not n.get("playable_player",{}).is_empty(): n["playable_player"]["upbringing"]=n["upbringing"].duplicate(true)
func resolve(op: String, args: Dictionary, answer: int) -> void:
	if op!="activity" or answer not in [0,1,2]: return
	var id: String=h.person(str(args["uid"]))
	if not eligible(id) or band(int(GameState.npc(id)["age"]))!=int(args["band"]):
		h.done("👪","A changed situation","Your child has moved into a different stage of life."); return
	answer=int(args["order"][answer])
	var scene: Dictionary=args["scene"]; var result: String=scene["endings"][answer]
	develop(GameState.npc(id),scene["effects"][answer],result,h.uid(),GameState.year_now())
	var n := GameState.npc(id)
	var fit := preference(n)==answer if scene.get("tradeoff",false) else answer==0
	var legacy_harsh: bool=not scene.get("tradeoff",false) and answer==2
	BondStats.apply(id,{"trust":-3 if legacy_harsh else 3 if fit else 1,"affection":-1 if legacy_harsh else 2 if fit else 1})
	GameState.apply_effects(scene.get("parent_effects",[{},{},{}])[answer])
	if scene.has("later"):
		st()["followups"].append({"uid":args["uid"],"parent":h.uid(),"due":GameState.year_now()+1,"text":scene["later"][answer],"effects":scene.get("later_effects",[{},{},{}])[answer],"state":"open"})
	FamilyChronicle.remember(id,result,"bad" if legacy_harsh else "good")
	st()["history"].push_front({"year":GameState.year_now(),"uid":args["uid"],"title":scene["title"],"result":result})
	if st()["history"].size()>24: st()["history"].resize(24)
	h.done("👪","A parenting choice remembered",result+" Your child will remember this.")
func review(s: Dictionary, owner: Dictionary, year: int) -> void:
	if int(s.get("last_year",-1))>=year: return
	s["last_year"]=year
	for f in s.get("followups",[]):
		if f["state"]!="open" or year<int(f["due"]): continue
		var child := child_for(str(f["uid"]))
		f["state"]="closed"
		if child.is_empty() or not child.get("alive",false) or not owner.get("alive",false): f["state"]="ended"; continue
		develop(child,f["effects"],str(f["text"]),str(f["parent"]),year)
		if owner==GameState.player: h.note(str(child["first"])+" · a year later",str(f["text"]))
	for p in s.get("plans",{}).values():
		if p["state"] in ["ended","lapsed","interrupted"] or year<=int(p["year"]): continue
		var n := child_for(str(p["uid"]))
		if n.is_empty() or not n.get("alive",false) or int(n["age"])>=18 or not owner.get("alive",false): p["state"]="ended"; continue
		if year>int(p["year"])+1: p["state"]="lapsed"; continue
		if int(p["settled"])>=year: continue
		var helper_n := child_for(str(p["helper"]))
		if int(owner.get("prison",0))>0 or n.get("custody","")=="ex" or (p["kind"]=="shared" and not available(helper_n)): p["state"]="interrupted"; continue
		p["settled"]=year; p["state"]="supported"
		develop(n,{"health":1,"happiness":1},str(p["name"])+" had a supported childcare year.",str(p["parent"]),year)
		if owner==GameState.player:
			GameState.change_stat("stress",2 if p["kind"]=="self" else 0)
			var id: String=h.person(str(p["uid"]))
			if id!="": BondStats.apply(id,{"trust":2})
		else:
			var saved: Dictionary=owner.get("playable_player",{})
			if not saved.is_empty(): saved["stats"]["stress"]=clampf(float(saved["stats"]["stress"])+(2 if p["kind"]=="self" else 0),0,100)
func yearly() -> void:
	if not Lives.separate(): review(st(),GameState.player,GameState.year_now())
func background(n: Dictionary, year: int) -> void:
	var saved: Dictionary=n.get("playable_player",{})
	var plans: Dictionary=saved.get("journey",{}).get("parenting",{})
	if not plans.is_empty(): review(plans,n,year)
func menu(page: String) -> Dictionary:
	var rows: Array=[]; var info: Array=["Renew childcare yearly. Your choices shape your child's learning, mood and memories."]
	if page.begins_with("child:"):
		var id := page.substr(6)
		if eligible(id):
			var n := GameState.npc(id); var uid := FamilyChronicle.identity(n)
			info.append("Usually prefers "+["clear routines","a flexible pace","making their own choice"][preference(n)]+"; needs can still change.")
			info.append(str(n["first"])+" · age "+str(n["age"])+" · "+["Early routines","Learning independence","Trust and responsibility"][band(int(n["age"]))])
			rows.append(h.row("parenting","A parenting moment","1 time · once per child/year · fresh scenes","activity",id,not h.used("parenting_activity:"+uid) and scene_pool(id).any(func(scene): return Novelty.eligible(scene))))
			for followup in st()["followups"]:
				if str(followup["uid"])==uid and str(followup["state"])=="open": info.append("Next follow-up: "+str(followup["due"]))
			rows.append({"icon":Bonds.U_face(n),"name":"View "+str(n["first"])+"'s profile","sub":Bonds.quick_line(id),"menu":"bond:"+id})
			for kind in PLANS: rows.append(h.row("parenting",PLANS[kind][0],"%d time · %s · renew yearly" % [PLANS[kind][1],GameState.fmt_money(Actions._cost(int(PLANS[kind][2])))],"arrange",[id,kind],not h.used("childcare:"+uid) and n.get("custody","")!="ex" and (kind!="shared" or helper()!="")))
			var p: Dictionary=st()["plans"].get(uid,{})
			if not p.is_empty(): info.append(str(p["kind"])+" · "+str(p["state"])+" · arranged "+str(p["year"]))
			if n.get("custody","")=="ex": info.append("Visits and custody remain in People & commitments; childcare cannot override them.")
			rows.append(h.nav("people","Visits & co-parenting","Existing care agreement and contact","person:"+id))
	else:
		for id in GameState.npcs:
			if eligible(str(id)): rows.append(h.nav("parenting",str(GameState.npc(id)["first"]),"Childcare, decisions and development","child:"+str(id)))
		for entry in st()["history"].slice(0,8): info.append(str(entry["year"])+" · "+str(entry["title"])+" · "+str(entry["result"]))
		for entry in GameState.player.get("upbringing",[]).slice(0,8): info.append("My childhood · "+str(entry["text"]))
	return {"title":"Parenting & childcare","icon":"👪","rows":rows,"info":info}
func act(key: String, arg: Variant) -> void:
	match key:
		"arrange": if arg is Array: arrange(str(arg[0]),str(arg[1]))
		"activity": activity(str(arg))
