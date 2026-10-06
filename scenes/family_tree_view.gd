class_name FamilyTreeView
extends Control

## THE FAMILY TREE, drawn as one: generations in rows, branches that join them,
## partners joined by a heart, and the gone shown in sepia with a small cross.
## Everything is read from the NPC records, so the tree is this family and no other.

const NW := 156.0
const NH := 132.0
const GAP := 26.0
const ROW := 190.0
const PAD := 40.0

var rows: Array = []          # [{"title", "ids": [..]}]
var pos: Dictionary = {}      # id -> Vector2 (top-left)
var kinds: Dictionary = {}    # id -> "me" | "blood" | "partner" | "in"
var links: Array = []         # [[from_id, to_id, "line"|"heart"]]
var title_text := ""
var width_total := 900.0


func setup() -> void:
	var p := GameState.player
	title_text = "The %s Family" % str(p.get("last", ""))
	rows = [
		{"title": "Parents", "ids": GameState.npcs_with("mother", false) + GameState.npcs_with("father", false) + GameState.npcs_with("stepparent", false)},
		{"title": "You, your siblings and your partner", "ids": ["__me"] + GameState.npcs_with("partner", false) + GameState.npcs_with("sibling", false) + GameState.npcs_with("stepsibling", false)},
		{"title": "Children", "ids": GameState.npcs_with("child", false) + GameState.npcs_with("stepchild", false)},
	]
	rows = rows.filter(func(r): return not (r["ids"] as Array).is_empty())
	_layout()


func _layout() -> void:
	for c in get_children():
		c.queue_free()
	pos.clear()
	kinds.clear()
	links.clear()
	var widest := 0.0
	for r in rows:
		widest = maxf(widest, float((r["ids"] as Array).size()) * (NW + GAP) - GAP)
	width_total = maxf(widest + PAD * 2.0, 900.0)
	var y := 96.0
	for ri in range(rows.size()):
		var ids: Array = rows[ri]["ids"]
		var rw := float(ids.size()) * (NW + GAP) - GAP
		var x := (width_total - rw) / 2.0
		for id in ids:
			pos[id] = Vector2(x, y)
			x += NW + GAP
			_make_node(id)
		y += ROW
	custom_minimum_size = Vector2(width_total, y + 20.0)
	size = custom_minimum_size
	_make_links()
	queue_redraw()


func _make_links() -> void:
	# parents join the row above them to the row below by one trunk each
	var by_rel := func(rel: String) -> Array:
		return GameState.npcs_with(rel, false)
	var parents: Array = by_rel.call("mother") + by_rel.call("father")
	var gps: Array = by_rel.call("grandparent")
	for g in gps:
		for pr in parents:
			links.append([g, pr, "line"])
	if parents.is_empty() and pos.has("__me"):
		pass
	for pr2 in parents:
		links.append([pr2, "__me", "line"])
	for sib in by_rel.call("sibling"):
		for pr3 in parents:
			links.append([pr3, sib, "line"])
	for par in by_rel.call("partner"):
		links.append(["__me", par, "heart"])
	var kids: Array = by_rel.call("child") + by_rel.call("stepchild")
	for k in kids:
		links.append(["__me", k, "line"])
	for gc in by_rel.call("grandchild"):
		for k2 in kids:
			links.append([k2, gc, "line"])
			break


