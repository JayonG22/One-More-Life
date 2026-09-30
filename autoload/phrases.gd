extends Node

## PHRASES — so a line of text is not the same line every time it is read.
##
## An event text can carry inline alternatives:
##
##   "The {~rain|drizzle|wind} followed me home."
##   "{~poor=I counted the coins twice|rich=I tipped without looking|I paid}."
##
## An option may be prefixed with a condition and `=`. Options whose condition
## holds are favoured; options with no condition are the fallback. The choice is
## made from a hash of the text, the player's age and a per-life seed, so a line
## reads differently from one life to the next but does not flicker while you
## are looking at it.
##
## It also owns the vocabulary of the era: what a phone, the internet and a
## night out were called when the player was young.

var _re := RegEx.new()
var year_override := 0   # tests set this to read the world as it was in another year


func _ready() -> void:
	_re.compile("\\{~([^{}]*)\\}")


func seed_of_life() -> int:
	var p := GameState.player
	if p.is_empty():
		return 0
	if not p.has("phrase_seed"):
		p["phrase_seed"] = randi()
	return int(p["phrase_seed"])


## True if a condition word holds for this player right now.
func holds(cond: String) -> bool:
	var p := GameState.player
	if p.is_empty():
		return false
	var age := int(p.get("age", 0))
	match cond:
		"male": return str(p.get("gender", "")) == "male"
		"female": return str(p.get("gender", "")) == "female"
		"young": return age < 25
		"adult": return age >= 25 and age < 60
		"old": return age >= 60
		"poor": return int(p.get("money", 0)) < 3000
		"rich": return int(p.get("money", 0)) > 250000
		"partnered": return str(p.get("partner", "")) != ""
		"single": return str(p.get("partner", "")) == ""
		"parent": return not GameState.npcs_with("child").is_empty()
		"renting": return str(p.get("housing", "")) == "apartment"
		"owner": return str(p.get("housing", "")) == "house"
		"city": return float(Places.region().get("transit", 0.5)) >= 0.7
		"country": return float(Places.region().get("transit", 0.5)) < 0.4
		"employed": return GameState.has_job()
		"driver": return str(p.get("car", "")) != ""
	if cond.begins_with("trait:"):
		return GameState.has_trait(cond.substr(6))
	if cond.begins_with("decade:"):
		return decade() == int(cond.substr(7))
	if cond.begins_with("pre:"):
		return _year() < int(cond.substr(4))
	if cond.begins_with("from:"):
		return _year() >= int(cond.substr(5))
	return false


func _year() -> int:
	return year_override if year_override > 0 else Expansion.era_year()


func decade() -> int:
	return int(_year() / 10) * 10


func expand(text: String) -> String:
	if text.find("{~") == -1:
		return text
	var out := text
	var guard := 0
	for m in _re.search_all(text):
		var whole := m.get_string(0)
		out = out.replace(whole, _pick(m.get_string(1), text + whole))
		guard += 1
		if guard > 64:
			break
	return out


func _pick(body: String, salt: String) -> String:
	var opts := body.split("|")
	var matched: Array = []
	var plain: Array = []
	for o in opts:
		var eq := o.find("=")
		if eq > 0 and eq < 24 and o.substr(0, eq).find(" ") == -1:
			if holds(o.substr(0, eq)):
				matched.append(o.substr(eq + 1))
		else:
			plain.append(o)
	var pool: Array = matched if not matched.is_empty() else plain
	if pool.is_empty():
		return ""
	var h := hash(salt + "|" + str(GameState.player.get("age", 0)) + "|" + str(seed_of_life()))
	return str(pool[absi(h) % pool.size()])


# ---------------------------------------------------------------- the era

## What things were called. Keyed words are used as {era.phone} style tokens.
const ERA := {
	"phone": [[1990, "landline"], [2002, "flip phone"], [2010, "mobile"], [9999, "phone"]],
	"net": [[1994, "the library's card index"], [2000, "dial-up"], [2010, "broadband"], [9999, "wifi"]],
	"music": [[1965, "the wireless"], [1985, "a cassette"], [2000, "a CD"], [2010, "an MP3"], [9999, "a playlist"]],
	"tv": [[1955, "the wireless"], [1990, "the telly"], [2008, "cable"], [9999, "streaming"]],
	"message": [[1990, "a letter"], [2003, "a text"], [9999, "a message"]],
	"photo": [[1995, "a print from the chemist"], [2005, "a digital snap"], [9999, "a photo on my phone"]],
	"map": [[1998, "a road atlas"], [2008, "a printed route"], [9999, "the map app"]],
	"shop": [[2000, "the high street"], [2012, "the shops"], [9999, "an online order"]],
}


func era_word(key: String) -> String:
	if not ERA.has(key):
		return key
	var y := _year()
	for step in ERA[key]:
		if y < int(step[0]):
			return str(step[1])
	return key


## The technology stage of the player's world, for gating and flavour.
func tech_level() -> int:
	var y := _year()
	if y < 1990: return 0
	if y < 2005: return 1
	if y < 2015: return 2
	return 3
