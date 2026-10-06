extends Node

## BECOME — every life path and every empire, as something you can go after.
##
## v0.11 took the life-path picker off the new-life screen because choosing
## "Vampire" before your first birthday told you the ending. That was right, but
## it left the other half undone: the only way in became waiting for the world to
## make you an offer. Wanting something and working for it is not the same as
## being found, and a game should let you do both.
##
## So this is the front door. Everything is listed, always, with what it needs
## spelled out. If you do not meet the conditions you can see exactly what is
## missing. If you do, you can apply — and applying is a roll, not a purchase.
## The paths with no prerequisites at all are the ordinary ones; the ones that
## rewrite your life ask for a great deal first.
##
## Destiny still works. Leads still accumulate, offers still arrive, and taking
## one is still the easier road. This is the harder one.

## kind: "life" routes through Lives/Expansion, "empire" starts a business-type
## venture, "career" hands off to a special career.
##
## need: what must be true. Every key is checked and reported.
##   age, smarts, looks, health, money, karma (min), karma_max, fame
##   licence, career, job_field, flag, stat_any, crimes, kids, partner
## odds: base chance of being accepted once you qualify.
const PATHS := {
	# ---- the supernatural. Expensive in prerequisites, because they end the
	#      ordinary life you have.
	"vampire": {
		"kind": "life", "icon": "🧛", "name": "Vampire",
		"blurb": "Ask the right questions in the wrong places for long enough and somebody answers.",
		"how": "Somebody has to want to turn you, and they only take people who will be worth the centuries.",
		"need": {"age": 16, "nightlife": 3, "looks": 45},
		"odds": 0.35, "cost": 0, "time": 3,
		"yes": "The one from the bar finally stopped deflecting. I do not remember the rest of that night and I have not been warm since.",
		"no": "They listened, and said no, and made it clear that asking again would not go well.",
	},
	"witch": {
		"kind": "life", "icon": "🧙", "name": "Witch",
		"blurb": "The books are real, most of them are wrong, and the difference takes years to learn.",
		"how": "You need to have read enough to know what you are looking at, and to have found somebody who will teach you.",
		"need": {"age": 14, "smarts": 55, "library": 4},
		"odds": 0.45, "cost": 2000, "time": 3,
		"yes": "I read it aloud and something in the room agreed with me. That was the first night of the rest of it.",
		"no": "Nothing happened. I sat in a circle of candles feeling like a fool, which is what I was.",
	},
	"super": {
		"kind": "life", "icon": "🦸", "name": "Gifted",
		"blurb": "Not everyone who volunteers for the trials comes out different. A few do.",
		"how": "It takes a body that can survive it and access to the sort of laboratory that runs these.",
		"need": {"age": 16, "health": 70, "smarts": 50, "gym": 4},
		"odds": 0.22, "cost": 0, "time": 4,
		"yes": "Whatever was in that room is in me now, and it is not going out again.",
		"no": "Nothing. Three days of tests and a headache and a form saying I had consented to it.",
	},
	"revenant": {
		"kind": "life", "icon": "🧟", "name": "Undead",
		"blurb": "You cannot rise until you have died. What you can do is arrange to be brought back.",
		"how": "Somebody has to owe you enough, or want something from you enough, to do the work after.",
		"need": {"age": 18, "karma_max": -20, "grudges": 1},
		"odds": 0.5, "cost": 0, "time": 3,
		"yes": "Whatever I agreed to, it does not take effect until the end. I have signed something I cannot read.",
		"no": "The person I asked laughed at me, and then stopped laughing, and then asked me to leave.",
	},
	"royal": {
		"kind": "life", "icon": "👑", "name": "Royal",
		"blurb": "There is always a line of succession and it is always longer than people think.",
		"how": "A genealogist, a great deal of money, and either fame or a marriage that puts you near it.",
		"need": {"age": 18, "money": 400000, "fame": 35},
		"odds": 0.25, "cost": 250000, "time": 4,
		"yes": "The claim held. It is a minor branch of a real house and it is mine.",
		"no": "The genealogist took my money and found a farmer. He was apologetic about it.",
	},
	"pirate": {
		"kind": "life", "icon": "🏴‍☠️", "name": "Pirate Life",
		"blurb": "A share, not a wage, on a ship whose paperwork does not bear looking at.",
		"how": "You need to be able to sail, and to have spent enough time on the water that somebody vouches for you.",
		"need": {"age": 18, "licence": "boating", "sea": 2, "health": 55},
		"odds": 0.55, "cost": 0, "time": 3,
		"yes": "I took the share. Nobody on that deck asked what I used to do.",
		"no": "They looked at my hands and said no. Apparently that is all it takes.",
	},
	"colonist": {
		"kind": "life", "icon": "🪐", "name": "Space Colonist",
		"blurb": "One way, for a long time, probably for good.",
		"how": "The programme takes pilots, engineers and doctors who are physically sound and have nobody they cannot leave.",
		"need": {"age": 21, "smarts": 70, "health": 75, "job_field": ["pilot", "engineer", "scientist", "doctor", "astronaut"]},
		"odds": 0.3, "cost": 0, "time": 5,
		"yes": "I took the seat. The last thing I saw of Earth was weather over an ocean I had never visited.",
		"no": "I did not make the shortlist. They were decent about telling me why: eleven better candidates.",
	},
	"traveler": {
		"kind": "life", "icon": "⌛", "name": "Time Traveler",
		"blurb": "The dates in the archive do not line up, and somebody has to follow that to the end of the shelf.",
		"how": "Very high smarts and a great many hours in places that keep records nobody checks.",
		"need": {"age": 18, "smarts": 85, "museum": 3},
		"odds": 0.18, "cost": 0, "time": 5,
		"yes": "I stepped through. The year on the newspaper was not the year I left.",
		"no": "I read the whole run. It was a filing error from 1911 and I have wasted four years.",
	},

	# ---- the lifestyles and ventures. Reachable, and mostly a matter of money,
	#      standing and nerve.
	"director": {
		"kind": "career", "icon": "🎬", "name": "Film Director",
		"blurb": "Somebody has to decide where the camera goes.",
		"how": "A film school or enough time on sets, and somebody willing to fund the first one.",
		"need": {"age": 20, "smarts": 45, "money": 25000},
		"odds": 0.5, "cost": 15000, "time": 3, "career_id": "director",
		"yes": "They greenlit it. It is small and it is mine and it starts shooting in the spring.",
		"no": "Everybody said the same thing: come back with something already made.",
	},
	"agent": {
		"kind": "career", "icon": "🕵️", "name": "Secret Agent",
		"blurb": "The people who do this were approached, and being approached can be arranged.",
		"how": "Clean record, sharp mind, a body that holds up, and a language or two.",
		"need": {"age": 21, "smarts": 65, "health": 65, "clean": true},
		"odds": 0.28, "cost": 0, "time": 4, "career_id": "agent",
		"yes": "The interview was four days long and about half of it was a test I did not know I was taking. I passed.",
		"no": "They thanked me for my interest. That was the entire response.",
	},
	"racer": {
		"kind": "career", "icon": "🏎️", "name": "Racing Driver",
		"blurb": "Seat time is the whole thing, and seat time costs money.",
		"how": "A licence, a car, and enough saved to buy a season before anybody pays you for one.",
		"need": {"age": 17, "licence": "driver", "money": 60000, "health": 60},
		"odds": 0.45, "cost": 45000, "time": 3, "career_id": "racer",
		"yes": "I bought a season in a junior series and finished it fourth. Somebody rang.",
		"no": "I bought a season and spent it in the wall. There is no second one.",
	},
	"casino": {
		"kind": "empire", "icon": "🎲", "name": "Own a Casino",
		"blurb": "Run the floor, pay your staff and keep the lights on. Profit is not guaranteed.",
		"how": "A licence is the hard part, and licences go to people with clean records and deep pockets.",
		"need": {"age": 21, "money": 2000000, "crimes_max": 0},
		"odds": 0.45, "cost": 1500000, "time": 5, "empire": "casino",
		"yes": "The gaming board approved it. The doors open on a Friday.",
		"no": "The board turned me down and would not put the reason in writing.",
	},
	"black_market": {
		"kind": "empire", "icon": "🕶️", "name": "Black Market Dealer",
		"blurb": "Anything, for anybody, provided nobody asks where it came from.",
		"how": "Somebody has to vouch for you, and you have to have done enough for that to mean something.",
		"need": {"age": 16, "crimes": 2},
		"odds": 0.7, "cost": 0, "time": 2, "empire": "black_market",
		"yes": "I was given an address and a name and told not to write either of them down.",
		"no": "The name I used to get in the door had already been burned.",
	},
	"cult": {
		"kind": "empire", "icon": "🛐", "name": "Found a Movement",
		"blurb": "People want to be told what it all means. Somebody is going to tell them.",
		"how": "You need to be able to hold a room, and you need somebody to hold it for.",
		"need": {"age": 21, "stat_any": {"smarts": 55, "looks": 60}},
		"odds": 0.65, "cost": 5000, "time": 4, "empire": "cult",
		"yes": "Nine people came to the first one. Forty came to the fourth.",
		"no": "Four people came, three of them were my family, and one left early.",
	},
	"zoo": {
		"kind": "empire", "icon": "🦁", "name": "Open a Zoo",
		"blurb": "Somebody has to look after them, and it may as well be somebody who cares.",
		"how": "Land, capital, and a licence that cares a great deal about how the animals will be kept.",
		"need": {"age": 21, "money": 900000, "karma": 10},
		"odds": 0.5, "cost": 700000, "time": 5, "empire": "zoo",
		"yes": "Inspection passed. Eleven species, forty staff and a gate that opens at nine.",
		"no": "The licensing inspector walked the site and said no, twice, for the same reason.",
	},
	"luxury": {
		"kind": "empire", "icon": "🛥️", "name": "The Luxury Life",
		"blurb": "A private society, new contacts and community grants. Annual dues apply.",
		"how": "It simply costs a great deal, and it is noticed.",
		"need": {"age": 21, "money": 5000000},
		"odds": 0.9, "cost": 2500000, "time": 3, "empire": "luxury",
		"yes": "The Velvet Society accepted my membership. Gatherings and community grants are open; annual dues apply. Property and boats are separate purchases.",
		"no": "The broker looked at my accounts properly and politely withdrew.",
	},
	"outdoor": {
		"kind": "empire", "icon": "🏔️", "name": "The Outdoor Life",
		"blurb": "Leave the city. Take up the whole of a different kind of difficulty.",
		"how": "Somewhere remote, the skill to be there safely, and the willingness to be far from everybody.",
		"need": {"age": 18, "health": 60, "money": 40000},
		"odds": 0.8, "cost": 30000, "time": 4, "empire": "outdoor",
		"yes": "Forty acres, a cabin, a well and a road that is a problem in February.",
		"no": "The land I had been looking at sold to somebody else the week I decided.",
	},
}

