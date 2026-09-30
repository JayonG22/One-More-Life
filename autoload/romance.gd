extends Node

## ROMANCE — what happens after "we are together now".
##
## Getting together was a log line and then silence. The eleven partner events
## in the library were all generic and all equally likely from day one, so a
## relationship of six months read exactly like one of thirty years, and a crush
## you had wanted for a decade produced nothing at all once you had them.
##
## This tracks the relationship itself: how long, which stage, and how it is
## actually going, and it pushes beats that belong to that stage. A first month
## is not a seventh year.

## stage -> [name, from year, what it is]
const STAGES := {
	"new":      ["The first months", 0, "Everything is new and nobody has annoyed anybody yet."],
	"settling": ["Settling in", 1, "The novelty has gone and something steadier is arriving, or is not."],
	"steady":   ["Steady", 4, "This is the shape of it now."],
	"long":     ["A long time", 12, "Long enough that most of the stories are shared ones."],
	"lifelong": ["A lifetime", 30, "Longer than either of you has been anything else."],
}

const ORDER := ["new", "settling", "steady", "long", "lifelong"]


func _p() -> Dictionary:
	return GameState.player


func st() -> Dictionary:
	var p := _p()
	if p.is_empty():
		return {}
	if not p.has("romance") or not (p["romance"] is Dictionary):
		p["romance"] = {"partner": "", "since": -1, "years": 0, "beats": {}, "was_crush": false, "last_beat": -99, "high": 0, "low": 0}
	return p["romance"]


## Called whenever a relationship starts, so the clock starts from the right year.
func began(id: String, from_relation: String = "") -> void:
	var s := st()
	if s.is_empty():
		return
	if str(s.get("partner", "")) == id:
		return
	s["partner"] = id
	s["since"] = int(_p().get("age", 0))
	s["years"] = 0
	s["beats"] = {}
	s["last_beat"] = -99
	s["high"] = 0
	s["low"] = 0
	s["was_crush"] = from_relation in ["crush", "friend", "best_friend", "classmate", "coworker", "neighbor"]
	if bool(s["was_crush"]) and GameState.npcs.has(id):
		var n: Dictionary = GameState.npcs[id]
		GameState.add_log("After all that, %s and I are actually together. I keep expecting to wake up." % str(n["first"]))
		GameState.apply_effects({"happiness": 10})
		BondStats.nudge(id, "romance", 14.0)
		Moments.fire("relationship_gain", 0.9)
		# The one thing the old code never did: put something in the diary about it.
		LifeThreads.remember("love", "The one I had wanted",
			"It was %s all along, and then one day it was not one-sided." % str(n["first"]),
			id, 74, ["romance", "crush"])


func ended() -> void:
	var s := st()
	if s.is_empty():
		return
	s["partner"] = ""
	s["since"] = -1
	s["years"] = 0
	s["beats"] = {}


func years() -> int:
	var s := st()
	if s.is_empty():
		return 0
	return int(s.get("years", 0))


func stage() -> String:
	var y := years()
	var out := "new"
	for k in ORDER:
		if y >= int(STAGES[k][1]):
			out = k
	return out


func stage_name() -> String:
	return str(STAGES[stage()][0])


## Whether the relationship is actually going well, read off the bond rather
## than the single closeness number.
func health() -> float:
	var s := st()
	var id := str(s.get("partner", ""))
	if id == "" or not GameState.npcs.has(id):
		return 0.0
	var aff := BondStats.get_stat(id, "affection")
	var tru := BondStats.get_stat(id, "trust")
	var rom := BondStats.get_stat(id, "romance")
	var res := BondStats.get_stat(id, "resentment")
	return clampf((aff + tru + rom) / 3.0 - res * 0.6, 0.0, 100.0)


func word() -> String:
	var h := health()
	if h >= 78.0:
		return "very good"
	if h >= 55.0:
		return "good"
	if h >= 35.0:
		return "wearing thin"
	if h >= 18.0:
		return "in trouble"
	return "over in all but name"


# ---------------------------------------------------------------- the beats

