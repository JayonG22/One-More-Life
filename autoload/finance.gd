extends Node

const STOCKS := {
	"NMB": {"name": "Nimbus Tech", "sector": "Tech", "icon": "💻", "start": 120.0, "vol": 0.28},
	"SOL": {"name": "Solaris Energy", "sector": "Energy", "icon": "⚡", "start": 64.0, "vol": 0.22},
	"HRT": {"name": "Hearth & Co.", "sector": "Retail", "icon": "🛍️", "start": 42.0, "vol": 0.16},
	"MDC": {"name": "MediCore", "sector": "Health", "icon": "💊", "start": 88.0, "vol": 0.18},
	"VRM": {"name": "Vroom Motors", "sector": "Auto", "icon": "🚗", "start": 55.0, "vol": 0.26},
	"PXW": {"name": "Pixelwave Media", "sector": "Media", "icon": "📺", "start": 31.0, "vol": 0.24},
	"GGF": {"name": "Golden Grain Foods", "sector": "Food", "icon": "🌾", "start": 47.0, "vol": 0.10},
	"IVB": {"name": "Ironvault Bank", "sector": "Banking", "icon": "🏦", "start": 73.0, "vol": 0.15},
}
const CRYPTO := {
	"BYC": {"name": "Bytecoin", "icon": "🪙", "start": 30000.0, "vol": 0.6},
	"LMN": {"name": "Lumen", "icon": "💠", "start": 1800.0, "vol": 0.75},
	"MFS": {"name": "Moonfish", "icon": "🐟", "start": 0.05, "vol": 1.2},
}
const PROPERTY_TYPES := [
	{"type": "Studio condo", "icon": "🏢", "base": 140000, "rent": 11000},
	{"type": "Duplex", "icon": "🏘️", "base": 290000, "rent": 23000},
	{"type": "Suburban house", "icon": "🏡", "base": 360000, "rent": 26000},
	{"type": "Downtown loft", "icon": "🌆", "base": 520000, "rent": 38000},
	{"type": "Beach house", "icon": "🏖️", "base": 950000, "rent": 62000},
	{"type": "Apartment building", "icon": "🏬", "base": 2400000, "rent": 190000},
	{"type": "Private island", "icon": "🏝️", "base": 18000000, "rent": 0},
]
const SHOP := [
	{"cat": "Jewelry", "name": "Gold ring", "icon": "💍", "price": 1200, "vol": 0.03},
	{"cat": "Jewelry", "name": "Diamond necklace", "icon": "💎", "price": 18000, "vol": 0.04},
	{"cat": "Jewelry", "name": "Luxury watch", "icon": "⌚", "price": 26000, "vol": 0.06},
	{"cat": "Art", "name": "Painting by a rising artist", "icon": "🖼️", "price": 5000, "vol": 0.45},
	{"cat": "Art", "name": "Classic oil painting", "icon": "🖼️", "price": 240000, "vol": 0.12},
	{"cat": "Art", "name": "Marble sculpture", "icon": "🗿", "price": 60000, "vol": 0.1},
	{"cat": "Collectibles", "name": "Rare trading card", "icon": "🃏", "price": 900, "vol": 0.5},
	{"cat": "Collectibles", "name": "Vintage comic book", "icon": "📚", "price": 3200, "vol": 0.25},
	{"cat": "Collectibles", "name": "Limited-edition sneakers", "icon": "👟", "price": 650, "vol": 0.35},
	{"cat": "Collectibles", "name": "Rare coin", "icon": "🪙", "price": 2100, "vol": 0.15},
	{"cat": "Collectibles", "name": "Signed guitar", "icon": "🎸", "price": 14000, "vol": 0.2},
	{"cat": "Vehicles", "name": "Classic car", "icon": "🚘", "price": 85000, "vol": 0.1},
	{"cat": "Vehicles", "name": "Yacht", "icon": "🛥️", "price": 1500000, "vol": 0.08},
	{"cat": "Vehicles", "name": "Private jet", "icon": "🛩️", "price": 9000000, "vol": 0.07},
]