## Activities that count toward a path's "time spent" prerequisites. These are
## the leads Destiny already tracks, reused so the two systems agree.
const LEAD_KEYS := {
	"nightlife": "nightlife", "library": "library", "museum": "museum",
	"gym": "gym", "sea": "sea_fish",
}


func _st() -> Dictionary:
	var p := GameState.player
	if p.is_empty():
		return {}
	if not p.has("become") or not (p["become"] is Dictionary):
		p["become"] = {"tried": {}, "last_age": -99, "done": []}
	return p["become"]


func visits(key: String) -> int:
	return int(GameState.player.get("activity_counts", {}).get(key, 0))


## Note that an activity was done, so "spent enough time on this" is a real
## prerequisite rather than a flag.
func note_activity(id: String) -> void:
	var p := GameState.player
	if p.is_empty():
		return
	if not p.has("activity_counts") or not (p["activity_counts"] is Dictionary):
		p["activity_counts"] = {}
	p["activity_counts"][id] = int(p["activity_counts"].get(id, 0)) + 1


# ---------------------------------------------------------------- eligibility

## Returns [met: bool, lines: Array of [ok, text]] so the UI can show the whole
## list of conditions with ticks and crosses instead of one vague refusal.
func check(id: String) -> Array:
	var d: Dictionary = PATHS.get(id, {})
	if d.is_empty():
		return [false, []]
	var p := GameState.player
	var need: Dictionary = d.get("need", {})
	var lines: Array = []
	var met := true
	if (id=="casino" and Ventures.book().has("casino")) or (id=="luxury" and p.has("luxury_club")):
		met = false
		lines.append([false, "Already owned or enrolled; manage it under Venues & ventures"])

	for key in need.keys():
		var want = need[key]
		var ok := true
		var text := ""
		match key:
			"age":
				ok = int(p.get("age", 0)) >= int(want)
				text = "At least %d years old" % int(want)
			"smarts", "looks", "health":
				ok = GameState.stat(str(key)) >= float(want)
				text = "%s %d or better" % [str(key).capitalize(), int(want)]
			"money":
				ok = int(p.get("money", 0)) >= int(want)
				text = "%s saved" % GameState.fmt_money(int(want))
			"karma":
				ok = int(p.get("karma", 0)) >= int(want)
				text = "Karma %d or better" % int(want)
			"karma_max":
				ok = int(p.get("karma", 0)) <= int(want)
				text = "Karma %d or worse" % int(want)
			"fame":
				ok = float(p.get("fame", 0.0)) >= float(want)
				text = "Fame %d or more" % int(want)
			"licence":
				ok = Law.has_license(str(want))
				text = "A %s licence" % str(want)
			"clean":
				ok = (p.get("record", []) as Array).is_empty() and Wanted.stars() == 0
				text = "A clean record"
			"crimes":
				ok = Wanted.crimes() >= int(want)
				text = "%d or more crimes behind you" % int(want)
			"crimes_max":
				ok = Wanted.crimes() <= int(want)
				text = "No crimes on your record" if int(want) == 0 else "At most %d crimes" % int(want)
			"grudges":
				ok = Grit.grudge_holders(40).size() >= int(want)
				text = "Somebody who wants you to suffer"
			"job_field":
				var fields: Array = want
				var jid := str(p.get("job", {}).get("id", "")) if p.get("job", {}) is Dictionary else ""
				var cid := str(p.get("career", {}).get("id", "")) if p.get("career", {}) is Dictionary else ""
				ok = fields.has(jid) or fields.has(cid)
				text = "Work as one of: %s" % ", ".join(fields)
			"stat_any":
				var any_ok := false
				var parts: Array = []
				for sk in (want as Dictionary).keys():
					parts.append("%s %d" % [str(sk).capitalize(), int(want[sk])])
					if GameState.stat(str(sk)) >= float(want[sk]):
						any_ok = true
				ok = any_ok
				text = "Either " + " or ".join(parts)
			"nightlife", "library", "museum", "gym", "sea":
				var akey := str(LEAD_KEYS.get(key, key))
				ok = visits(akey) >= int(want)
				text = "%d visits to %s (you have %d)" % [int(want), akey.replace("_", " "), visits(akey)]
			_:
				ok = true
				text = str(key)
		if not ok:
			met = false
		lines.append([ok, text])

	# A path already taken, or refused through Destiny, is not on offer.
	if Lives.kind() != "human" and d.get("kind", "") == "life":
		met = false
		lines.append([false, "You are already something else"])
	var dest := Destiny.state()
	if not dest.is_empty() and (dest.get("declined", []) as Array).has(id):
		met = false
		lines.append([false, "You turned this down once. They do not ask twice."])
	if (_st().get("done", []) as Array).has(id):
		met = false
		lines.append([false, "Already done"])
	return [met, lines]


