extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func frames() -> void:
	for i in range(8): await get_tree().process_frame
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func fits(root: Control) -> bool:
	for button in root.find_children("*","Button",true,false):
		for label in button.find_children("*","Label",true,false):
			if label.get_global_rect().end.y>button.get_global_rect().end.y+1: return false
	return true
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; GameState.settings["minigames"]=false; Fx.apply_volumes()
	var main: Control=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach); GameState.settings["effects"]=false
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/school-depth"
	DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.new_life({"country":"us","gender":"female","random_royalty":false})
		GameState.player["age"]=13; GameState.player["money"]=10000; GameState.player["time_left"]=12
		GameState.player["education"]["stage"]="secondary"; Daily._ss()["clubs"]=["robotics"]
		main._close_popup(); clear(); main._show("game")
		GameState.settings["ui_scale"]=scale; main._apply_display()
		Depth.school_activity("club","robotics"); await frames()
		ok(main.popup_open and fits(main.overlay_box),"Club plan hidden or button text clipped")
		var choices: Array=main.overlay_box.find_children("Choice*","Button",true,false)
		ok(choices.size()==3,"Club decision lacks its three choices")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/club-"+str(scale)+".png")
		var answer: Button=main.overlay_box.find_child("Choice1",true,false)
		if answer: answer.pressed.emit(); await frames()
		ok(Depth.state().get("club_work",[]).size()==1,"Actual club plan button does not conclude the activity")
		main._close_popup(); clear()
		main._open_panel(func(): main.MP.show("journey:school:clubs"),true); await frames()
		ok(main.g["panel_title"].text=="Club work record" and fits(main.g["panel"]),"Club record unavailable or clipped")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/record-"+str(scale)+".png")
		main._close_popup(); clear(); Daily._ss()["clique"]="gamers"
		Depth.school_activity("clique","gamers"); await frames()
		ok(main.popup_open and fits(main.overlay_box),"Clique decision hidden or text clipped")
		ok(main.overlay_box.find_children("Choice*","Button",true,false).size()==3,"Clique decision choices missing")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/clique-"+str(scale)+".png")
		var clique_answer: Button=main.overlay_box.find_child("Choice1",true,false)
		if clique_answer: clique_answer.pressed.emit(); await frames()
		ok(Depth.state().get("clique_work",[]).size()==1,"Actual clique button does not record its outcome")
		main._close_popup(); clear()
		main._open_panel(func(): main.MP.show("journey:school:cliques"),true); await frames()
		ok(main.g["panel_title"].text=="Clique memories" and fits(main.g["panel"]),"Clique memories unavailable or clipped")
		var school=Journey.modules["school"]
		school.start("science"); main._close_popup(); clear()
		school.step(); await frames()
		ok(main.popup_open and fits(main.overlay_box),"Named project collaborators make the decision clip")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/project-"+str(scale)+".png")
		var project_answer: Button=main.overlay_box.find_child("Choice1",true,false)
		if project_answer: project_answer.pressed.emit(); await frames()
		ok(school.st()["project"]["stage"]==1,"Actual project button does not record its choice")
		main._close_popup(); clear()
		main._open_panel(func(): main.MP.show("journey:school"),true); await frames()
		ok(main.g["panel"].find_children("*","Label",true,false).any(func(label): return label.text=="Pause project"),"Project has no accessible pause action")
		school.archive(true); main._close_popup(); clear()
		main._open_panel(func(): main.MP.show("journey:school"),true); await frames()
		ok(main.g["panel"].find_children("*","Label",true,false).any(func(label): return label.text=="Resume Science exhibition") and fits(main.g["panel"]),"Paused work has no readable return action")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/paused-"+str(scale)+".png")
	main.queue_free(); await frames()
	for player in Fx.find_children("*","AudioStreamPlayer",true,false): player.stop(); player.stream=null
	await get_tree().create_timer(0.2).timeout
	print("SCHOOL DEPTH UI checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
