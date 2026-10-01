extends Node

## ARCS — a life path is a road with chapters and an end, not a set of buttons.
##
## Vampire and the undead got this in v0.11: a shape to the life, and a death
## that meant something. The other six paths — Royal, Witch, Gifted, Pirate,
## Colonist and Time Traveler — had entry routes and a handful of actions, and
## then nothing, so one pirate life ended exactly like another.
##
## Each path now has five chapters that open on what the player has actually
## done (not on the calendar), a turning-point event for each, and a set of
## endings that is picked at death from the life as it ended. The ending is
## written into the life story, the tombstone, and the achievements.
##
## A need is [field, op, value]. A bare field is read from the path's life
## record; "c:name" is a lifetime counter; "p:name" is a player field.

const ARCS := {
	"pirate": {
		"title": "The Pirate's Road", "icon": "🏴‍☠️",
		"chapters": [
			{"id": "first_blood", "title": "First blood on the water", "blurb": "Raid your first ship.", "need": [["raids", ">=", 1]]},
			{"id": "price", "title": "A price on your head", "blurb": "Let the bounty climb to 30.", "need": [["bounty", ">=", 30]]},
			{"id": "the_map", "title": "The map that was real", "blurb": "Follow two treasure maps to the end.", "need": [["maps", ">=", 2]]},
			{"id": "fleet", "title": "Captain", "blurb": "Rise to Captain.", "need": [["rank", ">=", 3]]},
			{"id": "legend", "title": "A name the harbours sing", "blurb": "Become a Sea Legend with a hold worth the name.", "need": [["rank", ">=", 4], ["treasure", ">=", 60000]]},
		],
		"endings": [
			{"id": "sea_legend", "title": "Sea Legend", "need": [["rank", ">=", 4]], "epitaph": "The harbours still sing it wrong.", "text": "They made a song of the ship and got the name wrong in the second verse. Everyone who sailed with them sings it the right way, and quietly."},
			{"id": "hanged", "title": "The Gallows", "need": [["bounty", ">=", 85]], "epitaph": "Hanged at the dock, to a good crowd.", "text": "The price on the head was finally collected. A crowd came to the dock, as they always do, and some of them wept."},
			{"id": "mutiny", "title": "Mutinied Off", "need": [["mutinies", ">=", 2]], "epitaph": "Betrayed by those they fed.", "text": "A captain who loses the crew twice has not lost a ship. They have lost the argument about what a ship is for."},
			{"id": "retired_rich", "title": "Retired with the Hold", "need": [["treasure", ">=", 120000]], "epitaph": "Got out with the gold and the knees.", "text": "A cottage above a harbour, a boat for fishing and no one asking where the money came from. They told the neighbours they'd been in shipping."},
			{"id": "sea_grave", "title": "The Sea Has the Rest", "need": [], "epitaph": "The sea has the rest.", "text": "No stone, no grave, and no one quite sure where. The charts have a small gap."},
		],
	},
	"colonist": {
		"title": "Under Glass", "icon": "🪐",
		"chapters": [
			{"id": "first_winter", "title": "The first year under the dome", "blurb": "Complete a mission for the colony.", "need": [["missions", ">=", 1]]},
			{"id": "out_there", "title": "Something out there", "blurb": "Make two discoveries on the surface.", "need": [["discoveries", ">=", 2]]},
			{"id": "council", "title": "A voice on the council", "blurb": "Reach 40 influence.", "need": [["influence", ">=", 40]]},
			{"id": "signal", "title": "The signal answers", "blurb": "Raise the signal analysis to 60%.", "need": [["contact", ">=", 60]]},
			{"id": "founder", "title": "A name on the founders' wall", "blurb": "Become Colony Founder.", "need": [["rank", ">=", 4]]},
		],
		"endings": [
			{"id": "contact", "title": "First Contact", "need": [["contact", ">=", 100]], "epitaph": "Heard it first, and answered.", "text": "History will argue about who understood the signal first. The colony records say one name, and it is on this stone."},
			{"id": "founder", "title": "Founder of Ares Haven", "need": [["rank", ">=", 4]], "epitaph": "The dome is their monument.", "text": "The dome was extended twice in their lifetime, and a third time in their name. The children born there do not know it was ever small."},
			{"id": "lost_colony", "title": "The Dome Failed", "need": [["oxygen", "<=", 12]], "epitaph": "Held the door until the air ran out.", "text": "The seals failed in the night, and what mattered after that was who stayed. They stayed."},
			{"id": "elder", "title": "Council Elder", "need": [["influence", ">=", 70]], "epitaph": "Voted, and was heard.", "text": "A generation grew up taking the council for granted, because someone had once built it carefully."},
			{"id": "dome_grave", "title": "Buried Under Another Sky", "need": [], "epitaph": "Buried under a different sky.", "text": "Red dust, a small marker and a view of a very small sun. It was a life on the edge of the possible, and it was theirs."},
		],
	},
	"traveler": {
		"title": "Borrowed Time", "icon": "⌛",
		"chapters": [
			{"id": "fitting_in", "title": "Fitting in", "blurb": "Raise your cover to 70.", "need": [["cover", ">=", 70]]},
			{"id": "first_jump", "title": "The first jump", "blurb": "Travel through time once.", "need": [["jumps", ">=", 1]]},
			{"id": "collector", "title": "A collector of what was", "blurb": "Document three artifacts.", "need": [["artifacts", ">=", 3]]},
			{"id": "edge", "title": "Close to the edge", "blurb": "Let paradox reach 50.", "need": [["paradox", ">=", 50]]},
			{"id": "which_home", "title": "Which year is home?", "blurb": "Jump five times.", "need": [["jumps", ">=", 5]]},
		],
		"endings": [
			{"id": "erased", "title": "Erased", "need": [["paradox", ">=", 100]], "epitaph": "No longer on the records.", "text": "The timeline closed over the gap. People who loved them remember a vague, pleasant person who was hard to picture."},
			{"id": "historian", "title": "The Quiet Historian", "need": [["artifacts", ">=", 8]], "epitaph": "Kept what was, carefully.", "text": "A collection that did not belong to any year, catalogued in a hand that did not belong to any of them either. It was left, with no note, to a library."},
			{"id": "stranded", "title": "Stranded", "need": [["charge", "<=", 10]], "epitaph": "Chose a year and stayed.", "text": "The device ran down in a year that was perfectly pleasant. They did not try very hard to find a way back."},
			{"id": "wanderer", "title": "Out of Step", "need": [], "epitaph": "Born later than this stone admits.", "text": "They were never quite in step with the year they were in. Nobody could ever say why."},
		],
	},
	"royal": {
		"title": "The Crown", "icon": "👑",
		"chapters": [
			{"id": "line", "title": "A place in the line", "blurb": "Keep your respect above 55.", "need": [["respect", ">=", 55]]},
			{"id": "decree", "title": "The first decree", "blurb": "Issue a decree.", "need": [["decrees", ">=", 1]]},
			{"id": "crown", "title": "The crown", "blurb": "Be crowned.", "need": [["crowned", "==", true]]},
			{"id": "ten", "title": "Ten years on the throne", "blurb": "Reign for a decade.", "need": [["reign", ">=", 10]]},
			{"id": "remembered", "title": "A reign remembered", "blurb": "Reign for 25 years with respect above 70.", "need": [["reign", ">=", 25], ["respect", ">=", 70]]},
		],
		"endings": [
			{"id": "beloved", "title": "A Reign Remembered", "need": [["reign", ">=", 25], ["respect", ">=", 70]], "epitaph": "Wore it, and was worth it.", "text": "The people lined the road for four miles. Several said they had expected to feel nothing, and had been wrong."},
			{"id": "deposed", "title": "Deposed", "need": [["overthrown", "==", true]], "epitaph": "The crown outlasted them.", "text": "They were removed on a cold morning by people who had once bowed. History has been unkind, and may yet be corrected."},
			{"id": "abdicated", "title": "Abdicated", "need": [["abdicated", "==", true]], "epitaph": "Put it down, and lived.", "text": "They took off the crown on their own terms and handed it to someone who wanted it more. It was the bravest thing in a very public life."},
			{"id": "brief", "title": "A Short Reign", "need": [["crowned", "==", true]], "epitaph": "Wore it, for a while.", "text": "The reign was short and the funeral was long. Historians call it a transition."},
			{"id": "uncrowned", "title": "Never Crowned", "need": [], "epitaph": "Born near it. Never wore it.", "text": "A life lived within sight of the throne, and a hundred small decisions about whether to reach for it."},
		],
	},
	"witch": {
		"title": "The Craft", "icon": "🧙",
		"chapters": [
			{"id": "first_spell", "title": "The first spell", "blurb": "Cast a spell.", "need": [["spells", ">=", 1]]},
			{"id": "circle", "title": "A circle of your own", "blurb": "Gather a coven of two or more.", "need": [["coven_n", ">=", 2]]},
			{"id": "grimoire", "title": "The working grimoire", "blurb": "Cast twenty spells.", "need": [["spells", ">=", 20]]},
			{"id": "almost", "title": "Almost found out", "blurb": "Let exposure reach 50.", "need": [["exposure", ">=", 50]]},
			{"id": "mother", "title": "Mother of the coven", "blurb": "Lead a coven of four, and cast sixty spells.", "need": [["coven_n", ">=", 4], ["spells", ">=", 60]]},
		],
		"endings": [
			{"id": "burned", "title": "Found Out", "need": [["exposure", ">=", 95]], "epitaph": "They had the right name, eventually.", "text": "The town came for them with lanterns. The coven scattered. The garden went on blooming for years in the places they had touched."},
			{"id": "ascended", "title": "Ascended", "need": [["spells", ">=", 120]], "epitaph": "Left the room and the weather changed.", "text": "People who were there describe a stillness. The candles did not gutter. The kettle on the stove began to sing a note nobody had heard it sing before."},
			{"id": "matriarch", "title": "Matriarch of the Coven", "need": [["coven_n", ">=", 4]], "epitaph": "Taught what they knew.", "text": "The coven met at the kitchen table for decades, and at the funeral they set a place for her. The tea went cold, then was drunk."},
			{"id": "hedge", "title": "A Hedge Witch", "need": [], "epitaph": "Mended what they could.", "text": "A cottage, a garden, and a long list of people who had come to the door with a problem and gone away with something in a jar."},
		],
	},
	"pet": {
		"title": "A Good Animal", "icon": "🐾",
		"chapters": [
			{"id": "trust", "title": "Somebody's", "blurb": "Let one person become yours: bond 40.", "need": [["bond", ">=", 40]]},
			{"id": "known", "title": "The shape of the place", "blurb": "Learn your territory to 45, and three tricks.", "need": [["territory", ">=", 45], ["tricks_n", ">=", 3]]},
			{"id": "calling", "title": "What you are for", "blurb": "Choose a calling.", "need": [["role_set", "==", true]]},
			{"id": "test", "title": "The test", "blurb": "Be brave once, or win something, or survive something.", "need_any": [["heroics", ">=", 1], ["titles", ">=", 1], ["rescues", ">=", 1], ["escapes", ">=", 3]]},
			{"id": "evening", "title": "The long evening", "blurb": "Grow old and be loved: reach the senior years with a bond over 60.", "need": [["senior", "==", true], ["bond", ">=", 60]]},
		],
		"endings": [
			{"id": "pet_lost", "title": "Never Came Home", "need": [["lost", "==", true]], "epitaph": "Went looking, and kept going.", "text": "There is a poster on a lamp post with a photograph that is slightly too bright. It stayed up for two winters. Somebody left a bowl by the back step for another year, just in case."},
			{"id": "pet_hero", "title": "A Hero", "need": [["heroics", ">=", 3]], "epitaph": "Did the brave thing, and then had a biscuit.", "text": "The local paper ran a photograph and a headline that had a pun in it. The family framed it. The pet, it is thought, would have wanted the biscuit."},
			{"id": "pet_champion", "title": "Best in Show", "need": [["titles", ">=", 2]], "epitaph": "Held the ribbon, and the room.", "text": "The rosettes went up on the wall in a long, slightly crooked line, and each of them was dusted every spring for as long as the house had a wall."},
			{"id": "pet_stray_king", "title": "Lord of the Alley", "need": [["territory", ">=", 80], ["home", "==", "street"]], "epitaph": "Nobody's, and everyone's.", "text": "Three streets, two restaurants and a bakery's back door were arranged around them. When they went, the whole block seemed to hold its breath for a moment, and then a younger one stepped into the doorway."},
			{"id": "pet_best_friend", "title": "Best Friend", "need": [["bond", ">=", 85], ["belonging", ">=", 70]], "epitaph": "Somebody's whole world.", "text": "The collar still hangs on the hook by the door. Nobody has moved it, and nobody has said they're not going to."},
			{"id": "pet_sunbeam", "title": "A Long, Warm Life", "need": [["senior", "==", true], ["bond", ">=", 55]], "epitaph": "Old, loved, and exactly where they wanted to be.", "text": "The last years were mostly sun, sleep and being carried up the stairs. It was, everyone agreed, a good way to be old."},
			{"id": "pet_good", "title": "A Good Life", "need": [], "epitaph": "Short, as they all are, and good.", "text": "A life is the length it is. This one was full of walks, in the sense that matters, and of someone's hand on a warm head."},
		],
	},
	"prisoner": {
		"title": "Time", "icon": "⛓️",
		"chapters": [
			{"id": "fish", "title": "Fresh fish", "blurb": "Survive your first year inside.", "need": [["served", ">=", 1]]},
			{"id": "side", "title": "Whose side?", "blurb": "Find protection: join a gang, or reach respect 40 on your own.", "need_any": [["gang_rank", ">=", 1], ["respect", ">=", 40]]},
			{"id": "hope", "title": "Something to hope for", "blurb": "Finish a programme, start a plan, or build an appeal.", "need_any": [["programs_n", ">=", 1], ["escape", ">=", 1], ["appeal", ">=", 30]]},
			{"id": "walls", "title": "The test of the walls", "blurb": "Live through a riot, an attack or the hole.", "need_any": [["riots", ">=", 1], ["attacks", ">=", 1], ["solitary_years", ">=", 1]]},
			{"id": "door", "title": "The door", "blurb": "Get as near the outside as it gets: a hearing, a plan that is ready, or an appeal nearly won.", "need_any": [["hearings", ">=", 1], ["escape", ">=", 4], ["appeal", ">=", 70]]},
		],
		"endings": [
			{"id": "pr_exonerated", "title": "Exonerated", "need": [["exonerated", "==", true]], "epitaph": "The truth took years. It arrived.", "text": "The court said it plainly, in front of people who had said the opposite. There was a sum of money and a handshake and a long, dull argument about what an apology is. They went home to a town that had changed its roads."},
			{"id": "pr_ghost", "title": "A Ghost", "need": [["escaped", "==", true]], "epitaph": "Out, and never found.", "text": "A different name in a different town, a window onto a field, and a habit, kept for the rest of their life, of sitting where they could see the door. The file stayed open. Nobody was ever sent."},
			{"id": "pr_fallen", "title": "The Other Side of the Door", "need": [["ex_guard", "==", true]], "epitaph": "Knew the building from both sides.", "text": "They knew every lock by sound and every officer by name. So did everyone else. It was a long sentence in a building that remembered exactly who they had been, and what the badge had meant."},
			{"id": "pr_returned", "title": "Back Inside", "need": [["outcome", "==", "returned"]], "epitaph": "The door was never the hard part.", "text": "Free for a season, with a key, a job interview and a name on a list that had nothing to do with the building. Then a missed appointment, an old friend, a car in the street. The corridor was familiar, and so was the sound of the door."},
			{"id": "pr_paroled", "title": "Paroled", "need": [["outcome", "==", "paroled"]], "epitaph": "A board believed them.", "text": "The envelope was read aloud twice. There were conditions and a curfew and an officer to report to. They kept every one, and never went back."},
			{"id": "pr_served", "title": "Every Day of It", "need": [["outcome", "==", "served"]], "epitaph": "Nobody gave them anything.", "text": "The gate opened at 7.40 on a Tuesday, with a clear plastic bag and a travel warrant. Nobody had given them anything. They walked to the bus stop without looking back, and then, at the corner, they did."},
			{"id": "pr_legend", "title": "Old Head", "need": [["respect", ">=", 85]], "epitaph": "The block is quieter without them.", "text": "Three wings knew the name and one of them was named for it. When it was over there was a silence on the landing, which, by the standards of the building, was a eulogy."},
			{"id": "pr_died", "title": "Never Out", "need": [], "epitaph": "The building kept them.", "text": "A number on a form and a name in a chaplain's notebook. A letter went to the address on file. The cell was cleaned, and by the end of the month it had someone else in it."},
		],
	},
	"guard": {
		"title": "The Keys", "icon": "🗝️",
		"chapters": [
			{"id": "probation", "title": "Probation", "blurb": "Complete your first year on the staff.", "need": [["served", ">=", 1]]},
			{"id": "incident", "title": "The first incident", "blurb": "Handle a real incident on the wing.", "need": [["incidents", ">=", 1]]},
			{"id": "kind", "title": "What kind of officer", "blurb": "Show what you are: take a favour, earn a commendation, use force you cannot justify, or tell.", "need_any": [["corruption", ">=", 1], ["commend", ">=", 1], ["force_bad", ">=", 1], ["whistle", "==", true]]},
			{"id": "stripes", "title": "Stripes", "blurb": "Become a Sergeant.", "need": [["rank", ">=", 3]]},
			{"id": "long_shift", "title": "The long shift", "blurb": "Reach Captain, or give the service fifteen years.", "need_any": [["rank", ">=", 5], ["served", ">=", 15]]},
		],
		"endings": [
			{"id": "gd_warden", "title": "Warden", "need": [["outcome", "==", "warden"]], "epitaph": "Ran the building. It ran them.", "text": "The office was bigger than it looked from outside, and quieter. They signed the last order and gave the keys, one at a time, to the officer who was ready."},
			{"id": "gd_whistle", "title": "Whistleblower", "need": [["whistle", "==", true]], "epitaph": "Told, and paid for it.", "text": "It cost them the union, the pension and the table in the canteen. Eleven years later a government inquiry used the word 'vindicated', and a young officer, who had never heard the story, wrote them a letter."},
			{"id": "gd_kingpin", "title": "The Man With the Keys", "need": [["corruption", ">=", 5]], "epitaph": "Nothing came in without a price.", "text": "A bungalow, a boat, and a habit of looking at the horizon. There was never a charge. The wing, however, kept an exact record, and told the story for years."},
			{"id": "gd_hero", "title": "Hero of the Wing", "need": [["commend", ">=", 3]], "epitaph": "Was there when it counted.", "text": "Three commendations, one of them framed. Men who had been in their custody came to the funeral and stood at the back with their hats in their hands."},
			{"id": "gd_fired", "title": "Dismissed", "need": [["outcome", "==", "fired"]], "epitaph": "A box and an escort to the car park.", "text": "A cardboard box, a lanyard and a walk past people who found the floor interesting. They stood by the car for a long time, with the door open, and no idea at all of where to go."},
			{"id": "gd_burned", "title": "Burned Out", "need": [["trauma", ">=", 80]], "epitaph": "Did the time on the other side.", "text": "They stopped sleeping, and then stopped noticing they didn't. The service sent a letter. A friend sent a better one. It was, in the end, the second that got answered."},
			{"id": "gd_retired", "title": "Thirty Years", "need": [["outcome", "==", "retired"]], "epitaph": "A clock, a pension, a habit of facing the door.", "text": "A cake, a card signed by people who did not mean it equally, a clock. The keys went into a drawer. For the rest of their life they sat with their back to the wall in every restaurant."},
			{"id": "gd_duty", "title": "In the Line of Duty", "need": [], "epitaph": "Their name is on the wall in the hall.", "text": "The flag was lowered. The wing was quiet for a full minute, which has never happened before or since. There is a plaque in the corridor, and officers touch it on the way past."},
		],
	},
	"super": {
		"title": "The Mask", "icon": "🦸",
		"chapters": [
			{"id": "first", "title": "The first night out", "blurb": "Make a save or a heist.", "need": [["saves_heists", ">=", 1]]},
			{"id": "alias", "title": "An alias that sticks", "blurb": "Raise your reputation to 20.", "need": [["rep", ">=", 20]]},
			{"id": "nemesis", "title": "A nemesis", "blurb": "Draw an enemy of your own.", "need": [["has_nemesis", "==", true]]},
			{"id": "unmasked", "title": "Unmasked or untouchable", "blurb": "Be revealed, or reach power 60.", "need_any": [["revealed", "==", true], ["power", ">=", 60]]},
			{"id": "legend", "title": "A legend in the city", "blurb": "Reach reputation 70.", "need": [["rep", ">=", 70]]},
		],
		"endings": [
			{"id": "icon", "title": "An Icon", "need": [["side", "==", "hero"], ["rep", ">=", 70]], "epitaph": "The city kept the cape.", "text": "A mural went up before the funeral. It was repainted twice, by different hands, and nobody complained about the differences."},
			{"id": "infamous", "title": "Infamous", "need": [["side", "==", "villain"], ["rep", ">=", 70]], "epitaph": "Feared, which is a kind of remembered.", "text": "Parents used the alias to frighten children for forty years. Then somebody made a documentary and it became fashionable to be fond of it."},
			{"id": "unmasked_fall", "title": "Unmasked", "need": [["revealed", "==", true]], "epitaph": "The mask came off. The person stayed.", "text": "The day the face was shown was the day the city had to decide what it thought. It took a decade."},
			{"id": "quiet", "title": "A Quiet Hero", "need": [], "epitaph": "Did it, mostly without being seen.", "text": "A handful of people knew. They kept the secret, and each of them told the story to somebody they trusted, and so on."},
		],
	},
}


