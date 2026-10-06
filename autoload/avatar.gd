extends Node

## AVATAR — the original portrait art, with saved personal appearance choices.
##
## The current look is the player's own and is kept across lives; it can be changed at
## any time. Original skin/hair choices and new adult colours are free. Optional themed
## looks and charms remain in the Star Shop; ownership persists across saves.

## Skin tones are the emoji tone modifiers; the first is the plain yellow-ish default.
const SKIN := ["", "🏻", "🏼", "🏽", "🏾", "🏿"]
const SKIN_NAME := ["Classic", "Light", "Medium-light", "Medium", "Medium-dark", "Dark"]
const BG_COL := ["#27324a", "#2e4a3a", "#4a2e3a", "#4a3d2a", "#2a4a4a", "#3a2e4a", "#4a4a4a", "#1c1c28", "#314844", "#694836", "#343e59", "#5b465b", "#365447", "#59513c", "#3c5059", "#70403c", "#293b43", "#43364b", "#384339", "#443b32", "#333650", "#4c343c", "#274349", "#424245"]
const RIM_COL := ["#43575c","#71928b","#9c805e","#8b769d","#6f8faa","#a67683","#858b66","#96949b"]
const BADGES := [["None",""],["Heart","💛"],["Star","⭐"],["Music","🎵"],["Paw","🐾"],["Book","📖"],["Leaf","🍃"],["Moon","🌙"],["Planet","🪐"]]
const SKIN_COL := ["#f5cb58","#f0d0af","#dbac80","#c88e60","#a8744e","#805337"]
const HAIR_COL := ["#6c4c38","#302e2b","#72503a","#a86a44","#c8a467","#d8c6a3","#c9c5bb","#874d50","#627679","#706681","#79614d","#454c57"]
const EYE_COL := ["#765843","#4e6e72","#64795d","#9a875d","#655c73","#4f4a45","#77868a","#887153"]
const CLOTH_COL := ["#5c7580","#789282","#9a7e60","#856c86","#9a666b","#5d656e","#9b967c","#51696a","#7885a0","#8f735f"]
const CUTS := ["Life style","Soft tuft","Short crop","Side part","Bob","Waves","Curls","Coils","Locs","Braids","Ponytail","Bun","Pixie","Afro","Long hair","Buzz cut","Bald"]
const FEATURES := {"eyes":["Soft","Almond","Round","Lashes","Narrow","Lifted"],"brows":["Natural","Full","Fine","Arched","Straight"],"nose":["Soft","Round","Defined","Wide","Narrow"],"mouth":["Soft","Wide","Full","Small"],"face_shape":["Soft oval","Long oval","Round","Heart","Broad"],"details":["None","Freckles","More freckles","Beauty mark","Brow scar"],"facial_hair":["None","Stubble","Short beard","Full beard","Moustache","Goatee"],"accessory":["None","Glasses","Round glasses","Sunglasses","Studs","Hoops","Nose stud","Headphones"]}

## Legacy figure/hair/look indices remain stable. Original glyphs remain the base.
const FIGURE := ["Match my life", "Man", "Woman", "Person"]
const HAIR := ["Match my life", "Red hair", "Curly hair", "White hair", "Bald", "Blond"]
const HAIR_ZWJ := ["", "🦰", "🦱", "🦳", "🦲", ""]
## [name, emoji]  ({t} is the skin tone). Single emoji only: they draw the same everywhere.
const STYLE := [
	["Everyday", ""], ["Beard", "🧔{t}"], ["Turban", "👳{t}"], ["Headscarf", "🧕{t}"], ["Cap", "👲{t}"],
	["Builder", "👷{t}"], ["Officer", "👮{t}"], ["Detective", "🕵{t}"], ["Royal", "🤴{t}"], ["Wizard", "🧙{t}"],
	["Cowboy", "🤠"], ["Hero", "🦸{t}"], ["Ninja", "🥷{t}"], ["Vampire", "🧛{t}"], ["Elf", "🧝{t}"],
	["Artist", "🧑{t}‍🎨"], ["Scientist", "🧑{t}‍🔬"], ["Astronaut", "🧑{t}‍🚀"], ["Chef", "🧑{t}‍🍳"], ["Farmer", "🧑{t}‍🌾"], ["Pilot", "🧑{t}‍✈️"],
	["Teacher", "🧑{t}‍🏫"], ["Medic", "🧑{t}‍⚕️"], ["Musician", "🧑{t}‍🎤"], ["Student", "🧑{t}‍🎓"], ["Robot", "🤖"], ["Alien", "👽"],
	["Shades","😎"],["Monocle","🧐"],["Party","🥳"],["Halo","😇"],["Sleepy","😴"],["Formal","🤵{t}"],["Wedding","👰{t}"],["Spa day","🧖{t}"],["Dancer","💃{t}"],["Cyclist","🚴{t}"],["Merperson","🧜{t}"],
]

