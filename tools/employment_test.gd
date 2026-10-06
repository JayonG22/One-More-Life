extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear_events() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh(age: int = 30) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=age; GameState.player["money"]=200000; GameState.player["time_left"]=30
	clear_events()
func answer(value: int) -> void:
	var event := EventEngine.pop_next()
	while not event.is_empty() and str(event.get("def",{}).get("id",""))!="_employment": event=EventEngine.pop_next()
	if event.is_empty(): failures.append("employment choice was not queued"); return
	var choices: Array=event["def"]["choices"]
	for i in range(choices.size()):
		if int(choices[i]["outcomes"][0]["employment"]["answer"])==value:
			EventEngine.resolve(event,i)
			EventEngine.displayed.clear()
			EventEngine.pending=EventEngine.pending.filter(func(it): return str(it.get("def",{}).get("id",""))=="_employment")
			return
func _ready() -> void:
	seed(3232)
	fresh()
	var complete := true
	for job in ContentDB.jobs:
		var list: Array=Employment.briefs.get(str(job["id"]),[])
		complete=complete and list.size()>=2 and Depth.jobs.get(str(job["id"]),[]).size()==2
		for brief in list: complete=complete and brief["work"]["answers"].size()==3 and brief.has("standard")
	ok(complete,"job-specific project catalogue incomplete")
	ok(Employment.programs.size()==28,"training field catalogue changed")
	Actions.hire("appliance_repair")
	ok(Workplace.crew().size()==3,"missing team")
	ok(GameState.npc(Workplace.crew()[0])["work_role"]=="mentor","mentor role missing")
	clear_events()
	Employment.start_project(0)
	ok(Employment.st()["active"]["stage"]==0,"project did not start")
	var old_op: Dictionary=Employment.st()["prompt"].duplicate(true); old_op["answer"]=0
	var saved: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.from_dict(saved)
	ok(EventEngine.pending.size()==1,"save duplicated project choice")
	answer(0)
	var quality := float(Employment.st()["active"]["quality"])
	Employment.outcome(old_op)
	ok(Employment.st()["active"]["quality"]==quality,"choice replay changed quality")
	Employment.resume_project(); answer(0)
	Employment.resume_project(); answer(0)
	ok(Employment.st()["active"].is_empty(),"handover did not finish")
	ok(Employment.st()["history"].size()==1,"work record missing")
	ok(Journey.modules["pathways"].st()["cases"].size()==1 and Journey.modules["pathways"].st()["cases"][0]["field"]=="Trades","Actual completed job has no relevant named follow-up")
	ok(Employment.st()["clients"][0]["completed"]==1,"client history missing")
	ok(Employment.project_reason()!="","same-year project replay allowed")
	var bonus := int(Employment.st()["booked"])
	var cash := int(GameState.player["money"])
	EventEngine._yearly_finances()
	var ledger: Dictionary=GameState.player["household_ledger"]
	ok(int(GameState.player["money"])==cash+int(ledger["income"])-int(ledger["expenses"])-bonus,"bonus paid twice")
	ok(ledger["income_sources"].get("Project bonuses",0)==bonus,"bonus missing from income record")
	ok(Employment.take_income()["amount"]==0,"income booking replayed")
	fresh(); Actions.hire("appliance_repair"); clear_events(); Employment.start_project(1)
	old_op=Employment.st()["prompt"].duplicate(true); old_op["answer"]=0
	var old_session := Employment.job_session()
	Actions.lose_job("switch"); clear_events(); Actions.hire("appliance_repair"); clear_events()
	Employment.outcome(old_op)
	ok(Employment.job_session()!=old_session and Employment.st()["active"].is_empty(),"old project survived rehire")
	GameState.player["job"]["years_in_rank"]=2; GameState.player["job"]["perf"]=85
	ok(Employment.promotion_reason()!="","promotion ignored practical requirements")
	Market.learn("Trades",6); Employment.record("Trades")["samples"]=4
	ok(Employment.promotion_reason()=="","earned promotion blocked")
	Employment.set_schedule("overtime"); clear_events()
	ok(is_equal_approx(Employment.pay_factor(),1.10),"overtime pay not connected")
	Employment.set_term("fixed"); clear_events()
	ok(is_equal_approx(Employment.pay_factor(),1.155),"contract and hours do not combine")
	fresh(15); cash=int(GameState.player["money"])
	Employment.enrol("Trades","apprentice")
	ok(int(GameState.player["money"])==cash and Employment.st()["training"].is_empty(),"underage training charged")
	fresh(18); Employment.enrol("Trades","apprentice"); clear_events()
	Employment.practical(); answer(0); Employment.practical(); answer(0)
	ok(Employment.st()["training"]["units"]==2,"practical units not earned")
	ok(Employment.assessment_reason()!="","duration bypassed")
	GameState.player["age"]=20; Employment.assess(); answer(0); answer(1); answer(0)
	ok(Employment.has_certificate("Trades"),"passing assessment not recorded")
	ok(Employment.st()["training"].is_empty(),"completed course stayed active")
	GameState.player["education"]["degrees"]=[]
	Employment.st()["certificates"]["Healthcare"]={"year":GameState.year_now()}
	ok(Actions.job_requirement(ContentDB.job("doctor"))!="","certificate bypassed medical degree")
	fresh(); GameState.player["money"]=1000
	Lending.debts().append({"lender":"bank","principal":1000,"left":1200,"payment":400,"rate":0.05,"term":3,"taken_age":30,"missed":0})
	Employment.repay(0,250); clear_events()
	ok(GameState.player["money"]==750 and Lending.debts()[0]["left"]==950,"partial loan payment wrong")
	ok(Lending.debts()[0]["payment"]==400,"partial repayment changed annual contract")
	Employment.repay(0,999999); clear_events()
	ok(GameState.player["money"]==750,"unaffordable repayment charged")
	fresh(); Actions.hire("appliance_repair"); clear_events()
	GameState.player["job"]["work_contract"]="fixed"; GameState.player["job"]["contract_end"]=GameState.year_now(); GameState.player["job"]["perf"]=50
	EventEngine._yearly_finances(); cash=int(GameState.player["money"]); Employment.after_finances()
	ok(not GameState.has_job() and int(GameState.player["money"])==cash,"contract did not end after final wages")
	fresh(); Actions.hire("appliance_repair"); clear_events(); Employment.start_project(0); answer(1)
	GameState.player["age"]=33; Employment.yearly(); clear_events()
	ok(Employment.st()["active"].is_empty() and Employment.st()["history"][0]["result"]=="Missed deadline","overdue project not closed")
	fresh(); Actions.hire("appliance_repair"); clear_events()
	GameState.player["age"]=31; GameState.player["job"]["perf"]=60; Employment.finish_work_year()
	ok(GameState.player["job"].get("probation_passed",false),"probation review has no consequence")
	fresh(); Employment.enrol("Trades","retrain"); clear_events(); Employment.practical()
	old_op=Employment.st()["prompt"].duplicate(true); old_op["answer"]=0
	answer(1); GameState.player["age"]=31; Employment.practical()
	Employment.outcome(old_op)
	ok(Employment.st()["training"]["units"]==0,"old failed-unit choice bypassed retry")
	answer(0); Employment.practical(); answer(0); Employment.assess(); answer(1); answer(1); answer(0)
	ok(not Employment.has_certificate("Trades") and Employment.st()["training"]["units"]==2,"failed assessment granted qualification or lost progress")
	GameState.player["stats"]["smarts"]=95; GameState.player["stats"]["health"]=95; GameState.player["stats"]["happiness"]=95; GameState.player["stats"]["stress"]=5
	var high := Aptitude.chance(0.6,"work")
	GameState.player["stats"]["smarts"]=5; GameState.player["stats"]["health"]=5; GameState.player["stats"]["happiness"]=5; GameState.player["stats"]["stress"]=95
	ok(high>Aptitude.chance(0.6,"work"),"wellbeing not linked to project chances")
	fresh(); GameState.player["benefit"]={"amt":500,"months":2}; cash=int(GameState.player["money"])
	Workforce.yearly(); EventEngine._yearly_finances()
	ok(GameState.player["household_ledger"]["income_sources"]["Unemployment support"]==1000,"benefits absent from income report")
	ok(int(GameState.player["money"])==cash+1000-int(GameState.player["last_expenses"]),"benefits paid twice")
	fresh(); Actions.hire("appliance_repair"); clear_events()
	GameState.player.erase("employment"); Workplace.w()["crew"]=[]; Workplace.w()["union"]=true
	Employment.restore()
	ok(Workplace.crew().size()==3 and Workplace.w()["union"] and GameState.npc(Workplace.crew()[0])["work_role"]=="mentor","older workplace migration lost roles or union")
	for message in failures: print("FAIL: "+str(message))
	print("EMPLOYMENT TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
