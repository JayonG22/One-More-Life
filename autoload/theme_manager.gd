extends Node

signal theme_changed

const ORDER := ["ink", "dark", "light", "celebrity", "vampire", "undead", "villain", "superhero", "royal", "witch"]
const LABELS := {
	"ink": "Fieldnotes",
	"dark": "Dark", "light": "Twilight", "celebrity": "Celebrity", "vampire": "Vampire",
	"undead": "Undead", "villain": "Villain", "superhero": "Superhero", "royal": "Royal", "witch": "Witch", "custody": "In Custody",
}

const PALETTES := {
	"custody": {
		"bg": "171c20", "surface": "252c32", "surface2": "303940", "border": "59656e",
		"text": "e8ecee", "dim": "a9b3ba", "accent": "cfad72", "accent_text": "171c20",
		"primary": "8496a3", "primary_text": "151b1d", "event_bg": "303940", "event_text": "e8ecee",
		"good": "89a998", "warn": "cfad72", "bad": "d38d84", "track": "39434c", "gold": "cfad72", "border_w": 2,
	},
	"ink": {
		"bg": "151b1d", "surface": "20282a", "surface2": "283236", "border": "405051",
		"text": "f2eee4", "dim": "b0b6b0", "accent": "e7b36b", "accent_text": "151b1d",
		"primary": "6eaaa1", "primary_text": "111c1b", "event_bg": "283236", "event_text": "f2eee4",
		"good": "82b59b", "warn": "e7b36b", "bad": "df897d", "track": "313b3d", "gold": "e7b36b", "border_w": 1,
	},
	"dark": {
		"bg": "0b1424", "surface": "13213a", "surface2": "1a2b48", "border": "263b5e",
		"text": "eef3fb", "dim": "8fa3c2", "accent": "2ec4b6", "accent_text": "ffffff",
		"primary": "1f6fe0", "primary_text": "ffffff", "event_bg": "1a2b48", "event_text": "eef3fb",
		"good": "34c759", "warn": "f5b82e", "bad": "ef4b4b", "track": "22324f", "gold": "f2c14e", "border_w": 1,
	},
	"light": {
		"bg": "141b25", "surface": "1c2531", "surface2": "263140", "border": "435062",
		"text": "e2e7ed", "dim": "a7b3c2", "accent": "83aaa5", "accent_text": "ffffff",
		"primary": "88a6c8", "primary_text": "ffffff", "event_bg": "1c2531", "event_text": "e2e7ed",
		"good": "2fb350", "warn": "e8a317", "bad": "e04545", "track": "303d4d", "gold": "c5b58c", "border_w": 1,
	},
	"celebrity": {
		"bg": "0c0907", "surface": "1a130d", "surface2": "241a11", "border": "c9a34e",
		"text": "f8eedb", "dim": "b89d72", "accent": "f2c14e", "accent_text": "1a1206",
		"primary": "ff4fa0", "primary_text": "ffffff", "event_bg": "241a11", "event_text": "f8eedb",
		"good": "f2c14e", "warn": "ff9f43", "bad": "ff4f6d", "track": "33271a", "gold": "f2c14e", "border_w": 1,
	},
	"vampire": {
		"bg": "10050a", "surface": "220a12", "surface2": "2d0e18", "border": "5c1a2a",
		"text": "f3dde2", "dim": "a97d88", "accent": "c0162e", "accent_text": "ffffff",
		"primary": "7a1024", "primary_text": "ffffff", "event_bg": "2d0e18", "event_text": "f3dde2",
		"good": "d8345a", "warn": "d9822b", "bad": "8a8f99", "track": "3a121e", "gold": "d4af6a", "border_w": 1,
	},
	"undead": {
		"bg": "151a12", "surface": "20271c", "surface2": "2a3224", "border": "4a563f",
		"text": "dfe7d0", "dim": "96a28a", "accent": "9fd13a", "accent_text": "152005",
		"primary": "5e7a33", "primary_text": "f2f8e6", "event_bg": "2a3224", "event_text": "dfe7d0",
		"good": "9fd13a", "warn": "d9c23a", "bad": "c9573a", "track": "323b2b", "gold": "c9c05a", "border_w": 2,
	},
	"villain": {
		"bg": "100e14", "surface": "1b1722", "surface2": "241e2d", "border": "4a3a5e",
		"text": "ece4f6", "dim": "9b8dac", "accent": "7bdc3f", "accent_text": "10200a",
		"primary": "8c43ff", "primary_text": "ffffff", "event_bg": "241e2d", "event_text": "ece4f6",
		"good": "7bdc3f", "warn": "e9b53b", "bad": "ff4f6d", "track": "2e2639", "gold": "c7a4ff", "border_w": 1,
	},
	"royal": {
		"bg": "0a1030", "surface": "131b45", "surface2": "1b2558", "border": "c9a34e",
		"text": "f5efe0", "dim": "b3a98a", "accent": "c9a34e", "accent_text": "1a1406",
		"primary": "7a2a4a", "primary_text": "ffffff", "event_bg": "1b2558", "event_text": "f5efe0",
		"good": "d8b85a", "warn": "e0903a", "bad": "d24a5a", "track": "252d63", "gold": "e6c56a", "border_w": 2,
	},
	"witch": {
		"bg": "120d1c", "surface": "1d1530", "surface2": "271d40", "border": "4d3b73",
		"text": "ebe3f7", "dim": "a597bf", "accent": "5fd38a", "accent_text": "0b1f12",
		"primary": "6b3fb8", "primary_text": "ffffff", "event_bg": "271d40", "event_text": "ebe3f7",
		"good": "5fd38a", "warn": "e2b44a", "bad": "e0587a", "track": "2f2447", "gold": "c9a5ff", "border_w": 1,
	},
	"superhero": {
		"bg": "111a27", "surface": "1b2637", "surface2": "263246", "border": "435470",
		"text": "e3e9f2", "dim": "a9b6c9", "accent": "c58e85", "accent_text": "ffffff",
		"primary": "8ca7cf", "primary_text": "ffffff", "event_bg": "1b2637", "event_text": "e3e9f2",
		"good": "20a84a", "warn": "f4c20d", "bad": "e23a2e", "track": "303d51", "gold": "c6b98d", "border_w": 3,
	},
}

