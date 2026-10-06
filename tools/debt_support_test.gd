extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func clear() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear(); Journey.state()["prompt"]={}
func fresh(age: int = 35) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false,"born_year":1980})
	GameState.player["age"]=age; GameState.player["time_left"]=200; GameState.player["money"]=10000; GameState.player["last_income"]=40000; GameState.player["credit"]=800
	clear()
func loan(lender: String = "bank", left: int = 10000, pay: int = 2000) -> Dictionary:
	Lending.debts().append({"lender":lender,"principal":left,"left":left,"payment":pay,"rate":0.1,"term":5,"taken_age":GameState.player["age"],"missed":0})
	Lending.state(); return Lending.debts().back()
func reload() -> void:
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
func next_year() -> void:
	GameState.player["age"]+=1; clear()
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; GameState.settings["effects"]=false; Fx.apply_volumes()
	for lender in Lending.LENDERS:
		for kind in ["reduced","pause","extend"]:
			fresh(); var d := loan(lender); var year := GameState.year_now(); var uid: String=d["uid"]
			var allowed: bool=lender!="shark" and (kind!="pause" or lender!="online")
			Lending.request_support(uid,kind); clear()
			ok(d.has("support")==allowed,"Wrong lender eligibility: "+lender+"/"+kind)
			ok(GameState.player["time_left"]==200-(1 if allowed else 0),"Review time differs: "+lender+"/"+kind)
			ok(GameState.player["money"]==10000,"Fee wrongly paid from cash")
			if not allowed: continue
			ok(d["left"]==10200 and d["support"]["fee"]==200,"Review fee/balance mismatch")
			ok(d["support"]["starts"]==year+1,"Arrangement starts before its first scheduled birthday")
			var before := JSON.stringify(d); Lending.request_support(uid,kind); clear()
			ok(JSON.stringify(d)==before and GameState.player["time_left"]==199,"Repeated review alters balance or time")
			var expected := 1000 if kind=="reduced" else 0 if kind=="pause" else 1275
			ok(Lending.scheduled_payment(d,year+1)==expected,"Agreed payment is incorrect")
			if kind!="extend": ok(Lending.scheduled_payment(d,year)==2000,"Future temporary arrangement changes current schedule")
			else: ok(d["due_year"]==year+8,"Extended schedule has wrong maturity")
			reload(); d=Lending.debts()[0]
			ok(d["uid"]==uid and Lending.scheduled_payment(d,year+1)==expected,"Save reload changes agreement or loan identity")
			next_year(); var cash: int=GameState.player["money"]; var balance: int=d["left"]; Lending.yearly()
			ok(GameState.player["money"]==cash-expected and d["left"]==balance-expected,"Payment changes cash and debt by different amounts")
			var record := JSON.stringify(GameState.player["loan_record"]); Lending.yearly()
			ok(GameState.player["money"]==cash-expected and JSON.stringify(GameState.player["loan_record"])==record,"Birthday loan settles twice")
			if kind in ["reduced","pause"]:
				GameState.player["age"]+=2; clear(); Lending.yearly()
				ok(d["support"]["reviewed"] and GameState.player["money"]==cash-expected-2000,"Expired arrangement does not resume original payment")
				ok(GameState.player["loan_record"].any(func(entry): return entry["text"]=="Original payments resumed"),"Plan expiry has no recorded follow-up")
	fresh(); var d := loan(); d["missed"]=2; Lending.request_support(d["uid"],"pause"); clear(); GameState.player["money"]=-900; next_year(); var credit: int=GameState.player["credit"]; Lending.yearly()
	ok(GameState.player["money"]==-900 and d["left"]==10200 and d["missed"]==2 and GameState.player["credit"]==credit,"Approved pause in negative cash is treated as default or erases arrears")
	fresh(); d=loan(); GameState.player["time_left"]=0; Lending.request_support(d["uid"],"pause"); clear()
	ok(not d.has("support") and d["left"]==10000,"No-time review changes the contract")
	fresh(12); d=loan(); Lending.request_support(d["uid"],"pause"); clear(); Lending.yearly(); Lending.settle(0); Employment.repay(0,100)
	ok(d["left"]==10000 and GameState.player["money"]==10000,"Supported child assumes personal debt payments")
	fresh(); d=loan(); GameState.player["job"]={"salary":40000}; GameState.player["money"]=100000; GameState.player["stats"]["health"]=100
	Lending.request_support(d["uid"],"extend"); clear()
	ok(not d.has("support"),"No-hardship borrower receives support")
	GameState.player["stats"]["health"]=30; Lending.request_support(d["uid"],"extend"); clear()
	ok(d.has("support"),"Health hardship cannot access arrangement")
	fresh(); d=loan(); GameState.player["money"]=0; var before_balance: int=d["left"]; credit=GameState.player["credit"]; next_year(); Lending.yearly()
	ok(d["left"]==10500 and d["missed"]==1 and GameState.player["money"]==0 and GameState.player["credit"]==credit-22,"Default penalty/balance is incoherent")
	ok(GameState.player["loan_record"][0]["balance"]==10500,"Default history omits actual new balance")
	fresh(); d=loan("bank",1200,2000); next_year(); Lending.yearly()
	ok(Lending.debts().is_empty() and GameState.player["money"]==8800,"Final payment overcharges balance")
	fresh(); d=loan(); var first_uid: String=d["uid"]; Lending.settle(0); clear(); d=loan()
	ok(d["uid"]!=first_uid,"Cleared loan identity is reused")
	ok(Employment.st().get("booked_expenses",{}).get("Early loan repayment",0)==10000,"Early repayment not recorded for annual report")
	fresh(); d=loan(); Employment.repay(0,999999); clear()
	ok(d["left"]==10000 and GameState.player["money"]==10000,"Unaffordable extra payment alters balance")
	Employment.repay(0,1000); clear()
	ok(d["left"]==9000 and GameState.player["money"]==9000 and Employment.st()["booked_expenses"]["Early loan repayment"]==1000,"Extra payment cash/debt/report mismatch")
	fresh(); d=loan(); GameState.player["last_expenses"]=500; GameState.player["household_ledger"]={"year":GameState.year_now(),"expenses":500,"lines":{}}
	Employment.after_finances(); var paid_record: Dictionary=GameState.player["household_ledger"].duplicate(true)
	ok(GameState.player["last_expenses"]==2500 and paid_record["expenses"]==2500 and paid_record["lines"]["Personal loan payments"]==2000,"Annual loan payment missing from current-year ledger")
	ok(Employment.st().get("booked_expenses",{}).is_empty(),"Scheduled loan payment is booked again for next year")
	Employment.after_finances()
	ok(GameState.player["last_expenses"]==2500 and GameState.player["money"]==8000,"Annual report or debit repeats")
	for difficulty in Grit.DIFFICULTY:
		fresh(); GameState.player["difficulty"]=difficulty; GameState.player["money"]=100000; GameState.player["housing"]="house"; GameState.player["mortgage"]=20000; GameState.player["mortgage_payment"]=3000; GameState.player["loan"]=8000; Employment.record_income("Already received",10000)
		GameState.world["events"]={"war":2}; GameState.player["region"]="ny"
		ok(is_equal_approx(Grit.d("cost"),float(Grit.DIFFICULTY[difficulty]["cost"])) and is_equal_approx(Places.cost_mult(),1.45) and is_equal_approx(World.cost_mult(),1.1),"Price test did not activate actual difficulty, location and world modifiers")
		EventEngine._yearly_finances(); clear(); var ledger: Dictionary=GameState.player["household_ledger"]
		ok(GameState.player["mortgage"]==17000 and ledger["lines"]["Mortgage payment"]==3000,"Living-cost scale changes contractual mortgage charge: "+difficulty)
		ok(GameState.player["loan"]==6500 and ledger["lines"]["Education loan repayment"]==1500,"Living-cost scale changes education repayment: "+difficulty)
		var total := 0
		for amount in ledger["lines"].values(): total+=int(amount)
		ok(ledger["expenses"]==total and GameState.player["money"]==100000-total,"Annual ledger does not reconcile: "+difficulty)
		var exact_cash: int=GameState.player["money"]; var exact_ledger := JSON.stringify(ledger); EventEngine._yearly_finances(); clear()
		ok(GameState.player["money"]==exact_cash and JSON.stringify(GameState.player["household_ledger"])==exact_ledger and GameState.player["mortgage"]==17000,"Same-year finance callback repeats contractual payments: "+difficulty)
	fresh(); Employment.st()["buffer"]=true; GameState.player["last_income"]=10000; GameState.player["last_expenses"]=0; Employment.after_finances(); var savings: int=GameState.player["savings"]; var buffered_cash: int=GameState.player["money"]; Employment.after_finances()
	ok(savings==500 and GameState.player["savings"]==savings and GameState.player["money"]==buffered_cash,"Savings buffer moves money twice in one financial year")
	fresh(); Lending.borrow("bank",1000,2); clear(); d=Lending.debts()[0]; var signed_uid: String=d["uid"]; Lending.settle(0); clear(); Lending.borrow("bank",1000,2); clear()
	ok(Lending.debts()[0]["uid"]!=signed_uid and Lending.debts()[0]["due_year"]==GameState.year_now()+2,"Same-year same-size loan reuses identity or loses term")
	# A living transfer preserves each person's own obligations, not the parent's.
	fresh(55); GameState.player["money"]=50000; d=loan(); Lending.request_support(d["uid"],"reduced"); clear(); var parent_uid := FamilyChronicle.identity(GameState.player); var parent_debt := JSON.stringify(Lending.debts()); var parent_cash: int=GameState.player["money"]
	var child := GameState.create_npc("child",{"age":25,"money":6000,"gender":"male"})
	GameState.npc(child)["debts"]=[{"uid":"recorded-child-loan","lender":"online","principal":900,"left":900,"payment":300,"rate":0.1,"term":3,"taken_age":25,"missed":0}]
	GameState.npc(child)["loan_serial"]=4; GameState.npc(child)["loan_record"]=[]; GameState.npc(child)["credit"]=590
	ok(Dynasty.switch_to(child),"Living child transfer fails")
	ok(Lending.debts().size()==1 and Lending.debts()[0]["uid"]=="recorded-child-loan" and Lending.total_owed()==900 and GameState.player["credit"]==590,"Transfer inherits parent's loan/credit instead of child's")
	var parent_id := ""
	for id in GameState.npcs:
		if FamilyChronicle.identity(GameState.npc(id))==parent_uid: parent_id=id
	ok(parent_id!="" and JSON.stringify(GameState.npc(parent_id)["debts"])==parent_debt,"Former parent loses own arrangement")
	reload(); ok(Lending.debts()[0]["uid"]=="recorded-child-loan" and GameState.player["loan_serial"]>=4,"Transfer reload changes child debt serial")
	GameState.npc(parent_id)["age"]+=1; next_year(); FamilyChronicle.yearly()
	var parent: Dictionary=GameState.npc(parent_id)
	ok(parent["playable_player"]["debts"][0]["left"]==9200 and parent["debts"][0]["left"]==9200,"Offscreen parent arrangement does not make scheduled payment")
	ok(parent["last_budget"]["loans"]==1000 and parent["money"]==parent_cash-12000-1000,"Offscreen parent cash/budget differs from actual debt payment")
	var after_parent := JSON.stringify(parent); FamilyChronicle.yearly()
	ok(JSON.stringify(parent)==after_parent,"Dormant loan/budget settles twice")
	ok(Lending.total_owed()==900,"Dormant loan debits the current child")
	# Saved inherited life keeps recorded debts even after an estate transaction.
	fresh(65); child=GameState.create_npc("child",{"age":30,"money":5000,"gender":"male"})
	GameState.npc(child)["debts"]=[{"uid":"heir-loan","lender":"bank","principal":1100,"left":1100,"payment":400,"rate":0.1,"term":3,"taken_age":30,"missed":0}]; GameState.npc(child)["credit"]=610
	GameState.player["alive"]=false; GameState.continue_as(child); clear()
	ok(Lending.total_owed()==1100 and Lending.debts()[0]["uid"]=="heir-loan" and GameState.player["credit"]==610,"Inheritance discards heir's actual loan/credit")
	fresh(); d=loan(); Lending.request_support(d["uid"],"reduced"); clear(); var payments: Array=[]
	for i in range(3):
		GameState.player["money"]=10000; next_year(); Lending.yearly(); payments.append(10000-int(GameState.player["money"]))
	ok(payments==[1000,1000,2000] and d["left"]==6200,"Half payments do not cover exactly two birthdays")
	fresh(); d=loan("bank",10001); Lending.request_support(d["uid"],"extend"); clear(); var total_paid := 0
	for i in range(8):
		GameState.player["money"]=10000; next_year(); Lending.yearly(); total_paid+=10000-int(GameState.player["money"])
	ok(Lending.debts().is_empty() and total_paid==10201,"Restructure maturity overcharges or forgives the balance")
	var inactive := {"alive":true,"age":40,"born_year":1980,"money":0,"stats":{"stress":10},"debts":[{"lender":"bank","principal":1000,"left":1000,"payment":200,"rate":0.1,"term":5,"taken_age":40,"missed":2}]}
	var active_cash: int=GameState.player["money"]; clear(); Lending.service(inactive,GameState.year_now())
	ok(inactive["debts"][0]["left"]==1050 and inactive["credit"]==588 and inactive["stats"]["stress"]==18,"Dormant arrears do not carry interest/collections/strain")
	ok(GameState.player["money"]==active_cash and not EventEngine.has_pending(),"Dormant arrears create current-player bills or decisions")
	var settled := JSON.stringify(inactive); Lending.service(inactive,GameState.year_now()); ok(JSON.stringify(inactive)==settled,"Dormant default settles twice")
	for blocked_kind in ["dead","custody","supported"]:
		fresh(18); d=loan()
		if blocked_kind=="dead": GameState.player["alive"]=false
		elif blocked_kind=="custody": GameState.player["prison"]=2
		else: Childhood.st()["independence_age"]=21
		Lending.request_support(d["uid"],"pause"); clear()
		ok(not d.has("support") and GameState.player["time_left"]==200 and d["left"]==10000,"Review backend misses "+blocked_kind+" guard")
	fresh(); d=loan(); Lending.request_support("missing-loan","pause"); Lending.request_support(d["uid"],"invented"); clear()
	ok(not d.has("support") and GameState.player["money"]==10000 and GameState.player["time_left"]==200,"Invalid loan/kind creates a contract or consumes resources")
	for i in range(8): await get_tree().process_frame
	print("DEBT SUPPORT TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
