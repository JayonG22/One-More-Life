extends Node

## Stores and the things you own. Most items carry a tag that other systems
## check: rings for proposals, phones and cameras for social media, rods for
## fishing, lock picks for burglary, luck charms for the lottery, and so on.
## Heirlooms have powers of their own.

const STORES := {
	"jeweler": {"name": "Jeweler", "icon": "💎", "sub": "Engagement rings, necklaces, watches"},
	"shady": {"name": "A guy in an alley", "icon": "🕶️", "sub": "\"Genuine\" diamonds, cheap"},
	"electronics": {"name": "Electronics store", "icon": "📱", "sub": "Phones, computers, cameras, consoles"},
	"sports": {"name": "Sporting goods", "icon": "🏀", "sub": "Bikes, gym gear, rods, bows, rifles, scuba"},
	"music": {"name": "Music shop", "icon": "🎸", "sub": "Instruments and DJ gear"},
	"fashion": {"name": "Clothing & accessories", "icon": "👔", "sub": "Suits, designer outfits, sunglasses"},
	"novelty": {"name": "Novelty shop", "icon": "🔮", "sub": "Lucky charms, gadgets, pranks, oddities"},
	"books": {"name": "Bookstore", "icon": "📚", "sub": "Encyclopedias, self-help, cookbooks"},
	"motors": {"name": "Motorcycle dealer", "icon": "🏍️", "sub": "Scooters and motorcycles"},
	"boats": {"name": "Boat dealer", "icon": "🚤", "sub": "Kayaks to yachts · boating license"},
	"aircraft": {"name": "Aircraft broker", "icon": "✈️", "sub": "Ultralights to jets · pilot's license"},
	"collect": {"name": "Art & collectibles", "icon": "🖼️", "sub": "Investments with a story"},
}


## ---------------------------------------------------------------- brand houses
##
## The flair of shopping is not the object, it is whose name is on it and what
## that name is supposed to mean about you. These houses are invented - using a
## real maker's name would be someone else's trademark, and the project's own
## originality rules rule it out - but each has a history, a reputation and a
## price it can command, which is the part that actually plays.
##
## [name, blurb, price multiplier, yearly value multiplier, looks bonus]
const HOUSES := {
	"value":    ["Marrow & Lint", "A catalogue brand since 1961. Nobody's dream, everybody's first one.", 0.72, 0.90, 0],
	"solid":    ["Harrowgate", "Family-run, unfashionable, and quietly the one that outlasts the others.", 1.0, 1.0, 0],
	"design":   ["Voss Aurel", "A design house that became famous for refusing to explain itself.", 1.65, 1.04, 1],
	"heritage": ["Castellane Frères", "Founded 1848. Four generations, two wars, one unchanged workshop.", 3.1, 1.10, 2],
	"street":   ["NOCTURNE//", "Started as a market stall. Drops sell out in ninety seconds.", 1.9, 1.16, 1],
	"bespoke":  ["Aldridge & Wray", "They do not have a shop. You are introduced, or you are not.", 5.4, 1.14, 3],
}

## Which houses stock which kind of shop.
const HOUSE_STOCK := {
	"jeweler": ["solid", "heritage", "bespoke"],
	"electronics": ["value", "solid", "design"],
	"sports": ["value", "solid", "design"],
	"music": ["solid", "heritage", "design"],
	"fashion": ["value", "design", "street", "bespoke"],
	"novelty": ["value", "street"],
	"books": ["value", "solid", "heritage"],
	"motors": ["solid", "design", "heritage"],
	"boats": ["solid", "design", "bespoke"],
	"aircraft": ["solid", "bespoke"],
	"collect": ["heritage", "design", "bespoke"],
}

const EDITIONS := [
	["", "", 1.0, 1.0],
	["Numbered edition", "One of %d ever made, with the number stamped where only you will look for it.", 1.55, 1.22],
	["Archive reissue", "A reissue of a %d-era original, made on the same tooling.", 1.3, 1.12],
]


