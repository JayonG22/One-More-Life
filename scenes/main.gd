extends Control

const U := preload("res://scenes/ui_kit.gd")
const TF := preload("res://scenes/theme_filter.gd")

var root_bg: PanelContainer
var screens := {}
var overlay: Control
var overlay_box: VBoxContainer
var overlay_frame: PanelContainer
var popup_open := false
var death_waiting := false

# new life form
var nl := {}
# game screen refs
var g := {}
var panel_stack: Array = []
var life_theme_on := false
var fx_layer: Control
var filter_rect: ColorRect
var shake_root: Control
var last_stats := {}
var last_money := 0
var filter_time := 0.0
var ep
var mg_open := false
var mg_playing := false
var mg_layer: Control
var mg_frame: PanelContainer
var mg_box: VBoxContainer
var mg_default: Button
var mg_holder: Control = null
var mg_game: Minigame = null
var toasts_live := 0
var trophy_cat := "life"
var LP
var SP
var MP
var screen_tween: Tween


func _ready() -> void:
	ThemeManager.apply(GameState.settings.get("theme", "dark"))
	ThemeManager.theme_changed.connect(_on_theme_changed)
	GameState.changed.connect(_refresh_side)
	GameState.log_added.connect(_on_log_added)
	GameState.year_started.connect(_on_year_started)
	EventEngine.event_queued.connect(_pump)
	EventEngine.died.connect(_on_died)
	ep = preload("res://scenes/empire_panels.gd").new(self)
	LP = preload("res://scenes/lives_panels.gd").new(self)
	SP = preload("res://scenes/slot_panels.gd").new(self)
	MP = preload("res://scenes/menu_panels.gd").new(self)
	_apply_display()
	get_viewport().size_changed.connect(_mg_fit)
	get_viewport().size_changed.connect(_fit_layout)
	Minigames.requested.connect(_on_minigame)
	Goals.unlocked.connect(_toast_ach)
	Goals.mission_done.connect(_toast_mission)
	Lives.transformed.connect(_on_transformed)
	Minigames.host_ready = true
	_build()
	_show("title")


func _build() -> void:
	popup_open = false
	theme = ThemeManager.theme
	U.clear(self)
	root_bg = U.card("Screen")
	root_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_bg)
	filter_rect = TF.build(ThemeManager.current)
	if filter_rect != null:
		root_bg.add_child(filter_rect)
	var holder := Control.new()
	shake_root = holder
	root_bg.add_child(holder)
	screens = {
		"title": _build_title(),
		"new": _build_new_life(),
		"game": _build_game(),
		"death": _build_death_shell(),
		"graveyard": _build_graveyard_shell(),
	}
	for k in screens.keys():
		var s: Control = screens[k]
		s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		s.visible = false
		holder.add_child(s)
	_build_overlay()
	_build_mg_layer()
	fx_layer = Control.new()
	fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx_layer)
	Moments.bind(fx_layer, shake_root)
	last_stats.clear()
	last_money = int(GameState.player.get("money", 0)) if GameState.has_life() else 0


func _process(delta: float) -> void:
	if filter_rect != null and is_instance_valid(filter_rect) and TF.animated(ThemeManager.current):
		filter_time += delta
		var mat: ShaderMaterial = filter_rect.material
		mat.set_shader_parameter("t", filter_time)


func _show(name_key: String) -> void:
	var was := _current_screen()
	for k in screens.keys():
		screens[k].visible = k == name_key
	if was != name_key and screens.has(name_key) and Fx.effects_on() and not Fx.reduced_motion():
		var s: Control = screens[name_key]
		if screen_tween and screen_tween.is_valid():
			screen_tween.kill()
		s.modulate.a = 0.0
		screen_tween = s.create_tween()
		screen_tween.tween_property(s, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE)
		if was != "":
			Fx.play("whoosh", 0.05)
	if name_key == "title":
		_refresh_title()
	if name_key == "game":
		_rebuild_log()
		_refresh_side()
		if panel_stack.is_empty():
			_tab_press(0)
		else:
			_render_top_panel()


func _current_screen() -> String:
	for k in screens.keys():
		if screens[k].visible:
			return k
	return ""


func _on_theme_changed() -> void:
	var cur := _current_screen()
	var stack := panel_stack.duplicate()
	_build()
	panel_stack = stack
	if cur == "":
		cur = "title"
	_show(cur)
	if cur == "death" and GameState.has_life():
		_fill_death(GameState.player.get("legacy", {}))
	if cur == "graveyard":
		_fill_graveyard()


# ================================================================= TITLE

func _build_title() -> Control:
	var c := CenterContainer.new()
	var h := U.hb(90)
	c.add_child(h)
	var left := U.vb(14)
	left.custom_minimum_size = Vector2(720, 0)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(left)
	var crown := U.lbl("👑", "Emoji", 64)
	left.add_child(crown)
	var words := U.vb(-46)
	left.add_child(words)
	for word in ["ONE", "MORE", "LIFE"]:
		var l := U.lbl(word, "Huge", 128)
		if word == "MORE":
			l.add_theme_color_override("font_color", ThemeManager.c("primary").lightened(0.2))
		elif word == "LIFE":
			l.add_theme_color_override("font_color", ThemeManager.c("gold"))
		words.add_child(l)
	left.add_child(U.lbl("Every choice echoes.", "Dim", 24))
	var paths := U.hb(12)
	for k in Lives.TYPES.keys():
		var chip := U.card("Chip")
		chip.tooltip_text = Lives.TYPES[k]["name"] + ": " + Lives.TYPES[k]["desc"]
		chip.add_child(U.lbl(Lives.TYPES[k]["icon"], "Emoji", 30))
		paths.add_child(chip)
	left.add_child(paths)
	left.add_child(U.lbl("v%s · Other Lives" % ProjectSettings.get_setting("application/config/version", "0.5.0"), "Dim", 15))
	var box := U.card()
	box.custom_minimum_size = Vector2(560, 0)
	h.add_child(box)
	var bv := U.vb(10)
	box.add_child(bv)
	# The game modes come first and look different from the menu under them:
	# they are three separate ways to play, not three items in a list.
	var modes_h := U.lbl("CHOOSE YOUR GAME MODE", "Bold", 15)
	modes_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modes_h.add_theme_color_override("font_color", ThemeManager.c("gold"))
	bv.add_child(modes_h)
	var modes_row := U.hb(10)
	bv.add_child(modes_row)
	for md in [
		["NewLifeBtn", "🧑", "Human Life", "The classic. Be born, grow up, choose, die.", func(): _open_new_life(), true],
		["PetsBtn", "🐾", "Pets Life", "Live as a dog, cat, rabbit, parrot or horse.", func(): _open_pet_setup(), true],
		["PrisonBtn", "⛓️", "Prison Life", "Prisoner or guard. Ranks, gangs, a jailbreak. Arrives in v1.2.", func(): _show_info("⛓️", "Prison Life", "Prison Life is the next game mode: serve a sentence or work the walls as a guard, with ranks, gangs, contraband, parole and a jailbreak.\n\nIt arrives in version 1.2.", {}), false],
	]:
		var card := U.btn("", md[5], "Accent" if md[0] == "NewLifeBtn" else "Primary")
		card.name = md[0]
		card.custom_minimum_size = Vector2(0, 150)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = "%s: %s" % [md[2], md[3]]
		var cv := U.vb(2)
		cv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ci := U.lbl(md[1], "Emoji", 44)
		ci.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ci.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(ci)
		var cn := U.lbl(md[2], "Bold", 20)
		cn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(cn)
		var cd := U.lbl(md[3], "Dim", 12, true)
		cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(cd)
		card.add_child(cv)
		if not md[4]:
			card.modulate = Color(1, 1, 1, 0.62)
		modes_row.add_child(card)
	var sep := HSeparator.new()
	bv.add_child(sep)
	for item in [["⏯️", "Continue Life", _continue_life, "ContinueBtn"], ["📂", "Your Lives", func(): SP.show_lives(), "LivesBtn"], ["🎁", "Daily Heirloom", func(): SP.show_heirloom(), "HeirBtn"], ["🏆", "Trophy Room", _show_trophies, "TrophyBtn"], ["🎯", "Missions", _show_missions, "MissionBtn"], ["⭐", "Star Shop", _show_star_shop, "StarBtn"], ["⚙️", "Settings", _show_settings_popup, ""], ["🎨", "Theme", _cycle_theme_title, "ThemeBtn"], ["🪦", "Graveyard", func(): _open_graveyard(), ""], ["🚪", "Quit", func(): get_tree().quit(), ""]]:
		var b := U.icon_btn(item[0], item[1], item[2], "Row", false, 24, 18)
		b.custom_minimum_size = Vector2(0, 52)
		if item[3] != "":
			b.name = item[3]
		bv.add_child(b)
	return c


func _refresh_title() -> void:
	var t: Control = screens["title"]
	var cont := t.find_child("ContinueBtn", true, false) as Button
	if cont:
		cont.disabled = not SaveManager.has_save()
		var ls := SaveManager.latest_slot()
		var lc: Dictionary = SaveManager.card(ls) if ls > 0 else {}
		cont.get_meta("label").text = "Continue Life" + (("  ·  %s, %d" % [lc.get("name", ""), int(lc.get("age", 0))]) if not lc.is_empty() and lc.get("alive", false) else "")
	var lb := t.find_child("LivesBtn", true, false) as Button
	if lb:
		lb.get_meta("label").text = "Your Lives · %d / %d" % [SaveManager.cards().size(), SaveManager.SLOTS]
	var hb := t.find_child("HeirBtn", true, false) as Button
	if hb:
		hb.get_meta("label").text = "Daily Heirloom" + ("  ·  ready to open!" if Goals.daily_available() else "  ·  next in " + Goals.fmt_left(Goals.seconds_left("daily")))
	var tb := t.find_child("ThemeBtn", true, false) as Button
	if tb:
		tb.get_meta("label").text = "Theme: " + ThemeManager.LABELS[ThemeManager.current]
	if cont:
		cont.modulate = Color(1, 1, 1, 1.0 if SaveManager.has_save() else 0.45)
	var trb := t.find_child("TrophyBtn", true, false) as Button
	if trb:
		trb.get_meta("label").text = "Trophy Room · %d / %d" % [Meta.meta["goals"]["ach"].size(), Goals.achievements.size()]
	var msb := t.find_child("MissionBtn", true, false) as Button
	if msb:
		var ready := Goals.unclaimed_count()
		msb.get_meta("label").text = "Missions" + ("  ·  %d ready to claim!" % ready if ready > 0 else "  ·  daily resets in " + Goals.fmt_left(Goals.seconds_left("daily")))
	var stb := t.find_child("StarBtn", true, false) as Button
	if stb:
		stb.get_meta("label").text = "Star Shop · ⭐ %d" % Goals.stars()


func _cycle_theme_title() -> void:
	_set_theme(ThemeManager.next_theme())


func _set_theme(key: String) -> void:
	GameState.settings["theme"] = key
	SaveManager.save_settings()
	ThemeManager.apply(key)


func _continue_life() -> void:
	if SaveManager.has_save() and SaveManager.load_game():
		panel_stack.clear()
		last_stats.clear()
		last_money = int(GameState.player.get("money", 0))
		if GameState.player.get("alive", true):
			_show("game")
		else:
			_show("death")
			_fill_death(GameState.player.get("legacy", {}))


# ================================================================= PETS LIFE

var pn := {}


func _open_pet_setup(inherit: Dictionary = {}) -> void:
	pn = {"species": "dog", "origin": "loving", "gender": "female", "inherit": inherit}
	pn["name"] = ContentDB.random_pet_name()
	var v := _open_popup(860)
	_event_header(v, "🐾", "Pets Life")
	_event_text(v, "You are the animal now. No money, no job, no calendar of your own: a nose, a belly, a few people and a number of years that is not long enough.")
	var sprow := HFlowContainer.new()
	sprow.alignment = FlowContainer.ALIGNMENT_CENTER
	sprow.add_theme_constant_override("h_separation", U.sp(8))
	v.add_child(sprow)
	var sp_btns := {}
	var odesc := U.lbl("", "Dim", 16, true)
	odesc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sdesc := U.lbl("", "Dim", 15, true)
	sdesc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var refresh_desc := func() -> void:
		var sd: Dictionary = Pets.SPECIES[pn["species"]]
		sdesc.text = "%s lives about %d–%d years." % [str(sd["name"]), int(sd["life"][0]), int(sd["life"][1])]
		odesc.text = str(Pets.ORIGINS[pn["origin"]]["desc"])
		for sk in sp_btns.keys():
			(sp_btns[sk] as Button).theme_type_variation = "Accent" if sk == pn["species"] else "Row"
	for sk in Pets.SPECIES.keys():
		var skk: String = sk
		var b := U.btn("%s  %s" % [Pets.SPECIES[sk]["icon"], Pets.SPECIES[sk]["name"]], func(): pn["species"] = skk; refresh_desc.call(), "Row")
		b.custom_minimum_size = Vector2(150, 52)
		b.focus_mode = UIKit.fm()
		sp_btns[sk] = b
		sprow.add_child(b)
	v.add_child(sdesc)
	var orow := U.hb(10)
	orow.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(orow)
	orow.add_child(U.lbl("Where it begins", "Dim", 16))
	var ob := OptionButton.new()
	ob.focus_mode = UIKit.fm()
	var okeys: Array = Pets.ORIGINS.keys()
	for ok in okeys:
		ob.add_item("%s  %s" % [Pets.ORIGINS[ok]["icon"], Pets.ORIGINS[ok]["name"]])
	ob.item_selected.connect(func(idx): pn["origin"] = okeys[idx]; refresh_desc.call())
	orow.add_child(ob)
	v.add_child(odesc)
	var nrow := U.hb(10)
	nrow.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(nrow)
	nrow.add_child(U.lbl("Name", "Dim", 16))
	var le := LineEdit.new()
	le.text = str(pn["name"])
	le.custom_minimum_size = Vector2(220, 0)
	le.focus_mode = UIKit.fm() if UIKit.fm() != Control.FOCUS_NONE else Control.FOCUS_CLICK
	le.text_changed.connect(func(t): pn["name"] = t)
	nrow.add_child(le)
	var dice := U.btn("🎲", func(): pn["name"] = ContentDB.random_pet_name(); le.text = str(pn["name"]), "Row")
	dice.tooltip_text = "Another name"
	nrow.add_child(dice)
	var gb := OptionButton.new()
	gb.focus_mode = UIKit.fm()
	gb.add_item("Female")
	gb.add_item("Male")
	gb.item_selected.connect(func(idx): pn["gender"] = "female" if idx == 0 else "male")
	nrow.add_child(gb)
	var go := U.btn("Be born", func(): _start_pet(), "Accent")
	go.custom_minimum_size = Vector2(0, 58)
	go.name = "Choice1"
	v.add_child(go)
	var cancel := U.btn("Cancel", _close_popup, "Row")
	cancel.name = "OkButton"
	v.add_child(cancel)
	refresh_desc.call()


func _start_pet() -> void:
	popup_open = false
	overlay.visible = false
	var nm := str(pn.get("name", "")).strip_edges()
	if nm == "":
		nm = ContentDB.random_pet_name()
	var opts := {"first": nm, "last": "", "gender": pn["gender"], "country": ContentDB.countries[randi() % ContentDB.countries.size()]["id"], "face": 0,
		"life_path": "pet", "keep_family": true, "species": pn["species"], "origin": pn["origin"], "inherit": pn.get("inherit", {}),
		"modifiers": [], "difficulty": "real", "boons": [], "challenge": ""}
	if not SaveManager.begin_new_life():
		_show_info("💾", "No free save slot", SaveManager.last_error, {})
		return
	GameState.new_life(opts)
	panel_stack.clear()
	last_stats.clear()
	SaveManager.save_game()
	_show("game")


# ================================================================= NEW LIFE

func _open_new_life() -> void:
	nl = {
		"gender": "male", "country": "us", "face": 0, "mode": "standard",
		"stats": {"happiness": 75, "health": 85, "smarts": 55, "looks": 55, "stress": 10},
		"era": 1970,
	}
	nl["first"] = ContentDB.random_first("male", "us")
	nl["last"] = ContentDB.random_last("us")
	var tr: Array = ContentDB.trait_names()
	tr.shuffle()
	nl["t1"] = tr[0]
	nl["t2"] = tr[1]
	var fresh := _build_new_life()
	var old: Control = screens["new"]
	fresh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	old.get_parent().add_child(fresh)
	old.queue_free()
	screens["new"] = fresh
	_show("new")


func _build_new_life() -> Control:
	var c := CenterContainer.new()
	if nl.is_empty():
		return c
	var outer := U.card()
	outer.custom_minimum_size = Vector2(1120, 0)
	c.add_child(outer)
	var v := U.vb(14)
	outer.add_child(v)
	var head := U.hb()
	head.add_child(U.btn("‹", func(): _show("title"), "Flat"))
	var ttl := U.lbl("New Life", "Title")
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(ttl)
	head.add_child(U.btn("🎲 Random", _randomize_new_life, "Row"))
	v.add_child(head)

	var cols := U.hb(28)
	v.add_child(cols)
	var left := U.vb(10)
	left.custom_minimum_size = Vector2(330, 0)
	cols.add_child(left)
	var right := U.vb(10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)

	left.add_child(U.lbl("Your Character", "Bold"))
	var pr := U.hb(12)
	pr.alignment = BoxContainer.ALIGNMENT_CENTER
	pr.add_child(U.btn("‹", func(): _nl_face(-1), "Flat"))
	var port := U.card("Portrait")
	port.custom_minimum_size = Vector2(130, 130)
	var pl := U.lbl(U.face(nl["gender"], 20, nl["face"]), "Emoji", 80)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	port.add_child(pl)
	nl["portrait"] = pl
	pr.add_child(port)
	pr.add_child(U.btn("›", func(): _nl_face(1), "Flat"))
	left.add_child(pr)

	for field in [["First Name", "first"], ["Last Name", "last"]]:
		left.add_child(U.lbl(field[0], "Dim"))
		var h := U.hb(8)
		var le := LineEdit.new()
		le.text = nl[field[1]]
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.max_length = 24
		var key: String = field[1]
		le.text_changed.connect(func(t): nl[key] = t)
		h.add_child(le)
		h.add_child(U.btn("🎲", func(): _nl_reroll_name(key, le), "Row"))
		left.add_child(h)

	left.add_child(U.lbl("Gender", "Dim"))
	var gh := U.hb(8)
	var group := ButtonGroup.new()
	for gdef in [["male", "Male"], ["female", "Female"], ["nonbinary", "Non-Binary"]]:
		var gk: String = gdef[0]
		var gb := U.icon_btn(U.face(gdef[0], 20, nl["face"]), gdef[1], func(): _nl_gender(gk), "Toggle", true, 30, 16)
		gb.toggle_mode = true
		gb.button_group = group
		gb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gb.custom_minimum_size = Vector2(0, 84)
		gb.button_pressed = nl["gender"] == gdef[0]
		gh.add_child(gb)
	left.add_child(gh)

	right.add_child(U.lbl("Birthplace", "Dim"))
	var ob := OptionButton.new()
	ob.focus_mode = UIKit.fm()
	var i := 0
	for ctry in ContentDB.countries:
		ob.add_item("%s  %s" % [ctry.get("flag", ""), ctry["name"]])
		if ctry["id"] == nl["country"]:
			ob.select(i)
		i += 1
	ob.item_selected.connect(func(idx):
		nl["country"] = ContentDB.countries[idx]["id"]
		nl["region"] = ""
		_nl_fill_regions())
	right.add_child(ob)
	right.add_child(U.lbl("City", "Dim"))
	var rob := OptionButton.new()
	rob.focus_mode = UIKit.fm()
	nl["region_ob"] = rob
	var rdesc := U.lbl("", "Dim", 14, true)
	nl["region_desc"] = rdesc
	rob.item_selected.connect(func(idx):
		var rl := Places.regions(nl["country"])
		nl["region"] = "" if idx == 0 else rl[idx - 1]["id"]
		rdesc.text = "Somewhere in the country, chosen at birth." if idx == 0 else str(rl[idx - 1].get("blurb", "")))
	right.add_child(rob)
	right.add_child(rdesc)
	_nl_fill_regions()

	right.add_child(U.lbl("Traits", "Dim"))
	for tk in ["t1", "t2"]:
		var tob := OptionButton.new()
		tob.focus_mode = UIKit.fm()
		var j := 0
		for t in ContentDB.traits:
			tob.add_item("%s  %s — %s" % [t["icon"], t["name"], t["desc"]])
			if t["name"] == nl[tk]:
				tob.select(j)
			j += 1
		var tkey: String = tk
		tob.item_selected.connect(func(idx): nl[tkey] = ContentDB.traits[idx]["name"])
		right.add_child(tob)

	var pr2 := U.hb(12)
	right.add_child(pr2)
	var pcol := U.vb(6)
	pcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pr2.add_child(pcol)
	pcol.add_child(U.lbl("Life Path", "Dim"))
	nl["path"] = "human"
	pcol.add_child(U.lbl("Everyone starts ordinary.", "", 16, true))
	pcol.add_child(U.lbl("Crowns, covens, ships, Mars and worse are not chosen here. They find you, if the life you live goes anywhere near them — and you can still say no when they ask.", "Dim", 14, true))
	var mcol := U.vb(6)
	mcol.custom_minimum_size = Vector2(250, 0)
	pr2.add_child(mcol)
	mcol.add_child(U.lbl("Starting Stats", "Dim"))
	var sob := OptionButton.new()
	sob.focus_mode = UIKit.fm()
	var modes := [["standard", "🟢  Standard"], ["custom", "🎚️  Custom stats"], ["random", "🎲  Random everything"]]
	for mi in range(modes.size()):
		sob.add_item(modes[mi][1])
		if modes[mi][0] == nl["mode"]:
			sob.select(mi)
	sob.item_selected.connect(func(idx): _nl_mode(modes[idx][0]))
	mcol.add_child(sob)
	var sliders := U.vb(4)
	sliders.visible = nl["mode"] == "custom"
	nl["sliders"] = sliders
	for sk in ["happiness", "health", "smarts", "looks"]:
		var sh := U.hb(8)
		var sl := U.lbl("%s %s" % [U.STAT_ICONS[sk], U.STAT_NAMES[sk]], "", 16)
		sl.custom_minimum_size = Vector2(140, 0)
		sh.add_child(sl)
		var s := HSlider.new()
		s.min_value = 5
		s.max_value = 100
		s.value = nl["stats"][sk]
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.focus_mode = UIKit.fm()
		var vl := U.lbl(str(int(s.value)), "Dim")
		vl.custom_minimum_size = Vector2(40, 0)
		var skey: String = sk
		s.value_changed.connect(func(val): nl["stats"][skey] = int(val); vl.text = str(int(val)))
		sh.add_child(s)
		sh.add_child(vl)
		sliders.add_child(sh)
	right.add_child(sliders)

	var extra := U.hb(28)
	v.add_child(extra)
	var modbox := U.vb(6)
	modbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extra.add_child(modbox)
	modbox.add_child(U.lbl("Life Modifiers (optional · lives using them are tagged Modified)", "Dim"))
	var mflow := HFlowContainer.new()
	mflow.add_theme_constant_override("h_separation", U.sp(8))
	mflow.add_theme_constant_override("v_separation", U.sp(8))
	modbox.add_child(mflow)
	if not nl.has("mods"):
		nl["mods"] = []
	for mk in Meta.MODIFIERS.keys():
		var md: Dictionary = Meta.MODIFIERS[mk]
		var mb := Button.new()
		mb.theme_type_variation = "Toggle"
		mb.toggle_mode = true
		mb.focus_mode = UIKit.fm()
		mb.text = "%s %s" % [md["icon"], md["name"]]
		mb.tooltip_text = md["desc"]
		mb.button_pressed = nl["mods"].has(mk)
		var mkey: String = mk
		mb.toggled.connect(_nl_toggle_mod.bind(mkey))
		mflow.add_child(mb)
	var chbox := U.vb(6)
	chbox.custom_minimum_size = Vector2(300, 0)
	extra.add_child(chbox)
	chbox.add_child(U.lbl("Challenge (optional)", "Dim"))
	var cob := OptionButton.new()
	cob.focus_mode = UIKit.fm()
	cob.add_item("None")
	for ch in Meta.challenges:
		var done := "✓ " if Meta.meta["challenges_done"].has(ch["id"]) else ""
		cob.add_item("%s%s %s" % [done, ch["icon"], ch["name"]])
	cob.selected = 0
	if not nl.has("challenge"):
		nl["challenge"] = ""
	for ci in range(Meta.challenges.size()):
		if Meta.challenges[ci]["id"] == nl["challenge"]:
			cob.selected = ci + 1
	var cdesc := U.lbl("", "Dim", 14, true)
	cob.item_selected.connect(_nl_pick_challenge.bind(cdesc))
	chbox.add_child(cob)
	chbox.add_child(cdesc)
	chbox.add_child(U.lbl("Difficulty", "Dim"))
	var dob := OptionButton.new()
	dob.focus_mode = UIKit.fm()
	var dkeys: Array = Grit.DIFFICULTY.keys()
	if not nl.has("difficulty"):
		nl["difficulty"] = "real"
	for di in range(dkeys.size()):
		var dd: Dictionary = Grit.DIFFICULTY[dkeys[di]]
		dob.add_item("%s %s%s" % [dd["icon"], dd["name"], "  (default)" if dkeys[di] == "real" else ""])
		if dkeys[di] == nl["difficulty"]:
			dob.select(di)
	var ddesc := U.lbl(Grit.DIFFICULTY[nl["difficulty"]]["desc"], "Dim", 14, true)
	dob.item_selected.connect(func(idx): nl["difficulty"] = dkeys[idx]; ddesc.text = Grit.DIFFICULTY[dkeys[idx]]["desc"])
	chbox.add_child(dob)
	chbox.add_child(ddesc)
	var owned: Array = Grit.BOONS.keys().filter(func(b): return Goals.owns_boon(b))
	if not nl.has("boons"):
		nl["boons"] = []
	var boonbox := U.vb(6)
	boonbox.custom_minimum_size = Vector2(250, 0)
	extra.add_child(boonbox)
	extra.move_child(boonbox, 1)
	boonbox.add_child(U.lbl("Legacy Boons (earned with ⭐)", "Dim"))
	if owned.is_empty():
		boonbox.add_child(U.lbl("Earn Stars from achievements and missions, then buy boons in the Star Shop.", "Dim", 14, true))
	var bflow := HFlowContainer.new()
	bflow.add_theme_constant_override("h_separation", U.sp(8))
	bflow.add_theme_constant_override("v_separation", U.sp(8))
	boonbox.add_child(bflow)
	for bk in owned:
		var bd: Dictionary = Grit.BOONS[bk]
		var bb := Button.new()
		bb.theme_type_variation = "Toggle"
		bb.toggle_mode = true
		bb.focus_mode = UIKit.fm()
		bb.text = "%s %s" % [bd["icon"], bd["name"]]
		bb.tooltip_text = bd["desc"]
		bb.button_pressed = nl["boons"].has(bk)
		var bkey: String = bk
		bb.toggled.connect(_nl_toggle_boon.bind(bkey))
		bflow.add_child(bb)
	var start := U.btn("Start Life", _start_life, "Accent")
	start.custom_minimum_size = Vector2(0, 64)
	v.add_child(start)
	return c


