extends RefCounted
var h
var catalog: Dictionary={}
var supply
var people
const SUPPLIERS := {"value":["Value supply",0.94,-0.025,-3.0],"steady":["Reliable supply",1.0,0.0,0.0],"specialist":["Specialist supply",1.06,0.045,2.0]}
const PRICES := {"accessible":["Accessible prices",1.12,-0.045],"standard":["Standard prices",1.0,0.0],"premium":["Premium prices",0.82,0.07]}
const PAY := {"minimum":["Minimum staffing budget",0.85,-9.0],"fair":["Fair staffing budget",1.0,2.0],"invest":["Training & fair pay",1.18,7.0]}
const SCALE := {"small":["Small batches",0.85,0.008],"steady":["Regular capacity",1.0,0.0],"stretch":["Stretch capacity",1.20,0.035]}
func _init(hub):
	h=hub
	supply=preload("res://systems/company_supply.gd").new(self)
	people=preload("res://systems/company_people.gd").new(self)
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/business_operations.json"))
func biz() -> Dictionary: return GameState.player.get("business",{})
func st(company: Dictionary = {}) -> Dictionary:
	var b := biz() if company.is_empty() else company
	if b.is_empty(): return {}
	if not b.has("operations"): b["operations"]={}
	var s: Dictionary=b["operations"]
	for key in {"product":0,"supplier":"steady","pricing":"standard","pay":"fair","scale":"steady","morale":55.0,"loyalty":40.0,"orders":[],"active":{},"report":{},"history":[],"changed":{},"serial":0,"quality_boost":0.0}:
		if not s.has(key): s[key]={"product":0,"supplier":"steady","pricing":"standard","pay":"fair","scale":"steady","morale":55.0,"loyalty":40.0,"orders":[],"active":{},"report":{},"history":[],"changed":{},"serial":0,"quality_boost":0.0}[key]
	if not b.has("uid"): b["uid"]=h.uid()+":business:"+str(b.get("founded",0))+":"+str(b.get("name",""))
	supply.state(b)
	return s
func current(company: Dictionary = {}) -> Dictionary:
	var b := biz() if company.is_empty() else company
	var s := st(b)
	return {} if s.is_empty() else catalog[str(b["ind"])]["products"][int(s["product"])]
func set_option(key: String, value: Variant) -> void:
	var s := st()
	if s.is_empty() or h.blocked(18)!="" or int(s["changed"].get(key,-1))==GameState.year_now(): return
	if key=="product":
		if int(value)<0 or int(value)>=catalog[biz()["ind"]]["products"].size(): return
	elif not {"supplier":SUPPLIERS,"pricing":PRICES,"pay":PAY,"scale":SCALE}.get(key,{}).has(str(value)): return
	if s.get(key)==value: return
	# The signed order is for this product, so an owner cannot swap it away.
	if key=="product" and not s["active"].is_empty(): return
	if not h.pay("business_option:"+str(biz()["uid"])+":"+key,1,0,18): return
	s[key]=value; s["changed"][key]=GameState.year_now()
	h.done("🏪","Operating plan changed","The new plan applies to the next annual accounts. This setting can change once a year; existing costs and promises remain due.")
func modifiers(company: Dictionary = {}) -> Dictionary:
	var b := biz() if company.is_empty() else company
	var s := st(b); var product := current(b)
	var supply: Array=SUPPLIERS[s["supplier"]]; var price: Array=PRICES[s["pricing"]]; var scale: Array=SCALE[s["scale"]]
	var loyalty := 0.90+float(s["loyalty"])/400.0
	var readiness := 0.85+float(s["morale"])/350.0
	var premium := 1.0
	if s["pricing"]=="premium" and float(b["quality"])<70: premium=0.72
	return {"revenue":float(product["demand"])*float(supply[1])*float(price[1])*float(scale[1])*loyalty*readiness*premium,"margin":float(product["margin"])-float(supply[2])+float(price[2])-float(scale[2]),"payroll":float(PAY[s["pay"]][1]),"quality":float(supply[3])+float(s["quality_boost"]),"premium_penalty":premium<1.0}