## Ask whose version of this thing you actually want. Same object, different
## name on it, different price, different worth in twenty years.
func _offer_versions(sid: String, idx: int, d: Array) -> void:
	var choices: Array = []
	for hkey in houses_for(sid):
		var h: Array = HOUSES[hkey]
		var base := Actions._cost(int(round(float(d[2]) * float(h[2]))))
		var keep := "holds its value" if float(h[3]) >= 1.02 else ("loses value fast" if float(h[3]) < 0.95 else "depreciates normally")
		choices.append({
			"label": "%s  —  %s  ·  %s" % [str(h[0]), GameState.fmt_money(base), keep],
			"outcomes": [{"text": "", "no_friction": true, "shop_buy": {"store": sid, "idx": idx, "house": hkey, "edition": 0}}],
		})
	# A limited run only exists sometimes, which is the entire idea of a limited run.
	if randf() < 0.33:
		var hk: String = houses_for(sid)[-1]
		var hh: Array = HOUSES[hk]
		var lp := Actions._cost(int(round(float(d[2]) * float(hh[2]) * 1.55)))
		choices.append({
			"label": "%s, numbered edition  —  %s  ·  appreciates" % [str(hh[0]), GameState.fmt_money(lp)],
			"outcomes": [{"text": "", "no_friction": true, "shop_buy": {"store": sid, "idx": idx, "house": hk, "edition": 1}}],
		})
	choices.append({"label": "Leave it", "outcomes": [{"text": "", "no_friction": true}]})
	EventEngine.push_decision({
		"id": "_shop_" + sid,
		"icon": str(d[1]),
		"title": str(d[0]),
		"text": "Same object, different name on the back of it. What you pay for is partly the thing and partly whose it is.",
		"no_friction": true,
		"choices": choices,
	})


func houses_for(sid: String) -> Array:
	return HOUSE_STOCK.get(sid, ["value", "solid"])


## Anything with a name on it is worth something to somebody later.
func _house_of(it: Dictionary) -> Dictionary:
	var key := str(it.get("house", ""))
	return HOUSES.get(key, {})


