extends Node

## Personal systems share one guarded decision channel; the world retains identities.
const DOMAINS := {
	"campus": ["🏫", "School community", 3],
	"parenting": ["👪", "Parenting & childcare", 18],
	"pathways": ["🤝", "Connections & follow-through", 6],
	"coping": ["🌿", "Life & wellbeing", 6],
	"resilience": ["🌱", "Recovery & support", 14],
	"wellbeing": ["🌿", "Health & support", 0],
	"operations": ["🏪", "Company operations", 18],
	"fresh": ["🌱", "Fresh Start", 18],
	"leisure": ["🌿", "Hobbies & quiet goals", 6],
	"funds": ["🏦", "Shared household reserve", 18],
	"seasons": ["🏅", "Teams & seasons", 6],
	"learning": ["📚", "Learning & placements", 16],
	"people": ["🤝", "People & commitments", 6],
	"school": ["🏫", "School plans", 5],
	"skills": ["🎯", "Practical practice", 6],
	"enterprise": ["🌱", "Ambitions & enterprise", 18],
	"recovery": ["🌿", "Trouble & recovery", 16],
	"places": ["🏘️", "Places & community", 6],
	"heritage": ["🌳", "Generations & later life", 18],
	"identity": ["🎭", "Identity & stories", 0],
	"collection": ["🏛️", "Museum & collecting", 21]
}
var modules: Dictionary={}

# School responsibilities stay connected but distinct: campus owns the current
# classroom and grades, school owns long-running projects, and skills owns saved
# hands-on minigame checkpoints. The latter two are systems, not menu destinations.
func _ready() -> void:
	modules = {
		"campus": preload("res://systems/campus.gd").new(self),
		"parenting": preload("res://systems/parenting.gd").new(self),
		"pathways": preload("res://systems/pathways.gd").new(self),
		"coping": preload("res://systems/coping.gd").new(self),
		"resilience": preload("res://systems/resilience.gd").new(self),
		"wellbeing": preload("res://systems/wellbeing.gd").new(self),
		"operations": preload("res://systems/operations.gd").new(self),
		"fresh": preload("res://systems/fresh_start.gd").new(self),
		"leisure": preload("res://systems/leisure.gd").new(self),
		"funds": preload("res://systems/funds.gd").new(self),
		"seasons": preload("res://systems/seasons.gd").new(self),
		"learning": preload("res://systems/learning.gd").new(self),
		"people": preload("res://systems/commitments.gd").new(self),
		"school": preload("res://systems/growing_up.gd").new(self),
		"skills": preload("res://systems/competition.gd").new(self),
		"enterprise": preload("res://systems/enterprise.gd").new(self),
		"recovery": preload("res://systems/recovery.gd").new(self),
		"places": preload("res://systems/community.gd").new(self),
		"heritage": preload("res://systems/heritage.gd").new(self),
		"identity": preload("res://systems/identity.gd").new(self),
		"collection": preload("res://systems/collection.gd").new(self)
	}
func state(p: Dictionary = {}) -> Dictionary:
	if p.is_empty(): p=GameState.player
	if not p.has("journey") or not p["journey"] is Dictionary: p["journey"]={}
	var s: Dictionary=p["journey"]
	for pair in [["serial",0],["prompt",{}],["used",{}],["journal",[]],["last_year",-1]]:
		if not s.has(pair[0]): s[pair[0]]=pair[1].duplicate(true) if pair[1] is Dictionary or pair[1] is Array else pair[1]
	return s
func section(key: String, defaults: Dictionary, p: Dictionary = {}) -> Dictionary:
	var s := state(p)
	if not s.has(key) or not s[key] is Dictionary: s[key]=defaults.duplicate(true)
	for field in defaults:
		if not s[key].has(field): s[key][field]=defaults[field].duplicate(true) if defaults[field] is Dictionary or defaults[field] is Array else defaults[field]
	return s[key]
func uid() -> String: return FamilyChronicle.identity(GameState.player)
func person(uid0: String) -> String:
	if uid0=="": return ""
	for id in GameState.npcs:
		if str(GameState.npcs[id].get("person_uid",""))==uid0: return str(id)
	return ""
