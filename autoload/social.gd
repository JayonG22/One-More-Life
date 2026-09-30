extends Node

## Social media platforms and the celebrity cameo cast.

const PLATFORMS := {
	"snapgram": {"name": "Snapgram", "icon": "📸", "sub": "Photos and stories", "needs": ["phone"], "base": 60, "pay": 0.0},
	"clipz": {"name": "Clipz", "icon": "🎵", "sub": "Short videos, fast fame", "needs": ["phone"], "base": 90, "pay": 0.0},
	"tubehub": {"name": "TubeHub", "icon": "▶️", "sub": "Long videos · ad revenue", "needs": ["camera", "phone", "laptop"], "base": 40, "pay": 0.004},
	"streamr": {"name": "Streamr", "icon": "🟣", "sub": "Live streams · subs and tips", "needs": ["webcam"], "base": 30, "pay": 0.012},
	"chirp": {"name": "Chirp", "icon": "🐦", "sub": "Hot takes and threads", "needs": ["phone", "laptop"], "base": 50, "pay": 0.0},
}
const CONTENT := {
	"snapgram": [["selfie", "🤳", "Selfie", "looks"], ["food", "🍜", "Food pic", ""], ["travel", "🏝️", "Travel photo", "trip"], ["fitness", "💪", "Gym progress", "health"], ["fashion", "👗", "Outfit of the day", "designer"], ["pet", "🐶", "Pet photo", "pet"], ["sunset", "🌅", "Sunset", ""], ["couple", "💑", "Couple photo", "partner"]],
	"clipz": [["dance", "💃", "Dance trend", "looks"], ["skit", "😂", "Comedy skit", "funny"], ["challenge", "🔥", "Viral challenge", ""], ["lipsync", "🎤", "Lip sync", ""], ["prank", "🎭", "Prank video", "prank"], ["cooking", "🍳", "Quick recipe", "cookbook"], ["glowup", "✨", "Glow-up reveal", "looks"]],
	"tubehub": [["vlog", "🎥", "Vlog", "camera"], ["gaming", "🎮", "Gaming video", "gamer"], ["tutorial", "📐", "Tutorial", "smarts"], ["review", "📦", "Product review", "stuff"], ["docu", "🎞️", "Mini documentary", "smarts"], ["prank2", "🎭", "Prank video", "prank"], ["music", "🎸", "Music cover", "instrument"]],
	"streamr": [["gamestream", "🎮", "Gaming stream", "gamer"], ["chatting", "💬", "Just chatting", "funny"], ["musicstream", "🎹", "Music stream", "instrument"], ["artstream", "🎨", "Art stream", ""], ["irl", "🚶", "IRL stream", ""], ["marathon", "⏱️", "24-hour charity marathon", ""]],
	"chirp": [["take", "🌶️", "A hot take", ""], ["joke", "🃏", "A joke", "funny"], ["thread", "🧵", "A long thread", "smarts"], ["news", "📰", "Breaking news reaction", ""], ["rant", "😡", "A rant", ""], ["celeb", "⭐", "Reply to a celebrity", ""]],
}
const BRANDS := {
	"snapgram": ["a skincare brand", "a swimwear line", "a teeth-whitening kit", "a sneaker drop", "a detox tea (please don't)"],
	"clipz": ["an energy drink", "a mobile game", "a fast-food chain", "a phone case company", "an earbuds brand"],
	"tubehub": ["a VPN", "a meal kit", "a mattress company", "a mobile game", "a website builder"],
	"streamr": ["a gaming chair", "an energy drink", "a headset brand", "a game studio", "a pizza chain"],
	"chirp": ["a fintech app", "a news site", "a crypto exchange (risky)", "a bookshop", "a sports betting app"],
}

