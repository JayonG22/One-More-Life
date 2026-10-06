extends Node

## Family support is separate from the child's earned cash and formal adult loans.
func st() -> Dictionary:
	var p := GameState.player
	if not p.has("childhood_budget"): p["childhood_budget"]={"independence_age":18,"covered":0,"assistance":0,"contributed":0,"records":[],"used":{},"independent":false}
	return p["childhood_budget"]
func independence_age() -> int:
	return clampi(int(st()["independence_age"]),16,21)
func supported() -> bool:
	return GameState.has_life() and not Lives.separate() and int(GameState.player["age"])<independence_age()
func parents() -> Array:
	return GameState.npcs_with("mother")+GameState.npcs_with("father")+GameState.npcs_with("stepmother")+GameState.npcs_with("stepfather")
func cover(amount: int, reason: String) -> void:
	if amount<=0 or not supported(): return
	var remaining := amount
	for id in parents():
		var n := GameState.npc(id)
		var paid := mini(remaining,maxi(0,int(n.get("money",0))))
		n["money"]=int(n.get("money",0))-paid; remaining-=paid
		if n.has("playable_player"): n["playable_player"]["money"]=n["money"]
		if remaining==0: break
	st()["covered"]=int(st()["covered"])+amount
	st()["assistance"]=int(st()["assistance"])+remaining
	st()["records"].push_front({"year":GameState.year_now(),"reason":reason,"amount":amount,"assistance":remaining})
	if st()["records"].size()>20: st()["records"].resize(20)
	GameState.add_log("My household covered %s for %s%s; this is not my personal debt." % [GameState.fmt_money(amount),reason," with support assistance" if remaining>0 else ""])
func protect() -> void:
	if not GameState.has_life() or Lives.separate(): return
	if supported():
		var deficit := maxi(0,-int(GameState.player["money"]))
		if deficit>0: cover(deficit,"childhood bills"); GameState.player["money"]=0
	elif not st()["independent"]:
		st()["independent"]=true
		GameState.add_log("I now manage my own finances. Household support ends; my earned savings and gifts remain mine.")
func contribute(uid: String, percent: int) -> void:
	var id := Journey.person(uid)
	var key := str(GameState.year_now())+":"+uid
	if not supported() or int(GameState.player["age"])<6 or id not in parents() or percent not in [25,50,100] or st()["used"].has(key) or Journey.blocked(6)!="": return
	var amount := int(maxi(0,int(GameState.player["money"]))*percent/100.0)
	if amount<=0: return
	GameState.player["money"]=int(GameState.player["money"])-amount
	var n := GameState.npc(id); n["money"]=int(n.get("money",0))+amount
	if n.has("playable_player"): n["playable_player"]["money"]=n["money"]
	st()["contributed"]=int(st()["contributed"])+amount; st()["used"][key]=true
	FamilyChronicle.remember(id,"Received a household contribution of "+GameState.fmt_money(amount)+".","good")
	BondStats.apply(id,{"trust":2,"respect":2})
	Journey.done("🏠","Helped at home",GameState.fmt_money(amount)+" moved from my own cash to "+str(n["first"])+". No money was created; once per parent each year.")
func menu(_page: String) -> Dictionary:
	var rows: Array=[]
	var info: Array=["Family support ends at %d. This is a game household agreement, not a statement about local law." % independence_age(),"Earned cash and gifts are yours. Childhood event charges are paid by the household; emergencies can use assistance without creating personal debt.","Household covered %s · assistance %s · contributed %s" % [GameState.fmt_money(int(st()["covered"])),GameState.fmt_money(int(st()["assistance"])),GameState.fmt_money(int(st()["contributed"]))]]
	if supported():
		for age in [16,18,21]:
			rows.append({"name":"Support until "+str(age),"sub":"Household agreement · personal savings stay yours","icon":"🏠","act":"child:age","arg":age,"on":int(GameState.player["age"])<age})
		for id in parents():
			for percent in [25,50,100]: rows.append({"name":"Give "+str(GameState.npc(id)["first"])+" "+str(percent)+"%","sub":GameState.fmt_money(int(maxi(0,int(GameState.player["money"]))*percent/100.0))+" of my cash · once per parent/year","icon":"🤝","act":"child:give","arg":{"uid":FamilyChronicle.identity(GameState.npc(id)),"percent":percent},"on":int(GameState.player["age"])>=6 and int(GameState.player["money"])>0 and not st()["used"].has(str(GameState.year_now())+":"+FamilyChronicle.identity(GameState.npc(id)))})
	else: info.append("You now pay your own costs. There is no automatic cash grant or savings reset.")
	return {"title":"Family budget","icon":"🏠","rows":rows,"info":info}
func act(key: String, arg: Variant) -> void:
	if key=="age" and int(arg) in [16,18,21] and supported() and int(GameState.player["age"])<int(arg) and Journey.blocked()=="": st()["independence_age"]=int(arg)
	elif key=="give" and arg is Dictionary: contribute(str(arg.get("uid","")),int(arg.get("percent",0)))