## [key, label, option count, kind]  kind: "style" | "color"
const CATEGORIES := [
	["portrait_accessory","Accessories",6,"style"],["portrait_detail","Face details",4,"style"],["portrait_hair","Hair colour",13,"style"],["portrait_eyes","Eye colour",9,"style"],
	["skin","Skin tone",6,"style"],["cut","Haircut",17,"style"],["hair_color","Hair colour",12,"color"],["eyes","Eyes",6,"style"],["eye_color","Eye colour",8,"color"],
	["brows","Brows",5,"style"],["nose","Nose",5,"style"],["mouth","Mouth",4,"style"],["face_shape","Face shape",5,"style"],
	["details","Face details",5,"style"],["facial_hair","Facial hair",6,"style"],["accessory","Accessories",8,"style"],["clothes","Clothing colour",10,"color"],
	["figure","Figure",4,"style"],["style","Look",38,"style"],["bg","Backdrop",24,"color"],["frame","Portrait rim",8,"color"],["badge","Personal charm",9,"style"],["hair","Legacy hair",6,"style"],
]

## What the Star Shop charges for the parts that are not free ("category:index": stars).
const COST := {
	"style:2": 4, "style:3": 4, "style:4": 4, "style:5": 6, "style:6": 6, "style:7": 8, "style:8": 30,
	"style:9": 14, "style:10": 10, "style:11": 12, "style:12": 10, "style:13": 12, "style:14": 10,
	"style:15": 8, "style:16": 8, "style:17": 14, "style:18": 8, "style:19": 6, "style:20": 10, "style:21": 8, "style:22": 8, "style:23": 10, "style:24": 6, "style:25": 12, "style:26": 12,
	"bg:8": 4, "bg:9": 4, "bg:10": 4, "bg:11": 4, "bg:12": 4, "bg:13": 4, "bg:14": 4, "bg:15": 4,
	"badge:2":4,"badge:3":4,"badge:4":4,"badge:5":4,"badge:6":4,"badge:7":6,"badge:8":6,
	"style:27":8,"style:28":8,"style:29":8,"style:30":8,"style:31":4,"style:32":8,"style:33":8,"style:34":6,"style:35":8,"style:36":8,"style:37":12,
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
	if cat=="hair": return 0
	return int(COST.get("%s:%d" % [cat, idx], 0))

func editor_categories() -> Array:
	# Keep all saved features, showing only working original portrait controls.
	var out: Array=[]
	for key in ["skin","figure","hair","portrait_hair","portrait_eyes","portrait_accessory","portrait_detail","style","bg","frame","badge"]:
		for cat in CATEGORIES:
			if cat[0]==key:
				var row: Array=cat.duplicate()
				if key=="hair": row[1]="Hair"
				out.append(row)
	return out


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


## Free features use a local random generator. NPC seeds belong to their identity.
func random(_gender: String = "male", look_seed: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if look_seed<0: rng.seed=randi()
	else: rng.seed=look_seed
	var a := sanitize({"skin":rng.randi_range(0,5),"bg":rng.randi_range(0,6)})
	for key in ["cut","hair_color","eyes","eye_color","brows","nose","mouth","face_shape","details","clothes"]:
		for cat in CATEGORIES:
			if cat[0]==key: a[key]=rng.randi_range(0,int(cat[2])-1)
	a["accessory"]=rng.randi_range(0,7) if rng.randf()<0.35 else 0
	if rng.randf()<0.90: a["hair_color"]=[0,1,2,3,4,5,10][rng.randi_range(0,6)]
	a["portrait_accessory"]=rng.randi_range(1,5) if rng.randf()<0.22 else 0
	a["portrait_detail"]=rng.randi_range(1,3) if rng.randf()<0.18 else 0
	a["portrait_hair"]=rng.randi_range(1,6) if rng.randf()<0.55 else 0
	a["portrait_eyes"]=rng.randi_range(1,8) if rng.randf()<0.40 else 0
	a["facial_hair"]=rng.randi_range(0,5) if _gender=="male" and rng.randf()<0.30 else 0
	return a

func appearance(person: Dictionary) -> Dictionary:
	if not person.has("avatar") or not person["avatar"] is Dictionary or person["avatar"].is_empty():
		person["avatar"]=random(str(person.get("gender","nonbinary")),absi(FamilyChronicle.identity(person).hash()))
	person["avatar"]=sanitize(person["avatar"])
	return person["avatar"]

func face_state(person: Dictionary) -> String:
	if not person.get("alive",true): return "remembered"
	var stats: Dictionary=person.get("stats",person)
	if str(person.get("illness",""))!="" or float(stats.get("health",75))<30: return "unwell"
	if float(stats.get("stress",20))>=75: return "strain"
	if float(stats.get("happiness",60))<30: return "low"
	if float(stats.get("health",75))<55: return "tired"
	if float(stats.get("happiness",60))>=80: return "happy"
	return "steady"


func name_of(cat: String, idx: int) -> String:
	if cat=="portrait_accessory": return ["None","Round glasses","Soft frames","Sunglasses","Studs","Hoops"][clampi(idx,0,5)]
	if cat=="portrait_detail": return ["None","Freckles","Beauty mark","Brow scar"][clampi(idx,0,3)]
	if cat=="portrait_hair": return ["Original","Brown","Black","Chestnut","Copper","Honey","Blond","Silver","Rose","Teal","Lilac","Walnut","Slate"][clampi(idx,0,12)]
	if cat=="portrait_eyes": return ["Original","Brown","Blue","Green","Hazel","Violet","Dark","Grey","Amber"][clampi(idx,0,8)]
	if cat=="cut": return CUTS[clampi(idx,0,CUTS.size()-1)]
	if FEATURES.has(cat): return str(FEATURES[cat][clampi(idx,0,FEATURES[cat].size()-1)])
	match cat:
		"skin": return str(SKIN_NAME[clampi(idx, 0, SKIN_NAME.size() - 1)])
		"figure": return str(FIGURE[clampi(idx, 0, FIGURE.size() - 1)])
		"hair": return str(HAIR[clampi(idx, 0, HAIR.size() - 1)])
		"style": return str(STYLE[clampi(idx, 0, STYLE.size() - 1)][0])
		"badge": return str(BADGES[clampi(idx,0,BADGES.size()-1)][0])
	return "Colour %d" % (idx + 1)


func color_of(_cat: String, idx: int) -> Color:
	if _cat=="hair_color": return Color(HAIR_COL[clampi(idx,0,HAIR_COL.size()-1)])
	if _cat=="eye_color": return Color(EYE_COL[clampi(idx,0,EYE_COL.size()-1)])
	if _cat=="clothes": return Color(CLOTH_COL[clampi(idx,0,CLOTH_COL.size()-1)])
	if _cat=="frame": return Color(RIM_COL[clampi(idx,0,RIM_COL.size()-1)])
	return Color(str(BG_COL[clampi(idx, 0, BG_COL.size() - 1)]))


## A small emoji that shows what an option looks like, for the editor and the shop.
func glyph_of(cat: String, idx: int) -> String:
	if cat=="badge": return str(BADGES[clampi(idx,0,BADGES.size()-1)][1])
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
