extends Node
var checks := 0
var failures: Array=[]
var c
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func clear() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear(); Journey.state()["prompt"]={}
func fresh(age: int = 35) -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false,"born_year":1980})
	GameState.player["age"]=age; GameState.player["money"]=100000; GameState.player["time_left"]=200
	GameState.player["stats"]["stress"]=70; c=Journey.modules["coping"]; clear()
func reload() -> void:
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
func next_year() -> void:
	GameState.player["age"]+=1; GameState.player["time_left"]=200; clear()
func strained() -> void:
	c.st()["loneliness"]=75; c.st()["burnout"]=75
	c.st()["losses"]=[{"uid":"known-departed","name":"A remembered friend","year":GameState.year_now(),"burden":60.0,"remembered":-99,"relation":"friend"}]
	GameState.player["education"]["stage"]="graduated"; GameState.player["education"]["uni"]={"major":"computing","left":2}; GameState.player["job"]={"id":"software","title":"Developer","salary":10000}
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; GameState.settings["effects"]=false; Fx.apply_volumes()
	fresh(); var parent := GameState.create_npc("mother",{"age":70,"closeness":80}); var name := GameState.full_name(parent); EventEngine._npc_died(parent); clear()
	ok(c.st()["losses"].size()==1 and c.st()["losses"][0]["name"]==name,"Actual bereavement has no named dated record")
	var happy := GameState.stat("happiness"); EventEngine._npc_died(parent)
	ok(c.st()["losses"].size()==1 and GameState.stat("happiness")==happy,"Death/strain settled twice")
	c.clinical(); ok(not GameState.has_flag("lost_close_person") and c.grief_risk(),"Recent loss not linked or permanent flag remains")
	GameState.player["age"]+=4; ok(not c.grief_risk(),"Old loss keeps manufacturing new clinical grief")
	var uid: String=c.st()["losses"][0]["uid"]; var before: float=c.grief(); c.remember(uid); clear()
	ok(c.grief()==before-8 and c.st()["losses"][0]["name"]==name,"Remembering erases identity or does not relieve strain")
	before=c.grief(); var time: int=GameState.player["time_left"]; c.remember(uid); clear(); ok(c.grief()==before and GameState.player["time_left"]==time,"Remembering can be farmed")
	reload(); ok(c.st()["losses"][0]["name"]==name,"Reload forgets named loss")
	fresh(); GameState.set_flag("lost_close_person"); c.clinical(); ok(c.st()["legacy_loss"] and c.st()["losses"].is_empty() and not c.grief_risk(),"Legacy flag invents a person or recurring loss")
	fresh(); c.st()["loneliness"]=60; var friend := GameState.create_npc("friend",{"age":30,"closeness":80}); uid=FamilyChronicle.identity(GameState.npc(friend)); var trust: float=BondStats.ensure(friend)["trust"]
	c.talk(uid); clear(); ok(c.st()["loneliness"]==50 and c.connection_count()==1 and BondStats.ensure(friend)["trust"]>trust,"Conversation fails to affect actual relationship and strain")
	time=GameState.player["time_left"]; c.talk(uid); clear(); ok(GameState.player["time_left"]==time,"Repeated conversation spends time/rewards")
	GameState.npc(friend)["alive"]=false; ok(c.connection_count()==0,"Dead contact still provides living connection")
	fresh(); c.st()["loneliness"]=60; friend=GameState.create_npc("friend",{"age":30,"closeness":80}); Bonds._res(friend,"🤝","A shared afternoon",5); clear()
	ok(c.connection_count()==1 and c.st()["loneliness"]==54,"Existing positive relationship action is detached from coping")
	Bonds._res(friend,"🤝","A second kind act",5); clear(); ok(c.st()["loneliness"]==54,"Repeated action farms annual contact reward")
	fresh(); strained(); before=c.st()["burnout"]; c.routine("boundaries"); clear()
	ok(c.st()["burnout"]==before-6 and GameState.player["time_left"]==198,"Boundaries miss immediate effort or relief")
	next_year(); var stress: float=GameState.stat("stress"); c.yearly(); ok(GameState.stat("stress")<=stress and c.st()["routine"]=="boundaries","Routine has no next-year consequence")
	var snapshot := JSON.stringify(c.st()); stress=GameState.stat("stress"); c.yearly(); ok(JSON.stringify(c.st())==snapshot and GameState.stat("stress")==stress,"Coping year settles twice")
	GameState.player["age"]+=3; c.yearly(); ok(c.st()["routine_year"]<GameState.year_now()-1,"Routine renewal guard broken")
	fresh(); strained(); c.routine("push"); clear(); ok(c.st()["burnout"]==83,"Pushing does not record strain")
	fresh(6); strained(); GameState.player["stats"]["health"]=20; c.routine("gentle"); clear(); ok(c.st()["routine"]=="gentle","Low health excludes manageable activity")
	fresh(5); strained(); c.routine("gentle"); ok(c.st()["routine"]=="none","Older coping routine appears before eligible age")
	fresh(); strained(); before=c.grief(); Expansion.mental_action("therapy"); clear(); ok(c.grief()<before and c.st()["supported"]==GameState.year_now(),"Clinical therapy is disconnected from actual coping course")
	fresh(); strained(); var ready := Aptitude.score("work"); var smarts: float=GameState.stat("smarts"); c.st()["burnout"]=0
	ok(Aptitude.score("work")>ready and GameState.stat("smarts")==smarts,"Burnout doesn't affect readiness or changes innate ability")
	fresh(); var texts: Dictionary={}; var endings: Dictionary={}
	for scene in c.scenes:
		texts[scene["text"]]=true
		for option in scene["choices"]: endings[option["result"]]=true
	ok(c.scenes.size()==16 and texts.size()==16 and endings.size()==48,"Coping content repeats or is missing")
	fresh(12); strained(); GameState.player["job"]={}; GameState.player["education"]["stage"]="secondary"
	ok(not c.available_scenes("burnout").any(func(scene): return scene.get("work_only",false)),"Job scene appears without a job")
	GameState.player["education"]["stage"]="graduated"; GameState.player["education"]["uni"]={}; ok(not c.available_scenes("burnout").any(func(scene): return scene.get("school_only",false)),"School scene appears without schooling")
	fresh(); strained(); var seen: Dictionary={}
	for topic in c.TOPICS:
		for i in range(4):
			GameState.player["stats"]["stress"]=80; c.st()["loneliness"]=75; c.st()["burnout"]=75; c.st()["losses"][0]["burden"]=60
			c.story(topic); var prompt: Dictionary=Journey.state()["prompt"].duplicate(true)
			ok(not prompt.is_empty(),"Eligible coping story unavailable: "+topic)
			if prompt.is_empty(): break
			var scene: Dictionary=prompt["args"]["scene"]; ok(not seen.has(scene["id"]),"Coping story repeats"); seen[scene["id"]]=true
			if topic=="grief": ok(not prompt["def"]["text"].contains("{person}") and prompt["def"]["text"].contains("A remembered friend"),"Loss story has no actual remembered identity")
			var answer: int=i%3; var cash: int=GameState.player["money"]; before=c.pressure(topic)
			clear(); c.resolve("story",prompt["args"],answer); clear()
			ok(GameState.player["money"]==cash-Actions._cost(int(scene["choices"][answer]["cost"])) and c.pressure(topic)!=before,"Story has no real fee or strain consequence")
			cash=GameState.player["money"]; before=c.pressure(topic); c.resolve("story",prompt["args"],answer); clear()
			ok(GameState.player["money"]==cash and c.pressure(topic)==before,"Resolved coping story is replayable")
			ok(not c.st()["followup"].is_empty(),"Story has no scheduled consequence")
			reload(); next_year(); c.yearly(); clear(); ok(c.st()["followup"].is_empty(),"Following year leaves unresolved cliffhanger")
	ok(seen.size()==16,"Not all authored scenes delivered")
	c.story("stress"); ok(Journey.state()["prompt"].is_empty(),"Exhausted coping scenes repeat")
	fresh(12); strained(); GameState.player["money"]=17; var covered: int=Childhood.st()["covered"]; var scene: Dictionary=c.scenes[0]
	c.resolve("story",{"scene":scene,"year":GameState.year_now(),"owner":Journey.uid()},1); clear()
	ok(GameState.player["money"]==17 and Childhood.st()["covered"]==covered+Actions._cost(100),"Child support uses gift money instead of household")
	fresh(); strained(); scene=c.scenes[0]; GameState.player["money"]=0; before=c.pressure("stress")
	c.resolve("story",{"scene":scene,"year":GameState.year_now(),"owner":Journey.uid()},1); clear(); ok(GameState.player["money"]==0 and c.pressure("stress")==before,"Unfunded option charges or grants benefit")
	var child := GameState.create_npc("child",{"age":23,"money":1000}); GameState.npc(child)["journey"]={"coping":c.st().duplicate(true)}; var loss_name: String=c.st()["losses"][0]["name"]
	ok(Dynasty.switch_to(child),"Coping successor cannot transfer"); ok(c.st()["losses"][0]["name"]==loss_name,"Living transfer loses child's actual remembered life")
	reload(); ok(c.st()["losses"][0]["name"]==loss_name,"Reload loses successor coping course")
	var former: Array=GameState.npcs_with("mother").filter(func(id): return GameState.npc(id).has("playable_player"))
	if not former.is_empty():
		var n: Dictionary=GameState.npc(former[0]); before=c.st(n)["losses"][0]["burden"]; c.background(n,GameState.year_now()+1)
		ok(c.st(n)["losses"][0]["burden"]<before,"Remembered strain freezes off screen")
		snapshot=JSON.stringify(c.st(n)); c.background(n,GameState.year_now()+1); ok(snapshot==JSON.stringify(c.st(n)),"Background emotional course settles twice")
		ok(n["playable_player"]["journey"]["coping"]==n["journey"]["coping"],"Off-screen coping diverges from returning snapshot")
	fresh(); strained(); scene=c.scenes[0]; GameState.player["money"]=-500; before=c.pressure("stress")
	c.resolve("story",{"scene":scene,"year":GameState.year_now(),"owner":Journey.uid()},0); clear()
	ok(GameState.player["money"]==-500 and c.pressure("stress")<before,"Personal debt blocks free coping decision")
	fresh(); strained(); scene=c.scenes[0]; before=c.pressure("stress")
	c.resolve("story",{"scene":scene,"year":GameState.year_now(),"owner":"another person"},0)
	ok(c.pressure("stress")==before,"Another person's story modifies the current life")
	c.resolve("story",{"scene":scene,"year":GameState.year_now()-1,"owner":Journey.uid()},0)
	ok(c.pressure("stress")==before,"Earlier-year coping choice applies")
	fresh(); strained(); var heir := GameState.create_npc("child",{"age":23,"money":1000}); GameState.npc(heir)["journey"]={"coping":c.st().duplicate(true)}
	GameState.player["alive"]=false; clear(); GameState.continue_as(heir)
	ok(c.st()["losses"].any(func(loss): return loss["name"]=="A remembered friend") and c.st()["loneliness"]==75,"Inherited child loses existing emotional history")
	fresh(); strained(); GameState.player["time_left"]=0; before=c.st()["burnout"]; c.routine("gentle"); clear()
	ok(c.st()["burnout"]==before and c.st()["routine"]=="none","Unavailable time grants routine benefit")
	fresh(); strained(); before=c.st()["burnout"]; Journey.modules["leisure"].casual(); clear()
	ok(c.st()["burnout"]==before-2,"Existing quiet activity does not ease ongoing strain")
	Journey.modules["leisure"].casual(); clear(); ok(c.st()["burnout"]==before-2,"Quiet pleasure farms strain relief")
	fresh(); c.st()["loneliness"]=60; friend=GameState.create_npc("friend",{"age":30,"closeness":80}); Journey.modules["leisure"].start("reading"); clear(); Journey.modules["leisure"].step()
	var hobby: Dictionary=Journey.state()["prompt"]["args"].duplicate(true); clear(); Journey.modules["leisure"].resolve("step",hobby,0); clear()
	ok(c.connection_count()==1 and c.st()["loneliness"]==54,"Shared hobby doesn't register actual collaborator contact")
	fresh(); var parent_uid: String=Journey.uid(); heir=GameState.create_npc("child",{"age":23,"money":1000}); GameState.player["alive"]=false; clear(); GameState.continue_as(heir)
	ok(c.st()["losses"].any(func(loss): return loss["uid"]==parent_uid),"Inheritance fails to record the actual parent just lost")
	print("COPING TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
