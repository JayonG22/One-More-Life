extends RefCounted
var h
func _init(hub): h=hub
func st() -> Dictionary: return h.section("collection",{"open":false,"items":[],"ticket":12,"condition":75.0,"security":false,"last_year":-1,"history":[],"visitors":0,"profit":0,"name":"The Second Look Museum"})
func open() -> void:
	if st()["open"] or not h.pay("museum_open",2,Actions._cost(25000),21): return
	st()["open"]=true; st()["last_year"]=GameState.year_now()
	h.done("🏛️","Museum opened","The fit-out is paid. Ticket income arrives at yearly reviews; staffing, rent, care and security can make a loss. Add owned exhibits to begin.")
func exhibit(index: int) -> void:
	if not st()["open"] or st()["items"].size()>=6 or index<0 or index>=GameState.player["possessions"].size(): return
	if not h.pay("exhibit",1,Actions._cost(100),21): return
	var item: Dictionary=GameState.player["possessions"].pop_at(index)
	item["museum_documented"]=false; st()["items"].append(item)
	h.done("🖼️","Exhibit installed",str(item.get("name","The object"))+" moved from possessions into the museum. Its history is retained; it cannot be sold twice.")
func withdraw(index: int) -> void:
	if index<0 or index>=st()["items"].size() or not h.pay("withdraw_exhibit",1,0,21): return
	GameState.player["possessions"].append(st()["items"].pop_at(index))
	h.done("📦","Exhibit returned","The object is back in possessions. It stops attracting museum visitors.")
func document(index: int) -> void:
	if index<0 or index>=st()["items"].size() or st()["items"][index].get("museum_documented",false): return
	if not h.pay("museum_research",1,Actions._cost(300),21): return
	var item: Dictionary=st()["items"][index]
	item["museum_documented"]=true
	item["museum_disclosed"]=bool(item.get("fake",item.get("forged",false))) or bool(item.get("stolen",false))
	Market.learn("Media",1)
	h.done("🔎","Provenance recorded","The available records and ownership history are recorded. Known forgery or stolen status is disclosed; research does not erase it. Documented objects improve educational appeal.")
func appeal(s: Dictionary) -> float:
	var total := 0.0
	for item in s["items"]:
		total+=minf(15,3+log(maxf(1,float(item.get("value",100))))/2)+(4 if item.get("museum_documented",false) else 0)-(8 if item.get("museum_disclosed",false) else 0)
	return maxf(0,total)*float(s["condition"])/100.0
func review(s: Dictionary, owner: Dictionary, year: int) -> void:
	if not s.get("open",false) or int(s["last_year"])==year: return
	s["last_year"]=year
	s["condition"]=maxf(0,float(s["condition"])-(3 if s["security"] else 6))
	var demand := appeal(s)*80.0*(1.0 if int(s["ticket"])<=12 else 0.55 if int(s["ticket"])<=30 else 0.20)
	var visitors := maxi(0,int(demand))
	var country := str(owner.get("country",GameState.player["country"]))
	var regions := Places.regions(country)
	var region: Dictionary=regions[0] if not regions.is_empty() else {}
	for candidate in regions:
		if candidate["id"]==owner.get("region",""): region=candidate
	var cost := float(ContentDB.country(country).get("cost",1.0))*float(region.get("cost",1.0))*World.cost_mult()*Expansion.era_cost_mult()
	var tax := float(region.get("laws",{}).get("tax",Places.LAWS.get(country,Places.LAWS["us"])["tax"]))
	var expense := int((4000+s["items"].size()*180+(1000 if s["security"] else 0))*cost)
	var gross := visitors*int(s["ticket"])
	var profit := gross-expense
	if profit>0: profit=int(profit*(1-tax))
	owner["money"]=int(owner.get("money",0))+profit
	s["visitors"]=visitors; s["profit"]=profit
	s["history"].push_front({"year":year,"visitors":visitors,"revenue":gross,"expenses":expense,"profit":profit,"appeal":appeal(s)})
	if s["history"].size()>30: s["history"].resize(30)
func yearly() -> void:
	if Lives.separate(): return
	var s := st(); var before := int(s["last_year"])
	review(s,GameState.player,GameState.year_now())
	if s["open"] and before!=int(s["last_year"]):
		Employment.record_income("Museum operating result",int(s["profit"]))
		h.note("Museum annual review","%d visitors · revenue %s · expenses %s · net %s." % [s["visitors"],GameState.fmt_money(int(s["history"][0]["revenue"])),GameState.fmt_money(int(s["history"][0]["expenses"])),GameState.fmt_money(int(s["profit"]))])
