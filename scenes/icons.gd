class_name Icons
extends Control

## ICONS — drawn, not typed.
##
## Everything in the game was an emoji, and emoji are a fixed vocabulary somebody
## else designed. A studio condo, a suburban house, a beach house and a private
## island were 🏢 🏡 🏖️ 🏝️: four unrelated pictures at four different visual
## weights, none of which told you they were rungs on the same ladder.
##
## These are vector, so they scale, they take the theme's colours, and a mansion
## looks like a mansion standing next to the bungalow it is bigger than. They are
## also original, which matters: the game cannot use a licensed icon library.
##
## Usage:  Icons.make("house_large", 44)  ->  a Control you can put in any row.

const KINDS := [
	# dwellings, deliberately a ladder
	"tent", "trailer", "flat_small", "flat_block", "terrace", "bungalow",
	"house", "house_large", "villa", "mansion", "estate", "tower", "island",
	# vehicles, also a ladder
	"bike", "hatchback", "sedan", "sports", "limo", "boat", "yacht", "jet",
	# places and pursuits
	"gym", "library", "hospital", "court", "prison", "school", "office",
	"factory", "farm", "church", "casino", "theatre", "stadium", "zoo",
	# objects
	"ring", "crown", "diamond", "briefcase", "coins", "trophy", "mask",
	"book", "flask", "cards", "gavel", "star", "heart", "skull",
	# everyday life (v0.15 and v0.16)
	"key", "compass", "envelope", "bus", "train", "phone", "pill", "tooth",
	"eye", "ear", "handshake", "anchor", "hourglass", "scroll", "dome", "hat",
	"signpost", "road", "calendar", "pulse",
]

var kind := "house"
var tint := Color("#8d9199")
var ink := Color("#2b2e33")
var accent := Color("#e0b24a")
var px := 40.0


## The one call anything else needs.
static func make(which: String, size_px: float = 40.0, col: Color = Color(0, 0, 0, 0)) -> Icons:
	var i := Icons.new()
	i.kind = which
	i.px = size_px
	i.custom_minimum_size = Vector2(size_px, size_px)
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	i.tint = col if col.a > 0.0 else ThemeManager.c("dim")
	i.ink = ThemeManager.c("text")
	i.accent = ThemeManager.c("gold")
	return i


## A row-friendly wrapper so icons drop into the existing U.row() calls, which
## expect a string. Anything not drawn falls back to its emoji.
static func has(which: String) -> bool:
	return KINDS.has(which)


func _ready() -> void:
	custom_minimum_size = Vector2(px, px)
	queue_redraw()


# ---------------------------------------------------------------- helpers

func _s(v: float) -> float:
	return v * px / 40.0


func _p(x: float, y: float) -> Vector2:
	return Vector2(_s(x), _s(y))


func _poly(pts: Array, col: Color) -> void:
	var a := PackedVector2Array()
	for t in pts:
		a.append(_p(float(t[0]), float(t[1])))
	draw_colored_polygon(a, col)


func _line(x1: float, y1: float, x2: float, y2: float, col: Color, w: float = 1.4) -> void:
	draw_line(_p(x1, y1), _p(x2, y2), col, _s(w), true)


func _rect(x: float, y: float, w: float, h: float, col: Color) -> void:
	draw_rect(Rect2(_p(x, y), Vector2(_s(w), _s(h))), col)


func _circle(x: float, y: float, r: float, col: Color) -> void:
	draw_circle(_p(x, y), _s(r), col)


