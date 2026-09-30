extends Node

## NPC_WORLD — the people in your life having lives with each other.
##
## NPCs already aged, married, had children and changed jobs. What they never did
## was have anything to do with one another. Your sister and your best friend
## existed in separate sealed boxes, and the only relationship in the game was
## the one between you and each of them in turn. That is what makes a cast feel
## like a menu.
##
## So: your people now form their own bonds. They become friends, they fall out,
## two of them get together, somebody's new partner is somebody you already know
## and do not like. You hear about it, it shows on their page, and it can arrive
## as something you have to have an opinion about.
##
## Agency was also only ever triggered by extremes — closeness 72 or above, or 28
## or below. Everybody in the middle, which is most people, never did anything.

const LINK_KINDS := {
	"close": ["are close", "💚"],
	"friends": ["are friendly", "🙂"],
	"together": ["are together", "❤️"],
	"rivals": ["cannot stand each other", "⚔️"],
	"fell_out": ["are not speaking", "💢"],
}

## Who can plausibly meet whom. Family meet everyone; a coworker and your mother
## need a reason, and "at your wedding" is a reason, so the net is wide but not total.
const MEETABLE := ["sibling", "friend", "best_friend", "coworker", "neighbor",
	"cousin", "auntuncle", "mother", "father", "child", "partner", "ex", "boss",
	"classmate", "stepsibling", "grandparent", "mentor"]


func _p() -> Dictionary:
	return GameState.player


func links() -> Array:
	var p := _p()
	if p.is_empty():
		return []
	if not p.has("npc_links") or not (p["npc_links"] is Array):
		p["npc_links"] = []
	return p["npc_links"]


func link_between(a: String, b: String) -> Dictionary:
	for l in links():
		if (str(l["a"]) == a and str(l["b"]) == b) or (str(l["a"]) == b and str(l["b"]) == a):
			return l
	return {}


func links_for(id: String) -> Array:
	var out: Array = []
	for l in links():
		if str(l["a"]) == id or str(l["b"]) == id:
			out.append(l)
	return out


func _other(l: Dictionary, id: String) -> String:
	return str(l["b"]) if str(l["a"]) == id else str(l["a"])


## The line shown on a person's page: who else in your life they know, and how.
func lines_for(id: String) -> Array:
	var out: Array = []
	for l in links_for(id):
		var o := _other(l, id)
		if not GameState.npcs.has(o) or not bool(GameState.npcs[o].get("alive", true)):
			continue
		var k := str(l["kind"])
		var d: Array = LINK_KINDS.get(k, ["know each other", "•"])
		out.append("%s %s and %s %s" % [str(d[1]), GameState.npcs[id].get("first", ""),
			GameState.full_name(o), str(d[0])])
	return out


func _eligible(id: String) -> bool:
	if not GameState.npcs.has(id):
		return false
	var n: Dictionary = GameState.npcs[id]
	return bool(n.get("alive", true)) and str(n.get("species", "human")) == "human" \
		and int(n.get("age", 0)) >= 10 and MEETABLE.has(str(n.get("relation", "")))


func _pool() -> Array:
	var out: Array = []
	for id in GameState.npcs.keys():
		if _eligible(str(id)):
			out.append(str(id))
	return out


# ---------------------------------------------------------------- the yearly pass

func yearly() -> void:
	var p := _p()
	if p.is_empty() or not GameState.is_alive() or int(p.get("age", 0)) < 8:
		return
	_form()
	_drift()


## People meet. Two of yours, once in a while, become something to each other.
func _form() -> void:
	if randf() > 0.42:
		return
	var pool := _pool()
	if pool.size() < 2:
		return
	var a: String = pool[randi() % pool.size()]
	var b: String = pool[randi() % pool.size()]
	if a == b or not link_between(a, b).is_empty():
		return
	var na: Dictionary = GameState.npcs[a]
	var nb: Dictionary = GameState.npcs[b]
	# Family already know each other; this is about becoming something more.
	var both_family := str(na["relation"]) in ["sibling", "cousin", "mother", "father", "child"] \
		and str(nb["relation"]) in ["sibling", "cousin", "mother", "father", "child"]
	var kind := _decide(na, nb, both_family)
	if kind == "":
		return
	links().append({"a": a, "b": b, "kind": kind, "since": int(_p().get("age", 0))})
	_announce(a, b, kind)