func handover(id: String) -> void:
	if not st()["open"] or id not in GameState.npcs_with("child") or int(GameState.npc(id)["age"])<21 or not h.pay("museum_handover",2,Actions._cost(500),21): return
	var n := GameState.npc(id)
	var target: Dictionary=h.section("collection",{"open":false,"items":[]},n.get("playable_player",n))
	if target.get("open",false):
		# Do not overwrite an existing business; transfer the objects as gifts.
		if not n.has("possessions"): n["possessions"]=n.get("playable_player",{}).get("possessions",[]).duplicate(true)
		n["possessions"].append_array(st()["items"])
	else: target.merge(st().duplicate(true),true)
	st()["items"]=[]; st()["open"]=false
	if n.has("playable_player"): n["playable_player"]["possessions"]=n.get("possessions",[]).duplicate(true)
	FamilyChronicle.remember(id,"Received the family museum or its exhibit collection.","good")
	h.done("🌳","Museum handed over","The collection no longer belongs to me. Its new owner pays costs and receives future ticket income.")
func resolve(_op: String, _args: Dictionary, _answer: int) -> void: pass
func menu(page: String) -> Dictionary:
	var rows: Array=[]; var s := st()
	var info: Array=["Condition %d/100 · %d/6 exhibits · ticket %s · last visitors %d · net %s" % [s["condition"],s["items"].size(),GameState.fmt_money(int(s["ticket"])),s["visitors"],GameState.fmt_money(int(s["profit"]))]]
	if not s["open"]: rows.append(h.row("collection","Open a museum","2 time · "+GameState.fmt_money(Actions._cost(25000)),"open"))
	else:
		if page=="add":
			for i in range(GameState.player["possessions"].size()): rows.append(h.row("collection",str(GameState.player["possessions"][i].get("name","Object")),"Install · 1 time · "+GameState.fmt_money(Actions._cost(100)),"exhibit",i))
		else:
			rows.append(h.nav("collection","Add an exhibit","Move an owned object into the museum","add"))
			for fee in [0,12,30,75]: rows.append(h.row("collection","Ticket: "+GameState.fmt_money(fee),"Higher prices reduce attendance","ticket",fee))
			rows.append(h.row("collection","Clean & maintain","1 time · "+GameState.fmt_money(Actions._cost(500))+" · +15 condition","maintain",null,float(s["condition"])<100))
			rows.append(h.row("collection","Security: "+("ON" if s["security"] else "OFF"),"1 time · annual cost 1,000 before local costs · slower wear","security"))
			for i in range(s["items"].size()):
				rows.append(h.row("collection","Research: "+str(s["items"][i].get("name","Object")),"1 time · "+GameState.fmt_money(Actions._cost(300)),"document",i,not s["items"][i].get("museum_documented",false)))
				rows.append(h.row("collection","Return: "+str(s["items"][i].get("name","Object")),"1 time · return ownership to possessions","withdraw",i))
			for id in GameState.npcs_with("child"):
				if int(GameState.npc(id)["age"])>=21: rows.append(h.row("collection","Hand over to "+str(GameState.npc(id)["first"]),"2 time · "+GameState.fmt_money(Actions._cost(500)),"handover",id))
			rows.append(h.row("collection","Close the museum","Return exhibits; fit-out cost is not refunded","close"))
	for entry in s["history"].slice(0,5): info.append("%d · %d visitors · net %s" % [entry["year"],entry["visitors"],GameState.fmt_money(int(entry["profit"]))])
	return {"title":"My museum","icon":"🏛️","rows":rows,"info":info}
func act(key: String, arg: Variant) -> void:
	if key!="open" and not st()["open"]: return
	match key:
		"open": open()
		"exhibit": exhibit(int(arg))
		"withdraw": withdraw(int(arg))
		"document": document(int(arg))
		"handover": handover(str(arg))
		"ticket": if int(arg) in [0,12,30,75] and h.blocked(21)=="": st()["ticket"]=int(arg)
		"security": if h.pay("museum_security",1,0,21): st()["security"]=not st()["security"]
		"maintain": if float(st()["condition"])<100 and h.pay("museum_maintain",1,Actions._cost(500),21): st()["condition"]=minf(100,float(st()["condition"])+15)
		"close":
			if not st()["open"] or h.blocked(21)!="": return
			GameState.player["possessions"].append_array(st()["items"]); st()["items"]=[]; st()["open"]=false
			h.done("🏛️","Museum closed","All exhibits returned to possessions. Operating bills stop; the fit-out is not refunded.")