## Gauges that live between 0 and 100.
const CLAMPED := ["oxygen", "rations", "morale", "hull", "charge", "cover", "paradox", "suspicion", "mana", "exposure", "respect", "power", "bounty", "contact", "influence"]


func _p() -> Dictionary:
	return GameState.player


func kind() -> String:
	return Lives.kind()


func has_arc() -> bool:
	return ARCS.has(kind())


func st() -> Dictionary:
	var l := Lives.life()
	if l.is_empty() or not ARCS.has(kind()):
		return {}
	if not l.has("arc") or not (l["arc"] is Dictionary):
		l["arc"] = {"chapter": 0, "reached": []}
	return l["arc"]


## One value out of the life record, with a few derived fields.
func _val(field: String):
	var l := Lives.life()
	if field.begins_with("c:"):
		return GameState.get_counter(field.substr(2))
	if field.begins_with("p:"):
		return _p().get(field.substr(2), 0)
	match field:
		"coven_n": return Array(l.get("coven", [])).size()
		"saves_heists": return int(l.get("saves", 0)) + int(l.get("heists", 0))
		"has_nemesis": return str(l.get("nemesis", "")) != ""
		"overthrown": return bool(l.get("overthrown", false)) or GameState.has_flag("overthrown")
		"tricks_n": return Array(l.get("tricks", [])).size()
		"programs_n": return Array(l.get("programs", [])).size() if kind() == "prisoner" else 0
		"senior": return Pets.is_senior() if kind() == "pet" else false
		"lost": return bool(l.get("lost", false))
	return l.get(field, 0)