func _nl_toggle_mod(on: bool, key: String) -> void:
	if on and not nl["mods"].has(key):
		nl["mods"].append(key)
	elif not on:
		nl["mods"].erase(key)


func _nl_toggle_boon(on: bool, key: String) -> void:
	if on and not nl["boons"].has(key):
		nl["boons"].append(key)
	elif not on:
		nl["boons"].erase(key)


func _nl_pick_challenge(idx: int, desc: Label) -> void:
	nl["challenge"] = "" if idx == 0 else Meta.challenges[idx - 1]["id"]
	desc.text = "" if idx == 0 else Meta.challenges[idx - 1]["desc"]


func _nl_face(d: int) -> void:
	nl["face"] = (int(nl["face"]) + d + 5) % 5
	nl["portrait"].text = U.face(nl["gender"], 20, nl["face"])


func _nl_gender(gk: String) -> void:
	nl["gender"] = gk
	nl["portrait"].text = U.face(gk, 20, nl["face"])


func _nl_fill_regions() -> void:
	var rob: OptionButton = nl.get("region_ob")
	if rob == null or not is_instance_valid(rob):
		return
	rob.clear()
	rob.add_item("🎲  Anywhere (random)")
	var sel := 0
	var rl := Places.regions(nl["country"])
	for ri in range(rl.size()):
		var r: Dictionary = rl[ri]
		rob.add_item("%s%s" % [r["city"], (", " + r["name"]) if r["name"] != r["city"] else ""])
		if r["id"] == nl.get("region", ""):
			sel = ri + 1
	rob.select(sel)
	nl["region_desc"].text = "Somewhere in the country, chosen at birth." if sel == 0 else str(rl[sel - 1].get("blurb", ""))


func _nl_mode(mk: String) -> void:
	nl["mode"] = mk
	nl["sliders"].visible = mk == "custom"


func _nl_reroll_name(key: String, le: LineEdit) -> void:
	if key == "first":
		nl["first"] = ContentDB.random_first(nl["gender"], nl["country"])
	else:
		nl["last"] = ContentDB.random_last(nl["country"])
	le.text = nl[key]


func _randomize_new_life() -> void:
	var gs := ["male", "female", "nonbinary"]
	nl["gender"] = gs[randi() % 3] if randf() < 0.15 else gs[randi() % 2]
	nl["country"] = ContentDB.countries[randi() % ContentDB.countries.size()]["id"]
	var keep := nl.duplicate()
	_open_new_life()
	nl["gender"] = keep["gender"]
	nl["country"] = keep["country"]
	nl["face"] = randi() % 5
	nl["first"] = ContentDB.random_first(nl["gender"], nl["country"])
	nl["last"] = ContentDB.random_last(nl["country"])
	var fresh := _build_new_life()
	var old: Control = screens["new"]
	fresh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	old.get_parent().add_child(fresh)
	old.queue_free()
	screens["new"] = fresh
	_show("new")


func _start_life() -> void:
	var opts := {}
	if nl["mode"] == "random":
		var gs := ["male", "female"]
		var gk: String = gs[randi() % 2]
		var ck: String = ContentDB.countries[randi() % ContentDB.countries.size()]["id"]
		opts = {"gender": gk, "country": ck, "face": randi() % 5}
	else:
		var first: String = str(nl["first"]).strip_edges()
		var last: String = str(nl["last"]).strip_edges()
		if first == "":
			first = ContentDB.random_first(nl["gender"], nl["country"])
		if last == "":
			last = ContentDB.random_last(nl["country"])
		opts = {"first": first, "last": last, "gender": nl["gender"], "country": nl["country"], "face": nl["face"]}
		var tr: Array = [nl["t1"]]
		if nl["t2"] != nl["t1"]:
			tr.append(nl["t2"])
		opts["traits"] = tr
		if nl["mode"] == "custom":
			opts["stats"] = nl["stats"].duplicate()
	opts["modifiers"] = nl.get("mods", []).duplicate()
	opts["difficulty"] = nl.get("difficulty", "real")
	opts["boons"] = nl.get("boons", []).duplicate()
	opts["challenge"] = nl.get("challenge", "")
	opts["life_path"] = nl.get("path", "human")
	opts["era"] = int(nl.get("era", 1970))
	opts["region"] = nl.get("region", "") if nl["mode"] != "random" else ""
	if opts["challenge"] != "":
		Meta.apply_challenge_start(opts["challenge"], opts)
	if not SaveManager.begin_new_life():
		_show_info("💾", "No free save slot", SaveManager.last_error, {})
		return
	GameState.new_life(opts)
	panel_stack.clear()
	SaveManager.save_game()
	_show("game")


# ================================================================= GAME SCREEN

func _build_game() -> Control:
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 22)
	var h := U.hb(22)
	m.add_child(h)

	# ---- left column
	var left := U.vb(16)
	left.custom_minimum_size = Vector2(470, 0)
	g["left_col"] = left
	h.add_child(left)
	var head := U.card()
	var hh := U.hb(16)
	head.add_child(hh)
	var port := U.card("Portrait")
	port.custom_minimum_size = Vector2(118, 118)
	var pl := U.lbl("👶", "Emoji", 72)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	port.add_child(pl)
	g["portrait"] = pl
	hh.add_child(port)
	var nv := U.vb(2)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	var nm := U.lbl("", "Heading")
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	g["name"] = nm
	nv.add_child(nm)
	var occ := U.lbl("", "", 17)
	occ.add_theme_color_override("font_color", ThemeManager.c("primary").lightened(0.25))
	g["occ"] = occ
	nv.add_child(occ)
	var cty := U.lbl("", "Dim")
	cty.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cty.custom_minimum_size = Vector2(10, 0)
	g["country"] = cty
	nv.add_child(cty)
	hh.add_child(nv)
	var rv := U.vb(0)
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	var agel := U.lbl("", "AccentLabel")
	agel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	g["age"] = agel
	rv.add_child(agel)
	var money := U.lbl("", "Money")
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	g["money"] = money
	rv.add_child(money)
	var bal := U.lbl("Bank Balance", "Dim", 13)
	bal.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	g["bal_lbl"] = bal
	rv.add_child(bal)
	hh.add_child(rv)
	left.add_child(head)

	var stats := U.card()
	var sv := U.vb(14)
	stats.add_child(sv)
	g["bars"] = {}
	g["bar_lbl"] = {}
	for k in GameState.STAT_KEYS:
		var r := U.hb(10)
		var ic := U.lbl(U.STAT_ICONS[k], "Emoji", 22)
		ic.custom_minimum_size = Vector2(34, 0)
		r.add_child(ic)
		var l := U.lbl(U.STAT_NAMES[k], "", 18)
		l.custom_minimum_size = Vector2(110, 0)
		r.add_child(l)
		g["bar_lbl"][k] = [ic, l]
		var b := U.bar(50, ThemeManager.c("good"), 24)
		r.add_child(b)
		var pct := U.lbl("50%", "Bold", 16)
		pct.custom_minimum_size = Vector2(52, 0)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(pct)
		g["bars"][k] = [b, pct]
		sv.add_child(r)
	# Anything the player is progressing through gets a bar here, so progress is
	# visible at all times rather than buried in a sub-menu.
	var tracks := U.vb(8)
	g["tracks"] = tracks
	sv.add_child(tracks)
	left.add_child(stats)

	var info := U.card()
	var iv := U.vb(10)
	info.add_child(iv)
	var traits := HFlowContainer.new()
	traits.add_theme_constant_override("h_separation", U.sp(8))
	traits.add_theme_constant_override("v_separation", U.sp(8))
	g["traits"] = traits
	iv.add_child(traits)
	var home_icons := HFlowContainer.new()
	home_icons.add_theme_constant_override("h_separation", U.sp(6))
	g["home_icons"] = home_icons
	iv.add_child(home_icons)
	var home := U.lbl("", "Dim", 16, true)
	g["home"] = home
	iv.add_child(home)
	var fin := U.lbl("", "Dim", 16, true)
	g["fin"] = fin
	iv.add_child(fin)
	var extra_l := U.lbl("", "", 16, true)
	g["extra"] = extra_l
	iv.add_child(extra_l)
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(info)

	# ---- center column
	var center := U.vb(16)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(center)
	var logc := U.card()
	logc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var logv := U.vb(4)
	logv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(logv)
	logc.add_child(sc)
	g["log"] = logv
	g["log_scroll"] = sc
	center.add_child(logc)

	var ageb := U.card()
	var av := U.vb(10)
	ageb.add_child(av)
	var ah := U.hb(20)
	ah.alignment = BoxContainer.ALIGNMENT_CENTER
	var qa := U.icon_btn("🎓", "School", func(): _quick_press(0), "Row", true, 34, 17)
	qa.custom_minimum_size = Vector2(150, 96)
	g["quick_left"] = qa
	ah.add_child(qa)
	var age_btn := U.btn("+\nAge", _age_up, "AgeButton")
	age_btn.custom_minimum_size = Vector2(140, 140)
	g["age_btn"] = age_btn
	ah.add_child(age_btn)
	var qb := U.icon_btn("💰", "Assets", func(): _quick_press(1), "Row", true, 34, 17)
	qb.custom_minimum_size = Vector2(150, 96)
	g["quick_right"] = qb
	ah.add_child(qb)
	av.add_child(ah)
	var th := U.hb(10)
	var tl := U.lbl("Time 12/12", "Dim", 15)
	tl.custom_minimum_size = Vector2(110, 0)
	g["time_lbl"] = tl
	th.add_child(tl)
	var tb := U.bar(100, ThemeManager.c("good"), 12)
	g["time_bar"] = tb
	th.add_child(tb)
	av.add_child(th)
	center.add_child(ageb)

	var tabs := U.card("TabStrip")
	var tbh := U.hb(6)
	tabs.add_child(tbh)
	g["tab_btns"] = []
	var tab_i := 0
	for t in _tab_specs():
		var ti := tab_i
		var b := U.icon_btn(t[0], t[1], func(): _tab_press(ti), "Tab", true, 30, 15)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 76)
		if ti == 4:
			g["life_tab"] = b
		g["tab_btns"].append(b)
		tbh.add_child(b)
		tab_i += 1
	center.add_child(tabs)

	# ---- right column
	var right := U.card()
	right.custom_minimum_size = Vector2(540, 0)
	g["right_col"] = right
	var rvb := U.vb(14)
	right.add_child(rvb)
	var rh := U.hb(10)
	var back := U.btn("‹", _panel_back, "Flat")
	back.add_theme_font_size_override("font_size", 30)
	g["back"] = back
	rh.add_child(back)
	var picon := U.lbl("", "Emoji", 30)
	g["panel_icon"] = picon
	rh.add_child(picon)
	var ptitle := U.lbl("", "Title")
	ptitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g["panel_title"] = ptitle
	rh.add_child(ptitle)
	rvb.add_child(rh)
	var psc := ScrollContainer.new()
	psc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	psc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var pv := U.vb(10)
	pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	psc.add_child(pv)
	rvb.add_child(psc)
	g["panel"] = pv
	g["panel_scroll"] = psc
	h.add_child(right)
	return m


## Every progression the player is currently inside gets a bar on the main
## screen. Before this, fame, a career skill, a rank ladder and a supernatural
## meter were all numbers hidden behind a sub-menu, so there was no way to see
## you were getting somewhere without going looking.
func _refresh_tracks() -> void:
	if not g.has("tracks") or not is_instance_valid(g["tracks"]):
		return
	var box: VBoxContainer = g["tracks"]
	U.clear(box)
	var p := GameState.player

	# --- fame, once there is any
	var fame := float(p.get("fame", 0.0))
	if fame >= 1.0:
		var fw := "Recognised" if fame < 40.0 else ("Well known" if fame < 70.0 else ("Famous" if fame < 88.0 else "A household name"))
		box.add_child(U.track("⭐", "Fame", fame, 100.0, ThemeManager.c("gold"), "%d%% · %s" % [int(fame), fw]))

	# --- the career ladder, if one is running
	if not p.get("career", {}).is_empty():
		var c: Dictionary = p["career"]
		var cd: Dictionary = Careers.CAREERS[c["id"]]
		var ranks: Array = cd["ranks"]
		var ri := clampi(int(c.get("rank", 0)), 0, ranks.size() - 1)
		box.add_child(U.track(str(cd["icon"]), str(cd["skill"]).capitalize(), float(c.get("skill", 0.0)), 100.0,
			ThemeManager.c("accent"), "%d%%" % int(c.get("skill", 0.0))))
		box.add_child(U.track("🏅", "Rank", float(ri + 1), float(ranks.size()),
			ThemeManager.c("good"), "%d/%d" % [ri + 1, ranks.size()]))
		if c.has("approval") and c.get("in_office", false):
			box.add_child(U.track("🗳️", "Approval", float(c["approval"]), 100.0,
				ThemeManager.c("good") if float(c["approval"]) >= 50.0 else ThemeManager.c("bad"),
				"%d%%" % int(c["approval"])))

	# --- an ordinary job's performance, which decides promotions
	if GameState.has_job():
		var j: Dictionary = p["job"]
		box.add_child(U.track("💼", "Performance", float(j.get("performance", 50.0)), 100.0,
			ThemeManager.bar_color("happiness", float(j.get("performance", 50.0))),
			"%d%%" % int(j.get("performance", 50.0))))

	# --- school, while you are in it
	var edu: Dictionary = p.get("education", {})
	if str(edu.get("stage", "none")) not in ["none", "done"]:
		box.add_child(U.track("🎓", "School", float(edu.get("performance", 50.0)), 100.0,
			ThemeManager.bar_color("smarts", float(edu.get("performance", 50.0))),
			"%d%%" % int(edu.get("performance", 50.0))))

	# --- whatever the current life path meters
	if Lives.kind() != "human":
		for li in Lives.status_lines():
			if str(li[1]) != "":
				box.add_child(U.track("●", str(li[0]), float(li[1]), 100.0,
					ThemeManager.c("accent"), "%d%%" % int(float(li[1]))))

	# --- how much the law wants you
	if Wanted.stars() > 0:
		box.add_child(U.track("🚨", "Wanted", float(Wanted.raw()), float(Wanted.MAX_STARS),
			ThemeManager.c("bad"), "%s %s" % [Wanted.display(), Wanted.level_name()]))


func _refresh_side_pet() -> void:
	var p := GameState.player
	var l := Pets.L()
	g["portrait"].text = Pets.portrait()
	g["name"].text = str(p["first"]) + ("  " + str(p["badge"]) if str(p.get("badge", "")) != "" else "")
	g["occ"].text = Pets.header_occ()
	g["country"].text = Pets.header_sub()
	if g.has("life_tab") and is_instance_valid(g["life_tab"]):
		g["life_tab"].visible = true
	g["age"].text = "Age %d" % int(p["age"])
	var hun := float(l.get("hunger", 50))
	g["money"].text = "%d%%" % int(hun)
	g["money"].add_theme_color_override("font_color", ThemeManager.c("bad") if hun < 25.0 else (ThemeManager.c("warn") if hun > 88.0 else ThemeManager.c("good")))
	for k in GameState.STAT_KEYS:
		var v := GameState.stat(k)
		var pair: Array = g["bars"][k]
		var prev := float(last_stats.get(k, v))
		var diff := int(round(v)) - int(round(prev))
		VFX.bar_to(pair[0], v, ThemeManager.bar_color(k, v), diff != 0)
		pair[1].text = "%d%%" % int(round(v))
		if diff != 0 and abs(diff) >= 1 and not last_stats.is_empty():
			var good := diff > 0 if k != "stress" else diff < 0
			VFX.float_number(fx_layer, pair[1], "%s%d" % ["+" if diff > 0 else "", diff], ThemeManager.c("good") if good else ThemeManager.c("bad"))
		last_stats[k] = v
	var box: VBoxContainer = g["tracks"]
	U.clear(box)
	for tr in [["💞", "Bond", "bond"], ["📍", "Territory", "territory"], ["🎓", "Obedience", "obedience"], ["👃", "Instinct", "instinct"], ["🏡", "Belonging", "belonging"]]:
		var v2 := float(l.get(str(tr[2]), 0))
		box.add_child(U.track(str(tr[0]), str(tr[1]), v2, 100.0, ThemeManager.c("accent"), "%d%%" % int(v2)))
	U.clear(g["traits"])
	for t in p["traits"]:
		var info: Array = Pets.TRAIT_INFO.get(str(t), ["•", ""])
		var chip := U.card("Chip")
		chip.add_child(U.lbl("%s %s" % [info[0], t], "", 15))
		chip.tooltip_text = str(info[1])
		g["traits"].add_child(chip)
	g["home"].text = Pets.home_text()
	g["fin"].text = Pets.fin_text()
	var extra := ""
	var arc: Array = Arcs.status_line()
	if not arc.is_empty():
		extra += str(arc[0]) + "\n"
	var tl: Array = l.get("tricks", [])
	if not tl.is_empty():
		extra += "🎓 " + ", ".join(tl.slice(0, 4)) + ("…" if tl.size() > 4 else "") + "\n"
	g["extra"].text = extra.strip_edges()
	var tleft: int = p["time_left"]
	g["time_lbl"].text = "Time %d/%d" % [tleft, GameState.TIME_PER_YEAR]
	g["time_bar"].value = 100.0 * tleft / GameState.TIME_PER_YEAR
	U.set_bar_color(g["time_bar"], ThemeManager.c("good") if tleft > 3 else ThemeManager.c("warn"))
	g["age_btn"].disabled = not p["alive"]
	VFX.pulse(g["age_btn"], p["alive"] and not popup_open and int(p["time_left"]) >= GameState.TIME_PER_YEAR - 1)


