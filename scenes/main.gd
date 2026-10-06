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
var title_section := 0
var tv_category := "Original"
var tv_search := ""
var tv_results: VBoxContainer
var mg_help_visible := false
var LP
var SP
var MP
var screen_tween: Tween
var NAV
var panel_positions: Array = []
var panel_names: Array = []
var panel_render_serial := 0
var mg_before := {}
var mg_title := ""


func _ready() -> void:
	ThemeManager.apply(GameState.settings.get("theme", "ink"))
	ThemeManager.theme_changed.connect(_on_theme_changed)
	GameState.changed.connect(_refresh_side)
	GameState.log_added.connect(_on_log_added)
	GameState.year_started.connect(_on_year_started)
	EventEngine.event_queued.connect(_pump)
	SaveManager.save_failed.connect(func(message): _toast("💾","Save needs attention",message,ThemeManager.c("accent")))
	EventEngine.died.connect(_on_died)
	ep = preload("res://scenes/empire_panels.gd").new(self)
	LP = preload("res://scenes/lives_panels.gd").new(self)
	SP = preload("res://scenes/slot_panels.gd").new(self)
	MP = preload("res://scenes/menu_panels.gd").new(self)
	NAV = preload("res://scenes/navigation.gd").new(self)
	_apply_display()
	get_viewport().size_changed.connect(_mg_fit)
	get_viewport().size_changed.connect(_fit_active_popup)
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
	if name_key != "game":
		Fx.set_mode("")
	if name_key == "title":
		_refresh_title()
	if name_key == "game":
		_rebuild_log()
		_refresh_side()
		if panel_stack.is_empty() or was != "game":
			_tab_press(0)
		else:
			_render_top_panel()
		_maybe_tutorial()
		_pump.call_deferred()


const TUTORIALS := {
	"tv": ["🎬", "Story Life", "Next Chapter continues your campaign. Choices shape the route and ending. Your journal saves each decision; finishing the story closes the campaign."],
	"human": ["🧭", "How a life works", "Your annual Time points renew on birthdays. Spend them on activities, people, work or assets. Find & favourites helps locate an option. Age advances monthly during infancy, then yearly. Costly bulk actions combine activities in their own sections.\n\nEvents will stop you with choices. There are no right answers, only consequences, some of which arrive years later.\n\nMore shows your remembered choices, measured consequences and upcoming follow-ups."],
	"pet": ["🐾", "How a pet's life works", "You can't make people do anything. You can change how they feel about you.\n\nSpend your Time on care, play, learning and the wider world, then Age Up. Bond is the number that matters most.\n\nThe pack tab appears once you have packmates or are old enough for a litter."],
	"prisoner": ["⛓️", "How a sentence works", "Respect, heat, conduct and support are the four numbers you live by.\n\nKeep your head down for the parole board, or build a plan for the wall. Everything you do is read by someone.\n\nThe Road tab shows your chapters. After the gate there are three more years to get through."],
	"guard": ["🗝️", "How the keys work", "Control, integrity and merit are what the job runs on. Everything on the wing is noticed by someone.\n\nThe keys offer favours; every favour is a debt. Internal Affairs keeps count.\n\nThe Road tab shows your chapters."],
}


func _maybe_tutorial() -> void:
	if OS.get_environment("OML_USER_DIR") != "" or not GameState.has_life() or int(GameState.player.get("age", 1)) > 1 or popup_open:
		return
	var k := "human"
	if Lives.separate():
		k = Lives.kind() if Lives.kind() in TUTORIALS else "human"
	var seen: Dictionary = Meta.meta.get("tutorials", {})
	if seen.has(k):
		return
	seen[k] = true
	Meta.meta["tutorials"] = seen
	Meta.save()
	var t: Array = TUTORIALS[k]
	_show_info(t[0], t[1], t[2], {})


func _current_screen() -> String:
	for k in screens.keys():
		if screens[k].visible:
			return k
	return ""


func _on_theme_changed() -> void:
	_remember_panel_scroll()
	var cur := _current_screen()
	var stack := panel_stack.duplicate()
	var positions := panel_positions.duplicate()
	var names := panel_names.duplicate()
	_build()
	if cur == "":
		cur = "title"
	_show(cur)
	if cur=="game":
		panel_stack=stack
		panel_positions=positions
		panel_names=names
		_render_top_panel()
	if cur == "death" and GameState.has_life():
		_fill_death(GameState.player.get("legacy", {}))
	if cur == "graveyard":
		_fill_graveyard()


# ================================================================= TITLE

func _build_title() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var c := CenterContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(c)
	var h := U.hb(64)
	c.add_child(h)
	var left := U.vb(14)
	left.name = "TitleBrand"
	left.custom_minimum_size = Vector2(520, 0)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(left)
	left.visible = get_viewport_rect().size.x >= 1400.0 and float(GameState.settings.get("ui_scale", 1.0)) < 1.4
	var emblem := TextureRect.new()
	emblem.name = "OneMoreLifeMark"
	emblem.texture = preload("res://assets/brand/mark.svg")
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.custom_minimum_size = Vector2(96,96)
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(emblem)
	var words := U.vb(-28)
	left.add_child(words)
	for word in ["ONE", "MORE", "LIFE"]:
		var l := U.lbl(word, "Huge", 88)
		if word == "MORE":
			l.add_theme_color_override("font_color", ThemeManager.c("primary").lightened(0.2))
		elif word == "LIFE":
			l.add_theme_color_override("font_color", ThemeManager.c("gold"))
		words.add_child(l)
	left.add_child(U.lbl("A life in chapters. Every choice leaves a trace.", "Dim", 24))
	left.add_child(U.lbl("Your choices. Your people. Your next chapter.", "Dim", 18, true))
	left.add_child(U.lbl("Mature themes · non-graphic storytelling", "Dim", 15, true))
	left.add_child(U.lbl("One More Life · v%s" % ProjectSettings.get_setting("application/config/version", "0.5.0"), "Dim", 15))
	var box := U.card("HubPanel")
	box.name = "TitleHub"
	box.custom_minimum_size = Vector2(720, 0)
	h.add_child(box)
	var bv := U.vb(10)
	box.add_child(bv)
	var compact_brand := U.hb(10)
	compact_brand.name = "CompactBrand"
	compact_brand.visible = not left.visible
	var compact_mark := TextureRect.new()
	compact_mark.texture = preload("res://assets/brand/mark.svg")
	compact_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	compact_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	compact_mark.custom_minimum_size = Vector2(40,40)
	compact_brand.add_child(compact_mark)
	compact_brand.add_child(U.lbl("One More Life","Title",28))
	bv.add_child(compact_brand)
	bv.add_child(U.lbl("PICK UP YOUR STORY", "Bold", 15))
	var resume_row := U.hb(12)
	resume_row.add_child(_title_button("⏯️", "Continue Life", _continue_life, "ContinueBtn"))
	resume_row.add_child(_title_button("📂", "Your Lives", func(): SP.show_lives(), "LivesBtn"))
	bv.add_child(resume_row)
	var resume_details := U.lbl("", "Dim", 15, true)
	resume_details.name = "ResumeDetails"
	bv.add_child(resume_details)
	bv.add_child(U.btn("❔ How to play",func(): _show_info("❔","How to play", "Start a Human Life for school, work and family; Pets and Prison have their own rules. Story Life follows branching original campaigns or fixed reference stories.\n\nContinue resumes your most recently played life. Your Lives lets you choose another save. Inside a life, Find & favourites helps locate activities, and ? explains the current mode.",{}),"Flat"))
	# The game modes come first and look different from the menu under them:
	# Each mode has its own simulation or story chapters.
	var modes_h := U.lbl("START A NEW LIFE", "Bold", 15)
	modes_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modes_h.add_theme_color_override("font_color", ThemeManager.c("gold"))
	bv.add_child(modes_h)
	var modes_row := GridContainer.new()
	modes_row.columns = 2
	modes_row.add_theme_constant_override("h_separation",10)
	modes_row.add_theme_constant_override("v_separation",10)
	bv.add_child(modes_row)
	var tile_styles := ["LifeTileHuman", "LifeTilePet", "LifeTileStory", "LifeTilePrison"]
	var tile_index := 0
	for md in [
		["NewLifeBtn", "🧑", "Human Life", "School, work, family and the life between.", func(): _open_new_life(), true, Color("#34c759")],
		["PetsBtn", "🐾", "Pets Life", "Small paws. A whole world of possibilities.", func(): _open_pet_setup(), true, Color("#4a90ff")],
		["TVLifeBtn", "📖", "Story Life", "Original worlds. Choices that change the ending.", func(): _open_tv_setup(), true, Color("#e7b36b")],
		["PrisonBtn", "⛓️", "Prison Life", "Inside the walls. On either side of the keys.", func(): _open_prison_setup(), true, Color("#ff5a5f")],
	]:
		var card := U.btn("", md[4], tile_styles[tile_index])
		tile_index += 1
		card.name = md[0]
		card.custom_minimum_size = Vector2(320, 144)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = "%s: %s" % [md[2], md[3]]
		var cv := U.vb(4)
		cv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cv.offset_left = 8
		cv.offset_right = -8
		cv.offset_top = 10
		cv.offset_bottom = -10
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ci := U.lbl(md[1], "Emoji", 34)
		ci.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ci.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(ci)
		var cn := U.lbl(md[2], "Bold", 20)
		cn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cn.add_theme_color_override("font_color", ThemeManager.c("text"))
		cn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(cn)
		var cd := U.lbl(md[3], "", 13, true)
		cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(cd)
		card.add_child(cv)
		if not md[5]:
			card.modulate = Color(1, 1, 1, 0.7)
		modes_row.add_child(card)
	bv.add_child(U.lbl("EXPLORE", "Bold", 15))
	bv.add_child(_title_button("🌱", "Fresh Start · scenario lives", _open_fresh_start, "FreshStartBtn"))
	var sections := TabContainer.new()
	sections.name = "TitleSections"
	sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bv.add_child(sections)
	var groups := [
		["Challenges", [["📅", "Daily challenge", func(): _start_seeded("daily"), "DailyBtn"], ["🗓️", "Weekly challenge", func(): _start_seeded("weekly"), "WeeklyBtn"]]],
		["Rewards", [["🎯", "Missions", _show_missions, "MissionBtn"], ["🎁", "Daily Heirloom", func(): SP.show_heirloom(), "HeirBtn"], ["⭐", "Star Shop", _show_star_shop, "StarBtn"], ["🏆", "Trophy Room", _show_trophies, "TrophyBtn"]]],
		["Preferences", [["⚙️", "Settings", _show_settings_popup, "SettingsBtn"], ["🎨", "Theme", _cycle_theme_title, "ThemeBtn"], ["🪦", "Graveyard", func(): _open_graveyard(), "GraveyardBtn"], ["🚪", "Quit", func(): get_tree().quit(), "QuitBtn"]]],
	]
	for group in groups:
		var page := U.vb(8)
		page.name = group[0]
		sections.add_child(page)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 8)
		page.add_child(grid)
		for item in group[1]:
			if OS.has_feature("web") and item[3] == "QuitBtn": continue
			grid.add_child(_title_button(item[0], item[1], item[2], item[3]))
	sections.current_tab = clampi(title_section, 0, 2)
	sections.tab_changed.connect(func(i: int): title_section = i)
	return scroll


func _title_button(icon: String, caption: String, cb: Callable, key: String) -> Button:
	var b := U.icon_btn(icon, caption, cb, "Row", false, 24, 18)
	b.name = key
	b.custom_minimum_size = Vector2(320, 56)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var text: Label = b.get_meta("label")
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return b


func _refresh_title() -> void:
	var t: Control = screens["title"]
	var cont := t.find_child("ContinueBtn", true, false) as Button
	if cont:
		cont.disabled = not SaveManager.has_save()
		var ls := SaveManager.latest_slot()
		var lc: Dictionary = SaveManager.card(ls) if ls > 0 else {}
		cont.get_meta("label").text = "Continue Life"
		cont.tooltip_text = ("Resume %s · age %d" % [lc.get("name", ""), int(lc.get("age", 0))]) if not lc.is_empty() and lc.get("alive", false) else "No saved life to continue"
	var details := t.find_child("ResumeDetails",true,false) as Label
	if details:
		var latest: Dictionary = SaveManager.card(SaveManager.latest_slot())
		details.text = ("%s · age %d · %s" % [latest.get("name",""),int(latest.get("age",0)),"Ready to continue" if latest.get("alive",false) else "Life completed; view the ending"]) if not latest.is_empty() else "Start a life below. Your progress will appear here."
	var lb := t.find_child("LivesBtn", true, false) as Button
	if lb:
		lb.get_meta("label").text = "Your Lives · %d / %d" % [SaveManager.cards().size(), SaveManager.SLOTS]
	var hb := t.find_child("HeirBtn", true, false) as Button
	if hb:
		hb.get_meta("label").text = "Daily Heirloom" + (" · ready" if Goals.daily_available() else "")
		hb.tooltip_text = "Ready to open" if Goals.daily_available() else "Next in " + Goals.fmt_left(Goals.seconds_left("daily"))
	for sk in ["daily", "weekly"]:
		var sb := t.find_child("DailyBtn" if sk == "daily" else "WeeklyBtn", true, false) as Button
		if sb:
			sb.get_meta("label").text = "Daily challenge" if sk == "daily" else "Weekly challenge"
			sb.tooltip_text = Seeded.label(sk)
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
		msb.get_meta("label").text = "Missions" + (" · %d ready" % ready if ready > 0 else "")
		msb.tooltip_text = "Claim completed missions" if ready > 0 else "Daily resets in " + Goals.fmt_left(Goals.seconds_left("daily"))
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
		panel_positions.clear()
		panel_names.clear()
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


func _start_seeded(kind: String) -> void:
	if not SaveManager.begin_new_life():
		_show_info("💾", "No free save slot", SaveManager.last_error, {})
		return
	Seeded.start(kind)
	panel_stack.clear()
	last_stats.clear()
	SaveManager.save_game()
	_show("game")
	_toast("🎯", "Goal", str(GameState.player["seeded"]["goal"]["text"]), ThemeManager.c("gold"))

func _open_fresh_start() -> void:
	var body := _big_popup(720,"🌱","Fresh Start","Begin in adulthood. Build a life through ordinary work, people and practical choices. Finishing a scenario lets your life continue.")
	for key in Journey.modules["fresh"].SCENARIOS:
		var scenario: Array=Journey.modules["fresh"].SCENARIOS[key]
		body.add_child(U.row("🌱",scenario[0],scenario[1],func(): _begin_fresh_start(key)))

func _begin_fresh_start(key: String) -> void:
	if not SaveManager.begin_new_life():
		_show_info("💾","No free save slot",SaveManager.last_error,{}); return
	Journey.modules["fresh"].start(key)
	_close_popup()
	panel_stack.clear(); last_stats.clear()
	SaveManager.save_game(); _show("game")
	MP.open("journey:fresh")


# ================================================================= LEGACY

func _show_legacy() -> void:
	var body := _big_popup(760, "🕰️", "What past lives left", "Up to two of these find the next life you begin, in any mode. Each is used once.")
	var lines := Legacy.menu_lines()
	if lines.is_empty():
		body.add_child(U.lbl("Nothing yet. A life leaves an echo when it was famous, quarrelsome, loved a pet, did time, or wore the uniform.", "Dim", 16, true))
	for ln in lines:
		body.add_child(U.lbl(str(ln), "", 17, true))


# ================================================================= ENDINGS SEEN

func _endings_sub() -> String:
	var cat := Meta.endings_catalog()
	var n := 0
	for e in cat:
		if e["seen"]:
			n += 1
	return "%d of %d found" % [n, cat.size()]


