extends Node

## Everyday life: Mind & Body, salon and doctors, nightlife, outings, vacations,
## the casino and lottery, fertility and adoption, identity, your will, and
## school life (cliques, clubs, sports teams, popularity, prom).

const BELTS := ["White", "Yellow", "Orange", "Green", "Blue", "Purple", "Brown", "Black", "Black 2nd dan", "Black 3rd dan"]
const MARTIAL := {
	"karate": ["🥋", "Karate", 60], "judo": ["🥋", "Judo", 60], "boxing": ["🥊", "Boxing", 70],
	"taekwondo": ["🦶", "Taekwondo", 60], "krav": ["🛡️", "Krav Maga", 90], "bjj": ["🤼", "Brazilian jiu-jitsu", 80],
}
const DIETS := {
	"balanced": ["🥗", "Balanced diet", "Steady health", {"health": 2}],
	"mediterranean": ["🫒", "Mediterranean", "Health and a longer life", {"health": 3, "happiness": 1}],
	"vegetarian": ["🥦", "Vegetarian", "Health and karma", {"health": 2, "karma": 1}],
	"vegan": ["🌱", "Vegan", "Health and karma, if you plan it well", {"health": 2, "karma": 2}],
	"keto": ["🥓", "Keto", "Looks up, mood swings", {"looks": 2, "happiness": -1}],
	"paleo": ["🍖", "Paleo", "Looks and health", {"looks": 1, "health": 1}],
	"high_protein": ["🍗", "High protein", "Looks for gym-goers", {"looks": 2}],
	"junk": ["🍔", "Whatever's in the fridge", "Happy now, not later", {"happiness": 2, "health": -3, "looks": -1}],
}
const SALON := [
	["haircut", "💇", "Fresh haircut", 40, {"looks": 2}, "I got a fresh haircut. I keep catching my reflection."],
	["dye", "🎨", "Dye your hair a bold color", 90, {"looks": 1, "happiness": 3}, "I dyed my hair %s. Heads turn now."],
	["style", "💈", "A dramatic new hairstyle", 120, {"looks": 2}, "I walked out with %s. It's a whole new me."],
	["mani", "💅", "Manicure & pedicure", 60, {"looks": 1, "stress": -3}, "Nails done. I type louder now."],
	["massage", "💆", "Massage", 90, {"stress": -8, "health": 1}, "A deep-tissue massage. I melted into the table."],
	["facial", "🧖", "Facial", 110, {"looks": 2, "stress": -3}, "My skin is glowing. People asked if I'd been on vacation."],
	["tan", "☀️", "Tanning session", 40, {"looks": 1}, "Bronzed."],
	["whiten", "🦷", "Teeth whitening", 300, {"looks": 3}, "My smile is blinding. In a good way."],
	["tattoo", "🐉", "Get a tattoo", 250, {}, ""],
	["piercing", "💎", "Get a piercing", 60, {"looks": 1}, "I got my %s pierced."],
]
const SURGERY := [
	["botox", "💉", "Botox", 600, 4, 0.92], ["nose", "👃", "Nose job", 7000, 12, 0.8], ["face", "🫥", "Facelift", 15000, 16, 0.78],
	["lipo", "🩻", "Liposuction", 9000, 10, 0.8], ["tummy", "🩺", "Tummy tuck", 11000, 10, 0.8], ["hair", "🧑‍🦲", "Hair transplant", 8000, 8, 0.85],
	["veneers", "😁", "Veneers", 12000, 10, 0.9], ["eyes", "👁️", "Laser eye surgery", 4000, 2, 0.93], ["chin", "🗿", "Chin implant", 6000, 8, 0.8],
]
const CLUBS := [
	["dive", "🍺", "The Rusty Anchor (dive bar)", 10, 0, 0.0], ["lounge", "🍸", "Velvet Lounge", 40, 45, 0.0],
	["club", "🪩", "Pulse (nightclub)", 60, 55, 0.0], ["vip", "🥂", "Skyline VIP club", 200, 70, 20.0],
]
const OUTINGS := [
	["bowling", "🎳", "Bowling", 25, 6], ["arcade", "🕹️", "Arcade", 20, 6], ["themepark", "🎢", "Theme park", 120, 6],
	["zoo", "🦓", "Zoo", 30, 4], ["aquarium", "🐠", "Aquarium", 35, 4], ["comedy", "🎭", "Comedy club", 40, 18],
	["escape", "🔐", "Escape room", 45, 12], ["minigolf", "⛳", "Mini golf", 20, 6], ["theater", "🎭", "A play at the theater", 80, 10],
	["spa_day", "♨️", "Hot springs day", 70, 12], ["paintball", "🎯", "Paintball", 50, 12], ["festival", "🎪", "Music festival (2 time)", 350, 16],
]
const MOVIES := [["horror", "👻", "A horror movie"], ["romcom", "💕", "A romantic comedy"], ["action", "💥", "An action blockbuster"], ["animated", "🧸", "An animated film"], ["drama", "🎭", "A serious drama"], ["scifi", "🛸", "A sci-fi epic"]]
const TRIPS := [
	["beach", "🏖️", "Beach resort", 3000, 1, {"happiness": 12, "stress": -14}],
	["city", "🌆", "City break", 1800, 1, {"happiness": 9, "stress": -8, "smarts": 1}],
	["ski", "⛷️", "Ski trip", 2600, 1, {"happiness": 11, "stress": -10, "health": 2}],
	["safari", "🦁", "Safari", 6500, 2, {"happiness": 16, "stress": -12, "smarts": 2}],
	["cruise", "🛳️", "Cruise", 4200, 2, {"happiness": 13, "stress": -14, "health": -1}],
	["backpack", "🎒", "Backpacking", 700, 2, {"happiness": 10, "stress": -8, "health": 2}],
	["culture", "🏯", "Cultural tour abroad", 3800, 2, {"happiness": 12, "smarts": 4, "stress": -9}],
	["camping", "🏕️", "Camping road trip", 400, 1, {"happiness": 8, "stress": -9, "health": 2}],
	["island", "🏝️", "Luxury island retreat", 12000, 2, {"happiness": 18, "stress": -18, "looks": 2}],
]
const CLIQUES := {
	"jocks": ["🏈", "Jocks", "health", 60], "nerds": ["🤓", "Nerds", "smarts", 65], "populars": ["💅", "Popular kids", "looks", 70],
	"goths": ["🖤", "Goths", "", 0], "theater": ["🎭", "Theater kids", "", 0], "skaters": ["🛹", "Skaters", "health", 45],
	"band": ["🎺", "Band kids", "", 0], "gamers": ["🎮", "Gamers", "", 0], "artsy": ["🎨", "Art kids", "", 0],
}
const SCHOOL_CLUBS := [
	["chess", "♟️", "Chess club", {"smarts": 2}], ["drama", "🎭", "Drama club", {"happiness": 2, "looks": 1}],
	["robotics", "🤖", "Robotics team", {"smarts": 3}], ["debate", "🗣️", "Debate team", {"smarts": 2}],
	["art", "🎨", "Art club", {"happiness": 2}], ["band", "🎺", "School band", {"happiness": 2}],
	["council", "🏛️", "Student council", {"smarts": 1}], ["yearbook", "📸", "Yearbook", {"happiness": 1}],
	["science", "🔬", "Science olympiad", {"smarts": 3}], ["volunteer", "🤝", "Volunteer club", {"karma": 3}],
]
const SPORTS := [
	["soccer", "⚽", "Soccer"], ["basketball", "🏀", "Basketball"], ["football", "🏈", "Football"], ["track", "🏃", "Track"],
	["swimming", "🏊", "Swimming"], ["volleyball", "🏐", "Volleyball"], ["baseball", "⚾", "Baseball"], ["tennis", "🎾", "Tennis"],
	["cheer", "📣", "Cheerleading"], ["wrestling", "🤼", "Wrestling"],
]
const HORSE_A := ["Midnight", "Thunder", "Lucky", "Silver", "Golden", "Wild", "Dancing", "Iron", "Rocket", "Velvet", "Crimson", "Sleepy"]
const HORSE_B := ["Express", "Dream", "Comet", "Lady", "Duke", "Bandit", "Echo", "Biscuit", "Fury", "Whisper", "Legend", "Pancake"]
const SLOTS := ["🍒", "🍋", "🔔", "⭐", "💎", "7️⃣"]


func _p() -> Dictionary:
	return GameState.player


func _cost(v: int) -> int:
	return Actions._cost(v)


func _money(v: int) -> String:
	return GameState.fmt_money(v)


func _pick(a: Array) -> String:
	return str(a[randi() % a.size()])


func _row(icon: String, name: String, sub: String, act: String, arg = null, on: bool = true) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "act": "daily:" + act, "arg": arg, "on": on}


func _sub(icon: String, name: String, sub: String, menu_key: String, on: bool = true) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "menu": "daily:" + menu_key, "on": on}


func _ss() -> Dictionary:
	var p := _p()
	if not p.has("school_social") or not (p["school_social"] is Dictionary):
		p["school_social"] = {"clique": "", "clubs": [], "sport": "", "captain": false, "popularity": 40, "prom": false}
	return p["school_social"]


# ================================================================ menus

