extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh(age: int = 30) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=age; GameState.player["money"]=200000; GameState.player["time_left"]=100
	GameState.settings["volume"]=0; GameState.settings["minigames"]=false; Fx.apply_volumes(); clear()
func answer(index: int) -> void:
	var spec: Dictionary=Journey.state()["prompt"]["def"]["choices"][index]["outcomes"][0]["journey"].duplicate(true)
	clear(); Journey.outcome(spec); clear()
func year() -> void: GameState.player["age"]+=1; GameState.player["time_left"]=100; clear()
func reload_life() -> void: GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
func same(a: Variant, b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float): return absf(float(a)-float(b))<0.00001
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not same(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size(): return false
		for i in range(a.size()):
			if not same(a[i],b[i]): return false
		return true
	return a==b
func _ready() -> void:
	seed(7070); fresh()
	var seasons=Journey.modules["seasons"]
	seasons.start(); clear()
	ok(seasons.st()["season"]["fixtures"].size()==3,"Season has no fixtures")
	var fixtures: Array=seasons.st()["season"]["fixtures"].duplicate(true); reload_life()
	ok(same(seasons.st()["season"]["fixtures"],fixtures),"Season opponents reroll on load")
	for i in range(3):
		var f: Dictionary=seasons.st()["season"]["fixtures"][i]; f["roll"]=0
		var time := int(GameState.player["time_left"])
		seasons.fixture(); ok(GameState.player["time_left"]==time-1,"Fixture has no time cost")
		answer({"pressing":1,"patient":2,"wide":0}[f["opponent"]])
	ok(seasons.st()["season"].is_empty() and seasons.st()["history"][0]["wins"]==3,"Season never finishes")
	var skill := Market.skill("Sports"); seasons.resolve("fixture",{"stage":2},0)
	ok(Market.skill("Sports")==skill,"Season replay grants reward")
	year(); seasons.start(); clear(); year(); seasons.yearly()
	ok(seasons.st()["season"].is_empty() and seasons.st()["history"][0]["result"]=="Unfinished at year end","Season stays open forever")
	GameState.player["martial"]={"judo":{"belt":1}}
	seasons.style("judo"); ok(seasons.st()["style"]=="judo","Earned martial approach unavailable")
	seasons.style("bjj"); ok(seasons.st()["style"]=="judo","Unearned martial approach unlocked")
	fresh(17); GameState.player["education"]["stage"]="secondary"
	var learning=Journey.modules["learning"]
	var cash := int(GameState.player["money"])
	learning.enrol("Food","part_time"); clear()
	ok(not learning.st()["course"].is_empty() and int(GameState.player["money"])<cash,"Course no entry requirements/cost")
	learning.act("pause",null); var time := int(GameState.player["time_left"]); learning.unit()
	ok(GameState.player["time_left"]==time,"Paused course consumes time")
	learning.act("pause",null)
	for i in range(3):
		learning.unit(); var spec: Dictionary=Journey.state()["prompt"]
		ok(not spec.is_empty(),"Practical unit unavailable")
		answer(spec["args"]["order"].find(0))
		learning.unit(); ok(Journey.state()["prompt"].is_empty(),"Course unit repeats in same year")
		year()
	ok(learning.st()["course"]["points"]==3,"Learning evidence not saved")
	reload_life(); ok(learning.st()["course"]["units"]==3,"Course lost on load")
	for stat in GameState.player["stats"]: GameState.player["stats"][stat]=100 if stat!="stress" else 0
	seed(5); learning.assess(); clear()
	# A failed attempt retains all units; a success creates concrete evidence.
	ok(not learning.st()["completed"].is_empty() or learning.st()["course"].get("units",0)==3,"Assessment destroys progress")
	fresh(20); learning.enrol("Food","distance"); clear(); learning.internship(); clear()
	ok(not learning.st()["internship"].is_empty(),"Supervised placement missing")
	learning.shift(); answer(0); cash=int(GameState.player["money"]); learning.shift()
	ok(GameState.player["money"]==cash and Journey.state()["prompt"].is_empty(),"Placement stipend repeated")
	year(); learning.shift(); answer(1)
	ok(learning.st()["internship"].is_empty() and learning.st()["history"][0]["steps"]==2,"Placement never concludes")
	ok(Employment.record("Food")["samples"]==1,"Trustworthy placement has no work evidence")
	fresh(); learning.enrol("Food","distance"); clear(); learning.internship(); clear(); year(); year(); year(); learning.yearly()
	ok(learning.st()["history"][0]["result"]=="Placement deadline missed","Missed placement no consequence")
	fresh(); var people=Journey.modules["people"]
	var friend := GameState.create_npc("rival",{"age":30,"closeness":50})
	var uid := FamilyChronicle.identity(GameState.npc(friend)); people.motive(friend)["goal"]="quiet"
	var trust := BondStats.get_stat(friend,"trust"); people.help_goal(friend,1); clear()
	ok(people.motive(friend)["progress"]==1 and BondStats.get_stat(friend,"trust")>trust,"NPC goal preference irrelevant")
	people.help_goal(friend,1); ok(people.motive(friend)["progress"]==1,"Goal support repeats without cost")
	Household.state()["fatigue"]=50; people.favour(friend); clear()
	ok(Household.state()["fatigue"]==45 and people.motive(friend)["favours"]==0,"Favour has no practical effect")
	people.favour(friend); ok(Household.state()["fatigue"]==45,"Favour reused")
	people.rivalry(friend); var prompt: Dictionary=Journey.state()["prompt"].duplicate(true); reload_life()
	ok(same(Journey.state()["prompt"]["args"],prompt["args"]),"Rival scene rerolls on load")
	answer(0); ok(GameState.npc(friend)["personal_history"].size()>0,"Rival decision not remembered")
	fresh(); var funds=Journey.modules["funds"]
	var partner := GameState.create_npc("partner",{"age":30,"money":10000,"closeness":90,"job":{"salary":20000,"key":"employee"}})
	BondStats.apply(partner,{"trust":40}); GameState.player["partner"]=partner; GameState.player["living_together"]=true
	var wealth := GameState.net_worth(); funds.deposit(10); clear()
	ok(funds.value(Journey.uid())==20000 and GameState.net_worth()==wealth,"Reserve creates/destroys wealth")
	funds.invite(); clear(); var partner_cash := int(GameState.npc(partner)["money"])
	ok(partner_cash==8000,"Partner contribution does not debit actual cash")
	funds.invite(); ok(GameState.npc(partner)["money"]==partner_cash,"Partner contribution replayed")
	reload_life(); ok(funds.value(Journey.uid())==20000,"Reserve lost on reload")
	GameState.player["money"]=-1000; GameState.player["last_expenses"]=12000; funds.shortfall(); clear()
	ok(GameState.player["money"]==0 and funds.value(Journey.uid())==19000,"Shared shortfall creates cash")
	GameState.player["living_together"]=false; funds.withdraw(); clear()
	ok(GameState.player["money"]==19000 and funds.value(Journey.uid())==0,"Separation loses own share")
	ok(funds.book().values()[0]["balances"][FamilyChronicle.identity(GameState.npc(partner))]==2000,"Withdrawal steals partner's share")
	fresh(); GameState.player["housing"]="apartment"; cash=int(GameState.player["money"]); Tenancy.sync()
	var deposit := int(Tenancy.st()["deposit"])
	ok(GameState.player["money"]==cash-deposit,"Lease deposit never charged")
	GameState.player["housing"]="parents"; Tenancy.sync()
	ok(GameState.player["money"]<=cash,"Rental deposit manufactures cash")
	fresh(); GameState.player["housing"]="apartment"; Tenancy.st().merge({"active":true,"deposit":5000,"kind":"kind","damp":0.0},true)
	cash=int(GameState.player["money"]); GameState.player["housing"]="parents"; Tenancy.sync()
	ok(GameState.player["money"]==cash,"Legacy unpaid deposit creates cash")
	# Three generations, two beneficiaries at each death, reload each handover.
	for generation in range(3):
		fresh() if generation==0 else clear()
		GameState.player["age"]=65; GameState.player["money"]=100000; GameState.player["loan"]=0; GameState.player["savings"]=0
		var a := GameState.create_npc("child",{"age":25,"money":111,"smarts":72,"closeness":65})
		var b := GameState.create_npc("child",{"age":23,"money":222,"closeness":65})
		GameState.player["possessions"]=[{"name":"Recorded watch","value":1000,"icon":"⌚"}]
		var source := Journey.uid(); GameState.player["alive"]=false; GameState.continue_as(a); clear()
		var receipt: Dictionary=GameState.world["estate_register"][source]
		var sum := 0
		for allocation in receipt["allocations"]: sum+=int(allocation["cash"])+int(allocation["physical"])
		ok(sum==96000,"Estate allocation fails conservation")
		ok(receipt["allocations"].size()>=2,"Sibling receives no estate")
		var sibling := Journey.person(str(receipt["allocations"][1]["uid"]))
		ok(sibling!="" and int(GameState.npc(sibling)["money"])>222,"Sibling cash not applied")
		ok(GameState.stat("smarts")==72,"Child ability rerolled")
		ok(GameState.player["possessions"].size()+GameState.npc(sibling).get("possessions",[]).size()==1,"Physical bequest duplicated")
		reload_life(); ok(GameState.world["estate_register"][source]["status"]=="executed","Estate receipt lost")
		# Remove old siblings from this focused fixture's beneficiary list.
		for n in GameState.npcs.values():
			if n["relation"]=="child": n["relation"]="family_friend"
	# Insolvency, charity and company ownership use the same real settlement path.
	fresh(); GameState.player["money"]=1000; GameState.player["loan"]=5000
	GameState.player["possessions"]=[{"name":"Debt-sale watch","value":1000}]
	var insolvent_child := GameState.create_npc("child",{"age":25,"money":321})
	var estate_source := Journey.uid(); GameState.player["alive"]=false; GameState.continue_as(insolvent_child); clear()
	var estate_receipt: Dictionary=GameState.world["estate_register"][estate_source]
	ok(estate_receipt["liquidated"]==1000 and estate_receipt["unpaid"]==3000,"Insolvent estate gifts assets before paying debts")
	ok(GameState.player["money"]==321 and GameState.player["possessions"].is_empty(),"Estate debt or sold object wrongly inherited")
	fresh(); GameState.player["money"]=100000; GameState.player["will"]="charity"
	var charity_child := GameState.create_npc("child",{"age":25,"money":123})
	estate_source=Journey.uid(); GameState.player["alive"]=false; GameState.continue_as(charity_child); clear()
	ok(GameState.world["estate_register"][estate_source]["charity"]==95000 and GameState.player["money"]==123,"Charity duplicates cash into child")
	fresh(); GameState.player["money"]=5000
	var company_a := GameState.create_npc("child",{"age":25,"money":0})
	var company_b := GameState.create_npc("child",{"age":23,"money":0})
	GameState.player["ambition"]={"enterprise":{"portfolio":[{"name":"One owner","value":10000,"stake":0.5,"debt":1000}],"succession":company_b}}
	estate_source=Journey.uid(); GameState.player["alive"]=false; GameState.continue_as(company_a); clear()
	estate_receipt=GameState.world["estate_register"][estate_source]
	var company_total := 0
	for allocation in estate_receipt["allocations"]: company_total+=int(allocation["cash"])+int(allocation["physical"])
	ok(company_total==8750,"Company equity settlement fails conservation")
	ok(GameState.npc(company_b)["ambition"]["enterprise"]["portfolio"].size()==1 and GameState.player["ambition"]["enterprise"]["portfolio"].is_empty(),"Named business successor loses or duplicates ownership")
	fresh(); Journey.modules["places"].st()["home"]="active-home"
	var inactive_heir: Dictionary={"housing":"parents","journey":{},"properties":[]}
	Estate.restore_home(inactive_heir,{"uid":"heir-home","value":100000,"mortgage":20000,"payment":1000,"model":"family","home":{"condition":75},"adaptations":{"home":"heir-home","adaptations":["access"]}})
	ok(inactive_heir["journey"]["places"]["home"]=="heir-home" and inactive_heir["journey"]["places"]["adaptations"]==["access"],"Heir home loses recorded adaptations")
	ok(Journey.modules["places"].st()["home"]=="active-home","Restoring another person's home mutates active player")
	fresh(); var recovery=Journey.modules["recovery"]
	recovery.begin_trial("fictional fraud allegation",1,3,70)
	var questions: Array=recovery.st()["case"]["questions"].duplicate(true)
	ok(questions.size()==3 and questions[0]!=questions[1],"Hearing repeats question in one case")
	reload_life(); ok(same(recovery.st()["case"]["questions"],questions),"Court questions reroll")
	ok(ContentDB._load_json("res://data/mode_chapters.json",{}).size()==11,"Mode-specific chapters missing")
	for mode in ContentDB._load_json("res://data/mode_chapters.json",{}).values(): ok(mode.size()==3 and mode.all(func(ch): return ch["options"].size()==3 and ch["quality"].size()==3),"Mode chapter schema incomplete")
	fresh(65); var leisure=Journey.modules["leisure"]
	leisure.start("reading"); clear()
	for i in range(3): leisure.step(); answer(1); year()
	ok(leisure.st()["project"].is_empty() and leisure.st()["history"][0]["result"]=="Completed","Quiet-life project never concludes")
	ok(Market.skill("Education")==1,"Quiet-life project has no earned skill")
	var happiness := GameState.stat("happiness"); leisure.casual(); clear(); var after := GameState.stat("happiness"); leisure.casual()
	ok(after>=happiness and GameState.stat("happiness")==after,"Casual leisure reward loop")
	# Actual controls resume a saved round, not merely the challenge's title.
	fresh(); var skills=Journey.modules["skills"]; var token := 42; var owner := Journey.uid()
	skills.st()["active"]={"kind":"budget","practice":false,"token":token,"owner":owner}
	var game: Minigame=load("res://scenes/minigames/mg_workshop.gd").new()
	game.setup({"kind":"budget","skill":60,"progress_token":token,"progress_owner":owner}); add_child(game)
	game.choose(game.order.find(0)); var progress: Dictionary=skills.st()["active"]["progress"].duplicate(true)
	ok(progress["ready"] and float(progress["points"])==1,"Round checkpoint did not record result")
	game.queue_free(); await get_tree().process_frame
	reload_life(); var resumed: Minigame=load("res://scenes/minigames/mg_workshop.gd").new()
	resumed.setup({"kind":"budget","skill":60,"progress_token":token,"progress_owner":owner,"progress":skills.st()["active"]["progress"]}); add_child(resumed)
	ok(resumed.next_button.visible and resumed.buttons.all(func(b): return b.disabled) and resumed.points==1,"Scored round can be replayed after load")
	resumed.choose(0); ok(resumed.points==1,"Restored round awarded twice")
	resumed.next(); ok(resumed.round_i==1 and not resumed.next_button.visible,"Saved challenge cannot continue")
	resumed.queue_free(); await get_tree().process_frame
	print("COMPLETION TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