func _show_endings() -> void:
	var body := _big_popup(900, "🧭", "Endings seen", _endings_sub() + ". Some are hidden until you reach them.")
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 520)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := U.vb(8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(col)
	body.add_child(sc)
	var road := ""
	for e in Meta.endings_catalog():
		if str(e["road"]) != road:
			road = str(e["road"])
			col.add_child(U.section("%s  %s" % [e["icon"], road]))
		var row := U.hb(10)
		row.add_child(U.lbl("✅" if e["seen"] else "❔", "Emoji", 22))
		var tv := U.vb(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if e["seen"]:
			tv.add_child(U.lbl("%s  (×%d)" % [e["title"], e["n"]], "Bold", 18))
			tv.add_child(U.lbl("“%s”  — %s" % [e["epitaph"], e["who"]], "Dim", 14, true))
		else:
			tv.add_child(U.lbl("Not yet found", "Dim", 18))
		row.add_child(tv)
		col.add_child(row)


# ================================================================= SHARING

## Draws the finished life as one image, saves it, and puts the text on the clipboard.
func _share_life(entry: Dictionary) -> void:
	var card: Control = preload("res://scenes/share_card.gd").build(entry)
	var vp := SubViewport.new()
	vp.size = Vector2i(1080, 620)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.add_child(card)
	add_child(vp)
	await get_tree().process_frame
	await get_tree().process_frame
	var img := vp.get_texture().get_image()
	var dir := (OS.get_environment("OML_USER_DIR") if OS.get_environment("OML_USER_DIR") != "" else "user:/") + "/shares"
	DirAccess.make_dir_recursive_absolute(dir)
	var nm := str(entry.get("name", "life")).to_lower().replace(" ", "_")
	var path := "%s/%s_%d.png" % [dir, nm, int(Time.get_unix_time_from_system())]
	var err := OK
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(img.save_png_to_buffer(), "%s.png" % nm, "image/png")
		path = "your downloads folder"
	else:
		err = img.save_png(path)
	vp.queue_free()
	DisplayServer.clipboard_set(preload("res://scenes/share_card.gd").share_text(entry))
	var real := path if OS.has_feature("web") else ProjectSettings.globalize_path(path)
	_toast("📸", "Saved" if err == OK else "Couldn't save the picture", ("Picture: %s\nThe text is on your clipboard." % real) if err == OK else "The text is on your clipboard.", ThemeManager.c("good") if err == OK else ThemeManager.c("warn"))
	last_share = real


var last_share := ""


# ================================================================= PRISON LIFE

var pz := {}


func _open_prison_setup() -> void:
	pz = {"role": "prisoner", "story": "first", "gender": "male"}
	pz["first"] = ContentDB.random_first("male", "us")
	pz["last"] = ContentDB.random_last("us")
	var v := _open_popup(900)
	_event_header(v, "⛓️", "Prison Life")
	_event_text(v, "Two doors into one building. The institution is the same; what it means from each side is not. You will be someone with a family outside it, and a name that the building has already started to forget.")
	var rrow := U.hb(10)
	rrow.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(rrow)
	var role_btns := {}
	var sdesc := U.lbl("", "Dim", 16, true)
	sdesc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ob := OptionButton.new()
	ob.focus_mode = UIKit.fm()
	var skeys: Array = []
	var refresh := func() -> void:
		var stories: Dictionary = Prison.PRISONER_STORIES if pz["role"] == "prisoner" else Prison.GUARD_STORIES
		skeys.clear()
		ob.clear()
		for sk in stories.keys():
			skeys.append(sk)
			ob.add_item("%s  %s" % [stories[sk]["icon"], stories[sk]["name"]])
		if not stories.has(pz["story"]):
			pz["story"] = skeys[0]
		ob.select(skeys.find(pz["story"]))
		sdesc.text = str(stories[pz["story"]]["desc"])
		for rk in role_btns.keys():
			(role_btns[rk] as Button).theme_type_variation = "Accent" if rk == pz["role"] else "Row"
	for rd in [["prisoner", "⛓️  Prisoner", "Serve a sentence"], ["guard", "🗝️  Guard", "Work the walls"]]:
		var rk: String = rd[0]
		var b := U.btn(str(rd[1]), func(): pz["role"] = rk; refresh.call(), "Row")
		b.custom_minimum_size = Vector2(220, 56)
		b.tooltip_text = str(rd[2])
		b.focus_mode = UIKit.fm()
		role_btns[rk] = b
		rrow.add_child(b)
	var orow := U.hb(10)
	orow.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(orow)
	orow.add_child(U.lbl("Your story", "Dim", 16))
	ob.item_selected.connect(func(idx): pz["story"] = skeys[idx]; refresh.call())
	orow.add_child(ob)
	v.add_child(sdesc)
	var nrow := U.hb(10)
	nrow.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(nrow)
	nrow.add_child(U.lbl("Name", "Dim", 16))
	var fe := LineEdit.new()
	fe.text = str(pz["first"])
	fe.custom_minimum_size = Vector2(170, 0)
	fe.focus_mode = Control.FOCUS_CLICK
	fe.text_changed.connect(func(t): pz["first"] = t)
	nrow.add_child(fe)
	var le := LineEdit.new()
	le.text = str(pz["last"])
	le.custom_minimum_size = Vector2(170, 0)
	le.focus_mode = Control.FOCUS_CLICK
	le.text_changed.connect(func(t): pz["last"] = t)
	nrow.add_child(le)
	var dice := U.btn("🎲", func(): pz["first"] = ContentDB.random_first(pz["gender"], "us"); pz["last"] = ContentDB.random_last("us"); fe.text = str(pz["first"]); le.text = str(pz["last"]), "Row")
	dice.tooltip_text = "Another name"
	nrow.add_child(dice)
	var gb := OptionButton.new()
	gb.focus_mode = UIKit.fm()
	gb.add_item("Man")
	gb.add_item("Woman")
	gb.item_selected.connect(func(idx): pz["gender"] = "male" if idx == 0 else "female"; pz["first"] = ContentDB.random_first(pz["gender"], "us"); fe.text = str(pz["first"]))
	nrow.add_child(gb)
	var go := U.btn("Begin", func(): _start_prison(), "Accent")
	go.custom_minimum_size = Vector2(0, 58)
	go.name = "Choice1"
	v.add_child(go)
	var cancel := U.btn("Cancel", _close_popup, "Row")
	cancel.name = "OkButton"
	v.add_child(cancel)
	refresh.call()


func _start_prison() -> void:
	popup_open = false
	overlay.visible = false
	var first := str(pz.get("first", "")).strip_edges()
	var last := str(pz.get("last", "")).strip_edges()
	if first == "":
		first = ContentDB.random_first(str(pz["gender"]), "us")
	if last == "":
		last = ContentDB.random_last("us")
	var opts := {"first": first, "last": last, "gender": pz["gender"], "country": "us", "face": randi() % 5, "life_path": pz["role"], "keep_family": true, "story": pz["story"],
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
	pr.add_child(U.btn("🎲", func(): _nl_face(1), "Flat"))
	var port := U.card("Portrait")
	port.custom_minimum_size = Vector2(150, 150)
	if not nl.has("avatar"):
		nl["avatar"] = Avatar.current().duplicate()
	var pav := AvatarView.new()
	pav.custom_minimum_size = Vector2(150, 150)
	pav.setup(nl["avatar"], 20, str(nl["gender"]))
	port.add_child(pav)
	nl["portrait"] = pav
	pr.add_child(port)
	pr.add_child(U.btn("✏️", func(): _open_avatar_editor(nl["avatar"], str(nl["gender"]), 20, func(a): nl["avatar"] = a; nl["portrait"].setup(a, 20, str(nl["gender"]))), "Flat"))
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


## The avatar editor: a preview, a row per part, and the option to buy what you do not own.
func _open_avatar_editor(start: Dictionary, gender: String, age: int, on_save: Callable) -> void:
	var av := Avatar.sanitize(start)
	var body := _big_popup(1000, "🪞", "Appearance", "Your original face. Free colours and accessories for everyday adults; saved looks stay with each person.")
	var row := U.hb(24)
	body.add_child(row)
	var prev := AvatarView.new()
	prev.custom_minimum_size = Vector2(180,180)
	prev.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	prev.setup(av, age, gender)
	var pc := U.card("Portrait")
	pc.add_child(prev)
	row.add_child(pc)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(500,minf(350,get_viewport_rect().size.y*0.32))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sc)
	var list := U.vb(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	var refresh: Array = []
	for cat in Avatar.editor_categories():
		var key: String = cat[0]
		var count: int = cat[2]
		var kind: String = cat[3]
		var h := U.hb(8)
		var nm := U.lbl(str(cat[1]), "Bold", 15)
		nm.custom_minimum_size = Vector2(130, 0)
		h.add_child(nm)
		var val := U.lbl("", "", 15)
		val.custom_minimum_size = Vector2(170, 0)
		var sw := ColorRect.new()
		sw.custom_minimum_size = Vector2(26, 26)
		var buy := U.btn("", func(): pass, "Row")
		var upd := func():
			h.visible = not key in ["portrait_hair","portrait_eyes","portrait_accessory","portrait_detail"] or AvatarView.OriginalArt.supported(av,age)
			var i: int = int(av[key])
			val.text = ("%s %s" % [Avatar.glyph_of(key, i), Avatar.name_of(key, i)]).strip_edges() if kind == "style" else "#%d" % (i + 1)
			sw.visible = kind == "color"
			if kind == "color":
				sw.color = Avatar.color_of(key, i)
			var owned := Avatar.is_owned(key, i)
			buy.visible = not owned
			buy.text = "Buy ⭐ %d" % Avatar.cost_of(key, i)
			buy.disabled = Goals.stars() < Avatar.cost_of(key, i)
			prev.setup(av, age, gender)
		refresh.append(upd)
		var kk := key
		var cc := count
		h.add_child(U.btn("‹", func():
			av[kk] = (int(av[kk]) - 1 + cc) % cc
			for update in refresh: update.call(), "Flat"))
		h.add_child(sw)
		h.add_child(val)
		h.add_child(U.btn("›", func():
			av[kk] = (int(av[kk]) + 1) % cc
			for update in refresh: update.call(), "Flat"))
		h.add_child(buy)
		buy.pressed.connect(func():
			if Avatar.buy(kk, int(av[kk])):
				Fx.play("coin")
			for u in refresh:
				u.call())
		list.add_child(h)
		upd.call()
	var foot := U.hb(10)
	body.add_child(foot)
	foot.add_child(U.btn("🎲 Surprise me", func():
		var r := Avatar.random(gender)
		for k in r.keys():
			av[k] = r[k]
		for u in refresh:
			u.call(), "Row"))
	foot.add_child(U.spacer())
	var save := U.btn("Save look", func():
		for cat in Avatar.CATEGORIES:
			if not Avatar.is_owned(cat[0], int(av[cat[0]])):
				_toast("🔒", "Not yet", "%s is sold in the Star Shop." % Avatar.name_of(cat[0], int(av[cat[0]])), ThemeManager.c("warn"))
				return
		on_save.call(av)
		_close_popup(), "Accent")
	foot.add_child(save)


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


func _nl_face(_d: int) -> void:
	nl["avatar"] = Avatar.random(str(nl["gender"]))
	nl["portrait"].setup(nl["avatar"], 20, str(nl["gender"]))


func _nl_gender(gk: String) -> void:
	nl["gender"] = gk
	nl["portrait"].setup(nl["avatar"], 20, gk)


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
		opts = {"first": first, "last": last, "gender": nl["gender"], "country": nl["country"], "face": nl["face"], "avatar": nl["avatar"]}
		Avatar.set_current(nl["avatar"])
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
	var shell := U.vb(10)
	m.add_child(shell)
	# On a narrow window or a large interface size the three columns become one, with a
	# switcher: You · Story · Do.
	var col_tabs := U.hb(8)
	col_tabs.visible = false
	g["col_tabs"] = col_tabs
	g["col_idx"] = 1
	for ct in [["🧍 You", 0], ["📖 Story", 1], ["🕹️ Do", 2]]:
		var ci: int = ct[1]
		var cb := U.btn(str(ct[0]), func(): _set_column(ci), "Row")
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.custom_minimum_size = Vector2(0, 46)
		cb.name = "ColTab%d" % ci
		col_tabs.add_child(cb)
	shell.add_child(col_tabs)
	var h := U.hb(22)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(h)

	# ---- left column
	var left := U.vb(16)
	left.custom_minimum_size = Vector2(470, 0)
	g["left_col"] = left
	h.add_child(left)
	var head := U.card()
	var hh := U.hb(16)
	head.add_child(hh)
	var port := U.card("Portrait")
	port.custom_minimum_size = Vector2(104, 104)
	var pl := U.lbl("👶", "Emoji", 60)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	port.add_child(pl)
	g["portrait"] = pl
	var avv := AvatarView.new()
	avv.custom_minimum_size = Vector2(118, 118)
	avv.visible = false
	avv.mouse_filter = Control.MOUSE_FILTER_PASS
	port.add_child(avv)
	g["avatar_view"] = avv
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
	iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var isc := ScrollContainer.new()   # a long life summary scrolls here instead of stretching the whole column
	isc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	isc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	isc.add_child(iv)
	info.add_child(isc)
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
	var custody := U.card("Banner")
	custody.name = "CustodyBanner"
	var custody_text := U.lbl("", "Bold", 21, true)
	custody.add_child(custody_text)
	custody.visible = false
	g["custody_banner"] = custody
	g["custody_label"] = custody_text
	center.add_child(custody)
	var setting_ribbon := U.lbl("", "Bold", 17, true)
	g["setting_ribbon"] = setting_ribbon
	center.add_child(setting_ribbon)
	var logc := U.card()
	logc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var logv := U.vb(4)
	logv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(logv)
	var logbox := U.vb(6)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", U.sp(6))
	g["log_filter"] = "all"
	for f in [["all", "📖 All"], ["money", "💰 Money"], ["people", "👪 People"], ["work", "💼 Work"], ["health", "❤️ Health"]]:
		var fk: String = f[0]
		var chip := U.btn(str(f[1]), func():
			g["log_filter"] = fk
			for ch in chips.get_children():
				(ch as Button).theme_type_variation = "Primary" if ch.name == "LogFilter_" + fk else "Chip"
			_rebuild_log(), "Primary" if fk == "all" else "Chip")
		chip.name = "LogFilter_" + fk
		chips.add_child(chip)
	logbox.add_child(chips)
	logbox.add_child(sc)
	logc.add_child(logbox)
	g["log"] = logv
	g["log_scroll"] = sc
	center.add_child(logc)

	var ageb := U.card()
	var av := U.vb(10)
	ageb.add_child(av)
	var ah := U.hb(20)
	ah.alignment = BoxContainer.ALIGNMENT_CENTER
	var qa := U.icon_btn("⏪", "Do-Over", func(): _quick_press(0), "Row", true, 34, 17)
	qa.custom_minimum_size = Vector2(150, 96)
	g["quick_left"] = qa
	ah.add_child(qa)
	var age_btn := U.btn("↑\nOne year", _age_up, "AgeButton")
	age_btn.custom_minimum_size = Vector2(140, 140)
	g["age_btn"] = age_btn
	ah.add_child(age_btn)
	var qb := U.icon_btn("🎯", "Missions", func(): _quick_press(1), "Row", true, 34, 17)
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
	ptitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	g["panel_title"] = ptitle
	rh.add_child(ptitle)
	rvb.add_child(rh)
	back.tooltip_text = "Back to the previous section"
	var trail := U.lbl("", "Dim", 13, true)
	g["panel_trail"] = trail
	rvb.add_child(trail)
	var navigation := U.hb(6)
	var find := U.btn("🔎 Find & favourites",func(): _open_panel(NAV.show),"Row")
	find.name = "FindNavigation"
	find.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(find)
	var home_button := U.btn("Home",func(): _tab_press(int(g.get("tab_cur",0))),"Flat")
	home_button.tooltip_text = "Return to the current tab's main section"
	navigation.add_child(home_button)
	var help_button := U.btn("?",func(): _open_panel(_panel_guide),"Flat")
	help_button.tooltip_text = "How to play and what changes your outcomes"
	navigation.add_child(help_button)
	rvb.add_child(navigation)
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
## The things that define your day are always on screen, apart from the menus: where you
## work, where you study, what you run. One line each, with how it is going.
func _pinned_headlines(box: VBoxContainer) -> void:
	var p := GameState.player
	if int(p.get("age", 0)) < 3 or Lives.separate():
		return
	var any := false
	if GameState.has_job():
		var j: Dictionary = p["job"]
		var perf := float(j.get("perf", 50.0))
		var sub := "%s a year · %d year%s here" % [GameState.fmt_money(int(j["salary"])), int(j.get("years", 0)), "" if int(j.get("years", 0)) == 1 else "s"]
		if int(j.get("warned", 0)) >= 1:
			sub += " · ⚠️ on a performance plan"
		elif perf >= 70.0 and int(j.get("years_in_rank", 0)) >= 1:
			sub += " · 📈 promotion in sight"
		var co := str(j.get("employer_name", ""))
		var hb := U.hb(8)
		hb.add_child(U.bar(perf, ThemeManager.bar_color("happiness", perf), 8, 90))
		hb.add_child(U.lbl("%d%%" % int(perf), "Bold", 13))
		box.add_child(U.row("💼", "%s%s" % [str(j["title"]), ("  ·  " + co) if co != "" else ""], sub, func(): _tab_press(2), true, true, hb))
		any = true
	var edu: Dictionary = p.get("education", {})
	if GameState.in_school():
		var perf2 := float(edu.get("performance", 50.0))
		var hb2 := U.hb(8)
		hb2.add_child(U.bar(perf2, ThemeManager.bar_color("smarts", perf2), 8, 90))
		hb2.add_child(U.lbl("%d%%" % int(perf2), "Bold", 13))
		var gr := str(edu.get("grade", ""))
		box.add_child(U.row("🏫", Journey.modules["campus"].title(), "Grade %s" % (gr if gr != "" else "—"), func(): _tab_press(2), true, true, hb2))
		any = true
	elif GameState.in_university():
		var u: Dictionary = edu["uni"]
		var perf3 := float(u.get("performance", 50.0))
		var hb3 := U.hb(8)
		hb3.add_child(U.bar(perf3, ThemeManager.bar_color("smarts", perf3), 8, 90))
		hb3.add_child(U.lbl(EventEngine.grade_letter(perf3), "Bold", 13))
		box.add_child(U.row("🎓", str(ContentDB.major(u["major"])["name"]), "Year %d of %d" % [int(u["year"]) + 1, int(u["years"])], func(): _tab_press(2), true, true, hb3))
		any = true
	var biz: Dictionary = p.get("business", {})
	if not biz.is_empty():
		box.add_child(U.row("📈", str(biz["name"]), "Profit last year %s" % GameState.fmt_money(int(biz.get("profit", 0))), func(): _tab_press(2), true, true))
		any = true
	if any:
		var sep := HSeparator.new()
		box.add_child(sep)


func _refresh_tracks() -> void:
	if not g.has("tracks") or not is_instance_valid(g["tracks"]):
		return
	var box: VBoxContainer = g["tracks"]
	U.clear(box)
	var p := GameState.player
	_pinned_headlines(box)

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


## The left column for a separate mode: the mode's own header, gauges and notes.
func _refresh_side_mode() -> void:
	var p := GameState.player
	var md = Lives.mode()
	g["portrait"].text = str(md.portrait())
	g["portrait"].visible = true
	g["avatar_view"].visible = false
	g["name"].text = ("%s %s" % [p["first"], p["last"]] if not Pets.active() else str(p["first"])) + ("  " + str(p["badge"]) if str(p.get("badge", "")) != "" else "")
	g["occ"].text = str(md.header_occ())
	g["country"].text = str(md.header_sub())
	if g.has("life_tab") and is_instance_valid(g["life_tab"]):
		g["life_tab"].visible = true
	g["age"].text = (("Scene %d" % (Lives.life().get("journal",[]).size()+1)) if GameState.is_alive() else "Complete") if Lives.is_type("tv") else LifeCourse.age_label()
	if g.has("age_btn"): g["age_btn"].text = "▶\nNext chapter" if Lives.is_type("tv") else ("↑\nOne month" if LifeCourse.monthly_mode() else "↑\nOne year")
	g["money"].text = str(md.money_text())
	var ms: int = int(md.money_state())
	g["money"].add_theme_color_override("font_color", ThemeManager.c("bad") if ms < 0 else (ThemeManager.c("warn") if ms > 0 else ThemeManager.c("good")))
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
	for tr in md.tracks():
		var v2 := float(tr[2])
		box.add_child(U.track(str(tr[0]), str(tr[1]), v2, 100.0, ThemeManager.c("accent"), "%d%%" % int(v2)))
	U.clear(g["traits"])
	for t in p["traits"]:
		var info: Dictionary = {"icon": "•", "desc": ""}
		if Pets.active():
			var pi: Array = Pets.TRAIT_INFO.get(str(t), ["•", ""])
			info = {"icon": pi[0], "desc": pi[1]}
		else:
			info = ContentDB.trait_info(str(t))
		var chip := U.card("Chip")
		chip.add_child(U.lbl("%s %s" % [info["icon"], t], "", 15))
		chip.tooltip_text = str(info["desc"])
		g["traits"].add_child(chip)
	g["home"].text = str(md.home_text())
	g["fin"].text = str(md.fin_text())
	g["extra"].text = (str(md.extra_text()) + "\n" + Seeded.status_line()).strip_edges()
	var tleft: int = p["time_left"]
	g["time_lbl"].text = "Time %d/%d" % [tleft, GameState.TIME_PER_YEAR]
	g["time_bar"].value = 100.0 * tleft / GameState.TIME_PER_YEAR
	U.set_bar_color(g["time_bar"], ThemeManager.c("good") if tleft > 3 else ThemeManager.c("warn"))
	g["age_btn"].disabled = not p["alive"]
	if g.has("age_btn"): g["age_btn"].text = "▶\nNext chapter" if Lives.is_type("tv") else ("↑\nOne month" if LifeCourse.monthly_mode() else "↑\nOne year")
	VFX.pulse(g["age_btn"], p["alive"] and not popup_open and int(p["time_left"]) >= GameState.TIME_PER_YEAR - 1)


func _refresh_side() -> void:
	if not GameState.has_life() or g.is_empty() or not is_instance_valid(g.get("name")):
		return
	var p := GameState.player
	var in_custody := GameState.in_prison() and not Lives.separate()
	g["custody_banner"].visible = in_custody
	var path := Lives.kind()
	var world_caption := ""
	if path == "traveler": world_caption = "⌛  %d · %s" % [Expansion.era_year(),Expansion.TRAVEL_ERAS.get(int(Lives.life().get("era",1970)),{}).get("desc","")]
	elif path in ["pirate","colonist","royal","vampire","witch","super","revenant"]: world_caption = "%s · %s" % [Lives.TYPES[path]["icon"],Lives.title()]
	elif path == "tv": world_caption = "🎬  %s · %s" % [TVLife.profile()["show"],TVLife.profile()["coverage"]]
	elif Careers.has_career(): world_caption = Careers.title()
	g["setting_ribbon"].text = world_caption
	g["setting_ribbon"].visible = world_caption != ""
	if in_custody:
		g["custody_label"].text = "⛓️  IN CUSTODY · %d year%s remaining\nYour life continues inside prison." % [int(p["prison"]), "" if int(p["prison"])==1 else "s"]
	_apply_mode_chrome()
	if Lives.separate():
		_refresh_side_mode()
		return
	g["portrait"].text = U.face(p["gender"], int(p["age"]), int(p["face"])) if p["alive"] else "😇"
	var human_av: Dictionary = Avatar.for_player()
	g["portrait"].visible = false
	g["avatar_view"].visible = true
	g["avatar_view"].setup(human_av, int(p["age"]), str(p["gender"]),true)
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
	g["age"].text = LifeCourse.age_label()
	g["age"].tooltip_text = "Monthly before age two; yearly afterward"
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
	g["extra"].text = (extra + "\n" + Seeded.status_line()).strip_edges()
	g["name"].text = ("%s %s" % [p["first"], p["last"]]) + ("  " + p["badge"] if p.get("badge", "") != "" else "")
	_sync_life_theme()
	var tleft: int = p["time_left"]
	g["time_lbl"].text = "Time %d/%d" % [tleft, GameState.TIME_PER_YEAR]
	g["time_bar"].value = 100.0 * tleft / GameState.TIME_PER_YEAR
	U.set_bar_color(g["time_bar"], ThemeManager.c("good") if tleft > 3 else ThemeManager.c("warn"))
	var ql: Button = g["quick_left"]
	var have_redo := Items.owned("do_over")
	ql.get_meta("icon").text = "⏪"
	ql.get_meta("label").text = ("Do-Over ×%d" % have_redo) if have_redo > 0 else "Do-Over"
	ql.modulate = Color(1, 1, 1, 1.0 if have_redo > 0 else 0.62)
	var qr2: Button = g["quick_right"]
	var ready_n := Goals.unclaimed_count()
	qr2.get_meta("icon").text = "🎯"
	qr2.get_meta("label").text = ("Claim %d" % ready_n) if ready_n > 0 else "Missions"
	g["age_btn"].disabled = not p["alive"]
	if g.has("age_btn"): g["age_btn"].text = "▶\nNext chapter" if Lives.is_type("tv") else ("↑\nOne month" if LifeCourse.monthly_mode() else "↑\nOne year")
	VFX.pulse(g["age_btn"], p["alive"] and not popup_open and int(p["time_left"]) >= GameState.TIME_PER_YEAR - 1)


# ---- log

func _rebuild_log() -> void:
	if not g.has("log"):
		return
	U.clear(g["log"])
	g.erase("pending_header")
	for y in GameState.log_years:
		_add_year_header(int(y["age"]))
		for line in y["lines"]:
			_add_log_line(line)
	_scroll_log()


## Which kind of thing a line of the story is about, so the story can be read by topic.
func _log_cats(text: String) -> Array:
	var t := text.to_lower()
	var out: Array = []
	var money_words := ["£", "$", "€", "earned", "salary", "bills", "paid", "loan", "mortgage", "debt", "bank", "tax", "rent", "invest", "savings", "bought", "sold", "inherit", "lottery", "casino", "bet ", "shares", "profit", "bankrupt", "credit", "wage", "pension", "severance"]
	var work_words := ["job", "promot", "fired", "boss", "career", "school", "grade", "degree", "company", "hired", "interview", "application", "colleague", "coworker", "office", "demot", "redundan", "review", "university", "exam", "class", "teacher", "business", "employer", "manager"]
	var health_words := ["health", "doctor", "hospital", "ill ", "illness", "injur", "sick", "surgery", "therapy", "diagnos", "cancer", "medic", "symptom", "stress", "flu", "scar", "recover", "sleep", "died", "funeral", "vet "]
	var people_words := ["mother", "father", "mum", "dad", "sister", "brother", "friend", "partner", "married", "divorce", "wife", "husband", "kid", "baby", "child", "son ", "daughter", "uncle", "aunt", "cousin", "grand", "family", "dating", "girlfriend", "boyfriend", "ex ", "neighbo", "relationship", "wedding", "pet", "dog", "cat "]
	for w in money_words:
		if t.find(w) != -1:
			out.append("money")
			break
	for w2 in work_words:
		if t.find(w2) != -1:
			out.append("work")
			break
	for w3 in health_words:
		if t.find(w3) != -1:
			out.append("health")
			break
	for w4 in people_words:
		if t.find(w4) != -1:
			out.append("people")
			break
	return out


func _add_year_header(age: int) -> void:
	if str(g.get("log_filter", "all")) != "all":
		g["pending_header"] = age
		return
	_really_add_header(age)


func _really_add_header(age: int) -> void:
	var box: VBoxContainer = g["log"]
	if box.get_child_count() > 0:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 10)
		box.add_child(gap)
	var l := U.lbl(("Scene %d" % age if age > 0 else "Opening") if Lives.is_type("tv") else ("Age %d" % age if age > 0 else "Born"), "AccentLabel")
	l.add_theme_color_override("font_color", ThemeManager.c("primary").lightened(0.3) if ThemeManager.current != "light" else ThemeManager.c("primary"))
	box.add_child(l)


func _add_log_line(text: String) -> void:
	var flt := str(g.get("log_filter", "all"))
	if flt != "all":
		if not _log_cats(text).has(flt):
			return
		if g.has("pending_header"):
			_really_add_header(int(g["pending_header"]))
			g.erase("pending_header")
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
	if popup_open or mg_open or not GameState.is_alive():
		return
	Fx.play("age")
	if g.has("age_btn") and is_instance_valid(g["age_btn"]):
		VFX.age_press(g["age_btn"], fx_layer)
	EventEngine.progress()
	_refresh_side()
	_render_top_panel()
	_pump()


## Tab or an arrow key turns keyboard navigation on; a mouse click turns it off.
## When a pop-up opens and keyboard navigation is on, put the cursor on its first choice.
func _focus_overlay() -> void:
	if not UIKit.kb_mode or not popup_open:
		return
	for b in overlay_box.find_children("*", "BaseButton", true, false):
		var bb := b as BaseButton
		if bb.is_visible_in_tree() and not bb.disabled and bb.focus_mode != Control.FOCUS_NONE:
			bb.grab_focus()
			return


func _input(event: InputEvent) -> void:
	if get_viewport().gui_get_focus_owner() is LineEdit: return
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
	if Lives.separate():
		var out: Array = []
		for t in Lives.mode().tabs():
			var key: String = str(t[2])
			if key == "more":
				out.append([t[0], t[1], _panel_more_pet])
			else:
				out.append([t[0], t[1], func(): MP.show(key)])
		return out
	return [["🏃", "Activities", _panel_activities], ["❤️", "People", _panel_relationships], ["💼", "Work", _panel_occupation], ["💰", "Assets", _panel_assets], ["✨", "Life", LP.life_panel], ["⋯", "More", _panel_more]]


func _tab_press(i: int) -> void:
	var specs := _tab_specs()
	if i < 0 or i >= specs.size():
		return
	g["tab_cur"] = i
	var cb: Callable = specs[i][2]
	_open_panel(cb, true)


func _quick_press(side: int) -> void:
	if Lives.separate():
		var key: String = str(Lives.mode().quick()[side][2])
		_open_panel(func(): MP.show(key), true)
		return
	if side == 1:
		_show_missions()
		return
	if Items.owned("do_over") > 0 and Items.has_snapshot():
		_confirm_do_over()
	else:
		star_tab = "items"
		_show_star_shop()


func _apply_mode_chrome() -> void:
	var sep := Lives.separate()
	if g.has("age_btn"): g["age_btn"].text = "▶\nNext chapter" if Lives.is_type("tv") else ("↑\nOne month" if LifeCourse.monthly_mode() else "↑\nOne year")
	var md = Lives.mode()
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
		var sl: Dictionary = md.side_labels() if sep else {}
		pair[0].text = str(sl[k][0]) if sep else str(U.STAT_ICONS[k])
		pair[1].text = str(sl[k][1]) if sep else str(U.STAT_NAMES[k])
	if g.has("bal_lbl") and is_instance_valid(g["bal_lbl"]):
		g["bal_lbl"].text = str(md.balance_label()) if sep else "Bank Balance"
	if g.has("home_icons") and is_instance_valid(g["home_icons"]):
		g["home_icons"].visible = not sep
	var ql: Button = g["quick_left"]
	var qr: Button = g["quick_right"]
	if sep:
		var qk: Array = md.quick()
		ql.get_meta("icon").text = str(qk[0][0])
		ql.get_meta("label").text = str(qk[0][1])
		qr.get_meta("icon").text = str(qk[1][0])
		qr.get_meta("label").text = str(qk[1][1])
	else:
		qr.get_meta("icon").text = "🎯"
		qr.get_meta("label").text = "Missions"


func _panel_more_pet() -> void:
	_panel_header("⋯", "More")
	_add(U.row("🧵","Life activities","People, work, health and free time",func(): MP.open("journey:root")))
	var ready := Goals.unclaimed_count()
	_add(U.row("🎁", "Daily Heirloom", "Ready to open!" if Goals.daily_available() else "Next in " + Goals.fmt_left(Goals.seconds_left("daily")), func(): SP.show_heirloom()))
	_add(U.row("🎯", "Missions", ("%d ready to claim! · " % ready if ready > 0 else "") + "Daily, weekly and monthly goals", _show_missions))
	_add(U.row("🏆", "Trophy Room", "%d / %d achievements · ⭐ %d Stars" % [Meta.meta["goals"]["ach"].size(), Goals.achievements.size(), Goals.stars()], _show_trophies))
	_add(U.row("🧭", "Endings seen", _endings_sub(), _show_endings))
	_add(U.row("🕰️", "What past lives left", "%d echo%s waiting for the next life" % [Legacy.pending().size(), "" if Legacy.pending().size() == 1 else "es"], _show_legacy))
	_add(U.row("⭐", "Star Shop", "Items, avatar parts, boons and titles", _show_star_shop))
	_add(U.row("🪦", "Graveyard", "Past lives and their stories", _open_graveyard))
	_add(U.row("⚙️", "Settings", "Sound, effects, motion, display", func(): _open_panel(_panel_settings)))
	_add(U.row("🎨", "Theme: " + ThemeManager.LABELS[ThemeManager.current], "Tap to switch", func(): _set_theme(ThemeManager.next_theme()), true, false))
	_add(U.row("📂", "Your Lives", "Switch to another saved life", func(): SaveManager.save_game(); SP.show_lives()))
	_add(U.row("💾", "Save & Exit", "Back to the main menu", func(): SaveManager.save_game(); _show("title"), true, false))
	_add(U.lbl("Keys: Space = a year passes · 1–6 = tabs · Esc = back", "Dim", 14, true))


func _open_panel(builder: Callable, reset: bool = false) -> void:
	# Opened actions must be visible in the single-column large-text layout.
	if g.get("single_col",false): _set_column(2)
	_remember_panel_scroll()
	if reset:
		panel_stack.clear()
		panel_positions.clear()
		panel_names.clear()
	panel_stack.append(builder)
	panel_positions.append(0)
	panel_names.append("")
	_render_top_panel()


func _panel_back() -> void:
	if panel_stack.size() > 1:
		_remember_panel_scroll()
		panel_stack.pop_back()
		panel_positions.pop_back()
		panel_names.pop_back()
		_render_top_panel()


func _render_top_panel() -> void:
	if panel_stack.is_empty() or not g.has("panel") or not GameState.has_life():
		return
	U.clear(g["panel"])
	g["back"].visible = panel_stack.size() > 1
	var builder: Callable = panel_stack[-1]
	builder.call()
	while panel_positions.size()<panel_stack.size(): panel_positions.append(0)
	while panel_names.size()<panel_stack.size(): panel_names.append("")
	panel_render_serial += 1
	_restore_panel_scroll(panel_render_serial,int(panel_positions[panel_stack.size()-1]))
	if UIKit.kb_mode:
		_kb_focus_first.call_deferred()


func _remember_panel_scroll() -> void:
	if panel_stack.is_empty() or not g.has("panel_scroll"): return
	while panel_positions.size()<panel_stack.size(): panel_positions.append(0)
	panel_positions[panel_stack.size()-1] = int(g["panel_scroll"].scroll_vertical)

func _restore_panel_scroll(serial: int, position: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if serial==panel_render_serial and g.has("panel_scroll") and is_instance_valid(g["panel_scroll"]):
		g["panel_scroll"].scroll_vertical = position

func _panel_header(icon: String, title: String) -> void:
	g["panel_icon"].text = icon
	g["panel_title"].text = title
	while panel_names.size()<panel_stack.size(): panel_names.append("")
	if not panel_stack.is_empty(): panel_names[panel_stack.size()-1]=title
	if g.has("panel_trail"): g["panel_trail"].text = " › ".join(panel_names)


func _add(c: Control) -> void:
	g["panel"].add_child(c)


func _act(cb: Callable, tracked_people: Array = []) -> Callable:
	return func():
		_remember_panel_scroll()
		var before := Insight.snapshot(tracked_people)
		var title := str(g["panel_title"].text)
		cb.call()
		Insight.record(before,title,"",tracked_people)
		_refresh_side()
		_render_top_panel()
		_pump()


# ---- activities

func _panel_activities() -> void:
	_panel_header("🏃", "Activities")
	_add(U.row("🔎","Find & favourites","Search names, categories and destinations",func(): _open_panel(NAV.show)))
	var p := GameState.player
	if GameState.in_prison():
		_add(U.section("Prison"))
		for a in Actions.PRISON_ACTIONS:
			if a.has("mod") and not Meta.has_mod(a["mod"]):
				continue
			var aid: String = a["id"]
			_add(U.row(a["icon"], a["name"], a["sub"], _act(func(): Actions.do_activity(aid)), true, false))
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
	MP.rows_into(Bulk.menu(gid))
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
			var pcb: Callable = {"social_media": _panel_social, "licenses": _panel_licenses, "lawsuit": _panel_lawsuit, "murder": _panel_murder, "black_market": ep.black_market, "cult": ep.cult, "camp": ep.camping, "journal": ep.journal, "museum": ep.museum, "relocate": LP.places_panel, "become_list": _panel_become, "loans": _panel_loans, "fight_bets": _panel_fight_bets}[iid]
			_add(U.row(it["icon"], it["name"], sub, func(): _open_panel(pcb), ok))
		else:
			_add(U.row(it["icon"], it["name"], sub, _act(func(): Actions.do_activity(iid)), ok, false))



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
		_add(U.row("👪", "Family outing", str(bst["why"]), _act(func(): Actions.hang_out_with_all()), true, false))
	else:
		_add(U.row("🔒", "Family outing", str(bst["why"]), func(): pass, false, false))
	if int(GameState.player["age"]) >= 5:
		var fam_on: bool = GameState.player["routines"].get("family", false)
		_add(U.row("🔁", "Family time · %s" % ("On" if fam_on else "Off"), "Automatic · 1 time each year", _act(func(): GameState.player["routines"]["family"] = not GameState.player["routines"].get("family", false)), true, false))
	_add(U.section("People in your life"))
	var parents: Array = ["mother", "father", "stepparent"]
	if Origins.kind() == "grandparent": parents.append("grandparent")
	var close_count := _relationship_count(parents + ["sibling", "stepsibling"])
	var partner_count := _relationship_count(["partner", "lover"])
	var pet_count := _relationship_count(["pet"])
	var child_count := _relationship_count(["child", "stepchild"])
	var contact_count := _relationship_count(["friend", "best_friend", "teacher", "principal", "school_nurse", "mentor", "classmate", "boss", "coworker", "crush", "neighbor", "cellmate", "rival", "enemy", "family_friend"])
	var past_count := _past_relationship_count()
	_add(U.row("👪", "Parents & siblings", "%d people" % close_count if close_count else "No close family yet", func(): _open_panel(Callable(self, "_panel_relationship_group").bind("family"))))
	_add(U.row("💞", "Partners", "%d current" % partner_count if partner_count else "No current partner", func(): _open_panel(Callable(self, "_panel_relationship_group").bind("partners"))))
	_add(U.row("🐾", "Pets", "%d in your life" % pet_count if pet_count else "No pets yet", func(): _open_panel(Callable(self, "_panel_relationship_group").bind("pets"))))
	_add(U.row("🧒", "Children", "%d in your life" % child_count if child_count else "Parenting and family planning", func(): _open_panel(Callable(self, "_panel_relationship_group").bind("children"))))
	_add(U.row("🤝", "Friends & contacts", "%d people" % contact_count if contact_count else "School, work and community", func(): _open_panel(Callable(self, "_panel_relationship_group").bind("contacts"))))
	_add(U.row("🗂️", "Past relationships", "%d recorded" % past_count if past_count else "Past and deceased people", func(): _open_panel(Callable(self, "_panel_relationship_group").bind("past"))))


func _relationship_count(relations: Array) -> int:
	var count := 0
	for id in GameState.npcs:
		var n: Dictionary = GameState.npcs[id]
		if relations.has(str(n.get("relation", ""))) and not Bonds.is_past(n):
			count += 1
	return count


func _past_relationship_count() -> int:
	var count := 0
	for id in GameState.npcs:
		var n: Dictionary = GameState.npcs[id]
		if str(n.get("relation", "")) not in ["auntuncle", "cousin", "niece_nephew"] and Bonds.is_past(n):
			count += 1
	return count


func _panel_relationship_group(group: String) -> void:
	match group:
		"family":
			_panel_header("👪", "Parents & siblings")
			var parents: Array = ["mother", "father", "stepparent"]
			if Origins.kind() == "grandparent": parents.append("grandparent")
			_add_relationship_section("Parents", parents)
			_add_relationship_section("Siblings", ["sibling", "stepsibling"])
		"partners":
			_panel_header("💞", "Partners")
			_add_relationship_section("Current relationships", ["partner", "lover"])
		"pets":
			_panel_header("🐾", "Pets")
			_add_relationship_section("Your pets", ["pet"])
		"children":
			_panel_children()
		"contacts":
			_panel_contacts()
		"past":
			_panel_past_relationships()


func _add_relationship_section(title: String, relations: Array) -> void:
	var ids: Array = []
	for id in GameState.npcs:
		var n: Dictionary = GameState.npcs[id]
		if relations.has(str(n.get("relation", ""))) and not Bonds.is_past(n):
			ids.append(id)
	ids.sort_custom(func(a, b): return int(GameState.npcs[a]["closeness"]) > int(GameState.npcs[b]["closeness"]))
	_add(U.section("%s · %d" % [title, ids.size()]))
	if ids.is_empty():
		_add(U.lbl("No one here yet.", "Dim", 15, true))
		return
	for id in ids:
		_add(_person_row(id))


func _panel_past_relationships() -> void:
	_panel_header("🗂️", "Past relationships")
	var buckets := {"Deceased":[],"Past relationships":[]}
	for id in GameState.npcs:
		var n: Dictionary = GameState.npcs[id]
		if str(n.get("relation","")) in ["auntuncle","cousin","niece_nephew"] or not Bonds.is_past(n): continue
		buckets["Deceased" if not n.get("alive",true) else "Past relationships"].append(id)
	var any := false
	for k in buckets.keys():
		var ids: Array = buckets[k]
		_add(U.section("%s · %d" % [k,ids.size()]))
		if ids.is_empty():
			_add(U.lbl("Nobody recorded here yet.","Dim",15,true))
			continue
		any = true
		for id2 in ids:
			var n2: Dictionary = GameState.npcs[id2]
			var nid: String = id2
			_add(U.row(U.npc_icon(n2), "%s (%s)" % [GameState.full_name(id2), GameState.relation_label(id2)], Bonds.past_label(n2), func(): _open_panel(func(): _panel_person(nid)), true, true))
	if not any:
		_add(U.lbl("Past and deceased people will be kept here.", "Dim", 15, true))


func _panel_children() -> void:
	_panel_header("🧒", "Children")
	var found := false
	for id in GameState.npcs:
		if str(GameState.npcs[id]["relation"]) in ["child", "stepchild"] and not Bonds.is_past(GameState.npcs[id]):
			found = true
			_add(_person_row(id))
	if not found:
		_add(U.lbl("Children and stepchildren will appear here.", "Dim", 15, true))
	if not Dynasty.candidates().is_empty():
		_add(U.section("Continue as a child"))
		_add(U.row("👪", "Switch viewpoint", "The parent stays alive.", _open_live_child_switch))

func _panel_contacts() -> void:
	_panel_header("🤝", "Friends & contacts")
	var found := false
	for group in [["Friends", ["friend", "best_friend"]], ["School & work", ["teacher", "principal", "school_nurse", "mentor", "classmate", "boss", "coworker"]], ["Community", ["crush", "neighbor", "cellmate", "rival", "enemy", "family_friend"]]]:
		var ids: Array = []
		for id in GameState.npcs:
			if group[1].has(str(GameState.npcs[id]["relation"])) and not Bonds.is_past(GameState.npcs[id]):
				ids.append(id)
		if ids.is_empty():
			continue
		found = true
		_add(U.section("%s · %d" % [group[0], ids.size()]))
		for id in ids:
			_add(_person_row(id))
	if not found:
		_add(U.lbl("Friends, classmates and colleagues appear here.", "Dim", 15, true))

func _panel_decision_memory() -> void:
	_panel_header("📜", "Remembered choices")
	_add(U.lbl("Choices stay in your record. Some return in later scenes; others affect life right away.", "Dim", 15, true))
	var entries: Array = Depth.state().get("decisions",{}).values()
	entries.sort_custom(func(a,b): return int(a.get("last_age",0))>int(b.get("last_age",0)))
	for entry in entries:
		_add(U.row("📌",str(entry["event"]),"Age %d–%d · %s · %d time(s)" % [int(entry["first_age"]),int(entry["last_age"]),str(entry["choice"]),int(entry["count"])],func(): pass,false,false))


func _panel_guide() -> void:
	_panel_header("❔", "Quick guide")
	if Lives.separate() or Lives.is_type("tv"):
		var key := Lives.kind()
		var intro: Array = TUTORIALS.get(key,TUTORIALS["human"])
		_add(U.lbl(str(intro[2]),"",17,true))
		_add(U.lbl("Find searches this mode. Back returns; Home opens its main tab.", "Dim", 15, true))
		return
	_add(U.section("Time & actions"))
	_add(U.lbl("Age monthly until 2, then yearly. Actions cost time or money; bulk actions also charge a fee.", "Dim", 15, true))
	_add(U.section("Stats & outcomes"))
	_add(U.lbl("Lifestyle changes your stats. Readiness improves your odds; practice and choices still matter.", "Dim", 15, true))
	_add(U.row("🧭", "Your stats", "What they affect and how to improve", func(): _open_panel(_panel_readiness)))
	_add(U.section("Stories & navigation"))
	_add(U.lbl("Choices can change people, money and future opportunities. Some return later; not every choice has a custom follow-up.", "Dim", 15, true))
	_add(U.row("📌", "Recent effects", "Changes and scheduled follow-ups", func(): _open_panel(_panel_consequences)))
	_add(U.lbl("Search finds activities. Back returns; Home opens the current tab. Space ages up; Esc goes back.", "Dim", 14, true))

func _panel_consequences() -> void:
	_panel_header("📌", "Recent effects")
	_add(U.section("Upcoming follow-ups"))
	var upcoming := Insight.upcoming()
	for line in upcoming: _add(U.lbl(str(line),"",16,true))
	if upcoming.is_empty(): _add(U.lbl("Nothing is scheduled right now.", "Dim", 15, true))
	_add(U.section("Recent changes"))
	_add(U.lbl("Effects from actions and resolved decisions. Earlier saves start tracking here.", "Dim", 14, true))
	var history: Array = Insight.state()["history"].duplicate(true)
	history.reverse()
	for entry in history.slice(0,30):
		_add(U.section("Age %d, month %d · %s" % [int(entry["age"]),int(entry["month"]),str(entry["title"])]))
		if str(entry["reason"])!="": _add(U.lbl(str(entry["reason"]),"",16,true))
		for line in entry["changes"]: _add(U.lbl(str(line),"Dim",15,true))
		for person_id0 in entry.get("targets", []):
			var person_id := str(person_id0)
			if not GameState.npcs.has(person_id): continue
			var person: Dictionary = GameState.npcs[person_id]
			var target_id: String = person_id
			_add(U.row(U.npc_icon(person),"Open %s's profile" % str(person["first"]),GameState.relation_label(target_id),func(): _open_panel(func(): _panel_person(target_id)),true,true))
	if history.is_empty(): _add(U.lbl("Your next activity or decision will add its effects here.","Dim",16,true))
	if history.size()>30: _add(U.lbl("Showing the latest 30 of up to 80 stored change records. Full decision memory remains under Choices I remember.","Dim",14,true))

func _panel_readiness() -> void:
	_panel_header("🧭","What my stats affect")
	for key in Aptitude.WEIGHTS:
		_add(U.section(str(key).capitalize()))
		_add(U.lbl(Aptitude.describe(key),"Dim",16,true))
		var parts: Array = []
		for stat in Aptitude.WEIGHTS[key]: parts.append("%s %d%%" % [str(stat).capitalize(),int(Aptitude.WEIGHTS[key][stat]*100)])
		_add(U.lbl("Ability mix: "+", ".join(parts)+". This mix supplies 85% of readiness; low stress supplies the remaining 15%.","Dim",14,true))
	_add(U.lbl("To improve readiness: practise the relevant skill, maintain health and happiness, and reduce stress through rest or suitable activities. Practice and qualifications still matter. Chance remains uncertain; fixed wages and games of pure luck do not become guaranteed wins.","Dim",16,true))


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
	return U.row(U.npc_icon(n), title, sub, func(): _open_panel(func(): _panel_person(nid)), true, true, extra)


func _panel_person(id: String, detailed: bool=false) -> void:
	var n := GameState.npc(id)
	if n.is_empty():
		_panel_back()
		return
	_panel_header(U.npc_face(n), "Profile · "+str(n["first"]) if detailed else str(n["first"]))
	var info := U.card("Inset")
	var iv := U.vb(6)
	info.add_child(iv)
	if n.get("species","human")=="human":
		var portrait := AvatarView.new(); portrait.custom_minimum_size=Vector2(90,90)
		portrait.setup(Avatar.appearance(n),int(n["age"]),str(n["gender"]),false,n)
		iv.add_child(portrait)
	iv.add_child(U.lbl("%s  ·  %s" % [GameState.full_name(id), GameState.relation_label(id)], "Bold", 20))
	var details := "Age %d" % int(n["age"])
	if detailed and n.get("species", "human") == "human":
		details += "  ·  Trait: %s  ·  Looks %d%%" % [n.get("trait", ""), int(n.get("looks", 50))]
	if not n["alive"]:
		details += "  ·  Deceased"
	iv.add_child(U.lbl(details, "Dim", 16))
	if detailed or n.get("species","human")!="human":
		if n.get("species","human") == "human" and not Lives.separate():
			FamilyChronicle.sync()
			iv.add_child(U.btn("📖 Personal record",Callable(self,"_show_family_record").bind(FamilyChronicle.identity(n))))
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
				var cr: Dictionary = Companions.ensure(id).get("care", {})
				iv.add_child(U.track("🥣", "Fed", float(cr.get("fed", 70)), 100.0,
					ThemeManager.bar_color("health", float(cr.get("fed", 70))), "%d%%" % int(cr.get("fed", 70))))
				iv.add_child(U.lbl(Companions.status_line(id), "Dim", 14, true))
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
	if detailed and n.get("species", "human") == "human":
		if Journey.modules.has("people"):
			for motive_line in Journey.modules["people"].profile_lines(id):
				iv.add_child(U.lbl(str(motive_line), "Dim", 14, true))
		LifeThreads.ensure()
		var saved_threads: Dictionary = GameState.player.get("threads", {})
		var thread_items: Dictionary = saved_threads.get("items", {})
		var thread_history: Array = saved_threads.get("history", [])
		var shared: Array = []
		for thread_id in thread_items.keys():
			if not (thread_items[thread_id] is Dictionary):
				continue
			var candidate: Dictionary = thread_items[thread_id]
			if str(candidate.get("npc", "")) == id:
				shared.append(candidate)
		for archived_thread in thread_history:
			if archived_thread is Dictionary and str(archived_thread.get("npc", "")) == id:
				shared.append(archived_thread)
		shared.sort_custom(func(a, b): return int(a.get("last_touched", 0)) > int(b.get("last_touched", 0)))
		if not shared.is_empty():
			iv.add_child(U.lbl("🧵 Shared history", "Bold", 14))
			var shared_lines: Array = []
			for shared_thread in shared.slice(0, 3):
				var memory := str(shared_thread.get("memory", ""))
				if memory.length() > 92:
					memory = memory.substr(0, 89) + "…"
				var marker := "📕" if str(shared_thread.get("state", "active")) == "resolved" else "•"
				var title := str(shared_thread.get("title", "A moment that stayed"))
				var moment_count := Array(shared_thread.get("moments", [])).size()
				var moment_note := " · %d moments" % moment_count if moment_count > 1 else ""
				shared_lines.append("%s %s%s%s" % [marker, title, moment_note, " · " + memory if memory != "" else ""])
			iv.add_child(U.lbl("\n".join(shared_lines), "Dim", 14, true))
	_add(info)
	if detailed:
		_add(U.row("←","Interactions","Return to this person",func(): _open_panel(func(): _panel_person(id)),true,true))
		return
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
		_add(U.row("🧰", "Your job", "Tasks, raises, team and workplace", func(): _open_panel(_panel_at_work)))
		MP.rows_into(Bulk.menu("work"))
	var school_sub := "Not enrolled"
	if GameState.in_school():
		school_sub = Journey.modules["campus"].title() + " · Grade " + str(p["education"]["grade"] if p["education"]["grade"] != "" else "—")
	elif GameState.in_university():
		school_sub = "%s · Year %d of %d" % [ContentDB.major(p["education"]["uni"]["major"])["name"], int(p["education"]["uni"]["year"]) + 1, int(p["education"]["uni"]["years"])]
	elif age >= 18:
		school_sub = "University and graduate school"
	elif age < 5:
		school_sub = "School starts at 5"
	_add(U.row("🎓", "Education", school_sub, func(): _open_panel(_panel_education), age >= 3))
	_add(U.row("🔎", "Find a job", "Part-time, full-time, military and freelance", func(): _open_panel(_panel_find_work), age >= 13))
	_add(U.row("📈", "Careers & business", "Special paths, companies and career growth", func(): _open_panel(_panel_career_enterprise), age >= 6))
	if p["retired"]:
		_add(U.lbl("Retired · pension %s a year" % GameState.fmt_money(int(p["pension"])), "Dim", 16))


func _panel_career_enterprise() -> void:
	_panel_header("📈", "Careers & business")
	var p := GameState.player
	var age: int = int(p["age"])
	_add(U.row("💼", "Work & career", "Projects, training, promotion and pay", func(): MP.open("employment:root"), age >= 16))
	_add(U.row("🏢", "Business", ("%s · profit %s last year" % [p["business"]["name"], GameState.fmt_money(int(p["business"]["profit"]))]) if not p["business"].is_empty() else "Start a company", func(): _open_panel(_panel_business_hub), age >= 18))
	_add(U.row("⭐", "Special careers", "Sport, politics, arts and more", func(): _open_panel(_panel_special_hub), age >= 6))
	if not p["career"].is_empty():
		var cd: Dictionary = Careers.CAREERS[p["career"]["id"]]
		_add(U.row(cd["icon"], "Your career · " + Careers.title(), cd["name"], func(): _open_panel(_panel_career)))
	_add(U.row("🎛️", "Producer studio", "Make and release music", func(): MP.open("creator:studio"), age >= 18))
	_add(U.row("🔒", "OnlyPals", "Adult creator work and privacy", func(): MP.open("creator:fans"), age >= 18))


func _panel_at_work() -> void:
	_panel_header("🧰", "Your job")
	var p := GameState.player
	if not GameState.has_job():
		_add(U.lbl("You do not have a job right now.", "Dim", 16))
		return
	var j: Dictionary = p["job"]
	_add(U.row("📋", "Duties & team", "Tasks, situations and colleagues", func(): MP.open("employment:duties")))
	_add(U.row("📈", "Career & pay", "Projects, growth, salary and conditions", func(): MP.open("employment:root")))
	_add(U.row("@office", "Your workplace", "Boss, colleagues, union and office choices", func(): MP.open("real:work")))
	_add(U.section("This year"))
	_add(U.row("💪", "Work harder", "More performance · more stress", _act(Actions.work_harder), not j.get("worked_hard", false), false))
	_add(U.row("💰", "Ask for a raise", "1 time · higher performance improves the chance", _act(Actions.ask_raise), true, false))
	if j["field"] == "Military":
		_add(U.row("💣", "Deploy", "Minigame · clear a path through a minefield", _act(Actions.deploy), GameState.can_interact("job", "deploy"), false))
	if Shop.has_tag("suit") and not j.get("suited", false):
		_add(U.row("👔", "Dress to impress", "Wear the tailored suit this year · performance up", _act(Actions.dress_up), true, false))
	_add(U.row("🚪", "Quit job", "Leave now without a manager reference", _act(Actions.quit_job), true, false))
	if int(p["age"]) >= 60:
		_add(U.row("🏖️", "Retire", "Collect a pension", _act(Actions.retire), true, false))


func _panel_find_work() -> void:
	_panel_header("🔎", "Find work")
	var p := GameState.player
	var age: int = p["age"]
	_add(U.row("🍔", "Part-Time Jobs", "Find a part-time job" if age >= 13 else "Age 13+", func(): _open_panel(func(): _panel_jobs("part")), age >= 13))
	_add(U.row("💼", "Full-Time Jobs", "Find a full-time job" if age >= 18 else "Age 18+", func(): _open_panel(func(): _panel_jobs("full")), age >= 18))
	_add(U.row("🎖️", "Military", "Enlist and climb the ranks" if age >= 18 else "Age 18+", func(): _open_panel(func(): _panel_jobs("military")), age >= 18))
	_add(U.row("🧾", "Freelance", "Pick up a gig for quick cash" if age >= 14 else "Age 14+", _act(Actions.freelance), age >= 14, false))
	if not GameState.has_job() and age >= 18:
		_add(U.row("@signpost", "Career moves", "Freelancing, retraining, and what your CV says", func(): MP.open("real:work")))
	var hist: Array = Market.st().get("history", [])
	if not hist.is_empty():
		_add(U.row("📭", "Recent applications", "%d turned down, with the reasons" % hist.size(), func(): _open_panel(_panel_applications)))


func _panel_applications() -> void:
	_panel_header("📭", "Recent applications")
	for h in Market.st().get("history", []):
		_add(U.row("📭", "%s · %s" % [str(h["role"]), str(h["co"])], "Age %d · %s" % [int(h["age"]), str(h["why"])], func(): pass, false, false))


func _panel_business_hub() -> void:
	_panel_header("📈", "Business")
	var p := GameState.player
	var biz: Dictionary = p["business"]
	_add(U.row("📈", "Your company", ("%s · profit %s last year" % [biz["name"], GameState.fmt_money(int(biz["profit"]))]) if not biz.is_empty() else "Start a company", func(): _open_panel(ep.business)))
	_add(U.row("🏢", "Company Portfolio", "Own multiple companies, acquire rivals and plan succession", func(): MP.open("amb:enterprise")))
	_add(U.row("🎲", "Venues & ventures", "Casinos, museums, agencies and the Velvet Society", func(): MP.open("venue:root")))


func _panel_education() -> void:
	_panel_header("🎓", "Education")
	var p := GameState.player
	var e: Dictionary = p["education"]
	var c := U.card("Inset")
	var cv := U.vb(6)
	c.add_child(cv)
	if GameState.in_school():
		cv.add_child(U.lbl(Journey.modules["campus"].title(), "Bold", 20))
		var gtxt := "Current grade: %s" % (e["grade"] if e["grade"] != "" else "—")
		if int(e["gpa_years"]) > 0:
			gtxt += "  ·  GPA %.2f" % GameState.gpa()
		cv.add_child(U.lbl(gtxt, "Dim", 16))
		var ph := U.hb(10)
		ph.add_child(U.lbl("Performance", "", 16))
		ph.add_child(U.bar(float(e["performance"]), ThemeManager.bar_color("happiness", float(e["performance"])), 14))
		cv.add_child(ph)
		var sp := U.hb(10)
		sp.add_child(U.lbl("Stage progress", "", 16))
		sp.add_child(U.bar(Journey.modules["campus"].progress(), ThemeManager.bar_color("school", Journey.modules["campus"].progress()), 14))
		cv.add_child(sp)
	elif GameState.in_university():
		var u: Dictionary = e["uni"]
		cv.add_child(U.lbl(ContentDB.major(u["major"])["name"], "Bold", 20))
		cv.add_child(U.lbl("Year %d of %d  ·  Grade %s%s" % [int(u["year"]) + 1, int(u["years"]), EventEngine.grade_letter(float(u["performance"])), "  ·  Scholarship" if float(u.get("scholarship", 0)) > 0 else ""], "Dim", 16))
	else:
		var lvl: String = {"none": "No diploma", "high_school": "High school diploma", "associate":"Associate diploma", "bachelor": "Bachelor's degree", "graduate": "Graduate degree"}[GameState.edu_level()]
		cv.add_child(U.lbl(lvl, "Bold", 20))
		if int(e["gpa_years"]) > 0:
			cv.add_child(U.lbl("High school GPA %.2f" % GameState.gpa(), "Dim", 16))
	for d in e["degrees"]:
		cv.add_child(U.lbl("🎓 " + str(d["name"]), "Dim", 15))
	_add(c)
	if GameState.in_school() or GameState.in_university():
		_add(U.row("🏫","School community" if GameState.in_school() else "Campus & classes",Journey.modules["campus"].title()+" · people, classes and activities",func(): MP.open("journey:campus")))
		_add(U.lbl("Grades affect admission, scholarships and job eligibility. Health, happiness and stress shape yearly results.","Dim",15,true))
		MP.rows_into(Bulk.menu("education"))
	if GameState.in_school():
		_add(U.row("🏃", "Skip class", "Fun now, worse grades", _act(Actions.skip_class), true, false))
	if GameState.in_university():
		if GameState.player["education"]["uni"].get("level","")=="bachelor":
			_add(U.row("🎓","Change major","Preview credits, remaining years and fee",func(): _open_panel(_panel_change_major)))
		_add(U.row("🚪", "Drop out", "", _act(Actions.drop_out), true, false))
	elif int(GameState.player["age"])>=16:
		_add(U.row("🧭","Further study & training","Courses, apprenticeships and university",func(): _open_panel(_panel_further_study)))


func _panel_further_study() -> void:
	_panel_header("🧭","Further study & training")
	_add(U.section("Qualifications"))
	_add(U.row("🧰","Practical courses","Short courses employers recognize",func(): MP.open("market:training"),int(GameState.player["age"])>=16))
	_add(U.row("🎓","Apprenticeships & retraining","Train for a field and earn a qualification",func(): MP.open("employment:training"),int(GameState.player["age"])>=16))
	_add(U.section("University"))
	var interrupted: Array=GameState.player["education"].get("interrupted_study",[])
	for i in range(interrupted.size()):
		if interrupted[i].get("state","")!="open": continue
		var index := i
		var course: Dictionary=interrupted[i]["course"]
		var why := Actions.study_return_reason(index)
		_add(U.row("🎓","Return to "+str(ContentDB.major(str(course["major"])).get("name","study")),why if why!="" else "%d years kept · 1 time · %s · scholarship ends" % [course["year"],GameState.fmt_money(Actions._cost(300))],_act(func(): Actions.return_to_study(index)),why=="",false))
	var why_b := Actions.can_enroll("bachelor")
	_add(U.row("🏛️","University",why_b if why_b!="" else "Apply for a bachelor's degree",func(): _open_panel(func(): _panel_majors("bachelor")),why_b==""))
	var why_g := Actions.can_enroll("graduate")
	_add(U.row("📜","Graduate school",why_g if why_g!="" else "Law, medicine, MBA, PhD and more",func(): _open_panel(func(): _panel_majors("graduate")),why_g==""))


func _panel_change_major() -> void:
	_panel_header("🎓","Change major")
	_add(U.lbl("Same university · one change per year. Related subjects keep more credit. Grades, scholarship and loans stay with you.","Dim",15,true))
	for major in ContentDB.majors_of_level("bachelor"):
		var mid: String=major["id"]
		var preview := Actions.major_change_preview(mid)
		if preview.is_empty(): continue
		var available := Journey.blocked(18)=="" and not Journey.used("major_change") and int(GameState.player["money"])>=int(preview["fee"]) and int(GameState.player["time_left"])>=1
		_add(U.row("@study:"+mid,major["name"],"%d credited · %d lost · %d years left · 1 time · %s" % [preview["credit"],preview["lost"],preview["remaining"],GameState.fmt_money(int(preview["fee"]))],_act(func(): Actions.change_major(mid); _panel_back_to_root()),available,false))


func _panel_majors(level: String) -> void:
	_panel_header("🏛️", "Choose a Major" if level == "bachelor" else "Graduate School")
	var tuition := 12000 if level == "bachelor" else 25000
	var note := "Admission uses GPA, activities and related projects; GPA and team captaincy affect aid." if level == "bachelor" else "Admission uses smarts and your prior degree."
	_add(U.lbl("Tuition ~%s/year · unpaid fees become a student loan.\n%s" % [GameState.fmt_money(int(tuition * float(ContentDB.country(GameState.player["country"]).get("cost", 1.0)))), note], "Dim", 15, true))
	for m in ContentDB.majors_of_level(level):
		var mid: String = m["id"]
		var credit := Actions.college_credit(mid)
		var duration := int(m["years"])-credit
		var sub := "%d years · ~%d%% admission" % [duration, roundi(Actions.enrollment_chance(mid)*100.0)]
		if credit>0: sub += " · %d credited" % credit
		_add(U.row("@study:"+mid, m["name"], sub, _act(func(): Actions.enroll(mid); _panel_back_to_root()), true, false))


func _panel_back_to_root() -> void:
	while panel_stack.size() > 1:
		panel_stack.pop_back()


func _panel_jobs(kind: String) -> void:
	var titles := {"part": "Part-Time Jobs", "full": "Full-Time Jobs", "military": "Military"}
	_panel_header({"part": "🍔", "full": "💼", "military": "🎖️"}[kind], titles[kind])
	_add(U.lbl("See the duties, pay and fit before applying. An application uses 1 time.", "Dim", 15, true))
	var hist: Array = Market.st().get("history", [])
	if not hist.is_empty():
		var hl: Array = []
		for h in hist.slice(0, 4):
			hl.append("Age %d · %s (%s): %s" % [int(h["age"]), str(h["co"]), str(h["role"]), str(h["why"])])
		_add(U.lbl("Recent applications\n" + "\n".join(hl), "Dim", 14, true))
	var list := Market.openings(kind)
	if list.is_empty():
		_add(U.lbl("No openings right now. Check again next year.", "Dim", 16))
	for l in list:
		var jd := ContentDB.job(str(l["job"]))
		var why := str(l["locked"])
		var sub := "%s/year" % GameState.fmt_money(int(l["salary"]))
		if why != "":
			sub = "🔒 Requires: " + why
		else:
			var stand := Market.standing(l)
			sub += " · fit ~%d%% · details" % roundi(float(stand["chance"])*100.0)
		var applied: bool = Market.st()["applied"].has(str(l["id"]))
		if applied:
			sub = "✓ Applied · " + sub
		var l_id: String = str(l["id"])
		_add(U.row("@"+Icons.for_job(str(jd["id"])), "%s · %s" % [str(jd["ranks"][0]), str(l["company"])], sub, func(): _open_panel(func(): _panel_job_details(l_id)), why == "", true))


func _panel_job_details(id: String) -> void:
	_panel_header("💼", "Opening details")
	var listing := Market.find(id)
	if listing.is_empty():
		_add(U.lbl("This opening is no longer available.", "Dim", 16, true))
		return
	var jd := ContentDB.job(str(listing["job"]))
	var stand := Market.standing(listing)
	_add(U.lbl("%s · %s\n%s/year · %d applicants%s" % [str(jd["ranks"][0]),str(listing["company"]),GameState.fmt_money(int(listing["salary"])),int(listing["apps"])," · remote" if bool(listing.get("remote",false)) else ""], "Dim", 16, true))
	var duties: Array=Depth.jobs.get(str(listing["job"]),[])
	if not duties.is_empty():
		var duty_names: Array=[]
		for duty in duties.slice(0,2): duty_names.append(str(duty.get("name","")))
		_add(U.lbl("Typical duties · "+", ".join(duty_names),"Dim",15,true))
	_add(U.lbl("Fit estimate · %d%% · screening and interview" % roundi(float(stand["chance"])*100.0), "Bold", 16, true))
	var helps: Array=[]; var risks: Array=[]
	for line in stand.get("lines",[]):
		var value := float(line[1])
		if absf(value)<0.001: continue
		if value>0.0: helps.append(str(line[0]))
		else: risks.append(str(line[0]))
	if not helps.is_empty(): _add(U.lbl("Helps · "+", ".join(helps), "Dim", 15, true))
	if not risks.is_empty(): _add(U.lbl("Risks · "+", ".join(risks), "Dim", 15, true))
	else: _add(U.lbl("No major fit gap; each opening still has competition.", "Dim", 15, true))
	var already_applied: bool=Market.st()["applied"].has(id)
	var blocked := Actions.job_requirement(jd)
	if blocked!="":
		_add(U.lbl("Requires · "+blocked,"Dim",15,true))
	else:
		_add(U.row("✉️","Send application","1 time · CV screening; interview if selected",_act(func(): Market.apply(id)),not already_applied and not Actions._out_of_time(),false))


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
	_add(U.section("Choose a section"))
	_add(U.row("🧾", "Money & planning", "Savings, budgets and upcoming costs", func(): _open_panel(Callable(self, "_panel_assets_page").bind("money"))))
	_add(U.row("🏠", "Home & location", "Housing, tenancy and where you live", func(): _open_panel(Callable(self, "_panel_assets_page").bind("home"))))
	_add(U.row("🚗", "Transport", "Vehicles, upkeep and commuting", func(): _open_panel(Callable(self, "_panel_assets_page").bind("transport"))))
	_add(U.row("📦", "Things & collections", "%d owned · keepsakes, art and stores" % p["possessions"].size(), func(): _open_panel(Callable(self, "_panel_assets_page").bind("things"))))
	var biz_text := "Property, companies and ventures"
	if not p["business"].is_empty(): biz_text = "%s · own %d%%" % [p["business"]["name"], int(float(p["business"]["stake"]) * 100)]
	_add(U.row("🏢", "Businesses & property", biz_text, func(): _open_panel(Callable(self, "_panel_assets_page").bind("ventures"))))


func _panel_assets_page(page: String) -> void:
	var p := GameState.player
	var age: int = int(p["age"])
	match page:
		"money":
			_panel_header("🧾", "Money & planning")
			_add(U.row("🧭", "Plan costs & savings", "Forecasts and recurring clients", func(): MP.open("balance:root")))
			_add(U.row("👪", "Family budget", "Childhood support and contributions", func(): MP.open("child:root")))
			_add(U.row("🏦", "Savings & investments", "Cash %s · portfolio %s" % [GameState.fmt_money(int(p["savings"])), GameState.fmt_money(Finance.investments_value())], func(): _open_panel(_panel_investments), age >= 16))
			_add(U.row("💳", "Borrow money", "Loans and payment support", func(): _open_panel(_panel_loans), age >= 18))
		"home":
			_panel_header("🏠", "Home & location")
			var home: Dictionary = Actions.HOME_MODELS.get(str(p.get("house_model", "")), {"name": GameState.HOUSING[p["housing"]]["name"]})
			_add(U.row("🏠", "Your home", str(home["name"]) + " · ownership and sale", func(): _open_panel(_panel_housing), age >= 18))
			_add(U.row("🛠️", "Home life", "Upkeep, neighbors and renovations", func(): MP.open("exp:home"), age >= 18 and p["housing"] == "house"))
			_add(U.row("🔑", "Tenancy", "Landlord, repairs and flatmates", func(): MP.open("real:home"), age >= 18 and Tenancy.renting()))
			_add(U.row("📨", "Keeping up", "Invites, food and phone", func(): MP.open("real:keep"), age >= 14))
			_add(U.row("🏙️", "Where you live", Places.place_name() + " · local costs and laws", func(): _open_panel(LP.places_panel)))
			_add(U.row("🛍️", "Browse homes", "Homes & housing", func(): MP.open("shop:category:homes"), age >= 18))
		"transport":
			_panel_header("🚗", "Transport")
			var car_name: String = str(GameState.CARS[p["car"]]["name"]) if p["car"] != "" else "No vehicle owned"
			_add(U.row("🚗", "Your vehicles", car_name + " · ownership and sale", func(): _open_panel(_panel_vehicles), age >= 16))
			_add(U.row("🔧", "Upkeep & household use", "Condition, mileage and repairs", func(): MP.open("hold:root"), age >= 16))
			_add(U.row("🧭", "Getting about", "Commute, insurance and running costs", func(): MP.open("real:go"), age >= 12 and (Transit.commuting() or Transit.has_car())))
			_add(U.row("🛍️", "Browse vehicles", "Cars and other transport", func(): MP.open("shop:category:transport"), age >= 16))
		"things":
			_panel_header("📦", "Things & collections")
			_add(U.row("📦", "Possessions", "%d owned · see or sell keepsakes" % p["possessions"].size(), func(): _open_panel(_panel_possessions), age >= 16))
			_add(U.row("🛍️", "Shopping", "Stores, gifts and collectibles", func(): MP.open("shop:root")))
			_add(U.row("🏛️", "Museum", "Exhibits, visitors and costs", func(): MP.open("journey:collection"), age >= 21))
			var zoo: Dictionary = p["zoo"]
			_add(U.row("🦁", "Zoo", ("%s · %d visitors last year" % [zoo["name"], int(zoo["visitors"])]) if not zoo.is_empty() else "Run a zoo", func(): _open_panel(ep.zoo), age >= 21))
		"ventures":
			_panel_header("🏢", "Businesses & property")
			_add(U.row("🏘️", "Property", "%d owned · rent and tenants" % p["properties"].size(), func(): _open_panel(_panel_property), age >= 18))
			_add(U.row("📈", "Business", "Companies, ownership and operations", func(): _open_panel(_panel_business_hub), age >= 18))
			if World.billionaire_open():
				_add(U.row("💎", "Billionaire", "Teams, foundations and nation-building", func(): _open_panel(LP.billionaire_panel)))


func _panel_housing() -> void:
	_panel_header("🏠", "Houses")
	var p := GameState.player
	var cost: float = ContentDB.country(p["country"]).get("cost", 1.0)
	_add(U.lbl("Now: " + GameState.HOUSING[p["housing"]]["name"], "Bold", 18))
	if p["housing"] == "house":
		var model: Dictionary=Actions.HOME_MODELS.get(str(p.get("house_model","")),{})
		if not model.is_empty(): _add(U.row("@"+str(model["icon"]),str(model["name"]),"Your primary home",func(): pass,false,false))
		_add(U.row("💲", "Sell your house", "Worth about %s" % GameState.fmt_money(int(p["house_value"])), _act(Actions.sell_house),true,false))
	else:
		_add(U.lbl("No owned home.", "Dim", 15, true))
		_add(U.row("🛍️", "Browse homes", "Homes & housing", func(): MP.open("shop:category:homes"), int(p["age"]) >= 18))
	if p["housing"] == "apartment" or p["housing"] == "homeless":
		_add(U.row("🏠", "Move back with family", "Cheaper, less freedom", _act(Actions.move_home), true, false))


func _panel_vehicles() -> void:
	_panel_header("🚗", "Vehicles")
	var p := GameState.player
	if p["car"] != "":
		_add(U.lbl("You drive a " + GameState.CARS[p["car"]]["name"].to_lower() + ".", "Bold", 18))
		_add(U.row("💲", "Sell your car", GameState.fmt_money(Holdings.resale()), _act(Actions.sell_car), true, false))
		_add(U.row("🔧","Condition & repairs","Mileage, servicing and reliability",func(): MP.open("hold:root")))
	else:
		_add(U.lbl("No vehicle owned yet.", "Dim", 15, true))
		_add(U.row("🛍️", "Browse vehicles", "Cars and other transport", func(): MP.open("shop:category:transport"), int(p["age"]) >= 16))


# ---- more

func _panel_more() -> void:
	_panel_header("⋯", "More")
	_add(U.row("🧵", "Life activities", "School, work, people and hobbies", func(): MP.open("journey:root")))
	_add(U.row("🔎", "Search & help", "Find a feature or learn the basics", func(): _open_panel(Callable(self, "_panel_more_page").bind("find"))))
	_add(U.row("📖", "Story & memories", "Choices, changes and records", func(): _open_panel(Callable(self, "_panel_more_page").bind("story"))))
	_add(U.row("👪", "Family & home", "Family tree and household", func(): _open_panel(Callable(self, "_panel_more_page").bind("people"))))
	_add(U.row("🏆", "Goals & keepsakes", "Missions, awards and collections", func(): _open_panel(Callable(self, "_panel_more_page").bind("goals"))))
	_add(U.row("🌍", "World & settings", "Appearance, sound and display", func(): _open_panel(Callable(self, "_panel_more_page").bind("world"))))
	_add(U.row("💾", "Lives & saves", "Switch, copy or leave", func(): _open_panel(Callable(self, "_panel_more_page").bind("saves"))))

func _panel_more_page(page: String) -> void:
	match page:
		"find":
			_panel_header("🔎", "Search & help")
			_add(U.row("🔎", "Find & favourites", "Search activities and destinations", func(): _open_panel(NAV.show)))
			_add(U.row("❔", "Quick guide", "Time, stats and outcomes", func(): _open_panel(_panel_guide)))
			_add(U.row("🧭", "Your stats", "Readiness and success chances", func(): _open_panel(_panel_readiness)))
		"story":
			_panel_header("📖", "Story & memories")
			_add(U.row("📌", "Recent effects", "Changes and scheduled follow-ups", func(): _open_panel(_panel_consequences)))
			_add(U.row("📜", "Remembered choices", "Decisions saved in this life", func(): _open_panel(_panel_decision_memory)))
			_add(U.row("📖", "Family records", "School, work and key memories", _show_family_records))
			_add(U.row("🗓️", "This year", "Summary and open stories", _show_year_summary))
			_add(U.row("🧭", "Endings seen", _endings_sub(), _show_endings))
			_add(U.row("🕰️", "Past-life echoes", "%d waiting for a new life" % Legacy.pending().size(), _show_legacy))
		"people":
			_panel_header("👪", "Family & home")
			_add(U.row("🌳", "Family tree", "See your family at a glance", _show_family_tree))
			_add(U.row("🏠", "Household & week", "Bills, care, chores and rest", func(): MP.open("home:root")))
		"goals":
			_panel_header("🏆", "Goals & keepsakes")
			var ready := Goals.unclaimed_count()
			_add(U.row("🎁","Daily Heirloom","Ready to open" if Goals.daily_available() else "Next in "+Goals.fmt_left(Goals.seconds_left("daily")),func(): SP.show_heirloom()))
			_add(U.row("🎯","Missions",("%d ready to claim · " % ready if ready>0 else "")+"Daily, weekly and monthly goals",_show_missions))
			_add(U.row("🏆","Trophy Room","%d / %d achievements · ⭐ %d Stars" % [Meta.meta["goals"]["ach"].size(),Goals.achievements.size(),Goals.stars()],_show_trophies))
			_add(U.row("⭐","Star Shop","Items, avatar parts and titles",_show_star_shop))
			_add(U.row("🏅","Challenges","Goal lives and badges",func(): _open_panel(_panel_challenges)))
			_add(U.row("🎀","Ribbon collection","Achievements across your lives",func(): _open_panel(_panel_ribbons)))
			_add(U.row("🪦","Graveyard","Past lives and their stories",_open_graveyard))
		"world":
			_panel_header("🌍", "World & settings")
			_add(U.row("🌍", "The world", (", ".join(World.active_list().map(func(w): return World.EVENTS[w]["name"])) if not World.active_list().is_empty() else "Quiet year") + " · headlines", func(): _open_panel(LP.world_panel)))
			_add(U.row("🪞", "Appearance", "Change your avatar", func(): _open_avatar_editor(Avatar.for_player(), str(GameState.player.get("gender", "male")), int(GameState.player.get("age", 25)), func(a): Avatar.set_current(a); _refresh_side())))
			_add(U.row("🧙", "Sandbox mode", "Edit a character or their circumstances", func(): _open_panel(_panel_god)))
			_add(U.row("⚙️", "Settings", "Sound, effects, motion and controls", func(): _open_panel(_panel_settings)))
			_add(U.row("🎨", "Theme: " + ThemeManager.LABELS[ThemeManager.current], "Switch dark palettes", func(): _set_theme(ThemeManager.next_theme()), true, false))
		"saves":
			_panel_header("💾","Lives & saves")
			_add(U.row("📂","Your lives","Switch to another saved life",func(): SaveManager.save_game(); SP.show_lives()))
			_add(U.row("⧉","Duplicate this life","Create a separate branch",func():
				var j := SaveManager.duplicate_current()
				_toast("⧉","Life duplicated" if j>0 else "No free slot",("Copy saved to slot %d" % j) if j>0 else "Delete a life first",ThemeManager.c("good") if j>0 else ThemeManager.c("warn")),true,false))
			_add(U.row("🕯️","End this life","Fictional ending · confirmation required",_confirm_end_life,GameState.is_alive() and int(GameState.player.get("age",0))>=18 and not Lives.separate()))
			_add(U.row("💾","Save & exit","Return to the title screen",func(): SaveManager.save_game(); _show("title"),true,false))
			_add(U.lbl("Space · age up   Esc · back   1–9 · choose", "Dim", 14, true))

# ================================================================= POPUPS

func _open_live_child_switch() -> void:
	if mg_open or EventEngine.has_pending():
		_show_info("⏳", "Finish the current decision", "Resolve the active decision before changing the family viewpoint.", {})
		return
	var body := _big_popup(850, "👪", "Choose your next viewpoint", "The parent stays alive. The child keeps their recorded life; no estate is transferred.")
	for id in Dynasty.candidates():
		Web.ensure_job(id)
		var child: Dictionary = GameState.npcs[id]
		var row := U.row(U.npc_icon(child), GameState.full_name(id), "Age %d · %s · %s" % [int(child["age"]), Web.job_title(id), GameState.fmt_money(int(child.get("money",0)))], func(): _confirm_child_switch(id))
		row.name = "Child_" + id
		body.add_child(row)
	if Dynasty.candidates().is_empty(): body.add_child(U.lbl("There are no living human children to switch to.", "Dim", 17, true))

func _confirm_child_switch(id: String) -> void:
	if not Dynasty.candidates().has(id): return
	FamilyChronicle.ensure_npc(id)
	var child: Dictionary = GameState.npcs[id]
	var work: Dictionary = child.get("job",{})
	var preview := "Age %d · %s\nSchool: %s · Cash: %s\nAnnual salary: %s%s\n%d recorded memories · %d recorded convictions\n\n" % [int(child["age"]),work.get("title","Unemployed"),str(child["education"].get("stage","none")).capitalize(),GameState.fmt_money(int(child["money"])),GameState.fmt_money(int(work.get("salary",0)))," (estimated legacy detail)" if work.get("salary_source","")=="estimated" else "",child.get("personal_history",[]).size(),child.get("record",[]).size()]
	_show_menu_popup("👪", "Switch to " + GameState.full_name(id) + "?", preview + "This changes the active character in the current save. Recorded history, age, stats, education, employment and personal money stay with them. The parent keeps their assets and remains alive. Duplicate the save first if you want a separate branch.", [["Keep this viewpoint", _close_popup], ["Switch viewpoint", func():
		if Dynasty.switch_to(id):
			_close_popup()
			panel_stack.clear()
			panel_positions.clear()
			panel_names.clear()
			last_stats.clear()
			last_money = 0
			SaveManager.save_game()
			_show("game")]])

func _confirm_end_life() -> void:
	if mg_open or not GameState.is_alive() or Lives.separate() or int(GameState.player.get("age",0)) < 18: return
	_show_menu_popup("🕯️", "End this fictional life?", "This records suicide as the cause of death, without depicting a method. It permanently closes this life in the current save. There is no special reward for this ending. You can continue playing, start another life, or later continue as a living child.", [["Keep living", _close_popup], ["End this life", func(): _close_popup(); EventEngine.kill("suicide", true)]])

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.42)
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
	overlay_frame.custom_minimum_size = Vector2(minf(width,get_viewport_rect().size.x-48), 0)
	U.clear(overlay_box)
	var sc := ScrollContainer.new()
	sc.name="PopupScroll"; sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus=true
	sc.custom_minimum_size=Vector2(0,180)
	overlay_box.add_child(sc)
	VFX.pop_in(overlay_frame)
	var v := U.vb(12); v.name="PopupContent"; v.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	v.minimum_size_changed.connect(func(): _fit_active_popup.call_deferred())
	sc.add_child(v)
	_fit_active_popup.call_deferred()
	if UIKit.kb_mode:
		_focus_overlay.call_deferred()
	return v

func _fit_active_popup() -> void:
	if not is_instance_valid(overlay_box) or not overlay.visible: return
	var sc := overlay_box.get_node_or_null("PopupScroll") as ScrollContainer
	if sc==null or sc.is_queued_for_deletion(): return
	var content := sc.get_node_or_null("PopupContent") as Control
	if content==null: return
	var chrome := 48.0
	for child in overlay_box.get_children():
		if child!=sc and child is Control: chrome+=child.get_combined_minimum_size().y+12
	var room := maxf(180,get_viewport_rect().size.y*0.72-chrome)
	sc.custom_minimum_size.y=minf(room,maxf(100,content.get_combined_minimum_size().y))


func _close_popup() -> void:
	if EventEngine.displayed.get("info",false): EventEngine.displayed.clear()
	_remember_panel_scroll()
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
	var head := U.hb(14)
	var badge := U.card("EventIcon"); badge.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	badge.add_child(U.lbl(icon,"Emoji",40)); head.add_child(badge)
	var t := U.lbl(title, "EventTitle", 24, true)
	t.size_flags_horizontal=Control.SIZE_EXPAND_FILL; t.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	head.add_child(t)
	if v.name=="PopupContent" and v.get_parent() is ScrollContainer:
		head.name="EventHeading"; overlay_box.add_child(head); overlay_box.move_child(head,0)
	else: v.add_child(head)


func _event_text(v: VBoxContainer, text: String) -> void:
	var l := U.lbl(text, "EventText", 19, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(l)


func _show_decision(inst: Dictionary) -> void:
	EventEngine.displayed = inst.duplicate(true)
	SaveManager.save_game()
	Fx.play("choice")
	var def: Dictionary = inst["def"]
	var roles: Dictionary = inst.get("roles", {})
	var v := _open_popup(700 if def.get("twist", false) else 640)
	if def.get("twist", false):
		_twist_banner(v)
	_event_header(v, def.get("icon", "❔"), EventEngine.tokens(def.get("title", "Event"), roles))
	_event_text(v, EventEngine.tokens(def.get("text", ""), roles))
	var shown_people: Array=[]
	for who in roles.values():
		if shown_people.size()>=2: break
		if shown_people.has(who) or not GameState.npc(str(who)).get("alive",false): continue
		shown_people.append(who)
		v.add_child(U.lbl(GameState.full_name(str(who))+" · "+Bonds.quick_line(str(who)),"Dim",14,true))
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
		var hint_txt := str(st.get("hint", ""))
		if hint_txt != "":
			label = "%s\n%s" % [label, hint_txt]
		var idx := i
		var is_twist: bool = bool(def.get("twist", false))
		var press := func(): _choose(inst, idx)
		if is_twist:
			press = func(): _confirm_twist(inst, idx, label)
		var b := U.btn(label, press, "ChoiceRow")
		b.name = "Choice%d" % n
		b.disabled = not st["enabled"]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(0, 48)
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
func _confirm_do_over() -> void:
	Fx.play("choice")
	var v := _open_popup(560)
	_event_header(v,"⏪","Use a Do-Over?")
	var w := U.lbl("The year goes back to its start and you live it again. You have %d." % Items.owned("do_over"), "Dim", 16)
	w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(w)
	var yes := U.btn("Rewind the year", func(): _close_popup(); _use_star_item("do_over"), "Primary")
	yes.custom_minimum_size = Vector2(0, 54)
	v.add_child(yes)
	var no := U.btn("Not now", _close_popup, "Row")
	v.add_child(no)


func _confirm_twist(inst: Dictionary, idx: int, label: String) -> void:
	Fx.play("choice")
	var v := _open_popup(560)
	_event_header(v,"⚠️","Are you sure?")
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
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	overlay_frame.custom_minimum_size = Vector2(minf(980,get_viewport_rect().size.x*0.80), 0)
	U.clear(overlay_box)
	var head := U.hb(10)
	head.add_child(U.lbl("🌳", "Emoji", 30))
	head.add_child(U.lbl("Family Tree", "Title"))
	head.add_child(U.spacer())
	head.add_child(U.btn("Family records", _show_family_records, "Row"))
	var close := U.btn("Close", _close_popup, "Row")
	close.name = "OkButton"
	head.add_child(close)
	overlay_box.add_child(head)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(480.0, maxf(180.0,get_viewport_rect().size.y*0.65-80)))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var tree := FamilyTreeView.new()
	tree.setup()
	sc.add_child(tree)
	overlay_box.add_child(sc)


func _show_family_records(query: String = "") -> void:
	FamilyChronicle.sync()
	var body := _big_popup(940,"📖","Family records","Recorded lives stay in this family book across generations. Older missing details are labelled as estimates.")
	var search := LineEdit.new()
	search.placeholder_text = "Find a person by name…"
	search.text = query
	search.name = "FamilySearch"
	body.add_child(search)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size.y = minf(440,maxf(180,get_viewport_rect().size.y-290))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var rows := U.vb(8)
	rows.name = "FamilyRecordRows"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(rows)
	body.add_child(sc)
	var fill := func(text: String):
		U.clear(rows)
		var records: Dictionary = FamilyChronicle.book()["people"]
		var shown := 0
		for uid in records.keys():
			var record: Dictionary = records[uid]
			if not text.strip_edges().is_empty() and not str(record["name"]).to_lower().contains(text.strip_edges().to_lower()): continue
			var key: String = uid
			var row := U.row("👤" if record["alive"] else "🕯️",record["name"],"Age %d · %s · %s" % [int(record["age"]),record["job"],"Living" if record["alive"] else "Remembered"],func(): _show_family_record(key))
			row.name = "Family_"+uid
			rows.add_child(row)
			shown += 1
		if shown==0: rows.add_child(U.lbl("No matching family record.","Dim",17))
	search.text_changed.connect(fill)
	fill.call(query)

func _show_family_record(uid: String) -> void:
	var records: Dictionary = FamilyChronicle.book()["people"]
	if not records.has(uid): return
	var r: Dictionary = records[uid]
	var body := _big_popup(900,"👤",r["name"],"Age %d · %s · Last recorded %d" % [int(r["age"]),"Living" if r["alive"] else "Remembered",int(r["year"])])
	body.add_child(U.btn("‹ Family records",_show_family_records,"Flat"))
	var salary_text := "Not recorded" if r["salary_source"]=="unrecorded" else GameState.fmt_money(int(r["salary"]))+(" · estimated legacy detail" if r["salary_source"]=="estimated" else "")
	var education_text := str(r["education"].get("stage","none")).capitalize()+(" · estimated legacy detail" if r["education"].get("source","")=="legacy scaffold" else "")
	var text := "Work: %s\nSalary: %s\nPersonal cash: %s\nEducation: %s\nHealth record: %s\nCriminal record: %s" % [r["job"],salary_text,GameState.fmt_money(int(r["money"])),education_text,str(r["illness"]) if str(r["illness"])!="" else "No current illness recorded",", ".join(Array(r["record"])) if not Array(r["record"]).is_empty() else "None recorded"]
	var qualifications: Array = []
	for degree in r["education"].get("degrees",[]):
		if degree is Dictionary: qualifications.append("%s · %s" % [str(degree.get("level","Qualification")).capitalize(),degree.get("name",str(degree.get("major","Subject not recorded")).capitalize())])
	if not qualifications.is_empty(): text += "\nQualifications: "+"; ".join(qualifications)
	var parent_names: Array = []
	for parent in r["parents"]:
		if records.has(parent): parent_names.append(records[parent]["name"])
	var sc := ScrollContainer.new()
	sc.custom_minimum_size.y = minf(460,maxf(160,get_viewport_rect().size.y-280))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var history := U.vb(8)
	history.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(history)
	body.add_child(sc)
	history.add_child(U.lbl(text,"",18,true))
	history.add_child(U.lbl("Recorded parents: "+", ".join(parent_names) if not parent_names.is_empty() else "Parent details are not recorded.","Dim",16,true))
	var lines: Array = r["history"].duplicate()
	lines.reverse()
	for memory in lines: history.add_child(U.lbl("%d · %s" % [int(memory["year"]),memory["text"]],"",16,true))
	if lines.is_empty(): history.add_child(U.lbl("The next important moments will be recorded here.","Dim",16,true))

func _show_year_summary() -> void:
	var body := _big_popup(920,"🗓️","This year in my life","Changes since ageing up, plus the latest entries in your life story.")
	var sc := ScrollContainer.new()
	sc.custom_minimum_size.y = minf(460,maxf(180,get_viewport_rect().size.y-240))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var rows := U.vb(12)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(rows)
	body.add_child(sc)
	var summary_age := int(GameState.player.get("age", 0))
	if not GameState.log_years.is_empty(): summary_age = int(GameState.log_years[-1].get("age", summary_age))
	var tracked: Array = []
	for entry in Insight.state().get("history", []):
		if int(entry.get("age", -1)) == summary_age and (not Array(entry.get("changes", [])).is_empty() or str(entry.get("reason", "")) != ""):
			tracked.append(entry)
	tracked.reverse()
	rows.add_child(U.section("Measured outcomes · age %d" % summary_age))
	if tracked.is_empty():
		rows.add_child(U.lbl("No tracked action changes were recorded for this age yet.", "Dim", 15, true))
	else:
		for entry in tracked.slice(0, 12):
			var changes: Array = Array(entry.get("changes", [])).slice(0, 3)
			var line := str(entry.get("title", "Activity"))
			if not changes.is_empty(): line += " · " + " · ".join(changes)
			elif str(entry.get("reason", "")) != "": line += " · " + str(entry["reason"])
			if Array(entry.get("changes", [])).size() > 3: line += " · +%d more" % (Array(entry["changes"]).size() - 3)
			rows.add_child(U.lbl(line, "Dim", 15, true))
		if tracked.size() > 12: rows.add_child(U.lbl("Showing the latest 12 tracked changes.", "Dim", 14, true))
	for heading in ["Overview","Money","People","Work & school","Health","Other moments"]:
		rows.add_child(U.section(heading))
		if heading=="Overview":
			for line in FamilyChronicle.summary().slice(0,3): rows.add_child(U.lbl(line,"",17,true))
		else:
			var key: String = {"Money":"money","People":"people","Work & school":"work","Health":"health","Other moments":"other"}[heading]
			var found := false
			if not GameState.log_years.is_empty():
				for line in Array(GameState.log_years[-1].get("lines",[])).slice(-40):
					var cats := _log_cats(str(line))
					if cats.has(key) or (key=="other" and cats.is_empty()):
						rows.add_child(U.lbl(str(line),"",16,true)); found=true
			if not found: rows.add_child(U.lbl("No recent entries in this section.","Dim",15,true))
	rows.add_child(U.section("Upcoming consequences"))
	for line in Insight.upcoming(): rows.add_child(U.lbl(line,"",16,true))
	if Insight.upcoming().is_empty(): rows.add_child(U.lbl("No scheduled follow-ups. Other events remain uncertain.","Dim",15,true))


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
	Fx.voice("v_sigh", 0.8)
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
	if entry.get("mode",{}).get("story_complete",false):
		var end_card := U.card("Banner")
		end_card.custom_minimum_size = Vector2(400,620)
		var end_v := U.vb(24)
		end_v.alignment = BoxContainer.ALIGNMENT_CENTER
		end_card.add_child(end_v)
		for words in [str(entry["mode"].get("icon","🎬")), "THE END", str(entry["name"]), "Selected story arc complete", "%d chapters read" % int(entry["age"])]:
			var label := U.lbl(words,"Bold",32,true)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			end_v.add_child(label)
		row.add_child(end_card)
	else:
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
		for t in [[stone.ornament, 34, false], ["THE END" if entry.get("mode",{}).get("story_complete",false) else "R.I.P.", 40, true], [entry["name"], 28, true], ["Selected story arc" if entry.get("mode",{}).get("story_complete",false) else "%d – %d" % [int(entry["born"]), int(entry["died"])], 22, false], ["", 6, false], ["Story complete" if entry.get("mode",{}).get("story_complete",false) else "Died of %s" % entry["cause"], 18, false], [("%d chapters" if entry.get("mode",{}).get("story_complete",false) else "Age %d") % int(entry["age"]), 18, false], ["", 6, false], ["%s %s" % [ribbon.get("icon", ""), ribbon.get("name", "")], 24, true], ["“%s”" % stone.epitaph, 17, false]]:
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
	var hdr := U.lbl("💀  Death / Legacy" if not (entry.has("mode") and entry["mode"].has("role")) else "📁  Case closed", "Title")
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(hdr)
	var halo := U.card("Halo")
	halo.custom_minimum_size = Vector2(150, 150)
	var hf := U.lbl(str(entry["mode"].get("icon", "🐾")) if entry.has("mode") else U.face(entry.get("gender", "male"), int(entry["age"]), int(entry.get("face", 0))), "Emoji", 90)
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
	if entry.has("mode"):
		var me: Dictionary = entry["mode"]
		card_lines = [["Age", str(entry["age"])], ["Born", str(entry["born"])], ["Ended", str(entry["died"])], ["Outcome" if me.has("role") else "Cause of Death", str(entry["cause"]).capitalize()]]
		if me.get("story_complete",false): card_lines = []
		card_lines.append_array(me.get("card", []))
	for line in card_lines:
		var hh := U.hb()
		hh.add_child(U.lbl(line[0] + ":", "Bold", 17))
		hh.add_child(U.lbl(line[1], "", 17))
		lv.add_child(hh)
	var ban := U.card("Banner")
	var bl := U.lbl("%s  %s" % [ribbon.get("icon", ""), ribbon.get("name", "")], "Title")
	bl.add_theme_color_override("font_color", ThemeManager.c("text"))
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ban.add_child(bl)
	lv.add_child(ban)
	var desc := U.lbl(ribbon.get("desc", ""), "Dim", 16, true)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(desc)
	if entry.has("seeded"):
		var sd: Dictionary = entry["seeded"]
		var sl := U.lbl("%s %s: %s — %s · score %d" % ["📅" if sd["kind"] == "daily" else "🗓️", "Daily" if sd["kind"] == "daily" else "Weekly", str(sd["goal"]), "goal met ✓" if sd["met"] else "goal missed", int(sd["score"])], "Bold", 16, true)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.add_theme_color_override("font_color", ThemeManager.c("gold"))
		lv.add_child(sl)
	var heirs: Array = GameState.heirs() if GameState.has_life() and not p.get("alive", true) else []
	var cont := U.btn("Continue as Child", _continue_as_child, "Accent")
	cont.custom_minimum_size = Vector2(0, 56)
	cont.disabled = heirs.is_empty()
	if heirs.is_empty():
		cont.text = "Continue as Child (no living children)"
	if entry.has("mode"):
		var me0: Dictionary = entry["mode"]
		cont.disabled = false
		cont.pressed.disconnect(_continue_as_child)
		if entry.has("pet"):
			cont.text = "🐾  Another life in the same house"
			cont.tooltip_text = "Born again, a different animal, to the house that remembers %s." % str(entry.get("name", "").get_slice(" ", 0))
			cont.pressed.connect(func(): _open_pet_setup(Pets.next_life_opts(entry)["inherit"]))
		else:
			cont.text = "⛓️  Another turn inside the system" if str(me0.get("role", "")) == "prisoner" else "🗝️  Another posting"
			cont.tooltip_text = "Prison Life again: a different person, the same kind of building."
			cont.pressed.connect(func(): _open_prison_setup())
	lv.add_child(cont)
	if GameState.has_life() and not p.get("alive", true) and bool(p.get("life", {}).get("can_rise", false)):
		var rb := U.btn("🧟  Rise from the Grave", _rise, "Accent")
		rb.custom_minimum_size = Vector2(0, 56)
		rb.tooltip_text = "Crawl out as a Revenant. Unfinished business awaits."
		lv.add_child(rb)
	if Items.owned("do_over") > 0 and Items.has_snapshot() and not entry.has("mode"):
		var dob2 := U.btn("🔄  Use a Do-Over  (you have %d)" % Items.owned("do_over"), func(): _use_star_item("do_over"), "Accent")
		dob2.name = "DoOverButton"
		dob2.custom_minimum_size = Vector2(0, 52)
		lv.add_child(dob2)
	var shb := U.btn("📸  Share this life", func(): _share_life(entry), "Row")
	shb.custom_minimum_size = Vector2(0, 46)
	shb.name = "ShareBtn"
	shb.tooltip_text = "Save a picture of this life and copy its summary to your clipboard"
	lv.add_child(shb)
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
	if SaveManager.graveyard.is_empty():
		v.add_child(U.lbl("Nobody rests here yet. Every life you finish gets a stone, drawn from the life it marks.", "Dim", 20, true))
		return
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var gv := GraveyardView.new()
	gv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var list := SaveManager.graveyard.duplicate()
	var sx := float(get_viewport_rect().size.x) - 80.0
	gv.setup(list, maxf(sx, 800.0))
	gv.opened.connect(func(e: Dictionary): _show_grave(e))
	sc.add_child(gv)
	v.add_child(sc)


func _show_grave(e: Dictionary) -> void:
	var r: Dictionary = e.get("ribbon", {})
	var is_case: bool = e.has("mode") and ((e["mode"] as Dictionary).has("role") or e["mode"].get("story_complete",false))
	var body := _big_popup(760, "🪦", str(e["name"]), "%d – %d  ·  Age %d  ·  Gen %d" % [int(e["born"]), int(e["died"]), int(e["age"]), int(e.get("generation", 1))])
	if e.get("modified", false):
		body.add_child(U.lbl("🧪 Modified life", "Dim", 14))
	body.add_child(U.lbl(("Outcome: %s" if is_case else "Died of %s") % e["cause"], "", 18, true))
	body.add_child(U.lbl("%s %s" % [r.get("icon", ""), r.get("name", "")], "Bold", 20))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 360)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(U.lbl(str(e.get("story", "")), "", 17, true))
	body.add_child(sc)


# ================================================================= TIER 2 PANELS

func _sync_life_theme() -> void:
	# modes have their own sound, independent of the look
	var want_snd := ""
	if GameState.has_life() and _current_screen() == "game" and Lives.separate():
		want_snd = "tv" if Lives.is_type("tv") else ("pets" if Pets.active() else ("guard" if Prison.is_guard() else "prison"))
	if GameState.has_life() and GameState.in_prison() and not Lives.separate() and _current_screen() == "game": want_snd = "prison"
	Fx.set_mode(want_snd)
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
	if GameState.in_prison() and not Lives.separate() and p.get("alive",false): target = "custody"
	var want := target != ""
	if want and ThemeManager.current != target:
		life_theme_on = true
		ThemeManager.call_deferred("apply", target)
	elif not want and life_theme_on:
		life_theme_on = false
		ThemeManager.call_deferred("apply", GameState.settings.get("theme", "ink"))


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
	_add(U.lbl("Choose one special career. Skills can carry into the next.", "Dim", 15, true))
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
			_add(U.row(d["icon"], d["name"], sub, _act(func(): Careers.join(cid)), why == "", false))


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
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(U.lbl(str(r["name"]), "Bold", 20))
		var bl := U.lbl(str(r["blurb"]), "Dim", 15, true)
		tv.add_child(bl)
		h.add_child(tv)
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
		_add(U.row("🏦","Payment support","Review plans and loan history",func(): MP.open("employment:loan_support"),true))
		_add(U.section("What you already owe"))
		for i in range(owing.size()):
			var d: Dictionary = owing[i]
			var l: Dictionary = Lending.LENDERS[str(d["lender"])]
			var idx := i
			var sub := "%s left · next payment %s · contract rate %d%%" % [
				GameState.fmt_money(int(d["left"])), GameState.fmt_money(Lending.scheduled_payment(d,GameState.year_now()+1)),
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
		_add(U.row("🎚️","Configure this loan","Exact whole amount, decimal percentage of the limit, and term; preview every cost",func(): _open_panel(func(): _panel_loan_config(oid)),true))
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
			var picked_side: String = side
			_add(U.amount_row("Stake on " + who + " · %.2f× payout" % odds, int(p["money"]), func(amount): _act(func(): Fights.bet(bid, picked_side, amount)).call(), 10))
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


func _panel_loan_config(lender: String) -> void:
	_panel_header("🎚️","Configure borrowing")
	var offer := Lending.offer(lender)
	if offer.is_empty() or not bool(offer["ok"]):
		_add(U.lbl("This offer is no longer available.","Dim",16,true))
		return
	_add(U.lbl("Choose an exact whole currency amount (minimum $500) or a percentage of the limit (for example 12.5%). The game uses flat interest: principal × annual rate × term, fixed at signing. The displayed total includes that interest.","Dim",15,true))
	var amount := SpinBox.new()
	amount.min_value=500
	amount.max_value=int(offer["cap"])
	amount.step=1
	amount.value=mini(5000,int(offer["cap"]))
	amount.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	amount.custom_minimum_size=Vector2(120,44)
	var fraction := SpinBox.new()
	fraction.min_value=0.1
	fraction.max_value=100
	fraction.step=0.1
	fraction.value=float(amount.value)/float(offer["cap"])*100
	fraction.suffix="% of limit"
	fraction.custom_minimum_size=Vector2(200,44)
	var term := SpinBox.new()
	term.min_value=1
	term.max_value=int(offer["term"])
	term.step=1
	term.value=int(offer["term"])
	term.suffix="years"
	term.custom_minimum_size=Vector2(200,44)
	for pair in [["Principal · limit "+GameState.fmt_money(int(offer["cap"])),amount],["Percentage of the available limit",fraction],["Repayment term",term]]:
		_add(U.lbl(str(pair[0]),"Bold",16,true))
		_add(pair[1])
	var preview := U.lbl("","Dim",16,true)
	_add(preview)
	var confirm := U.btn("Borrow this amount",_act(func():
		amount.apply()
		term.apply()
		Lending.borrow(lender,int(amount.value),int(term.value))),"Accent")
	_add(confirm)
	var refresh := func(_value=0):
		var q := Lending.quote(lender,int(amount.value),int(term.value))
		confirm.disabled=q.is_empty()
		preview.text="Amount is outside this lender's limits." if q.is_empty() else "Principal %s · interest %s · total %s · annual payment %s · rate %.1f%%" % [GameState.fmt_money(int(q["principal"])),GameState.fmt_money(int(q["interest"])),GameState.fmt_money(int(q["total"])),GameState.fmt_money(int(q["payment"])),float(q["rate"])*100]
	amount.value_changed.connect(func(value):
		fraction.set_value_no_signal(value/float(offer["cap"])*100)
		refresh.call())
	fraction.value_changed.connect(func(value):
		var exact := Lending.fraction_amount(lender,value)
		amount.set_value_no_signal(maxi(500,exact))
		fraction.set_value_no_signal(float(amount.value)/float(offer["cap"])*100)
		refresh.call())
	term.value_changed.connect(refresh)
	refresh.call()

func _panel_murder() -> void:
	_panel_header("🥷","Crime · murder")
	_add(U.lbl("A non-graphic fictional crime with lasting death, relationship and legal consequences. Select an adult, then confirm or walk away. No method is depicted and there is no reward.","Dim",15,true))
	for id in GameState.npcs:
		var npc: Dictionary = GameState.npcs[id]
		if not bool(npc.get("alive",false)) or int(npc.get("age",0))<18 or str(npc.get("species","human"))!="human": continue
		var target := str(id)
		_add(U.row(U.npc_icon(npc),GameState.full_name(target),GameState.relation_label(target),_act(func(): Depth.murder(target)),Depth.available("murder") and not GameState.in_prison(),false))

func _panel_lawsuit() -> void:
	_panel_header("⚖️", "Lawsuit")
	_add(U.lbl("Pick someone to sue. Choose grounds, representation and evidence. Play disclosure, cross-examination and closing arguments; a verdict changes money and relationships.", "Dim", 15, true))
	for claim in Depth.state()["claims"]:
		_add(U.lbl("Age %d · %s · %s · award %s" % [int(claim["age"]),Depth.CLAIMS[str(claim["reason"])][0],"upheld" if claim["won"] else "dismissed",GameState.fmt_money(int(claim["damages"]))],"Dim",14,true))
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"] or n.get("species", "human") != "human":
			continue
		var nid: String = id
		_add(U.row(U.npc_icon(n), "%s (%s)" % [GameState.full_name(id), GameState.relation_label(id)], "", _act(func(): Law.sue(nid)), true, false))


# ---- money

func _panel_investments() -> void:
	Finance.ensure_market()
	_panel_header("🏦", "Savings & Investments")
	var p := GameState.player
	var w := GameState.world
	var mood: String = {"crash": "📉 The market crashed last year", "boom": "📈 The market boomed last year", "steady": "Markets were steady last year"}[w.get("market_mood", "steady")]
	_add(_info_card([_kv("Cash", GameState.fmt_money(int(p["money"]))), _kv("Savings (2.5%/yr)", GameState.fmt_money(int(p["savings"]))), _kv("Portfolio", GameState.fmt_money(Finance.investments_value())), U.lbl(mood, "Dim", 15)]))
	_add(U.section("Savings account"))
	_add(U.amount_row("Deposit an amount", int(p["money"]), func(amount): _act(func(): Finance.deposit(amount)).call()))
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


func _asset_row(kind: String, sym: String) -> VBoxContainer:
	var d: Dictionary = (Finance.STOCKS if kind == "stock" else Finance.CRYPTO)[sym]
	var price := float(GameState.world["stocks" if kind == "stock" else "crypto"][sym])
	var ch := float(GameState.world["change"].get(sym, 0.0))
	var held := Finance.holding_value(kind, sym)
	var sub := "%s · %s%.0f%% last year" % [Finance.fmt_price(price), "+" if ch >= 0 else "", ch * 100]
	if held > 0:
		sub += " · you hold %s" % GameState.fmt_money(held)
	var k := kind
	var s := sym
	var box := U.vb(2)
	box.add_child(U.row(d["icon"], "%s (%s)" % [d["name"], sym], sub, func(): _open_panel(func(): _panel_trade(k, s))))
	var chart := preload("res://scenes/price_chart.gd").new()
	chart.setup(Finance.history(sym))
	box.add_child(chart)
	return box


func _panel_trade(kind: String, sym: String) -> void:
	Finance.ensure_market()
	var d: Dictionary = (Finance.STOCKS if kind == "stock" else Finance.CRYPTO)[sym]
	_panel_header(d["icon"], d["name"])
	var price := float(GameState.world["stocks" if kind == "stock" else "crypto"][sym])
	var held := Finance.holding_value(kind, sym)
	_add(_info_card([_kv("Price", Finance.fmt_price(price)), _kv("Your holding", GameState.fmt_money(held)), U.lbl(d.get("sector", "Cryptocurrency · very volatile"), "Dim", 15)]))
	var chart := preload("res://scenes/price_chart.gd").new()
	chart.setup(Finance.history(sym), 130.0)
	_add(chart)
	_add(U.lbl(str(GameState.world["market_news"].get(sym, "No results have been reported yet.")), "Dim", 14, true))
	_add(U.amount_row("Buy an amount · cash %s" % GameState.fmt_money(int(GameState.player["money"])), int(GameState.player["money"]), func(amount): _act(func(): Finance.buy(kind, sym, amount)).call()))
	for amt in [1000, 10000, 100000, 1000000]:
		var a: int = amt
		_add(U.row("🛒", "Buy %s worth" % GameState.fmt_money(a), "", _act(func(): Finance.buy(kind, sym, a)), int(GameState.player["money"]) >= a, false))
	_add(U.row("💵", "Sell all", GameState.fmt_money(held), _act(func(): Finance.sell_all(kind, sym)), held > 0, false))
	for fraction in [0.25, 0.5]:
		var part: float = fraction
		_add(U.row("💵", "Sell %d%%" % int(part * 100), GameState.fmt_money(int(held * part)), _act(func(): Finance.sell_fraction(kind, sym, part)), held > 0, false))


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
		_add(U.row(str(it.get("icon","🎁")), it["name"], "Worth %s (paid %s)%s · tap to sell" % [GameState.fmt_money(int(it["value"])), GameState.fmt_money(int(it.get("bought",0))), tag], _act(func(): Finance.sell_item(idx)), true, false))
		var story := str(it.get("story",it.get("note","")))
		if story != "":
			_add(U.lbl("      " + story, "Dim", 14, true))
	_add(U.row("🛍️", "Go shopping", "Jewelry, art, collectibles, vehicles", func(): _open_panel(_panel_shop)))


func _panel_shop() -> void:
	MP.show("shop:root")


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
	_panel_header("🧙", "Sandbox Mode")
	_add(U.lbl("Edit anyone. Using Sandbox Mode tags this life as Modified.", "Dim", 15, true))
	var p := GameState.player
	_add(U.row(U.face(p["gender"], int(p["age"]), int(p["face"])), "You", "Stats, money, traits", func(): _open_panel(func(): _panel_god_edit(""))))
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"]:
			continue
		var nid: String = id
		_add(U.row(U.npc_icon(n), "%s (%s)" % [GameState.full_name(id), GameState.relation_label(id)], "", func(): _open_panel(func(): _panel_god_edit(nid))))


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
	_add(U.row("💾", "Save recovery", "Checkpoints and backups", func(): MP.open("recovery:root")))
	_add(U.section("Preferences"))
	_add(U.row("🌙", "Stories", "Mature content options", func(): _open_panel(Callable(self, "_panel_settings_page").bind("stories"))))
	_add(U.row("🔊", "Sound", "Master, music and effects", func(): _open_panel(Callable(self, "_panel_settings_page").bind("sound"))))
	_add(U.row("🎮", "Gameplay", "Events, minigames and controls", func(): _open_panel(Callable(self, "_panel_settings_page").bind("gameplay"))))
	_add(U.row("🖥️", "Display", "Size, fullscreen and theme", func(): _open_panel(Callable(self, "_panel_settings_page").bind("display"))))
	_add(U.row("🐢", "Effects & comfort", "Motion, contrast and effects", func(): _open_panel(Callable(self, "_panel_settings_page").bind("comfort"))))


func _panel_settings_page(group: String) -> void:
	var titles := {"stories": ["🌙", "Stories"], "sound": ["🔊", "Sound"], "gameplay": ["🎮", "Gameplay"], "display": ["🖥️", "Display"], "comfort": ["🐢", "Effects & comfort"]}
	var spec: Array = titles.get(group, ["⚙️", "Settings"])
	_panel_header(str(spec[0]), str(spec[1]))
	for c in _settings_rows(func(): _render_top_panel(), group):
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


func _settings_rows(redraw: Callable, group: String = "") -> Array:
	var s := GameState.settings
	var out: Array = []
	if group in ["", "stories"]:
		out.append(U.section("Stories"))
		out.append(U.row("🌙", "Additional mature arcs: " + ("ON" if s.get("mature_arcs", true) else "OFF"), "Violence and adult relationship stories. Active stories still resolve.", func():
			GameState.settings["mature_arcs"] = not GameState.settings.get("mature_arcs", true)
			SaveManager.save_settings()
			redraw.call(), true, false))
	if group in ["", "sound"]:
		out.append(U.section("Sound"))
		for sl in [["volume", "🔊 Master", 70], ["music_vol", "🎵 Music", 45], ["sfx_vol", "💥 Effects", 80], ["ui_vol", "🖱️ Interface", 65]]:
			var key: String = sl[0]
			out.append(_god_slider_plain(sl[1], float(s.get(key, sl[2])), func(v):
				GameState.settings[key] = int(v)
				Fx.apply_volumes()
				SaveManager.save_settings()))
	if group in ["", "gameplay"]:
		out.append(U.section("Gameplay"))
		var usys: String = Units.system()
		var udef: Dictionary = Units.SYSTEMS[usys]
		out.append(U.row(udef["icon"], "Units: %s" % udef["name"], "%s · tap to change" % udef["desc"], func():
			var keys: Array = Units.SYSTEMS.keys()
			var idx: int = keys.find(Units.system())
			Units.set_system(str(keys[(idx + 1) % keys.size()]))
			redraw.call(), true, false))
		if GameState.has_life():
			var cur: Dictionary = GameState.currency()
			out.append(U.row("💱", "Currency: %s" % cur["code"], "%s · changes when you move abroad" % ContentDB.country(GameState.player["country"])["name"], func(): pass, false, false))
		var pace: String = str(s.get("mg_pace", "relaxed"))
		var pace_def: Dictionary = Minigame.PACE.get(pace, Minigame.PACE["relaxed"])
		out.append(U.row(pace_def["icon"], "Minigame pace: %s" % pace_def["name"], pace_def["desc"], func():
			var keys: Array = Minigame.PACE.keys()
			var idx: int = keys.find(str(GameState.settings.get("mg_pace", "relaxed")))
			GameState.settings["mg_pace"] = keys[(idx + 1) % keys.size()]
			SaveManager.save_settings()
			redraw.call(), true, false))
		var density: String = str(s.get("event_density", "normal"))
		out.append(U.row("🎲", "Event pace: " + density.capitalize(), "Calm, Normal or Busy", func():
			var order: Array = ["calm", "normal", "busy"]
			GameState.settings["event_density"] = order[(order.find(density) + 1) % 3]
			SaveManager.save_settings()
			redraw.call(), true, false))
		for opt in [["ask_activity_length", "🎚️", "Ask activity length", "OFF repeats the last duration", true], ["minigames", "🎮", "Career minigames", "OFF uses your skill to resolve them", true]]:
			var key: String = opt[0]
			var default_value: bool = opt[4]
			out.append(U.row(opt[1], "%s: %s" % [opt[2], "ON" if s.get(key, default_value) else "OFF"], opt[3], func():
				GameState.settings[key] = not GameState.settings.get(key, default_value)
				SaveManager.save_settings()
				redraw.call(), true, false))
		out.append(U.lbl("Tab/arrows · move   Enter/Space · select   Esc · back   Space · age up   1–6 · tabs", "Dim", 14, true))
	if group in ["", "display"]:
		out.append(U.section("Display"))
		var fullscreen: bool = s.get("fullscreen", false)
		out.append(U.row("🖥️", "Fullscreen: %s" % ("ON" if fullscreen else "OFF"), "Switch between windowed and fullscreen", func():
			GameState.settings["fullscreen"] = not GameState.settings.get("fullscreen", false)
			SaveManager.save_settings()
			_apply_display()
			redraw.call(), true, false))
		var scale := float(s.get("ui_scale", 1.0))
		out.append(U.row("🔎", "Interface size: %d%%" % int(round(scale * 100)), "Cycle 90 · 100 · 115 · 130 · 150 · 175%", func():
			var steps := [0.9, 1.0, 1.15, 1.3, 1.5, 1.75]
			var idx: int = steps.find(float(GameState.settings.get("ui_scale", 1.0)))
			GameState.settings["ui_scale"] = steps[(idx + 1) % steps.size()]
			SaveManager.save_settings()
			_apply_display()
			redraw.call(), true, false))
		out.append(U.row("🎨", "Theme: " + ThemeManager.LABELS[ThemeManager.current], "All palettes are dark", func(): _set_theme(ThemeManager.next_theme()), true, false))
	if group in ["", "comfort"]:
		out.append(U.section("Effects & comfort"))
		for opt in [["effects", "✨", "Visual effects", "Particles and floating numbers", true], ["voices", "🗣️", "Voice sounds", "Cheers and reactions", true], ["flashes", "⚡", "Screen flashes", "Brief flashes on major events", true], ["shake", "📳", "Screen shake", "Movement on major events", true], ["reduced_motion", "🐢", "Reduced motion", "Fewer animations", false], ["high_contrast", "🔳", "High contrast", "Brighter text and heavier outlines", false], ["life_theme", "🧛", "Life Path themes", "Change the look for special paths", true], ["celeb_theme", "⭐", "Celebrity theme", "Change the look at 88+ fame", true]]:
			var key: String = opt[0]
			var default_value: bool = opt[4]
			out.append(U.row(opt[1], "%s: %s" % [opt[2], "ON" if s.get(key, default_value) else "OFF"], opt[3], func():
				GameState.settings[key] = not GameState.settings.get(key, default_value)
				SaveManager.save_settings()
				if key == "life_theme" or key == "celeb_theme": _sync_life_theme()
				if key == "high_contrast": ThemeManager.set_contrast(GameState.settings.get("high_contrast", false))
				redraw.call(), true, false))
	return out


## The three-column game screen needs about 1630 logical pixels. A larger
## interface size shrinks the logical screen, so below that width the columns
## give up some of their minimum width instead of running off the edge.
func _set_column(i: int) -> void:
	g["col_idx"] = i
	_fit_layout()


func _fit_layout() -> void:
	if screens.has("title") and is_instance_valid(screens["title"]):
		var brand: Control = screens["title"].find_child("TitleBrand", true, false)
		if brand:
			brand.visible = get_viewport_rect().size.x >= 1400.0 and float(GameState.settings.get("ui_scale", 1.0)) < 1.4
			var compact: Control=screens["title"].find_child("CompactBrand",true,false)
			if compact: compact.visible=not brand.visible
	if not g.has("left_col") or not is_instance_valid(g["left_col"]):
		return
	var w := get_viewport().get_visible_rect().size.x
	var single := float(GameState.settings.get("ui_scale", 1.0)) >= 1.45 or w < 1000.0
	g["single_col"] = single
	if g.has("col_tabs") and is_instance_valid(g["col_tabs"]):
		(g["col_tabs"] as Control).visible = single
		var cols: Array = [g["left_col"], g.get("mid_col"), g["right_col"]]
		for ci in range(3):
			var cc: Control = cols[ci]
			if cc != null and is_instance_valid(cc):
				cc.visible = (not single) or int(g.get("col_idx", 1)) == ci
				if single:
					cc.custom_minimum_size.x = 0.0
					cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for ci2 in range(3):
			var tb := (g["col_tabs"] as Control).get_child(ci2) as Button
			if tb != null:
				tb.theme_type_variation = "Primary" if int(g.get("col_idx", 1)) == ci2 else "Row"
		if single:
			return
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
var ach_queue: Array = []
var ach_busy := false


## Achievements arrive one at a time. Each gets the stage to itself, with its own sound,
## a voice and a look that grows with the tier; the next one waits its turn.
func _toast_ach(a: Dictionary) -> void:
	ach_queue.append(a)
	if not ach_busy:
		_pump_ach()


func _pump_ach() -> void:
	if ach_queue.is_empty():
		ach_busy = false
		return
	ach_busy = true
	var a: Dictionary = ach_queue.pop_front()
	var tier: String = a.get("tier", "bronze")
	var col: Color = Goals.TIER_COLORS[tier]
	var stars: int = int(Goals.TIER_STARS[tier])
	var big := tier in ["gold", "platinum", "legendary", "diamond"]
	var hurry := 0.55 if ach_queue.size() >= 3 else 1.0
	var hold: float = {"bronze": 2.6, "silver": 3.2, "gold": 4.0, "platinum": 4.8, "legendary": 5.4, "diamond": 5.4}.get(tier, 3.0) * hurry
	_ach_card(a, tier, col, stars, big, hold)
	match tier:
		"bronze":
			Fx.play("ach_bronze")
			Fx.voice("v_yay", 0.7)
			Moments.fire("achievement", 0.55)
		"silver":
			Fx.play("ach_silver")
			Fx.voice("v_yay", 1.0)
			Moments.fire("achievement", 0.7)
		"gold":
			Fx.play("ach_gold")
			Fx.voice("v_woo", 1.0)
			Moments.fire("achievement", 1.0)
		_:
			Fx.play("ach_epic")
			Fx.voice("v_cheer", 1.0)
			Moments.fire("achievement", 1.0)
	if fx_layer != null and is_instance_valid(fx_layer):
		match tier:
			"silver": VFX.burst(fx_layer, "sparks", 10)
			"gold":
				VFX.burst(fx_layer, "sparks", 24)
			"platinum", "legendary", "diamond":
				VFX.burst(fx_layer, "sparks", 40)
				VFX.burst(fx_layer, "confetti", 30)
				VFX.shake(shake_root, 5.0, 0.35)
	var wait := get_tree().create_timer(hold + 0.55)
	wait.timeout.connect(_pump_ach)


func _ach_card(a: Dictionary, tier: String, col: Color, stars: int, big: bool, hold: float = 3.2) -> void:
	if fx_layer == null or not is_instance_valid(fx_layer):
		return
	var win := get_viewport_rect().size
	# light rays behind the card, for the tiers that earn them
	if tier in ["gold", "platinum", "legendary", "diamond"]:
		var rays := AchBurst.new()
		rays.size = win
		rays.setup(col, hold, 18 if tier != "gold" else 12)
		fx_layer.add_child(rays)
	var card := PanelContainer.new()
	card.theme_type_variation = "EventFrame"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := U.vb(8)
	card.add_child(v)
	var top := U.lbl("🏆  ACHIEVEMENT UNLOCKED", "Bold", 15)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_theme_color_override("font_color", col)
	v.add_child(top)
	var rule := ColorRect.new()
	rule.color = Color(col, 0.6)
	rule.custom_minimum_size = Vector2(0, 2)
	v.add_child(rule)
	var h := U.hb(16)
	var ic := U.lbl(str(a["icon"]), "Emoji", 72 if big else 58)
	h.add_child(ic)
	var tv := U.vb(3)
	var nm := U.lbl(str(a["name"]), "Title", 28 if big else 24)
	nm.custom_minimum_size = Vector2(360, 0)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(nm)
	if str(a.get("desc", "")) != "":
		var ds := U.lbl(str(a["desc"]), "Dim", 15, true)
		ds.custom_minimum_size = Vector2(360, 0)
		tv.add_child(ds)
	var tl := U.lbl("%s  ·  +%d ⭐" % [tier.capitalize(), stars], "Bold", 16)
	tl.add_theme_color_override("font_color", col)
	tv.add_child(tl)
	h.add_child(tv)
	v.add_child(h)
	card.custom_minimum_size = Vector2(600 if big else 520, 0)
	U._ignore_all(card)
	fx_layer.add_child(card)
	var w2: float = 300.0 if big else 260.0
	card.position = Vector2(win.x / 2.0 - w2, -160.0)
	card.pivot_offset = Vector2(w2, 70.0)
	card.scale = Vector2(0.7, 0.7)
	var rest := win.y * (0.26 if big else 0.12)
	var tw := card.create_tween().set_parallel(true)
	tw.tween_property(card, "position:y", rest, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# the icon pops in a beat later
	ic.pivot_offset = Vector2(36, 36)
	ic.scale = Vector2.ZERO
	var ti := ic.create_tween()
	ti.tween_interval(0.25)
	ti.tween_property(ic, "scale", Vector2(1.25, 1.25), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ti.tween_property(ic, "scale", Vector2.ONE, 0.14)
	var out := card.create_tween()
	out.tween_interval(hold)
	out.tween_property(card, "modulate:a", 0.0, 0.4)
	out.tween_callback(card.queue_free)
	if big:
		VFX.flash(fx_layer, col, 0.3, 0.8)


func _toast_mission(info: Dictionary) -> void:
	var period: String = info["period"]
	_toast("🎯", "%s mission complete · claim it in Missions" % Goals.PERIODS[period]["name"], Goals.text(info["m"], period), ThemeManager.c("good"))


func _big_popup(width: int, icon: String, title: String, sub: String = "") -> VBoxContainer:
	popup_open = true
	overlay.visible = true
	overlay_frame.custom_minimum_size = Vector2(minf(width,get_viewport_rect().size.x*0.80), 0)
	U.clear(overlay_box)
	var head := U.hb(10)
	var badge := U.card("EventIcon"); badge.add_child(U.lbl(icon,"Emoji",30)); head.add_child(badge)
	var tv := U.vb(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(U.lbl(title, "Title",0,true))
	if sub != "":
		tv.add_child(U.lbl(sub, "Dim", 15,true))
	head.add_child(tv)
	var close := U.btn("Close", _close_popup, "Row")
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.name = "OkButton"
	head.add_child(close)
	overlay_box.add_child(head)
	VFX.pop_in(overlay_frame)
	var sc := ScrollContainer.new(); sc.name="PopupScroll"; sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; sc.follow_focus=true
	sc.custom_minimum_size=Vector2(0,180); overlay_box.add_child(sc)
	var body := U.vb(12); body.name="PopupContent"; body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.minimum_size_changed.connect(func(): _fit_active_popup.call_deferred())
	sc.add_child(body); _fit_active_popup.call_deferred()
	if UIKit.kb_mode:
		_focus_overlay.call_deferred()
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
	var grid := HFlowContainer.new()
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", U.sp(10))
	grid.add_theme_constant_override("v_separation", U.sp(10))
	v.add_child(grid)
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
	var cols := HFlowContainer.new(); cols.add_theme_constant_override("h_separation",U.sp(14)); cols.add_theme_constant_override("v_separation",U.sp(14))
	v.add_child(cols)
	for period in ["daily", "weekly", "monthly"]:
		var pd: Dictionary = Goals.PERIODS[period]
		var b := Goals.board(period)
		var card := U.card("Inset")
		card.custom_minimum_size.x=320
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


var star_tab := "items"


func _show_star_shop() -> void:
	var g: Dictionary = Meta.meta["goals"]
	var v := _big_popup(1200, "⭐", "Star Shop", "You have ⭐ %d Stars. Earn more from achievements and missions." % Goals.stars())
	var tabs := U.hb(8)
	v.add_child(tabs)
	for t in [["items", "🧰", "Items"], ["avatar", "🪞", "Avatar"], ["boons", "✨", "Legacy Boons"], ["titles", "🎖️", "Titles"]]:
		var tk: String = t[0]
		var tb := U.btn("%s  %s" % [t[1], t[2]], func():
			star_tab = tk
			_show_star_shop(), "Primary" if star_tab == tk else "Row")
		tb.name = "StarTab_" + tk
		tabs.add_child(tb)
	var box := U.vb(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(box)
	match star_tab:
		"items": _star_items(box)
		"avatar": _star_avatar(box)
		"boons":
			box.add_child(U.lbl("Boons are yours forever once bought. Choose which ones to bring into each new life.", "Dim", 14, true))
			for bk in Grit.BOONS.keys():
				var bd: Dictionary = Grit.BOONS[bk]
				var own := Goals.owns_boon(bk)
				var bkey: String = bk
				box.add_child(U.row(bd["icon"], bd["name"], bd["desc"] + ("  ·  ✓ Owned" if own else "  ·  ⭐ %d" % int(bd["cost"])), func():
					Goals.buy_boon(bkey)
					_show_star_shop(), not own and Goals.stars() >= int(bd["cost"]), false))
		"titles":
			box.add_child(U.lbl("Titles are earned from achievements and shown under your name. Pick the one you want to wear.", "Dim", 14, true))
			box.add_child(U.row("🚫", "No title", "Hide your title", func():
				Goals.set_title("")
				_show_star_shop(), true, false))
			for a in Goals.achievements:
				if not a.has("title"):
					continue
				var tid: String = a["title"]
				var owned: bool = g["titles"].has(tid)
				var equipped: bool = g["title"] == tid
				var sub := "✓ Worn" if equipped else ("Earned · tap to wear" if owned else "🏆 Earn the \"%s\" achievement" % a["name"])
				box.add_child(U.row("🎖️", a.get("title_name", tid), sub, func():
					Goals.set_title(tid)
					_show_star_shop(), owned, false))
			for tk2 in Goals.TITLES.keys():
				if g["titles"].has(tk2):
					var tkk: String = tk2
					box.add_child(U.row("🎖️", Goals.TITLES[tk2]["name"], "✓ Worn" if g["title"] == tk2 else "Owned · tap to wear", func():
						Goals.set_title(tkk)
						_show_star_shop(), true, false))


func _star_items(box: VBoxContainer) -> void:
	var left := Items.seconds_left()
	box.add_child(U.lbl("The shelf turns over every half hour and is the same for everyone. New stock in %dm %02ds." % [left / 60, left % 60], "Dim", 14, true))
	var grid := HFlowContainer.new()
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", U.sp(12))
	grid.add_theme_constant_override("v_separation", U.sp(12))
	box.add_child(grid)
	for id in Items.stock():
		var d: Array = Items.CATALOG[id]
		var iid: String = id
		var card := U.card("Inset")
		card.custom_minimum_size = Vector2(360, 0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cv := U.vb(4)
		card.add_child(cv)
		var top := U.hb(10)
		top.add_child(U.lbl(str(d[1]), "Emoji", 40))
		var tv := U.vb(1)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(U.lbl(str(d[0]), "Bold", 18))
		tv.add_child(U.lbl("you own %d" % Items.owned(iid), "Dim", 13))
		top.add_child(tv)
		cv.add_child(top)
		cv.add_child(U.lbl(str(d[4]), "Dim", 14, true))
		var left_n := Items.left_in_stock(iid)
		var buy := U.btn("Buy  ⭐ %d   ·   %d left" % [int(d[2]), left_n] if left_n > 0 else "Sold out this rotation", func():
			if Items.buy(iid):
				Fx.play("coin")
			_show_star_shop(), "Primary" if left_n > 0 and Goals.stars() >= int(d[2]) else "Row")
		buy.disabled = left_n <= 0 or Goals.stars() < int(d[2])
		cv.add_child(buy)
		grid.add_child(card)
	box.add_child(U.section("Your items"))
	var any := false
	for id2 in Items.CATALOG.keys():
		if Items.owned(id2) <= 0:
			continue
		any = true
		var d2: Array = Items.CATALOG[id2]
		var uid: String = id2
		var why := Items.can_use(uid)
		box.add_child(U.row(str(d2[1]), "%s  ×%d" % [str(d2[0]), Items.owned(uid)], str(d2[4]) if why == "" else why, func():
			_use_star_item(uid), why == "", false))
	if not any:
		box.add_child(U.lbl("Nothing yet. Items you buy are kept across every life and every save.", "Dim", 14, true))


func _use_star_item(id: String) -> void:
	var r := Items.use(id)
	if r == "":
		return
	if r == "__redo":
		_close_popup()
		panel_stack.clear()
		panel_positions.clear()
		panel_names.clear()
		last_stats.clear()
		_show("game")
		_toast("🔄", "Do-Over", "The year is back at the start. Live it differently.", ThemeManager.c("good"))
		return
	Fx.play("good")
	_toast(str(Items.CATALOG[id][1]), str(Items.CATALOG[id][0]), r, ThemeManager.c("good"))
	_show_star_shop()


func _star_avatar(box: VBoxContainer) -> void:
	box.add_child(U.lbl("Optional looks and charms. Hair and skin tones are free in Appearance.", "Dim", 14, true))
	var cur := Avatar.current()
	var gender := str(GameState.player.get("gender", "male")) if GameState.has_life() else "male"
	var age := 28
	for cat in Avatar.CATEGORIES:
		var key: String = cat[0]
		var shown := false
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", U.sp(10))
		flow.add_theme_constant_override("v_separation", U.sp(10))
		for i in range(int(cat[2])):
			if Avatar.cost_of(key, i) == 0:
				continue
			if not shown:
				box.add_child(U.section(str(cat[1])))
				box.add_child(flow)
				shown = true
			var ii := i
			var card := U.card("Inset")
			card.custom_minimum_size = Vector2(150, 0)
			var cv := U.vb(3)
			card.add_child(cv)
			var look := cur.duplicate()
			look[key] = i
			var pv := AvatarView.new()
			pv.custom_minimum_size = Vector2(110, 110)
			pv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			pv.setup(look, age, gender)
			cv.add_child(pv)
			var nl2 := U.lbl(("%s %s" % [Avatar.glyph_of(key, i), Avatar.name_of(key, i)]).strip_edges(), "Bold", 13)
			nl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(nl2)
			var owned := Avatar.is_owned(key, i)
			var worn := int(cur.get(key, 0)) == i
			var b := U.btn("Worn" if worn else ("Wear" if owned else "Buy  ⭐ %d" % Avatar.cost_of(key, i)), func():
				if not Avatar.is_owned(key, ii):
					Avatar.buy(key, ii)
				else:
					var c2 := Avatar.current().duplicate()
					c2[key] = ii
					Avatar.set_current(c2)
				_show_star_shop(), "Primary" if not owned else "Row")
			b.disabled = worn or (not owned and Goals.stars() < Avatar.cost_of(key, i))
			cv.add_child(b)
			flow.add_child(card)


# ================================================================= MINIGAMES

func _build_mg_layer() -> void:
	mg_layer = Control.new()
	mg_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg_layer.visible = false
	mg_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(mg_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.42)
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
	mg_before = Insight.snapshot() if GameState.has_life() else {}
	mg_title = str(params.get("title",Minigames.DEFS[id]["name"]))
	var d: Dictionary = Minigames.DEFS[id]
	mg_open = true
	mg_playing = false
	mg_layer.visible = true
	U.clear(mg_box)
	mg_frame.custom_minimum_size = Vector2(minf(620,get_viewport_rect().size.x-48), 0)
	var head := U.hb(14)
	var badge := U.card("EventIcon"); badge.add_child(U.lbl(d["icon"], "Emoji", 40)); head.add_child(badge)
	var tv := U.vb(2)
	tv.size_flags_horizontal=Control.SIZE_EXPAND_FILL; tv.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	tv.add_child(U.lbl(mg_title, "Title",24,true))
	head.add_child(tv)
	mg_box.add_child(head)
	mg_box.add_child(U.lbl(d["how"], "", 18, true))
	mg_box.add_child(U.lbl("Pace: " + Minigame.PACE.get(str(GameState.settings.get("mg_pace", "relaxed")), Minigame.PACE["relaxed"])["name"] + " · change this in Settings", "Dim", 15, true))
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
	mg_help_visible = false
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
		if bool(Minigames.DEFS[id].get("gamble", false)):
			get_tree().create_timer(0.3).timeout.connect(func(): _mg_finish(cb, score, detail))
			return
		get_tree().create_timer(0.9).timeout.connect(func(): _mg_result(id, score, detail, cb))
	game.finished.connect(on_done)
	if game.has_signal("restarted"):
		game.connect("restarted", func(n: Minigame) -> void:
			mg_game = n
			n.finished.connect(on_done)
			_mg_fit())
	var give_up := func() -> void:
		if is_instance_valid(mg_game) and not mg_game.done:
			mg_game.finish(0.05, {"quit": true})
	var footer := U.hb(12)
	mg_box.add_child(footer)
	var activity_badge := U.card("EventIcon")
	activity_badge.add_child(U.lbl(Minigames.DEFS[id]["icon"],"Emoji",28)); footer.add_child(activity_badge)
	var help := U.card("Inset")
	help.visible = false
	help.custom_minimum_size = Vector2(0, 440)
	var instructions := U.vb(16)
	instructions.add_child(U.lbl("PAUSED · HOW TO PLAY", "Bold", 18))
	instructions.add_child(U.lbl(Minigames.DEFS[id]["how"], "", 20, true))
	instructions.add_child(U.lbl("Resume when you are ready. Your game waits here.", "Dim", 16, true))
	help.add_child(instructions)
	mg_box.add_child(help)
	var help_btn := U.btn("Pause / How to play", func():
		if not is_instance_valid(mg_game) or mg_game.done: return
		mg_help_visible = not mg_help_visible
		mg_game.process_mode = Node.PROCESS_MODE_DISABLED if mg_help_visible else Node.PROCESS_MODE_INHERIT
		mg_holder.visible = not mg_help_visible
		help.visible = mg_help_visible
		var toggle: Button = footer.find_child("MinigameHelp", true, false)
		toggle.text = "Resume game" if mg_help_visible else "Pause / How to play"
		if not mg_help_visible: mg_game.grab_focus()
	, "Row")
	help_btn.name = "MinigameHelp"
	footer.add_child(help_btn)
	footer.add_child(U.spacer())
	var quit := U.btn("Leave round" if bool(Minigames.DEFS[id].get("gamble", false)) else "End attempt", give_up, "Flat")
	quit.tooltip_text = "An unfinished wager is lost; settled session winnings are retained." if bool(Minigames.DEFS[id].get("gamble", false)) else "End this attempt with a low result."
	footer.add_child(quit)
	mg_default = null


## Fit the 1000x540 board into the window, uniformly, never above 1:1.
func _mg_fit() -> void:
	if mg_holder == null or not is_instance_valid(mg_holder) or mg_game == null or not is_instance_valid(mg_game):
		return
	var win := get_viewport_rect().size
	# Room left after the popup's own chrome: padding, the Give up button, and a
	# margin so the frame never runs off the edge of the screen.
	var enlarged := float(GameState.settings.get("ui_scale",1.0))>=1.4
	var avail := Vector2(minf(1000 if enlarged else 900,maxf(320,win.x*0.78-48)),maxf(240,win.y*(0.76 if enlarged else 0.65)-150))
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
	mg_frame.custom_minimum_size = Vector2(minf(520,get_viewport_rect().size.x-48), 0)
	_event_header(mg_box,Minigames.DEFS[id]["icon"],Minigames.grade(score))
	var st := Minigames.stars(score)
	var stars := U.lbl("★".repeat(st) + "☆".repeat(5 - st), "Bold", 32)
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
	if not mg_open: return
	var before := mg_before.duplicate(true)
	var title := mg_title
	mg_open = false
	mg_playing = false
	mg_default = null
	mg_layer.visible = false
	U.clear(mg_box)
	cb.call(score, detail)
	Insight.record(before,title,"Challenge result: %d%%. Recorded effects follow below." % int(score*100))
	if GameState.has_life(): SaveManager.save_game()
	_refresh_side()
	_render_top_panel()
	_pump()


# ================================================================= REACTIONS

## Presentation is now decided by what happened, not by reading the sentence.
## The vocabulary, the sounds and the particle choices all live in
## autoload/moments.gd so any system can fire the same beats.
func _react(title: String, text: String, changes: Dictionary, signals: Array = []) -> void:
	Moments.react(title, text, changes, signals)


func _open_tv_setup() -> void:
	var body := _big_popup(980, "📖", "Story Life · Story library", "Original worlds. Choose a story and shape its ending.")
	body.add_child(U.lbl("Every campaign has branching choices, different endings and a saved journal. Spoilers ahead.", "Dim", 16, true))
	var search := LineEdit.new()
	search.name = "StorySearch"
	search.placeholder_text = "Search characters or stories…"
	search.text = tv_search
	search.custom_minimum_size.y = 44
	body.add_child(search)
	var genres := HFlowContainer.new()
	genres.add_theme_constant_override("h_separation", 8)
	genres.add_theme_constant_override("v_separation", 8)
	body.add_child(genres)
	var buttons := ButtonGroup.new()
	for category in ["All stories", "Original", "Cartoon", "Adult Animation", "Anime", "Crime / Action"]:
		var genre := U.btn(category, func(): tv_category = category; _draw_tv_catalog(), "Toggle")
		genre.toggle_mode = true
		genre.button_group = buttons
		genre.button_pressed = tv_category == category
		genres.add_child(genre)
	tv_results = U.vb(12)
	tv_results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(tv_results)
	search.text_changed.connect(func(value: String): tv_search = value; _draw_tv_catalog())
	_draw_tv_catalog()


func _draw_tv_catalog() -> void:
	if not is_instance_valid(tv_results): return
	U.clear(tv_results)
	var count := 0
	for category in ["Original", "Cartoon", "Adult Animation", "Anime", "Crime / Action"]:
		if tv_category != "All stories" and category != tv_category: continue
		var profiles := TVLife.catalog.filter(func(p): return p["category"] == category and (tv_search.strip_edges().is_empty() or (str(p["name"]) + " " + str(p["show"]) + " " + str(p.get("reference_name", ""))).to_lower().contains(tv_search.strip_edges().to_lower())))
		if profiles.is_empty(): continue
		tv_results.add_child(U.lbl(category.to_upper(), "Dim", 14))
		for profile in profiles:
			var id := str(profile["id"])
			var story := U.row(profile["icon"], profile["name"], "%s · %d scenes%s" % [profile["show"], profile["chapters"].size()," · theme disabled" if not TVLife.available(id) else ""], func(): _start_tv(id),TVLife.available(id))
			story.name = "Story_" + id
			story.tooltip_text = str(profile["coverage"])
			tv_results.add_child(story)
			count += 1
	if count == 0:
		tv_results.add_child(U.lbl("No stories match. Try another name or choose All stories.", "Dim", 18, true))

func _start_tv(id: String) -> void:
	if not TVLife.available(id): return
	if not SaveManager.begin_new_life():
		_show_info("💾", "No free save slot", SaveManager.last_error, {})
		return
	popup_open = false
	overlay.visible = false
	EventEngine.pending.clear()
	GameState.new_life({"gender":"male", "country":"us", "life_path":"tv", "character":id})
	panel_stack.clear()
	last_stats.clear()
	SaveManager.save_game()
	_show("game")
