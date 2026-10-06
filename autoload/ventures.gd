extends Node

## Owned venues have separate operating accounts. Personal gambling never moves
## a venue's money. State stays on the owner when changing family viewpoint.
const TYPES := {
	"casino": {"name":"Casino", "icon":"🎲", "cost":1500000, "base":360000, "overhead":150000},
	"museum": {"name":"Museum", "icon":"🏛️", "cost":180000, "base":50000, "overhead":30000},
	"agency": {"name":"Intelligence agency", "icon":"🕵️", "cost":250000, "base":60000, "overhead":45000},
}
const ROOMS := {"cards":["Card lounge",120000,0.20], "slots":["Slot floor",90000,0.15], "stage":["Live music stage",150000,0.25]}
const EXHIBITS := {"local":["Local lives",12000], "science":["Science after dark",22000], "art":["Emerging artists",30000]}
const OPERATIONS := {"rescue":["Recover a missing witness",50000,45], "audit":["Investigate corporate fraud",35000,30], "protect":["Protect a threatened source",45000,40]}

func book(p: Dictionary = {}) -> Dictionary:
	if p.is_empty(): p = GameState.player
	if not p.get("ventures",{}) is Dictionary: p["ventures"] = {}
	if not p.has("ventures"): p["ventures"] = {}
	return p["ventures"]

func allowed(age: int = 18) -> bool:
	return GameState.is_alive() and int(GameState.player.get("age",0))>=age and not Lives.separate() and not GameState.in_prison()

func _row(name: String, sub: String, action: String, arg = null, on: bool = true) -> Dictionary:
	return {"icon":"•", "name":name,"sub":sub,"act":"venue:"+action,"arg":arg,"on":on}

func _pay(cost: int, time: int = 1) -> bool:
	if not allowed(): return false
	if int(GameState.player["money"]) < cost:
		EventEngine.push_info("💵","Not enough cash","This needs %s available." % GameState.fmt_money(cost))
		return false
	if not GameState.spend_time(time):
		EventEngine.push_info("⏳","No time left","Make room for this next year.")
		return false
	GameState.player["money"] = int(GameState.player["money"])-cost
	return true

func acquire(kind: String, already_paid: bool = false) -> bool:
	if not TYPES.has(kind) or not allowed(21) or book().has(kind): return false
	if not GameState.player.get("record",[]).is_empty() and kind in ["casino","agency"]: return false
	if not already_paid and not _pay(int(TYPES[kind]["cost"]),3): return false
	if kind=="casino": GameState.player["casino_legacy_checked"]=true
	book()[kind] = {"name":TYPES[kind]["name"],"opened":GameState.year_now(),"quality":45.0,"reputation":40.0,"staff":1,"rooms":[],"exhibits":[],"agents":[],"next_agent":1,"reserve":0,"report":{},"history":[],"year":GameState.year_now(),"fee":10,"contract_year":-1}
	GameState.add_log("I opened my %s. Its accounts and operating decisions are now my responsibility." % str(TYPES[kind]["name"]).to_lower())
	return true

func migrate() -> void:
	# Old accepted purchases must receive their venue without paying twice.
	if GameState.flags.has("owns_casino") and not GameState.player.get("casino_legacy_checked",false):
		GameState.player["casino_legacy_checked"]=true
		if not book().has("casino"):
			book()["casino"] = {"name":"Casino","opened":GameState.year_now(),"quality":45.0,"reputation":40.0,"staff":1,"rooms":[],"exhibits":[],"agents":[],"next_agent":1,"reserve":0,"report":{},"history":[],"year":GameState.year_now(),"fee":10,"contract_year":-1}
	if GameState.flags.has("luxury_life") and not GameState.player.has("luxury_club"):
		start_luxury()

func value(p: Dictionary = {}) -> int:
	if p.is_empty(): p = GameState.player
	var total := 0
	for kind in book(p):
		var v: Dictionary = book(p)[kind]
		total += int(float(TYPES[kind]["cost"])*0.55)+maxi(0,int(v.get("reserve",0)))
		for room in v.get("rooms",[]): total += int(ROOMS[room][1]*0.4)
		for exhibit in v.get("exhibits",[]): total += int(EXHIBITS[exhibit][1]*0.4)
	return total