## The chance of being accepted, after the things that ought to move it do.
func odds(id: String) -> float:
	var d: Dictionary = PATHS.get(id, {})
	if d.is_empty():
		return 0.0
	var o := float(d.get("odds", 0.4))
	# Having been circling it through ordinary life genuinely helps.
	o += clampf(float(Destiny.lead(id)) * 0.03, 0.0, 0.3)
	# Who you are moves it, a little, in the direction you would expect.
	o += (GameState.stat("smarts") - 50.0) / 500.0
	if GameState.has_trait("Lucky"):
		o += 0.08
	if Grit.has_boon("lucky_star"):
		o += 0.05
	var tried := int((_st().get("tried", {}) as Dictionary).get(id, 0))
	# Trying again is allowed and gets harder, because they remember.
	o -= float(tried) * 0.09
	return clampf(o, 0.02, 0.95)


func tried_count(id: String) -> int:
	return int((_st().get("tried", {}) as Dictionary).get(id, 0))


func cooling() -> int:
	var st := _st()
	if st.is_empty():
		return 0
	return maxi(0, 2 - (int(GameState.player.get("age", 0)) - int(st.get("last_age", -99))))


# ---------------------------------------------------------------- applying

## Apply. This spends time and money whether or not it works, which is the
## point: going after something is a cost, not a menu selection.
func apply(id: String) -> void:
	var d: Dictionary = PATHS.get(id, {})
	if d.is_empty():
		return
	var res := check(id)
	if not bool(res[0]):
		return
	if cooling() > 0:
		return
	var st := _st()
	var cost := int(d.get("cost", 0))
	if cost > 0 and int(GameState.player["money"]) < cost:
		return
	var time_cost := int(d.get("time", 3))
	if not GameState.spend_time(time_cost):
		EventEngine.push_info("⏳", "Out of time",
			"Going after this takes %d of your %d remaining time points this year." % [time_cost, int(GameState.player.get("time_left", 0))])
		return
	st["last_age"] = int(GameState.player.get("age", 0))
	(st["tried"] as Dictionary)[id] = tried_count(id) + 1
	var o := odds(id)
	if cost > 0:
		GameState.player["money"] = int(GameState.player["money"]) - cost
	var won := randf() < o
	EventEngine.push_decision({
		"id": "_become_" + id,
		"icon": str(d["icon"]),
		"title": ("%s — accepted" % str(d["name"])) if won else ("%s — refused" % str(d["name"])),
		"text": str(d["yes"]) if won else str(d["no"]),
		"no_friction": true,
		"twist": won and str(d.get("kind", "")) == "life",
		"choices": [{"label": "Go on" if won else "Live with it",
			"outcomes": [{"text": "", "no_friction": true, "become": {"id": id, "won": won}}]}],
	})


