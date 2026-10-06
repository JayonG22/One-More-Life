extends RefCounted
var h
var hearing_questions: Array=[]
const QUESTIONS := [
	["The witness's timeline conflicts with a dated record.",["Ask for the conflict to be examined","Declare the whole case impossible","Ignore both accounts"],0],
	["A claim rests on a rumour about the accused.",["Ask what admissible evidence supports it","Treat reputation as proof","Threaten the witness"],0],
	["An exhibit supports one fact but not the whole allegation.",["Accept the narrow fact and dispute the unsupported inference","Deny every recorded fact","Invent a replacement story"],0],
	["The court asks whether the person understands a proposed plea.",["Request a clear explanation before deciding","Accept without reading","Assume a plea erases every consequence"],0],
	["The hearing record contains a factual mistake.",["Identify it precisely and ask for correction","Promise it guarantees acquittal","Hide it until after sentencing"],0]
]
func _init(hub):
	h=hub; hearing_questions=QUESTIONS+ContentDB._load_json("res://data/hearing_questions.json",[])
func st() -> Dictionary: return h.section("recovery",{"case":{},"history":[],"care":{},"reentry":{"housing":false,"appointments":0,"support":0},"was_prison":false,"release_year":-1,"grief":{},"appeal":{}})
func begin_trial(crime: String, low: int, high: int, evidence: float) -> bool:
	if Lives.separate(): return false
	var current: Dictionary=st()["case"]
	if not current.is_empty():
		current["charges"].append(crime); current["high"]=maxi(high,int(current["high"])); return true
	st()["case"]={"crime":crime,"charges":[crime],"low":low,"high":high,"evidence":evidence,"stage":0,"strength":20.0,"lawyer":0,"cost":0,"answers":0,"year":GameState.year_now(),"owner":h.uid(),"verdict_roll":randf(),"sentence_roll":randf(),"bribe_roll":randf()}
	var recent: Array=[]
	for old in st()["history"].slice(0,4):
		for question in old.get("questions",[]): recent.append(str(question[0]))
	var available: Array=range(hearing_questions.size()).filter(func(i): return not str(hearing_questions[i][0]) in recent)
	if available.size()<3: available=range(hearing_questions.size())
	available.shuffle()
	st()["case"]["questions"]=available.slice(0,3).map(func(i): return hearing_questions[i].duplicate(true))
	st()["case"]["timeline"]=[{"year":GameState.year_now(),"step":"Representation requested","evidence":evidence}]
	if GameState.has_flag("hostile_witness"): st()["case"]["evidence"]=minf(100,evidence+10); GameState.clear_flag("hostile_witness")
	if GameState.has_flag("truth_spell"): st()["case"]["strength"]=35.0; GameState.clear_flag("truth_spell")
	if Lives.has_power("mind"): st()["case"]["strength"]=float(st()["case"]["strength"])+8
	if h.state()["prompt"].is_empty(): hearing()
	else: h.note("Hearing scheduled","My existing decision must finish before this criminal hearing. Open Trouble & recovery to continue.")
	return true
func hearing() -> void:
	var c: Dictionary=st()["case"]
	if c.is_empty() or c["owner"]!=h.uid() or not h.state()["prompt"].is_empty(): return
	for key in ["verdict_roll","sentence_roll","bribe_roll"]:
		if not c.has(key): c[key]=randf()
	var stage := int(c["stage"])
	if stage==0:
		var options: Array=["Public defender · free",{"label":"Private representation · "+GameState.fmt_money(Law._lawyer_cost(1)),"requires":{"money":Law._lawyer_cost(1)}},{"label":"Specialist representation · "+GameState.fmt_money(Law._lawyer_cost(2)),"requires":{"money":Law._lawyer_cost(2)}}]
		var lawyer := Web.contact(["lawyer"],55)
		c["contact"]=FamilyChronicle.identity(GameState.npc(lawyer)) if lawyer!="" else ""
		if lawyer!="": options.append("Call "+str(GameState.npc(lawyer)["first"])+" · existing legal contact")
		c["bribe_index"]=options.size()
		c["bribe_cost"]=maxi(Actions._cost(5000),int(GameState.net_worth()*0.05))
		if float(Places.law("corruption"))>=0.1: options.append({"label":"Bribe the court · "+GameState.fmt_money(int(c["bribe_cost"])),"requires":{"money":int(c["bribe_cost"])}})
		h.decision("recovery","representation",{},"Representation · "+str(c["crime"]),"Evidence strength %d/100. Organise a defence; money cannot guarantee a verdict." % c["evidence"],options)
	else:
		var q: Array=c.get("questions",QUESTIONS)[stage-1]
		if not c.has("orders"): c["orders"]={}
		if not c["orders"].has(str(stage)):
			var shuffled: Array=[0,1,2]; shuffled.shuffle(); c["orders"][str(stage)]=shuffled
		var order: Array=c["orders"][str(stage)]
		h.decision("recovery","hearing",{"stage":stage,"order":order,"question":q},"Hearing · "+str(stage)+"/3",q[0],order.map(func(i): return q[1][i]))
