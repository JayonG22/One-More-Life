extends RefCounted

## Renders data-driven menus from Bonds, Daily, Shop and Social in the right panel.

const U := preload("res://scenes/ui_kit.gd")

var m
const PAGE_ROWS := 48
const PAGE_INFO := 20
var pages: Dictionary={}


func _init(main_node) -> void:
	m = main_node


func _module(key: String):
	var pre := key.get_slice(":", 0)
	match pre:
		"bond": return Bonds
		"daily": return Daily
		"shop": return Shop
		"social": return Social
		"creator": return Creator
		"dealer": return Dealer
		"venue": return Ventures
		"home": return Household
		"bulk": return Bulk
		"exp": return Expansion
		"threads": return LifeThreads
		"amb": return Ambition
		"real": return Real
		"pet": return Pets
		"pr": return Prison
		"comp": return Companions
		"market": return Market
		"employment": return Employment
		"journey": return Journey
		"hold": return Holdings
		"child": return Childhood
		"balance": return Stewardship
		"recovery": return SaveManager
		"tv": return TVLife
		"lore": return Lore
	return null


func _rest(key: String) -> String:
	var i := key.find(":")
	return "" if i < 0 else key.substr(i + 1)


func open(key: String) -> void:
	if key.begins_with("bond:") and key.ends_with(":profile"):
		var who := key.split(":")[1]
		m._open_panel(func(): m._panel_person(who,true)); return
	m._open_panel(func(): show(key))


func show(key: String) -> void:
	var mod = _module(key)
	if mod == null:
		return
	var d: Dictionary = mod.menu(_rest(key))
	m._panel_header(str(d.get("icon", "")), str(d.get("title", "")))
	var count := maxi(int(ceil(d.get("rows",[]).size()/float(PAGE_ROWS))),int(ceil(d.get("info",[]).size()/float(PAGE_INFO))))
	var page := clampi(int(pages.get(key,0)),0,maxi(0,count-1)); pages[key]=page
	if count<=1: rows_into(d); return
	var visible := d.duplicate(false)
	visible["rows"]=Array(d.get("rows",[])).slice(page*PAGE_ROWS,(page+1)*PAGE_ROWS)
	visible["info"]=Array(d.get("info",[])).slice(page*PAGE_INFO,(page+1)*PAGE_INFO)
	m._add(U.lbl("Page %d of %d · all entries remain available" % [page+1,count],"Dim",14))
	rows_into(visible)
	if page>0: m._add(U.row("←","Previous page","Earlier entries",func(): turn_page(key,page-1),true,true))
	if page<count-1: m._add(U.row("→","Next page","More entries",func(): turn_page(key,page+1),true,true))

func turn_page(key: String, page: int) -> void:
	pages[key]=page
	m._open_panel(func(): show(key),true)


func rows_into(d: Dictionary) -> void:
	for spec in d.get("bars",[]):
		var value := clampf(float(spec.get("value",0)),0,100)
		m._add(U.track("",str(spec["name"]),value,100.0,ThemeManager.bar_color("happiness",value),"%d%%" % int(value)))
	var info: Array = d.get("info", [])
	if not info.is_empty():
		var lines: Array = []
		var details: Array=[]
		var summary := str(d.get("summary",preload("res://scenes/brief_copy.gd").summary(str(d.get("title","")))))
		for t in info:
			if str(t) != "":
				if str(t).length()>180 and not summary.is_empty(): details.append(str(t))
				else: lines.append([str(t), "Dim", 15])
		if not details.is_empty(): lines.push_front([summary,"Dim",15])
		if not lines.is_empty():
			m._add(m._info_card(lines))
		if not details.is_empty():
			var disclosure := U.vb(6); disclosure.visible=false
			for text in details: disclosure.add_child(U.lbl(str(text),"Dim",15,true))
			var toggle := U.btn("Details",func(): disclosure.visible=not disclosure.visible,"Flat")
			toggle.tooltip_text="Show or hide the full explanation"
			m._add(toggle); m._add(disclosure)
	if d.has("wager"):
		var spec: Dictionary = d["wager"]
		m._add(U.amount_row(str(spec.get("title","Your stake"))+" · cash %s" % GameState.fmt_money(int(GameState.player["money"])), int(GameState.player["money"]), func(amount): wager(spec, amount), int(spec.get("minimum",10))))
	for r in d.get("rows", []):
		m._add(row(r))


func wager(spec: Dictionary, amount: int) -> void:
	if spec.has("menu"):
		open(str(spec["menu"]) % amount)
		return
	var arg = spec["arg"].duplicate(true)
	if arg is Array: arg[int(spec["amount_index"])] = amount
	else: arg[str(spec["amount_key"])] = amount
	m._act(func(): run(str(spec["act"]), arg)).call()


func row(r: Dictionary) -> Button:
	var on: bool = r.get("on", true)
	if r.has("menu"):
		var mk: String = r["menu"]
		return U.row(str(r.get("icon", "")), str(r.get("name", "")), str(r.get("sub", "")), func(): open(mk), on, true)
	if r.has("act"):
		var ak: String = r["act"]
		var arg = r.get("arg", null)
		if ak.begins_with("bulk:"):
			var details := U.lbl(str(r.get("sub","")),"Dim",14,true)
			var button := U.row(str(r.get("icon","")),"BUNDLE · "+str(r.get("name","")),"",m._act(func(): run(ak,arg)),on,false,details)
			button.theme_type_variation="BulkRow"
			button.set_meta("interaction","bulk")
			button.tooltip_text=str(r.get("name",""))+". "+str(r.get("sub",""))
			return button
		var tracked_people: Array = []
		if ak.begins_with("bond:"):
			var parts := ak.split(":")
			if parts.size() >= 3: tracked_people.append(parts[1])
		return U.row(str(r.get("icon", "")), str(r.get("name", "")), str(r.get("sub", "")), m._act(func(): run(ak, arg), tracked_people), on, false)
	return U.row(str(r.get("icon", "")), str(r.get("name", "")), str(r.get("sub", "")), func(): pass, false, false)


func run(key: String, arg) -> void:
	var mod = _module(key)
	if mod != null:
		mod.act(_rest(key), arg)
