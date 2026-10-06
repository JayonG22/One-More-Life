extends Node
var checks := 0
var failures: Array=[]
var endings: Dictionary={}
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear()
func explore(depth: int=0) -> void:
	if not GameState.is_alive(): endings[Lives.life().get("ending","")]=true; return
	if depth>14: ok(false,"Campaign has an unending branch"); return
	var story := TVLife.profile(); var chapter := int(Lives.life()["chapter"])
	var snapshot: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
	for i in range(story["chapters"][chapter]["choices"].size()):
		GameState.from_dict(snapshot.duplicate(true)); clear()
		TVLife.advance()
		var event := EventEngine.pop_next()
		ok(not event.is_empty() and event["def"]["title"]==story["chapters"][chapter]["title"],"Wrong queued campaign chapter")
		var pending: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
		GameState.from_dict(pending); clear()
		TVLife.branch({"story":story["id"],"chapter":chapter,"choice":i}); clear()
		var size0: int=Lives.life()["journal"].size()
		ok(GameState.player["age"]==story["age"],"Reading a scene advanced a simulation year")
		ok(GameState.log_years[-1]["age"]==size0,"Story log uses character age instead of reading order")
		ok(size0==snapshot["player"]["life"]["journal"].size()+1,"Branch choice not recorded once")
		TVLife.branch({"story":story["id"],"chapter":chapter,"choice":i}); clear()
		ok(Lives.life()["journal"].size()==size0,"Completed branch paid/recorded twice")
		GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
		ok(Lives.life()["journal"].size()==size0,"Saved branch journal changed")
		explore(depth+1)
func _ready() -> void:
	seed(101200); GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	ok(TVLife.catalog.size()==12 and TVLife.catalog.all(func(story): return story.get("original",false)),"Public story library is not twelve original campaigns")
	var texts: Array=[]
	for id in ["stormpost","moon_shift","lantern_league","last_receipt","missing_tuesday","detour_season"]:
		GameState.new_life({"country":"us","life_path":"tv","character":id}); clear()
		var story := TVLife.profile()
		ok(story["chapters"].size()==10 and Fx.MUSIC.has(id),"Missing new campaign chapters/music")
		for chapter in story["chapters"]: texts.append(chapter["text"])
		endings={}; explore()
		ok(endings.size()==3 and not endings.has(""),"Not all three campaign endings reachable: "+id)
	ok(texts.size()==60 and texts.all(func(text): return texts.count(text)==1),"New campaigns recycle scene text")
	# Retired preview saves archive the user's journal instead of misreading it
	# as choices from the new graph. Existing completed lives remain completed.
	for old_id in TVLife.RETIRED:
		GameState.new_life({"country":"us","life_path":"tv","character":"stormpost"}); clear()
		GameState.player["life"]={"type":"tv","character":old_id,"chapter":3,"journal":[{"chapter":0,"focus":"The person"},{"chapter":1,"focus":"The relationships"},{"chapter":2,"focus":"The turning point"}]}
		GameState.player["first"]="My earlier reader"
		EventEngine.pending=[{"def":{"id":"_tv_"+old_id+"_3","choices":[]}}]
		var save: Dictionary=JSON.parse_string(JSON.stringify(GameState.to_dict()))
		var original: Dictionary=save.duplicate(true)
		GameState.from_dict(save)
		ok(EventEngine.pending.is_empty(),"Retired decision survived migration")
		clear()
		ok(save==original,"Migration changed the source backup snapshot")
		ok(Lives.life()["character"]==TVLife.RETIRED[old_id] and Lives.life()["chapter"]==0,"Retired story mapped to an invalid cursor")
		ok(GameState.player["age"]==TVLife.profile()["age"],"Replacement retained the retired character's age")
		TVLife.reflect({"chapter":0,"focus":"The person"})
		ok(Lives.life()["chapter"]==0 and Lives.life()["journal"].is_empty(),"Retired callback skipped an original scene")
		ok(GameState.player["story_archives"].size()==1 and GameState.player["story_archives"][0]["journal"].size()==3,"Retired journal lost")
		ok(TVLife.quick().any(func(row): return row[2]=="tv:archives") and TVLife.menu("archives")["info"].size()>=4,"Retired journal inaccessible")
		GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
		ok(GameState.player["story_archives"].size()==1,"Migration duplicated archived journal")
		TVLife.advance(); var notice := EventEngine.pop_next()
		ok(notice.get("info",false) and Lives.life()["chapter"]==0,"Replacement notice missing or advanced chapter")
		clear(); TVLife.advance(); ok(not EventEngine.pop_next().get("info",false),"Replacement never begins")
		clear(); save["player"]["alive"]=false
		GameState.from_dict(save); clear()
		ok(not GameState.is_alive() and Lives.life()["chapter"]==TVLife.profile()["chapters"].size(),"Completed preview was revived")
	GameState.settings["content_themes"]={"crime":false}
	ok(not TVLife.available("last_receipt"),"Crime campaign ignores theme preference")
	for id in ["harbour_echoes","stormpost"]:
		GameState.new_life({"country":"us","life_path":"tv","character":id}); clear()
		TVLife.branch({"story":id,"chapter":0,"choice":0}); clear()
		Lives.life().erase("scene_log"); GameState.player["age"]+=1
		GameState.log_years[0]["age"]=GameState.player["age"]-1; GameState.log_years[1]["age"]=GameState.player["age"]
		var old_lines: Array=GameState.log_years.map(func(year): return year["lines"].duplicate(true))
		var old_journal: Array=Lives.life()["journal"].duplicate(true)
		GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
		ok(GameState.log_years[0]["age"]==0 and GameState.log_years[1]["age"]==1,"Old original log was not migrated to scenes")
		ok(GameState.log_years.map(func(year): return year["lines"])==old_lines and Lives.life()["journal"]==JSON.parse_string(JSON.stringify(old_journal)),"Old original migration lost story writing or choices")
		ok(GameState.player["age"]==TVLife.profile()["age"],"Old original migration retained incorrect yearly ageing")
	for player in Fx.find_children("*","AudioStreamPlayer",true,false): player.stop(); player.stream=null
	await get_tree().create_timer(0.2).timeout
	print("ORIGINAL CAMPAIGNS checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
