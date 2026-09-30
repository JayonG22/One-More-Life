extends Node

## WANTED — how much the law wants you, and what that costs.
##
## The game already tracked `record` (a list of convictions) and `heat` (a
## vague number). Neither told the player anything at a glance, and neither
## accumulated: your eleventh burglary read exactly like your first.
##
## Stars are the visible version. They go up with every crime you commit, not
## every crime you are caught for, and they decay only slowly and only if you
## stop. They are not decoration: they feed sentencing, police attention, job
## applications, whether you can leave the country, and how nervous the people
## around you are.

const MAX_STARS := 5

## What each level means, and what it does.
const LEVELS := [
	{"name": "Clean", "desc": "Nobody is looking for you."},
	{"name": "Of interest", "desc": "Your name is in a file somewhere."},
	{"name": "Known", "desc": "Local police know your face and your address."},
	{"name": "Wanted", "desc": "There is a warrant. Traffic stops are not routine any more."},
	{"name": "Hunted", "desc": "A unit is assigned to you. Sentences will not be lenient."},
	{"name": "Most wanted", "desc": "Your photograph is on a wall. Everybody is looking."},
]


func _st() -> Dictionary:
	var p := GameState.player
	if p.is_empty():
		return {}
	if not p.has("wanted") or not (p["wanted"] is Dictionary):
		p["wanted"] = {"stars": 0.0, "crimes": 0, "by_kind": {}, "last_crime_age": -99, "peak": 0}
	return p["wanted"]


func stars() -> int:
	var st := _st()
	if st.is_empty():
		return 0
	return clampi(int(floor(float(st.get("stars", 0.0)))), 0, MAX_STARS)


func raw() -> float:
	var st := _st()
	return float(st.get("stars", 0.0)) if not st.is_empty() else 0.0


func crimes() -> int:
	var st := _st()
	return int(st.get("crimes", 0)) if not st.is_empty() else 0


func peak() -> int:
	var st := _st()
	return int(st.get("peak", 0)) if not st.is_empty() else 0


func by_kind() -> Dictionary:
	var st := _st()
	return st.get("by_kind", {}) if not st.is_empty() else {}


func level_name() -> String:
	return str(LEVELS[clampi(stars(), 0, MAX_STARS)]["name"])


func level_desc() -> String:
	return str(LEVELS[clampi(stars(), 0, MAX_STARS)]["desc"])


func display() -> String:
	var s := stars()
	if s <= 0:
		return ""
	return "⭐".repeat(s)


## How much a given crime raises the heat. Violence counts for more than theft,
## which is roughly how the world treats it.
const WEIGHT := {
	"murder": 2.4, "manslaughter": 1.8, "kidnapping": 1.8, "arson": 1.4,
	"armed robbery": 1.5, "robbery": 1.1, "assault": 0.9, "battery": 0.9,
	"burglary": 0.8, "grand theft auto": 0.9, "theft": 0.5, "shoplifting": 0.3,
	"fraud": 0.7, "embezzlement": 0.8, "money laundering": 0.9, "extortion": 1.0,
	"drug trafficking": 1.2, "drug possession": 0.4, "smuggling": 0.9,
	"hit and run": 1.3, "dangerous driving": 0.5, "dui": 0.5,
	"vandalism": 0.3, "trespassing": 0.2, "tax evasion": 0.6, "conspiracy": 0.8,
	"rioting": 0.7, "bribery": 0.6, "poaching": 0.5, "counterfeiting": 0.6,
}


## Call this whenever the player COMMITS a crime, caught or not.
func commit(kind: String, caught: bool = false) -> void:
	var st := _st()
	if st.is_empty():
		return
	var k := kind.to_lower().strip_edges()
	var w := float(WEIGHT.get(k, 0.6))
	if caught:
		w *= 1.35
	st["crimes"] = int(st.get("crimes", 0)) + 1
	var bk: Dictionary = st["by_kind"]
	bk[k] = int(bk.get(k, 0)) + 1
	st["last_crime_age"] = int(GameState.player.get("age", 0))
	var before := stars()
	st["stars"] = clampf(float(st.get("stars", 0.0)) + w * 0.5, 0.0, float(MAX_STARS))
	st["peak"] = maxi(int(st.get("peak", 0)), stars())
	GameState.counter("crimes_committed")
	if stars() > before:
		_announce(stars())


