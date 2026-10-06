extends Node
var checks := 0
var failures: Array=[]
var c
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh() -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=50; GameState.player["time_left"]=12; clear()
	c=Journey.modules["coping"]
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	for relation in ["mother","father","parent","child","sibling"]:
		fresh()
		var departed := GameState.create_npc("friend",{"first":"Rowan","age":50,"gender":"male" if relation=="father" else "nonbinary" if relation=="parent" else "female"})
		var uid := FamilyChronicle.identity(GameState.npc(departed))
		var receiver := GameState.create_npc("child",{"first":"Ari","age":25,"happiness":70})
		var recipient := GameState.npc(receiver); recipient["stress"]=20
		var own_uid := FamilyChronicle.identity(recipient)
		GameState.npc(departed)["parent_uids"]=[]
		if relation in ["mother","father","parent"]: recipient["parent_uids"]=[uid]
		elif relation=="child": GameState.npc(departed)["parent_uids"]=[own_uid]; recipient["parent_uids"]=[]
		else: GameState.npc(departed)["parent_uids"]=[Journey.uid()]; recipient["parent_uids"]=[Journey.uid()]
		recipient["playable_player"]=GameState.player.duplicate(true)
		recipient["playable_player"]["person_uid"]=own_uid
		var stranger := GameState.create_npc("friend",{"first":"Unrelated","age":30})
		var dead_receiver := GameState.create_npc("child",{"age":20}); GameState.npc(dead_receiver)["parent_uids"]=[uid]; GameState.npc(dead_receiver)["alive"]=false
		var pet := GameState.create_npc("pet",{"species":"dog","age":3}); GameState.npc(pet)["parent_uids"]=[uid]
		EventEngine._npc_died(departed); clear()
		var loss: Dictionary=c.st(recipient)["losses"][0]
		ok(loss["uid"]==uid and loss["name"]=="Rowan "+str(GameState.npc(departed)["last"]) and loss["relation"]==relation,"Actual relative loss used active-player family role")
		ok(loss["year"]==GameState.year_now() and loss["burden"]==40,"Loss lacks dated bounded strain")
		ok(recipient["stress"]==25 and recipient["happiness"]==64,"Off-screen family loss has no reaction")
		ok(recipient["playable_player"]["journey"]["coping"]==c.st(recipient) and recipient["playable_player"]["stats"]["stress"]==25,"Former-player snapshot diverged from own grief")
		ok(not GameState.npc(stranger).get("journey",{}).has("coping") and not GameState.npc(dead_receiver).get("journey",{}).has("coping") and not GameState.npc(pet).get("journey",{}).has("coping"),"Invented stranger, dead or nonhuman kinship")
		var snapshot := JSON.stringify(c.st(recipient)); c.family_loss(departed)
		ok(JSON.stringify(c.st(recipient))==snapshot and recipient["stress"]==25,"Repeated death duplicates NPC grief")
		GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear(); recipient=GameState.npc(receiver)
		ok(c.st(recipient)["losses"][0]["uid"]==uid,"Saved actual family loss vanished")
		c.background(recipient,GameState.year_now()+1)
		ok(c.st(recipient)["losses"][0]["burden"]==37,"NPC grief does not ease across actual years")
		var next := JSON.stringify(c.st(recipient)); c.background(recipient,GameState.year_now()+1)
		ok(JSON.stringify(c.st(recipient))==next,"NPC grief year settles twice")
		var stress: float=recipient["stress"]
		ok(Dynasty.switch_to(receiver),"Cannot enter actual surviving child's life"); clear()
		ok(c.st()["losses"][0]["uid"]==uid and c.st()["losses"][0]["burden"]==37 and GameState.stat("stress")==stress,"Living switch discarded own loss, recovery or stress")
	# Death handover preserves the child's prior family loss alongside the new one.
	fresh(); var source := Journey.uid()
	var heir := GameState.create_npc("child",{"age":25,"money":321}); GameState.npc(heir)["stress"]=42
	c.st(GameState.npc(heir))["losses"]=[{"uid":"earlier-parent","name":"Earlier parent","year":GameState.year_now()-2,"burden":21.0,"remembered":-99,"relation":"father"}]
	GameState.player["alive"]=false; GameState.continue_as(heir); clear()
	ok(c.st()["losses"].size()==2 and c.st()["losses"].any(func(loss): return loss["uid"]=="earlier-parent") and c.st()["losses"].any(func(loss): return loss["uid"]==source),"Death handover erases previous loss or omits actual parent")
	ok(GameState.stat("stress")==42,"Death handover rerolls the child's recorded stress")
	# Older former-player snapshots may carry history only in their saved life.
	fresh(); var departed := GameState.create_npc("friend",{"age":60})
	var receiver := GameState.create_npc("child",{"age":25,"happiness":3})
	var recipient := GameState.npc(receiver)
	recipient["parent_uids"]=[FamilyChronicle.identity(GameState.npc(departed))]; recipient["stress"]=99
	recipient["playable_player"]=GameState.player.duplicate(true)
	var saved: Dictionary=c.st(recipient["playable_player"])
	for i in range(32): saved["losses"].append({"uid":"old-"+str(i),"name":"Old loss","year":GameState.year_now()-3,"relation":"friend","burden":1.0,"remembered":-99})
	for i in range(100): saved["history"].append({"year":GameState.year_now()-3,"text":"Earlier support"})
	recipient.erase("journey")
	EventEngine._npc_died(departed); clear()
	ok(c.st(recipient)["losses"].size()==32 and c.st(recipient)["losses"][1]["uid"]=="old-0","Snapshot-only history lost or loss list unbounded")
	ok(c.st(recipient)["history"].size()==100 and c.st(recipient)["history"][1]["text"]=="Earlier support","Support history erased or unbounded")
	ok(recipient["stress"]==100 and recipient["happiness"]==0,"Bereavement reaction escapes stat bounds")
	ok(recipient["playable_player"]["journey"]["coping"]==c.st(recipient),"Legacy snapshot and current NPC grief diverged")
	print("FAMILY LOSS checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
