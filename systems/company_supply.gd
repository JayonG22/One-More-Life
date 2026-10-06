extends RefCounted
## Stock, contractual deliveries and cash flow belong to the actual company.
var _operations: WeakRef
var op:
	get: return _operations.get_ref()
const TERMS := {"value":[2,0.85,0.94],"steady":[1,0.97,1.0],"specialist":[0,0.99,1.06]}
func _init(operations): _operations=weakref(operations)
func state(b: Dictionary) -> Dictionary:
	var s: Dictionary=b["operations"]
	if not s.has("supply"):
		# Migration represents existing operations; it creates no spendable cash.
		s["supply"]={"lots":[],"contracts":[],"deliveries":[],"serial":0,"cash":0,"portfolio":false,"auto":100,"facilities":{"storage":0,"research":0,"production":0},"research":{},"insights":[0,0],"last_research":-1,"research_seen":[],"ledger":{},"changed":{},"settled":-1}
		var old: Dictionary=s["supply"]
		var opening := mini(100,maxi(8,int(b.get("rev",0))/unit_price(b,0,1.0)))
		for product in range(2): old["lots"].append({"product":product,"quantity":opening,"basis":int(int(b.get("value",0))*0.05),"received":GameState.year_now()})
		# Existing stock is part of the already-owned company value, never cash.
	return s["supply"]
func launch(b: Dictionary, cost: int) -> void:
	var s := state(b)
	s["cash"]=int(cost*0.15)
	s["lots"]=[]
	for i in range(2): s["lots"].append({"product":i,"quantity":8,"basis":int(cost*0.05),"received":GameState.year_now()})
	contract(b,0,100,"steady",GameState.year_now()+1)
func unit_price(b: Dictionary, product: int, cost: float) -> int:
	return maxi(1,int(float(Empires.INDUSTRIES[b["ind"]]["rev"])/100.0*cost*(1.0 if product==0 else 1.25)))
func unit_cost(b: Dictionary, product: int, supplier: String, cost: float) -> int:
	var fraction := 0.45-float(Empires.INDUSTRIES[b["ind"]]["margin"])*0.30
	return maxi(1,int(unit_price(b,product,cost)*fraction*float(TERMS[supplier][2])))
func local_cost(b: Dictionary) -> float:
	if b==op.biz(): return float(ContentDB.country(GameState.player["country"]).get("cost",1.0))*Places.cost_mult()
	return float(ContentDB.country(str(b.get("country","us"))).get("cost",1.0))*float(b.get("local_cost",1.0))
func capacity(b: Dictionary) -> int:
	return 150+int(b["staff"])*10+int(state(b)["facilities"]["production"])*50
func stock(b: Dictionary, product: int) -> int:
	var amount := 0
	for lot in state(b)["lots"]:
		if int(lot["product"])==product: amount+=int(lot["quantity"])
	return amount
func contract(b: Dictionary, product: int, quantity: int, supplier: String, due: int = -1) -> void:
	var s := state(b); s["serial"]=int(s["serial"])+1
	var arrival := GameState.year_now()+int(TERMS[supplier][0]) if due<0 else due
	s["contracts"].append({"id":s["serial"],"product":product,"quantity":quantity,"supplier":supplier,"name":op.catalog[b["ind"]]["suppliers"][supplier],"due":arrival,"roll":randf(),"delayed":false,"unit_cost":unit_cost(b,product,supplier,local_cost(b)),"signed":GameState.year_now()})
func place(product: int, quantity: int) -> void:
	var b: Dictionary=op.biz()
	if b.is_empty() or product<0 or product>1 or quantity not in [25,75,150]: return
	var s := state(b)
	if s["contracts"].size()>=8 or not op.h.pay("supply_contract:"+str(b["uid"])+":"+str(product),1,0,18): return
	contract(b,product,quantity,str(op.st()["supplier"]))
	var c: Dictionary=s["contracts"].back()
	op.h.done("🚚","Supply contract signed","%d batches · due %d · bill %s at annual settlement. Late delivery keeps the same saved risk." % [quantity,c["due"],GameState.fmt_money(quantity*int(c["unit_cost"]))])
func policy(key: String, value: Variant) -> void:
	var b: Dictionary=op.biz()
	if b.is_empty() or key not in ["auto","portfolio"]: return
	if key=="auto" and int(value) not in [0,50,100,150]: return
	if key=="portfolio" and not value is bool: return
	var s := state(b)
	if s[key]==value or not op.h.pay("supply_policy:"+str(b["uid"])+":"+key,1,0,18): return
	s[key]=value
	op.h.done("📦","Stock plan changed","Existing contracts still fall due. Automatic orders are signed after the next accounts.")
