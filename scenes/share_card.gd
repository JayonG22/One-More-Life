extends RefCounted

## The shareable card for a finished life: one image that says who it was, how it
## ended, and the lines worth remembering. Drawn from the same entry as the
## tombstone, in the current theme, at a fixed size so it looks the same everywhere.

const W := 1080
const H := 620


static func accent_for(entry: Dictionary) -> Color:
	var m: Dictionary = entry.get("mode", {})
	match str(m.get("role", "")):
		"prisoner": return Color("#ff5a5f")
		"guard": return Color("#ff9f43")
	if entry.has("pet"):
		return Color("#4a90ff")
	return Color("#34c759")


## The few lines worth keeping: skip the birth line and the death line.
static func highlights(entry: Dictionary, limit: int = 3) -> Array:
	var lines: Array = str(entry.get("story", "")).split("\n", false)
	var mid: Array = []
	var dull := ["reached chapter", "year inside", "year on the staff", "years on the staff", "years inside", "turned ", "became a", "became an", "learned to sit", "took on a calling"]
	var rest: Array = []
	for i in range(1, maxi(1, lines.size() - 1)):
		var ln := str(lines[i])
		var boring := false
		for d in dull:
			if ln.find(d) != -1:
				boring = true
		if boring:
			rest.append(ln)
		else:
			mid.append(ln)
	if mid.size() < limit:
		mid.append_array(rest)
	if mid.size() <= limit:
		return mid
	# prefer the ones with a verb that costs something, otherwise spread them out
	var pick: Array = []
	var step := float(mid.size()) / float(limit)
	for k in range(limit):
		pick.append(mid[int(float(k) * step)])
	return pick


static func share_text(entry: Dictionary) -> String:
	var r: Dictionary = entry.get("ribbon", {})
	var e: Dictionary = entry.get("ending", {})
	var out: Array = []
	out.append("ONE MORE LIFE — %s" % str(entry.get("name", "")))
	out.append("%s %s%s" % [str(r.get("icon", "")), str(r.get("name", "")), (" · " + str(e.get("title", ""))) if not e.is_empty() else ""])
	out.append("Age %d, %d–%d. %s" % [int(entry.get("age", 0)), int(entry.get("born", 0)), int(entry.get("died", 0)), str(entry.get("cause", ""))])
	if not e.is_empty():
		out.append("“%s”" % str(e.get("epitaph", "")))
	var sd: Dictionary = entry.get("seeded", {})
	if not sd.is_empty():
		out.append("%s %s %s — %s (score %d)" % ["Daily" if sd["kind"] == "daily" else "Weekly", str(sd["key"]), str(sd["goal"]), "goal met" if sd["met"] else "goal missed", int(sd["score"])])
	for h in highlights(entry):
		out.append("• " + str(h))
	return "\n".join(out)


static func build(entry: Dictionary) -> Control:
	var acc := accent_for(entry)
	var bg := ColorRect.new()
	bg.color = Color("#0b1020")
	bg.custom_minimum_size = Vector2(W, H)
	bg.size = Vector2(W, H)
	var strip := ColorRect.new()
	strip.color = acc
	strip.position = Vector2(0, 0)
	strip.size = Vector2(W, 10)
	bg.add_child(strip)
	var m: Dictionary = entry.get("mode", {})
	var icon := str(m.get("icon", "")) if not m.is_empty() else "🧑"
	var r: Dictionary = entry.get("ribbon", {})
	var e: Dictionary = entry.get("ending", {})
	var is_case: bool = m.has("role")
	_text(bg, "ONE MORE LIFE", Vector2(48, 30), 22, acc.lightened(0.2), 400)
	_text(bg, icon, Vector2(48, 78), 96, Color.WHITE, 140, true)
	_text(bg, str(entry.get("name", "")), Vector2(200, 80), 54, Color.WHITE, W - 260)
	var years := "%d – %d  ·  age %d" % [int(entry.get("born", 0)), int(entry.get("died", 0)), int(entry.get("age", 0))]
	_text(bg, years, Vector2(200, 148), 26, Color("#9db0d0"), W - 260)
	_text(bg, "%s  %s" % [str(r.get("icon", "")), str(r.get("name", ""))], Vector2(48, 214), 40, Color("#f2c94c"), W - 96)
	if not e.is_empty():
		if str(e.get("title", "")) != str(r.get("name", "")):
			_text(bg, str(e.get("title", "")), Vector2(48, 266), 30, acc.lightened(0.3), W - 96)
		_text(bg, "“%s”" % str(e.get("epitaph", "")), Vector2(48, 310), 28, Color("#dfe7f5"), W - 96)
	var y := 380
	for h in highlights(entry):
		_text(bg, "•  " + str(h), Vector2(48, y), 22, Color("#b8c6e0"), W - 96)
		y += 56
	var foot := ("Case closed: " if is_case else "Died of ") + str(entry.get("cause", ""))
	_text(bg, foot.left(90), Vector2(48, H - 52), 20, Color("#7f90b3"), W - 96)
	return bg


static func _text(parent: Control, t: String, pos: Vector2, size_px: int, col: Color, width: float, emoji: bool = false) -> void:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.size = Vector2(width, size_px * 2.4)
	l.custom_minimum_size = Vector2(width, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	if not emoji and ThemeManager.font_bold != null:
		l.add_theme_font_override("font", ThemeManager.font_bold)
	l.max_lines_visible = 2 if size_px >= 26 else 1
	l.clip_text = true
	parent.add_child(l)
