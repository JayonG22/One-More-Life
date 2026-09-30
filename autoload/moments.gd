extends Node

## MOMENTS — the game's named vocabulary of beats.
##
## Presentation used to be decided by reading the sentence. `_react()` in main
## scanned the outcome text for "promot", "arrest", "baby" and guessed. That is
## wrong in two directions at once: an event whose text says "I was arrested"
## in a daydream got sirens, and an event that quietly put a felony on your
## record got a polite tap because nobody wrote the word "arrest" into it.
##
## So a beat is now chosen by WHAT HAPPENED, not by what the sentence says.
## EventEngine already knows it applied a crime, an illness, a jail term, a
## marriage, a windfall — it now says so, and this file turns that into sound,
## colour and motion.
##
## The vocabulary is the one the design doc asked for:
##   money_gain money_loss stat_gain stat_loss danger success failure
##   achievement death relationship_gain relationship_break jackpot
##   crime_heat diagnosis
## plus the beats the game needed that the list did not name: birth, wedding,
## freedom, transformation, milestone, loss.
##
## Any system can invoke one: `Moments.fire("jackpot")`. Nothing has to know
## where the effects layer lives or which of the thirty sounds is the right one.
## That is the whole point — one place to tune the feel of the game.

## Every beat: sound, particles, flash, shake. Scale 0..1 modulates all of it.
##   sound    id passed to Fx.play
##   burst    [kind, count at full intensity]  (falls from the top)
##   rise     [kind, count]                    (floats up from the bottom)
##   flash    [theme colour key or #hex, strength, seconds]
##   shake    [strength, seconds]
##   floor    minimum intensity this beat is ever played at
const BEATS := {
	# ---- money
	"money_gain":   {"sound": "coin", "burst": ["coins", 14], "flash": ["", 0.0, 0.0], "shake": [0.0, 0.0]},
	"money_loss":   {"sound": "bad", "burst": ["", 0], "flash": ["bad", 0.16, 0.35], "shake": [3.0, 0.2]},
	"jackpot":      {"sound": "legendary", "burst": ["coins", 34], "flash": ["gold", 0.42, 0.8], "shake": [6.0, 0.4], "floor": 0.85},

	# ---- effort and outcome
	"success":      {"sound": "good", "burst": ["sparks", 10], "flash": ["good", 0.14, 0.3], "shake": [0.0, 0.0]},
	"failure":      {"sound": "bad", "burst": ["", 0], "flash": ["bad", 0.2, 0.35], "shake": [5.0, 0.25]},
	"stat_gain":    {"sound": "levelup", "burst": ["sparks", 8], "flash": ["", 0.0, 0.0], "shake": [0.0, 0.0]},
	"stat_loss":    {"sound": "bad", "burst": ["", 0], "flash": ["bad", 0.12, 0.3], "shake": [3.0, 0.2]},
	"achievement":  {"sound": "achieve", "burst": ["confetti", 24], "flash": ["gold", 0.24, 0.5], "shake": [0.0, 0.0], "floor": 0.7},

	# ---- harm
	"danger":       {"sound": "bad", "burst": ["", 0], "flash": ["bad", 0.34, 0.5], "shake": [10.0, 0.4], "floor": 0.5},
	"crime_heat":   {"sound": "siren", "burst": ["", 0], "flash": ["bad", 0.3, 0.6], "shake": [7.0, 0.35], "floor": 0.6},
	"verdict":      {"sound": "gavel", "burst": ["", 0], "flash": ["bad", 0.26, 0.5], "shake": [8.0, 0.3], "floor": 0.75},
	"diagnosis":    {"sound": "monitor", "burst": ["", 0], "flash": ["#3d6c7a", 0.26, 0.9], "shake": [0.0, 0.0], "floor": 0.7},
	"death":        {"sound": "death", "burst": ["grief", 10], "flash": ["#000000", 0.4, 1.2], "shake": [0.0, 0.0], "floor": 1.0},
	"loss":         {"sound": "twist", "burst": ["grief", 8], "flash": ["#2b2e33", 0.28, 0.9], "shake": [0.0, 0.0], "floor": 0.7},

	# ---- people
	"relationship_gain":  {"sound": "good", "rise": ["hearts", 10], "flash": ["", 0.0, 0.0], "shake": [0.0, 0.0]},
	"relationship_break": {"sound": "twist", "burst": ["grief", 8], "flash": ["bad", 0.2, 0.6], "shake": [5.0, 0.3], "floor": 0.6},
	"wedding":      {"sound": "wedding", "rise": ["hearts", 16], "burst": ["confetti", 18], "flash": ["gold", 0.2, 0.6], "shake": [0.0, 0.0], "floor": 0.9},
	"birth":        {"sound": "baby", "rise": ["hearts", 12], "flash": ["", 0.0, 0.0], "shake": [0.0, 0.0], "floor": 0.8},

	# ---- standing
	"fame":         {"sound": "crowd", "burst": ["sparks", 20], "flash": ["gold", 0.18, 0.5], "shake": [0.0, 0.0], "floor": 0.6},
	"milestone":    {"sound": "fanfare", "burst": ["confetti", 26], "flash": ["gold", 0.2, 0.5], "shake": [0.0, 0.0], "floor": 0.8},
	"freedom":      {"sound": "fanfare", "burst": ["confetti", 20], "flash": ["good", 0.22, 0.5], "shake": [0.0, 0.0], "floor": 0.8},
	"news":         {"sound": "news", "burst": ["", 0], "flash": ["accent", 0.14, 0.4], "shake": [0.0, 0.0], "floor": 0.6},

	# ---- becoming something else
	"turn_vampire": {"sound": "bite", "burst": ["blood", 18], "flash": ["#7a0014", 0.45, 0.9], "shake": [6.0, 0.4], "floor": 1.0},
	"turn_witch":   {"sound": "magic", "burst": ["magic", 24], "flash": ["#6b3fa0", 0.35, 0.8], "shake": [0.0, 0.0], "floor": 1.0},
	"turn_super":   {"sound": "power", "burst": ["sparks", 20], "flash": ["#2f6bff", 0.4, 0.5], "shake": [7.0, 0.35], "floor": 1.0},
	"turn_royal":   {"sound": "crown", "burst": ["royal", 26], "flash": ["#e8c15a", 0.3, 0.8], "shake": [0.0, 0.0], "floor": 1.0},
	"turn_undead":  {"sound": "rise", "burst": ["grief", 14], "flash": ["#3c6b3a", 0.4, 0.7], "shake": [8.0, 0.5], "floor": 1.0},
	"turn_other":   {"sound": "twist", "burst": ["sparks", 18], "flash": ["accent", 0.32, 0.7], "shake": [5.0, 0.35], "floor": 1.0},
}