func _met(needs: Array) -> bool:
	for n in needs:
		var have = _val(str(n[0]))
		var want = n[2]
		match str(n[1]):
			">=": if not (float(have) >= float(want)): return false
			"<=": if not (float(have) <= float(want)): return false
			"==":
				if want is bool:
					if bool(have) != bool(want): return false
				elif str(have) != str(want):
					return false
	return true


func _chapter_met(ch: Dictionary) -> bool:
	if ch.has("need_any"):
		for n in ch["need_any"]:
			if _met([n]):
				return true
		return false
	return _met(ch.get("need", []))


func chapters() -> Array:
	return ARCS.get(kind(), {}).get("chapters", [])


func current_index() -> int:
	return int(st().get("chapter", 0))


## Called each year after the path's own yearly pass. Opens every chapter whose
## needs are met, in order, and queues the turning-point event for each.
func yearly() -> void:
	var s := st()
	if s.is_empty():
		return
	var chs := chapters()
	var guard := 0
	while int(s["chapter"]) < chs.size() and guard < 5:
		guard += 1
		var ch: Dictionary = chs[int(s["chapter"])]
		if not _chapter_met(ch):
			break
		_open(ch)


func _open(ch: Dictionary) -> void:
	var s := st()
	var idx := int(s["chapter"])
	s["chapter"] = idx + 1
	s["reached"].append(str(ch["id"]))
	GameState.counter("arc_" + kind())
	var n := idx + 1
	GameState.add_milestone(int(_p()["age"]), "reached chapter %d of %s: %s" % [n, str(ARCS[kind()]["title"]), str(ch["title"])])
	GameState.add_log("%s Chapter %d — %s." % [str(ARCS[kind()]["icon"]), n, str(ch["title"])])
	LifeThreads.remember(kind(), str(ch["title"]), str(ch["blurb"]), "", 55 + n * 6, [kind(), "chapter"])
	GameState.apply_effects({"happiness": 3 + n})
	var eid := "arc.%s.%d" % [kind(), n]
	if ContentDB.events_by_id.has(eid):
		EventEngine._enqueue(ContentDB.events_by_id[eid], {})