func menu(key: String) -> Dictionary:
	var parts := key.split(":")
	var k: String = parts[0]
	var a1: String = parts[1] if parts.size() > 1 else ""
	var p := _p()
	var age: int = p["age"]
	match k:
		"martial":
			var rows: Array = []
			var m: Dictionary = p.get("martial", {})
			for d in MARTIAL.keys():
				var md: Array = MARTIAL[d]
				var rank := int(m.get(d, {}).get("belt", -1))
				rows.append(_row(md[0], md[1], ("Not started" if rank < 0 else "%s belt · %d%% to next" % [BELTS[mini(rank, BELTS.size() - 1)], int(m[d].get("prog", 0))]) + " · " + _money(_cost(int(md[2]))) + " a class", "martial", d))
			return {"icon": "🥋", "title": "Martial arts", "rows": rows, "info": ["Belts make you better in fights, muggings and street scraps. Train a few times a year; each belt takes longer."]}
		"diet":
			var rows2: Array = []
			var cur: String = p.get("diet", "")
			for d in DIETS.keys():
				var dd: Array = DIETS[d]
				rows2.append(_row(dd[0], dd[1] + ("  ✓" if d == cur else ""), dd[2], "diet", d, d != cur))
			return {"icon": "🥗", "title": "Diet", "rows": rows2, "info": ["Your diet quietly affects you every year."]}
		"salon":
			var rows3: Array = []
			for s in SALON:
				rows3.append(_row(s[1], s[2], _money(_cost(int(s[3]))), "salon", s[0], age >= (16 if s[0] in ["tattoo", "piercing"] else 10)))
			return {"icon": "💇", "title": "Salon & Spa", "rows": rows3}
		"surgery":
			var rows4: Array = []
			for s in SURGERY:
				rows4.append(_row(s[1], s[2], "%s · looks +%d · %d%% success" % [_money(_cost(int(s[3]))), int(s[4]), int(float(s[5]) * 100)], "surgery", s[0]))
			return {"icon": "💉", "title": "Plastic surgery", "rows": rows4, "info": ["A botched job costs you looks and health. Cheaper countries, cheaper surgeons."]}
		"doctor":
			var fee := int(_cost(150) * Places.healthcare_mult())
			var rows5: Array = [
				_row("🩺", "Family doctor", _money(fee) + " · checkups and illness", "doctor", "gp"),
				_row("🚑", "Emergency room", _money(int(_cost(1200) * Places.healthcare_mult())) + " · better odds for serious illness", "doctor", "er"),
				_row("🧠", "Psychiatrist", _money(int(_cost(250) * Places.healthcare_mult())) + " · mood and stress", "doctor", "psych"),
				_row("👓", "Optometrist", _money(_cost(120)) + " · eye exam", "doctor", "eyes"),
				_row("🦴", "Chiropractor", _money(_cost(90)) + " · backs and necks", "doctor", "chiro"),
				_row("🌿", "Alternative medicine", _money(_cost(150)) + " · crystals and herbs", "doctor", "alt"),
				_row("🪬", "Witch doctor", _money(_cost(400)) + " · a long shot", "doctor", "witch"),
				_row("🦷", "Dentist", _money(_cost(120)), "doctor", "dentist"),
			]
			return {"icon": "🏥", "title": "Doctors", "rows": rows5}
		"nightlife":
			var rows6: Array = []
			var drink := int(Places.law("drink"))
			for c in CLUBS:
				rows6.append(_row(c[1], c[2], _money(_cost(int(c[3]))) + (" · bouncer is picky" if int(c[4]) >= 55 else "") + (" · famous faces only" if float(c[5]) > 0 else ""), "club", c[0], age >= drink))
			rows6.append(_row("🍻", "Bar crawl with friends", _money(_cost(120)) + " · bring the whole crew", "club", "crawl", age >= drink and not (GameState.npcs_with("friend") + GameState.npcs_with("best_friend")).is_empty()))
			return {"icon": "🪩", "title": "Nightlife", "rows": rows6, "info": ["Clubs in %s let you in at %d." % [Places.region().get("city", ""), drink]]}
		"outings":
			var rows7: Array = []
			for o in OUTINGS:
				rows7.append(_row(o[1], o[2], _money(_cost(int(o[3]))), "outing", o[0], age >= int(o[4])))
			return {"icon": "🎟️", "title": "Going out", "rows": rows7}
		"movies":
			var rows8: Array = []
			for mv in MOVIES:
				rows8.append(_row(mv[1], mv[2], _money(_cost(15)), "movie", mv[0], age >= (13 if mv[0] == "horror" else 4)))
			return {"icon": "🎬", "title": "Movie theater", "rows": rows8}
		"vacation":
			var comp := a1
			var rows9: Array = []
			var fly := Shop.has_any(["plane", "jet"])
			for t in TRIPS:
				var price := _cost(int(t[3])) * (2 if comp != "" else 1)
				if fly:
					price = int(price * 0.6)
				rows9.append(_row(t[1], t[2], "%s · %d time%s" % [_money(price), int(t[4]), " · you fly yourself" if fly else ""], "vacation", [t[0], comp], age >= 18))
			var who: String = "" if comp == "" else " with " + GameState.npc(comp).get("first", "")
			return {"icon": "✈️", "title": "Vacation" + who, "rows": rows9}
		"casino":
			var gl := str(Places.law("gambling"))
			var rows10: Array = []
			if gl == "banned":
				rows10.append(_row("🃏", "Find the underground game", "Gambling is illegal here. Risky.", "underground"))
				return {"icon": "🎰", "title": "Casino", "rows": rows10}
			for g in [["blackjack", "🃏", "Blackjack", "Play it yourself. Beat the dealer to 21"], ["roulette", "🎡", "Roulette", "Red, black, odd, even, or one number for 35×"], ["slots", "🎰", "Slots", "Three reels, pure luck"], ["highlow", "🂠", "High or low", "Build a streak, cash out any time"], ["rocket", "🚀", "Rocket", "Cash out before it crashes"], ["plinko", "🔵", "Plinko", "Drop the ball, pick your risk"], ["scratch", "🎟️", "Scratch card", "Three of a kind wins"], ["wheel", "🎡", "Lucky wheel", "Spin for a multiplier"]]:
				if gl == "restricted" and g[0] != "slots":
					continue
				rows10.append(_sub(g[1], g[2], g[3], "bet:" + g[0], age >= 18))
			rows10.append(_sub("🏇", "Horse races", "Six horses, real odds, real form", "horses", age >= 18))
			rows10.append({"icon":"🎲", "name":"More tables", "sub":"Baccarat, craps, video poker, keno, poker tournaments and Sic Bo", "menu":"exp:casino", "on":age >= 18})
			return {"icon": "🎰", "title": "Casino", "rows": rows10, "info": ["House edge is small but real. Luck charms and lucky heirlooms help a little."]}
		"bet":
			var rows11: Array = []
			for amt in [10, 100, 1000, 10000, 100000]:
				if int(p["money"]) >= amt:
					if a1 == "roulette":
						rows11.append(_sub("💵", "Bet %s" % _money(amt), "Then pick where", "roulette:%d" % amt))
					else:
						rows11.append(_row("💵", "Bet %s" % _money(amt), "", "casino", [a1, amt, ""]))
			if rows11.is_empty():
				rows11.append({"icon": "💸", "name": "You need at least $10", "sub": "", "on": false})
			return {"icon": "🎲", "title": a1.capitalize(), "rows": rows11}
		"roulette":
			var amt2 := int(a1)
			var rows12: Array = []
			for c in [["red", "🔴", "Red", "2×"], ["black", "⚫", "Black", "2×"], ["odd", "1️⃣", "Odd", "2×"], ["even", "2️⃣", "Even", "2×"], ["low", "⬇️", "1–18", "2×"], ["high", "⬆️", "19–36", "2×"], ["dozen", "🔢", "13–24", "3×"], ["seven", "7️⃣", "Number 7", "36×"], ["lucky", "🍀", "Number 17", "36×"], ["zero", "0️⃣", "Zero", "36×"]]:
				rows12.append(_row(c[1], c[2], "Pays " + c[3], "casino", ["roulette", amt2, c[0]]))
			return {"icon": "🎡", "title": "Roulette · " + _money(amt2), "rows": rows12}
		"horses":
			var race := _race()
			var rows13: Array = []
			for i in range(race["horses"].size()):
				var h: Dictionary = race["horses"][i]
				rows13.append(_sub("🐎", "%s  ·  %.1f to 1" % [h["name"], float(h["odds"]) - 1.0], "Form %s · jockey %s" % ["★".repeat(int(h["form"])) + "☆".repeat(5 - int(h["form"])), h["jockey"]], "horse_bet:%d" % i, age >= 18))
			return {"icon": "🏇", "title": "Today's race", "rows": rows13, "info": ["Odds reflect each horse's real chance (minus the track's cut). Form helps, but upsets happen."]}
		"horse_bet":
			var idx := int(a1)
			var rows14: Array = []
			for amt3 in [10, 100, 1000, 10000, 100000]:
				if int(p["money"]) >= amt3:
					rows14.append(_row("💵", "Bet %s" % _money(amt3), "", "horse", [idx, amt3]))
			return {"icon": "🐎", "title": _race()["horses"][idx]["name"], "rows": rows14}
		"lottery":
			var lot := lottery()
			var luck := Shop.luck()
			var rows15: Array = []
			rows15.append({"icon": "🏆", "name": "Mega jackpot: %s" % _money(int(lot["jackpot"])), "sub": "Grows every year nobody wins · last won %s" % (str(lot.get("last_winner", "years ago"))), "on": false})
			rows15.append(_row("🎟️", "Buy 1 Mega ticket", "%s · jackpot 1 in %s · $50,000 1 in 60,000 · $500 1 in 1,500" % [_money(_cost(2)), _big(int(2500000 / luck))], "lottery", ["mega", 1], age >= 18))
			rows15.append(_row("🎟️", "Buy 10 Mega tickets", _money(_cost(20)), "lottery", ["mega", 10], age >= 18))
			rows15.append(_row("🎟️", "Buy 100 Mega tickets", _money(_cost(200)), "lottery", ["mega", 100], age >= 18))
			rows15.append(_row("🎫", "Scratch card", "%s · 1 in 4 wins something · top prize $10,000" % _money(_cost(5)), "lottery", ["scratch", 1], age >= 18))
			rows15.append(_row("🔢", "Pick 3", "%s · match 3 digits (1 in 1,000) for $500" % _money(_cost(2)), "lottery", ["pick3", 1], age >= 18))
			var info: Array = ["Your odds are shown before you buy."]
			if luck > 1.0:
				info.append("🍀 Your lucky charms improve your odds by %d%%." % int(round((luck - 1.0) * 100)))
			return {"icon": "🎟️", "title": "Lottery", "rows": rows15, "info": info}
		"fertility":
			var rows16: Array = [
				_row("🔬", "Fertility test", _money(_cost(300)) + " · find out your odds", "fertility", "test", age >= 16),
				_row("🧫", "IVF", "%s · about 45%% per round · twins are more likely" % _money(_cost(15000)), "fertility", "ivf", age >= 18),
				_row("🧬", "Artificial insemination", "%s · no partner needed" % _money(_cost(3000)), "fertility", "insem", age >= 18 and p["gender"] != "male"),
				_row("🤰", "Hire a surrogate", "%s · legal here? %s" % [_money(_cost(60000)), "yes" if p["country"] in ["us", "uk", "mx", "br", "ph", "ng"] else "no"], "fertility", "surrogate", age >= 21 and p["country"] in ["us", "uk", "mx", "br", "ph", "ng"]),
				_sub("🏠", "Adopt a child", "Meet children who need a home", "adoption", age >= 21),
				_sub("🍼", "Foster a child", "Temporary care, big heart", "foster", age >= 21),
			]
			return {"icon": "🧬", "title": "Fertility & family", "rows": rows16}
		"adoption":
			return _adoption_menu()
		"foster":
			return {"icon": "🍼", "title": "Foster care", "rows": [_row("🍼", "Take in a foster child this year", "The state pays a small stipend · they might stay", "foster")]}
		"identity":
			var rows17: Array = []
			for i in range(4):
				var nf := ContentDB.random_first(p["gender"], p["country"])
				rows17.append(_row("🪪", "Change your first name to %s" % nf, _money(_cost(200)) + " court fee", "rename", ["first", nf], age >= 18))
			for i in range(2):
				var nl := ContentDB.random_last(p["country"])
				rows17.append(_row("🪪", "Change your last name to %s" % nl, _money(_cost(200)) + " court fee", "rename", ["last", nl], age >= 18))
			for g in [["male", "♂️", "Male"], ["female", "♀️", "Female"], ["nonbinary", "⚧️", "Non-binary"]]:
				if g[0] != p["gender"]:
					rows17.append(_row(g[1], "Update your gender to %s" % g[2], "Paperwork and a new chapter", "gender", g[0], age >= 16))
			return {"icon": "🪪", "title": "Identity", "rows": rows17}
		"will":
			var rows18: Array = []
			var cur2: String = p.get("will", "equal")
			rows18.append(_row("⚖️", "Split everything equally" + ("  ✓" if cur2 == "equal" else ""), "Every child gets the same", "will", "equal", cur2 != "equal"))
			for cid in GameState.npcs_with("child"):
				var cn: Dictionary = GameState.npcs[cid]
				if cn.get("disowned", false):
					continue
				var mine: bool = cur2 == "heir:" + cid
				rows18.append(_row("👑", "Leave most of it to %s" % cn["first"] + ("  ✓" if mine else ""), "70% to them, the rest shared", "will", "heir:" + cid, not mine))
			rows18.append(_row("🎗️", "Leave it all to charity" + ("  ✓" if cur2 == "charity" else ""), "Karma now, a furious family later", "will", "charity", cur2 != "charity"))
			return {"icon": "📜", "title": "Will & testament", "rows": rows18}
		"school":
			return _school_menu()
		"cliques":
			var rows19: Array = []
			var ss := _ss()
			for c2 in CLIQUES.keys():
				var cd: Array = CLIQUES[c2]
				var req := "" if str(cd[2]) == "" else "Needs %s %d+" % [cd[2], int(cd[3])]
				rows19.append(_row(cd[0], cd[1] + ("  ✓" if ss["clique"] == c2 else ""), req if req != "" else "Anyone can try", "clique", c2, ss["clique"] != c2))
			if ss["clique"] != "":
				rows19.append(_row("🚶", "Leave your clique", "Go solo", "clique", ""))
			return {"icon": "👥", "title": "Cliques", "rows": rows19}
		"clubs":
			var rows20: Array = []
			var ss2 := _ss()
			for c3 in SCHOOL_CLUBS:
				var inn: bool = ss2["clubs"].has(c3[0])
				rows20.append(_row(c3[1], c3[2] + ("  ✓" if inn else ""), "Leave" if inn else "Join (max 2)", "club_join", c3[0], inn or ss2["clubs"].size() < 2))
			return {"icon": "🏫", "title": "Clubs", "rows": rows20}
		"sports":
			var rows21: Array = []
			var ss3 := _ss()
			for s3 in SPORTS:
				var on_team: bool = ss3["sport"] == s3[0]
				rows21.append(_row(s3[1], s3[2] + (" team  ✓" if on_team else " team") + (" · captain" if on_team and ss3["captain"] else ""), "Practice hard" if on_team else "Try out", "sport", s3[0], ss3["sport"] == "" or on_team))
			if ss3["sport"] != "":
				rows21.append(_row("🚪", "Quit the team", "", "sport", ""))
			return {"icon": "🏆", "title": "Sports teams", "rows": rows21}
		"date_venues":
			var id := a1
			var nm: String = GameState.npc(id).get("first", "")
			var rows22: Array = []
			for v in [["picnic", "🧺", "Picnic in the park", 0], ["dinner", "🍝", "Dinner out", 80], ["fancy", "🥂", "A fancy restaurant", 300], ["dancing", "💃", "Go dancing", 60], ["bowling", "🎳", "Bowling", 40], ["comedy", "😂", "Comedy club", 50], ["stars", "🌌", "Stargazing drive", 0], ["getaway", "🏨", "Weekend getaway (2 time)", 800]]:
				rows22.append(_row(v[1], v[2], "Free" if int(v[3]) == 0 else _money(_cost(int(v[3]))), "date", [id, v[0]], GameState.can_interact(id, "date")))
			return {"icon": "🍷", "title": "Date night with " + nm, "rows": rows22}
		"dating":
			var rows23: Array = [
				_row("💘", "Try your luck somewhere", "A coffee shop, a bookstore, a friend's party", "find_date", "street", age >= 14),
				_row("📱", "Dating app", "Free · more matches, more weirdos", "find_date", "app", age >= 18),
				_row("💎", "Premium dating app", "%s · better matches" % _money(_cost(80)), "find_date", "premium", age >= 18),
				_row("⏱️", "Speed dating night", "%s · meet five people in an hour" % _money(_cost(40)), "find_date", "speed", age >= 21),
				_row("🌟", "Celebrity dating app", "%s · famous people only · needs fame 40+" % _money(_cost(100000)), "find_date", "celeb", age >= 18 and float(p.get("fame", 0)) >= 40),
			]
			return {"icon": "❤️", "title": "Find love", "rows": rows23}
	return {"icon": "❔", "title": "", "rows": []}


