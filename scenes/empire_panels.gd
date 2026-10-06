extends RefCounted

## Right-hand panels for Business, Black Market, Cult, Zoo and Outdoors.
## `m` is the main screen; panels reuse its _add/_open_panel/_act helpers.

const U := preload("res://scenes/ui_kit.gd")

var m


func _init(main_node) -> void:
	m = main_node


func _money(v: int) -> String:
	return GameState.fmt_money(v)


func _person_sub(id: String) -> String:
	Web.ensure_job(id)
	var s := Web.job_title(id)
	var perk := Web.perk_text(id)
	if perk != "":
		s += " · " + perk
	return s


# ================================================================ business

func business() -> void:
	m._panel_header("📈", "Business")
	var p := GameState.player
	var b: Dictionary = p["business"]
	if b.is_empty():
		m._add(U.lbl("Start a company. Your past careers, degree and the people you know give you an edge in matching industries. Fame sells.", "Dim", 15, true))
		var keys: Array = Empires.INDUSTRIES.keys()
		keys.sort_custom(func(a, bb): return int(Empires.INDUSTRIES[a]["cost"]) < int(Empires.INDUSTRIES[bb]["cost"]))
		for k in keys:
			var ind: Dictionary = Empires.INDUSTRIES[k]
			var e := Empires.edge(k)
			var sub := "Startup cost %s" % _money(Empires._cost(ind["cost"]))
			if not e["why"].is_empty():
				sub += " · ⭐ Edge: " + ", ".join(e["why"])
			var kk: String = k
			m._add(U.row(ind["icon"], ind["name"], sub, m._act(func(): Empires.start_business(kk)), int(p["age"]) >= 18, false))
		return
	var ind2: Dictionary = Empires.INDUSTRIES[b["ind"]]
	var lines: Array = []
	lines.append(U.lbl("%s %s" % [ind2["icon"], b["name"]], "Heading", 22, true))
	var sub2 := "%s · founded %d" % [ind2["name"], int(b["founded"])]
	if b["public"]:
		sub2 += " · 🔔 %s at %s a share" % [b["symbol"], Finance.fmt_price(float(b["price"]))]
	lines.append(U.lbl(sub2, "Dim", 15, true))
	lines.append(m._stat_row("Quality", float(b["quality"])))
	lines.append(m._stat_row("Marketing", float(b["marketing"])))
	lines.append(m._kv("Revenue last year", _money(int(b["rev"]))))
	lines.append(m._kv("Profit last year", _money(int(b["profit"]))))
	lines.append(m._kv("Company value", _money(int(b["value"]))))
	lines.append(m._kv("You own", "%d%%" % int(float(b["stake"]) * 100)))
	lines.append(m._kv("Staff", "%d hired · %d people you know%s" % [int(b["staff"]), b["crew"].size(), " · followers working free" if b["labor"] else ""]))
	if int(b["debt"]) > 0:
		lines.append(m._kv("Loan", _money(int(b["debt"]))))
	if b["cooked"]:
		lines.append(U.lbl("📒 The books are cooked. Heat rises every year.", "Dim", 14, true))
	m._add(m._info_card(lines))
	m._add(U.row("🏪", "Company operations", "Products, supply, prices, staff and customer orders", func(): m.MP.open("journey:operations")))
	m._add(U.section("Run the company"))
	for a in Empires.biz_actions():
		var aid: String = a["id"]
		m._add(U.row(a["icon"], a["name"], a["sub"], m._act(func(): Empires.biz_action(aid)), true, false))
	m._add(U.section("Your team"))
	m._add(U.row("🤝", "Hire someone you know", "Friends and family work harder, but you might lose their other job's perks", func(): m._open_panel(func(): pick_person("biz"))))
	for id in b["crew"]:
		var n := GameState.npc(id)
		if n.is_empty():
			continue
		var cid: String = id
		m._add(U.row(U.npc_icon(n), "Fire %s" % GameState.full_name(id), GameState.relation_label(id), m._act(func(): Empires.fire_known(cid)), true, false))