var current := "ink"
var theme: Theme
var font_regular: Font
var font_bold: Font


func _ready() -> void:
	font_regular = _make_font("res://fonts/nunito-latin-700-normal.woff2", 600)
	font_bold = _make_font("res://fonts/nunito-latin-800-normal.woff2", 800)


func _make_font(path: String, weight: int) -> Font:
	var fallbacks: Array[Font] = []
	if ResourceLoader.exists("res://fonts/NotoColorEmoji.ttf"):
		fallbacks.append(load("res://fonts/NotoColorEmoji.ttf"))
	var sys_emoji := SystemFont.new()
	sys_emoji.font_names = PackedStringArray(["Segoe UI Emoji", "Apple Color Emoji", "Noto Color Emoji"])
	fallbacks.append(sys_emoji)
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray(["Segoe UI", "Roboto", "Noto Sans", "Arial", "sans-serif"])
	sys.font_weight = weight
	fallbacks.append(sys)
	if ResourceLoader.exists(path):
		var f: FontFile = load(path)
		var v := FontVariation.new()
		v.base_font = f
		v.fallbacks = fallbacks
		return v
	sys.fallbacks = fallbacks.filter(func(f): return f != sys)
	return sys


var high_contrast := false


func set_contrast(on: bool) -> void:
	high_contrast = on
	apply(current)


func c(key: String) -> Color:
	var v = PALETTES[current].get(key, "ff00ff")
	if v is String:
		var col := Color("#" + v)
		if key in ["accent","primary","good","warn","bad","gold"]:
			col = Color.from_hsv(col.h,minf(col.s,0.58),col.v,col.a)
		if high_contrast and key == "dim":
			# secondary text is the first thing to fail a contrast check
			return col.lerp(Color("#" + str(PALETTES[current].get("text", "ffffff"))), 0.6)
		return col
	return Color.MAGENTA


func bar_color(stat_key: String, value: float) -> Color:
	var v := value
	if stat_key == "stress":
		v = 100.0 - value
	if v >= 60:
		return c("good")
	if v >= 30:
		return c("warn")
	return c("bad")


func apply(name_key: String) -> void:
	if not PALETTES.has(name_key):
		name_key = "dark"
	current = name_key
	theme = build()
	get_tree().root.theme = theme
	RenderingServer.set_default_clear_color(c("bg"))
	theme_changed.emit()


