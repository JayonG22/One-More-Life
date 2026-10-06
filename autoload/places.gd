extends Node

## Where you live matters: each country has its own laws, and each state or
## city has its own economy, hazards, crime and scene.

const LAWS := {
	"us": {"drive": 16, "drink": 21, "gambling": "legal", "guns": "permit", "death_penalty": true, "healthcare": "private", "tuition": 1.0, "tax": 0.22, "corruption": 0.04, "police": 1.0, "crime": 1.1, "hunting": true, "conscription": false},
	"uk": {"drive": 17, "drink": 18, "gambling": "legal", "guns": "banned", "death_penalty": false, "healthcare": "free", "tuition": 0.8, "tax": 0.26, "corruption": 0.03, "police": 0.95, "crime": 0.9, "hunting": true, "conscription": false},
	"de": {"drive": 18, "drink": 16, "gambling": "legal", "guns": "strict", "death_penalty": false, "healthcare": "free", "tuition": 0.05, "tax": 0.32, "corruption": 0.03, "police": 0.95, "crime": 0.8, "hunting": true, "conscription": false},
	"jp": {"drive": 18, "drink": 20, "gambling": "restricted", "guns": "banned", "death_penalty": true, "healthcare": "free", "tuition": 0.6, "tax": 0.24, "corruption": 0.02, "police": 1.3, "crime": 0.5, "hunting": true, "conscription": false},
	"fr": {"drive": 18, "drink": 18, "gambling": "legal", "guns": "strict", "death_penalty": false, "healthcare": "free", "tuition": 0.05, "tax": 0.3, "corruption": 0.04, "police": 0.95, "crime": 0.9, "hunting": true, "conscription": false},
	"br": {"drive": 18, "drink": 18, "gambling": "banned", "guns": "strict", "death_penalty": false, "healthcare": "public", "tuition": 0.3, "tax": 0.2, "corruption": 0.22, "police": 0.9, "crime": 1.5, "hunting": false, "conscription": true},
	"mx": {"drive": 18, "drink": 18, "gambling": "legal", "guns": "strict", "death_penalty": false, "healthcare": "public", "tuition": 0.2, "tax": 0.2, "corruption": 0.28, "police": 0.85, "crime": 1.5, "hunting": true, "conscription": false},
	"ph": {"drive": 17, "drink": 18, "gambling": "legal", "guns": "permit", "death_penalty": false, "healthcare": "public", "tuition": 0.2, "tax": 0.2, "corruption": 0.3, "police": 1.1, "crime": 1.2, "hunting": false, "conscription": false},
	"ng": {"drive": 18, "drink": 18, "gambling": "legal", "guns": "banned", "death_penalty": true, "healthcare": "private", "tuition": 0.2, "tax": 0.15, "corruption": 0.38, "police": 1.1, "crime": 1.4, "hunting": false, "conscription": false},
}