func menu(key: String) -> Dictionary:
	migrate()
	if key.begins_with("history:"): return history_menu(key.get_slice(":",1))
	if key=="luxury": return luxury_menu()
	var rows: Array = []
	if not TYPES.has(key):
		for kind in TYPES:
			rows.append({"icon":TYPES[kind]["icon"],"name":TYPES[kind]["name"],"sub":"Manage your venue" if book().has(kind) else "Open from %s · age 21+" % GameState.fmt_money(int(TYPES[kind]["cost"])),"menu":"venue:"+kind})
		rows.append({"icon":"🛥️","name":"The Velvet Society","sub":"Membership, gatherings and giving","menu":"venue:luxury"})
		return {"icon":"🏢","title":"Venues & ventures","rows":rows,"info":["Each venue owns an operating reserve. Cash withdrawals, operating losses and sale proceeds are shown separately."]}
	var d: Dictionary = TYPES[key]
	if not book().has(key):
		return {"icon":d["icon"],"title":d["name"],"rows":[_row("Open "+str(d["name"]),"%s · 3 time · working venue with yearly costs" % GameState.fmt_money(int(d["cost"])),"open",key,allowed(21) and (key=="museum" or GameState.player.get("record",[]).is_empty()))],"info":["The cash price includes the premises and initial setup. Your first operating report arrives next year. A clean record is needed for casinos and agencies."]}
	var v: Dictionary = book()[key]
	var info: Array = ["Reputation %d · condition %d · staff %d" % [int(v["reputation"]),int(v["quality"]),int(v["staff"])],"Operating reserve: %s" % GameState.fmt_money(int(v["reserve"])),"Sale estimate: %s" % GameState.fmt_money(_sale_value(key))]
	var report: Dictionary = v["report"]
	if not report.is_empty(): info.append("Last year: revenue %s · costs %s · result %s" % [GameState.fmt_money(int(report["revenue"])),GameState.fmt_money(int(report["cost"])),GameState.fmt_money(int(report["profit"]))])
	rows.append(_row("Maintain the premises","%s · condition +15" % GameState.fmt_money(10000),"maintain",key,allowed() and float(v["quality"])<100))
	rows.append(_row("Hire a team member","%s recruitment · %s annual salary" % [GameState.fmt_money(2000),GameState.fmt_money(18000)],"hire",key,allowed() and int(v["staff"])<8))
	rows.append(_row("Reduce staffing","Keep at least one team member","reduce",key,allowed() and int(v["staff"])>1))
	rows.append(_row("Promote the venue","%s · reputation +8" % GameState.fmt_money(8000),"promote",key,allowed() and float(v["reputation"])<100))
	rows.append(_row("Withdraw available reserve","Moves earnings to your personal cash","withdraw",key,allowed() and int(v["reserve"])>0))
	if key=="casino":
		for room in ROOMS: rows.append(_row("Install "+str(ROOMS[room][0]),GameState.fmt_money(int(ROOMS[room][1])),"room",room,allowed() and not v["rooms"].has(room)))
		rows.append(_row("Responsible play program","%s · reputation +10 · lower revenue this year" % GameState.fmt_money(5000),"responsible",key,allowed() and not v.get("responsible",false)))
	elif key=="museum":
		for exhibit in EXHIBITS: rows.append(_row("Curate "+str(EXHIBITS[exhibit][0]),GameState.fmt_money(int(EXHIBITS[exhibit][1])),"exhibit",exhibit,allowed() and not v["exhibits"].has(exhibit)))
		for fee in [0,10,20]: rows.append(_row("Admission: "+GameState.fmt_money(fee),"Free entry builds reputation; high fees reduce attendance","fee",fee,allowed() and int(v["fee"])!=fee))
		rows.append(_row("Community collection evening","1 time · reputation and local memories","community",key,allowed() and int(v.get("community_year",-1))!=GameState.year_now()))
	elif key=="agency":
		rows.append(_row("Recruit an operative","%s · %s annual salary · maximum 4" % [GameState.fmt_money(12000),GameState.fmt_money(24000)],"recruit",key,allowed() and v["agents"].size()<4))
		for agent in v["agents"]:
			rows.append(_row("Train "+str(agent["name"]),"%s · skill %d → +8 · maximum 95" % [GameState.fmt_money(3000),int(agent["skill"])],"train",agent["id"],allowed() and int(agent["skill"])<95 and int(agent.get("training_year",-1))!=GameState.year_now()))
		for op in OPERATIONS: rows.append(_row(OPERATIONS[op][0],"1 contract per year · pay %s · one available operative needed" % GameState.fmt_money(int(OPERATIONS[op][1])),"operation",op,allowed() and not v["agents"].is_empty() and int(v["contract_year"])!=GameState.year_now()))
	rows.append({"icon":"📚","name":"Operating history","sub":"The last twelve reports and assignments","menu":"venue:history:"+key})
	rows.append(_row("Sell the venue","Confirm sale on the next screen","sale_preview",key,allowed()))
	return {"icon":d["icon"],"title":d["name"],"rows":rows,"info":info}

