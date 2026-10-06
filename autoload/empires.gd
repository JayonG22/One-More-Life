extends Node

## Business, Black Market, Cult, Zoo and Outdoors. Each one reads from and feeds
## into careers, fame, heat, the people you know, property and possessions.

const KINDS := ["fishing", "biz_pitch", "cult_sermon", "brawl", "hunt"]

# ================================================================ data

const INDUSTRIES := {
	"restaurant": {"name": "Restaurant", "icon": "🍽️", "cost": 60000, "rev": 220000, "margin": 0.15, "vol": 0.2, "job": "chef", "career": "", "majors": ["culinary"], "names": ["The Golden Fork", "Ember & Oak", "Little Saffron", "Nonna's Table", "Smoke House"]},
	"tech": {"name": "Tech Startup", "icon": "💻", "cost": 40000, "rev": 140000, "margin": 0.3, "vol": 0.6, "job": "programmer", "career": "", "majors": ["computer_science", "engineering", "game_dev"], "names": ["Cloudnest", "Bytewise", "Quantaloop", "Nimbly", "Stackfire"]},
	"fashion": {"name": "Fashion Label", "icon": "👗", "cost": 80000, "rev": 240000, "margin": 0.2, "vol": 0.35, "job": "artist", "career": "model", "majors": ["graphic_design"], "names": ["Maison Velour", "Threadline", "NOIR/BLANC", "Silk Road Atelier", "Kinetic"]},
	"label": {"name": "Record Label", "icon": "💿", "cost": 120000, "rev": 300000, "margin": 0.22, "vol": 0.45, "job": "musician", "career": "musician", "majors": ["music"], "names": ["Vinyl Heart Records", "Loud Room", "Bassline Music", "Midnight Tape", "Echo Chamber"]},
	"studio": {"name": "Film Studio", "icon": "🎬", "cost": 400000, "rev": 1000000, "margin": 0.15, "vol": 0.5, "job": "producer", "career": "director", "alt": "actor", "majors": ["communications"], "names": ["Silverlight Pictures", "Northstar Films", "Paper Moon Studios", "Crimson Reel", "Lighthouse Pictures"]},
	"gym": {"name": "Gym Chain", "icon": "🏋️", "cost": 90000, "rev": 250000, "margin": 0.2, "vol": 0.2, "job": "", "career": "athlete", "alt": "fighter", "majors": [], "names": ["Iron Temple", "PulseFit", "Grit Gym", "Titan Athletics", "Forge Fitness"]},
	"security": {"name": "Private Security Firm", "icon": "🛡️", "cost": 150000, "rev": 420000, "margin": 0.2, "vol": 0.25, "job": "cop", "career": "agent", "majors": ["criminal_justice"], "names": ["Blackwall Security", "Sentinel Group", "Aegis Protection", "Watchtower", "Onyx Guard"]},
	"aerospace": {"name": "Private Space Company", "icon": "🚀", "cost": 2000000, "rev": 3500000, "margin": 0.15, "vol": 0.7, "job": "engineer", "career": "astronaut", "majors": ["engineering", "phd"], "names": ["Starward", "Apogee Dynamics", "Orbital Forge", "Helix Aerospace", "Farside"]},
	"construction": {"name": "Construction Company", "icon": "🏗️", "cost": 200000, "rev": 650000, "margin": 0.14, "vol": 0.25, "job": "electrician", "career": "mafia", "majors": ["architecture", "engineering"], "names": ["Keystone Builders", "Granite & Sons", "Summit Construction", "Bedrock Group", "Ironbeam"]},
	"dealership": {"name": "Car Dealership", "icon": "🚗", "cost": 250000, "rev": 850000, "margin": 0.08, "vol": 0.2, "job": "mechanic", "career": "", "majors": ["business"], "names": ["Premier Motors", "Highway Auto", "Redline Cars", "Crown Motors", "Easy Drive"]},
	"consulting": {"name": "Political Consultancy", "icon": "🏛️", "cost": 30000, "rev": 160000, "margin": 0.35, "vol": 0.3, "job": "lawyer", "career": "politician", "majors": ["political_science", "law", "economics"], "names": ["Capitol Strategies", "Ballot & Co.", "Keystone Advisors", "Frontline Consulting", "Mandate Group"]},
	"clinic": {"name": "Private Clinic", "icon": "🏥", "cost": 300000, "rev": 700000, "margin": 0.18, "vol": 0.15, "job": "doctor", "career": "", "majors": ["medicine", "nursing", "pharmacy", "dentistry"], "names": ["Evergreen Clinic", "Harbor Health", "Clearview Medical", "Oakridge Care", "Northside Clinic"]},
}

const DOCTRINES := {
	"stars": {"name": "The Star Children", "icon": "🛸", "blurb": "Beings from the stars are coming for the chosen few", "recruit": 1.0, "donate": 1.0, "heat": 1.0, "devotion": 1.1},
	"wellness": {"name": "Pure Light Wellness", "icon": "🧘", "blurb": "Juice cleanses, crystals and total surrender", "recruit": 1.4, "donate": 0.8, "heat": 0.5, "devotion": 0.8},
	"doomsday": {"name": "The Final Dawn", "icon": "☄️", "blurb": "The end is near. Only the faithful survive", "recruit": 0.7, "donate": 1.3, "heat": 1.8, "devotion": 1.4},
	"prosperity": {"name": "Church of Abundance", "icon": "💰", "blurb": "Give and you shall receive (mostly me)", "recruit": 1.0, "donate": 1.8, "heat": 1.2, "devotion": 0.9},
	"nature": {"name": "Children of the Grove", "icon": "🌿", "blurb": "Return to the earth. Live off the land", "recruit": 1.0, "donate": 0.7, "heat": 0.6, "devotion": 1.2},
}

const ZOO_ANIMALS := {
	"goat": {"name": "Goats", "icon": "🐐", "price": 300, "draw": 1, "care": 1, "danger": 0.0},
	"flamingo": {"name": "Flamingos", "icon": "🦩", "price": 2500, "draw": 3, "care": 1, "danger": 0.0},
	"penguin": {"name": "Penguins", "icon": "🐧", "price": 8000, "draw": 6, "care": 2, "danger": 0.0},
	"zebra": {"name": "Zebras", "icon": "🦓", "price": 15000, "draw": 7, "care": 2, "danger": 0.05},
	"bear": {"name": "Bears", "icon": "🐻", "price": 30000, "draw": 10, "care": 3, "danger": 0.3},
	"giraffe": {"name": "Giraffes", "icon": "🦒", "price": 40000, "draw": 10, "care": 3, "danger": 0.02},
	"lion": {"name": "Lions", "icon": "🦁", "price": 60000, "draw": 14, "care": 4, "danger": 0.6},
	"gorilla": {"name": "Gorillas", "icon": "🦍", "price": 90000, "draw": 13, "care": 4, "danger": 0.3},
	"elephant": {"name": "Elephants", "icon": "🐘", "price": 120000, "draw": 16, "care": 5, "danger": 0.15},
	"panda": {"name": "Giant pandas", "icon": "🐼", "price": 500000, "draw": 25, "care": 5, "danger": 0.02},
	"tiger": {"name": "Tigers", "icon": "🐅", "price": 25000, "draw": 15, "care": 4, "danger": 0.7, "illegal": true},
	"chimp": {"name": "Chimpanzees", "icon": "🐒", "price": 18000, "draw": 11, "care": 3, "danger": 0.35, "illegal": true},
	"komodo": {"name": "Komodo dragons", "icon": "🦎", "price": 30000, "draw": 12, "care": 3, "danger": 0.5, "illegal": true},
	"python": {"name": "Reticulated pythons", "icon": "🐍", "price": 6000, "draw": 6, "care": 2, "danger": 0.3, "illegal": true},
	"rhino": {"name": "White rhinos", "icon": "🦏", "price": 150000, "draw": 20, "care": 5, "danger": 0.25, "illegal": true},
	"redpanda": {"name": "Red pandas", "icon": "🦊", "price": 22000, "draw": 9, "care": 2, "danger": 0.0, "illegal": true},
	"petting": {"name": "Petting zoo pets", "icon": "🐾", "price": 0, "draw": 1, "care": 1, "danger": 0.0},
	"rescue": {"name": "Rescued wildlife", "icon": "🦌", "price": 0, "draw": 2, "care": 1, "danger": 0.02},
}

const WILDLIFE := [
	["🦌", "White-tailed deer"], ["🦊", "Red fox"], ["🦉", "Great horned owl"], ["🐻", "Black bear"], ["🦅", "Bald eagle"],
	["🐺", "Gray wolf"], ["🦫", "Beaver"], ["🦝", "Raccoon"], ["🐿️", "Red squirrel"], ["🦔", "Hedgehog"],
	["🐍", "Rattlesnake"], ["🦎", "Collared lizard"], ["🐸", "Tree frog"], ["🦋", "Monarch butterfly"], ["🦇", "Brown bat"],
	["🐗", "Wild boar"], ["🦡", "Badger"], ["🦬", "Bison"], ["🐢", "Box turtle"], ["🦆", "Wood duck"],
	["🐇", "Snowshoe hare"], ["🦃", "Wild turkey"], ["🦨", "Skunk"], ["🐆", "Mountain lion"],
]
const FISH := [
	["🐟", "Bluegill", 0.0], ["🐟", "Yellow perch", 0.0], ["🐠", "Rainbow trout", 0.3], ["🐟", "Largemouth bass", 0.35],
	["🐡", "Channel catfish", 0.45], ["🐟", "Northern pike", 0.6], ["🐠", "Chinook salmon", 0.7], ["🐟", "Golden trout", 0.85], ["🦈", "Lake sturgeon", 0.93],
]
const SEA_FISH := [
	["🐟", "Mackerel", 0.0], ["🐠", "Mahi-mahi", 0.3], ["🐟", "Yellowfin tuna", 0.5], ["🐡", "Grouper", 0.6],
	["🗡️", "Swordfish", 0.78], ["🐟", "Blue marlin", 0.88], ["🦈", "Mako shark", 0.95],
]
const FINDS := [["🪨", "Geode", 300], ["🏹", "Ancient arrowhead", 1200], ["🪙", "Gold nugget", 4000], ["💎", "Raw sapphire", 8000], ["☄️", "Meteorite", 15000], ["🦴", "Dinosaur fossil", 25000]]
const CAVE_FINDS := [["🔮", "Giant crystal", 12000], ["🏺", "Ancient pottery", 9000], ["🪙", "Sunken gold coins", 20000], ["💀", "Prehistoric skull", 40000], ["🗿", "Carved idol", 30000]]
const BM_GOODS := [
	["🖼️", "Hot painting", 60000, 0.25], ["💎", "Smuggled diamonds", 30000, 0.3], ["⌚", "Hot designer watch", 20000, 0.3],
	["🏺", "Looted antiquity", 80000, 0.25], ["🎻", "Stolen violin", 45000, 0.3],
]


# ================================================================ helpers

func handles(kind: String) -> bool:
	return KINDS.has(kind)


func _cost(v: float) -> int:
	return int(v * float(ContentDB.country(GameState.player.get("country", "us")).get("cost", 1.0)) * Places.cost_mult())


func _t() -> bool:
	return Careers._t()


func _done(icon: String, title_txt: String, text: String, effects: Dictionary = {}) -> void:
	Careers._done(icon, title_txt, text, effects)


func _info(icon: String, title_txt: String, text: String) -> void:
	EventEngine.push_info(icon, title_txt, text)


func _pay(amount: int, title_txt: String) -> bool:
	if int(GameState.player["money"]) >= amount:
		return true
	_info("💸", title_txt, "You can't afford that. It costs %s." % GameState.fmt_money(amount))
	return false


func _has_major(list: Array) -> bool:
	for d in GameState.player["education"]["degrees"]:
		if list.has(d["major"]):
			return true
	return false


func _mood_mult() -> float:
	match GameState.world.get("market_mood", "steady"):
		"crash": return 0.7
		"boom": return 1.25
	return 1.0


