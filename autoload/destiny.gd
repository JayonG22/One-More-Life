extends Node

## DESTINY — how a life path finds you.
##
## Choosing "Vampire" on the new-life screen told you the ending before the
## first age-up. Everything interesting about becoming something else is the
## becoming, and the picker skipped it.
##
## So paths are no longer picked. They are stumbled into. Ordinary things you do
## — where you drink, what you read, the job you take, who you marry — quietly
## leave a LEAD. Leads mature. When one is ripe, the world makes you an offer,
## and you can still say no.
##
## Nothing here forces a path on anybody. A life where you never go near any of
## it stays an ordinary life, which is the point: the supernatural should feel
## like something that happened to you, not a difficulty setting.

## path -> [icon, name, how many lead points before an offer can come]
const PATHS := {
	"vampire":  ["🧛", "Vampire", 10],
	"witch":    ["🧙", "Witch", 10],
	"super":    ["🦸", "Gifted", 12],
	"revenant": ["🧟", "Undead", 8],
	"royal":    ["👑", "Royal", 14],
	"pirate":   ["🏴‍☠️", "Pirate Life", 12],
	"colonist": ["🪐", "Space Colonist", 14],
	"traveler": ["⌛", "Time Traveler", 16],
}

## What ordinary behaviour plants which lead. These are activity ids, job ids and
## flags the rest of the game already produces.
const ACTIVITY_LEADS := {
	"nightlife": {"vampire": 1},
	"library": {"witch": 1, "traveler": 1},
	"museum": {"traveler": 2},
	"cave": {"traveler": 1, "witch": 1},
	"sea_fish": {"pirate": 2},
	"fish": {"pirate": 1},
	"dirtbike": {"super": 1},
	"meditate": {"witch": 1},
	"pray": {"witch": 1, "revenant": 1},
	"black_market": {"vampire": 1, "traveler": 1},
	"crystal": {"witch": 2},
	"volunteer": {"super": 1},
	"gym": {"super": 1},
}

const JOB_LEADS := {
	"scientist": {"super": 2, "traveler": 1},
	"chemist": {"super": 2, "witch": 1},
	"biologist": {"super": 2},
	"doctor": {"vampire": 1},
	"nurse": {"vampire": 1},
	"paramedic": {"vampire": 1},
	"pilot": {"colonist": 2},
	"engineer": {"colonist": 2},
	"astronaut": {"colonist": 4},
	"sailor": {"pilot": 0, "pirate": 3},
	"fisherman": {"pirate": 2},
	"librarian": {"traveler": 2, "witch": 1},
	"archaeologist": {"traveler": 3},
	"soldier": {"super": 1},
	"police": {"super": 1},
}


func _p() -> Dictionary:
	return GameState.player


func state() -> Dictionary:
	var p := _p()
	if p.is_empty():
		return {}
	if not p.has("destiny") or not (p["destiny"] is Dictionary):
		p["destiny"] = {"leads": {}, "offered": [], "declined": [], "last_offer": -99}
	return p["destiny"]


func leads() -> Dictionary:
	var st := state()
	return st.get("leads", {}) if not st.is_empty() else {}


func lead(path: String) -> int:
	return int(leads().get(path, 0))


## Add lead points toward a path. Silent by design: the player should notice the
## world leaning toward them, not read a progress bar.
func add(path: String, amount: int = 1) -> void:
	var st := state()
	if st.is_empty() or amount <= 0 or not PATHS.has(path):
		return
	if Lives.kind() != "human":
		return
	if (st["declined"] as Array).has(path):
		return
	st["leads"][path] = int(st["leads"].get(path, 0)) + amount
	# The first real brush with something gets a line, so it does not come from
	# nowhere twenty years later.
	if int(st["leads"][path]) == amount and amount >= 2:
		_first_brush(path)


