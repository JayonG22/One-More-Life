extends Node
var main: Control
var checks := 0
var failures: Array = []
func ok(value: bool, reason: String) -> void:
	checks+=1
	if not value: failures.append(reason)
func frames(n: int = 8) -> void:
	for i in range(n): await get_tree().process_frame
func text(node: Node) -> String:
	var value := ""
	for label in node.find_children("*","Label",true,false): value+="\n"+label.text
	return value
func capture(name: String) -> void:
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/v31"
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory+"/"+name+".png")
func _ready() -> void:
	seed(3132)
	main=load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await frames()
	Goals.unlocked.disconnect(main._toast_ach)
	GameState.settings["effects"]=false
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30
	GameState.player["money"]=200000
	GameState.player.erase("life_course")
	LifeCourse.state()
	EventEngine.pending.clear()
	main._show("game")
	await frames()
	var catalog: Array = main.NAV.catalog()
	var ids := {}
	for entry in catalog:
		ok(not ids.has(entry["id"]),"duplicate search key")
		ids[entry["id"]]=true
		ok(entry["open"].is_valid(),"invalid navigation route")
	ok(catalog.size()>90,"navigation index too small")
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale
		main._apply_display()
		main._refresh_side()
		main._open_panel(main.NAV.show,true)
		await frames()
		var input: LineEdit = main.g["panel"].find_child("NavigationSearch",true,false)
		input.text="borrow"
		input.text_changed.emit("borrow")
		await frames()
		ok(text(main.NAV.results).contains("Borrow money"),"search failed")
		ok(main.NAV.results.get_child_count()==1,"search returned irrelevant results")
		var result: HBoxContainer = main.NAV.results.get_child(0)
		(result.get_child(0) as Button).emit_signal("pressed")
		await frames()
		ok(main.NAV.favourites().has("activity:loans") or main.NAV.favourites().has("place:loans"),"pin failed")
		main.NAV.only_favourites=true
		main.NAV.refresh()
		await frames()
		ok(main.NAV.results.get_child_count()==1,"favourites lost result")
		main.NAV.only_favourites=false
		main.NAV.query="school quizzes"
		main.NAV.refresh()
		await frames()
		ok(main.NAV.results.get_child_count()==1,"multiword search failed")
		var education_button: Button = main.NAV.results.get_child(0).get_child(1)
		education_button.emit_signal("pressed")
		await frames()
		ok(main.g["panel_title"].text=="Education","search route did not open destination")
		ok(text(main.g["panel"]).contains("undergraduate") or main.g["panel"].get_child_count()>0,"education route empty")
		main._panel_back()
		await frames()
		ok(main.g["panel_title"].text=="Find & favourites","Back lost search")
		ok(main.g["panel_trail"].text.contains("Find & favourites"),"breadcrumb missing")
		# The original age button remains; bulk buttons live inside their sections.
		ok(not main.g.has("age_slider"),"removed age slider remained")
		ok(main.g["age_btn"].text.contains("One year"),"annual button changed")
		main._open_panel(func(): main._panel_activity_group("mind"),true)
		await frames()
		ok(text(main.g["panel"]).contains(str(Bulk.PACKS["fitness"]["name"])),"fitness bundle missing")
		ok(text(main.g["panel"]).contains("incl. fee") and text(main.g["panel"]).contains(GameState.fmt_money(Bulk.price("fitness"))),"bundle total cost unclear")
		if scale==1.0: await capture("bulk-actions")
		var viewport: Rect2 = get_viewport().get_visible_rect()
		main._open_panel(main._panel_guide,true)
		await frames()
		ok(text(main.g["panel"]).contains("before age two") and text(main.g["panel"]).contains("Lifestyle"),"guide missing timing explanation")
		var panel_bounds: Rect2 = main.g["right_col"].get_global_rect()
		ok(panel_bounds.position.x>=0 and panel_bounds.end.x<=viewport.end.x+1,"help outside viewport")
		main._open_panel(main._panel_more,true)
		await frames()
		main.g["panel_scroll"].scroll_vertical=220
		await frames()
		var position: int = main.g["panel_scroll"].scroll_vertical
		main._open_panel(main._panel_guide)
		await frames()
		main._panel_back()
		await frames()
		ok(abs(main.g["panel_scroll"].scroll_vertical-position)<=1,"Back lost scroll position")
		# Actual action wrapper records measured changes without another popup.
		var record_count: int = Insight.state()["history"].size()
		main._act(func(): GameState.apply_effects({"money":-40,"stress":-2})).call()
		await frames()
		ok(Insight.state()["history"].size()==record_count+1,"action ledger not wired")
		main._open_panel(main._panel_consequences,true)
		await frames()
		ok(text(main.g["panel"]).contains("Cash") and text(main.g["panel"]).contains("Stress"),"ledger not readable")
		if scale==1.0: await capture("consequences")
		main._show_year_summary()
		await frames()
		for heading in ["Overview","Money","People","Work & school","Health","Upcoming consequences"]: ok(text(main.overlay_box).contains(heading),"recap missing "+heading)
		if scale==1.0: await capture("recap")
		main._close_popup()
		EventEngine.pending.clear()
		EventEngine.displayed.clear()
		var age := int(GameState.player["age"])
		EventEngine.push_info("🧭","Pause fixture","Resolve first.")
		main._pump()
		main._age_up()
		ok(GameState.player["age"]==age,"open event did not block age")
		main._close_popup()
		await frames()
		ok(GameState.player["age"]==age,"closing event advanced automatically")
		# Keep saved favourite selected on the second scale, not toggled off.
		GameState.settings["navigation_favourites"]=[]
		main.NAV.query=""
	GameState.settings["ui_scale"]=1.0
	main._apply_display()
	# A school bundle launches the real quiz, rather than granting a fabricated score.
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=15
	GameState.player["education"]["stage"]="secondary"
	GameState.player["money"]=200000
	EventEngine.pending.clear()
	EventEngine.displayed.clear()
	main._show("game")
	await frames()
	var school_before := float(GameState.player["education"]["performance"])
	main._open_panel(main._panel_education,true)
	await frames()
	var bundle: Button
	for button in main.g["panel"].find_children("*","Button",true,false):
		if button.get_meta("interaction","")=="bulk" and text(button).contains(str(Bulk.PACKS["learning"]["name"])): bundle=button
	ok(bundle!=null and not bundle.disabled,"school bundle inaccessible")
	if bundle!=null: bundle.emit_signal("pressed")
	await frames()
	ok(main.mg_open and not Depth.state()["active"].is_empty(),"bundle skipped interactive quiz")
	ok(GameState.player["time_left"]==9 and int(GameState.player["money"])==200000-Bulk.price("learning"),"school bundle did not charge full cost")
	ok(is_equal_approx(float(GameState.player["education"]["performance"]),school_before),"bundle awarded grades before answers")
	main.mg_default.emit_signal("pressed")
	await frames()
	var quiz=main.mg_game
	await capture("bulk-school-quiz")
	Engine.time_scale=20
	for i in range(3):
		quiz._answer(int(quiz.bank[i]["correct"]))
		await get_tree().create_timer(2.6).timeout
	await get_tree().create_timer(1.2).timeout
	Engine.time_scale=1
	await frames()
	ok(main.mg_default!=null,"quiz result did not offer Continue")
	if main.mg_default!=null: main.mg_default.emit_signal("pressed")
	await frames()
	ok(Depth.state()["active"].is_empty() and not main.mg_open,"completed bundled quiz did not resolve")
	ok(float(GameState.player["education"]["performance"])>school_before,"correct quiz answers did not earn grade improvement")
	ok(Bulk.reason("learning")!="" and int(GameState.player["bulk_used"]["learning"])==GameState.year_now(),"school bundle repeat allowed")
	main._close_popup()
	EventEngine.pending.clear()
	EventEngine.displayed.clear()
	main._show("title")
	await frames()
	ok(main.screens["title"].find_child("ResumeDetails",true,false)!=null,"title missing resume details")
	await capture("title")
	print("V31 UI TEST checks=%d failures=%d" % [checks,failures.size()])
	for reason in failures: print("FAIL: "+str(reason))
	get_tree().quit(0 if failures.is_empty() else 1)
