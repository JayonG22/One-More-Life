extends RefCounted

const U := preload("res://scenes/ui_kit.gd")
var m
var query := ""
var only_favourites := false
var results: VBoxContainer
var count: Label
var filter_buttons := {}

func _init(main_node) -> void:
	m = main_node

func catalog() -> Array:
	var entries: Array = []
	var specs: Array = m._tab_specs()
	for i in range(specs.size()):
		var index := i
		entries.append({"id":"tab:"+str(i),"name":specs[i][1],"icon":specs[i][0],"path":"Main tabs","sub":"Open this section","on":true,"open":func(): m._tab_press(index)})
	if not Lives.separate() and not Lives.is_type("tv"):
		for group in Actions.ACTIVITY_GROUPS:
			var gid := str(group["id"])
			for item in group["items"]:
				var available := Actions.activity_available(item) and not GameState.in_prison()
				var reason := "Available · open the category to choose" if available else ("Unavailable while in custody" if GameState.in_prison() else (Expansion.era_activity_block(str(item["id"])) if int(GameState.player["age"])>=int(item["min"]) else "Age %d+" % int(item["min"])))
				entries.append({"id":"activity:"+str(item["id"]),"name":item["name"],"icon":item["icon"],"path":"Activities › "+str(group["name"]),"sub":str(item["sub"])+" · "+reason,"on":available,"open":func(): m._open_panel(func(): m._panel_activity_group(gid))})
		for id in Bulk.PACKS:
			var group := str(Bulk.PACKS[id]["group"])
			var cb: Callable
			if group=="work": cb=m._panel_occupation
			elif group=="home": cb=func(): m.MP.open("home:root")
			elif group=="education": cb=m._panel_education if id=="learning" else func(): m._panel_activity_group("edu")
			else: cb=func(): m._panel_activity_group(group)
			var why := Bulk.reason(id)
			entries.append({"id":"bulk:"+str(id),"name":Bulk.PACKS[id]["name"],"icon":"🧺","path":"Bulk activities › "+group.capitalize(),"sub":"%d time · %s total · %s" % [int(Bulk.PACKS[id]["time"]),GameState.fmt_money(Bulk.price(id)),why if why!="" else "Open the section to choose"],"on":why=="","open":func(): m._open_panel(cb)})
		for spec in [
			["education","🎓","Education","Work › Education",m._panel_education],
			["school","🏫","School clubs, teams & elections","Work › School life",func(): m.MP.open("daily:school")],
			["journey","🧵","Life activities","More",func(): m.MP.open("journey:root")],
			["community","🏘️","Places & community","More",func(): m.MP.open("journey:places")],
			["recovery","🌿","Trouble & recovery","More",func(): m.MP.open("journey:recovery")],
			["heritage","🌳","Generations & later life","More",func(): m.MP.open("journey:heritage")],
			["jobs","💼","Find work","Work › Applications",m._panel_find_work],
			["employment","💼","Work & independence","Work",func(): m.MP.open("employment:root")],
			["projects","📁","Career projects","Work",func(): m.MP.open("employment:projects")],
			["training","🧰","Apprenticeships & retraining","Work",func(): m.MP.open("employment:training")],
			["children","🧒","Your children","More › Family",m._panel_children],
			["contacts","👥","Friends & contacts","More › Family",m._panel_contacts],
			["past","🕰️","Past relationships","People",m._panel_past_relationships],
			["home","🏠","Household & routines","More › Everyday life",func(): m.MP.open("home:root")],
			["readiness","🧭","What my stats affect","More › Help",m._panel_readiness],
			["consequences","📌","Consequences & changes","More › My story",m._panel_consequences],
			["memory","📖","Choices I remember","More › My story",m._panel_decision_memory],
			["investments","📈","Investments","Assets",m._panel_investments],
			["housing","🏠","Owned home","Assets",m._panel_housing],
			["shopping","🛍️","Shopping & stores","Activities",m._panel_shop],
			["buy_home","🏡","Buy or rent a home","Shopping",func(): m.MP.open("shop:category:homes")],
			["buy_car","🚗","Buy a vehicle","Shopping",func(): m.MP.open("shop:category:transport")],
			["career","🌟","Special careers","Work",m._panel_special_hub],
			["guide","❔","How to play","More › Help",m._panel_guide],
		]:
			var cb: Callable = spec[4]
			var available := true
			var description := "School, university, study and quizzes" if spec[0]=="education" else "Browse options and requirements"
			if spec[0] == "school" and not GameState.in_school():
				available=false
				description="Requires current school enrollment"
			var minimum := 13 if spec[0]=="jobs" else 5 if spec[0]=="education" else 18 if spec[0] in ["investments","housing","career"] else 0
			if spec[0] in ["employment","projects","training"]: minimum=16
			if int(GameState.player["age"])<minimum:
				available=false
				description="Age %d+" % minimum
			entries.append({"id":"place:"+str(spec[0]),"icon":spec[1],"name":spec[2],"path":spec[3],"sub":description,"on":available,"open":func(): m._open_panel(cb)})
	entries.append({"id":"settings","icon":"⚙️","name":"Settings","path":"More","sub":"Audio, text size, motion and display","on":true,"open":func(): m._open_panel(m._panel_settings)})
	return entries