func _cost() -> float:
	return float(ContentDB.country(GameState.player.get("country", "us")).get("cost", 1.0)) * Places.housing_mult()


func init_world() -> void:
	var w := GameState.world
	w["stocks"] = {}
	w["crypto"] = {}
	w["change"] = {}
	for s in STOCKS.keys():
		w["stocks"][s] = STOCKS[s]["start"] * randf_range(0.8, 1.2)
		w["change"][s] = 0.0
	for c in CRYPTO.keys():
		w["crypto"][c] = CRYPTO[c]["start"] * randf_range(0.6, 1.4)
		w["change"][c] = 0.0
	w["market_mood"] = "steady"
	w["listings"] = {}


# ---------------------------------------------------------------- yearly

func yearly() -> void:
	var p := GameState.player
	_yearly_market()
	if int(p["savings"]) > 0:
		var interest := int(int(p["savings"]) * 0.025)
		p["savings"] = int(p["savings"]) + interest
	_yearly_properties()
	_yearly_possessions()


func _yearly_market() -> void:
	var w := GameState.world
	var roll := randf()
	var mood := "steady"
	var shock := 0.0
	if roll < 0.06:
		mood = "crash"
		shock = randf_range(-0.42, -0.22)
	elif roll < 0.13:
		mood = "boom"
		shock = randf_range(0.18, 0.35)
	shock += World.market_shock()
	w["market_mood"] = mood
	var owns_any: bool = not GameState.player["stocks"].is_empty() or not GameState.player["crypto"].is_empty()
	for s in STOCKS.keys():
		var ch := randfn(0.07, float(STOCKS[s]["vol"])) + shock
		ch = clampf(ch, -0.75, 1.5)
		w["stocks"][s] = maxf(0.5, float(w["stocks"][s]) * (1.0 + ch))
		w["change"][s] = ch
	for c in CRYPTO.keys():
		var ch2 := randfn(0.15, float(CRYPTO[c]["vol"])) + shock * 1.5
		if c == "MFS" and randf() < 0.05:
			ch2 = -0.97
		ch2 = clampf(ch2, -0.97, 6.0)
		w["crypto"][c] = maxf(0.0001, float(w["crypto"][c]) * (1.0 + ch2))
		w["change"][c] = ch2
	if mood == "crash":
		GameState.add_log("The stock market crashed this year." + (" My portfolio took a beating." if owns_any else ""))
		if owns_any:
			GameState.apply_effects({"stress": 8, "happiness": -4})
	elif mood == "boom" and owns_any:
		GameState.add_log("The markets boomed this year. My portfolio loved it.")
		GameState.apply_effects({"happiness": 4})


func _yearly_properties() -> void:
	var p := GameState.player
	var income := 0
	for pr in p["properties"]:
		pr["value"] = int(int(pr["value"]) * (1.0 + randfn(0.03, 0.05)))
		pr["condition"] = maxf(0.0, float(pr["condition"]) - randf_range(4.0, 10.0))
		var tid: String = pr.get("tenant", "")
		if tid != "" and GameState.npcs.has(tid) and GameState.npcs[tid]["alive"]:
			var t: Dictionary = GameState.npcs[tid]
			if float(pr["condition"]) < 35 and randf() < 0.4:
				GameState.add_log("%s moved out of my %s, complaining it's falling apart." % [t["first"], pr["type"].to_lower()])
				t["relation"] = "former_tenant"
				pr["tenant"] = ""
				continue
			if randf() < 0.1:
				GameState.add_log("%s paid rent late on my %s again." % [t["first"], pr["type"].to_lower()])
				income += int(int(pr["rent"]) * 0.5)
			else:
				income += int(pr["rent"])
		elif int(pr["rent"]) > 0 and randf() < 0.5:
			find_tenant(pr, false)
		var upkeep := int(int(pr["value"]) * 0.012)
		income -= upkeep
	if not p["properties"].is_empty():
		p["money"] = int(p["money"]) + income
		GameState.add_log("My properties brought in %s after upkeep." % GameState.fmt_money(income))