## Adults you know who could work for you or join you.
func candidates(exclude: Array = []) -> Array:
	var out: Array = []
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"] or n.get("species", "human") != "human" or int(n["age"]) < 18 or int(n["age"]) > 75:
			continue
		if exclude.has(id) or n["relation"] in ["ex", "enemy", "former_tenant", "tenant", "mafia_boss"]:
			continue
		out.append(id)
	out.sort_custom(func(a, b): return int(GameState.npcs[a]["closeness"]) > int(GameState.npcs[b]["closeness"]))
	return out.slice(0, 14)


func _employ(id: String, title_txt: String) -> void:
	var n: Dictionary = GameState.npcs[id]
	if n.has("job") and str(n["job"].get("key", "")) != "employee":
		n["prev_job"] = n["job"]
	n["job"] = {"title": title_txt, "key": "employee"}


func _release(id: String) -> void:
	if not GameState.npcs.has(id):
		return
	var n: Dictionary = GameState.npcs[id]
	if n.has("prev_job"):
		n["job"] = n["prev_job"]
		n.erase("prev_job")
	else:
		n.erase("job")
	Web.ensure_job(id)


## Total worth of everything here, for net worth and the obituary.
func net_value(p: Dictionary = {}) -> int:
	if p.is_empty(): p=GameState.player
	var v := 0
	var b: Dictionary = p.get("business", {})
	if not b.is_empty():
		v += int(float(b["value"]) * float(b["stake"])) - int(b.get("debt", 0))
	var z: Dictionary = p.get("zoo", {})
	if not z.is_empty():
		v += zoo_value(p)
	return v


# ================================================================ yearly

func yearly() -> void:
	var p := GameState.player
	if GameState.in_prison():
		if not p["business"].is_empty() and randf() < 0.25:
			var b: Dictionary = p["business"]
			b["quality"] = maxf(5.0, float(b["quality"]) - 10.0)
			GameState.add_log("With me locked up, %s drifted without a boss." % b["name"])
	if not p["business"].is_empty():
		_business_yearly()
	if not p["cult"].is_empty():
		_cult_yearly()
	if not p["zoo"].is_empty():
		_zoo_yearly()
	_exotic_pets_yearly()
	_forgery_yearly()


# ================================================================ BUSINESS

func edge(ind_id: String) -> Dictionary:
	var ind: Dictionary = INDUSTRIES[ind_id]
	var e := 0.0
	var why: Array = []
	if ind.get("career", "") != "" and (Careers.past(ind["career"]) or Careers.has_career(ind["career"])):
		e += 0.35
		why.append("your %s career" % Careers.CAREERS[ind["career"]]["name"].to_lower())
	elif ind.get("alt", "") != "" and (Careers.past(ind["alt"]) or Careers.has_career(ind["alt"])):
		e += 0.2
		why.append("your %s career" % Careers.CAREERS[ind["alt"]]["name"].to_lower())
	if _has_major(ind.get("majors", [])):
		e += 0.15
		why.append("your degree")
	if ind.get("job", "") != "":
		var c := Web.contact([ind["job"]], 50)
		if c != "":
			e += 0.1
			why.append(GameState.npc(c)["first"] + " (" + Web.job_title(c).to_lower() + ")")
	if GameState.has_job() and str(GameState.player["job"].get("field", "")).to_lower().find(ind["name"].split(" ")[0].to_lower()) != -1:
		e += 0.1
		why.append("your job")
	return {"edge": e, "why": why}


func start_business(ind_id: String) -> void:
	var p := GameState.player
	var ind: Dictionary = INDUSTRIES[ind_id]
	var cost := _cost(ind["cost"])
	if int(p["age"]) < 18:
		_info("📈", "Business", "You must be 18 to start a company.")
		return
	if not p["business"].is_empty():
		_info("📈", "Business", "You already run %s." % p["business"]["name"])
		return
	if not _pay(cost, ind["name"]):
		return
	if _t(): return
	var e := edge(ind_id)
	var nm: String = ind["names"][randi() % ind["names"].size()]
	var fmap := {"restaurant": "Food", "tech": "Tech", "fashion": "Design", "label": "Media", "studio": "Media"}
	if randf() < 0.55:
		nm = Names.company(str(fmap.get(ind_id, "Business")), str(p.get("country", "")))
	elif randf() < 0.3:
		nm = "%s %s" % [p["last"], ["Group", "& Co.", "Holdings", "Enterprises", "Brothers", "& Daughters", "& Sons", "Ltd"][randi() % 8]]
	p["money"] = int(p["money"]) - cost
	p["business"] = {"ind": ind_id, "name": nm, "founded": GameState.year_now(), "quality": 30.0 + float(e["edge"]) * 60.0,
		"uid":FamilyChronicle.identity(p)+":business:"+str(GameState.get_counter("businesses")+1),
		"marketing": 10.0, "staff": 2, "crew": [], "value": cost, "rev": 0, "profit": 0, "public": false, "stake": 1.0,
		"price": 0.0, "symbol": "", "cooked": false, "debt": 0, "years": 0, "labor": false, "best": 0}
	Journey.modules["operations"].st()
	Journey.modules["operations"].supply.launch(p["business"],cost)
	GameState.add_milestone(p["age"], "founded %s" % nm)
	GameState.counter("businesses")
	var text := "I founded %s, a %s, for %s." % [nm, ind["name"].to_lower(), GameState.fmt_money(cost)]
	if not e["why"].is_empty():
		text += "\n\nMy edge: " + ", ".join(e["why"]) + "."
	_done(ind["icon"], "Open for business!", text, {"happiness": 10, "stress": 8})


func biz_actions() -> Array:
	var p := GameState.player
	var b: Dictionary = p["business"]
	if b.is_empty():
		return []
	var out: Array = []
	out.append({"id": "b_improve", "icon": "🛠️", "name": "Improve the product", "sub": "Quality %d%%" % int(b["quality"])})
	out.append({"id": "b_market", "icon": "📣", "name": "Marketing campaign", "sub": "%s · reach %d%%" % [GameState.fmt_money(_market_cost()), int(b["marketing"])]})
	if float(p["fame"]) >= 30:
		out.append({"id": "b_star", "icon": "⭐", "name": "Star in your own ads", "sub": "Your fame sells it for free"})
	out.append({"id": "b_hire", "icon": "🧑‍💼", "name": "Hire staff", "sub": "%d staff · %s each a year" % [int(b["staff"]), GameState.fmt_money(_staff_cost())]})
	if int(b["staff"]) > 0:
		out.append({"id": "b_layoff", "icon": "📉", "name": "Lay off staff", "sub": "Cut costs"})
	out.append({"id": "b_pitch", "icon": "🎤", "name": "Pitch investors", "sub": "Minigame · trade equity for cash" if not b["public"] else "Public companies raise money on the market"})
	var banker := Web.contact(["banker"], 50)
	out.append({"id": "b_loan", "icon": "🏦", "name": "Business loan", "sub": ("%s can fast-track it" % GameState.npc(banker)["first"]) if banker != "" else "Needs good numbers"})
	if int(b["debt"]) > 0:
		out.append({"id": "b_repay", "icon": "💳", "name": "Repay the loan", "sub": "Debt %s" % GameState.fmt_money(int(b["debt"]))})
	out.append({"id": "b_cook", "icon": "📒", "name": "Stop cooking the books" if b["cooked"] else "Cook the books", "sub": "Inflates the value · heat every year" if not b["cooked"] else "Go straight"})
	if Careers.has_career("mafia") or Careers.has_career("hustler") or Careers.past("mafia"):
		out.append({"id": "b_launder", "icon": "🧺", "name": "Launder money", "sub": "Lose heat through the books"})
	if not p["cult"].is_empty():
		out.append({"id": "b_labor", "icon": "🛐", "name": ("Stop using " if b["labor"] else "Put ") + "your followers to work", "sub": "Free staff · karma and heat" if not b["labor"] else "Pay people again"})
	if not b["public"] and int(b["value"]) >= _cost(2000000):
		out.append({"id": "b_ipo", "icon": "🔔", "name": "Go public (IPO)", "sub": "Sell 30% on the stock market"})
	if b["public"]:
		out.append({"id": "b_sell_shares", "icon": "📈", "name": "Sell 10% of your shares", "sub": "You own %d%%" % int(float(b["stake"]) * 100)})
	out.append({"id": "b_sell", "icon": "🤝", "name": "Sell the company", "sub": "1 time · buyer takes contracts · about %s to you" % GameState.fmt_money(int(float(b["value"]) * float(b["stake"])) - int(b["debt"]))})
	out.append({"id": "b_close", "icon": "🔒", "name": "Close the company", "sub": "1 time · stock salvage · supplier cancellation fees"})
	return out


func _market_cost() -> int:
	var b: Dictionary = GameState.player["business"]
	return maxi(_cost(5000), int(int(b.get("rev", 0)) * 0.05))


func _staff_cost() -> int:
	return _cost(12000)


