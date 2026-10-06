extends RefCounted
var h
const HOUSEHOLD_LINES := ["Living costs at home","Dorm and living costs","Living costs","My rent share","Mortgage payment","Transport, utilities and keeping in touch","Household service","Dependent support"]
func _init(hub): h=hub
func book() -> Dictionary:
	if not GameState.world.has("shared_funds"): GameState.world["shared_funds"]={}
	return GameState.world["shared_funds"]
func partner() -> String:
	if int(GameState.player.get("age",0))<18: return ""
	var id := str(GameState.player.get("partner",""))
	return id if GameState.player.get("living_together",false) and GameState.npcs.has(id) and GameState.npc(id).get("alive",false) and int(GameState.npc(id)["age"])>=18 else ""
func account() -> Dictionary:
	var id := partner()
	if id=="": return {}
	var owners: Array=[h.uid(),FamilyChronicle.identity(GameState.npc(id))]; owners.sort()
	var key := ":".join(owners)
	if not book().has(key): book()[key]={"owners":owners,"balances":{owners[0]:0,owners[1]:0},"history":[],"partner_year":-1}
	return book()[key]
func value(uid: String) -> int:
	var result := 0
	for a in book().values(): result+=maxi(0,int(a["balances"].get(uid,0)))
	return result
func record(a: Dictionary, text: String, amount: int) -> void:
	a["history"].push_front({"year":GameState.year_now(),"text":text,"amount":amount})
	if a["history"].size()>20: a["history"].resize(20)
func deposit(percent: int) -> void:
	var a := account()
	if a.is_empty() or percent not in [5,10,20] or h.blocked(18)!="": return
	var amount := int(maxi(0,int(GameState.player["money"]))*percent/100.0)
	if amount<=0 or not h.pay("fund_deposit",0,amount,18): return
	a["balances"][h.uid()]+=amount; record(a,"My contribution",amount)
	Finance.record_transfer("Shared household reserve",amount)
	h.done("🏦","Household reserve","Moved "+GameState.fmt_money(amount)+" from cash into my owned share. It remains in my net worth; a partner's share belongs to them.")
func invite() -> void:
	var id := partner(); var a := account()
	if id=="" or a.is_empty() or int(a["partner_year"])==GameState.year_now() or not h.pay("fund_invite",1,0,18): return
	a["partner_year"]=GameState.year_now()
	var n := GameState.npc(id); var uid := FamilyChronicle.identity(n)
	var available := maxi(0,int(n.get("money",0))-Actions._cost(1000))
	var amount := mini(available,int(maxi(0,int(n.get("job",{}).get("salary",0)))*0.10))
	if BondStats.get_stat(id,"trust")<55 or amount<=0:
		h.done("🏦","A separate decision","They declined or could not afford a contribution. No money moved; sharing an address does not give access to their cash."); return
	n["money"]-=amount; a["balances"][uid]+=amount
	if n.has("playable_player"): n["playable_player"]["money"]=n["money"]
	record(a,str(n["first"])+" contributed",amount)
	FamilyChronicle.remember(id,"Agreed to an affordable household reserve contribution.")
	h.done("🏦","A shared reserve",str(n["first"])+" moved "+GameState.fmt_money(amount)+" from their cash. It is still their owned share, available for an agreed household shortfall.")
func withdraw() -> void:
	if h.blocked(18)!="": return
	var amount := 0
	for a in book().values():
		var own := maxi(0,int(a["balances"].get(h.uid(),0)))
		if own==0: continue
		a["balances"][h.uid()]=0; amount+=own; record(a,"My owned share withdrawn",-own)
	GameState.player["money"]+=amount
	if amount>0:
		Finance.record_transfer("Shared household reserve",-amount)
		h.done("🏦","My share returned",GameState.fmt_money(amount)+" returned to my cash. Other owners' money stays theirs; separation does not erase ownership.")