## Lists people you know for hiring, cult invites or zookeeper jobs.
func pick_person(kind: String) -> void:
	var p := GameState.player
	var titles := {"biz": ["🤝", "Hire someone you know"], "cult": ["🛐", "Invite to the cult"], "zoo": ["🧑‍🌾", "Hire a zookeeper"]}
	m._panel_header(titles[kind][0], titles[kind][1])
	var exclude: Array = []
	match kind:
		"biz":
			if p["business"].is_empty():
				m._panel_back()
				return
			exclude = p["business"]["crew"]
		"cult":
			if p["cult"].is_empty():
				m._panel_back()
				return
			exclude = p["cult"]["inner"]
		"zoo":
			if p["zoo"].is_empty():
				m._panel_back()
				return
			exclude = p["zoo"]["crew"]
	var list := Empires.candidates(exclude)
	if list.is_empty():
		m._add(U.lbl("You don't know any adults who could do this right now.", "Dim", 16, true))
		return
	for id in list:
		var n := GameState.npc(id)
		var nid: String = id
		var cb: Callable
		match kind:
			"biz": cb = func(): Empires.hire_known(nid)
			"cult": cb = func(): Empires.invite_to_cult(nid)
			"zoo": cb = func(): Empires.zoo_action("hire_known", nid)
		var h := U.hb(8)
		h.add_child(U.lbl("Relationship", "Dim", 14))
		h.add_child(U.bar(n["closeness"], ThemeManager.bar_color("happiness", n["closeness"]), 8, 120))
		var wrapped := func():
			cb.call()
			m._panel_back()
		m._add(U.row(U.npc_icon(n), "%s (%s)" % [GameState.full_name(id), GameState.relation_label(id)], _person_sub(id), m._act(wrapped), true, false, h))


# ================================================================ black market

func black_market() -> void:
	m._panel_header("🕶️", "Black Market")
	var p := GameState.player
	var why := Empires.bm_access()
	if why != "":
		m._add(U.lbl("🔒 " + why, "Dim", 16, true))
		m._add(U.row("🤫", "Lay low", "Stay home and keep your head down", m._act(Empires.lay_low), true, false))
		return
	m._add(m._info_card([["Every deal could be an undercover cop. The hotter you are, the likelier it is.", "Dim", 15], m._stat_row("Heat", float(p.get("heat", 0)), "stress")]))
	var stolen: Array = []
	for i in range(p["possessions"].size()):
		if p["possessions"][i].get("stolen", false):
			stolen.append(i)
	if not stolen.is_empty():
		m._add(U.section("Fence stolen goods"))
		stolen.reverse()
		for i in stolen:
			var it: Dictionary = p["possessions"][i]
			var idx: int = i
			m._add(U.row(it["icon"], "Fence the %s" % it["name"].to_lower(), "Worth %s legit · a fence pays half" % _money(int(it["value"])), m._act(func(): Empires.bm_action("fence", idx)), true, false))
	m._add(U.section("Buy"))
	for g in Empires.bm_goods():
		var gg: Dictionary = g
		m._add(U.row(g["icon"], g["name"], "%s · worth %s, but hot" % [_money(int(g["price"])), _money(int(g["real"]))], m._act(func(): Empires.bm_action("buy_hot", gg)), true, false))
	m._add(U.row("⌚", "Knockoff luxury watch", "%s · looks real. Until someone checks." % _money(Empires._cost(400)), m._act(func(): Empires.bm_action("fake_watch")), true, false))
	m._add(U.row("🛂", "Forged passport", "%s · one escape from the country%s" % [_money(Empires._cost(15000)), " · ✓ you have one" if GameState.has_flag("forged_passport") else ""], m._act(func(): Empires.bm_action("passport")), not GameState.has_flag("forged_passport"), false))
	m._add(U.row("📜", "Forged diploma", "%s · qualifies you for jobs. HR might check." % _money(Empires._cost(8000)), m._act(func(): Empires.bm_action("diploma")), true, false))
	m._add(U.section("Exotic animals" + (" (delivered to your zoo)" if not p["zoo"].is_empty() else " (they become pets)")))
	for k in Empires.ZOO_ANIMALS.keys():
		var a: Dictionary = Empires.ZOO_ANIMALS[k]
		if not a.get("illegal", false):
			continue
		var kk: String = k
		m._add(U.row(a["icon"], a["name"].trim_suffix("s"), "%s · danger %s" % [_money(Empires._cost(int(a["price"]))), ["low", "some", "high"][clampi(int(float(a["danger"]) * 3), 0, 2)]], m._act(func(): Empires.bm_action("exotic", kk)), true, false))
	m._add(U.section("Hustle"))
	m._add(U.row("👜", "Sell counterfeit goods", "Quick cash · heat", m._act(func(): Empires.bm_action("counterfeit")), true, false))
	if GameState.has_flag("forged_passport"):
		m._add(U.row("✈️", "Flee the country", "Use your forged passport. All heat gone.", m._act(func(): Empires.bm_action("flee")), true, false))
	m._add(U.row("🤫", "Lay low", "Stay home and keep your head down", m._act(Empires.lay_low), true, false))