func _decide(na: Dictionary, nb: Dictionary, both_family: bool) -> String:
	var ca := int(na.get("craziness", 35))
	var cb := int(nb.get("craziness", 35))
	var volatile := (ca + cb) / 2
	var age_gap := absi(int(na.get("age", 0)) - int(nb.get("age", 0)))
	var r := randf() * 100.0
	# Two volatile people are far more likely to end up at odds than two calm ones.
	var clash := 18.0 + float(volatile) * 0.45
	if r < clash:
		return "rivals"
	# Romance needs both to be adults, close in age, and not related to each other.
	var free_a := not bool(na.get("married", false)) and str(na.get("relation", "")) != "partner"
	var free_b := not bool(nb.get("married", false)) and str(nb.get("relation", "")) != "partner"
	if not both_family and int(na.get("age", 0)) >= 18 and int(nb.get("age", 0)) >= 18 \
		and age_gap <= 14 and free_a and free_b and r < clash + 14.0:
		return "together"
	if r < clash + 45.0:
		return "friends"
	return "close"


func _announce(a: String, b: String, kind: String) -> void:
	var an := GameState.full_name(a)
	var bn := GameState.full_name(b)
	var la := GameState.relation_label(a).to_lower()
	var lb := GameState.relation_label(b).to_lower()
	match kind:
		"close":
			GameState.add_log("My %s %s and my %s %s have got very close." % [la, an, lb, bn])
		"friends":
			GameState.add_log("My %s %s and my %s %s have started spending time together." % [la, an, lb, bn])
		"rivals":
			GameState.add_log("My %s %s and my %s %s have taken against each other." % [la, an, lb, bn])
			GameState.change_stat("stress", 3.0)
		"together":
			_together(a, b)


## Two of your people getting together is the one that has to be a real moment,
## because it changes who is at every table for the rest of your life.
func _together(a: String, b: String) -> void:
	var na: Dictionary = GameState.npcs[a]
	var nb: Dictionary = GameState.npcs[b]
	if randf() < 0.35:
		Origins.wed(a, b)
	var an := GameState.full_name(a)
	var bn := GameState.full_name(b)
	var awkward := str(na["relation"]) in ["ex", "best_friend"] or str(nb["relation"]) in ["ex", "best_friend"]
	if not awkward:
		GameState.add_log("My %s %s and my %s %s are together. Nobody saw that coming except apparently everybody." % [
			GameState.relation_label(a).to_lower(), an, GameState.relation_label(b).to_lower(), bn])
		GameState.apply_effects({"happiness": 3})
		return
	# One of them is an ex or your closest friend, which is a different thing.
	EventEngine.push_decision({
		"id": "_npcw_together", "icon": "💞", "title": "Those two",
		"text": "%s and %s are seeing each other. One of them told you; the other has been avoiding you for a month." % [an, bn],
		"choices": [
			{"label": "Be pleased for them",
			 "outcomes": [
				{"text": "I said I was happy about it and by the second time I said it I meant it.", "weight": 2,
				 "effects": {"karma": 6, "happiness": 4}, "relationship": {"x": 12, "y": 12}},
				{"text": "I said I was happy about it and everybody in that room knew I was not.", "weight": 1,
				 "effects": {"stress": 8, "happiness": -5}, "relationship": {"x": -6, "y": -6}}]},
			{"label": "Say what you actually think",
			 "outcomes": [
				{"text": "I told them it was a bad idea and why. They did not take it well and one of them later said I had been right.", "weight": 2,
				 "relationship": {"x": -18, "y": -14}, "effects": {"stress": 10}},
				{"text": "I said my piece and they listened, and it changed nothing, and at least it was said out loud.", "weight": 1,
				 "relationship": {"x": -8, "y": -8}, "effects": {"happiness": -4}}]},
			{"label": "Make it their problem, not yours",
			 "outcomes": [
				{"text": "I stayed out of it entirely. It lasted eleven months and I never had to have an opinion.", "weight": 2,
				 "effects": {"stress": 4}},
				{"text": "Staying out of it was taken as a verdict anyway, by both of them, in opposite directions.", "weight": 1,
				 "relationship": {"x": -10, "y": -10}, "effects": {"stress": 8}}]},
		]}, {"x": a, "y": b})


