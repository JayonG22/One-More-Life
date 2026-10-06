extends RefCounted
var h
var chapters: Dictionary={}
const THEMES := {"adult":"Adult relationship drama","crime":"Crime and betrayal scenes","loss":"Loss and illness scenes"}
const MODES := {
	"pet":["A home I can trust",["A new household routine is noisy and unpredictable.","Someone wants training to happen faster than I can manage.","The household changes, but familiar people and places can still help."]],
	"prisoner":["A release worth preparing for",["A program place is available, but a gang wants my time.","A visit brings news of people who have carried on outside.","A release plan needs realistic housing and support."]],
	"guard":["The duty behind the keys",["A colleague dismisses an inmate's recorded concern.","A favour is offered in exchange for ignoring the rules.","The report could protect the institution or expose a failure."]],
	"royal":["A crown with responsibilities",["The household expects a ceremonial promise.","The public asks who can actually access the promised service.","An heir wants a clear account of the duty being inherited."]],
	"witch":["The promise in a spell",["A neighbour asks for magic without discussing its limits.","An apprentice makes a mistake and expects humiliation.","The work needs honest boundaries and a record for whoever follows."]],
	"vampire":["A long life among short lives",["A trusted companion asks what I am hiding.","A long absence has changed the people I once knew.","Someone offers loyalty only if I give up every boundary."]],
	"revenant":["What follows a second life",["Someone I knew remembers my ending differently.","Old unfinished promises return with familiar faces.","I must decide what to carry forward and what to let rest."]],
	"super":["Power and accountability",["A rescue earns praise while a quieter need is overlooked.","A rival offers an easy victory at someone else's expense.","The city asks for an account of the damage and the help."]],
	"pirate":["A crew with a future",["Crew members disagree over the next voyage.","A damaged ship needs a fair division of work and supplies.","A reward must be shared according to the actual agreement."]],
	"colonist":["A settlement worth staying in",["A ration plan serves one group better than another.","A maintenance problem competes with a public celebration.","The settlement needs a handover for the next arrival."]],
	"traveler":["A visitor with a footprint",["Knowledge from another time tempts me to make impossible promises.","Someone notices a mismatch between my story and this era.","A local friendship depends on honest limits rather than borrowed certainty."]]
}
func _init(hub):
	h=hub; chapters=ContentDB._load_json("res://data/mode_chapters.json",{})
func st() -> Dictionary: return h.section("identity",{"mode":{},"mode_history":[],"relationships":{},"pose":"auto","last_mode_year":-1})
func allowed(theme: String) -> bool: return bool(GameState.settings.get("content_themes",{}).get(theme,true))
func definition_allowed(def: Dictionary) -> bool:
	var text := str(def.get("tags",[]))+" "+str(def.get("id",""))
	if not allowed("adult") and (text.contains("affair") or text.contains("intimacy") or text.contains("sex_work")): return false
	if not allowed("crime") and (text.contains("murder") or text.contains("blackmail") or text.contains("betrayal")): return false
	if not allowed("loss") and (text.contains("grief") or text.contains("illness")): return false
	return true
func pose() -> Dictionary:
	if not GameState.player.has("stats"): return {"glyph":"","label":"","tint":Color.WHITE}
	var mood := Depth.expression()
	if st()["pose"]=="neutral": return {"glyph":"🙂","label":"Neutral expression","tint":Color(1,1,1)}
	var tint := Color(1,1,1)
	if GameState.stat("health")<35: tint=Color(0.82,0.86,0.9)
	elif GameState.stat("stress")>75: tint=Color(0.95,0.88,0.85)
	elif GameState.stat("happiness")<25: tint=Color(0.85,0.88,0.95)
	return {"glyph":mood["glyph"],"label":mood["label"],"tint":tint}
func mode_step() -> void:
	var type := str(Lives.life().get("type","human"))
	if not mode_available(type): return
	var p: Dictionary=st()["mode"]
	if p.is_empty() or p.get("type","")!=type: st()["mode"]={"type":type,"stage":0,"quality":35.0,"owner":h.uid()}; p=st()["mode"]
	if int(p["stage"])>=3 or not h.pay("mode_chapter",1,0,0,true,true): return
	var chapter: Dictionary=chapters[type][int(p["stage"])]
	h.decision("identity","mode",{"type":type,"stage":p["stage"],"chapter":chapter},MODES[type][0],chapter["text"],chapter["options"])
