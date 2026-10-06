extends Node

## Records attach to a particular car/home, never to the next purchase.
const HOMES := {"studio":[2,0.8,600],"terrace":[4,0.9,900],"bungalow":[4,1.1,1100],"family":[6,1.15,1600],"villa":[8,1.25,2400],"mansion":[12,1.3,4800],"estate":[20,1.5,8500]}

func car(p: Dictionary = {}) -> Dictionary:
	if p.is_empty(): p=GameState.player
	var model := str(p.get("car",""))
	if model=="": return {}
	if not p.has("car_record") or str(p["car_record"].get("model",""))!=model:
		var price := int(int(GameState.CARS[model]["price"])*float(ContentDB.country(p.get("country","us")).get("cost",1.0))*Places.cost_mult(p)*World.cost_mult()*Expansion.era_cost_mult())
		p["car_record"]={"uid":FamilyChronicle.identity(p)+":car:"+str(Time.get_ticks_usec()),"model":model,"condition":75.0,"mileage":60000,"years":5,"price":price,"last_year":-1,"history":[],"repairs":0}
	return p["car_record"]

func new_car(model: String, price: int) -> void:
	GameState.player["car_record"]={"uid":Journey.uid()+":car:"+str(Time.get_ticks_usec()),"model":model,"condition":100.0,"mileage":0,"years":0,"price":price,"last_year":GameState.year_now(),"history":[],"repairs":0}
	Transit.st()["serviced"]=false

func resale(p: Dictionary = {}) -> int:
	var r := car(p)
	if r.is_empty(): return 0
	var age_factor := maxf(0.15,pow(0.94,int(r["years"])))
	var mileage_factor := clampf(1.0-int(r["mileage"])/450000.0,0.4,1.0)
	return maxi(0,int(int(r["price"])*0.8*age_factor*mileage_factor*(0.25+float(r["condition"])*0.0075)))

func drivable() -> bool:
	return not car().is_empty() and float(car()["condition"])>=15

func primary_index() -> int:
	var p := GameState.player; var h: Dictionary=p.get("home",{})
	if h.has("primary_uid"):
		for i in range(p["properties"].size()):
			if p["properties"][i].get("uid","")==h["primary_uid"]: return i
		return -1
	return int(h.get("primary_property",-1)) if int(h.get("primary_property",-1))<p["properties"].size() else -1
func is_primary(pr: Dictionary) -> bool:
	var index := primary_index()
	return index>=0 and GameState.player["properties"][index]==pr
func sync_home() -> void:
	var index := primary_index()
	if index>=0: GameState.player["properties"][index]["condition"]=GameState.player["home"]["condition"]

func commute_factor() -> float:
	if GameState.player.get("housing","")!="house": return 1.0
	return float(HOMES.get(str(GameState.player.get("house_model","")),[4,1.0,1100])[1])

func occupants() -> int:
	var total := 1+(1 if GameState.player.get("living_together",false) and GameState.player.get("partner","")!="" else 0)
	for id in GameState.npcs_with("child")+GameState.npcs_with("stepchild"):
		if int(GameState.npc(id)["age"])<18: total+=1
	return total

func home_costs() -> int:
	if GameState.player.get("housing","")!="house": return 0
	return int(HOMES.get(str(GameState.player.get("house_model","")),[4,1.0,1100])[2])

func yearly_vehicle(p: Dictionary = {}, driving: bool = true) -> void:
	if p.is_empty(): p=GameState.player
	var r := car(p); var year := GameState.year_now()
	if r.is_empty() or int(r["last_year"])==year: return
	r["last_year"]=year; r["years"]=int(r["years"])+1
	var distance := 1000
	if driving: distance=5000+Transit.base_minutes()*180 if p==GameState.player else 12000
	r["mileage"]=int(r["mileage"])+distance
	var maintained := bool(p.get("transit",{}).get("serviced",false))
	var wear := 2.0+distance/5000.0+mini(12,int(r["years"]))*0.3
	r["condition"]=maxf(0,float(r["condition"])-wear*(0.45 if maintained else 1.0))
	r["history"].push_front({"year":year,"distance":distance,"serviced":maintained,"condition":r["condition"]})
	if r["history"].size()>20: r["history"].resize(20)

