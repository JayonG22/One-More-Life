extends Minigame

## Three phases: choose ingredients by their properties, brew (heat + stirring),
## then stabilize and bottle. Unknown properties and recipes fill the grimoire.

const PROPS := {"vigor": ["💪", "Vigor"], "calm": ["🌙", "Calm"], "blight": ["🥀", "Blight"], "mind": ["👁️", "Mind"],
	"luck": ["🍀", "Luck"], "beauty": ["✨", "Beauty"], "charm": ["💗", "Charm"], "gold": ["🪙", "Gold"], "warm": ["🔥", "Warmth"], "volatile": ["💥", "Volatile"]}
const INGREDIENTS := {
	"toadstool": ["🍄", "Toadstool", ["vigor", "volatile"]], "nightshade": ["🌿", "Nightshade", ["blight", "calm"]],
	"bone": ["🦴", "Bone dust", ["blight", "mind"]], "feather": ["🪶", "Raven feather", ["mind", "luck"]],
	"moonstone": ["💎", "Moonstone", ["calm", "beauty"]], "frogeye": ["🐸", "Frog eye", ["charm", "vigor"]],
	"rose": ["🌹", "Rose petals", ["charm", "beauty"]], "goldleaf": ["🟨", "Gold leaf", ["gold", "warm"]],
	"pepper": ["🌶️", "Dragon pepper", ["warm", "volatile"]], "clover": ["☘️", "Four-leaf clover", ["luck", "vigor"]],
}
const RECIPES := {
	"healing": ["💚", "Healing Draught", ["vigor", "calm"]], "glamour": ["💄", "Glamour Tonic", ["beauty", "calm"]],
	"love": ["💘", "Love Philter", ["charm", "warm"]], "fortune": ["🪙", "Fortune Brew", ["luck", "gold"]],
	"insight": ["🔮", "Insight Elixir", ["mind", "calm"]], "hex": ["☠️", "Hex in a Bottle", ["blight", "volatile"]],
}
const STARTER := ["healing", "glamour"]

var phase := 1
var grimoire: Dictionary = {}
var target := ""
var chosen: Array = []
var ing_btns: Dictionary = {}
var rec_btns: Dictionary = {}
var start_b: Button
var info_l: Label
var ui: Array = []
var t := 0.0
var temp := 55.0
var zone_time := 0.0
var stir_dir := 0
var stir_t := 0.0
var stir_hits := 0
var stir_total := 0
var next_stir := 1.5
var brew_len := 12.0
var fill := 0.0
var pouring := false
var band := Vector2(0.55, 0.7)
var bottles: Array = []
var match_score := 0.0
var result := ""
var volatile := false
var bubble_t := 0.0
var t1 := 0.0
var idle3 := 0.0


func build() -> void:
	make_status()
	var g = Meta.meta.get("grimoire", {})
	grimoire = g if g is Dictionary else {}
	if not grimoire.has("known"):
		grimoire["known"] = {}
	if not grimoire.has("recipes"):
		grimoire["recipes"] = {}
	for r in STARTER:
		grimoire["recipes"][r] = true
	Meta.meta["grimoire"] = grimoire
	_phase1()


func _clear_ui() -> void:
	for n in ui:
		if is_instance_valid(n):
			n.queue_free()
	ui.clear()
	ing_btns.clear()
	rec_btns.clear()


func _p(node: Control, pos: Vector2, sz: Vector2 = Vector2.ZERO) -> Control:
	place(node, pos, sz)
	ui.append(node)
	return node


func _known(ing: String, prop_i: int) -> bool:
	return grimoire["known"].get(ing, []).has(prop_i)


# ---------------------------------------------------------------- phase 1