## Original celebrities. [name, icon, kind, sub]
const CELEBS := [
	["Nova Reign", "🎤", "pop", "Pop superstar"], ["Lil Static", "🎧", "rap", "Rapper"], ["Dax Holloway", "🎬", "actor", "Action movie star"],
	["Marisol Vega", "🌹", "actor", "Telenovela icon"], ["Theo Blackwood", "🚀", "tech", "Tech billionaire"], ["PixelPrince", "🎮", "streamer", "Streaming king"],
	["Juno Park", "✨", "pop", "Idol-group leader"], ["Ronan Frost", "⚽", "athlete", "Star striker"], ["Bea Montclair", "👗", "model", "Supermodel"],
	["Chef Augustin Beaumarché", "👨‍🍳", "chef", "TV chef, famous for yelling"], ["Kendrix Wolfe", "🎤", "rap", "Chart-topping rapper"], ["Sienna Starling", "🌟", "actor", "Oscar-darling actress"],
	["Big Mo Okafor", "🏀", "athlete", "Basketball MVP"], ["Luna Vex", "🖤", "pop", "Alt-pop singer"], ["Dr. Rex Harlan", "🩺", "tv", "Daytime TV doctor"],
	["Gigi Glitz", "💄", "influencer", "Beauty influencer"], ["Captain Crunchwell", "🤸", "influencer", "Prank channel legend"], ["Aiyana Cross", "🥊", "athlete", "Undefeated fighter"],
	["Maestro Vittorio Lanza", "🎻", "classical", "Celebrity violinist"], ["Tess Tumbleweed", "🤠", "country", "Country music queen"], ["Kai Ocean", "🏄", "athlete", "Pro surfer"],
	["Priya Solstice", "🧘", "influencer", "Wellness guru"], ["DJ Neon Moth", "🎛️", "dj", "Festival headliner"], ["Hugo Brennan", "🎩", "tv", "Late-night talk show host"],
	["Yuki Amano", "🎮", "streamer", "Speedrun champion"], ["Zara Quill", "📚", "author", "Bestselling novelist"], ["Rocco Valentine", "💪", "actor", "Wrestler-turned-actor"],
	["Delphine Moreau", "🎬", "director", "Auteur director"], ["Sunny Adeyemi", "🎤", "pop", "Afrobeats star"], ["Mateus Rocha", "⚽", "athlete", "Football legend"],
]


func _p() -> Dictionary:
	return GameState.player


func celeb(kind: String = "") -> Array:
	var pool: Array = CELEBS if kind == "" else CELEBS.filter(func(c): return str(c[2]) == kind)
	if pool.is_empty():
		pool = CELEBS
	return pool[randi() % pool.size()]


func celeb_name(kind: String = "") -> String:
	return str(celeb(kind)[0])


func socials() -> Dictionary:
	var p := _p()
	if not p.has("socials") or not (p["socials"] is Dictionary):
		p["socials"] = {}
		if int(p.get("followers", 0)) > 0:
			p["socials"]["snapgram"] = {"followers": int(p["followers"]), "posts": 5, "handle": str(p.get("first", "me")).to_lower(), "niche": "", "verified": false, "earned": 0, "last": int(p.get("age", 0))}
	return p["socials"]


func acct(pid: String) -> Dictionary:
	return socials().get(pid, {})


func total() -> int:
	var t := 0
	for k in socials().keys():
		t += int(socials()[k].get("followers", 0))
	return t


func _sync() -> void:
	_p()["followers"] = total()


func _fmt(v: int) -> String:
	return Careers._fmt_big(v)


func _can(pid: String) -> String:
	var p := _p()
	if int(p["age"]) < 13:
		return "You need to be 13"
	var needs: Array = PLATFORMS[pid]["needs"]
	if pid == "streamr":
		if not Shop.has_tag("webcam") or not Shop.has_any(["gaming_pc", "laptop", "console"]):
			return "Needs a webcam plus a computer or console"
		return ""
	if not Shop.has_any(needs):
		return "Needs a %s" % " or ".join(needs.map(func(n): return {"phone": "phone", "camera": "camera", "laptop": "laptop", "webcam": "webcam"}.get(n, n)))
	return ""


# ================================================================ menus

func menu(key: String) -> Dictionary:
	var parts := key.split(":")
	if key == "" or key == "root":
		var rows: Array = []
		for pid in PLATFORMS.keys():
			var pl: Dictionary = PLATFORMS[pid]
			var a := acct(pid)
			var why := _can(pid)
			var sub: String = pl["sub"]
			if not a.is_empty():
				sub = "%s followers%s%s" % [_fmt(int(a["followers"])), " · ✔️ verified" if a.get("verified", false) else "", (" · " + str(a.get("niche_name", ""))) if a.get("niche_name", "") != "" else ""]
			elif why != "":
				sub = "🔒 " + why
			rows.append({"icon": pl["icon"], "name": pl["name"], "sub": sub, "menu": "social:" + pid, "on": why == "" or not a.is_empty()})
		var info: Array = ["Total followers: %s · Fame %d" % [_fmt(total()), int(_p().get("fame", 0))], "Stick to one kind of content per platform to build a niche. Gear from the electronics store makes you better."]
		return {"icon": "📱", "title": "Social media", "rows": rows, "info": info}
	var pid: String = parts[0]
	if not PLATFORMS.has(pid):
		return {"icon": "📱", "title": "", "rows": []}
	if parts.size() > 1 and parts[1] == "post":
		return _post_menu(pid)
	return _plat_menu(pid)