const REGIONS := {
	"us": [
		{"id": "ca", "name": "California", "city": "Los Angeles", "cost": 1.35, "pay": 1.3, "crime": 1.1, "unemployment": 0.055, "education": 1.05, "transit": 0.4, "housing": 1.5, "hazard": "earthquake", "scene": ["tech", "studio"], "blurb": "Sunshine, startups, studios and earthquakes."},
		{"id": "ny", "name": "New York", "city": "New York City", "cost": 1.45, "pay": 1.35, "crime": 1.1, "unemployment": 0.05, "education": 1.05, "transit": 0.95, "housing": 1.6, "hazard": "blizzard", "scene": ["consulting", "fashion"], "blurb": "The city that never sleeps, or lets you afford rent."},
		{"id": "tx", "name": "Texas", "city": "Houston", "cost": 0.9, "pay": 1.0, "crime": 1.0, "unemployment": 0.045, "education": 0.95, "transit": 0.2, "housing": 0.9, "hazard": "hurricane", "scene": ["construction", "dealership"], "blurb": "Big trucks, big sky, no state income tax.", "laws": {"tax": 0.15, "guns": "loose"}},
		{"id": "fl", "name": "Florida", "city": "Miami", "cost": 1.05, "pay": 0.95, "crime": 1.1, "unemployment": 0.04, "education": 0.95, "transit": 0.25, "housing": 1.1, "hazard": "hurricane", "scene": ["restaurant", "zoo"], "blurb": "Beaches, retirees and hurricane season.", "laws": {"tax": 0.15}},
		{"id": "nv", "name": "Nevada", "city": "Las Vegas", "cost": 0.95, "pay": 0.95, "crime": 1.2, "unemployment": 0.06, "education": 0.9, "transit": 0.25, "housing": 1.0, "hazard": "heatwave", "scene": ["restaurant"], "blurb": "The casinos never close.", "laws": {"tax": 0.15, "gambling": "vegas"}},
		{"id": "oh", "name": "Ohio", "city": "Columbus", "cost": 0.8, "pay": 0.85, "crime": 0.9, "unemployment": 0.045, "education": 1.0, "transit": 0.3, "housing": 0.75, "hazard": "tornado", "scene": ["gym"], "blurb": "Quiet, affordable and very normal.", "laws": {"death_penalty": true}},
	],
	"uk": [
		{"id": "ldn", "name": "Greater London", "city": "London", "cost": 1.5, "pay": 1.35, "crime": 1.2, "unemployment": 0.05, "education": 1.1, "transit": 0.95, "housing": 1.7, "hazard": "flood", "scene": ["consulting", "fashion", "studio"], "blurb": "Finance, theatre, and a flat the size of a cupboard."},
		{"id": "man", "name": "Greater Manchester", "city": "Manchester", "cost": 0.95, "pay": 0.95, "crime": 1.0, "unemployment": 0.055, "education": 1.0, "transit": 0.7, "housing": 0.95, "hazard": "flood", "scene": ["label", "gym"], "blurb": "Football, music and rain."},
		{"id": "edi", "name": "Scotland", "city": "Edinburgh", "cost": 1.0, "pay": 0.95, "crime": 0.8, "unemployment": 0.045, "education": 1.05, "transit": 0.7, "housing": 1.05, "hazard": "storm", "scene": ["restaurant"], "blurb": "Castles, festivals and free university.", "laws": {"tuition": 0.0}},
		{"id": "cor", "name": "Cornwall", "city": "Truro", "cost": 0.85, "pay": 0.8, "crime": 0.6, "unemployment": 0.04, "education": 0.95, "transit": 0.3, "housing": 0.95, "hazard": "storm", "scene": ["restaurant", "zoo"], "blurb": "Surf, pasties and quiet villages."},
	],
	"de": [
		{"id": "ber", "name": "Berlin", "city": "Berlin", "cost": 1.1, "pay": 1.05, "crime": 1.1, "unemployment": 0.07, "education": 1.05, "transit": 0.95, "housing": 1.2, "hazard": "heatwave", "scene": ["tech", "label"], "blurb": "Techno, startups and history on every corner."},
		{"id": "bay", "name": "Bavaria", "city": "Munich", "cost": 1.25, "pay": 1.2, "crime": 0.7, "unemployment": 0.035, "education": 1.1, "transit": 0.8, "housing": 1.4, "hazard": "flood", "scene": ["dealership", "aerospace"], "blurb": "Beer halls, cars and Alpine views."},
		{"id": "ham", "name": "Hamburg", "city": "Hamburg", "cost": 1.15, "pay": 1.1, "crime": 0.9, "unemployment": 0.06, "education": 1.05, "transit": 0.9, "housing": 1.25, "hazard": "flood", "scene": ["consulting", "construction"], "blurb": "A harbor city of trade and media."},
		{"id": "sax", "name": "Saxony", "city": "Leipzig", "cost": 0.8, "pay": 0.85, "crime": 0.9, "unemployment": 0.065, "education": 1.0, "transit": 0.75, "housing": 0.75, "hazard": "flood", "scene": ["label"], "blurb": "Cheap rent and a growing art scene."},
	],
	"jp": [
		{"id": "tok", "name": "Tokyo", "city": "Tokyo", "cost": 1.35, "pay": 1.25, "crime": 0.5, "unemployment": 0.03, "education": 1.15, "transit": 1.0, "housing": 1.4, "hazard": "earthquake", "scene": ["tech", "fashion", "studio"], "blurb": "Neon, trains that are never late, and tiny apartments."},
		{"id": "osa", "name": "Osaka", "city": "Osaka", "cost": 1.05, "pay": 1.0, "crime": 0.6, "unemployment": 0.035, "education": 1.05, "transit": 0.95, "housing": 1.05, "hazard": "earthquake", "scene": ["restaurant"], "blurb": "Japan's kitchen. Loud, friendly and delicious."},
		{"id": "hok", "name": "Hokkaido", "city": "Sapporo", "cost": 0.85, "pay": 0.85, "crime": 0.4, "unemployment": 0.03, "education": 1.0, "transit": 0.5, "housing": 0.8, "hazard": "blizzard", "scene": ["zoo", "restaurant"], "blurb": "Snow festivals, farms and wild bears."},
		{"id": "oki", "name": "Okinawa", "city": "Naha", "cost": 0.8, "pay": 0.8, "crime": 0.4, "unemployment": 0.04, "education": 0.95, "transit": 0.35, "housing": 0.8, "hazard": "typhoon", "scene": ["restaurant"], "blurb": "Beaches, and people who live to 100."},
	],
	"fr": [
		{"id": "par", "name": "Île-de-France", "city": "Paris", "cost": 1.4, "pay": 1.25, "crime": 1.2, "unemployment": 0.075, "education": 1.1, "transit": 1.0, "housing": 1.6, "hazard": "heatwave", "scene": ["fashion", "restaurant", "studio"], "blurb": "Fashion, food and very long lunches."},
		{"id": "pro", "name": "Provence", "city": "Marseille", "cost": 1.0, "pay": 0.9, "crime": 1.3, "unemployment": 0.1, "education": 0.95, "transit": 0.6, "housing": 1.05, "hazard": "wildfire", "scene": ["restaurant"], "blurb": "Lavender fields and a busy Mediterranean port."},
		{"id": "lyo", "name": "Auvergne-Rhône-Alpes", "city": "Lyon", "cost": 1.0, "pay": 1.0, "crime": 0.9, "unemployment": 0.07, "education": 1.05, "transit": 0.8, "housing": 1.0, "hazard": "flood", "scene": ["restaurant", "clinic"], "blurb": "Gastronomy and ski slopes."},
	],
	"br": [
		{"id": "sp", "name": "São Paulo", "city": "São Paulo", "cost": 1.2, "pay": 1.2, "crime": 1.4, "unemployment": 0.08, "education": 0.95, "transit": 0.6, "housing": 1.2, "hazard": "flood", "scene": ["consulting", "tech"], "blurb": "A megacity of business and traffic jams."},
		{"id": "rj", "name": "Rio de Janeiro", "city": "Rio de Janeiro", "cost": 1.1, "pay": 1.0, "crime": 1.6, "unemployment": 0.1, "education": 0.9, "transit": 0.55, "housing": 1.15, "hazard": "landslide", "scene": ["restaurant", "label"], "blurb": "Beaches, samba and Carnival."},
		{"id": "am", "name": "Amazonas", "city": "Manaus", "cost": 0.75, "pay": 0.75, "crime": 1.2, "unemployment": 0.12, "education": 0.8, "transit": 0.3, "housing": 0.7, "hazard": "flood", "scene": ["zoo"], "blurb": "The edge of the rainforest."},
	],
	"mx": [
		{"id": "cdmx", "name": "Mexico City", "city": "Mexico City", "cost": 1.15, "pay": 1.15, "crime": 1.4, "unemployment": 0.04, "education": 0.95, "transit": 0.7, "housing": 1.15, "hazard": "earthquake", "scene": ["studio", "restaurant"], "blurb": "Murals, markets and endless tacos."},
		{"id": "qr", "name": "Quintana Roo", "city": "Cancún", "cost": 1.05, "pay": 0.95, "crime": 1.2, "unemployment": 0.035, "education": 0.85, "transit": 0.35, "housing": 1.1, "hazard": "hurricane", "scene": ["restaurant", "zoo"], "blurb": "Resorts, cenotes and tourists."},
		{"id": "nl", "name": "Nuevo León", "city": "Monterrey", "cost": 1.0, "pay": 1.1, "crime": 1.3, "unemployment": 0.04, "education": 0.95, "transit": 0.4, "housing": 0.95, "hazard": "heatwave", "scene": ["construction", "dealership"], "blurb": "Mexico's industrial powerhouse."},
	],
	"ph": [
		{"id": "mnl", "name": "Metro Manila", "city": "Manila", "cost": 1.15, "pay": 1.15, "crime": 1.3, "unemployment": 0.06, "education": 0.95, "transit": 0.55, "housing": 1.2, "hazard": "typhoon", "scene": ["consulting", "tech"], "blurb": "Traffic, malls and call centers."},
		{"id": "ceb", "name": "Cebu", "city": "Cebu City", "cost": 0.95, "pay": 0.95, "crime": 1.0, "unemployment": 0.05, "education": 0.9, "transit": 0.4, "housing": 0.95, "hazard": "typhoon", "scene": ["restaurant"], "blurb": "Islands, diving and old churches."},
		{"id": "dav", "name": "Davao", "city": "Davao City", "cost": 0.85, "pay": 0.85, "crime": 0.8, "unemployment": 0.045, "education": 0.9, "transit": 0.35, "housing": 0.85, "hazard": "earthquake", "scene": ["restaurant"], "blurb": "Durian, mountains and strict local rules.", "laws": {"police": 1.3}},
	],
	"ng": [
		{"id": "lag", "name": "Lagos", "city": "Lagos", "cost": 1.2, "pay": 1.25, "crime": 1.4, "unemployment": 0.1, "education": 0.9, "transit": 0.4, "housing": 1.35, "hazard": "flood", "scene": ["studio", "label", "tech"], "blurb": "Nollywood, Afrobeats and hustle."},
		{"id": "abj", "name": "Federal Capital Territory", "city": "Abuja", "cost": 1.1, "pay": 1.15, "crime": 1.0, "unemployment": 0.08, "education": 0.95, "transit": 0.35, "housing": 1.2, "hazard": "flood", "scene": ["consulting"], "blurb": "The planned capital. Politics and embassies."},
		{"id": "kan", "name": "Kano", "city": "Kano", "cost": 0.7, "pay": 0.7, "crime": 1.1, "unemployment": 0.12, "education": 0.8, "transit": 0.3, "housing": 0.7, "hazard": "heatwave", "scene": ["restaurant"], "blurb": "An ancient trading city on the edge of the Sahel.", "laws": {"gambling": "banned"}},
	],
	"in": [
		{"id": "del", "name": "Delhi", "city": "New Delhi", "cost": 1.0, "pay": 1.1, "crime": 1.1, "unemployment": 0.07, "education": 1.1, "transit": 0.8, "housing": 1.2, "hazard": "heatwave", "scene": ["consulting", "construction"], "blurb": "Government, history and summers that stop the city."},
		{"id": "mum", "name": "Maharashtra", "city": "Mumbai", "cost": 1.2, "pay": 1.25, "crime": 1.0, "unemployment": 0.06, "education": 1.05, "transit": 0.85, "housing": 1.6, "hazard": "flood", "scene": ["studio", "consulting"], "blurb": "Film, finance, and a monsoon that owns four months."},
		{"id": "blr", "name": "Karnataka", "city": "Bengaluru", "cost": 1.05, "pay": 1.2, "crime": 0.8, "unemployment": 0.05, "education": 1.15, "transit": 0.6, "housing": 1.15, "hazard": "flood", "scene": ["tech"], "blurb": "Software, good weather and impossible traffic."},
	],
	"kr": [
		{"id": "seo", "name": "Seoul Capital Area", "city": "Seoul", "cost": 1.3, "pay": 1.25, "crime": 0.5, "unemployment": 0.035, "education": 1.2, "transit": 1.0, "housing": 1.55, "hazard": "typhoon", "scene": ["tech", "label", "fashion"], "blurb": "Study hard, work late, eat well at 2 a.m."},
		{"id": "bus", "name": "Busan", "city": "Busan", "cost": 1.0, "pay": 1.0, "crime": 0.55, "unemployment": 0.04, "education": 1.05, "transit": 0.8, "housing": 1.0, "hazard": "typhoon", "scene": ["restaurant", "construction"], "blurb": "Port city, beaches, and a slower pulse than the capital."},
	],
	"eg": [
		{"id": "cai", "name": "Cairo", "city": "Cairo", "cost": 0.9, "pay": 1.0, "crime": 0.9, "unemployment": 0.09, "education": 0.95, "transit": 0.7, "housing": 1.0, "hazard": "heatwave", "scene": ["construction", "studio"], "blurb": "Twenty million people and five thousand years."},
		{"id": "alx", "name": "Alexandria", "city": "Alexandria", "cost": 0.8, "pay": 0.9, "crime": 0.85, "unemployment": 0.085, "education": 0.95, "transit": 0.6, "housing": 0.85, "hazard": "flood", "scene": ["restaurant"], "blurb": "The sea, the corniche, and a city that used to run the world."},
	],
	"ca": [
		{"id": "on", "name": "Ontario", "city": "Toronto", "cost": 1.25, "pay": 1.2, "crime": 0.7, "unemployment": 0.055, "education": 1.1, "transit": 0.8, "housing": 1.5, "hazard": "blizzard", "scene": ["tech", "consulting"], "blurb": "The economic engine, and six months of winter."},
		{"id": "bc", "name": "British Columbia", "city": "Vancouver", "cost": 1.35, "pay": 1.15, "crime": 0.8, "unemployment": 0.05, "education": 1.1, "transit": 0.75, "housing": 1.75, "hazard": "wildfire", "scene": ["studio", "tech"], "blurb": "Mountains, ocean, rain, and the housing market from hell."},
		{"id": "ab", "name": "Alberta", "city": "Calgary", "cost": 1.0, "pay": 1.2, "crime": 0.8, "unemployment": 0.06, "education": 1.05, "transit": 0.5, "housing": 0.95, "hazard": "blizzard", "scene": ["construction", "dealership"], "blurb": "Oil money, big skies and brutal cold snaps."},
	],
	"au": [
		{"id": "nsw", "name": "New South Wales", "city": "Sydney", "cost": 1.4, "pay": 1.3, "crime": 0.7, "unemployment": 0.04, "education": 1.1, "transit": 0.8, "housing": 1.7, "hazard": "wildfire", "scene": ["consulting", "fashion"], "blurb": "Harbour views you will never afford to live behind."},
		{"id": "qld", "name": "Queensland", "city": "Brisbane", "cost": 1.05, "pay": 1.05, "crime": 0.8, "unemployment": 0.05, "education": 1.0, "transit": 0.6, "housing": 1.15, "hazard": "hurricane", "scene": ["zoo", "restaurant"], "blurb": "Reef, rainforest, and a cyclone season."},
		{"id": "wa_au", "name": "Western Australia", "city": "Perth", "cost": 1.1, "pay": 1.25, "crime": 0.75, "unemployment": 0.045, "education": 1.0, "transit": 0.5, "housing": 1.1, "hazard": "wildfire", "scene": ["construction"], "blurb": "Mining wages and the most isolated city on earth."},
	],
}

