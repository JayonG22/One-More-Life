extends Node
var checks := 0
var failures: Array = []
func ok(value: bool, reason: String) -> void:
	checks+=1
	if not value: failures.append(reason)
func fresh(age: int = 30) -> void:
	EventEngine.pending.clear()
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=age
	GameState.player["money"]=1000000
	GameState.player["time_left"]=1000
	for stat in ["smarts","health","happiness","looks"]: GameState.player["stats"][stat]=100
	GameState.player["stats"]["stress"]=0
	EventEngine.pending.clear()
func choice(value: Variant) -> Dictionary:
	var inst := EventEngine.pop_next()
	if not inst.has("def"):
		ok(false,"expected interactive decision")
		return {}
	for i in range(inst["def"]["choices"].size()):
		var answer: Dictionary = inst["def"]["choices"][i]
		var operation: Dictionary = answer["outcomes"][0].get("depth",{})
		var candidate: Variant = operation.get("value",null)
		if (candidate is String and value is String and str(candidate)==str(value)) or ((candidate is int or candidate is float) and (value is int or value is float) and float(candidate)==float(value)):
			EventEngine.resolve(inst,i)
			return operation
	ok(false,"missing response "+str(value))
	return {}
func clear_info() -> void:
	EventEngine.pending.clear()
