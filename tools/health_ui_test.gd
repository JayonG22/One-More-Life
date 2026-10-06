extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func frames() -> void:
	for i in range(8): await get_tree().process_frame
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; GameState.settings["effects"]=false; Fx.apply_volumes()
	var main: Control=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach)
	GameState.new_life({"country":"us","gender":"female","random_royalty":false}); GameState.player["age"]=35; GameState.player["money"]=100000; GameState.player["time_left"]=50
	var w=Journey.modules["wellbeing"]
	for id in ["diabetes","asthma","arthritis"]:
		GameState.player["medical"]["conditions"][id]={"years":2,"controlled":false,"treated":0,"flares":1}; w.reviewed(id,"Clinic review")
	for i in range(45): w.record("Care review","A saved follow-up with readable costs",Actions._cost(100))
	GameState.create_npc("mother",{"age":75,"health":35}); GameState.create_npc("sibling",{"age":28,"health":80,"closeness":80})
	EventEngine.pending.clear(); EventEngine.displayed.clear(); main._close_popup(); main._show("game"); await frames()
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/health"; DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._refresh_side()
		main._open_panel(func(): main._panel_activity_group("health"),true); await frames()
		ok(main.g["panel"].find_children("*","Label",true,false).any(func(label): return label.text=="Health & support"),"Shared clinical entry missing from actual Activities")
		for page in ["journey:wellbeing","journey:wellbeing:record","journey:wellbeing:plans","journey:wellbeing:plan:diabetes","journey:wellbeing:access","journey:wellbeing:family","real:care","exp:medical","exp:mental"]:
			main._open_panel(func(): main.MP.show(page),true); await frames()
			var buttons: Array=main.g["panel"].find_children("*","Button",true,false)
			ok(not buttons.is_empty(),"Empty health page: "+page)
			var fits := true
			for button in buttons:
				for label in button.find_children("*","Label",true,false): fits=fits and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
			ok(fits,"Health button text clipped: "+page+" scale "+str(scale))
			if page=="journey:wellbeing": ok(buttons.size()<=14,"Health overview flooded with repeated condition actions")
			if page=="journey:wellbeing:record":
				ok(main.g["panel"].find_children("*","Label",true,false).any(func(label): return label.text=="Next page"),"Care record not paginated")
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw; get_viewport().get_texture().get_image().save_png(directory+"/"+page.replace(":","-")+"-"+str(scale)+".png")
	main.queue_free(); await frames()
	print("HEALTH UI TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
