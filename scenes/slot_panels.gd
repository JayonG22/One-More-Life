extends RefCounted

## Save-slot browser (Your Lives) and the Daily Heirloom popup with its collection.

const U := preload("res://scenes/ui_kit.gd")

var m
var confirm_delete := -1
var renaming := -1


func _init(main_node) -> void:
	m = main_node


static func ago(ts: float) -> String:
	var s := int(Time.get_unix_time_from_system() - ts)
	if s < 90:
		return "just now"
	if s < 3600:
		return "%d min ago" % (s / 60)
	if s < 86400:
		return "%d h ago" % (s / 3600)
	var d := s / 86400
	return "yesterday" if d == 1 else "%d days ago" % d


# ================================================================ YOUR LIVES

func show_lives() -> void:
	var cs: Array = SaveManager.cards()
	var v: VBoxContainer = m._big_popup(1560, "📂", "Your Lives", "%d of %d slots used  ·  favorites first  ·  saves back up automatically" % [cs.size(), SaveManager.SLOTS])
	if cs.is_empty():
		v.add_child(U.lbl("No saved lives yet. Start one from New Life.", "Dim", 18, true))
		return
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 700)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", U.sp(14))
	grid.add_theme_constant_override("v_separation", U.sp(14))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(grid)
	var i := 0
	for c in cs:
		var tile := _life_card(c)
		grid.add_child(tile)
		VFX.fade_in(tile, 0.04 * i)
		i += 1


