extends Node

## Original branching stories. Simulation years, health hazards and unrelated
## actions cannot change their timeline. Saved journals belong to this reader.
var catalog: Array = []
const RETIRED := {"aang":"stormpost","fry":"moon_shift","naruto":"lantern_league","walter":"last_receipt"}

func _ready() -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/tv_life.json"))
	catalog.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://data/original_stories.json")))

func profile(id: String = "") -> Dictionary:
	var key := id if id != "" else str(Lives.life().get("character", "stormpost"))
	key=str(RETIRED.get(key,key))
	for p in catalog:
		if str(p["id"]) == key: return p
	return catalog[0]

func setup(opts: Dictionary) -> void:
	var d := profile(str(opts.get("character", "stormpost")))
	var p := GameState.player
	p["life"] = {"type":"tv", "character":d["id"], "chapter":0, "journal":[],"scene_log":true}
	p["first"] = d["name"]
	p["last"] = ""
	p["gender"] = d["gender"]
	p["age"] = int(d.get("age",0))
	p["money"] = 0
	p["traits"] = []
	p["job"] = {}
	p["career"] = {}
	GameState.npcs.clear()
	GameState.log_years = [{"age":0,"lines":[]}]
	GameState.milestones.clear()
	GameState.add_log("Story Life · %s. Choices branch toward alternate endings." % d["show"])
func migrate_retired() -> void:
	var p := GameState.player
	var l: Dictionary=p.get("life",{})
	if l.get("type","")!="tv": return
	if not RETIRED.has(str(l.get("character",""))):
		# Older original campaigns also recorded character age as chapter numbers.
		# Keep every log line and choice, but use their actual reading order.
		if not l.get("scene_log",false):
			for i in range(GameState.log_years.size()): GameState.log_years[i]["age"]=i
			if GameState.is_alive(): p["age"]=int(profile().get("age",0))
			l["scene_log"]=true
		return
	var old_id := str(l["character"])
	var archive := {"id":old_id,"name":p.get("first","Archived reader"),"chapter":l.get("chapter",0),"journal":l.get("journal",[]).duplicate(true),"log":GameState.log_years.duplicate(true),"completed":not GameState.is_alive()}
	if not p.has("story_archives"): p["story_archives"]=[]
	p["story_archives"].append(archive)
	var replacement := profile(str(RETIRED[old_id]))
	l["character"]=replacement["id"]; l["journal"]=[]; l["story_flags"]={}; l["scene_log"]=true
	l["chapter"]=0 if GameState.is_alive() else replacement["chapters"].size()
	l["replacement_notice"]=true
	if not GameState.is_alive(): l["ending"]="Archived preview completed"
	p["first"]=replacement["name"]; p["last"]=""; p["gender"]=replacement["gender"]
	if GameState.is_alive():
		p["age"]=int(replacement.get("age",0))
		GameState.log_years=[{"age":0,"lines":[]}]
	# An unresolved retired preview must not appear on top of the new campaign.
	EventEngine.pending=EventEngine.pending.filter(func(item):
		var def: Dictionary=item.get("def",{})
		if str(def.get("id","")).begins_with("_tv_"): return false
		return not def.get("choices",[]).any(func(choice): return choice.get("outcomes",[]).any(func(outcome): return outcome.has("tv_reflection")))
	)
	GameState.add_log("The retired preview journal was archived. Its replacement is the original campaign "+str(replacement["show"])+". No story completion reward was added.")
func available(id: String) -> bool:
	return profile(id).get("theme","")=="" or Journey.modules["identity"].allowed(str(profile(id)["theme"]))

func advance() -> void:
	if not Lives.is_type("tv") or not GameState.is_alive() or EventEngine.has_pending(): return
	var l := Lives.life()
	var d := profile()
	if l.get("replacement_notice",false):
		l["replacement_notice"]=false
		EventEngine.push_info("📖","Your earlier journal is safe","The TV-based preview has been replaced by an original campaign. Your old choices and saved log remain in Story → Earlier journal. The new story begins at its first chapter.")
		return
	var i := int(l.get("chapter",0))
	if i >= d["chapters"].size():
		EventEngine.kill("the end of this story arc", true)
		return
	var ch: Dictionary = d["chapters"][i]
	if d.get("original",false):
		var options: Array=[]
		for k in range(ch["choices"].size()): options.append({"label":ch["choices"][k]["label"],"outcomes":[{"text":"","no_friction":true,"tv_branch":{"chapter":i,"choice":k,"story":d["id"]}}]})
		EventEngine.push_decision({"id":"_original_"+str(d["id"]),"icon":d["icon"],"title":ch["title"],"text":ch["text"],"choices":options,"no_friction":true})
		return

func reflect(_record: Dictionary) -> void:
	# Compatibility hook: a retired preview callback cannot advance an original.
	pass