func _refresh_side() -> void:
	if not GameState.has_life() or g.is_empty() or not is_instance_valid(g.get("name")):
		return
	var p := GameState.player
	_apply_mode_chrome()
	if Pets.active():
		_refresh_side_pet()
		return
	g["portrait"].text = U.face(p["gender"], int(p["age"]), int(p["face"])) if p["alive"] else "😇"
	g["name"].text = "%s %s" % [p["first"], p["last"]]
	g["occ"].text = GameState.occupation_label()
	var c := ContentDB.country(p["country"])
	g["country"].text = "%s %s  ·  %s  ·  %s  ·  Gen %d" % [c.get("flag", ""), Places.region().get("city", c["name"]), c["name"], GameState.life_stage(), int(p["generation"])] + ("  ·  🎖️ " + Goals.title_name() if Goals.title_name() != "" else "")
	if g.has("life_tab") and is_instance_valid(g["life_tab"]):
		var lk := Lives.kind()
		g["life_tab"].visible = lk != "human"
		if lk != "human":
			g["life_tab"].get_meta("icon").text = Lives.TYPES[lk]["icon"]
			g["life_tab"].get_meta("label").text = Lives.TYPES[lk]["name"]
	g["age"].text = "Age %d" % int(p["age"])
	var money_now := int(p["money"])
	VFX.roll_money(g["money"], last_money, money_now)
	if money_now != last_money and last_money != 0:
		VFX.float_number(fx_layer, g["money"], "%s%s" % ["+" if money_now > last_money else "", GameState.fmt_money(money_now - last_money)], ThemeManager.c("good") if money_now > last_money else ThemeManager.c("bad"))
	last_money = money_now
	g["money"].add_theme_color_override("font_color", ThemeManager.c("good") if int(p["money"]) >= 0 else ThemeManager.c("bad"))
	for k in GameState.STAT_KEYS:
		var v := GameState.stat(k)
		var pair: Array = g["bars"][k]
		var prev := float(last_stats.get(k, v))
		var diff := int(round(v)) - int(round(prev))
		VFX.bar_to(pair[0], v, ThemeManager.bar_color(k, v), diff != 0)
		pair[1].text = "%d%%" % int(round(v))
		if diff != 0 and abs(diff) >= 1 and not last_stats.is_empty():
			var good := diff > 0 if k != "stress" else diff < 0
			VFX.float_number(fx_layer, pair[1], "%s%d" % ["+" if diff > 0 else "", diff], ThemeManager.c("good") if good else ThemeManager.c("bad"))
		last_stats[k] = v
	_refresh_tracks()
	U.clear(g["traits"])
	for t in p["traits"]:
		var info := ContentDB.trait_info(t)
		var chip := U.card("Chip")
		chip.add_child(U.lbl("%s %s" % [info["icon"], t], "", 15))
		chip.tooltip_text = info["desc"]
		g["traits"].add_child(chip)
	var home_txt: String = GameState.HOUSING[p["housing"]]["name"]
	if p["car"] != "":
		home_txt += "   ·   " + GameState.CARS[p["car"]]["name"]
	if g.has("home_icons") and is_instance_valid(g["home_icons"]):
		U.clear(g["home_icons"])
		g["home_icons"].add_child(Icons.make(Icons.for_housing(str(p["housing"]), int(p.get("house_value", 0))), 34.0))
		if str(p["car"]) != "":
			g["home_icons"].add_child(Icons.make(Icons.for_car(str(p["car"])), 34.0))
		var props: Array = p.get("properties", [])
		for pr in props.slice(0, 4):
			g["home_icons"].add_child(Icons.make(Icons.for_property(str(pr.get("type", "")), int(pr.get("value", 0))), 30.0))
	if p["partner"] != "" and GameState.npcs.has(p["partner"]):
		home_txt += "\n❤️ %s: %s" % [GameState.relation_label(p["partner"]), GameState.full_name(p["partner"])]
	if p["illness"] != "":
		home_txt += "\n🤒 Dealing with " + p["illness"]
	if GameState.in_prison():
		home_txt += "\n⛓️ In prison: %d year%s left" % [int(p["prison"]), "" if int(p["prison"]) == 1 else "s"]
	g["home"].text = home_txt
	var fin := "Last year: earned %s · spent %s" % [GameState.fmt_money(int(p["last_income"])), GameState.fmt_money(int(p["last_expenses"]))]
	if int(p["loan"]) > 0:
		fin += "\nStudent loans: " + GameState.fmt_money(int(p["loan"]))
	if int(p["mortgage"]) > 0:
		fin += "\nMortgage left: " + GameState.fmt_money(int(p["mortgage"]))
	fin += "\nNet worth: " + GameState.fmt_money(GameState.net_worth())
	g["fin"].text = fin
	var extra := ""
	if Lives.kind() != "human":
		var sl: Array = Lives.status_lines()
		for li in range(mini(3, sl.size())):
			extra += (str(sl[li][0]) + (" %d%%" % int(sl[li][1]) if str(sl[li][1]) != "" else "")) + "\n"
	var wl := World.active_list()
	if not wl.is_empty():
		extra += "🌍 " + ", ".join(wl.map(func(w): return World.EVENTS[w]["icon"] + " " + World.EVENTS[w]["name"])) + "\n"
	if not p["career"].is_empty():
		extra += "%s %s" % [Careers.CAREERS[p["career"]["id"]]["icon"], Careers.title()]
		var cd: Dictionary = Careers.CAREERS[p["career"]["id"]]
		extra += " · %s %d" % [cd["skill"], int(p["career"]["skill"])]
		if p["career"].has("approval") and p["career"].get("in_office", false):
			extra += " · Approval %d%%" % int(p["career"]["approval"])

		extra += "\n"
	if p.get("difficulty", "real") != "real":
		extra += "%s %s difficulty\n" % [Grit.DIFFICULTY[p["difficulty"]]["icon"], Grit.DIFFICULTY[p["difficulty"]]["name"]]
	if not p.get("scars", []).is_empty():
		extra += "🩹 " + ", ".join(p["scars"].map(func(sid): return Grit.SCARS[sid]["icon"] + " " + Grit.SCARS[sid]["name"])) + "\n"
	var hab := Grit.active_habits()
	if not hab.is_empty():
		extra += "⛓️ Habits: " + ", ".join(hab.map(func(hid): return Grit.HABITS[hid]["icon"] + " " + Grit.HABITS[hid]["name"])) + "\n"
	if int(p["age"]) >= 18:
		extra += "💳 Credit %d (%s)%s\n" % [Grit.credit(), Grit.credit_label(), "  ·  📉 bankrupt" if int(p.get("bankrupt_until", -1)) > int(p["age"]) else ""]
	var gh := Grit.grudge_holders().size()
	if gh > 0:
		extra += "😠 %d %s holding a grudge\n" % [gh, "person is" if gh == 1 else "people are"]
	if p.get("nursing_home", false):
		extra += "🏥 Living in a nursing home\n"
	# Everything the player is currently carrying, in one place, so nothing that
	# needs attention is only discoverable by opening the right sub-menu.
	if str(p.get("illness", "")) != "":
		extra += "🤒 Ill: %s — see a doctor\n" % str(p["illness"]).capitalize()
	var sym: Array = Expansion.symptoms()
	if not sym.is_empty():
		extra += "❓ Unexplained symptoms: %s\n" % ", ".join(sym.map(func(x): return str(x).replace("_", " ")))
	var conds: Dictionary = p.get("medical", {}).get("conditions", {})
	if not conds.is_empty():
		extra += "❤️‍🩹 Ongoing: " + ", ".join(conds.keys().map(func(k): return str(Expansion.CONDITIONS.get(k, {}).get("name", k)))) + "\n"
	var injs: Dictionary = p.get("medical", {}).get("injuries", {})
	if not injs.is_empty():
		extra += "🩼 Injured: " + ", ".join(injs.keys().map(func(k): return str(k).replace("_", " "))) + "\n"
	var mh: Dictionary = p.get("medical", {}).get("mental", {})
	if not mh.is_empty():
		extra += "🧠 " + ", ".join(mh.keys().map(func(k): return str(Expansion.MENTAL.get(k, {}).get("name", k)))) + "\n"
	if int(p.get("age", 0)) - int(p.get("last_checkup_age", -99)) >= 4 and int(p.get("age", 0)) >= 18:
		extra += "🩺 Overdue a checkup\n"
	# Responsibilities: the things other people are waiting on.
	var duties: Array = []
	var kids := GameState.npcs_with("child")
	var young := 0
	for k in kids:
		if int(GameState.npc(k).get("age", 99)) < 18:
			young += 1
	if young > 0:
		duties.append("%d child%s at home" % [young, "" if young == 1 else "ren"])
	if not p.get("ambition", {}).get("pets", {}).get("business", {}).is_empty():
		duties.append("a pet business")
	var port: Array = p.get("ambition", {}).get("enterprise", {}).get("portfolio", [])
	if not port.is_empty():
		duties.append("%d compan%s" % [port.size(), "y" if port.size() == 1 else "ies"])
	var jst: Dictionary = p.get("ambition", {}).get("justice", {})
	if int(jst.get("probation", 0)) > 0:
		duties.append("probation for %d more year%s" % [int(jst["probation"]), "" if int(jst["probation"]) == 1 else "s"])
	if int(jst.get("parole", 0)) > 0:
		duties.append("parole for %d more year%s" % [int(jst["parole"]), "" if int(jst["parole"]) == 1 else "s"])
	var owed_out := 0
	for nid in GameState.npcs.keys():
		owed_out += int(GameState.npcs[nid].get("owes", 0))
	if owed_out > 0:
		duties.append("%s owed to me" % GameState.fmt_money(owed_out))
	if not duties.is_empty():
		extra += "📌 " + " · ".join(duties) + "\n"
	var pets := GameState.npcs_with("pet")
	var vet_due := 0
	for pid2 in pets:
		var pp: Dictionary = GameState.npc(pid2).get("pet_profile", {})
		if not pp.is_empty() and (float(pp.get("health", 100)) < 40.0 or int(p.get("age", 0)) >= int(pp.get("vet_due", 999))):
			vet_due += 1
	if vet_due > 0:
		extra += "🐾 %d pet%s needs the vet\n" % [vet_due, "" if vet_due == 1 else "s"]
	# Where this life started, which the player is told once and can always check.
	for ol in Origins.summary_lines():
		extra += "%s — %s\n" % [str(ol[0]), str(ol[1])]
	for wl2 in Wanted.summary_lines():
		extra += "%s — %s\n" % [str(wl2[0]), str(wl2[1])]
	for rl2 in Romance.summary_lines():
		extra += "%s — %s\n" % [str(rl2[0]), str(rl2[1])]
	for dl2 in Lending.summary_lines():
		extra += "%s — %s\n" % [str(dl2[0]), str(dl2[1])]
	for fl2 in Fights.summary_lines():
		extra += "%s — %s\n" % [str(fl2[0]), str(fl2[1])]
	if float(p.get("heat", 0)) >= 1:
		var ht := float(p["heat"])
		extra += "🚨 Heat %d%% · %s\n" % [int(ht), "the police are closing in" if ht >= 70 else "detectives are interested" if ht >= 35 else "a little attention"]
	if not p["business"].is_empty():
		extra += "%s %s · profit %s\n" % [Empires.INDUSTRIES[p["business"]["ind"]]["icon"], p["business"]["name"], GameState.fmt_money(int(p["business"]["profit"]))]
	if not p["cult"].is_empty():
		extra += "🛐 %s · %d members\n" % [p["cult"]["name"], int(p["cult"]["members"])]
	if not p["zoo"].is_empty():
		extra += "🦁 %s · %d animals\n" % [p["zoo"]["name"], Empires.zoo_care_load()]
	if float(p["fame"]) >= 1:
		extra += "⭐ Fame %d · %s followers%s\n" % [int(p["fame"]), Careers._fmt_big(Careers.followers()), " · Celebrity" if p["celebrity"] else ""]
	if p["modified"]:
		extra += "🧪 Modified life: " + ", ".join(p["modifiers"].map(func(k): return Meta.MODIFIERS[k]["name"])) + "\n"
	var chl: String = p.get("challenge", "")
	if chl != "":
		var cdef := Meta.challenge(chl)
		if not cdef.is_empty():
			extra += "\n%s Challenge: %s%s\n" % [cdef["icon"], cdef["name"], " ✓" if GameState.has_flag("challenge_done") else ""]
			for goal in cdef["goals"]:
				var gp := Meta.goal_progress(goal)
				extra += "   %s %s  (%s)\n" % ["✅" if gp[0] else "⬜", goal["label"], gp[1]]
	g["extra"].text = extra.strip_edges()
	g["name"].text = ("%s %s" % [p["first"], p["last"]]) + ("  " + p["badge"] if p.get("badge", "") != "" else "")
	_sync_life_theme()
	var tleft: int = p["time_left"]
	g["time_lbl"].text = "Time %d/%d" % [tleft, GameState.TIME_PER_YEAR]
	g["time_bar"].value = 100.0 * tleft / GameState.TIME_PER_YEAR
	U.set_bar_color(g["time_bar"], ThemeManager.c("good") if tleft > 3 else ThemeManager.c("warn"))
	var ql: Button = g["quick_left"]
	var qtxt := "Career"
	var qicon := "💼"
	if GameState.has_job():
		qtxt = "Work"
	elif int(p["age"]) >= 5 and (GameState.in_school() or GameState.in_university()):
		qtxt = "School"
		qicon = "🎓"
	ql.get_meta("icon").text = qicon
	ql.get_meta("label").text = qtxt
	g["age_btn"].disabled = not p["alive"]
	VFX.pulse(g["age_btn"], p["alive"] and not popup_open and int(p["time_left"]) >= GameState.TIME_PER_YEAR - 1)


# ---- log

func _rebuild_log() -> void:
	if not g.has("log"):
		return
	U.clear(g["log"])
	for y in GameState.log_years:
		_add_year_header(int(y["age"]))
		for line in y["lines"]:
			_add_log_line(line)
	_scroll_log()


func _add_year_header(age: int) -> void:
	var box: VBoxContainer = g["log"]
	if box.get_child_count() > 0:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 10)
		box.add_child(gap)
	var l := U.lbl("Age %d" % age if age > 0 else "Born", "AccentLabel")
	l.add_theme_color_override("font_color", ThemeManager.c("primary").lightened(0.3) if ThemeManager.current != "light" else ThemeManager.c("primary"))
	box.add_child(l)


func _add_log_line(text: String) -> void:
	var l := U.lbl(text, "", 18, true)
	var big := text.find("!") != -1
	if big:
		l.add_theme_color_override("font_color", ThemeManager.c("gold"))
	g["log"].add_child(l)
	VFX.fade_in(l)


func _on_year_started(age: int) -> void:
	if _current_screen() == "game":
		_add_year_header(age)
		Fx.play("page", 0.05)


func _on_log_added(_age: int, text: String) -> void:
	if _current_screen() == "game" and g.has("log") and is_instance_valid(g["log"]):
		_add_log_line(text)
		_scroll_log()


func _scroll_log() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if g.has("log_scroll") and is_instance_valid(g["log_scroll"]):
		var sc: ScrollContainer = g["log_scroll"]
		sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value)


# ---- age

func _age_up() -> void:
	if popup_open or not GameState.is_alive():
		return
	Fx.play("age")
	if g.has("age_btn") and is_instance_valid(g["age_btn"]):
		VFX.age_press(g["age_btn"], fx_layer)
	EventEngine.age_up()
	_refresh_side()
	_render_top_panel()
	_pump()


## Tab or an arrow key turns keyboard navigation on; a mouse click turns it off.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and UIKit.kb_mode:
		_set_kb_mode(false)
	elif event is InputEventKey and event.pressed and not event.echo and not UIKit.kb_mode:
		var k: int = event.keycode
		if k == KEY_TAB or k == KEY_UP or k == KEY_DOWN or k == KEY_LEFT or k == KEY_RIGHT:
			if _current_screen() == "game" and not mg_open:
				_set_kb_mode(true)
				get_viewport().set_input_as_handled()


func _set_kb_mode(on: bool) -> void:
	UIKit.kb_mode = on
	_apply_focus_mode(self, UIKit.fm())
	if on:
		_kb_focus_first()
	else:
		var fo := get_viewport().gui_get_focus_owner()
		if fo != null:
			fo.release_focus()


func _apply_focus_mode(n: Node, mode: int) -> void:
	if n is BaseButton or n is Slider:
		(n as Control).focus_mode = mode
	for ch in n.get_children():
		_apply_focus_mode(ch, mode)


## Put keyboard focus on the first thing in the open panel that can take it.
func _kb_focus_first() -> void:
	if not UIKit.kb_mode:
		return
	var root: Node = g["panel"] if g.has("panel") else self
	for b in root.find_children("*", "BaseButton", true, false):
		var bb := b as BaseButton
		if bb.is_visible_in_tree() and not bb.disabled:
			bb.grab_focus()
			return


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: int = event.keycode
	if mg_open:
		if not mg_playing and (k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE) and is_instance_valid(mg_default):
			mg_default.emit_signal("pressed")
			get_viewport().set_input_as_handled()
		return
	if popup_open:
		if k >= KEY_1 and k <= KEY_9:
			var btns: Array = overlay_box.find_children("Choice*", "Button", true, false)
			var idx := k - KEY_1
			if idx < btns.size() and not btns[idx].disabled:
				btns[idx].emit_signal("pressed")
		elif k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
			var ok := overlay_box.find_child("OkButton", true, false) as Button
			if ok:
				ok.emit_signal("pressed")
		get_viewport().set_input_as_handled()
		return
	if _current_screen() != "game":
		return
	match k:
		KEY_SPACE:
			_age_up()
		KEY_1, KEY_2, KEY_3, KEY_4:
			_tab_press(k - KEY_1)
		KEY_5:
			if Lives.kind() != "human":
				_tab_press(4)
			else:
				_tab_press(5)
		KEY_6:
			_tab_press(5)
		KEY_ESCAPE, KEY_BACKSPACE:
			_panel_back()
		_:
			return
	get_viewport().set_input_as_handled()


# ================================================================= RIGHT PANEL

## The six tabs are the same buttons in every mode; what they open is not.
func _tab_specs() -> Array:
	if Pets.active():
		return [
			["🐾", "Do", func(): MP.show("pet:home")],
			["🏠", "People", func(): MP.show("pet:house")],
			["🏅", "Calling", func(): MP.show("pet:calling")],
			["🌳", "World", func(): MP.show("pet:wild")],
			["🛤️", "Road", func(): MP.show("real:arc")],
			["⋯", "More", _panel_more_pet],
		]
	return [["🏃", "Activities", _panel_activities], ["❤️", "People", _panel_relationships], ["💼", "Work", _panel_occupation], ["💰", "Assets", _panel_assets], ["✨", "Life", LP.life_panel], ["⋯", "More", _panel_more]]


func _tab_press(i: int) -> void:
	var specs := _tab_specs()
	if i < 0 or i >= specs.size():
		return
	var cb: Callable = specs[i][2]
	_open_panel(cb, true)


func _quick_press(side: int) -> void:
	if Pets.active():
		_open_panel(func(): MP.show("pet:care" if side == 0 else "pet:play"), true)
		return
	_open_panel(_panel_occupation if side == 0 else _panel_assets, true)


func _apply_mode_chrome() -> void:
	var pet := Pets.active()
	var specs := _tab_specs()
	var btns: Array = g.get("tab_btns", [])
	for i in range(mini(btns.size(), specs.size())):
		var b: Button = btns[i]
		if not is_instance_valid(b):
			continue
		b.get_meta("icon").text = str(specs[i][0])
		b.get_meta("label").text = str(specs[i][1])
	for k in GameState.STAT_KEYS:
		var pair: Array = g["bar_lbl"][k]
		pair[0].text = str(Pets.SIDE_LABELS[k][0]) if pet else str(U.STAT_ICONS[k])
		pair[1].text = str(Pets.SIDE_LABELS[k][1]) if pet else str(U.STAT_NAMES[k])
	if g.has("bal_lbl") and is_instance_valid(g["bal_lbl"]):
		g["bal_lbl"].text = "Belly" if pet else "Bank Balance"
	if g.has("home_icons") and is_instance_valid(g["home_icons"]):
		g["home_icons"].visible = not pet
	if pet:
		var ql: Button = g["quick_left"]
		ql.get_meta("icon").text = "🥣"
		ql.get_meta("label").text = "Care"
		var qr: Button = g["quick_right"]
		qr.get_meta("icon").text = "🎾"
		qr.get_meta("label").text = "Play"
	else:
		var qr2: Button = g["quick_right"]
		qr2.get_meta("icon").text = "💰"
		qr2.get_meta("label").text = "Assets"


func _panel_more_pet() -> void:
	_panel_header("⋯", "More")
	var ready := Goals.unclaimed_count()
	_add(U.row("🎁", "Daily Heirloom", "Ready to open!" if Goals.daily_available() else "Next in " + Goals.fmt_left(Goals.seconds_left("daily")), func(): SP.show_heirloom()))
	_add(U.row("🎯", "Missions", ("%d ready to claim! · " % ready if ready > 0 else "") + "Daily, weekly and monthly goals", _show_missions))
	_add(U.row("🏆", "Trophy Room", "%d / %d achievements · ⭐ %d Stars" % [Meta.meta["goals"]["ach"].size(), Goals.achievements.size(), Goals.stars()], _show_trophies))
	_add(U.row("⭐", "Star Shop", "Titles and Legacy Boons", _show_star_shop))
	_add(U.row("🪦", "Graveyard", "Past lives and their stories", _open_graveyard))
	_add(U.row("⚙️", "Settings", "Sound, effects, motion, display", func(): _open_panel(_panel_settings)))
	_add(U.row("🎨", "Theme: " + ThemeManager.LABELS[ThemeManager.current], "Tap to switch", func(): _set_theme(ThemeManager.next_theme()), true, false))
	_add(U.row("📂", "Your Lives", "Switch to another saved life", func(): SaveManager.save_game(); SP.show_lives()))
	_add(U.row("💾", "Save & Exit", "Back to the main menu", func(): SaveManager.save_game(); _show("title"), true, false))
	_add(U.lbl("Keys: Space = a year passes · 1–6 = tabs · Esc = back", "Dim", 14, true))


func _open_panel(builder: Callable, reset: bool = false) -> void:
	if reset:
		panel_stack.clear()
	panel_stack.append(builder)
	_render_top_panel()


func _panel_back() -> void:
	if panel_stack.size() > 1:
		panel_stack.pop_back()
		_render_top_panel()


func _render_top_panel() -> void:
	if panel_stack.is_empty() or not g.has("panel") or not GameState.has_life():
		return
	U.clear(g["panel"])
	g["back"].visible = panel_stack.size() > 1
	var builder: Callable = panel_stack[-1]
	builder.call()
	g["panel_scroll"].scroll_vertical = 0
	if UIKit.kb_mode:
		_kb_focus_first.call_deferred()