## Windows in a grid, which is most of what makes a building read as a building.
func _windows(x: float, y: float, cols: int, rows: int, step: float, sz: float, col: Color) -> void:
	for c in range(cols):
		for r in range(rows):
			_rect(x + float(c) * step, y + float(r) * step, sz, sz, col)


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var body := tint
	var dark := tint.darkened(0.3)
	var light := tint.lightened(0.22)
	var glass := ink.lightened(0.15) if tint.get_luminance() > 0.45 else Color(1, 1, 1, 0.55)
	var ground := Color(ink, 0.18)

	match kind:
		# ---------------- dwellings, smallest to largest
		"tent":
			_poly([[20, 8], [34, 33], [6, 33]], body)
			_poly([[20, 8], [24, 33], [16, 33]], dark)
		"trailer":
			_rect(6, 16, 26, 13, body)
			_rect(8, 19, 7, 5, glass)
			_circle(13, 31, 3, dark)
			_circle(27, 31, 3, dark)
			_poly([[32, 16], [36, 22], [32, 22]], dark)
		"flat_small":
			_rect(12, 12, 16, 21, body)
			_windows(15, 15, 2, 3, 6, 3, glass)
			_rect(19, 27, 4, 6, dark)
		"flat_block":
			_rect(7, 8, 26, 25, body)
			_windows(10, 11, 4, 4, 6, 3, glass)
			_rect(18, 27, 5, 6, dark)
			_rect(7, 6, 26, 2, light)
		"terrace":
			for i in range(3):
				var x := 4.0 + float(i) * 11.0
				_rect(x, 14, 10, 19, body if i != 1 else light)
				_poly([[x, 14], [x + 5, 9], [x + 10, 14]], dark)
				_rect(x + 3.5, 25, 3, 8, dark)
		"bungalow":
			_poly([[4, 20], [20, 10], [36, 20]], dark)
			_rect(7, 20, 26, 13, body)
			_rect(11, 23, 5, 5, glass)
			_rect(24, 23, 5, 5, glass)
			_rect(18, 25, 4, 8, dark)
		"house":
			_poly([[4, 19], [20, 7], [36, 19]], dark)
			_rect(7, 19, 26, 14, body)
			_rect(10, 22, 5, 5, glass)
			_rect(25, 22, 5, 5, glass)
			_rect(18, 24, 4, 9, dark)
			_rect(27, 10, 3, 6, dark)   # chimney
		"house_large":
			_poly([[2, 18], [20, 5], [38, 18]], dark)
			_rect(5, 18, 30, 15, body)
			_windows(8, 21, 2, 2, 6, 4, glass)
			_windows(25, 21, 2, 2, 6, 4, glass)
			_rect(18, 24, 4, 9, dark)
			_rect(29, 8, 3, 7, dark)
			_rect(5, 32, 30, 1.5, light)
		"villa":
			_rect(4, 16, 32, 17, body)
			_rect(4, 14, 32, 2, light)
			for i in range(5):
				_rect(6.0 + float(i) * 6.5, 18, 2, 13, light)
			_rect(17, 24, 5, 9, dark)
			_poly([[2, 16], [20, 8], [38, 16]], dark)
		"mansion":
			# Two wings, a taller centre, columns and a pediment: the thing that
			# makes a mansion read as a mansion is symmetry plus a middle.
			_rect(2, 20, 11, 13, body)
			_rect(27, 20, 11, 13, body)
			_rect(12, 13, 16, 20, light)
			_poly([[10, 13], [20, 5], [30, 13]], dark)
			for i in range(4):
				_rect(14.0 + float(i) * 3.6, 18, 1.8, 15, body.darkened(0.08))
			_rect(18, 26, 4, 7, dark)
			_windows(4, 23, 2, 2, 5, 3, glass)
			_windows(29, 23, 2, 2, 5, 3, glass)
			_rect(2, 33, 36, 1.5, ground)
		"estate":
			_rect(1, 22, 9, 11, body)
			_rect(30, 22, 9, 11, body)
			_rect(10, 16, 20, 17, light)
			_poly([[8, 16], [20, 7], [32, 16]], dark)
			_circle(20, 12, 2.2, accent)
			for i in range(5):
				_rect(12.0 + float(i) * 3.4, 20, 1.6, 13, body.darkened(0.08))
			_rect(18, 27, 4, 6, dark)
			# the drive
			_poly([[16, 33], [24, 33], [28, 38], [12, 38]], ground)
		"tower":
			_rect(13, 3, 14, 30, body)
			_windows(15, 6, 3, 8, 3.6, 2, glass)
			_rect(13, 1, 14, 2, light)
			_rect(11, 30, 18, 3, dark)
			_line(20, 1, 20, -3, accent, 1.2)
		"island":
			_poly([[3, 30], [12, 24], [28, 24], [37, 30], [30, 34], [10, 34]], body)
			_line(20, 24, 20, 14, dark.darkened(0.2), 2.0)
			for a in [-1.0, -0.45, 0.45, 1.0]:
				draw_line(_p(20, 14), _p(20.0 + a * 9.0, 10.0 + absf(a) * 3.0), accent.darkened(0.35), _s(1.6), true)
			_rect(0, 34, 40, 6, Color(ink, 0.12))

		# ---------------- vehicles
		"bike":
			_circle(11, 27, 6, Color(0, 0, 0, 0))
			draw_arc(_p(11, 27), _s(6), 0, TAU, 28, dark, _s(1.6))
			draw_arc(_p(29, 27), _s(6), 0, TAU, 28, dark, _s(1.6))
			_line(11, 27, 20, 18, body, 1.6)
			_line(20, 18, 29, 27, body, 1.6)
			_line(20, 18, 24, 14, body, 1.4)
		"hatchback":
			_poly([[6, 27], [10, 18], [26, 18], [31, 27]], body)
			_rect(6, 25, 25, 4, dark)
			_poly([[12, 24], [13, 19], [24, 19], [25, 24]], glass)
			_circle(12, 30, 3.2, dark)
			_circle(26, 30, 3.2, dark)
		"sedan":
			_poly([[4, 27], [9, 17], [29, 17], [35, 27]], body)
			_rect(4, 25, 31, 4, dark)
			_poly([[11, 24], [12, 18], [27, 18], [28, 24]], glass)
			_circle(11, 30, 3.4, dark)
			_circle(28, 30, 3.4, dark)
			_rect(33, 23, 3, 2, accent)
		"sports":
			_poly([[3, 28], [8, 21], [16, 18], [28, 18], [37, 26], [37, 28]], body)
			_poly([[13, 21], [17, 19], [25, 19], [27, 22]], glass)
			_circle(11, 30, 3.6, dark)
			_circle(29, 30, 3.6, dark)
			_line(3, 28, 37, 28, accent, 1.0)
		"limo":
			_poly([[2, 27], [5, 19], [34, 19], [38, 27]], body)
			_rect(2, 25, 36, 4, dark)
			for i in range(4):
				_rect(7.0 + float(i) * 7.0, 20.5, 5, 4, glass)
			_circle(9, 30, 3.2, dark)
			_circle(31, 30, 3.2, dark)
		"boat":
			_poly([[5, 26], [35, 26], [30, 32], [10, 32]], body)
			_line(20, 26, 20, 10, dark, 1.6)
			_poly([[20, 11], [31, 24], [20, 24]], light)
			_rect(0, 32, 40, 5, Color(ink, 0.12))
		"yacht":
			_poly([[3, 24], [37, 24], [32, 31], [8, 31]], light)
			_rect(12, 18, 16, 6, body)
			_rect(14, 19.5, 4, 3, glass)
			_rect(21, 19.5, 4, 3, glass)
			_line(20, 18, 20, 8, dark, 1.2)
			_rect(0, 31, 40, 5, Color(ink, 0.12))
		"jet":
			_poly([[4, 22], [30, 19], [37, 22], [30, 25], [4, 24]], light)
			_poly([[14, 22], [22, 12], [26, 12], [20, 22]], body)
			_poly([[14, 24], [22, 32], [26, 32], [20, 24]], body)
			_poly([[4, 22], [9, 16], [11, 16], [8, 22]], dark)

		# ---------------- places
		"gym":
			_rect(4, 18, 4, 10, dark)
			_rect(32, 18, 4, 10, dark)
			_rect(8, 21, 24, 4, body)
			_circle(6, 23, 4, body)
			_circle(34, 23, 4, body)
		"library":
			for i in range(4):
				var bx := 6.0 + float(i) * 7.5
				_rect(bx, 12.0 + float(i % 2) * 2.0, 6, 21.0 - float(i % 2) * 2.0, body if i % 2 == 0 else light)
			_rect(4, 33, 32, 2, dark)
		"hospital":
			_rect(8, 10, 24, 23, light)
			_rect(18, 15, 4, 14, body)
			_rect(13, 20, 14, 4, body)
			_rect(8, 33, 24, 2, dark)
		"court":
			_poly([[3, 15], [20, 6], [37, 15]], dark)
			for i in range(5):
				_rect(5.0 + float(i) * 7.2, 16, 2.6, 15, body)
			_rect(3, 31, 34, 3, light)
		"prison":
			_rect(6, 12, 28, 21, body)
			for i in range(6):
				_rect(8.0 + float(i) * 4.6, 14, 1.8, 17, dark)
			_rect(6, 10, 28, 2, dark)
		"school":
			_poly([[4, 16], [20, 8], [36, 16]], dark)
			_rect(7, 16, 26, 17, body)
			_circle(20, 21, 3.4, light)
			_line(20, 21, 20, 18.5, dark, 1.0)
			_rect(17, 27, 6, 6, dark)
		"office":
			_rect(6, 6, 12, 27, body)
			_rect(20, 13, 14, 20, light)
			_windows(8, 9, 2, 6, 4, 2.4, glass)
			_windows(22, 16, 3, 4, 4, 2.4, glass)
		"factory":
			_rect(4, 20, 30, 13, body)
			for i in range(3):
				_poly([[6.0 + float(i) * 9.0, 20], [10.0 + float(i) * 9.0, 14], [14.0 + float(i) * 9.0, 20]], dark)
			_rect(30, 8, 4, 12, dark)
		"farm":
			_poly([[6, 18], [20, 9], [34, 18]], dark)
			_rect(9, 18, 22, 15, body)
			_poly([[16, 21], [20, 18], [24, 21], [24, 33], [16, 33]], light)
			_line(4, 33, 36, 33, dark, 1.2)
		"church":
			_poly([[8, 20], [20, 8], [32, 20]], dark)
			_rect(11, 20, 18, 13, body)
			_line(20, 8, 20, 2, accent, 1.6)
			_line(17, 4, 23, 4, accent, 1.6)
			_poly([[18, 26], [20, 23], [22, 26], [22, 33], [18, 33]], dark)
		"casino":
			_rect(8, 14, 24, 19, body)
			_circle(20, 11, 3.5, accent)
			_poly([[16, 22], [20, 18], [24, 22], [20, 26]], accent)
			_rect(17, 28, 6, 5, dark)
		"theatre":
			_poly([[4, 14], [20, 7], [36, 14]], dark)
			_rect(7, 14, 26, 19, body)
			draw_arc(_p(20, 24), _s(7), PI, TAU, 24, light, _s(2.0))
			_rect(13, 24, 14, 9, light)
		"stadium":
			draw_arc(_p(20, 22), _s(15), PI * 0.05, PI * 0.95, 32, body, _s(4.0))
			_circle(20, 24, 8, light)
			_line(20, 16, 20, 32, dark, 1.0)
		"zoo":
			_rect(5, 12, 30, 21, body)
			for i in range(7):
				_rect(6.5 + float(i) * 4.2, 14, 1.6, 17, dark)
			_circle(20, 22, 4, accent)

		# ---------------- objects
		"ring":
			draw_arc(_p(20, 25), _s(8), 0, TAU, 36, accent, _s(2.6))
			_poly([[20, 9], [25, 15], [20, 19], [15, 15]], light)
		"crown":
			_poly([[6, 28], [10, 14], [15, 22], [20, 11], [25, 22], [30, 14], [34, 28]], accent)
			_rect(6, 28, 28, 4, accent.darkened(0.25))
			_circle(20, 17, 1.8, light)
		"diamond":
			_poly([[10, 17], [30, 17], [20, 32]], light)
			_poly([[10, 17], [14, 11], [26, 11], [30, 17]], accent)
		"briefcase":
			_rect(6, 16, 28, 16, body)
			_rect(6, 21, 28, 2, dark)
			_rect(16, 12, 8, 4, dark)
			_rect(18, 20, 4, 4, accent)
		"coins":
			for i in range(3):
				_circle(14.0 + float(i) * 6.0, 26.0 - float(i) * 4.0, 6, accent.darkened(float(i) * 0.08))
		"trophy":
			_poly([[12, 8], [28, 8], [25, 22], [15, 22]], accent)
			_rect(18, 22, 4, 6, accent.darkened(0.2))
			_rect(13, 28, 14, 4, dark)
			draw_arc(_p(12, 13), _s(4), PI * 0.5, PI * 1.5, 16, accent, _s(1.6))
			draw_arc(_p(28, 13), _s(4), -PI * 0.5, PI * 0.5, 16, accent, _s(1.6))
		"mask":
			_poly([[8, 14], [32, 14], [30, 26], [20, 32], [10, 26]], body)
			_circle(15, 20, 2.2, dark)
			_circle(25, 20, 2.2, dark)
		"book":
			_poly([[8, 12], [20, 15], [20, 32], [8, 29]], body)
			_poly([[32, 12], [20, 15], [20, 32], [32, 29]], light)
			_line(20, 15, 20, 32, dark, 1.0)
		"flask":
			_poly([[16, 10], [24, 10], [24, 18], [31, 31], [9, 31]], glass)
			_poly([[13, 24], [27, 24], [31, 31], [9, 31]], accent)
			_rect(15, 8, 10, 2.5, dark)
		"cards":
			_poly([[9, 14], [20, 11], [24, 28], [13, 31]], light)
			_poly([[18, 12], [29, 14], [27, 31], [16, 29]], body)
		"gavel":
			_rect(8, 26, 24, 3, dark)
			draw_set_transform(_p(22, 16), -0.6, Vector2.ONE)
			draw_rect(Rect2(Vector2(-_s(7), -_s(4)), Vector2(_s(14), _s(8))), body)
			draw_rect(Rect2(Vector2(_s(6), -_s(1.4)), Vector2(_s(12), _s(2.8))), dark)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"star":
			var pts: Array = []
			for i in range(10):
				var ang := -PI / 2.0 + float(i) * PI / 5.0
				var rr := 15.0 if i % 2 == 0 else 6.5
				pts.append([20.0 + cos(ang) * rr, 21.0 + sin(ang) * rr])
			_poly(pts, accent)
		"heart":
			_circle(14, 17, 7, body)
			_circle(26, 17, 7, body)
			_poly([[7, 20], [33, 20], [20, 34]], body)
		"skull":
			_circle(20, 18, 11, light)
			_circle(15, 17, 3, dark)
			_circle(25, 17, 3, dark)
			_rect(14, 27, 12, 6, light)
			for i in range(3):
				_rect(15.0 + float(i) * 4.0, 27, 2, 6, dark)
		# ---------------- everyday life
		"key":
			draw_arc(_p(14, 17), _s(7), 0, TAU, 28, accent, _s(3.2))
			_line(20, 21, 33, 34, accent, 3.2)
			_line(27, 28, 31, 24, accent, 3.0)
			_line(31, 32, 35, 28, accent, 3.0)
		"compass":
			draw_arc(_p(20, 20), _s(14), 0, TAU, 36, body, _s(3.0))
			_poly([[20, 8], [24, 20], [16, 20]], accent)
			_poly([[20, 32], [24, 20], [16, 20]], light)
			_circle(20, 20, 2, dark)
		"envelope":
			_rect(6, 11, 28, 20, body)
			_poly([[6, 11], [34, 11], [20, 23]], light)
			_line(6, 31, 17, 21, dark, 1.0)
			_line(34, 31, 23, 21, dark, 1.0)
		"bus":
			_rect(6, 10, 28, 20, body)
			_rect(8, 13, 7, 7, glass)
			_rect(17, 13, 7, 7, glass)
			_rect(26, 13, 6, 7, glass)
			_rect(6, 24, 28, 2, accent)
			_circle(13, 31, 3, dark)
			_circle(27, 31, 3, dark)
		"train":
			_poly([[9, 8], [31, 8], [34, 28], [6, 28]], body)
			_rect(11, 12, 18, 8, glass)
			_circle(14, 24, 1.6, accent)
			_circle(26, 24, 1.6, accent)
			_line(10, 33, 6, 37, dark, 1.6)
			_line(30, 33, 34, 37, dark, 1.6)
			_line(8, 31, 32, 31, dark, 1.2)
		"phone":
			_rect(12, 5, 16, 30, body)
			_rect(14, 9, 12, 19, glass)
			_circle(20, 31, 1.6, dark)
		"pill":
			draw_set_transform(_p(20, 20), -0.7, Vector2.ONE)
			draw_rect(Rect2(Vector2(-_s(12), -_s(5.5)), Vector2(_s(12), _s(11))), accent)
			draw_rect(Rect2(Vector2(0, -_s(5.5)), Vector2(_s(12), _s(11))), light)
			draw_circle(Vector2(-_s(12), 0), _s(5.5), accent)
			draw_circle(Vector2(_s(12), 0), _s(5.5), light)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"tooth":
			_circle(15, 15, 6, light)
			_circle(25, 15, 6, light)
			_rect(9, 15, 22, 8, light)
			_poly([[10, 22], [20, 22], [18, 35], [14, 35]], light)
			_poly([[20, 22], [30, 22], [26, 35], [22, 35]], light)
			draw_arc(_p(20, 14), _s(5), 0.3, PI - 0.3, 10, dark, _s(1.2))
		"eye":
			_poly([[4, 20], [12, 12], [20, 10], [28, 12], [36, 20], [28, 28], [20, 30], [12, 28]], light)
			_circle(20, 20, 7, body)
			_circle(20, 20, 3.4, dark)
			_circle(22, 18, 1.2, light)
		"ear":
			_poly([[6, 15], [13, 15], [21, 8], [21, 32], [13, 25], [6, 25]], body)
			draw_arc(_p(22, 20), _s(6), -PI * 0.35, PI * 0.35, 10, accent, _s(2.4))
			draw_arc(_p(22, 20), _s(11), -PI * 0.35, PI * 0.35, 12, accent, _s(2.4))
			draw_arc(_p(22, 20), _s(16), -PI * 0.3, PI * 0.3, 14, accent, _s(2.4))
		"handshake":
			_rect(3, 13, 7, 14, dark)
			_rect(30, 13, 7, 14, dark)
			_poly([[10, 15], [22, 14], [28, 19], [22, 26], [10, 26]], body)
			_poly([[30, 15], [19, 16], [14, 21], [20, 28], [30, 26]], light)
			for i in range(3):
				_line(20.0 + float(i) * 2.6, 22.0 + float(i) * 1.6, 23.0 + float(i) * 2.6, 19.0 + float(i) * 1.6, dark, 0.9)
		"anchor":
			_circle(20, 9, 3.2, accent)
			_line(20, 12, 20, 32, accent, 3.0)
			_line(12, 17, 28, 17, accent, 3.0)
			draw_arc(_p(20, 25), _s(11), 0.15, PI - 0.15, 20, accent, _s(3.0))
			_poly([[7, 27], [12, 22], [14, 28]], accent)
			_poly([[33, 27], [28, 22], [26, 28]], accent)
		"hourglass":
			_rect(9, 6, 22, 3, dark)
			_rect(9, 31, 22, 3, dark)
			_poly([[11, 9], [29, 9], [20, 20]], glass)
			_poly([[20, 20], [29, 31], [11, 31]], glass)
			_poly([[14, 12], [26, 12], [20, 19]], accent)
			_poly([[20, 24], [27, 31], [13, 31]], accent)
		"scroll":
			_rect(9, 9, 22, 22, light)
			draw_arc(_p(9, 12), _s(3), PI * 0.5, PI * 1.5, 10, body, _s(2.6))
			draw_arc(_p(31, 28), _s(3), -PI * 0.5, PI * 0.5, 10, body, _s(2.6))
			for i in range(4):
				_line(13, 14.0 + float(i) * 4.4, 27, 14.0 + float(i) * 4.4, dark, 1.0)
		"dome":
			draw_arc(_p(20, 28), _s(15), PI, TAU, 28, body, _s(4.0))
			_poly([[5, 28], [35, 28], [35, 33], [5, 33]], dark)
			_rect(17, 22, 6, 6, glass)
			_circle(20, 14, 1.6, accent)
		"hat":
			_poly([[20, 4], [27, 22], [13, 22]], body)
			_rect(5, 22, 30, 4, dark)
			_rect(14, 17, 12, 3, accent)
		"signpost":
			_rect(19, 6, 3, 30, dark)
			_poly([[8, 9], [28, 9], [33, 14], [28, 19], [8, 19]], body)
			_poly([[12, 23], [32, 23], [32, 31], [12, 31], [7, 27]], light)
		"road":
			_poly([[14, 6], [26, 6], [36, 36], [4, 36]], dark)
			for i in range(4):
				_rect(19, 8.0 + float(i) * 7.5, 2, 4.2, accent)
		"calendar":
			_rect(7, 9, 26, 24, light)
			_rect(7, 9, 26, 7, body)
			_rect(12, 6, 3, 6, dark)
			_rect(25, 6, 3, 6, dark)
			for r in range(2):
				for c in range(4):
					_rect(10.0 + float(c) * 5.8, 19.0 + float(r) * 6.4, 3.8, 4, dark if (r + c) % 3 else accent)
		"pulse":
			_line(4, 22, 12, 22, body, 2.4)
			_line(12, 22, 16, 10, accent, 2.4)
			_line(16, 10, 22, 32, accent, 2.4)
			_line(22, 32, 26, 22, accent, 2.4)
			_line(26, 22, 36, 22, body, 2.4)
		_:
			# Unknown kind: a plain plate rather than nothing, so a typo is visible.
			_rect(8, 8, 24, 24, body)
			_line(8, 8, 32, 32, dark, 1.2)