func biz_action(aid: String) -> void:
	var p := GameState.player
	var b: Dictionary = p["business"]
	if b.is_empty():
		return
	var ind: Dictionary = INDUSTRIES[b["ind"]]
	match aid:
		"b_improve":
			if _t(): return
			Grit.habit("workaholic", 6)
			var gain := 4.0 + GameState.stat("smarts") / 20.0 + float(edge(b["ind"])["edge"]) * 10.0 + randf_range(0, 4)
			b["quality"] = minf(100.0, float(b["quality"]) + gain)
			_done(ind["icon"], b["name"], "I spent long nights making %s better. Quality is now %d%%." % [b["name"], int(b["quality"])], {"stress": 4, "smarts": 1})
		"b_market":
			var mc := _market_cost()
			if not _pay(mc, "Marketing"): return
			if _t(): return
			p["money"] = int(p["money"]) - mc
			b["marketing"] = minf(100.0, float(b["marketing"]) + 15.0 + randf_range(0, 10))
			var agent := Web.contact(["agent", "journalist"], 55)
			if agent != "":
				b["marketing"] = minf(100.0, float(b["marketing"]) + 8.0)
			_done("📣", "Campaign launched", "I ran a %s campaign for %s.%s" % [["TV", "billboard", "social media", "radio", "influencer"][randi() % 5], b["name"], (" %s got it extra coverage." % GameState.npc(agent)["first"]) if agent != "" else ""], {"stress": 2})
		"b_star":
			if _t(): return
			b["marketing"] = minf(100.0, float(b["marketing"]) + 10.0 + float(p["fame"]) / 10.0)
			_done("⭐", "Celebrity ad", "I starred in a commercial for my own company. Fans started buying.", {"fame": 1, "happiness": 3})
		"b_hire":
			b["staff"] = int(b["staff"]) + 1
			_done("🧑‍💼", "New hire", "%s hired a new employee. Staff: %d." % [b["name"], int(b["staff"])], {})
		"b_layoff":
			b["staff"] = maxi(0, int(b["staff"]) - 1)
			_done("📉", "Layoffs", "I laid someone off at %s." % b["name"], {"karma": -1, "stress": 2})
		"b_pitch":
			if b["public"]:
				_info("🔔", "Public company", "Your company is public. Its shares trade on the stock market now.")
				return
			if float(b["stake"]) <= 0.35:
				_info("🎤", "Pitch", "You've already sold too much of your company. The investors want a founder with skin in the game.")
				return
			if _t(): return
			Minigames.play("debate", {"skill": GameState.stat("smarts") * 0.6 + float(b["quality"]) * 0.4, "difficulty": 1.0, "flavor": "pitch"}, Callable(Careers, "resolve_play").bind({"kind": "biz_pitch"}))
		"b_loan":
			var banker := Web.contact(["banker"], 50)
			var amount := maxi(_cost(50000), int(int(b["value"]) * 0.4))
			var ok := banker != "" or int(b["profit"]) > 0 or GameState.net_worth() > amount
			if not Grit.credit_ok() and banker == "":
				_info("💳", "Loan denied", "Your credit score is %d (%s). The bank won't lend to you." % [Grit.credit(), Grit.credit_label()])
				return
			if int(b["debt"]) > int(b["value"]):
				ok = false
			if not ok:
				_info("🏦", "Loan denied", "The bank looked at your numbers and said no.")
				return
			b["debt"] = int(b["debt"]) + amount
			p["money"] = int(p["money"]) + amount
			var text := "The bank approved a %s loan for %s." % [GameState.fmt_money(amount), b["name"]]
			if banker != "":
				text = "%s pushed my %s loan through at the bank." % [GameState.full_name(banker), GameState.fmt_money(amount)]
				GameState.change_closeness(banker, 3)
			_done("🏦", "Loan approved", text, {})
		"b_repay":
			var pay := mini(int(b["debt"]), int(p["money"]))
			if pay <= 0:
				_info("💸", "Repay", "You don't have any cash to repay with.")
				return
			b["debt"] = int(b["debt"]) - pay
			p["money"] = int(p["money"]) - pay
			_done("💳", "Loan payment", "I paid %s toward the business loan. %s left." % [GameState.fmt_money(pay), GameState.fmt_money(int(b["debt"]))], {"stress": -3})
		"b_cook":
			b["cooked"] = not b["cooked"]
			if b["cooked"]:
				GameState.set_flag("cooked_books")
				_done("📒", "Creative accounting", "I started cooking the books at %s. On paper, we're booming." % b["name"], {"karma": -6, "heat": 8})
			else:
				GameState.clear_flag("cooked_books")
				_done("📒", "Clean books", "I stopped cooking the books. The real numbers are sobering.", {"karma": 2, "stress": 3})
		"b_launder":
			if _t(): return
			var fee := _cost(8000)
			if not _pay(fee, "Laundering"): return
			p["money"] = int(p["money"]) - fee
			b["cooked"] = true
			GameState.set_flag("cooked_books")
			_done("🧺", "Clean money", "I ran dirty money through %s's books. The trail went cold." % b["name"], {"heat": -18, "karma": -4})
		"b_labor":
			b["labor"] = not b["labor"]
			if b["labor"]:
				_done("🛐", "Divine labor", "My followers now work at %s for free. They call it service." % b["name"], {"karma": -10, "heat": 6})
			else:
				_done("🛐", "Paid again", "I started paying my followers for their work at %s." % b["name"], {"karma": 4})
		"b_ipo":
			if _t(): return
			var raise := int(int(b["value"]) * 0.3)
			b["public"] = true
			b["stake"] = float(b["stake"]) * 0.7
			b["symbol"] = _ticker(b["name"])
			b["price"] = float(b["value"]) / 1000000.0
			p["money"] = int(p["money"]) + raise
			GameState.add_milestone(p["age"], "took %s public" % b["name"])
			_done("🔔", "IPO day!", "%s is now traded on the stock exchange as %s. I rang the opening bell and raised %s." % [b["name"], b["symbol"], GameState.fmt_money(raise)], {"fame": 5, "happiness": 15})
		"b_sell_shares":
			var sell := minf(0.1, float(b["stake"]))
			var cash := int(float(b["value"]) * sell)
			b["stake"] = float(b["stake"]) - sell
			p["money"] = int(p["money"]) + cash
			_done("📈", "Shares sold", "I sold shares of %s for %s. I own %d%% now." % [b["symbol"], GameState.fmt_money(cash), int(float(b["stake"]) * 100)], {})
			if float(b["stake"]) < 0.3 and randf() < 0.5:
				_board_ousts()
		"b_sell":
			if _t(): return
			var price := int(float(b["value"]) * float(b["stake"]) * randf_range(0.85, 1.15)) - int(b["debt"])
			p["money"] = int(p["money"]) + price
			var nm: String = b["name"]
			_transfer_sold_business(b)
			_close_business(false)
			GameState.add_milestone(p["age"], "sold %s" % nm)
			_done("🤝", "Sold!", "I sold %s for %s." % [nm, GameState.fmt_money(price)], {"happiness": 8 if price > 0 else -8})
		"b_close":
			if _t(): return
			var nm2: String = b["name"]
			var debt := int(b["debt"])
			p["money"] = int(p["money"]) - debt
			_close_business()
			_done("🔒", "Closed", "I shut down %s for good.%s" % [nm2, (" I still had to pay back %s." % GameState.fmt_money(debt)) if debt > 0 else ""], {"happiness": -6})


func _ticker(nm: String) -> String:
	var letters := ""
	for ch in nm.to_upper():
		if ch >= "A" and ch <= "Z":
			letters += ch
	if letters.length() < 3:
		letters += "XYZ"
	return letters.substr(0, 1) + letters.substr(letters.length() / 2, 1) + letters.substr(letters.length() - 1, 1)


func _board_ousts() -> void:
	var p := GameState.player
	var b: Dictionary = p["business"]
	var payout := int(float(b["value"]) * float(b["stake"]))
	p["money"] = int(p["money"]) + payout
	var nm: String = b["name"]
	_close_business(false)
	GameState.add_milestone(p["age"], "was ousted from %s by the board" % nm)
	_done("🪑", "Ousted!", "The board of %s voted me out of my own company. They bought out my shares for %s." % [nm, GameState.fmt_money(payout)], {"happiness": -15, "stress": 10})


func _transfer_sold_business(company: Dictionary) -> void:
	var operations=Journey.modules["operations"]
	operations.remember_crew(company,GameState.npcs)
	var packet := company.duplicate(true)
	packet["country"]=GameState.player["country"]; packet["local_cost"]=Places.cost_mult()
	var buyer := GameState.create_npc("friend",{"age":randi_range(30,60),"money":maxi(100000,int(company["value"])),"country":GameState.player["country"]})
	GameState.npc(buyer)["business"]=packet
	FamilyChronicle.remember(buyer,"Bought "+str(company["name"])+" with its stock, staff and supply contracts.","neutral")
	GameState.add_log(GameState.full_name(buyer)+" now owns "+str(company["name"])+" and its supply obligations.")
func _close_business(liquidate: bool = true) -> void:
	var p := GameState.player
	if liquidate and not p["business"].is_empty():
		var receipt: Dictionary=Journey.modules["operations"].supply.liquidation(p["business"])
		p["money"]=int(p["money"])+int(receipt["net"])
		var fees := int(receipt["cancellation"])+int(receipt["customer_fee"])
		if fees>0: Employment.record_expense("Company cancellation costs",fees)
		GameState.add_log("Company exit: cash %s · stock salvage %s · supplier cancellation %s · customer fee %s." % [GameState.fmt_money(receipt["cash"]),GameState.fmt_money(receipt["salvage"]),GameState.fmt_money(receipt["cancellation"]),GameState.fmt_money(receipt["customer_fee"])])
	for id in p["business"].get("crew", []):
		_release(id)
	p["business"] = {}
	GameState.clear_flag("cooked_books")


func hire_known(id: String) -> void:
	var p := GameState.player
	var b: Dictionary = p["business"]
	if b.is_empty() or b["crew"].has(id):
		return
	var n: Dictionary = GameState.npcs[id]
	var perk := Web.perk_text(id)
	var yes := clampf(0.35 + float(n["closeness"]) / 150.0 + (0.2 if Web.job_of(id) in ["none", "retail", "student"] else 0.0), 0.1, 0.95)
	if randf() > yes:
		GameState.change_closeness(id, -3)
		_done("🙅", "Turned down", "%s passed on a job at %s. \"I'm happy where I am.\"" % [n["first"], b["name"]], {})
		return
	b["crew"].append(id)
	var old := Web.job_title(id)
	_employ(id, "Works at " + b["name"])
	GameState.change_closeness(id, 8)
	b["quality"] = minf(100.0, float(b["quality"]) + 3.0 + randf_range(0, 4))
	var text := "%s (%s) joined %s." % [GameState.full_name(id), GameState.relation_label(id).to_lower(), b["name"]]
	if perk != "":
		text += "\n\nThey left their job as a %s, so you lose that connection while they work for you." % old.to_lower()
	_done("🤝", "New team member", text, {"happiness": 3})


func fire_known(id: String) -> void:
	var b: Dictionary = GameState.player["business"]
	if b.is_empty():
		return
	b["crew"].erase(id)
	_release(id)
	GameState.change_closeness(id, -35)
	var n := GameState.npc(id)
	_done("🔥", "Fired", "I fired %s from %s. It got awkward fast." % [n.get("first", "them"), b["name"]], {"stress": 5, "karma": -2})


func business_numbers(b: Dictionary, fame: float, crew: int, cost: float, synergy: float, scene: float, extra_size: float) -> Dictionary:
	var ind: Dictionary=INDUSTRIES[b["ind"]]
	var mods: Dictionary=Journey.modules["operations"].modifiers(b)
	var demand := 0.35+float(b["quality"])/100.0*0.8+float(b["marketing"])/100.0*0.5+fame/100.0*0.6
	var size := 1.0+int(b["staff"])*0.2+crew*0.25+extra_size
	var rev := int(float(ind["rev"])*demand*size*_mood_mult()*synergy*World.biz_mult(b["ind"])*scene*randf_range(1.0-float(ind["vol"]),1.0+float(ind["vol"]))*float(mods["revenue"])*cost)
	var payroll := int(((0 if b["labor"] else int(b["staff"])*12000)+crew*12000)*cost*float(mods["payroll"]))
	var interest := int(int(b["debt"])*0.07)
	var margin := clampf(float(ind["margin"])+float(b["quality"])/400.0+float(mods["margin"]),0.01,0.70)
	var supply=Journey.modules["operations"].supply
	var inventory: Dictionary=supply.plan(b,rev,cost,margin,payroll,interest,GameState.year_now())
	return {"rev":inventory["rev"],"payroll":payroll,"interest":interest,"profit":inventory["profit"],"draw":inventory["draw"],"inventory":inventory,"mods":mods}

func settle_business(b: Dictionary, numbers: Dictionary, cost: float) -> void:
	Journey.modules["operations"].supply.settle(b,numbers["inventory"])
	b["years"]=int(b["years"])+1; b["rev"]=int(numbers["rev"]); b["profit"]=int(numbers["profit"]); b["best"]=maxi(int(b["best"]),int(numbers["profit"]))
	b["quality"]=clampf(float(b["quality"])-randf_range(2.0,5.0)+float(numbers["mods"]["quality"]),5,100)
	b["marketing"]=maxf(0,float(b["marketing"])*0.75)
	var val := maxf(float(numbers["rev"])*0.5,float(numbers["profit"])*9.0)*(1.4 if b["cooked"] else 1.0)
	b["value"]=int(maxf(float(INDUSTRIES[b["ind"]]["cost"])*cost*0.3,lerpf(float(b["value"]),val,0.6)))
	if b["public"]: b["price"]=float(b["value"])/1000000.0