func _big(v: int) -> String:
	var s := str(v)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out


func _school_menu() -> Dictionary:
	var p := _p()
	var ss := _ss()
	var rows: Array = []
	var in_hs: bool = GameState.in_school() and int(p["age"]) >= 11
	rows.append({"icon": "⭐", "name": "Popularity: %d%%" % int(ss["popularity"]), "sub": ("Clique: %s" % CLIQUES[ss["clique"]][1]) if ss["clique"] != "" else "Not in a clique", "on": false})
	if int(p["age"]) >= 11:
		rows.append(_sub("👥", "Cliques", "Jocks, nerds, goths, theater kids…", "cliques"))
		rows.append(_sub("🏫", "Clubs", "%d joined · chess, drama, robotics, debate…" % ss["clubs"].size(), "clubs"))
		rows.append(_sub("🏆", "Sports teams", "On the %s team" % ss["sport"] if ss["sport"] != "" else "Try out for a team", "sports"))
	rows.append(_row("🧑‍🏫", "Visit the principal", "Complain, confess, or charm", "principal"))
	rows.append(_row("🩹", "Go to the school nurse", "Get out of class", "nurse"))
	if int(p["age"]) >= 10:
		rows.append(_row("📝", "Cheat on a test", "Grades up, if you don't get caught", "cheat"))
		rows.append(_row("🎤", "Enter the talent show", "Sing, dance, magic, stand-up", "talent"))
	if in_hs and int(p["age"]) >= 13:
		rows.append(_row("🗳️", "Run for class president", "Popularity helps", "president"))
		rows.append(_row("💃", "Go to the school dance", "Ask someone, or go with friends", "dance"))
	if in_hs and int(p["age"]) >= 16 and not ss["prom"]:
		rows.append(_row("👑", "Prom", "Once in a lifetime. Maybe king or queen", "prom"))
	return {"icon": "🏫", "title": "School life", "rows": rows}


func _adoption_menu() -> Dictionary:
	var p := _p()
	var w := GameState.world
	var yr := int(p["age"])
	if int(w.get("adopt_year", -1)) != yr or not w.has("adopt_kids"):
		var kids: Array = []
		for i in range(4):
			var g := "male" if randf() < 0.5 else "female"
			var c: Dictionary = ContentDB.countries[randi() % ContentDB.countries.size()]
			var a := randi_range(0, 12)
			kids.append({"gender": g, "first": ContentDB.random_first(g, c["id"]), "age": a, "from": c["name"], "flag": c.get("flag", ""), "behavior": randi_range(10, 95), "smarts": randi_range(15, 95), "fee": [12000, 9000, 6000, 4000][mini(3, a / 4)] + (8000 if c["id"] != p["country"] else 0)})
		w["adopt_kids"] = kids
		w["adopt_year"] = yr
	var rows: Array = []
	for i in range(w["adopt_kids"].size()):
		var k: Dictionary = w["adopt_kids"][i]
		var bh := "Angel" if int(k["behavior"]) >= 75 else ("Well-behaved" if int(k["behavior"]) >= 50 else ("A handful" if int(k["behavior"]) >= 30 else "A lot of trauma, a lot of love needed"))
		rows.append(_row(preload("res://scenes/ui_kit.gd").face(k["gender"], int(k["age"]), randi() % 5), "%s, %d · %s %s" % [k["first"], int(k["age"]), k["flag"], k["from"]], "%s · smarts %d · fee %s" % [bh, int(k["smarts"]), _money(_cost(int(k["fee"])))], "adopt", i, not k.get("taken", false)))
	var why := _adopt_block()
	var info: Array = ["The agency checks your home, income and record."]
	if why != "":
		info.append("🔒 " + why)
	return {"icon": "🏠", "title": "Adoption agency", "rows": rows, "info": info}


func _adopt_block() -> String:
	var p := _p()
	if int(p["age"]) < 21:
		return "You must be at least 21."
	if p["housing"] in ["parents", "homeless"]:
		return "You need a home of your own."
	if not p["record"].is_empty() and p["record"].size() >= 2:
		return "Your criminal record worries the agency."
	if int(p.get("last_income", 0)) < _cost(15000) and int(p["money"]) < _cost(40000):
		return "The agency wants to see steady income or savings."
	return ""


# ================================================================ actions

func act(key: String, arg = null) -> void:
	var p := _p()
	match key:
		"martial": _martial(str(arg))
		"diet":
			p["diet"] = str(arg)
			Actions._done(DIETS[arg][0], "New diet", "I switched to a %s diet." % str(DIETS[arg][1]).to_lower(), {})
		"salon": _salon(str(arg))
		"surgery": _surgery(str(arg))
		"doctor": _doctor(str(arg))
		"club": _club(str(arg))
		"outing": _outing(str(arg))
		"movie": _movie(str(arg))
		"vacation": _vacation(str(arg[0]), str(arg[1]))
		"casino": _casino(str(arg[0]), int(arg[1]), str(arg[2]))
		"underground": Actions._underground_casino()
		"horse": _horse(int(arg[0]), int(arg[1]))
		"lottery": _lottery(str(arg[0]), int(arg[1]))
		"fertility": _fertility(str(arg))
		"adopt": _adopt(int(arg))
		"foster": _foster()
		"rename": _rename(str(arg[0]), str(arg[1]))
		"gender":
			if Actions._out_of_time(): return
			p["gender"] = str(arg)
			GameState.add_milestone(p["age"], "updated their gender")
			Actions._done("🪪", "Identity", "I updated my documents. It feels like me.", {"happiness": 8, "stress": -4})
		"will":
			p["will"] = str(arg)
			var who := "equally among my children"
			if str(arg).begins_with("heir:"):
				who = "mostly to " + GameState.npc(str(arg).substr(5)).get("first", "one child")
			elif str(arg) == "charity":
				who = "to charity"
			Actions._done("📜", "Will", "I updated my will. Everything goes %s." % who, {"karma": 5 if str(arg) == "charity" else 0})
		"clique": _clique(str(arg))
		"club_join": _club_join(str(arg))
		"sport": _sport(str(arg))
		"principal", "nurse", "cheat", "talent", "president", "dance", "prom": _school_act(key)
		"date": _date(str(arg[0]), str(arg[1]))
		"find_date": _find_date(str(arg))
		"garden":
			if Actions._out_of_time(): return
			var g: String = ["tomatoes", "sunflowers", "herbs", "a stubborn lemon tree", "strawberries"][randi() % 5]
			Actions._done("🌻", "Gardening", "I spent the day in the garden with my %s." % g, {"stress": -6, "happiness": 4, "health": 1})
		"voice", "acting":
			if Actions._out_of_time(): return
			var c := _cost(80)
			if not Actions._can_pay(c, "Lessons"): return
			p["talent_" + key] = int(p.get("talent_" + key, 0)) + 1
			var lvl := int(p["talent_" + key])
			var t := "voice" if key == "voice" else "acting"
			Actions._done("🎙️" if key == "voice" else "🎭", "%s lessons" % t.capitalize(), "I took %s lessons (%d so far). %s" % [t, lvl, ["My teacher says I have potential.", "I hit a note I didn't know I had." if key == "voice" else "I cried on cue. My teacher clapped.", "Progress is slow, but it's progress."][randi() % 3]], {"money": -c, "happiness": 2, "skill": 1 if Careers.has_career() else 0})
		"memory":
			if Actions._out_of_time(): return
			Minigames.play("memory", {"skill": GameState.stat("smarts"), "difficulty": 1.0}, func(score: float, d: Dictionary) -> void:
				var n := int(d.get("length", 0)) if not d.get("auto", false) else clampi(int(GameState.stat("smarts") / 10.0 + randi_range(-2, 3)), 1, 10)
				var fx := {"smarts": 1} if score >= 0.6 else {}
				Actions._done("🧠", "Memory test", "I held a sequence of %d. %s" % [n, "Impressive." if score >= 0.7 else ("Solid." if score >= 0.4 else "Goldfish energy.")], fx))
		"pray":
			if Actions._out_of_time(): return
			var r := randf()
			if r < 0.05 and _p()["illness"] != "":
				var ill: String = p["illness"]
				p["illness"] = ""
				Actions._done("🙏", "Prayer", "I prayed. The next morning, the %s was gone. The doctors can't explain it." % ill, {"happiness": 10, "karma": 2})
			else:
				Actions._done("🙏", "Prayer", ["I prayed and felt a little lighter.", "I prayed for patience. Still waiting.", "I sat in silence for an hour. It helped."][randi() % 3], {"stress": -4, "karma": 1})


