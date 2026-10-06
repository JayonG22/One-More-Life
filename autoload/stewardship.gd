extends Node
const Icons := preload("res://scenes/icons.gd")

func st() -> Dictionary:
	var s := Journey.section("stewardship",{"saving":0,"cash_floor":0,"last_year":-1,"retainers":[],"history":[]})
	# Earlier saves could enable both the workplace 5% buffer and the separate
	# surplus plan. Fold that legacy choice into this single personal-savings plan.
	if not bool(s.get("legacy_buffer_migrated",false)):
		var employment: Dictionary=GameState.player.get("employment",{})
		if bool(employment.get("buffer",false)):
			if int(s.get("saving",0))==0: s["saving"]=5
			s["cash_floor"]=maxi(int(s.get("cash_floor",0)),2500)
			employment["buffer"]=false
		s["legacy_buffer_migrated"]=true
	return s
func forecast() -> Dictionary:
	var p := GameState.player
	if Childhood.supported() or GameState.in_prison(): return {"income":0,"bills":0,"balance":int(p["money"]),"supported":true}
	var cost := float(ContentDB.country(p["country"]).get("cost",1.0))*Grit.d("cost")*World.cost_mult()*Places.cost_mult()
	var base := 2500 if p["housing"]=="parents" else 6000 if p["housing"]=="dorm" else 11000
	if p["housing"]=="apartment": base+=Tenancy.annual_rent()
	base+=Real.extra_costs()+Household.service_cost()
	if p["car"]!="": base+=int(GameState.CARS[p["car"]]["upkeep"])
	for id in GameState.npcs_with("child")+GameState.npcs_with("stepchild"):
		if int(GameState.npc(id)["age"])<18: base+=int(7000*Journey.modules["people"].support_factor(id))
	base+=mini(int(p["mortgage"]),int(p["mortgage_payment"]))
	var income := int(int(p["job"].get("salary",0))*Employment.pay_factor()*(1-Places.tax())) if GameState.has_job() else int(p.get("pension",0))
	var bills := int(base*cost)
	return {"income":income,"bills":bills,"balance":int(p["money"])+income-bills,"supported":false}
func finish_year() -> void:
	var s := st(); var year := GameState.year_now()
	if int(s["last_year"])==year or Lives.separate(): return
	s["last_year"]=year
	if not Childhood.supported() and not GameState.in_prison():
		var amount := mini(maxi(0,int(GameState.player["money"])),int(maxi(0,int(GameState.player.get("last_income",0))-int(GameState.player.get("last_expenses",0)))*int(s["saving"])/100.0))
		amount=mini(amount,maxi(0,int(GameState.player["money"])-Actions._cost(int(s.get("cash_floor",0)))))
		if amount>0:
			GameState.player["money"]-=amount; GameState.player["savings"]+=amount
			Finance.record_transfer("Personal savings",amount)
			GameState.add_log("I moved "+GameState.fmt_money(amount)+" of this year's surplus to savings. It is still my money.")
	review_contracts(s,Employment.st()["clients"],year)
func review_contracts(s: Dictionary, clients: Array, year: int) -> void:
	for contract in s.get("retainers",[]):
		if contract["state"]!="active": continue
		var client: Dictionary={}
		for candidate in clients:
			if candidate["id"]==contract["client"]: client=candidate
		if year>int(contract["reviewed"]):
			if int(contract["delivered_year"])<int(contract["reviewed"]):
				contract["missed"]+=1
				if not client.is_empty(): client["trust"]=maxf(0,float(client["trust"])-8)
				GameState.add_log("A continuing client recorded a missed retainer commitment. No payment was created.")
			contract["reviewed"]=year
		if year>int(contract["due"]) or int(contract["missed"])>=2 or client.is_empty() or Journey.person(str(client.get("contact","")))=="" or not GameState.npc(Journey.person(str(client.get("contact","")))).get("alive",false):
			contract["state"]="closed"
			s["history"].push_front(contract.duplicate(true))
	if s["history"].size()>20: s["history"].resize(20)
	s["retainers"]=s["retainers"].filter(func(c): return c["state"]=="active")
func accept(id: String) -> void:
	var client := Employment.find_client(id)
	if Journey.blocked(18)!="" or client.is_empty() or not GameState.has_job() or GameState.player["job"]["field"]!=client["field"] or float(client["trust"])<65 or int(client["completed"])<2 or st()["retainers"].size()>=2: return
	var person := Journey.person(str(client.get("contact","")))
	if person=="" or not GameState.npc(person).get("alive",false) or st()["retainers"].any(func(c): return c["client"]==id) or Journey.used("retainer:"+id): return
	if not GameState.spend_time(1): return
	Journey.mark("retainer:"+id)
	st()["retainers"].append({"paid_work":0,"client":id,"field":client["field"],"session":Employment.job_session(),"due":GameState.year_now()+2,"reviewed":GameState.year_now(),"delivered_year":-1,"delivered":0,"missed":0,"state":"active","roll":randf(),"roll_year":GameState.year_now(),"fee":clampi(int(GameState.player["job"]["salary"])*4/100,1000,12000)})
	Journey.done("🤝","Retainer agreed","Three yearly deliveries, including this year. Each takes time. Missed work lowers trust; two misses end the agreement. The client pays only for actual delivery.")