func next_theme() -> String:
	var i := ORDER.find(current)
	return ORDER[(i + 1) % ORDER.size()]


func _box(bg: Color, radius: int = 12, border: Color = Color.TRANSPARENT, bw: int = 0, pad_h: int = 14, pad_v: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(bw)
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	s.anti_aliasing = true
	return s


func _button_set(t: Theme, type: String, bg: Color, fg: Color, radius: int, border: Color, bw: int, pad_h: int = 14, pad_v: int = 10) -> void:
	t.set_stylebox("normal", type, _box(bg, radius, border, bw, pad_h, pad_v))
	t.set_stylebox("hover", type, _box(bg.lightened(0.08), radius, border.lightened(0.1), bw, pad_h, pad_v))
	t.set_stylebox("pressed", type, _box(bg.darkened(0.12), radius, border, bw, pad_h, pad_v))
	t.set_stylebox("focus", type, _box(Color.TRANSPARENT, radius, c("primary").lightened(0.2), 2, pad_h, pad_v))
	var dis := _box(bg.darkened(0.25), radius, border.darkened(0.3), bw, pad_h, pad_v)
	t.set_stylebox("disabled", type, dis)
	t.set_color("font_color", type, fg)
	t.set_color("font_hover_color", type, fg)
	t.set_color("font_pressed_color", type, fg)
	t.set_color("font_focus_color", type, fg)
	t.set_color("font_disabled_color", type, Color(fg, 0.45))


func _corners(box: StyleBoxFlat, tl: int, tr: int, br: int, bl: int) -> StyleBoxFlat:
	box.corner_radius_top_left = tl
	box.corner_radius_top_right = tr
	box.corner_radius_bottom_right = br
	box.corner_radius_bottom_left = bl
	return box


func build() -> Theme:
	var t := Theme.new()
	var bw: int = 1 if high_contrast else 0
	t.default_font = font_regular
	t.default_font_size = 18

	t.set_color("font_color", "Label", c("text"))
	t.set_color("default_color", "RichTextLabel", c("text"))
	t.set_font("bold_font", "RichTextLabel", font_bold)

	for v in [["Heading", 26], ["Title", 30], ["Big", 44], ["Huge", 80]]:
		t.set_type_variation(v[0], "Label")
		t.set_font("font", v[0], font_bold)
		t.set_font_size("font_size", v[0], v[1])
	t.set_type_variation("Bold", "Label")
	t.set_font("font", "Bold", font_bold)
	t.set_type_variation("Dim", "Label")
	t.set_color("font_color", "Dim", c("dim"))
	t.set_font_size("font_size", "Dim", 15)
	t.set_type_variation("AccentLabel", "Label")
	t.set_color("font_color", "AccentLabel", c("accent"))
	t.set_font("font", "AccentLabel", font_bold)
	t.set_font_size("font_size", "AccentLabel", 22)
	t.set_type_variation("Money", "Label")
	t.set_color("font_color", "Money", c("good"))
	t.set_font("font", "Money", font_bold)
	t.set_font_size("font_size", "Money", 26)
	t.set_type_variation("EventText", "Label")
	t.set_color("font_color", "EventText", c("event_text"))
	t.set_type_variation("EventTitle", "Label")
	t.set_color("font_color", "EventTitle", c("text"))
	t.set_font("font", "EventTitle", font_bold)
	t.set_font_size("font_size", "EventTitle", 28)
	t.set_type_variation("Emoji", "Label")
	t.set_font_size("font_size", "Emoji", 30)

	t.set_stylebox("panel", "PanelContainer", _box(c("surface"), 14, c("border"), bw, 16, 16))
	t.set_stylebox("panel", "Panel", _box(c("surface"), 14, c("border"), bw))
	t.set_type_variation("Screen", "PanelContainer")
	t.set_stylebox("panel", "Screen", _box(c("bg"), 0, Color.TRANSPARENT, 0, 16, 16))
	t.set_type_variation("Card", "PanelContainer")
	t.set_stylebox("panel", "Card", _corners(_box(c("surface"), 24, c("border"), bw, 18, 16), 28, 28, 28, 12))
	t.set_type_variation("HubPanel", "PanelContainer")
	t.set_stylebox("panel", "HubPanel", _corners(_box(c("surface"), 28, c("border"), bw, 22, 20), 36, 36, 18, 36))
	t.set_type_variation("Inset", "PanelContainer")
	t.set_stylebox("panel", "Inset", _box(c("surface"), 12, c("border"), bw, 14, 12))
	t.set_type_variation("Chip", "PanelContainer")
	t.set_stylebox("panel", "Chip", _box(c("surface2"), 14, c("border"), bw, 10, 4))
	t.set_type_variation("EventCard", "PanelContainer")
	t.set_stylebox("panel", "EventCard", _corners(_box(c("event_bg"), 28, c("border"), 0, 28, 26), 36, 14, 36, 14))
	t.set_type_variation("EventFrame", "PanelContainer")
	var frame := _corners(_box(c("surface"), 28, Color.TRANSPARENT, 0, 22, 20), 34, 16, 28, 34)
	frame.shadow_color = Color(0, 0, 0, 0.45)
	frame.shadow_size = 0
	t.set_stylebox("panel", "EventFrame", frame)
	t.set_type_variation("EventIcon", "PanelContainer")
	t.set_stylebox("panel", "EventIcon", _corners(_box(c("surface2"), 22, Color.TRANSPARENT, 0, 10, 8), 24, 12, 24, 12))
	t.set_type_variation("Portrait", "PanelContainer")
	t.set_stylebox("panel", "Portrait", _box(c("surface2"), 60, c("border"), bw, 6, 4))
	t.set_type_variation("Halo", "PanelContainer")
	t.set_stylebox("panel", "Halo", _box(c("surface").lerp(c("gold"), 0.12), 90, c("gold"), bw, 10, 8))
	t.set_type_variation("Banner", "PanelContainer")
	t.set_stylebox("panel", "Banner", _box(c("surface").lerp(c("gold"), 0.15), 8, c("gold"), bw, 20, 8))
	t.set_type_variation("Tomb", "PanelContainer")
	var tomb := _box(c("surface2").lerp(Color("#6f7a63"), 0.12), 18, c("border"), bw, 24, 24)
	tomb.corner_radius_top_left = 150
	tomb.corner_radius_top_right = 150
	tomb.content_margin_top = 56
	t.set_stylebox("panel", "Tomb", tomb)
	t.set_type_variation("TabStrip", "PanelContainer")
	t.set_stylebox("panel", "TabStrip", _box(c("surface"), 16, c("border"), bw, 8, 6))

	_button_set(t, "Button", c("surface2"), c("text"), 10, c("border"), bw)
	t.set_font_size("font_size", "Button", 18)
	t.set_type_variation("Row", "Button")
	_button_set(t, "Row", c("surface2"), c("text"), 18, c("border"), bw, 16, 12)
	for role in ["NavigationRow", "BulkRow"]:
		t.set_type_variation(role,"Button")
		var fill := c("surface2").lerp(c("accent"),0.12) if role=="BulkRow" else c("surface")
		if fill.get_luminance()>0.22: fill=fill.darkened(1.0-0.22/fill.get_luminance())
		_button_set(t,role,fill,c("text"),20,c("border"),bw,16,12)
		for state in ["normal","hover","pressed","disabled","focus"]:
			var style: StyleBoxFlat=t.get_stylebox(state,role)
			_corners(style,28,12,28,12) if role=="BulkRow" else _corners(style,12,24,24,12)
	for tile in [["LifeTileHuman", [32, 16, 32, 16]], ["LifeTilePet", [32, 32, 14, 32]], ["LifeTileStory", [14, 32, 32, 32]], ["LifeTilePrison", [28, 14, 28, 14]]]:
		t.set_type_variation(tile[0], "Button")
		_button_set(t, tile[0], c("surface2"), c("text"), 24, c("border"), bw, 16, 12)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var box: StyleBoxFlat = t.get_stylebox(state, tile[0])
			_corners(box, tile[1][0], tile[1][1], tile[1][2], tile[1][3])
	t.set_type_variation("Primary", "Button")
	t.set_type_variation("ChoiceRow", "Button")
	_button_set(t, "ChoiceRow", c("surface2"), c("text"), 18, Color.TRANSPARENT, 0, 16, 12)
	t.set_font("font", "ChoiceRow", font_bold)
	_button_set(t, "Primary", c("surface2").lerp(c("primary"), 0.18), c("text"), 10, c("primary"), bw, 16, 12)
	t.set_type_variation("Accent", "Button")
	_button_set(t, "Accent", c("surface2").lerp(c("accent"), 0.18), c("text"), 12, c("accent"), bw, 18, 12)
	t.set_font("font", "Accent", font_bold)
	t.set_font_size("font_size", "Accent", 22)
	t.set_type_variation("AgeButton", "Button")
	var age_bg := c("surface2").lerp(c("accent"), 0.22)
	_button_set(t, "AgeButton", age_bg, c("text"), 12, c("accent"), bw, 10, 10)
	t.set_font("font", "AgeButton", font_bold)
	t.set_font_size("font_size", "AgeButton", 30)
	t.set_type_variation("Flat", "Button")
	_button_set(t, "Flat", Color.TRANSPARENT, c("text"), 10, Color.TRANSPARENT, 0, 10, 6)
	t.set_stylebox("hover", "Flat", _box(c("surface2"), 10, Color.TRANSPARENT, 0, 10, 6))
	t.set_type_variation("Tab", "Button")
	_button_set(t, "Tab", Color.TRANSPARENT, c("dim"), 12, Color.TRANSPARENT, 0, 6, 6)
	t.set_stylebox("hover", "Tab", _box(c("surface2"), 12, Color.TRANSPARENT, 0, 6, 6))
	t.set_stylebox("pressed", "Tab", _box(c("surface2"), 12, c("accent"), 0, 6, 6))
	t.set_color("font_hover_color", "Tab", c("text"))
	t.set_color("font_pressed_color", "Tab", c("accent"))
	t.set_font_size("font_size", "Tab", 15)
	t.set_type_variation("Toggle", "Button")
	_button_set(t, "Toggle", c("surface2"), c("text"), 12, c("border"), bw, 12, 10)
	t.set_stylebox("pressed", "Toggle", _box(c("surface2").lerp(c("primary"), 0.18), 12, c("primary"), bw, 12, 10))
	t.set_color("font_pressed_color", "Toggle", c("text"))

	t.set_stylebox("background", "ProgressBar", _box(c("track"), 8, Color.TRANSPARENT, 0, 0, 0))
	t.set_stylebox("fill", "ProgressBar", _box(c("accent"), 8, Color.TRANSPARENT, 0, 0, 0))

	t.set_stylebox("normal", "LineEdit", _box(c("surface2"), 10, c("border"), bw, 12, 8))
	t.set_stylebox("focus", "LineEdit", _box(c("surface2"), 10, c("primary"), 2, 12, 8))
	t.set_color("font_color", "LineEdit", c("text"))
	t.set_color("font_placeholder_color", "LineEdit", c("dim"))
	t.set_color("caret_color", "LineEdit", c("text"))

	_button_set(t, "OptionButton", c("surface2"), c("text"), 10, c("border"), bw)
	t.set_stylebox("panel", "PopupMenu", _box(c("surface"), 10, c("border"), bw, 8, 8))
	t.set_stylebox("hover", "PopupMenu", _box(c("surface2"), 8))
	t.set_color("font_color", "PopupMenu", c("text"))
	t.set_color("font_hover_color", "PopupMenu", c("text"))

	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	var grab := _box(c("border"), 6, Color.TRANSPARENT, 0, 4, 4)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", _box(c("dim"), 6, Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("grabber_pressed", "VScrollBar", _box(c("dim"), 6, Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("scroll", "VScrollBar", _box(Color.TRANSPARENT, 6, Color.TRANSPARENT, 0, 4, 4))
	var sep := StyleBoxLine.new()
	sep.color = c("border")
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)
	t.set_constant("separation", "HSeparator", 12)

	t.set_stylebox("panel", "TabContainer", _box(c("surface"), 0, Color.TRANSPARENT, 0, 0, 12))
	t.set_stylebox("tab_selected", "TabContainer", _box(c("surface2"), 8, Color.TRANSPARENT, 0, 16, 10))
	t.set_stylebox("tab_unselected", "TabContainer", _box(Color.TRANSPARENT, 8, Color.TRANSPARENT, 0, 16, 10))
	t.set_color("font_selected_color", "TabContainer", c("text"))
	t.set_color("font_unselected_color", "TabContainer", c("dim"))
	return t