# ---------------------------------------------------------------- mind & body

func _martial(d: String) -> void:
	var p := _p()
	var md: Array = MARTIAL[d]
	var fee := _cost(int(md[2]))
	if Actions._out_of_time(): return
	if not Actions._can_pay(fee, str(md[1])): return
	if not p.has("martial"):
		p["martial"] = {}
	var m: Dictionary = p["martial"]
	if not m.has(d):
		m[d] = {"belt": 0, "prog": 0}
	var s: Dictionary = m[d]
	var gain := randi_range(22, 40) - int(s["belt"]) * 2 + int((GameState.stat("health") - 50.0) / 10.0)
	s["prog"] = int(s["prog"]) + maxi(8, gain)
	var txt := "I trained %s." % str(md[1]).to_lower()
	var fx := {"money": -fee, "health": 2, "stress": -3}
	if int(s["prog"]) >= 100:
		s["prog"] = 0
		s["belt"] = mini(BELTS.size() - 1, int(s["belt"]) + 1)
		txt += " I passed my belt test: %s belt!" % BELTS[int(s["belt"])]
		fx["happiness"] = 6
		GameState.counter("belts_earned")
		if int(s["belt"]) == 7:
			GameState.add_milestone(p["age"], "earned a black belt in %s" % str(md[1]).to_lower())
	else:
		txt += " %d%% of the way to my next belt." % int(s["prog"])
	Actions._done(md[0], str(md[1]), txt, fx)


func fight_bonus() -> float:
	var best := 0
	for d in _p().get("martial", {}).keys():
		best = maxi(best, int(_p()["martial"][d].get("belt", 0)))
	return minf(0.35, best * 0.045) + (0.1 if Shop.has_tag("sword") else 0.0)


func _salon(s: String) -> void:
	var p := _p()
	var d: Array = []
	for x in SALON:
		if x[0] == s:
			d = x
	var fee := _cost(int(d[3]))
	if Actions._out_of_time(): return
	if not Actions._can_pay(fee, str(d[2])): return
	var fx: Dictionary = (d[4] as Dictionary).duplicate()
	fx["money"] = -fee
	var txt := str(d[5])
	match s:
		"dye":
			var colr := _pick(["platinum blonde", "cherry red", "pastel pink", "electric blue", "jet black", "forest green"])
			p["hair"] = colr
			txt = txt % colr
		"style":
			var st := _pick(["a buzz cut", "a sleek bob", "long layers", "a mullet (ironic)", "curtain bangs", "a mohawk"])
			p["hair_style"] = st
			txt = txt % st
			if randf() < 0.2:
				txt = "I asked for %s. I got something else. I'm wearing a hat for a month." % st
				fx["looks"] = -2
		"piercing":
			txt = txt % _pick(["ear", "nose", "eyebrow", "lip", "tongue"])
		"tattoo":
			var tat := _pick(["a dragon on my back", "my mom's name on my arm", "a tiny heart on my wrist", "song lyrics on my ribs", "a skull with roses", "a tribal band", "a portrait of my dog"])
			p["tattoos"] = p.get("tattoos", []) + [tat]
			if randf() < 0.18:
				txt = "I got %s. The artist spelled something wrong. It's permanent." % tat
				fx["happiness"] = -6
				fx["looks"] = -1
			else:
				txt = "I got %s. I love it." % tat
				fx["happiness"] = 5
				fx["looks"] = 1
	Actions._done(d[1], str(d[2]), txt, fx)


func _surgery(s: String) -> void:
	var p := _p()
	var d: Array = []
	for x in SURGERY:
		if x[0] == s:
			d = x
	var fee := _cost(int(d[3]))
	if int(p["age"]) < 18:
		EventEngine.push_info("💉", "Plastic surgery", "You have to be 18.")
		return
	if Actions._out_of_time(): return
	if not Actions._can_pay(fee, str(d[2])): return
	var ok := randf() < float(d[5]) + (0.05 if int(p["money"]) > 1000000 else 0.0)
	var fx := {"money": -fee}
	if ok:
		fx["looks"] = int(d[4])
		fx["happiness"] = 5
		if s == "eyes":
			p["glasses"] = false
		GameState.counter("surgeries")
		Actions._done(d[1], str(d[2]), "The %s went perfectly." % str(d[2]).to_lower(), fx)
	else:
		fx["looks"] = -int(d[4])
		fx["health"] = -8
		fx["happiness"] = -10
		Actions._done(d[1], str(d[2]), "The %s was botched. I need a better surgeon to fix this, and a lawyer." % str(d[2]).to_lower(), fx)


func _doctor(k: String) -> void:
	var p := _p()
	match k:
		"gp":
			Actions.do_activity("doctor")
		"dentist":
			Actions.do_activity("dentist")
		"er":
			var fee := int(_cost(1200) * Places.healthcare_mult())
			if Actions._out_of_time(): return
			if not Actions._can_pay(fee, "Emergency room"): return
			if p["illness"] != "":
				var ill: String = p["illness"]
				if randf() < (0.55 if ill == "cancer" else 0.92):
					p["illness"] = ""
					Actions._done("🚑", "Emergency room", "The ER team went all out. The %s is under control." % ill, {"money": -fee, "health": 14})
				else:
					Actions._done("🚑", "Emergency room", "They stabilized me, but the %s is still there." % ill, {"money": -fee, "health": 5})
			else:
				Actions._done("🚑", "Emergency room", "I waited six hours to be told I'm fine and to drink more water.", {"money": -fee, "stress": 5})
		"psych":
			var fee2 := int(_cost(250) * Places.healthcare_mult())
			if Actions._out_of_time(): return
			if not Actions._can_pay(fee2, "Psychiatrist"): return
			Grit.therapy_helps()
			var wp := GameState.hidden("willpower")
			var dc := GameState.hidden("discipline")
			var note := "\n\nThe assessment says my willpower is %s and my self-discipline is %s." % [_grade_word(wp), _grade_word(dc)]
			Actions._done("🧠", "Psychiatrist", "I talked to a psychiatrist about how I've been feeling. We made a plan." + note, {"money": -fee2, "stress": -14, "happiness": 6})
		"eyes":
			if Actions._out_of_time(): return
			if not Actions._can_pay(_cost(120), "Optometrist"): return
			if randf() < 0.3 + int(p["age"]) / 150.0 and not p.get("glasses", false):
				p["glasses"] = true
				Actions._done("👓", "Optometrist", "I need glasses. Now I can see individual leaves on trees. Wild.", {"money": -_cost(120), "smarts": 1, "happiness": 2})
			else:
				Actions._done("👓", "Optometrist", "20/20. The optometrist seemed disappointed.", {"money": -_cost(120)})
		"chiro":
			if Actions._out_of_time(): return
			if not Actions._can_pay(_cost(90), "Chiropractor"): return
			if p.get("scars", []).has("back_injury") and randf() < 0.15:
				p["scars"].erase("back_injury")
				Actions._done("🦴", "Chiropractor", "One loud crack and my old back injury finally let go.", {"money": -_cost(90), "health": 6})
			else:
				Actions._done("🦴", "Chiropractor", "Crack, crack, pop. I feel an inch taller.", {"money": -_cost(90), "health": 2, "stress": -3})
		"alt":
			if Actions._out_of_time(): return
			if not Actions._can_pay(_cost(150), "Alternative medicine"): return
			if p["illness"] != "" and randf() < 0.08:
				p["illness"] = ""
				Actions._done("🌿", "Alternative medicine", "Herbal tea, crystals and chanting. And somehow I'm better?", {"money": -_cost(150), "health": 5})
			else:
				Actions._done("🌿", "Alternative medicine", "I left smelling like lavender and $150 lighter.", {"money": -_cost(150), "stress": -3})
		"witch":
			if Actions._out_of_time(): return
			if not Actions._can_pay(_cost(400), "Witch doctor"): return
			var r := randf()
			if p["illness"] != "" and r < 0.06:
				p["illness"] = ""
				Actions._done("🪬", "Witch doctor", "A chicken, a chant and something I drank. The illness is gone.", {"money": -_cost(400), "health": 10})
			elif r < 0.2:
				Actions._done("🪬", "Witch doctor", "Whatever he gave me made everything worse.", {"money": -_cost(400), "health": -8})
			else:
				Actions._done("🪬", "Witch doctor", "He shook a rattle at me for twenty minutes. No change.", {"money": -_cost(400)})


# ---------------------------------------------------------------- going out