func _announce(s: int) -> void:
	var line := ""
	match s:
		1: line = "Somebody official has started a file with my name on it."
		2: line = "The local police know my face now. A patrol car slowed down outside my place."
		3: line = "There is a warrant out for me. I have stopped answering the door."
		4: line = "Somebody is working my case full time. I can feel the difference."
		5: line = "I saw my own photograph on a wall in a post office."
	if line != "":
		GameState.add_log(line)
		if Moments.ready_to_play():
			Moments.fire("crime_heat", clampf(0.5 + float(s) * 0.1, 0.5, 1.0))


## Clean records, pardons and doing your time all cut it down.
func clear_all(reason: String = "") -> void:
	var st := _st()
	if st.is_empty():
		return
	st["stars"] = 0.0
	if reason != "":
		GameState.add_log(reason)


func serve_time(years: int) -> void:
	var st := _st()
	if st.is_empty():
		return
	# Doing the time answers for the crime, but the file does not vanish.
	st["stars"] = clampf(float(st["stars"]) - 0.55 * float(maxi(1, years)), 0.0, float(MAX_STARS))


func yearly() -> void:
	var st := _st()
	if st.is_empty() or not GameState.is_alive():
		return
	var age := int(GameState.player.get("age", 0))
	var quiet := age - int(st.get("last_crime_age", -99))
	if quiet >= 2 and float(st["stars"]) > 0.0:
		# Going straight works, slowly, and more slowly the worse it got.
		var cool := 0.16 if stars() >= 4 else 0.28
		st["stars"] = maxf(0.0, float(st["stars"]) - cool)
	# Being wanted is not free even on a quiet year.
	var s := stars()
	if s >= 3:
		GameState.change_stat("stress", float(s) * 1.6)
	if s >= 4 and randf() < 0.30:
		GameState.add_log("I keep changing where I sleep. It is not a life.")
		GameState.change_stat("happiness", -float(s))


# ---------------------------------------------------------------- what it costs

## Extra evidence the prosecution brings because of who you already are.
func trial_bias() -> float:
	return float(stars()) * 5.5


## Multiplier on a prison sentence.
func sentence_mult() -> float:
	return 1.0 + float(stars()) * 0.22


## How much harder it is to be hired.
func hiring_penalty() -> float:
	return float(stars()) * 0.08


## Whether a border is going to be a problem. Three stars is the level where the
## description says there is a warrant out, and a warrant is exactly the thing
## that stops you boarding — so that is where the wall goes, not at four.
func can_leave_country() -> bool:
	return stars() < 3


## Chance per year that the law comes to you rather than waiting.
func pursuit_chance() -> float:
	var s := stars()
	if s < 2:
		return 0.0
	return 0.04 * float(s - 1)


func summary_lines() -> Array:
	var out: Array = []
	var s := stars()
	if s > 0:
		out.append(["%s %s" % [display(), level_name()], level_desc()])
	var c := crimes()
	if c > 0:
		out.append(["🔨 %d %s committed" % [c, "crime" if c == 1 else "crimes"],
			"Peak: %s" % ("⭐".repeat(peak()) if peak() > 0 else "never wanted")])
	return out


## For the records panel, so "in retrospect" is a real screen and not a number.
func history_lines() -> Array:
	var out: Array = []
	var bk := by_kind()
	var keys: Array = bk.keys()
	keys.sort_custom(func(a, b): return int(bk[a]) > int(bk[b]))
	for k in keys:
		var n := int(bk[k])
		out.append(["%s" % str(k).capitalize(), "%d %s" % [n, "time" if n == 1 else "times"]])
	return out