func fund(amount: int) -> void:
	var b: Dictionary=op.biz()
	if b.is_empty() or amount not in [10,25,50]: return
	var price := Actions._cost(int(Empires.INDUSTRIES[b["ind"]]["cost"])*amount/100.0)
	if not op.h.pay("company_funding:"+str(b["uid"]),1,price,18): return
	var s := state(b); s["cash"]=int(s["cash"])+price
	op.h.done("🏦","Company reserve funded",GameState.fmt_money(price)+" moved from my cash into the company's reserve. It is capital, not revenue or a reward.")
func upgrade(kind: String) -> void:
	var b: Dictionary=op.biz()
	if b.is_empty() or kind not in ["storage","research","production"]: return
	var s := state(b); var level := int(s["facilities"][kind])
	var fee := Actions._cost(int(Empires.INDUSTRIES[b["ind"]]["cost"])*0.12*(level+1))
	if level>=2 or not op.h.pay("facility:"+str(b["uid"])+":"+kind,2,fee,18): return
	s["facilities"][kind]=level+1; b["value"]=int(b["value"])+fee
	op.h.done("🏗️","Facility improved",str(op.catalog[b["ind"]]["facilities"][kind])+" · level %d/2. Upkeep joins the annual accounts." % (level+1))
func research() -> void:
	var b: Dictionary=op.biz()
	if b.is_empty(): return
	var s := state(b); var product := int(op.st()["product"])
	if not s["research"].is_empty() or int(s["insights"][product])>=3: return
	var cost := Actions._cost(int(Empires.INDUSTRIES[b["ind"]]["cost"])*0.02)
	if not op.h.pay("market_research:"+str(b["uid"]),1,cost,18): return
	var pool: Array=op.catalog[b["ind"]]["research_pool"]
	var available: Array=[]
	for i in range(pool.size()):
		if not s.get("research_seen",[]).any(func(seen): return int(seen)==i): available.append(i)
	if available.size()<2: available=range(pool.size())
	available.shuffle(); var questions: Array=[]
	for i in available.slice(0,2):
		var question: Dictionary=pool[i].duplicate(true); var positions: Array=[0,1,2]; positions.shuffle()
		var answers: Array=[]
		for position in positions: answers.append(question["answers"][position])
		question["answers"]=answers; question["correct"]=positions.find(int(question["correct"])); questions.append(question)
		if not s.has("research_seen"): s["research_seen"]=[]
		s["research_seen"].append(i)
	s["research"]={"questions":questions,"id":GameState.year_now(),"product":product,"stage":0,"quality":Aptitude.score("work")*0.4,"roll":randf(),"due":GameState.year_now()+1}
	op.h.done("🔎","Research started","Two assessments · due next year. Good evidence and business skills improve the result.")
func research_work() -> void:
	var b: Dictionary=op.biz()
	if b.is_empty(): return
	var s := state(b); var r: Dictionary=s["research"]
	if r.is_empty() or not op.h.pay("research_stage:"+str(b["uid"])+":"+str(r["id"])+":"+str(r["stage"]),1,0,18): return
	var data: Dictionary=r["questions"][int(r["stage"])]
	op.h.decision("operations","research",{"owner":b["uid"],"id":r["id"],"stage":r["stage"]},"Market research",str(data["question"]),data["answers"])
func resolve(args: Dictionary, answer: int) -> void:
	var b: Dictionary=op.biz(); var s := state(b); var r: Dictionary=s["research"]
	if r.is_empty() or int(args.get("id",-1))!=int(r["id"]) or int(args.get("stage",-1))!=int(r["stage"]) or answer<0 or answer>2: return
	var correct := int(r["questions"][int(r["stage"])] ["correct"])
	r["quality"]=float(r["quality"])+(25 if answer==correct else -8)+int(s["facilities"]["research"])*4
	r["stage"]=int(r["stage"])+1
	if int(r["stage"])<2: op.h.done("🔎","Evidence gathered","One assessment remains. Findings are saved with this product."); return
	var chance := clampf(float(r["quality"])/100.0,0.05,0.95)
	var good := float(r["roll"])<chance
	if good: s["insights"][int(r["product"])]=mini(3,int(s["insights"][int(r["product"])])+1); Market.learn("Business",2)
	s["last_research"]=GameState.year_now(); s["research"]={}
	op.h.done("🔎","Research concluded","Success chance %d%%. %s" % [roundi(chance*100),"The product gains a lasting demand insight." if good else "The pilot was inconclusive. Skills remain; there is no cash reward."])