func _yearly_possessions() -> void:
	for it in GameState.player["possessions"]:
		var ch := randfn(0.02, float(it.get("vol", 0.1)))
		it["value"] = maxi(10, int(int(it["value"]) * (1.0 + clampf(ch, -0.6, 2.0))))
		if ch > 0.6:
			GameState.add_log("My %s shot up in value. It's worth %s now." % [it["name"].to_lower(), GameState.fmt_money(int(it["value"]))])


# ---------------------------------------------------------------- values

func investments_value() -> int:
	var w := GameState.world
	var p := GameState.player
	if w.is_empty() or p.is_empty():
		return 0
	var v := 0.0
	for s in p.get("stocks", {}).keys():
		v += float(p["stocks"][s]) * float(w["stocks"].get(s, 0.0))
	for c in p.get("crypto", {}).keys():
		v += float(p["crypto"][c]) * float(w["crypto"].get(c, 0.0))
	return int(v)


func properties_value() -> int:
	var v := 0
	for pr in GameState.player.get("properties", []):
		v += int(pr["value"])
	return v


func possessions_value() -> int:
	var v := 0
	for it in GameState.player.get("possessions", []):
		v += int(it["value"])
	return v


func holding_value(kind: String, sym: String) -> int:
	var table: Dictionary = GameState.player["stocks" if kind == "stock" else "crypto"]
	var prices: Dictionary = GameState.world["stocks" if kind == "stock" else "crypto"]
	return int(float(table.get(sym, 0.0)) * float(prices.get(sym, 0.0)))


static func fmt_price(v: float) -> String:
	if v >= 1000:
		return GameState.fmt_money(int(v))
	if v >= 1:
		return "$%.2f" % v
	return "$%.4f" % v


# ---------------------------------------------------------------- actions

func deposit(amount: int) -> void:
	var p := GameState.player
	amount = mini(amount, int(p["money"]))
	if amount <= 0:
		EventEngine.push_info("🏦", "Savings", "You don't have any cash to deposit.")
		return
	p["money"] = int(p["money"]) - amount
	p["savings"] = int(p["savings"]) + amount
	EventEngine.push_info("🏦", "Savings", "I deposited %s into savings. It earns 2.5%% a year." % GameState.fmt_money(amount))


func withdraw(amount: int) -> void:
	var p := GameState.player
	amount = mini(amount, int(p["savings"]))
	if amount <= 0:
		return
	p["savings"] = int(p["savings"]) - amount
	p["money"] = int(p["money"]) + amount
	EventEngine.push_info("🏦", "Savings", "I withdrew %s from savings." % GameState.fmt_money(amount))


func buy(kind: String, sym: String, dollars: int) -> void:
	var p := GameState.player
	if int(p["age"]) < 18:
		EventEngine.push_info("📈", "Investing", "You need to be 18 to open a brokerage account.")
		return
	if int(p["money"]) < dollars:
		EventEngine.push_info("💸", "Investing", "You don't have %s in cash." % GameState.fmt_money(dollars))
		return
	var price := float(GameState.world["stocks" if kind == "stock" else "crypto"][sym])
	var table: Dictionary = p["stocks" if kind == "stock" else "crypto"]
	table[sym] = float(table.get(sym, 0.0)) + dollars / price
	p["money"] = int(p["money"]) - dollars
	var nm: String = (STOCKS if kind == "stock" else CRYPTO)[sym]["name"]
	GameState.counter("trades")
	EventEngine.push_info("📈", nm, "I invested %s in %s at %s." % [GameState.fmt_money(dollars), nm, fmt_price(price)])


func sell_all(kind: String, sym: String) -> void:
	var p := GameState.player
	var table: Dictionary = p["stocks" if kind == "stock" else "crypto"]
	if not table.has(sym):
		return
	var value := holding_value(kind, sym)
	table.erase(sym)
	p["money"] = int(p["money"]) + value
	var nm: String = (STOCKS if kind == "stock" else CRYPTO)[sym]["name"]
	EventEngine.push_info("💵", nm, "I sold all my %s for %s." % [nm, GameState.fmt_money(value)])