const HAZARDS := {
	"earthquake": {"icon": "🌋", "name": "Earthquake"}, "hurricane": {"icon": "🌀", "name": "Hurricane"}, "typhoon": {"icon": "🌀", "name": "Typhoon"},
	"flood": {"icon": "🌊", "name": "Flood"}, "wildfire": {"icon": "🔥", "name": "Wildfire"}, "blizzard": {"icon": "❄️", "name": "Blizzard"},
	"heatwave": {"icon": "🥵", "name": "Heatwave"}, "tornado": {"icon": "🌪️", "name": "Tornado"}, "storm": {"icon": "⛈️", "name": "Storm"},
	"landslide": {"icon": "⛰️", "name": "Landslide"},
}


func regions(country: String) -> Array:
	return REGIONS.get(country, [])


func region(p: Dictionary = {}) -> Dictionary:
	if p.is_empty(): p=GameState.player
	var list := regions(p.get("country", "us"))
	if list.is_empty():
		return {"id": "", "name": "", "city": ContentDB.country(p.get("country", "us"))["name"], "cost": 1.0, "pay": 1.0, "crime": 1.0, "hazard": "flood", "scene": [], "blurb": ""}
	var rid: String = p.get("region", "")
	for r in list:
		if r["id"] == rid:
			return r
	p["region"] = list[0]["id"]
	return list[0]