func _business_yearly() -> void:
	var p := GameState.player
	var b: Dictionary = p["business"]
	var ind: Dictionary = INDUSTRIES[b["ind"]]
	if int(b.get("settled_year",-1))==GameState.year_now(): return
	b["settled_year"]=GameState.year_now()
	var operations=Journey.modules["operations"]
	operations.yearly()
	var alive_crew: Array = []
	for id in b["crew"]:
		if GameState.npcs.has(id) and GameState.npcs[id]["alive"]:
			alive_crew.append(id)
			GameState.change_closeness(id, 1)
	b["crew"] = alive_crew
	operations.remember_crew(b,GameState.npcs)
	var extra_size := minf(4.0,float(p["cult"]["members"])/200.0) if b["labor"] and not p["cult"].is_empty() else 0.0
	var synergy := 1.2 if ind.get("career","")!="" and Careers.has_career(ind["career"]) else 1.0
	var cost := float(ContentDB.country(p["country"]).get("cost",1.0))*Places.cost_mult()
	var numbers := business_numbers(b,float(p["fame"]),alive_crew.size(),cost,synergy,Places.scene_bonus(b["ind"]),extra_size)
	var old_price := float(b["price"])
	settle_business(b,numbers,cost)
	var rev := int(numbers["rev"]); var payroll := int(numbers["payroll"]); var interest := int(numbers["interest"]); var profit := int(numbers["profit"])
	if b["public"]: GameState.world.get("change",{})[b["symbol"]]=(float(b["price"])-old_price)/maxf(0.01,old_price)

	var draw := int(numbers["draw"])
	p["money"] = int(p["money"]) + draw
	operations.accounts(int(rev),payroll,interest,profit,draw,numbers["mods"])
	if profit >= 0:
		GameState.add_log("%s made %s in profit this year%s." % [b["name"], GameState.fmt_money(profit), "" if synergy == 1.0 else ", helped by my career"])
	else:
		GameState.add_log("%s lost %s this year." % [b["name"], GameState.fmt_money(-profit)])
	if profit < 0 and int(p["money"]) < 0 and int(b["debt"]) > int(b["value"]) * 0.5:
		var nm: String = b["name"]
		_close_business()
		GameState.add_milestone(p["age"], "went bankrupt")
		EventEngine.push_info("📉", "Bankrupt", "%s ran out of money. The creditors took everything that was left." % nm, GameState.apply_effects({"happiness": -20, "stress": 15}))
		return
	if b["cooked"]:
		var acc := Web.contact(["accountant"], 55)
		GameState.apply_effects({"heat": 3 if acc != "" else 7})
		if randf() < 0.1 + float(p["heat"]) / 400.0:
			_audit(acc)
	elif profit > _cost(400000) and randf() < 0.05:
		_audit(Web.contact(["accountant"], 55))
	if b["labor"] and randf() < 0.15:
		GameState.apply_effects({"heat": 8})
		GameState.add_log("A former follower told the labor board they'd worked at %s for free." % b["name"])
	if not alive_crew.is_empty() and randf() < 0.12:
		var id: String = alive_crew[randi() % alive_crew.size()]
		if randf() < 0.5:
			GameState.add_log("%s asked me for a raise at %s." % [GameState.npc(id)["first"], b["name"]])
			GameState.change_closeness(id, -4)
		else:
			GameState.add_log("%s pulled an all-nighter to save a deal at %s." % [GameState.npc(id)["first"], b["name"]])
			b["quality"] = minf(100.0, float(b["quality"]) + 4.0)


func _audit(acc: String) -> void:
	var p := GameState.player
	var b: Dictionary = p["business"]
	var cooked: bool = b.get("cooked", false)
	var choices: Array = []
	if acc != "":
		choices.append({"label": "Call %s" % Web.contact_line(acc), "outcomes": [
			{"weight": 0.85, "text": "%s buried the problems in paperwork so deep the auditors gave up." % GameState.npc(acc)["first"], "effects": {"heat": -10, "stress": -5}, "relationship": {"acc": 6}},
			{"weight": 0.15, "text": "Even %s couldn't hide it. I paid a huge fine." % GameState.npc(acc)["first"], "effects": {"money": -int(int(b["value"]) * 0.15), "stress": 10}}]})
	if cooked:
		choices.append({"label": "Shred the evidence", "outcomes": [
			{"weight": 0.5, "text": "The shredder ran all night. The auditors found nothing.", "effects": {"heat": 5, "karma": -5}},
			{"weight": 0.5, "text": "They caught me shredding. That's obstruction on top of fraud.", "effects": {"stress": 15}, "trial": ["tax evasion", 2, 8]}]})
		choices.append({"label": "Come clean and pay", "outcomes": [
			{"text": "I confessed and paid back taxes plus penalties.", "effects": {"money": -int(int(b["value"]) * 0.25), "karma": 5, "heat": -20}}]})
	else:
		choices.append({"label": "Open the books", "outcomes": [
			{"weight": 0.8, "text": "Everything checked out. The auditors left disappointed.", "effects": {"stress": -3}},
			{"weight": 0.2, "text": "They found honest mistakes. I paid a small fine.", "effects": {"money": -_cost(20000)}}]})
	var roles := {}
	if acc != "":
		roles["acc"] = acc
	EventEngine.push_decision({"id": "_audit", "icon": "🧾", "title": "Tax audit", "text": "The tax office is auditing %s.%s" % [b["name"], " Your cooked books won't survive a close look." if cooked else ""], "choices": choices}, roles)


# ================================================================ BLACK MARKET

func bm_access() -> String:
	var p := GameState.player
	if int(p["age"]) < 16:
		return "Age 16+"
	if Careers.has_career("mafia") or Careers.has_career("hustler") or Careers.past("mafia") or Careers.past("hustler"):
		return ""
	if not p["record"].is_empty() or float(p.get("heat", 0)) >= 15 or GameState.has_flag("bm_known"):
		return ""
	if Web.contact(["mafia"], 30) != "" or not GameState.npcs_with("mafia_boss").is_empty():
		return ""
	return "You don't know the right people yet. A record, a crime career or a shady friend opens the door."


func _undercover(what: String) -> bool:
	var p := GameState.player
	GameState.set_flag("black_market_buyer")
	var risk := (0.04 + float(p.get("heat", 0)) / 500.0) * (0.5 if Lives.has_power("invisibility") or Grit.has_boon("street_smarts") else 1.0)
	if Careers.has_career("hustler") or Careers.has_career("mafia"):
		risk *= 0.6
	if randf() >= risk:
		return false
	var cop := Web.contact(["cop"], 60)
	if cop != "" and randf() < 0.6:
		_done("👮", "Tip-off", "%s texted me just in time: \"Don't do the deal. The buyer is a cop.\"" % GameState.full_name(cop), {"heat": 5, "stress": 6})
		return true
	p["record"].append(what)
	GameState.add_log("The buyer was an undercover cop. I was arrested for %s." % what)
	Law.trial(what, 1, 5)
	return true


func bm_goods() -> Array:
	var out: Array = []
	var yr := GameState.year_now()
	seed(yr * 7 + int(GameState.player.get("seed", 3)))
	for g in BM_GOODS:
		out.append({"icon": g[0], "name": g[1], "real": _cost(g[2] * randf_range(0.7, 1.3)), "price": 0})
	randomize()
	for g in out:
		g["price"] = int(int(g["real"]) * 0.3)
	return out


func bm_action(aid: String, arg = null) -> void:
	var p := GameState.player
	match aid:
		"fence":
			var idx: int = arg
			var it: Dictionary = p["possessions"][idx]
			if _t(): return
			if _undercover("trafficking stolen goods"):
				p["possessions"].remove_at(idx)
				return
			var rate := 0.5 + (0.25 if Careers.has_career("hustler") or Careers.has_career("mafia") else 0.0)
			var cash := int(int(it["value"]) * rate * randf_range(0.85, 1.1))
			p["possessions"].remove_at(idx)
			GameState.counter("fenced")
			_done("🕶️", "Fenced", "A fence in a parking garage gave me %s for the %s. No questions asked." % [GameState.fmt_money(cash), it["name"].to_lower()], {"money": cash, "heat": 4, "karma": -3})
		"buy_hot":
			var g: Dictionary = arg
			if not _pay(int(g["price"]), g["name"]): return
			if _t(): return
			if _undercover("receiving stolen goods"):
				return
			p["money"] = int(p["money"]) - int(g["price"])
			p["possessions"].append({"name": g["name"], "icon": g["icon"], "cat": "Stolen", "value": int(g["real"]), "vol": 0.1, "bought": int(g["price"]), "heirloom": false, "stolen": true})
			_done(g["icon"], "Hot merchandise", "I bought a %s for %s. It's worth a lot more, if I can ever sell it." % [g["name"].to_lower(), GameState.fmt_money(int(g["price"]))], {"heat": 5, "karma": -4})
		"counterfeit":
			if _t(): return
			if _undercover("selling counterfeit goods"):
				return
			var cash2 := _cost(randi_range(800, 5000)) * (2 if Careers.has_career("hustler") else 1)
			_done("👜", "Knockoffs", "I sold a trunk of fake designer bags at a street market for %s." % GameState.fmt_money(cash2), {"money": cash2, "heat": 6, "karma": -3})
		"fake_watch":
			var fee := _cost(400)
			if not _pay(fee, "Fake watch"): return
			p["money"] = int(p["money"]) - fee
			p["possessions"].append({"name": "Luxury watch", "icon": "⌚", "cat": "Jewelry", "value": _cost(26000), "vol": 0.0, "bought": fee, "heirloom": false, "fake": true})
			_done("⌚", "Knockoff", "I bought a perfect fake luxury watch for %s. Nobody will ever know. Probably." % GameState.fmt_money(fee), {"looks": 1, "karma": -1})
		"passport":
			var pf := _cost(15000)
			if not _pay(pf, "Forged passport"): return
			if _t(): return
			if _undercover("document forgery"):
				return
			p["money"] = int(p["money"]) - pf
			GameState.set_flag("forged_passport")
			_done("🛂", "New identity", "A forger made me a passport under a new name. It's my ticket out if things get hot.", {"heat": 4, "karma": -3})
		"diploma":
			var df := _cost(8000)
			if not _pay(df, "Forged diploma"): return
			if _t(): return
			var majors := ["business", "engineering", "law", "medicine", "computer_science", "economics"]
			var mj: String = majors[randi() % majors.size()]
			var m := ContentDB.major(mj)
			p["money"] = int(p["money"]) - df
			p["education"]["degrees"].append({"major": mj, "level": m.get("level", "bachelor"), "name": m.get("degree", "Degree"), "forged": true})
			_done("📜", "Instant graduate", "I bought a forged %s. It looks real enough to fool HR." % m.get("degree", "degree"), {"karma": -5, "heat": 3})
		"flee":
			if not GameState.has_flag("forged_passport"):
				return
			var choices: Array = []
			for c in ContentDB.countries:
				if c["id"] == p["country"]:
					continue
				choices.append({"label": "%s %s" % [c.get("flag", ""), c["name"]], "outcomes": [
					{"text": "I slipped across the border to %s on a fake passport. The heat stayed behind." % c["name"], "effects": {"heat": -100, "stress": 10, "happiness": -4}, "emigrate": c["id"], "milestone": "fled the country"}]})
			choices.append({"label": "Not yet", "outcomes": [{"text": ""}]})
			GameState.clear_flag("forged_passport")
			GameState.set_flag("fled_country")
			EventEngine.push_decision({"id": "_flee", "icon": "🛂", "title": "Flee the country", "text": "Your forged passport is good for one trip. Where to?", "choices": choices})
		"exotic":
			var key: String = arg
			var a: Dictionary = ZOO_ANIMALS[key]
			var price := _cost(int(a["price"]))
			if not _pay(price, a["name"]): return
			if _t(): return
			if _undercover("wildlife trafficking"):
				return
			p["money"] = int(p["money"]) - price
			if not p["zoo"].is_empty():
				p["zoo"]["animals"][key] = int(p["zoo"]["animals"].get(key, 0)) + 1
				p["zoo"]["illegal"] = int(p["zoo"].get("illegal", 0)) + 1
				_done(a["icon"], "Smuggled in", "A crate arrived at %s in the dead of night. Inside: one very angry %s." % [p["zoo"]["name"], a["name"].to_lower().trim_suffix("s")], {"heat": 6, "karma": -4})
			else:
				var sp: String = a["name"].to_lower().trim_suffix("s")
				var id := GameState.create_npc("pet", {"species": sp, "first": ContentDB.random_pet_name(), "last": "", "age": 1, "closeness": 40})
				GameState.npcs[id]["exotic"] = true
				_done(a["icon"], "Exotic pet", "I bought a baby %s named %s. My neighbors are nervous." % [sp, GameState.npcs[id]["first"]], {"heat": 5, "happiness": 8, "karma": -3})


func _exotic_pets_yearly() -> void:
	for id in GameState.npcs_with("pet"):
		var n: Dictionary = GameState.npcs[id]
		if not n.get("exotic", false) or randf() > 0.1:
			continue
		if randf() < 0.5:
			GameState.add_log("My %s %s escaped and terrified the neighborhood." % [n["species"], n["first"]])
			GameState.apply_effects({"heat": 10, "stress": 6})
		else:
			GameState.add_log("My %s %s turned on me. I needed stitches." % [n["species"], n["first"]])
			GameState.apply_effects({"health": -18, "stress": 8})


func _forgery_yearly() -> void:
	var p := GameState.player
	for d in p["education"]["degrees"]:
		if d.get("forged", false) and GameState.has_job() and randf() < 0.06:
			d["forged"] = false
			p["education"]["degrees"].erase(d)
			Actions.lose_job("fired")
			p["record"].append("fraud")
			GameState.add_log("HR discovered my %s was forged. I was fired on the spot." % d["name"])
			GameState.apply_effects({"heat": 15, "happiness": -12})
			return


