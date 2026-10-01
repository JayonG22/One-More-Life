extends Node

## Routes career actions to playable minigames. When minigames are off, or no
## screen is attached (headless tests), results are rolled from skill instead.

signal requested(id: String, params: Dictionary, cb: Callable)

const DEFS := {
	"quiz": {"name": "Licence Theory Test", "icon": "📋", "script": "res://scenes/minigames/mg_quiz.gd",
		"how": "A written test, untimed on purpose. Answer with the mouse or keys 1-4.\nEvery question must be right to pass. You are shown the correct answer either way."},
	"audition": {"name": "Audition", "icon": "🎭", "script": "res://scenes/minigames/mg_audition.gd",
		"how": "Emotion cues slide toward the circle. Press the matching face (keys 1–4) as each one lands.\nMeanwhile, stay in the moving spotlight with ← → (A / D). Miss too much and the director says NEXT."},
	"rhythm": {"name": "Live Set", "icon": "🎸", "script": "res://scenes/minigames/mg_rhythm.gd",
		"how": "Notes fall down four lanes. Hit D  F  J  K (or click the lane) as each note crosses the line."},
	"clutch": {"name": "Clutch Moment", "icon": "🏆", "script": "res://scenes/minigames/mg_clutch.gd",
		"how": "Stop the needle inside the green zone with Space or the button. The zone shrinks every attempt.\nIn soccer and hockey, pick a corner first (A S D) — the keeper guesses too."},
	"debate": {"name": "Debate", "icon": "🎙️", "script": "res://scenes/minigames/mg_debate.gd",
		"how": "Tug-of-war for the crowd. The crowd's color shows what it wants: hit that card (keys 1–3) to pull the rope your way.\nEach argument costs breath, so don't spam. When the opponent winds up, press Space once the bar passes the line."},
	"safecrack": {"name": "Safecracker", "icon": "🔐", "script": "res://scenes/minigames/mg_safecrack.gd",
		"how": "Turn the dial with ◀ ▶ (or A / D). The tumbler meter fills as you get close.\nPress Lock (Space) on the exact number. Wrong locks raise the alarm."},
	"pickpocket": {"name": "Pickpocket", "icon": "👛", "script": "res://scenes/minigames/mg_pickpocket.gd",
		"how": "Hold Space (or the button) to lift the wallet. Let go before the mark looks your way.\nIf they catch you holding, you're busted."},
	"docking": {"name": "Docking", "icon": "🚀", "script": "res://scenes/minigames/mg_docking.gd",
		"how": "Thrust with the arrow keys or WASD. Fly into the green docking port slowly (speed under 45).\nFuel is limited. Too fast and you crash."},
	"runway": {"name": "Runway", "icon": "💃", "script": "res://scenes/minigames/mg_runway.gd",
		"how": "Watch the pose sequence, then repeat it with the arrow keys or buttons.\nEach walk adds one more pose."},
	"fight": {"name": "Fight Night", "icon": "🥊", "script": "res://scenes/minigames/mg_fight.gd",
		"how": "When your opponent winds up HIGH or LOW, block with ↑ or ↓ (W / S).\nA clean block opens a counter: hit Space to strike. You can also jab any time, but it costs stamina."},
	"onset": {"name": "On Set", "icon": "🎬", "script": "res://scenes/minigames/mg_onset.gd",
		"how": "Lighting, performance and camera keep drifting. Nudge each back into the green with − and +\n(keys Q/A, W/S, E/D). Keep all three green for as long as you can."},
	"infiltrate": {"name": "Infiltration", "icon": "🕵️", "script": "res://scenes/minigames/mg_infiltrate.gd",
		"how": "Move with the arrow keys or WASD; Space waits a turn. Guards move when you do.\nStay out of their sight (the red cells), grab the 📁 intel and get back to the 🚪 exit."},
	"potion": {"name": "Potion Brewing", "icon": "⚗️", "script": "res://scenes/minigames/mg_potion.gd",
		"how": "1 · Pick a recipe from your grimoire (or Experiment) and three ingredients (keys 0–9). Each ingredient has two properties; unknown ones are revealed as you use them.\n2 · Brew: keep the heat in the green with Space and stir when the cauldron asks (← / →).\n3 · Bottle: hold Space to pour and let go inside the band. Odd mixtures make odd potions."},
	"blackjack": {"name": "Blackjack", "icon": "🃏", "script": "res://scenes/minigames/mg_blackjack.gd",
		"how": "Get closer to 21 than the dealer without going over. Hit (H), Stand (S) or Double down (D) on your first two cards.\nThe dealer must hit below 17. Blackjack pays 3:2."},
	"escape": {"name": "Prison Break", "icon": "🔓", "script": "res://scenes/minigames/mg_escape.gd",
		"how": "Reach the 🕳️ hole in the fence. Every time you move, each guard moves TWICE toward you: sideways first, then up or down.\nGuards can't think around walls. Trap them behind one, or make two of them collide. Space waits a turn."},
	"burglary": {"name": "Break-in", "icon": "🥷", "script": "res://scenes/minigames/mg_burglary.gd",
		"how": "Sneak through the house with the arrow keys, grab loot, and climb back out the 🪟 window.\nEvery step makes noise, and steps near a sleeper make a lot. Holding still (Space) lets the house settle. Dogs bark. At 100% noise the lights come on: run."},
	"minefield": {"name": "Minefield", "icon": "💣", "script": "res://scenes/minigames/mg_minefield.gd",
		"how": "Cross the field to the green column. Each cleared square shows how many mines touch it, including diagonals.\nSpace sweeps the 3×3 area around you and marks mines with 🚩. Sweeps are limited, and so is time."},
	"fishing": {"name": "Fishing", "icon": "🎣", "script": "res://scenes/minigames/mg_fishing.gd",
		"how": "Hold Space (or the button) to reel. Keep the line tension in the green.\nToo tight and the line snaps; too slack and the fish gets away."},
	"evidence": {"name": "Evidence Board", "icon": "🧩", "script": "res://scenes/minigames/mg_evidence.gd",
		"how": "Read each clue and choose the strongest defensible inference with 1–3. Weak links cost time and case credibility; the goal is a coherent theory, not a forced one."},
	"haggle": {"name": "Negotiation", "icon": "🤝", "script": "res://scenes/minigames/mg_haggle.gd",
		"how": "They open at 100. Somewhere above that is the most they will really pay, and you can't see it.\nSet your ask with ← → (1) and ↑ ↓ (5), then press Enter. Their reply tells you how much room is left. You have three rounds: ask too little and they accept at once; ask too much and they walk."},
	"road": {"name": "Road Test", "icon": "🚦", "script": "res://scenes/minigames/mg_road.gd",
		"how": "A short route in three lanes. Change lane with ← → (A / D); hold Space to brake.\nAvoid cones, wait for pedestrians, stop at red lights. Four faults fail the test. There is no clock."},
	"pet_pounce": {"name": "Stalk and Pounce", "icon": "🐭", "script": "res://scenes/minigames/mg_pet_pounce.gd",
		"how": "Three holes. One shakes, then the prey pops out for a moment. Pounce on that hole: A / S / D (or ← ↓ →).\nPounce on an empty hole and the prey gets wary and stays out for less time. Eight chances."},
	"pet_scent": {"name": "Scent Work", "icon": "👃", "script": "res://scenes/minigames/mg_pet_scent.gd",
		"how": "Eight forks in a trail. At each, the three bars show how strong the scent is left, ahead and right, but every reading is noisy.\nSpace sniffs again (readings average out, but sniffing costs a second). Choose with A / W / D. A wrong turn costs four seconds."},
	"pet_sneak": {"name": "Sneak", "icon": "🍗", "script": "res://scenes/minigames/mg_pet_sneak.gd",
		"how": "Hold Space to creep toward the food; let go to freeze.\nWhen ❓ appears the human is about to look: freeze. While 👀 is showing, stay frozen. Three slips and you are caught."},
	"pet_agility": {"name": "Agility Course", "icon": "🏃", "script": "res://scenes/minigames/mg_pet_agility.gd",
		"how": "Ten obstacles slide toward you. Jump hurdles with ↑ / W / Space; duck through tunnels with ↓ / S.\nPress while the obstacle is inside the green box. The label on each obstacle says which key."},
	"pet_herd": {"name": "Herding", "icon": "🐑", "script": "res://scenes/minigames/mg_pet_herd.gd",
		"how": "Move with the arrow keys or WASD. Sheep step away from you, so stand on the side of a sheep away from the pen and let it walk in.\nGet all five penned before time runs out."},
	"surgery": {"name": "Operating Room", "icon": "🔪", "script": "res://scenes/minigames/mg_surgery.gd",
		"how": "Keep oxygen, pressure and bleeding stable while completing the prompted procedure steps. Use keys 1–4 for the instruments; wrong choices can destabilize the patient."},
}

