extends Node
var checks := 0
var failures: Array=[]
var endings: Dictionary={}
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func reload_life() -> void: GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
func explore(depth: int = 0) -> void:
	if not GameState.is_alive(): endings[Lives.life().get("ending","")]=true; return
	if depth>14: ok(false,"Original campaign has an unending route"); return
	var chapter := int(Lives.life()["chapter"]); var story := TVLife.profile()
	var snapshot: Dictionary=GameState.to_dict().duplicate(true)
	for index in range(story["chapters"][chapter]["choices"].size()):
		GameState.from_dict(snapshot.duplicate(true)); clear()
		TVLife.branch({"chapter":chapter,"choice":index,"story":story["id"]}); clear()
		var journal_size: int=Lives.life()["journal"].size(); reload_life()
		ok(Lives.life()["journal"].size()==journal_size,"Branch journal lost on reload")
		explore(depth+1)
func _ready() -> void:
	seed(7171); GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	var fresh=Journey.modules["fresh"]
	for key in fresh.SCENARIOS:
		fresh.start(key); clear()
		ok(GameState.player["age"]==int(fresh.SCENARIOS[key][2]) and GameState.year_now()==GameState.START_YEAR,"Scenario age/calendar wrong")
		ok(int(GameState.player["money"])==Actions._cost(int(fresh.SCENARIOS[key][3]))-int(Tenancy.st()["deposit"]),"Scenario deposit creates or loses cash")
		ok(GameState.player["education"]["hs_graduated"] and GameState.player["loan"]==0,"Scenario invents debt or missing school credential")
		var person: String=Journey.person(str(fresh.st()["person"]))
		ok(person!="" and GameState.npc(person)["age"]==GameState.player["age"]+2,"Scenario cast ages wrong")
		if key=="second_act":
			var learning=Journey.modules["learning"]
			learning.enrol("Food","campus"); clear()
			for unit in range(3):
				learning.unit(); var unit_prompt: Dictionary=Journey.state()["prompt"]
				var position: int=unit_prompt["args"]["order"].find(0)
				var selected: Dictionary=unit_prompt["def"]["choices"][position]["outcomes"][0]["journey"].duplicate(true)
				clear(); Journey.outcome(selected); clear()
				ok(learning.st()["course"]["units"]==unit+1,"Scenario course does not earn a unit")
				GameState.begin_year()
			for attempt in range(5):
				if learning.st()["course"].is_empty(): break
				learning.assess(); clear(); GameState.begin_year()
			ok(not learning.st()["completed"].is_empty(),"Scenario practical study never qualifies")
		for stage in range(4):
			var money := int(GameState.player["money"]); fresh.chapter()
			var prompt: Dictionary=Journey.state()["prompt"].duplicate(true); reload_life()
			ok(int(Journey.state()["prompt"]["args"]["stage"])==stage,"Scenario prompt lost on save")
			var answer: Dictionary=prompt["def"]["choices"][0]["outcomes"][0]["journey"]
			clear(); Journey.outcome(answer); clear()
			ok(fresh.st()["stage"]==stage+1 and int(GameState.player["money"])<=money,"Scenario choice creates unearned cash or loses progress")
			var after := int(GameState.player["money"]); Journey.outcome(answer); clear()
			ok(GameState.player["money"]==after,"Scenario outcome applies twice")
			var people=Journey.modules["people"]
			people.help_goal(person,1 if people.motive(person)["goal"]=="quiet" else 0); clear()
			GameState.begin_year(); GameState.player["last_income"]=1000; GameState.player["last_expenses"]=4000
			GameState.player["stats"]["health"]=70; GameState.player["stats"]["happiness"]=70
			fresh.after_finances(); var steady := int(fresh.st()["steady"]); fresh.after_finances()
			ok(int(fresh.st()["steady"])==steady,"Annual scenario review repeats")
		for i in range(3): GameState.begin_year(); fresh.after_finances()
		ok(fresh.st()["completed"] and GameState.is_alive(),"Scenario has no attainable completion or kills life: "+str(key)+" "+str(fresh.review())+" steady="+str(fresh.st()["steady"]))
		var cash := int(GameState.player["money"]); fresh.after_finances(); fresh.chapter(); clear()
		ok(GameState.player["money"]==cash,"Scenario completion produces cash repeatedly")
		var recorded: int=fresh.st()["choices"].size(); reload_life()
		ok(fresh.st()["completed"] and fresh.st()["choices"].size()==recorded,"Completed scenario lost on reload")
	fresh.start("small_world"); clear()
	var old_friend: String=Journey.person(str(fresh.st()["person"]))
	GameState.npc(old_friend)["alive"]=false
	GameState.create_npc("best_friend",{"age":47,"closeness":85})
	ok(fresh.review()["priority"],"A deceased scenario friend permanently blocks belonging")
	fresh.st()["steady"]=2; GameState.player["last_income"]=0; GameState.begin_year(); fresh.after_finances()
	ok(fresh.st()["steady"]==0,"Interrupted income does not reset consecutive steady years")
	for story_id in ["small_hours","borrowed_house"]:
		GameState.new_life({"country":"us","life_path":"tv","character":story_id}); clear(); endings={}; explore()
		ok(endings.size()==3 and not endings.has(""),"Campaign lacks all three reachable endings")
		ok(Fx.MUSIC.has(story_id),"Original campaign lacks its own music")
	for palette in ThemeManager.PALETTES:
		ThemeManager.apply(palette)
		ok(ThemeManager.c("bg").srgb_to_linear().get_luminance()<0.08 and ThemeManager.c("surface").srgb_to_linear().get_luminance()<0.13,"Theme becomes bright")
		ok(ThemeManager.c("primary").s<=0.581,"Theme primary remains oversaturated")
	ThemeManager.apply("ink")
	print("APPLICATION TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
