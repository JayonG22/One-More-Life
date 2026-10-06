extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func frames() -> void:
	for i in range(8): await get_tree().process_frame
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; GameState.settings["reduced_motion"]=true; Fx.apply_volumes()
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30; EventEngine.pending.clear(); EventEngine.displayed.clear()
	var old := Avatar.sanitize({"skin":3,"hair":2,"style":8,"bg":6})
	ok(old["skin"]==3 and old["hair"]==2 and old["style"]==8 and old["cut"]==0,"Legacy appearance choices lost")
	for cat in Avatar.CATEGORIES:
		if cat[0] in ["cut","hair_color","eyes","eye_color","brows","nose","mouth","face_shape","details","facial_hair","accessory","clothes"]:
			for i in range(cat[2]): ok(Avatar.is_owned(cat[0],i) and Avatar.cost_of(cat[0],i)==0,"Basic feature not freely available")
	var looks: Dictionary={}; var ids: Array=[]
	for i in range(16):
		var id := GameState.create_npc("friend",{"age":20+i,"gender":"female" if i%2==0 else "male"})
		ids.append(id); var n := GameState.npc(id); var av := Avatar.appearance(n)
		looks[JSON.stringify(av)]=true
		ok(Avatar.appearance(n)==av,"NPC look rerolls on view")
	ok(looks.size()>=14,"NPCs are not visually varied")
	var saved_looks: Array=ids.map(func(id): return GameState.npc(id)["avatar"].duplicate(true))
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict())))
	for i in range(ids.size()): ok(GameState.npc(ids[i])["avatar"]==saved_looks[i],"NPC appearance changes on reload")
	var states := [{"health":100,"happiness":55,"stress":10},{"health":100,"happiness":90,"stress":10},{"health":100,"happiness":10,"stress":10},{"health":100,"happiness":55,"stress":90},{"health":45,"happiness":55,"stress":10},{"health":20,"happiness":55,"stress":10}]
	var expected := ["steady","happy","low","strain","tired","unwell"]
	var same_person := Avatar.random("female",42)
	for pair in [["skin",0],["cut",2],["hair_color",1],["details",0],["accessory",0],["facial_hair",0],["eyes",0],["brows",0],["mouth",0],["style",0],["skin",5],["portrait_hair",0],["portrait_eyes",0],["portrait_accessory",0],["portrait_detail",0]]:
		same_person[pair[0]]=pair[1]
	var grid := GridContainer.new(); grid.columns=8; grid.position=Vector2(16,16); grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",12); add_child(grid)
	for i in range(24):
		var box := VBoxContainer.new(); grid.add_child(box)
		var portrait := AvatarView.new(); portrait.custom_minimum_size=Vector2(145,145); box.add_child(portrait)
		var av: Dictionary=same_person if i<6 else Avatar.random("female" if i%2==0 else "male",i*133)
		var person := {"alive":true,"stats":states[i]} if i<6 else {"alive":true,"health":75,"happiness":55,"stress":10}
		portrait.setup(av,[1,8,20,40,60,80][i%6] if i>=6 else 30,"female" if i<6 or i%2==0 else "male",false,person)
		if i<6: ok(portrait.expression==expected[i],"Portrait status does not follow actual life condition")
		ok(portrait.find_children("OriginalFace","Label",true,false).size()==1 and portrait._face.text==Avatar.face_emoji(av,portrait.age,portrait.gender),"Original portrait glyph is not restored")
		var label := UIKit.lbl(expected[i] if i<6 else "Age "+str(portrait.age),"Dim",14); label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; box.add_child(label)
	var original := Avatar.sanitize({"skin":5})
	var reference := OriginalPortraits.texture(original,30,"female","reference").get_image()
	for mood in ["happy","low","strain","tired","unwell"]:
		var changed := OriginalPortraits.texture(original,30,"female",mood).get_image()
		ok(changed.get_data()!=reference.get_data(),"Expression does not alter original facial paths: "+mood)
		var preserved := true
		for y in range(128):
			for x in range(128):
				if y<47 or x<32 or x>99: preserved=preserved and changed.get_pixel(x,y)==reference.get_pixel(x,y)
		ok(preserved,"Expression changes the original hair or silhouette: "+mood)
	for figure in range(4):
		for tone in range(6):
			var a := Avatar.sanitize({"figure":figure,"skin":tone,"portrait_hair":4,"portrait_eyes":3})
			ok(OriginalPortraits.texture(a,30,"female","neutral")!=null,"Adult figure/tone customization missing")
	for key in ["portrait_hair","portrait_eyes"]:
		for i in range(1,13 if key=="portrait_hair" else 9):
			var a := original.duplicate(); a[key]=i
			ok(Avatar.cost_of(key,i)==0 and Avatar.is_owned(key,i),"Original-art colour not free")
			ok(OriginalPortraits.texture(a,30,"female","neutral").get_image().get_data()!=reference.get_data(),"Colour selection does not change portrait")
	for key in ["portrait_accessory","portrait_detail"]:
		for i in range(1,6 if key=="portrait_accessory" else 4):
			var a := original.duplicate(); a[key]=i
			ok(Avatar.is_owned(key,i) and Avatar.cost_of(key,i)==0,"Original-art accessory not free")
			ok(OriginalPortraits.texture(a,30,"female","neutral").get_image().get_data()!=reference.get_data(),"Accessory choice does not draw on original face")
	for years in [0,8,65,90]:
		ok(OriginalPortraits.texture(original,years,"female","happy")!=null,"Lifespan expression missing")
		ok(OriginalPortraits.texture(original,years,"female","neutral")==null,"Unchanged neutral lifespan glyph replaced")
	for a in [Avatar.sanitize({"style":8}),Avatar.sanitize({"hair":2})]:
		ok(OriginalPortraits.texture(a,30,"female","happy")==null,"Special look loses original portrait")
	ok(OriginalPortraits.texture(original,30,"female","neutral")==null,"Default neutral portrait replaced")
	var adult := AvatarView.new(); adult.custom_minimum_size=Vector2(120,120); add_child(adult)
	var subject := {"alive":true,"stats":{"health":100,"happiness":55,"stress":20}}
	adult.setup(original,30,"female",false,subject)
	ok(adult._face.visible and not adult._features.visible,"Steady original glyph hidden")
	subject["stats"]["health"]=20; adult.refresh_expression()
	ok(adult._features.visible and not adult._face.visible,"Actual health change does not refresh in-face expression")
	subject["stats"]["health"]=100; adult.refresh_expression()
	ok(adult._face.visible and not adult._features.visible,"Recovered face does not return to original")
	adult.queue_free()
	await frames()
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/portraits"; DirAccess.make_dir_recursive_absolute(directory)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw; get_viewport().get_texture().get_image().get_region(Rect2i(0,0,1080,500)).save_png(directory+"/faces.png")
	grid.queue_free(); await frames()
	var main: Control=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach); GameState.settings["effects"]=false
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._show("game"); await frames()
		main._open_avatar_editor(Avatar.for_player(),"female",30,func(_av): pass); await frames()
		var fits := true
		for button in main.overlay_box.find_children("*","Button",true,false):
			for label in button.find_children("*","Label",true,false):
				if label.is_visible_in_tree(): fits=fits and label.get_global_rect().end.x<=main.get_viewport_rect().end.x+1 and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
		ok(fits,"Appearance editor clips at scale "+str(scale))
		ok(main.overlay_box.find_children("*","AvatarView",true,false).size()==1,"Appearance preview not drawn")
		var preview: AvatarView=main.overlay_box.find_children("*","AvatarView",true,false)[0]
		var hair_row
		for label in main.overlay_box.find_children("*","Label",true,false):
			if label.text=="Hair colour": hair_row=label.get_parent()
		ok(hair_row!=null and hair_row.is_visible_in_tree(),"Working original hair colour control missing")
		if hair_row!=null:
			var before: int=preview.av["portrait_hair"]
			for button in hair_row.get_children():
				if button is Button and button.text=="›": button.pressed.emit()
			await frames()
			ok(preview.av["portrait_hair"]==(before+1)%13 and preview._features.visible,"Actual editor colour button does not update original artwork")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw; get_viewport().get_texture().get_image().save_png(directory+"/editor-"+str(scale)+".png")
		main._close_popup(); main._open_panel(func(): main._panel_person(str(ids[0])),true); await frames()
		ok(main.g["panel"].find_children("*","AvatarView",true,false).size()>=1,"Actual NPC page uses no drawn portrait")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw; get_viewport().get_texture().get_image().save_png(directory+"/person-"+str(scale)+".png")
	main._close_popup()
	main._open_panel(func():
		main._panel_header("","Health")
		main.MP.rows_into({"title":"Health","info":["Full explanation. ".repeat(20),"Treatment cost: $200"],"rows":[]})
	,true); await frames()
	var toggle
	for button in main.g["panel"].find_children("*","Button",true,false):
		if button.text=="Details": toggle=button
	ok(toggle!=null,"Long explanations have no Details control")
	var full_label
	for label in main.g["panel"].find_children("*","Label",true,false):
		if label.text.begins_with("Full explanation."): full_label=label
	ok(full_label!=null and not full_label.is_visible_in_tree(),"Full explanation is not initially folded")
	if toggle!=null:
		toggle.pressed.emit(); await frames()
		ok(full_label.is_visible_in_tree(),"Details does not reveal the full explanation")
		toggle.pressed.emit(); await frames()
		ok(not full_label.is_visible_in_tree(),"Details does not close again")
	var cost_visible := false
	for label in main.g["panel"].find_children("*","Label",true,false):
		if label.text=="Treatment cost: $200": cost_visible=label.is_visible_in_tree()
	ok(cost_visible,"Brief layout hides the actual cost")
	main.queue_free(); await frames()
	var child := GameState.create_npc("child",{"age":24,"gender":"female","money":120})
	var child_look := Avatar.random("female",786); child_look["cut"]=9; child_look["eyes"]=3; child_look["accessory"]=5; child_look["portrait_hair"]=4; child_look["portrait_eyes"]=3; child_look["portrait_accessory"]=1; child_look["portrait_detail"]=1
	GameState.npc(child)["avatar"]=child_look.duplicate(true)
	var tree := FamilyTreeView.new(); add_child(tree); tree.setup(); await frames()
	ok(tree.find_children("*","AvatarView",true,false).size()>=2,"Family tree does not use actual portraits")
	tree.queue_free(); await frames()
	ok(Dynasty.switch_to(child),"Living child transfer failed")
	ok(Avatar.for_player()==child_look,"Living transfer loses child's facial features")
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict())))
	ok(Avatar.for_player()==child_look,"Transferred face changes after save reload")
	print("PORTRAIT TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
