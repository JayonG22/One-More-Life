extends Node

## CLIMATE — where you live has weather, and the weather has opinions.
##
## Every region maps to a climate archetype with a real summer and winter mean,
## a rainfall character and a seasonal rhythm. That does three jobs:
##
##   1. It makes two cities that look similar on paper feel different to live in.
##      Sapporo and Naha are both Japan. One of them buries you in snow.
##   2. It gives the hazard system a reason: a heatwave in Phoenix is a bad
##      summer, a heatwave in Sapporo is a genuine emergency nobody is built for.
##   3. It puts a number on the year that costs money and health — heating bills,
##      cooling bills, the winter you spent indoors and gained no fitness from.
##
## Temperatures are stored in Celsius and only converted when written out, so the
## Units setting decides what the player reads without touching the simulation.

const CLIMATES := {
	"mediterranean": {"name": "Mediterranean", "icon": "🌞", "summer": 28.0, "winter": 11.0, "wet": "wet winters, dry summers", "rain": 0.35},
	"humid_subtropical": {"name": "Humid subtropical", "icon": "🌴", "summer": 31.0, "winter": 10.0, "wet": "hot wet summers", "rain": 0.6},
	"tropical": {"name": "Tropical", "icon": "🌺", "summer": 32.0, "winter": 26.0, "wet": "a wet season and a dry one", "rain": 0.75},
	"monsoon": {"name": "Tropical monsoon", "icon": "🌧️", "summer": 33.0, "winter": 25.0, "wet": "a monsoon that arrives on schedule", "rain": 0.85},
	"arid": {"name": "Desert", "icon": "🏜️", "summer": 40.0, "winter": 12.0, "wet": "almost no rain at all", "rain": 0.08},
	"semi_arid": {"name": "Semi-arid", "icon": "🌾", "summer": 34.0, "winter": 14.0, "wet": "a short, unreliable rainy season", "rain": 0.25},
	"oceanic": {"name": "Oceanic", "icon": "🌦️", "summer": 21.0, "winter": 6.0, "wet": "rain in every month of the year", "rain": 0.7},
	"continental": {"name": "Continental", "icon": "🍂", "summer": 26.0, "winter": -2.0, "wet": "four sharply separate seasons", "rain": 0.5},
	"cold_continental": {"name": "Cold continental", "icon": "❄️", "summer": 23.0, "winter": -8.0, "wet": "heavy snow for months", "rain": 0.55},
	"highland": {"name": "Highland", "icon": "⛰️", "summer": 22.0, "winter": 9.0, "wet": "thin air and sudden afternoon storms", "rain": 0.45},
}

## Region id to climate. Kept as a lookup so the region table itself stays
## readable and adding a climate never means rewriting a city's economy.
const REGION_CLIMATE := {
	"ca": "mediterranean", "ny": "continental", "tx": "humid_subtropical", "fl": "humid_subtropical",
	"nv": "arid", "oh": "continental",
	"ldn": "oceanic", "man": "oceanic", "edi": "oceanic", "cor": "oceanic",
	"ber": "continental", "bay": "continental", "ham": "oceanic", "sax": "continental",
	"tok": "humid_subtropical", "osa": "humid_subtropical", "hok": "cold_continental", "oki": "tropical",
	"par": "oceanic", "pro": "mediterranean", "lyo": "continental",
	"sp": "humid_subtropical", "rj": "tropical", "am": "tropical",
	"cdmx": "highland", "qr": "tropical", "nl": "semi_arid",
	"mnl": "monsoon", "ceb": "tropical", "dav": "tropical",
	"lag": "tropical", "abj": "semi_arid", "kan": "semi_arid",
	"del": "semi_arid", "mum": "monsoon", "blr": "highland",
	"seo": "continental", "bus": "humid_subtropical",
	"cai": "arid", "alx": "arid",
	"on": "cold_continental", "bc": "oceanic", "ab": "cold_continental",
	"nsw": "humid_subtropical", "qld": "tropical", "wa_au": "mediterranean",
}

const SEASONS := ["winter", "spring", "summer", "autumn"]


func _p() -> Dictionary:
	return GameState.player


func climate_id() -> String:
	var r := Places.region()
	return str(REGION_CLIMATE.get(str(r.get("id", "")), "oceanic"))


func climate() -> Dictionary:
	return CLIMATES[climate_id()]


## Southern-hemisphere regions run the year the other way round.
func southern() -> bool:
	return str(Places.region().get("id", "")) in ["sp", "rj", "am", "nsw", "qld", "wa_au"]


func mean_temp(season: String) -> float:
	var c := climate()
	var s := float(c["summer"])
	var w := float(c["winter"])
	var mid := (s + w) * 0.5
	match season:
		"summer":
			return s
		"winter":
			return w
		_:
			return mid


## The defining number of this year's weather in this place, with variance.
func year_temp(season: String) -> float:
	return mean_temp(season) + randf_range(-3.5, 3.5)


func season_now() -> String:
	return str(snapshot()["season"])


