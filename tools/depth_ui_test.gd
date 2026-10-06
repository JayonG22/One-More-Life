extends Node
var main: Control
var checks := 0
var failures: Array = []
func frames(n: int = 12) -> void:
	for i in range(n): await get_tree().process_frame
func ok(value: bool, reason: String) -> void:
	checks+=1
	if not value: failures.append(reason)
func text(node: Node) -> String:
	var value := ""
	for label in node.find_children("*","Label",true,false): value+="\n"+label.text
	for button in node.find_children("*","Button",true,false): value+="\n"+button.text
	return value
func capture(name: String) -> void:
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/v30"
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory+"/"+name+".png")
func _ready() -> void:
	seed(3033)
	main=load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await frames()
	Goals.unlocked.disconnect(main._toast_ach)
	GameState.settings["effects"]=false
	GameState.settings["voices"]=false
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	EventEngine.pending.clear()
	GameState.player["age"]=15
	GameState.player["education"]["stage"]="secondary"
	GameState.player["stats"]["health"]=20
	Daily._ss()["clique"]="nerds"
	Daily._ss()["clubs"]=["band","council"]
	Daily._ss()["sport"]="basketball"
	main._show("game")
	await frames()
	ok(main.g["avatar_view"]._expression.visible and main.g["avatar_view"].tooltip_text=="Feeling unwell","live portrait not showing current condition")
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale
		main._apply_display()
		main._open_panel(main._panel_education,true)
		await frames()
		ok(text(main.g["panel"]).contains("Arithmetic quiz"),"education quizzes inaccessible")
		ok(text(main.g["panel"]).contains("Science practical"),"practical learning inaccessible")
		var bounds: Rect2 = main.g["panel"].get_global_rect()
		ok(bounds.position.x>=0 and bounds.end.x<=get_viewport().get_visible_rect().size.x+1,"education panel exceeds viewport")
		if scale==1.0: await capture("school")
		main.MP.open("daily:depth")
		await frames()
		var contents := text(main.g["panel"])
		for item in ["Clique gathering","School band project","Student council project","School team fixture","Talent show","class president"]: ok(contents.contains(item),"school activity missing "+item)
		if scale==1.0: await capture("school-portfolio")
	GameState.settings["ui_scale"]=1.0
	main._apply_display()
	main._close_popup()
	Depth.school("Arithmetic")
	await frames()
	ok(main.mg_open,"school quiz did not reach minigame host")
	main._mg_play("school_quiz",{"bank":Depth.lessons["Arithmetic"].slice(0,3),"needed":3,"graded":true,"skill":50,"title":"Arithmetic quiz"},func(_score,_detail): pass)
	await frames()
	var quiz=main.mg_game
	ok(quiz.q_label.text!="" and quiz.buttons[0].visible,"school quiz has no visible questions or answer controls")
	await capture("school-quiz")
	Engine.time_scale=20
	for i in range(3):
		quiz._answer(int(quiz.bank[i]["correct"]))
		await get_tree().create_timer(2.6).timeout
	ok(quiz.done and quiz.correct==3,"school quiz not completable through answer controls")
	Engine.time_scale=1
	# Close the artificial hosted round and end the genuine school action once.
	main._mg_finish(func(_score,_detail): pass,1.0,{})
	Depth._school_result(1.0,{},"Arithmetic")
	EventEngine.pending.clear()
	Depth.remember({"id":"ui_memory","title":"A remembered choice","text":"A test","choices":[{"label":"Remember me"}]},0)
	main._open_panel(main._panel_decision_memory,true)
	await frames()
	ok(text(main.g["panel"]).contains("Remember me"),"saved choices not readable in play")
	GameState.player["age"]=30
	GameState.player["last_income"]=50000
	GameState.player["job"]={"id":"developer","title":"Software Engineer","field":"Technology","perf":60,"salary":50000,"years":1,"boss":""}
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale
		main._apply_display()
		main._open_panel(main._panel_occupation,true)
		await frames()
		ok(text(main.g["panel"]).contains("Investigate a regression") and text(main.g["panel"]).contains("Review a code change"),"specific job functions inaccessible")
		if scale==1.0: await capture("job-tasks")
		main._open_panel(func(): main._panel_loan_config("shark"),true)
		await frames()
		var spinboxes: Array = main.g["panel"].find_children("*","SpinBox",true,false)
		ok(spinboxes.size()==3,"exact amount fraction or loan term missing")
		if spinboxes.size()==3:
			spinboxes[0].value=1234
			spinboxes[2].value=2
			await frames()
			ok(text(main.g["panel"]).contains("Principal $1,234"),"live loan quote failed")
			spinboxes[1].value=12.5
			await frames()
			ok(int(spinboxes[0].value)==Lending.fraction_amount("shark",12.5),"fraction control failed")
		if scale==1.0: await capture("loan-config")
		main._open_panel(main._panel_murder,true)
		await frames()
		ok(main.g["panel_title"].text=="Crime · murder","murder not discoverable in crime")
	print("DEPTH UI TEST checks=%d failures=%d" % [checks,failures.size()])
	for reason in failures: print("FAIL: "+str(reason))
	get_tree().quit(0 if failures.is_empty() else 1)
