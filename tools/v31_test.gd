extends Node
var checks := 0
var failures: Array = []
func ok(value: bool, reason: String) -> void:
	checks += 1
	if not value: failures.append(reason)
func clear_events() -> void:
	EventEngine.pending.clear()
	EventEngine.displayed.clear()
func fresh(age: int = 30, month: int = 0) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"] = age
	GameState.player["money"] = 200000
	GameState.player.erase("life_course")
	LifeCourse.state()["months"] = age*12+month
	LifeCourse.state()["cursor"] = age*12+month
	clear_events()
func saved() -> Dictionary:
	return JSON.parse_string(JSON.stringify(GameState.to_dict()))
func _ready() -> void:
	seed(3131)
	# Original infancy timing, all firsts, then annual progression.
	fresh(0)
	for month in range(1,25):
		clear_events()
		EventEngine.progress()
		ok(int(LifeCourse.state()["months"])==month,"infancy calendar skipped")
		ok(int(GameState.player["age"])==month/12,"infancy birthday disagrees")
	ok(LifeCourse.state()["firsts"].size()==7,"firsts missing")
	clear_events()
	EventEngine.progress()
	ok(int(GameState.player["age"])==3,"annual progression not restored")
	# Displayed choices still survive saving and block progression.
	fresh(20)
	var decision := {"id":"_v31_pause","title":"A required decision","text":"Choose first.","choices":[{"label":"Continue","outcomes":[{"text":"I chose.","effects":{"happiness":1}}]}],"no_friction":true}
	EventEngine.push_decision(decision)
	EventEngine.pop_next()
	EventEngine.progress()
	ok(GameState.player["age"]==20,"displayed decision skipped")
	GameState.from_dict(saved())
	ok(EventEngine.pending.size()==1,"displayed decision lost")
	EventEngine.resolve(EventEngine.pop_next(),0)
	clear_events()
	# Bundles charge full costs, retain preferences and cannot be repeated.
	for id in Bulk.PACKS:
		if id=="learning": continue
		fresh()
		GameState.player["time_left"]=12
		GameState.player["activity_lengths"]={"walk":0,"gym":2}
		if id=="work": GameState.player["job"]={"id":"fixture","title":"Test job","field":"Trades","perf":40.0,"salary":10000,"years":0,"worked_hard":false}
		var money := int(GameState.player["money"])
		var time := int(GameState.player["time_left"])
		ok(Bulk.reason(id)=="","valid bundle rejected: "+id)
		Bulk.act("run",id)
		ok(money-int(GameState.player["money"])==Bulk.price(id),"bundle wrong cost: "+id)
		ok(time-int(GameState.player["time_left"])==int(Bulk.PACKS[id]["time"]),"bundle wrong time: "+id)
		ok(GameState.player["activity_lengths"]=={"walk":0,"gym":2},"bundle changed individual preferences")
		ok(EventEngine.pending.size()==1,"bundle produced extra popups: "+id)
		clear_events()
		ok(Bulk.reason(id)!="","bundle annual guard failed")
		if id=="home": ok(Household.state()["completed_year"]==GameState.year_now()+1 and Household.state()["rest_year"]==GameState.year_now(),"household duties not completed")
		if id=="work": ok(GameState.player["job"]["worked_hard"],"work duty not completed")
	for constraint in ["age","cash","time","custody","used","event"]:
		fresh()
		if constraint=="age": GameState.player["age"]=4
		if constraint=="cash": GameState.player["money"]=0
		if constraint=="time": GameState.player["time_left"]=1
		if constraint=="custody": GameState.player["prison"]=2
		if constraint=="used": GameState.player["bulk_used"]={"fitness":GameState.year_now()}
		if constraint=="event": EventEngine.push_decision(decision)
		var money := int(GameState.player["money"])
		var time := int(GameState.player["time_left"])
		ok(Bulk.reason("fitness")!="","missing preflight: "+constraint)
		Bulk.act("run","fitness")
		ok(int(GameState.player["money"])==money and int(GameState.player["time_left"])==time,"failed preflight charged player")
	# Lifestyle changes are bounded, persisted and sensitive to actual habits.
	fresh()
	GameState.player["money"]=0
	Actions.do_activity_for("yoga",1)
	ok(Lifestyle.state()["activities"].is_empty(),"unaffordable activity counted as completed lifestyle")
	fresh()
	for key in GameState.STAT_KEYS: GameState.player["stats"][key]=70.0
	var baseline := saved()
	Lifestyle.advance(false)
	var idle: Dictionary = GameState.player["stats"].duplicate(true)
	ok(idle["health"]<70 and idle["smarts"]<70 and idle["looks"]<70 and idle["happiness"]<70 and idle["stress"]<70,"idle lifestyle did not affect all stats")
	Lifestyle.advance(false)
	ok(GameState.player["stats"]==idle,"lifestyle applied twice in year")
	GameState.from_dict(baseline)
	clear_events()
	for habit in ["gym","walk","yoga","read","library","meditate","movie","spa"]: Lifestyle.note(habit)
	Lifestyle.advance(false)
	for key in ["health","smarts","looks","happiness"]: ok(GameState.stat(key)>float(idle[key]),"habits made no difference: "+key)
	ok(GameState.stat("stress")<float(idle["stress"]),"calm habit did not improve stress")
	ok(Lifestyle.state()["activities"].is_empty(),"annual activity window not reset")
	fresh(0)
	for key in GameState.STAT_KEYS: GameState.player["stats"][key]=70.0
	LifeCourse.state()["months"]=1
	Lifestyle.advance(true)
	var month_stats: Dictionary = GameState.player["stats"].duplicate(true)
	for key in GameState.STAT_KEYS: ok(absf(GameState.stat(key)-70.0)<=1.0,"month applied full annual swing")
	Lifestyle.advance(true)
	ok(GameState.player["stats"]==month_stats,"monthly double application")
	GameState.from_dict(saved())
	var restored_stats: Dictionary = GameState.player["stats"].duplicate(true)
	Lifestyle.advance(true)
	for key in GameState.STAT_KEYS:
		ok(is_equal_approx(GameState.stat(key),float(month_stats[key])),"reload changed monthly stat: "+key)
	ok(GameState.player["stats"]==restored_stats,"reload repeated monthly drift")
	LifeCourse.state()["months"]=12
	Lifestyle.advance(true)
	ok(Insight.state()["history"][-1]["age"]==1 and Insight.state()["history"][-1]["month"]==0,"birthday lifestyle recorded at wrong age")
	# Both choices of all eight source scenes have a distinct, one-time callback.
	for id in Insight.callback_library:
		var source: Dictionary = LifeCourse.scenes.filter(func(d): return d["id"]==id)[0]
		for index in range(2):
			fresh(int(source["min"]))
			EventEngine.resolve({"def":source,"roles":{}},index)
			ok(Insight.state()["callbacks"].size()==1,"callback missing")
			Insight.remember_choice(source,index)
			ok(Insight.state()["callbacks"].size()==1,"callback duplicated")
			var prior := int(GameState.player["age"])
			Insight.yearly()
			ok(EventEngine.pending.is_empty(),"callback arrived too early")
			GameState.player["age"] = prior+2
			Insight.yearly()
			ok(EventEngine.pending.size()==1 and Insight.state()["callbacks"].is_empty(),"due callback missing")
			Director.curate()
			var inst := EventEngine.pop_next()
			ok(str(inst["def"]["text"]).contains(source["choices"][index]["label"]),"callback forgot exact choice")
			var stored := saved()
			GameState.from_dict(stored)
			ok(EventEngine.pending.size()==1,"callback lost on load")
			EventEngine.resolve(EventEngine.pop_next(),0)
			ok(Insight.state()["history"].size()>=2,"consequence effect not recorded")
			Insight.yearly()
			ok(EventEngine.pending.is_empty(),"callback replayed")
	# Measured ledger includes bond and real deltas, and stays bounded.
	fresh()
	var friend := GameState.create_npc("friend",{"age":30,"closeness":50})
	BondStats.ensure(friend)
	BondStats._sync(friend)
	var before := Insight.snapshot()
	GameState.apply_effects({"health":-3,"money":-500,"stress":4})
	GameState.change_closeness(friend,7)
	Insight.record(before,"Measured choice","A specific consequence.")
	var changes: String = " ".join(Insight.state()["history"][-1]["changes"])
	ok(changes.contains("Health -3.0") and changes.contains("Stress +4.0") and changes.contains("Trust +2.1"),"ledger guessed rather than measured: "+changes)
	for i in range(100): Insight.record(Insight.snapshot(),"Memory","A result")
	ok(Insight.state()["history"].size()==80,"ledger grew unbounded")
	var old := saved()
	GameState.from_dict(old)
	ok(Insight.state()["history"].size()==80,"ledger lost on save")
	# Saved Depth stages must be restored once, not twice.
	clear_events()
	Depth.state()["active"]={"kind":"fixture"}
	Depth._push("Stage","Saved stage",[{"label":"Wait","outcomes":[{"text":"Waiting"}]}])
	var stage := saved()
	GameState.from_dict(stage)
	ok(EventEngine.pending.size()==1,"Depth prompt duplicated on load")
	fresh()
	var child := GameState.create_npc("child",{"age":12,"gender":"female","closeness":80})
	GameState.npcs[child]["parent_id"]="player"
	ok(Dynasty.switch_to(child),"child transfer failed")
	ok(int(GameState.player["age"])==12,"transfer changed child age")
	print("V31 TEST checks=%d failures=%d" % [checks,failures.size()])
	for reason in failures: print("FAIL: "+str(reason))
	get_tree().quit(0 if failures.is_empty() else 1)