func status_line() -> Array:
	var s := st()
	if s.is_empty():
		return []
	var chs := chapters()
	var idx := int(s["chapter"])
	if idx >= chs.size():
		return ["%s The road is walked. What's left is how it ends." % str(ARCS[kind()]["icon"]), ""]
	var ch: Dictionary = chs[idx]
	return ["%s Chapter %d of %d — %s: %s" % [str(ARCS[kind()]["icon"]), idx + 1, chs.size(), str(ch["title"]), str(ch["blurb"])], ""]


func menu() -> Dictionary:
	var s := st()
	var rows: Array = []
	var info: Array = []
	if s.is_empty():
		return {"icon": "🛤️", "title": "Your road", "rows": rows, "info": ["Nothing in this life has a road yet."]}
	var a: Dictionary = ARCS[kind()]
	var chs := chapters()
	info.append("%s %s" % [str(a["icon"]), str(a["title"])])
	for i in range(chs.size()):
		var ch: Dictionary = chs[i]
		var done: bool = i < int(s["chapter"])
		var now: bool = i == int(s["chapter"])
		info.append("%s %d. %s — %s" % ["✓" if done else ("→" if now else "·"), i + 1, str(ch["title"]), str(ch["blurb"])])
	var e := ending()
	info.append("")
	info.append("If it ended today: %s." % str(e["title"]))
	return {"icon": str(a["icon"]), "title": "Your road", "rows": rows, "info": info}