func order() -> void:
	var s := st()
	if s.is_empty() or not s["active"].is_empty() or supply.stock(biz(),int(s["product"]))<3 or not h.pay("business_order:"+str(biz()["uid"]),1,0,18): return
	supply.reserve_for_order(biz(),int(s["product"]))
	s["serial"]=int(s["serial"])+1
	var customer: Dictionary={}
	if not s["orders"].is_empty() and float(s["loyalty"])>=50:
		customer=s["orders"][0].get("customer",{}).duplicate(true)
	if customer.is_empty(): customer={"uid":str(biz()["uid"])+":client:"+str(s["serial"]),"name":Names.company("Business",str(GameState.player["country"]))}
	s["active"]={"id":s["serial"],"owner":biz()["uid"],"product":s["product"],"customer":customer,"stage":0,"quality":35.0,"due":GameState.year_now(),"roll":randf(),"choices":[]}
	h.done("📋","A customer order",str(customer["name"])+" wants "+str(current()["name"])+". Two work stages are due this year. It uses regular sales capacity; payment is included in annual revenue, with no separate cash prize.")
func work() -> void:
	var s := st()
	if s.is_empty() or s["active"].is_empty() or not h.pay("business_work:"+str(biz()["uid"])+":"+str(s["active"]["id"])+":"+str(s["active"]["stage"]),1,0,18): return
	var a: Dictionary=s["active"]
	var choices: Array=["Check the actual requirements","Offer a smaller clear scope","Promise the fastest full order"] if int(a["stage"])==0 else ["Test before the handover","Agree an honest limited delivery","Send it without checking"]
	h.decision("operations","work",{"owner":biz()["uid"],"id":a["id"],"stage":a["stage"]},str(a["customer"]["name"]),"The order needs a workable scope." if int(a["stage"])==0 else "The customer is ready for the handover. Quality, staff morale and my business skills influence delivery.",choices)
func finish(result: String, success: bool) -> void:
	var s := st(); var a: Dictionary=s["active"]
	if a.is_empty(): return
	a["result"]=result; a["ended"]=GameState.year_now(); a["success"]=success
	supply.return_reservation(biz(),int(a["product"]),success)
	s["loyalty"]=clampf(float(s["loyalty"])+(10.0 if success else -12.0),0,100)
	s["quality_boost"]=float(s["quality_boost"])+(2 if success else -3)
	var fee := 0 if success else Actions._cost(maxi(100,int(Empires.INDUSTRIES[biz()["ind"]]["cost"])*0.01))
	GameState.player["money"]=int(GameState.player["money"])-fee
	a["fee"]=fee; s["orders"].push_front(a.duplicate(true)); s["active"]={}
	if s["orders"].size()>16: s["orders"].resize(16)
	if success: Market.learn("Business",1)
	h.note("Customer order",str(a["customer"]["name"])+" · "+result+" · remedial cost "+GameState.fmt_money(fee)+". Customer loyalty is now %d/100." % s["loyalty"])
func incident() -> void:
	var s := st()
	if s.is_empty() or h.blocked(18)!="": return
	var scene: Dictionary=Novelty.pick(catalog[biz()["ind"]]["scenes"])
	if scene.is_empty() or not h.pay("business_issue:"+str(biz()["uid"]),1,0,18): return
	Novelty.note(scene)
	var options: Array=[]
	for choice in scene["choices"]:
		var option := {"label":choice["label"]}
		if int(choice.get("cost",0))>0: option["requires"]={"money":Actions._cost(int(choice["cost"]))}
		options.append(option)
	h.decision("operations","issue",{"owner":biz()["uid"],"scene":scene},str(scene["title"]),str(scene["text"]),options)
