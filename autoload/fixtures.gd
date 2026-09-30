extends Node

## FIXTURES — a world with furniture.
##
## Until now the pub was "a pub", the school was "your school" and the hospital
## was "the hospital". Nothing you met was a particular place, so nothing you
## remembered was either. Each place is now invented once, the first time it is
## needed, and then kept for the life: the pub you drank in at nineteen is the
## same one you see closed at sixty.
##
## Text reaches them through {fx.pub}, {fx.street}, {fx.school} and so on.

const KINDS := ["street", "pub", "cafe", "shop", "bakery", "park", "gym", "primary", "secondary", "hospital", "surgery", "paper", "station", "church", "market", "library"]

const STREET_A := ["Elm", "Mill", "Church", "Station", "Bridge", "Orchard", "Park", "Victoria", "Albert", "Chapel", "Meadow", "Kiln", "Maple", "Harbour", "Cedar", "Quarry", "Willow", "Beacon"]
const STREET_B := ["Street", "Road", "Lane", "Avenue", "Terrace", "Close", "Row", "Way", "Court", "Drive"]
const PUB_A := ["Red", "Crown", "Golden", "Royal", "Black", "White", "Old", "Three", "Lamb", "Plough", "Fox", "Swan", "Bell", "Rose", "Anchor"]
const PUB_B := ["Lion", "and Anchor", "Oak", "Horse", "Arms", "Inn", "Tavern", "Cross Keys", "Head", "Barrels", "Fox", "Compass"]
const CAFE := ["Bean There", "The Daily Grind", "Cup & Saucer", "Nell's", "The Teapot", "Kettle & Crumb", "Corner House Coffee", "Ritchie's", "Mabel's", "The Rusty Spoon"]
const SHOP := ["Patel's", "Corner Shop", "Kowalski & Son", "Mehmet's", "Dawson's", "Friendly Grocer", "Nisha's Mini Market", "The Little Spar", "Hughes Newsagent"]
const BAKERY := ["Crumb", "Baker's Dozen", "Golden Crust", "Flour & Co", "Rosa's Bakery", "The Bun Shop", "Hearth"]
const PARK := ["Memorial Park", "Victoria Park", "the Rec", "Cherry Tree Green", "Riverside Gardens", "the Common", "Hilltop Park", "Kingsway Fields"]
const GYM := ["PowerHouse Gym", "Iron Works", "FitLife", "The Pump Room", "Anytime Fitness", "Leisure Centre", "Peak Gym"]
const SAINTS := ["St. Anne's", "St. Michael's", "St. Mary's", "St. Joseph's", "St. Luke's", "Holy Cross", "All Saints"]
const TREES := ["Oakfield", "Ashdown", "Elmwood", "Beechwood", "Hawthorn", "Riverside", "Heathfield", "Greenfield", "Northgate", "Westbrook"]
const PAPERS := ["Gazette", "Courier", "Herald", "Echo", "Chronicle", "Post", "Advertiser"]
const MARKETS := ["Saturday market", "the Corn Exchange", "the Sunday market", "the covered market", "Lakeside market"]
const LIBS := ["the Carnegie library", "Central Library", "the little library", "the branch library"]


func _st() -> Dictionary:
	var p := GameState.player
	if p.is_empty():
		return {}
	if not p.has("fixtures") or not (p["fixtures"] is Dictionary):
		p["fixtures"] = {}
	return p["fixtures"]


func place_name() -> String:
	return str(Places.region().get("city", "town"))


## The name of a fixture, invented the first time it is asked for.
func named(kind: String) -> String:
	if GameState.player.is_empty():
		return _generic(kind)
	var st := _st()
	if not st.has(kind):
		st[kind] = _invent(kind)
	return str(st[kind])


func _generic(kind: String) -> String:
	return {"street": "the street", "pub": "the pub", "cafe": "the cafe", "shop": "the corner shop", "bakery": "the bakery", "park": "the park", "gym": "the gym", "primary": "primary school", "secondary": "high school", "hospital": "the hospital", "surgery": "the clinic", "paper": "the local paper", "station": "the station", "church": "the church", "market": "the market", "library": "the library"}.get(kind, "the place")


func _pick(a: Array) -> String:
	return str(a[randi() % a.size()])


func _invent(kind: String) -> String:
	var city := place_name()
	match kind:
		"street": return "%s %s" % [_pick(STREET_A), _pick(STREET_B)]
		"pub": return "The %s %s" % [_pick(PUB_A), _pick(PUB_B)]
		"cafe": return _pick(CAFE)
		"shop": return _pick(SHOP)
		"bakery": return _pick(BAKERY)
		"park": return _pick(PARK)
		"gym": return _pick(GYM)
		"primary": return "%s Primary School" % _pick(TREES)
		"secondary": return "%s High School" % _pick(TREES) if randf() < 0.6 else "%s Academy" % _pick(TREES)
		"hospital": return "%s General Hospital" % (city if randf() < 0.5 else _pick(SAINTS).replace("St. ", "St ").replace("'s", ""))
		"surgery": return "%s Surgery" % _pick(TREES)
		"paper": return "the %s %s" % [city, _pick(PAPERS)]
		"station": return "%s Station" % (city if randf() < 0.6 else _pick(STREET_A))
		"church": return _pick(SAINTS)
		"market": return _pick(MARKETS)
		"library": return _pick(LIBS)
	return _generic(kind)


## The place you work, invented once per job and kept until you change jobs.
func employer() -> String:
	var p := GameState.player
	if p.is_empty() or not GameState.has_job():
		return "the firm"
	var j: Dictionary = p["job"]
	if not j.has("employer_name"):
		var kind := str(j.get("title", "")).to_lower()
		var first: Array = ["Halden", "Brightwell", "Corvin", "Ashby", "Northfield", "Lumen", "Kestrel", "Marlow", "Pryor", "Tandem", "Greaves", "Fairlight"]
		var tail: Array = ["& Sons", "Partners", "Group", "Holdings", "Systems", "Services", "Co.", "Logistics", "Works", "Associates"]
		j["employer_name"] = "%s %s" % [_pick(first), _pick(tail)]
	return str(j["employer_name"])
