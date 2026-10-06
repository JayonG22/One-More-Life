extends RefCounted
var h
const PROJECTS := {
	"service":["A reliable small service","Business",300,1800,["A repeat customer wants a clear scope.","A supplier can deliver cheaply or reliably, but not both.","The customer questions a charge that was not in the agreement."]],
	"creative":["An original release","Arts",500,1600,["The collaborators need a brief and agreed credits.","Feedback says the work is distinctive but unfinished.","An audience wants the promised release, while a sponsor wants changes."]],
	"community":["A community promise","Politics",250,0,["Residents want a useful project, not another speech.","The accessible option costs more effort than the convenient one.","A public report must explain what was delivered and what was not."]],
	"royal":["A public royal duty","Politics",900,0,["The public asks whose needs this visit serves.","The household wants ceremony; residents need a practical commitment.","Publish the costs and outcomes, including the unfinished work."]]
}
const GOALS := {"belonging":"Keep meaningful ties for three years","learning":"Build practical skills and completed work","stability":"Maintain health and a cash cushion","service":"Complete useful public work","creative":"Finish an original release"}
func _init(hub): h=hub
func st() -> Dictionary: return h.section("enterprise",{"active":{},"history":[],"clients":{},"goal":{},"public_trust":50.0,"body_of_work":[],"contracts":0,"supplier":"reliable","pricing":"fair","cashflow":[],"last_year":-1})
func choose_goal(kind: String) -> void:
	if not GOALS.has(kind) or not h.pay("goal",0,0,18): return
	st()["goal"]={"kind":kind,"since":GameState.year_now(),"progress":0,"completed":false}
	h.done("🌱","A personal ambition",GOALS[kind]+". Wealth and fame are not required to make this life worthwhile.")
func startup_cost(kind: String) -> int:
	return Actions._cost(int(int(PROJECTS[kind][2])*(0.75 if st()["supplier"]=="cheap" else 1.0)))
func start(kind: String) -> void:
	if not PROJECTS.has(kind) or not st()["active"].is_empty() or (kind=="royal" and not Lives.is_type("royal")): return
	var pool: Array=ContentDB._load_json("res://data/enterprise_scenes.json",[]).filter(func(scene): return scene["kind"]==kind)
	var scenario := Novelty.pick(pool)
	if scenario.is_empty(): h.done("🌱","No fresh commitment","No new project is available today. Existing business work and personal ambitions are still open."); return
	if not h.pay("enterprise_start",1,startup_cost(kind),18): return
	st()["active"]={"kind":kind,"stage":0,"quality":40.0+h.modules["pathways"].support(str(PROJECTS[kind][1]))*100.0,"started":GameState.year_now(),"due":GameState.year_now()+2,"last":-1,"scope":"","credits":true,"supplier":st()["supplier"],"pricing":st()["pricing"]}
	var counterpart: String=h.modules["pathways"].contact("enterprise",str(PROJECTS[kind][1]),"")
	st()["active"]["witness"]=FamilyChronicle.identity(GameState.npc(counterpart))
	st()["active"]["counterpart"]=GameState.npc(counterpart)["first"]
	st()["active"]["scenario"]=scenario; st()["active"]["choices"]=[]; Novelty.note(scenario)
	h.done("📋","A real commitment",PROJECTS[kind][0]+" · plan, delivery and accountability. The deadline is "+str(GameState.year_now()+2)+"; abandoning it keeps the record and loses the startup cost.")
func step() -> void:
	var p: Dictionary=st()["active"]
	if p.is_empty() or not h.pay("enterprise_step:"+str(p["stage"]),1,0,18): return
	var kind := str(p["kind"]); var stage := int(p["stage"])
	var options := [["Agree scope, costs and credits","Promise a premium result at any cost","Keep it vague"],["Check quality and pay fairly","Use the cheapest option without checks","Ask for support and adjust openly"],["Deliver with a transparent report","Hide delays and claim all credit","Renegotiate the missing work"]]
	if p.has("scenario"):
		var scene: Dictionary=p["scenario"]["stages"][stage]
		h.decision("enterprise","step",{"kind":kind,"stage":stage},str(p["scenario"]["name"])+" · "+str(stage+1)+"/3",str(scene["question"])+"\nWorking with "+str(p.get("counterpart","a counterpart"))+".",scene["answers"])
		return
	h.decision("enterprise","step",{"kind":kind,"stage":stage},PROJECTS[kind][0]+" · "+str(stage+1)+"/3",PROJECTS[kind][4][stage],options[stage])