# ---------------------------------------------------------------- mapping

## Which drawn icon a property, car or housing tier should use. Picked by value,
## so the ladder reads as a ladder.
static func for_property(type_name: String, value: int) -> String:
	var t := type_name.to_lower()
	if t.find("island") >= 0:
		return "island"
	if t.find("apartment building") >= 0 or t.find("block") >= 0:
		return "flat_block"
	if t.find("loft") >= 0 or t.find("condo") >= 0 or t.find("studio") >= 0:
		return "tower" if value >= 900000 else "flat_small"
	if t.find("duplex") >= 0 or t.find("terrace") >= 0:
		return "terrace"
	if t.find("beach") >= 0:
		return "villa"
	if value >= 8000000:
		return "estate"
	if value >= 2500000:
		return "mansion"
	if value >= 700000:
		return "house_large"
	return "house"


static func for_housing(key: String, house_value: int) -> String:
	match key:
		"parents":
			return "house"
		"dorm":
			return "flat_small"
		"apartment":
			return "flat_block"
		"homeless":
			return "tent"
		"house":
			if house_value >= 8000000:
				return "estate"
			if house_value >= 2500000:
				return "mansion"
			if house_value >= 700000:
				return "house_large"
			return "house"
	return "house"


static func for_car(key: String) -> String:
	match key:
		"used":
			return "hatchback"
		"new":
			return "sedan"
		"sports":
			return "sports"
	return "sedan"