func listings() -> Array:
	var w := GameState.world
	var key := str(int(GameState.player["age"]))
	if w.get("listings", {}).has(key):
		return w["listings"][key]
	var out: Array = []
	var pool := PROPERTY_TYPES.duplicate()
	pool.shuffle()
	for t in pool.slice(0, 5):
		var f := randf_range(0.85, 1.2)
		var price := int(int(t["base"]) * _cost() * f)
		out.append({"type": t["type"], "icon": "@" + Icons.for_property(str(t["type"]), price),
			"emoji": t["icon"], "price": price,
			"rent": int(int(t["rent"]) * _cost() * randf_range(0.9, 1.15)), "condition": randf_range(55, 100)})
	w["listings"] = {key: out}
	return out


func buy_property(idx: int) -> void:
	var p := GameState.player
	var l: Dictionary = listings()[idx]
	if int(p["age"]) < 18:
		return
	if int(p["money"]) < int(l["price"]):
		EventEngine.push_info("💸", l["type"], "You need %s in cash to buy this." % GameState.fmt_money(int(l["price"])))
		return
	p["money"] = int(p["money"]) - int(l["price"])
	var pr := {"type": l["type"], "icon": l["icon"], "emoji": l.get("emoji", "🏠"), "value": int(l["price"]), "rent": int(l["rent"]), "condition": float(l["condition"]), "tenant": ""}
	p["properties"].append(pr)
	listings().remove_at(idx)
	GameState.counter("properties_bought")
	if l["type"] == "Private island":
		GameState.add_milestone(p["age"], "bought a private island")
		GameState.set_flag("island_owner")
	elif p["properties"].size() == 1:
		GameState.add_milestone(p["age"], "became a landlord")
	var changes := GameState.apply_effects({"happiness": 6})
	GameState.add_log("I bought a %s for %s." % [l["type"].to_lower(), GameState.fmt_money(int(l["price"]))])
	EventEngine.push_info(str(l.get("emoji", "🏠")), "Property bought", "I bought a %s for %s." % [l["type"].to_lower(), GameState.fmt_money(int(l["price"]))], changes)


func find_tenant(pr: Dictionary, announce: bool = true) -> void:
	if int(pr["rent"]) <= 0:
		if announce:
			EventEngine.push_info(str(pr.get("emoji", "🏠")), pr["type"], "This isn't a rental. Enjoy it yourself.")
		return
	var tid := GameState.create_npc("tenant", {"age": randi_range(22, 70), "closeness": 50})
	pr["tenant"] = tid
	var t: Dictionary = GameState.npcs[tid]
	GameState.add_log("%s moved into my %s." % [GameState.full_name(tid), pr["type"].to_lower()])
	if announce:
		EventEngine.push_info("🔑", "New tenant", "%s signed a lease for your %s at %s a year." % [GameState.full_name(tid), pr["type"].to_lower(), GameState.fmt_money(int(pr["rent"]))])


func renovate(pr: Dictionary) -> void:
	var p := GameState.player
	var cost := int(int(pr["value"]) * 0.08)
	if int(p["money"]) < cost:
		EventEngine.push_info("💸", "Renovation", "Renovating costs %s." % GameState.fmt_money(cost))
		return
	p["money"] = int(p["money"]) - cost
	pr["condition"] = 100.0
	pr["value"] = int(int(pr["value"]) * 1.1)
	GameState.add_log("I renovated my %s." % pr["type"].to_lower())
	EventEngine.push_info("🔨", "Renovation", "I spent %s renovating my %s. It's worth %s now." % [GameState.fmt_money(cost), pr["type"].to_lower(), GameState.fmt_money(int(pr["value"]))])


func raise_rent(pr: Dictionary) -> void:
	pr["rent"] = int(int(pr["rent"]) * 1.1)
	var tid: String = pr.get("tenant", "")
	if tid != "" and GameState.npcs.has(tid):
		GameState.change_closeness(tid, -15)
		if randf() < 0.3:
			GameState.npcs[tid]["relation"] = "former_tenant"
			pr["tenant"] = ""
			EventEngine.push_info("📄", "Rent increase", "I raised the rent to %s. My tenant moved out in protest." % GameState.fmt_money(int(pr["rent"])))
			return
	EventEngine.push_info("📄", "Rent increase", "I raised the rent on my %s to %s a year." % [pr["type"].to_lower(), GameState.fmt_money(int(pr["rent"]))])


