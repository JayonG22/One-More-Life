extends RefCounted
## Administration reviews an already-paid estate; it never awards it again.
var h
const STAGES := ["Review claims","Check the accounts","Send the final report"]
func _init(hub): h=hub
func book() -> Dictionary: return GameState.world.get("estate_register",{})
func adult(uid: String) -> bool:
	if uid=="": return false
	if uid==h.uid(): return GameState.is_alive() and int(GameState.player["age"])>=18
	var id: String=h.person(uid)
	return id!="" and GameState.npc(id).get("alive",false) and int(GameState.npc(id).get("age",0))>=18
func ensure(source: String) -> Dictionary:
	var receipt: Dictionary=book().get(source,{})
	if receipt.get("status","")!="executed": return {}
	if not receipt.has("administration"):
		receipt["administration"]={"executor":str(receipt.get("executor","")),"stage":0,"closed":false,"history":[],"last_year":GameState.year_now(),"corrected":0}
	var a: Dictionary=receipt["administration"]
	if a["closed"]: return a
	if not adult(str(a["executor"])) and not a.get("delegated",false):
		var replacement := ""
		if adult(str(receipt.get("heir",""))): replacement=str(receipt["heir"])
		else:
			for allocation in receipt.get("allocations",[]):
				if adult(str(allocation["uid"])): replacement=str(allocation["uid"]); break
		if str(a["executor"])!=replacement:
			a["history"].append({"year":GameState.year_now(),"stage":-1,"result":"Executor unavailable; reassigned","executor":replacement})
			a["executor"]=replacement
	if a["history"].size()>32: a["history"]=Array(a["history"]).slice(-32)
	return a
func delegate(source: String) -> void:
	var a := ensure(source)
	if a.is_empty() or a["closed"] or a["executor"]!=h.uid() or not h.pay("estate_delegate:"+source,1,0,18): return
	a["delegated"]=true; a["executor"]=""; a["last_year"]=GameState.year_now()
	a["history"].append({"year":GameState.year_now(),"stage":-1,"result":"Remaining checks delegated","executor":""})
	h.done("📋","Administration delegated","The estate administrator will complete one remaining step per year. The recorded settlement stays unchanged.")
func name_for(uid: String) -> String:
	if uid=="": return "Estate administrator"
	if uid==h.uid(): return str(GameState.player["first"])
	var id: String=h.person(uid)
	return str(GameState.npc(id)["first"]) if id!="" else "Estate administrator"
func total(receipt: Dictionary) -> int:
	var amount := int(receipt.get("charity",0))
	for allocation in receipt.get("allocations",[]): amount+=int(allocation["cash"])+int(allocation["physical"])
	return amount
func summary(receipt: Dictionary) -> Array:
	var lines: Array=["Transfers already received.","Tax %s · fees %s · unpaid claims %s" % [GameState.fmt_money(int(receipt.get("tax",0))),GameState.fmt_money(int(receipt.get("fees",0))),GameState.fmt_money(int(receipt.get("unpaid",0)))]]
	for allocation in receipt.get("allocations",[]):
		lines.append(str(allocation["name"])+" · cash "+GameState.fmt_money(int(allocation["cash"]))+" · owned assets "+GameState.fmt_money(int(allocation["physical"])))
	if int(receipt.get("charity",0))>0: lines.append("Charity · "+GameState.fmt_money(int(receipt["charity"])))
	if not receipt.has("allocations"): lines.append("Older receipt: complete allocation details were not recorded.")
	return lines
func reason(source: String) -> String:
	var a := ensure(source)
	if a.is_empty(): return "No executed estate"
	if a["closed"]: return "Report completed"
	if a["executor"]!=h.uid(): return "Executor: "+name_for(str(a["executor"]))
	var why: String=h.blocked(18)
	if why!="": return why
	if h.used("estate_duty:"+source+":"+str(a["stage"])): return "Continue next year"
	if int(GameState.player["time_left"])<1: return "Needs 1 time"
	return ""
func start(source: String) -> void:
	if reason(source)!="": return
	var a := ensure(source); var stage := int(a["stage"])
	if not h.pay("estate_duty:"+source+":"+str(stage),1,0,18): return
	var receipt: Dictionary=book()[source]
	var text := "\n".join(summary(receipt))
	var options: Array=[]
	if stage==0:
		text+="\n\nHow should the claims record be handled?"
		options=["Record unpaid claims against the estate" if int(receipt.get("unpaid",0))>0 else "Keep the settled claims with the receipt","Charge the heirs the estate's old debts","Distribute the estate a second time"]
	elif stage==1:
		var amount := total(receipt)
		text+="\n\nWhat total was transferred, including owned assets and charity?"
		if not receipt.has("allocations"): text+=" Use the recorded selected cash bequest only."
		if not receipt.has("allocations"): amount=int(receipt.get("cash",0))+int(receipt.get("charity",0))
		options=[GameState.fmt_money(amount),GameState.fmt_money(amount+maxi(1,int(receipt.get("tax",0)))+100),GameState.fmt_money(amount+maxi(1,int(receipt.get("fees",0)))+500)]
	else:
		text+="\n\nHow will you conclude your duties?"
		options=["Share the full receipt with the heirs","Send a brief completion notice","Withhold the report"]
	var order: Array=[0,1,2]
	if stage<2: order.shuffle()
	h.decision("heritage","estate_duty",{"source":source,"stage":stage,"executor":h.uid(),"order":order},STAGES[stage],text,order.map(func(i): return options[i]),"📋")
