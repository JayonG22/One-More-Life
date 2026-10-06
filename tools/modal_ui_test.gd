extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func frames() -> void:
	for i in range(12): await get_tree().process_frame
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; GameState.settings["reduced_motion"]=true; Fx.apply_volumes()
	var main: Control=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach)
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30; GameState.player["time_left"]=100; GameState.player["money"]=200000
	GameState.settings["effects"]=false; EventEngine.pending.clear(); EventEngine.displayed.clear(); main._show("game")
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/modals"; DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); await frames()
		for view in ["_open_tv_setup","_show_trophies","_show_star_shop","_show_family_tree","_show_missions"]:
			main.call(view); await frames(); main._fit_active_popup(); await frames()
			var bounds: Rect2=main.overlay_frame.get_global_rect(); var window := main.get_viewport_rect().size
			ok(bounds.position.x>=20 and bounds.end.x<=window.x-20 and bounds.position.y>=20 and bounds.end.y<=window.y-20,"Large menu leaves screen: "+view+" scale "+str(scale))
			ok(bounds.size.x<=window.x*0.84 and bounds.size.y<=window.y*0.84,"Large menu still blocks almost the full screen: "+view+" scale "+str(scale))
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(directory+"/"+view+"-"+str(scale)+".png")
			main._close_popup(); EventEngine.pending.clear(); EventEngine.displayed.clear(); await frames()
		for long in [false,true]:
			var choices: Array=[]
			for i in range(6 if long else 3):
				choices.append({"label":("Compare the offer, the delivery schedule and the materials before agreeing to this option " if long else "Try this approach ")+str(i+1),"outcomes":[{"text":"The choice was recorded.","effects":{"happiness":1},"no_friction":true}]})
			var inst := {"def":{"id":"_layout_choice","icon":"🎭" if long else "👪","title":"A plan with several possibilities" if long else "The cardboard kingdom","text":"An interesting offer has arrived. We can compare its terms, keep our plans flexible, or try a smaller first step. ".repeat(7 if long else 1),"choices":choices,"no_friction":true},"roles":{}}
			main._show_decision(inst); await frames(); main._fit_active_popup(); await frames()
			var frame: Control=main.overlay_frame; var rect := frame.get_global_rect(); var win := main.get_viewport_rect().size
			ok(rect.position.x>=20 and rect.end.x<=win.x-20 and rect.position.y>=20 and rect.end.y<=win.y-20,"Event card leaves the screen")
			ok(rect.size.y<=win.y*0.78,"Event takes nearly the full screen")
			ok(frame.find_children("*","PanelContainer",true,false).all(func(p): return p.theme_type_variation!="EventCard"),"Event retains a nested outer/inner frame")
			ok(frame.find_children("*","PanelContainer",true,false).any(func(p): return p.theme_type_variation=="EventIcon"),"Event lost its icon badge")
			var sc := main.overlay_box.get_node("PopupScroll") as ScrollContainer
			var last := main.overlay_box.find_child("Choice"+str(choices.size()),true,false) as Button
			if long: ok(sc.get_v_scroll_bar().max_value>sc.size.y,"Long choice bank is cut off instead of scrollable")
			sc.scroll_vertical=int(sc.get_v_scroll_bar().max_value); await frames()
			ok(main.overlay_box.has_node("EventHeading") and main.overlay_box.get_node("EventHeading").get_global_rect().position.y>=frame.get_global_rect().position.y,"Event title disappears with scrolling choices")
			ok(last!=null and last.theme_type_variation=="ChoiceRow","Choice action is missing or uses navigation styling")
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(directory+"/event-"+str(scale)+("-long" if long else "")+".png")
			GameState.player["stats"]["happiness"]=50
			var happiness := GameState.stat("happiness"); last.pressed.emit(); await frames()
			ok(GameState.stat("happiness")==minf(100,happiness+1),"Scrolled last choice does not work")
			main._close_popup(); EventEngine.pending.clear(); EventEngine.displayed.clear(); await frames()
		GameState.settings["minigames"]=true
		var cash: int=GameState.player["money"]; var time: int=GameState.player["time_left"]; var stats: Dictionary=GameState.player["stats"].duplicate(true)
		Journey.modules["skills"].start("music",true); await frames(); main.mg_default.pressed.emit(); await frames()
		var rect: Rect2=main.mg_frame.get_global_rect(); var win := main.get_viewport_rect().size
		ok(rect.size.x<=win.x*0.82 and rect.size.y<=win.y*0.84,"Minigame frame does not preserve breathing room")
		ok(rect.position.y>=20 and rect.end.y<=win.y-20,"Minigame frame leaves screen")
		ok(main.mg_frame.find_children("*","PanelContainer",true,false).any(func(p): return p.theme_type_variation=="EventIcon"),"Active minigame lacks its activity icon")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/music-"+str(scale)+".png")
		main.mg_game.finish(0.7,{"practice":true}); await get_tree().create_timer(1.1).timeout
		main.mg_default.pressed.emit(); await frames(); main._close_popup(); EventEngine.pending.clear(); EventEngine.displayed.clear()
		ok(GameState.player["money"]==cash and GameState.player["time_left"]==time and GameState.player["stats"]==stats,"Practice charged or rewarded the active player")
	main.queue_free(); await frames()
	for player in Fx.get_children():
		if player is AudioStreamPlayer: player.stop(); player.stream=null
	await get_tree().create_timer(0.2).timeout
	for message in failures: print("FAIL: "+str(message))
	print("MODAL UI TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