## When several beats fire at once, the louder one wins the screen. Two at most,
## because three overlapping flashes is a migraine, not a celebration.
const LOUDNESS := {
	"death": 100, "turn_vampire": 96, "turn_undead": 96, "turn_royal": 95,
	"turn_witch": 95, "turn_super": 95, "turn_other": 94,
	"jackpot": 90, "diagnosis": 86, "verdict": 84, "wedding": 82, "birth": 80,
	"crime_heat": 78, "milestone": 76, "danger": 74, "freedom": 72,
	"relationship_break": 68, "loss": 66, "achievement": 64, "fame": 60,
	"news": 50, "money_loss": 44, "money_gain": 42, "relationship_gain": 40,
	"failure": 34, "success": 32, "stat_loss": 22, "stat_gain": 20,
}

var _fx_layer: Control = null
var _shake_root: Control = null


## main.gd hands over its layers once at startup. Everything else just fires.
func bind(fx_layer: Control, shake_root: Control) -> void:
	_fx_layer = fx_layer
	_shake_root = shake_root


func ready_to_play() -> bool:
	return _fx_layer != null and is_instance_valid(_fx_layer)


# ---------------------------------------------------------------- playing

## Fire a named beat. `intensity` 0..1 scales particle count, flash and shake;
## a beat with a `floor` is never played quieter than that.
func fire(beat: String, intensity: float = 1.0) -> void:
	if not BEATS.has(beat):
		return
	var b: Dictionary = BEATS[beat]
	var i := clampf(maxf(intensity, float(b.get("floor", 0.0))), 0.0, 1.0)
	if i <= 0.02:
		return
	Fx.play(str(b.get("sound", "tap")))
	if not ready_to_play():
		return
	var burst: Array = b.get("burst", ["", 0])
	if str(burst[0]) != "" and int(burst[1]) > 0:
		VFX.burst(_fx_layer, str(burst[0]), maxi(3, int(round(float(burst[1]) * i))))
	var ri: Array = b.get("rise", ["", 0])
	if str(ri[0]) != "" and int(ri[1]) > 0:
		VFX.rise(_fx_layer, str(ri[0]), maxi(3, int(round(float(ri[1]) * i))))
	var fl: Array = b.get("flash", ["", 0.0, 0.0])
	if float(fl[1]) > 0.0:
		VFX.flash(_fx_layer, _col(str(fl[0])), float(fl[1]) * i, float(fl[2]))
	var sh: Array = b.get("shake", [0.0, 0.0])
	if float(sh[0]) > 0.0 and _shake_root != null and is_instance_valid(_shake_root):
		VFX.shake(_shake_root, float(sh[0]) * i, float(sh[1]))


func _col(key: String) -> Color:
	if key == "":
		return Color.WHITE
	if key.begins_with("#"):
		return Color(key)
	return ThemeManager.c(key)