func law(key: String):
	var p := GameState.player
	var base: Dictionary = LAWS.get(p.get("country", "us"), LAWS["us"])
	var r := region()
	if r.get("laws", {}).has(key):
		return r["laws"][key]
	return base.get(key, null)


func place_name() -> String:
	var r := region()
	if r.get("name", "") == "" or r["name"] == r["city"]:
		return r["city"]
	return "%s, %s" % [r["city"], r["name"]]


func cost_mult(p: Dictionary = {}) -> float:
	return float(region(p).get("cost", 1.0))


func housing_mult() -> float:
	return float(region().get("housing", region().get("cost", 1.0)))


func unemployment() -> float:
	var u := float(region().get("unemployment", 0.06))
	if World.active("recession"):
		u *= 1.8
	if World.active("boom"):
		u *= 0.6
	if World.active("war"):
		u *= 0.8
	return u


func education() -> float:
	return float(region().get("education", 1.0))


func transit() -> float:
	return float(region().get("transit", 0.5))


func pay_mult() -> float:
	return float(region().get("pay", 1.0))


func scene_bonus(ind: String) -> float:
	return 1.2 if region().get("scene", []).has(ind) else 1.0


func tax() -> float:
	return float(law("tax"))


func healthcare_mult() -> float:
	match str(law("healthcare")):
		"free": return 0.0
		"public": return 0.4
	return 1.0