func _make_node(id: String) -> void:
	var p := GameState.player
	var alive := true
	var face := ""
	var name1 := ""
	var rel := ""
	var age := 0
	var kind := "blood"
	if id == "__me":
		alive = bool(p.get("alive", true))
		face = UIKit.face(str(p["gender"]), int(p["age"]), int(p.get("face", 0))) if alive else "😇"
		name1 = "%s %s" % [p["first"], p["last"]]
		rel = "You"
		age = int(p["age"])
		kind = "me"
	else:
		var n := GameState.npc(id)
		alive = bool(n.get("alive", true))
		face = UIKit.npc_face(n)
		name1 = GameState.full_name(id)
		rel = GameState.relation_label(id)
		age = int(n.get("age", 0))
		if str(n.get("relation", "")) in ["partner", "lover"]:
			kind = "partner"
		elif str(n.get("relation", "")) in ["stepparent", "stepsibling", "stepchild"]:
			kind = "in"
	kinds[id] = kind
	var card := PanelContainer.new()
	card.position = pos[id]
	card.custom_minimum_size = Vector2(NW, NH)
	card.size = Vector2(NW, NH)
	var sb := StyleBoxFlat.new()
	var border := {"me": Color("#f2c14e"), "blood": Color("#8a6a3d"), "partner": Color("#e0607e"), "in": Color("#6f8f6a")}[kind] as Color
	sb.bg_color = Color("#2a2118") if alive else Color("#1c1a17")
	sb.border_color = border if alive else border.darkened(0.45)
	sb.set_border_width_all(3 if kind == "me" else 2)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	card.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 1)
	card.add_child(v)
	var subject: Dictionary=p if id=="__me" else GameState.npc(id)
	if subject.get("species","human")=="human":
		var portrait := AvatarView.new(); portrait.custom_minimum_size=Vector2(54,54); portrait.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
		portrait.setup(Avatar.for_player() if id=="__me" else Avatar.appearance(subject),age,str(subject.get("gender","nonbinary")),false,subject)
		v.add_child(portrait)
	else:
		var portrait := UIKit.lbl(face,"Emoji",40); portrait.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; v.add_child(portrait)

	var nm := UIKit.lbl(name1, "Bold", 14)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nm)
	var sub := UIKit.lbl(rel + ("  ✝" if not alive else ""), "Dim", 12)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var ag := UIKit.lbl(("Age %d" if alive else "Died at %d") % age, "Dim", 12)
	ag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ag)
	card.tooltip_text = "%s\n%s\n%s" % [name1, rel, ("Age %d" % age) if alive else ("Died at %d" % age)]
	add_child(card)


func _draw() -> void:
	# parchment ground
	draw_rect(Rect2(Vector2.ZERO, size), Color("#17120d"))
	for i in range(0, int(size.y), 4):
		var a := 0.04 + 0.03 * sin(float(i) * 0.05)
		draw_line(Vector2(0, i), Vector2(size.x, i), Color(0.55, 0.42, 0.25, a), 1.0)
	# the trunk and roots: a soft tree shape behind the lowest row
	var cx := size.x / 2.0
	draw_circle(Vector2(cx, 48.0), 0.0, Color(0, 0, 0, 0))
	# the title ribbon
	var font: Font = ThemeManager.font_bold
	var tw: float = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	var rb := Rect2(cx - tw / 2.0 - 40.0, 18.0, tw + 80.0, 48.0)
	draw_rect(rb, Color("#6e3b25"))
	draw_rect(rb.grow(-4.0), Color("#8d4a2e"), false, 2.0)
	draw_string(font, Vector2(cx - tw / 2.0, 52.0), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#f6e7c8"))
	# generation labels
	for ri in range(rows.size()):
		var first_id: String = (rows[ri]["ids"] as Array)[0]
		var yy: float = (pos[first_id] as Vector2).y - 14.0
		draw_string(ThemeManager.font_bold, Vector2(14.0, yy), str(rows[ri]["title"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#9c8560"))
	# the branches
	for l in links:
		if not pos.has(l[0]) or not pos.has(l[1]):
			continue
		var a: Vector2 = pos[l[0]]
		var b: Vector2 = pos[l[1]]
		var alive_b := true
		if str(l[1]) != "__me":
			alive_b = bool(GameState.npc(str(l[1])).get("alive", true))
		var col := Color("#8a6a3d") if alive_b else Color("#5a4a34")
		if str(l[2]) == "heart":
			var ma := a + Vector2(NW, NH / 2.0)
			var mb := b + Vector2(0, NH / 2.0)
			if b.x < a.x:
				ma = a + Vector2(0, NH / 2.0)
				mb = b + Vector2(NW, NH / 2.0)
			draw_line(ma, mb, Color("#e0607e"), 3.0, true)
			draw_string(ThemeManager.font_bold, (ma + mb) / 2.0 + Vector2(-9, 8), "♥", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#e0607e"))
			continue
		var p0 := a + Vector2(NW / 2.0, NH)
		var p1 := b + Vector2(NW / 2.0, 0.0)
		var mid := (p0.y + p1.y) / 2.0
		var pts := PackedVector2Array([p0, Vector2(p0.x, mid), Vector2(p1.x, mid), p1])
		draw_polyline(pts, col, 3.0, true)
		draw_circle(Vector2(p1.x, mid), 4.0, Color("#5c8a4a") if alive_b else Color("#6b6254"))