## Links change. Friends get closer, rivals sometimes make it up, couples split.
func _drift() -> void:
	var l := links()
	var i := l.size() - 1
	while i >= 0:
		var lk: Dictionary = l[i]
		var a := str(lk["a"])
		var b := str(lk["b"])
		if not GameState.npcs.has(a) or not GameState.npcs.has(b) \
			or not bool(GameState.npcs[a].get("alive", true)) or not bool(GameState.npcs[b].get("alive", true)):
			l.remove_at(i)
			i -= 1
			continue
		var kind := str(lk["kind"])
		var years := int(_p().get("age", 0)) - int(lk.get("since", 0))
		var vol := (int(GameState.npcs[a].get("craziness", 35)) + int(GameState.npcs[b].get("craziness", 35))) / 2
		var r := randf()
		match kind:
			"friends":
				if r < 0.10:
					lk["kind"] = "close"
					GameState.add_log("%s and %s are properly close now." % [GameState.full_name(a), GameState.full_name(b)])
				elif r < 0.10 + float(vol) * 0.0016:
					lk["kind"] = "fell_out"
					GameState.add_log("%s and %s have fallen out over something neither will explain." % [GameState.full_name(a), GameState.full_name(b)])
			"close":
				if r < float(vol) * 0.0012:
					lk["kind"] = "fell_out"
					GameState.add_log("%s and %s are not speaking. It is serious." % [GameState.full_name(a), GameState.full_name(b)])
					GameState.change_stat("stress", 4.0)
			"rivals":
				if r < 0.07:
					lk["kind"] = "friends"
					GameState.add_log("%s and %s have somehow become friends. I will never understand it." % [GameState.full_name(a), GameState.full_name(b)])
			"fell_out":
				if r < 0.12 and years >= 2:
					lk["kind"] = "friends"
					GameState.add_log("%s and %s have patched it up." % [GameState.full_name(a), GameState.full_name(b)])
			"together":
				if r < 0.05 + float(vol) * 0.0010:
					lk["kind"] = "fell_out"
					Origins.part(a)
					GameState.add_log("%s and %s have split up, and now I have to pick which one to see at Christmas." % [GameState.full_name(a), GameState.full_name(b)])
					GameState.change_stat("stress", 5.0)
		i -= 1


## Everybody in the middle used to be inert. This is the neutral band: nothing
## dramatic, just people being people at you.
const NEUTRAL := [
	"asked me for a lift and then talked for an hour in the car park.",
	"has taken up something baffling and will not stop explaining it.",
	"rang to ask whether I remembered somebody neither of us has seen in years.",
	"turned up unannounced with food, which was either kind or a hint.",
	"has started saying a phrase constantly and does not know they are doing it.",
	"sent me a photograph of the two of us that I have never seen before.",
	"wants my opinion on a decision they have obviously already made.",
	"has fallen out with somebody at work and I am getting all of it in instalments.",
	"asked, quite seriously, whether I was happy. I did not have an answer ready.",
	"remembered something about me I had forgotten entirely.",
]


## Called from the agency pass for the people who are neither loved nor loathed.
func neutral_beat() -> bool:
	var pool: Array = []
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not bool(n.get("alive", true)) or str(n.get("species", "human")) != "human":
			continue
		var c := int(n.get("closeness", 50))
		if c > 28 and c < 72 and int(n.get("age", 0)) >= 8:
			pool.append(str(id))
	if pool.is_empty():
		return false
	var id: String = pool[randi() % pool.size()]
	var n: Dictionary = GameState.npcs[id]
	GameState.add_log("My %s %s %s" % [GameState.relation_label(id).to_lower(),
		str(n["first"]), NEUTRAL[randi() % NEUTRAL.size()]])
	# It is small, but it moves something, which is the difference between a
	# person and a line of flavour text.
	GameState.change_closeness(id, randi_range(-1, 3))
	return true