## [name, icon, price, tag, depreciation per year, extra]
const ITEMS := {
	"jeweler": [
		["Promise ring", "💍", 150, "ring", 0.1, {}], ["Gold wedding band", "💍", 1200, "ring", 0.02, {}],
		["Diamond engagement ring", "💍", 6500, "ring", 0.02, {}], ["Platinum solitaire ring", "💎", 22000, "ring", 0.01, {}],
		["Pearl earrings", "🦪", 900, "jewelry", 0.02, {"looks": 1}], ["Diamond necklace", "💎", 18000, "jewelry", 0.01, {"looks": 2}],
		["Luxury watch", "⌚", 26000, "watch", 0.0, {"looks": 1}],
	],
	"shady": [
		["\"Diamond\" ring", "💍", 60, "fake_ring", 0.5, {}], ["\"Designer\" watch", "⌚", 40, "fake_watch", 0.5, {}],
	],
	"electronics": [
		["Budget smartphone", "📱", 150, "phone", 0.35, {}], ["Flagship smartphone", "📱", 1100, "phone", 0.3, {"quality": 1}],
		["Laptop", "💻", 1100, "laptop", 0.25, {}], ["Gaming PC", "🖥️", 2200, "gaming_pc", 0.2, {}],
		["Game console", "🎮", 500, "console", 0.2, {}], ["Webcam & microphone", "🎙️", 250, "webcam", 0.25, {}],
		["Pro camera", "📷", 1800, "camera", 0.15, {}], ["VR headset", "🥽", 450, "vr", 0.3, {}],
		["Drone", "🛸", 900, "drone", 0.2, {}], ["Smart TV", "📺", 800, "tv", 0.2, {}],
	],
	"sports": [
		["Bicycle", "🚲", 400, "bike", 0.1, {}], ["Home gym", "🏋️", 1500, "home_gym", 0.1, {}],
		["Fishing rod & tackle", "🎣", 180, "rod", 0.1, {}], ["Pro fishing rig", "🎣", 900, "rod_pro", 0.08, {}],
		["Hunting bow", "🏹", 600, "bow", 0.08, {}], ["Hunting rifle", "🔫", 900, "rifle", 0.05, {"license": "firearms", "guns": true}],
		["Scuba gear", "🤿", 1400, "scuba_gear", 0.08, {}], ["Tent & camping gear", "⛺", 300, "tent", 0.1, {}],
		["Surfboard", "🏄", 500, "surf", 0.08, {}], ["Golf clubs", "🏌️", 1200, "golf", 0.05, {}],
		["Boxing gloves", "🥊", 80, "gloves", 0.1, {}], ["Skateboard", "🛹", 120, "skate", 0.15, {}],
	],
	"music": [
		["Kazoo", "🎺", 5, "kazoo", 0.0, {}], ["Ukulele", "🪕", 90, "instrument", 0.05, {}],
		["Acoustic guitar", "🎸", 300, "instrument", 0.05, {}], ["Electric guitar & amp", "🎸", 900, "instrument", 0.05, {}],
		["Keyboard", "🎹", 500, "instrument", 0.05, {}], ["Drum kit", "🥁", 1200, "instrument", 0.05, {}],
		["Violin", "🎻", 700, "instrument", 0.03, {}], ["Saxophone", "🎷", 1500, "instrument", 0.03, {}],
		["DJ decks", "🎛️", 800, "dj", 0.1, {}], ["Microphone", "🎤", 200, "mic", 0.1, {}],
	],
	"fashion": [
		["Casual wardrobe refresh", "👕", 300, "clothes", 0.5, {"looks": 1}], ["Tailored suit", "🤵", 600, "suit", 0.15, {}],
		["Designer outfit", "👗", 2500, "designer", 0.25, {"looks": 3}], ["Sunglasses", "🕶️", 150, "sunglasses", 0.2, {"looks": 1}],
		["Designer handbag", "👜", 3000, "bag", 0.1, {"looks": 1}], ["Fresh sneakers", "👟", 200, "sneakers", 0.3, {}],
		["Party costume", "🦸", 80, "costume", 0.3, {}], ["Wedding dress or tux", "👰", 2000, "wedding_wear", 0.3, {}],
	],
	"novelty": [
		["Magic 8-Ball", "🎱", 15, "eightball", 0.0, {}], ["Lucky rabbit's foot", "🐇", 25, "luck", 0.0, {}],
		["Four-leaf clover charm", "🍀", 40, "luck", 0.0, {}], ["Ouija board", "👻", 35, "ouija", 0.0, {}],
		["Metal detector", "🧲", 250, "detector", 0.05, {}], ["Telescope", "🔭", 400, "telescope", 0.05, {}],
		["Karaoke machine", "🎤", 200, "karaoke", 0.1, {}], ["Chemistry set", "🧪", 60, "chemset", 0.1, {}],
		["Crystal ball", "🔮", 120, "crystal", 0.0, {}], ["Whoopee cushion", "💨", 5, "prank", 0.0, {}],
		["Fake mustache kit", "🥸", 15, "disguise", 0.0, {}], ["Lock pick set", "🗝️", 70, "lockpick", 0.0, {}],
		["Night-vision goggles", "🥽", 600, "nightvision", 0.05, {}], ["Pepper spray", "🌶️", 20, "spray", 0.0, {}],
		["Baseball bat", "⚾", 60, "bat", 0.0, {}], ["Board game collection", "🎲", 120, "boardgames", 0.05, {}],
	],
	"books": [
		["Encyclopedia set", "📚", 300, "books", 0.02, {}], ["Self-help shelf", "📗", 120, "selfhelp", 0.02, {}],
		["Cookbook collection", "📙", 80, "cookbook", 0.02, {}], ["Coding bootcamp books", "📘", 150, "codebooks", 0.02, {}],
	],
	"motors": [
		["Scooter", "🛵", 2000, "scooter", 0.12, {}], ["Motorcycle", "🏍️", 9000, "motorcycle", 0.1, {"license": "motorcycle"}],
		["Dirt bike", "🏍️", 5000, "dirtbike", 0.12, {"license": "motorcycle"}],
	],
	"boats": [
		["Kayak", "🛶", 600, "kayak", 0.05, {}], ["Jet ski", "🚤", 12000, "boat", 0.12, {"license": "boating"}],
		["Fishing boat", "🚤", 28000, "boat", 0.08, {"license": "boating"}], ["Speedboat", "🚤", 65000, "boat", 0.1, {"license": "boating"}],
		["Yacht", "🛥️", 1500000, "yacht", 0.05, {"license": "boating"}],
	],
	"aircraft": [
		["Ultralight", "🪂", 25000, "plane", 0.08, {"license": "pilot"}], ["Single-engine plane", "🛩️", 180000, "plane", 0.06, {"license": "pilot"}],
		["Helicopter", "🚁", 900000, "plane", 0.06, {"license": "pilot"}], ["Private jet", "🛩️", 9000000, "jet", 0.05, {"license": "pilot"}],
	],
}