func resolve(op: String, args: Dictionary, answer: int) -> void:
	var c: Dictionary=st()["case"]
	if op=="representation":
		if c.is_empty() or int(c["stage"])!=0: return
		if answer==int(c.get("bribe_index",-1)):
			var fee := int(c["bribe_cost"])
			if GameState.player["money"]<fee: return
			GameState.player["money"]=int(GameState.player["money"])-fee; c["cost"]=fee
			GameState.apply_effects({"karma":-10,"stress":5})
			if float(c["bribe_roll"])<clampf(float(Places.law("corruption"))*2.2,0.1,0.85):
				c["result"]="dismissed"; c["appealed"]=false
				st()["history"].push_front(c.duplicate(true)); st()["case"]={}
				if st()["history"].size()>30: st()["history"].resize(30)
				Ambition.outcome({"kind":"court_case","crime":c["crime"],"result":"dismissed","evidence":c["evidence"],"lawyer":0})
				h.done("⚖️","Case dismissed","The corrupt intervention is recorded. It does not undo the underlying actions or family consequences."); return
			c["evidence"]=minf(100,float(c["evidence"])+12)
			c["high"]=int(c["high"])+1; answer=0
		elif answer==3:
			var id: String=h.person(str(c.get("contact","")))
			if id!="" and GameState.npc(id).get("alive",false): c["strength"]=float(c["strength"])+12; FamilyChronicle.remember(id,"Helped organise my criminal defence.")
			answer=0
		var cost := Law._lawyer_cost(answer)
		if int(GameState.player["money"])<cost: answer=0; cost=0
		GameState.player["money"]=int(GameState.player["money"])-cost
		c["lawyer"]=answer; c["cost"]=int(c["cost"])+cost; c["strength"]=float(c["strength"])+[8,15,20][answer]; c["stage"]=1
		hearing()
	elif op=="hearing":
		if c.is_empty() or int(c["stage"])!=int(args["stage"]): return
		var correct := int(args["order"][answer])==int(args["question"][2])
		c["strength"]=float(c["strength"])+(10+Aptitude.score("education")/25.0 if correct else -4); c["answers"]=int(c["answers"])+(1 if correct else 0); c["stage"]=int(c["stage"])+1
		if not c.has("timeline"): c["timeline"]=[]
		c["timeline"].append({"year":GameState.year_now(),"step":str(args["question"][0]),"prepared":correct,"choice":str(args["question"][1][int(args["order"][answer])])})
		h.note("Hearing evidence",str(args["question"][1][int(args["order"][answer])])+". "+("The answer supported case preparation." if correct else "The answer weakened case preparation."))
		if int(c["stage"])<=3: hearing(); return
		var chance := clampf((0.35+(float(c["strength"])-float(c["evidence"]))/140.0)*clampf(float(Grit.d("acquit"))/float(Places.law("police")),0.5,1.5),0.05,0.85)
		var won := float(c["verdict_roll"])<chance; c["result"]="acquitted" if won else "convicted"; c["chance"]=chance; c["appealed"]=false
		var history := c.duplicate(true); st()["history"].push_front(history); st()["case"]={}
		if st()["history"].size()>30: st()["history"].resize(30)
		if not won:
			var sentence := int(history["low"])+int(float(history["sentence_roll"])*(int(history["high"])-int(history["low"])+1))
			history["sentence"]=clampi(sentence,int(history["low"]),int(history["high"]))
			st()["history"][0]["sentence"]=history["sentence"]
			Actions.go_to_prison(int(history["sentence"]),str(history["crime"]))
		Ambition.outcome({"kind":"court_case","crime":history["crime"],"result":history["result"],"evidence":history["evidence"],"lawyer":history["lawyer"],"years":int(GameState.player["prison"])})
		h.done("⚖️","Criminal verdict","%s · defence %d · evidence %d · %d%% acquittal chance. Representation cost %s. The hearing and result remain in the case record." % [history["result"],history["strength"],history["evidence"],chance*100,GameState.fmt_money(int(history["cost"]))],{"happiness":8 if won else -6,"stress":-4 if won else 8})
	elif op in ["appeal_ground","appeal"]:
		var a: Dictionary=st()["appeal"]
		if a.is_empty() and op=="appeal" and not st()["history"].is_empty():
			var legacy: Dictionary=st()["history"][0]
			a={"stage":1,"case_year":legacy["year"],"crime":legacy["crime"],"ground":0 if answer==0 else 1,"grounds":["Legacy factual/procedural review","Unsupported legacy request"],"roll":randf(),"cost":Actions._cost(600)}
			st()["appeal"]=a
		if a.is_empty() or st()["history"].is_empty() or not GameState.in_prison(): return
		var case: Dictionary=st()["history"][0]
		if case["result"]!="convicted" or case.get("appealed",false) or int(case["year"])!=int(a["case_year"]) or str(case["crime"])!=str(a["crime"]): return
		if op=="appeal_ground":
			if int(a["stage"])!=0: return
			a["ground"]=int(args["order"][answer]); a["stage"]=1
			appeal_hearing(); return
		if int(a["stage"])!=1: return
		answer=int(args.get("order",[0,1,2])[answer])
		case["appealed"]=true
		var chance := clampf(0.10+float(case["strength"])/500.0+(0.10 if int(a["ground"])==0 else -0.06)+(0.08 if answer==0 else -0.05),0.03,0.55)
		var accepted := float(a["roll"])<chance
		var before := int(GameState.player["prison"])
		if accepted: GameState.player["prison"]=maxi(0,before-maxi(1,before/4))
		case["appeal_record"]={"ground":a["grounds"][int(a["ground"])],"submission":["Cite the dated record and limits","Demand a new verdict without evidence","Rely on fame"][answer],"chance":chance,"accepted":accepted,"reduction":before-int(GameState.player["prison"]),"year":GameState.year_now(),"cost":a["cost"]}
		st()["appeal"]={}
		h.done("⚖️","Appeal concluded","Review %s · %d%% chance · sentence reduction %d. The crime and verdict stay recorded." % ["accepted" if accepted else "declined",chance*100,before-int(GameState.player["prison"])])
