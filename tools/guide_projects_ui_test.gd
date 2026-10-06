extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func frames() -> void:
	for i in range(6): await get_tree().process_frame
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	var main: Control=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach)
	GameState.settings["effects"]=false
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30; GameState.player["money"]=200000; GameState.player["time_left"]=50
	Actions.hire("pharmacist"); EventEngine.pending.clear(); EventEngine.displayed.clear()
	main._show("game"); await frames()
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/guide-projects"
	DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._refresh_side()
		main._open_panel(func(): main.MP.show("employment:projects"),true); await frames()
		ok(not main.g["panel"].find_children("*","Label",true,false).is_empty(),"Empty project menu")
		for stage in range(3):
			Employment.st()["active"]={"token":Employment.serial(),"session":Employment.job_session(),"job":"pharmacist","field":"Healthcare","brief":Employment.briefs["pharmacist"][2].duplicate(true),"stage":stage,"quality":65.0,"due":GameState.year_now()+1,"client":"Healthcare:2","support":0,"dishonest":false,"salary":115000,"started":GameState.year_now()}
			Employment.st()["prompt"]={}; EventEngine.pending.clear(); EventEngine.displayed.clear()
			Employment.resume_project()
			var event := {"def":Employment.st()["prompt"]["def"],"roles":{}}
			ok(not event.is_empty(),"Missing project prompt")
			main._show_decision(event); await frames()
			var buttons: Array=main.find_children("*","Button",true,false)
			var layout := true
			for button in buttons:
				if not button.is_visible_in_tree(): continue
				for label in button.find_children("*","Label",true,false): layout=layout and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
			ok(layout,"Project text outside a button at scale "+str(scale))
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(directory+"/project-"+str(stage)+"-"+str(scale)+".png")
	for message in failures: print("FAIL: "+str(message))
	print("GUIDE PROJECTS UI TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