func resolve(op: String, args: Dictionary, answer: int) -> void:
	var s := st()
	if s.is_empty() or str(args.get("owner",""))!=str(biz()["uid"]): return
	if op=="work":
		var a: Dictionary=s["active"]
		if a.is_empty() or int(args["id"])!=int(a["id"]) or int(args["stage"])!=int(a["stage"]) or answer<0 or answer>2: return
		a["choices"].append(answer); a["quality"]=clampf(float(a["quality"])+[20,12,-5][answer]+Aptitude.score("work")/8.0,0,100); a["stage"]+=1
		if int(a["stage"])==2:
			var chance := clampf((float(a["quality"])*0.55+float(biz()["quality"])*0.25+float(s["morale"])*0.2)/100.0,0.05,0.95)
			var good := float(a["roll"])<chance
			finish("Delivered reliably" if good else "Delivery needed rework",good)
			h.done("📦","Customer handover","Success chance %d%%. %s" % [roundi(chance*100),"The customer will consider returning." if good else "The remedial bill is paid now; loyalty and the next annual quality review fall."])
		else: h.done("📋","Scope agreed","One stage remains this year. The promised scope is saved with the order.")
	elif op=="research": supply.resolve(args,answer)
	elif op=="apprentice": people.resolve(args,answer)
	elif op=="issue":
		var scene: Dictionary=args["scene"]
		if answer<0 or answer>=scene["choices"].size(): return
		var choice: Dictionary=scene["choices"][answer]; var cost := Actions._cost(int(choice.get("cost",0)))
		if int(GameState.player["money"])<cost and cost>0: return
		GameState.player["money"]=int(GameState.player["money"])-cost
		for key in ["morale","loyalty"]: s[key]=clampf(float(s[key])+float(choice.get(key,0)),0,100)
		biz()["quality"]=clampf(float(biz()["quality"])+float(choice.get("quality",0)),5,100)
		h.done("🏪",str(scene["title"]),str(choice["result"])+" Cost "+GameState.fmt_money(cost)+". The changes affect future quality, customer demand or staffing.",choice.get("effects",{}))
func accounts(revenue: int, payroll: int, interest: int, profit: int, draw: int, mods: Dictionary, company: Dictionary = {}, active: bool = true) -> void:
	var b := biz() if company.is_empty() else company
	var s := st(b)
	var report := {"year":GameState.year_now(),"product":current(b)["name"],"revenue":revenue,"payroll":payroll,"interest":interest,"operating_cost":revenue-payroll-interest-profit,"profit":profit,"draw":draw,"plan":{"supplier":s["supplier"],"pricing":s["pricing"],"pay":s["pay"],"scale":s["scale"]},"premium_penalty":mods["premium_penalty"]}
	report["stock"]=supply.state(b)["ledger"].duplicate(true)
	s["report"]=report; s["history"].push_front(report.duplicate(true))
	if s["history"].size()>24: s["history"].resize(24)
	s["morale"]=clampf(float(s["morale"])+float(PAY[s["pay"]][2])-(6 if s["scale"]=="stretch" else 0),0,100)
	s["loyalty"]=clampf(float(s["loyalty"])+(2 if float(b["quality"])>=70 else -3 if float(b["quality"])<35 else 0),0,100)
	s["quality_boost"]=0.0
	# Positive business drawings join the already-paid income ledger, not salary twice.
	if active and draw>0: Employment.record_income("Business drawings",draw)
	if active and draw<0: Employment.record_expense("Business loss coverage",-draw)
func remember_crew(company: Dictionary, cast: Dictionary) -> void:
	company["crew_uids"]=[]
	for id in company.get("crew",[]):
		if cast.has(id): company["crew_uids"].append(FamilyChronicle.identity(cast[id]))
func rebind() -> void:
	var b := biz()
	if b.is_empty() or not b.has("crew_uids"): return
	if b.get("cooked",false): GameState.set_flag("cooked_books")
	else: GameState.clear_flag("cooked_books")
	b["crew"]=[]
	for uid0 in b["crew_uids"]:
		var id: String=h.person(str(uid0))
		if id!="" and GameState.npc(id).get("alive",false): b["crew"].append(id)
func successor(id: String) -> void:
	if biz().is_empty() or id not in GameState.npcs_with("child"): return
	var n := GameState.npc(id)
	if int(n["age"])<18 or not n.get("business",n.get("playable_player",{}).get("business",{})).is_empty() or not h.pay("operating_successor",1,0,18): return
	st(); biz()["successor_uid"]=FamilyChronicle.identity(n)
	h.done("📜","Company successor named",str(n["first"])+" is the intended operator after my death. Estate debts and taxes come first. An ineligible successor or an insolvent company can still require a sale.")