func _phase1() -> void:
	phase = 1
	_clear_ui()
	status.text = "1 · Choose three ingredients"
	_p(label("Aim for:", 16, true, col("dim")), Vector2(30, 46), Vector2(200, 24))
	var i := 0
	for rid in RECIPES.keys():
		var r: Array = RECIPES[rid]
		var known: bool = grimoire["recipes"].has(rid)
		var txt := "%s %s\n%s" % [r[0], r[1], " + ".join(r[2].map(func(pp): return PROPS[pp][0] + PROPS[pp][1]))] if known else "❔ Unknown recipe"
		var b := button(txt, _pick_target.bind(rid), "Toggle")
		b.toggle_mode = true
		b.disabled = not known
		b.add_theme_font_size_override("font_size", 13)
		_p(b, Vector2(30, 74 + i * 58), Vector2(230, 52))
		rec_btns[rid] = b
		i += 1
	var ex := button("🔮 Experiment\nsee what happens", _pick_target.bind(""), "Toggle")
	ex.toggle_mode = true
	ex.add_theme_font_size_override("font_size", 13)
	_p(ex, Vector2(30, 74 + i * 58), Vector2(230, 52))
	rec_btns[""] = ex
	var k := 0
	for iid in INGREDIENTS.keys():
		var ing: Array = INGREDIENTS[iid]
		var props: Array = []
		for pi in range(2):
			props.append((PROPS[ing[2][pi]][0] + " " + PROPS[ing[2][pi]][1]) if _known(iid, pi) else "❔ ???")
		var b2 := button("%s %s  [%d]\n%s\n%s" % [ing[0], ing[1], (k + 1) % 10, props[0], props[1]], _toggle_ing.bind(iid), "Toggle")
		b2.toggle_mode = true
		b2.add_theme_font_size_override("font_size", 13)
		_p(b2, Vector2(290 + (k % 5) * 138, 74 + int(k / 5) * 112), Vector2(130, 104))
		ing_btns[iid] = b2
		k += 1
	info_l = label("", 16, false, col("dim"))
	info_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_p(info_l, Vector2(290, 312), Vector2(680, 60))
	start_b = button("⚗️ Start brewing  [Enter]", _start_brew, "Accent")
	start_b.disabled = true
	_p(start_b, Vector2(560, 470), Vector2(410, 54))
	_pick_target(str(params.get("target", "healing")))
	_update_info()


func _pick_target(rid: String) -> void:
	if phase != 1:
		return
	target = rid
	for k in rec_btns.keys():
		rec_btns[k].button_pressed = k == rid
	_update_info()


func _toggle_ing(iid: String) -> void:
	if phase != 1:
		return
	if chosen.has(iid):
		chosen.erase(iid)
	elif chosen.size() < 3:
		chosen.append(iid)
		Fx.play("page", 0.1)
	for k in ing_btns.keys():
		ing_btns[k].button_pressed = chosen.has(k)
	_update_info()


func _update_info() -> void:
	if info_l == null:
		return
	var tgt := "Experimenting: the brew will become whatever the ingredients add up to." if target == "" else "Target: %s needs %s." % [RECIPES[target][1], " and ".join(RECIPES[target][2].map(func(pp): return PROPS[pp][1]))]
	info_l.text = "%s\nChosen: %s" % [tgt, ", ".join(chosen.map(func(c): return INGREDIENTS[c][0] + " " + INGREDIENTS[c][1])) if not chosen.is_empty() else "nothing yet (pick 3)"]
	if start_b:
		start_b.disabled = chosen.size() < 3


func _start_brew() -> void:
	if phase != 1 or chosen.size() < 3:
		return
	var props := {}
	for c in chosen:
		for pi in range(2):
			var pp: String = INGREDIENTS[c][2][pi]
			props[pp] = int(props.get(pp, 0)) + 1
			var kn: Array = grimoire["known"].get(c, [])
			if not kn.has(pi):
				kn.append(pi)
				grimoire["known"][c] = kn
	volatile = props.has("volatile")
	var best := ""
	var best_m := -1.0
	for rid in RECIPES.keys():
		var need: Array = RECIPES[rid][2]
		var m := 0.0
		for pp in need:
			if props.has(pp):
				m += 0.5
		if rid != "hex" and props.has("volatile"):
			m -= 0.15
		if m > best_m:
			best_m = m
			best = rid
	if target != "":
		var need2: Array = RECIPES[target][2]
		match_score = 0.0
		for pp in need2:
			if props.has(pp):
				match_score += 0.5
		if target != "hex" and volatile:
			match_score -= 0.15
		result = target if match_score >= 0.99 else (best if best_m >= 0.99 else "")
	else:
		match_score = maxf(0.0, best_m)
		result = best if best_m >= 0.99 else ""
	if result != "" and not grimoire["recipes"].has(result):
		grimoire["recipes"][result] = true
		flash_text("📖 New recipe: %s!" % RECIPES[result][1], col("gold"), Vector2(W / 2, 260))
		Fx.play("magic")
	_phase2()


# ---------------------------------------------------------------- phase 2