## Play a whole set of beats, loudest first, capped so the screen stays readable.
func play_set(beats: Dictionary) -> void:
	if beats.is_empty():
		return
	var order: Array = beats.keys()
	order.sort_custom(func(a, b): return int(LOUDNESS.get(a, 0)) > int(LOUDNESS.get(b, 0)))
	var played := 0
	for beat in order:
		fire(str(beat), float(beats[beat]))
		played += 1
		if played >= 2:
			break


# ---------------------------------------------------------------- reading events

## Turn what an outcome actually DID into beats. `signals` comes from
## EventEngine and is structural: it says a crime was committed, not that the
## word "crime" appeared. `changes` is the applied stat deltas.
func beats_for(signals: Array, changes: Dictionary) -> Dictionary:
	var out: Dictionary = {}

	for s in signals:
		var sig := str(s)
		match sig:
			"died":
				out["death"] = 1.0
			"jail":
				out["verdict"] = 1.0
			"trial":
				out["verdict"] = 0.85
			"crime":
				out["crime_heat"] = 0.9
			"fine":
				out["crime_heat"] = 0.6
			"cleared":
				out["freedom"] = 1.0
			"illness":
				out["diagnosis"] = 1.0
			"cure":
				out["success"] = 0.9
			"marry":
				out["wedding"] = 1.0
			"baby":
				out["birth"] = 1.0
			"partner_gained":
				out["relationship_gain"] = 1.0
			"partner_lost":
				out["relationship_break"] = 1.0
			"bereaved":
				out["loss"] = 1.0
			"fired", "quit_job":
				out["failure"] = 0.8
			"hired", "promoted":
				out["achievement"] = 0.9
			"milestone":
				out["milestone"] = 0.9
			"achievement":
				out["achievement"] = 1.0
			"fame":
				out["fame"] = 0.9
			"office":
				out["milestone"] = 1.0
			"bond_up":
				out["relationship_gain"] = 0.7
			"bond_down":
				out["relationship_break"] = 0.6

	# --- money reads off the actual delta, measured against what you have.
	var money := int(changes.get("money", 0))
	if money != 0:
		var worth := maxi(2000, absi(int(GameState.player.get("money", 0))))
		var weight := clampf(float(absi(money)) / float(worth), 0.0, 1.0)
		if money > 0:
			if absi(money) >= 250000 or weight >= 0.9:
				out["jackpot"] = 1.0
			elif absi(money) >= 200:
				out["money_gain"] = clampf(0.3 + weight, 0.3, 1.0)
		elif absi(money) >= 200:
			out["money_loss"] = clampf(0.3 + weight, 0.3, 1.0)

	# --- stats: the net swing, so a mixed result does not read as a triumph.
	var swing := 0.0
	var worst := 0.0
	for k in changes.keys():
		if k == "money":
			continue
		var v := float(changes[k])
		if k == "stress":
			v = -v
		swing += v
		worst = minf(worst, v)
	if worst <= -18.0 and not out.has("death"):
		out["danger"] = clampf(absf(worst) / 40.0, 0.5, 1.0)
	if swing >= 8.0:
		out["stat_gain"] = clampf(swing / 30.0, 0.3, 1.0)
	elif swing <= -8.0:
		out["stat_loss"] = clampf(absf(swing) / 30.0, 0.3, 1.0)

	return out


## Last resort for events that changed nothing measurable and carry no signals —
## a pure story beat. Reading the sentence is a fallback here, not the method.
const WORD_BEATS := {
	"milestone": ["graduat", "promot", "champion", "first place", "record deal", "elected", "award"],
	"wedding": ["wedding", "proposed", "said yes", "engaged"],
	"birth": ["baby", "twins", "triplets", "newborn", "expecting", "pregnan"],
	"fame": ["viral", "famous", "celebrity", "red carpet", "paparazzi", "premiere", "the charts"],
	"danger": ["crash", "accident", "attacked", "hospital", "collapsed", "the fire"],
	"loss": ["funeral", "buried", "passed away", "the grave"],
	"news": ["headline", "the paper", "on the news", "announced"],
}


func beats_from_text(title: String, text: String) -> Dictionary:
	var blob := (title + " " + text).to_lower()
	for beat in WORD_BEATS.keys():
		for k in WORD_BEATS[beat]:
			if blob.find(str(k)) != -1:
				return {beat: 0.8}
	return {}


## The one call main.gd makes when an outcome resolves.
func react(title: String, text: String, changes: Dictionary, signals: Array = []) -> void:
	var beats := beats_for(signals, changes)
	if beats.is_empty():
		beats = beats_from_text(title, text)
	if beats.is_empty():
		Fx.play_for_changes(changes)
		return
	play_set(beats)