func menu(key: String) -> Dictionary:
	var d := profile()
	var rows: Array = []
	var info: Array = [d["show"], d["coverage"]]
	var heading := "Journal"
	if key=="archives":
		var saved: Array=GameState.player.get("story_archives",[])
		var history: Array=[]
		for archive in saved:
			history.append(str(archive["name"])+" · "+str(archive["chapter"])+" chapter(s) previously read"+(" · completed" if archive.get("completed",false) else " · preview replaced"))
			for record in archive["journal"]: history.append("Chapter %d · %s" % [int(record["chapter"])+1,str(record["focus"])])
			for year in archive.get("log",[]):
				for line in year.get("lines",[]): history.append(str(line))
		return {"icon":"📖","title":"Earlier journal","info":history if not history.is_empty() else ["No earlier preview journal."],"rows":[]}
	if key == "character":
		return {"icon":d["icon"],"title":d["name"],"info":[d["category"],d["show"],d["coverage"],"An original fictional campaign. Choices, trust and pressure can change the route and ending."],"rows":[]}
	if key == "arc":
		for i in range(d["chapters"].size()):
			var read: bool=Lives.life().get("journal",[]).any(func(r): return int(r["chapter"])==i)
			rows.append({"icon":"✓" if read else "○", "name":"Chapter %d · %s" % [i+1, d["chapters"][i]["title"] if read else "Not read yet"], "sub": "Read" if read else "Continue the story to reveal this chapter", "on":false})
		return {"icon":"🗺️", "title":"Story arc · %s" % d["name"], "info":["%d of %d scenes read · choices reveal different routes" % [Lives.life().get("journal",[]).size(),d["chapters"].size()]], "rows":rows}
	if key == "story":
		heading = "Story"
		info.append("Next Chapter advances the story. Read chapters are collected below.")
	elif key == "reflections":
		heading = "Choices"
		info.append("Your choices, saved once per scene.")
	else:
		info.append("Spoilers for chapters you have read. Your saved story journal.")
	for r in Lives.life().get("journal",[]):
		var ch: Dictionary = d["chapters"][int(r["chapter"])]
		rows.append({"icon":"💭" if key == "reflections" else "📖","name":ch["title"],"sub":"%s · %s" % [ch["period"],r["focus"]] if key == "reflections" else "%s · %s\n%s" % [ch["period"],r["focus"],ch["text"]],"on":false})
	if rows.is_empty(): info.append("No chapters read yet. Use Next Chapter to begin.")
	return {"icon":d["icon"],"title": heading + " · " + str(d["name"]),"info":info,"rows":rows}

func act(_key: String, _arg) -> void: pass
func branch(spec: Dictionary) -> void:
	if not Lives.is_type("tv") or not GameState.is_alive(): return
	var d := profile(); var l := Lives.life(); var chapter := int(l.get("chapter",0))
	if not d.get("original",false) or str(spec.get("story",""))!=str(d["id"]) or int(spec.get("chapter",-1))!=chapter: return
	var choices: Array=d["chapters"][chapter]["choices"]
	var choice_index := int(spec.get("choice",-1))
	if choice_index<0 or choice_index>=choices.size(): return
	var choice: Dictionary=choices[choice_index]
	if not l.has("story_flags"): l["story_flags"]={}
	for flag in choice.get("flags",{}): l["story_flags"][flag]=int(l["story_flags"].get(flag,0))+int(choice["flags"][flag])
	l["journal"].append({"chapter":chapter,"focus":choice["label"]})
	# A scene is not a simulation year. Keep the character's established age;
	# the saved log uses reading order, independent of graph indices and age.
	var scene: int=l["journal"].size()
	GameState.log_years.append({"age":scene,"lines":[]})
	GameState.year_started.emit(scene)
	GameState.add_log(str(d["chapters"][chapter]["title"])+": "+str(choice["label"]))
	var target: Variant=choice["next"]
	if target is Dictionary: target=int(target["then"]) if int(l["story_flags"].get(target["flag"],0))>=int(target["min"]) else int(target["else"])
	if int(target)<0:
		l["chapter"]=d["chapters"].size(); l["ending"]=d["chapters"][chapter]["title"]
		EventEngine.kill("the end of "+str(d["show"]),true)
	else: l["chapter"]=int(target)
func portrait() -> String: return str(profile()["icon"])
func relation_name(_rel: String, _g: String) -> String: return "Cast"
func header_occ() -> String: return str(profile()["show"])
func header_sub() -> String: return str(profile()["category"]) + " · Story Life"
func title() -> String: return "Story Life"
func money_text() -> String: return "%d / %d" % [Lives.life().get("journal",[]).size(),profile()["chapters"].size()]
func money_state() -> int: return 0
func tracks() -> Array: return []
func home_text() -> String: return str(profile()["coverage"])
func fin_text() -> String: return "A branching story, a saved journal."
func extra_text() -> String: return "Use Next Chapter to continue."
func balance_label() -> String: return "Chapters read"
func quick() -> Array:
	var rows: Array=[["📖","Journal","tv:journal"],["🎬","Story","tv:story"]]
	if not GameState.player.get("story_archives",[]).is_empty(): rows.append(["📚","Earlier journal","tv:archives"])
	return rows
func tabs() -> Array: return [["🎬","Story","tv:story"],["📖","Journal","tv:journal"],["🧑","Character","tv:character"],["🗺️","Arc","tv:arc"],["💭","Choices","tv:reflections"],["⋯","More","more"]]
func side_labels() -> Dictionary: return {"happiness":["💭","Mood"],"health":["📖","Story"],"smarts":["💡","Insight"],"looks":["🎭","Presence"],"stress":["⚡","Tension"]}
func story() -> String:
	var lines: Array = [str(profile()["name"]) + " · " + str(profile()["coverage"])]
	for r in Lives.life().get("journal",[]):
		var ch: Dictionary = profile()["chapters"][int(r["chapter"])]
		lines.append("%s: %s\nChoice: %s." % [ch["title"],ch["text"],r["focus"]])
	return "\n\n".join(lines)
func ribbon() -> Dictionary: return {"icon":"🎬","name":"Story Complete","desc":"Reached an ending of an original campaign."}
func entry_extra() -> Dictionary:
	var card: Array=[["Story",profile()["show"]],["Arc",profile()["coverage"]],["Chapters",money_text()]]
	if Lives.life().has("ending"): card.append(["Ending",Lives.life()["ending"]])
	return {"title":"Story Complete","story_complete":true,"character":profile()["id"],"card":card,"icon":profile()["icon"]}