func handover(id: String) -> void:
	if id not in GameState.npcs_with("child") or int(GameState.npc(id)["age"])<18 or biz().is_empty(): return
	var n := GameState.npc(id)
	if not n.get("business",n.get("playable_player",{}).get("business",{})).is_empty() or not h.pay("operating_handover",2,Actions._cost(500),18): return
	var b := biz(); st(); people.transition(b,id); remember_crew(b,GameState.npcs)
	b["country"]=GameState.player["country"]; b["local_cost"]=Places.cost_mult()
	b["family_handover"]={"from":h.uid(),"to":FamilyChronicle.identity(n),"year":GameState.year_now()}
	n["business"]=b.duplicate(true); GameState.player["business"]={}; GameState.clear_flag("cooked_books")
	if n.has("playable_player"): n["playable_player"]["business"]=n["business"].duplicate(true)
	FamilyChronicle.remember(id,"Took ownership of "+str(b["name"])+" and its operating obligations.","good")
	h.done("🏪","Company handed over",str(b["name"])+" belongs to "+str(n["first"])+". Products, staff, debts and orders remain with the company. This is a gift of ownership, with no sale payment.")
func background(n: Dictionary, year: int) -> void:
	var b: Dictionary=n.get("business",n.get("playable_player",{}).get("business",{}))
	if b.is_empty() or int(b.get("settled_year",-1))==year or not n.get("alive",false): return
	if not b.has("uid"): b["uid"]=FamilyChronicle.identity(n)+":business:"+str(b.get("founded",0))+":"+str(b.get("name",""))
	b["settled_year"]=year
	var s := st(b)
	people.review(b,year)
	supply.yearly(b,year)
	if not s["active"].is_empty() and year>int(s["active"]["due"]):
		var a: Dictionary=s["active"]; var fee := maxi(100,int(Empires.INDUSTRIES[b["ind"]]["cost"])*0.01)
		fee=int(fee*float(ContentDB.country(str(b.get("country",n.get("country","us")))).get("cost",1.0)))
		supply.return_reservation(b,int(a["product"]),false)
		n["money"]=int(n.get("money",0))-fee; a["fee"]=fee; a["result"]="Deadline missed"; a["ended"]=year; a["success"]=false
		s["orders"].push_front(a.duplicate(true)); s["orders"]=Array(s["orders"]).slice(0,16); s["active"]={}
		s["loyalty"]=maxf(0,float(s["loyalty"])-12); s["quality_boost"]=float(s["quality_boost"])-3
	var crew := 0
	for uid0 in b.get("crew_uids",[]):
		var id: String=h.person(str(uid0))
		if id!="" and GameState.npc(id).get("alive",false): crew+=1
	var cost := float(ContentDB.country(str(b.get("country",n.get("country","us")))).get("cost",1.0))*float(b.get("local_cost",1.0))
	var numbers := Empires.business_numbers(b,float(n.get("fame",0)),crew,cost,1.0,1.0,0.0)
	Empires.settle_business(b,numbers,cost)
	var draw := int(numbers["draw"])
	n["money"]=int(n.get("money",0))+draw
	accounts(int(numbers["rev"]),int(numbers["payroll"]),int(numbers["interest"]),int(numbers["profit"]),draw,numbers["mods"],b,false)
	if int(numbers["profit"])<0 and int(n["money"])<0 and int(b["debt"])>int(b["value"])*0.5:
		n["business_history"]=n.get("business_history",[]); n["business_history"].push_front({"name":b["name"],"year":year,"result":"Bankrupt"}); n["business_history"]=Array(n["business_history"]).slice(0,16); b={}
	n["business"]=b
	if n.has("playable_player"): n["playable_player"]["business"]=b.duplicate(true); n["playable_player"]["money"]=n["money"]
func yearly() -> void:
	var s := st()
	if s.is_empty(): return
	people.review(biz(),GameState.year_now())
	supply.yearly(biz(),GameState.year_now())
	if not s["active"].is_empty() and GameState.year_now()>int(s["active"]["due"]): finish("Deadline missed",false)
func navigation(name: String, sub: String, page: String) -> Dictionary:
	var row: Dictionary=h.nav("operations",name,sub,page)
	row["icon"]={"product":"📦","supplier":"🚚","pricing":"🏷️","pay":"👥","scale":"🏗️","records":"🧾","family":"🌳","inventory":"📦","deliveries":"🚚","facilities":"🏗️","research":"🔎","cash":"🏦"}[page]
	return row
