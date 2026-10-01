class_name Tombstone
extends Control

## The stone is drawn, and what it looks like comes from the life.
##
## The old death screen was one text card: identical for a saint and a murderer,
## a pauper and a billionaire, a child and a four-hundred-year-old vampire. The
## information was all there and none of it was visible at a glance.
##
## Now the silhouette, the material, the weathering, the ornament and the
## epitaph are all read off the life that just ended, so two graves never look
## the same unless two lives were.

const W := 400.0
const H := 620.0

var entry: Dictionary = {}
var ribbon: Dictionary = {}
var shape := "round"
var stone_col := Color("#8d9199")
var ink := Color("#2b2e33")
var weather := 0.0      ## 0 fresh, 1 ruined
var ornament := ""
var epitaph := ""
var moss := 0.0


func setup(e: Dictionary, r: Dictionary, p: Dictionary) -> void:
	entry = e
	ribbon = r
	_read_the_life(p)
	custom_minimum_size = Vector2(W, H)
	queue_redraw()


func _read_the_life(p: Dictionary) -> void:
	var age := int(entry.get("age", 0))
	var worth := int(p.get("legacy", {}).get("net", p.get("money", 0)))
	var karma := int(p.get("karma", 0))
	var fame := float(p.get("fame", 0.0))
	var life_kind := str(p.get("life", {}).get("type", "human"))
	var record: Array = p.get("record", [])
	var kids := GameState.npcs_with("child", false).size()

	# --- silhouette: what kind of marker this life earned
	if life_kind == "royal" or fame >= 85.0:
		shape = "obelisk"
	elif age <= 12:
		shape = "small"
	elif worth >= 5000000:
		shape = "mausoleum"
	elif life_kind in ["vampire", "revenant", "witch"]:
		shape = "gothic"
	elif age >= 90:
		shape = "celtic"
	elif not record.is_empty() and karma <= -30:
		shape = "broken"
	else:
		shape = "round"

	# --- material: what it is made of, and therefore what it cost
	if worth >= 5000000:
		stone_col = Color("#e8e2d4")        # pale marble
	elif worth >= 400000:
		stone_col = Color("#b9bcc2")        # good granite
	elif worth >= 40000:
		stone_col = Color("#8d9199")        # ordinary stone
	elif worth >= 2000:
		stone_col = Color("#767a80")        # plain slab
	else:
		stone_col = Color("#6d6459")        # a wooden marker
	if life_kind == "vampire":
		stone_col = Color("#4a3540")
	elif life_kind == "revenant":
		stone_col = Color("#5c6153")
	elif life_kind == "witch":
		stone_col = Color("#4b4258")
	ink = Color("#2b2e33") if stone_col.get_luminance() > 0.42 else Color("#e7e3da")

	# --- weathering: how long the world has had to forget you
	weather = clampf(float(age) / 150.0, 0.0, 0.85)
	moss = clampf(float(kids) * 0.12 + (0.3 if karma > 30 else 0.0), 0.0, 0.9)
	if karma <= -50:
		moss = 0.0                          # nobody tends it

	# --- ornament: the single thing this life is remembered for
	if life_kind == "vampire":
		ornament = "🦇"
	elif life_kind == "revenant":
		ornament = "🕯️"
	elif life_kind == "witch":
		ornament = "🌙"
	elif life_kind == "super":
		ornament = "⚡"
	elif life_kind == "royal":
		ornament = "👑"
	elif life_kind == "pirate":
		ornament = "⚓"
	elif life_kind == "colonist":
		ornament = "🪐"
	elif life_kind == "traveler":
		ornament = "⌛"
	elif fame >= 70.0:
		ornament = "⭐"
	elif worth >= 5000000:
		ornament = "💠"
	elif not record.is_empty():
		ornament = "⛓️"
	elif kids >= 3:
		ornament = "🌳"
	elif karma >= 50:
		ornament = "🕊️"
	elif age >= 95:
		ornament = "🕰️"
	else:
		ornament = "🌿"

	epitaph = _epitaph(p, age, karma, worth, kids, fame, life_kind, record)
	# a path with an ending writes its own last line
	var end: Dictionary = entry.get("ending", {})
	if not end.is_empty() and str(end.get("epitaph", "")) != "" and age > 12:
		epitaph = str(end["epitaph"])


func _epitaph(p: Dictionary, age: int, karma: int, worth: int, kids: int, fame: float, life_kind: String, record: Array) -> String:
	if age <= 12:
		return "Taken far too early."
	if life_kind == "vampire":
		return "Outlived everyone who could have said a word over this."
	if life_kind == "revenant":
		return "Finished, at last, what was left unfinished."
	if life_kind == "royal":
		return "Wore it, for a while."
	if life_kind == "pirate":
		return "The sea has the rest."
	if life_kind == "colonist":
		return "Buried under a different sky."
	if life_kind == "traveler":
		return "Born later than this stone admits."
	if fame >= 80.0:
		return "Known by more people than ever met them."
	if karma <= -50:
		return "Few came. Fewer stayed."
	if karma >= 55 and kids >= 2:
		return "Loved, and left rather a lot of people behind."
	if karma >= 55:
		return "Kinder than the world required."
	if worth >= 5000000:
		return "Owned a great deal. Took none of it."
	if not record.is_empty():
		return "Paid for it, one way and another."
	if kids >= 3:
		return "Survived by more than they expected."
	if age >= 95:
		return "Saw the whole century out."
	if age >= 70:
		return "A long and ordinary life, which is no small thing."
	return "Here lies somebody who was here."