func resolve(op: String, args: Dictionary, answer: int) -> void:
	if op!="step": return
	var p: Dictionary=st()["active"]
	if p.is_empty() or p["kind"]!=args["kind"] or int(p["stage"])!=int(args["stage"]): return
	var stage := int(p["stage"]); var kind := str(p["kind"])
	var gain: int = [14,1,-5][answer] if stage==0 else [16,-12,8][answer] if stage==1 else [12,-15,4][answer]
	if p.has("scenario"):
		var scene: Dictionary=p["scenario"]["stages"][stage]
		gain=int(float(scene["gains"][answer])*(0.55+Aptitude.score("work")/200.0))
		p["choices"].append(str(scene["answers"][answer])); GameState.change_stat("stress",int(scene["stress"][answer]))
		if stage==2: p["credits"]=bool(scene["honest"][answer])
	if stage==1 and p["supplier"]=="cheap": gain-=5
	if stage==0: p["scope"]=["clear","premium","vague"][answer]
	if stage==2 and answer==1 and not p.has("scenario"): p["credits"]=false
	p["quality"]=clampf(float(p["quality"])+gain+Aptitude.score("work")/35.0,0,100)
	p["stage"]=stage+1
	if stage<2: h.done("📦","Delivery progress","Quality %d/100. The scope and trade-offs remain in this contract." % p["quality"]); return
	finish(true)
func finish(delivered: bool) -> void:
	var p: Dictionary=st()["active"]
	if p.is_empty(): return
	var kind := str(p["kind"]); var honest := bool(p["credits"]); var quality := float(p["quality"])
	var trust := float(st()["clients"].get(kind,50.0))
	var paid := 0; var late := delivered and kind in ["service","creative"] and randf()<0.20
	if delivered and honest:
		var gross := int(int(PROJECTS[kind][3])*quality/100.0*(0.8+trust/250.0)*((1.15 if quality>=85 else 0.70) if p["pricing"]=="premium" else 1.0))
		paid=maxi(0,int(gross*(1.0-Places.tax())))
		if late: st()["cashflow"].append({"due":GameState.year_now()+1,"amount":paid,"kind":kind}); paid=0
		else: GameState.player["money"]=int(GameState.player["money"])+paid; Employment.record_income("Independent contracts",paid)
	st()["clients"][kind]=clampf(trust+(6 if delivered and honest and quality>=65 else -10),0,100)
	if kind in ["community","royal"]:
		st()["public_trust"]=clampf(float(st()["public_trust"])+(8 if delivered and honest and quality>=65 else -12),0,100)
		if delivered and honest and quality>=65: h.modules["places"].contribution(5)
	if delivered and honest and quality>=65:
		Market.learn(str(PROJECTS[kind][1]),1); st()["contracts"]=int(st()["contracts"])+1
		if kind=="creative": st()["body_of_work"].push_front({"year":GameState.year_now(),"quality":quality,"credits":true})
	h.modules["pathways"].record("enterprise",kind+":"+str(p.get("started",GameState.year_now()))+":"+str(p.get("scenario",{}).get("id","legacy")),str(PROJECTS[kind][1]),quality if delivered else 0.0,delivered and honest,str(p.get("witness","")))
	st()["history"].push_front({"kind":kind,"name":p.get("scenario",{}).get("name",PROJECTS[kind][0]),"choices":p.get("choices",[]).duplicate(),"year":GameState.year_now(),"quality":quality,"delivered":delivered,"honest":honest,"paid":paid,"late":late})
	if st()["history"].size()>40: st()["history"].resize(40)
	if st()["body_of_work"].size()>20: st()["body_of_work"].resize(20)
	st()["active"]={}
	h.done("📖","Commitment closed","%s · quality %d · payment %s. %s" % [PROJECTS[kind][0],quality,GameState.fmt_money(paid),"Payment is due next year; it was not counted as cash yet." if late else "The client/public record keeps the outcome."],{"happiness":3 if delivered else -2,"stress":-2 if honest else 5})