func lay_low() -> void:
	if _t(): return
	GameState.spend_time()
	var drop := 12.0 + (6.0 if GameState.player["housing"] == "parents" else 0.0)
	_done("🤫", "Laying low", "I stayed home, kept the curtains shut and avoided my usual spots.", {"heat": -drop, "happiness": -2, "stress": 2})


# ================================================================ CULT

func cult_can_start() -> String:
	var p := GameState.player
	if int(p["age"]) < 21:
		return "Age 21+"
	if not p["cult"].is_empty():
		return "You already lead a cult"
	return ""


func start_cult(doc_id: String) -> void:
	var p := GameState.player
	var d: Dictionary = DOCTRINES[doc_id]
	var fee := _cost(5000)
	if not _pay(fee, d["name"]): return
	if _t(): return
	p["money"] = int(p["money"]) - fee
	var start := 3 + int(float(p["fame"]) / 4.0) + int(GameState.stat("looks") / 25.0)
	p["cult"] = {"doctrine": doc_id, "name": d["name"], "members": start, "devotion": 50.0, "inner": [], "compound": "", "founded": GameState.year_now(), "exposes": 0, "peak": start}
	GameState.add_milestone(p["age"], "founded %s" % d["name"])
	_done(d["icon"], "A new faith", "I founded %s. %s. %d people showed up to the first meeting." % [d["name"], d["blurb"], start], {"karma": -5, "happiness": 6})


func cult_actions() -> Array:
	var p := GameState.player
	var c: Dictionary = p["cult"]
	if c.is_empty():
		return []
	var out: Array = []
	out.append({"id": "c_recruit", "icon": "📢", "name": "Recruit on the streets", "sub": "Looks and charm help"})
	if float(p["fame"]) >= 25:
		out.append({"id": "c_fans", "icon": "⭐", "name": "Recruit your fans", "sub": "%s followers to draw from" % GameState.fmt_money(int(p.get("followers", 0))).trim_prefix("$")})
	out.append({"id": "c_sermon", "icon": "🕯️", "name": "Give a sermon", "sub": "Minigame · devotion %d%%" % int(c["devotion"])})
	out.append({"id": "c_donate", "icon": "🪙", "name": "Collect donations", "sub": "Money · heat"})
	out.append({"id": "c_ritual", "icon": "🌕", "name": "Hold a ritual", "sub": "Devotion up · strange things happen"})
	var jr := Web.contact(["journalist"], 55)
	if jr != "":
		out.append({"id": "c_press", "icon": "📰", "name": "Ask %s for a puff piece" % GameState.npc(jr)["first"], "sub": "Lower heat, more members"})
	if c["compound"] == "":
		out.append({"id": "c_compound", "icon": "🏕️", "name": "Build a compound", "sub": "Needs a property you own"})
	if c["doctrine"] == "nature" and not p["zoo"].is_empty():
		out.append({"id": "c_zoo", "icon": "🌿", "name": "Send followers to care for the zoo", "sub": "Free keepers"})
	out.append({"id": "c_disband", "icon": "🚪", "name": "Disband the cult", "sub": "Walk away"})
	return out


func cult_action(aid: String, arg = null) -> void:
	var p := GameState.player
	var c: Dictionary = p["cult"]
	if c.is_empty():
		return
	var d: Dictionary = DOCTRINES[c["doctrine"]]
	match aid:
		"c_recruit":
			if _t(): return
			var n := int((3 + GameState.stat("looks") / 10.0 + GameState.stat("smarts") / 25.0 + float(p["fame"]) * 0.4) * float(d["recruit"]) * randf_range(0.5, 1.6))
			c["members"] = int(c["members"]) + n
			_done("📢", "New believers", "I handed out pamphlets and gave a speech in the park. %d people joined %s." % [n, c["name"]], {"heat": 1})
		"c_fans":
			if _t(): return
			var n2 := int(float(p.get("followers", 0)) * randf_range(0.0005, 0.002) * float(d["recruit"])) + randi_range(10, 40)
			c["members"] = int(c["members"]) + n2
			_done("⭐", "Fans become followers", "I told my fans the truth about %s. %d of them joined." % [c["name"], n2], {"fame": -2, "heat": 3})
		"c_sermon":
			if _t(): return
			Minigames.play("debate", {"skill": GameState.stat("smarts") * 0.5 + GameState.stat("looks") * 0.3 + float(c["devotion"]) * 0.2, "difficulty": 1.0, "flavor": "sermon"}, Callable(Careers, "resolve_play").bind({"kind": "cult_sermon"}))
		"c_donate":
			if _t(): return
			var cash := _cost(int(c["members"]) * float(c["devotion"]) / 100.0 * 150.0 * float(d["donate"]) * randf_range(0.7, 1.3))
			var heat := 3.0 + int(c["members"]) / 80.0 * float(d["heat"])
			c["devotion"] = maxf(0.0, float(c["devotion"]) - 4.0)
			_done("🪙", "Tithes", "The faithful of %s gave %s to the cause. I spent some of it on the cause." % [c["name"], GameState.fmt_money(cash)], {"money": cash, "heat": minf(heat, 15.0), "karma": -4})
		"c_ritual":
			if _t(): return
			var r := randf()
			c["devotion"] = minf(100.0, float(c["devotion"]) + 10.0 * float(d["devotion"]))
			if r < 0.12:
				c["members"] = maxi(0, int(c["members"]) - randi_range(2, 10))
				_done("🌕", "Ritual gone wrong", "The ritual got out of hand. Someone called the police and several members fled.", {"heat": 10, "stress": 8})
			elif r < 0.3:
				_done("🌕", "A sign!", "A shooting star crossed the sky mid-ritual. My followers wept. Even I got chills.", {"happiness": 6})
			else:
				_done("🌕", "Ritual", "We chanted under the full moon until sunrise. Devotion is %d%%." % int(c["devotion"]), {"stress": -3})
		"c_press":
			var jr := Web.contact(["journalist"], 55)
			if jr == "" or _t(): return
			if randf() < 0.75:
				c["members"] = int(c["members"]) + randi_range(15, 60)
				_done("📰", "Good press", "%s wrote a glowing piece on our \"wellness community.\" Membership spiked." % GameState.npc(jr)["first"], {"heat": -12})
				GameState.change_closeness(jr, -2)
			else:
				GameState.change_closeness(jr, -20)
				_done("📰", "Backfire", "%s dug too deep and wrote the truth instead." % GameState.npc(jr)["first"], {"heat": 12})
		"c_compound":
			var idx: int = arg if arg != null else -1
			if idx < 0 or idx >= p["properties"].size():
				return
			if _t(): return
			var pr: Dictionary = p["properties"][idx]
			if pr.get("tenant", "") != "" and GameState.npcs.has(pr["tenant"]):
				GameState.npcs[pr["tenant"]]["relation"] = "former_tenant"
				pr["tenant"] = ""
			pr["compound"] = true
			c["compound"] = pr["type"]
			c["devotion"] = minf(100.0, float(c["devotion"]) + 15.0)
			var island: bool = pr["type"] == "Private island"
			_done("🏕️", "The compound", "My followers moved into my %s. It's %s now." % [pr["type"].to_lower(), "a holy island no one can reach" if island else "our compound"], {"heat": 2 if island else 6})
		"c_zoo":
			if _t(): return
			p["zoo"]["cult_keepers"] = true
			_done("🌿", "Sacred duty", "My followers now tend the animals at %s as a form of worship." % p["zoo"]["name"], {"karma": -2})
		"c_disband":
			var nm: String = c["name"]
			_end_cult()
			_done("🚪", "Disbanded", "I told my followers %s was over. Some cried. Some cheered. One threatened me." % nm, {"heat": -10, "karma": 4, "stress": -5})


func invite_to_cult(id: String) -> void:
	var p := GameState.player
	var c: Dictionary = p["cult"]
	if c.is_empty() or c["inner"].has(id):
		return
	if _t(): return
	var n: Dictionary = GameState.npcs[id]
	var yes := clampf(float(n["closeness"]) / 140.0 + (0.2 if n.get("trait", "") in ["Naive", "Spiritual", "Lonely"] else 0.0), 0.05, 0.9)
	if randf() < yes:
		c["inner"].append(id)
		c["members"] = int(c["members"]) + 1
		n["cult"] = true
		GameState.change_closeness(id, 10)
		_done("🛐", "A true believer", "%s joined my inner circle at %s." % [GameState.full_name(id), c["name"]], {"karma": -2})
	else:
		GameState.change_closeness(id, -15)
		_done("🙅", "Refused", "%s looked at me like I'd lost my mind. \"Is this a cult?\"" % n["first"], {"happiness": -3})


func _end_cult() -> void:
	var p := GameState.player
	var c: Dictionary = p["cult"]
	for id in c.get("inner", []):
		if GameState.npcs.has(id):
			GameState.npcs[id].erase("cult")
	for pr in p["properties"]:
		pr.erase("compound")
	if not p["zoo"].is_empty():
		p["zoo"].erase("cult_keepers")
	if not p["business"].is_empty():
		p["business"]["labor"] = false
	p["cult"] = {}


func _cult_yearly() -> void:
	var p := GameState.player
	var c: Dictionary = p["cult"]
	var d: Dictionary = DOCTRINES[c["doctrine"]]
	var m := int(c["members"])
	var dev := float(c["devotion"])
	var decay := 5.0 if c["compound"] == "" else 2.0
	if c["doctrine"] == "nature" and int(GameState.player["journal"].get("trips", 0)) > 0:
		decay -= 1.0
	c["devotion"] = maxf(0.0, dev - decay)
	if dev >= 50:
		c["members"] = m + int(m * 0.12 * float(d["recruit"])) + randi_range(0, 6)
	elif dev < 30:
		var lost := int(m * randf_range(0.1, 0.25))
		c["members"] = maxi(0, m - lost)
		if lost > 0:
			GameState.add_log("%d disillusioned members left %s." % [lost, c["name"]])
	c["peak"] = maxi(int(c.get("peak", 0)), int(c["members"]))
	var passive := _cost(int(c["members"]) * dev / 100.0 * 40.0 * float(d["donate"]))
	p["money"] = int(p["money"]) + passive
	GameState.add_log("%s now has %d members. The faithful gave %s this year." % [c["name"], int(c["members"]), GameState.fmt_money(passive)])
	var island: bool = c["compound"] == "Private island"
	GameState.apply_effects({"heat": minf(12.0, int(c["members"]) / 150.0 * float(d["heat"])) * (0.4 if island else 1.0), "fame": minf(3.0, int(c["members"]) / 3000.0)})
	if int(c["members"]) >= 1000 and not GameState.has_flag("cult_1000"):
		GameState.set_flag("cult_1000")
		GameState.add_milestone(p["age"], "led a cult of over 1,000 followers")
	for id in c["inner"].duplicate():
		if not GameState.npcs.has(id) or not GameState.npcs[id]["alive"]:
			c["inner"].erase(id)
		elif randf() < 0.06:
			c["inner"].erase(id)
			GameState.npcs[id].erase("cult")
			GameState.change_closeness(id, -25)
			GameState.add_log("%s left %s and told everyone what goes on inside." % [GameState.full_name(id), c["name"]])
			GameState.apply_effects({"heat": 8})
	if randf() < float(p["heat"]) / 350.0 + int(c["members"]) / 30000.0:
		_cult_expose()