func _club(c: String) -> void:
	var p := _p()
	if int(p["age"]) < int(Places.law("drink")):
		EventEngine.push_info("🪩", "ID check", "You're too young.")
		return
	if c == "crawl":
		if Actions._out_of_time(): return
		var fee := _cost(120)
		if not Actions._can_pay(fee, "Bar crawl"): return
		for f in GameState.npcs_with("friend") + GameState.npcs_with("best_friend"):
			GameState.change_closeness(f, 8)
		Grit.habit("partying", 8)
		Actions._done("🍻", "Bar crawl", ["Seven bars, one kebab, zero regrets.", "We lost someone at bar four and found them singing at bar six.", "My friends and I closed down every bar on the street."][randi() % 3], {"money": -fee, "happiness": 8, "health": -3})
		return
	var d: Array = []
	for x in CLUBS:
		if x[0] == c:
			d = x
	if Actions._out_of_time(): return
	var fee2 := _cost(int(d[3]))
	if not Actions._can_pay(fee2, str(d[2])): return
	if GameState.stat("looks") < float(d[4]) and float(p.get("fame", 0)) < 30 and randf() < 0.6:
		Actions._done("🚫", str(d[2]), "The bouncer looked me up and down and said \"Not tonight.\"", {"happiness": -5})
		return
	if float(d[5]) > 0 and float(p.get("fame", 0)) < float(d[5]) and int(p["money"]) < 1000000:
		Actions._done("🚫", str(d[2]), "\"Are you on the list?\" I was not on the list.", {"happiness": -4})
		return
	Grit.habit("partying", 7)
	var r := randf()
	var fx := {"money": -fee2, "happiness": 6, "stress": -4}
	if r < 0.2:
		var g := "female" if p["gender"] == "male" else "male"
		var cid := GameState.create_npc("crush", {"gender": g, "age": maxi(int(Places.law("drink")), int(p["age"]) + randi_range(-4, 4)), "closeness": 45})
		Actions._done(d[1], str(d[2]), "I met %s on the dance floor. We traded numbers." % GameState.npcs[cid]["first"], fx)
	elif r < 0.3:
		EventEngine.push_decision({"id": "_offer", "icon": "💊", "title": "Something extra", "text": "A stranger at %s offers you a little pill. \"Makes the night better.\"" % str(d[2]), "choices": [
			{"label": "Take it", "outcomes": [{"weight": 3, "text": "The night got very colorful. The next day did not.", "effects": {"happiness": 6, "health": -8}, "habit": ["partying", 15]}, {"weight": 1, "text": "I woke up in the hospital.", "effects": {"health": -25, "money": -_cost(2000)}, "habit": ["partying", 15]}]},
			{"label": "No thanks", "outcomes": [{"text": "I said no and went back to dancing.", "effects": {"karma": 1}}]},
			{"label": "Tell security", "outcomes": [{"text": "Security walked the guy out.", "effects": {"karma": 3}}]},
		]})
		GameState.apply_effects(fx)
	elif r < 0.37:
		Actions._done("🥊", str(d[2]), "Some guy spilled a drink on me and swung when I complained. Security threw us both out.", {"money": -fee2, "health": -6, "happiness": -4})
	elif r < 0.43 and c == "vip":
		var celeb := _pick(["a pop star", "a famous footballer", "a reality TV star", "an actor from that show everyone watches"])
		Actions._done("🌟", str(d[2]), "I shared a booth with %s. We took a selfie. Nobody believes me." % celeb, {"money": -fee2, "happiness": 10, "fame": 1})
	elif r < 0.5:
		Actions._done("🤢", str(d[2]), "One too many. I spent the end of the night in a bathroom stall.", {"money": -fee2, "health": -4, "happiness": -2})
	else:
		Actions._done(d[1], str(d[2]), ["I danced until they turned the lights on.", "The DJ played my song twice.", "Good music, bad drinks, great night.", "I won a dance-off against a bachelor party."][randi() % 4], fx)


func _outing(o: String) -> void:
	var d: Array = []
	for x in OUTINGS:
		if x[0] == o:
			d = x
	if Actions._out_of_time(): return
	if o == "festival" and not GameState.spend_time():
		GameState.player["time_left"] = int(GameState.player["time_left"]) + 1
		EventEngine.push_info("⏳", "Not enough time", "A festival takes 2 time.")
		return
	var fee := _cost(int(d[3]))
	if not Actions._can_pay(fee, str(d[2])): return
	var fx := {"money": -fee, "happiness": 5, "stress": -3}
	var txt := ""
	match o:
		"bowling": txt = "I bowled a %d. %s" % [randi_range(60, 240), _pick(["One strike, many gutters.", "Personal best!", "The shoes were damp."])]
		"arcade": txt = _pick(["I spent $20 in tokens on a claw machine and won nothing.", "I got the high score on a zombie game and entered my initials proudly.", "I traded 900 tickets for a plastic spider ring."])
		"themepark":
			if randf() < 0.05:
				txt = "A roller coaster stalled upside down for twenty minutes. I'm fine. Mostly."
				fx["stress"] = 8
			else:
				txt = _pick(["I rode the biggest coaster three times and screamed every time.", "I ate a turkey leg the size of my arm.", "The lines were long, the rides were worth it."])
				fx["happiness"] = 9
		"zoo": txt = _pick(["A giraffe licked my hat.", "The penguins were the stars of the day.", "A monkey threw something at a man in a suit. Justice."])
		"aquarium": txt = _pick(["I stared at the jellyfish for a very long time.", "A shark swam right over my head in the tunnel."])
		"comedy": txt = _pick(["The comedian roasted my shirt. Fair.", "I laughed so hard I snorted, and the whole room heard."])
		"escape": txt = _pick(["We escaped with 40 seconds left.", "We did not escape. The staff had to let us out."])
		"minigolf": txt = _pick(["Hole-in-one on the windmill!", "I lost my ball in a fake volcano."])
		"theater":
			txt = _pick(["The play was three hours long and I loved every minute.", "I fell asleep in act two. The ending was apparently great."])
			fx["smarts"] = 1
		"spa_day":
			txt = "I soaked in the hot springs until my fingers pruned."
			fx["stress"] = -9
		"paintball":
			txt = _pick(["I got shot in the neck in the first minute. It left a mark.", "I took out the whole other team from a bush."])
			fx["health"] = 1
		"festival":
			txt = _pick(["Three days of music, mud and questionable showers. Life-changing.", "I lost my voice, my shoes and my friends. Found two of the three."])
			fx["happiness"] = 12
			fx["health"] = -3
			Grit.habit("partying", 6)
	Actions._done(d[1], str(d[2]), txt, fx)


func _movie(g: String) -> void:
	if Actions._out_of_time(): return
	var fee := _cost(15)
	if not Actions._can_pay(fee, "Movie"): return
	var d: Array = []
	for x in MOVIES:
		if x[0] == g:
			d = x
	var review := _pick(["It was great.", "Two hours I'll never get back.", "The twist got me.", "I cried. Don't tell anyone.", "The popcorn was the best part."])
	var fx := {"money": -fee, "happiness": 4}
	if g == "horror" and GameState.has_trait("Anxious"):
		fx["stress"] = 6
	Actions._done(d[1], "Movie theater", "I watched %s. %s" % [str(d[2]).to_lower(), review], fx)


func _vacation(dest: String, comp: String) -> void:
	var p := _p()
	var d: Array = []
	for x in TRIPS:
		if x[0] == dest:
			d = x
	var t := int(d[4])
	if int(p["time_left"]) < t:
		EventEngine.push_info("⏳", "Not enough time", "This trip takes %d time." % t)
		return
	var fly := Shop.has_any(["plane", "jet"])
	var price := _cost(int(d[3])) * (2 if comp != "" else 1)
	if fly:
		price = int(price * 0.6)
	if not Actions._can_pay(price, str(d[2])): return
	GameState.spend_time(t)
	var fx: Dictionary = (d[5] as Dictionary).duplicate()
	fx["money"] = -price
	GameState.counter("vacations")
	var r := randf()
	var txt := "I went on a %s." % str(d[2]).to_lower()
	if comp != "" and GameState.npcs.has(comp):
		var cn: Dictionary = GameState.npcs[comp]
		txt = "I took %s on a %s." % [cn["first"], str(d[2]).to_lower()]
		GameState.change_closeness(comp, 16)
		Bonds.remember(comp, "took me on a trip", true)
	if r < 0.1:
		txt += " The airline lost my luggage. I wore the same shirt for four days."
		fx["happiness"] = int(fx["happiness"]) - 4
	elif r < 0.17:
		txt += " I got food poisoning on day two."
		fx["health"] = int(fx.get("health", 0)) - 6
	elif r < 0.25 and comp == "" and p["partner"] == "":
		var cid := GameState.create_npc("crush", {"age": maxi(18, int(p["age"]) + randi_range(-5, 5)), "closeness": 50})
		txt += " I met %s on the trip. We're still texting." % GameState.npcs[cid]["first"]
	elif r < 0.3 and Shop.has_tag("compass"):
		txt += " Grandpa's old compass led me to a hidden beach nobody else knew about."
		fx["happiness"] = int(fx["happiness"]) + 4
	else:
		txt += " " + _pick(["Every photo looks like a postcard.", "I came back a slightly different person.", "I want to live there now.", "Ten out of ten."])
	if fly:
		txt += " I flew us there myself."
	Actions._done(d[1], "Vacation", txt, fx)


func _date(id: String, venue: String) -> void:
	var n := Bonds.ensure(id)
	if n.is_empty():
		return
	if not GameState.can_interact(id, "date"):
		return
	var costs := {"picnic": 0, "dinner": 80, "fancy": 300, "dancing": 60, "bowling": 40, "comedy": 50, "stars": 0, "getaway": 800}
	var fee := _cost(int(costs.get(venue, 0)))
	if Actions._out_of_time(): return
	if venue == "getaway" and not GameState.spend_time():
		GameState.player["time_left"] = int(GameState.player["time_left"]) + 1
		EventEngine.push_info("⏳", "Not enough time", "A getaway takes 2 time.")
		return
	if not Actions._can_pay(fee, "Date"):
		return
	GameState.mark_interacted(id, "date")
	var nm: String = n["first"]
	var d: int = {"picnic": 8, "dinner": 10, "fancy": 14, "dancing": 11, "bowling": 9, "comedy": 10, "stars": 12, "getaway": 22}.get(venue, 8)
	var line: String = {
		"picnic": _pick(["We ate sandwiches on a blanket and watched dogs.", "Ants found our picnic. We laughed it off."]),
		"dinner": _pick(["We split three desserts.", "We talked so much the food went cold."]),
		"fancy": _pick(["The menu had no prices. The bill had many.", "A violinist played at our table. %s blushed." % nm]),
		"dancing": _pick(["We salsa'd badly and enthusiastically.", "We slow-danced to a song that was not slow."]),
		"bowling": _pick(["%s beat me by one pin and did a victory dance." % nm, "We named our bowling team 'Split Happens'."]),
		"comedy": _pick(["The comedian picked on us. We became part of the act.", "%s laughed so hard %s cried." % [nm, GameState.pron(n["gender"], "he")]]),
		"stars": _pick(["We drove out of town and counted shooting stars.", "We lay on the car hood until 2 a.m."]),
		"getaway": _pick(["A cabin, a fireplace and no phone signal.", "We found a tiny hotel by the sea. Perfect."]),
	}.get(venue, "")
	var fx := {"money": -fee, "happiness": 5, "stress": -4}
	if Shop.has_tag("designer") or Shop.has_tag("charm"):
		d += 3
	if int(n.get("craziness", 30)) > 75 and randf() < 0.2:
		line += " Then %s picked a fight with the waiter." % nm
		d -= 10
	GameState.change_closeness(id, d)
	if venue == "getaway":
		Bonds.remember(id, "whisked me away for a weekend", true)
	Actions._done("🍷", "Date night", "Date night with %s. %s" % [nm, line], fx)