func deliver(index: int, approach: int) -> void:
	if Journey.blocked(18)!="" or index<0 or index>=st()["retainers"].size() or approach not in [0,1,2]: return
	var c: Dictionary=st()["retainers"][index]; var year := GameState.year_now()
	var client := Employment.find_client(str(c["client"]))
	var person := Journey.person(str(client.get("contact","")))
	if c["state"]!="active" or int(c["delivered_year"])==year or year>int(c["due"]) or client.is_empty() or person=="" or not GameState.npc(person).get("alive",false): return
	if not GameState.has_job() or GameState.player["job"]["field"]!=c["field"] or Employment.job_session()!=int(c["session"]): return
	if not GameState.spend_time(2 if approach==0 else 1): return
	if int(c["roll_year"])!=year: c["roll"]=randf(); c["roll_year"]=year
	c["delivered_year"]=year; c["delivered"]+=1
	var passed := float(c["roll"])<Aptitude.chance(0.80 if approach==0 else 0.60,"work")
	var amount := int(int(c["fee"])*(1.0 if passed else 0.5)*(0.65 if approach==1 else 1.0)*(1-Places.tax())) if approach!=2 else 0
	if passed and approach!=2: c["paid_work"]=int(c.get("paid_work",0))+1
	GameState.player["money"]+=amount; Employment.record_income("Client retainers",amount)
	client["trust"]=clampf(float(client["trust"])+(5 if passed and approach==0 else 2 if passed and approach==1 else 1 if approach==2 else -3),0,100)
	GameState.change_stat("stress",-4 if approach==2 else 2 if approach==0 else 1)
	FamilyChronicle.remember(person,"Continuing agreement: "+["full delivery","smaller agreed scope","unpaid renegotiation"][approach]+".","neutral")
	if int(c.get("paid_work",0))>=3 and float(client["trust"])>=70 and approach!=2: client["reference"]=true
	Journey.done("📋","Client commitment",["Full scope","Reduced scope","Renegotiated without payment"][approach]+" · "+GameState.fmt_money(amount)+" · trust "+str(int(client["trust"]))+". This year is recorded; it cannot pay again.")