func history_menu(kind: String) -> Dictionary:
	var rows: Array = []
	for text in book().get(kind,{}).get("history",[]): rows.append({"name":text,"icon":"📖","on":false})
	return {"icon":"📚","title":"Operating history","rows":rows,"info":["No reports yet." if rows.is_empty() else "Recent decisions and results."]}

func _remember(v: Dictionary, text: String) -> void:
	v["history"].append("%d · %s" % [GameState.year_now(),text])
	v["history"] = Array(v["history"]).slice(-12)
	GameState.add_log(text)

func _sale_value(kind: String) -> int:
	var v: Dictionary = book()[kind]
	var total := int(float(TYPES[kind]["cost"])*0.55)+maxi(0,int(v["reserve"]))
	for room in v["rooms"]: total+=int(ROOMS[room][1]*0.4)
	for exhibit in v["exhibits"]: total+=int(EXHIBITS[exhibit][1]*0.4)
	return total

func act(action: String, arg = null) -> void:
	if not allowed(): return
	if action.begins_with("lux_"):
		luxury_act(action,arg)
		return
	if action=="open": acquire(str(arg)); return
	var kind := str(arg)
	if action=="room": kind="casino"
	if action in ["exhibit","fee"]: kind="museum"
	if action in ["recruit","train","operation"]: kind="agency"
	if not book().has(kind): return
	var v: Dictionary = book()[kind]
	match action:
		"maintain":
			if float(v["quality"])>=100 or not _pay(10000): return
			v["quality"]=minf(100,float(v["quality"])+15)
		"hire":
			if int(v["staff"])>=8 or not _pay(2000): return
			v["staff"]=int(v["staff"])+1
		"reduce":
			if int(v["staff"])<=1 or not _pay(0): return
			v["staff"]=int(v["staff"])-1
		"promote":
			if float(v["reputation"])>=100 or not _pay(8000): return
			v["reputation"]=minf(100,float(v["reputation"])+8)
		"withdraw":
			if int(v["reserve"])<=0: return
			GameState.player["money"]=int(GameState.player["money"])+int(v["reserve"])
			v["reserve"]=0
		"room":
			if not ROOMS.has(str(arg)) or v["rooms"].has(arg) or not _pay(int(ROOMS[arg][1]),2): return
			v["rooms"].append(arg)
		"exhibit":
			if not EXHIBITS.has(str(arg)) or v["exhibits"].has(arg) or not _pay(int(EXHIBITS[arg][1]),2): return
			v["exhibits"].append(arg)
		"fee":
			if not arg in [0,10,20]: return
			v["fee"]=arg
		"responsible":
			if v.get("responsible",false) or not _pay(5000): return
			v["responsible"]=true
			v["reputation"]=minf(100,float(v["reputation"])+10)
		"community":
			if int(v.get("community_year",-1))==GameState.year_now() or not _pay(0): return
			v["community_year"]=GameState.year_now()
			v["reputation"]=minf(100,float(v["reputation"])+8)
			GameState.change_stat("happiness",4)
		"recruit":
			if v["agents"].size()>=4 or not _pay(12000,2): return
			var id := int(v["next_agent"])
			v["next_agent"]=id+1
			v["agents"].append({"id":id,"name":["Quinn","Marlow","Indigo","Ash"][id%4],"skill":randi_range(35,60),"missions":0,"training_year":-1})
		"train":
			for agent in v["agents"]:
				if int(agent["id"])!=int(arg): continue
				if int(agent["skill"])>=95 or int(agent["training_year"])==GameState.year_now() or not _pay(3000): return
				agent["skill"]=mini(95,int(agent["skill"])+8)
				agent["training_year"]=GameState.year_now()
		"operation":
			if not OPERATIONS.has(str(arg)) or v["agents"].is_empty() or int(v["contract_year"])==GameState.year_now() or not _pay(5000,2): return
			v["contract_year"]=GameState.year_now()
			var agent: Dictionary = v["agents"][0]
			for candidate in v["agents"]:
				if int(candidate["skill"])>int(agent["skill"]): agent=candidate
			var chance := clampf(0.45+(float(agent["skill"])-float(OPERATIONS[arg][2]))/100,0.15,0.90)
			var won := randf()<chance
			agent["missions"]=int(agent["missions"])+1
			v["reserve"]=int(v["reserve"])+(int(OPERATIONS[arg][1]) if won else 0)
			v["reputation"]=clampf(float(v["reputation"])+(5 if won else -8),0,100)
			_remember(v,"%s %s the assignment: %s." % [agent["name"],"completed" if won else "could not complete",OPERATIONS[arg][0]])
			return
		"sale_preview":
			EventEngine.push_decision({"id":"_venue_sale","icon":"🏢","title":"Sell your "+kind+"?","text":"Receive %s. Your staff, rooms and venue progress leave with the sale." % GameState.fmt_money(_sale_value(kind)),"choices":[{"label":"Keep it","outcomes":[{"text":"I kept the venue."}]},{"label":"Sell","outcomes":[{"text":"I signed the sale papers.","venue_sale":kind}]}]})
			return
		_: return
	_remember(v,"I updated my %s: %s." % [kind,action.replace("_"," ")])
	GameState.emit_changed()