# ================================================================ cult

func cult() -> void:
	m._panel_header("🛐", "Cult")
	var p := GameState.player
	var c: Dictionary = p["cult"]
	if c.is_empty():
		var why := Empires.cult_can_start()
		m._add(U.lbl("Start your own movement. Fame brings fans, looks and smarts bring believers, property becomes a compound. Big cults draw big heat.", "Dim", 15, true))
		for k in Empires.DOCTRINES.keys():
			var d: Dictionary = Empires.DOCTRINES[k]
			var kk: String = k
			m._add(U.row(d["icon"], d["name"], d["blurb"] + (" · 🔒 " + why if why != "" else " · %s to found" % _money(Empires._cost(5000))), m._act(func(): Empires.start_cult(kk)), why == "", false))
		return
	var d2: Dictionary = Empires.DOCTRINES[c["doctrine"]]
	var lines: Array = [U.lbl("%s %s" % [d2["icon"], c["name"]], "Heading", 22, true), U.lbl(d2["blurb"], "Dim", 15, true)]
	lines.append(m._kv("Members", "%d (peak %d)" % [int(c["members"]), int(c.get("peak", c["members"]))]))
	lines.append(m._stat_row("Devotion", float(c["devotion"])))
	lines.append(m._stat_row("Heat", float(p["heat"]), "stress"))
	lines.append(m._kv("Compound", c["compound"] if c["compound"] != "" else "None"))
	var names: Array = []
	for id in c["inner"]:
		if GameState.npcs.has(id):
			names.append(GameState.npc(id)["first"])
	if not names.is_empty():
		lines.append(U.lbl("Inner circle: " + ", ".join(names), "Dim", 15, true))
	m._add(m._info_card(lines))
	m._add(U.section("Lead"))
	for a in Empires.cult_actions():
		var aid: String = a["id"]
		if aid == "c_compound":
			m._add(U.row(a["icon"], a["name"], a["sub"], func(): m._open_panel(compound_pick), not p["properties"].is_empty()))
		else:
			m._add(U.row(a["icon"], a["name"], a["sub"], m._act(func(): Empires.cult_action(aid)), true, false))
	m._add(U.row("🫂", "Invite someone you know", "Family and friends join the inner circle (or never forgive you)", func(): m._open_panel(func(): pick_person("cult"))))


func compound_pick() -> void:
	m._panel_header("🏕️", "Build a compound")
	var p := GameState.player
	for i in range(p["properties"].size()):
		var pr: Dictionary = p["properties"][i]
		var idx: int = i
		var sub := "Any tenant will be evicted"
		if pr["type"] == "Private island":
			sub = "Isolated · heat grows much slower"
		m._add(U.row(pr["icon"], pr["type"], sub, m._act(func(): Empires.cult_action("c_compound", idx); m._panel_back()), true, false))