func _panel_header(icon: String, title: String) -> void:
	g["panel_icon"].text = icon
	g["panel_title"].text = title


func _add(c: Control) -> void:
	g["panel"].add_child(c)


func _act(cb: Callable) -> Callable:
	return func():
		cb.call()
		_refresh_side()
		_render_top_panel()
		_pump()


# ---- activities

func _panel_activities() -> void:
	_panel_header("🏃", "Activities")
	var p := GameState.player
	if GameState.in_prison():
		_add(U.section("Prison"))
		for a in Actions.PRISON_ACTIONS:
			if a.has("mod") and not Meta.has_mod(a["mod"]):
				continue
			var aid: String = a["id"]
			_add(U.row(a["icon"], a["name"], a["sub"], _act(func(): Actions.do_activity(aid))))
		return
	var lk := Lives.kind()
	if lk != "human":
		var td: Dictionary = Lives.TYPES[lk]
		var sl: Array = Lives.status_lines()
		_add(U.row(td["icon"], Lives.title() if Lives.title() != "" else td["name"], str(sl[0][0]) if not sl.is_empty() else td["desc"], func(): _open_panel(LP.life_panel)))
	if int(p["age"]) >= 5:
		var on: Array = []
		for k in p["routines"].keys():
			if p["routines"][k]:
				on.append(k)
		_add(U.lbl("Routines run automatically each year. Set each one where you would actually do it: the gym, the library, your family." + ("\nRunning: " + ", ".join(on) if not on.is_empty() else "\nNone set."), "Dim", 15, true))
	for grp in Actions.ACTIVITY_GROUPS:
		var avail := false
		for it in grp["items"]:
			if Actions.activity_available(it):
				avail = true
		var gid: String = grp["id"]
		var sub: String = grp["sub"] if avail else "Unlocks as you grow up"
		_add(U.row(grp["icon"], grp["name"], sub, func(): _open_panel(func(): _panel_activity_group(gid)), avail))


func _panel_activity_group(gid: String) -> void:
	var grp: Dictionary = {}
	for x in Actions.ACTIVITY_GROUPS:
		if x["id"] == gid:
			grp = x
	_panel_header(grp["icon"], grp["name"])
	for it in grp["items"]:
		var ok := Actions.activity_available(it)
		var iid: String = it["id"]
		var sub: String = it["sub"]
		if not ok:
			var era_reason := Expansion.era_activity_block(iid)
			sub = era_reason if era_reason != "" and int(GameState.player["age"]) >= int(it["min"]) else "Age %d+" % int(it["min"])
		if it.has("menu"):
			var mk: String = it["menu"]
			_add(U.row(it["icon"], it["name"], sub, func(): MP.open(mk), ok))
			continue
		if it.has("act"):
			var ak: String = it["act"]
			_add(U.row(it["icon"], it["name"], sub, _act(func(): MP.run(ak, null)), ok, false))
			continue
		if it.get("panel", false):
			var pcb: Callable = {"social_media": _panel_social, "licenses": _panel_licenses, "lawsuit": _panel_lawsuit, "black_market": ep.black_market, "cult": ep.cult, "camp": ep.camping, "journal": ep.journal, "museum": ep.museum, "relocate": LP.places_panel, "become_list": _panel_become, "loans": _panel_loans, "fight_bets": _panel_fight_bets}[iid]
			_add(U.row(it["icon"], it["name"], sub, func(): _open_panel(pcb), ok))
		else:
			_add(U.row(it["icon"], it["name"], sub, _act(func(): Actions.do_activity(iid)), ok))



func _panel_routines() -> void:
	_panel_header("🔁", "Routines")
	_add(U.lbl("Routines happen automatically when you age up. Each one uses 1 of your 12 time points for the year.", "Dim", 16, true))
	var p := GameState.player
	var defs := [
		["gym", "🏋️", "Go to the gym", "Health, looks, less stress", 12],
		["study", "📝", "Study", "Better grades while in school", 5],
		["meditate", "🧘", "Meditate", "Less stress, more happiness", 8],
		["walk", "🚶", "Daily walks", "A little health and happiness", 6],
		["family", "👪", "Family time", "Stay close to your family", 0],
	]
	for d in defs:
		var key: String = d[0]
		var on: bool = p["routines"].get(key, false)
		var ok: bool = int(p["age"]) >= int(d[4])
		var sub: String = ("ON · " if on else "OFF · ") + d[3]
		if not ok:
			sub = "Age %d+" % int(d[4])
		_add(U.row(d[1], d[2], sub, _act(func(): p["routines"][key] = not p["routines"].get(key, false)), ok, false))


# ---- relationships

const ROUTINE_HOME := {"gym": "gym", "library": "study", "meditate": "meditate", "walk": "walk"}


func _panel_relationships() -> void:
	_panel_header("❤️", "Relationships")
	var bst := Actions.batch_state()
	if bool(bst["ok"]):
		_add(U.row("👪", "Get everyone together", str(bst["why"]), _act(func(): Actions.hang_out_with_all()), true, false))
	else:
		_add(U.row("🔒", "Get everyone together", str(bst["why"]), func(): pass, false, false))
	if int(GameState.player["age"]) >= 5:
		var fam_on: bool = GameState.player["routines"].get("family", false)
		_add(U.row("🔁", "Family time routine: %s" % ("ON" if fam_on else "OFF"), "Stay close to your family automatically each year, for 1 time point", _act(func(): GameState.player["routines"]["family"] = not GameState.player["routines"].get("family", false)), true, false))
	var groups := [
		["Family", ["mother", "father", "stepparent", "grandparent", "sibling", "stepsibling", "child", "stepchild", "grandchild"]],
		["Extended family", ["auntuncle", "cousin", "niece_nephew"]],
		["Romantic", ["partner"]],
		["Friends", ["best_friend", "friend"]],
		["Pets", ["pet"]],
		["Others", ["mentor", "teacher", "boss", "coworker", "classmate", "crush", "neighbor", "cellmate", "rival", "enemy", "ex", "former_coworker", "former_friend", "lover"]],
	]
	for grp in groups:
		var ids: Array = []
		for rel in grp[1]:
			for id in GameState.npcs_with(rel, false):
				ids.append(id)
		if grp[0] == "Romantic" and ids.is_empty():
			_add(U.section("Romantic"))
			_add(U.row("🩶", "None", "You are not currently in a relationship.", func(): pass, true, false))
			continue
		if ids.is_empty():
			continue
		_add(U.section(grp[0]))
		ids.sort_custom(func(a, b): return int(GameState.npcs[a]["alive"]) > int(GameState.npcs[b]["alive"]))
		for id in ids:
			_add(_person_row(id))


func _person_row(id: String) -> Button:
	var n := GameState.npc(id)
	var extra: Control = null
	var sub := ""
	if n["alive"]:
		var h := U.hb(8)
		h.add_child(U.lbl("Relationship", "Dim", 14))
		h.add_child(U.bar(n["closeness"], ThemeManager.bar_color("happiness", n["closeness"]), 8, 150))
		h.add_child(U.lbl("Age %d" % int(n["age"]), "Dim", 14))
		extra = h
		if n.get("species", "human") == "human" and int(n["age"]) >= 16:
			Web.ensure_job(id)
			sub = Web.job_title(id)
			if Web.perk_text(id) != "":
				sub += " ⭐"
	else:
		sub = "Deceased · %d" % int(n["age"])
	var title := "%s (%s)" % [GameState.full_name(id), GameState.relation_label(id)]
	var nid := id
	return U.row(U.npc_face(n), title, sub, func(): _open_panel(func(): _panel_person(nid)), true, true, extra)


func _panel_person(id: String) -> void:
	var n := GameState.npc(id)
	if n.is_empty():
		_panel_back()
		return
	_panel_header(U.npc_face(n), n["first"])
	var info := U.card("Inset")
	var iv := U.vb(6)
	info.add_child(iv)
	iv.add_child(U.lbl("%s  ·  %s" % [GameState.full_name(id), GameState.relation_label(id)], "Bold", 20))
	var details := "Age %d" % int(n["age"])
	if n.get("species", "human") == "human":
		details += "  ·  Trait: %s  ·  Looks %d%%" % [n.get("trait", ""), int(n.get("looks", 50))]
	if not n["alive"]:
		details += "  ·  Deceased"
	iv.add_child(U.lbl(details, "Dim", 16))
	if n["alive"] and n.get("species", "human") == "human":
		Web.ensure_job(id)
		var jt := Web.job_title(id)
		if jt != "":
			iv.add_child(U.lbl("💼 " + jt, "", 16, true))
		if Web.perk_text(id) != "":
			iv.add_child(U.lbl("⭐ " + Web.perk_text(id), "Dim", 15, true))
		if n.get("cult", false):
			iv.add_child(U.lbl("🛐 In your inner circle", "Dim", 15, true))
		var gr := int(n.get("grudge", 0))
		if gr >= 20:
			var gl := U.lbl("😠 %s" % ("Holds a serious grudge against you. Expect payback." if gr >= 40 else "Still resents you."), "", 15, true)
			gl.add_theme_color_override("font_color", ThemeManager.c("bad"))
			iv.add_child(gl)
		if n.get("feud", false):
			iv.add_child(U.lbl("⚔️ An inherited family feud", "Dim", 15, true))
	if n["alive"]:
		var rh := U.hb(10)
		rh.add_child(U.lbl("Relationship", "", 16))
		rh.add_child(U.bar(n["closeness"], ThemeManager.bar_color("happiness", n["closeness"]), 14))
		rh.add_child(U.lbl("%d%%" % int(n["closeness"]), "Bold", 16))
		iv.add_child(rh)
		# The bond underneath the headline number. Their own stats are theirs;
		# these are the ones you actually play.
		for row in BondStats.detail_lines(id):
			var bh := U.hb(10)
			bh.add_child(U.lbl("%s %s" % [str(row[0]), str(row[1])], "", 14))
			var col_key := "bad" if str(row[1]) == "Resentment" else "happiness"
			bh.add_child(U.bar(int(row[2]), ThemeManager.bar_color(col_key, int(row[2])), 10))
			bh.add_child(U.lbl(str(row[3]), "Dim", 13))
			iv.add_child(bh)
	# #19 and #20: a pet is a character too, and craziness is the stat that
	# explains the most about anybody, so it is shown rather than hidden.
	if n["alive"] and n.get("species", "human") != "human":
		Ambition.ensure_pet(id)
		var pp: Dictionary = n.get("pet_profile", {})
		if not pp.is_empty():
			iv.add_child(U.lbl("🐾 %s" % str(pp.get("temperament", "")).capitalize(), "Bold", 16))
			iv.add_child(U.track("❤️", "Health", float(pp.get("health", 100)), 100.0,
				ThemeManager.bar_color("health", float(pp.get("health", 100))), "%d%%" % int(pp.get("health", 100))))
			iv.add_child(U.track("🧠", "Training", float(pp.get("training", 0)), 100.0,
				ThemeManager.c("accent"), "%d%%" % int(pp.get("training", 0))))
			iv.add_child(U.track("🏅", "Pedigree", float(pp.get("pedigree", 50)), 100.0,
				ThemeManager.c("gold"), "%d%%" % int(pp.get("pedigree", 50))))
			var bits: Array = []
			if int(pp.get("tricks", []).size()) > 0:
				bits.append("%d trick%s" % [pp["tricks"].size(), "" if pp["tricks"].size() == 1 else "s"])
			if int(pp.get("titles", 0)) > 0:
				bits.append("%d show title%s" % [int(pp["titles"]), "" if int(pp["titles"]) == 1 else "s"])
			var vet_in := int(pp.get("vet_due", 0)) - int(GameState.player.get("age", 0))
			bits.append("vet %s" % ("overdue" if vet_in <= 0 else "due in %d year%s" % [vet_in, "" if vet_in == 1 else "s"]))
			iv.add_child(U.lbl(" · ".join(bits), "Dim", 14, true))
	if n["alive"]:
		Bonds.ensure(id)
		var cz := int(n.get("craziness", 35))
		iv.add_child(U.track("🌀", "Craziness", float(cz), 100.0,
			ThemeManager.c("bad") if cz >= 70 else (ThemeManager.c("warn") if cz >= 45 else ThemeManager.c("good")),
			"%d%% · %s" % [cz, "volatile" if cz >= 70 else ("unpredictable" if cz >= 45 else "steady")]))
	if n["alive"]:
		iv.add_child(U.lbl(Bonds.stat_line(id), "", 15, true))
	if n["alive"] and n.get("species", "human") == "human":
		Bonds.ensure(id)
		iv.add_child(U.lbl(Bonds.trait_line(id), "Dim", 14, true))
		var st := Bonds.status_line(id)
		if st != "":
			iv.add_child(U.lbl(st, "", 15, true))
		var social: Array = NpcWorld.lines_for(id)
		if not social.is_empty():
			iv.add_child(U.lbl("\n".join(social), "Dim", 14, true))
		var mems: Array = Bonds.memories(id)
		if not mems.is_empty():
			var ml: Array = []
			for mm in mems.slice(0, 3):
				ml.append(("💚 " if mm["good"] else "💢 ") + "Remembers you %s (age %d)" % [mm["text"], int(mm["age"])])
			iv.add_child(U.lbl("\n".join(ml), "Dim", 14, true))
	_add(info)
	var p := GameState.player
	if n["alive"]:
		MP.rows_into(Bonds.menu(id))
	if n["alive"] and n.get("species", "human") == "human" and int(n["age"]) >= 18 and int(p["age"]) >= 18:
		var nid := id
		if not p["business"].is_empty():
			if p["business"]["crew"].has(id):
				_add(U.row("🔥", "Fire from %s" % p["business"]["name"], "", _act(func(): Empires.fire_known(nid)), true, false))
			else:
				_add(U.row("🤝", "Offer a job at %s" % p["business"]["name"], "They'd leave their current job", _act(func(): Empires.hire_known(nid)), true, false))
		if not p["cult"].is_empty() and not p["cult"]["inner"].has(id):
			_add(U.row("🛐", "Invite to %s" % p["cult"]["name"], "Uses 1 time", _act(func(): Empires.invite_to_cult(nid)), true, false))
		if not p["zoo"].is_empty() and not p["zoo"]["crew"].has(id):
			_add(U.row("🧑‍🌾", "Hire as a zookeeper", p["zoo"]["name"], _act(func(): Empires.zoo_action("hire_known", nid)), true, false))
	if n["alive"] and n["relation"] == "pet":
		var petid := id
		_add(U.row("🐾", "Pet life", "Training, shows, health, breeding and legacy", func(): MP.open("amb:pet/" + petid)))
	if n["alive"] and n["relation"] == "pet" and not p["zoo"].is_empty():
		var pid := id
		_add(U.row("🐾", "Move to your petting zoo", p["zoo"]["name"], _act(func(): Empires.zoo_action("donate_pet", pid); _panel_back()), true, false))


# ---- occupation

func _panel_occupation() -> void:
	_panel_header("💼", "Occupation")
	var p := GameState.player
	var age: int = p["age"]
	if GameState.in_prison():
		_add(U.lbl("You can't work while you're in prison.", "Dim", 17, true))
		return
	if GameState.has_job():
		var j: Dictionary = p["job"]
		var c := U.card("Inset")
		var cv := U.vb(6)
		c.add_child(cv)
		cv.add_child(U.lbl("%s  ·  %s" % [j["title"], j["field"]], "Bold", 20))
		cv.add_child(U.lbl("Salary %s / year  ·  %d year%s here" % [GameState.fmt_money(int(j["salary"])), int(j["years"]), "" if int(j["years"]) == 1 else "s"], "Dim", 16))
		var ph := U.hb(10)
		ph.add_child(U.lbl("Performance", "", 16))
		ph.add_child(U.bar(float(j["perf"]), ThemeManager.bar_color("happiness", float(j["perf"])), 14))
		ph.add_child(U.lbl("%d%%" % int(j["perf"]), "Bold", 16))
		cv.add_child(ph)
		if j.get("boss", "") != "" and GameState.npcs.has(j["boss"]):
			cv.add_child(U.lbl("Boss: " + GameState.full_name(j["boss"]), "Dim", 15))
		_add(c)
		_add(U.row("💪", "Work harder", "Performance up, stress up", _act(Actions.work_harder), not j.get("worked_hard", false), false))
		_add(U.row("💰", "Ask for a raise", "Depends on your performance", _act(Actions.ask_raise), true, false))
		_add(U.row("🧭", "Professional Life", "Projects, mentors, rivals and career-specific systems", func(): MP.open("amb:work")))
		_add(U.row("@office", "Your workplace", "Boss, colleagues, the union, and ways out", func(): MP.open("real:work")))
		if j["field"] == "Military":
			_add(U.row("💣", "Deploy", "Minigame · clear a path through a minefield", _act(Actions.deploy), GameState.can_interact("job", "deploy"), false))
		if Shop.has_tag("suit") and not j.get("suited", false):
			_add(U.row("👔", "Dress to impress", "Wear the tailored suit this year · performance up", _act(Actions.dress_up), true, false))
		_add(U.row("🚪", "Quit job", "", _act(Actions.quit_job), true, false))
		if age >= 60:
			_add(U.row("🏖️", "Retire", "Collect a pension", _act(Actions.retire), true, false))
	var school_sub := "Not enrolled"
	if GameState.in_school():
		school_sub = ("Elementary School" if p["education"]["stage"] == "primary" else "High School") + " · Grade " + str(p["education"]["grade"] if p["education"]["grade"] != "" else "—")
	elif GameState.in_university():
		school_sub = "%s · Year %d of %d" % [ContentDB.major(p["education"]["uni"]["major"])["name"], int(p["education"]["uni"]["year"]) + 1, int(p["education"]["uni"]["years"])]
	elif age >= 18:
		school_sub = "University and graduate school"
	elif age < 5:
		school_sub = "School starts at 5"
	_add(U.row("🎓", "Education", school_sub, func(): _open_panel(_panel_education), age >= 5))
	if not GameState.has_job() and age >= 18:
		_add(U.row("@signpost", "Career moves", "Freelancing, retraining, and what your CV says", func(): MP.open("real:work")))
	_add(U.row("🍔", "Part-Time Jobs", "Find a part-time job" if age >= 13 else "Age 13+", func(): _open_panel(func(): _panel_jobs("part")), age >= 13))
	_add(U.row("💼", "Full-Time Jobs", "Find a full-time job" if age >= 18 else "Age 18+", func(): _open_panel(func(): _panel_jobs("full")), age >= 18))
	_add(U.row("🎖️", "Military", "Enlist and climb the ranks" if age >= 18 else "Age 18+", func(): _open_panel(func(): _panel_jobs("military")), age >= 18))
	_add(U.row("🧾", "Freelance", "Pick up a gig for quick cash" if age >= 14 else "Age 14+", _act(Actions.freelance), age >= 14, false))
	var biz: Dictionary = p["business"]
	_add(U.row("📈", "Business", ("%s · profit %s last year" % [biz["name"], GameState.fmt_money(int(biz["profit"]))]) if not biz.is_empty() else "Start a company" if age >= 18 else "Age 18+", func(): _open_panel(ep.business), age >= 18))
	_add(U.row("🏢", "Company Portfolio", "Own multiple companies, acquire rivals and plan succession", func(): MP.open("amb:enterprise"), age >= 18))
	if not p["career"].is_empty():
		var cd: Dictionary = Careers.CAREERS[p["career"]["id"]]
		_add(U.row(cd["icon"], "Your career: " + Careers.title(), "Open your %s career" % cd["name"].to_lower(), func(): _open_panel(_panel_career)))
	_add(U.row("⭐", "Special Careers", "Actor, musician, athlete, politician, astronaut, model, fighter, director, secret agent, mafia, hustler", func(): _open_panel(_panel_special_hub), age >= 6))
	if p["retired"]:
		_add(U.lbl("Retired · pension %s a year" % GameState.fmt_money(int(p["pension"])), "Dim", 16))


func _panel_education() -> void:
	_panel_header("🎓", "Education")
	var p := GameState.player
	var e: Dictionary = p["education"]
	var c := U.card("Inset")
	var cv := U.vb(6)
	c.add_child(cv)
	if GameState.in_school():
		cv.add_child(U.lbl("Elementary School" if e["stage"] == "primary" else "High School", "Bold", 20))
		var gtxt := "Current grade: %s" % (e["grade"] if e["grade"] != "" else "—")
		if int(e["gpa_years"]) > 0:
			gtxt += "  ·  GPA %.2f" % GameState.gpa()
		cv.add_child(U.lbl(gtxt, "Dim", 16))
		var ph := U.hb(10)
		ph.add_child(U.lbl("Performance", "", 16))
		ph.add_child(U.bar(float(e["performance"]), ThemeManager.bar_color("happiness", float(e["performance"])), 14))
		cv.add_child(ph)
	elif GameState.in_university():
		var u: Dictionary = e["uni"]
		cv.add_child(U.lbl(ContentDB.major(u["major"])["name"], "Bold", 20))
		cv.add_child(U.lbl("Year %d of %d  ·  Grade %s%s" % [int(u["year"]) + 1, int(u["years"]), EventEngine.grade_letter(float(u["performance"])), "  ·  Scholarship" if float(u.get("scholarship", 0)) > 0 else ""], "Dim", 16))
	else:
		var lvl: String = {"none": "No diploma", "high_school": "High school diploma", "bachelor": "Bachelor's degree", "graduate": "Graduate degree"}[GameState.edu_level()]
		cv.add_child(U.lbl(lvl, "Bold", 20))
		if int(e["gpa_years"]) > 0:
			cv.add_child(U.lbl("High school GPA %.2f" % GameState.gpa(), "Dim", 16))
	for d in e["degrees"]:
		cv.add_child(U.lbl("🎓 " + str(d["name"]), "Dim", 15))
	_add(c)
	if GameState.in_school() or GameState.in_university():
		_add(U.row("📝", "Study harder", "Better grades, more stress", _act(Actions.study_harder), not e["studied"], false))
	if GameState.in_school():
		_add(U.row("🏃", "Skip class", "Fun now, worse grades", _act(Actions.skip_class), true, false))
	if GameState.in_school() or GameState.in_university():
		_add(U.row("🏫", "School life", "Cliques, clubs, sports, popularity, prom", func(): MP.open("daily:school")))
	if GameState.in_university():
		_add(U.row("🚪", "Drop out", "", _act(Actions.drop_out), true, false))
	else:
		var why_b := Actions.can_enroll("bachelor")
		_add(U.row("🏛️", "University", why_b if why_b != "" else "Apply for a bachelor's degree", func(): _open_panel(func(): _panel_majors("bachelor")), why_b == ""))
		var why_g := Actions.can_enroll("graduate")
		_add(U.row("📜", "Graduate School", why_g if why_g != "" else "Law, medicine, MBA, PhD and more", func(): _open_panel(func(): _panel_majors("graduate")), why_g == ""))