func _plat_menu(pid: String) -> Dictionary:
	var pl: Dictionary = PLATFORMS[pid]
	var a := acct(pid)
	var rows: Array = []
	var why := _can(pid)
	if a.is_empty():
		rows.append({"icon": "➕", "name": "Create a %s account" % pl["name"], "sub": why if why != "" else "Pick a handle and go", "act": "social:join", "arg": pid, "on": why == ""})
		return {"icon": pl["icon"], "title": pl["name"], "rows": rows}
	var f := int(a["followers"])
	rows.append({"icon": pl["icon"], "name": "Post something", "sub": "Pick what to make · 1 time", "menu": "social:%s:post" % pid, "on": why == ""})
	rows.append({"icon": "🤝", "name": "Collab with another creator", "sub": "Borrow their audience", "act": "social:collab", "arg": pid, "on": f >= 1000})
	rows.append({"icon": "💼", "name": "Find a sponsor", "sub": "Needs 10K followers" if f < 10000 else "Brands that fit your niche pay more", "act": "social:sponsor", "arg": pid, "on": f >= 10000})
	if not a.get("verified", false):
		rows.append({"icon": "✔️", "name": "Request verification", "sub": "Needs 100K followers", "act": "social:verify", "arg": pid, "on": f >= 100000})
	rows.append({"icon": "🛒", "name": "Buy followers", "sub": "%s for 5,000 · risk of a ban" % GameState.fmt_money(Actions._cost(150)), "act": "social:buy", "arg": pid, "on": true})
	rows.append({"icon": "🗑️", "name": "Delete your account", "sub": "Start over, or log off for good", "act": "social:delete", "arg": pid, "on": true})
	var info: Array = ["@%s · %s followers · %d posts" % [a.get("handle", "me"), _fmt(f), int(a.get("posts", 0))]]
	if a.get("niche_name", "") != "":
		info.append("Known for: %s" % a["niche_name"])
	if float(pl["pay"]) > 0:
		info.append("Earned %s here so far" % GameState.fmt_money(int(a.get("earned", 0))))
	return {"icon": pl["icon"], "title": pl["name"], "rows": rows, "info": info}


func _post_menu(pid: String) -> Dictionary:
	var a := acct(pid)
	var rows: Array = []
	for c in CONTENT[pid]:
		var bonus := _content_bonus(str(c[3]))
		var sub := "Your niche" if a.get("niche", "") == c[0] else ("Off-niche" if a.get("niche", "") != "" else "")
		if bonus > 1.05:
			sub += (" · " if sub != "" else "") + "you're good at this"
		elif bonus < 0.95:
			sub += (" · " if sub != "" else "") + _hint(str(c[3]))
		rows.append({"icon": c[1], "name": c[2], "sub": sub, "act": "social:post", "arg": [pid, c[0]], "on": true})
	return {"icon": PLATFORMS[pid]["icon"], "title": "Post on " + PLATFORMS[pid]["name"], "rows": rows}


func _hint(need: String) -> String:
	match need:
		"looks": return "better with high looks"
		"trip": return "better after a vacation"
		"health": return "better when you're fit"
		"designer": return "better with designer clothes"
		"pet": return "needs a pet"
		"partner": return "needs a partner"
		"funny": return "better if you're funny"
		"prank": return "a whoopee cushion helps"
		"cookbook": return "a cookbook helps"
		"camera": return "a pro camera helps"
		"gamer": return "needs a console or gaming PC"
		"smarts": return "better with high smarts"
		"stuff": return "better if you own nice things"
		"instrument": return "needs an instrument"
	return ""


