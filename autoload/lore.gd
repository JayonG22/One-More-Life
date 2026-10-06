extends Node

## People and projects carry on even when the player does nothing. Each setting
## retains its own cast and state, so returning to an era does not reset it.
const PROJECTS := {
	"human":[["A workshop on the empty corner","Trades","opens a small repair workshop","takes on an apprentice","tries to survive a bad trading year","keeps the doors open with a cooperative"],["The shared garden","Environment","asks for an unused plot","gets the first planting organised","faces a difficult growing season","turns the garden into a dependable neighbourhood place"],["A room for music","Media","finds a room for local performers","hosts a first crowded evening","faces complaints and rising costs","finds a way to keep the venue running"]],
	"traveler1850":[["The print shop","Media","sets up a hand press","finds readers for a local paper","faces a shortage of paper and credit","keeps printing through a partnership"],["The station road","Trades","surveys a road to the new station","gathers a working crew","finds the first route flooded","builds a usable crossing"]],
	"traveler1920":[["The wireless circle","Media","builds a wireless receiver","starts a listening club","struggles with faulty components","sets up a dependable evening gathering"],["The motor workshop","Trades","opens a motor repair shed","teaches a young helper","faces a parts shortage","makes the workshop a local fixture"]],
	"traveler1970":[["The independent record shop","Retail","rents a shop for records","starts hosting small performances","struggles when deliveries become unreliable","keeps a loyal listening community"],["The shared commute","Transport","organises lifts to work","builds a dependable rota","faces a fuel shortage","finds a route the group can maintain"]],
	"pirate":[["A life ashore","Trades","plans a chandlery in a safe port","finds a reliable supplier","loses a cargo to rough seas","opens a smaller shop with a trusted partner"]],
	"colonist":[["The second greenhouse","Environment","proposes another habitat greenhouse","raises a first tray of seedlings","faces an irrigation fault","makes the next harvest dependable"]],
	"royal":[["The palace archive","Media","begins restoring neglected records","trains a new archivist","finds a missing chapter in the collection","opens part of the archive to visitors"]],
	"vampire":[["The night refuge","Hospitality","offers a discreet room after sunset","finds others who need shelter","faces an unwanted investigation","keeps a smaller refuge through trusted keepers"]],
	"witch":[["A quiet circle","Education","brings together solitary practitioners","shares carefully tested remedies","faces a dispute about dangerous magic","keeps a circle with clearer responsibilities"]],
	"super":[["The rescue network","Healthcare","organises ordinary people after a disaster","trains a volunteer team","loses support when attention moves on","keeps a smaller team ready for the next call"]],
	"revenant":[["The memory keeper","Media","records stories of people who are gone","finds someone willing to preserve them","discovers conflicting memories","keeps a collection that admits its uncertainties"]],
}

func key() -> String:
	var path := Lives.kind()
	var setting := path + str(Lives.life().get("era","")) if path == "traveler" else path
	return "%s:%s:%s" % [setting,GameState.player.get("country",""),GameState.player.get("region","")]

func state() -> Dictionary:
	if not GameState.world.has("local_lore"): GameState.world["local_lore"] = {}
	var root: Dictionary = GameState.world["local_lore"]
	var k := key()
	if not root.has(k):
		var setting := Lives.kind() + str(Lives.life().get("era","")) if Lives.is_type("traveler") else Lives.kind()
		var templates: Array = PROJECTS.get(setting,PROJECTS["human"])
		var cast: Array = []
		for t in templates:
			cast.append({"name":ContentDB.random_first("female",str(GameState.player.get("country","us"))),"project":t.duplicate(),"stage":0,"momentum":randi_range(-1,1),"next":GameState.year_now()+randi_range(1,3),"helped":-1,"status":"Taking shape"})
		root[k] = {"threads":cast,"history":[],"last_year":-1}
	return root[k]

func yearly() -> void:
	if Lives.separate(): return
	var s := state()
	var year := GameState.year_now()
	if int(s["last_year"]) == year: return
	s["last_year"] = year
	for t in s["threads"]:
		if int(t["stage"]) >= 4 or int(t["next"]) > year: continue
		var project: Array = t["project"]
		var stage := int(t["stage"])
		var text := "%s %s." % [t["name"],project[stage+2]]
		if stage == 2:
			t["momentum"] = int(t["momentum"]) + (1 if Workforce.climate(str(project[1])) >= 0.0 else -1)
		if stage == 3 and int(t["momentum"]) < 0:
			text = "%s pauses %s after costs and setbacks make it unsustainable. The people involved look for a smaller beginning." % [t["name"],str(project[0]).to_lower()]
			t["status"] = "Paused after setbacks"
		elif stage == 3: t["status"] = "Established"
		else: t["status"] = ["Getting started","Growing","Under pressure"][stage]
		t["stage"] = stage+1
		t["next"] = year+randi_range(2,4)
		s["history"].append({"year":year,"text":text})
		while s["history"].size() > 24: s["history"].pop_front()
		GameState.add_log("📰 " + text)
		# One local development per year. Silence leaves breathing room.
		break

func demand(field: String) -> float:
	if Lives.separate(): return 1.0
	for t in state()["threads"]:
		if str(t["project"][1]) == field and int(t["stage"]) > 0:
			return 0.9 if str(t["status"]) == "Paused after setbacks" else 1.12
	return 1.0

func menu(_key: String) -> Dictionary:
	var s := state()
	var rows: Array = []
	for i in range(s["threads"].size()):
		var t: Dictionary = s["threads"][i]
		rows.append({"icon":"📰","name":"%s · %s" % [t["name"],t["project"][0]],"sub":"%s · %s\nOffer a day of help: 1 time, once per year. The project can still struggle." % [t["status"],t["project"][1]],"act":"lore:help","arg":i,"on":int(t["stage"])<4 and int(t["helped"])!=GameState.year_now()})
	var info: Array = ["People here have projects of their own. Time, local demand and occasional help shape their progress, including setbacks. Returning to a place or timeline preserves its history."]
	for h in s["history"]: info.append("%d · %s" % [h["year"],h["text"]])
	return {"icon":"📰","title":"The world around you","info":info,"rows":rows}

func act(action: String, arg) -> void:
	if action != "help" or Lives.separate(): return
	var s := state()
	var i := int(arg)
	if i < 0 or i >= s["threads"].size(): return
	var t: Dictionary = s["threads"][i]
	if int(t["stage"])>=4 or int(t["helped"])==GameState.year_now() or Actions._out_of_time(): return
	t["helped"] = GameState.year_now()
	t["momentum"] = int(t["momentum"])+1
	Actions._done("🤝","A day of help","I gave %s a day of help with %s. The work will carry on when I am doing something else." % [t["name"],str(t["project"][0]).to_lower()],{"happiness":2,"stress":1})
