extends Node
func _ready() -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=75; GameState.player["money"]=100000; SaveManager.current_slot=1
	var failures := 0
	for target in [10,50,100]:
		while GameState.npcs.size()<target:
			var id := GameState.create_npc("friend",{"age":60,"closeness":60})
			GameState.npc(id)["personal_history"]=[]
			for i in range(20): GameState.npc(id)["personal_history"].append({"year":1950+i,"text":"A remembered friendship, ordinary responsibility and family milestone."})
		var start := Time.get_ticks_usec(); SaveManager.save_game()
		var milliseconds := (Time.get_ticks_usec()-start)/1000.0
		var bytes := FileAccess.get_file_as_bytes(SaveManager.slot_path(1)).size()
		var valid := SaveManager.valid(SaveManager._read(SaveManager.slot_path(1),null))
		if not valid or bytes>2000000 or milliseconds>1000: failures+=1
		print("SAVE BENCHMARK people=%d bytes=%d write_ms=%.2f valid=%s" % [target,bytes,milliseconds,valid])
	print("STEWARDSHIP PERFORMANCE checks=3 failures=%d" % failures)
	get_tree().quit(0 if failures==0 else 1)
