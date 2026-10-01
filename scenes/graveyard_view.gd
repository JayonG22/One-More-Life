class_name GraveyardView
extends Control

## THE GRAVEYARD, as a place: a night sky and a moon, a fence, mist that drifts,
## and a stone for every life, each drawn from the life it marks (marble for the
## rich, a wooden cross for the poor, a small stone for the young). Fresh graves
## get flowers; old ones get moss. Click a stone to read the life.

signal opened(entry: Dictionary)

const SCALE := 0.46
const SW := 400.0 * SCALE
const SH := 620.0 * SCALE
const GAPX := 22.0
const ROWH := 330.0

var entries: Array = []
var mist_t := 0.0
var stars: Array = []
var cols := 5


func setup(list: Array, width: float) -> void:
	entries = list
	cols = maxi(2, int((width - 80.0) / (SW + GAPX)))
	for c in get_children():
		c.queue_free()
	var rows_n := int(ceil(float(entries.size()) / float(cols)))
	custom_minimum_size = Vector2(width, 200.0 + float(rows_n) * ROWH + 80.0)
	size = custom_minimum_size
	stars.clear()
	for i in range(70):
		stars.append(Vector3(randf() * width, randf() * 190.0, randf_range(0.6, 1.8)))
	for i in range(entries.size()):
		var e: Dictionary = entries[i]
		var r := i / cols
		var cidx := i % cols
		var in_row := mini(cols, entries.size() - r * cols)
		var row_w := float(in_row) * (SW + GAPX) - GAPX
		var x := (width - row_w) / 2.0 + float(cidx) * (SW + GAPX)
		var y := 220.0 + float(r) * ROWH
		_make_stone(e, Vector2(x, y), i)
	set_process(true)


func _make_stone(e: Dictionary, at: Vector2, idx: int) -> void:
	var ribbon: Dictionary = e.get("ribbon", {})
	var fake_p := {"legacy": e, "money": int(e.get("net_worth", e.get("net", 0))), "karma": int(e.get("karma", 0)), "fame": float(e.get("fame", 0.0)), "life": {"type": str(e.get("kind", "human"))}, "record": []}
	var holder := Control.new()
	holder.position = at
	holder.custom_minimum_size = Vector2(SW, SH + 30.0)
	holder.size = Vector2(SW, SH + 30.0)
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	var stone := Tombstone.new()
	stone.setup(e, ribbon, fake_p)
	stone.scale = Vector2(SCALE, SCALE)
	stone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(stone)
	# the inscription, set onto the stone
	var ink: Color = stone.text_ink()
	var yy := SH * 0.17
	for t in [[stone.ornament, 22, false], ["R.I.P.", 24, true], [str(e.get("name", "")), 14, true], ["%d – %d" % [int(e.get("born", 0)), int(e.get("died", 0))], 12, false], ["age %d" % int(e.get("age", 0)), 11, false], ["%s %s" % [str(ribbon.get("icon", "")), str(ribbon.get("name", ""))], 12, true]]:
		var tl := UIKit.lbl(str(t[0]), "Bold" if t[2] else "", int(t[1]))
		tl.add_theme_color_override("font_color", ink)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.position = Vector2(14.0, yy)
		tl.size = Vector2(SW - 28.0, 24)
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tl)
		yy += float(t[1]) + 8.0
	var nm := UIKit.lbl("", "Bold", 1)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.position = Vector2(0, SH + 4.0)
	nm.size = Vector2(SW, 24)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(nm)
	var tip := "%s\n%d – %d · age %d\n%s\n%s %s" % [str(e.get("name", "")), int(e.get("born", 0)), int(e.get("died", 0)), int(e.get("age", 0)), str(e.get("cause", "")), str(ribbon.get("icon", "")), str(ribbon.get("name", ""))]
	holder.tooltip_text = tip
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL
	btn.size = Vector2(SW, SH + 30.0)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.tooltip_text = tip
	btn.pressed.connect(func(): opened.emit(e))
	holder.add_child(btn)
	# a fresh grave has flowers
	if idx >= entries.size() - 2:
		var fl := UIKit.lbl("💐", "Emoji", 24)
		fl.position = Vector2(SW / 2.0 - 12.0, SH - 22.0)
		fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(fl)
	add_child(holder)


func _process(delta: float) -> void:
	mist_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# the sky
	var sky := PackedColorArray([Color("#070b1a"), Color("#070b1a"), Color("#1b2140"), Color("#1b2140")])
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, 260), Vector2(0, 260)]), sky)
	for s in stars:
		var tw := 0.5 + 0.5 * sin(mist_t * 1.5 + s.x)
		draw_circle(Vector2(s.x, s.y), s.z * (0.7 + 0.3 * tw), Color(1, 1, 0.9, 0.5 + 0.4 * tw))
	draw_circle(Vector2(w - 160, 90), 46, Color("#f1ead0"))
	draw_circle(Vector2(w - 144, 80), 40, Color("#070b1a") if false else Color("#e6dfc0"))
	draw_circle(Vector2(w - 160, 90), 90, Color(0.9, 0.9, 0.7, 0.05))
	# hills
	var hills := PackedVector2Array([Vector2(0, 250)])
	for i in range(0, int(w) + 40, 40):
		hills.append(Vector2(i, 230.0 + 24.0 * sin(float(i) * 0.012) + 12.0 * sin(float(i) * 0.031)))
	hills.append(Vector2(w, h))
	hills.append(Vector2(0, h))
	draw_colored_polygon(hills, Color("#0d1a12"))
	# the lawn, in bands
	for r in range(int((h - 240.0) / 40.0) + 1):
		draw_rect(Rect2(0, 250.0 + float(r) * 40.0, w, 40), Color(0.06, 0.13, 0.08, 1.0) if r % 2 == 0 else Color(0.07, 0.15, 0.09, 1.0))
	# the fence along the back
	for i in range(0, int(w), 26):
		draw_rect(Rect2(i, 214, 6, 40), Color("#1a1a22"))
		draw_colored_polygon(PackedVector2Array([Vector2(i, 214), Vector2(i + 3, 205), Vector2(i + 6, 214)]), Color("#1a1a22"))
	draw_rect(Rect2(0, 226, w, 4), Color("#1a1a22"))
	draw_rect(Rect2(0, 242, w, 4), Color("#1a1a22"))
	# mist, drifting
	for k in range(4):
		var mx := fposmod(mist_t * (6.0 + float(k) * 3.0) + float(k) * 300.0, w + 400.0) - 200.0
		var my := 300.0 + float(k) * 180.0 + 14.0 * sin(mist_t * 0.4 + float(k))
		draw_circle(Vector2(mx, my), 160.0, Color(0.75, 0.8, 0.9, 0.035))
		draw_circle(Vector2(mx + 120.0, my + 10.0), 120.0, Color(0.75, 0.8, 0.9, 0.03))
