extends RefCounted
## Development records travel with the company; they do not transfer ownership.
var _op: WeakRef
var op:
	get: return _op.get_ref()
const LESSONS := [
	{"name":"Cash and payroll","question":"Sales look strong, but bills are due before customers pay. What should the trainee do?","answers":["Map due dates and protect payroll","Treat unpaid invoices as available cash","Draw the expected profit now"],"why":"Sales and usable cash arrive at different times."},
	{"name":"Customer handover","question":"The promised order will miss its deadline. What should the trainee do?","answers":["Explain the delay and agree a new scope","Keep quiet until the delivery date","Promise another order to cover the problem"],"why":"A clear revised promise preserves more trust than a hidden delay."},
	{"name":"Stock and supply","question":"A cheap large order exceeds storage capacity. What should the trainee do?","answers":["Compare demand, storage and payment dates","Buy everything because each unit is cheap","Ignore existing supply commitments"],"why":"Unit price alone does not show the stock and cash risks."}
]
func _init(operations): _op=weakref(operations)
func state(b: Dictionary) -> Dictionary:
	var s: Dictionary=op.st(b)
	if not s.has("people"): s["people"]={"plans":[],"history":[],"trainees":{},"used":{}}
	return s["people"]
func crew(b: Dictionary) -> Array:
	var ids: Array=[]
	for id in b.get("crew",[]):
		if GameState.npc(str(id)).get("alive",false): ids.append(str(id))
	if b==op.biz(): return ids
	for uid in b.get("crew_uids",[]):
		var id: String=op.h.person(str(uid))
		if id!="" and GameState.npc(id).get("alive",false) and not ids.has(id): ids.append(id)
	return ids
func train(id: String, kind: String) -> void:
	var b: Dictionary=op.biz()
	if b.is_empty() or kind not in ["quality","service"] or id not in crew(b): return
	var s := state(b); var uid := FamilyChronicle.identity(GameState.npc(id))
	if s["plans"].size()>=24: return
	if s["plans"].any(func(p): return p["uid"]==uid and p["state"]=="open"): return
	var key := "company_train:"+str(b["uid"])+":"+uid
	var fee := Actions._cost(180)
	if not op.h.pay(key,1,fee,18): return
	Employment.record_expense("Company staff development",fee)
	s["plans"].push_front({"uid":uid,"name":GameState.full_name(id),"kind":kind,"due":GameState.year_now()+1,"roll":randf(),"state":"open"})
	BondStats.apply(id,{"respect":2,"trust":2})
	FamilyChronicle.remember(id,"Agreed a "+kind+" development plan at "+str(b["name"])+".","good")
	op.h.done("👥","Development agreed","Review next year. Staff wellbeing, morale and the pay plan affect progress. No immediate skill or profit reward.")
func apprentice(id: String) -> void:
	var b: Dictionary=op.biz()
	if b.is_empty() or id not in GameState.npcs_with("child") or int(GameState.npc(id)["age"])<18: return
	var n := GameState.npc(id)
	if not n.get("business",n.get("playable_player",{}).get("business",{})).is_empty(): return
	var uid := FamilyChronicle.identity(n); var s := state(b)
	if not s["trainees"].has(uid) and s["trainees"].size()>=32: return
	if not s["trainees"].has(uid): s["trainees"][uid]={"stage":0,"readiness":0.0,"history":[],"completed":false}
	var trainee: Dictionary=s["trainees"][uid]
	if int(trainee["stage"])>=3 and float(trainee["readiness"])>=100: return
	var fee := Actions._cost(150)
	if not op.h.pay("company_apprentice:"+str(b["uid"])+":"+uid,1,fee,18): return
	Employment.record_expense("Successor preparation",fee)
	var lesson_index: int=int(trainee["stage"]) if int(trainee["stage"])<3 else int(trainee.get("revision",0))%3
	var lesson: Dictionary=LESSONS[lesson_index]
	var order: Array=[0,1,2]; order.shuffle()
	op.h.decision("operations","apprentice",{"owner":b["uid"],"uid":uid,"stage":trainee["stage"],"lesson":lesson_index,"order":order,"roll":randf()},str(n["first"])+" · "+str(lesson["name"]),str(lesson["question"])+"\nOne lesson per year · preparation does not give ownership.",order.map(func(i): return lesson["answers"][i]))
