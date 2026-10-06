extends Node
var checks := 0
var failures: Array=[]
var main
var directory := ""
func ok(value: bool,message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func frames() -> void:
	for i in range(8): await get_tree().process_frame
func clear() -> void: main._close_popup(); EventEngine.pending.clear(); EventEngine.displayed.clear()
func capture(name: String,root: Control) -> void:
	await frames(); var fits := true
	for button in root.find_children("*","Button",true,false):
		for label in button.find_children("*","Label",true,false):
			if label.is_visible_in_tree(): fits=fits and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
	ok(fits,"Clipped button text: "+name)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory+"/"+name+".png")
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	main=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach); GameState.settings["effects"]=false
	directory=OS.get_environment("OML_SCREENSHOT_DIR")+"/community"; DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display()
		for age in [3,5,12,15,20]:
			GameState.new_life({"country":"us","gender":"female","random_royalty":false})
			GameState.player["age"]=age; GameState.player["time_left"]=12; GameState.player["money"]=10000
			GameState.player["education"]["stage"]="none" if age<5 else "primary" if age<12 else "secondary"
			if age==20:
				var major: Dictionary=ContentDB.majors.filter(func(m): return m["level"]=="bachelor")[0]
				GameState.player["education"]["uni"]={"major":major["id"],"year":1,"years":4,"performance":50,"level":"bachelor","scholarship":0}
			clear(); main._show("game")
			main._open_panel(func(): main.MP.show("journey:campus"),true); await frames()
			ok(main.g["panel"].find_children("*","ProgressBar",true,false).size()==3,"School summary bars missing")
			await capture("school-"+str(age)+"-"+str(scale),main.g["panel"])
			if age!=15: continue
			main._open_panel(func(): main.MP.show("journey:campus:people"),true); await frames()
			ok(main.g["panel"].find_children("*","Button",true,false).size()>=13,"Actual school people inaccessible")
			await capture("people-"+str(scale),main.g["panel"])
			var campus=Journey.modules["campus"]; var who: String=campus.members("principal")[0]
			main._open_panel(func(): main._panel_person(who),true); await frames()
			ok(main.g["panel"].find_children("*","ProgressBar",true,false).size()==3,"Interaction page retains every detailed stat")
			await capture("person-"+str(scale),main.g["panel"])
			main.MP.open("bond:"+who+":profile"); await frames()
			ok(main.g["panel_title"].text.begins_with("Profile") and main.g["panel"].find_children("*","ProgressBar",true,false).size()>3,"Profile lost original detailed systems")
			await capture("profile-"+str(scale),main.g["panel"])
			campus.situation(who); await frames()
			ok(main.popup_open,"Principal's named situation did not open")
			await capture("situation-"+str(scale),main.overlay_box)
			var button: Button=main.overlay_box.find_child("Choice1",true,false)
			if button: button.pressed.emit(); await frames()
			ok(campus.st()["decisions"].size()==1,"Actual person choice button has no consequence")
			clear()
		GameState.new_life({"country":"us","gender":"female","random_royalty":false})
		GameState.player["age"]=30; GameState.player["money"]=100000; GameState.player["time_left"]=12
		Actions.hire("appliance_repair"); clear(); main._show("game")
		main._open_panel(func(): main.MP.show("employment:duties"),true); await frames()
		ok(main.g["panel"].find_children("*","ProgressBar",true,false).size()==2,"Work template lacks progress bars")
		await capture("work-"+str(scale),main.g["panel"])
	main.queue_free(); await frames()
	for player in Fx.find_children("*","AudioStreamPlayer",true,false): player.stop(); player.stream=null
	await get_tree().create_timer(0.2).timeout
	print("COMMUNITY UI checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