# ================================================================ zoo

func zoo() -> void:
	m._panel_header("🦁", "Zoo")
	var p := GameState.player
	var z: Dictionary = p["zoo"]
	if z.is_empty():
		m._add(U.lbl("Buy land, fill enclosures, hire keepers. Visitors come for variety, star animals and your fame. Understaffed zoos lose animals, and dangerous ones escape.", "Dim", 15, true))
		m._add(U.row("🏞️", "Open a zoo", "%s for 10 acres · age 21+" % _money(Empires._cost(250000)), m._act(Empires.open_zoo), int(p["age"]) >= 21, false))
		return
	var lines: Array = [U.lbl("🦁 " + z["name"], "Heading", 22, true)]
	lines.append(m._kv("Land", "%d acres · space %d/%d" % [int(z["acres"]), Empires.zoo_care_load(), Empires.zoo_capacity()]))
	lines.append(m._stat_row("Rating", float(z["rating"])))
	lines.append(m._stat_row("Animal welfare", minf(100.0, Empires.zoo_welfare() * 100.0)))
	lines.append(m._kv("Keepers", "%d hired · %d people you know%s" % [int(z["keepers"]), z["crew"].size(), " · cult volunteers" if z.get("cult_keepers", false) else ""]))
	lines.append(m._kv("Visitors last year", str(int(z["visitors"]))))
	lines.append(m._kv("Profit last year", _money(int(z["profit"]))))
	if Web.contact(["vet"], 50) != "":
		lines.append(U.lbl("🩺 %s checks on your animals for free." % GameState.full_name(Web.contact(["vet"], 50)), "Dim", 14, true))
	m._add(m._info_card(lines))
	if not z["animals"].is_empty():
		m._add(U.section("Animals"))
		for k in z["animals"].keys():
			var a: Dictionary = Empires.ZOO_ANIMALS[k]
			var kk: String = k
			m._add(U.row(a["icon"], "%s ×%d" % [a["name"], int(z["animals"][k])], "Sell one" + (" · smuggled" if a.get("illegal", false) else ""), m._act(func(): Empires.zoo_action("sell", kk)), true, false))
	m._add(U.section("Manage"))
	m._add(U.row("🛒", "Buy animals", "From licensed breeders", func(): m._open_panel(zoo_shop)))
	m._add(U.row("🏞️", "Buy 5 more acres", _money(Empires._cost(120000)), m._act(func(): Empires.zoo_action("land")), true, false))
	m._add(U.row("🧑‍🌾", "Hire a zookeeper", "%s a year" % _money(Empires._cost(32000)), m._act(func(): Empires.zoo_action("keeper")), true, false))
	if int(z["keepers"]) > 0:
		m._add(U.row("📉", "Let a keeper go", "", m._act(func(): Empires.zoo_action("fire_keeper")), true, false))
	m._add(U.row("🤝", "Hire someone you know", "As a zookeeper", func(): m._open_panel(func(): pick_person("zoo"))))
	m._add(U.row("🎈", "Throw a zoo festival", "%s · rating and visitors" % _money(Empires._cost(15000)), m._act(func(): Empires.zoo_action("event")), true, false))
	m._add(U.row("🥕", "Spend a day with the animals", "Happiness", m._act(func(): Empires.zoo_action("visit")), true, false))
	var pets := GameState.npcs_with("pet")
	for pid in pets:
		var pn := GameState.npc(pid)
		var ppid: String = pid
		m._add(U.row("🐾", "Move %s to the petting zoo" % pn["first"], pn.get("species", "pet").capitalize(), m._act(func(): Empires.zoo_action("donate_pet", ppid)), true, false))
	m._add(U.row("🤝", "Sell the zoo", "Worth about %s" % _money(Empires.zoo_value()), m._act(func(): Empires.zoo_action("sell_zoo")), true, false))