func shortfall() -> void:
	var a := account(); var id := partner()
	if a.is_empty() or id=="" or int(GameState.player["money"])>=0: return
	var limit := bill_limit(a)
	if limit<=0:
		h.done("🏦","No eligible shortfall","No unpaid allowance remains from the current household bill record. Personal loans and unrelated purchases are excluded."); return
	if not h.pay("fund_shortfall",0,0,18): return
	if a.get("shared_cover",false) and (BondStats.get_stat(id,"trust")<40 or BondStats.get_stat(id,"resentment")>=60):
		a["shared_cover"]=false; record(a,"Shared cover paused after relationship strain",0)
	var deficit := mini(-int(GameState.player["money"]),limit)
	var paid := 0
	for uid in [h.uid(),FamilyChronicle.identity(GameState.npc(id))]:
		if uid!=h.uid() and (not a.get("shared_cover",false) or BondStats.get_stat(id,"trust")<40): continue
		var amount := mini(deficit-paid,maxi(0,int(a["balances"].get(uid,0))))
		a["balances"][uid]-=amount; paid+=amount
	if not a.has("covered"): a["covered"]={}
	var claim: Dictionary=a["covered"].get(h.uid(),{"year":GameState.year_now(),"paid":0})
	if int(claim["year"])!=GameState.year_now(): claim={"year":GameState.year_now(),"paid":0}
	claim["paid"]=int(claim["paid"])+paid; a["covered"][h.uid()]=claim
	GameState.player["money"]+=paid; record(a,"Covered a recorded household shortfall",-paid)
	Finance.record_transfer("Shared household reserve",-paid)
	h.done("🏦","Reserve used",GameState.fmt_money(paid)+" covered negative cash within the eligible household bill allowance. Loans remain outstanding. "+("Both owned shares were available by agreement." if a.get("shared_cover",false) else "Only my share was available."))
func bill_limit(a: Dictionary) -> int:
	var ledger: Dictionary=GameState.player.get("household_ledger",{})
	if int(ledger.get("year",-1))!=GameState.year_now(): return 0
	var total := mini(bill_cost(ledger.get("lines",{})),maxi(0,int(ledger.get("reserve_shortfall",0))))
	var claim: Dictionary=a.get("covered",{}).get(h.uid(),{})
	if int(claim.get("year",-1))==GameState.year_now(): total-=int(claim.get("paid",0))
	return maxi(0,total)
func bill_cost(lines: Dictionary) -> int:
	var total := 0
	for category in lines:
		if HOUSEHOLD_LINES.has(str(category)): total+=maxi(0,int(lines[category]))
	return total
func agreement() -> void:
	var a := account(); var id := partner()
	if a.is_empty() or id=="" or not h.pay("fund_agreement",1,0,18): return
	var n := GameState.npc(id)
	var accepted := BondStats.get_stat(id,"trust")>=55 and BondStats.get_stat(id,"resentment")<35
	a["shared_cover"]=accepted; a["agreement_year"]=GameState.year_now()
	record(a,"Agreed shared household cover" if accepted else "Kept separate reserve permissions",0)
	FamilyChronicle.remember(id,"Discussed permission to use reserve shares for recorded household bills.","good" if accepted else "neutral")
	if accepted: BondStats.apply(id,{"trust":1,"respect":1})
	h.done("🤝","Reserve agreement","We agreed that either owned share can cover recorded household shortfalls. Ownership stays separate; either side can return to separate cover." if accepted else "They declined shared cover. I can still use my own share; their cash and reserve remain theirs.")
func revoke() -> void:
	var a := account()
	if a.is_empty() or h.blocked(18)!="" or not a.get("shared_cover",false): return
	a["shared_cover"]=false
	record(a,"Returned to separate cover permissions",0)
	h.done("🏦","Separate cover","My shortfalls can use my share only. Both reserve balances keep their owners.")
