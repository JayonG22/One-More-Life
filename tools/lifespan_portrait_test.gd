extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func _ready() -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	var cases: Array=[[0,"female","baby"],[8,"male","boy"],[8,"female","girl"],[8,"nonbinary","child"],[70,"male","old_man"],[70,"female","old_woman"],[70,"nonbinary","older_person"]]
	var moods: Array=["reference","happy","low","strain","tired","unwell"]
	get_window().size=Vector2i(1260,800)
	var background := ColorRect.new(); background.color=Color("#101923"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var grid := GridContainer.new(); grid.columns=7; grid.position=Vector2(20,12); grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",10); add_child(grid)
	for subject in cases:
		var label := UIKit.lbl(subject[2],"Dim",16); label.custom_minimum_size=Vector2(160,24); grid.add_child(label)
	for mood in moods:
		for subject in cases:
			var box := VBoxContainer.new(); box.custom_minimum_size=Vector2(160,105); grid.add_child(box)
			var image := TextureRect.new(); image.custom_minimum_size=Vector2(100,82); image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; box.add_child(image)
			image.texture=OriginalPortraits.texture(Avatar.sanitize({}),subject[0],subject[1],mood)
			box.add_child(UIKit.lbl(mood,"Dim",13))
	for subject in cases:
		for tone in range(6):
			var av := Avatar.sanitize({"skin":tone})
			ok(OriginalPortraits.person_kind(subject[0],subject[1])==subject[2],"Wrong age/gender portrait selected")
			ok(OriginalPortraits.texture(av,subject[0],subject[1],"neutral")==null,"Neutral original glyph replaced")
			var reference := OriginalPortraits.texture(av,subject[0],subject[1],"reference")
			ok(reference!=null,"Missing original tone: "+str(subject))
			for mood in moods.slice(1):
				var changed := OriginalPortraits.texture(av,subject[0],subject[1],mood)
				ok(changed!=null and changed.get_image().get_data()!=reference.get_image().get_data(),"Expression did not affect actual face: "+str(subject)+str(tone)+mood)
			for category in ["portrait_hair","portrait_eyes","portrait_accessory","portrait_detail"]:
				var changed: Dictionary=av.duplicate(true); changed[category]=1
				var texture := OriginalPortraits.texture(changed,subject[0],subject[1],"neutral")
				ok(texture!=null and texture.get_image().get_data()!=reference.get_image().get_data(),"Lifespan cosmetic missing: "+str(subject)+category)
	ok(OriginalPortraits.cache.size()<=128,"Lifespan textures exceed bounded cache")
	for i in range(8): await get_tree().process_frame
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")
	if directory!="" and DisplayServer.get_name()!="headless":
		DirAccess.make_dir_recursive_absolute(directory)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory+"/lifespan-faces.png")
	print("LIFESPAN PORTRAIT checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
