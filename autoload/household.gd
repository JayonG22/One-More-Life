extends Node

const PLANS := {
	"balanced":{"name":"Balanced week","routines":{"walk":true,"family":true},"text":"Daily walks and time for family; leave room for other choices."},
	"student":{"name":"Study with breathing room","routines":{"study":true,"meditate":true},"text":"Study and meditation; protect time outside the classroom."},
	"recovery":{"name":"Rest and reconnect","routines":{"walk":true,"meditate":true},"text":"Gentle movement and lower stress."},
	"retirement":{"name":"An unhurried chapter","routines":{"family":true,"walk":true},"text":"Relationships and everyday enjoyment."},
}

func state() -> Dictionary:
	var p := GameState.player
	if not p.has("household") or not p["household"] is Dictionary: p["household"]={"chores":"self","completed_year":-1,"year":GameState.year_now(),"fatigue":0,"plan":"custom"}
	return p["household"]

func menu(key: String) -> Dictionary:
	var all := _all_items()
	var rows: Array=[]; var info: Array=[]
	var title := "My household"
	if key in ["","root"]:
		info=[all["info"][0],"Manage the home without charging the same bill twice."]
		rows=[
			{"icon":"🧾","name":"Bills & budget","sub":"Income and recorded living costs","menu":"home:budget"},
			{"icon":"🧹","name":"Chores & rest","sub":"Time, services and activity bundles","menu":"home:chores"},
			{"icon":"🗓️","name":"Weekly routine","sub":"Study, recovery, family and retirement","menu":"home:routines"},
			{"icon":"👪","name":"Household people","sub":"Residents, dependents and profiles","menu":"home:people"},
			Journey.nav("funds","Shared reserve","Owned money, agreements and shortfalls"),
			Journey.nav("parenting","Parenting & childcare","Children, plans and later follow-ups"),
			Journey.nav("wellbeing","Health & family care","Care schedules, support and recovery")]
	elif key=="budget":
		title="Bills & budget"
		info=["Recorded at the last age-up. This screen adds no new charge."]
		var ledger: Dictionary=GameState.player.get("household_ledger",{})
		if not ledger.is_empty():
			info.append("%d · income %s · bills %s" % [int(ledger["year"]),GameState.fmt_money(int(ledger["income"])),GameState.fmt_money(int(ledger["expenses"]))])
			info.append("Transfers move money between accounts; they are not extra bills.")
			info.append("Now · cash %s · savings %s · net worth %s" % [GameState.fmt_money(int(GameState.player["money"])),GameState.fmt_money(int(GameState.player.get("savings",0))),GameState.fmt_money(GameState.net_worth())])
			for source in ledger.get("income_sources",{}): rows.append({"icon":"💰","name":str(source),"sub":"Income · "+GameState.fmt_money(int(ledger["income_sources"][source])),"on":false})
		rows.append_array(all["rows"].filter(func(r): return r.get("icon","")=="🧾"))
		for name in ledger.get("transfers",{}):
			var amount := int(ledger["transfers"][name])
			if amount==0: continue
			var transfer_text := "Cash → account" if amount>0 else "Account → cash"
			rows.append({"icon":"↔️","name":str(name),"sub":transfer_text+" · "+GameState.fmt_money(absi(amount)),"on":false})
		var debt_rows: Array=[["Mortgage",int(GameState.player.get("mortgage",0))],["Education loan",int(GameState.player.get("loan",0))],["Personal loans",Lending.total_owed()],["Other education debt",int(GameState.player.get("student_debt",0))]]
		for debt in debt_rows:
			if int(debt[1])>0: rows.append({"icon":"💳","name":str(debt[0])+" remaining","sub":"Current balance · "+GameState.fmt_money(int(debt[1])),"on":false})
		rows.append(Journey.nav("funds","Shared reserve","Contribution plan and shortfall cover"))
	elif key=="chores":
		title="Chores & rest"; info=[all["info"][0]]
		rows=all["rows"].filter(func(r): return r.get("act","") in ["home:chores","home:complete","home:rest","bulk:run"])
	elif key=="routines":
		title="Weekly routine"
		info=["Choose a routine. It replaces your current routine selections; age-up uses the normal time costs."]
		rows=all["rows"].filter(func(r): return r.get("act","")=="home:plan")
	elif key=="people":
		title="Household people"
		info=["People retain their own money, relationships and records."]
		var people: Array=Tenancy.mates().duplicate()
		var partner_id := str(GameState.player.get("partner",""))
		if GameState.player.get("living_together",false) and partner_id!="": people.append(partner_id)
		for id in GameState.heirs():
			if int(GameState.npc(id)["age"])<18: people.append(id)
		if GameState.player.get("housing","")=="parents": people.append_array(GameState.npcs_with("mother")+GameState.npcs_with("father")+GameState.npcs_with("stepparent"))
		var seen: Dictionary={}
		for id in people:
			if seen.has(id) or not GameState.npc(id).get("alive",false): continue
			seen[id]=true
			rows.append({"icon":Bonds.U_face(GameState.npc(id)),"name":GameState.full_name(id),"sub":GameState.relation_label(id)+" · "+Bonds.quick_line(id),"menu":"bond:"+str(id)})
	return {"icon":"🏠","title":title,"info":info,"rows":rows}