func _content_bonus(need: String) -> float:
	var p := _p()
	match need:
		"looks": return 0.6 + GameState.stat("looks") / 110.0
		"health": return 0.6 + GameState.stat("health") / 120.0
		"smarts": return 0.6 + GameState.stat("smarts") / 120.0
		"trip": return 1.4 if GameState.get_counter("vacations") > int(p.get("_last_trip_posted", 0)) else 0.7
		"designer": return 1.4 if Shop.has_tag("designer") else 0.85
		"pet": return 1.5 if not GameState.npcs_with("pet").is_empty() else 0.3
		"partner": return 1.3 if p["partner"] != "" else 0.3
		"funny": return 1.4 if GameState.has_trait("Funny") else 0.9
		"prank": return 1.3 if Shop.has_tag("prank") else 0.95
		"cookbook": return 1.3 if Shop.has_tag("cookbook") else 0.9
		"camera": return 1.4 if Shop.has_tag("camera") else 0.8
		"gamer": return 1.3 if Shop.has_any(["console", "gaming_pc"]) else 0.3
		"stuff": return 0.8 + minf(0.8, owned_value() / 50000.0)
		"instrument": return 1.3 if Shop.has_tag("instrument") else 0.3
	return 1.0


func owned_value() -> float:
	var v := 0.0
	for it in Shop.owned():
		v += float(it.get("value", 0))
	return v


# ================================================================ actions

func act(key: String, arg = null) -> void:
	var p := _p()
	if key != "join":
		var pid0: String = str(arg[0]) if arg is Array else str(arg)
		if not socials().has(pid0):
			return
	match key:
		"join":
			var pid: String = arg
			if _can(pid) != "": return
			var handle := "%s%s%d" % [str(p["first"]).to_lower(), ["", "_", ".", "x"][randi() % 4], randi_range(1, 999)]
			socials()[pid] = {"followers": randi_range(3, 40), "posts": 0, "handle": handle, "niche": "", "verified": false, "earned": 0, "last": -1}
			_sync()
			Actions._done(PLATFORMS[pid]["icon"], PLATFORMS[pid]["name"], "I made a %s account: @%s. My mom was my first follower." % [PLATFORMS[pid]["name"], handle], {"happiness": 2})
		"post":
			_post(str(arg[0]), str(arg[1]))
		"collab":
			_collab(str(arg))
		"sponsor":
			_sponsor(str(arg))
		"verify":
			var a := acct(str(arg))
			if randf() < 0.55 + float(p.get("fame", 0)) / 150.0:
				a["verified"] = true
				GameState.counter("verified")
				Actions._done("✔️", "Verified", "%s gave me the blue check." % PLATFORMS[arg]["name"], {"happiness": 6, "fame": 2})
			else:
				Actions._done("✔️", "Verification", "%s said I'm not \"notable\" enough yet." % PLATFORMS[arg]["name"], {"happiness": -3})
		"buy":
			var cost := Actions._cost(150)
			if not Actions._can_pay(cost, "Buy followers"): return
			var a2 := acct(str(arg))
			if randf() < 0.18:
				a2["followers"] = int(int(a2["followers"]) * 0.6)
				_sync()
				Actions._done("🚫", "Busted", "%s caught the fake followers and wiped a big chunk of my real ones too." % PLATFORMS[arg]["name"], {"money": -cost, "happiness": -6})
			else:
				a2["followers"] = int(a2["followers"]) + 5000
				_sync()
				Actions._done("🛒", "Bought followers", "5,000 new followers with names like user8847203. Engagement did not improve.", {"money": -cost})
		"delete":
			socials().erase(str(arg))
			_sync()
			Actions._done("🗑️", "Deleted", "I deleted my %s. The silence is nice." % PLATFORMS[arg]["name"], {"stress": -5})