func menu(page: String) -> Dictionary:
	var rows: Array=[]; var info: Array=[]
	if page=="vehicles":
		info=["Second Lap Autos · listings stay the same for the year and survive saves. Mileage is declared; an inspection reveals condition. Buying replaces your current car with its resale value credited."]
		for i in range(used_market().size()):
			var car: Dictionary=used_market()[i]
			if car.get("sold",false): continue
			var name := str(GameState.CARS[car["model"]]["name"])
			rows.append({"name":name,"sub":"%d years · %d km · %s · %s" % [car["years"],car["mileage"],"condition "+str(int(car["condition"]))+"/100" if car["inspected"] else "condition unknown",GameState.fmt_money(int(car["asking"]))],"icon":"@"+Icons.for_car(car["model"]),"act":"balance:used_buy","arg":i,"on":int(GameState.player["age"])>=16})
			rows.append({"name":"Inspect "+name,"sub":"1 time · "+GameState.fmt_money(Actions._cost(150))+" · no hidden-condition reroll","icon":"🔎","act":"balance:used_inspect","arg":i,"on":not car["inspected"]})
	elif page=="clients":
		info=["Retainers require two completed projects and trust 65+. At most two can run together. Changing jobs prevents delivery under the old employment agreement."]
		for client in Employment.st()["clients"]:
			if st()["retainers"].any(func(c): return c["client"]==client["id"]): continue
			var person := Journey.person(str(client.get("contact","")))
			var available: bool=person!="" and GameState.npc(person).get("alive",false) and GameState.has_job() and GameState.player["job"]["field"]==client["field"] and st()["retainers"].size()<2 and not Journey.used("retainer:"+str(client["id"]))
			rows.append({"name":"Retainer: "+str(client["name"]),"sub":"3 years · 1 time to agree · delivery takes 1–2 time/year","icon":"🤝","act":"balance:accept","arg":client["id"],"on":available and int(client["completed"])>=2 and float(client["trust"])>=65})
		for i in range(st()["retainers"].size()):
			var c: Dictionary=st()["retainers"][i]
			var name := str(Employment.find_client(str(c["client"])).get("name","Former client"))
			info.append(name+" · deliveries "+str(c["delivered"])+" · missed "+str(c["missed"])+" · ends "+str(c["due"]))
			for choice in range(3): rows.append({"name":name+" · "+["Full delivery","Smaller scope","Unpaid renegotiation"][choice],"sub":["2 time · better success chance","1 time · lower pay and success chance","1 time · reduce pressure; protect the relationship"][choice],"icon":"📋","act":"balance:deliver","arg":{"index":i,"approach":choice},"on":int(c["delivered_year"])!=GameState.year_now()})
	else:
		var s := st()
		var f := forecast()
		info=["Planning estimate: work/pension "+GameState.fmt_money(int(f["income"]))+" · ordinary bills "+GameState.fmt_money(int(f["bills"]))+" · projected cash "+GameState.fmt_money(int(f["balance"])),"This estimate excludes investments, optional purchases, repairs, unexpected events, museum results and loan repayments. It is not another bill.","Cash "+GameState.fmt_money(int(GameState.player["money"]))+" · savings "+GameState.fmt_money(int(GameState.player["savings"]))]
		info.append("Personal plan: %d%% of surplus · cash floor %s." % [int(s["saving"]),GameState.fmt_money(Actions._cost(int(s.get("cash_floor",0))))])
		for percent in [0,5,10,20,30]: rows.append({"name":("✓ " if int(s["saving"])==percent else "")+"Save "+str(percent)+"% of surplus","sub":"Once yearly after bills and loans · moves cash into personal savings","icon":"🏦","act":"balance:saving","arg":percent})
		for floor in [0,1000,2500,5000]: rows.append({"name":("✓ " if int(s.get("cash_floor",0))==floor else "")+"Cash floor: "+GameState.fmt_money(Actions._cost(floor)),"sub":"Keep this amount in cash before saving","icon":"💵","act":"balance:floor","arg":floor})
		rows.append({"name":"Recurring client agreements","sub":"Continuing work, deadlines and real payments","icon":"🤝","menu":"balance:clients"})
	return {"title":"Second Lap Autos" if page=="vehicles" else "Recurring clients" if page=="clients" else "Planning & commitments","icon":"🧭","rows":rows,"info":info}
func act(key: String, arg: Variant) -> void:
	if key=="saving" and int(arg) in [0,5,10,20,30] and Journey.blocked()=="":
		st()["saving"]=int(arg)
		SaveManager.save_game()
	elif key=="floor" and int(arg) in [0,1000,2500,5000] and Journey.blocked()=="":
		st()["cash_floor"]=int(arg)
		SaveManager.save_game()
	elif key=="accept": accept(str(arg))
	elif key=="deliver" and arg is Dictionary: deliver(int(arg["index"]),int(arg["approach"]))
	elif key in ["used_buy","used_inspect"]: used_action(int(arg),key=="used_inspect")

func used_market() -> Array:
	var s := st(); var year := GameState.year_now()
	if int(s.get("market_year",-1))!=year:
		s["market_year"]=year; s["cars"]=[]
		for model in GameState.CARS:
			var car := {"model":model,"years":randi_range(3,14),"mileage":randi_range(30000,180000),"condition":float(randi_range(45,90)),"price":Actions._cost(int(GameState.CARS[model]["price"])),"inspected":false,"sold":false}
			car["asking"]=maxi(300,int(Holdings.resale({"car":model,"car_record":car})*1.10))
			s["cars"].append(car)
	return s["cars"]
func used_action(index: int, inspect: bool) -> void:
	if Journey.blocked(16)!="" or index<0 or index>=used_market().size(): return
	var car: Dictionary=used_market()[index]
	if car["sold"]: return
	var trade := 0 if inspect else Holdings.resale()
	var fee := Actions._cost(150) if inspect else int(car["asking"])-trade
	if inspect and car["inspected"] or int(GameState.player["money"])<maxi(0,fee) or not GameState.spend_time(1): return
	GameState.player["money"]-=fee
	if inspect:
		car["inspected"]=true
		Journey.done("🔎","Inspection complete","Condition %d/100 · %d km · age %d. The result stays with this listing." % [car["condition"],car["mileage"],car["years"]])
	else:
		GameState.player["car"]=car["model"]; Holdings.new_car(str(car["model"]),int(car["price"]))
		for field in ["years","mileage","condition"]: Holdings.car()[field]=car[field]
		car["sold"]=true
		Journey.done("🚗","Used car bought","Paid %s; previous-car credit %s. Condition %d/100 and wear now belong to this car. A driving licence is still required to drive it." % [GameState.fmt_money(int(car["asking"])),GameState.fmt_money(trade),car["condition"]])
