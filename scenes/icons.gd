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
	"electric", "wagon", "suv", "pickup", "bike", "hatchback", "sedan", "sports", "limo", "boat", "yacht", "jet",
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

const JOB_TOOLS := {"baker":["bread","oven"],"mortician":["flower","clipboard"],"exorcist":["lantern","book"],"marines":["anchor","shield"],"coast_guard":["ring","boat"],"adult_performer":["mask","clipboard"],"pt_cashier": ["coins", "receipt"], "pt_burger": ["plate", "burger"], "pt_lifeguard": ["lifebuoy", "wave"], "pt_babysitter": ["heart", "child"], "pt_dogwalker": ["paw", "lead"], "pt_tutor": ["book", "pencil"], "pt_barista": ["cup", "bean"], "pt_stocker": ["crate", "moon"], "pt_delivery": ["road", "parcel"], "retail": ["coins", "tag"], "fastfood": ["plate", "fries"], "warehouse": ["crate", "stack"], "trucker": ["road", "truck"], "janitor": ["brush", "bucket"], "security": ["shield", "eye"], "receptionist": ["phone", "bell"], "electrician": ["bolt", "plug"], "plumber": ["pipe", "drop"], "mechanic": ["wrench", "gear"], "carpenter": ["hammer", "wood"], "hairstylist": ["scissors", "comb"], "line_cook": ["plate", "pan"], "firefighter": ["shield", "flame"], "mail": ["envelope", "parcel"], "flight_attendant": ["jet", "cup"], "developer": ["code", "gear"], "game_dev": ["code", "pad"], "nurse": ["stethoscope", "cross"], "teacher": ["book", "chalk"], "police": ["shield", "star"], "accountant": ["ledger", "coins"], "marketing": ["megaphone", "tag"], "analyst": ["ledger", "graph"], "engineer": ["gear", "ruler"], "architect": ["ruler", "house"], "designer": ["brush", "palette"], "journalist": ["pen", "news"], "counselor": ["heart", "speech"], "lab_tech": ["microscope", "tube"], "chef": ["plate", "hat"], "music_teacher": ["book", "note"], "paralegal": ["gavel", "scroll"], "probation": ["handshake", "shield"], "civil_servant": ["scroll", "stamp"], "lawyer": ["gavel", "scales"], "doctor": ["stethoscope", "pulse"], "dentist": ["tooth", "mirror"], "pharmacist": ["pill", "cross"], "vet": ["stethoscope", "paw"], "executive": ["briefcase", "graph"], "professor": ["book", "cap"], "scientist": ["microscope", "flask"], "army": ["shield", "stripes"], "navy": ["anchor", "stripes"], "air_force": ["jet", "stripes"], "pilot": ["jet", "compass"], "data_analyst": ["code", "graph"], "cybersecurity": ["code", "shield"], "ux_research": ["eye", "speech"], "technical_writer": ["pen", "gear"], "game_producer": ["pad", "calendar"], "renewable_tech": ["bolt", "sun"], "urban_planner": ["house", "map"], "environment_officer": ["leaf", "drop"], "food_scientist": ["flask", "plate"], "community_worker": ["handshake", "house"], "care_assistant": ["heart", "cross"], "logistics_planner": ["crate", "map"], "event_coordinator": ["calendar", "star"], "archivist": ["scroll", "key"], "sound_engineer": ["headphones", "wave"], "compliance": ["ledger", "shield"], "museum_educator": ["book", "dome"], "tour_guide": ["compass", "flag"], "farm_manager": ["leaf", "tractor"], "biomedical_engineer": ["gear", "pulse"], "public_defender": ["gavel", "handshake"], "insurance_analyst": ["ledger", "umbrella"], "special_education": ["book", "heart"], "community_nurse": ["stethoscope", "house"], "family_role": ["briefcase", "tree"], "appliance_repair": ["wrench", "plug"], "bike_repair": ["wrench", "bike"], "dispatch_support": ["phone", "map"], "repair_support": ["code", "wrench"], "recycling_operator": ["leaf", "recycle"], "grounds_keeper": ["leaf", "brush"], "print_technician": ["brush", "printer"], "venue_service": ["calendar", "bell"]}