## Applied from the outcome, so it lands after the card is read.
func outcome(data: Dictionary) -> void:
	var id := str(data.get("id", ""))
	var won := bool(data.get("won", false))
	var d: Dictionary = PATHS.get(id, {})
	if d.is_empty():
		return
	var st := _st()
	if not won:
		GameState.change_stat("happiness", -6.0)
		GameState.change_stat("stress", 8.0)
		return
	(st["done"] as Array).append(id)
	GameState.counter("become_taken")
	GameState.add_milestone(int(GameState.player["age"]), "set out to become %s and got there" % str(d["name"]).to_lower())
	match str(d.get("kind", "")):
		"life":
			_start_life(id)
		"career":
			Careers.start(str(d.get("career_id", id)), "")
		"empire":
			_start_empire(str(d.get("empire", id)))
	LifeThreads.remember("career", "The year I went after it",
		"Nobody offered me this. I went and asked for it.", "", 78, ["become", id])


func _start_life(id: String) -> void:
	match id:
		"vampire", "witch":
			Lives.become(id)
		"super":
			Lives.become("super", {"side": "hero" if int(GameState.player.get("karma", 0)) >= 0 else "villain"})
		"revenant":
			Lives.life()["destiny_rise"] = true
			GameState.add_log("Whatever I agreed to, it does not take effect until the end.")
		"royal":
			Lives.setup_royal(false)
			GameState.counter("life_royal")
		"pirate", "colonist", "traveler":
			Expansion.setup_life(id, {"born_year": 1715})
			GameState.counter("life_" + id)