func _cult_expose() -> void:
	var p := GameState.player
	var c: Dictionary = p["cult"]
	c["exposes"] = int(c["exposes"]) + 1
	var choices: Array = []
	var jr := Web.contact(["journalist"], 50)
	if jr != "":
		choices.append({"label": "Get %s to kill the story" % Web.contact_line(jr), "outcomes": [
			{"weight": 0.6, "text": "%s talked the editor out of running it." % GameState.npc(jr)["first"], "effects": {"heat": -10}, "relationship": {"jr": -8}},
			{"weight": 0.4, "text": "%s refused. The story ran, and it named me." % GameState.npc(jr)["first"], "effects": {"heat": 15, "fame": 5}, "relationship": {"jr": -20}}]})
	choices.append({"label": "Deny everything", "outcomes": [
		{"weight": 0.55, "text": "My followers rallied behind me. The story fizzled.", "effects": {"heat": 5, "fame": 3}},
		{"weight": 0.45, "text": "Nobody believed the denial. Members started leaving.", "effects": {"heat": 15, "fame": 5, "happiness": -8}}]})
	choices.append({"label": "Double down on TV", "outcomes": [
		{"weight": 0.5, "text": "I went on TV and preached. Membership exploded.", "effects": {"fame": 10, "heat": 12}},
		{"weight": 0.5, "text": "I melted down on live TV. The clip went viral.", "effects": {"fame": 8, "heat": 20, "happiness": -10}}]})
	choices.append({"label": "Disband before it gets worse", "outcomes": [
		{"text": "I shut it all down. The reporters moved on.", "effects": {"heat": -15, "karma": 5}, "empire": "cult_disband"}]})
	var roles := {}
	if jr != "":
		roles["jr"] = jr
	c["members"] = int(int(c["members"]) * 0.9)
	EventEngine.push_decision({"id": "_cult_expose", "icon": "📰", "title": "Exposé!", "text": "A news show is about to air an exposé on %s, with interviews from ex-members." % c["name"], "choices": choices}, roles)


## Outcome hook for events: {"empire": "<what>"}.
func outcome(what: String) -> void:
	var p := GameState.player
	match what:
		"cult_disband":
			if not p["cult"].is_empty():
				_end_cult()
		"zoo_confiscate":
			var z: Dictionary = p["zoo"]
			if z.is_empty():
				return
			for k in z["animals"].keys():
				if ZOO_ANIMALS[k].get("illegal", false):
					z["animals"].erase(k)
			z["illegal"] = 0
		"bm_known":
			GameState.set_flag("bm_known")
		"biz_boost":
			if not p["business"].is_empty():
				p["business"]["quality"] = minf(100.0, float(p["business"]["quality"]) + 10.0)
		"biz_hit":
			if not p["business"].is_empty():
				p["business"]["quality"] = maxf(5.0, float(p["business"]["quality"]) - 12.0)
		"biz_buzz":
			if not p["business"].is_empty():
				p["business"]["marketing"] = minf(100.0, float(p["business"]["marketing"]) + 20.0)
		"cult_grow":
			if not p["cult"].is_empty():
				p["cult"]["members"] = int(p["cult"]["members"]) + randi_range(20, 120)
		"cult_devotion":
			if not p["cult"].is_empty():
				p["cult"]["devotion"] = minf(100.0, float(p["cult"]["devotion"]) + 15.0)
		"cult_shrink":
			if not p["cult"].is_empty():
				p["cult"]["members"] = int(int(p["cult"]["members"]) * 0.7)
		"zoo_rating_up":
			if not p["zoo"].is_empty():
				p["zoo"]["rating"] = minf(100.0, float(p["zoo"]["rating"]) + 12.0)
		"zoo_rating_down":
			if not p["zoo"].is_empty():
				p["zoo"]["rating"] = maxf(0.0, float(p["zoo"]["rating"]) - 12.0)
		"zoo_baby":
			if not p["zoo"].is_empty() and not p["zoo"]["animals"].is_empty():
				var k: String = p["zoo"]["animals"].keys()[randi() % p["zoo"]["animals"].size()]
				p["zoo"]["animals"][k] = int(p["zoo"]["animals"][k]) + 1
		"random_find":
			_find(FINDS, 1.0)
		"poach_ban":
			Law.suspend("hunting", 10, "poaching a protected animal")
			GameState.counter("poaching")
		"biz_embezzle":
			if not p["business"].is_empty():
				p["business"]["value"] = int(int(p["business"]["value"]) * 0.55)
				p["business"]["quality"] = maxf(5.0, float(p["business"]["quality"]) - 15.0)
		"biz_double":
			if not p["business"].is_empty():
				p["business"]["value"] = int(p["business"]["value"]) * 2
				p["business"]["marketing"] = 100.0
		"biz_close":
			if not p["business"].is_empty():
				_close_business()
		"biz_sell":
			# Selling pays what the business is worth, not a number written into
			# an event. Building something good is the only way to sell it well.
			if not p["business"].is_empty():
				var sale := int(p["business"].get("value", 0))
				sale = int(sale * (0.6 + float(p["business"].get("quality", 50.0)) / 125.0))
				p["money"] = int(p["money"]) + sale
				GameState.add_log("I sold %s for %s." % [str(p["business"].get("name", "the business")), GameState.fmt_money(sale)])
				GameState.counter("businesses_sold")
				_close_business()
		"zoo_plague":
			var zz: Dictionary = p["zoo"]
			if not zz.is_empty():
				for k in zz["animals"].keys():
					zz["animals"][k] = int(zz["animals"][k]) / 2
					if int(zz["animals"][k]) <= 0:
						zz["animals"].erase(k)
				zz["rating"] = maxf(0.0, float(zz["rating"]) - 25.0)


# ================================================================ ZOO

func zoo_capacity() -> int:
	return int(GameState.player["zoo"]["acres"]) * 4


func zoo_care_load() -> int:
	var total := 0
	for k in GameState.player["zoo"]["animals"].keys():
		total += int(ZOO_ANIMALS[k]["care"]) * int(GameState.player["zoo"]["animals"][k])
	return total


func zoo_welfare() -> float:
	var z: Dictionary = GameState.player["zoo"]
	var load := maxi(1, zoo_care_load())
	var keepers: int = int(z["keepers"]) + z.get("crew", []).size()
	if z.get("cult_keepers", false) and not GameState.player["cult"].is_empty():
		keepers += 4
	var w := float(keepers * 7) / float(load)
	if Web.contact(["vet"], 50) != "":
		w += 0.2
	return clampf(w, 0.0, 1.2)


func zoo_value(p: Dictionary = {}) -> int:
	if p.is_empty(): p=GameState.player
	var z: Dictionary = p["zoo"]
	var price := int(20000 * float(ContentDB.country(p.get("country","us")).get("cost",1.0)) * Places.cost_mult(p))
	var v := int(z["acres"]) * price
	for k in z["animals"].keys():
		v += int(ZOO_ANIMALS[k]["price"]) * int(z["animals"][k])
	return v


func open_zoo() -> void:
	var p := GameState.player
	var cost := _cost(250000)
	if int(p["age"]) < 21:
		_info("🦁", "Zoo", "You must be 21 to open a zoo.")
		return
	if not _pay(cost, "Zoo"): return
	if _t(): return
	p["money"] = int(p["money"]) - cost
	var nm: String = "%s %s" % [p["last"], ["Wildlife Park", "Zoo", "Safari Park", "Animal Kingdom", "Menagerie"][randi() % 5]]
	p["zoo"] = {"name": nm, "acres": 10, "animals": {"goat": 4}, "keepers": 1, "crew": [], "rating": 40.0, "visitors": 0, "rev": 0, "profit": 0, "founded": GameState.year_now(), "illegal": 0}
	GameState.add_milestone(p["age"], "opened %s" % nm)
	_done("🦁", "Zoo opened!", "I bought 10 acres and opened %s with four goats and a dream." % nm, {"happiness": 10})


func zoo_action(aid: String, arg = null) -> void:
	var p := GameState.player
	var z: Dictionary = p["zoo"]
	if z.is_empty():
		return
	match aid:
		"buy":
			var key: String = arg
			var a: Dictionary = ZOO_ANIMALS[key]
			var price := _cost(int(a["price"]))
			if zoo_care_load() + int(a["care"]) > zoo_capacity():
				_info("🏞️", "No room", "%s is full. Buy more land first." % z["name"])
				return
			if not _pay(price, a["name"]): return
			p["money"] = int(p["money"]) - price
			z["animals"][key] = int(z["animals"].get(key, 0)) + 1
			_done(a["icon"], "New arrival", "A %s arrived at %s from a licensed breeder." % [a["name"].to_lower().trim_suffix("s"), z["name"]], {"happiness": 3})
		"sell":
			var key2: String = arg
			if int(z["animals"].get(key2, 0)) <= 0:
				return
			var a2: Dictionary = ZOO_ANIMALS[key2]
			z["animals"][key2] = int(z["animals"][key2]) - 1
			if int(z["animals"][key2]) <= 0:
				z["animals"].erase(key2)
			var cash := _cost(int(a2["price"]) * 0.6)
			if a2.get("illegal", false):
				z["illegal"] = maxi(0, int(z.get("illegal", 0)) - 1)
			_done(a2["icon"], "Sold", "I sold one of my %s for %s." % [a2["name"].to_lower(), GameState.fmt_money(cash)], {"money": cash})
		"land":
			var lc := _cost(120000)
			if not _pay(lc, "Land"): return
			p["money"] = int(p["money"]) - lc
			z["acres"] = int(z["acres"]) + 5
			_done("🏞️", "More land", "I bought 5 more acres for %s. %s is now %d acres." % [GameState.fmt_money(lc), z["name"], int(z["acres"])], {})
		"keeper":
			z["keepers"] = int(z["keepers"]) + 1
			_done("🧑‍🌾", "New keeper", "I hired another zookeeper. %d on staff." % int(z["keepers"]), {})
		"fire_keeper":
			z["keepers"] = maxi(0, int(z["keepers"]) - 1)
			_done("📉", "Keeper let go", "I cut a zookeeper to save money.", {"karma": -1})
		"event":
			var ec := _cost(15000)
			if not _pay(ec, "Zoo event"): return
			if _t(): return
			p["money"] = int(p["money"]) - ec
			z["rating"] = minf(100.0, float(z["rating"]) + 8.0)
			z["buzz"] = 1.3
			_done("🎈", "Zoo festival", "I threw a %s at %s. Families lined up around the block." % [["Night Safari", "Baby Animal Day", "Summer Zoo Fest", "Lantern Walk"][randi() % 4], z["name"]], {"happiness": 5, "fame": 1})
		"visit":
			if z["animals"].is_empty():
				_info("🦁", "Empty zoo", "There are no animals to visit yet.")
				return
			if _t(): return
			var fave: String = z["animals"].keys()[randi() % z["animals"].size()]
			_done(ZOO_ANIMALS[fave]["icon"], "Feeding time", "I spent the day feeding the %s at my own zoo. Best job in the world." % ZOO_ANIMALS[fave]["name"].to_lower(), {"happiness": 8, "stress": -6})
		"donate_pet":
			var id: String = arg
			var n := GameState.npc(id)
			if n.is_empty():
				return
			n["relation"] = "zoo_animal"
			z["animals"]["petting"] = int(z["animals"].get("petting", 0)) + 1
			_done("🐾", "Petting zoo", "%s the %s moved into the petting zoo at %s. The kids adore them." % [n["first"], n.get("species", "pet"), z["name"]], {"happiness": -2, "karma": 2})
		"hire_known":
			var hid: String = arg
			z["crew"].append(hid)
			_employ(hid, "Zookeeper at " + z["name"])
			GameState.change_closeness(hid, 6)
			_done("🧑‍🌾", "Family business", "%s started working as a zookeeper at %s." % [GameState.full_name(hid), z["name"]], {})
		"sell_zoo":
			var price := int(zoo_value() * randf_range(0.8, 1.1))
			var nm: String = z["name"]
			for cid in z["crew"]:
				_release(cid)
			p["zoo"] = {}
			p["money"] = int(p["money"]) + price
			_done("🦁", "Zoo sold", "I sold %s for %s." % [nm, GameState.fmt_money(price)], {"happiness": -4})