## Stage-gated events. `id` is unique so each fires once per relationship; the
## engine's own history is not used because a second relationship should get the
## first-months beats again.
const BEATS := [
	# ---- new
	{"id": "r_keys", "stage": ["new"], "icon": "🔑", "title": "A key",
	 "text": "{p.first} has had a spare key cut for you, and left it on the table without saying anything about it.",
	 "choices": [
		{"label": "Take it, and give {p.him} one of yours",
		 "outcomes": [
			{"text": "We swapped keys over the kitchen table like it was nothing. It was not nothing.", "weight": 2, "relationship": {"p": 12}, "effects": {"happiness": 8}, "bond": {"trust": 10, "romance": 8}},
			{"text": "I gave {p.him} mine and then spent a fortnight quietly tidying before {p.he} came round.", "weight": 1, "relationship": {"p": 8}, "effects": {"happiness": 4, "stress": 5}}]},
		{"label": "Take it and say nothing",
		 "outcomes": [
			{"text": "I put it on my ring and neither of us mentioned it again, which suited us both.", "weight": 2, "relationship": {"p": 5}, "bond": {"trust": 5}},
			{"text": "{p.He} noticed I had not offered one back. {p.He} did not say so, but {p.he} noticed.", "weight": 1, "relationship": {"p": -6}, "bond": {"resentment": 8}}]},
		{"label": "Say it is too soon",
		 "outcomes": [
			{"text": "I said I was not ready for that yet, and {p.he} took it well, and put it back in the drawer.", "weight": 2, "relationship": {"p": -3}, "bond": {"trust": 4}},
			{"text": "{p.He} said of course, absolutely, no problem, in the voice that means the opposite.", "weight": 1, "relationship": {"p": -12}, "bond": {"resentment": 12}}]}]},
	{"id": "r_meet_family", "stage": ["new", "settling"], "icon": "👪", "title": "Meeting the family",
	 "text": "{p.first} wants you to meet {p.his} family. All of them. At once. At a thing.",
	 "choices": [
		{"label": "Go, and make an effort",
		 "outcomes": [
			{"text": "I learned eleven names and remembered nine of them. {p.first}'s mother has decided she likes me.", "weight": 2, "relationship": {"p": 14}, "effects": {"happiness": 8}, "bond": {"affection": 10}},
			{"text": "I tried very hard and it was obvious I was trying very hard, which somebody said out loud.", "weight": 1, "relationship": {"p": 3}, "effects": {"stress": 10, "happiness": -3}}]},
		{"label": "Go, and be yourself",
		 "outcomes": [
			{"text": "I did not perform. Two of them found me difficult and one of them found me the best thing that had happened to {p.first}.", "weight": 2, "relationship": {"p": 10}, "bond": {"trust": 12}},
			{"text": "Being myself involved an opinion about something at the table that I could have kept to myself.", "weight": 1, "relationship": {"p": -8}, "effects": {"stress": 8}, "bond": {"resentment": 6}}]},
		{"label": "Put it off",
		 "outcomes": [
			{"text": "I said not yet. {p.He} was fine about it and asked again in the spring.", "weight": 2, "relationship": {"p": -4}},
			{"text": "Putting it off turned out to be about something {p.he} had already suspected about how serious I was.", "weight": 1, "relationship": {"p": -14}, "bond": {"trust": -10, "resentment": 10}}]}]},

	# ---- settling
	{"id": "r_move_in", "stage": ["settling", "steady"], "icon": "📦", "title": "One address",
	 "text": "Two rents, two sets of everything, and most nights spent in one of the two flats. {p.first} has said the obvious thing out loud.",
	 "choices": [
		{"label": "Move in together",
		 "outcomes": [
			{"text": "We found somewhere that was neither of ours and made it both of ours.", "weight": 2, "relationship": {"p": 16}, "effects": {"happiness": 12, "money": -3000}, "bond": {"trust": 12, "obligation": 8}, "milestone": "moved in with their partner"},
			{"text": "We moved in, and within four months discovered how differently we each think a kitchen should work.", "weight": 1, "relationship": {"p": 2}, "effects": {"stress": 12, "money": -3000}, "bond": {"resentment": 10}, "milestone": "moved in with their partner"}]},
		{"label": "Keep your own place",
		 "outcomes": [
			{"text": "We kept both. It costs more and it has probably saved us twice.", "weight": 2, "relationship": {"p": 4}, "effects": {"money": -1200}},
			{"text": "Keeping my own place was read as keeping an exit, which, on the honest days, it was.", "weight": 1, "relationship": {"p": -12}, "bond": {"trust": -8, "resentment": 12}}]},
		{"label": "Ask what {p.he} actually wants",
		 "outcomes": [
			{"text": "It turned out {p.he} had been asking a smaller question than I had heard, and the answer was easy.", "weight": 2, "relationship": {"p": 12}, "bond": {"trust": 14}},
			{"text": "Asking properly surfaced a much bigger conversation about where either of us thought this was going.", "weight": 1, "relationship": {"p": -5}, "effects": {"stress": 12}, "bond": {"trust": 6}}]}]},
	{"id": "r_first_fight", "stage": ["settling", "steady"], "icon": "💬", "title": "The first real one",
	 "text": "Not a disagreement. The first argument where both of you say something you have been saving.",
	 "choices": [
		{"label": "Stay in the room and finish it",
		 "outcomes": [
			{"text": "We stayed up until it was actually finished. Something in us is stronger than it was at the start of the evening.", "weight": 2, "relationship": {"p": 14}, "effects": {"stress": 8, "happiness": 6}, "bond": {"trust": 16}},
			{"text": "We finished it and I learned something about myself I would rather not have had said to me.", "weight": 1, "relationship": {"p": 6}, "effects": {"stress": 14, "happiness": -6}, "bond": {"trust": 8}}]},
		{"label": "Walk out and cool off",
		 "outcomes": [
			{"text": "I went round the block eleven times and came back able to talk. That was the right call.", "weight": 2, "relationship": {"p": 6}, "bond": {"trust": 6}},
			{"text": "Walking out was the thing {p.he} could not stand, and it became its own argument on top of the first one.", "weight": 1, "relationship": {"p": -14}, "effects": {"stress": 15}, "bond": {"resentment": 14}}]},
		{"label": "Say whatever wins it",
		 "outcomes": [
			{"text": "I won. I have thought about what I said for a very long time since.", "weight": 2, "relationship": {"p": -18}, "effects": {"karma": -6, "stress": 10}, "bond": {"resentment": 18, "affection": -10}},
			{"text": "I went for the throat and {p.he} did not fight back at all, which was worse than if {p.he} had.", "weight": 1, "relationship": {"p": -22}, "effects": {"happiness": -10, "karma": -8}, "bond": {"resentment": 22, "trust": -14}}]}]},

	# ---- steady
	{"id": "r_proposal_talk", "stage": ["steady", "long"], "icon": "💍", "title": "The question about the question",
	 "text": "Somebody at a wedding asked when it would be your turn, and neither of you had an answer ready.",
	 "conditions": {"married": false},
	 "choices": [
		{"label": "Decide together, properly",
		 "outcomes": [
			{"text": "We talked about it for two hours in a car park and came out of it agreed.", "weight": 2, "relationship": {"p": 16}, "effects": {"happiness": 10}, "bond": {"trust": 14, "romance": 10}},
			{"text": "We talked about it and found out we want different things, and now we both know that.", "weight": 1, "relationship": {"p": -8}, "effects": {"stress": 14}, "bond": {"trust": 8, "resentment": 8}}]},
		{"label": "Let it lie",
		 "outcomes": [
			{"text": "Neither of us needed it to be a question. We are what we are.", "weight": 2, "relationship": {"p": 4}},
			{"text": "Letting it lie was my idea, and {p.he} had been waiting years for somebody to pick it up.", "weight": 1, "relationship": {"p": -14}, "bond": {"resentment": 16}}]},
		{"label": "Ask {p.him}",
		 "outcomes": [
			{"text": "I asked in a car park, badly, with no ring, and {p.he} said yes before I finished.", "weight": 2, "relationship": {"p": 25}, "effects": {"happiness": 20}, "marry": true, "bond": {"romance": 20, "trust": 14}, "milestone": "proposed in a car park"},
			{"text": "I asked and {p.he} said {p.he} needed time, and took it, and I had to live in that fortnight.", "weight": 1, "relationship": {"p": -6}, "effects": {"stress": 20, "happiness": -10}, "bond": {"resentment": 6}}]}]},
	{"id": "r_dull", "stage": ["steady", "long"], "icon": "🛋️", "title": "The same Tuesday",
	 "text": "You have had this exact evening perhaps four hundred times. Neither of you is unhappy. Neither of you is anything much.",
	 "choices": [
		{"label": "Change something",
		 "outcomes": [
			{"text": "We booked a thing neither of us would have picked and it was the best weekend in five years.", "weight": 2, "relationship": {"p": 14}, "effects": {"happiness": 12, "money": -900}, "bond": {"romance": 14}},
			{"text": "I tried to change it and {p.he} did not want it changed, and being the one who wanted more was lonely.", "weight": 1, "relationship": {"p": -6}, "effects": {"happiness": -8}, "bond": {"resentment": 8}}]},
		{"label": "Decide this is fine",
		 "outcomes": [
			{"text": "It is fine. Four hundred quiet Tuesdays is a thing most people do not get.", "weight": 2, "effects": {"happiness": 5, "stress": -6}, "bond": {"affection": 6}},
			{"text": "I decided it was fine for another nine years and then decided it had not been.", "weight": 1, "relationship": {"p": -10}, "effects": {"happiness": -10}, "bond": {"romance": -14}}]},
		{"label": "Say it out loud",
		 "outcomes": [
			{"text": "I said I was bored and that it was not {p.his} fault, and {p.he} said {p.he} had been waiting for one of us to say it.", "weight": 2, "relationship": {"p": 12}, "bond": {"trust": 16, "romance": 8}},
			{"text": "Saying it out loud was heard as something much worse than I meant, and it took a year to put back.", "weight": 1, "relationship": {"p": -16}, "effects": {"stress": 16}, "bond": {"resentment": 14}}]}]},

	# ---- long
	{"id": "r_history", "stage": ["long", "lifelong"], "icon": "📼", "title": "Somebody else's memory",
	 "text": "{p.first} tells a story about something you both did, and {p.his} version of it is not yours. It is not close.",
	 "choices": [
		{"label": "Let {p.him} have it",
		 "outcomes": [
			{"text": "I let the story stand. It is a better story {p.his} way and I am in it either way.", "weight": 2, "relationship": {"p": 8}, "effects": {"happiness": 5}, "bond": {"affection": 8}},
			{"text": "I let it stand, and heard it told that way for another twenty years, and it stopped being funny.", "weight": 1, "relationship": {"p": -4}, "bond": {"resentment": 6}}]},
		{"label": "Correct {him}",
		 "outcomes": [
			{"text": "I corrected {p.him} in front of everybody. I was right and it was not worth it.", "weight": 2, "relationship": {"p": -10}, "bond": {"resentment": 10}},
			{"text": "I corrected {p.him} and {p.he} thought about it and said I was right, and that {p.he} had been telling it wrong for years.", "weight": 1, "relationship": {"p": 6}, "bond": {"trust": 8}}]},
		{"label": "Ask why {p.he} remembers it that way",
		 "outcomes": [
			{"text": "Because of something that happened that day that I never knew about. Thirty years and there was still one left.", "weight": 2, "relationship": {"p": 16}, "effects": {"happiness": 10}, "bond": {"trust": 16, "affection": 10}},
			{"text": "{p.He} did not know why and found the question upsetting, and I wish I had left it.", "weight": 1, "relationship": {"p": -6}, "effects": {"stress": 8}}]}]},
	{"id": "r_illness_care", "stage": ["long", "lifelong"], "icon": "🩺", "title": "The one who is ill",
	 "text": "{p.first} has been unwell for a while now, and the doctors have stopped talking about getting better and started talking about managing it.",
	 "choices": [
		{"label": "Be the one who does it",
		 "outcomes": [
			{"text": "I do the appointments, the medicines and the nights. It is the hardest and least complicated thing I have ever done.", "weight": 2, "relationship": {"p": 25}, "effects": {"stress": 22, "happiness": -6, "karma": 15}, "bond": {"affection": 20, "obligation": 15}},
			{"text": "I said I would do all of it and then found out what all of it is, and I have not always been kind about it.", "weight": 1, "relationship": {"p": 12}, "effects": {"stress": 30, "health": -8, "happiness": -12}, "bond": {"obligation": 20, "resentment": 8}}]},
		{"label": "Get help in",
		 "outcomes": [
			{"text": "A carer three mornings a week, which meant I could still be a partner rather than only a nurse.", "weight": 2, "relationship": {"p": 14}, "effects": {"money": -22000, "stress": 8}, "bond": {"affection": 10}},
			{"text": "{p.He} hated having a stranger in the house and said so every single morning.", "weight": 1, "relationship": {"p": -6}, "effects": {"money": -22000, "stress": 16}, "bond": {"resentment": 10}}]},
		{"label": "Ask {p.him} what {p.he} wants",
		 "outcomes": [
			{"text": "{p.He} wanted to be at home, and to be asked, and to not be talked about in the third person. So that is what we did.", "weight": 2, "relationship": {"p": 22}, "effects": {"karma": 12, "stress": 14}, "bond": {"trust": 20, "affection": 15}},
			{"text": "What {p.he} wanted was for none of it to be happening, and there was nothing in that I could give {p.him}.", "weight": 1, "relationship": {"p": 8}, "effects": {"stress": 20, "happiness": -12}}]}]},
]