func reserve_for_order(b: Dictionary, product: int) -> bool:
	# Reserve three actual batches when accepting, rather than inventing them later.
	if stock(b,product)<3: return false
	var remaining := 3; var basis := 0
	for lot in state(b)["lots"]:
		if int(lot["product"])!=product or remaining<=0: continue
		var take := mini(remaining,int(lot["quantity"])); var cost := int(int(lot["basis"])*float(take)/maxi(1,int(lot["quantity"])))
		lot["quantity"]=int(lot["quantity"])-take; lot["basis"]=int(lot["basis"])-cost; basis+=cost; remaining-=take
	state(b)["order_basis"]=basis
	return true
func return_reservation(b: Dictionary, product: int, successful: bool) -> void:
	var s := state(b); var basis := int(s.get("order_basis",0)); s.erase("order_basis")
	# Delivery uses annual sales capacity; failed work is a written-off batch.
	if successful: s["lots"].append({"product":product,"quantity":3,"basis":basis,"received":GameState.year_now()})
	else: s["writeoff"]=int(s.get("writeoff",0))+basis
func plan(b: Dictionary, potential_revenue: int, cost: float, margin: float, payroll: int, interest: int, year: int) -> Dictionary:
	# A pure preview: inspecting numbers cannot consume stock or redraw delivery risk.
	var s := state(b).duplicate(true); var purchased := 0; var arrivals: Array=[]; var pending: Array=[]
	for c0 in s["contracts"]:
		var c: Dictionary=c0.duplicate(true)
		if int(c["due"])>year: pending.append(c); continue
		if not c["delayed"] and float(c["roll"])>=float(TERMS[c["supplier"]][1]): c["due"]=year+1; c["delayed"]=true; pending.append(c); arrivals.append({"name":c["name"],"result":"Delayed","quantity":c["quantity"],"year":year}); continue
		var bill := int(c["quantity"])*int(c["unit_cost"]); purchased+=bill
		s["lots"].append({"product":c["product"],"quantity":c["quantity"],"basis":bill,"received":year})
		arrivals.append({"name":c["name"],"result":"Received","quantity":c["quantity"],"year":year})
	s["contracts"]=pending; s["deliveries"]=arrivals+s["deliveries"]; s["deliveries"]=Array(s["deliveries"]).slice(0,24)
	var revenue := 0; var cogs := 0; var wasted := int(s.get("writeoff",0)); var sold: Array=[0,0]; var demand: Array=[0,0]; var lost := 0
	# Old expired lots cannot be sold before being written off.
	for lot in s["lots"]:
		var product: Dictionary=op.catalog[b["ind"]]["products"][int(lot["product"])]
		var shelf := int(product["shelf_life"])
		if shelf>0 and year-int(lot["received"])>=shelf:
			wasted+=int(lot["basis"]); lot["quantity"]=0; lot["basis"]=0
		elif product["physical"]:
			var rate := maxf(0,(0.06 if b["ind"]=="restaurant" else 0.02)*(1-int(s["facilities"]["storage"])*0.5))
			var discard := mini(int(lot["quantity"]),int(round(int(lot["quantity"])*rate)))
			var basis := int(int(lot["basis"])*float(discard)/maxi(1,int(lot["quantity"])))
			wasted+=basis; lot["quantity"]=int(lot["quantity"])-discard; lot["basis"]=int(lot["basis"])-basis
	var primary := int(b["operations"]["product"])
	var room := capacity(b)
	for product in [primary,1-primary]:
		var share := 0.75 if product==primary else 0.25
		if not s["portfolio"]: share=1.0 if product==primary else 0.0
		var base_price := unit_price(b,product,cost)
		var tariff := maxi(1,int(base_price*{"accessible":0.90,"standard":1.0,"premium":1.18}[b["operations"]["pricing"]]))
		var request := int(potential_revenue*share/base_price*(1.0+int(s["insights"][product])*0.05))
		var remaining := mini(room,request); var count := 0
		# Lots retain their product and paid cost even when plans/prices change.
		for lot in s["lots"]:
			if int(lot["product"])!=product or remaining<=0: continue
			var take := mini(remaining,int(lot["quantity"])); var basis := int(int(lot["basis"])*float(take)/maxi(1,int(lot["quantity"])))
			lot["quantity"]=int(lot["quantity"])-take; lot["basis"]=int(lot["basis"])-basis; remaining-=take; count+=take; cogs+=basis
		revenue+=count*tariff; sold[product]=count; demand[product]=request; lost+=request-count; room-=count
	# Current-period perishables and unbooked service capacity cannot be banked.
	for lot in s["lots"]:
		var shelf := int(op.catalog[b["ind"]]["products"][int(lot["product"])] ["shelf_life"])
		if shelf==1 and int(lot["quantity"])>0:
			wasted+=int(lot["basis"]); lot["quantity"]=0; lot["basis"]=0
	s["lots"]=s["lots"].filter(func(lot): return int(lot["quantity"])>0)
	var overhead_share := clampf(1.0-margin-(0.45-float(Empires.INDUSTRIES[b["ind"]]["margin"])*0.30),0.05,0.90)
	var overhead := int(revenue*maxf(0.05,overhead_share-int(s["facilities"]["storage"])*0.008))
	var upkeep := int(float(Empires.INDUSTRIES[b["ind"]]["cost"])*cost*0.01*(int(s["facilities"]["storage"])+int(s["facilities"]["research"])+int(s["facilities"]["production"])))
	var profit := revenue-cogs-wasted-overhead-upkeep-payroll-interest
	var cash_flow := revenue-purchased-overhead-upkeep-payroll-interest
	var available := int(s["cash"])+cash_flow
	var draw := mini(maxi(0,available),maxi(0,int(profit*float(b["stake"])*(0.3 if b["public"] else 1.0)))) if available>=0 else available
	s["cash"]=maxi(0,available-draw); s["settled"]=year; s["writeoff"]=0
	s["ledger"]={"year":year,"sales":revenue,"sold":sold,"demand":demand,"missed":lost,"purchases":purchased,"cost_of_sales":cogs,"writeoff":wasted,"overhead":overhead,"upkeep":upkeep,"cash_flow":cash_flow,"cash":s["cash"],"draw":draw,"profit":profit}
	return {"state":s,"rev":revenue,"profit":profit,"draw":draw,"ledger":s["ledger"]}
