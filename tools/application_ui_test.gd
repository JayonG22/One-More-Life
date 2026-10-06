extends Node
var checks := 0
var failures: Array=[]
var main: Control
var directory: String
func ok(value: bool, text: String) -> void:
	checks+=1
	if not value: failures.append(text); print("FAIL: "+text)
func frames() -> void:
	for i in range(8): await get_tree().process_frame
func capture(name: String, root: Control) -> void:
	await frames()
	var fits := true
	for button in root.find_children("*","Button",true,false):
		for label in button.find_children("*","Label",true,false):
			if label.is_visible_in_tree(): fits=fits and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
	ok(fits,"Button text overflows: "+name)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory+"/"+name+".png")
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; GameState.settings["effects"]=false; Fx.apply_volumes()
	main=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach)
	directory=OS.get_environment("OML_SCREENSHOT_DIR")+"/application"
	DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._show("title"); await frames()
		ok(main.screens["title"].find_child("FreshStartBtn",true,false)!=null,"Fresh Start not reachable from title")
		ok(main.screens["title"].find_child("TitleBrand",true,false).visible or main.screens["title"].find_child("CompactBrand",true,false).visible,"Brand vanishes in compact layout")
		await capture("title-"+str(scale),main.screens["title"])
		main._open_fresh_start(); await capture("scenarios-"+str(scale),main.overlay_box)
		ok(main.overlay_box.find_children("*","Button",true,false).size()>=3,"Scenario choices inaccessible")
		main._close_popup(); main._open_tv_setup(); await frames()
		ok(main.tv_results.find_children("Story_*","Button",true,false).size()==6,"Original story library not the default or campaign missing")
		await capture("stories-"+str(scale),main.overlay_box); main._close_popup()
		main._begin_fresh_start("first_keys"); await frames()
		ok(SaveManager.current_slot>0 and GameState.player["age"]==18,"Scenario does not start in its own save")
		await capture("fresh-start-"+str(scale),main.g["panel"])
		Journey.modules["fresh"].chapter(); await frames()
		ok(EventEngine.displayed.has("def") or EventEngine.has_pending(),"Scenario chapter button produces no decision")
		await capture("chapter-"+str(scale),main.overlay_box)
		EventEngine.pending.clear(); EventEngine.displayed.clear(); Journey.state()["prompt"]={}; main._close_popup()
	print("APPLICATION UI TEST checks=%d failures=%d" % [checks,failures.size()])
	await frames()
	main.queue_free(); main=null
	await frames()
	get_tree().quit(0 if failures.is_empty() else 1)
