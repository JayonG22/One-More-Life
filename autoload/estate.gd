extends Node

## Fictional estate rules: each whole object has one owner; cash compensates
## uneven physical allocations when the estate has enough liquidity.
func prepare(old: Dictionary, cast: Dictionary, selected: String) -> Dictionary:
	var source := FamilyChronicle.identity(old)
	var prior: Dictionary=GameState.world.get("estate_register",{}).get(source,{})
	if prior.get("status","")=="executed": return {}
	var ids: Array=cast.keys().filter(func(id): return cast[id].get("alive",false) and cast[id].get("relation","")=="child" and not cast[id].get("disowned",false))
	var will := str(old.get("will","equal")); var named := will.substr(5) if will.begins_with("heir:") else ""
	var named_uid := str(old.get("journey",{}).get("heritage",{}).get("plan",{}).get("heir_uid",old.get("estate_child_uids",{}).get(named,"")))
	if named_uid!="":
		for id in ids:
			if FamilyChronicle.identity(cast[id])==named_uid: named=str(id); break
	var weights: Dictionary={}; var allocations: Dictionary={}
	for id in ids:
		weights[id]=0.3/ids.size()+(0.7 if id==named else 0.0) if ids.has(named) else 1.0/ids.size()
		allocations[id]={"uid":FamilyChronicle.identity(cast[id]),"cash":0,"properties":[],"items":[],"companies":[],"business":{},"home":{},"physical":0}
	var packets: Array=[]
	for property in old.get("properties",[]): packets.append({"type":"properties","value":maxi(0,int(property.get("value",0))),"object":property.duplicate(true)})
	var home_equity := maxi(0,int(old.get("house_value",0))-int(old.get("mortgage",0)))
	var secured_shortfall := 0
	if old.get("housing","")=="house" and int(old.get("house_value",0))>0 and int(old.get("mortgage",0))>int(old["house_value"]):
		# The secured lender takes the underwater residence. Only the remaining
		# claim enters estate settlement; heirs don't receive negative equity.
		secured_shortfall=int(old["mortgage"])-int(old["house_value"])
	elif old.get("housing","")=="house" and int(old.get("house_value",0))>0:
		packets.append({"type":"home","value":home_equity,"object":{"value":old["house_value"],"mortgage":old.get("mortgage",0),"payment":old.get("mortgage_payment",0),"uid":old.get("house_uid",source+":home"),"model":old.get("house_model","family"),"home":old.get("home",{}).duplicate(true),"adaptations":old.get("journey",{}).get("places",{}).duplicate(true)}})
	for item in old.get("possessions",[])+old.get("journey",{}).get("collection",{}).get("items",[]): packets.append({"type":"items","value":maxi(0,int(item.get("value",0))),"object":item.duplicate(true)})
	for company in old.get("ambition",{}).get("enterprise",{}).get("portfolio",[]):
		packets.append({"type":"companies","value":maxi(0,int(float(company.get("value",0))*float(company.get("stake",0))-int(company.get("debt",0)))),"object":company.duplicate(true)})
	var operating: Dictionary=old.get("business",{})
	var eligible_operators: Array=ids.filter(func(id): return int(cast[id].get("age",0))>=18 and cast[id].get("business",cast[id].get("playable_player",{}).get("business",{})).is_empty())
	var operating_equity := 0
	if not operating.is_empty() and not eligible_operators.is_empty() and will!="charity":
		operating_equity=int(float(operating.get("value",0))*float(operating.get("stake",1)))-int(operating.get("debt",0))
		# Insolvent businesses are wound up, not used to saddle an heir with debt.
		if operating_equity>0:
			var company := operating.duplicate(true)
			if not company.has("uid"): company["uid"]=source+":business:"+str(company.get("founded",0))+":"+str(company.get("name",""))
			Journey.modules["operations"].remember_crew(company,cast)
			company["country"]=old["country"]; company["local_cost"]=Places.cost_mult(old)
			packets.append({"type":"business","value":operating_equity,"object":company})
		else: operating_equity=0
	var cash := int(old.get("money",0))+int(old.get("savings",0))+Finance.investments_value(old)+Holdings.resale(old)+Ventures.value(old)+Empires.net_value(old)
	cash-=operating_equity
	cash+=Journey.modules["funds"].release(source)
	var debts := maxi(0,int(old.get("loan",0)))+Lending.total_owed(old)+maxi(0,int(old.get("student_debt",0)))+secured_shortfall
	if old.get("housing","")=="house" and int(old.get("house_value",0))==0: debts+=maxi(0,int(old.get("mortgage",0)))
	var physical := 0
	for packet in packets: physical+=int(packet["value"])
	var tx: Array=GameState.ESTATE_TAX.get(str(old["country"]),[0.0,0])
	var tax := int(maxi(0,cash+physical-debts-int(tx[1]))*float(tx[0]))
	cash-=debts+tax
	# Pay estate obligations before awarding objects. Insolvent estates cannot gift
	# a valuable portfolio while leaving all of its debt behind.
	packets.sort_custom(func(a,b): return int(a["value"])>int(b["value"]))
	var liquidated := 0
	while cash<0 and not packets.is_empty():
		var sold: Dictionary=packets.pop_back(); cash+=int(sold["value"]); liquidated+=int(sold["value"])
	var unpaid := maxi(0,-cash); cash=maxi(0,cash)
	var fees := int(cash*0.05); cash-=fees
	physical=0
	for packet in packets: physical+=int(packet["value"])
	var total := cash+physical
	var charity := 0
	if will=="charity" or ids.is_empty(): charity=total; cash=0; packets=[]
	else:
		for packet in packets:
			var target := str(ids[0]); var gap := -INF
			var succession := str(old.get("ambition",{}).get("enterprise",{}).get("succession",""))
			var succession_uid := str(old.get("estate_child_uids",{}).get(succession,""))
			if succession_uid!="":
				for id in ids:
					if FamilyChronicle.identity(cast[id])==succession_uid: succession=str(id); break
			for id in ids:
				var deficit := total*float(weights[id])-int(allocations[id]["physical"])
				if deficit>gap: gap=deficit; target=str(id)
			if packet["type"]=="companies" and ids.has(succession): target=succession
			if packet["type"]=="business":
				var operator := ""
				for id in eligible_operators:
					if FamilyChronicle.identity(cast[id])==str(packet["object"].get("successor_uid","")): operator=str(id)
				if operator!="": target=operator
				elif eligible_operators.has(succession): target=succession
				elif eligible_operators.has(named): target=named
				else: target=str(eligible_operators[0])
			var a: Dictionary=allocations[target]; var object: Dictionary=packet["object"]
			if packet["type"]=="home": a["home"]=object
			elif packet["type"]=="business":
				object["family_handover"]={"from":source,"to":a["uid"],"year":GameState.year_now()}
				a["business"]=object
			else:
				if packet["type"]=="properties": object["tenant"]=""
				if packet["type"]=="companies": object["ceo"]=""; object["family_handover"]={"from":source,"to":a["uid"],"year":GameState.year_now()}
				if packet["type"]=="items":
					object["heirloom"]=true
					object["heirloom_history"]=object.get("heirloom_history",[])
					object["heirloom_history"].append({"from":source,"to":a["uid"],"year":GameState.year_now(),"kind":"inheritance"})
					object["heirloom_history"]=Array(object["heirloom_history"]).slice(-16)
				a[packet["type"]].append(object)
			a["physical"]+=int(packet["value"])
		var deficit_total := 0.0
		for id in ids: deficit_total+=maxf(0,total*float(weights[id])-int(allocations[id]["physical"]))
		var remaining := cash
		for id in ids:
			var deficit := maxf(0,total*float(weights[id])-int(allocations[id]["physical"]))
			allocations[id]["cash"]=mini(remaining,int(cash*deficit/deficit_total)) if deficit_total>0 else 0
			remaining-=int(allocations[id]["cash"])
		if remaining>0: allocations[ids[0]]["cash"]+=remaining
		for id in ids:
			var n: Dictionary=cast[id]; var a: Dictionary=allocations[id]
			# The selected child's cash is added by continue_as, never here as well.
			if id!=selected: n["money"]=int(n.get("money",0))+int(a["cash"])
			if not a["business"].is_empty(): n["business"]=a["business"].duplicate(true)
			n["possessions"]=n.get("possessions",n.get("playable_player",{}).get("possessions",[])).duplicate(true)+a["items"]
			n["properties"]=n.get("properties",n.get("playable_player",{}).get("properties",[])).duplicate(true)+a["properties"]
			if not n.has("ambition"): n["ambition"]=n.get("playable_player",{}).get("ambition",{}).duplicate(true)
			if not n["ambition"].has("enterprise"): n["ambition"]["enterprise"]={"portfolio":[],"succession":""}
			n["ambition"]["enterprise"]["portfolio"].append_array(a["companies"])
			if not a["home"].is_empty():
				var previous_home: Dictionary=n.get("estate_home",{})
				if not previous_home.is_empty(): n["properties"].append({"uid":previous_home["uid"],"type":"Inherited home","value":maxi(0,int(previous_home["value"])-int(previous_home["mortgage"])),"condition":previous_home["home"].get("condition",75),"tenant":"","rent":0})
				n["estate_home"]=a["home"].duplicate(true)
			if n.has("playable_player"):
				for key in ["money","possessions","properties","ambition"]+(["business"] if n.has("business") else []): n["playable_player"][key]=n[key].duplicate(true) if n[key] is Array or n[key] is Dictionary else n[key]
	var receipts: Array=[]
	for id in ids:
		var a: Dictionary=allocations[id]
		receipts.append({"uid":a["uid"],"name":str(cast[id]["first"]),"cash":a["cash"],"physical":a["physical"],"properties":a["properties"].size(),"items":a["items"].size(),"companies":a["companies"].size(),"home":not a["home"].is_empty(),"business":not a["business"].is_empty()})
	if not GameState.world.has("estate_register"): GameState.world["estate_register"]={}
	GameState.world["estate_register"][source]={"status":"executed","heir":FamilyChronicle.identity(cast[selected]) if cast.has(selected) else "","cash":allocations.get(selected,{}).get("cash",0),"will":will,"year":GameState.year_now(),"allocations":receipts,"tax":tax,"fees":fees,"charity":charity,"unpaid":unpaid,"liquidated":liquidated,"executor":old.get("journey",{}).get("heritage",{}).get("plan",{}).get("executor",""),"name":old.get("first","Earlier life")}
	return allocations.get(selected,{"cash":0,"properties":[],"items":[],"companies":[],"business":{},"home":{}})