func _phase2() -> void:
	phase = 2
	_clear_ui()
	t = 0.0
	var cauldron := label("🫕", 120)
	cauldron.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p(cauldron, Vector2(W / 2 - 100, 110), Vector2(200, 170))
	info_l = label("", 26, true)
	info_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p(info_l, Vector2(0, 300), Vector2(W, 40))
	var stoke := button("🔥 Stoke  [Space]", _stoke, "Accent")
	_p(stoke, Vector2(W / 2 - 330, 460), Vector2(200, 52))
	var lb := button("↺ Stir left  [←]", _stir.bind(-1), "Row")
	_p(lb, Vector2(W / 2 - 110, 460), Vector2(210, 52))
	var rb := button("↻ Stir right  [→]", _stir.bind(1), "Row")
	_p(rb, Vector2(W / 2 + 120, 460), Vector2(210, 52))


func _stoke() -> void:
	if phase == 2:
		temp = minf(100.0, temp + 15.0)
		Fx.play("bubble", 0.15)


func _stir(d: int) -> void:
	if phase != 2:
		return
	if stir_dir != 0 and d == stir_dir:
		stir_hits += 1
		stir_dir = 0
		next_stir = randf_range(0.6, 1.4)
		Fx.play("coin", 0.1)
		flash_text("🌀 Good stir", col("good"), Vector2(W / 2, 360), 22)
	elif stir_dir != 0:
		stir_dir = 0
		next_stir = randf_range(0.6, 1.4)
		Fx.play("error")
		temp = minf(100.0, temp + 12.0)
		flash_text("💦 Splash!", col("bad"), Vector2(W / 2, 360), 22)


# ---------------------------------------------------------------- phase 3

func _phase3() -> void:
	phase = 3
	_clear_ui()
	fill = 0.0
	band = Vector2(randf_range(0.45, 0.7), 0.0)
	band.y = band.x + 0.13 / difficulty
	info_l = label("Hold Space to pour. Let go inside the band. Bottle 1 of 3.", 20, true)
	info_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p(info_l, Vector2(0, 60), Vector2(W, 32))
	var pour := button("🫗 Hold to pour  [Space]", func(): pass, "Accent")
	pour.button_down.connect(func():
		pouring = true
		Fx.play("pour", 0.1))
	pour.button_up.connect(_release)
	_p(pour, Vector2(W / 2 - 170, 460), Vector2(340, 56))


func _release() -> void:
	if phase != 3 or not pouring:
		pouring = false
		return
	pouring = false
	var mid := (band.x + band.y) / 2.0
	var s := 1.0 if fill >= band.x and fill <= band.y else maxf(0.0, 1.0 - absf(fill - mid) * 5.0)
	bottles.append(s)
	Fx.play("good" if s >= 1.0 else ("coin" if s > 0.4 else "bad"))
	flash_text("🧪 Sealed!" if s >= 1.0 else ("🫧 A little off" if s > 0.4 else "💥 Spilled"), col("good") if s >= 1.0 else col("warn"), Vector2(W / 2, 400), 24)
	if bottles.size() >= 3:
		_end()
		return
	fill = 0.0
	band.x = randf_range(0.4, 0.75)
	band.y = band.x + 0.13 / difficulty
	info_l.text = "Hold Space to pour. Let go inside the band. Bottle %d of 3." % (bottles.size() + 1)