func menu(page: String) -> Dictionary:
	var s := st()
	if s.is_empty(): return {"title":"Company operations","icon":"🏪","info":["Start a company in Occupation → Business first."],"rows":[]}
	if page=="people": return people.menu()
	if page in ["inventory","deliveries","facilities","research","cash"]: return supply.menu(page)
	var info: Array=[str(biz()["name"])+" · "+str(current()["name"]),"Loyalty %d · morale %d. Changes: 1 time, once a year." % [s["loyalty"],s["morale"]],"Premium needs quality 70+. Cheap supply lowers quality; extra capacity strains staff."]
	var rows: Array=[]
	var tables := {"supplier":SUPPLIERS,"pricing":PRICES,"pay":PAY,"scale":SCALE}
	if page=="product":
		info=["1 time to change · once a year. A signed order keeps its original product until delivery or expiry."]
		for i in range(catalog[biz()["ind"]]["products"].size()):
			var product: Dictionary=catalog[biz()["ind"]]["products"][i]
			rows.append(h.row("operations",str(product["name"])+( " ✓" if i==int(s["product"]) else ""),str(product["description"]),"set",{"key":"product","value":i},i!=int(s["product"]) and s["active"].is_empty() and int(s["changed"].get("product",-1))!=GameState.year_now()))
		return {"title":"Products & services","icon":"📦","info":info,"rows":rows}
	if tables.has(page):
		var options: Dictionary=tables[page]
		var descriptions := {
			"supplier":{"value":"Supply demand −6% · cheaper inputs · quality −3/year","steady":"Balanced inputs and supply reliability","specialist":"Supply demand +6% · cost +4.5 points · quality +2/year"},
			"pricing":{"accessible":"Demand +12% · margin −4.5 points","standard":"Balanced demand and margin","premium":"Demand −18% · margin +7 points · needs quality 70+"},
			"pay":{"minimum":"Payroll −15% · morale −9/year","fair":"Normal payroll · morale +2/year","invest":"Payroll +18% · morale +7/year"},
			"scale":{"small":"Capacity −15% · cost +0.8 points","steady":"Regular capacity and costs","stretch":"Capacity +20% · cost +3.5 points · morale −6/year"}}
		for value in options:
			var name := str(catalog[biz()["ind"]]["suppliers"][value]) if page=="supplier" else str(options[value][0])
			rows.append(h.row("operations",name+(" ✓" if s[page]==value else ""),descriptions[page][value],"set",{"key":page,"value":value},s[page]!=value and int(s["changed"].get(page,-1))!=GameState.year_now()))
		return {"title":{"supplier":"Suppliers","pricing":"Pricing","pay":"Staff conditions","scale":"Capacity"}[page],"icon":"🏪","info":["1 time · once a year. The next accounts use this plan. Cost points are a share of revenue."],"rows":rows}
	if page not in ["records","family"]:
		rows.append(navigation("Products & services",str(current()["name"]),"product"))
		for key in tables: rows.append(navigation({"supplier":"Suppliers","pricing":"Pricing","pay":"Staff conditions","scale":"Capacity"}[key],str(catalog[biz()["ind"]]["suppliers"][s[key]]) if key=="supplier" else str(tables[key][s[key]][0]),key))
		rows.append(navigation("Orders & accounts","Customer history and annual figures","records"))
		for extra in ["inventory","deliveries","facilities","research","cash"]:
			rows.append(navigation({"inventory":"Stock & production","deliveries":"Supply contracts","facilities":"Facilities","research":"Market research","cash":"Company cash"}[extra],{"inventory":"Two product stocks and order targets","deliveries":"Delivery dates, risk and bills","facilities":"Capacity, storage and research tools","research":"Evidence with lasting product insights","cash":"Working reserves and owner drawings"}[extra],extra))
		rows.append(h.nav("operations","Company people","Profiles, coaching and development","people"))
		rows.append(navigation("Family succession","Plan inheritance or transfer ownership","family"))
	if page in ["records","family"]: info=[]
	if page in ["","records"]:
		rows.append(h.row("operations","Customer order","1 time · reserves 3 batches · 2 work stages","order",null,supply.stock(biz(),int(s["product"]))>=3 and s["active"].is_empty() and not h.used("business_order:"+str(biz()["uid"]))))
		if not s["active"].is_empty():
			info.append(str(s["active"]["customer"]["name"])+" · work %d/2 · due %d" % [s["active"]["stage"],s["active"]["due"]])
			rows.append(h.row("operations","Work on the order","1 time per stage · two saved decisions","work"))
	if page=="": rows.append(h.row("operations","Handle an industry issue","1 time · once a year · each scene appears once","issue",null,not h.used("business_issue:"+str(biz()["uid"])) and catalog[biz()["ind"]]["scenes"].any(func(scene): return Novelty.eligible(scene))))
	if page=="family":
		info=["Handovers transfer ownership and debt. Inheritance follows estate bills. One operating company per person.","Prepared handover: three lessons and readiness 60+ · morale +4; otherwise −4. Training is optional."]
		var successor_id: String=h.person(str(biz().get("successor_uid","")))
		if successor_id!="": info.append("Intended successor: "+GameState.full_name(successor_id))
		for id in GameState.npcs_with("child"):
			var n := GameState.npc(id)
			var uid := FamilyChronicle.identity(n)
			var training: Dictionary=people.state(biz())["trainees"].get(uid,{})
			rows.append({"icon":Bonds.U_face(n),"name":GameState.full_name(id),"sub":"Readiness %d · lessons %d/3" % [int(training.get("readiness",0)),int(training.get("stage",0))],"menu":"bond:"+str(id)})
			rows.append(h.row("operations","Prepare "+str(n["first"]),"1 time · "+GameState.fmt_money(Actions._cost(150))+" · one lesson/year","apprentice",id,int(n["age"])>=18 and float(training.get("readiness",0))<100 and n.get("business",n.get("playable_player",{}).get("business",{})).is_empty() and not h.used("company_apprentice:"+str(biz()["uid"])+":"+uid) and (not training.is_empty() or people.state(biz())["trainees"].size()<32)))
			rows.append(h.row("operations","Name "+str(n["first"])+" as successor","1 time · death plan; ownership stays with me","successor",id,int(n["age"])>=18 and n.get("business",n.get("playable_player",{}).get("business",{})).is_empty() and not h.used("operating_successor")))
			rows.append(h.row("operations","Hand over to "+str(n["first"]),"2 time · "+GameState.fmt_money(Actions._cost(500))+" · transfers ownership and obligations","handover",id,int(n["age"])>=18 and n.get("business",n.get("playable_player",{}).get("business",{})).is_empty()))
		if rows.is_empty(): info.append("No living children are available.")
	if page=="records":
		for report in s["history"]:
			info.append("%d · %s\nRevenue %s · operating costs %s\nPayroll %s · interest %s\nProfit %s · owner draw %s%s" % [report["year"],report["product"],GameState.fmt_money(report["revenue"]),GameState.fmt_money(report["operating_cost"]),GameState.fmt_money(report["payroll"]),GameState.fmt_money(report["interest"]),GameState.fmt_money(report["profit"]),GameState.fmt_money(report["draw"]),"\nPremium demand fell below quality 70" if report["premium_penalty"] else ""])
		for report in s["history"]:
			var stock_report: Dictionary=report.get("stock",{})
			if not stock_report.is_empty(): info.append("Stock · sold %s · missed %d\nSupply bills %s · cost of sales %s · write-offs %s\nCompany cash %s · cash flow %s" % [str(stock_report["sold"]),stock_report["missed"],GameState.fmt_money(stock_report["purchases"]),GameState.fmt_money(stock_report["cost_of_sales"]),GameState.fmt_money(stock_report["writeoff"]),GameState.fmt_money(stock_report["cash"]),GameState.fmt_money(stock_report["cash_flow"])])
		for order0 in s["orders"]: info.append(str(order0["customer"]["name"])+" · "+str(order0["result"])+" · remedial cost "+GameState.fmt_money(int(order0["fee"])))
		if info.is_empty(): info.append("Orders and annual accounts will appear here.")
	return {"title":"Company operations","icon":"🏪","info":info,"rows":rows}
func act(key: String, arg: Variant) -> void:
	match key:
		"stock": if arg is Dictionary: supply.place(int(arg["product"]),int(arg["quantity"]))
		"supply_policy": if arg is Dictionary: supply.policy(str(arg["key"]),arg["value"])
		"facility": supply.upgrade(str(arg))
		"company_fund": supply.fund(int(arg))
		"research": supply.research()
		"research_work": supply.research_work()
		"set": if arg is Dictionary: set_option(str(arg["key"]),arg["value"])
		"order": order()
		"work": work()
		"issue": incident()
		"handover": handover(str(arg))
		"successor": successor(str(arg))
		"apprentice": people.apprentice(str(arg))
		"staff_train": if arg is Array: people.train(str(arg[0]),str(arg[1]))