func settle_inactive(id: String) -> bool:
	var n := GameState.npc(id)
	if n.get("playable_player",{}).is_empty(): return false
	var source := FamilyChronicle.identity(n)
	if GameState.world.get("estate_register",{}).get(source,{}).get("status","")=="executed": return true
	var old: Dictionary=n["playable_player"].duplicate(true)
	for key in ["money","age","country","region","debts","business","ambition","possessions","properties","journey"]:
		if n.has(key): old[key]=n[key].duplicate(true) if n[key] is Dictionary or n[key] is Array else n[key]
	old["alive"]=false
	var cast: Dictionary={}
	var relations: Dictionary={}
	for who in GameState.npcs:
		if str(who)==id: continue
		var person: Dictionary=GameState.npcs[who]
		if person.get("parent_uids",[]).has(source):
			cast[who]=person; relations[who]=person["relation"]; person["relation"]="child"
	var selected := ""
	var active_had_relation := GameState.player.has("relation")
	var active_relation := str(GameState.player.get("relation",""))
	if GameState.player.get("parent_uids",[]).has(source):
		selected="__active_heir__"; cast[selected]=GameState.player
		GameState.player["relation"]="child"
	var allocation := prepare(old,cast,selected)
	for who in relations: cast[who]["relation"]=relations[who]
	if selected!="":
		if active_had_relation: GameState.player["relation"]=active_relation
		else: GameState.player.erase("relation")
		GameState.player["money"]=int(GameState.player["money"])+int(allocation.get("cash",0))
		restore_home(GameState.player,allocation.get("home",{})); GameState.player.erase("estate_home")
		Journey.modules["heritage"].record_inheritance(old,GameState.player,int(allocation.get("cash",0)))
		GameState.add_log(str(old["first"])+"'s estate was settled. My cash bequest was "+GameState.fmt_money(int(allocation.get("cash",0)))+"; estate obligations were paid before distribution.")
	n["money"]=0
	n["alive"]=false; n["playable_player"]["alive"]=false
	n["playable_player"]["car"]=""; n["playable_player"]["car_record"]={}
	n.erase("estate_home")
	# Keep the collection's provenance, but not ownership of transferred objects.
	for owner in [n,n["playable_player"]]:
		if owner.get("journey",{}).get("collection",{}).has("items"):
			owner["journey"]["collection"]["items"]=[]
	for key in ["money","savings","house_value","mortgage","loan","student_debt"]: n["playable_player"][key]=0
	for key in ["stocks","crypto","business","zoo","ventures"]: n["playable_player"][key]={}
	n["business"]={}
	for key in ["possessions","properties","debts"]:
		n[key]=[]; n["playable_player"][key]=[]
	if n["playable_player"].get("ambition",{}).has("enterprise"): n["playable_player"]["ambition"]["enterprise"]["portfolio"]=[]
	if n.get("ambition",{}).has("enterprise"): n["ambition"]["enterprise"]["portfolio"]=[]
	return true