## Heirloom name -> [tag, what it does]
const HEIR_POWERS := {
	"Brass pocket watch": ["punctual", "Never late: small work boost every year"],
	"Silver spoon set": ["host", "Parties and holidays go better"],
	"Old brass compass": ["compass", "More finds when hiking and traveling"],
	"Hand-stitched quilt": ["cozy", "A little less stress every year"],
	"First-pressing vinyl": ["vinyl", "A little happier every year"],
	"Grandpa's coin jar": ["luck", "Better lottery and casino luck"],
	"Pearl necklace": ["charm", "Looks and dates"],
	"Antique mantel clock": ["cozy", "A little less stress every year"],
	"First-edition novel": ["scholar", "A little smarter every year"],
	"Jade figurine": ["luck", "Better lottery and casino luck"],
	"Vintage camera": ["camera", "Better photos on social media"],
	"Porcelain vase": ["fragile", "Beautiful. Breaks if you move carelessly"],
	"Antique violin": ["instrument", "Counts as an instrument, and a fine one"],
	"Ceremonial sword": ["sword", "Wins fights and scares off burglars"],
	"Sapphire brooch": ["charm", "Looks and dates"],
	"Jeweled egg": ["treasure", "Just very, very valuable"],
	"Diamond tiara": ["regal", "Fame, and royal respect"],
	"Old master sketch": ["treasure", "Museums would kill for it"],
	"Fossilized dinosaur egg": ["scholar", "A little smarter every year"],
	"Iron meteorite": ["cosmic", "Astronauts and dreamers do better"],
	"Royal scepter": ["regal", "Fame, and royal respect"],
	"A long-lost masterpiece": ["treasure", "Museums would kill for it"],
	"Pirate treasure chest": ["luck", "Better lottery and casino luck"],
	"An emperor's signed letter": ["scholar", "A little smarter every year"],
}


func _p() -> Dictionary:
	return GameState.player


func owned() -> Array:
	return _p().get("possessions", [])


func tag_of(it: Dictionary) -> String:
	if it.has("tag"):
		return str(it["tag"])
	if it.get("heirloom", false):
		for k in HEIR_POWERS.keys():
			if str(it.get("name", "")).ends_with(k.to_lower()) or str(it.get("name", "")) == k or str(it.get("name", "")).to_lower().ends_with(k.to_lower()):
				return str(HEIR_POWERS[k][0])
	return ""


func has_tag(tag: String) -> bool:
	for it in owned():
		if tag_of(it) == tag:
			return true
	return false


func has_any(tags: Array) -> bool:
	for t in tags:
		if has_tag(t):
			return true
	return false


func count_tag(tag: String) -> int:
	var c := 0
	for it in owned():
		if tag_of(it) == tag:
			c += 1
	return c


func luck() -> float:
	return 1.0 + 0.25 * mini(3, count_tag("luck"))


func power_text(it: Dictionary) -> String:
	if it.get("heirloom", false):
		for k in HEIR_POWERS.keys():
			if str(it.get("name", "")).to_lower().ends_with(k.to_lower()):
				return HEIR_POWERS[k][1]
	match tag_of(it):
		"ring": return "Makes a proposal far more likely to land"
		"fake_ring": return "Might fool someone. Probably not"
		"phone": return "Needed to post on social media"
		"laptop": return "Online courses and freelance gigs go better"
		"gaming_pc": return "Stream games, and more fun from video games"
		"console": return "More fun from video games; stream console games"
		"webcam": return "Needed to go live"
		"camera": return "Better photos and videos"
		"rod", "rod_pro": return "Better fishing"
		"bow", "rifle": return "Needed to hunt"
		"scuba_gear": return "Cheaper, safer cave dives"
		"tent": return "Better camping trips"
		"bike": return "Walks become bike rides: more health"
		"home_gym": return "Your gym routine does more"
		"instrument": return "Better music lessons, busking and gigs"
		"suit": return "Job interviews go better"
		"designer": return "Looks, dates and red carpets"
		"luck": return "Better luck at the lottery and casino"
		"eightball": return "Ask it anything"
		"ouija": return "Talk to the other side. Maybe"
		"detector": return "Search beaches and parks for treasure"
		"telescope": return "Stargazing: smarts and calm"
		"karaoke": return "Parties go better"
		"chemset": return "A great gift for a curious kid"
		"crystal": return "Witches draw more mana from it"
		"prank": return "Pranks land better"
		"disguise": return "Less likely to be recognized during crimes"
		"lockpick": return "Burglaries go better"
		"nightvision": return "Night hunts and night crimes go better"
		"spray", "bat": return "Fight off muggers"
		"boat", "yacht": return "Deep-sea fishing and days on the water"
		"plane", "jet": return "Fly yourself on vacations"
		"motorcycle", "dirtbike": return "Dirt biking and a faster commute"
		"books": return "Read at home for extra smarts"
		"selfhelp": return "Therapy-lite: less stress"
		"cookbook": return "Cook for people: better dinners and dates"
		"codebooks": return "Tech jobs and courses go better"
		"boardgames": return "Family nights go better"
	return ""


