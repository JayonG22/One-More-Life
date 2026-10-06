extends Node
var checks := 0
var failures: Array = []
func ok(c: bool,m: String) -> void:
	checks += 1
	if not c: failures.append(m)
func fresh(path: String="human", extra: Dictionary={}) -> void:
	EventEngine.pending.clear()
	GameState.new_life({"gender":"female","country":"us","life_path":path}.merged(extra,true))
	GameState.player["age"] = 24
	GameState.player["money"] = 100000

func _ready() -> void:
	seed(2626)
	ok(ContentDB.events.size() == ContentDB.events_by_id.size(),"duplicate event IDs share cooldown or follow-up state")
	fresh()
	var weather := Climate.snapshot().duplicate(true)
	for i in range(30): ok(Climate.snapshot()==weather,"weather rerolls on eligibility")
	ok(not Context.matches({"weather":"impossible"}),"invalid weather passes")
	ok(not Context.matches({"unknown":"x"}),"unknown context passes")
	GameState.player["education"]["degrees"]=[{"major":"english","level":"bachelor"}]
	ok(Context.matches({"major":"english"}) and not Context.matches({"current_major":"english"}),"completed degree acts as current enrolment")
	var event := {"id":"repeat-test","text":"One question","conditions":{"age":[18,90]},"cooldown":0}
	Director.note(event)
	GameState.event_history[event["id"]]=24
	for age in range(24,29):
		GameState.player["age"]=age
		ok(not EventEngine._eligible(event,false),"repeat appears inside five-year cooldown")
	GameState.player["age"]=29
	ok(EventEngine._eligible(event,false),"event never becomes available again")
	var duplicate := event.duplicate(true)
	duplicate["id"]="different-id"
	GameState.player["age"]=25
	ok(not EventEngine._eligible(duplicate,false),"duplicate question bypasses cooldown by id")
	# Shelved optional events retain their previous history, and required decisions survive.
	fresh()
	GameState.settings["event_density"] = "normal"
	GameState.player["age"] = 24
	var queued: Array = []
	for i in range(5):
		var d := {"id":"budget_%d" % i,"themes":["theme_%d" % i],"text":"Budget question %d" % i}
		GameState.event_history[d["id"]] = 24
		queued.append({"def":d,"roles":{},"created":[],"previous_age":10})
	EventEngine.pending = queued
	Director.curate()
	ok(EventEngine.pending.size() == 2,"optional questions exceed the yearly budget")
	ok(GameState.event_history["budget_4"] == 10,"shelved question loses its previous history")
	EventEngine.pending = [{"def":{"id":"_trial"}},{"def":{"id":"_family_required"}},{"def":{"id":"optional"}}]
	Director.curate()
	ok(EventEngine.pending.size() == 2 and EventEngine.pending[0]["def"]["id"] == "_trial","pacing discards required decisions")
	for era in [1850,1920,1970]:
		fresh("traveler",{"era":era})
		World._w()["events"]["crypto"] = 3
		ok(not World.active("crypto") and not World.active_list().has("crypto"),"old timeline retains an incompatible world shock")
		for def in ContentDB.events:
			var timeline = def.get("conditions",{}).get("context",{}).get("timeline",null)
			if timeline!=null: ok(EventEngine._eligible(def,false)==(str(timeline)==str(era)),"timeline scene mismatches "+str(def["id"]))
		ok(not EventEngine._eligible({"id":"modern","available_from":1995,"conditions":{"age":[0,100]}},false),"modern event enters early timeline")
	for path in ["pirate","colonist"]:
		fresh(path)
		ok(not EventEngine._eligible({"id":"commute","conditions":{"age":[18,90]}},false),"commuter scene enters "+path)
		ok(EventEngine._eligible(ContentDB.events_by_id["setting."+path+(".chart" if path=="pirate" else ".air")],false),"setting event unavailable "+path)
	fresh()
	var first := Actions.listings("full").duplicate()
	Actions.listings("part")
	ok(Actions.listings("full")==first,"switching categories rerolls board")
	var posts := Market.openings("full").duplicate(true)
	Market.openings("part")
	ok(Market.openings("full")==posts,"employers reroll across categories")
	var jd := ContentDB.job("data_analyst")
	GameState.player["education"]["degrees"]=[]
	var untrained := Market.education_fit(jd)
	GameState.player["education"]["degrees"]=[{"major":"computer_science","level":"bachelor"}]
	ok(Market.education_fit(jd)>untrained,"degree does not improve relevant employment")
	Market.train("Tech")
	var practice := Market.skill("Tech")
	var cash := int(GameState.player["money"])
	Market.train("Tech")
	ok(practice>0 and Market.skill("Tech")==practice and int(GameState.player["money"])==cash,"course repeat creates farming exploit")
	EventEngine.pending.clear()
	var price := float(GameState.world["stocks"]["NMB"])
	GameState.world.erase("price_history")
	GameState.world["stocks"].erase("BND")
	Finance.ensure_market()
	ok(float(GameState.world["stocks"]["NMB"])==price and GameState.world["stocks"].has("BND"),"migration resets prices or misses asset")
	Finance.buy("stock","NMB",-100)
	ok(int(GameState.player["money"])==cash,"negative investment creates cash")
	for i in range(30):
		GameState.player["age"] += 1
		Finance._yearly_market()
	ok(Finance.history("NMB").size()==24,"market history is not bounded")
	var plot: Control = load("res://scenes/price_chart.gd").new()
	plot.setup(Finance.history("NMB"))
	add_child(plot)
	fresh()
	var s := Lore.state()
	var person := str(s["threads"][0]["name"])
	s["threads"][0]["next"]=GameState.year_now()
	Lore.yearly()
	ok(int(s["threads"][0]["stage"])==1 and s["history"].size()==1,"world story does not advance autonomously")
	Lore.yearly()
	ok(s["history"].size()==1,"world story advances twice in a year")
	ok(str(Lore.state()["threads"][0]["name"])==person,"world cast rerolls on read")
	for d in TVLife.catalog:
		fresh("tv",{"character":d["id"]})
		GameState.player["age"]=0
		ok(Lives.separate() and Lives.mode()==TVLife,"TVLife missing mode adapter")
		for i in range(d["chapters"].size()):
			TVLife.advance()
			var inst := EventEngine.pop_next()
			ok(inst["def"]["title"]==d["chapters"][i]["title"],"TVLife chapter order changes")
			ok(int(Lives.life()["chapter"])==i,"unanswered chapter advances cursor")
			EventEngine.resolve(inst,i%3)
			ok(int(Lives.life()["chapter"])==i+1,"reflection fails to checkpoint")
		var saved := GameState.to_dict().duplicate(true)
		GameState.from_dict(saved)
		ok(int(Lives.life()["chapter"])==d["chapters"].size(),"TVLife save loses cursor")
		ok(TVLife.story().contains(str(d["chapters"][-1]["title"])),"TVLife journal loses ending")
		var e := GameState.finalize_death("the end of this story arc")
		ok(e["mode"].get("story_complete",false),"TVLife ending records a fake death")
	ok(Avatar.STYLE.size()>=27 and Avatar.BG_COL.size()>=16,"vanity catalog missing entries")
	print("V26 TEST checks=%d failures=%d" % [checks,failures.size()])
	for f in failures: print("FAIL: ",f)
	get_tree().quit(1 if not failures.is_empty() else 0)