func favourites() -> Array:
	var saved = GameState.settings.get("navigation_favourites",[])
	return saved if saved is Array else []

func toggle(id: String) -> void:
	var saved := favourites().duplicate()
	if saved.has(id): saved.erase(id)
	else: saved.append(id)
	GameState.settings["navigation_favourites"] = saved
	SaveManager.save_settings()

func matches(entry: Dictionary, words: String) -> bool:
	var haystack := (str(entry["name"])+" "+str(entry["path"])+" "+str(entry["sub"])).to_lower()
	for word in words.strip_edges().to_lower().split(" ",false):
		if not haystack.contains(word): return false
	return true

func show() -> void:
	m._panel_header("🔎","Find & favourites")
	m._add(U.lbl("Search activities and destinations. ☆ saves a shortcut; opening a result never performs the action for you.","Dim",15,true))
	var input := LineEdit.new()
	input.name = "NavigationSearch"
	input.placeholder_text = "Try school, gym, loans or consequences"
	input.text = query
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.custom_minimum_size.y = 42
	m._add(input)
	var filters := U.hb(8)
	filter_buttons.clear()
	for choice in [[false,"All"],[true,"Favourites"]]:
		var selected: bool = choice[0]
		var button := U.btn(choice[1],func(): only_favourites=selected; refresh(),"Primary" if only_favourites==selected else "Row")
		filter_buttons[selected]=button
		filters.add_child(button)
	m._add(filters)
	count = U.lbl("","Dim",14,true)
	m._add(count)
	results = U.vb(8)
	m._add(results)
	input.text_changed.connect(func(value): query=value; refresh())
	input.text_submitted.connect(func(_value): refresh())
	refresh()

func refresh() -> void:
	if not is_instance_valid(results): return
	for key in filter_buttons:
		if is_instance_valid(filter_buttons[key]): filter_buttons[key].theme_type_variation="Primary" if key==only_favourites else "Row"
	U.clear(results)
	var total := 0
	var shown := 0
	for entry in catalog():
		var id := str(entry["id"])
		if only_favourites and not favourites().has(id): continue
		if not matches(entry,query): continue
		total += 1
		# Empty broad searches stay compact; narrowing the query reveals more.
		if shown >= 35: continue
		shown += 1
		var line := U.hb(6)
		var pin := U.btn("★" if favourites().has(id) else "☆",func(): toggle(id); refresh(),"Flat")
		pin.tooltip_text = "Remove favourite" if favourites().has(id) else "Save favourite"
		pin.custom_minimum_size = Vector2(42,42)
		line.add_child(pin)
		var cb: Callable = entry["open"]
		var row := U.row(str(entry["icon"]),str(entry["name"]),str(entry["path"])+"\n"+str(entry["sub"]),cb,bool(entry["on"]))
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(row)
		results.add_child(line)
	count.text = "%d match%s%s" % [total,"" if total==1 else "es"," · showing 35; narrow your search" if total>35 else ""]
	if total==0: results.add_child(U.lbl("No favourites here yet. Switch to All and tap ☆." if only_favourites else "No matches. Try a shorter name or a category such as health.","Dim",16,true))