func random_region(country: String) -> String:
	var list := regions(country)
	return list[randi() % list.size()]["id"] if not list.is_empty() else ""


func summary() -> Array:
	var r := region()
	var hz: Dictionary = HAZARDS.get(r.get("hazard", "flood"), HAZARDS["flood"])
	var g := {"legal": "Legal", "vegas": "Legal · casino capital", "restricted": "Restricted (pachinko and lotteries only)", "banned": "Illegal (underground only)"}
	var gun := {"loose": "Easy to get", "permit": "Permit required", "strict": "Strict licensing", "banned": "Almost entirely banned"}
	var hc := {"free": "Free public healthcare", "public": "Cheap public clinics, long waits", "private": "Private: you pay for everything"}
	return [
		["🏙️", "City", place_name()],
		["💵", "Cost of living", _rel(float(r.get("cost", 1.0)))],
		["💼", "Wages", _rel(float(r.get("pay", 1.0)))],
		["🏠", "Housing pressure", _rel(housing_mult())],
		["📉", "Unemployment", "%.1f%%" % (unemployment() * 100.0)],
		["🏫", "Schools", _rel(education())],
		["🚇", "Public transit", "Excellent" if transit() >= 0.9 else ("Good" if transit() >= 0.65 else ("Patchy" if transit() >= 0.4 else "You need a car"))],
		["🧾", "Income tax", "%d%%" % int(round(float(law("tax")) * 100))],
		["🚗", "Driving age", str(law("drive"))],
		["🍺", "Drinking age", str(law("drink"))],
		["🎰", "Gambling", g.get(str(law("gambling")), "Legal")],
		["🎯", "Guns", gun.get(str(law("guns")), "Permit required")],
		["🏥", "Healthcare", hc.get(str(law("healthcare")), "")],
		["🎓", "University", "Free" if float(law("tuition")) <= 0.1 else ("Cheap" if float(law("tuition")) < 0.5 else "Expensive")],
		["⚖️", "Death penalty", "Yes" if law("death_penalty") else "No"],
		["👮", "Police", "Very strict (almost everyone is convicted)" if float(law("police")) >= 1.2 else ("Strict" if float(law("police")) >= 1.05 else "Normal")],
		["💰", "Corruption", "Rampant" if float(law("corruption")) >= 0.25 else ("Common" if float(law("corruption")) >= 0.1 else "Rare")],
		["🚨", "Crime", _crime_word(float(r.get("crime", 1.0)) * float(law("crime")))],
		["🦌", "Hunting", "Allowed with a license" if law("hunting") else "Banned"],
		["🎖️", "Military service", "Mandatory at 18" if law("conscription") else "Voluntary"],
		[hz["icon"], "Natural hazard", hz["name"]],
		[Climate.climate()["icon"], "Climate", Climate.describe()],
	]