func sell(kind: String) -> void:
	if not book().has(kind) or not allowed(): return
	GameState.player["money"]=int(GameState.player["money"])+_sale_value(kind)
	book().erase(kind)
	if kind=="casino": GameState.clear_flag("owns_casino")
	GameState.emit_changed()

func operate(p: Dictionary, year: int, log_active: bool = true) -> void:
	for kind in book(p).keys():
		var v: Dictionary = book(p)[kind]
		if int(v["year"])>=year: continue
		v["year"]=year
		var appeal := (0.35+float(v["quality"])/130+float(v["reputation"])/150)*randf_range(0.75,1.15)
		var scale := 1.0
		var extra_cost := 0
		if kind=="casino":
			for room in v["rooms"]: scale+=float(ROOMS[room][2]); extra_cost+=18000
			scale*=minf(1.0,float(v["staff"])/float(1+v["rooms"].size()))
			if v.get("responsible",false): scale*=0.90
		elif kind=="museum":
			scale=0.25+v["exhibits"].size()*0.35
			scale*=minf(1.0,float(v["staff"])/float(maxi(1,v["exhibits"].size())))
			if int(v["fee"])==0: scale*=0.60; v["reputation"]=minf(100,float(v["reputation"])+4)
			elif int(v["fee"])==20: scale*=1.15; v["reputation"]=maxf(0,float(v["reputation"])-2)
		else:
			scale=0.3+v["agents"].size()*0.25
			extra_cost=v["agents"].size()*24000
		var revenue := int(float(TYPES[kind]["base"])*appeal*scale)
		var costs := int(TYPES[kind]["overhead"])+int(v["staff"])*18000+extra_cost
		var profit := revenue-costs
		var reserve := int(v["reserve"])+profit
		var subsidy := maxi(0,-reserve)
		p["money"]=int(p["money"])-subsidy
		v["reserve"]=maxi(0,reserve)
		v["report"]={"year":year,"revenue":revenue,"cost":costs,"profit":profit,"personal_subsidy":subsidy}
		v["quality"]=maxf(0,float(v["quality"])-randf_range(4,9))
		v["reputation"]=clampf(float(v["reputation"])+(2 if float(v["quality"])>50 else -3),0,100)
		v["responsible"]=false
		var line := "%s operating result: %s%s." % [TYPES[kind]["name"],GameState.fmt_money(profit),"; I covered "+GameState.fmt_money(subsidy) if subsidy>0 else "; earnings held in its reserve"]
		v["history"].append("%d · %s" % [year,line])
		v["history"]=Array(v["history"]).slice(-12)
		if log_active: GameState.add_log(line)
		if int(p["money"]) < -100000 and subsidy>0:
			p["money"]=int(p["money"])+int(TYPES[kind]["cost"]*0.25)
			book(p).erase(kind)
			if log_active:
				GameState.add_log("I could not keep funding my %s. It closed and the premises were liquidated." % kind)
				if kind=="casino": GameState.clear_flag("owns_casino")

