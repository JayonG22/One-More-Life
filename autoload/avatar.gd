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

## Everything here sits on top of the age-and-gender face the game has always used.
## Option 0 of "Figure" and "Hair" means "follow that template"; pick anything else to override it.
const FIGURE := ["Match my life", "Man", "Woman", "Person"]
const HAIR := ["Match my life", "Red hair", "Curly hair", "White hair", "Bald", "Blond"]
const HAIR_ZWJ := ["", "🦰", "🦱", "🦳", "🦲", ""]
const HAT := ["None", "Cap", "Sun hat", "Graduation cap", "Top hat", "Crown", "Helmet", "Cowboy hat"]
const HAT_EMOJI := ["", "🧢", "👒", "🎓", "🎩", "👑", "🪖", "🤠"]
const GLASSES := ["None", "Glasses", "Shades", "Goggles"]
const GLASSES_EMOJI := ["", "👓", "🕶", "🥽"]
const EXTRA := ["None", "Headphones", "Ribbon", "Scarf", "Medal", "Flower", "Gem", "Star"]
const EXTRA_EMOJI := ["", "🎧", "🎀", "🧣", "🏅", "🌸", "💎", "⭐"]

## [key, label, option count, kind]  kind: "style" | "color"
const CATEGORIES := [
	["skin", "Skin tone", 6, "style"], ["figure", "Figure", 4, "style"], ["hair", "Hair", 6, "style"],
	["hat", "Headwear", 8, "style"], ["glasses", "Eyewear", 4, "style"], ["extra", "Extra", 8, "style"],
	["bg", "Backdrop", 8, "color"],
]

## What the Star Shop charges for the parts that are not free ("category:index": stars).
const COST := {
	"hat:3": 6, "hat:4": 12, "hat:5": 30, "hat:6": 8, "hat:7": 12,
	"glasses:2": 12, "glasses:3": 8,
	"hair:3": 6, "hair:4": 6, "hair:5": 8,
	"extra:4": 8, "extra:5": 6, "extra:6": 14, "extra:7": 10, "bg:7": 6,
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
	return g["avatar"]


func set_current(a: Dictionary) -> void:
	_g()["avatar"] = a.duplicate()
	if GameState.has_life():
		GameState.player["avatar"] = a.duplicate()
	Meta.save()


## The avatar for the person being played: the life's own, or the saved default.
func for_player() -> Dictionary:
	if GameState.has_life() and GameState.player.get("avatar", {}) is Dictionary and not (GameState.player["avatar"] as Dictionary).is_empty():
		return GameState.player["avatar"]
	return current()


## A random look from the free parts. Most lives simply follow the template.
func random(_gender: String = "male") -> Dictionary:
	var a := {"skin": randi() % SKIN.size(), "figure": 0, "hair": 0, "hat": 0, "glasses": 0, "extra": 0, "bg": randi() % 7}
	if randf() < 0.3:
		a["hair"] = 1 + randi() % 2
	if randf() < 0.2:
		a["glasses"] = 1
	if randf() < 0.15:
		a["hat"] = 1 + randi() % 2
	for cat in CATEGORIES:
		var k: String = cat[0]
		if not is_owned(k, int(a[k])):
			a[k] = 0
	return a


func name_of(cat: String, idx: int) -> String:
	var lists := {"skin": SKIN_NAME, "figure": FIGURE, "hair": HAIR, "hat": HAT, "glasses": GLASSES, "extra": EXTRA}
	if lists.has(cat):
		return str(lists[cat][clampi(idx, 0, lists[cat].size() - 1)])
	return "Colour %d" % (idx + 1)


func color_of(cat: String, idx: int) -> Color:
	return Color(str(BG_COL[clampi(idx, 0, BG_COL.size() - 1)]))


## The emoji for what a part looks like, for the shop and editor chips.
func glyph_of(cat: String, idx: int) -> String:
	match cat:
		"hat": return str(HAT_EMOJI[clampi(idx, 0, HAT_EMOJI.size() - 1)])
		"glasses": return str(GLASSES_EMOJI[clampi(idx, 0, GLASSES_EMOJI.size() - 1)])
		"extra": return str(EXTRA_EMOJI[clampi(idx, 0, EXTRA_EMOJI.size() - 1)])
	return ""


## The face itself: the long-standing age-and-gender emoji, with the chosen figure, skin
## tone and hair laid over the template.
func face_emoji(av: Dictionary, age: int, gender: String) -> String:
	var tone: String = str(SKIN[clampi(int(av.get("skin", 0)), 0, SKIN.size() - 1)])
	var gen := gender
	match int(av.get("figure", 0)):
		1: gen = "male"
		2: gen = "female"
		3: gen = "nonbinary"
	if age < 3:
		return "👶" + tone
	var hair := int(av.get("hair", 0))
	if hair > 0 and age >= 13 and age < 65:
		if hair == 5:
			return "👱" + tone + ("\u200d♂\ufe0f" if gen == "male" else ("\u200d♀\ufe0f" if gen == "female" else ""))
		var base := "👨" if gen == "male" else ("👩" if gen == "female" else "🧑")
		return base + tone + "\u200d" + str(HAIR_ZWJ[hair])
	return UIKit.face_tone(gen, age, tone)