# ---------------------------------------------------------------- drawing

func _silhouette() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var left := 36.0
	var right := W - 36.0
	var top := 70.0
	var bottom := H - 54.0
	match shape:
		"obelisk":
			pts.append(Vector2(W * 0.5, 24.0))
			pts.append(Vector2(right - 44.0, top + 40.0))
			pts.append(Vector2(right - 44.0, bottom))
			pts.append(Vector2(left + 44.0, bottom))
			pts.append(Vector2(left + 44.0, top + 40.0))
		"mausoleum":
			pts.append(Vector2(left - 14.0, top + 16.0))
			pts.append(Vector2(W * 0.5, 22.0))
			pts.append(Vector2(right + 14.0, top + 16.0))
			pts.append(Vector2(right + 14.0, bottom))
			pts.append(Vector2(left - 14.0, bottom))
		"gothic":
			pts.append(Vector2(W * 0.5, 26.0))
			for i in range(9):
				var a := lerpf(0.0, 1.0, float(i) / 8.0)
				pts.append(Vector2(lerpf(W * 0.5, right, a), lerpf(60.0, top + 46.0, a * a)))
			pts.append(Vector2(right, bottom))
			pts.append(Vector2(left, bottom))
			for i in range(9):
				var b := lerpf(1.0, 0.0, float(i) / 8.0)
				pts.append(Vector2(lerpf(W * 0.5, left, b), lerpf(60.0, top + 46.0, b * b)))
		"celtic":
			pts.append(Vector2(left, top + 30.0))
			pts.append(Vector2(right, top + 30.0))
			pts.append(Vector2(right, bottom))
			pts.append(Vector2(left, bottom))
		"small":
			left += 58.0
			right -= 58.0
			top += 130.0
			for i in range(13):
				var t := PI - PI * float(i) / 12.0
				pts.append(Vector2(W * 0.5 + cos(t) * (right - left) * 0.5, top - sin(t) * 46.0))
			pts.append(Vector2(right, bottom))
			pts.append(Vector2(left, bottom))
		"broken":
			pts.append(Vector2(left, top + 54.0))
			pts.append(Vector2(W * 0.42, top + 8.0))
			pts.append(Vector2(W * 0.55, top + 96.0))
			pts.append(Vector2(right, top + 40.0))
			pts.append(Vector2(right, bottom))
			pts.append(Vector2(left, bottom))
		_:
			for i in range(17):
				var t2 := PI - PI * float(i) / 16.0
				pts.append(Vector2(W * 0.5 + cos(t2) * (right - left) * 0.5, top - sin(t2) * 66.0))
			pts.append(Vector2(right, bottom))
			pts.append(Vector2(left, bottom))
	return pts


func _draw() -> void:
	var pts := _silhouette()

	# ground shadow, so the stone sits in something
	draw_colored_polygon(PackedVector2Array([
		Vector2(20.0, H - 58.0), Vector2(W - 20.0, H - 58.0),
		Vector2(W - 44.0, H - 34.0), Vector2(44.0, H - 34.0)]), Color(0, 0, 0, 0.22))

	draw_colored_polygon(pts, stone_col)

	# a darker edge down the right, so it reads as stone rather than a sticker
	var edge := stone_col.darkened(0.22)
	var out := PackedVector2Array(pts)
	out.append(pts[0])
	draw_polyline(out, edge, 3.0, true)

	# weathering: age puts marks on it
	if weather > 0.05:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(entry.get("age", 1)) * 977 + int(entry.get("born", 0))
		var marks := int(weather * 26.0)
		for i in range(marks):
			var x := rng.randf_range(44.0, W - 44.0)
			var y := rng.randf_range(110.0, H - 80.0)
			var l := rng.randf_range(6.0, 26.0) * weather
			draw_line(Vector2(x, y), Vector2(x + rng.randf_range(-6.0, 6.0), y + l), edge.darkened(0.15), 1.0)

	# moss along the base for a life people still visit
	if moss > 0.05:
		var mrng := RandomNumberGenerator.new()
		mrng.seed = int(entry.get("born", 7)) * 31 + 5
		for i in range(int(moss * 34.0)):
			var mx := mrng.randf_range(44.0, W - 44.0)
			var my := H - 62.0 - mrng.randf_range(0.0, 34.0 * moss)
			draw_circle(Vector2(mx, my), mrng.randf_range(2.0, 6.0), Color(0.35, 0.48, 0.28, 0.5))

	# the celtic ring, drawn rather than faked with a glyph
	if shape == "celtic":
		draw_arc(Vector2(W * 0.5, 92.0), 46.0, 0.0, TAU, 40, stone_col, 12.0)
		draw_arc(Vector2(W * 0.5, 92.0), 46.0, 0.0, TAU, 40, edge, 2.0)
		draw_rect(Rect2(W * 0.5 - 13.0, 30.0, 26.0, 120.0), stone_col)
		draw_rect(Rect2(W * 0.5 - 62.0, 78.0, 124.0, 26.0), stone_col)


func text_ink() -> Color:
	return ink