func _ready() -> void:
	seed(3032)
	fresh()
	ok(Depth.jobs.size()==ContentDB.jobs.size(),"job task coverage incomplete")
	# These fixtures check the two original tasks. The richer career situations
	# have three valid trade-offs, separately exercised by replayability_test.
	var career_bank: Array=Depth.career_cases; Depth.career_cases=[]
	for job in ContentDB.jobs:
		var id := str(job["id"])
		ok(Depth.jobs.has(id) and Depth.jobs[id].size()==2,"two tasks missing "+id)
		for index in range(2):
			GameState.player["job"]={"id":id,"perf":50.0,"salary":int(job["salary"]),"title":job["ranks"][0],"field":job["field"]}
			Depth.job_task(index)
			ok(EventEngine.pending.size()==1,"job task not playable "+id)
			var before_choice: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
			var operation := choice(0)
			ok(float(GameState.player["job"]["perf"])>50,"successful task no performance "+id)
			var before := float(GameState.player["job"]["perf"])
			Depth.outcome(operation)
			ok(float(GameState.player["job"]["perf"])==before,"job result paid twice "+id)
			clear_info()
			var completed_choice: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
			Depth.job_task(index)
			ok(EventEngine.pending.is_empty(),"job task repeat farm "+id)
			GameState.from_dict(before_choice)
			choice(2)
			ok(float(GameState.player["job"]["perf"])<50,"bad task no consequence "+id)
			clear_info()
			GameState.from_dict(completed_choice); clear_info()
	Depth.career_cases=career_bank
	for subject in Depth.lessons:
		ok(Depth.lessons[subject].size()>=6,"thin subject "+str(subject))
		for q in Depth.lessons[subject]: ok(q["a"].size()==4 and int(q["correct"])<4 and str(q["why"])!="","invalid lesson")
	fresh(15)
	GameState.player["education"]["stage"]="secondary"
	GameState.player["education"]["performance"]=30.0
	for subject in Depth.lessons:
		Depth.school(str(subject))
		ok(float(Depth.state()["subjects"].get(subject,0))>0,"quiz no mastery")
		ok((Depth.state()["active"] as Dictionary).is_empty(),"quiz leaves activity locked")
		clear_info()
		var mastery := float(Depth.state()["subjects"][subject])
		Depth.school(str(subject))
		ok(float(Depth.state()["subjects"][subject])==mastery,"quiz repeat farm")
		clear_info()
	Daily._ss()["clique"]="nerds"
	Depth.school_activity("clique","nerds")
	choice(0)
	clear_info()
	ok(Depth.state()["school_history"].has("clique:nerds"),"clique history lost")
	for club in Daily.SCHOOL_CLUBS:
		Daily._ss()["clubs"]=[club[0]]
		Depth.school_activity("club",str(club[0]))
		choice(0)
		ok(Depth.state()["school_history"].has("club:"+str(club[0])),"club has no playable contribution "+str(club[0]))
		clear_info()
	Daily._ss()["sport"]="soccer"
	Depth.school_activity("school_sport","soccer")
	choice(0)
	clear_info()
	ok(Depth.school_bonus("athlete")>0,"sport missing future preparation")
	Depth.school_activity("talent","music")
	clear_info()
	ok(Depth.state()["school_history"].has("talent:music"),"talent show missing history")
	Daily._ss()["popularity"]=100
	Depth.school_activity("president","")
	var platform := int(Depth.state()["active"]["priority"])
	choice(platform)
	clear_info()
	ok(int(Depth.state().get("president_year",-1))==GameState.year_now(),"class campaign did not elect competent candidate")
	Depth.school_activity("council","")
	choice(platform)
	clear_info()
	ok(Depth.school_bonus("politician")>0,"council missing career preparation")
	ok(Depth.work_portfolio_bonus()>0 and Depth.work_portfolio_bonus()<=0.05,"school contributions not influencing ordinary hiring within limits")
	var portfolio: Dictionary = Depth.state()["school_history"].duplicate(true)
	GameState.player["age"]=20
	Depth.yearly()
	ok(EventEngine.pending.size()==1 and EventEngine.pending[0]["def"]["choices"].size()==3,"school history not gating relevant adult followups")
	EventEngine.push_decision({"id":"_course_budget_probe","text":"An optional life scene","choices":[{"label":"Continue","outcomes":[{"text":""}]}]})
	Director.curate()
	ok(EventEngine.pending.any(func(item): return item.get("def",{}).get("id","")=="_school_portfolio"),"school consequence dropped by event curation")
	clear_info()
	Careers.start("politician","")
	ok(float(Careers.career()["skill"])>20,"school preparation missing from career start")
	clear_info()
	var saved := JSON.parse_string(JSON.stringify(GameState.to_dict())) as Dictionary
	GameState.from_dict(saved)
	ok(Depth.state()["school_history"].size()==portfolio.size() and portfolio.keys().all(func(key): return Depth.state()["school_history"].has(key)),"school history changed on load")
	ok(not (Depth.state().get("decisions",{}) as Dictionary).is_empty(),"choices not remembered")
	fresh()
	GameState.player["last_income"]=50000
	var offer := Lending.offer("shark")
	for percent in [1.0,12.5,33.3,50.0,99.9,100.0]:
		var amount := Lending.fraction_amount("shark",percent)
		ok(amount==int(round(float(offer["cap"])*percent/100)),"fraction snapped to preset")
	for term in range(1,int(offer["term"])+1):
		var q := Lending.quote("shark",1234,term)
		ok(int(q["total"])==int(round(1234*(1+0.55*term))),"loan quote accounting")
	ok(Lending.quote("shark",-100).is_empty() and Lending.quote("shark",999999999).is_empty() and Lending.quote("shark",1234,99).is_empty(),"invalid loan accepted")
	var cash := int(GameState.player["money"])
	Lending.borrow("shark",1234,2)
	ok(int(GameState.player["money"])==cash+1234 and int(Lending.debts()[0]["principal"])==1234 and int(Lending.debts()[0]["term"])==2,"exact configured loan not honoured")
	fresh()
	var defendant := GameState.create_npc("neighbor",{"age":35,"money":30000})
	Depth.start_claim(defendant)
	var stale := choice("debt")
	var active: Dictionary = Depth.state()["active"].duplicate(true)
	Depth.outcome(stale)
	ok(Depth.state()["active"]==active,"stale trial stage replayed")
	choice(0)
	for round_no in range(3):
		ok(EventEngine.pending.size()==1,"trial missing phase")
		choice(0)
	ok(Depth.state()["claims"].size()==1 and (Depth.state()["active"] as Dictionary).is_empty(),"trial no enduring verdict")
	clear_info()
	Depth.start_claim(defendant)
	ok(EventEngine.pending.is_empty(),"same-year repeated lawsuit farm")
	GameState.player["born_year"]+=1
	Depth.start_claim(defendant)
	var prompt: Dictionary = EventEngine.pending[0]["def"].duplicate(true)
	saved=JSON.parse_string(JSON.stringify(GameState.to_dict()))
	EventEngine.pending.clear()
	GameState.from_dict(saved)
	ok(EventEngine.pending.size()==1 and EventEngine.pending[0]["def"]["title"]==prompt["title"],"saved trial did not resume")
	choice(0)
	clear_info()
	fresh(18)
	for discipline in Daily.MARTIAL:
		GameState.player["martial"]={discipline:{"belt":0,"prog":100}}
		Depth.martial(str(discipline),false)
		choice(0)
		ok(int(GameState.player["martial"][discipline]["belt"]) in [0,1],"invalid belt result "+str(discipline))
		Depth.state()["active"]={"kind":"martial"}
		GameState.player["martial"][discipline]={"belt":0,"prog":100}
		Depth._martial_result(1.0,{},str(discipline),false)
		ok(int(GameState.player["martial"][discipline]["belt"])==1,"passing belt assessment did not progress "+str(discipline))
		clear_info()
	GameState.player["martial"]={"karate":{"belt":6,"prog":100}}
	Depth.martial("karate",true)
	ok(EventEngine.pending[0]["def"]["choices"].size()==4,"belts did not unlock moves")
	choice(3)
	clear_info()
	ok(float(Fights.own_slot()["rating"])>65,"fight ignores belt field")
	fresh(23)
	Careers.start("athlete","basketball")
	clear_info()
	Careers.career()["team"]="Test Team"
	Careers.career()["skill"]=100
	for i in range(8):
		GameState.player["born_year"]+=1
		Depth.sport()
		ok(EventEngine.pending.size()==1,"sport missing strategy")
		choice(0)
		clear_info()
	ok(Depth.state()["sport_seen"].size()>=2,"sport moment variety collapsed")
	fresh()
	GameState.player["stats"]["health"]=20
	ok(Depth.expression()["label"]=="Feeling unwell","portrait not reflecting health")
	GameState.player["stats"]["health"]=100
	GameState.player["stats"]["stress"]=90
	ok(Depth.expression()["label"]=="Under strain","portrait not reflecting stress")
	var target := GameState.create_npc("neighbor",{"age":35})
	var money := int(GameState.player["money"])
	Depth.murder(target)
	choice(0)
	ok(GameState.npcs[target]["alive"] and int(GameState.player["money"])==money,"walking away caused death or reward")
	clear_info()
	ok(Actions.ACTIVITY_GROUPS.any(func(category): return category["id"]=="crime" and category["items"].any(func(item): return item["id"]=="murder")),"murder outside crime category")
	GameState.settings["ask_activity_length"]=false
	GameState.player["activity_lengths"]={"walk":2}
	var time := int(GameState.player["time_left"])
	Actions.do_activity("walk")
	ok(int(GameState.player["time_left"])==time-2 and EventEngine.pending.size()==1 and EventEngine.pending[0].get("info",false),"saved activity duration did not simplify the flow")
	clear_info()
	var random_event := {"id":"repeat_test","text":"A reusable scene","choices":[]}
	Director.state()["seen"]["repeat_test"]=2
	ok(Director.weight(random_event,1)==0,"scene repeat cap missing")
	ok(Director._tier({"def":{"id":"_course_adult_1"}})==3,"life scenes bypass budget")
	print("DEPTH TEST checks=%d failures=%d" % [checks,failures.size()])
	for reason in failures: print("FAIL: "+str(reason))
	get_tree().quit(0 if failures.is_empty() else 1)