func _start_empire(which: String) -> void:
	match which:
		"cult":
			GameState.set_flag("can_found_cult")
			GameState.add_log("Activities → Social → Cult. It is open to me now.")
		"black_market":
			Empires.outcome("bm_known")
		"zoo":
			GameState.set_flag("can_open_zoo")
			GameState.add_log("Activities → Travel & Luck → Zoo. The licence is in my name.")
		"casino":
			GameState.set_flag("owns_casino")
			Ventures.acquire("casino",true)
			GameState.add_log("Occupation → Business → Venues & ventures opens the casino accounts.")
		"luxury":
			GameState.set_flag("luxury_life")
			Ventures.start_luxury()
			GameState.add_log("The Velvet Society opens under Occupation → Business → Venues & ventures.")
		"outdoor":
			GameState.set_flag("outdoor_life")
			GameState.add_log("I live a long way from anybody now, on purpose.")


# ---------------------------------------------------------------- the menu

## One row per path, in the order they are likely to be reachable, with the
## whole prerequisite list attached so nothing is a mystery.
func rows() -> Array:
	var out: Array = []
	for id in PATHS.keys():
		var d: Dictionary = PATHS[id]
		var res := check(str(id))
		var met := bool(res[0])
		var lines: Array = res[1]
		out.append({
			"id": str(id), "icon": str(d["icon"]), "name": str(d["name"]),
			"blurb": str(d["blurb"]), "how": str(d["how"]),
			"met": met, "lines": lines,
			"odds": odds(str(id)) if met else 0.0,
			"cost": int(d.get("cost", 0)),
			"time": int(d.get("time", 3)),
			"tried": tried_count(str(id)),
			"kind": str(d.get("kind", "life")),
		})
	out.sort_custom(func(a, b):
		if bool(a["met"]) != bool(b["met"]):
			return bool(a["met"])
		return float(a["odds"]) > float(b["odds"]))
	return out