func _find_date(where: String) -> void:
	var p := _p()
	if Actions._out_of_time(): return
	match where:
		"premium":
			if not Actions._can_pay(_cost(80), "Premium app"): return
			p["money"] = int(p["money"]) - _cost(80)
		"speed":
			if not Actions._can_pay(_cost(40), "Speed dating"): return
			p["money"] = int(p["money"]) - _cost(40)
		"celeb":
			if not Actions._can_pay(_cost(100000), "Celebrity app"): return
			p["money"] = int(p["money"]) - _cost(100000)
	var want: String = "female" if p["gender"] == "male" else ("male" if p["gender"] == "female" else ("male" if randf() < 0.5 else "female"))
	if randf() < 0.12:
		want = p["gender"] if p["gender"] != "nonbinary" else "nonbinary"
	var age: int = p["age"]
	var lo := maxi(14, age - 3) if age < 18 else maxi(18, age - 9)
	var hi := mini(17, age + 2) if age < 18 else age + 9
	var count := 5 if where == "speed" else 1
	var roles := {}
	var body := ""
	var choices: Array = []
	for i in range(count):
		var cid := GameState.create_npc("crush", {"gender": want, "age": randi_range(lo, maxi(lo, hi)), "closeness": 30})
		var c: Dictionary = Bonds.ensure(cid)
		if where == "premium":
			c["looks"] = maxi(int(c["looks"]), randi_range(55, 95))
		if where == "celeb":
			c["looks"] = randi_range(70, 99)
			c["title"] = _pick(["Actor", "Pop star", "Athlete", "Model", "Influencer", "CEO"])
			c["money"] = randi_range(2000000, 80000000)
		var role := "c%d" % i
		roles[role] = cid
		var chance := clampf(0.35 + (GameState.stat("looks") - float(c["looks"])) / 160.0 + (0.1 if GameState.has_trait("Charmer") else 0.0) + (0.08 if Shop.has_any(["designer", "charm"]) else 0.0) + (0.1 if where == "premium" else 0.0) + (float(p.get("fame", 0)) - 60.0) / 200.0 * (1.0 if where == "celeb" else 0.0), 0.05, 0.9)
		body += "%s%s (%d) · looks %d%%%s\n" % ["" if count == 1 else "%d. " % (i + 1), GameState.full_name(cid), int(c["age"]), int(c["looks"]), (" · " + str(c["title"])) if c.has("title") else ""]
		choices.append({"label": "Ask out %s" % c["first"], "outcomes": [
			{"weight": chance, "text": "%s said yes! We're dating now." % c["first"], "new_partner": role, "keep_role": role, "effects": {"happiness": 8}},
			{"weight": 1.0 - chance, "text": "%s turned me down." % c["first"], "effects": {"happiness": -4}},
		]})
	choices.append({"label": "Nobody here", "outcomes": [{"text": "I went home alone. It's fine."}]})
	var place: String = {"street": _pick(["at a coffee shop", "at a friend's party", "at the gym", "in a bookstore"]), "app": "on a dating app", "premium": "on a premium dating app", "speed": "at speed dating", "celeb": "on a celebrity dating app"}.get(where, "")
	var head := "You met someone %s:\n" % place if count == 1 else "Five dates, twelve minutes each, %s:\n" % place
	if p["partner"] != "":
		body += "\nYou're already with %s. Dating someone else would be cheating." % GameState.npcs[p["partner"]]["first"]
	EventEngine.push_decision({"id": "_date", "icon": "💘", "title": "A potential match", "text": head + body, "choices": choices, "discard_unkept": true}, roles)


# ---------------------------------------------------------------- gambling

func _race() -> Dictionary:
	var w := GameState.world
	var stamp := "%d:%d" % [int(_p()["age"]), int(_p()["time_left"])]
	if str(w.get("race", {}).get("stamp", "")) != stamp:
		var horses: Array = []
		var total := 0.0
		for i in range(6):
			var f := randi_range(1, 5)
			var strength := float(f) + randf_range(0.0, 2.0)
			horses.append({"name": "%s %s" % [HORSE_A[randi() % HORSE_A.size()], HORSE_B[randi() % HORSE_B.size()]], "form": f, "s": strength, "jockey": ContentDB.random_last("us")})
			total += strength
		for h in horses:
			var prob := float(h["s"]) / total
			h["prob"] = prob
			h["odds"] = snappedf(maxf(1.2, 0.88 / prob), 0.1)
		w["race"] = {"stamp": stamp, "horses": horses}
	return w["race"]


func _gamble_ok(amt: int) -> bool:
	if Actions._out_of_time(): return false
	if not Actions._can_pay(amt, "Bet"):
		GameState.player["time_left"] = int(GameState.player["time_left"]) + 1
		return false
	GameState.counter("gambles")
	Grit.habit("gambling", 5 + int(log(float(maxi(amt, 10))) / log(10.0) * 2.0))
	return true


func _payout(game: String, amt: int, won: int, text: String) -> void:
	var net := won - amt
	Expansion.record_casino(net, amt)
	var fx := {"money": net, "happiness": 6 if net > 0 else (-4 if net < 0 else 0), "stress": 0 if net >= 0 else 3}
	if net > 0:
		GameState.counter("gamble_wins")
	if net >= 100000:
		GameState.add_milestone(_p()["age"], "won %s at the casino" % _money(net))
	Actions._done("🎰", game, text + (" I won %s." % _money(net) if net > 0 else (" I lost %s." % _money(-net) if net < 0 else " I broke even.")), fx)


const GAMBLE_GAMES := ["slots", "roulette", "rocket", "plinko", "scratch", "wheel", "highlow"]


func _casino(game: String, amt: int, choice: String) -> void:
	if game == "blackjack":
		if not _gamble_ok(amt): return
		Minigames.play("blackjack", {"bet": amt, "skill": 50, "difficulty": 1.0, "can_double": int(_p()["money"]) >= amt * 2}, Callable(self, "_bj_done").bind(amt))
		return
	if not _gamble_ok(amt): return
	if GAMBLE_GAMES.has(game):
		Minigames.play("g_" + game, {"bet": amt, "luck": Shop.luck(), "choice": choice, "money": int(_p()["money"]), "skill": 50, "difficulty": 1.0}, Callable(self, "_gamble_done").bind(game, amt, choice))
		return
	_casino_roll(game, amt, choice)


## What the minigame decided, paid out. With minigames off or headless it falls back
## to the plain roll, so the money always moves the same way.
func _gamble_done(_score: float, detail: Dictionary, game: String, amt: int, choice: String) -> void:
	if detail.get("auto", false) or not detail.has("won"):
		_casino_roll(game, amt, choice)
		return
	var extra := int(detail.get("extra", 0))
	_payout(game.capitalize(), amt + extra, int(detail["won"]), str(detail.get("text", "")))


func _casino_roll(game: String, amt: int, choice: String) -> void:
	var luck := Shop.luck()
	match game:
		"rocket":
			var cp := maxf(1.0, 0.96 / maxf(0.0001, 1.0 - randf()))
			var tgt := 1.0 + randf() * 1.5
			_payout("Rocket", amt, int(amt * tgt) if cp >= tgt else 0, "I tried to cash out at %.2fx. The rocket went to %.2fx." % [tgt, minf(cp, 99.0)])
		"plinko":
			var tab := [12.0, 3.0, 1.3, 0.6, 0.35, 0.6, 1.3, 3.0, 12.0]
			var k := 0
			for _i in range(8):
				if randf() < 0.5:
					k += 1
			_payout("Plinko", amt, int(amt * float(tab[k])), "The ball dropped into the %s× bucket." % str(tab[k]))
		"scratch":
			var wm: float = [2.0, 3.0, 5.0, 10.0, 25.0, 100.0][mini(5, int(pow(randf(), 3.0) * 6.0))]
			var hit := randf() < 0.27 * (1.0 + (luck - 1.0) * 0.12)
			_payout("Scratch card", amt, int(amt * wm) if hit else 0, "I scratched the card.")
		"wheel":
			var wt := [0.0, 2.0, 0.0, 1.0, 0.0, 0.5, 0.0, 3.0, 0.0, 1.0, 0.5, 0.0, 1.5, 0.0, 2.0, 3.5]
			var wv: float = wt[randi() % wt.size()]
			_payout("Lucky wheel", amt, int(amt * wv), "The wheel stopped on %s×." % str(wv))
		"roulette":
			var n := randi() % 37
			var red := [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36].has(n)
			var win := false
			var mult := 2
			match choice:
				"red": win = n != 0 and red
				"black": win = n != 0 and not red
				"odd": win = n != 0 and n % 2 == 1
				"even": win = n != 0 and n % 2 == 0
				"low": win = n >= 1 and n <= 18
				"high": win = n >= 19
				"dozen":
					win = n >= 13 and n <= 24
					mult = 3
				"seven":
					win = n == 7
					mult = 36
				"lucky":
					win = n == 17
					mult = 36
				"zero":
					win = n == 0
					mult = 36
			if not win and luck > 1.0 and randf() < (luck - 1.0) * 0.04:
				win = true
			var col := "green" if n == 0 else ("red" if red else "black")
			_payout("Roulette", amt, amt * mult if win else 0, "The ball landed on %d %s." % [n, col])
		"slots":
			var reels: Array = []
			for i in range(3):
				reels.append(SLOTS[_weighted_reel()])
			if randf() < (luck - 1.0) * 0.05:
				reels[2] = reels[1]
				reels[0] = reels[1]
			var mult2 := 0.0
			if reels[0] == reels[1] and reels[1] == reels[2]:
				mult2 = {"🍒": 5.0, "🍋": 8.0, "🔔": 12.0, "⭐": 20.0, "💎": 50.0, "7️⃣": 100.0}[reels[0]]
			elif reels[0] == reels[1] or reels[1] == reels[2]:
				mult2 = 1.5 if reels[1] != "🍒" else 2.0
			elif reels.has("🍒"):
				mult2 = 0.5
			_payout("Slots", amt, int(amt * mult2), "%s  %s  %s" % reels)
		"highlow":
			var a := randi_range(2, 14)
			var b := randi_range(2, 14)
			var names := {11: "Jack", 12: "Queen", 13: "King", 14: "Ace"}
			var an: String = names.get(a, str(a))
			var bn: String = names.get(b, str(b))
			var guess_high := a <= 8
			var won := (b > a and guess_high) or (b < a and not guess_high)
			if not won and randf() < (luck - 1.0) * 0.05:
				won = true
			_payout("High or low", amt, amt * 2 if won else 0, "The dealer showed a %s. I called %s. Next card: %s." % [an, "higher" if guess_high else "lower", bn])


func _weighted_reel() -> int:
	var w := [30, 25, 18, 13, 9, 5]
	var r := randi() % 100
	var acc := 0
	for i in range(w.size()):
		acc += w[i]
		if r < acc:
			return i
	return 0


func _bj_done(score: float, detail: Dictionary, amt: int) -> void:
	var res: String = str(detail.get("result", ""))
	if detail.get("auto", false) or res == "":
		var r := randf() / Shop.luck()
		res = "blackjack" if r < 0.045 else ("win" if r < 0.43 else ("push" if r < 0.52 else "lose"))
	if detail.get("doubled", false):
		amt *= 2
	var won := 0
	var txt := ""
	match res:
		"blackjack":
			won = int(amt * 2.5)
			txt = "Blackjack! Ace and a face card."
		"win":
			won = amt * 2
			txt = "I beat the dealer at blackjack%s." % (" on a double down" if detail.get("doubled", false) else "")
		"push":
			won = amt
			txt = "Blackjack push: same total as the dealer."
		_:
			txt = "The dealer beat me at blackjack."
	_payout("Blackjack", amt, won, txt)


func _horse(idx: int, amt: int) -> void:
	var race := _race()
	if not _gamble_ok(amt): return
	var horses: Array = race["horses"]
	Minigames.play("g_horses", {"bet": amt, "luck": Shop.luck(), "horses": horses, "pick": idx, "skill": 50, "difficulty": 1.0}, Callable(self, "_horse_done").bind(idx, amt))