func _rel(v: float) -> String:
	if v >= 1.3: return "Very high"
	if v >= 1.1: return "High"
	if v >= 0.9: return "Average"
	if v >= 0.8: return "Low"
	return "Very low"


func _crime_word(v: float) -> String:
	if v >= 1.6: return "Dangerous"
	if v >= 1.2: return "High"
	if v >= 0.8: return "Average"
	return "Very safe"


# ================================================================ yearly

func yearly() -> void:
	var p := GameState.player
	var age: int = p["age"]
	var r := region()
	Climate.yearly()
	Deeds.yearly()
	var crime := float(r.get("crime", 1.0)) * float(law("crime")) * World.crime_mult()
	if age >= 14 and not GameState.in_prison() and randf() < 0.035 * crime:
		_victim()
	var hz_chance := 0.012 * (4.0 if World.active("climate") else 1.0)
	if age >= 5 and randf() < hz_chance:
		_hazard()
	if law("conscription") and age == 18 and p["gender"] == "male" and not GameState.has_flag("served"):
		GameState.set_flag("served")
		EventEngine.push_decision({"id": "_service", "icon": "🎖️", "title": "Military service", "text": "Military service is mandatory here. Your papers have arrived.", "choices": [
			{"label": "Serve your year", "outcomes": [{"text": "A year of drills, bad food and good friends. I came back tougher.", "effects": {"health": 6, "happiness": -3, "smarts": 1}, "milestone": "completed military service"}]},
			{"label": "Get a medical exemption", "outcomes": [{"weight": 1, "text": "A friendly doctor signed the exemption.", "effects": {"money": -800, "karma": -3}}, {"weight": 1, "text": "The board saw through it. I served anyway, and they made it hard.", "effects": {"health": 3, "happiness": -8}}]},
		]})
	if GameState.has_flag("death_row") and GameState.in_prison():
		_death_row()
	if age >= 18 and p["car"] == "" and transit() < 0.4 and not GameState.in_prison():
		GameState.apply_effects({"happiness": -2, "stress": 2})
	if GameState.in_school() or GameState.in_university():
		GameState.apply_effects({"school": (education() - 1.0) * 20.0})


