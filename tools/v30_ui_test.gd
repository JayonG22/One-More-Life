extends Node
var main: Control
var failures: Array = []
var checks := 0
func frames(n: int = 10) -> void:
	for i in range(n): await get_tree().process_frame
func ok(value: bool, reason: String) -> void:
	checks+=1
	if not value: failures.append(reason)
func texts(control: Node) -> String:
	var result := ""
	for label in control.find_children("*","Label",true,false): result+="\n"+label.text
	return result
func shot(name: String) -> void:
	var folder := OS.get_environment("OML_SCREENSHOT_DIR")+"/v30"
	DirAccess.make_dir_recursive_absolute(folder)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")
func _ready() -> void:
	main=load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await frames()
	Goals.unlocked.disconnect(main._toast_ach)
	GameState.settings["effects"]=false
	GameState.settings["voices"]=false
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	EventEngine.pending.clear()
	main._show("game")
	await frames()
	ok(main.g["age_btn"].text.contains("One month"),"infant button still advances a year")
	main._age_up()
	await frames()
	ok(int(LifeCourse.state()["months"])==1 and int(GameState.player["age"])==0,"button did not advance one month")
	main._close_popup()
	EventEngine.pending.clear()
	GameState.player["age"]=30
	var parent := GameState.create_npc("stepparent",{"first":"TestParent","age":50})
	GameState.create_npc("stepsibling",{"first":"TestSibling","age":20})
	GameState.create_npc("cousin",{"first":"HiddenCousin","age":30})
	var dead := GameState.create_npc("mother",{"first":"RememberedMother","age":70})
	GameState.npcs[dead]["alive"]=false
	GameState.create_npc("ex",{"first":"PreviousPartner","age":30})
	GameState.create_npc("child",{"first":"TestChild","age":10})
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale
		main._apply_display()
		await frames()
		for builder in [main._panel_relationships,main._panel_past_relationships,main._panel_children,main._panel_contacts,main._panel_readiness]:
			main._open_panel(builder,true)
			await frames(15)
			var panel: Control = main.g["panel"]
			var rect := panel.get_global_rect()
			ok(rect.position.x>=-1 and rect.end.x<=get_viewport().get_visible_rect().size.x+1,"panel outside viewport")
			var text := texts(panel)
			ok(not text.contains("HiddenCousin"),"extended relative displayed")
			if builder==main._panel_relationships:
				for section in ["Parents","Siblings","Romantic","Pets"]: ok(text.contains(section),"missing relationship section "+section)
				ok(text.contains("TestParent") and text.contains("TestSibling") and not text.contains("TestChild"),"circle routing wrong")
				if scale==1.0: await shot("relationships")
			if builder==main._panel_past_relationships:
				ok(text.contains("Deceased") and text.contains("Past relationships"),"past panel is not two sections")
				ok(text.contains("RememberedMother") and text.contains("PreviousPartner"),"history entries missing")
			if builder==main._panel_children: ok(text.contains("TestChild"),"parenting inaccessible")
	main._open_avatar_editor(Avatar.for_player(),"female",30,func(_a): pass)
	await frames(20)
	var labels := texts(main.overlay_box)
	ok(labels.contains("Portrait rim") and labels.contains("Personal charm"),"new cosmetics not in editor")
	for button in main.overlay_box.find_children("*","Button",true,false):
		if button.text=="Save look":
			ok(button.get_global_rect().end.y<=get_viewport().get_visible_rect().size.y,"appearance save cut off at 175% text")
	await shot("avatar-editor")
	main._close_popup()
	GameState.settings["ui_scale"]=1.0
	main._apply_display()
	main._open_panel(main._panel_readiness,true)
	await frames(15)
	await shot("stats")
	print("V30 UI TEST checks=%d failures=%d" % [checks,failures.size()])
	for reason in failures: print("FAIL: "+str(reason))
	get_tree().quit(0 if failures.is_empty() else 1)