func _horse_done(_score: float, detail: Dictionary, idx: int, amt: int) -> void:
	var race := _race()
	var horses: Array = race["horses"]
	GameState.world.erase("race")
	if not detail.get("auto", false) and detail.has("won"):
		_payout("Horse races", amt, int(detail["won"]), str(detail.get("text", "")))
		return
	var r := randf()
	var acc := 0.0
	var winner := 0
	for i in range(horses.size()):
		acc += float(horses[i]["prob"])
		if r < acc:
			winner = i
			break
	if winner != idx and randf() < (Shop.luck() - 1.0) * 0.05:
		winner = idx
	var mine: Dictionary = horses[idx]
	var won := int(amt * float(mine["odds"])) if winner == idx else 0
	var place := "won" if winner == idx else "finished behind %s" % horses[winner]["name"]
	_payout("Horse races", amt, won, "I bet on %s at %.1f to 1. %s %s." % [mine["name"], float(mine["odds"]) - 1.0, mine["name"], place])


func lottery() -> Dictionary:
	var w := GameState.world
	if not w.has("lottery"):
		w["lottery"] = {"jackpot": 18000000, "rolls": 0}
	return w["lottery"]


func lottery_yearly() -> void:
	var lot := lottery()
	if randf() < 0.18:
		var who := "%s %s from %s" % [ContentDB.random_first("male" if randf() < 0.5 else "female", "us"), ContentDB.random_last("us"), ["Ohio", "Lyon", "Osaka", "Leeds", "Recife", "Cebu", "Lagos", "Munich"][randi() % 8]]
		if int(lot["jackpot"]) > 100000000:
			GameState.add_log("🌍 %s won the %s lottery jackpot." % [who, _money(int(lot["jackpot"]))])
		lot["last_winner"] = "by %s at %s" % [who, _money(int(lot["jackpot"]))]
		lot["jackpot"] = randi_range(12, 25) * 1000000
		lot["rolls"] = 0
	else:
		lot["jackpot"] = int(int(lot["jackpot"]) * randf_range(1.25, 1.6))
		lot["rolls"] = int(lot["rolls"]) + 1


func _lottery(kind: String, count: int) -> void:
	var p := _p()
	var price: int = {"mega": 2, "scratch": 5, "pick3": 2}[kind] * count
	var cost := _cost(price)
	if Actions._out_of_time(): return
	if not Actions._can_pay(cost, "Lottery"):
		p["time_left"] = int(p["time_left"]) + 1
		return
	GameState.counter("gambles")
	GameState.counter("lottery_tickets", count)
	Grit.habit("gambling", 3 + count / 10)
	var luck := Shop.luck()
	var lot := lottery()
	var won := 0
	var txt := ""
	match kind:
		"mega":
			var jack := false
			var second := 0
			var third := 0
			for i in range(count):
				var r := randf()
				if r < luck / 2500000.0:
					jack = true
				elif r < luck / 60000.0:
					second += 1
				elif r < luck / 1500.0:
					third += 1
			if jack:
				_jackpot(int(lot["jackpot"]), cost)
				return
			won = second * 50000 + third * 500
			txt = "I bought %d Mega ticket%s. " % [count, "" if count == 1 else "s"]
			if second > 0:
				txt += "One matched five numbers: $50,000! "
			elif third > 0:
				txt += "%d matched three numbers. " % third
			else:
				txt += "Nothing. The jackpot is %s now." % _money(int(lot["jackpot"]))
		"scratch":
			var r2 := randf() / luck
			var prizes := [[0.00005, 10000], [0.001, 1000], [0.01, 100], [0.05, 20], [0.25, 5]]
			for pz in prizes:
				if r2 < float(pz[0]):
					won = int(pz[1])
					break
			txt = "I scratched off a card. " + ("A %s winner!" % _money(won) if won > 0 else "Nothing but gray dust under my nails.")
		"pick3":
			var mine := "%d%d%d" % [randi() % 10, randi() % 10, randi() % 10]
			var drawn := mine if randf() < luck / 1000.0 else "%d%d%d" % [randi() % 10, randi() % 10, randi() % 10]
			if drawn == mine:
				won = 500
			txt = "I played %s. They drew %s." % [mine, drawn]
	p["money"] = int(p["money"]) - cost + won
	var fx := {"happiness": 3 if won > cost else -1}
	if won >= 50000:
		GameState.add_milestone(p["age"], "won %s in the lottery" % _money(won))
	Actions._done("🎟️", "Lottery", txt, fx)


func _jackpot(amount: int, cost: int) -> void:
	var p := _p()
	p["money"] = int(p["money"]) - cost
	var tax := float(Places.tax())
	var lump := int(amount * 0.6 * (1.0 - tax))
	var yearly := int(amount / 30.0 * (1.0 - tax))
	GameState.add_milestone(p["age"], "won the lottery jackpot")
	GameState.counter("jackpots")
	lottery()["last_winner"] = "by me at %s" % _money(amount)
	lottery()["jackpot"] = 15000000
	EventEngine.push_decision({"id": "_jackpot", "icon": "🎉", "title": "JACKPOT", "text": "Every number matched. You just won the %s Mega jackpot.\n\nTake it as a lump sum (about 60%%, after tax), or yearly payments for 30 years?" % _money(amount), "choices": [
		{"label": "Lump sum: %s now" % _money(lump), "outcomes": [{"text": "I took the lump sum. %s landed in my account. My phone hasn't stopped ringing." % _money(lump), "effects": {"money": lump, "happiness": 30}, "flags": ["lottery_winner"]}]},
		{"label": "Annuity: %s a year for 30 years" % _money(yearly), "outcomes": [{"text": "I took the annuity: %s a year, every year." % _money(yearly), "effects": {"money": yearly, "happiness": 25}, "flags": ["lottery_winner", "lottery_annuity"]}]},
	]})
	p["annuity"] = yearly
	p["annuity_left"] = 29


# ---------------------------------------------------------------- family building

func _grade_word(v: float) -> String:
	if v >= 80: return "exceptional"
	if v >= 62: return "strong"
	if v >= 40: return "average"
	if v >= 22: return "weak"
	return "very poor"


func _fertility(k: String) -> void:
	var p := _p()
	if k == "test":
		if Actions._out_of_time(): return
		if not Actions._can_pay(_cost(300), "Fertility test"): return
		var fv := GameState.hidden("fertility")
		var extra := "" if int(p["age"]) < 35 else " Age is starting to work against me, though."
		Actions._done("🔬", "Fertility test", "The clinic says my fertility is %s.%s" % [_grade_word(fv), extra], {"money": -_cost(300)})
		return
	if p.get("expecting", false):
		EventEngine.push_info("🤰", "Already expecting", "A baby is already on the way.")
		return
	if Actions._out_of_time(): return
	match k:
		"ivf":
			var fee := _cost(15000)
			if not Actions._can_pay(fee, "IVF"): return
			var partner: String = p["partner"]
			var agree := partner == "" or randf() < 0.85
			if not agree:
				Actions._done("🧫", "IVF", "%s isn't ready for IVF." % GameState.npc(partner)["first"], {})
				return
			if randf() < (0.45 - maxf(0.0, int(p["age"]) - 38) * 0.03) * lerpf(0.6, 1.3, GameState.hidden("fertility") / 100.0):
				p["expecting"] = true
				p["ivf_twins"] = randf() < 0.3
				Actions._done("🧫", "IVF", "The IVF worked. We're expecting!", {"money": -fee, "happiness": 12})
			else:
				Actions._done("🧫", "IVF", "This round of IVF didn't take. The doctor says we can try again.", {"money": -fee, "happiness": -8, "stress": 6})
		"insem":
			var fee2 := _cost(3000)
			if not Actions._can_pay(fee2, "Insemination"): return
			if randf() < 0.3:
				p["expecting"] = true
				Actions._done("🧬", "Insemination", "It worked. I'm going to be a parent.", {"money": -fee2, "happiness": 10})
			else:
				Actions._done("🧬", "Insemination", "Not this time.", {"money": -fee2, "happiness": -4})
		"surrogate":
			var fee3 := _cost(60000)
			if not Actions._can_pay(fee3, "Surrogacy"): return
			if randf() < 0.75:
				p["expecting"] = true
				Actions._done("🤰", "Surrogacy", "Our surrogate is pregnant. Nine very long months ahead.", {"money": -fee3, "happiness": 10})
			else:
				Actions._done("🤰", "Surrogacy", "The first transfer didn't take. The agency will try again next year.", {"money": -fee3 / 2, "happiness": -6})


func _adopt(i: int) -> void:
	var p := _p()
	var why := _adopt_block()
	if why != "":
		EventEngine.push_info("🏠", "Adoption", why)
		return
	var k: Dictionary = GameState.world["adopt_kids"][i]
	var fee := _cost(int(k["fee"]))
	if Actions._out_of_time(): return
	if not Actions._can_pay(fee, "Adoption"): return
	var cid := GameState.create_npc("child", {"gender": k["gender"], "first": k["first"], "last": p["last"], "age": int(k["age"]), "closeness": 40 + int(k["behavior"]) / 3})
	var cn: Dictionary = Bonds.ensure(cid)
	cn["adopted"] = true
	cn["smarts"] = int(k["smarts"])
	cn["craziness"] = clampi(100 - int(k["behavior"]), 5, 95)
	k["taken"] = true
	GameState.counter("adoptions")
	GameState.counter("babies")
	GameState.add_milestone(p["age"], "adopted %s" % k["first"])
	Actions._done("🏠", "Adoption", "I adopted %s, age %d, from %s. %s" % [k["first"], int(k["age"]), k["from"], "First night home, %s fell asleep holding my hand." % GameState.pron(k["gender"], "he") if int(k["age"]) < 8 else "%s is guarded. That's okay. We have time." % GameState.pron(k["gender"], "he").capitalize()], {"money": -fee, "happiness": 12, "karma": 8})


func _foster() -> void:
	var p := _p()
	if _adopt_block() != "":
		EventEngine.push_info("🍼", "Foster care", _adopt_block())
		return
	if Actions._out_of_time(): return
	var g := "male" if randf() < 0.5 else "female"
	var nm := ContentDB.random_first(g, p["country"])
	GameState.counter("fostered")
	if randf() < 0.25:
		var cid := GameState.create_npc("child", {"gender": g, "first": nm, "last": p["last"], "age": randi_range(3, 14), "closeness": 60})
		Bonds.ensure(cid)["adopted"] = true
		GameState.counter("adoptions")
		Actions._done("🍼", "Foster care", "I fostered %s this year. At the end, %s asked if %s could stay. I said yes. We made it official." % [nm, GameState.pron(g, "he"), GameState.pron(g, "he")], {"happiness": 14, "karma": 12})
	else:
		Actions._done("🍼", "Foster care", "I fostered %s for the year. %s went back to family in the end. I think about %s a lot." % [nm, GameState.pron(g, "he").capitalize(), GameState.pron(g, "him")], {"happiness": 4, "karma": 10, "money": _cost(3000)})