func _zoo_yearly() -> void:
	var p := GameState.player
	var z: Dictionary = p["zoo"]
	var crew: Array = []
	for id in z["crew"]:
		if GameState.npcs.has(id) and GameState.npcs[id]["alive"]:
			crew.append(id)
	z["crew"] = crew
	if z["animals"].is_empty():
		GameState.add_log("%s has no animals. Nobody came." % z["name"])
		return
	var w := zoo_welfare()
	var draw := 0
	var variety: int = z["animals"].size()
	for k in z["animals"].keys():
		draw += int(ZOO_ANIMALS[k]["draw"]) * mini(int(z["animals"][k]), 4)
	z["rating"] = clampf(lerpf(float(z["rating"]), w * 70.0 + variety * 3.0, 0.4), 0.0, 100.0)
	var visitors := int(draw * 400 * (0.4 + float(z["rating"]) / 100.0) * (1.0 + float(p["fame"]) / 80.0) * _mood_mult() * float(z.get("buzz", 1.0)) * World.zoo_mult() * randf_range(0.8, 1.2))
	z["buzz"] = 1.0
	var ticket := _cost(25)
	var rev := visitors * ticket
	var costs := int(z["keepers"]) * _cost(32000) + crew.size() * _cost(28000) + zoo_care_load() * _cost(15000) + int(z["acres"]) * _cost(800)
	var profit := rev - costs
	z["visitors"] = visitors
	z["rev"] = rev
	z["profit"] = profit
	p["money"] = int(p["money"]) + profit
	GameState.add_log("%d people visited %s this year. It made %s." % [visitors, z["name"], GameState.fmt_money(profit)])
	for k in z["animals"].keys():
		var cnt := int(z["animals"][k])
		if cnt >= 2 and k != "petting" and randf() < 0.15 * w:
			z["animals"][k] = cnt + 1
			GameState.add_log("A baby was born in the %s enclosure at %s!" % [ZOO_ANIMALS[k]["name"].to_lower(), z["name"]])
			z["rating"] = minf(100.0, float(z["rating"]) + 5.0)
		elif w < 0.5 and randf() < 0.12:
			z["animals"][k] = cnt - 1
			if int(z["animals"][k]) <= 0:
				z["animals"].erase(k)
			GameState.add_log("One of the %s at %s died. The keepers were stretched too thin." % [ZOO_ANIMALS[k]["name"].to_lower(), z["name"]])
			GameState.apply_effects({"happiness": -4, "karma": -2})
	for k in z["animals"].keys():
		var danger := float(ZOO_ANIMALS[k]["danger"])
		if danger > 0 and randf() < danger * 0.06 * (1.3 - w):
			_zoo_escape(k)
			break
	if int(z.get("illegal", 0)) > 0 and randf() < 0.1 + float(p["heat"]) / 300.0:
		_zoo_inspection()


func _zoo_escape(key: String) -> void:
	var p := GameState.player
	var z: Dictionary = p["zoo"]
	var a: Dictionary = ZOO_ANIMALS[key]
	var claim := _cost(randi_range(50000, 400000))
	var victim := GameState.create_npc("enemy", {"age": randi_range(20, 60), "closeness": 5})
	var choices: Array = []
	var lw := Web.contact(["lawyer"], 50)
	if lw != "":
		choices.append({"label": "Have %s fight it" % Web.contact_line(lw), "outcomes": [
			{"weight": 0.75, "text": "%s proved the victim climbed the fence. Case dismissed." % GameState.npc(lw)["first"], "relationship": {"lw": 5}},
			{"weight": 0.25, "text": "The jury sided with the victim. I paid %s." % GameState.fmt_money(claim), "effects": {"money": -claim}}]})
	choices.append({"label": "Settle for %s" % GameState.fmt_money(claim / 2), "outcomes": [
		{"text": "I settled quietly with {v.first} for %s." % GameState.fmt_money(claim / 2), "effects": {"money": -claim / 2, "stress": 4}}]})
	choices.append({"label": "Fight it in court", "outcomes": [
		{"weight": 0.45, "text": "I won. The judge said {v.first} ignored every warning sign.", "effects": {"stress": 6}},
		{"weight": 0.55, "text": "I lost and paid {v.first} %s in damages." % GameState.fmt_money(claim), "effects": {"money": -claim, "stress": 10}}]})
	GameState.add_log("One of the %s escaped at %s and injured a visitor." % [a["name"].to_lower(), z["name"]])
	z["rating"] = maxf(0.0, float(z["rating"]) - 15.0)
	EventEngine.push_decision({"id": "_zoo_escape", "icon": a["icon"], "title": "Escape at the zoo!", "text": "One of your %s got out of its enclosure and injured {v.first} {v.last}. They're suing %s for %s." % [a["name"].to_lower(), z["name"], GameState.fmt_money(claim)], "choices": choices}, {"v": victim, "lw": lw} if lw != "" else {"v": victim})


func _zoo_inspection() -> void:
	var p := GameState.player
	var z: Dictionary = p["zoo"]
	var cop := Web.contact(["cop"], 60)
	var illegal: Array = []
	for k in z["animals"].keys():
		if ZOO_ANIMALS[k].get("illegal", false):
			illegal.append(k)
	var choices: Array = []
	choices.append({"label": "Hide the animals", "outcomes": [
		{"weight": 0.5, "text": "We moved the animals into a barn. The inspectors saw nothing.", "effects": {"stress": 5}},
		{"weight": 0.5, "text": "A tiger roared from inside the barn. Busted.", "effects": {"heat": 20}, "trial": ["wildlife trafficking", 1, 5]}]})
	choices.append({"label": "Surrender them and pay the fine", "outcomes": [
		{"text": "Wildlife officers took my smuggled animals away and fined me heavily.", "effects": {"money": -_cost(100000), "heat": -10, "karma": 3}, "empire": "zoo_confiscate"}]})
	if cop != "":
		choices.append({"label": "Ask %s to call off the raid" % Web.contact_line(cop), "outcomes": [
			{"weight": 0.5, "text": "The raid was mysteriously cancelled.", "effects": {"karma": -5}, "relationship": {"cop": -10}},
			{"weight": 0.5, "text": "%s refused and the raid went ahead. I was charged." % GameState.npc(cop)["first"], "trial": ["wildlife trafficking", 1, 5], "relationship": {"cop": -20}}]})
	EventEngine.push_decision({"id": "_zoo_raid", "icon": "🚨", "title": "Wildlife inspection", "text": "Federal wildlife inspectors are at the gates of %s. They got a tip about smuggled animals." % z["name"], "choices": choices}, {"cop": cop} if cop != "" else {})


# ================================================================ OUTDOORS

func _journal() -> Dictionary:
	var j: Dictionary = GameState.player["journal"]
	if not j.has("species"):
		j["species"] = {}
		j["fish"] = {}
		j["trips"] = 0
		j["finds"] = 0
		j["donated"] = 0
	return j


func journal_progress() -> Array:
	var j := _journal()
	return [j["species"].size(), WILDLIFE.size(), j["fish"].size(), FISH.size() + SEA_FISH.size()]


func _sighting() -> String:
	var j := _journal()
	var w: Array = WILDLIFE[randi() % WILDLIFE.size()]
	var first: bool = not j["species"].has(w[1])
	j["species"][w[1]] = int(j["species"].get(w[1], 0)) + 1
	if first:
		var prog := journal_progress()
		if int(prog[0]) == int(prog[1]):
			GameState.add_milestone(GameState.player["age"], "completed their wildlife journal")
		return "\n\n📓 New journal entry: %s %s (%d of %d)" % [w[0], w[1], int(prog[0]), int(prog[1])]
	return "\n\nI spotted a %s %s." % [w[0], w[1].to_lower()]


func _find(pool: Array, chance: float) -> String:
	if randf() >= chance:
		return ""
	var p := GameState.player
	var f: Array = pool[randi() % pool.size()]
	var value := _cost(float(f[2]) * randf_range(0.6, 1.5))
	if f[1] == "Meteorite" and (Careers.past("astronaut") or Careers.has_career("astronaut")):
		value = int(value * 1.5)
	p["possessions"].append({"name": f[1], "icon": f[0], "cat": "Finds", "value": value, "vol": 0.05, "bought": 0, "heirloom": false, "find": true})
	_journal()["finds"] = int(_journal()["finds"]) + 1
	return "\n\n%s I found a %s! An expert says it's worth %s." % [f[0], f[1].to_lower(), GameState.fmt_money(value)]


func outdoor_companions() -> Array:
	var out: Array = []
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"] or n["relation"] in ["ex", "enemy", "rival", "former_tenant", "tenant", "cellmate", "zoo_animal", "boss"]:
			continue
		if n.get("species", "human") == "human" and int(n["closeness"]) < 35:
			continue
		out.append(id)
	out.sort_custom(func(a, b): return int(GameState.npcs[a]["closeness"]) > int(GameState.npcs[b]["closeness"]))
	return out.slice(0, 12)


func outdoor(aid: String, arg = null) -> void:
	var p := GameState.player
	var j := _journal()
	match aid:
		"camp":
			if _t(): return
			j["trips"] = int(j["trips"]) + 1
			GameState.counter("camps")
			var who: String = arg if arg != null else ""
			var n := GameState.npc(who)
			var text := ""
			var fx := {"happiness": 8, "stress": -8, "health": 2}
			var mishap := randf()
			if n.is_empty():
				text = "I camped alone under the stars. Just me, a fire and my thoughts."
				fx["stress"] = -12
			elif n.get("species", "human") != "human":
				text = "I took %s camping. They chased every squirrel in the forest." % n["first"]
				GameState.change_closeness(who, 12)
			else:
				text = "I went camping with %s. We told stories by the fire until 2 a.m." % GameState.full_name(who)
				GameState.change_closeness(who, 12)
			if mishap < 0.08:
				text += "\n\nA bear raided our food in the night. We drove home hungry."
				fx["stress"] = 6
			elif mishap < 0.16:
				text += "\n\nIt rained the whole time. Our tent flooded."
				fx["happiness"] = 2
			text += _sighting()
			_done("🏕️", "Camping", text, fx)
		"hike":
			if _t(): return
			j["trips"] = int(j["trips"]) + 1
			GameState.counter("hikes")
			var text2 := "I hiked %s." % ["a mountain trail", "through an old-growth forest", "along a canyon rim", "to a hidden waterfall", "up a volcano"][randi() % 5]
			var fx2 := {"health": 4, "happiness": 5, "stress": -5}
			if randf() < 0.06 and not (Careers.past("athlete") or Careers.has_career("athlete")):
				text2 += " I twisted my ankle on the way down." + Grit.scar_chance("bad_knee", 0.12)
				fx2["health"] = -8
			text2 += _sighting()
			text2 += _find(FINDS, 0.12)
			if randf() < 0.07:
				text2 += _rescue_line()
			_done("🥾", "Hiking", text2, fx2)
		"hunt":
			hunt_menu()
		"fish", "sea_fish":
			if not Law.has_license("fishing") and randf() < 0.18:
				if _t(): return
				_done("🎣", "Game warden", "A game warden asked for my fishing license. I didn't have one. $300 fine, and my rod was confiscated.", {"money": -_cost(300), "happiness": -4})
				return
			if aid == "sea_fish" and not (Law.has_license("boating") or Shop.has_any(["boat", "yacht"])):
				_info("🚤", "Deep-sea fishing", "You need a boating license or a yacht to go out to sea.")
				return
			if _t(): return
			if aid == "sea_fish" and Law.has_license("boating") and randf() < 0.06:
				Law.suspend("boating", 1, "reckless boating")
				_done("🚤", "Harbor patrol", "I cut through a no-wake zone too fast and nearly swamped a kayak. The harbor patrol suspended my boating license for a year.", {"money": -_cost(750), "stress": 6})
				return
			j["trips"] = int(j["trips"]) + 1
			var skill := 40.0 + minf(30.0, j["fish"].size() * 3.0) + (15.0 if Shop.has_tag("rod_pro") else (8.0 if Shop.has_tag("rod") else 0.0))
			var fdiff := (1.2 if aid == "sea_fish" else 0.9) * (0.85 if Shop.has_tag("rod_pro") else (0.93 if Shop.has_tag("rod") else 1.0))
			Minigames.play("fishing", {"skill": skill, "difficulty": fdiff}, Callable(Careers, "resolve_play").bind({"kind": "fishing", "sea": aid == "sea_fish"}))
		"dirtbike":
			if not Law.has_license("motorcycle"):
				_info("🏍️", "Dirt biking", "You need a motorcycle license. Get one under Activities → Legal → Licenses.")
				return
			var fee := _cost(150)
			if not _pay(fee, "Dirt biking"): return
			if _t(): return
			p["money"] = int(p["money"]) - fee
			var r := randf()
			var fx3 := {"happiness": 12, "stress": -6}
			var text3 := "I tore up the dirt trails and hit a jump I'd been scared of for years."
			if r < 0.1:
				text3 = "I wiped out on a jump and broke my collarbone." + Grit.scar_chance(["limp", "back_injury", "bad_knee"][randi() % 3], 0.35)
				fx3 = {"health": -20, "happiness": -5, "stress": 6}
			elif r < 0.25 and float(p["fame"]) >= 15:
				text3 += " Someone filmed it. The clip got millions of views."
				fx3["fame"] = 2
			_done("🏍️", "Dirt biking", text3, fx3)
		"cave":
			if int(p["age"]) < 18:
				_info("🤿", "Cave diving", "You must be 18.")
				return
			if not Law.has_license("scuba"):
				_info("🤿", "Cave diving", "No dive shop will take you without a scuba certification. Get one under Activities → Legal → Licenses.")
				return
			var fee2 := _cost(400)
			if not _pay(fee2, "Cave diving"): return
			if _t(): return
			p["money"] = int(p["money"]) - fee2
			var danger := 0.004 + (0.01 if GameState.stat("health") < 40 else 0.0)
			if randf() < danger:
				GameState.add_log("I went cave diving and never came back up.")
				EventEngine.kill("a cave diving accident")
				return
			var text4 := "I dove through a flooded cave system with a guide. The water was so clear it looked like air."
			var fx4 := {"happiness": 10, "stress": -4}
			if randf() < 0.12:
				text4 += " My light failed for a terrifying minute."
				fx4 = {"happiness": 2, "stress": 12}
			text4 += _find(CAVE_FINDS, 0.18)
			_done("🤿", "Cave diving", text4, fx4)
		"museum":
			var idx: int = arg
			var it: Dictionary = p["possessions"][idx]
			p["possessions"].remove_at(idx)
			j["donated"] = int(j["donated"]) + 1
			p["museum"] = true
			var fx5 := {"karma": 6, "happiness": 5, "fame": 1}
			var text5 := ("I donated the family's %s to the city museum. It sits behind glass with our name beside it." if it.get("heirloom", false) else "I donated my %s to the natural history museum. They put my name on the plaque.") % it["name"].to_lower()
			if it.get("heirloom", false):
				fx5["karma"] = 4
				fx5["fame"] = 2 if str(it.get("rarity", "")) in ["epic", "legendary"] else 1
			if int(j["donated"]) == 5:
				GameState.add_milestone(p["age"], "had a museum wing named after them")
				text5 += "\n\nThat's five donations. The museum named a wing after me!"
				fx5["fame"] = 5
			_done("🏛️", "Museum donation", text5, fx5)


