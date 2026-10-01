extends RefCounted

## Right-hand panels for Life Paths, the World and the Billionaire endgame.

const U := preload("res://scenes/ui_kit.gd")

var m


func _init(main_node) -> void:
	m = main_node


func life_panel() -> void:
	var k := Lives.kind()
	if k == "human":
		m._panel_header("🧑", "An ordinary life")
		var l := Lives.life()
		var txt := "Nothing supernatural about you. As far as you know."
		if l.has("destiny"):
			txt = {"vampire": "Someone has been watching you from the shadows for years. Around 18, they'll make you an offer.", "witch": "Strange things happen around you. The women in your family say your gift wakes at 13.", "super": "You're stronger and faster than you should be. Something is coming, probably around 13."}.get(str(l["destiny"]), txt)
		elif l.get("destiny_rise", false):
			txt = "Death won't hold you. When you die, you'll be able to rise again."
		elif l.get("cured", false):
			txt = "You were a vampire once. Now you age like everyone else, and the sun feels wonderful."
		elif l.get("exroyal", false):
			txt = "You were royalty once. The crown is gone, but people still bow out of habit."
		m._add(m._info_card([[txt, "", 17]]))
		return
	var td: Dictionary = Lives.TYPES[k]
	m._panel_header(td["icon"], Lives.title() if Lives.title() != "" else td["name"])
	var lines: Array = []
	for sl in Lives.status_lines():
		if str(sl[1]) == "":
			lines.append(U.lbl(sl[0], "Bold" if lines.is_empty() else "Dim", 18 if lines.is_empty() else 15, true))
		else:
			var key := "happiness"
			if sl[0] in ["Thirst", "Rot", "Exposure", "Suspicion"]:
				key = "stress"
			lines.append(m._stat_row(sl[0], float(sl[1]), key))
	m._add(m._info_card(lines))
	if Lives.is_type("royal"):
		var fam: Array = []
		var mon := Lives.monarch()
		if mon != "":
			fam.append("👑 %s %s" % [GameState.npc(mon).get("title", ""), GameState.npc(mon)["first"]])
		var line_list := Lives.royals()
		line_list.sort_custom(func(a, b): return int(GameState.npcs[a]["line"]) < int(GameState.npcs[b]["line"]))
		for id in line_list.slice(0, 5):
			fam.append("%s. %s %s" % [str(GameState.npcs[id]["line"]), GameState.npcs[id].get("title", ""), GameState.npcs[id]["first"]])
		if not fam.is_empty():
			m._add(U.section("Line of succession"))
			m._add(U.lbl("\n".join(fam), "", 15, true))
	if Arcs.has_arc():
		m._add(U.row("@signpost", "Your road", "Chapters, and how this life would end if it ended today", func(): m.MP.open("real:arc")))
	m._add(U.section("Actions"))
	for a in Lives.actions():
		var aid: String = a["id"]
		if a.get("pick", false):
			m._add(U.row(a["icon"], a["name"], a["sub"], func(): m._open_panel(func(): pick(aid, a["name"]))))
		else:
			var arg = a.get("arg", null)
			m._add(U.row(a["icon"], a["name"], a["sub"], m._act(func(): Lives.act(aid, arg)), true, false))


func pick(aid: String, title: String) -> void:
	m._panel_header("👥", title)
	var list := Lives.pick_targets(aid)
	if list.is_empty():
		m._add(U.lbl("There's nobody suitable right now.", "Dim", 16, true))
		return
	for id in list:
		var n := GameState.npc(id)
		var nid: String = id
		var h := U.hb(8)
		h.add_child(U.lbl("Relationship", "Dim", 14))
		h.add_child(U.bar(n["closeness"], ThemeManager.bar_color("happiness", n["closeness"]), 8, 120))
		var cb := func():
			Lives.act(aid, nid)
			m._panel_back()
		m._add(U.row(U.npc_face(n), "%s (%s)" % [GameState.full_name(id), GameState.relation_label(id)], "Age %d" % int(n["age"]), m._act(cb), true, false, h))


func world_panel() -> void:
	m._panel_header("🌍", "The World")
	var act := World.active_list()
	if act.is_empty():
		m._add(m._info_card([["A quiet year for the world. Enjoy it while it lasts.", "Dim", 16]]))
	else:
		m._add(U.section("Happening now"))
		for id in act:
			var e: Dictionary = World.EVENTS[id]
			var left := int(GameState.world["events"][id])
			m._add(U.row(e["icon"], e["name"], "%s · about %d more year%s" % [_effect_text(id), left, "" if left == 1 else "s"], func(): pass, true, false))
	m._add(U.section("Headlines"))
	var lines: Array = []
	for h in World.news():
		lines.append("%d · %s" % [int(h["year"]), h["text"]])
	m._add(U.lbl("\n".join(lines) if not lines.is_empty() else "No headlines yet.", "", 15, true))