func home_yearly() -> void:
	var p := GameState.player
	if p.get("housing","")!="house": return
	var profile: Array=HOMES.get(str(p.get("house_model","")),[4,1.0,1100])
	var crowd := maxi(0,occupants()-int(profile[0]))
	if crowd>0:
		GameState.apply_effects({"stress":mini(6,crowd*2),"happiness":-mini(3,crowd)})
		GameState.add_log("My home has space for %d people, but %d live here. The crowding adds pressure." % [profile[0],occupants()])

func service(repair: bool = false, diy: bool = false) -> void:
	if not Transit.has_car() or Journey.blocked(16)!="": return
	if diy and Market.skill("Trades")<4: return
	if not repair and Transit.st().get("serviced",false): return
	var time := 2 if diy else 1
	var fee := Actions._cost(220 if diy else 950 if repair else 450)
	if GameState.player["time_left"]<time or int(GameState.player["money"])<fee: return
	GameState.spend_time(time); GameState.player["money"]=int(GameState.player["money"])-fee
	var r := car()
	r["condition"]=minf(100,float(r["condition"])+(20 if diy else 38 if repair else 12))
	r["repairs"]=int(r["repairs"])+(1 if repair else 0)
	Transit.st()["serviced"]=true
	Journey.done("🔧","Car maintained","Paid %s · condition %d/100. Protection applies to the next yearly driving check." % [GameState.fmt_money(fee),int(r["condition"])])

func menu(_key: String) -> Dictionary:
	var rows: Array=[]; var info: Array=[]
	if Transit.has_car():
		var r := car()
		info.append("%s · condition %d/100 · %d km · %d years" % [GameState.CARS[r["model"]]["name"],int(r["condition"]),int(r["mileage"]),int(r["years"])])
		info.append("Resale %s. Wear depends on use; low condition increases breakdown risk. Below 15 condition, choose another commute." % GameState.fmt_money(resale()))
		rows.append({"name":"Service","icon":"🔧","sub":"1 time · "+GameState.fmt_money(Actions._cost(450)),"act":"hold:service","on":not Transit.st().get("serviced",false)})
		rows.append({"name":"Repair worn parts","icon":"🛠️","sub":"1 time · "+GameState.fmt_money(Actions._cost(950))+" · +38 condition","act":"hold:repair","on":float(r["condition"])<100})
		rows.append({"name":"Repair it yourself","icon":"🧰","sub":"Trades skill 4 · 2 time · "+GameState.fmt_money(Actions._cost(220))+" · +20 condition","act":"hold:diy","on":Market.skill("Trades")>=4 and float(r["condition"])<100})
		rows.append({"name":"Commute & insurance","icon":"🧭","sub":"Choose transport and cover","menu":"real:go"})
	if GameState.player.get("housing","")=="house":
		var profile: Array=HOMES.get(str(GameState.player.get("house_model","")),[4,1.0,1100])
		info.append("Home: capacity %d · household %d · commute ×%.2f · utilities %s/year before local costs." % [profile[0],occupants(),profile[1],GameState.fmt_money(int(profile[2]))])
		rows.append({"name":"Home condition & improvements","icon":"🏡","sub":"Maintain this particular home","menu":"exp:home"})
	if info.is_empty(): info=["Buy homes and vehicles through Shopping. Owned-item condition and suitability appear here."]
	return {"title":"Ownership & everyday use","icon":"🔑","info":info,"rows":rows}

func act(key: String, _arg: Variant = null) -> void:
	match key:
		"service": service()
		"repair": service(true)
		"diy": service(true,true)
