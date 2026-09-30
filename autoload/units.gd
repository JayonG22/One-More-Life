extends Node

## UNITS — the one toggleable measurement layer.
##
## Money is deliberately NOT toggleable: what a life costs and earns is part of
## the simulation, and expressing it in the wrong currency would be a lie about
## where the character lives. Distance, weight and temperature are only ever
## description, so those follow whatever the player finds readable.
##
## Everything in game code is stored metric (km, kg, °C, cm) and converted at the
## moment it is written into a sentence.

const SYSTEMS := {
	"metric": {"name": "Metric", "icon": "📏", "desc": "Kilometres, kilograms, °C"},
	"imperial": {"name": "Imperial (US)", "icon": "📐", "desc": "Miles, pounds, °F"},
	"uk": {"name": "UK mixed", "icon": "🇬🇧", "desc": "Miles and stone, but °C"},
}

## Countries whose everyday measurements are not metric, used to pick a sensible
## default the first time a player starts a life there.
const DEFAULT_BY_COUNTRY := {"us": "imperial", "uk": "uk"}


func system() -> String:
	var s := str(GameState.settings.get("units", "metric"))
	return s if SYSTEMS.has(s) else "metric"


func set_system(id: String) -> void:
	if SYSTEMS.has(id):
		GameState.settings["units"] = id
		SaveManager.save_settings()


func suggest_for_country(country_id: String) -> String:
	return str(DEFAULT_BY_COUNTRY.get(country_id, "metric"))


func _trim(v: float, decimals: int = 1) -> String:
	if is_equal_approx(v, round(v)) or decimals <= 0:
		return str(int(round(v)))
	return String.num(v, decimals)


# ---------------------------------------------------------------- distance

func distance(km: float) -> String:
	if system() == "metric":
		if km < 1.0:
			return "%s m" % _trim(km * 1000.0, 0)
		return "%s km" % _trim(km)
	var miles := km * 0.621371
	if miles < 0.19:
		return "%s ft" % _trim(km * 3280.84, 0)
	return "%s miles" % _trim(miles)


func speed(kmh: float) -> String:
	if system() == "metric":
		return "%s km/h" % _trim(kmh, 0)
	return "%s mph" % _trim(kmh * 0.621371, 0)


# ---------------------------------------------------------------- weight

func weight(kg: float) -> String:
	match system():
		"imperial":
			return "%s lb" % _trim(kg * 2.20462)
		"uk":
			if kg >= 25.0:
				var total := kg * 2.20462
				var stone := int(total / 14.0)
				var pounds := int(round(total - stone * 14.0))
				return "%d st %d lb" % [stone, pounds]
			return "%s lb" % _trim(kg * 2.20462)
		_:
			return "%s kg" % _trim(kg)


# ---------------------------------------------------------------- height

func height(cm: float) -> String:
	if system() == "metric":
		return "%s cm" % _trim(cm, 0)
	var inches := cm / 2.54
	var feet := int(inches / 12.0)
	var rest := int(round(inches - feet * 12.0))
	if rest == 12:
		feet += 1
		rest = 0
	return "%d'%d\"" % [feet, rest]


# ---------------------------------------------------------------- temperature

func temperature(celsius: float) -> String:
	if system() == "imperial":
		return "%s°F" % _trim(celsius * 9.0 / 5.0 + 32.0, 0)
	return "%s°C" % _trim(celsius, 0)


## A short human read on the weather, independent of the numbers.
func temp_word(celsius: float) -> String:
	if celsius <= -15.0:
		return "brutally cold"
	if celsius <= -2.0:
		return "freezing"
	if celsius <= 8.0:
		return "cold"
	if celsius <= 16.0:
		return "cool"
	if celsius <= 24.0:
		return "mild"
	if celsius <= 31.0:
		return "warm"
	if celsius <= 38.0:
		return "hot"
	return "dangerously hot"


# ---------------------------------------------------------------- volume

func volume(litres: float) -> String:
	if system() == "metric":
		return "%s L" % _trim(litres)
	return "%s gal" % _trim(litres * 0.264172)
