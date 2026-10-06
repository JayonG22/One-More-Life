extends Node
var checks := 0
var failures: Array=[]
var operations
var supply
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh(ind: String = "restaurant") -> Dictionary:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30; GameState.player["money"]=10000000; GameState.player["time_left"]=100
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes(); clear()
	Empires.start_business(ind); clear(); return GameState.player["business"]
func reload_life() -> void: GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
func answer(index: int) -> Dictionary:
	var spec: Dictionary=Journey.state()["prompt"]["def"]["choices"][index]["outcomes"][0]["journey"].duplicate(true)
	clear(); Journey.outcome(spec); clear(); return spec
func preview(b: Dictionary, revenue: int, year: int = -1) -> Dictionary:
	return supply.plan(b,revenue,1.0,0.3,1000,500,GameState.year_now() if year<0 else year)
func _ready() -> void:
	seed(7474); operations=Journey.modules["operations"]; supply=operations.supply
	var names: Array=[]
	for ind in Empires.INDUSTRIES:
		var b := fresh(ind); var s: Dictionary=supply.state(b)
		ok(int(s["cash"])==int(int(b["value"])*0.15),"Opening cash not part of founding capital: "+ind)
		ok(supply.stock(b,0)==8 and supply.stock(b,1)==8,"No distinct opening stocks: "+ind)
		ok(s["contracts"].size()==1 and s["contracts"][0]["due"]==GameState.year_now()+1,"No explicit starter replenishment: "+ind)
		ok(operations.catalog[ind]["research_pool"].size()==4,"Thin industry research bank: "+ind)
		for product in operations.catalog[ind]["products"]:
			ok(not names.has(product["unit"]),"Product capacity names repeat")
			names.append(product["unit"])
		var saved := JSON.stringify(s); var result := preview(b,1000000)
		ok(JSON.stringify(s)==saved,"A preview consumes stock or changes contracts: "+ind)
		ok(int(result["ledger"]["sold"][0])<=8 and int(result["ledger"]["missed"])>0,"Sales ignore limited stock: "+ind)
		var l: Dictionary=result["ledger"]
		ok(int(l["sales"])-int(l["cost_of_sales"])-int(l["writeoff"])-int(l["overhead"])-int(l["upkeep"])-1500==int(l["profit"]),"Profit does not reconcile: "+ind)
		ok(int(s["cash"])+int(l["cash_flow"])-int(result["draw"])==int(l["cash"]),"Cash/draw do not conserve: "+ind)
		ok(int(l["cash_flow"])==int(l["sales"])-int(l["purchases"])-int(l["overhead"])-int(l["upkeep"])-1500,"Supplier bills charged like cost of sales twice: "+ind)
	var b := fresh("tech"); var s: Dictionary=supply.state(b)
	s["contracts"]=[]; s["lots"]=[]; s["auto"]=0
	var result := preview(b,1000000)
	ok(result["rev"]==0 and result["profit"]==-1500,"Empty company invents sales")
	s["lots"]=[{"product":0,"quantity":20,"basis":2000,"received":GameState.year_now()},{"product":1,"quantity":30,"basis":4000,"received":GameState.year_now()}]
	s["portfolio"]=true; result=preview(b,1000000)
	ok(result["ledger"]["sold"]==[20,30],"Two product lines do not actually sell their separate stocks")
	ok(result["ledger"]["cost_of_sales"]==6000,"Stored product cost changes with today's supplier")
	s["portfolio"]=false; result=preview(b,1000000)
	ok(result["ledger"]["sold"]==[20,0],"Single-line policy sells an unselected product")
	s["lots"][0]["received"]=GameState.year_now()-3; result=preview(b,1000000)
	ok(result["ledger"]["sold"][0]==0 and result["ledger"]["writeoff"]==2000,"Expired stock is sold before write-off")
	b=fresh(); s=supply.state(b); s["auto"]=0; s["contracts"]=[]
	s["lots"]=[{"product":0,"quantity":100,"basis":10000,"received":GameState.year_now()}]
	var exposed := preview(b,250000)
	s["facilities"]["storage"]=2; var protected := preview(b,250000)
	ok(protected["ledger"]["sold"][0]>exposed["ledger"]["sold"][0],"Storage never prevents damaged stock")
	ok(int(protected["ledger"]["upkeep"])>int(exposed["ledger"]["upkeep"]),"Storage is a free upgrade")
	s["lots"]=[{"product":0,"quantity":100,"basis":10000,"received":GameState.year_now()}]
	result=preview(b,22000)
	ok(result["state"]["lots"].is_empty() and result["ledger"]["writeoff"]==9000,"Perishable leftovers persist without a cost")
	# Both lines share one actual production capacity; the main line has priority.
	b=fresh("tech"); s=supply.state(b); s["contracts"]=[]; s["auto"]=0; s["portfolio"]=true
	s["lots"]=[{"product":0,"quantity":500,"basis":5000,"received":GameState.year_now()},{"product":1,"quantity":500,"basis":5000,"received":GameState.year_now()}]
	result=preview(b,10000000)
	ok(int(result["ledger"]["sold"][0])+int(result["ledger"]["sold"][1])==supply.capacity(b),"Two lines each receive a duplicated plant capacity")
	operations.st()["product"]=1; result=preview(b,10000000)
	ok(result["ledger"]["sold"][1]==supply.capacity(b) and result["ledger"]["sold"][0]==0,"Main product loses capacity priority after switching")
	s["facilities"]["production"]=1; result=preview(b,10000000)
	ok(result["ledger"]["sold"][1]==supply.capacity(b),"Production facilities do not raise actual sales capacity")
	# Signed contracts retain timing, cost and risk across supplier changes/reloads.
	b=fresh("fashion"); s=supply.state(b); s["contracts"]=[]; s["lots"]=[]; s["auto"]=0
	operations.st()["supplier"]="value"; supply.place(0,75); clear()
	var c: Dictionary=s["contracts"][0].duplicate(true)
	ok(c["due"]==GameState.year_now()+2,"Value supplier has no lead time")
	var time := int(GameState.player["time_left"]); supply.place(0,150); clear()
	ok(s["contracts"].size()==1 and GameState.player["time_left"]==time,"Contracts can be stacked without limits")
	operations.st()["supplier"]="specialist"; reload_life(); b=operations.biz(); s=supply.state(b)
	ok(s["contracts"][0]==JSON.parse_string(JSON.stringify(c)),"Supplier switch/reload rewrites existing bills or risk")
	ok(preview(b,1000000,GameState.year_now()+1)["ledger"]["purchases"]==0,"Undelivered contract paid early")
	s["contracts"][0]["roll"]=0.99
	result=preview(b,1000000,GameState.year_now()+2)
	ok(result["ledger"]["purchases"]==0 and result["state"]["contracts"][0]["due"]==GameState.year_now()+3,"Saved late risk has no real postponement")
	var delayed: Dictionary=result["state"].duplicate(true); b["operations"]["supply"]=delayed; reload_life(); b=operations.biz(); s=supply.state(b)
	result=preview(b,1000000,GameState.year_now()+3)
	ok(result["ledger"]["purchases"]==75*int(c["unit_cost"]) and result["state"]["contracts"].is_empty(),"A delayed delivery is lost, rerolled or charged twice")
	# Large unsold purchases cannot become a spendable profit drawing.
	b=fresh("tech"); s=supply.state(b); s["contracts"]=[]; s["lots"]=[]; s["cash"]=0; s["auto"]=0
	supply.contract(b,0,150,"specialist",GameState.year_now()); s["contracts"][0]["roll"]=0; s["contracts"][0]["unit_cost"]=400
	result=preview(b,14000)
	ok(int(result["profit"])>0 and int(result["draw"])<0,"Unsold prepaid stock can fund a fictitious owner payout")
	ok(int(result["ledger"]["cash"])==0,"Unfunded inventory creates free company cash")
	# Capital moves into the reserve, never adding revenue or duplicate cash.
	b=fresh(); s=supply.state(b); var personal := int(GameState.player["money"]); var reserve := int(s["cash"])
	supply.fund(25); clear()
	ok(int(GameState.player["money"])+int(s["cash"])==personal+reserve,"Company funding creates or loses money")
	ok(int(s["cash"])>reserve and s["ledger"].is_empty(),"Capital funding is recorded as a sales reward")
	reserve=int(s["cash"]); supply.fund(50); clear(); ok(int(s["cash"])==reserve,"Funding repeats without its annual limit")
	s["auto"]=100; s["contracts"]=[]; s["lots"]=[]; s["portfolio"]=true
	result=preview(b,0); supply.settle(b,result)
	var amounts: Array=[0,0]
	for order in supply.state(b)["contracts"]: amounts[int(order["product"])]+=int(order["quantity"])
	ok(amounts==[75,25],"Mixed production doubles rather than splits the chosen target")
	# Actual order reservation is retained and consumes stock only once.
	b=fresh(); s=supply.state(b); operations.order(); clear()
	ok(supply.stock(b,0)==5 and s.has("order_basis"),"Customer order invents its reserved batches")
	reload_life(); b=operations.biz(); s=supply.state(b); operations.st()["active"]["roll"]=0
	operations.work(); answer(0); operations.work(); answer(0)
	ok(supply.stock(b,0)==8 and not s.has("order_basis"),"Delivery duplicates or loses the reserved batches")
	# Facilities use real capital, affect capacity/upkeep and cannot repeat that year.
	var before_cash := int(GameState.player["money"]); var old_capacity: int=supply.capacity(b)
	supply.upgrade("production"); clear()
	ok(supply.capacity(b)==old_capacity+50 and GameState.player["money"]==before_cash-Actions._cost(7200),"Production facility is cosmetic or free")
	supply.upgrade("production"); clear(); ok(s["facilities"]["production"]==1,"Facility upgrade repeats in one year")
	# Assessments keep both the question order and outcome roll across save/replay.
	supply.research(); clear(); var research: Dictionary=s["research"].duplicate(true)
	reload_life(); b=operations.biz(); s=supply.state(b)
	ok(s["research"]["questions"]==JSON.parse_string(JSON.stringify(research["questions"])) and absf(s["research"]["roll"]-research["roll"])<0.00001,"Research rerolls on save")
	s["research"]["roll"]=0; before_cash=int(GameState.player["money"])
	supply.research_work(); var spec := answer(int(s["research"]["questions"][0]["correct"]))
	Journey.outcome(spec); ok(s["research"]["stage"]==1,"Replayed answer advances research twice")
	supply.research_work(); answer(int(s["research"]["questions"][1]["correct"]))
	ok(s["research"].is_empty() and s["insights"][0]==1 and GameState.player["money"]==before_cash,"Research has no lasting insight or invents a cash prize")
	var weak := preview(b,100000); s["insights"][0]=3; var better := preview(b,100000)
	ok(better["ledger"]["demand"][0]>weak["ledger"]["demand"][0],"Research does not affect actual demand")
	GameState.player["age"]+=1; s["insights"][0]=1; supply.research(); clear()
	ok(s["research"]["questions"][0]["question"] not in research["questions"].map(func(q): return q["question"]),"Research repeats before unused questions are tried")
	GameState.player["age"]+=2; supply.yearly(b,GameState.year_now()); ok(s["research"].is_empty(),"Abandoned research has no deadline")
	# Migration reclassifies an existing company's assets, without gifting cash.
	b=fresh(); b["operations"].erase("supply"); before_cash=int(GameState.player["money"])
	s=supply.state(b); ok(s["cash"]==0 and GameState.player["money"]==before_cash,"Old-save migration gifts spendable cash")
	var legacy := s.duplicate(true); reload_life(); b=operations.biz(); ok(supply.state(b)==JSON.parse_string(JSON.stringify(legacy)),"Migration restocks on each load")
	# The actual company packet, not replacement stock, follows its living successor.
	var child := GameState.create_npc("child",{"age":25,"money":1000}); s=supply.state(b)
	s["cash"]=5000; s["facilities"]["production"]=2; s["insights"][1]=2; supply.contract(b,1,75,"steady")
	var packet := s.duplicate(true); operations.handover(child); clear()
	ok(GameState.npc(child)["business"]["operations"]["supply"]==packet,"Handover drops stock, cash, facilities or contracts")
	GameState.player["age"]+=1; Journey.background_companies(GameState.year_now()); clear()
	ok(GameState.npc(child)["business"]["operations"]["supply"]["ledger"]["year"]==GameState.year_now(),"Off-screen inventories and deliveries freeze")
	var actual: Dictionary=GameState.npc(child)["business"]["operations"]["supply"].duplicate(true)
	ok(Dynasty.switch_to(child),"Successor cannot be played")
	ok(supply.state(operations.biz())==actual,"Returning to successor resets the stock accounts")
	# An inherited operating packet retains actual stock capital without cash duplication.
	b=fresh("tech"); s=supply.state(b); s["cash"]=18000; s["facilities"]["storage"]=1; s["insights"][1]=2
	supply.contract(b,1,75,"steady"); packet=s.duplicate(true)
	child=GameState.create_npc("child",{"age":25,"money":321}); var parent_uid := Journey.uid()
	GameState.player["alive"]=false; GameState.continue_as(child); clear()
	ok(supply.state(operations.biz())==packet,"Inheritance resets stock, research, cash or contracts")
	ok(GameState.player["money"]==321+int(GameState.world["estate_register"][parent_uid]["cash"]),"Inherited company cash is paid twice outside the company")
	reload_life(); ok(supply.state(operations.biz())==JSON.parse_string(JSON.stringify(packet)),"Inherited stock accounts change after reload")
	# Voluntary closure charges commitments, salvages goods, and cannot repeat.
	b=fresh(); s=supply.state(b); var exit_receipt: Dictionary=supply.liquidation(b); personal=int(GameState.player["money"])
	Empires.biz_action("b_close"); clear()
	ok(GameState.player["business"].is_empty() and int(GameState.player["money"])==personal+int(exit_receipt["net"]),"Closing erases supplier commitments or duplicates stock cash")
	personal=int(GameState.player["money"]); Empires.biz_action("b_close"); clear(); ok(GameState.player["money"]==personal,"Closing payout repeats")
	b=fresh(); b["public"]=true; b["stake"]=0.6; var sold_uid: String=b["uid"]; packet=supply.state(b).duplicate(true); Empires.biz_action("b_sell"); clear()
	var buyers: Array=GameState.npcs.values().filter(func(n): return str(n.get("business",{}).get("uid",""))==sold_uid)
	ok(GameState.player["business"].is_empty() and buyers.size()==1,"Sale loses or duplicates the company owner")
	ok(buyers[0]["business"]["public"] and buyers[0]["business"]["stake"]==0.6,"Sale rewrites outside shareholders' ownership")
	ok(buyers[0]["business"]["operations"]["supply"]==packet,"Selling erases stock or passes supplier bills back to the seller")
	GameState.player["age"]+=1; Journey.background_companies(GameState.year_now()); clear()
	ok(buyers[0]["business"]["operations"]["supply"]["ledger"]["year"]==GameState.year_now(),"Buyer never settles transferred contracts")
	print("SUPPLY TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