func mode_available(type: String) -> bool:
	return MODES.has(type) and int(GameState.player["age"])>=int({"vampire":18,"witch":13,"super":13}.get(type,0)) and (type!="revenant" or Lives.life().has("risen"))
func discuss(id: String) -> void:
	if not GameState.npcs.has(id) or not GameState.npc(id).get("alive",false) or GameState.npc(id)["relation"] not in ["partner","lover"] or int(GameState.npc(id)["age"])<18: return
	if not allowed("adult") or not h.pay("boundaries",1,0,18): return
	var uid := FamilyChronicle.identity(GameState.npc(id))
	if not st()["relationships"].has(uid): st()["relationships"][uid]={"agreement":"exclusive","preference":"exclusive" if abs(uid.hash())%3!=0 else "open","discussed":-1,"trust_steps":0}
	h.decision("identity","boundaries",{"uid":uid},"Boundaries and future plans","Both adults can agree, disagree or ask for time. No sexual scene is depicted; a relationship agreement requires mutual consent.",["Discuss an exclusive commitment","Discuss a consensually open agreement","Ask for time and clarify limits"])
func agreement_for(id: String) -> String:
	if not GameState.npcs.has(id): return "exclusive"
	var uid := FamilyChronicle.identity(GameState.npc(id))
	return str(st()["relationships"].get(uid,{}).get("agreement","exclusive"))
func resolve(op: String, args: Dictionary, answer: int) -> void:
	if op=="mode":
		var p: Dictionary=st()["mode"]
		if p.is_empty() or p["type"]!=args["type"] or int(p["stage"])!=int(args["stage"]) or p["owner"]!=h.uid(): return
		var chapter: Dictionary=args.get("chapter",{})
		var quality_gain := float(chapter.get("quality",[22,-5,2])[answer])
		p["quality"]=clampf(float(p["quality"])+quality_gain,0,100); p["stage"]=int(p["stage"])+1
		if not p.has("choices"): p["choices"]=[]
		p["choices"].append({"year":GameState.year_now(),"text":chapter.get("options",["Listen","Take control","Ignore"])[answer]})
		var type := str(p["type"]); var good := quality_gain>=15
		if type=="pet": Pets.apply({"mood":4 if good else -3})
		elif type in ["prisoner","guard"]: Prison.apply({"conduct":3 if good else -2} if type=="prisoner" else {"integrity":3 if good else -3,"merit":2 if good else -1})
		elif type=="royal": Lives.outcome({"royal":4 if good else -4},{})
		else:
			var l := Lives.life()
			for metric in ["morale","loyalty","respect"]:
				if l.has(metric): l[metric]=clampf(float(l[metric])+(3 if good else -3),0,100)
		GameState.apply_effects({"happiness":chapter.get("happiness",[2,-1,-1])[answer],"stress":chapter.get("stress",[1,3,3])[answer]})
		if int(p["stage"])>=3:
			st()["mode_history"].push_front(p.duplicate(true))
			if st()["mode_history"].size()>12: st()["mode_history"].resize(12)
			GameState.add_milestone(int(GameState.player["age"]),"completed "+str(MODES[type][0]))
		h.done("🎭","A path with consequences","Stage %d/3 · quality %d. The mode's relationships, duty or household mood reflect the choice." % [p["stage"],p["quality"]])
	elif op=="boundaries":
		var id: String=h.person(str(args["uid"]))
		if id=="" or not GameState.npc(id).get("alive",false): return
		var r: Dictionary=st()["relationships"][args["uid"]]; var requested: String = ["exclusive","open","pause"][answer]
		var accepted: bool = requested=="pause" or (requested==r["preference"] and BondStats.get_stat(id,"trust")>=50)
		r["discussed"]=GameState.year_now()
		r["last_request"]=requested
		if accepted:
			if requested!="pause": r["agreement"]=requested
			r["trust_steps"]=int(r["trust_steps"])+1; BondStats.apply(id,{"trust":3,"respect":2})
			r["last_result"]="Mutually agreed to "+requested+" boundaries." if requested!="pause" else "Asked for time; the current agreement remains."
		else:
			BondStats.apply(id,{"respect":1})
			r["last_result"]="They did not agree to "+requested+"; the existing agreement remains."
		FamilyChronicle.remember(id,"Discussed adult relationship boundaries: "+requested+"; "+str(r["last_result"]))
		h.done("💬","A mutual decision",str(r["last_result"])+" Current agreement: "+str(r.get("agreement","exclusive"))+".")