const STUDY_TOOLS := {"computer_science": ["code", "book"], "nursing": ["stethoscope", "book"], "business": ["briefcase", "book"], "criminal_justice": ["shield", "book"], "education": ["book", "pencil"], "engineering": ["gear", "book"], "biology": ["flask", "leaf"], "psychology": ["heart", "book"], "graphic_design": ["brush", "book"], "communications": ["megaphone", "book"], "economics": ["graph", "book"], "culinary": ["plate", "book"], "music": ["note", "book"], "political_science": ["dome", "book"], "english": ["pen", "book"], "architecture": ["ruler", "book"], "accounting": ["ledger", "book"], "game_dev": ["pad", "book"], "law": ["scales", "book"], "medicine": ["stethoscope", "cap"], "mba": ["briefcase", "cap"], "dentistry": ["tooth", "book"], "pharmacy": ["pill", "book"], "veterinary": ["paw", "book"], "phd": ["microscope", "cap"]}

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
	return (which.begins_with("car:") and GameState.CARS.has(which.substr(4))) or (which.begins_with("study:") and STUDY_TOOLS.has(which.substr(6))) or KINDS.has(which) or (which.begins_with("job:") and JOB_TOOLS.has(which.substr(4)))


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
	if kind.begins_with("car:"):
		_draw_model(kind.substr(4))
		return
	if kind.begins_with("study:"):
		_draw_tools(STUDY_TOOLS.get(kind.substr(6),["book","cap"]))
		return
	if kind.begins_with("job:"):
		_draw_job(kind.substr(4))
		return
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
		"electric", "wagon", "suv", "pickup":
			var top := 14.0 if kind in ["suv","pickup"] else 18.0
			_poly([[3,27],[8,top],[28,top],[37,25],[37,29],[3,29]],body)
			_rect(10,top+2,8,6,glass)
			if kind=="pickup":
				_rect(22,top,15,8,ThemeManager.c("surface"))
				_line(22,23,37,23,light,2)
			else: _rect(21,top+2,7,6,glass)
			_circle(10,30,3.5,dark)
			_circle(29,30,3.5,dark)
			if kind=="electric": _poly([[20,22],[17,27],[21,27],[19,32],[25,25],[21,25]],accent)
			if kind=="wagon": _line(7,16,29,16,accent,1.5)
			if kind=="suv": _line(4,28,36,28,accent,2)
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
			var model: Dictionary=Actions.HOME_MODELS.get(str(GameState.player.get("house_model","")),{})
			if not model.is_empty(): return str(model["icon"])
			if house_value >= 8000000:
				return "estate"
			if house_value >= 2500000:
				return "mansion"
			if house_value >= 700000:
				return "house_large"
			return "house"
	return "house"


static func for_car(key: String) -> String:
	if GameState.CARS.has(key): return "car:"+key
	match key:
		"used":
			return "hatchback"
		"new":
			return "sedan"
		"sports":
			return "sports"
	return "sedan"


static func for_job(id: String) -> String:
	return "job:"+id if JOB_TOOLS.has(id) else "briefcase"

func _draw_model(id: String) -> void:
	var original := kind
	kind=str(GameState.CARS[id].get("icon",{"used":"hatchback","new":"sedan","sports":"sports"}.get(id,"sedan")))
	_draw(); kind=original
	match id:
		"city": _line(14,13,23,13,accent,2)
		"hybrid": _line(8,24,29,24,accent,1.4); _circle(32,18,2,accent)
		"electric": _line(6,23,30,23,accent,1.4)
		"wagon": _line(11,8,28,8,accent,2)
		"suv": _rect(28,12,3,9,accent)
		"pickup": _line(5,19,16,19,accent,1.4)
		"roadster": _line(15,13,25,14,ink,3); _line(6,25,30,25,accent,1.4)
		"luxury": _line(10,23,31,23,accent,1.5)
		"used": _line(7,24,12,23,ink,1.3); _line(25,24,29,25,ink,1.3)
		"new": _line(8,24,29,24,ink,1.2)
		"sports": _line(29,15,35,15,accent,2); _line(32,15,32,22,accent,1.5)

func _draw_job(id: String) -> void:
	var tools: Array=JOB_TOOLS.get(id,["briefcase","star"])
	_draw_tools(tools)