func _life_card(c: Dictionary) -> Control:
	var slot := int(c["slot"])
	var alive: bool = c.get("alive", true)
	var card := U.card("Inset")
	card.custom_minimum_size = Vector2(496, 0)
	var cv := U.vb(8)
	card.add_child(cv)
	var top := U.hb(14)
	cv.add_child(top)
	var port := U.card("Portrait")
	port.custom_minimum_size = Vector2(104, 104)
	var face := U.lbl(U.face(str(c.get("gender", "male")), int(c.get("age", 0)), int(c.get("face", 0))) if alive else "🪦", "Emoji", 60)
	face.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	port.add_child(face)
	top.add_child(port)
	var info := U.vb(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	var label: String = c.get("label", "")
	if renaming == slot:
		var le := LineEdit.new()
		le.text = label if label != "" else str(c.get("name", ""))
		le.max_length = 40
		le.select_all_on_focus = true
		le.text_submitted.connect(func(t):
			SaveManager.set_label(slot, t)
			renaming = -1
			show_lives())
		info.add_child(le)
		le.call_deferred("grab_focus")
	else:
		var nm := U.lbl(("⭐ " if c.get("fav", false) else "") + (label if label != "" else str(c.get("name", "?"))), "Heading", 22)
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info.add_child(nm)
		if label != "":
			info.add_child(U.lbl(str(c.get("name", "")), "Dim", 14))
	var lt: String = c.get("life", "human")
	var ltd: Dictionary = Lives.TYPES.get(lt, Lives.TYPES["human"])
	var status := ("Age %d" % int(c.get("age", 0))) if alive else "Died at %d · %s" % [int(c.get("age", 0)), str(c.get("cause", ""))]
	info.add_child(U.lbl(status + ("   " + ltd["icon"] + " " + ltd["name"] if lt != "human" else ""), "Bold", 16))
	var place := "%s %s" % [c.get("flag", ""), c.get("country", "")]
	if str(c.get("city", "")) != "":
		place += " · " + str(c["city"])
	info.add_child(U.lbl(place, "Dim", 15))
	if str(c.get("occupation", "")) != "":
		info.add_child(U.lbl("💼 " + str(c["occupation"]), "", 15))
	var stats := U.hb(14)
	cv.add_child(stats)
	var nw := U.lbl("📊 " + GameState.fmt_money(int(c.get("net_worth", 0))), "Money", 17)
	stats.add_child(nw)
	stats.add_child(U.lbl("🧬 Gen %d" % int(c.get("generation", 1)), "", 15))
	var dd: Dictionary = Grit.DIFFICULTY.get(str(c.get("difficulty", "real")), {})
	if not dd.is_empty():
		stats.add_child(U.lbl("%s %s" % [dd.get("icon", ""), dd.get("name", "")], "", 15))
	if str(c.get("badge", "")) != "":
		stats.add_child(U.lbl(str(c["badge"]), "Emoji", 18))
	cv.add_child(U.lbl(str(c.get("summary", "")), "Dim", 14, true))
	cv.add_child(U.lbl("🕘 Last played " + ago(float(c.get("updated", 0))) + ("   ·   🩹 restored from backup" if c.get("recovered", false) else ""), "Dim", 13))
	var btns := U.hb(6)
	cv.add_child(btns)
	var load := U.btn("▶  Play" if alive else "📜  View", func(): _load(slot), "Accent" if alive else "Row")
	load.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load.custom_minimum_size = Vector2(0, 46)
	btns.add_child(load)
	btns.add_child(_small("⭐" if not c.get("fav", false) else "☆", "Favorite", func():
		SaveManager.toggle_fav(slot)
		show_lives()))
	btns.add_child(_small("✏️", "Rename", func():
		renaming = slot
		show_lives()))
	btns.add_child(_small("⧉", "Duplicate", func():
		if SaveManager.duplicate_slot(slot) < 0:
			m._toast("💾", "No free slot", SaveManager.last_error, ThemeManager.c("warn"))
		show_lives()))
	var del := _small("🗑️" if confirm_delete != slot else "Sure?", "Delete", func():
		if confirm_delete == slot:
			SaveManager.delete_slot(slot)
			confirm_delete = -1
		else:
			confirm_delete = slot
		show_lives())
	if confirm_delete == slot:
		del.add_theme_color_override("font_color", ThemeManager.c("bad"))
	btns.add_child(del)
	return card


func _small(icon: String, tip: String, cb: Callable) -> Button:
	var b := U.btn(icon, cb, "Row")
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(52, 46)
	return b


func _load(slot: int) -> void:
	confirm_delete = -1
	if not SaveManager.load_slot(slot):
		m._toast("⚠️", "Couldn't load", SaveManager.last_error, ThemeManager.c("bad"))
		return
	var note := SaveManager.last_error
	m._close_popup()
	m.panel_stack.clear()
	m.last_money = int(GameState.player.get("money", 0))
	m.last_stats.clear()
	if GameState.player.get("alive", true):
		m._show("game")
	else:
		m._show("death")
		m._fill_death(GameState.player.get("legacy", {}))
	if note != "":
		m._toast("🩹", "Save restored", note, ThemeManager.c("warn"))


# ================================================================ HEIRLOOMS

func show_heirloom(reveal: Dictionary = {}) -> void:
	var col: Dictionary = Goals.heirloom_collection()
	var total := 0
	for t in Goals.HEIR_TIERS:
		total += (t[4] as Array).size()
	var v: VBoxContainer = m._big_popup(1300, "🎁", "Daily Heirloom", "%d of %d heirlooms discovered  ·  one a day, no streaks to lose" % [col.size(), total])
	var top := U.hb(20)
	v.add_child(top)
	var box := U.card("Inset")
	box.custom_minimum_size = Vector2(420, 330)
	top.add_child(box)
	var bv := U.vb(10)
	bv.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(bv)
	if not reveal.is_empty():
		var tier: Array = reveal["tier"]
		var it: Dictionary = reveal["item"]
		var tl := U.lbl(str(tier[1]).to_upper(), "Bold", 20)
		tl.add_theme_color_override("font_color", tier[3])
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(tl)
		var ic := U.lbl(it["icon"], "Emoji", 96)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(ic)
		VFX.pop_in(ic, 0.3, 0.5)
		var nl := U.lbl(it["name"], "Heading", 24, true)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(nl)
		var vl := U.lbl("Worth about " + GameState.fmt_money(int(it["value"])), "Money", 18)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(vl)
		var where := "Added to your possessions. Keep it, sell it, or leave it to your heirs." if reveal["delivered"] else "Held in trust. A family lawyer will deliver it to your next life at 16."
		if int(reveal["count"]) > 1:
			where = "Copy #%d: a finer example than the last. " % int(reveal["count"]) + where
		var wl := U.lbl(where, "Dim", 15, true)
		wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(wl)
	elif Goals.daily_available():
		var ic := U.lbl("🎁", "Emoji", 110)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(ic)
		VFX.pulse(ic, true)
		var ob := U.btn("Open today's heirloom", _open, "Accent", "choice")
		ob.custom_minimum_size = Vector2(0, 60)
		ob.name = "OkButton"
		bv.add_child(ob)
		var hint := U.lbl("A relative you never met left something behind.", "Dim", 15, true)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(hint)
	else:
		var ic := U.lbl("📦", "Emoji", 90)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic.modulate = Color(1, 1, 1, 0.5)
		bv.add_child(ic)
		var tl := U.lbl("Opened today", "Heading", 22)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(tl)
		var nx := U.lbl("Next heirloom in " + Goals.fmt_left(Goals.seconds_left("daily")), "Dim", 16)
		nx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(nx)
	var odds := U.vb(8)
	odds.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(odds)
	odds.add_child(U.section("Rarity"))
	for t in Goals.HEIR_TIERS:
		var h := U.hb(10)
		var dot := U.lbl("●", "Bold", 20)
		dot.add_theme_color_override("font_color", t[3])
		h.add_child(dot)
		var found := 0
		for it in t[4]:
			if col.has(it[1]):
				found += 1
		h.add_child(U.lbl(str(t[1]), "Bold", 17))
		h.add_child(U.spacer())
		h.add_child(U.lbl("%d%%  ·  %d/%d found" % [int(t[2]), found, (t[4] as Array).size()], "Dim", 15))
		odds.add_child(h)
	odds.add_child(U.lbl("Duplicates aren't wasted: each copy of an heirloom comes in better condition (Polished, Restored, Pristine, Museum-grade) and is worth more. Your collection carries across every life.", "Dim", 14, true))
	var pend: Array = Meta.meta["goals"].get("heir_stash", [])
	if not pend.is_empty():
		odds.add_child(U.lbl("📜 %d heirloom%s held in trust for your next life." % [pend.size(), "" if pend.size() == 1 else "s"], "", 15, true))
	v.add_child(U.section("Collection"))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 300)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", U.sp(10))
	grid.add_theme_constant_override("v_separation", U.sp(10))
	sc.add_child(grid)
	for t in Goals.HEIR_TIERS:
		for it in t[4]:
			var have: Dictionary = col.get(it[1], {})
			var tile := U.card("Inset")
			tile.custom_minimum_size = Vector2(166, 124)
			var tv := U.vb(2)
			tv.alignment = BoxContainer.ALIGNMENT_CENTER
			tile.add_child(tv)
			var ic := U.lbl(it[0] if not have.is_empty() else "❔", "Emoji", 40)
			ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if have.is_empty():
				ic.modulate = Color(1, 1, 1, 0.35)
			tv.add_child(ic)
			var nl := U.lbl(it[1] if not have.is_empty() else "???", "", 13, true)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tv.add_child(nl)
			var cl := U.lbl(("×%d" % int(have["count"])) if not have.is_empty() else str(t[1]), "Bold", 13)
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cl.add_theme_color_override("font_color", t[3])
			tv.add_child(cl)
			grid.add_child(tile)


func _open() -> void:
	var r: Dictionary = Goals.claim_daily()
	if r.is_empty():
		show_heirloom()
		return
	var tier: String = r["tier"][0]
	match tier:
		"legendary":
			Fx.play("legendary")
			VFX.flash(m.fx_layer, r["tier"][3], 0.4, 0.8)
			VFX.burst(m.fx_layer, "sparks", 40)
			VFX.shake(m.shake_root, 6.0, 0.4)
		"epic":
			Fx.play("fanfare")
			VFX.flash(m.fx_layer, r["tier"][3], 0.25, 0.6)
			VFX.burst(m.fx_layer, "sparks", 26)
		"rare":
			Fx.play("achieve")
			VFX.burst(m.fx_layer, "sparks", 16)
		_:
			Fx.play("heirloom")
	show_heirloom(r)
	if GameState.has_life():
		m._refresh_side()
