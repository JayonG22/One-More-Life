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
	var main: Control=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames(); Goals.unlocked.disconnect(main._toast_ach)
	GameState.new_life({"country":"us","gender":"female","random_royalty":false}); GameState.player["age"]=35; GameState.player["money"]=100000; GameState.player["time_left"]=50
	var r=Journey.modules["resilience"]
	for id in Grit.HABITS:
		GameState.player["habits"][id]={"level":75.0,"active":true,"clean":-1}
		r.plan(id)
	for i in range(45): r.record("gambling","A remembered support check-in and its outcome")
	GameState.create_npc("friend",{"age":35,"closeness":80})
	EventEngine.pending.clear(); EventEngine.displayed.clear(); main._close_popup(); main._show("game"); await frames()
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/resilience"; DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._refresh_side()
		var pages: Array=["journey:wellbeing","journey:resilience","journey:resilience:history","journey:resilience:settings","journey:resilience:routes:gambling","journey:resilience:boundary:gambling","journey:resilience:buddy:gambling"]
		for id in Grit.HABITS: pages.append("journey:resilience:"+id)
		for page in pages:
			main._open_panel(func(): main.MP.show(page),true); await frames()
			var buttons: Array=main.g["panel"].find_children("*","Button",true,false)
			ok(not buttons.is_empty(),"Empty recovery page: "+page)
			var fits := true
			for button in buttons:
				for label in button.find_children("*","Label",true,false): fits=fits and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
			ok(fits,"Recovery button text clipped: "+page+" scale "+str(scale))
			if page=="journey:resilience:history": ok(main.g["panel"].find_children("*","Label",true,false).any(func(label): return label.text=="Next page"),"Recovery history lacks pagination")
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw; get_viewport().get_texture().get_image().save_png(directory+"/"+page.replace(":","-")+"-"+str(scale)+".png")
	main.queue_free(); await frames()
	print("RESILIENCE UI TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