func _beat_done(id: String) -> bool:
	return bool((st().get("beats", {}) as Dictionary).get(id, false))


func yearly() -> void:
	var p := _p()
	var s := st()
	if s.is_empty() or not GameState.is_alive():
		return
	var pid := str(p.get("partner", ""))
	# keep the clock honest
	if pid == "":
		if str(s.get("partner", "")) != "":
			ended()
		return
	if str(s.get("partner", "")) != pid:
		began(pid, str(GameState.npcs.get(pid, {}).get("relation", "")))
		return
	s["years"] = int(s.get("years", 0)) + 1
	var h := health()
	if h >= 70.0:
		s["high"] = int(s.get("high", 0)) + 1
	elif h <= 30.0:
		s["low"] = int(s.get("low", 0)) + 1

	var age := int(p.get("age", 0))
	if age - int(s.get("last_beat", -99)) < 2:
		return
	# A relationship should produce something most years, especially early on.
	var chance := 0.55 if stage() == "new" else 0.42
	if randf() > chance:
		return
	var sg := stage()
	var pool: Array = []
	for b in BEATS:
		if _beat_done(str(b["id"])):
			continue
		if not (b["stage"] as Array).has(sg):
			continue
		var c: Dictionary = b.get("conditions", {})
		if c.has("married") and bool(c["married"]) != (str(p.get("partner_status", "")) == "married"):
			continue
		pool.append(b)
	if pool.is_empty():
		return
	var pick: Dictionary = (pool[randi() % pool.size()] as Dictionary).duplicate(true)
	(s["beats"] as Dictionary)[str(pick["id"])] = true
	s["last_beat"] = age
	pick["roles"] = {"p": {"id": pid}}
	EventEngine.push_decision(pick, {"p": pid})


func summary_lines() -> Array:
	var s := st()
	if s.is_empty() or str(s.get("partner", "")) == "":
		return []
	var pid := str(s["partner"])
	if not GameState.npcs.has(pid):
		return []
	return [["💞 %s · %d year%s" % [stage_name(), years(), "" if years() == 1 else "s"],
		"Going %s" % word()]]
