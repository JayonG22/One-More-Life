extends Node

## AVATAR — who you look like. Drawn, not picked from a list of faces, so a life can
## start with the person you want to play and grow old as them.
##
## The current look is the player's own and is kept across lives; it can be changed at
## any time. Some parts are free and some are sold in the Star Shop (hats, shades,
## wild hair colours and so on); a part you own is yours in every save.

const SKIN := ["#fbe3d3", "#f4d0b0", "#e8b98c", "#d39d70", "#b97b52", "#9a5f3a", "#7a4529", "#5a321d", "#3f2314"]
const HAIR_COL := ["#16110d", "#3b2a1e", "#6b4423", "#a8742f", "#d8b258", "#b23a1e", "#8d8d92", "#f2f2f4", "#e87bb0", "#4a8df0", "#43b97f", "#8a4de0"]
const EYE_COL := ["#3b2a1e", "#6b4423", "#2f6fb5", "#3f8f5f", "#7a8a96", "#8a5aa8"]
const TOP_COL := ["#d94f4f", "#e8863a", "#e8c53a", "#58b368", "#3aa6a6", "#4f7fd9", "#7a5ad0", "#d95aa8", "#2c313a", "#e6e6e6", "#6b4a2f", "#1f3a5f"]
const BG_COL := ["#27324a", "#2e4a3a", "#4a2e3a", "#4a3d2a", "#2a4a4a", "#3a2e4a", "#4a4a4a", "#1c1c28"]

const HAIR := ["Bald", "Buzz cut", "Short", "Side part", "Curls", "Afro", "Long", "Ponytail", "Bun", "Braids", "Mohawk", "Bob", "Waves", "Spikes"]
const EYES := ["Round", "Almond", "Wide", "Sleepy", "Narrow", "Sparkling"]
const MOUTH := ["Smile", "Grin", "Neutral", "Smirk", "Open", "Pout"]
const BROWS := ["Soft", "Straight", "Arched", "Thick"]
const BEARD := ["None", "Stubble", "Goatee", "Full beard", "Moustache"]
const GLASSES := ["None", "Round", "Square", "Shades", "Monocle"]
const HAT := ["None", "Cap", "Beanie", "Crown", "Cowboy hat", "Headband"]
const TOP := ["T-shirt", "Hoodie", "Shirt", "Suit", "Dress", "Uniform"]
const MARK := ["None", "Freckles", "Beauty mark", "Scar"]

## [key, label, option count, kind]  kind: "style" | "color"
const CATEGORIES := [
	["skin", "Skin", 9, "color"], ["hair", "Hair", 14, "style"], ["hair_col", "Hair colour", 12, "color"],
	["eyes", "Eyes", 6, "style"], ["eye_col", "Eye colour", 6, "color"], ["brows", "Brows", 4, "style"],
	["mouth", "Mouth", 6, "style"], ["beard", "Facial hair", 5, "style"], ["mark", "Marks", 4, "style"],
	["glasses", "Glasses", 5, "style"], ["hat", "Headwear", 6, "style"], ["top", "Clothes", 6, "style"],
	["top_col", "Clothes colour", 12, "color"], ["bg", "Backdrop", 8, "color"],
]

## What the Star Shop charges for the parts that are not free ("category:index": stars).
const COST := {
	"hair:5": 10, "hair:10": 12, "hair:13": 8, "hair:9": 8, "hair_col:8": 12, "hair_col:9": 12, "hair_col:10": 12, "hair_col:11": 12,
	"hat:3": 30, "hat:4": 12, "hat:2": 6, "hat:1": 6, "glasses:3": 12, "glasses:4": 18, "glasses:2": 6,
	"top:3": 14, "top:5": 10, "top:4": 6, "mark:3": 8, "eyes:5": 10, "beard:3": 8, "beard:4": 6, "bg:7": 6,
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


## A random look from the free parts, leaning on the gender for starting hair and clothes.
func random(gender: String = "male") -> Dictionary:
	var a := {"skin": randi() % SKIN.size(), "hair": 0, "hair_col": randi() % 8, "eyes": randi() % 5, "eye_col": randi() % EYE_COL.size(), "brows": randi() % BROWS.size(), "mouth": randi() % MOUTH.size(), "beard": 0, "mark": 0, "glasses": 0, "hat": 0, "top": 0, "top_col": randi() % TOP_COL.size(), "bg": randi() % 7}
	var hair_pool: Array = [1, 2, 3, 4, 6, 7, 8, 11, 12] if gender == "female" else ([2, 3, 4, 1, 0, 13] if gender == "male" else [2, 3, 4, 6, 11, 12, 13])
	a["hair"] = hair_pool[randi() % hair_pool.size()]
	if gender == "male" and randf() < 0.3:
		a["beard"] = [1, 2, 4][randi() % 3]
	if randf() < 0.25:
		a["glasses"] = 1
	if randf() < 0.25:
		a["mark"] = 1 + randi() % 2
	a["top"] = [0, 1, 2][randi() % 3] if gender != "female" else [0, 1, 2, 4][randi() % 4]
	for cat in CATEGORIES:
		var k: String = cat[0]
		if not is_owned(k, int(a[k])):
			a[k] = 0
	return a


func name_of(cat: String, idx: int) -> String:
	var lists := {"hair": HAIR, "eyes": EYES, "mouth": MOUTH, "brows": BROWS, "beard": BEARD, "glasses": GLASSES, "hat": HAT, "top": TOP, "mark": MARK}
	if lists.has(cat):
		return str(lists[cat][clampi(idx, 0, lists[cat].size() - 1)])
	return "%d" % (idx + 1)


func color_of(cat: String, idx: int) -> Color:
	var lists := {"skin": SKIN, "hair_col": HAIR_COL, "eye_col": EYE_COL, "top_col": TOP_COL, "bg": BG_COL}
	var arr: Array = lists.get(cat, SKIN)
	return Color(str(arr[clampi(idx, 0, arr.size() - 1)]))