func _first_brush(path: String) -> void:
	var lines := {
		"vampire": "Somebody at the bar asked how old I thought they were, and did not laugh when I guessed.",
		"witch": "A book I did not order arrived with my name on the packing slip.",
		"super": "I have been lifting things this week that I should not be able to lift.",
		"revenant": "I have started dreaming about a door I have never seen, and being asked to hold it open.",
		"royal": "Someone at the party knew exactly who my grandmother was, and seemed very interested in me.",
		"pirate": "The harbourmaster told me a story he clearly does not tell everyone.",
		"colonist": "My name came up in a briefing I was not supposed to be in.",
		"traveler": "The dates in the archive do not line up, and I appear to be the only person bothered by it.",
	}
	GameState.add_log(str(lines.get(path, "Something odd happened this year.")))


# ---------------------------------------------------------------- hooks

func on_activity(id: String) -> void:
	if ACTIVITY_LEADS.has(id):
		for path in (ACTIVITY_LEADS[id] as Dictionary).keys():
			add(str(path), int(ACTIVITY_LEADS[id][path]))


func on_job(job_id: String) -> void:
	if JOB_LEADS.has(job_id):
		for path in (JOB_LEADS[job_id] as Dictionary).keys():
			if int(JOB_LEADS[job_id][path]) > 0:
				add(str(path), int(JOB_LEADS[job_id][path]))


## Conditions that build on their own, checked once a year.
func _passive() -> void:
	var p := _p()
	var age := int(p.get("age", 0))
	if age >= 13 and GameState.stat("smarts") >= 85.0:
		add("traveler", 1)
	if float(p.get("karma", 0)) <= -55.0:
		add("revenant", 1)
	if not Grit.grudge_holders(60).is_empty():
		add("revenant", 1)
	if float(p.get("fame", 0)) >= 60.0:
		add("royal", 1)
	if int(p.get("money", 0)) >= 4000000:
		add("royal", 1)
	# Marrying into a family with a title is the most direct route to a crown.
	var partner := str(p.get("partner", ""))
	if partner != "" and GameState.npcs.has(partner):
		var n := GameState.npc(partner)
		if str(n.get("title", "")).find("Royal") >= 0 or bool(n.get("royal", false)):
			add("royal", 4)
	if Careers.has_career("astronaut"):
		add("colonist", 3)
	if Law.has_license("boating"):
		add("pirate", 1)
	if Law.has_license("scuba"):
		add("pirate", 1)


func yearly() -> void:
	var p := _p()
	if p.is_empty() or not GameState.is_alive() or Lives.kind() != "human":
		return
	var st := state()
	if st.is_empty():
		return
	_passive()
	if int(p["age"]) - int(st.get("last_offer", -99)) < 3:
		return
	# The ripest lead gets to speak, and only if it has genuinely accumulated.
	var best := ""
	var best_v := 0
	for path in (st["leads"] as Dictionary).keys():
		var need := int(PATHS[str(path)][2])
		var v := int(st["leads"][path])
		if v >= need and v > best_v and not (st["offered"] as Array).has(path) and not (st["declined"] as Array).has(path):
			best = str(path)
			best_v = v
	if best == "":
		return
	if randf() > 0.45:
		return
	st["last_offer"] = int(p["age"])
	(st["offered"] as Array).append(best)
	_offer(best)


# ---------------------------------------------------------------- the offer