# ================================================================ menus

func menu(key: String) -> Dictionary:
	if _p().is_empty():
		return {"icon": "🛍️", "title": "Shopping", "rows": []}
	if key == "" or key == "root":
		var rows: Array = []
		for sid in STORES.keys():
			var s: Dictionary = STORES[sid]
			rows.append({"icon": s["icon"], "name": s["name"], "sub": s["sub"], "menu": "shop:" + sid, "on": _store_open(sid) == ""})
		rows.append({"icon": "🎒", "name": "Your stuff", "sub": "%d items · what they do, sell, use" % owned().size(), "menu": "shop:mine", "on": true})
		return {"icon": "🛍️", "title": "Shopping", "rows": rows}
	if key == "mine":
		return _mine_menu()
	if key.begins_with("item:"):
		return item_menu(int(key.substr(5)))
	if key == "collect":
		var rows2: Array = []
		for i in range(Finance.SHOP.size()):
			var it: Dictionary = Finance.SHOP[i]
			var price := int(it["price"] * Finance._cost())
			rows2.append({"icon": it["icon"], "name": it["name"], "sub": "%s · %s" % [GameState.fmt_money(price), it["cat"]], "act": "shop:collect", "arg": i, "on": int(_p()["money"]) >= price})
		return {"icon": "🖼️", "title": "Art & collectibles", "rows": rows2}
	if not ITEMS.has(key):
		return {"icon": "🛍️", "title": "Shopping", "rows": []}
	var why := _store_open(key)
	var rows3: Array = []
	if why != "":
		rows3.append({"icon": "🔒", "name": why, "sub": "", "on": false})
	var list: Array = ITEMS[key]
	for i in range(list.size()):
		var d: Array = list[i]
		var price := Actions._cost(int(d[2]))
		var need := _need(d)
		var have := count_name(str(d[0]))
		var sub := GameState.fmt_money(price)
		if need != "":
			sub += " · 🔒 " + need
		elif have > 0:
			sub += " · you own %d" % have
		var fake := {"tag": d[3], "name": d[0]}
		var pw := power_text(fake)
		if pw != "":
			sub += " · " + pw
		rows3.append({"icon": d[1], "name": d[0], "sub": sub, "act": "shop:buy", "arg": [key, i], "on": need == "" and int(_p()["money"]) >= price and why == ""})
	return {"icon": STORES[key]["icon"], "title": STORES[key]["name"], "rows": rows3}


func _store_open(sid: String) -> String:
	if _p().is_empty():
		return "No life in progress"
	var age := int(_p().get("age", 0))
	match sid:
		"shady":
			return "" if age >= 14 else "Too young"
		"motors", "boats":
			return "" if age >= 16 else "Age 16+"
		"aircraft":
			return "" if age >= 18 else "Age 18+"
		"jeweler", "fashion", "collect":
			return "" if age >= 12 else "Age 12+"
	return "" if age >= 8 else "Age 8+"


func _need(d: Array) -> String:
	var era_why := Expansion.era_item_block(str(d[3]), str(d[0]))
	if era_why != "":
		return era_why
	var ex: Dictionary = d[5]
	if ex.has("license") and not Law.has_license(str(ex["license"])):
		return Law.LICENSES[ex["license"]]["name"] + " required"
	if ex.get("guns", false) and str(Places.law("guns")) == "banned":
		return "Banned in " + ContentDB.country(_p()["country"])["name"]
	return ""


func count_name(nm: String) -> int:
	var c := 0
	for it in owned():
		if str(it.get("name", "")) == nm:
			c += 1
	return c