func _end() -> void:
	var brew := 0.6 * clampf(zone_time / brew_len, 0.0, 1.0) + 0.4 * (float(stir_hits) / maxf(1.0, float(stir_total)))
	var bottle := 0.0
	for b in bottles:
		bottle += float(b)
	bottle /= 3.0
	var total := 0.4 * clampf(match_score, 0.0, 1.0) + 0.35 * brew + 0.25 * bottle
	var variant := ""
	if volatile and brew < 0.4 and result != "hex":
		variant = "explosion"
	elif result == "":
		variant = "strange" if match_score >= 0.5 else "sludge"
	elif brew < 0.35:
		variant = "weak"
	elif brew >= 0.85 and bottle >= 0.8 and match_score >= 0.99:
		variant = "masterwork"
	Meta.meta["grimoire"] = grimoire
	Meta.save()
	if variant == "explosion":
		Fx.play("explosion")
	elif variant == "masterwork":
		Fx.play("magic")
	finish(total, {"recipe": result, "variant": variant, "bottled": bottles.filter(func(b): return float(b) > 0.4).size(), "match": match_score, "brew": brew, "zone": zone_time, "stirs": [stir_hits, stir_total]})


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	if done:
		return
	match phase:
		1:
			t1 += delta
			if t1 > 45.0:
				status.text = "1 · Choose three ingredients   ·   the cauldron cools in %ds" % int(ceil(60.0 - t1))
			if t1 >= 60.0:
				var pool: Array = INGREDIENTS.keys().filter(func(k): return not chosen.has(k))
				pool.shuffle()
				while chosen.size() < 3:
					chosen.append(pool.pop_back())
				_start_brew()
		2:
			t += delta
			temp = maxf(0.0, temp - delta * (8.0 + 5.0 * difficulty))
			if temp >= 45.0 and temp <= 72.0:
				zone_time += delta
				bubble_t -= delta
				if bubble_t <= 0.0:
					bubble_t = randf_range(0.25, 0.6)
					Fx.play("bubble", 0.2)
			next_stir -= delta
			if stir_dir == 0 and next_stir <= 0:
				stir_dir = [-1, 1][randi() % 2]
				stir_total += 1
				stir_t = 1.3 / difficulty
			elif stir_dir != 0:
				stir_t -= delta
				if stir_t <= 0:
					stir_dir = 0
					next_stir = randf_range(0.6, 1.4)
			if stir_dir == 0 and next_stir <= -0.01:
				next_stir = randf_range(0.6, 1.4)
			info_l.text = ("Stir %s!" % ("↺ LEFT" if stir_dir < 0 else "↻ RIGHT")) if stir_dir != 0 else "Keep the heat in the green"
			status.text = "2 · Brew   ·   %.0fs   ·   Heat %d°" % [maxf(0.0, brew_len - t), int(temp)]
			if t >= brew_len:
				_phase3()
		3:
			if pouring:
				idle3 = 0.0
				fill = minf(1.0, fill + delta * 0.45 * difficulty)
				if fill >= 1.0:
					_release()
			else:
				idle3 += delta
				if idle3 >= 7.0:
					idle3 = 0.0
					bottles.append(0.0)
					Fx.play("bad")
					flash_text("🫠 It curdled in the ladle", col("bad"), Vector2(W / 2, 400), 24)
					if bottles.size() >= 3:
						_end()
						return
			status.text = "3 · Stabilize & bottle   ·   Bottle %d of 3" % mini(3, bottles.size() + 1)
	queue_redraw()


func _draw() -> void:
	if phase == 2:
		var r := Rect2(W - 100, 110, 30, 220)
		draw_rect(r, col("track"))
		var zy := r.position.y + r.size.y * (1.0 - 0.72)
		draw_rect(Rect2(r.position.x, zy, r.size.x, r.size.y * 0.27), Color(col("good"), 0.5))
		var ty := r.position.y + r.size.y * (1.0 - temp / 100.0)
		draw_rect(Rect2(r.position.x - 8, ty - 4, r.size.x + 16, 8), col("good") if temp >= 45 and temp <= 72 else col("bad"))
		bar_rect(Rect2(60, 420, W - 120, 10), zone_time / brew_len, col("primary"), col("track"))
	elif phase == 3:
		var br := Rect2(W / 2 - 60, 110, 120, 300)
		draw_rect(br, col("track"))
		var by := br.position.y + br.size.y * (1.0 - band.y)
		draw_rect(Rect2(br.position.x, by, br.size.x, br.size.y * (band.y - band.x)), Color(col("good"), 0.45))
		var fh := br.size.y * fill
		draw_rect(Rect2(br.position.x + 10, br.position.y + br.size.y - fh, br.size.x - 20, fh), Color(col("primary"), 0.85))


func _unhandled_input(event: InputEvent) -> void:
	match phase:
		1:
			var keys := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
			var ids: Array = INGREDIENTS.keys()
			for i in range(keys.size()):
				if key_pressed(event, [keys[i]]):
					_toggle_ing(ids[i])
					get_viewport().set_input_as_handled()
					return
			if key_pressed(event, [KEY_ENTER, KEY_KP_ENTER]):
				_start_brew()
				get_viewport().set_input_as_handled()
		2:
			if key_pressed(event, [KEY_SPACE]):
				_stoke()
			elif key_pressed(event, [KEY_LEFT, KEY_A]):
				_stir(-1)
			elif key_pressed(event, [KEY_RIGHT, KEY_D]):
				_stir(1)
			else:
				return
			get_viewport().set_input_as_handled()
		3:
			if key_pressed(event, [KEY_SPACE]):
				pouring = true
				get_viewport().set_input_as_handled()
			elif key_released(event, [KEY_SPACE]):
				_release()
				get_viewport().set_input_as_handled()