func appeal_hearing() -> void:
	var a: Dictionary=st()["appeal"]
	if a.is_empty() or not h.state()["prompt"].is_empty(): return
	var order: Array=[0,1,2]; order.shuffle()
	if int(a["stage"])==0:
		h.decision("recovery","appeal_ground",{"order":order},"Review the hearing",str(a["context"]),order.map(func(i): return a["grounds"][i]))
	else:
		var options: Array=["Cite the dated record and its limits","Demand a verdict without new evidence","Rely on fame"]
		h.decision("recovery","appeal",{"order":order},"Submit the appeal",str(a["grounds"][int(a["ground"])])+". The reviewer weighs relevance; no answer guarantees reversal.",order.map(func(i): return options[i]))
func appeal() -> void:
	if not st()["appeal"].is_empty():
		if h.state()["prompt"].is_empty() and GameState.in_prison(): appeal_hearing()
		return
	if st()["history"].is_empty(): return
	var c: Dictionary=st()["history"][0]
	if not GameState.in_prison() or c["result"]!="convicted" or c.get("appealed",false) or not h.pay("appeal",2,Actions._cost(600),16,false,true): return
	var timeline: Array=c.get("timeline",[]).filter(func(entry): return entry.has("prepared"))
	var context := str(timeline[0]["step"]) if not timeline.is_empty() else "The old case has no detailed hearing transcript."
	var ground := "Request transcript disclosure and review missing records" if timeline.is_empty() else "Cite the recorded issue and seek a narrow review" if bool(timeline[0]["prepared"]) else "Request the missed examination of this recorded issue"
	st()["appeal"]={"stage":0,"case_year":c["year"],"crime":c["crime"],"context":context,"grounds":[ground,"Treat every allegation as disproved","Ask popularity to replace evidence"],"roll":randf(),"cost":Actions._cost(600)}
	Employment.record_expense("Criminal appeal",Actions._cost(600)); appeal_hearing()