# ------------------------------------------------------------------ the end

func ending() -> Dictionary:
	if not ARCS.has(kind()):
		return {}
	for e in ARCS[kind()]["endings"]:
		if _met(e.get("need", [])):
			return e
	return ARCS[kind()]["endings"][-1]


## A path that ends before the life does (an overthrown monarch, say) still
## gets its ending: it is written down at the moment the path is lost.
func freeze(reason: String) -> void:
	if not has_arc():
		return
	var l := Lives.life()
	if reason == "overthrown":
		l["overthrown"] = true
	elif reason == "abdicated":
		l["abdicated"] = true
	var e := ending()
	_p()["arc_frozen"] = {"id": str(e["id"]), "title": str(e["title"]), "text": str(e["text"]), "epitaph": str(e["epitaph"]), "path": kind(), "chapters": int(st().get("chapter", 0))}
	GameState.counter("ending_" + str(e["id"]))


## What goes into the legacy entry when the life is over.
func ending_entry() -> Dictionary:
	if _p().has("arc_frozen") and not has_arc():
		return _p()["arc_frozen"]
	if not has_arc():
		return {}
	var e := ending()
	if e.is_empty():
		return {}
	GameState.counter("ending_" + str(e["id"]))
	return {"id": str(e["id"]), "title": str(e["title"]), "text": str(e["text"]), "epitaph": str(e["epitaph"]), "path": kind(), "chapters": int(st().get("chapter", 0))}


## Outcome operations from authored events: {"bounty": 10, "morale": -5}.
func apply(ops: Dictionary) -> void:
	var l := Lives.life()
	if l.is_empty():
		return
	for k in ops.keys():
		var v = ops[k]
		if v is bool:
			l[k] = v
		elif v is String:
			l[k] = v
		else:
			l[k] = float(l.get(k, 0)) + float(v) if l.get(k, 0) is float else int(l.get(k, 0)) + int(v)
		if CLAMPED.has(k):
			l[k] = clampi(int(l[k]), 0, 100)


func tag(t: String) -> bool:
	var s := st()
	if s.is_empty():
		return false
	if t.begins_with("chapter:"):
		return int(s["chapter"]) >= int(t.substr(8))
	if t == "road_walked":
		return int(s["chapter"]) >= chapters().size()
	return false