func _victim() -> void:
	var p := GameState.player
	var r := region()
	var roll := randf()
	if roll < 0.4:
		var loss := mini(maxi(0, int(p["money"])), Actions._cost(randi_range(80, 900)))
		if Shop.has_tag("spray") and randf() < 0.6:
			GameState.add_log("A mugger came at me in %s. One blast of pepper spray and he was on the ground crying." % r["city"])
			GameState.apply_effects({"stress": 4, "happiness": 2})
			return
		var fdiff := 0.9 - Daily.fight_bonus() - (0.15 if Shop.has_any(["bat", "sword"]) else 0.0)
		EventEngine.push_decision({"id": "_mugged", "icon": "🔪", "title": "Mugged", "text": "A man steps out of a doorway in %s: \"Wallet. Now.\"" % r["city"], "choices": [
			{"label": "Hand it over", "outcomes": [{"text": "I handed it over. %s gone, and my hands wouldn't stop shaking." % GameState.fmt_money(loss), "effects": {"money": -loss, "stress": 8}}]},
			{"label": "Fight back", "outcomes": [{"text": "", "play": {"id": "fight", "kind": "brawl", "params": {"difficulty": fdiff, "opponent": "The mugger"}}}]},
			{"label": "Run", "outcomes": [{"weight": 2, "text": "I ran and didn't stop for six blocks.", "effects": {"stress": 6}}, {"weight": 1, "text": "He caught me.", "effects": {"money": -loss, "health": -12}}]},
		]})
	elif roll < 0.7 and not p["possessions"].is_empty():
		var idx: int = randi() % p["possessions"].size()
		var it: Dictionary = p["possessions"][idx]
		p["possessions"].remove_at(idx)
		GameState.add_log("Someone broke into my place and stole my %s." % str(it["name"]).to_lower())
		GameState.apply_effects({"happiness": -8, "stress": 8})
	elif p["car"] != "":
		GameState.add_log("My car was stolen from outside my home in %s." % r["city"])
		p["car"] = ""
		GameState.apply_effects({"happiness": -8, "stress": 6})