func settle(b: Dictionary, result: Dictionary) -> void:
	var s: Dictionary=result["state"]; b["operations"]["supply"]=s
	if int(s["auto"])<=0: return
	var primary := int(b["operations"]["product"])
	for product in range(2):
		if product!=primary and not s["portfolio"]: continue
		var planned := 0
		for c in s["contracts"]:
			if int(c["product"])==product: planned+=int(c["quantity"])
		var share := (0.75 if product==primary else 0.25) if s["portfolio"] else 1.0
		var target := mini(capacity(b),int(int(s["auto"])*share))
		var quantity := maxi(0,target-stock(b,product)-planned)
		if quantity>0:
			# Even express replenishment arrives for the next accounting period.
			contract(b,product,quantity,str(b["operations"]["supplier"]),GameState.year_now()+maxi(1,int(TERMS[b["operations"]["supplier"]][0])))
func liquidation(b: Dictionary) -> Dictionary:
	var s := state(b); var stock_value := 0; var cancellation := 0
	for lot in s["lots"]:
		if op.catalog[b["ind"]]["products"][int(lot["product"])] ["physical"]: stock_value+=int(int(lot["basis"])*0.35)
	for c in s["contracts"]: cancellation+=int(int(c["quantity"])*int(c["unit_cost"])*0.10)
	var customer_fee := 0 if b["operations"]["active"].is_empty() else int(float(Empires.INDUSTRIES[b["ind"]]["cost"])*local_cost(b)*0.01)
	return {"cash":int(s["cash"]),"salvage":stock_value,"cancellation":cancellation,"customer_fee":customer_fee,"net":int(s["cash"])+stock_value-cancellation-customer_fee}
func yearly(b: Dictionary, year: int) -> void:
	var s := state(b)
	if not s["research"].is_empty() and year>int(s["research"]["due"]): s["research"]={}; s["last_research"]=year
