class_name AvatarView
extends Control

## Draws the player's avatar. The shapes are plain polygons and ellipses, scaled to the
## size of the control, and the person ages: a child has a bigger head and a smaller
## body, an elder's hair goes grey and the face gets lines.

var av: Dictionary = {}
var age := 25
var gender := "male"
var s := 1.0


func setup(a: Dictionary, years: int, gen: String) -> void:
	av = a
	age = years
	gender = gen
	queue_redraw()


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(120, 144)


func _p(x: float, y: float) -> Vector2:
	return Vector2(x, y) * s


func _ell(c: Vector2, rx: float, ry: float, col: Color) -> void:
	draw_set_transform(c * s, 0.0, Vector2(rx, ry) * s)
	draw_circle(Vector2.ZERO, 1.0, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _poly(pts: Array, col: Color) -> void:
	var out := PackedVector2Array()
	for p in pts:
		out.append(_p(p[0], p[1]))
	if out.size() >= 3:
		draw_colored_polygon(out, col)


func _line(a: Vector2, b: Vector2, col: Color, w: float = 2.0) -> void:
	draw_line(a * s, b * s, col, w * s, true)


func _arc(c: Vector2, r: float, a0: float, a1: float, col: Color, w: float = 2.0) -> void:
	draw_arc(c * s, r * s, a0, a1, 18, col, w * s, true)


func _draw() -> void:
	if av.is_empty():
		return
	s = minf(size.x / 200.0, size.y / 240.0)
	var ox := (size.x - 200.0 * s) / 2.0
	draw_set_transform(Vector2(ox, 0), 0.0, Vector2.ONE)
	var kid := age < 13
	var baby := age < 3
	var elder := age >= 60
	var skin := Avatar.color_of("skin", int(av["skin"]))
	var hair := Avatar.color_of("hair_col", int(av["hair_col"]))
	if age > 45:
		var t := clampf(float(age - 45) / 35.0, 0.0, 1.0)
		hair = hair.lerp(Color("#cfcfd6"), t * (0.0 if int(av["hair_col"]) >= 8 else 1.0))
	var bg := Avatar.color_of("bg", int(av["bg"]))
	var top_c := Avatar.color_of("top_col", int(av["top_col"]))
	var hc := Vector2(100, 108 if kid else 98)
	var hr := Vector2(54, 60) if not kid else Vector2(60, 64)
	if baby:
		hr = Vector2(62, 64)
		hc = Vector2(100, 116)
	# backdrop
	var rect := PackedVector2Array([_p(4, 4), _p(196, 4), _p(196, 236), _p(4, 236)])
	draw_colored_polygon(rect, bg)
	draw_colored_polygon(PackedVector2Array([_p(4, 150), _p(196, 120), _p(196, 236), _p(4, 236)]), bg.darkened(0.18))
	# hair behind the head
	var hs := int(av["hair"])
	if hs == 5:
		_ell(Vector2(100, 84), 76, 72, hair)
	elif hs == 6 or hs == 12:
		_poly([[44, 70], [156, 70], [166, 190], [34, 190]], hair)
		if hs == 12:
			for i in range(5):
				_ell(Vector2(40 + i * 3, 150 + i * 8), 12, 10, hair)
				_ell(Vector2(160 - i * 3, 150 + i * 8), 12, 10, hair)
	elif hs == 11:
		_poly([[46, 70], [154, 70], [152, 138], [48, 138]], hair)
	elif hs == 7:
		_ell(Vector2(160, 118), 14, 30, hair)
	# body
	if not baby:
		var by := 188.0 if not kid else 200.0
		_ell(Vector2(100, 172), 14, 30, skin.darkened(0.08))
		_poly([[22, 240], [38, by], [84, by - 18], [116, by - 18], [162, by], [178, 240]], top_c)
		_clothes(top_c, skin, by)
	else:
		_poly([[50, 240], [62, 205], [138, 205], [150, 240]], top_c)
	# ears and head
	_ell(Vector2(hc.x - hr.x + 2, hc.y + 6), 9, 14, skin.darkened(0.06))
	_ell(Vector2(hc.x + hr.x - 2, hc.y + 6), 9, 14, skin.darkened(0.06))
	_ell(hc, hr.x, hr.y, skin)
	_ell(hc + Vector2(0, hr.y * 0.55), hr.x * 0.7, hr.y * 0.35, skin.darkened(0.04))
	# face
	_face(hc, hr, skin, kid, baby, elder)
	# facial hair
	_beard(hc, hr, hair)
	# front hair, then hats
	_front_hair(hs, hc, hr, hair, baby)
	_hat(int(av["hat"]), hc, hr, top_c)
	_glasses(int(av["glasses"]), hc)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _clothes(top_c: Color, skin: Color, by: float) -> void:
	var t := int(av["top"])
	var dark := top_c.darkened(0.25)
	match t:
		0:
			_arc(Vector2(100, by - 18), 16, 0.1, PI - 0.1, dark, 3)
		1:
			_arc(Vector2(100, by - 20), 30, 0.2, PI - 0.2, dark, 6)
			_line(Vector2(92, by - 6), Vector2(92, by + 26), Color("#eeeeee"), 2)
			_line(Vector2(108, by - 6), Vector2(108, by + 26), Color("#eeeeee"), 2)
		2:
			_poly([[84, by - 18], [100, by + 6], [116, by - 18], [108, by - 20], [100, by - 4], [92, by - 20]], Color("#f4f4f4"))
			for i in range(3):
				draw_circle(_p(100, by + 10 + i * 14), 2.0 * s, dark)
		3:
			_poly([[84, by - 18], [100, by + 40], [116, by - 18], [128, by - 14], [114, by + 40], [86, by + 40], [72, by - 14]], dark)
			_poly([[94, by - 12], [106, by - 12], [103, by + 38], [97, by + 38]], Color("#c0392b"))
		4:
			_poly([[78, by - 18], [100, by + 8], [122, by - 18], [116, by - 20], [100, by - 2], [84, by - 20]], skin)
		5:
			draw_circle(_p(130, by + 12), 6.0 * s, Color("#f2c14e"))
			_line(Vector2(60, by - 8), Vector2(76, by - 14), Color("#f2c14e"), 4)
			_line(Vector2(140, by - 8), Vector2(124, by - 14), Color("#f2c14e"), 4)


func _face(hc: Vector2, hr: Vector2, skin: Color, kid: bool, baby: bool, elder: bool) -> void:
	var ec := Avatar.color_of("eye_col", int(av["eye_col"]))
	var ey := hc.y - 4.0
	var ex := 22.0 if not kid else 24.0
	var etype := int(av["eyes"])
	var ew: float = [11.0, 12.0, 13.0, 11.0, 12.0, 11.0][etype]
	var eh: float = [10.0, 7.0, 13.0, 6.0, 5.0, 10.0][etype]
	if kid:
		eh += 2.0
	for sgn in [-1.0, 1.0]:
		var c := Vector2(hc.x + sgn * ex, ey)
		_ell(c, ew, eh, Color("#fdfdfd"))
		_ell(c + Vector2(sgn * -1.0, 1.0), ew * 0.52, eh * 0.78, ec)
		_ell(c + Vector2(sgn * -1.0, 1.0), ew * 0.24, eh * 0.4, Color("#101018"))
		if etype == 5:
			draw_circle(_p(c.x - 3, c.y - 3), 2.5 * s, Color(1, 1, 1, 0.95))
		if etype == 3:
			_poly([[c.x - ew, c.y - eh], [c.x + ew, c.y - eh], [c.x + ew, c.y - eh * 0.1], [c.x - ew, c.y - eh * 0.1]], skin)
			_line(Vector2(c.x - ew, c.y - eh * 0.1), Vector2(c.x + ew, c.y - eh * 0.1), skin.darkened(0.45), 2)
		# brows
		var bt := int(av["brows"])
		var by: float = ey - eh - [7.0, 6.0, 9.0, 6.0][bt]
		var bcol := Avatar.color_of("hair_col", int(av["hair_col"])).darkened(0.1)
		if age > 55 and int(av["hair_col"]) < 8:
			bcol = Color("#9a9aa2")
		var w: float = [2.5, 2.5, 3.0, 5.0][bt]
		match bt:
			0: _arc(Vector2(c.x, by + 6), 12, PI * 1.15, PI * 1.85, bcol, w)
			1: _line(Vector2(c.x - 11, by), Vector2(c.x + 11, by), bcol, w)
			2: _arc(Vector2(c.x, by + 10), 13, PI * 1.2, PI * 1.8, bcol, w)
			3: _line(Vector2(c.x - 11, by + 1), Vector2(c.x + 11, by - 1), bcol, w)
	# nose
	_arc(Vector2(hc.x, hc.y + 14), 6, 0.2, PI - 0.2, skin.darkened(0.25), 2)
	# mouth
	var my := hc.y + 34.0
	var mt := int(av["mouth"])
	var lip := Color("#a8455a") if gender == "female" else Color("#8f4a45")
	match mt:
		0: _arc(Vector2(hc.x, my - 6), 14, 0.35, PI - 0.35, lip, 3)
		1:
			_poly([[hc.x - 15, my - 4], [hc.x + 15, my - 4], [hc.x + 11, my + 8], [hc.x - 11, my + 8]], Color("#fdfdfd"))
			_arc(Vector2(hc.x, my - 6), 15, 0.2, PI - 0.2, lip, 3)
		2: _line(Vector2(hc.x - 11, my), Vector2(hc.x + 11, my), lip, 3)
		3:
			_line(Vector2(hc.x - 11, my + 2), Vector2(hc.x + 6, my + 1), lip, 3)
			_line(Vector2(hc.x + 6, my + 1), Vector2(hc.x + 13, my - 5), lip, 3)
		4: _ell(Vector2(hc.x, my + 2), 9, 8, Color("#3a1218"))
		5: _ell(Vector2(hc.x, my + 1), 8, 5, lip)
	# marks
	match int(av["mark"]):
		1:
			for p in [[-30, 18], [-24, 24], [-34, 26], [30, 18], [24, 24], [34, 26], [-20, 14], [20, 14]]:
				draw_circle(_p(hc.x + p[0], hc.y + p[1]), 1.6 * s, skin.darkened(0.3))
		2: draw_circle(_p(hc.x + 26, hc.y + 26), 2.2 * s, Color("#3a2418"))
		3:
			_line(Vector2(hc.x - 34, hc.y - 12), Vector2(hc.x - 16, hc.y + 24), Color("#c97a7a"), 2.5)
	if elder:
		for yy in [-30.0, -24.0]:
			_arc(Vector2(hc.x, hc.y + yy + 20), 36, PI * 1.2, PI * 1.8, skin.darkened(0.18), 1.6)
		_arc(Vector2(hc.x - 28, hc.y + 22), 10, -0.4, 1.2, skin.darkened(0.2), 1.6)
		_arc(Vector2(hc.x + 28, hc.y + 22), 10, PI - 1.2, PI + 0.4, skin.darkened(0.2), 1.6)
	if kid:
		_ell(Vector2(hc.x - 36, hc.y + 20), 9, 6, Color(0.95, 0.5, 0.5, 0.25))
		_ell(Vector2(hc.x + 36, hc.y + 20), 9, 6, Color(0.95, 0.5, 0.5, 0.25))


func _beard(hc: Vector2, hr: Vector2, hair: Color) -> void:
	var b := int(av["beard"])
	if b == 0 or age < 14:
		return
	var col := hair.darkened(0.05)
	match b:
		1:
			_poly([[hc.x - 40, hc.y + 18], [hc.x + 40, hc.y + 18], [hc.x + 34, hc.y + 54], [hc.x, hc.y + 62], [hc.x - 34, hc.y + 54]], Color(col.r, col.g, col.b, 0.28))
		2:
			_ell(Vector2(hc.x, hc.y + 52), 14, 12, col)
			_ell(Vector2(hc.x, hc.y + 40), 16, 4, col)
		3:
			_poly([[hc.x - 48, hc.y + 6], [hc.x - 40, hc.y + 40], [hc.x - 20, hc.y + 66], [hc.x, hc.y + 74], [hc.x + 20, hc.y + 66], [hc.x + 40, hc.y + 40], [hc.x + 48, hc.y + 6], [hc.x + 34, hc.y + 36], [hc.x, hc.y + 44], [hc.x - 34, hc.y + 36]], col)
		4:
			_ell(Vector2(hc.x - 9, hc.y + 26), 12, 5, col)
			_ell(Vector2(hc.x + 9, hc.y + 26), 12, 5, col)


func _cap(hc: Vector2, hr: Vector2, hair: Color, line_y: float, extra: float = 4.0) -> void:
	var pts: Array = []
	for i in range(0, 19):
		var a := PI + PI * float(i) / 18.0
		pts.append([hc.x + cos(a) * (hr.x + extra), hc.y + sin(a) * (hr.y + extra)])
	pts.append([hc.x + hr.x - 2, hc.y - line_y + 14])
	pts.append([hc.x + hr.x * 0.4, hc.y - line_y])
	pts.append([hc.x - hr.x * 0.4, hc.y - line_y])
	pts.append([hc.x - hr.x + 2, hc.y - line_y + 14])
	_poly(pts, hair)


func _front_hair(hs: int, hc: Vector2, hr: Vector2, hair: Color, baby: bool) -> void:
	if baby:
		_arc(Vector2(hc.x, hc.y - hr.y + 6), 14, PI * 1.1, PI * 1.9, hair, 4)
		return
	match hs:
		1: _cap(hc, hr, hair, hr.y - 10.0, 1.0)
		2: _cap(hc, hr, hair, hr.y - 18.0, 3.0)
		3:
			_cap(hc, hr, hair, hr.y - 20.0, 4.0)
			_poly([[hc.x - 30, hc.y - hr.y + 4], [hc.x + 48, hc.y - hr.y + 4], [hc.x + 40, hc.y - hr.y + 34], [hc.x - 8, hc.y - hr.y + 20]], hair)
		4:
			for i in range(9):
				var a := PI + PI * float(i) / 8.0
				_ell(Vector2(hc.x + cos(a) * (hr.x + 2), hc.y + sin(a) * (hr.y + 2)), 15, 15, hair)
			_cap(hc, hr, hair, hr.y - 22.0, 0.0)
		5:
			_cap(hc, hr, hair, hr.y - 24.0, 2.0)
		6, 12:
			_cap(hc, hr, hair, hr.y - 20.0, 5.0)
		7: _cap(hc, hr, hair, hr.y - 20.0, 4.0)
		8:
			_cap(hc, hr, hair, hr.y - 20.0, 4.0)
			_ell(Vector2(hc.x, hc.y - hr.y - 12), 18, 16, hair)
		9:
			_cap(hc, hr, hair, hr.y - 20.0, 4.0)
			for i in range(5):
				_ell(Vector2(hc.x - hr.x - 6, hc.y + 2 + i * 14), 7, 8, hair)
				_ell(Vector2(hc.x + hr.x + 6, hc.y + 2 + i * 14), 7, 8, hair)
		10:
			_poly([[hc.x - 12, hc.y - hr.y + 10], [hc.x - 6, hc.y - hr.y - 30], [hc.x, hc.y - hr.y - 12], [hc.x + 6, hc.y - hr.y - 34], [hc.x + 12, hc.y - hr.y + 10]], hair)
		11:
			_cap(hc, hr, hair, hr.y - 22.0, 5.0)
			_poly([[hc.x - hr.x, hc.y - 20], [hc.x + hr.x, hc.y - 20], [hc.x + hr.x - 10, hc.y - 6], [hc.x - hr.x + 10, hc.y - 6]], hair)
		13:
			_cap(hc, hr, hair, hr.y - 18.0, 3.0)
			for i in range(7):
				var a2 := PI + PI * float(i + 1) / 8.0
				var bx := hc.x + cos(a2) * hr.x
				var by := hc.y + sin(a2) * hr.y
				_poly([[bx - 7, by + 6], [bx + cos(a2) * 14, by + sin(a2) * 20], [bx + 7, by + 6]], hair)


func _hat(h: int, hc: Vector2, hr: Vector2, top_c: Color) -> void:
	var top := hc.y - hr.y
	match h:
		1:
			_poly([[hc.x - hr.x - 2, top + 22], [hc.x - hr.x + 6, top - 4], [hc.x + hr.x - 6, top - 4], [hc.x + hr.x + 2, top + 22]], Color("#d94f4f"))
			_poly([[hc.x - 4, top + 20], [hc.x + hr.x + 30, top + 20], [hc.x + hr.x + 26, top + 28], [hc.x - 4, top + 28]], Color("#a63a3a"))
		2:
			_poly([[hc.x - hr.x - 2, top + 26], [hc.x - hr.x + 4, top - 6], [hc.x + hr.x - 4, top - 6], [hc.x + hr.x + 2, top + 26]], Color("#4f7fd9"))
			_poly([[hc.x - hr.x - 3, top + 18], [hc.x + hr.x + 3, top + 18], [hc.x + hr.x + 3, top + 30], [hc.x - hr.x - 3, top + 30]], Color("#3a64b0"))
			draw_circle(_p(hc.x, top - 8), 8.0 * s, Color("#e6e6e6"))
		3:
			_poly([[hc.x - 40, top + 14], [hc.x - 46, top - 28], [hc.x - 22, top - 6], [hc.x, top - 36], [hc.x + 22, top - 6], [hc.x + 46, top - 28], [hc.x + 40, top + 14]], Color("#f2c14e"))
			draw_circle(_p(hc.x, top - 8), 4.0 * s, Color("#d94f4f"))
			draw_circle(_p(hc.x - 24, top), 3.0 * s, Color("#4f7fd9"))
			draw_circle(_p(hc.x + 24, top), 3.0 * s, Color("#58b368"))
		4:
			_ell(Vector2(hc.x, top + 20), 82, 12, Color("#8a5a2f"))
			_poly([[hc.x - 36, top + 18], [hc.x - 30, top - 22], [hc.x + 30, top - 22], [hc.x + 36, top + 18]], Color("#a06a38"))
		5:
			_poly([[hc.x - hr.x - 1, top + 28], [hc.x + hr.x + 1, top + 28], [hc.x + hr.x + 1, top + 40], [hc.x - hr.x - 1, top + 40]], Color("#e8863a"))


func _glasses(g: int, hc: Vector2) -> void:
	var ey := hc.y - 4.0
	match g:
		1:
			for sgn in [-1.0, 1.0]:
				_arc(Vector2(hc.x + sgn * 22, ey), 15, 0, TAU, Color("#2c313a"), 3)
			_line(Vector2(hc.x - 8, ey), Vector2(hc.x + 8, ey), Color("#2c313a"), 3)
		2:
			for sgn in [-1.0, 1.0]:
				var cx: float = hc.x + sgn * 22
				_line(Vector2(cx - 15, ey - 11), Vector2(cx + 15, ey - 11), Color("#2c313a"), 3)
				_line(Vector2(cx + 15, ey - 11), Vector2(cx + 15, ey + 11), Color("#2c313a"), 3)
				_line(Vector2(cx + 15, ey + 11), Vector2(cx - 15, ey + 11), Color("#2c313a"), 3)
				_line(Vector2(cx - 15, ey + 11), Vector2(cx - 15, ey - 11), Color("#2c313a"), 3)
			_line(Vector2(hc.x - 7, ey - 4), Vector2(hc.x + 7, ey - 4), Color("#2c313a"), 3)
		3:
			for sgn in [-1.0, 1.0]:
				_ell(Vector2(hc.x + sgn * 22, ey), 17, 12, Color("#14141c"))
			_line(Vector2(hc.x - 6, ey - 3), Vector2(hc.x + 6, ey - 3), Color("#14141c"), 4)
		4:
			_arc(Vector2(hc.x + 22, ey), 15, 0, TAU, Color("#c9a227"), 3)
			_line(Vector2(hc.x + 36, ey + 8), Vector2(hc.x + 44, ey + 70), Color("#c9a227"), 1.5)