func care(kind: String) -> void:
	if kind not in ["paced","supported","push"] or not h.pay("recovery_care",1,Actions._cost(0 if kind=="paced" else 100),16): return
	var plan: Dictionary=st()["care"]
	if plan.is_empty(): plan.merge({"years":0,"kind":kind,"last":-1,"steps":0})
	plan["kind"]=kind; plan["last"]=GameState.year_now(); plan["steps"]=int(plan["steps"])+1
	h.done("🌿","Recovery plan",{"paced":"Make room for rest and achievable activities.","supported":"Arrange practical support and follow the care team's plan.","push":"Push through obligations; progress may come with fatigue."}[kind],{"stress":-3 if kind!="push" else 5,"happiness":2 if kind!="push" else 0})
func reentry(kind: String) -> void:
	if GameState.in_prison() or GameState.player.get("record",[]).is_empty() or kind not in ["housing","appointment","support"]: return
	if not h.pay("reentry:"+kind,1,Actions._cost(200 if kind=="housing" else 0),18): return
	var r: Dictionary=st()["reentry"]
	if kind=="housing": r["housing"]=true
	elif kind=="appointment": r["appointments"]=int(r["appointments"])+1
	else: r["support"]=int(r["support"])+1
	Market.st()["interview_xp"]=minf(0.15,float(Market.st()["interview_xp"])+0.015)
	h.done("🌱","Rebuilding",{"housing":"I prepared a housing application and references; a home is not awarded for free.","appointment":"I kept a supervision/support appointment. The record now shows consistent attendance.","support":"A support group helped me plan the next step without pretending the past vanished."}[kind],{"stress":-2})
func yearly() -> void:
	if Lives.separate(): return
	if not GameState.in_prison() and not st()["appeal"].is_empty():
		st()["appeal"]={}; h.note("Appeal closed","Custody ended before the review; no further sentence reduction was applied.")
	if st()["was_prison"] and not GameState.in_prison(): st()["release_year"]=GameState.year_now(); h.note("A playable next chapter","Housing, work, supervision and trust need rebuilding after release.")
	st()["was_prison"]=GameState.in_prison()
	var plan: Dictionary=st()["care"]
	if plan.is_empty(): return
	if int(plan["last"])==GameState.year_now()-1:
		plan["years"]=int(plan["years"])+1
		if plan["kind"]!="push":
			GameState.apply_effects({"stress":-3,"health":1,"happiness":1})
			if int(plan["years"])>=2:
				Expansion.ensure()
				for injury in GameState.player["medical"]["injuries"].values(): injury["left"]=maxi(0,int(injury.get("left",1))-1)
		else: GameState.apply_effects({"stress":4,"health":-1})
	else: plan["years"]=maxi(0,int(plan["years"])-1)
func menu(_key: String) -> Dictionary:
	var rows: Array=[]; var info: Array=["Consequences stay recorded. Recovery does not guarantee a cure or erase a criminal history."]
	var c: Dictionary=st()["case"]
	if not c.is_empty(): info.append(str(c["crime"])+" · hearing stage "+str(c["stage"])); rows.append(h.row("recovery","Continue hearing","Representation, evidence and a recorded verdict","hearing"))
	if not st()["history"].is_empty(): rows.append(h.row("recovery","Seek a review","2 time · "+GameState.fmt_money(Actions._cost(600))+" · two recorded stages","appeal",null,GameState.in_prison() and st()["history"][0]["result"]=="convicted" and not st()["history"][0].get("appealed",false)))
	for kind in ["paced","supported","push"]: rows.append(h.row("recovery",kind.capitalize()+" recovery","1 time · rest/support or a demanding approach","care",kind,not h.used("recovery_care")))
	if not GameState.player.get("record",[]).is_empty() and not GameState.in_prison():
		for kind in ["housing","appointment","support"]: rows.append(h.row("recovery",kind.capitalize()+" plan","1 time · sustainable re-entry","reentry",kind,not h.used("reentry:"+kind)))
	for c0 in st()["history"]: info.append("%d · %s · %s · %d/3 prepared answers" % [c0["year"],c0["crime"],c0["result"],c0["answers"]])
	rows.append({"icon":"🩺","name":"Medical care","sub":"Diagnosis, referrals, treatment and rehabilitation","menu":"real:care"})
	return {"icon":"🌿","title":"Trouble & recovery","info":info,"rows":rows}
func act(key: String, arg: Variant) -> void:
	match key:
		"hearing": if h.state()["prompt"].is_empty(): hearing()
		"appeal": appeal()
		"care": care(str(arg))
		"reentry": reentry(str(arg))