func menu(page: String) -> Dictionary:
	var b: Dictionary=op.biz(); var s := state(b); var rows: Array=[]; var info: Array=[]
	if page=="inventory":
		info=["Batches are annual sales capacity. Services use appointment or contract places.","Orders reserve 3 batches. Supply bills are due in the delivery year's accounts."]
		for i in range(2):
			var p: Dictionary=op.catalog[b["ind"]]["products"][i]
			info.append(str(p["name"])+" · %d batches ready · base sale %s/batch" % [stock(b,i),GameState.fmt_money(unit_price(b,i,local_cost(b)))])
			for amount in [25,75,150]: rows.append(op.h.row("operations","Order %d · %s" % [amount,p["unit"]],"1 time · bill "+GameState.fmt_money(amount*unit_cost(b,i,str(op.st()["supplier"]),local_cost(b)))+" · lead "+("now" if int(TERMS[op.st()["supplier"]][0])==0 else "%d yr" % TERMS[op.st()["supplier"]][0]),"stock",{"product":i,"quantity":amount},not op.h.used("supply_contract:"+str(b["uid"])+":"+str(i)) and s["contracts"].size()<8))
		rows.append(op.h.row("operations","Two product lines"+(" ✓" if s["portfolio"] else ""),"1 time · demand split 75% main / 25% second","supply_policy",{"key":"portfolio","value":not s["portfolio"]},not op.h.used("supply_policy:"+str(b["uid"])+":portfolio")))
		for amount in [0,50,100,150]: rows.append(op.h.row("operations","Auto order: "+("off" if amount==0 else str(amount))+(" ✓" if int(s["auto"])==amount else ""),"1 time · total batch target; existing bills remain due","supply_policy",{"key":"auto","value":amount},int(s["auto"])!=amount and not op.h.used("supply_policy:"+str(b["uid"])+":auto")))
	elif page=="deliveries":
		info=["Value: 2 yr / 85% on time. Reliable: 1 yr / 97%. Specialist: next accounts / 99%.","A delay keeps the same bill. Changing suppliers keeps contracts; closing charges 10% cancellation."]
		for c in s["contracts"]: info.append(str(c["name"])+" · %d batches · due %d · %s%s" % [c["quantity"],c["due"],GameState.fmt_money(int(c["quantity"])*int(c["unit_cost"]))," · delayed" if c["delayed"] else ""])
		for c in s["deliveries"]: info.append("%d · %s · %s · %d batches" % [c["year"],c["name"],c["result"],c["quantity"]])
	elif page=="cash":
		info=["Company reserve: "+GameState.fmt_money(int(s["cash"])),"Profit counts sold stock costs. Cash flow pays the actual supplier bills.","Drawings need both profit and available cash. A shortfall requires owner funding."]
		for percentage in [10,25,50]:
			var fee := Actions._cost(int(Empires.INDUSTRIES[b["ind"]]["cost"])*percentage/100.0)
			rows.append(op.h.row("operations","Fund "+GameState.fmt_money(fee),"1 time · moves my money to company cash","company_fund",percentage,not op.h.used("company_funding:"+str(b["uid"]))))
	elif page=="facilities":
		info=["2 time per improvement · two levels each. All levels add annual upkeep.","Storage reduces damage and overhead; production adds 50 batches/level; research improves assessments."]
		for kind in ["storage","research","production"]:
			var level := int(s["facilities"][kind]); var fee := Actions._cost(int(Empires.INDUSTRIES[b["ind"]]["cost"])*0.12*(level+1))
			rows.append(op.h.row("operations",str(op.catalog[b["ind"]]["facilities"][kind])+" · %d/2" % level,"2 time · "+GameState.fmt_money(fee)+" · upkeep +"+GameState.fmt_money(Actions._cost(int(Empires.INDUSTRIES[b["ind"]]["cost"])*0.01))+"/year","facility",kind,level<2 and not op.h.used("facility:"+str(b["uid"])+":"+kind)))
	elif page=="research":
		info=["Two saved assessments per project. Skills, evidence and facilities affect success.","Each product can earn 3 insights; each adds 5% demand.","Current insights: %d / %d" % [s["insights"][0],s["insights"][1]]]
		rows.append(op.h.row("operations","Start research","1 time · "+GameState.fmt_money(Actions._cost(int(Empires.INDUSTRIES[b["ind"]]["cost"])*0.02)),"research",null,s["research"].is_empty() and int(s["insights"][int(op.st()["product"])])<3 and not op.h.used("market_research:"+str(b["uid"]))))
		if not s["research"].is_empty():
			info.append("Stage %d/2 · due %d" % [s["research"]["stage"],s["research"]["due"]])
			rows.append(op.h.row("operations","Continue research","1 time · assess the evidence","research_work"))
	if rows.is_empty(): rows.append(op.h.nav("operations","Stock & production","Change the supply plan","inventory"))
	return {"title":{"inventory":"Stock & production","deliveries":"Supply contracts","facilities":"Facilities","research":"Market research","cash":"Company cash"}[page],"icon":{"inventory":"📦","deliveries":"🚚","facilities":"🏗️","research":"🔎","cash":"🏦"}[page],"info":info,"rows":rows}