func snapshot() -> Dictionary:
	var p := _p()
	var stamp := "%s:%s:%d" % [str(p.get("country", "")), str(p.get("region", "")), int(p.get("age", 0))]
	var saved: Dictionary = p.get("weather_year", {})
	if str(saved.get("stamp", "")) == stamp: return saved
	var season: String = SEASONS[randi() % SEASONS.size()]
	var temp := year_temp(season)
	var wet := randf() < float(climate()["rain"])
	var weather := "mild"
	if temp >= 33.0: weather = "heat"
	elif temp <= 0.0: weather = "snow"
	elif wet: weather = "rain"
	elif temp < 10.0: weather = "cold"
	elif float(climate()["rain"]) <= 0.25: weather = "dry"
	saved = {"stamp": stamp, "season": season, "temperature": temp, "weather": weather}
	p["weather_year"] = saved
	return saved


func describe() -> String:
	var c := climate()
	var s := Units.temperature(float(c["summer"]))
	var w := Units.temperature(float(c["winter"]))
	return "%s %s · summers around %s, winters around %s · %s" % [c["icon"], c["name"], s, w, c["wet"]]


# ---------------------------------------------------------------- the year

## Called once a year from Places. Produces at most one weather beat, weighted by
## what this climate actually does, and lets it touch money, health and mood.
func yearly() -> void:
	var p := _p()
	if p.is_empty() or not GameState.is_alive():
		return
	var c := climate()
	var cid := climate_id()
	var current := snapshot()

	# Heating and cooling are a real, boring, unavoidable cost of place.
	var extreme := maxf(absf(float(c["winter"]) - 16.0), absf(float(c["summer"]) - 22.0))
	if int(p["age"]) >= 18 and extreme > 8.0:
		var bill := Actions._cost(int(extreme * 18.0))
		p["money"] = int(p["money"]) - bill
		if bill > 0 and randf() < 0.3:
			GameState.add_log("Heating and cooling this year came to %s. That is the price of the climate here." % GameState.fmt_money(bill))

	if randf() > 0.42:
		return

	var season := season_now()
	var t := float(current["temperature"])
	match str(current["weather"]):
		"heat": _heat(t)
		"cold", "snow": _cold(t)
		"rain": _wet()
		"dry": _dry(t, season)
		_:
			if t >= 15.0 and t <= 27.0: _mild(t, season)
			else: _dry(t, season)


func _heat(t: float) -> void:
	var reading := Units.temperature(t)
	var frail := int(_p()["age"]) >= 65 or int(_p()["age"]) <= 5 or GameState.stat("health") < 40.0
	if frail and randf() < 0.45:
		GameState.apply_effects({"health": -5, "happiness": -4, "stress": 6})
		GameState.add_log("The heat reached %s and it genuinely took something out of me. I was told to stay inside and drink water." % reading)
		LifeThreads.remember("illness", "The summer that nearly got me", "A heatwave hit %s and my body could not cope with it the way it once did." % reading, "", 56, ["weather", "heat"])
	else:
		GameState.apply_effects({"happiness": -2, "stress": 3, "money": -Actions._cost(60)})
		GameState.add_log("A heatwave pushed the thermometer to %s. Nothing got done for a week." % reading)


func _cold(t: float) -> void:
	var reading := Units.temperature(t)
	if randf() < 0.3:
		GameState.apply_effects({"health": -3, "stress": 4, "money": -Actions._cost(180)})
		GameState.add_log("The winter bottomed out at %s. Between the heating bill and the ice, it was a hard few months." % reading)
	else:
		GameState.apply_effects({"happiness": -2, "money": -Actions._cost(120)})
		GameState.add_log("A long cold winter, down to %s. I spent most of it indoors." % reading)


func _wet() -> void:
	if randf() < 0.25:
		GameState.apply_effects({"happiness": -3, "stress": 5, "money": -Actions._cost(220)})
		GameState.add_log("The rains came harder than usual. Water got in, and getting it out cost money.")
	else:
		GameState.apply_effects({"happiness": -1})
		GameState.add_log("A long wet season. Everything took longer and dried slower.")


func _grey() -> void:
	GameState.apply_effects({"happiness": -2, "stress": 2})
	GameState.add_log("Grey month after grey month. Nothing dramatic happened; it just never quite got light.")


func _dry(t: float, season: String) -> void:
	var c := climate()
	if float(c["rain"]) <= 0.2:
		GameState.apply_effects({"happiness": -1, "money": -Actions._cost(40)})
		GameState.add_log("Another year without real rain. The %s was dust and water restrictions." % season)
	else:
		GameState.add_log("An unremarkable %s, around %s. The weather asked nothing of me." % [season, Units.temperature(t)])


func _mild(t: float, season: String) -> void:
	GameState.apply_effects({"happiness": 4, "stress": -3, "health": 1})
	GameState.add_log("A genuinely good %s, around %s. I was outside more than usual, and it showed." % [season, Units.temperature(t)])