func yearly() -> void:
	if Lives.separate(): return
	var year := GameState.year_now()
	for invoice in st()["cashflow"].duplicate(true):
		if year>=int(invoice["due"]):
			GameState.player["money"]=int(GameState.player["money"])+int(invoice["amount"]); Employment.record_income("Late contract payments",int(invoice["amount"]))
			st()["cashflow"].erase(invoice); h.note("Invoice paid",GameState.fmt_money(int(invoice["amount"]))+" arrived after its earlier delay.")
	if not st()["active"].is_empty() and year>int(st()["active"]["due"]): finish(false)
	var g: Dictionary=st()["goal"]
	if g.is_empty() or g["completed"]: return
	var good := false
	match str(g["kind"]):
		"belonging":
			for id in GameState.npcs_with("friend")+GameState.npcs_with("partner"): good=good or BondStats.get_stat(str(id),"trust")>=55
		"learning": good=Employment.st()["records"].values().any(func(r): return int(r["samples"])>=2)
		"stability": good=GameState.stat("health")>=50 and int(GameState.player["money"])+int(GameState.player["savings"])>=Actions._cost(2500)
		"service": good=st()["history"].any(func(p): return p["kind"] in ["community","royal"] and p["delivered"] and p["honest"] and float(p["quality"])>=65)
		"creative": good=not st()["body_of_work"].is_empty()
	if good: g["progress"]=int(g["progress"])+1
	if int(g["progress"])>=3:
		g["completed"]=true; GameState.add_milestone(int(GameState.player["age"]),"fulfilled a personal ambition: "+str(g["kind"]))
		h.done("🌱","A life with meaning",GOALS[g["kind"]]+". Three years of progress are recorded; no cash prize defines its value.",{"happiness":5})
func menu(_key: String) -> Dictionary:
	var rows: Array=[h.nav("pathways","Connections","Named people and next-year follow-ups")]; var info: Array=["Public trust %d/100 · client relationships and cash flow persist." % st()["public_trust"]]
	var g: Dictionary=st()["goal"]
	if not g.is_empty(): info.append("Ambition: %s · %d/3 years · %s" % [g["kind"],g["progress"],"fulfilled" if g["completed"] else "in progress"])
	for kind in GOALS: rows.append(h.row("enterprise",kind.capitalize()+" ambition",GOALS[kind],"goal",kind,not h.used("goal")))
	if st()["active"].is_empty():
		for kind in PROJECTS:
			if kind=="royal" and not Lives.is_type("royal"): continue
			rows.append(h.row("enterprise",PROJECTS[kind][0],"3 steps · start "+GameState.fmt_money(startup_cost(kind)),"start",kind,not h.used("enterprise_start")))
	else:
		var p: Dictionary=st()["active"]
		info.append("%s · stage %d/3 · quality %d · due %d" % [PROJECTS[p["kind"]][0],int(p["stage"])+1,p["quality"],p["due"]])
		if p.has("counterpart"): info.append("Working with "+str(p["counterpart"])+".")
		rows.append(h.row("enterprise","Continue commitment","1 time · choices affect quality, credits and reliability","step"))
		rows.append(h.row("enterprise","End the contract","Keep skills and record; startup cost is lost","cancel"))
	for kind in ["reliable","cheap"]: rows.append(h.row("enterprise",kind.capitalize()+" supplier","Cheap startup saves 25%; delivery loses quality","supplier",kind))
	for kind in ["fair","premium"]: rows.append(h.row("enterprise",kind.capitalize()+" pricing","Premium: +15% at quality 85+, otherwise -30%","pricing",kind))
	for p in st()["history"]: info.append("%d · %s · quality %d · %s" % [p["year"],p.get("name",PROJECTS[p["kind"]][0]),p["quality"],"delivered" if p["delivered"] else "ended"])
	rows.append({"icon":"🎨","name":"Creator work","sub":"Existing publication, collaborators and audiences","menu":"creator:root"})
	return {"icon":"🌱","title":"Ambitions & enterprise","info":info,"rows":rows}
func act(key: String, arg: Variant) -> void:
	match key:
		"goal": choose_goal(str(arg))
		"start": start(str(arg))
		"step": step()
		"cancel": if h.blocked(18)=="": finish(false)
		"supplier": if str(arg) in ["cheap","reliable"] and h.blocked(18)=="": st()["supplier"]=str(arg)
		"pricing": if str(arg) in ["fair","premium"] and h.blocked(18)=="": st()["pricing"]=str(arg)