func person_status(uid0: String) -> Dictionary:
	if uid0=="": return {"state":"missing","id":""}
	if str(GameState.player.get("person_uid",""))==uid0:
		return {"state":"alive" if GameState.player.get("alive",false) else "deceased","id":"player"}
	for id0 in GameState.npcs:
		var person0: Dictionary=GameState.npcs[id0]
		if str(person0.get("person_uid",""))==uid0:
			return {"state":"alive" if person0.get("alive",false) else "deceased","id":str(id0)}
	return {"state":"missing","id":""}
func person_name(uid0: String, fallback: String = "Someone") -> String:
	var status := person_status(uid0)
	if status.get("state", "missing")!="alive": return fallback
	if str(status.get("id", ""))=="player": return str(GameState.player.get("first", fallback))
	var id := str(status.get("id", ""))
	var person0: Dictionary=GameState.npc(id)
	return str(person0.get("first", fallback)) if not person0.is_empty() else fallback
func used(key: String) -> bool: return state()["used"].has("%d:%s" % [GameState.year_now(),key])
func busy() -> bool:
	return not state()["prompt"].is_empty() or (modules.has("skills") and not modules["skills"].st()["active"].is_empty()) or (modules.has("recovery") and (not modules["recovery"].st()["case"].is_empty() or not modules["recovery"].st()["appeal"].is_empty()))
func mark(key: String) -> void: state()["used"]["%d:%s" % [GameState.year_now(),key]]=true
func blocked(age: int = 0, separate: bool = false, custody: bool = false) -> String:
	if not GameState.is_alive(): return "Needs an active life"
	if int(GameState.player["age"])<age: return "Age %d+" % age
	if not separate and Lives.separate(): return "Human-life activity"
	if not custody and GameState.in_prison(): return "Unavailable in custody"
	if EventEngine.has_pending() or EventEngine.displayed.has("def") or busy() or not Depth.state()["active"].is_empty() or not Employment.st()["prompt"].is_empty(): return "Finish the current decision"
	return ""
func pay(key: String, time: int = 1, price: int = 0, age: int = 0, separate: bool = false, custody: bool = false) -> bool:
	if blocked(age,separate,custody)!="" or used(key) or (price>0 and int(GameState.player["money"])<price) or int(GameState.player["time_left"])<time: return false
	GameState.spend_time(time); GameState.player["money"]=int(GameState.player["money"])-price; mark(key)
	return true
func note(title: String, text: String) -> void:
	state()["journal"].push_front({"year":GameState.year_now(),"title":title,"text":text})
	if state()["journal"].size()>80: state()["journal"].resize(80)
	GameState.add_log(title+": "+text)
func done(icon: String, title: String, text: String, effects: Dictionary = {}) -> void:
	GameState.apply_effects(effects); note(title,text); EventEngine.push_info(icon,title,text)
func decision(domain: String, op: String, args: Dictionary, title: String, text: String, options: Array, icon: String = "") -> void:
	state()["serial"]=int(state()["serial"])+1
	var token := int(state()["serial"])
	var choices: Array=[]
	for i in range(options.size()):
		var option: Dictionary=options[i] if options[i] is Dictionary else {"label":str(options[i])}
		var choice := {"label":str(option["label"]),"outcomes":[{"text":"","no_friction":true,"journey":{"token":token,"owner":uid(),"domain":domain,"op":op,"args":args.duplicate(true),"answer":i}}]}
		if option.has("requires"): choice["requires"]=option["requires"].duplicate(true)
		choices.append(choice)
	var def := {"id":"_journey","icon":DOMAINS[domain][0] if icon=="" else icon,"title":title,"text":text,"choices":choices,"no_friction":true}
	state()["prompt"]={"token":token,"owner":uid(),"domain":domain,"op":op,"args":args.duplicate(true),"def":def}
	EventEngine.push_decision(def)