func _rename(which: String, nm: String) -> void:
	var p := _p()
	var fee := _cost(200)
	if Actions._out_of_time(): return
	if not Actions._can_pay(fee, "Name change"): return
	var old: String = p[which]
	p[which] = nm
	GameState.add_milestone(p["age"], "changed their name from %s to %s" % [old, nm])
	Actions._done("🪪", "New name", "I legally changed my %s name from %s to %s." % [which, old, nm], {"money": -fee, "happiness": 3})


# ---------------------------------------------------------------- school life

func _clique(c: String) -> void:
	var ss := _ss()
	if c == "":
		ss["clique"] = ""
		Actions._done("🚶", "Cliques", "I left my clique. Lunch is lonelier, but quieter.", {"happiness": -2})
		return
	if Actions._out_of_time(): return
	var cd: Array = CLIQUES[c]
	var need := str(cd[2])
	var ok := need == "" or GameState.stat(need) >= float(cd[3]) or randf() < 0.25
	if c == "populars" and float(ss["popularity"]) < 55 and randf() < 0.6:
		ok = false
	if ok:
		ss["clique"] = c
		ss["popularity"] = clampf(float(ss["popularity"]) + (10.0 if c == "populars" else 4.0), 0.0, 100.0)
		for i in range(randi_range(1, 2)):
			GameState.create_npc("friend", {"age": int(_p()["age"]) + randi_range(-1, 1), "closeness": 50})
		GameState.counter("cliques")
		Actions._done(cd[0], str(cd[1]), "I'm one of the %s now. They sat me at their table." % str(cd[1]).to_lower(), {"happiness": 6})
	else:
		ss["popularity"] = clampf(float(ss["popularity"]) - 5.0, 0.0, 100.0)
		Actions._done(cd[0], str(cd[1]), "I tried to join the %s. They laughed. Loudly." % str(cd[1]).to_lower(), {"happiness": -6})


func _club_join(c: String) -> void:
	var ss := _ss()
	if ss["clubs"].has(c):
		ss["clubs"].erase(c)
		Actions._done("🏫", "Clubs", "I quit the %s." % _club_name(c).to_lower(), {})
		return
	if ss["clubs"].size() >= 2: return
	if Actions._out_of_time(): return
	ss["clubs"].append(c)
	GameState.counter("clubs_joined")
	Actions._done("🏫", _club_name(c), "I joined the %s." % _club_name(c).to_lower(), {"happiness": 3})


func _club_name(c: String) -> String:
	for x in SCHOOL_CLUBS:
		if x[0] == c:
			return str(x[2])
	return c


func _sport(s: String) -> void:
	var ss := _ss()
	if s == "":
		ss["sport"] = ""
		ss["captain"] = false
		Actions._done("🚪", "Sports", "I quit the team.", {})
		return
	if Actions._out_of_time(): return
	var nm := s
	for x in SPORTS:
		if x[0] == s:
			nm = str(x[2])
	if ss["sport"] == s:
		var fx := {"health": 3, "stress": 2}
		if not ss["captain"] and randf() < 0.18 + (GameState.stat("health") - 60.0) / 150.0:
			ss["captain"] = true
			ss["popularity"] = clampf(float(ss["popularity"]) + 10.0, 0.0, 100.0)
			GameState.counter("captain")
			Actions._done("🏆", nm, "I trained harder than anyone. Coach made me team captain!", fx)
		elif randf() < 0.15:
			GameState.counter("school_titles")
			ss["popularity"] = clampf(float(ss["popularity"]) + 6.0, 0.0, 100.0)
			Actions._done("🏆", nm, "We won the regional championship! I scored in the final.", fx.merged({"happiness": 10}))
		elif randf() < 0.08:
			Actions._done("🤕", nm, "I got hurt at practice and sat out three weeks.", {"health": -8})
		else:
			Actions._done("🏃", nm, "Practice, practice, practice. I'm getting better.", fx)
		return
	var ok := randf() < 0.3 + (GameState.stat("health") - 50.0) / 100.0 + (0.15 if GameState.has_trait("Athletic") else 0.0)
	if ok:
		ss["sport"] = s
		ss["popularity"] = clampf(float(ss["popularity"]) + 5.0, 0.0, 100.0)
		Actions._done("🏆", nm, "I made the %s team!" % nm.to_lower(), {"happiness": 8, "health": 2})
	else:
		Actions._done("🏆", nm, "I didn't make the %s team. Coach said to try again next year." % nm.to_lower(), {"happiness": -5})


func _school_act(k: String) -> void:
	var p := _p()
	var ss := _ss()
	if Actions._out_of_time(): return
	match k:
		"principal":
			var r := randf()
			if r < 0.4:
				Actions._done("🧑‍🏫", "Principal", "I complained about the cafeteria food. The principal nodded and did nothing.", {})
			elif r < 0.7:
				Actions._done("🧑‍🏫", "Principal", "I charmed the principal. I now have a hall pass forever.", {"happiness": 3, "school": 1})
			else:
				Actions._done("🧑‍🏫", "Principal", "The principal asked why I'm not in class. Detention.", {"school": -3, "happiness": -3})
		"nurse":
			if randf() < 0.5:
				Actions._done("🩹", "School nurse", "The nurse let me lie down for an hour. I missed a math test.", {"stress": -3, "school": -1})
			else:
				Actions._done("🩹", "School nurse", "The nurse took my temperature, said I'm fine, and sent me back.", {})
		"cheat":
			if randf() < 0.65 - (0.1 if GameState.has_trait("Anxious") else 0.0):
				Actions._done("📝", "Cheating", "I wrote the answers on my water bottle label. A+.", {"school": 8, "karma": -3})
			else:
				GameState.set_flag("caught_cheating")
				for par in GameState.npcs_with("mother") + GameState.npcs_with("father"):
					GameState.change_closeness(par, -8)
				Actions._done("📝", "Cheating", "The teacher caught me cheating. Zero on the test, and a call home.", {"school": -12, "happiness": -8})
		"talent":
			var act2 := _pick(["sang a ballad", "did a magic act", "did stand-up", "danced", "played the %s" % _pick(["piano", "guitar", "violin", "kazoo"])])
			var sk := GameState.stat("looks") / 200.0 + float(p.get("talent_voice", 0)) * 0.05 + float(p.get("talent_acting", 0)) * 0.04 + (0.1 if Shop.has_tag("instrument") else 0.0) + randf() * 0.5
			if sk >= 0.7:
				ss["popularity"] = clampf(float(ss["popularity"]) + 12.0, 0.0, 100.0)
				GameState.counter("talent_wins")
				Actions._done("🎤", "Talent show", "I %s at the talent show and won first place!" % act2, {"happiness": 12, "fame": 1})
			elif sk >= 0.4:
				Actions._done("🎤", "Talent show", "I %s at the talent show. Polite applause." % act2, {"happiness": 3})
			else:
				ss["popularity"] = clampf(float(ss["popularity"]) - 8.0, 0.0, 100.0)
				Actions._done("🎤", "Talent show", "I %s at the talent show. Someone recorded it. It's everywhere now." % act2, {"happiness": -10})
		"president":
			var ch := float(ss["popularity"]) / 110.0 + (0.1 if GameState.has_trait("Charmer") else 0.0)
			if randf() < ch:
				GameState.set_flag("class_president")
				GameState.add_milestone(p["age"], "was elected class president")
				Actions._done("🗳️", "Election", "I won! Class president. My first act: longer lunches.", {"happiness": 10, "popularity": 8})
			else:
				Actions._done("🗳️", "Election", "I lost to someone who promised a vending machine in every hallway.", {"happiness": -5})
		"dance":
			var crush := ""
			for id in GameState.npcs.keys():
				var n: Dictionary = GameState.npcs[id]
				if n["alive"] and n["relation"] in ["crush", "classmate"] and abs(int(n["age"]) - int(p["age"])) <= 2:
					crush = id
			if crush != "" and randf() < 0.55:
				GameState.change_closeness(crush, 15)
				Actions._done("💃", "School dance", "I asked %s to dance. We slow-danced to a song that was way too long. Perfect." % GameState.npcs[crush]["first"], {"happiness": 8})
			else:
				Actions._done("💃", "School dance", _pick(["I danced with my friends all night.", "I stood by the snack table. Very good snacks.", "The DJ was a teacher. It was exactly as bad as it sounds."]), {"happiness": 4})
		"prom":
			ss["prom"] = true
			var date := ""
			if p["partner"] != "":
				date = GameState.npcs[p["partner"]]["first"]
			var crown := randf() < float(ss["popularity"]) / 160.0 + GameState.stat("looks") / 400.0
			var title := "prom king" if p["gender"] == "male" else ("prom queen" if p["gender"] == "female" else "prom royalty")
			var txt := "I went to prom%s. " % (" with " + date if date != "" else " with my friends")
			var fx := {"happiness": 8, "money": -_cost(200)}
			if crown:
				txt += "Then they called my name: %s!" % title
				fx["happiness"] = 16
				GameState.add_milestone(p["age"], "was crowned %s" % title)
				GameState.counter("prom_crowns")
			else:
				txt += _pick(["The limo broke down. We walked the last mile in formal wear.", "We danced until our feet hurt.", "Someone spiked the punch. I did not drink the punch."])
			if p["partner"] != "":
				GameState.change_closeness(p["partner"], 10)
			Actions._done("👑", "Prom", txt, fx)


# ================================================================ yearly

func yearly() -> void:
	var p := _p()
	var dd: String = p.get("diet", "")
	if dd != "" and DIETS.has(dd):
		GameState.apply_effects(DIETS[dd][3])
	if int(p.get("annuity_left", 0)) > 0:
		p["annuity_left"] = int(p["annuity_left"]) - 1
		p["money"] = int(p["money"]) + int(p.get("annuity", 0))
		GameState.add_log("My lottery annuity paid out %s." % _money(int(p.get("annuity", 0))))
	var ss := _ss()
	if GameState.in_school() or GameState.in_university():
		var fx := {}
		for c in ss["clubs"]:
			for x in SCHOOL_CLUBS:
				if x[0] == c:
					for k in x[3].keys():
						fx[k] = int(fx.get(k, 0)) + int(x[3][k])
		if ss["sport"] != "":
			fx["health"] = int(fx.get("health", 0)) + 2
		var target := 40.0 + (GameState.stat("looks") - 50.0) * 0.3 + (8.0 if ss["clique"] == "populars" else 0.0) + (6.0 if ss["sport"] != "" else 0.0) + (5.0 if ss["captain"] else 0.0)
		ss["popularity"] = clampf(lerpf(float(ss["popularity"]), target, 0.25) + randf_range(-3.0, 3.0), 0.0, 100.0)
		if not fx.is_empty():
			GameState.apply_effects(fx)
	elif int(p["age"]) >= 19 and (ss["clique"] != "" or ss["sport"] != "" or not ss["clubs"].is_empty()):
		ss["clique"] = ""
		ss["sport"] = ""
		ss["captain"] = false
		ss["clubs"] = []
	lottery_yearly()


func extracurricular_bonus() -> float:
	var ss := _ss()
	return 0.03 * ss["clubs"].size() + (0.04 if ss["sport"] != "" else 0.0) + (0.04 if ss["captain"] else 0.0) + (0.03 if GameState.has_flag("class_president") else 0.0)
