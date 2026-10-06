extends Control

## Prices from simulated years only. Old saves begin with one observation.
var points: Array = []


func setup(history: Array, height: float = 72.0) -> void:
	points = history
	custom_minimum_size = Vector2(0, height)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	var readings: Array = []
	for p in points: readings.append("%d: %s" % [int(p["year"]), Finance.fmt_price(float(p["price"]))])
	tooltip_text = "Recorded yearly prices\n" + "\n".join(readings)
	queue_redraw()


func _draw() -> void:
	if points.is_empty(): return
	var first := float(points[0]["price"])
	var last := float(points[-1]["price"])
	var low := first
	var high := first
	for p in points:
		low = minf(low, float(p["price"]))
		high = maxf(high, float(p["price"]))
	var color := ThemeManager.bar_color("health", 85.0 if last >= first else 15.0)
	var area := Rect2(10, 6, maxf(1, size.x - 20), maxf(1, size.y - 30))
	draw_line(Vector2(area.position.x, area.end.y), area.end, Color(0.5, 0.5, 0.5, 0.25))
	var line := PackedVector2Array()
	for i in points.size():
		var x := area.position.x + area.size.x * float(i) / float(maxi(1, points.size() - 1))
		var y := area.end.y - area.size.y * ((float(points[i]["price"]) - low) / (high - low) if high > low else 0.5)
		line.append(Vector2(x, y))
	if line.size() > 1: draw_polyline(line, color, 2.0, true)
	draw_circle(line[-1], 3.0, color)
	var caption := "History begins this year" if points.size() == 1 else "%d–%d · yearly · low %s / high %s" % [int(points[0]["year"]), int(points[-1]["year"]), Finance.fmt_price(low), Finance.fmt_price(high)]
	draw_string(ThemeManager.font_bold, Vector2(10, size.y - 5), caption, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 12, color)