func resolve(args: Dictionary, answer: int) -> void:
	var source := str(args.get("source","")); var a := ensure(source)
	if a.is_empty() or a["closed"] or a["executor"]!=h.uid() or str(args.get("executor",""))!=h.uid() or int(args.get("stage",-1))!=int(a["stage"]): return
	var order: Array=args.get("order",[])
	if answer<0 or answer>=order.size(): return
	var chosen := int(order[answer]); var stage := int(a["stage"])
	var good := stage==2 or chosen==0
	a["history"].append({"year":GameState.year_now(),"stage":stage,"choice":chosen,"correct":good,"executor":h.uid()})
	a["last_year"]=GameState.year_now()
	if not good:
		a["corrected"]=int(a["corrected"])+1
		h.done("📋","Check before filing","No money or ownership changed. Review the receipt and correct this step next year.",{"stress":1})
		return
	a["stage"]=stage+1
	if stage==2:
		a["closed"]=true; a["closed_year"]=GameState.year_now(); a["report"]=chosen
		for allocation in book()[source].get("allocations",[]):
			var id: String=h.person(str(allocation["uid"]))
			if id!="" and GameState.npc(id).get("alive",false):
				BondStats.apply(id,{"trust":3 if chosen==0 else -3 if chosen==2 else 0})
				FamilyChronicle.remember(id,"Estate report: "+["full receipt shared","completion notice","report withheld"][chosen],"good" if chosen==0 else "bad" if chosen==2 else "neutral")
		if chosen==0: Market.learn("Legal",1)
		h.done("📜","Executor duties completed","Report filed. Family trust reflects how you shared it.")
	else: h.done("📋","Estate check recorded","Next: "+STAGES[int(a["stage"])]+" · 1 time. Ownership and payouts stay unchanged.")
func yearly() -> void:
	var year := GameState.year_now()
	for source in book():
		var a := ensure(str(source))
		if a.is_empty() or a["closed"] or a["executor"]==h.uid() or year<=int(a["last_year"]): continue
		# An inactive executor continues their own duties one stage per year.
		# Existing estate fees cover administration; active heirs aren't charged.
		var stage := int(a["stage"])
		a["history"].append({"year":year,"stage":stage,"result":"Completed by executor","executor":a["executor"]})
		a["stage"]=stage+1; a["last_year"]=year
		if stage==2:
			a["closed"]=true; a["closed_year"]=year; a["report"]=0
			var id: String=h.person(str(a["executor"]))
			if id!="": FamilyChronicle.remember(id,"Completed the family's estate administration.","good")
func menu(source: String) -> Dictionary:
	var receipt: Dictionary=book().get(source,{})
	var a := ensure(source); var rows: Array=[]; var info: Array=summary(receipt) if not receipt.is_empty() else ["No estate record."]
	if not a.is_empty():
		info.append("Executor · "+name_for(str(a["executor"])))
		info.append("Final report completed" if a["closed"] else "Step %d/3 · %s" % [int(a["stage"])+1,STAGES[int(a["stage"])]])
		var why := reason(source)
		var work: Dictionary=h.row("heritage","Continue executor duties",why if why!="" else "1 time · no fee · review transfers","estate_duty",source,why==""); work["icon"]="📋"; rows.append(work)
		var delegation: Dictionary=h.row("heritage","Delegate remaining checks","1 time · yearly administration · no extra fee","estate_delegate",source,not a["closed"] and a["executor"]==h.uid()); delegation["icon"]="🤝"; rows.append(delegation)
		for entry in a["history"]: info.append(str(entry["year"])+" · "+(STAGES[int(entry["stage"])] if int(entry["stage"])>=0 else "Executor changed")+" · "+str(entry.get("result","checked" if entry.get("correct",false) else "correction needed")))
	return {"icon":"📋","title":"Estate receipt & duties","info":info,"rows":rows}
func rows() -> Array:
	var result: Array=[]
	for source in book():
		var receipt: Dictionary=book()[source]
		if str(receipt.get("heir",""))!=h.uid() and str(receipt.get("executor",""))!=h.uid() and not receipt.get("allocations",[]).any(func(a): return str(a["uid"])==h.uid()): continue
		var a := ensure(str(source))
		if a.is_empty(): continue
		result.append(h.nav("heritage","Estate receipt · "+str(receipt.get("name","Earlier life")),"Report completed" if a["closed"] else STAGES[int(a["stage"])]+" · executor "+name_for(str(a["executor"])),"estate:"+str(source)))
	return result