func release(uid: String) -> int:
	var amount := value(uid)
	for a in book().values():
		if a["balances"].has(uid): a["balances"][uid]=0
	return amount
func plan() -> Dictionary:
	var rules: Dictionary=h.section("funds",{"monthly":0,"floor":1000,"last_year":-1})
	if not rules.has("floor_cash"): rules["floor_cash"]=Actions._cost(int(rules["floor"]))
	return rules
func budget(monthly: int) -> void:
	if monthly not in [0,25,100,250] or h.blocked(18)!="": return
	plan()["monthly"]=monthly
	var id := partner()
	if id!="": account(); GameState.player["reserve_partner_uid"]=FamilyChronicle.identity(GameState.npc(id))
	h.done("🏦","Reserve plan",("Paused." if monthly==0 else GameState.fmt_money(monthly)+" a month, settled yearly from available cash.")+" The configured cash floor is protected; unpaid contributions create no debt.")
func floor_amount(amount: int) -> void:
	if amount not in [500,1000,3000] or h.blocked(18)!="": return
	plan()["floor"]=amount; plan()["floor_cash"]=Actions._cost(amount)
func settle_budget(p: Dictionary, year: int) -> int:
	var rules: Dictionary=p.get("journey",{}).get("funds",{})
	if rules.is_empty() or int(rules.get("last_year",-1))>=year: return 0
	rules["last_year"]=year
	if not p.get("alive",false) or int(p.get("age",0))<18 or int(p.get("prison",0))>0 or not p.get("living_together",false): return 0
	var uid := FamilyChronicle.identity(p); var a: Dictionary={}
	var partner_id := str(p.get("partner",""))
	var other: Dictionary=GameState.npc(partner_id)
	var other_uid: String=str(p.get("reserve_partner_uid",other.get("person_uid","")))
	# A dormant parent's partner may now be the active player.
	if other_uid=="": other_uid=str(p.get("reserve_partner_uid",""))
	var person: Dictionary=GameState.player if other_uid==h.uid() else GameState.npc(h.person(other_uid))
	if person.is_empty() or not person.get("alive",false): return 0
	for candidate in book().values():
		if candidate["owners"].has(uid) and candidate["owners"].has(other_uid): a=candidate; break
	if a.is_empty(): return 0
	var amount := mini(maxi(0,int(rules["monthly"]))*12,maxi(0,int(p.get("money",0))-int(rules.get("floor_cash",Actions._cost(int(rules["floor"]))))))
	p["money"]=int(p.get("money",0))-amount; a["balances"][uid]=int(a["balances"].get(uid,0))+amount
	if amount>0: record(a,"Standing reserve contribution",amount)
	rules["last_amount"]=amount
	return amount
func settle_active_after_finances() -> void:
	if Lives.separate(): return
	var p := GameState.player
	var amount := settle_budget(p,GameState.year_now())
	if amount<=0: return
	Finance.record_transfer("Shared household reserve",amount)
func yearly() -> void:
	if Lives.separate(): return
	var id := partner()
	if id!="":
		var a := account(); GameState.player["reserve_partner_uid"]=FamilyChronicle.identity(GameState.npc(id))
		if a.get("shared_cover",false) and (BondStats.get_stat(id,"trust")<40 or BondStats.get_stat(id,"resentment")>=60):
			a["shared_cover"]=false; record(a,"Shared cover paused after relationship strain",0)
			h.note("Reserve agreement paused","The shared-cover agreement needs another discussion. Owned balances remain intact.")
func background(n: Dictionary, year: int) -> void:
	var saved: Dictionary=n.get("playable_player",{})
	if saved.is_empty(): return
	saved["money"]=n.get("money",0); saved["age"]=n.get("age",0); saved["alive"]=n.get("alive",false)
	saved["prison"]=n.get("prison",0)
	settle_budget(saved,year); n["money"]=saved["money"]
