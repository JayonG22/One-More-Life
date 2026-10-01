extends Node

## AVATAR — who you look like. Drawn, not picked from a list of faces, so a life can
## start with the person you want to play and grow old as them.
##
## The current look is the player's own and is kept across lives; it can be changed at
## any time. Some parts are free and some are sold in the Star Shop (hats, shades,
## wild hair colours and so on); a part you own is yours in every save.

## Skin tones are the emoji tone modifiers; the first is the plain yellow-ish default.
const SKIN := ["", "🏻", "🏼", "🏽", "🏾", "🏿"]
const SKIN_NAME := ["Classic", "Light", "Medium-light", "Medium", "Medium-dark", "Dark"]
const BG_COL := ["#27324a", "#2e4a3a", "#4a2e3a", "#4a3d2a", "#2a4a4a", "#3a2e4a", "#4a4a4a", "#1c1c28"]

## Every option here is a real emoji, picked whole; nothing is drawn or layered on top.
## "Match my life" / "Everyday" means the age-and-gender face the game has always used.
const FIGURE := ["Match my life", "Man", "Woman", "Person"]
const HAIR := ["Match my life", "Red hair", "Curly hair", "White hair", "Bald", "Blond"]
const HAIR_ZWJ := ["", "🦰", "🦱", "🦳", "🦲", ""]
## [name, emoji]  ({t} is the skin tone). Single emoji only: they draw the same everywhere.
const STYLE := [
	["Everyday", ""], ["Beard", "🧔{t}"], ["Turban", "👳{t}"], ["Headscarf", "🧕{t}"], ["Cap", "👲{t}"],
	["Builder", "👷{t}"], ["Officer", "👮{t}"], ["Detective", "🕵{t}"], ["Royal", "🤴{t}"], ["Wizard", "🧙{t}"],
	["Cowboy", "🤠"], ["Hero", "🦸{t}"], ["Ninja", "🥷{t}"], ["Vampire", "🧛{t}"], ["Elf", "🧝{t}"],
]

## [key, label, option count, kind]  kind: "style" | "color"
const CATEGORIES := [
	["skin", "Skin tone", 6, "style"], ["figure", "Figure", 4, "style"], ["hair", "Hair", 6, "style"],
	["style", "Look", 15, "style"], ["bg", "Backdrop", 8, "color"],
]

## What the Star Shop charges for the parts that are not free ("category:index": stars).
const COST := {
	"style:2": 4, "style:3": 4, "style:4": 4, "style:5": 6, "style:6": 6, "style:7": 8, "style:8": 30,
	"style:9": 14, "style:10": 10, "style:11": 12, "style:12": 10, "style:13": 12, "style:14": 10,
	"hair:3": 6, "hair:4": 6, "hair:5": 8, "bg:7": 6,
}


func _g() -> Dictionary:
	return Goals._g()


func owned_set() -> Dictionary:
	var g := _g()
	if not g.has("avatar_owned") or not (g["avatar_owned"] is Dictionary):
		g["avatar_owned"] = {}
	return g["avatar_owned"]


func cost_of(cat: String, idx: int) -> int:
	return int(COST.get("%s:%d" % [cat, idx], 0))


func is_owned(cat: String, idx: int) -> bool:
	return cost_of(cat, idx) == 0 or owned_set().has("%s:%d" % [cat, idx])


func buy(cat: String, idx: int) -> bool:
	var c := cost_of(cat, idx)
	if c == 0 or is_owned(cat, idx) or Goals.stars() < c:
		return false
	var g := _g()
	g["stars"] = Goals.stars() - c
	owned_set()["%s:%d" % [cat, idx]] = true
	Meta.save()
	return true


func current() -> Dictionary:
	var g := _g()
	if not g.has("avatar") or not (g["avatar"] is Dictionary) or g["avatar"].is_empty():
		g["avatar"] = random("male")
	g["avatar"] = sanitize(g["avatar"])
	return g["avatar"]


func set_current(a: Dictionary) -> void:
	_g()["avatar"] = a.duplicate()
	if GameState.has_life():
		GameState.player["avatar"] = a.duplicate()
	Meta.save()


## The avatar for the person being played: the life's own, or the saved default.
func for_player() -> Dictionary:
	if GameState.has_life() and GameState.player.get("avatar", {}) is Dictionary and not (GameState.player["avatar"] as Dictionary).is_empty():
		GameState.player["avatar"] = sanitize(GameState.player["avatar"])
		return GameState.player["avatar"]
	return current()


## Clamp a saved look into today's options (older saves had other categories).
func sanitize(av: Dictionary) -> Dictionary:
	var out := {}
	for cat in CATEGORIES:
		out[cat[0]] = clampi(int(av.get(cat[0], 0)), 0, int(cat[2]) - 1)
	return out


## A random look from the free parts. Most lives simply follow the template.
func random(_gender: String = "male") -> Dictionary:
	var a := {"skin": randi() % SKIN.size(), "figure": 0, "hair": 0, "style": 0, "bg": randi() % 7}
	if randf() < 0.3:
		a["hair"] = 1 + randi() % 2
	for cat in CATEGORIES:
		var k: String = cat[0]
		if not is_owned(k, int(a[k])):
			a[k] = 0
	return a


func name_of(cat: String, idx: int) -> String:
	match cat:
		"skin": return str(SKIN_NAME[clampi(idx, 0, SKIN_NAME.size() - 1)])
		"figure": return str(FIGURE[clampi(idx, 0, FIGURE.size() - 1)])
		"hair": return str(HAIR[clampi(idx, 0, HAIR.size() - 1)])
		"style": return str(STYLE[clampi(idx, 0, STYLE.size() - 1)][0])
	return "Colour %d" % (idx + 1)


func color_of(_cat: String, idx: int) -> Color:
	return Color(str(BG_COL[clampi(idx, 0, BG_COL.size() - 1)]))


## A small emoji that shows what an option looks like, for the editor and the shop.
func glyph_of(cat: String, idx: int) -> String:
	if cat == "style" and idx > 0:
		return face_emoji({"style": idx}, 30, "male")
	if cat == "hair" and idx > 0:
		return face_emoji({"hair": idx}, 30, "male")
	return ""


## The face itself, always a real emoji: the long-standing age-and-gender one, or the
## figure, hair and look the player chose, with the skin tone applied.
func face_emoji(av0: Dictionary, age: int, gender: String) -> String:
	var av := sanitize(av0)
	var tone: String = str(SKIN[int(av["skin"])])
	var gen := gender
	match int(av["figure"]):
		1: gen = "male"
		2: gen = "female"
		3: gen = "nonbinary"
	if age < 3:
		return "👶" + tone
	if age >= 13:
		var st := int(av["style"])
		if st > 0:
			if st == 8 and gen == "female":
				return "👸" + tone
			return str(STYLE[st][1]).replace("{t}", tone)
		var hair := int(av["hair"])
		if hair > 0 and age < 65:
			if hair == 5:
				return "👱" + tone
			var base := "👨" if gen == "male" else ("👩" if gen == "female" else "🧑")
			return base + tone + "\u200d" + str(HAIR_ZWJ[hair])
	return UIKit.face_tone(gen, age, tone)