func _panel_majors(level: String) -> void:
	_panel_header("🏛️", "Choose a Major" if level == "bachelor" else "Graduate School")
	var tuition := 12000 if level == "bachelor" else 25000
	_add(U.lbl("Tuition is about %s a year. If you can't pay, it becomes a student loan. High school GPA affects admission and scholarships." % GameState.fmt_money(int(tuition * float(ContentDB.country(GameState.player["country"]).get("cost", 1.0)))), "Dim", 15, true))
	for m in ContentDB.majors_of_level(level):
		var mid: String = m["id"]
		_add(U.row("📘", m["name"], "%s · %d years" % [m["degree"], int(m["years"])], _act(func(): Actions.enroll(mid); _panel_back_to_root())))


func _panel_back_to_root() -> void:
	while panel_stack.size() > 1:
		panel_stack.pop_back()


func _panel_jobs(kind: String) -> void:
	var titles := {"part": "Part-Time Jobs", "full": "Full-Time Jobs", "military": "Military"}
	_panel_header({"part": "🍔", "full": "💼", "military": "🎖️"}[kind], titles[kind])
	_add(U.lbl("Real openings, with real competition. Applying uses 1 time point: a screening, then an interview, then an offer you can negotiate.", "Dim", 15, true))
	var list := Market.openings(kind)
	if list.is_empty():
		_add(U.lbl("No openings right now. Check again next year.", "Dim", 16))
	for l in list:
		var jd := ContentDB.job(str(l["job"]))
		var why := str(l["locked"])
		var stand := Market.standing(l)
		var sub := "%s a year · %d applicants%s" % [GameState.fmt_money(int(l["salary"])), int(l["apps"]), " · remote" if bool(l["remote"]) else ""]
		if why != "":
			sub = "🔒 Requires: " + why
		else:
			sub += " · odds ~%d%%" % int(round(float(stand["chance"]) * 100.0))
		var applied: bool = Market.st()["applied"].has(str(l["id"]))
		if applied:
			sub = "✓ Applied · " + sub
		var l_id: String = str(l["id"])
		_add(U.row(str(jd.get("icon", "💼" if kind != "military" else "🎖️")), "%s · %s" % [str(jd["ranks"][0]), str(l["company"])], sub, _act(func(): Market.apply(l_id)), why == "" and not applied))


# ---- assets

func _panel_assets() -> void:
	_panel_header("💰", "Assets")
	var p := GameState.player
	var c := U.card("Inset")
	var cv := U.vb(6)
	c.add_child(cv)
	var top := U.hb()
	top.add_child(U.lbl("Finances", "Bold", 20))
	top.add_child(U.spacer())
	var m := U.lbl(GameState.fmt_money(int(p["money"])), "Money", 22)
	top.add_child(m)
	cv.add_child(top)
	for line in [["🟢 Income (last year)", GameState.fmt_money(int(p["last_income"]))], ["🔴 Expenses (last year)", GameState.fmt_money(-int(p["last_expenses"]))], ["🎓 Student loans", GameState.fmt_money(int(p["loan"]))], ["🏦 Mortgage", GameState.fmt_money(int(p["mortgage"]))], ["📊 Net worth", GameState.fmt_money(GameState.net_worth())]]:
		var h := U.hb()
		h.add_child(U.lbl(line[0], "", 16))
		h.add_child(U.spacer())
		h.add_child(U.lbl(line[1], "Bold", 16))
		cv.add_child(h)
	_add(c)
	var age: int = p["age"]
	_add(U.row("🏠", "Houses", GameState.HOUSING[p["housing"]]["name"] + " · buy, sell, rent", func(): _open_panel(_panel_housing), age >= 18))
	_add(U.row("🛠️", "Home Life", "Condition, renovations, neighbors, HOA and house stories", func(): MP.open("exp:home"), age >= 18 and p["housing"] == "house"))
	_add(U.row("@key", "Your tenancy", "Landlord, deposit, repairs, flatmates and bills", func(): MP.open("real:home"), age >= 18 and Tenancy.renting()))
	_add(U.row("@compass", "Getting about", "Your commute, insurance and what the car is costing you", func(): MP.open("real:go"), age >= 12 and (Transit.commuting() or Transit.has_car())))
	_add(U.row("@envelope", "Keeping up", "Invitations, lapsed friends, what you eat, your phone", func(): MP.open("real:keep"), age >= 14))
	_add(U.row("🚗", "Vehicles", (GameState.CARS[p["car"]]["name"] if p["car"] != "" else "No car") + " · buy or sell", func(): _open_panel(_panel_vehicles), age >= 16))
	_add(U.row("🏦", "Savings & Investments", "Savings %s · portfolio %s" % [GameState.fmt_money(int(p["savings"])), GameState.fmt_money(Finance.investments_value())], func(): _open_panel(_panel_investments), age >= 16))
	_add(U.row("🏢", "Property", "%d owned · rentals and tenants" % p["properties"].size(), func(): _open_panel(_panel_property), age >= 18))
	_add(U.row("📦", "Possessions", "%d items · jewelry, art, collectibles, heirlooms" % p["possessions"].size(), func(): _open_panel(_panel_possessions), age >= 16))
	_add(U.row("🏙️", "Where You Live", Places.place_name() + " · local laws, costs, moving", func(): _open_panel(LP.places_panel)))
	if World.billionaire_open():
		_add(U.row("💎", "Billionaire", "Teams, rockets, foundations, your own nation", func(): _open_panel(LP.billionaire_panel)))
	var z: Dictionary = p["zoo"]
	_add(U.row("🦁", "Zoo", ("%s · %d visitors last year" % [z["name"], int(z["visitors"])]) if not z.is_empty() else "Open your own zoo" if age >= 21 else "Age 21+", func(): _open_panel(ep.zoo), age >= 21))
	if not p["business"].is_empty():
		_add(U.row("📈", p["business"]["name"], "Worth %s · you own %d%%" % [GameState.fmt_money(int(p["business"]["value"])), int(float(p["business"]["stake"]) * 100)], func(): _open_panel(ep.business)))


func _panel_housing() -> void:
	_panel_header("🏠", "Houses")
	var p := GameState.player
	var cost: float = ContentDB.country(p["country"]).get("cost", 1.0)
	_add(U.lbl("Now: " + GameState.HOUSING[p["housing"]]["name"], "Bold", 18))
	if p["housing"] != "apartment" and p["housing"] != "house":
		_add(U.row("🏢", "Rent an apartment", "About %s a year with living costs" % GameState.fmt_money(int((11000 + 14000) * cost)), _act(Actions.move_out)))
	if p["housing"] != "house":
		var price := Actions.house_price()
		_add(U.row("🏡", "Buy a house", "%s · 20%% down (%s), mortgage for the rest" % [GameState.fmt_money(price), GameState.fmt_money(int(price * 0.2))], _act(Actions.buy_house)))
	else:
		_add(U.row("💲", "Sell your house", "Worth about %s" % GameState.fmt_money(int(p["house_value"])), _act(Actions.sell_house)))
	if p["housing"] == "apartment" or p["housing"] == "homeless":
		_add(U.row("🏠", "Move back with family", "Cheaper, less freedom", _act(Actions.move_home)))


func _panel_vehicles() -> void:
	_panel_header("🚗", "Vehicles")
	var p := GameState.player
	if p["car"] != "":
		_add(U.lbl("You drive a " + GameState.CARS[p["car"]]["name"].to_lower() + ".", "Bold", 18))
		_add(U.row("💲", "Sell your car", "", _act(Actions.sell_car), true, false))
	var cost: float = ContentDB.country(p["country"]).get("cost", 1.0)
	for k in ["used", "new", "sports"]:
		var cdef: Dictionary = GameState.CARS[k]
		var kk: String = k
		_add(U.row("🚙" if k == "used" else ("🚗" if k == "new" else "🏎️"), cdef["name"], "%s · upkeep %s/yr" % [GameState.fmt_money(int(cdef["price"] * cost)), GameState.fmt_money(int(cdef["upkeep"] * cost))], _act(func(): Actions.buy_car(kk)), p["car"] != k))


# ---- more

func _panel_more() -> void:
	_panel_header("⋯", "More")
	var ready := Goals.unclaimed_count()
	_add(U.row("🌍", "The World", (", ".join(World.active_list().map(func(w): return World.EVENTS[w]["name"])) if not World.active_list().is_empty() else "A quiet year") + " · headlines", func(): _open_panel(LP.world_panel)))
	_add(U.row("🎁", "Daily Heirloom", "Ready to open!" if Goals.daily_available() else "Next in " + Goals.fmt_left(Goals.seconds_left("daily")), func(): SP.show_heirloom()))
	_add(U.row("🎯", "Missions", ("%d ready to claim! · " % ready if ready > 0 else "") + "Daily, weekly and monthly goals", _show_missions))
	_add(U.row("🏆", "Trophy Room", "%d / %d achievements · ⭐ %d Stars" % [Meta.meta["goals"]["ach"].size(), Goals.achievements.size(), Goals.stars()], _show_trophies))
	_add(U.row("⭐", "Star Shop", "Titles and Legacy Boons", _show_star_shop))
	_add(U.row("🌳", "Family Tree", "Your bloodline at a glance", _show_family_tree))
	_add(U.row("🪦", "Graveyard", "Past lives and their stories", _open_graveyard))
	_add(U.row("🏅", "Challenges", "Goal lives and badges", func(): _open_panel(_panel_challenges)))
	_add(U.row("🎀", "Ribbon Collection", "Every ribbon across all your lives", func(): _open_panel(_panel_ribbons)))
	_add(U.row("🧙", "God Mode", "Edit anyone's stats, money, looks and more (free)", func(): _open_panel(_panel_god)))
	_add(U.row("⚙️", "Settings", "Sound, effects, motion, celebrity theme", func(): _open_panel(_panel_settings)))
	_add(U.row("🎨", "Theme: " + ThemeManager.LABELS[ThemeManager.current], "Tap to switch · " + ", ".join(ThemeManager.ORDER.map(func(k): return ThemeManager.LABELS[k])), func(): _set_theme(ThemeManager.next_theme()), true, false))
	_add(U.row("📂", "Your Lives", "Switch to another saved life", func(): SaveManager.save_game(); SP.show_lives()))
	_add(U.row("⧉", "Duplicate This Life", "Branch a copy into a new slot and try another path", func():
		var j := SaveManager.duplicate_current()
		_toast("⧉", "Life duplicated" if j > 0 else "No free slot", ("Copy saved to slot %d" % j) if j > 0 else "Delete a life first", ThemeManager.c("good") if j > 0 else ThemeManager.c("warn")), true, false))
	_add(U.row("💾", "Save & Exit", "Back to the main menu", func(): SaveManager.save_game(); _show("title"), true, false))
	_add(U.lbl("Keys: Space = Age · 1–6 = tabs · Esc = back · 1–9 picks a choice in events", "Dim", 14, true))


# ================================================================= POPUPS

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(cc)
	overlay_frame = U.card("EventFrame")
	overlay_frame.custom_minimum_size = Vector2(640, 0)
	cc.add_child(overlay_frame)
	overlay_box = U.vb(12)
	overlay_frame.add_child(overlay_box)


func _pump() -> void:
	if popup_open or mg_open:
		return
	if death_waiting:
		death_waiting = false
		_show_death()
		return
	if not EventEngine.has_pending():
		return
	var inst := EventEngine.pop_next()
	if inst.get("info", false):
		_show_info(inst["icon"], inst["title"], inst["text"], inst.get("changes", {}), false, inst.get("signals", []))
	else:
		_show_decision(inst)


func _open_popup(width: int = 640) -> VBoxContainer:
	popup_open = true
	overlay.visible = true
	overlay_frame.custom_minimum_size = Vector2(width, 0)
	U.clear(overlay_box)
	var head := U.lbl("Event", "Bold", 18)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_box.add_child(head)
	var cardp := U.card("EventCard")
	overlay_box.add_child(cardp)
	VFX.pop_in(overlay_frame)
	var v := U.vb(14)
	cardp.add_child(v)
	return v


func _close_popup() -> void:
	popup_open = false
	overlay.visible = false
	U.clear(overlay_box)
	if _current_screen() == "title":
		_refresh_title()
	_refresh_side()
	_render_top_panel()
	if GameState.has_life() and not GameState.player["alive"] and _current_screen() == "game":
		_show_death()
		return
	_pump()


func _event_header(v: VBoxContainer, icon: String, title: String) -> void:
	var ic := U.lbl(icon, "Emoji", 64)
	ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ic)
	var t := U.lbl(title, "EventTitle", 0, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)


func _event_text(v: VBoxContainer, text: String) -> void:
	var l := U.lbl(text, "EventText", 19, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)


func _show_decision(inst: Dictionary) -> void:
	Fx.play("choice")
	var def: Dictionary = inst["def"]
	var roles: Dictionary = inst.get("roles", {})
	var v := _open_popup(700 if def.get("twist", false) else 640)
	if def.get("twist", false):
		_twist_banner(v)
	_event_header(v, def.get("icon", "❔"), EventEngine.tokens(def.get("title", "Event"), roles))
	_event_text(v, EventEngine.tokens(def.get("text", ""), roles))
	var q := U.lbl("What will you do?", "EventText", 18)
	q.theme_type_variation = "EventText"
	q.add_theme_font_override("font", ThemeManager.font_bold)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(q)
	var n := 0
	var choices: Array = def.get("choices", [])
	for i in range(choices.size()):
		var ch: Dictionary = choices[i]
		var st := EventEngine.choice_state(ch, roles)
		if not st["visible"]:
			continue
		n += 1
		var label := EventEngine.tokens(ch["label"], roles)
		if st["enabled"] and st["reason"] != "":
			label = "%s   [%s]" % [label, st["reason"]]
		elif not st["enabled"]:
			label = "%s   (%s)" % [label, st["reason"]]
		var idx := i
		var is_twist: bool = bool(def.get("twist", false))
		var press := func(): _choose(inst, idx)
		if is_twist:
			press = func(): _confirm_twist(inst, idx, label)
		var b := U.btn(label, press, "Primary")
		b.name = "Choice%d" % n
		b.disabled = not st["enabled"]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(0, 54)
		v.add_child(b)

	# Surprise me: for when you genuinely do not know, which is most of the
	# interesting ones. It picks from what you could actually have picked.
	if n >= 2:
		var pickable: Array = []
		for i2 in range(choices.size()):
			var s2 := EventEngine.choice_state(choices[i2], roles)
			if s2["visible"] and s2["enabled"]:
				pickable.append(i2)
		if pickable.size() >= 2:
			var sb := U.btn("🎲  Surprise me", func(): _surprise(inst, pickable), "Flat")
			sb.name = "SurpriseButton"
			sb.custom_minimum_size = Vector2(0, 42)
			v.add_child(sb)


## A turning point asks once. Answering no puts the original choices back rather
## than closing the event, because backing out is not the same as deciding.
func _confirm_twist(inst: Dictionary, idx: int, label: String) -> void:
	Fx.play("choice")
	var v := _open_popup(560)
	var ic := U.lbl("⚠️", "Emoji", 54)
	ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ic)
	var t := U.lbl("Are you sure?", "Title", 26)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var q := U.lbl(label, "EventText", 19)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(q)
	var w := U.lbl("This is a turning point. You will not get to take it back.", "Dim", 15)
	w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(w)
	var yes := U.btn("Yes, do it", func(): _choose(inst, idx), "Primary")
	yes.custom_minimum_size = Vector2(0, 54)
	yes.name = "Choice1"
	v.add_child(yes)
	var no := U.btn("No, let me think", func(): _show_decision(inst), "Row")
	no.custom_minimum_size = Vector2(0, 48)
	no.name = "Choice2"
	v.add_child(no)


## Let the game choose. It says which one it took, so this never feels like the
## choice was skipped rather than made.
func _surprise(inst: Dictionary, pickable: Array) -> void:
	if pickable.is_empty():
		return
	var idx: int = int(pickable[randi() % pickable.size()])
	var def: Dictionary = inst["def"]
	var roles: Dictionary = inst.get("roles", {})
	var label := EventEngine.tokens(str(def["choices"][idx]["label"]), roles)
	Fx.play("whoosh")
	GameState.add_log("I could not decide, so I let it happen: %s." % label.to_lower())
	_choose(inst, idx)


func _choose(inst: Dictionary, idx: int) -> void:
	Fx.play("choice")
	var res := EventEngine.resolve(inst, idx)
	var def: Dictionary = inst["def"]
	if res.get("died", false):
		popup_open = false
		overlay.visible = false
		_show_death()
		return
	if str(res.get("text", "")) == "" and res.get("changes", {}).is_empty():
		_close_popup()
		return
	_show_info(def.get("icon", "❔"), EventEngine.tokens(def.get("title", ""), inst.get("roles", {})), res["text"], res.get("changes", {}), def.get("twist", false), res.get("signals", []))


func _show_info(icon: String, title: String, text: String, changes: Dictionary, twist: bool = false, signals: Array = []) -> void:
	if not twist:
		_react(title, text, changes, signals)
	var v := _open_popup(700 if twist else 640)
	if twist:
		var tl := U.lbl("⚡ TURNING POINT", "Bold", 16)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.add_theme_color_override("font_color", ThemeManager.c("bad"))
		v.add_child(tl)
	_event_header(v, icon, title)
	_event_text(v, text)
	var bb := U.changes_bbcode(changes)
	if bb != "":
		var r := RichTextLabel.new()
		r.bbcode_enabled = true
		r.fit_content = true
		r.scroll_active = false
		r.text = "[center]%s[/center]" % bb
		r.add_theme_font_override("normal_font", ThemeManager.font_bold)
		r.add_theme_font_size_override("normal_font_size", 17)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(r)
	var ok := U.btn("OK", _close_popup, "Primary")
	ok.name = "OkButton"
	ok.custom_minimum_size = Vector2(0, 54)
	v.add_child(ok)


func _show_menu_popup(icon: String, title: String, text: String, options: Array) -> void:
	var v := _open_popup()
	_event_header(v, icon, title)
	if text != "":
		_event_text(v, text)
	var n := 0
	for o in options:
		n += 1
		var cb: Callable = o[1]
		var b := U.btn(o[0], func(): popup_open = false; overlay.visible = false; cb.call(), "Primary")
		b.name = "Choice%d" % n
		b.custom_minimum_size = Vector2(0, 54)
		v.add_child(b)
	var cancel := U.btn("Cancel", _close_popup, "Row")
	cancel.name = "OkButton"
	v.add_child(cancel)


# ---- family tree

func _show_family_tree() -> void:
	popup_open = true
	overlay.visible = true
	overlay_frame.custom_minimum_size = Vector2(1100, 0)
	U.clear(overlay_box)
	var head := U.hb(10)
	head.add_child(U.lbl("🌳", "Emoji", 30))
	head.add_child(U.lbl("Family Tree", "Title"))
	head.add_child(U.spacer())
	var close := U.btn("Close", _close_popup, "Row")
	close.name = "OkButton"
	head.add_child(close)
	overlay_box.add_child(head)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 640)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var v := U.vb(18)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	overlay_box.add_child(sc)
	var p := GameState.player
	var tiers := [
		["Grandparents", GameState.npcs_with("grandparent", false)],
		["Parents, aunts & uncles", GameState.npcs_with("mother", false) + GameState.npcs_with("father", false) + GameState.npcs_with("auntuncle", false)],
		["You, siblings & partner", ["__me"] + GameState.npcs_with("sibling", false) + (GameState.npcs_with("partner", false))],
		["Children", GameState.npcs_with("child", false)],
	]
	for tier in tiers:
		if tier[1].is_empty():
			continue
		var l := U.section(tier[0])
		v.add_child(l)
		var fl := HFlowContainer.new()
		fl.alignment = FlowContainer.ALIGNMENT_CENTER
		fl.add_theme_constant_override("h_separation", U.sp(14))
		fl.add_theme_constant_override("v_separation", U.sp(14))
		for id in tier[1]:
			var cv := U.card("Inset")
			cv.custom_minimum_size = Vector2(150, 0)
			var vv := U.vb(2)
			cv.add_child(vv)
			var face := ""
			var name1 := ""
			var rel := ""
			var age := 0
			var alive := true
			if id == "__me":
				face = U.face(p["gender"], int(p["age"]), int(p["face"])) if p["alive"] else "😇"
				name1 = "%s %s" % [p["first"], p["last"]]
				rel = "You"
				age = p["age"]
				alive = p["alive"]
				cv.theme_type_variation = "Chip"
			else:
				var n := GameState.npc(id)
				face = U.npc_face(n)
				name1 = GameState.full_name(id)
				rel = GameState.relation_label(id)
				age = n["age"]
				alive = n["alive"]
			var fl2 := U.lbl(face, "Emoji", 40)
			fl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vv.add_child(fl2)
			for txt in [[name1, "Bold", 15], [rel + ("" if alive else " (Deceased)"), "Dim", 13], ["Age %d" % age, "Dim", 13]]:
				var tl := U.lbl(txt[0], txt[1], txt[2])
				tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				vv.add_child(tl)
			fl.add_child(cv)
		v.add_child(fl)


# ================================================================= DEATH / LEGACY

func _build_death_shell() -> Control:
	var c := CenterContainer.new()
	var h := U.hb(28)
	h.name = "DeathRow"
	c.add_child(h)
	return c


func _on_died(_entry: Dictionary) -> void:
	if popup_open:
		death_waiting = true
		return
	_show_death()


func _show_death() -> void:
	Fx.play("death")
	VFX.death_fade(fx_layer)
	VFX.burst(fx_layer, "grief", 10)
	_show("death")
	_fill_death(GameState.player.get("legacy", {}))