func resolve(args: Dictionary, answer: int) -> void:
	var b: Dictionary=op.biz()
	if b.is_empty() or str(b["uid"])!=str(args.get("owner","")): return
	var s := state(b); var uid: String=str(args.get("uid",""))
	var id: String=op.h.person(uid)
	if id=="" or id not in GameState.npcs_with("child") or int(GameState.npc(id)["age"])<18: return
	var trainee: Dictionary=s["trainees"].get(uid,{})
	if trainee.is_empty() or int(trainee["stage"])!=int(args["stage"]) or answer<0 or answer>2: return
	var correct: bool=int(args["order"][answer])==0
	var n := GameState.npc(id)
	var readiness: float=clampf(0.45+float(n.get("smarts",50))/300.0+Market.skill("Business")*0.025-float(n.get("stress",30))/500.0,0.2,0.9)
	var practised: bool=correct and float(args["roll"])<readiness
	trainee["readiness"]=minf(100,float(trainee["readiness"])+(34 if practised else 24 if correct else 8))
	trainee["history"].append({"year":GameState.year_now(),"lesson":LESSONS[int(args["lesson"])]["name"],"correct":correct,"practised":practised})
	trainee["stage"]=mini(3,int(trainee["stage"])+1)
	trainee["revision"]=int(trainee.get("revision",0))+1
	while trainee["history"].size()>12: trainee["history"].pop_front()
	trainee["completed"]=int(trainee["stage"])==3
	BondStats.apply(id,{"respect":3 if correct else 1})
	FamilyChronicle.remember(id,"Practised company responsibilities: "+str(LESSONS[int(args["lesson"])]["name"])+".")
	op.h.done("🌳","Lesson complete",str(LESSONS[int(args["lesson"])]["why"])+" Readiness %d/100 · lessons %d/3. %s" % [int(trainee["readiness"]),int(trainee["stage"]),"Practical work went well." if practised else "More supervised practice would help."])
func transition(b: Dictionary, id: String) -> void:
	var s := state(b); var uid := FamilyChronicle.identity(GameState.npc(id))
	var trainee: Dictionary=s["trainees"].get(uid,{})
	var prepared: bool=trainee.get("completed",false) and float(trainee.get("readiness",0))>=60
	op.st(b)["morale"]=clampf(float(op.st(b)["morale"])+(4 if prepared else -4),0,100)
	s["history"].push_front({"year":GameState.year_now(),"name":GameState.full_name(id),"result":"Prepared ownership handover" if prepared else "Handover needs practical support"})
	trim(s)
func review(b: Dictionary, year: int) -> void:
	var s := state(b)
	for p in s["plans"]:
		if p["state"]!="open" or year<int(p["due"]): continue
		p["state"]="closed"
		var id: String=op.h.person(str(p["uid"]))
		var result := "Person left or became unavailable; no company reward"
		if id!="" and id in crew(b):
			var n := GameState.npc(id)
			var chance: float=clampf(0.35+float(op.st(b)["morale"])/300.0+float(n.get("health",50))/500.0-float(n.get("stress",30))/400.0+(0.12 if op.st(b)["pay"]=="invest" else -0.08 if op.st(b)["pay"]=="minimum" else 0.0),0.15,0.9)
			var success: bool=float(p["roll"])<chance
			result="Training carried into daily work" if success else "Training needs a simpler workload"
			if success:
				if not n.has("company_skills"): n["company_skills"]={}
				n["company_skills"][p["kind"]]=mini(5,int(n["company_skills"].get(p["kind"],0))+1)
				if p["kind"]=="quality": b["quality"]=minf(100,float(b["quality"])+1)
				else: op.st(b)["loyalty"]=minf(100,float(op.st(b)["loyalty"])+1)
			FamilyChronicle.remember(id,str(b["name"])+": "+result,"good" if success else "neutral")
		p["result"]=result
		s["history"].push_front({"year":year,"name":p["name"],"result":result})
	s["plans"]=s["plans"].filter(func(p): return p["state"]=="open")
	trim(s)
func trim(s: Dictionary) -> void:
	while s["history"].size()>32: s["history"].pop_back()
func menu() -> Dictionary:
	var b: Dictionary=op.biz(); var s := state(b); var rows: Array=[]
	var info: Array=["Staff development · 1 time · "+GameState.fmt_money(Actions._cost(180)),"One plan per colleague per year · review next year"]
	for id in crew(b):
		var n := GameState.npc(str(id)); var uid := FamilyChronicle.identity(n)
		rows.append({"icon":Bonds.U_face(n),"name":GameState.full_name(str(id)),"sub":Bonds.quick_line(str(id))+" · quality %d/5 · service %d/5" % [int(n.get("company_skills",{}).get("quality",0)),int(n.get("company_skills",{}).get("service",0))],"menu":"bond:"+str(id)})
		var pending: bool=s["plans"].any(func(p): return p["uid"]==uid and p["state"]=="open")
		for kind in ["quality","service"]: rows.append(op.h.row("operations",kind.capitalize()+" coaching","1 time · "+GameState.fmt_money(Actions._cost(180)),"staff_train",[id,kind],s["plans"].size()<24 and not pending and not op.h.used("company_train:"+str(b["uid"])+":"+uid)))
	if rows.is_empty(): info.append("Hire a known contact through Business to develop a named team member.")
	for p in s["plans"]: info.append(str(p["name"])+" · "+str(p["kind"])+" · review "+str(p["due"]))
	for entry in s["history"].slice(0,6): info.append(str(entry["name"])+": "+str(entry["result"]))
	return {"title":"Company people","icon":"👥","info":info,"rows":rows}