func _post(pid: String, cid: String) -> void:
	var p := _p()
	if _can(pid) != "": return
	if Actions._out_of_time(): return
	var a := acct(pid)
	var c: Array = []
	for x in CONTENT[pid]:
		if x[0] == cid:
			c = x
	var pl: Dictionary = PLATFORMS[pid]
	var q := _content_bonus(str(c[3])) * (1.15 if Shop.has_tag("camera") and pid in ["snapgram", "tubehub"] else 1.0) * (1.1 if Shop.has_tag("phone") and _flagship() else 1.0)
	if Shop.has_tag("camera") and pid == "snapgram":
		q *= 1.05
	var niche_mult := 1.0
	if a["niche"] == "":
		if int(a["posts"]) >= 2:
			a["niche"] = cid
			a["niche_name"] = str(c[2])
	elif a["niche"] == cid:
		niche_mult = 1.5
	else:
		niche_mult = 0.6
	var f := int(a["followers"])
	var base := float(pl["base"]) * q * niche_mult
	var gain := int(base * randf_range(0.5, 1.8) + f * randf_range(0.01, 0.05) * q * niche_mult)
	var txt := ""
	var fx := {"happiness": 2}
	var viral := randf() < 0.035 * q * niche_mult + (0.05 if a.get("verified", false) else 0.0)
	if cid == "celeb":
		var cel := celeb()
		if randf() < 0.12:
			viral = true
			txt = "I replied to %s. %s replied back!" % [cel[0], cel[0]]
		else:
			txt = "I replied to %s. Nothing, but %d people liked my reply." % [cel[0], randi_range(2, 80)]
	elif cid == "take" or cid == "rant":
		if randf() < 0.18:
			var lose := int(f * randf_range(0.05, 0.25))
			a["followers"] = maxi(0, f - lose)
			a["posts"] = int(a["posts"]) + 1
			_sync()
			GameState.counter("cancelled")
			Actions._done("🔥", pl["name"], "My %s blew up the wrong way. I lost %s followers and my name was trending for all the wrong reasons." % [str(c[2]).to_lower(), _fmt(lose)], {"happiness": -8, "stress": 8, "fame": 1})
			return
	elif cid == "marathon":
		var raised := int(f * randf_range(0.05, 0.3)) + randi_range(50, 500)
		txt = "I streamed for 24 hours straight and raised %s for charity." % GameState.fmt_money(raised)
		fx["karma"] = 8
		fx["health"] = -3
	if viral:
		gain = int(gain * randf_range(8.0, 40.0)) + randi_range(5000, 80000)
		GameState.counter("viral")
		fx["fame"] = randi_range(2, 8)
		fx["happiness"] = 10
		txt = (txt + " " if txt != "" else "") + "It went VIRAL. %s new followers." % _fmt(gain)
	elif txt == "":
		txt = _post_text(pid, cid, gain)
	a["followers"] = int(a["followers"]) + gain
	a["posts"] = int(a["posts"]) + 1
	a["last"] = int(p["age"])
	if str(c[3]) == "trip":
		p["_last_trip_posted"] = GameState.get_counter("vacations")
	if pid in ["streamr"]:
		var tips := int(int(a["followers"]) * randf_range(0.002, 0.01)) + randi_range(0, 40)
		a["earned"] = int(a.get("earned", 0)) + tips
		fx["money"] = tips
		txt += " Chat tipped %s." % GameState.fmt_money(tips)
	_sync()
	GameState.counter("posts")
	Actions._done(pl["icon"], pl["name"], txt, fx)


func _flagship() -> bool:
	for it in Shop.owned():
		if str(it.get("name", "")) == "Flagship smartphone":
			return true
	return false


func _post_text(pid: String, cid: String, gain: int) -> String:
	var lines := {
		"selfie": ["I posted a selfie with perfect lighting.", "I posted a selfie. My aunt commented \"beautiful!!\" four times."],
		"food": ["I posted my brunch. The avocado toast did numbers.", "I posted a photo of homemade ramen."],
		"travel": ["I posted my vacation photos.", "I posted a sunset from my trip. Everyone is jealous."],
		"fitness": ["I posted my gym progress.", "I posted a sweaty mirror selfie with an inspirational caption."],
		"fashion": ["I posted my outfit of the day.", "I posted a fit check."],
		"pet": ["I posted my pet in a tiny hat. The internet loves it.", "I posted my pet asleep in a funny position."],
		"sunset": ["I posted a sunset. #nofilter (there was a filter)"],
		"couple": ["I posted a couple photo.", "I posted us at dinner. Hearts everywhere."],
		"dance": ["I learned the new dance trend and posted it.", "I nailed the dance on the fourteenth take."],
		"skit": ["I posted a comedy skit where I play every character.", "I posted a skit about group projects."],
		"challenge": ["I did the latest challenge.", "I posted my attempt at the challenge. It did not go well, which is why it did well."],
		"lipsync": ["I lip-synced to a power ballad with full commitment."],
		"prank": ["I pranked my roommate on camera.", "I posted a prank video. Nobody got hurt. Mostly."],
		"prank2": ["I posted a long prank video.", "I pranked my whole family on camera."],
		"cooking": ["I posted a 30-second recipe.", "I posted a recipe that's mostly cheese."],
		"glowup": ["I posted a glow-up reveal."],
		"vlog": ["I posted a vlog about my week.", "I vlogged a day in my life. My life is apparently interesting."],
		"gaming": ["I posted a gaming video.", "I uploaded my best clutch moments."],
		"tutorial": ["I posted a tutorial.", "I posted a step-by-step guide that actually helps people."],
		"review": ["I reviewed my stuff on camera.", "I posted an honest review. The brand did not like it."],
		"docu": ["I posted a mini documentary about my town's weirdest legend."],
		"music": ["I posted a music cover.", "I posted an original song."],
		"gamestream": ["I streamed games for five hours.", "I streamed a horror game and screamed on cue."],
		"chatting": ["I did a just-chatting stream.", "I talked to chat for three hours about nothing."],
		"musicstream": ["I played requests live."],
		"artstream": ["I streamed a painting from start to finish."],
		"irl": ["I streamed a walk around the city. A stranger joined in."],
		"joke": ["I posted a joke.", "I posted a pun. People groaned. People shared."],
		"thread": ["I posted a long thread.", "I wrote a thread explaining something complicated. It took off a little."],
		"news": ["I posted a quick reaction to the news."],
		"take": ["I posted a spicy take.", "I posted an opinion. The replies were a war zone."],
		"rant": ["I posted a rant about customer service."],
	}
	var arr: Array = lines.get(cid, ["I posted something."])
	var line := str(arr[randi() % arr.size()])
	if gain <= 5:
		return line + " Crickets."
	return line + " %s new followers." % _fmt(gain)