func _fill_death(entry: Dictionary) -> void:
	if entry.is_empty():
		return
	last_stats.clear()
	var row := screens["death"].find_child("DeathRow", true, false) as HBoxContainer
	U.clear(row)
	var p := GameState.player
	var ribbon: Dictionary = entry.get("ribbon", {})

	# The stone itself is drawn from the life that just ended, so a pauper, a
	# billionaire, a child and a four-hundred-year-old vampire do not all get the
	# same rectangle.
	var stone := Tombstone.new()
	stone.setup(entry, ribbon, p)
	var tomb := PanelContainer.new()
	tomb.custom_minimum_size = Vector2(400, 620)
	tomb.add_child(stone)
	var tv := U.vb(8)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tv.add_theme_constant_override("margin_top", 40)
	stone.add_child(tv)
	var ink: Color = stone.text_ink()
	for t in [[stone.ornament, 34, false], ["R.I.P.", 46, true], [entry["name"], 28, true], ["%d – %d" % [int(entry["born"]), int(entry["died"])], 22, false], ["", 6, false], ["Died of %s" % entry["cause"], 18, false], ["Age %d" % int(entry["age"]), 18, false], ["", 6, false], ["%s %s" % [ribbon.get("icon", ""), ribbon.get("name", "")], 24, true], ["“%s”" % stone.epitaph, 17, false]]:
		var l := U.lbl(t[0], "Bold" if t[2] else "", t[1])
		l.add_theme_color_override("font_color", ink)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(340, 0)
		tv.add_child(l)
	var grass := U.lbl("🌷 🌿 🌼 🌿 🌷", "Emoji", 26)
	grass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tcol := U.vb(0)
	tcol.add_child(tomb)
	tcol.add_child(grass)
	row.add_child(tcol)

	var lc := U.card()
	lc.custom_minimum_size = Vector2(440, 0)
	var lv := U.vb(10)
	lc.add_child(lv)
	var hdr := U.lbl("💀  Death / Legacy", "Title")
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(hdr)
	var halo := U.card("Halo")
	halo.custom_minimum_size = Vector2(150, 150)
	var hf := U.lbl(str(entry["pet"].get("icon", "🐾")) if entry.has("pet") else U.face(entry.get("gender", "male"), int(entry["age"]), int(entry.get("face", 0))), "Emoji", 90)
	hf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hf.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	halo.add_child(hf)
	var hc := CenterContainer.new()
	hc.add_child(halo)
	lv.add_child(hc)
	var nm := U.lbl(entry["name"], "Heading")
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(nm)
	if entry.get("modified", false):
		var mt := U.lbl("🧪 Modified life", "Dim", 15)
		mt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lv.add_child(mt)
	var card_lines: Array = [["Age", str(entry["age"])], ["Born", str(entry["born"])], ["Died", str(entry["died"])], ["Cause of Death", str(entry["cause"]).capitalize()], ["Occupation", str(entry["occupation"])], ["Net Worth", GameState.fmt_money(int(entry["net_worth"]))]]
	if entry.has("pet"):
		var pe: Dictionary = entry["pet"]
		card_lines = [["Age", str(entry["age"])], ["Born", str(entry["born"])], ["Died", str(entry["died"])], ["Cause of Death", str(entry["cause"]).capitalize()], ["Kind", "%s · %s" % [str(pe.get("breed", "")), str(pe.get("species", "")).capitalize()]], ["Started", str(pe.get("origin", ""))], ["Calling", str(entry.get("occupation", ""))], ["Loved by", str(pe.get("owner", "")) + " " + str(pe.get("house", ""))]]
	for line in card_lines:
		var hh := U.hb()
		hh.add_child(U.lbl(line[0] + ":", "Bold", 17))
		hh.add_child(U.lbl(line[1], "", 17))
		lv.add_child(hh)
	var ban := U.card("Banner")
	var bl := U.lbl("%s  %s" % [ribbon.get("icon", ""), ribbon.get("name", "")], "Title")
	bl.add_theme_color_override("font_color", Color("#2a1d06"))
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ban.add_child(bl)
	lv.add_child(ban)
	var desc := U.lbl(ribbon.get("desc", ""), "Dim", 16, true)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(desc)
	var heirs: Array = GameState.heirs() if GameState.has_life() and not p.get("alive", true) else []
	var cont := U.btn("Continue as Child", _continue_as_child, "Accent")
	cont.custom_minimum_size = Vector2(0, 56)
	cont.disabled = heirs.is_empty()
	if heirs.is_empty():
		cont.text = "Continue as Child (no living children)"
	if entry.has("pet"):
		var pe0: Dictionary = entry["pet"]
		cont.text = "🐾  Another life in the same house"
		cont.disabled = false
		cont.tooltip_text = "Born again, a different animal, to the house that remembers %s." % str(entry.get("name", "").get_slice(" ", 0))
		cont.pressed.disconnect(_continue_as_child)
		cont.pressed.connect(func(): _open_pet_setup(Pets.next_life_opts(entry)["inherit"]))
		if pe0.is_empty():
			cont.disabled = true
	lv.add_child(cont)
	if GameState.has_life() and not p.get("alive", true) and bool(p.get("life", {}).get("can_rise", false)):
		var rb := U.btn("🧟  Rise from the Grave", _rise, "Accent")
		rb.custom_minimum_size = Vector2(0, 56)
		rb.tooltip_text = "Crawl out as a Revenant. Unfinished business awaits."
		lv.add_child(rb)
	var nb := U.btn("Start New Life", func(): _open_new_life(), "Primary")
	nb.custom_minimum_size = Vector2(0, 52)
	lv.add_child(nb)
	var ft := U.btn("🌳  View Family Tree", _show_family_tree, "Row")
	ft.custom_minimum_size = Vector2(0, 50)
	lv.add_child(ft)
	var mm := U.btn("Main Menu", func(): _show("title"), "Flat")
	lv.add_child(mm)
	row.add_child(lc)

	var sc := U.card()
	sc.custom_minimum_size = Vector2(560, 700)
	var sv := U.vb(12)
	sc.add_child(sv)
	sv.add_child(U.lbl("📜  Life Story", "Title"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var sbox := U.vb(12)
	sbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(sbox)
	var story := U.lbl(entry.get("story", ""), "", 18, true)
	story.add_theme_constant_override("line_spacing", 6)
	sbox.add_child(story)
	var end: Dictionary = entry.get("ending", {})
	if not end.is_empty():
		sbox.add_child(U.section("How it ended: %s" % str(end.get("title", ""))))
		sbox.add_child(U.lbl("%d of 5 chapters walked." % int(end.get("chapters", 0)), "Dim", 15))
	var cons: Array = entry.get("consequences", [])
	if not cons.is_empty():
		sbox.add_child(U.section("What caught up with you"))
		sbox.add_child(U.lbl("\n".join(cons), "", 17, true))
	var unl: Array = entry.get("unlocks", [])
	if not unl.is_empty():
		sbox.add_child(U.section("Achievements unlocked this life"))
		sbox.add_child(U.lbl("\n".join(unl), "", 17, true))
	if entry.get("difficulty", "real") != "real":
		var dd: Dictionary = Grit.DIFFICULTY[entry["difficulty"]]
		sbox.add_child(U.lbl("%s Played on %s" % [dd["icon"], dd["name"]], "Dim", 15))
	sv.add_child(scroll)
	row.add_child(sc)


func _on_transformed(kind: String) -> void:
	if fx_layer == null or not is_instance_valid(fx_layer):
		return
	match kind:
		"vampire": Moments.fire("turn_vampire")
		"witch": Moments.fire("turn_witch")
		"super": Moments.fire("turn_super")
		"royal_consort", "crowned": Moments.fire("turn_royal")
		_: Moments.fire("turn_other")
	call_deferred("_sync_life_theme")


func _rise() -> void:
	Moments.fire("turn_undead")
	Lives.rise()
	panel_stack.clear()
	last_stats.clear()
	SaveManager.save_game()
	_show("game")
	_pump()


func _continue_as_child() -> void:
	var heirs := GameState.heirs()
	if heirs.is_empty():
		return
	if heirs.size() == 1:
		_do_continue(heirs[0])
		return
	var opts: Array = []
	for id in heirs:
		var n := GameState.npc(id)
		var hid: String = id
		opts.append(["%s %s (%s, %d)" % [U.npc_face(n), n["first"], GameState.relation_label(id), int(n["age"])], func(): _do_continue(hid)])
	_show_menu_popup("👪", "Choose an heir", "Who carries on the family name?", opts)


func _do_continue(id: String) -> void:
	popup_open = false
	overlay.visible = false
	GameState.continue_as(id)
	panel_stack.clear()
	SaveManager.save_game()
	_show("game")


# ================================================================= GRAVEYARD

func _build_graveyard_shell() -> Control:
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 40)
	var v := U.vb(16)
	v.name = "GraveBox"
	m.add_child(v)
	return m


func _open_graveyard() -> void:
	_show("graveyard")
	_fill_graveyard()


func _fill_graveyard() -> void:
	var v := screens["graveyard"].find_child("GraveBox", true, false) as VBoxContainer
	U.clear(v)
	var head := U.hb()
	head.add_child(U.btn("‹  Back", func(): _show("game" if GameState.is_alive() else "title"), "Row"))
	var t := U.lbl("🪦  Graveyard", "Title")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(t)
	v.add_child(head)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var fl := HFlowContainer.new()
	fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fl.add_theme_constant_override("h_separation", U.sp(16))
	fl.add_theme_constant_override("v_separation", U.sp(16))
	sc.add_child(fl)
	v.add_child(sc)
	if SaveManager.graveyard.is_empty():
		v.add_child(U.lbl("Nobody rests here yet.", "Dim", 20))
		return
	var list := SaveManager.graveyard.duplicate()
	list.reverse()
	for e in list:
		var card := U.card()
		card.custom_minimum_size = Vector2(400, 0)
		var cv := U.vb(6)
		card.add_child(cv)
		var r: Dictionary = e.get("ribbon", {})
		cv.add_child(U.lbl("🪦  " + str(e["name"]) + ("  " + str(e.get("badge", "")) if e.get("badge", "") != "" else ""), "Heading"))
		if e.get("modified", false):
			cv.add_child(U.lbl("🧪 Modified life", "Dim", 14))
		cv.add_child(U.lbl("%d – %d  ·  Age %d  ·  Gen %d" % [int(e["born"]), int(e["died"]), int(e["age"]), int(e.get("generation", 1))], "Dim", 16))
		cv.add_child(U.lbl("Died of %s" % e["cause"], "", 16))
		cv.add_child(U.lbl("%s %s" % [r.get("icon", ""), r.get("name", "")], "Bold", 18))
		var story: String = e.get("story", "")
		var nm: String = e["name"]
		cv.add_child(U.btn("Read life story", func(): _show_info("📜", nm, story, {}), "Row"))
		fl.add_child(card)


# ================================================================= TIER 2 PANELS

func _sync_life_theme() -> void:
	if not GameState.has_life() or _current_screen() != "game" or mg_open:
		return
	var p := GameState.player
	var target := ""
	if p.get("alive", false) and bool(GameState.settings.get("life_theme", true)):
		match Lives.kind():
			"vampire": target = "vampire"
			"revenant": target = "undead"
			"witch": target = "witch"
			"royal": target = "royal" if Lives.life().get("crowned", false) or not Lives.life().get("abdicated", false) else ""
			"super": target = "villain" if Lives.life().get("side", "hero") == "villain" else "superhero"
	if target == "" and p.get("alive", false) and p.get("celebrity", false) and bool(GameState.settings.get("celeb_theme", true)):
		target = "celebrity"
	var want := target != ""
	if want and ThemeManager.current != target:
		life_theme_on = true
		ThemeManager.call_deferred("apply", target)
	elif not want and life_theme_on:
		life_theme_on = false
		ThemeManager.call_deferred("apply", GameState.settings.get("theme", "dark"))


func _info_card(lines: Array) -> PanelContainer:
	var c := U.card("Inset")
	var v := U.vb(6)
	c.add_child(v)
	for l in lines:
		if l is Control:
			v.add_child(l)
		else:
			v.add_child(U.lbl(l[0], l[1], l[2], true))
	return c


func _kv(k: String, val: String) -> HBoxContainer:
	var h := U.hb()
	h.add_child(U.lbl(k, "", 16))
	h.add_child(U.spacer())
	h.add_child(U.lbl(val, "Bold", 16))
	return h


func _stat_row(label: String, value: float, key: String = "happiness") -> HBoxContainer:
	var h := U.hb(10)
	var l := U.lbl(label, "", 16)
	l.custom_minimum_size = Vector2(130, 0)
	h.add_child(l)
	h.add_child(U.bar(value, ThemeManager.bar_color(key, value), 14))
	var pl := U.lbl("%d" % int(value), "Bold", 16)
	pl.custom_minimum_size = Vector2(40, 0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(pl)
	return h


# ---- special careers

func _panel_special_hub() -> void:
	_panel_header("⭐", "Special Careers")
	_add(U.lbl("One special career at a time. Most are full-time and replace a regular job; Mafia and Street Hustler can run on the side. Every career has its own minigame, and what you learn carries over to the next one.", "Dim", 15, true))
	for id in Careers.CAREERS.keys():
		var d: Dictionary = Careers.CAREERS[id]
		var why := Careers.join_requirement(id)
		var cid: String = id
		var mine := Careers.has_career(id)
		var sub: String = d["desc"]
		if mine:
			sub = "Your career · " + Careers.title()
		elif why != "":
			sub = "🔒 " + why
		if mine:
			_add(U.row(d["icon"], d["name"], sub, func(): _open_panel(_panel_career)))
		else:
			_add(U.row(d["icon"], d["name"], sub, _act(func(): Careers.join(cid)), why == ""))


func _panel_career() -> void:
	var c := Careers.career()
	if c.is_empty():
		_panel_back()
		return
	var d: Dictionary = Careers.CAREERS[c["id"]]
	_panel_header(d["icon"], d["name"])
	var info: Array = []
	var head := U.lbl(Careers.title(), "Heading", 22, true)
	info.append(head)
	var sub := ""
	match c["id"]:
		"actor":
			sub = "%d %s · %d %s · agent: %s" % [c["roles"].size(), "role" if c["roles"].size() == 1 else "roles", int(c["awards"]), "award" if int(c["awards"]) == 1 else "awards", ["none", "small agency", "top agent"][int(c["agent"])]]
		"musician":
			sub = ("Band: " + c["band"] if c.get("band", "") != "" else "Solo artist") + " · %d albums · %s" % [c["albums"].size(), "signed" if c["label"] else "independent"]
		"athlete":
			Ambition.ensure_sports(c)
			sub = "%s %s · %s · %d championships · career %d-%d" % [Careers.SPORTS[c["sport"]][0], Careers.SPORTS[c["sport"]][1], c["team"] if c["team"] != "" else "not drafted yet", int(c["titles"]), int(c.get("wins", 0)), int(c.get("losses", 0))]
			if not c.get("awards", []).is_empty():
				sub += " · " + ", ".join(c["awards"].slice(maxi(0, c["awards"].size() - 2)))
			if int(c["injured"]) > 0:
				sub += " · 🤕 injured"
		"politician":
			sub = ("In office · %d years left in term" % int(c["term_left"])) if c["in_office"] else "Not in office"
		"mafia":
			sub = "Member of %s" % c["family"]
		"hustler":
			sub = "Working the streets"
		"astronaut":
			sub = "%d mission%s flown" % [int(c["missions"]), "" if int(c["missions"]) == 1 else "s"]
		"model":
			sub = "%d runway shows · %s" % [int(c["shows"]), "signed to a top agency" if c["agency"] else "freelance"]
		"fighter":
			sub = "%s %s · record %d-%d · %d belt%s" % [c["nick"], c["class"], int(c["wins"]), int(c["losses"]), int(c["belts"]), "" if int(c["belts"]) == 1 else "s"]
		"director":
			sub = "%d film%s · %d award%s%s" % [c["films"].size(), "" if c["films"].size() == 1 else "s", int(c["awards"]), "" if int(c["awards"]) == 1 else "s", (" · shooting \"%s\"" % c["project"]["title"]) if not c["project"].is_empty() else ""]
		"agent":
			sub = "Cover: %s · %d operations · %d assets" % [c["cover"], int(c["ops"]), c["assets"].size()]
	info.append(U.lbl(sub, "Dim", 15, true))
	info.append(_stat_row(d["skill"], float(c["skill"])))
	if c["id"] == "politician":
		info.append(_stat_row("Approval", float(c["approval"])))
	if float(GameState.player.get("heat", 0)) > 0:
		info.append(_stat_row("Heat", float(GameState.player["heat"]), "stress"))
	if float(GameState.player["fame"]) > 0:
		info.append(_stat_row("Fame", float(GameState.player["fame"])))
	info.append(U.lbl("Last year's income: %s" % GameState.fmt_money(int(c.get("income_last", 0))), "Dim", 15))
	_add(_info_card(info))
	if c["id"] == "actor" and not c["roles"].is_empty():
		_add(U.section("Filmography"))
		var roles: Array = c["roles"].duplicate()
		roles.reverse()
		for r in roles.slice(0, 6):
			var rec: String = r.get("reception", "in production")
			_add(U.lbl("🎞️ \"%s\" · %s · %s" % [r["title"], r["tier"], rec], "", 15, true))
	if c["id"] == "musician" and not c["albums"].is_empty():
		_add(U.section("Discography"))
		for a in c["albums"]:
			_add(U.lbl("📀 \"%s\" (%d) · %s sold%s" % [a["title"], int(a["year"]), Careers._fmt_big(int(a["sales"])), " · " + a["cert"] if a["cert"] != "" else ""], "", 15, true))
	_add(U.section("Actions"))
	for a in Careers.actions():
		var aid: String = a["id"]
		_add(U.row(a["icon"], a["name"], a.get("sub", ""), _act(func(): Careers.do_action(aid)), not a.get("off", false), false))


func _panel_social() -> void:
	MP.show("social:root")
	return
	_panel_header("📱", "Social Media")
	var p := GameState.player
	_add(_info_card([["%s followers" % Careers._fmt_big(Careers.followers()), "Heading", 22], ["Fame %d%s" % [int(p["fame"]), " · Celebrity" if p["celebrity"] else ""], "Dim", 15]]))
	for a in [["photo", "📷", "Post a photo", "A few new followers"], ["video", "🎥", "Post a video", "Small chance to go viral"], ["live", "🔴", "Go live", "Tips from viewers"], ["brand", "🤝", "Take a brand deal", "Needs Fame 30+"]]:
		var aid: String = a[0]
		_add(U.row(a[1], a[2], a[3], _act(func(): Careers.social_action(aid)), true, false))


# ---- legal

func _panel_licenses() -> void:
	_panel_header("🪪", "Licenses")
	for id in Law.LICENSES.keys():
		var l: Dictionary = Law.LICENSES[id]
		var have := Law.has_license(id)
		var lid: String = id
		var sub := "✅ Licensed" if have else "Age %d+ · test fee %s" % [int(l["age"]), GameState.fmt_money(int(l["fee"]))]
		_add(U.row(l["icon"], l["name"], sub, _act(func(): Law.take_test(lid)), not have, false))


## Everything you can set out to be, always listed, with exactly what each one
## needs. A locked row shows its whole checklist rather than a bare "Age 21+",
## because the point is to be able to work toward it.
func _panel_become() -> void:
	_panel_header("✨", "Become a…")
	_add(U.lbl("Paths can also find you on their own, if your life leans that way. This is the other door: go and ask. Applying costs time and money whether or not they say yes.", "Dim", 16, true))
	var cool := Become.cooling()
	if cool > 0:
		_add(U.lbl("⏳ You asked recently. Wait %d more year%s." % [cool, "" if cool == 1 else "s"], "Dim", 15, true))
	for r in Become.rows():
		var id: String = r["id"]
		var card := U.card("Inset")
		var v := U.vb(6)
		card.add_child(v)
		var h := U.hb(12)
		h.add_child(U.lbl(str(r["icon"]), "Emoji", 34))
		var tv := U.vb(1)
		tv.add_child(U.lbl(str(r["name"]), "Bold", 20))
		var bl := U.lbl(str(r["blurb"]), "Dim", 15, true)
		tv.add_child(bl)
		h.add_child(tv)
		h.add_child(U.spacer())
		if bool(r["met"]):
			var chance := int(round(float(r["odds"]) * 100.0))
			var cl := U.lbl("%d%%" % chance, "Bold", 22)
			cl.add_theme_color_override("font_color", ThemeManager.c("good") if chance >= 45 else (ThemeManager.c("warn") if chance >= 25 else ThemeManager.c("bad")))
			h.add_child(cl)
		v.add_child(h)
		v.add_child(U.lbl(str(r["how"]), "Dim", 14, true))
		# the checklist, with what is and is not true
		var reqs := U.vb(2)
		for li in r["lines"]:
			var okr := bool(li[0])
			var rl := U.lbl("%s %s" % ["✓" if okr else "✗", str(li[1])], "", 14)
			rl.add_theme_color_override("font_color", ThemeManager.c("good") if okr else ThemeManager.c("dim"))
			reqs.add_child(rl)
		v.add_child(reqs)
		var bits: Array = []
		if int(r["cost"]) > 0:
			bits.append(GameState.fmt_money(int(r["cost"])))
		bits.append("%d time" % int(r["time"]))
		if int(r["tried"]) > 0:
			bits.append("asked %d time%s before" % [int(r["tried"]), "" if int(r["tried"]) == 1 else "s"])
		v.add_child(U.lbl("Costs " + " · ".join(bits), "Dim", 14))
		var can := bool(r["met"]) and cool == 0 and int(GameState.player["money"]) >= int(r["cost"]) and not Actions._out_of_time_soft(int(r["time"]))
		var why := "Apply"
		if not bool(r["met"]):
			why = "Not eligible yet"
		elif cool > 0:
			why = "Asked too recently"
		elif int(GameState.player["money"]) < int(r["cost"]):
			why = "Cannot afford it"
		var b := U.btn(why, _act(func(): Become.apply(id)), "Primary" if can else "Row")
		b.disabled = not can
		v.add_child(b)
		_add(card)


## Four lenders, each with its own bar to clear, so credit and income finally
## decide something the player can feel.
func _panel_loans() -> void:
	_panel_header("🏦", "Borrow money")
	_add(U.lbl("Credit %d (%s)  ·  assessed on last year's income of %s" % [
		Grit.credit(), Grit.credit_label(), GameState.fmt_money(Lending.assessed_income())], "Dim", 16, true))
	var owing := Lending.debts()
	if not owing.is_empty():
		_add(U.section("What you already owe"))
		for i in range(owing.size()):
			var d: Dictionary = owing[i]
			var l: Dictionary = Lending.LENDERS[str(d["lender"])]
			var idx := i
			var sub := "%s left  ·  %s a year at %d%%" % [
				GameState.fmt_money(int(d["left"])), GameState.fmt_money(int(d["payment"])),
				int(round(float(d["rate"]) * 100.0))]
			if int(d.get("missed", 0)) > 0:
				sub += "  ·  ⚠️ %d missed" % int(d["missed"])
			var can_settle := int(GameState.player["money"]) >= int(d["left"])
			_add(U.row(str(l["icon"]), str(l["name"]),
				sub + ("  ·  tap to clear it in full" if can_settle else ""),
				_act(func(): Lending.settle(idx)), can_settle, false))
	_add(U.section("Who will lend to you"))
	for o in Lending.offers():
		var d2: Dictionary = o["def"]
		var oid: String = str(o["id"])
		if not bool(o["ok"]):
			_add(U.row(str(d2["icon"]), str(d2["name"]), "✗ " + " · ".join(o["reasons"]), func(): pass, false, false))
			continue
		var cap := int(o["cap"])
		var rate := int(round(float(o["rate"]) * 100.0))
		_add(U.lbl("%s %s — %s" % [str(d2["icon"]), str(d2["name"]), str(d2["desc"])], "Dim", 15, true))
		for frac in [0.25, 0.5, 1.0]:
			var amt := int(round(float(cap) * frac / 500.0)) * 500
			if amt < 500:
				continue
			var total := int(round(float(amt) * (1.0 + float(o["rate"]) * float(o["term"]))))
			var per := int(ceil(float(total) / float(o["term"])))
			_add(U.row("💵", "Borrow %s" % GameState.fmt_money(amt),
				"%d%% over %d years  ·  %s a year  ·  %s repaid in total" % [
					rate, int(o["term"]), GameState.fmt_money(per), GameState.fmt_money(total)],
				_act(func(): Lending.borrow(oid, amt)), true, false))


## Betting on the card, and the option to be on it. Taking the fight yourself is
## the same minigame the careers use, so it is a real fight rather than a roll.
func _panel_fight_bets() -> void:
	_panel_header("🥊", "Fight night")
	var p := GameState.player
	_add(U.lbl("A local card, four bouts, and a bookmaker who has seen everything. You can back somebody, or you can ask for a slot yourself.", "Dim", 16, true))
	_add(U.section("The card"))
	for b in Fights.card():
		var bid: String = str(b["id"])
		_add(U.lbl("%s  %s  vs  %s" % [str(b["icon"]), str(b["a"]), str(b["b"])], "Bold", 17))
		for side in ["a", "b"]:
			var who := str(b[side])
			var odds := float(b["odds_" + side])
			for stake in [100, 1000, 10000]:
				if int(p["money"]) < stake:
					continue
				var st: int = stake
				var sd: String = side
				_add(U.row("💵", "%s on %s" % [GameState.fmt_money(stake), who],
					"Pays %s if %s wins" % [GameState.fmt_money(int(round(float(stake) * odds))), who],
					_act(func(): Fights.bet(bid, sd, st)), true, false))
	_add(U.section("Or get in the ring"))
	var slot := Fights.own_slot()
	_add(U.lbl(str(slot["blurb"]), "Dim", 15, true))
	_add(U.row("🥋", "Take the fight", str(slot["sub"]),
		_act(func(): Fights.fight_yourself()), bool(slot["ok"]), false))


func _panel_lawsuit() -> void:
	_panel_header("⚖️", "Lawsuit")
	_add(U.lbl("Pick someone to sue. Winning depends on your lawyer and your smarts. They won't like you afterward.", "Dim", 15, true))
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"] or n.get("species", "human") != "human":
			continue
		var nid: String = id
		_add(U.row(U.npc_face(n), "%s (%s)" % [GameState.full_name(id), GameState.relation_label(id)], "", _act(func(): Law.sue(nid)), true, false))


# ---- money

func _panel_investments() -> void:
	_panel_header("🏦", "Savings & Investments")
	var p := GameState.player
	var w := GameState.world
	var mood: String = {"crash": "📉 The market crashed last year", "boom": "📈 The market boomed last year", "steady": "Markets were steady last year"}[w.get("market_mood", "steady")]
	_add(_info_card([_kv("Cash", GameState.fmt_money(int(p["money"]))), _kv("Savings (2.5%/yr)", GameState.fmt_money(int(p["savings"]))), _kv("Portfolio", GameState.fmt_money(Finance.investments_value())), U.lbl(mood, "Dim", 15)]))
	_add(U.section("Savings account"))
	for amt in [1000, 10000, 100000]:
		var a: int = amt
		_add(U.row("⬆️", "Deposit %s" % GameState.fmt_money(a), "", _act(func(): Finance.deposit(a)), int(p["money"]) >= a, false))
	_add(U.row("⬇️", "Withdraw everything", GameState.fmt_money(int(p["savings"])), _act(func(): Finance.withdraw(int(GameState.player["savings"]))), int(p["savings"]) > 0, false))
	_add(U.section("Stocks"))
	for s in Finance.STOCKS.keys():
		_add(_asset_row("stock", s))
	_add(U.section("Crypto"))
	for s in Finance.CRYPTO.keys():
		_add(_asset_row("crypto", s))


func _asset_row(kind: String, sym: String) -> Button:
	var d: Dictionary = (Finance.STOCKS if kind == "stock" else Finance.CRYPTO)[sym]
	var price := float(GameState.world["stocks" if kind == "stock" else "crypto"][sym])
	var ch := float(GameState.world["change"].get(sym, 0.0))
	var held := Finance.holding_value(kind, sym)
	var sub := "%s · %s%.0f%% last year" % [Finance.fmt_price(price), "+" if ch >= 0 else "", ch * 100]
	if held > 0:
		sub += " · you hold %s" % GameState.fmt_money(held)
	var k := kind
	var s := sym
	return U.row(d["icon"], "%s (%s)" % [d["name"], sym], sub, func(): _open_panel(func(): _panel_trade(k, s)))


func _panel_trade(kind: String, sym: String) -> void:
	var d: Dictionary = (Finance.STOCKS if kind == "stock" else Finance.CRYPTO)[sym]
	_panel_header(d["icon"], d["name"])
	var price := float(GameState.world["stocks" if kind == "stock" else "crypto"][sym])
	var held := Finance.holding_value(kind, sym)
	_add(_info_card([_kv("Price", Finance.fmt_price(price)), _kv("Your holding", GameState.fmt_money(held)), U.lbl(d.get("sector", "Cryptocurrency · very volatile"), "Dim", 15)]))
	for amt in [1000, 10000, 100000, 1000000]:
		var a: int = amt
		_add(U.row("🛒", "Buy %s worth" % GameState.fmt_money(a), "", _act(func(): Finance.buy(kind, sym, a)), int(GameState.player["money"]) >= a, false))
	_add(U.row("💵", "Sell all", GameState.fmt_money(held), _act(func(): Finance.sell_all(kind, sym)), held > 0, false))


func _panel_property() -> void:
	_panel_header("🏢", "Property")
	var p := GameState.player
	var props: Array = p["properties"]
	if not props.is_empty():
		_add(U.section("Your properties"))
		for i in range(props.size()):
			var pr: Dictionary = props[i]
			var tn := "No tenant" if pr.get("tenant", "") == "" else "Tenant: " + GameState.full_name(pr["tenant"])
			if int(pr["rent"]) == 0:
				tn = "Personal retreat"
			var idx := i
			_add(U.row(pr["icon"], pr["type"], "%s · %s · condition %d%%" % [GameState.fmt_money(int(pr["value"])), tn, int(pr["condition"])], func(): _open_panel(func(): _panel_property_detail(idx))))
	_add(U.section("For sale this year"))
	var ls := Finance.listings()
	for i in range(ls.size()):
		var l: Dictionary = ls[i]
		var idx2 := i
		var sub := "%s · rent %s/yr · condition %d%%" % [GameState.fmt_money(int(l["price"])), GameState.fmt_money(int(l["rent"])), int(l["condition"])]
		if int(l["rent"]) == 0:
			sub = "%s · parties, privacy, a place to hide" % GameState.fmt_money(int(l["price"]))
		_add(U.row(l["icon"], l["type"], sub, _act(func(): Finance.buy_property(idx2)), int(p["money"]) >= int(l["price"]), false))


func _panel_property_detail(idx: int) -> void:
	var props: Array = GameState.player["properties"]
	if idx >= props.size():
		_panel_back()
		return
	var pr: Dictionary = props[idx]
	_panel_header(pr["icon"], pr["type"])
	_add(_info_card([_kv("Value", GameState.fmt_money(int(pr["value"]))), _kv("Rent", GameState.fmt_money(int(pr["rent"])) + " / year"), _stat_row("Condition", float(pr["condition"])), U.lbl("Tenant: " + (GameState.full_name(pr["tenant"]) if pr.get("tenant", "") != "" else "none"), "Dim", 15)]))
	if int(pr["rent"]) > 0:
		if pr.get("tenant", "") == "":
			_add(U.row("🔑", "Find a tenant", "", _act(func(): Finance.find_tenant(pr)), true, false))
		else:
			_add(U.row("📈", "Raise rent 10%", "Your tenant may leave", _act(func(): Finance.raise_rent(pr)), true, false))
			_add(U.row("🚪", "Evict tenant", "", _act(func(): Finance.evict(pr)), true, false))
	else:
		_add(U.row("🎉", "Throw an island party", "Fame and fun, costs $250,000", _act(func(): _island_party()), int(GameState.player["money"]) >= 250000, false))
		_add(U.row("🕶️", "Lie low on the island", "Heat drops to zero", _act(func(): _island_hide()), float(GameState.player.get("heat", 0)) > 0, false))
	_add(U.row("🔨", "Renovate", "About 8% of value", _act(func(): Finance.renovate(pr)), true, false))
	_add(U.row("💲", "Sell", "", _act(func(): Finance.sell_property(idx); _panel_back_to_root()), true, false))


func _island_party() -> void:
	var ch := GameState.apply_effects({"money": -250000, "fame": 6, "happiness": 10})
	GameState.add_log("I threw a legendary party on my private island.")
	EventEngine.push_info("🏝️", "Island party", "Yachts, a live band and fireworks over the lagoon. People will talk about this for years.", ch)


func _island_hide() -> void:
	GameState.player["heat"] = 0.0
	GameState.add_log("I disappeared to my island until things cooled down.")
	EventEngine.push_info("🏝️", "Off the grid", "Nobody can find you out here. Your heat is gone.")


func _panel_possessions() -> void:
	_panel_header("📦", "Possessions")
	var p := GameState.player
	var items: Array = p["possessions"]
	if items.is_empty():
		_add(U.lbl("You don't own anything special yet.", "Dim", 16))
	for i in range(items.size()):
		var it: Dictionary = items[i]
		var idx := i
		var tag := " · 🏺 heirloom" if it.get("heirloom", false) else ""
		if int(it.get("run", 0)) > 0:
			tag += " · #%d of %d" % [int(it.get("serial", 1)), int(it["run"])]
		elif int(it.get("reissue", 0)) > 0:
			tag += " · %d reissue" % int(it["reissue"])
		_add(U.row(it["icon"], it["name"], "Worth %s (paid %s)%s · tap to sell" % [GameState.fmt_money(int(it["value"])), GameState.fmt_money(int(it["bought"])), tag], _act(func(): Finance.sell_item(idx)), true, false))
		if str(it.get("story", "")) != "":
			_add(U.lbl("      " + str(it["story"]), "Dim", 14, true))
	_add(U.row("🛍️", "Go shopping", "Jewelry, art, collectibles, vehicles", func(): _open_panel(_panel_shop)))


func _panel_shop() -> void:
	_panel_header("🛍️", "Shopping")
	var cat := ""
	for i in range(Finance.SHOP.size()):
		var s: Dictionary = Finance.SHOP[i]
		if s["cat"] != cat:
			cat = s["cat"]
			_add(U.section(cat))
		var price := int(int(s["price"]) * float(ContentDB.country(GameState.player["country"]).get("cost", 1.0)))
		var idx := i
		var risk := "value is volatile" if float(s["vol"]) >= 0.3 else "holds value"
		_add(U.row(s["icon"], s["name"], "%s · %s" % [GameState.fmt_money(price), risk], _act(func(): Finance.buy_item(idx)), int(GameState.player["money"]) >= price, false))


# ---- meta

func _panel_challenges() -> void:
	_panel_header("🏅", "Challenges")
	_add(U.lbl("Pick a challenge on the New Life screen. Completing one earns a badge that shows next to your name.", "Dim", 15, true))
	for c in Meta.challenges:
		var done: int = int(Meta.meta["challenges_done"].get(c["id"], 0))
		var goals := " · ".join(c["goals"].map(func(gl): return gl["label"]))
		_add(U.row(c["icon"], c["name"] + ("  ✓ ×%d" % done if done > 0 else ""), c["desc"] + " — " + goals, func(): pass, true, false))


func _panel_ribbons() -> void:
	_panel_header("🎀", "Ribbon Collection")
	var got := 0
	for r in GameState.ALL_RIBBONS:
		if Meta.meta["ribbons"].has(r[0]):
			got += 1
	_add(U.lbl("%d of %d ribbons earned in unmodified lives." % [got, GameState.ALL_RIBBONS.size()], "Dim", 15, true))
	for r in GameState.ALL_RIBBONS:
		var n: int = int(Meta.meta["ribbons"].get(r[0], 0))
		var nm: int = int(Meta.meta["ribbons_modified"].get(r[0], 0))
		var sub := ""
		if n > 0:
			sub = "Earned ×%d" % n
		if nm > 0:
			sub += ("" if sub == "" else " · ") + "×%d in modified lives" % nm
		if n == 0 and nm == 0:
			_add(U.row("❔", "???", "Not earned yet", func(): pass, false, false))
		else:
			_add(U.row(r[1], r[0], sub, func(): pass, true, false))


func _panel_god() -> void:
	_panel_header("🧙", "God Mode")
	_add(U.lbl("Edit anyone. Using God Mode tags this life as Modified.", "Dim", 15, true))
	var p := GameState.player
	_add(U.row(U.face(p["gender"], int(p["age"]), int(p["face"])), "You", "Stats, money, traits", func(): _open_panel(func(): _panel_god_edit(""))))
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"]:
			continue
		var nid: String = id
		_add(U.row(U.npc_face(n), "%s (%s)" % [GameState.full_name(id), GameState.relation_label(id)], "", func(): _open_panel(func(): _panel_god_edit(nid))))


func _god_mark() -> void:
	if not GameState.player["modified"]:
		GameState.player["modified"] = true
		GameState.add_log("🧙 A mysterious force reshaped my life.")


func _god_slider(label: String, value: float, lo: float, hi: float, cb: Callable) -> HBoxContainer:
	var h := U.hb(10)
	var l := U.lbl(label, "", 16)
	l.custom_minimum_size = Vector2(120, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.focus_mode = UIKit.fm()
	var vl := U.lbl(str(int(value)), "Bold", 16)
	vl.custom_minimum_size = Vector2(44, 0)
	s.value_changed.connect(func(val): vl.text = str(int(val)); cb.call(val); _god_mark(); _refresh_side())
	h.add_child(s)
	h.add_child(vl)
	return h


func _panel_god_edit(id: String) -> void:
	var p := GameState.player
	if id == "":
		_panel_header("🧙", "Edit yourself")
		for k in GameState.STAT_KEYS:
			var key: String = k
			_add(_god_slider(U.STAT_NAMES[k], GameState.stat(k), 0, 100, func(v): GameState.player["stats"][key] = float(v)))
		_add(_god_slider("Karma", float(p["karma"]), -100, 100, func(v): GameState.player["karma"] = int(v)))
		_add(_god_slider("Fame", float(p["fame"]), 0, 100, func(v): GameState.player["fame"] = float(v)))
		if not p["career"].is_empty():
			_add(_god_slider(Careers.CAREERS[p["career"]["id"]]["skill"], float(p["career"]["skill"]), 0, 100, func(v): GameState.player["career"]["skill"] = float(v)))
		_add(U.section("Money"))
		for amt in [10000, 1000000, 100000000]:
			var a: int = amt
			_add(U.row("💵", "Add %s" % GameState.fmt_money(a), "", _act(func(): GameState.player["money"] = int(GameState.player["money"]) + a; _god_mark()), true, false))
		_add(U.row("🧹", "Clear debts and record", "", _act(func(): GameState.player["loan"] = 0; GameState.player["record"] = []; GameState.player["money"] = maxi(0, int(GameState.player["money"])); _god_mark()), true, false))
		_add(U.section("Traits (tap to toggle)"))
		for t in ContentDB.traits:
			var tn: String = t["name"]
			var has: bool = p["traits"].has(tn)
			_add(U.row(t["icon"], tn + ("  ✓" if has else ""), t["desc"], _act(func(): _god_toggle_trait(tn)), true, false))
	else:
		var n := GameState.npc(id)
		_panel_header(U.npc_face(n), n["first"])
		_add(_god_slider("Relationship", float(n["closeness"]), 0, 100, func(v): GameState.npcs[id]["closeness"] = int(v)))
		_add(_god_slider("Looks", float(n.get("looks", 50)), 0, 100, func(v): GameState.npcs[id]["looks"] = int(v)))
		_add(_god_slider("Age", float(n["age"]), 0, 110, func(v): GameState.npcs[id]["age"] = int(v)))
		_add(U.row("💵", "Give them $100,000", "", _act(func(): GameState.npcs[id]["money"] = int(GameState.npcs[id]["money"]) + 100000; _god_mark()), true, false))


func _god_toggle_trait(tn: String) -> void:
	var tr: Array = GameState.player["traits"]
	if tr.has(tn):
		tr.erase(tn)
	else:
		tr.append(tn)
	_god_mark()


func _panel_settings() -> void:
	_panel_header("⚙️", "Settings")
	for c in _settings_rows(func(): _render_top_panel()):
		_add(c)


func _show_settings_popup() -> void:
	var v := _big_popup(760, "⚙️", "Settings")
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 720)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var box := U.vb(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(box)
	for c in _settings_rows(_show_settings_popup):
		box.add_child(c)


func _settings_rows(redraw: Callable) -> Array:
	var s := GameState.settings
	var out: Array = [U.section("Sound")]
	for sl in [["volume", "🔊 Master", 70], ["music_vol", "🎵 Music", 45], ["sfx_vol", "💥 Effects", 80], ["ui_vol", "🖱️ Interface", 65]]:
		var key: String = sl[0]
		out.append(_god_slider_plain(sl[1], float(s.get(key, sl[2])), func(v):
			GameState.settings[key] = int(v)
			Fx.apply_volumes()
			SaveManager.save_settings()))
	out.append(U.section("Measurements"))
	var usys: String = Units.system()
	var udef: Dictionary = Units.SYSTEMS[usys]
	out.append(U.row(udef["icon"], "Units: %s" % udef["name"], "%s · tap to cycle. Money always follows the country you live in." % udef["desc"], func():
		var keys: Array = Units.SYSTEMS.keys()
		var idx: int = keys.find(Units.system())
		Units.set_system(str(keys[(idx + 1) % keys.size()]))
		redraw.call(), true, false))
	if GameState.has_life():
		var cur: Dictionary = GameState.currency()
		out.append(U.row("💱", "Currency: %s" % cur["code"], "%s lives in %s, so money is counted in %s. Emigrating changes the currency, not what you own." % [GameState.player["first"], ContentDB.country(GameState.player["country"])["name"], cur["code"]], func(): pass, false, false))
	var pkey: String = str(s.get("mg_pace", "relaxed"))
	var pdef: Dictionary = Minigame.PACE.get(pkey, Minigame.PACE["relaxed"])
	out.append(U.row(pdef["icon"], "Minigame pace: %s" % pdef["name"], "%s · tap to cycle. Affects timing windows, not the questions in a test." % pdef["desc"], func():
		var keys: Array = Minigame.PACE.keys()
		var i: int = keys.find(str(GameState.settings.get("mg_pace", "relaxed")))
		GameState.settings["mg_pace"] = keys[(i + 1) % keys.size()]
		SaveManager.save_settings()
		redraw.call(), true, false))
	out.append(U.section("Display"))
	var fs: bool = s.get("fullscreen", false)
	out.append(U.row("🖥️", "Fullscreen: %s" % ("ON" if fs else "OFF"), "Native 1920×1080 layout that scales cleanly to 1440p, 4K and ultrawide", func():
		GameState.settings["fullscreen"] = not GameState.settings.get("fullscreen", false)
		SaveManager.save_settings()
		_apply_display()
		redraw.call(), true, false))
	var scale := float(s.get("ui_scale", 1.0))
	out.append(U.row("🔎", "Interface size: %d%%" % int(round(scale * 100)), "Tap to cycle 90 · 100 · 115 · 130%", func():
		var steps := [0.9, 1.0, 1.15, 1.3]
		var idx := steps.find(float(GameState.settings.get("ui_scale", 1.0)))
		GameState.settings["ui_scale"] = steps[(idx + 1) % steps.size()]
		SaveManager.save_settings()
		_apply_display()
		redraw.call(), true, false))
	out.append(U.lbl("Keyboard: Tab or the arrow keys move between things, Enter or Space selects, Esc goes back. Space ages up when nothing is selected. 1–6 open the main menus; in a pop-up, 1–9 pick a choice.", "Dim", 14, true))
	out.append(U.section("Effects and comfort"))
	for opt in [["effects", "✨", "Visual effects", "Particles, bursts and floating numbers", true], ["flashes", "⚡", "Screen flashes", "Bright full-screen flashes on big moments", true], ["shake", "📳", "Screen shake", "Shake on crashes, explosions and disasters", true], ["reduced_motion", "🐢", "Reduced motion", "Fewer animations and transitions", false], ["high_contrast", "🔳", "High contrast", "Brighter secondary text and heavier outlines", false], ["minigames", "🎮", "Career minigames", "Play them yourself. OFF lets your skill decide", true], ["life_theme", "🧛", "Life Path themes", "Switch look and sound when you become a vampire, witch, royal and so on", true], ["celeb_theme", "⭐", "Celebrity theme when famous", "Switch to the Celebrity look at 88+ fame", true]]:
		var key: String = opt[0]
		var dflt: bool = opt[4]
		var on: bool = s.get(key, dflt)
		out.append(U.row(opt[1], "%s: %s" % [opt[2], "ON" if on else "OFF"], opt[3], func():
			GameState.settings[key] = not GameState.settings.get(key, dflt)
			SaveManager.save_settings()
			if key == "life_theme" or key == "celeb_theme":
				_sync_life_theme()
			if key == "high_contrast":
				ThemeManager.set_contrast(GameState.settings.get("high_contrast", false))
			redraw.call(), true, false))
	out.append(U.row("🎨", "Theme: " + ThemeManager.LABELS[ThemeManager.current], "Tap to switch", func(): _set_theme(ThemeManager.next_theme()), true, false))
	return out


## The three-column game screen needs about 1630 logical pixels. A larger
## interface size shrinks the logical screen, so below that width the columns
## give up some of their minimum width instead of running off the edge.
func _fit_layout() -> void:
	if not g.has("left_col") or not is_instance_valid(g["left_col"]):
		return
	var w := get_viewport().get_visible_rect().size.x
	var compact := w < 1680.0
	var tight := w < 1380.0
	(g["left_col"] as Control).custom_minimum_size.x = (310.0 if tight else 350.0) if compact else 470.0
	(g["right_col"] as Control).custom_minimum_size.x = (380.0 if tight else 410.0) if compact else 540.0
	var q := 96.0 if not compact else (86.0 if tight else 100.0)
	for k in ["quick_left", "quick_right"]:
		if g.has(k) and is_instance_valid(g[k]):
			(g[k] as Control).custom_minimum_size.x = 150.0 if not compact else q
	if g.has("age_btn") and is_instance_valid(g["age_btn"]):
		(g["age_btn"] as Control).custom_minimum_size = Vector2(140.0 if not compact else (104.0 if tight else 116.0), 140.0)


func _apply_display() -> void:
	var s := GameState.settings
	if ThemeManager.high_contrast != bool(s.get("high_contrast", false)):
		ThemeManager.set_contrast(bool(s.get("high_contrast", false)))
	get_tree().root.content_scale_factor = float(s.get("ui_scale", 1.0))
	_fit_layout.call_deferred()
	if DisplayServer.get_name() == "headless":
		return
	var w := get_window()
	if w == null:
		return
	var want := Window.MODE_FULLSCREEN if s.get("fullscreen", false) else Window.MODE_WINDOWED
	if w.mode != want:
		w.mode = want
		# Leaving fullscreen can land the window at the wrong size on some
		# platforms, so the windowed size is restored explicitly.
		if want == Window.MODE_WINDOWED:
			w.size = Vector2i(1600, 900)
			w.move_to_center()


func _god_slider_plain(label: String, value: float, cb: Callable) -> HBoxContainer:
	var h := U.hb(10)
	var l := U.lbl(label, "", 16)
	l.custom_minimum_size = Vector2(140, 0)
	h.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = 100
	sl.value = value
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.focus_mode = UIKit.fm()
	sl.value_changed.connect(func(val): cb.call(val))
	h.add_child(sl)
	return h


# ================================================================= GRIT & GLORY

func _twist_banner(v: VBoxContainer) -> void:
	# A turning point used to be an ordinary card with a red line of text on top,
	# which is easy to click straight through. It now gets a rule above and below,
	# its own colour, and a confirmation on the way out.
	var top := ColorRect.new()
	top.color = ThemeManager.c("bad")
	top.custom_minimum_size = Vector2(0, 4)
	v.add_child(top)
	var ban := U.lbl("⚡  TURNING POINT  ⚡", "Bold", 24)
	ban.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ban.add_theme_color_override("font_color", ThemeManager.c("bad"))
	v.add_child(ban)
	var sub := U.lbl("This could change everything. There is no going back on it.", "Dim", 15)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var bot := ColorRect.new()
	bot.color = Color(ThemeManager.c("bad"), 0.35)
	bot.custom_minimum_size = Vector2(0, 2)
	v.add_child(bot)
	Fx.play("twist")
	VFX.flash(fx_layer, ThemeManager.c("bad"), 0.35, 0.8)
	VFX.shake(shake_root, 7.0, 0.45)


func _toast(icon: String, head: String, body: String, col: Color) -> void:
	if fx_layer == null or not is_instance_valid(fx_layer):
		return
	var card := PanelContainer.new()
	card.theme_type_variation = "EventFrame"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := U.hb(12)
	card.add_child(h)
	var strip := ColorRect.new()
	strip.color = col
	strip.custom_minimum_size = Vector2(6, 58)
	h.add_child(strip)
	h.add_child(U.lbl(icon, "Emoji", 36))
	var tv := U.vb(0)
	var hl := U.lbl(head, "Dim", 14)
	hl.add_theme_color_override("font_color", col)
	tv.add_child(hl)
	var bl := U.lbl(body, "Bold", 19, true)
	bl.custom_minimum_size = Vector2(390, 0)
	tv.add_child(bl)
	h.add_child(tv)
	card.custom_minimum_size = Vector2(480, 0)
	U._ignore_all(card)
	fx_layer.add_child(card)
	var slot := toasts_live
	toasts_live += 1
	var x := get_viewport_rect().size.x / 2.0 - 240.0
	card.position = Vector2(x, -100)
	var tw := card.create_tween()
	tw.tween_property(card, "position:y", 20.0 + slot * 92.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(3.2)
	tw.tween_property(card, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		toasts_live = maxi(0, toasts_live - 1)
		card.queue_free())
	Fx.play("achieve")


## An achievement used to slide in as one more toast, indistinguishable from a
## mission reminder. Now it takes the screen for a moment: the card lands, the
## colour of its tier washes over everything, and the higher tiers get a real
## fanfare and a shower. Bronze stays modest, because most of them are bronze.
func _toast_ach(a: Dictionary) -> void:
	var tier: String = a.get("tier", "bronze")
	var col: Color = Goals.TIER_COLORS[tier]
	var stars: int = int(Goals.TIER_STARS[tier])
	var big := tier in ["gold", "platinum", "legendary", "diamond"]
	_ach_card(a, tier, col, stars, big)
	if big:
		Moments.fire("achievement", 1.0)
		if fx_layer != null and is_instance_valid(fx_layer):
			VFX.burst(fx_layer, "sparks", 18)
	else:
		Moments.fire("achievement", 0.55)


func _ach_card(a: Dictionary, tier: String, col: Color, stars: int, big: bool) -> void:
	if fx_layer == null or not is_instance_valid(fx_layer):
		return
	var card := PanelContainer.new()
	card.theme_type_variation = "EventFrame"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := U.vb(6)
	card.add_child(v)
	var top := U.lbl("🏆  ACHIEVEMENT UNLOCKED", "Bold", 15)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_theme_color_override("font_color", col)
	v.add_child(top)
	var rule := ColorRect.new()
	rule.color = Color(col, 0.6)
	rule.custom_minimum_size = Vector2(0, 2)
	v.add_child(rule)
	var h := U.hb(14)
	var ic := U.lbl(str(a["icon"]), "Emoji", 58)
	h.add_child(ic)
	var tv := U.vb(2)
	var nm := U.lbl(str(a["name"]), "Title", 24)
	nm.custom_minimum_size = Vector2(340, 0)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(nm)
	if str(a.get("desc", "")) != "":
		var ds := U.lbl(str(a["desc"]), "Dim", 15, true)
		ds.custom_minimum_size = Vector2(340, 0)
		tv.add_child(ds)
	tv.add_child(U.lbl("%s  ·  +%d ⭐" % [tier.capitalize(), stars], "Bold", 15))
	h.add_child(tv)
	v.add_child(h)
	card.custom_minimum_size = Vector2(560 if big else 500, 0)
	U._ignore_all(card)
	fx_layer.add_child(card)
	var slot := toasts_live
	toasts_live += 1
	var win := get_viewport_rect().size
	card.position = Vector2(win.x / 2.0 - (280.0 if big else 250.0), -140.0)
	card.pivot_offset = Vector2(280.0 if big else 250.0, 60.0)
	card.scale = Vector2(0.82, 0.82)
	var tw := card.create_tween().set_parallel(true)
	var rest := (win.y * 0.28 if big else 20.0 + slot * 92.0)
	tw.tween_property(card, "position:y", rest, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var out := card.create_tween()
	out.tween_interval(4.6 if big else 3.2)
	out.tween_property(card, "modulate:a", 0.0, 0.4)
	out.tween_callback(func():
		toasts_live = maxi(0, toasts_live - 1)
		card.queue_free())
	if big:
		VFX.flash(fx_layer, col, 0.26, 0.7)


func _toast_mission(info: Dictionary) -> void:
	var period: String = info["period"]
	_toast("🎯", "%s mission complete · claim it in Missions" % Goals.PERIODS[period]["name"], Goals.text(info["m"], period), ThemeManager.c("good"))


func _big_popup(width: int, icon: String, title: String, sub: String = "") -> VBoxContainer:
	popup_open = true
	overlay.visible = true
	overlay_frame.custom_minimum_size = Vector2(width, 0)
	U.clear(overlay_box)
	var head := U.hb(10)
	head.add_child(U.lbl(icon, "Emoji", 30))
	var tv := U.vb(0)
	tv.add_child(U.lbl(title, "Title"))
	if sub != "":
		tv.add_child(U.lbl(sub, "Dim", 15))
	head.add_child(tv)
	head.add_child(U.spacer())
	var close := U.btn("Close", _close_popup, "Row")
	close.name = "OkButton"
	head.add_child(close)
	overlay_box.add_child(head)
	VFX.pop_in(overlay_frame)
	var body := U.vb(12)
	overlay_box.add_child(body)
	return body


func _show_trophies() -> void:
	var g: Dictionary = Meta.meta["goals"]
	var v := _big_popup(1500, "🏆", "Trophy Room", "%d of %d unlocked  ·  ⭐ %d Stars  ·  %d earned in total" % [g["ach"].size(), Goals.achievements.size(), Goals.stars(), int(g["stars_total"])])
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", U.sp(6))
	tabs.add_theme_constant_override("v_separation", U.sp(6))
	v.add_child(tabs)
	var grp := ButtonGroup.new()
	for cdef in Goals.CATEGORIES:
		var cnt := Goals.count_in(cdef[0])
		var b := Button.new()
		b.theme_type_variation = "Toggle"
		b.toggle_mode = true
		b.button_group = grp
		b.focus_mode = UIKit.fm()
		b.text = "%s %s  %d/%d" % [cdef[1], cdef[2], cnt[0], cnt[1]]
		b.button_pressed = cdef[0] == trophy_cat
		var ck: String = cdef[0]
		b.pressed.connect(func():
			trophy_cat = ck
			_show_trophies())
		tabs.add_child(b)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 640)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", U.sp(10))
	grid.add_theme_constant_override("v_separation", U.sp(10))
	sc.add_child(grid)
	for a in Goals.achievements:
		if a.get("cat", "") != trophy_cat:
			continue
		grid.add_child(_trophy_tile(a))


func _trophy_tile(a: Dictionary) -> Control:
	var got := Goals.has(a["id"])
	var open := Goals.prereqs_met(a)
	var hidden: bool = a.get("hidden", false) and not got
	var tile := U.card("Inset")
	tile.custom_minimum_size = Vector2(196, 176)
	var tv := U.vb(4)
	tile.add_child(tv)
	var tier: String = a.get("tier", "bronze")
	var bar := ColorRect.new()
	bar.color = Goals.TIER_COLORS[tier] if got else Color(Goals.TIER_COLORS[tier], 0.3)
	bar.custom_minimum_size = Vector2(0, 5)
	tv.add_child(bar)
	var ic := U.lbl("❔" if hidden else (a["icon"] if open or got else "🔒"), "Emoji", 40)
	ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv.add_child(ic)
	var nm := U.lbl("???" if hidden else a["name"], "Bold", 16, true)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv.add_child(nm)
	var desc: String = "A secret. Keep living." if hidden else a["desc"]
	if not got and not open and not hidden:
		var names: Array = []
		for n in a.get("needs", []):
			names.append(Goals.by_id[n]["name"] if Goals.by_id.has(n) else n)
		desc = "Needs: " + ", ".join(names)
	var dl := U.lbl(desc, "Dim", 13, true)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv.add_child(dl)
	var foot := U.lbl(("✓ %s · +%d ⭐" % [tier.capitalize(), int(Goals.TIER_STARS[tier])]) if got else ("%s · %d ⭐" % [tier.capitalize(), int(Goals.TIER_STARS[tier])]), "", 12)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_color_override("font_color", Goals.TIER_COLORS[tier])
	tv.add_child(foot)
	if not got:
		tile.modulate = Color(1, 1, 1, 0.55 if open else 0.35)
	if got:
		tile.tooltip_text = "Unlocked by %s" % Meta.meta["goals"]["ach"][a["id"]].get("who", "")
	return tile


func _show_missions() -> void:
	var v := _big_popup(1500, "🎯", "Missions", "Progress counts across every life you play in the period  ·  ⭐ %d Stars" % Goals.stars())
	var cols := U.hb(14)
	v.add_child(cols)
	for period in ["daily", "weekly", "monthly"]:
		var pd: Dictionary = Goals.PERIODS[period]
		var b := Goals.board(period)
		var card := U.card("Inset")
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cols.add_child(card)
		var cv := U.vb(10)
		card.add_child(cv)
		var hh := U.hb()
		hh.add_child(U.lbl("%s" % pd["name"], "Heading", 22))
		hh.add_child(U.spacer())
		hh.add_child(U.lbl("⏳ resets in %s" % Goals.fmt_left(Goals.seconds_left(period)), "Dim", 14))
		cv.add_child(hh)
		cv.add_child(U.lbl("+%d ⭐ each · clear the board for +%d ⭐" % [int(pd["stars"]), int(pd["bonus"])], "Dim", 14))
		for id in b["ids"]:
			var m := Goals.mission(id)
			if m.is_empty():
				continue
			var t := Goals.target(m, period)
			var prog := minf(Goals.progress(period, id), t)
			var row := U.vb(4)
			var txt := U.lbl(Goals.text(m, period), "Bold", 16, true)
			row.add_child(txt)
			var ph := U.hb(8)
			ph.add_child(U.bar(prog / t * 100.0, ThemeManager.c("good") if prog >= t else ThemeManager.c("primary"), 10))
			var shown := (GameState.fmt_money(int(prog)) + " / " + GameState.fmt_money(int(t))) if m.get("money", false) else "%d / %d" % [int(prog), int(t)]
			ph.add_child(U.lbl(shown, "Dim", 13))
			row.add_child(ph)
			if b["claimed"].has(id):
				row.add_child(U.lbl("✓ Claimed", "Dim", 14))
			elif Goals.claimable(period, id):
				var per: String = period
				var mid: String = id
				var cb := U.btn("Claim +%d ⭐" % int(pd["stars"]), func():
					var n := Goals.claim(per, mid)
					_toast("⭐", "Mission reward", "+%d Stars" % n, ThemeManager.c("gold"))
					_show_missions(), "Accent")
				cb.custom_minimum_size = Vector2(0, 42)
				row.add_child(cb)
			cv.add_child(row)
			cv.add_child(HSeparator.new())
		if b["bonus"]:
			cv.add_child(U.lbl("🎉 Board cleared!", "Bold", 16))


func _show_star_shop() -> void:
	var g: Dictionary = Meta.meta["goals"]
	var v := _big_popup(1200, "⭐", "Star Shop", "You have ⭐ %d Stars. Earn more from achievements and missions." % Goals.stars())
	var cols := U.hb(16)
	v.add_child(cols)
	var lc := U.vb(8)
	lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(lc)
	lc.add_child(U.section("Titles (shown under your name)"))
	var tsc := ScrollContainer.new()
	tsc.custom_minimum_size = Vector2(0, 560)
	tsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lc.add_child(tsc)
	var tl := U.vb(6)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tsc.add_child(tl)
	tl.add_child(U.row("🚫", "No title", "Hide your title", func():
		Goals.set_title("")
		_show_star_shop(), true, false))
	var entries: Array = []
	for k in Goals.TITLES.keys():
		entries.append([k, Goals.TITLES[k]["name"], int(Goals.TITLES[k]["cost"]), ""])
	for a in Goals.achievements:
		if a.has("title"):
			entries.append([a["title"], a.get("title_name", a["title"]), -1, a["name"]])
	for e in entries:
		var tid: String = e[0]
		var owned: bool = g["titles"].has(tid)
		var equipped: bool = g["title"] == tid
		var sub := ""
		if equipped:
			sub = "✓ Equipped"
		elif owned:
			sub = "Owned · tap to wear"
		elif int(e[2]) >= 0:
			sub = "⭐ %d" % int(e[2])
		else:
			sub = "🏆 Unlock the \"%s\" achievement" % e[3]
		var ok := owned or (int(e[2]) >= 0 and Goals.stars() >= int(e[2]))
		tl.add_child(U.row("🎖️", e[1], sub, func():
			if Goals.owns_title(tid):
				Goals.set_title(tid)
			else:
				Goals.buy_title(tid)
			_show_star_shop(), ok, false))
	var rc := U.vb(8)
	rc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(rc)
	rc.add_child(U.section("Legacy Boons (pick them at New Life)"))
	rc.add_child(U.lbl("Boons are yours forever once bought. Choose which ones to bring into each new life.", "Dim", 14, true))
	for bk in Grit.BOONS.keys():
		var bd: Dictionary = Grit.BOONS[bk]
		var own := Goals.owns_boon(bk)
		var bkey: String = bk
		rc.add_child(U.row(bd["icon"], bd["name"], bd["desc"] + ("  ·  ✓ Owned" if own else "  ·  ⭐ %d" % int(bd["cost"])), func():
			Goals.buy_boon(bkey)
			_show_star_shop(), own or Goals.stars() >= int(bd["cost"]), false))


# ================================================================= MINIGAMES

func _build_mg_layer() -> void:
	mg_layer = Control.new()
	mg_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg_layer.visible = false
	mg_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(mg_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg_layer.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg_layer.add_child(cc)
	mg_frame = U.card("EventFrame")
	cc.add_child(mg_frame)
	mg_box = U.vb(14)
	mg_frame.add_child(mg_box)


func _on_minigame(id: String, params: Dictionary, cb: Callable) -> void:
	var d: Dictionary = Minigames.DEFS[id]
	mg_open = true
	mg_playing = false
	mg_layer.visible = true
	U.clear(mg_box)
	mg_frame.custom_minimum_size = Vector2(760, 0)
	var head := U.hb(14)
	head.add_child(U.lbl(d["icon"], "Emoji", 56))
	var tv := U.vb(2)
	tv.add_child(U.lbl(d["name"], "Title"))
	if params.has("title"):
		tv.add_child(U.lbl(str(params["title"]), "Dim", 16, true))
	head.add_child(tv)
	mg_box.add_child(head)
	var how := U.card("Inset")
	how.add_child(U.lbl(d["how"], "", 18, true))
	mg_box.add_child(how)
	var sk := float(params.get("skill", 50.0))
	mg_box.add_child(U.lbl("Your skill: %d · Auto-play rolls a result from your skill instead" % int(sk), "Dim", 15, true))
	var bh := U.hb(12)
	var play := U.btn("🎮  Play  [Enter]", func(): _mg_play(id, params, cb), "Primary")
	play.custom_minimum_size = Vector2(0, 58)
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(play)
	var auto := U.btn("⚡  Auto-play", func(): _mg_finish(cb, Minigames.auto_score(sk), {"auto": true}), "Row")
	auto.custom_minimum_size = Vector2(220, 58)
	bh.add_child(auto)
	mg_box.add_child(bh)
	mg_default = play
	Fx.play("choice")
	VFX.pop_in(mg_frame)


func _mg_play(id: String, params: Dictionary, cb: Callable) -> void:
	mg_playing = true
	U.clear(mg_box)
	# Minigames are authored at a fixed 1000x540 and the board is scaled to the
	# space available. In the normal setup the engine's own canvas stretch means
	# there is always room and the scale stays 1:1; this only bites if the
	# viewport is ever configured smaller than the board.
	var holder := Control.new()
	holder.clip_contents = true
	var game: Minigame = load(Minigames.DEFS[id]["script"]).new()
	game.setup(params)
	holder.add_child(game)
	mg_holder = holder
	mg_game = game
	mg_box.add_child(holder)
	_mg_fit()
	var on_done := func(score: float, detail: Dictionary) -> void:
		get_tree().create_timer(0.9).timeout.connect(func(): _mg_result(id, score, detail, cb))
	game.finished.connect(on_done)
	var give_up := func() -> void:
		if is_instance_valid(game) and not game.done:
			game.finish(0.05, {"quit": true})
	var quit := U.btn("Give up", give_up, "Flat")
	mg_box.add_child(quit)
	mg_default = null


## Fit the 1000x540 board into the window, uniformly, never above 1:1.
func _mg_fit() -> void:
	if mg_holder == null or not is_instance_valid(mg_holder) or mg_game == null or not is_instance_valid(mg_game):
		return
	var win := get_viewport_rect().size
	# Room left after the popup's own chrome: padding, the Give up button, and a
	# margin so the frame never runs off the edge of the screen.
	var avail := Vector2(maxf(320.0, win.x - 120.0), maxf(240.0, win.y - 190.0))
	var s := minf(1.0, minf(avail.x / Minigame.W, avail.y / Minigame.H))
	mg_game.scale = Vector2(s, s)
	mg_game.position = Vector2.ZERO
	mg_holder.custom_minimum_size = Vector2(Minigame.W * s, Minigame.H * s)
	mg_holder.size = mg_holder.custom_minimum_size
	mg_frame.custom_minimum_size = Vector2(minf(Minigame.W * s + 40.0, win.x - 40.0), 0)


func _mg_result(id: String, score: float, detail: Dictionary, cb: Callable) -> void:
	if not mg_open:
		return
	mg_playing = false
	U.clear(mg_box)
	mg_frame.custom_minimum_size = Vector2(620, 0)
	var ic := U.lbl(Minigames.DEFS[id]["icon"], "Emoji", 60)
	ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mg_box.add_child(ic)
	var gl := U.lbl(Minigames.grade(score), "EventTitle", 0, true)
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mg_box.add_child(gl)
	var st := Minigames.stars(score)
	var stars := U.lbl("★".repeat(st) + "☆".repeat(5 - st), "Bold", 46)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_color_override("font_color", ThemeManager.c("gold"))
	mg_box.add_child(stars)
	var sl := U.lbl("Score %d%%" % int(round(score * 100)), "Dim", 17)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mg_box.add_child(sl)
	var ok := U.btn("Continue  [Enter]", func(): _mg_finish(cb, score, detail), "Primary")
	ok.custom_minimum_size = Vector2(0, 56)
	mg_box.add_child(ok)
	mg_default = ok
	VFX.pop_in(mg_frame)
	if score >= 0.9:
		Fx.play("fanfare")
		VFX.burst(fx_layer, "confetti", 30)
	elif score >= 0.45:
		Fx.play("coin")
	else:
		Fx.play("bad")


func _mg_finish(cb: Callable, score: float, detail: Dictionary) -> void:
	mg_open = false
	mg_playing = false
	mg_default = null
	mg_layer.visible = false
	U.clear(mg_box)
	cb.call(score, detail)
	_refresh_side()
	_render_top_panel()
	_pump()


# ================================================================= REACTIONS

## Presentation is now decided by what happened, not by reading the sentence.
## The vocabulary, the sounds and the particle choices all live in
## autoload/moments.gd so any system can fire the same beats.
func _react(title: String, text: String, changes: Dictionary, signals: Array = []) -> void:
	Moments.react(title, text, changes, signals)
