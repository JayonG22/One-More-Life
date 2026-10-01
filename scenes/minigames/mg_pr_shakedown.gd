extends Minigame

## A CELL SEARCH. Twelve things in a cell. Three are not what they appear. Every
## item has a one-line description, and the ones that are wrong give themselves
## away in the wording — a glued seam, a weight that isn't right, screws that
## are too bright. Mark the three, then SEIZE. A wrong item is a cell turned over
## for nothing, and the inmate will remember it.

const TELLS := [
	["🧼", "Soap bar", "the seam has been cut and glued shut"],
	["📻", "Radio", "the screws are bright and the case was opened recently"],
	["🪥", "Toothbrush", "the handle has been ground to a point"],
	["☕", "Coffee jar", "far too heavy for what it holds"],
	["📖", "Paperback", "the pages have been hollowed out"],
	["✉️", "Bundle of letters", "one envelope is noticeably thick and warm"],
	["👟", "Trainer", "the sole has been re-glued and is slightly raised"],
	["🕯️", "Candle", "it is hollow, and plugged at the base"],
	["🧴", "Shampoo bottle", "it has a false base"],
	["🃏", "Pack of cards", "one card is thicker than the rest"],
]
const PLAIN := [
	["🪞", "Plastic mirror", "scratched, as you'd expect"],
	["📸", "Photograph", "curling at the corners from years of handling"],
	["🧦", "Socks", "grey and darned"],
	["🥫", "Tin of mackerel", "sealed, with the commissary sticker"],
	["📔", "Notebook", "half full of small, neat sums"],
	["🧢", "Cap", "faded, with a sweat line"],
	["🪒", "Plastic razor", "the standard issue, with a number on it"],
	["📺", "Small TV", "serial number matches the property sheet"],
	["🍫", "Chocolate bar", "wrapper intact"],
	["🧻", "Toilet roll", "ordinary"],
	["🔑", "Cell key tag", "plastic, issued"],
	["📅", "Calendar", "a year of crossed-out days"],
	["🖊️", "Pen", "the clear plastic kind, issued"],
	["🥄", "Spoon", "bent a little, but whole"],
]
const TIME := 36.0
const NEED := 3

var items: Array = []
var picked: Dictionary = {}
var btns: Array = []
var time_left := TIME
var hint_l: Label
var seize_b: Button


func build() -> void:
	make_status()
	hint_l = label("Three of these are not what they appear. Read the descriptions, mark three, then press SEIZE.", 18, true)
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(hint_l, Vector2(40, 38), Vector2(W - 80, 30))
	var pool_t := TELLS.duplicate()
	pool_t.shuffle()
	var pool_p := PLAIN.duplicate()
	pool_p.shuffle()
	for i in range(NEED):
		items.append({"it": pool_t[i], "tell": true})
	for j in range(12 - NEED):
		items.append({"it": pool_p[j], "tell": false})
	items.shuffle()
	for k in range(items.size()):
		var it: Array = items[k]["it"]
		var b := Button.new()
		b.text = "%s %s\n%s" % [it[0], it[1], it[2]]
		b.theme_type_variation = "Row"
		b.toggle_mode = false
		b.focus_mode = Control.FOCUS_NONE
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.clip_text = false
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(_toggle.bind(k))
		b.tooltip_text = str(it[1])
		place(b, Vector2(32 + (k % 4) * 236, 78 + (k / 4) * 106), Vector2(224, 96))
		btns.append(b)
	seize_b = button("🔦  SEIZE the three marked  [Enter]", _seize, "Accent")
	place(seize_b, Vector2(W / 2 - 220, 404 + 70), Vector2(440, 54))
	_refresh()


func _toggle(k: int) -> void:
	if done:
		return
	if picked.has(k):
		picked.erase(k)
	elif picked.size() < NEED:
		picked[k] = true
	Fx.play("tap", 0.05)
	_refresh()


func _refresh() -> void:
	for k in range(btns.size()):
		btns[k].modulate = Color(1.0, 0.85, 0.3) if picked.has(k) else Color(1, 1, 1)
	status.text = "Marked %d of %d  ·  %d s" % [picked.size(), NEED, int(maxf(0.0, time_left))]


func _seize() -> void:
	if done:
		return
	var right := 0
	var wrong := 0
	for k in picked.keys():
		if items[k]["tell"]:
			right += 1
		else:
			wrong += 1
	var s := clampf((float(right) - 0.5 * float(wrong)) / float(NEED) * 0.9 + 0.1 * clampf(time_left / TIME, 0.0, 1.0) * (1.0 if right > 0 else 0.0), 0.0, 1.0)
	finish(s, {"found": right, "wrong": wrong})


func _process(delta: float) -> void:
	if done:
		return
	time_left -= delta
	status.text = "Marked %d of %d  ·  %d s" % [picked.size(), NEED, int(maxf(0.0, time_left))]
	if time_left <= 0.0:
		_seize()


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]):
		_seize()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode >= KEY_1 and event.keycode <= KEY_9:
		_toggle(event.keycode - KEY_1)
		get_viewport().set_input_as_handled()