func _hazard() -> void:
	var p := GameState.player
	var r := region()
	var hz: Dictionary = HAZARDS.get(r.get("hazard", "flood"), HAZARDS["flood"])
	var severe := randf() < 0.35
	var text := "A %s hit %s." % [hz["name"].to_lower(), r["city"]]
	var fx := {"stress": 8}
	if severe:
		text += " It was the worst in decades."
		fx["health"] = -10
		if p["housing"] == "house":
			var dmg := int(int(p["house_value"]) * 0.25)
			p["house_value"] = int(p["house_value"]) - dmg
			text += " My house took %s in damage." % GameState.fmt_money(dmg)
		for pr in p["properties"]:
			pr["condition"] = maxf(0.0, float(pr["condition"]) - 30.0)
	EventEngine.push_info(hz["icon"], hz["name"], text, GameState.apply_effects(fx))
	GameState.counter("disasters")


func _death_row() -> void:
	var p := GameState.player
	var yrs := int(p.get("death_row_years", 0)) + 1
	p["death_row_years"] = yrs
	if randf() < 0.18:
		GameState.clear_flag("death_row")
		GameState.add_log("My death sentence was commuted to life in prison.")
		GameState.add_milestone(p["age"], "had their death sentence commuted")
		return
	if yrs >= 4 and randf() < 0.2:
		GameState.add_milestone(p["age"], "was executed by the state")
		EventEngine.kill("execution")


## Called by Law when a severe sentence is handed down.
func maybe_death_row(max_years: int) -> bool:
	if not law("death_penalty") or max_years < 15:
		return false
	if randf() < 0.18 * float(law("police")):
		GameState.set_flag("death_row")
		GameState.player["death_row_years"] = 0
		GameState.add_milestone(GameState.player["age"], "was sentenced to death")
		return true
	return false


func relocate(rid: String) -> void:
	var p := GameState.player
	if int(p["age"])<18 or rid==str(p.get("region","")) or not regions(str(p["country"])).any(func(r): return r["id"]==rid): return
	var fee := Actions._cost(3000)
	if int(p["money"]) < fee:
		EventEngine.push_info("💸", "Moving", "Moving costs %s." % GameState.fmt_money(fee))
		return
	if Actions._out_of_time(): return
	p["money"] = int(p["money"]) - fee
	if p["housing"] == "house":
		p["money"] = int(p["money"]) + int(p["house_value"]) - int(p["mortgage"])
		p["house_value"] = 0
		p["house_model"]=""
		p.erase("house_uid")
		p["mortgage"] = 0
		p["mortgage_payment"] = 0
	if p["housing"] in ["house", "parents"] and int(p["age"]) >= 18:
		p["housing"] = "apartment"
	p["region"] = rid
	GameState.counter("relocations")
	GameState.job_listings.clear()
	var lost := GameState.has_job() and randf() < (0.35 if Journey.modules["places"].prepared(rid) else 0.6)
	if lost:
		Actions.lose_job("moved")
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if n["alive"] and n["relation"] in ["friend", "best_friend", "neighbor"]:
			GameState.change_closeness(id, -10)
	GameState.add_milestone(p["age"], "moved to %s" % place_name())
	Careers._done("🚚", "New city", "I packed everything into a van and moved to %s. %s%s" % [place_name(), region()["blurb"], " I had to leave my job behind." if lost else ""], {"happiness": 4, "stress": 6})