func _collab(pid: String) -> void:
	if Actions._out_of_time(): return
	var a := acct(pid)
	var f := int(a["followers"])
	var big := f >= 250000 and randf() < 0.4
	var partner := celeb("streamer" if pid == "streamr" else ("influencer" if pid in ["snapgram", "clipz"] else "")) if big else []
	var who: String = str(partner[0]) if big else "a creator with a similar audience"
	var gain := int(f * randf_range(0.05, 0.25) * (3.0 if big else 1.0)) + randi_range(200, 2000)
	if randf() < 0.12:
		Actions._done("🤝", "Collab", "I collabed with %s. We didn't get along on camera. The comments noticed." % who, {"happiness": -3})
		return
	a["followers"] = f + gain
	_sync()
	GameState.counter("collabs")
	Actions._done("🤝", "Collab", "I collabed with %s. %s new followers." % [who, _fmt(gain)], {"happiness": 5, "fame": 2 if big else 0})


func _sponsor(pid: String) -> void:
	if Actions._out_of_time(): return
	var a := acct(pid)
	var f := int(a["followers"])
	var br: String = BRANDS[pid][randi() % BRANDS[pid].size()]
	var fit := 1.3 if a.get("niche", "") != "" else 1.0
	var pay := int(f * randf_range(0.004, 0.02) * fit * (1.4 if a.get("verified", false) else 1.0))
	pay = maxi(pay, Actions._cost(200))
	a["earned"] = int(a.get("earned", 0)) + pay
	var lose := 0
	if br.contains("don't") or br.contains("risky"):
		if randf() < 0.4:
			lose = int(f * 0.08)
			a["followers"] = f - lose
			_sync()
	GameState.counter("sponsors")
	Actions._done("💼", "Sponsored", "I did a sponsored post for %s and got paid %s.%s" % [br, GameState.fmt_money(pay), " Some followers called me a sellout and left." if lose > 0 else ""], {"money": pay, "happiness": 3})


func yearly() -> void:
	var p := _p()
	if socials().is_empty():
		return
	var earned := 0
	for pid in socials().keys():
		var a: Dictionary = socials()[pid]
		var f := int(a["followers"])
		if int(a.get("last", -1)) < int(p["age"]) - 1:
			a["followers"] = int(f * randf_range(0.9, 0.97))
		var pay := float(PLATFORMS[pid]["pay"])
		if pay > 0 and int(a.get("last", -1)) >= int(p["age"]) - 1 and f >= 1000:
			var e := int(f * pay * randf_range(0.6, 1.4))
			a["earned"] = int(a.get("earned", 0)) + e
			earned += e
	_sync()
	if earned > 0:
		p["money"] = int(p["money"]) + earned
		GameState.add_log("My channels paid out %s in ads and subscriptions this year." % GameState.fmt_money(earned))
	var t := total()
	if t >= 1000:
		var target := clampf(log(float(t)) / log(10.0) * 13.0 - 30.0, 0.0, 95.0)
		if target > float(p.get("fame", 0)):
			p["fame"] = minf(target, float(p["fame"]) + 4.0)