func _effect_text(id: String) -> String:
	match id:
		"recession": return "Layoffs, pay cuts, more crime, weaker businesses, falling stocks"
		"boom": return "Rising stocks, better pay, stronger businesses, less crime"
		"war": return "The draft, prices up 10%, more crime, defense firms and military pay boom"
		"pandemic": return "Borders and nightlife shut, school goes online, health hits, clinics boom"
		"tech": return "Tech and science pay +18%, other jobs get automated"
		"housing": return "Property values climb 12% a year, until it bursts"
		"crypto": return "Crypto prices soar, until the crash"
		"climate": return "Floods and fires"
		"space": return "Aerospace booms, astronauts are celebrities"
		"medicine": return "People live longer"
		"election": return "Politics everywhere"
		"sports": return "Athletes and gyms get a boost"
	return ""


func billionaire_panel() -> void:
	m._panel_header("💎", "Billionaire")
	if not World.billionaire_open():
		m._add(U.lbl("Reach a net worth of $1,000,000,000 to open the endgame.", "Dim", 16, true))
		return
	var b: Dictionary = GameState.player.get("billionaire", {})
	var lines: Array = [U.lbl("Net worth %s" % GameState.fmt_money(GameState.net_worth()), "Heading", 22, true)]
	if b.has("team"):
		lines.append(m._kv("%s %s" % [b["team"]["icon"], b["team"]["name"]], "%d championships" % int(b["team"].get("titles", 0))))
	if int(b.get("foundation", 0)) > 0:
		lines.append(m._kv("🎗️ Foundation", GameState.fmt_money(int(b["foundation"]))))
	if int(b.get("offshore", 0)) > 0:
		lines.append(m._kv("🏝️ Offshore", GameState.fmt_money(int(b["offshore"]))))
	if b.get("media", false):
		lines.append(U.lbl("📰 You own the press", "Dim", 15))
	if b.get("pledge", false):
		lines.append(U.lbl("🤲 Giving Pledge signed", "Dim", 15))
	for pj in b.get("projects", []):
		lines.append(U.lbl("🏙️ Built " + str(pj), "Dim", 15, true))
	m._add(m._info_card(lines))
	var b2: Dictionary = GameState.player.get("billionaire", {})
	if b2.has("team"):
		var t: Dictionary = b2["team"]
		m._add(U.section("%s %s" % [t["icon"], t["name"]]))
		m._add(m._info_card([m._kv("Last season", str(t.get("last", "not played yet"))), m._kv("Payroll", World.PAYROLL[int(t.get("payroll", 1))]), m._kv("Coaching", "%d / 3" % int(t.get("coach", 0))), m._kv("Fans", "%d%%" % int(t.get("fans", 50))), m._kv("Value", GameState.fmt_money(int(t["value"])))]))
	if b2.has("nation"):
		var n: Dictionary = b2["nation"]
		var laws: Array = n.get("laws", {}).keys().map(func(k): return World.NATION_LAWS[k][1])
		m._add(U.section("🏳️ " + str(n["name"])))
		m._add(m._info_card([m._stat_row("Legitimacy", float(n["legitimacy"])), U.lbl("Laws: " + (", ".join(laws) if not laws.is_empty() else "none yet"), "Dim", 15, true), U.lbl("🇺🇳 Recognized by the UN" if n.get("recognized", false) else "At 60 legitimacy the UN recognizes you. At 5, a neighbor may simply take the island.", "Dim", 14, true)]))
	m._add(U.section("Actions"))
	for a in World.billionaire_actions():
		var aid: String = a["id"]
		var arg = a.get("arg", null)
		m._add(U.row(a["icon"], a["name"], a["sub"], m._act(func(): World.billionaire_action(aid, arg)), true, false))


func places_panel() -> void:
	var p := GameState.player
	var r := Places.region()
	var c := ContentDB.country(p["country"])
	m._panel_header("🏙️", "Where You Live")
	var head: Array = [U.lbl("%s  %s" % [c.get("flag", ""), Places.place_name()], "Heading", 22, true)]
	if str(r.get("blurb", "")) != "":
		head.append(U.lbl(str(r["blurb"]), "Dim", 15, true))
	m._add(m._info_card(head))
	m._add(U.section("Local life and law"))
	var lines: Array = []
	for row in Places.summary().slice(1):
		lines.append(m._kv("%s  %s" % [row[0], row[1]], str(row[2])))
	m._add(m._info_card(lines))
	var others: Array = Places.regions(p["country"]).filter(func(x): return x["id"] != r.get("id", ""))
	if others.is_empty():
		return
	m._add(U.section("Move somewhere else in %s" % c["name"]))
	var fee := Actions._cost(3000)
	for o in others:
		var rid: String = o["id"]
		var sub := "Cost %s · wages %s · %s" % [Places._rel(float(o.get("cost", 1.0))).to_lower(), Places._rel(float(o.get("pay", 1.0))).to_lower(), str(o.get("blurb", ""))]
		var ok := int(p["age"]) >= 18 and not GameState.in_prison() and int(p["money"]) >= fee
		m._add(U.row("🚚", "%s, %s" % [o["city"], o["name"]] if o["name"] != o["city"] else o["city"], sub, m._act(func(): Places.relocate(rid)), ok, false))
	m._add(U.lbl("Moving costs about %s, sells your house, and may cost you your job and some friendships." % GameState.fmt_money(fee), "Dim", 14, true))