func evict(pr: Dictionary) -> void:
	var tid: String = pr.get("tenant", "")
	if tid == "" or not GameState.npcs.has(tid):
		return
	var nm := GameState.full_name(tid)
	GameState.npcs[tid]["relation"] = "former_tenant"
	GameState.change_closeness(tid, -40)
	pr["tenant"] = ""
	GameState.apply_effects({"karma": -3})
	GameState.add_log("I evicted %s from my %s." % [nm, pr["type"].to_lower()])
	EventEngine.push_info("🚪", "Eviction", "I evicted %s." % nm)


func sell_property(idx: int) -> void:
	var p := GameState.player
	var pr: Dictionary = p["properties"][idx]
	var price := int(int(pr["value"]) * randf_range(0.92, 1.12))
	var tid: String = pr.get("tenant", "")
	if tid != "" and GameState.npcs.has(tid):
		GameState.npcs[tid]["relation"] = "former_tenant"
	p["money"] = int(p["money"]) + price
	p["properties"].remove_at(idx)
	GameState.add_log("I sold my %s for %s." % [pr["type"].to_lower(), GameState.fmt_money(price)])
	EventEngine.push_info("💲", "Property sold", "I sold my %s for %s." % [pr["type"].to_lower(), GameState.fmt_money(price)])


func buy_item(idx: int) -> void:
	var p := GameState.player
	var s: Dictionary = SHOP[idx]
	var price := int(int(s["price"]) * _cost())
	if int(p["age"]) < 16:
		EventEngine.push_info("🛍️", "Shopping", "You're too young for this store.")
		return
	if int(p["money"]) < price:
		EventEngine.push_info("💸", s["name"], "That costs %s." % GameState.fmt_money(price))
		return
	p["money"] = int(p["money"]) - price
	p["possessions"].append({"name": s["name"], "icon": s["icon"], "cat": s["cat"], "value": price, "vol": s["vol"], "bought": price, "heirloom": false})
	Grit.habit("shopping", 12)
	var changes := GameState.apply_effects({"happiness": 3 + mini(8, price / 50000)})
	GameState.add_log("I bought a %s for %s." % [s["name"].to_lower(), GameState.fmt_money(price)])
	EventEngine.push_info(s["icon"], "New purchase", "I bought a %s for %s." % [s["name"].to_lower(), GameState.fmt_money(price)], changes)


func sell_item(idx: int) -> void:
	var p := GameState.player
	var it: Dictionary = p["possessions"][idx]
	if it.get("stolen", false):
		EventEngine.push_info("🕶️", "Hot item", "No legit dealer will touch a stolen %s. Try the Black Market (Activities → Crime)." % it["name"].to_lower())
		return
	if it.get("fake", false):
		p["possessions"].remove_at(idx)
		var junk := randi_range(20, 80)
		p["money"] = int(p["money"]) + junk
		GameState.add_log("I tried to sell my %s. The dealer spotted it was a fake." % it["name"].to_lower())
		EventEngine.push_info("🔍", "It's a fake!", "The dealer took one look through a loupe and laughed. My %s was a knockoff. He gave me %s for the parts." % [it["name"].to_lower(), GameState.fmt_money(junk)], GameState.apply_effects({"happiness": -4}))
		return
	var price := int(int(it["value"]) * randf_range(0.85, 1.0))
	p["money"] = int(p["money"]) + price
	p["possessions"].remove_at(idx)
	if it.get("heirloom", false):
		GameState.apply_effects({"happiness": -3})
	GameState.add_log("I sold my %s for %s." % [it["name"].to_lower(), GameState.fmt_money(price)])
	EventEngine.push_info("💲", "Sold", "I sold my %s for %s." % [it["name"].to_lower(), GameState.fmt_money(price)])