func zoo_shop() -> void:
	m._panel_header("🛒", "Buy animals")
	m._add(U.lbl("Rarer animals are on the Black Market, if you know where to look.", "Dim", 15, true))
	for k in Empires.ZOO_ANIMALS.keys():
		var a: Dictionary = Empires.ZOO_ANIMALS[k]
		if a.get("illegal", false) or int(a["price"]) == 0:
			continue
		var kk: String = k
		m._add(U.row(a["icon"], a["name"].trim_suffix("s"), "%s · draws crowds %s · needs %d space%s" % [_money(Empires._cost(int(a["price"]))), "★".repeat(clampi(int(a["draw"]) / 5 + 1, 1, 5)), int(a["care"]), " · ⚠️ dangerous" if float(a["danger"]) >= 0.3 else ""], m._act(func(): Empires.zoo_action("buy", kk)), true, false))


# ================================================================ outdoors

func camping() -> void:
	m._panel_header("🏕️", "Camping")
	m._add(U.lbl("Who's coming? A trip together brings you closer.", "Dim", 15, true))
	m._add(U.row("🌲", "Go alone", "Peace and quiet", m._act(func(): Empires.outdoor("camp", null); m._panel_back()), true, false))
	for id in Empires.outdoor_companions():
		var n := GameState.npc(id)
		var nid: String = id
		m._add(U.row(U.npc_icon(n), "%s (%s)" % [GameState.full_name(id), GameState.relation_label(id)], "", m._act(func(): Empires.outdoor("camp", nid); m._panel_back()), true, false))


func journal() -> void:
	m._panel_header("📓", "Wildlife Journal")
	var j: Dictionary = Empires._journal()
	var prog := Empires.journal_progress()
	m._add(m._info_card([["%d of %d animals · %d of %d fish · %d trips · %d finds" % [prog[0], prog[1], prog[2], prog[3], int(j["trips"]), int(j["finds"])], "Bold", 16]]))
	m._add(U.section("Wildlife"))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", U.sp(8))
	flow.add_theme_constant_override("v_separation", U.sp(8))
	for w in Empires.WILDLIFE:
		var chip := U.card("Chip")
		var seen: bool = j["species"].has(w[1])
		chip.add_child(U.lbl(("%s %s ×%d" % [w[0], w[1], int(j["species"][w[1]])]) if seen else "❔ ???", "", 14))
		flow.add_child(chip)
	m._add(flow)
	m._add(U.section("Fish"))
	var flow2 := HFlowContainer.new()
	flow2.add_theme_constant_override("h_separation", U.sp(8))
	flow2.add_theme_constant_override("v_separation", U.sp(8))
	for f in Empires.FISH + Empires.SEA_FISH:
		var chip2 := U.card("Chip")
		var got: bool = j["fish"].has(f[1])
		chip2.add_child(U.lbl(("%s %s ×%d" % [f[0], f[1], int(j["fish"][f[1]])]) if got else "❔ ???", "", 14))
		flow2.add_child(chip2)
	m._add(flow2)


func museum() -> void:
	m._panel_header("🏛️", "Museum")
	var p := GameState.player
	var any := false
	m._add(U.lbl("Donate what you find outdoors, or a family heirloom. Five donations and they name a wing after you.", "Dim", 15, true))
	for i in range(p["possessions"].size() - 1, -1, -1):
		var it: Dictionary = p["possessions"][i]
		if not it.get("find", false) and not it.get("heirloom", false):
			continue
		any = true
		var idx: int = i
		m._add(U.row(it["icon"], "Donate the %s" % it["name"].to_lower(), "Worth %s · karma and fame" % _money(int(it["value"])), m._act(func(): Empires.outdoor("museum", idx)), true, false))
	if not any:
		m._add(U.lbl("You haven't found anything yet. Try hiking or cave diving.", "Dim", 16, true))