func outcome(spec: Dictionary) -> void:
	var prompt: Dictionary=state()["prompt"]
	if prompt.is_empty() or int(spec.get("token",-1))!=int(prompt["token"]) or str(spec.get("owner",""))!=uid() or str(spec.get("domain",""))!=str(prompt["domain"]): return
	var answer := int(spec.get("answer",-1))
	if answer<0 or answer>=prompt["def"]["choices"].size(): return
	state()["prompt"]={}
	modules[str(prompt["domain"])].resolve(str(prompt["op"]),prompt["args"],answer)
func restore() -> void:
	var prompt: Dictionary=state()["prompt"]
	if prompt.is_empty(): return
	if str(prompt.get("owner",""))!=uid(): state()["prompt"]={}; return
	if not EventEngine.pending.any(func(it): return str(it.get("def",{}).get("id",""))=="_journey"): EventEngine.push_decision(prompt["def"])
func yearly() -> void:
	if Lives.is_type("tv"): return
	var s := state(); var year := GameState.year_now()
	if int(s["last_year"])==year: return
	s["last_year"]=year
	for key in s["used"].keys():
		if int(str(key).get_slice(":",0))<year-2: s["used"].erase(key)
	for mod in modules.values(): mod.yearly()
	Depth.settle_work_reviews()
	background_commitments(year)
	background_companies(year)
	for n in GameState.npcs.values():
		if n.get("alive",false): modules["funds"].background(n,year)
func background_companies(year: int) -> void:
	for n in GameState.npcs.values():
		if not n.get("alive",false) or int(n.get("company_year",-1))==year: continue
		modules["operations"].background(n,year)
		var former: Dictionary=n.get("playable_player",{})
		var e: Dictionary=n.get("ambition",former.get("ambition",{})).get("enterprise",{})
		if e.get("portfolio",[]).is_empty(): continue
		var cash := 0
		for co in e["portfolio"]:
			if float(co.get("stake",0))<=0: continue
			var industry: Dictionary=Empires.INDUSTRIES.get(co.get("ind",""),{})
			var demand := 0.55+float(co.get("quality",50))/130.0+randf_range(-0.2,0.2)
			var profit := int(float(industry.get("rev",120000))*demand*(1+int(co.get("staff",0))*0.12)*float(industry.get("margin",0.15)))-int(co.get("staff",0))*13000-int(float(co.get("debt",0))*0.07)
			co["profit"]=profit; co["years"]=int(co.get("years",0))+1
			co["quality"]=clampf(float(co.get("quality",50))+randf_range(-4,3),8,100)
			co["value"]=maxi(5000,int(lerpf(float(co.get("value",5000)),maxf(float(co.get("value",5000))*0.6,profit*8.0),0.35)))
			cash+=maxi(0,int(profit*float(co.get("stake",0))*0.35))
			if profit<0: co["debt"]=int(co.get("debt",0))+abs(profit)
			if int(co.get("debt",0))>int(co["value"])*2: co["stake"]=0.0; co["value"]=0; e["bankruptcies"]=int(e.get("bankruptcies",0))+1
		e["portfolio"]=e["portfolio"].filter(func(co): return float(co.get("stake",0))>0)
		e["dividends"]=int(e.get("dividends",0))+cash
		n["money"]=int(n.get("money",0))+cash; n["company_year"]=year
		if not former.is_empty(): former["money"]=n["money"]; former["ambition"]["enterprise"]=e.duplicate(true)
