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
	GameState.settings["effects"]=false; GameState.settings["reduced_motion"]=true
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=15; GameState.player["money"]=200000; GameState.player["education"]["stage"]="secondary"
	EventEngine.pending.clear(); EventEngine.displayed.clear()
	main._show("game"); await frames()
	main._open_panel(main._panel_more,true); await frames()
	ok(main.g["panel"].find_children("*","Label",true,false).any(func(l): return l.text.contains("Life activities")),"Human More menu has no hub entry")
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._refresh_side()
		for key in ["root","group:family","group:health","group:work","group:play","group:money","group:trouble","group:identity","parenting","funds","wellbeing","seasons","pathways","people","school","skills","enterprise","recovery","places","heritage","identity"]:
			main._open_panel(func(): main.MP.show("journey:"+key),true); await frames()
			var panel: Control=main.g["panel"]
			ok(not panel.find_children("*","Label",true,false).is_empty(),"Empty panel: "+key)
			var layout := true
			for button in panel.find_children("*","Button",true,false):
				for label in button.find_children("*","Label",true,false): layout=layout and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
			ok(layout,"Button text overflows: "+key+" scale "+str(scale))
		main._open_panel(func(): main.MP.show("journey:root"),true); await frames()
		var first: Button
		for button in main.g["panel"].find_children("*","Button",true,false):
			if button.find_children("*","Label",true,false).any(func(label): return label.text.contains("People & family")): first=button
		ok(first.theme_type_variation=="NavigationRow","Hub navigation looks like ordinary activity")
		first.pressed.emit(); await frames()
		var connection: Button
		for button in main.g["panel"].find_children("*","Button",true,false):
			if button.find_children("*","Label",true,false).any(func(label): return label.text.contains("Connections & follow-through")): connection=button
		ok(connection!=null,"Family group lost connections")
		if connection!=null: connection.pressed.emit(); await frames()
		ok(main.g["panel"].find_children("*","Label",true,false).any(func(l): return l.text.contains("One follow-up a year")),"Hub navigation click failed")
		if DisplayServer.get_name()!="headless":
			main._open_panel(func(): main.MP.show("journey:root"),true); await frames(); await RenderingServer.frame_post_draw
			var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/journey"
			DirAccess.make_dir_recursive_absolute(directory)
			get_viewport().get_texture().get_image().save_png(directory+"/connected-"+str(scale)+".png")
	EventEngine.pending.clear(); EventEngine.displayed.clear(); GameState.settings["minigames"]=true
	Journey.modules["skills"].start("budget",false); await frames()
	ok(main.mg_open,"New challenge did not open the actual game host")
	main.mg_default.pressed.emit(); await frames()
	ok(main.mg_playing and is_instance_valid(main.mg_game),"Game host intro did not start challenge")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("OML_SCREENSHOT_DIR")+"/journey/challenge-budget.png")
	var active=main.mg_game
	for i in range(5): active.choose(active.order.find(0)); active.next()
	await get_tree().create_timer(1.1).timeout
	main.mg_default.pressed.emit(); await frames()
	ok(Journey.modules["skills"].st()["active"].is_empty() and Journey.modules["skills"].st()["records"].has("budget"),"Game host did not apply result and close")
	GameState.player["age"]=18
	for kind in ["repair","music","negotiation"]:
		EventEngine.pending.clear(); EventEngine.displayed.clear(); main._close_popup()
		Journey.modules["skills"].start(kind,false); await frames()
		ok(main.mg_open,"Hands-on activity did not reach actual host: "+kind)
		main.mg_default.pressed.emit(); await frames()
		ok(main.mg_game.get_script().resource_path.ends_with("mg_hands_on.gd"),"Host opened quiz instead of hands-on activity: "+kind)
		active=main.mg_game
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OS.get_environment("OML_SCREENSHOT_DIR")+"/journey/hands-"+kind+".png")
		for round_i in range(5):
			if kind=="repair":
				for i in range(3):
					active.inspect(i)
					if int(active.current[i])!=int(active.target[i]): active.toggle(i)
			elif kind=="music":
				for note in active.notes:
					var press := InputEventKey.new(); press.pressed=true; press.keycode=KEY_1+int(note); active._unhandled_input(press)
			else: active.offer_slider.value=80+round_i*4; active.scope_slider.value=80
			active.submit_round(); active.next_round()
		await get_tree().create_timer(1.1).timeout
		main.mg_default.pressed.emit(); await frames()
		ok(Journey.modules["skills"].st()["records"][kind]["last"]>=0.6 and not main.mg_open,"Hands-on result did not apply and close: "+kind)
	# A pre-update repair attempt must keep the old workshop format on resume.
	EventEngine.pending.clear(); EventEngine.displayed.clear(); main._close_popup()
	Journey.modules["skills"].st()["active"]={"kind":"repair","practice":true,"token":999,"owner":Journey.uid()}
	Journey.modules["skills"].run(); await frames(); main.mg_default.pressed.emit(); await frames()
	ok(main.mg_game.get_script().resource_path.ends_with("mg_workshop.gd"),"Old saved workshop changed format")
	active=main.mg_game
	for i in range(3): active.choose(active.order.find(0)); active.next()
	await get_tree().create_timer(1.1).timeout; main.mg_default.pressed.emit(); await frames()
	ok(Journey.modules["skills"].st()["active"].is_empty(),"Legacy workshop cannot finish after resume")
	main.visible=false
	for kind in Journey.modules["skills"].GAMES:
		var mg=load("res://scenes/minigames/mg_workshop.gd").new()
		mg.setup({"kind":kind,"title":kind.capitalize(),"skill":75,"belt":3,"opponent_style":"aggressive","practice":false})
		mg.theme=main.theme
		var results: Array=[]
		mg.finished.connect(func(score,detail): results.append([score,detail]))
		add_child(mg); await frames()
		var layout := true
		for button in mg.buttons: layout=layout and button.get_rect().end.y<=mg.size.y
		ok(layout,"Challenge buttons outside scene: "+kind)
		for round_i in range(5):
			var press := InputEventKey.new(); press.pressed=true; press.keycode=KEY_1+mg.order.find(0)
			mg._unhandled_input(press)
			press=InputEventKey.new(); press.pressed=true; press.keycode=KEY_ENTER
			mg._unhandled_input(press)
		mg.finish(1,{})
		ok(results.size()==1 and float(results[0][0])>0.60 and int(results[0][1]["rounds"])==5,"Challenge result/keyboard/replay failed: "+kind)
		mg.queue_free(); await frames()
	# Short workshop practice finishes in three rounds and stays reward-free.
	var practice=load("res://scenes/minigames/mg_workshop.gd").new()
	practice.setup({"kind":"budget","title":"Short practice","skill":75,"practice":true,"rounds":3})
	practice.theme=main.theme
	var practice_results: Array=[]
	practice.finished.connect(func(score,detail): practice_results.append([score,detail]))
	add_child(practice); await frames()
	for i in range(3): practice.choose(practice.order.find(0)); practice.next()
	await get_tree().create_timer(0.8).timeout
	ok(practice_results.size()==1 and int(practice_results[0][1]["rounds"])==3,"Short practice did not finish in three rounds")
	practice.next(); ok(practice_results.size()==1,"Short practice result replayed")
	practice.queue_free(); await frames()
	main.visible=true; EventEngine.pending.clear(); EventEngine.displayed.clear()
	GameState.player["time_left"]=12
	var paths=Journey.modules["pathways"]
	paths.record("school","ui-project","Tech",80,true)
	GameState.player["age"]=int(GameState.player["age"])+1
	main._open_panel(func(): main.MP.show("journey:pathways"),true); await frames()
	var follow_button: Button
	for button in main.g["panel"].find_children("*","Button",true,false):
		if button.find_children("*","Label",true,false).any(func(label): return label.text.contains(str(paths.st()["cases"][0]["name"]))): follow_button=button
	ok(follow_button!=null,"Named follow-up has no actual activity button")
	if follow_button!=null:
		ok(follow_button.theme_type_variation!="NavigationRow","Follow-up activity looks like navigation")
		follow_button.pressed.emit(); await frames()
		ok(Journey.state()["prompt"].get("domain","")=="pathways","Actual follow-up button does not open the decision")
	Journey.state()["prompt"]={}; EventEngine.pending.clear(); EventEngine.displayed.clear()
	main._close_popup(); await frames()
	GameState.player["age"]=30; GameState.player["time_left"]=100
	var child := GameState.create_npc("child",{"age":9,"closeness":70})
	var parent=Journey.modules["parenting"]
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._refresh_side()
		main._open_panel(func(): main.MP.show("journey:parenting:child:"+child),true); await frames()
		var moment: Button
		for button in main.g["panel"].find_children("*","Button",true,false):
			for label in button.find_children("*","Label",true,false):
				ok(label.get_global_rect().end.y<=button.get_global_rect().end.y+1,"Parenting wording clipped at scale "+str(scale))
			if button.find_children("*","Label",true,false).any(func(label): return label.text=="A parenting moment"): moment=button
		ok(moment!=null and moment.theme_type_variation!="NavigationRow","Parenting action/button absent")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OS.get_environment("OML_SCREENSHOT_DIR")+"/journey/parenting-"+str(scale)+".png")
		if scale==1.75 and moment!=null:
			moment.pressed.emit(); await frames()
			ok(Journey.state()["prompt"].get("domain","")=="parenting","Parenting action does not open actual choice")
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(OS.get_environment("OML_SCREENSHOT_DIR")+"/journey/parenting-choice.png")
	Journey.state()["prompt"]={}; EventEngine.pending.clear(); EventEngine.displayed.clear()
	main.queue_free(); await frames()
	for player in Fx.get_children():
		if player is AudioStreamPlayer: player.stop(); player.stream=null
	await get_tree().create_timer(0.2).timeout
	for message in failures: print("FAIL: "+str(message))
	print("JOURNEY UI TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
