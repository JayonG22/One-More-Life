extends Node

const WEIGHTS := {
	"education":{"smarts":0.60,"health":0.20,"happiness":0.20},
	"work":{"smarts":0.35,"health":0.30,"happiness":0.35},
	"creative":{"smarts":0.35,"looks":0.20,"health":0.15,"happiness":0.30},
	"physical":{"health":0.65,"happiness":0.20,"smarts":0.15},
	"social":{"happiness":0.45,"looks":0.25,"smarts":0.15,"health":0.15},
	"technical":{"smarts":0.60,"health":0.25,"happiness":0.15},
}

func score(context: String = "work") -> float:
	var weights: Dictionary = WEIGHTS.get(context,WEIGHTS["work"])
	var result := 0.0
	for stat in weights: result+=GameState.stat(stat)*float(weights[stat])
	var fatigue := float(GameState.player.get("household",{}).get("fatigue",0))
	var access: float=Journey.modules["wellbeing"].readiness(context) if Journey.modules.has("wellbeing") else 0.0
	var coping: float=Journey.modules["coping"].readiness(context) if Journey.modules.has("coping") else 0.0
	return clampf(coping+access+result*0.85+(100-GameState.stat("stress"))*0.15-maxf(0,fatigue-25)*0.12,0,100)

func chance(base: float, context: String = "work") -> float:
	return clampf(base+(score(context)-50)/200.0,0.02,0.98)

func reward(context: String = "work") -> float:
	return 0.65+score(context)*0.007

func effective_skill(trained: float, context: String = "work") -> float:
	return clampf(trained+(score(context)-50)*0.35,0,100)

func game_context(id: String) -> String:
	if id=="school_quiz": return "education"
	if id in ["fight","clutch","fishing","pr_dodge","pr_fight","road","workshop_tactics"]: return "physical"
	if id in ["rhythm","audition","onset","runway","hands_music","workshop_music"]: return "creative"
	if id in ["debate","haggle","pr_standoff","hands_negotiation","workshop_negotiation"]: return "social"
	return "technical"

func career_context(id: String) -> String:
	if id in ["athlete","fighter"]: return "physical"
	if id in ["actor","musician","model","director"]: return "creative"
	if id in ["politician","hustler"]: return "social"
	return "technical"

func describe(context: String) -> String:
	return "Readiness %d/100 · chance adjustment %+.0f percentage points · variable rewards ×%.2f. Health, mood, ability, stress, fatigue and burnout contribute." % [int(score(context)),(score(context)-50)/2,reward(context)]