func yearly() -> void: pass
func menu(page: String) -> Dictionary:
	var rows: Array=[]; var info: Array=["Facial features reflect wellbeing. Basic hair, eyes and accessories are free."]
	if page.begins_with("partner:"):
		var id := page.substr(8)
		if GameState.npcs.has(id) and GameState.npc(id).get("alive",false):
			var uid := FamilyChronicle.identity(GameState.npc(id))
			var relation_state: Dictionary=st()["relationships"].get(uid,{"agreement":"exclusive","preference":"exclusive" if abs(uid.hash())%3!=0 else "open","discussed":-1})
			info.append("Current agreement · "+str(relation_state.get("agreement", "exclusive")).capitalize()+" · their preference: "+str(relation_state.get("preference", "exclusive")).capitalize())
			if int(relation_state.get("discussed", -1))>=0:
				info.append("Last discussion · "+str(relation_state.get("last_result", "No change recorded.")))
			info.append("A shared agreement changes which relationship situations can occur. Trust and consent matter.")
			var reason: String = h.blocked(18)
			if not allowed("adult"): reason="Adult relationship stories are disabled"
			elif GameState.npc(id)["relation"] not in ["partner", "lover"] or int(GameState.npc(id)["age"])<18: reason="Both partners must be adults"
			elif h.used("boundaries"): reason="Used this year"
			elif int(GameState.player["time_left"])<1: reason="Needs 1 time"
			var ready: bool = reason==""
			rows=[h.row("identity","Discuss boundaries & plans",reason if not ready else "1 time · mutual consent · trust matters","discuss",id,ready)]
		else:
			info.append("This person is no longer available for a discussion.")
	else:
		for theme in THEMES: rows.append(h.row("identity",str(THEMES[theme])+": "+("ON" if allowed(theme) else "OFF"),"New optional scenes only; existing consequences remain","theme",theme))
		rows.append(h.row("identity","Expression: "+str(st()["pose"]),"Live expression or a neutral face","pose"))
		rows.append(h.row("identity","Quiet audio: "+("ON" if GameState.settings.get("quiet_audio",false) else "OFF"),"Cap music, effects and interface sound at 35%; muted stays muted","quiet"))
		rows.append({"icon":"📖","name":"My connected-life journal","sub":"Promises, projects, recovery and personal history","menu":"journey:journal"})
		var type := str(Lives.life().get("type","human"))
		if MODES.has(type):
			var p: Dictionary=st()["mode"]
			rows.append(h.row("identity",MODES[type][0],"Three annual chapters · needs this mode's active powers or duties","mode",null,mode_available(type) and (p.is_empty() or int(p["stage"])<3)))
		for p in st()["mode_history"]: info.append("%s · quality %d" % [MODES[p["type"]][0],p["quality"]])
		info.append("Six original branching campaigns are available in the main-menu story picker. Their choices and alternate endings are saved separately from the fixed reference stories.")
	return {"icon":"🎭","title":"Identity & stories","info":info,"rows":rows}
func act(key: String, arg: Variant) -> void:
	match key:
		"mode": mode_step()
		"discuss": discuss(str(arg))
		"quiet":
			GameState.settings["quiet_audio"]=not GameState.settings.get("quiet_audio",false)
			Fx.apply_volumes(); SaveManager.save_settings()
		"pose": if h.blocked(0,true,true)=="": st()["pose"]="neutral" if st()["pose"]=="auto" else "auto"
		"theme":
			if not THEMES.has(str(arg)) or h.blocked(0,true,true)!="": return
			if not GameState.settings.has("content_themes"): GameState.settings["content_themes"]={}
			GameState.settings["content_themes"][str(arg)]=not allowed(str(arg)); SaveManager.save_settings()