func _all_items() -> Dictionary:
	var p := GameState.player
	var s := state()
	var rows: Array = [Journey.nav("funds","Shared household reserve","Owned contributions, partner agreement and shortfalls")]
	var info: Array = ["Home: %s · time remaining %d · fatigue %d" % [str(p["housing"]).capitalize(),int(p["time_left"]),int(s["fatigue"])],"Your routine uses time at each age-up. These plans replace routine selections; they do not add a second set of habits.","Living-cost detail below is the amount already charged at the last age-up, not another bill."]
	var ledger: Dictionary = p.get("household_ledger",{})
	if not ledger.is_empty():
		info.append("Year %d · after-tax work/pension income %s · household bills %s" % [int(ledger["year"]),GameState.fmt_money(int(ledger["income"])),GameState.fmt_money(int(ledger["expenses"]))])
		for name in ledger["lines"]: rows.append({"icon":"🧾","name":str(name),"sub":GameState.fmt_money(int(ledger["lines"][name])),"on":false})
	var adult := int(p["age"])>=18 and not Lives.separate() and not GameState.in_prison()
	rows.append({"icon":"🧹","name":"Keep house myself","sub":"2 time each year unless chores are completed; unpaid chores add fatigue","act":"home:chores","arg":"self","on":adult and s["chores"]!="self"})
	rows.append({"icon":"🤝","name":"Use a household service","sub":"Annual charge: base 1,200 × local living-cost modifiers; frees chore time","act":"home:chores","arg":"service","on":adult and s["chores"]!="service"})
	rows.append({"icon":"🧺","name":"Do this year's chores now","sub":"2 time · avoid the automatic chore time cost at age-up","act":"home:complete","on":adult and int(s["completed_year"])!=GameState.year_now()+1})
	rows.append({"icon":"🛌","name":"Take a proper break","sub":"1 time · fatigue −15 · once per year","act":"home:rest","on":adult and int(s.get("rest_year",-1))!=GameState.year_now()})
	rows.append_array(Bulk.menu("home")["rows"])
	for plan in PLANS:
		rows.append({"icon":"🗓️","name":PLANS[plan]["name"],"sub":PLANS[plan]["text"],"act":"home:plan","arg":plan,"on":GameState.is_alive() and not Lives.separate() and not GameState.in_prison() and int(p["age"])>=12})
	rows.append({"icon":"📂","name":"Residents and dependents","sub":"People who share your home or depend on your support","on":false})
	if p.get("living_together",false) and p["partner"]!="" and GameState.npcs.has(p["partner"]): rows.append({"icon":"❤️","name":GameState.full_name(p["partner"]),"sub":"Partner · personal funds remain separate","on":false})
	for id in Tenancy.mates(): rows.append({"icon":"🏠","name":GameState.full_name(id),"sub":"Roommate · rent sharing handled by the lease","on":false})
	for id in GameState.heirs():
		if int(GameState.npcs[id]["age"])<18: rows.append({"icon":"🧒","name":GameState.full_name(id),"sub":"Child · age %d · dependent support included in bills" % int(GameState.npcs[id]["age"]),"on":false})
	return {"icon":"🏠","title":"My household & week","info":info,"rows":rows}

func act(key: String, arg = null) -> void:
	if not GameState.is_alive() or Lives.separate() or GameState.in_prison(): return
	var s := state()
	match key:
		"plan":
			if not PLANS.has(str(arg)) or int(GameState.player["age"])<12: return
			for routine in GameState.player["routines"]: GameState.player["routines"][routine]=bool(PLANS[arg]["routines"].get(routine,false))
			s["plan"]=arg
			GameState.add_log("I planned my week: "+str(PLANS[arg]["name"])+".")
		"chores":
			if not arg in ["self","service"] or int(GameState.player["age"])<18: return
			s["chores"]=arg
		"complete":
			if int(GameState.player["age"])<18 or int(s["completed_year"])==GameState.year_now()+1 or not GameState.spend_time(2): return
			s["completed_year"]=GameState.year_now()+1
			s["fatigue"]=mini(100,int(s["fatigue"])+3)
			GameState.add_log("I dealt with chores and household paperwork before the next year caught up with me.")
		"rest":
			if int(GameState.player["age"])<18 or int(s.get("rest_year",-1))==GameState.year_now() or not GameState.spend_time(): return
			s["rest_year"]=GameState.year_now()
			s["fatigue"]=maxi(0,int(s["fatigue"])-15)
			GameState.change_stat("stress",-4)
	GameState.emit_changed()

func service_cost() -> int:
	if int(GameState.player["age"])<18 or GameState.in_prison() or Lives.separate(): return 0
	return 1200 if state()["chores"]=="service" and int(state()["completed_year"])!=GameState.year_now() else 0

func yearly() -> void:
	if Lives.separate(): return
	var s := state()
	if int(s["year"])>=GameState.year_now(): return
	s["year"]=GameState.year_now()
	if int(GameState.player["age"])<18 or GameState.in_prison(): return
	if int(s["completed_year"])!=GameState.year_now() and s["chores"]=="self":
		if GameState.spend_time(2): s["fatigue"]=mini(100,int(s["fatigue"])+3)
		else:
			s["fatigue"]=mini(100,int(s["fatigue"])+12)
			GameState.add_log("Work, routines and chores competed for the same week. I let the chores slip.")
	var load := 0
	if GameState.has_job(): load+=10 if GameState.player["job"].get("work_schedule","regular")=="overtime" else 2 if GameState.player["job"].get("work_schedule","regular")=="reduced" else 5
	if Transit.commuting(): load+=mini(8,Transit.minutes(Transit.current())/15)
	for id in GameState.heirs():
		if int(GameState.npc(id)["age"])<6: load+=2
	s["fatigue"]=clampi(int(s["fatigue"])+load-8,0,100)
	if int(s["fatigue"])>65: GameState.apply_effects({"stress":4,"happiness":-2})