const OFFERS := {
	"vampire": ["🧛", "The offer",
		"The one from the bar finally says it plainly. They are older than this city. They are asking, not taking, and they will not ask twice.",
		"I said yes, and the last thing I remember of being warm is the sound of my own heartbeat slowing.",
		"I said no. They nodded like they had expected it, and paid for my drink."],
	"witch": ["🧙", "The book opens",
		"The book that arrived without being ordered has been waiting three years. Tonight the first page finally means something, and the meaning is an instruction.",
		"I read it aloud. Something in the room agreed with me.",
		"I put it in a drawer and did not open it again. It stopped being warm after a while."],
	"super": ["🦸", "Whatever this is",
		"It is no longer deniable. Something is happening to me that does not happen to people, and pretending has stopped working.",
		"I stopped pretending. Whatever I am now, I am it on purpose.",
		"I kept it down. It takes something out of me every day, and nobody knows."],
	"revenant": ["🧟", "Not finished",
		"The dream about the door has been every night for a month, and in last night's version somebody on the other side used my name.",
		"I answered. Dying turned out not to be the end of the paperwork.",
		"I stopped answering the dream. It stopped coming. Mostly."],
	"royal": ["👑", "The letter",
		"A solicitor who does not usually write to people like me has written to me, and the envelope has a crest on it.",
		"I answered the letter. It turns out the family had been looking for a while.",
		"I did not answer. Some doors are more peaceful closed."],
	"pirate": ["🏴‍☠️", "A berth",
		"The offer is a share, not a wage, on a ship whose paperwork does not bear looking at.",
		"I took the share. Nobody on that deck asked what I used to do.",
		"I stayed ashore. I watched them leave on the tide and went back to work."],
	"colonist": ["🪐", "The seat",
		"The programme has a seat that needs filling and my name on the shortlist. It is one way for a long time.",
		"I took the seat. The last thing I saw of Earth was weather over an ocean I had never visited.",
		"I turned down the seat. I still look up more than I used to."],
	"traveler": ["⌛", "The date that does not fit",
		"The discrepancy in the archive is not an error, and following it to the end of the shelf has put me somewhere that should not exist.",
		"I stepped through. The year on the newspaper was not the year I left.",
		"I closed the file and walked out. I have not been back to that archive."],
}


func _offer(path: String) -> void:
	var d: Array = OFFERS.get(path, ["✨", "Something", "…", "I said yes.", "I said no."])
	EventEngine.push_decision({
		"id": "_destiny_" + path, "icon": str(d[0]), "title": str(d[1]), "text": str(d[2]),
		"no_friction": true,
		"choices": [
			{"label": "Take it", "outcomes": [{"text": str(d[3]), "no_friction": true, "destiny": {"take": path}}]},
			{"label": "Walk away", "outcomes": [{"text": str(d[4]), "no_friction": true, "destiny": {"decline": path}}]},
		]})


func outcome(data: Dictionary) -> void:
	var st := state()
	if st.is_empty():
		return
	if data.has("decline"):
		var dp := str(data["decline"])
		(st["declined"] as Array).append(dp)
		(st["leads"] as Dictionary)[dp] = 0
		GameState.counter("destiny_declined")
		return
	if not data.has("take"):
		return
	var path := str(data["take"])
	GameState.counter("destiny_taken")
	GameState.counter("life_paths")
	match path:
		"vampire", "witch":
			Lives.become(path)
		"super":
			Lives.become("super", {"side": "hero" if int(_p().get("karma", 0)) >= 0 else "villain"})
		"revenant":
			# Rising is a thing that happens at death; taking the offer schedules it.
			Lives.life()["destiny_rise"] = true
			GameState.add_log("Whatever I agreed to, it does not take effect until the end.")
		"royal":
			Lives.setup_royal(false)
			GameState.counter("life_royal")
			GameState.add_milestone(int(_p()["age"]), "was recognised as part of a royal house")
		"pirate", "colonist", "traveler":
			Expansion.setup_life(path, {"born_year": 1715})
			GameState.counter("life_" + path)
			GameState.add_milestone(int(_p()["age"]), "left the life they had for a %s" % str(PATHS[path][1]).to_lower())
	LifeThreads.remember("career", "The year everything changed",
		"I was offered something nobody gets offered, and I took it.", "", 82, ["destiny", path])


## For the More screen, so a curious player can see the world leaning at them
## without it becoming a checklist to grind.
func hint_lines() -> Array:
	var out: Array = []
	if Lives.kind() != "human":
		return out
	for path in leads().keys():
		var v := int(leads()[path])
		var need := int(PATHS[str(path)][2])
		if v <= 0:
			continue
		var word := "something is circling" if v < need / 2 else ("something is close" if v < need else "something is waiting on your answer")
		out.append(["%s %s" % [str(PATHS[str(path)][0]), word], ""])
	return out
