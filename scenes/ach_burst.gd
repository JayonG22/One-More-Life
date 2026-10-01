class_name AchBurst
extends Control

## Light rays behind a big achievement: they fan out, turn slowly and fade.

var col := Color.WHITE
var life := 0.0
var span := 2.2
var rays := 14


func setup(c: Color, seconds: float, ray_count: int = 14) -> void:
	col = c
	span = seconds
	rays = ray_count
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	life += delta
	if life >= span:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := life / span
	var a := sin(clampf(k, 0.0, 1.0) * PI) * 0.5
	var c := size / 2.0
	var r := maxf(size.x, size.y)
	for i in range(rays):
		var ang := TAU * float(i) / float(rays) + life * 0.35
		var w := TAU / float(rays) * 0.32
		var pts := PackedVector2Array([c, c + Vector2(cos(ang - w), sin(ang - w)) * r, c + Vector2(cos(ang + w), sin(ang + w)) * r])
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, a * (0.16 if i % 2 == 0 else 0.08)))
	draw_circle(c, 140.0 * (0.6 + k), Color(col.r, col.g, col.b, a * 0.25))