func _mine_menu() -> Dictionary:
	var rows: Array = []
	var list := owned()
	for i in range(list.size()):
		var it: Dictionary = list[i]
		var pw := power_text(it)
		var sub := "Worth %s" % GameState.fmt_money(int(it.get("value", 0)))
		if pw != "":
			sub += " · " + pw
		if it.get("heirloom", false):
			sub = "Heirloom · " + sub
		rows.append({"icon": it.get("icon", "📦"), "name": str(it["name"]), "sub": sub, "menu": "shop:item:%d" % i, "on": true})
	if rows.is_empty():
		rows.append({"icon": "🫙", "name": "Nothing yet", "sub": "Go shopping, or open your daily heirloom", "on": false})
	return {"icon": "🎒", "title": "Your stuff", "rows": rows}


func item_menu(i: int) -> Dictionary:
	var list := owned()
	if i < 0 or i >= list.size():
		return _mine_menu()
	var it: Dictionary = list[i]
	var rows: Array = []
	var t := tag_of(it)
	var use := _use_label(t)
	if use != "":
		rows.append({"icon": "✨", "name": use, "sub": "1 time", "act": "shop:use", "arg": i, "on": true})
	rows.append({"icon": "💲", "name": "Sell it", "sub": "About %s" % GameState.fmt_money(int(int(it.get("value", 0)) * 0.8)), "act": "shop:sell", "arg": i, "on": true})
	return {"icon": it.get("icon", "📦"), "title": str(it["name"]), "rows": rows, "info": [power_text(it)]}


func _use_label(t: String) -> String:
	match t:
		"eightball": return "Ask the Magic 8-Ball a question"
		"ouija": return "Hold a séance"
		"detector": return "Go treasure hunting"
		"telescope": return "Stargaze"
		"karaoke": return "Karaoke night at home"
		"books": return "Read from the encyclopedia"
		"selfhelp": return "Read a self-help book"
		"cookbook": return "Cook something ambitious"
		"boardgames": return "Family game night"
		"console", "gaming_pc", "vr": return "Play games"
		"drone": return "Fly the drone"
		"kazoo": return "Play the kazoo"
		"crystal": return "Gaze into the crystal ball"
		"boat", "kayak": return "A day on the water"
		"plane": return "Take a scenic flight"
		"surf": return "Go surfing"
		"golf": return "Play a round of golf"
		"skate", "bike", "motorcycle": return "Go for a ride"
	return ""


# ================================================================ actions

func act(key: String, arg = null) -> void:
	var p := _p()
	match key:
		"buy":
			var sid: String = arg[0]
			var d: Array = ITEMS[sid][int(arg[1])]
			if _need(d) != "": return
			_offer_versions(sid, int(arg[1]), d)
		"buy_version":
			var sid: String = arg[0]
			var d: Array = ITEMS[sid][int(arg[1])]
			if _need(d) != "": return
			var hkey: String = str(arg[2])
			var ed: int = int(arg[3])
			var house: Array = HOUSES.get(hkey, HOUSES["solid"])
			var edition: Array = EDITIONS[clampi(ed, 0, EDITIONS.size() - 1)]
			var price := Actions._cost(int(round(float(d[2]) * float(house[2]) * float(edition[2]))))
			if not Actions._can_pay(price, str(d[0])): return
			p["money"] = int(p["money"]) - price
			var label := "%s %s" % [str(house[0]), str(d[0]).to_lower()]
			var it := {"name": label, "icon": d[1], "cat": STORES[sid]["name"], "value": price, "vol": 0.03,
				"dep": float(d[4]) / maxf(0.4, float(house[3])), "bought": price, "tag": d[3],
				"house": hkey, "edition": str(edition[0])}
			var story := str(house[1])
			if ed == 1:
				var run: int = [50, 100, 250, 500, 1000][randi() % 5]
				it["run"] = run
				it["serial"] = randi_range(1, run)
				it["name"] = "%s, one of %d" % [label, run]
				story += " " + (str(edition[1]) % run)
			elif ed == 2:
				var yr: int = [1958, 1967, 1974, 1983, 1991][randi() % 5]
				it["reissue"] = yr
				story += " " + (str(edition[1]) % yr)
			it["story"] = story
			p["possessions"].append(it)
			GameState.apply_effects({"looks": int(house[4])} if int(house[4]) > 0 else {})
			var ex: Dictionary = d[5]
			if ex.has("looks"):
				GameState.apply_effects({"looks": int(ex["looks"])})
			GameState.counter("purchases")
			GameState.counter("spent", price)
			if sid == "shady" and randf() < 0.25:
				Actions._done(d[1], "Bought", "I bought a %s for %s. The guy ran off before I could look at it closely." % [str(d[0]).to_lower().replace("\"", ""), GameState.fmt_money(price)], {"happiness": 1})
			else:
				Actions._done(d[1], "Bought", "I bought a %s for %s." % [str(d[0]).to_lower(), GameState.fmt_money(price)], {"happiness": 2 if price < 5000 else 6})
			if sid == "boats" or sid == "aircraft" or sid == "motors":
				GameState.add_milestone(p["age"], "bought a %s" % str(d[0]).to_lower())
		"collect":
			Finance.buy_item(int(arg))
		"sell":
			var i := int(arg)
			if i < 0 or i >= owned().size(): return
			var it2: Dictionary = owned()[i]
			var got := int(int(it2.get("value", 0)) * 0.8)
			owned().remove_at(i)
			p["money"] = int(p["money"]) + got
			Actions._done("💲", "Sold", "I sold my %s for %s." % [str(it2["name"]).to_lower(), GameState.fmt_money(got)], {"happiness": -2 if it2.get("heirloom", false) else 0})
		"use":
			_use(int(arg))