func yearly() -> void:
	if Lives.separate(): return
	migrate()
	operate(GameState.player,GameState.year_now())
	if GameState.player.has("luxury_club"):
		var club: Dictionary = GameState.player["luxury_club"]
		if int(club["year"])<GameState.year_now():
			club["year"]=GameState.year_now()
			if int(GameState.player["money"])>=25000:
				GameState.player["money"]=int(GameState.player["money"])-25000
				GameState.add_log("Velvet Society annual dues: %s." % GameState.fmt_money(25000))
			else:
				GameState.player.erase("luxury_club")
				GameState.clear_flag("luxury_life")
				GameState.add_log("I let my Velvet Society membership lapse. The velvet did not send condolences.")

func start_luxury() -> void:
	if GameState.player.has("luxury_club"): return
	GameState.player["luxury_club"]={"standing":10,"attended":0,"donated":0,"year":GameState.year_now(),"gathering_year":-1}

func luxury_menu() -> Dictionary:
	var rows: Array = []
	var club: Dictionary = GameState.player.get("luxury_club",{})
	if club.is_empty():
		rows.append(_row("Apply for the Luxury Life","%s application · age 21+ · needs %s saved · annual dues apply" % [GameState.fmt_money(2500000),GameState.fmt_money(5000000)],"lux_apply",null,allowed(21) and bool(Become.check("luxury")[0])))
	else:
		rows.append(_row("Attend a society gathering","%s · 2 time · once per year · meet a new contact" % GameState.fmt_money(5000),"lux_gather",null,allowed() and int(club["gathering_year"])!=GameState.year_now()))
		rows.append(_row("Sponsor a community arts grant","%s · standing and community impact" % GameState.fmt_money(50000),"lux_grant",null,allowed() and int(club.get("grant_year",-1))!=GameState.year_now()))
		rows.append(_row("Leave the society","Stop annual dues; standing is lost","lux_leave",null,allowed()))
	return {"icon":"🛥️","title":"The Velvet Society","rows":rows,"info":["Annual dues: %s. Membership is a social commitment, not guaranteed investment income." % GameState.fmt_money(25000),"Standing %d · gatherings %d · grants %s" % [int(club.get("standing",0)),int(club.get("attended",0)),GameState.fmt_money(int(club.get("donated",0)))]]}

func luxury_act(action: String, _arg) -> void:
	if action=="lux_apply": Become.apply("luxury"); return
	var club: Dictionary = GameState.player.get("luxury_club",{})
	if club.is_empty(): return
	match action:
		"lux_gather":
			if int(club["gathering_year"])==GameState.year_now() or not _pay(5000,2): return
			club["gathering_year"]=GameState.year_now()
			club["attended"]=int(club["attended"])+1
			club["standing"]=mini(100,int(club["standing"])+10)
			var id := GameState.create_npc("friend",{"age":randi_range(25,70),"closeness":45})
			FamilyChronicle.remember(id,"We met at a Velvet Society gathering.")
			GameState.add_log("I met %s at a gathering. We bonded over how neither of us knows which fork is decorative." % GameState.full_name(id))
		"lux_grant":
			if int(club.get("grant_year",-1))==GameState.year_now() or not _pay(50000,2): return
			club["grant_year"]=GameState.year_now()
			club["donated"]=int(club["donated"])+50000
			club["standing"]=mini(100,int(club["standing"])+15)
			GameState.apply_effects({"karma":5,"happiness":6})
			GameState.add_log("My arts grant funded a community exhibition. For once the plaque was smaller than the useful part.")
		"lux_leave":
			GameState.player.erase("luxury_club")
			GameState.clear_flag("luxury_life")
			GameState.add_log("I left the Velvet Society. My wallet applauded politely.")
	GameState.emit_changed()