func background_commitments(year: int) -> void:
	for n in GameState.npcs.values():
		if not n.get("alive",false): continue
		var saved: Dictionary=n.get("playable_player",{})
		Novelty.background(n,year)
		modules["pathways"].background(n,year)
		modules["people"].background(n,year)
		modules["parenting"].background(n,year)
		var plans: Dictionary=saved.get("journey",{}).get("stewardship",{})
		if not plans.is_empty(): Stewardship.review_contracts(plans,saved.get("employment",{}).get("clients",[]),year)
		var museum: Dictionary=saved.get("journey",n.get("journey",{})).get("collection",{})
		if not museum.is_empty():
			modules["collection"].review(museum,n,year)
			if not saved.is_empty(): saved["money"]=n["money"]
		if not saved.is_empty():
			Holdings.yearly_vehicle(saved)
			if saved.has("transit"): saved["transit"]["serviced"]=false
		var people: Dictionary=saved.get("journey",{}).get("people",{})
		var enterprise: Dictionary=saved.get("journey",{}).get("enterprise",{})
		for invoice in enterprise.get("cashflow",[]).duplicate(true):
			if year>=int(invoice["due"]):
				n["money"]=int(n.get("money",0))+int(invoice["amount"])
				saved["money"]=n["money"]; enterprise["cashflow"].erase(invoice)
		var project: Dictionary=enterprise.get("active",{})
		if not project.is_empty() and year>int(project["due"]):
			var business: Dictionary=saved["journey"]["enterprise"]
			var kind := str(project["kind"])
			business["clients"][kind]=maxf(0,float(business["clients"].get(kind,50))-10)
			business["history"].push_front({"kind":kind,"year":year,"quality":project["quality"],"delivered":false,"honest":project["credits"],"paid":0,"late":false})
			if business["history"].size()>40: business["history"].resize(40)
			business["active"]={}
		var chapters: Dictionary=saved.get("journey",{})
		var season: Dictionary=chapters.get("seasons",{}).get("season",{})
		if not season.is_empty() and year>int(season["year"]):
			season["result"]="Unfinished while life continued"
			chapters["seasons"]["history"].push_front(season.duplicate(true)); chapters["seasons"]["season"]={}
			if chapters["seasons"]["history"].size()>16: chapters["seasons"]["history"].resize(16)
		var learning: Dictionary=chapters.get("learning",{})
		var intern: Dictionary=learning.get("internship",{})
		if not intern.is_empty() and year>int(intern["due"]):
			intern["result"]="Placement deadline missed while life continued"
			learning["history"].push_front(intern.duplicate(true)); learning["internship"]={}
			if learning["history"].size()>20: learning["history"].resize(20)
		var work: Dictionary=saved.get("employment",{})
		var assignment: Dictionary=work.get("active",{})
		if not assignment.is_empty() and year>int(assignment["due"]):
			work["history"].push_front({"name":assignment["brief"]["name"],"field":assignment["field"],"year":year,"quality":assignment["quality"],"result":"Deadline missed while life continued","bonus":0,"dishonest":false,"audit_due":-1,"audited":false})
			if work["history"].size()>50: work["history"].resize(50)
			for client in work.get("clients",[]):
				if client["id"]==assignment["client"]: client["trust"]=maxf(0,float(client["trust"])-12)
			work["active"]={}; work["prompt"]={}
		for promise in people.get("promises",[]):
			if promise.get("state","")!="open" or year<=int(promise["due"]): continue
			var recipient_uid := str(promise.get("uid", ""))
			var recipient := person_status(recipient_uid)
			var recipient_name := person_name(recipient_uid,str(promise.get("name", "Someone important")))
			var maker_id := str(n.get("id", ""))
			if recipient["state"]!="alive":
				promise["state"]="ended"
				promise["conclusion"]="Closed when the person was no longer available; no trust penalty was applied."
				background_note(saved,year,"Promise closed",recipient_name+" was no longer available while life continued. The promise ended without blame.")
				if maker_id!="": FamilyChronicle.remember(maker_id,"A promise to "+recipient_name+" ended when they were no longer available.")
				if str(recipient.get("id", "")) not in ["", "player"]: FamilyChronicle.remember(str(recipient["id"]),"A promise from "+str(n["first"])+" ended when life changed.")
				continue
			promise["state"]="broken"
			promise["conclusion"]="Missed while this life continued."
			people["reliability"]=maxf(0,float(people.get("reliability",50))-5)
			if recipient_uid==uid() and maker_id!="":
				BondStats.apply(maker_id,{"trust":-8,"resentment":5})
				note("Missed promise",str(n["first"])+" did not follow through on a promise to you while life continued.")
			elif str(recipient.get("id", "")) not in ["", "player"]: FamilyChronicle.remember(str(recipient["id"]),str(n["first"])+" missed a promise to "+recipient_name+" while life continued.","bad")
			if maker_id!="": FamilyChronicle.remember(maker_id,"I missed a promise to "+recipient_name+" while life continued.","bad")
			background_note(saved,year,"Missed commitment",recipient_name+" · a promise was missed while life continued.")