func _draw_tools(tools: Array) -> void:
	_tool(str(tools[0]),tint)
	# A second occupational tool distinguishes related professions. Its own
	# silhouette is drawn at half scale, rather than a letter or color-only badge.
	draw_set_transform(_p(23,23),0,Vector2(0.46,0.46))
	_tool(str(tools[1]),accent)
	draw_set_transform(Vector2.ZERO)

func _tool(tool: String, col: Color) -> void:
	match tool:
		"bread":
			_poly([[5,14],[8,7],[17,4],[29,7],[35,15],[33,33],[7,33]],col)
			_line(12,12,16,19,ink,2); _line(20,10,24,18,ink,2); _line(27,13,30,20,ink,2)
		"oven":
			_rect(5,4,30,33,col); _rect(9,14,22,18,ink); _circle(12,9,2,ink); _circle(28,9,2,ink); _line(13,18,27,18,col,2)
		"flower":
			_line(20,17,20,36,col,3); _poly([[19,29],[8,23],[9,31],[19,34]],col)
			for center in [[13,11],[20,6],[27,11],[25,18],[15,18]]: _circle(center[0],center[1],5,col)
			_circle(20,13,4,ink)
		"lantern":
			_rect(10,12,20,22,col); _rect(14,16,12,14,ink); _line(12,8,28,8,col,3); draw_arc(_p(20,9),_s(7),PI,TAU,20,col,_s(2)); _poly([[18,27],[16,23],[20,17],[24,23],[22,27]],col)
		"clipboard":
			_rect(7,7,27,30,col); _rect(14,3,12,8,ink); _line(12,17,28,17,ink,2); _line(12,24,26,24,ink,2); _line(12,31,23,31,ink,2)
		"stethoscope":
			draw_arc(_p(19,15),_s(9),0,PI,20,col,_s(2.5))
			_line(10,8,10,15,col,2.5); _line(28,8,28,15,col,2.5)
			_line(19,24,19,30,col,2); _line(19,30,31,30,col,2); _circle(32,27,4,col)
		"code":
			_line(13,9,5,20,col,2.5); _line(5,20,13,31,col,2.5)
			_line(27,9,35,20,col,2.5); _line(35,20,27,31,col,2.5); _line(23,8,17,32,col,2)
		"wrench":
			_poly([[8,4],[6,13],[13,19],[29,35],[35,29],[19,13],[14,6],[13,12],[9,13]],col)
		"bolt": _poly([[23,3],[9,23],[18,23],[15,37],[32,16],[23,16]],col)
		"pipe":
			_line(7,9,22,9,col,6); _line(22,9,22,29,col,6); _line(22,29,34,29,col,6)
		"hammer":
			_poly([[7,6],[30,6],[33,13],[22,16],[20,35],[14,35],[15,15],[7,15]],col)
		"scissors":
			draw_arc(_p(10,29),_s(5),0,TAU,20,col,_s(2)); draw_arc(_p(23,29),_s(5),0,TAU,20,col,_s(2))
			_line(12,25,30,5,col,2.5); _line(21,25,8,5,col,2.5)
		"microscope":
			_line(16,7,24,16,col,6); _line(24,16,16,23,col,2); _line(13,25,28,25,col,3)
			draw_arc(_p(19,21),_s(12),-PI/2,PI/2,20,col,_s(3)); _rect(7,34,28,3,col)
		"ledger", "receipt", "news", "scroll", "calendar":
			_rect(8,5,23,30,col.darkened(0.25)); _line(11,12,27,12,col,2)
			for i in range(3): _line(11,18+i*5,23 if tool=="receipt" else 27,18+i*5,col,1.8)
			if tool=="calendar": _line(12,3,12,8,col,3); _line(26,3,26,8,col,3)
		"book":
			_poly([[4,8],[19,11],[19,33],[4,30]],col); _poly([[21,11],[36,8],[36,30],[21,33]],col)
		"plate", "lifebuoy", "gear", "coins":
			draw_arc(_p(19,20),_s(13),0,TAU,32,col,_s(3)); draw_arc(_p(19,20),_s(7),0,TAU,24,col,_s(1.5))
			if tool=="gear":
				for i in range(8):
					var a := i*PI/4; _line(19+cos(a)*12,20+sin(a)*12,19+cos(a)*17,20+sin(a)*17,col,3)
			if tool=="coins": _line(19,10,19,30,col,2)
		"cup":
			_poly([[7,13],[27,13],[25,31],[10,31]],col); draw_arc(_p(28,20),_s(5),-PI/2,PI/2,20,col,_s(2)); _line(14,5,14,10,col)
		"paw":
			_poly([[9,30],[11,21],[19,16],[27,21],[29,30],[19,34]],col)
			for x in [8,15,24,31]: _circle(x,10 if x in [15,24] else 15,3.5,col)
		"shield": _poly([[5,7],[19,3],[33,7],[31,23],[19,36],[7,23]],col)
		"leaf":
			_poly([[7,32],[8,16],[19,6],[34,4],[31,20],[18,31]],col); _line(6,35,29,10,ink,1.5)
		"drop": _poly([[20,3],[7,22],[8,29],[14,35],[25,35],[32,29],[33,22]],col)
		"headphones":
			draw_arc(_p(19,20),_s(13),PI,TAU,28,col,_s(3)); _rect(5,20,7,12,col); _rect(27,20,7,12,col)
		"brush":
			_poly([[8,5],[31,5],[29,16],[23,20],[23,35],[17,35],[17,20],[10,16]],col)
			_line(12,8,12,14,ink); _line(19,8,19,15,ink); _line(26,8,26,14,ink)
		"pen", "pencil", "chalk":
			_poly([[6,32],[10,23],[28,5],[34,11],[16,29]],col); _line(12,24,27,9,ink,1)
		"crate", "parcel", "stack":
			_rect(6,10,28,24,col); _line(6,10,20,4,col,2); _line(20,4,34,10,col,2); _line(20,10,20,34,ink,1)
		"graph":
			_rect(5,24,6,11,col); _rect(15,16,6,19,col); _rect(25,7,6,28,col)
		"ruler":
			_rect(6,11,28,15,col); _line(11,11,11,18,ink); _line(18,11,18,21,ink); _line(25,11,25,18,ink)
		"megaphone":
			_poly([[5,16],[13,16],[32,7],[32,32],[13,24],[5,24]],col); _rect(12,24,5,11,col)
		"cross": _rect(15,5,9,30,col); _rect(5,15,30,9,col)
		"note":
			_circle(12,29,5,col); _line(16,29,16,8,col,2); _line(16,8,29,5,col,3); _line(29,5,29,24,col,2); _circle(25,25,5,col)
		"wave", "pulse":
			_line(3,22,11,22,col,2); _line(11,22,16,10,col,2); _line(16,10,22,31,col,2); _line(22,31,28,18,col,2); _line(28,18,36,18,col,2)
		"pad":
			_poly([[8,12],[30,12],[36,30],[29,33],[23,25],[15,25],[9,33],[3,30]],col)
			_line(8,20,17,20,ink,2); _line(12,16,12,24,ink,2); _circle(28,18,2,ink); _circle(30,23,2,ink)
		"phone": _rect(11,4,18,32,col); _rect(14,8,12,21,ink.darkened(0.5)); _circle(20,32,1.5,ink)
		"scales": _line(20,5,20,34,col,2); _line(5,12,35,12,col,2); _poly([[4,25],[15,25],[10,14]],col); _poly([[25,25],[36,25],[30,14]],col)
		"plug": _rect(10,15,19,12,col); _line(14,5,14,15,col,3); _line(25,5,25,15,col,3); _line(20,27,20,36,col,3)
		"tag": _poly([[5,7],[24,7],[36,20],[24,33],[5,33]],col); _circle(28,20,2,ink)
		"map": _poly([[4,9],[14,5],[25,9],[36,5],[36,31],[25,35],[14,31],[4,35]],col); _line(14,5,14,31,ink); _line(25,9,25,35,ink)
		"flame": _poly([[9,30],[6,22],[16,5],[21,17],[27,9],[34,23],[29,34],[15,36]],col)
		"stripes": _poly([[5,12],[20,21],[35,12],[35,17],[20,26],[5,17]],col); _poly([[5,23],[20,32],[35,23],[35,28],[20,37],[5,28]],col)
		"tube": _line(16,5,16,27,col,7); _circle(16,28,3.5,col); _line(10,5,23,5,col,2)
		"bean": _poly([[12,7],[24,4],[31,14],[29,29],[17,35],[7,27],[6,16]],col); _line(15,9,23,29,ink,2)
		"comb":
			_rect(4,9,31,5,col)
			for x in range(5,35,5): _line(x,14,x,30,col,2)
		"speech": _poly([[4,6],[35,6],[35,27],[17,27],[8,35],[8,27],[4,27]],col)
		"umbrella": draw_arc(_p(20,21),_s(16),PI,TAU,28,col,_s(4)); _line(20,9,20,33,col,2); _line(20,33,26,33,col,2)
		"burger":
			draw_arc(_p(20,18),_s(13),PI,TAU,24,col,_s(6)); _rect(6,20,28,4,col); _rect(7,28,26,5,col)
		"fries":
			_poly([[7,20],[33,20],[29,35],[11,35]],col)
			for x in [11,17,23,29]: _rect(x,5 if x==17 else 9,3,14,col)
		"pan":
			draw_arc(_p(14,22),_s(10),0,TAU,28,col,_s(3)); _line(23,18,36,10,col,4)
		"child":
			_circle(20,10,6,col); _rect(15,19,10,12,col); _line(15,21,7,27,col,3); _line(25,21,33,27,col,3); _line(17,29,15,37,col,3); _line(23,29,25,37,col,3)
		"lead":
			draw_arc(_p(11,10),_s(6),0,TAU,20,col,_s(2)); _line(15,15,30,31,col,2); draw_arc(_p(29,30),_s(5),0,PI,20,col,_s(2))
		"moon":
			draw_arc(_p(20,20),_s(13),PI/3,PI*1.7,28,col,_s(5)); _circle(29,8,2,col)
		"truck":
			_rect(3,10,22,18,col); _poly([[25,16],[32,16],[37,23],[37,28],[25,28]],col); _circle(10,31,4,col); _circle(30,31,4,col)
		"bucket": _poly([[7,14],[33,14],[29,35],[11,35]],col); draw_arc(_p(20,14),_s(10),PI,TAU,24,col,_s(2))
		"wood": _rect(5,10,30,20,col); _line(9,15,31,15,ink); _line(9,23,31,23,ink); draw_arc(_p(22,20),_s(3),0,TAU,20,ink,_s(1))
		"bell": _poly([[7,27],[11,22],[12,11],[20,5],[28,11],[29,22],[33,27]],col); _circle(20,31,3,col)
		"palette": _poly([[6,12],[17,4],[31,8],[35,23],[28,34],[13,35],[5,26]],col); _circle(27,24,5,ink); _circle(12,16,2,ink); _circle(20,11,2,ink); _circle(12,26,2,ink)
		"cap": _poly([[3,13],[20,5],[37,13],[20,21]],col); _rect(12,22,16,6,col); _line(34,15,34,29,col,2)
		"stamp": _rect(7,28,27,7,col); _rect(16,14,9,15,col); _circle(20,10,7,col)
		"sun":
			_circle(20,20,7,col)
			for i in range(8):
				var a := i*PI/4; _line(20+cos(a)*11,20+sin(a)*11,20+cos(a)*16,20+sin(a)*16,col,2)
		"tractor": _circle(12,29,8,col); _circle(31,31,4,col); _rect(12,17,22,10,col); _rect(10,5,14,4,col); _line(21,9,21,17,col,3)
		"recycle": _poly([[17,5],[26,5],[32,16],[25,16]],col); _poly([[34,24],[29,34],[15,34],[19,27]],col); _poly([[6,29],[2,21],[10,9],[14,15]],col)
		"printer": _rect(5,15,30,15,col); _rect(11,4,18,13,col); _rect(11,27,18,10,col); _line(15,30,25,30,ink)
		"mirror": draw_arc(_p(18,13),_s(9),0,TAU,24,col,_s(2)); _line(18,22,18,37,col,4)
		"tree": _rect(18,23,5,13,col); _circle(20,14,11,col); _circle(11,22,7,col); _circle(29,22,7,col)
		"flag": _line(10,4,10,36,col,2); _poly([[12,6],[34,6],[29,14],[34,23],[12,23]],col)
		_:
			# Existing silhouettes provide the remainder of the occupational tools.
			var original := kind
			kind=tool if KINDS.has(tool) else "star"
			var original_tint := tint; tint=col
			_draw(); tint=original_tint; kind=original