func _use(i: int) -> void:
	if i < 0 or i >= owned().size(): return
	var it: Dictionary = owned()[i]
	var t := tag_of(it)
	if Actions._out_of_time(): return
	var nm: String = str(it["name"]).to_lower()
	var r := randf()
	match t:
		"eightball":
			var q: String = ["Will I be rich?", "Does my crush like me back?", "Should I quit my job?", "Will I live to 100?", "Is my partner the one?"][randi() % 5]
			var a: String = ["It is certain.", "Reply hazy, try again.", "Don't count on it.", "Outlook good.", "My sources say no.", "Ask again later."][randi() % 6]
			Actions._done("🎱", "Magic 8-Ball", "I asked: \"%s\" The 8-Ball said: \"%s\"" % [q, a], {"happiness": 1})
		"ouija":
			if r < 0.15:
				Actions._done("👻", "Séance", "The planchette spelled out a name I didn't recognize. Then the lights went out. I slept with them on for a week.", {"stress": 10})
			elif r < 0.3 and GameState.npcs_with("grandparent", false).any(func(g): return not GameState.npcs[g]["alive"]):
				Actions._done("👻", "Séance", "The board spelled G-R-A-N-D-M-A and then S-T-O-P. I stopped.", {"stress": 6, "happiness": 2})
			else:
				Actions._done("👻", "Séance", "The planchette moved. I'm fairly sure my friend moved it.", {"happiness": 2})
		"detector":
			if r < 0.05:
				var val := Actions._cost(randi_range(2000, 25000))
				_p()["possessions"].append({"name": "Buried gold coin", "icon": "🪙", "cat": "Finds", "value": val, "vol": 0.1, "bought": 0, "find": true})
				Actions._done("🧲", "Treasure!", "BEEP BEEP BEEP. I dug up an old gold coin worth about %s!" % GameState.fmt_money(val), {"happiness": 12})
			elif r < 0.4:
				var small := randi_range(1, 40)
				Actions._done("🧲", "Metal detecting", "I found $%d in loose change and a very old key." % small, {"money": small, "happiness": 3})
			else:
				Actions._done("🧲", "Metal detecting", "Bottle caps. So many bottle caps.", {"happiness": 1, "health": 1})
		"telescope":
			Actions._done("🔭", "Stargazing", "I watched Saturn's rings for an hour. Everything else felt small.", {"smarts": 2, "stress": -5, "happiness": 3})
		"karaoke":
			for f in GameState.npcs_with("friend") + GameState.npcs_with("best_friend"):
				GameState.change_closeness(f, 4)
			Actions._done("🎤", "Karaoke", "Karaoke at my place. The neighbors know every word of my power ballad now.", {"happiness": 7, "stress": -4})
		"books":
			Actions._done("📚", "Encyclopedia", "I read everything about %s." % ["octopuses", "the Roman Empire", "black holes", "volcanoes", "the history of cheese"][randi() % 5], {"smarts": 4})
		"selfhelp":
			Actions._done("📗", "Self-help", "I read about %s. I feel like a slightly better person." % ["setting boundaries", "habits", "gratitude", "saying no"][randi() % 4], {"stress": -6, "happiness": 2})
		"cookbook":
			if r < 0.25:
				Actions._done("📙", "Cooking", "I attempted a soufflé. The smoke alarm reviewed it.", {"happiness": -2})
			else:
				if _p()["partner"] != "":
					GameState.change_closeness(_p()["partner"], 6)
				Actions._done("📙", "Cooking", "I cooked a proper three-course dinner. I'm basically a chef.", {"happiness": 5, "health": 1})
		"boardgames":
			for rel in ["mother", "father", "sibling", "child", "partner"]:
				for fid in GameState.npcs_with(rel):
					GameState.change_closeness(fid, 5)
			Actions._done("🎲", "Game night", "Family game night. Someone flipped the Monopoly board. Tradition.", {"happiness": 6})
		"console", "gaming_pc", "vr":
			Actions._done(it.get("icon", "🎮"), "Gaming", "I played %s until my eyes hurt." % ["a new open-world game", "an online shooter", "a cozy farming game", "a horror game"][randi() % 4], {"happiness": 7, "stress": -4, "health": -1})
		"drone":
			if r < 0.12:
				owned().remove_at(i)
				Actions._done("🛸", "Drone", "I flew my drone into a tree. The tree won.", {"happiness": -5})
			else:
				Actions._done("🛸", "Drone", "I got incredible aerial footage of the city at sunset.", {"happiness": 5})
		"kazoo":
			Actions._done("🎺", "Kazoo", "I performed a kazoo solo. Nobody asked for it.", {"happiness": 4})
		"crystal":
			if Lives.is_type("witch"):
				Lives.life()["mana"] = mini(100, int(Lives.life()["mana"]) + 20)
				Actions._done("🔮", "Crystal ball", "The crystal hummed under my hands. Mana flowed back into me.", {"stress": -3})
			else:
				Actions._done("🔮", "Crystal ball", "I stared into the crystal ball. I saw my own reflection, looking silly.", {"happiness": 1})
		"boat", "kayak", "yacht":
			Actions._done(it.get("icon", "🚤"), "On the water", "I spent a whole day out on my %s. Sunburned and happy." % nm, {"happiness": 8, "stress": -8})
		"plane", "jet":
			Actions._done("🛩️", "Scenic flight", "I flew my %s along the coast at golden hour." % nm, {"happiness": 9, "stress": -6})
		"surf":
			if r < 0.1:
				Actions._done("🏄", "Surfing", "I wiped out hard and ate half the ocean.", {"health": -5})
			else:
				Actions._done("🏄", "Surfing", "I caught a perfect wave. Just one, but it counts.", {"health": 3, "happiness": 6})
		"golf":
			Actions._done("🏌️", "Golf", "I shot a %d. I'm telling everyone it was lower." % randi_range(78, 120), {"happiness": 4, "stress": -3})
		"skate", "bike", "motorcycle":
			if r < 0.07:
				Actions._done(it.get("icon", "🚲"), "Ride", "I crashed on my %s. Road rash everywhere." % nm, {"health": -8})
			else:
				Actions._done(it.get("icon", "🚲"), "Ride", "I took my %s out for a long ride." % nm, {"health": 3, "happiness": 4, "stress": -3})


# ================================================================ yearly

func yearly() -> void:
	var p := _p()
	var list := owned()
	for it in list:
		var dep := float(it.get("dep", 0.0))
		if dep > 0.0:
			it["value"] = maxi(0, int(int(it["value"]) * (1.0 - dep)))
	var fx := {}
	if has_tag("cozy"): fx["stress"] = int(fx.get("stress", 0)) - 2
	if has_tag("vinyl"): fx["happiness"] = int(fx.get("happiness", 0)) + 1
	if has_tag("scholar"): fx["smarts"] = int(fx.get("smarts", 0)) + 1
	if has_tag("punctual") and GameState.has_job(): fx["job_perf"] = 2
	if has_tag("regal") and Lives.is_type("royal"):
		Lives.life()["respect"] = minf(100.0, float(Lives.life()["respect"]) + 2.0)
	if has_tag("home_gym") and p["routines"].get("gym", false): fx["health"] = int(fx.get("health", 0)) + 1
	if not fx.is_empty():
		GameState.apply_effects(fx)