func background_note(saved: Dictionary, year: int, title: String, text: String) -> void:
	if saved.is_empty(): return
	var journey_state: Dictionary=saved.get("journey",{})
	var journal: Array=journey_state.get("journal",[])
	journal.push_front({"year":year,"title":title,"text":text})
	if journal.size()>80: journal.resize(80)
	journey_state["journal"]=journal
	saved["journey"]=journey_state
func row(domain: String, name: String, sub: String, act: String, arg: Variant = null, on: bool = true) -> Dictionary:
	return {"name":name,"sub":sub,"icon":DOMAINS[domain][0],"act":"journey:"+domain+":"+act,"arg":arg,"on":on}
func nav(domain: String, name: String, sub: String, page: String = "") -> Dictionary:
	return {"name":name,"sub":sub,"icon":DOMAINS[domain][0],"menu":"journey:"+domain+(":"+page if page!="" else ""),"on":true}
const GROUPS := {
 "family":["👪","People & family","Relationships, parenting and generations",["people","parenting","heritage","pathways"]],
 "work":["💼","School & work","Learning, careers and enterprise",["campus","learning","enterprise","operations"]],
 "health":["🩺","Health & wellbeing","Appointments, emotions and ongoing care",["wellbeing","coping","resilience"]],
 "play":["🌿","Free time","Teams, hobbies and collections",["seasons","leisure","collection"]],
 "money":["🏘️","Money & places","Household reserves, moving and community",["funds","places"]],
 "trouble":["⚖️","Courts & fresh starts","Trials, re-entry and rebuilding",["recovery","fresh"]],
 "identity":["🎭","Identity & stories","Appearance and other lives",["identity"]]
}
const CLEAR_LABELS := {"wellbeing":"Appointments & family care","coping":"Mood, grief & stress","resilience":"Dependence & aftercare","recovery":"Trials & re-entry"}
func menu(key: String) -> Dictionary:
	if key in ["","root"]:
		var rows: Array=[]
		for group in GROUPS:
			var g: Array=GROUPS[group]
			rows.append({"icon":g[0],"name":g[1],"sub":g[2],"menu":"journey:group:"+group,"on":not Lives.separate() or group=="identity"})
		return {"icon":"🧵","title":"Life activities","info":["Choose an area of life."],"rows":rows}
	if key.begins_with("group:"):
		var group := key.substr(6)
		if GROUPS.has(group):
			var g: Array=GROUPS[group]; var rows: Array=[]
			for domain in g[3]:
				var r := nav(domain,CLEAR_LABELS.get(domain,DOMAINS[domain][1]),DOMAINS[domain][1] if CLEAR_LABELS.has(domain) else "Activities and history")
				r["on"]=int(GameState.player["age"])>=int(DOMAINS[domain][2]) and (not Lives.separate() or domain=="identity")
				rows.append(r)
			return {"icon":g[0],"title":g[1],"info":[g[2]],"rows":rows}
	var domain := key.get_slice(":",0)
	if modules.has(domain): return modules[domain].menu(key.substr(domain.length()+1) if key.length()>domain.length() else "")
	var entries: Array=Novelty.story_journal()+state()["journal"].map(func(it): return "%d · %s · %s" % [int(it["year"]),it["title"],it["text"]])
	return {"title":"My journal","icon":"📖","rows":[],"info":entries if not entries.is_empty() else ["No connected stories yet. Decisions, projects and their conclusions will appear here."]}
func act(key: String, arg: Variant = null) -> void:
	var domain := key.get_slice(":",0)
	if modules.has(domain): modules[domain].act(key.get_slice(":",1),arg)