var host_ready := false


func enabled() -> bool:
	return bool(GameState.settings.get("minigames", true))


func headless() -> bool:
	return DisplayServer.get_name() == "headless"


func auto_score(skill: float) -> float:
	return clampf(skill / 100.0 * 0.75 + randf_range(0.0, 0.3), 0.02, 1.0)


func play(id: String, params: Dictionary, cb0: Callable) -> void:
	var cb := cb0
	if DEFS.has(id):
		cb = func(s: float, d: Dictionary) -> void:
			Goals.on_minigame(id, s, d.get("auto", false))
			cb0.call(s, d)
	if Lives.has_power("speed") and params.has("difficulty"):
		params = params.duplicate()
		params["difficulty"] = float(params["difficulty"]) * 0.85
	var skill := float(params.get("skill", 50.0))
	if not DEFS.has(id) or not enabled() or headless() or not host_ready:
		cb.call(auto_score(skill), {"auto": true})
		return
	requested.emit(id, params, cb)


static func grade(score: float) -> String:
	if score >= 0.9:
		return "Perfect!"
	if score >= 0.7:
		return "Great"
	if score >= 0.45:
		return "Solid"
	if score >= 0.2:
		return "Rough"
	return "Flop"


static func stars(score: float) -> int:
	return clampi(int(ceil(score * 5.0)), 0, 5)


static func tier(score: float) -> int:
	if score >= 0.85:
		return 3
	if score >= 0.6:
		return 2
	if score >= 0.35:
		return 1
	return 0