func restore_home(p: Dictionary, home: Dictionary) -> void:
	if home.is_empty(): return
	if p.get("housing","")=="house" and int(p.get("house_value",0))>0:
		# Preserve an heir's existing residence. The inherited residence becomes
		# a separately owned property with its secured debt paid from that value.
		p["properties"].append({"uid":home["uid"],"name":"Inherited home","value":maxi(0,int(home["value"])-int(home["mortgage"])),"condition":home["home"].get("condition",75),"tenant":"","rent":0,"type":"house"})
		return
	p["housing"]="house"; p["house_value"]=home["value"]; p["mortgage"]=home["mortgage"]; p["mortgage_payment"]=home["payment"]
	p["house_uid"]=home["uid"]; p["house_model"]=home["model"]; p["home"]=home["home"].duplicate(true)
	# A separate residence must never retain the old portfolio primary index.
	p["home"].erase("primary_property"); p["home"].erase("primary_uid")
	if home["adaptations"].get("home","")==home["uid"]:
		if not p.has("journey"): p["journey"]={}
		if not p["journey"].has("places"): p["journey"]["places"]={}
		p["journey"]["places"]["home"]=home["uid"]
		p["journey"]["places"]["adaptations"]=home["adaptations"].get("adaptations",[]).duplicate()