const GAME := [["🦌", "White-tailed deer", 400, 0.5], ["🦆", "Mallard ducks", 60, 0.35], ["🐗", "Wild boar", 300, 0.6], ["🫎", "Elk", 900, 0.8]]


func hunt_menu() -> void:
	var p := GameState.player
	if not Law.has_license("hunting"):
		_info("🦌", "Hunting", "You need a hunting license. Hunting without one is poaching." if Places.law("hunting") else "Hunting is banned in %s." % ContentDB.country(p["country"])["name"])
		return
	if not Shop.has_any(["bow", "rifle"]):
		_info("🏹", "Hunting", "You need something to hunt with. Buy a hunting bow or a hunting rifle under Shopping → Sporting goods.")
		return
	var used := int(p.get("act_year", {}).get("hunt", 0))
	if used >= 2:
		_info("🦌", "Bag limit", "You've used both of this season's tags. The season opens again next year.")
		return
	var choices: Array = []
	for g in GAME:
		choices.append({"label": "%s %s" % [g[0], g[1]], "outcomes": [{"text": "", "play": {"id": "clutch", "kind": "hunt", "game": g[1], "icon": g[0], "value": g[2], "params": {"sport": "hunt", "difficulty": g[3] + (0.35 if Shop.has_tag("rifle") else 0.5), "skill": 45 + (10 if Shop.has_tag("rifle") else 0)}}}]})
	choices.append({"label": "🐻 The protected black bear on the ridge", "outcomes": [
		{"weight": 1, "text": "I took the bear. A ranger found the carcass and traced it to me. Poaching charges, and my hunting license is gone for ten years.", "effects": {"karma": -15, "money": -_cost(15000)}, "flags": ["poached"], "grudge_clear": "none", "empire": "poach_ban"},
		{"weight": 1, "text": "I lined up the shot and couldn't take it. I watched it walk away.", "effects": {"karma": 4}}]})
	choices.append({"label": "Go home", "outcomes": [{"text": ""}]})
	if _t(): return
	if not p.has("act_year"):
		p["act_year"] = {}
	p["act_year"]["hunt"] = used + 1
	EventEngine.push_decision({"id": "_hunt", "icon": "🦌", "title": "Hunting season", "text": "Dawn in %s. You have %d tag%s left this season. What are you hunting?" % [Places.region()["city"], 2 - used, "" if 2 - used == 1 else "s"], "choices": choices})


func _owns(item_name: String) -> bool:
	for it in GameState.player["possessions"]:
		if it["name"] == item_name:
			return true
	return false


func _rescue_line() -> String:
	var p := GameState.player
	var w: Array = WILDLIFE[randi() % WILDLIFE.size()]
	if not p["zoo"].is_empty():
		p["zoo"]["animals"]["rescue"] = int(p["zoo"]["animals"].get("rescue", 0)) + 1
		GameState.apply_effects({"karma": 4})
		return "\n\n%s I found an injured %s and brought it to the rescue center at %s." % [w[0], w[1].to_lower(), p["zoo"]["name"]]
	var vet := Web.contact(["vet"], 40)
	GameState.apply_effects({"karma": 3})
	if vet != "":
		return "\n\n%s I found an injured %s. %s nursed it back to health for free." % [w[0], w[1].to_lower(), GameState.npc(vet)["first"]]
	return "\n\n%s I found an injured %s and drove it to a wildlife rescue." % [w[0], w[1].to_lower()]


# ================================================================ minigame results

func resolve(kind: String, score: float, detail: Dictionary, pl: Dictionary) -> void:
	var p := GameState.player
	var grade := Minigames.grade(score)
	match kind:
		"hunt":
			var gname: String = pl.get("game", "deer")
			if score >= 0.5:
				GameState.counter("hunts")
				var meat := _cost(int(pl.get("value", 300)))
				var text := "Hunt: %s. A clean shot. I took home a %s." % [grade, gname.to_lower().trim_suffix("s")]
				var fxh := {"money": meat, "happiness": 6}
				if score >= 0.9:
					p["possessions"].append({"name": "Mounted %s antlers" % gname.to_lower().trim_suffix("s") if "deer" in gname.to_lower() or "elk" in gname.to_lower() else "Hunting trophy", "icon": pl.get("icon", "🦌"), "cat": "Trophies", "value": _cost(2000), "vol": 0.03, "bought": 0, "heirloom": false})
					text += " A trophy animal. It's going on the wall."
				_done(pl.get("icon", "🦌"), "Hunting", text, fxh)
			elif score >= 0.2:
				_done(pl.get("icon", "🦌"), "Hunting", "Hunt: %s. I missed, and everything within a mile heard it." % grade, {"stress": 2})
			else:
				var hurt := randf() < 0.25
				_done("🤕" if hurt else pl.get("icon", "🦌"), "Hunting", ("Hunt: %s. I slipped on a wet rock with a loaded rifle. It went off. I was lucky." % grade + Grit.scar_chance("missing_finger", 0.5)) if hurt else "Hunt: %s. A whole morning in the cold, and nothing." % grade, {"health": -12} if hurt else {"happiness": -2})
		"brawl":
			var foe: String = pl.get("params", {}).get("opponent", "him")
			if detail.get("won", score >= 0.5):
				_done("👊", "Brawl", "Fight: %s. I put %s on the ground and walked away." % [grade, foe.to_lower() if foe != "him" else foe], {"happiness": 6, "health": -4, "heat": 6})
			else:
				_done("🤕", "Brawl", "Fight: %s. %s got the better of me. I woke up on the pavement." % [grade, foe] + Grit.scar_chance("facial_scar", 0.2), {"health": -14, "happiness": -8})
		"fishing":
			var sea: bool = pl.get("sea", false)
			var pool: Array = SEA_FISH if sea else FISH
			var caught: bool = detail.get("caught", score >= 0.45)
			var text := ""
			var fx := {"happiness": 4, "stress": -6}
			if caught:
				var options: Array = []
				for f in pool:
					if float(f[2]) <= score:
						options.append(f)
				var fish: Array = options[randi() % options.size()] if randf() < 0.5 else options[-1]
				var j := _journal()
				GameState.counter("fish")
				var first: bool = not j["fish"].has(fish[1])
				j["fish"][fish[1]] = int(j["fish"].get(fish[1], 0)) + 1
				var lbs := snappedf(randf_range(1.0, 6.0) * (1.0 + float(fish[2]) * (8.0 if sea else 4.0)), 0.1)
				text = "Fishing: %s. I reeled in a %s %s %s!" % [grade, Units.weight(lbs * 0.453592), fish[1].to_lower(), fish[0]]
				if first:
					text += "\n\n📓 New journal entry: %s" % fish[1]
				fx["happiness"] = 6 + int(score * 6)
				if float(fish[2]) >= 0.85:
					var val := _cost(1500 + lbs * 60)
					p["possessions"].append({"name": "Mounted %s" % fish[1].to_lower(), "icon": fish[0], "cat": "Trophies", "value": val, "vol": 0.03, "bought": 0, "heirloom": false})
					text += "\n\nA trophy fish! I had it mounted for the wall."
					GameState.counter("trophy_fish")
					if not GameState.has_flag("trophy_angler"):
						GameState.set_flag("trophy_angler")
						GameState.add_milestone(p["age"], "caught a record %s" % fish[1].to_lower())
			else:
				text = "Fishing: %s. %s" % [grade, "The line snapped on something huge." if detail.get("snapped", false) else "Nothing but weeds and one old boot."]
				fx["happiness"] = 1
			_done("🎣", "Deep-sea fishing" if sea else "Fishing", text, fx)
		"biz_pitch":
			var b: Dictionary = p["business"]
			if b.is_empty():
				return
			if score >= 0.45:
				var equity := 0.1 if score >= 0.8 else 0.15
				var cash := int(float(b["value"]) * (0.2 + score * 0.6))
				b["stake"] = maxf(0.3, float(b["stake"]) - equity)
				b["quality"] = minf(100.0, float(b["quality"]) + 5.0)
				p["money"] = int(p["money"]) + cash
				_done("🎤", "Deal!", "Pitch: %s. The investors bought %d%% of %s for %s." % [grade, int(equity * 100), b["name"], GameState.fmt_money(cash)], {"happiness": 10, "stress": 4})
			else:
				_done("🎤", "No deal", "Pitch: %s. The investors passed. One of them laughed." % grade, {"happiness": -6, "stress": 6})
		"cult_sermon":
			var c: Dictionary = p["cult"]
			if c.is_empty():
				return
			var dd := score * 30.0 - 8.0
			c["devotion"] = clampf(float(c["devotion"]) + dd, 0.0, 100.0)
			var new_m := int(score * 12.0 * float(DOCTRINES[c["doctrine"]]["recruit"]))
			var lost := 0 if score >= 0.35 else randi_range(1, 6)
			c["members"] = maxi(0, int(c["members"]) + new_m - lost)
			var text2 := ""
			if score >= 0.8:
				text2 = "Sermon: %s. The hall fell silent, then erupted. Some of them fainted." % grade
			elif score >= 0.45:
				text2 = "Sermon: %s. My followers nodded along and stayed for the potluck." % grade
			else:
				text2 = "Sermon: %s. People checked their phones. %d walked out for good." % [grade, lost]
			_done("🕯️", "Sermon", text2 + " Devotion is %d%%." % int(c["devotion"]), {"happiness": 4 if score >= 0.45 else -3})
