extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func frames() -> void:
	for i in range(6): await get_tree().process_frame
func clear() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear()
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	var main: Control=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach); GameState.settings["effects"]=false
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=25; GameState.player["money"]=100000; GameState.player["time_left"]=100
	GameState.player["education"]["hs_graduated"]=true; clear(); main._close_popup(); main._show("game"); await frames()
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/study"
	DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._refresh_side()
		GameState.player["education"]["uni"]={"major":"computer_science","level":"bachelor","year":2,"years":4,"performance":70.0,"scholarship":0.5}
		GameState.player["education"]["degrees"]=[]
		for panel in ["education","change","college","associate","return"]:
			match panel:
				"education": main._open_panel(main._panel_education,true)
				"change": main._open_panel(main._panel_change_major,true)
				"college": main._open_panel(func(): main.MP.show("journey:learning:field:Tech"),true)
				"associate":
					GameState.player["education"]["uni"]={}
					GameState.player["education"]["degrees"]=[{"major":"college:Tech","field":"Tech","name":"Associate diploma in Tech","level":"associate","country":"us"}]
					main._open_panel(main._panel_education,true)
				"return":
					GameState.player["education"]["interrupted_study"]=[{"state":"open","left":GameState.year_now()-1,"course":{"major":"computer_science","level":"bachelor","year":2,"years":4,"performance":70.0,"scholarship":0.5}}]
					main._open_panel(main._panel_education,true)
			await frames()
			var labels: Array=main.g["panel"].find_children("*","Label",true,false)
			var required: String={"education":"Change major","change":"Change major","college":"Community college","associate":"Associate diploma","return":"Return to Computer Science"}[panel]
			ok(main.g["panel_title"].text==required or labels.any(func(label): return label.text==required),"Study route not reachable/label missing: "+panel)
			var fits := true
			for button in main.g["panel"].find_children("*","Button",true,false):
				for label in button.find_children("*","Label",true,false): fits=fits and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
			ok(fits,"Study button text clips: "+panel+" at "+str(scale))
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(directory+"/"+panel+"-"+str(scale)+".png")
	main.queue_free(); await frames()
	for player in Fx.find_children("*","AudioStreamPlayer",true,false): player.stop(); player.stream=null
	await get_tree().create_timer(0.2).timeout
	print("STUDY UI checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