func resolve(_op: String, _args: Dictionary, _answer: int) -> void: pass
func menu(page: String) -> Dictionary:
	var rows: Array=[]; var a := account()
	var rules := plan()
	var info: Array=["Standing plan: %s/month · cash floor %s." % [GameState.fmt_money(int(rules["monthly"])),GameState.fmt_money(int(rules.get("floor_cash",Actions._cost(int(rules["floor"])))))],"My reserve shares: "+GameState.fmt_money(value(h.uid()))+". Your share stays yours. This reserve earns no interest."]
	if page in ["","root"]:
		rows=[h.nav("funds","Savings plan","After-bill contributions and cash floor","plan"),h.nav("funds","Contributions & withdrawals","Move owned money","money"),h.nav("funds","Household cover","Agreement and actual bill shortfalls","agreement"),h.nav("funds","Reserve history","Contributions and withdrawals","history")]
		rows.append({"icon":"🧾","name":"Budget practice","sub":"Short household-planning challenge","menu":"journey:skills:budget"})
	elif page=="history":
		for reserve in book().values():
			if not reserve["balances"].has(h.uid()): continue
			for entry in reserve["history"].slice(0,8): info.append("%d · %s · %s" % [entry["year"],entry["text"],GameState.fmt_money(int(entry["amount"]))])
	elif not a.is_empty():
		var id := partner(); var uid := FamilyChronicle.identity(GameState.npc(id))
		info.append(str(GameState.npc(id)["first"])+" owns "+GameState.fmt_money(int(a["balances"][uid]))+" in this reserve.")
		if page=="plan":
			for monthly in [0,25,100,250]: rows.append(h.row("funds","Pause savings" if monthly==0 else "Save "+GameState.fmt_money(monthly)+"/month","After yearly bills · own cash only · no debt","budget",monthly,int(rules["monthly"])!=monthly))
			for amount in [500,1000,3000]: rows.append(h.row("funds","Cash floor: "+GameState.fmt_money(Actions._cost(amount)),"Protect cash before saving","floor",amount,int(rules["floor"])!=amount))
		elif page=="money":
			for percent in [5,10,20]: rows.append(h.row("funds","Set aside "+str(percent)+"% of my cash","Once yearly · my owned share","deposit",percent,not h.used("fund_deposit") and int(GameState.player["money"])>0))
			rows.append(h.row("funds","Discuss their contribution","1 time · trust and affordability","invite",null,int(a["partner_year"])!=GameState.year_now()))
		elif page=="agreement":
			info.append("Cover: "+("Agreed shared cover" if a.get("shared_cover",false) else "Separate shares"))
			info.append("Eligible bill allowance: "+GameState.fmt_money(bill_limit(a)))
			rows.append(h.row("funds","Discuss shared cover","1 time · trust 55+ · resentment below 35","agreement",null,not h.used("fund_agreement")))
			rows.append(h.row("funds","Return to separate cover","Keep balances and ownership","revoke",null,a.get("shared_cover",false)))
			rows.append(h.row("funds","Cover a household shortfall","Recorded bills · negative cash · once yearly","shortfall",null,int(GameState.player["money"])<0 and bill_limit(a)>0 and not h.used("fund_shortfall")))
	else:
		info.append("No automatic contribution without a current shared household. Earlier owned shares remain accessible.")
		if int(rules["monthly"])>0: rows.append(h.row("funds","Pause standing savings","Keep existing reserve shares","budget",0))
	if page=="money": rows.append(h.row("funds","Return my reserve shares","Withdraw only my own contributions","withdraw",null,value(h.uid())>0))
	return {"title":"Shared household reserve","icon":"🏦","rows":rows,"info":info}
func act(key: String, arg: Variant) -> void:
	match key:
		"deposit": deposit(int(arg))
		"invite": invite()
		"withdraw": withdraw()
		"shortfall": shortfall()
		"budget": budget(int(arg))
		"floor": floor_amount(int(arg))
		"agreement": agreement()
		"revoke": revoke()
