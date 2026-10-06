extends RefCounted
var h
const HOBBIES := {"cooking":["A recipe collection","Food",40],"garden":["A shared growing season","Environment",30],"photo":["A neighbourhood photo essay","Media",120],"craft":["A handmade exhibition","Arts",70],"reading":["A reading circle","Education",0]}
const SCENES := {
	"cooking":[
		["The first recipe works, but one guest cannot eat an ingredient.",["Test a suitable variation","Offer two clearly labelled dishes","Keep one dish and explain the limit"],[18,16,10]],
		["A friend has a useful family recipe but wants its origin credited.",["Cook together and keep their credit","Learn the technique without publishing it","Use the recipe and omit the origin"],[20,15,-5]],
		["The collection is ready, but testing every variation would take another season.",["Share the tested recipes with clear limits","Hold a small tasting and invite feedback","Claim every variation is tested"],[18,20,-6]]],
	"garden":[
		["The shared plot has sun in one corner and limited water.",["Choose plants for the actual space","Start a smaller trial bed","Plant everything from the catalogue"],[20,18,3]],
		["The plants are growing, but the watering rota is uneven.",["Agree on realistic shared shifts","Reduce the plot to fit our time","Assume someone else will handle it"],[20,16,-5]],
		["The harvest is smaller than expected; neighbours still want to join next season.",["Share the result and what we learned","Keep a small seed and care record","Describe the trial as a huge success"],[20,18,-4]]],
	"photo":[
		["A photo essay about the area risks showing people who do not want to be featured.",["Ask before including identifiable portraits","Focus on places and details","Publish every portrait without asking"],[20,18,-6]],
		["A dramatic edit makes the area look more neglected than it is.",["Keep the image faithful and explain context","Use a clearly labelled artistic study","Present the edit as documentary evidence"],[20,17,-5]],
		["The exhibition has room for six images, but twelve tell different parts of the story.",["Choose a balanced sequence","Show six and provide the wider context","Choose only the most shocking images"],[20,18,6]]],
	"craft":[
		["The material is attractive but more difficult than the prototype.",["Test a small sample first","Choose a simpler suitable material","Commit every supply before testing"],[20,17,4]],
		["A collaborator made a component that changes the design.",["Revise the design together","Keep distinct contributions in the display","Remove their credit to protect my idea"],[20,18,-7]],
		["One piece is imperfect but tells the story of how the work developed.",["Include the prototype with honest notes","Show only the finished work","Sell the prototype as flawless"],[20,16,-5]]],
	"reading":[
		["The circle has different reading speeds and access needs.",["Agree on accessible excerpts and a flexible pace","Choose a shorter first book","Make finishing every page a condition of joining"],[20,18,-4]],
		["Two readers interpret the same character very differently.",["Compare the passages behind both readings","Keep room for an unresolved interpretation","Vote one interpretation out of the group"],[20,18,-5]],
		["The group wants to continue after its original organiser leaves.",["Share the duties and leave a reading record","Keep a smaller informal gathering","Promise a full schedule with no organiser"],[20,18,-4]]]
}
func _init(hub): h=hub
func st() -> Dictionary: return h.section("leisure",{"project":{},"history":[],"undertaken":[],"casual_year":-1})
func casual() -> void:
	if not h.pay("casual_leisure",1,0,6): return
	st()["casual_year"]=GameState.year_now()
	Journey.modules["coping"].relieve(2)
	h.done("🫖","Enjoyment without a score","I made space for an ordinary pleasure. No project, prize or public performance was required.",{"happiness":3,"stress":-3})
func start(kind: String) -> void:
	if not HOBBIES.has(kind) or not st()["project"].is_empty() or st()["undertaken"].has(kind) or (kind=="photo" and GameState.year_now()<1840): return
	if not h.pay("hobby_start",1,Actions._cost(int(HOBBIES[kind][2])),6): return
	var friends := GameState.npcs_with("friend")
	var id := str(friends.pick_random()) if not friends.is_empty() else GameState.create_npc("friend",{"age":maxi(6,int(GameState.player["age"])),"closeness":40})
	st()["undertaken"].append(kind)
	st()["project"]={"kind":kind,"stage":0,"quality":30.0,"started":GameState.year_now(),"last":-1,"peer":FamilyChronicle.identity(GameState.npc(id)),"choices":[]}
	h.done("🌿","A personal project",str(HOBBIES[kind][0])+" · three yearly stages. This can remain a small personal achievement; fame and sales are not required.")
func step() -> void:
	var p: Dictionary=st()["project"]
	if p.is_empty() or int(p["last"])==GameState.year_now() or not h.pay("hobby_step",1,0,6): return
	var scene: Array=SCENES[p["kind"]][int(p["stage"])]
	h.decision("leisure","step",{"kind":p["kind"],"stage":p["stage"]},HOBBIES[p["kind"]][0],scene[0],scene[1])
func close(reason: String) -> void:
	var p: Dictionary=st()["project"]
	if p.is_empty(): return
	p["result"]=reason; p["ended"]=GameState.year_now()
	st()["history"].push_front(p.duplicate(true)); st()["project"]={}
	if st()["history"].size()>20: st()["history"].resize(20)
	h.note("Personal project closed",str(HOBBIES[p["kind"]][0])+" · "+reason+" · quality %d/100. The decisions and collaborator remain recorded." % p["quality"])
func resolve(op: String, args: Dictionary, answer: int) -> void:
	var p: Dictionary=st()["project"]
	if op!="step" or p.is_empty() or p["kind"]!=args["kind"] or int(p["stage"])!=int(args["stage"]): return
	var scene: Array=SCENES[p["kind"]][int(p["stage"])]
	p["choices"].append(scene[1][answer]); p["quality"]=clampf(float(p["quality"])+int(scene[2][answer])+Aptitude.score("creative")/20.0,0,100)
	p["last"]=GameState.year_now(); p["stage"]+=1
	var id: String=h.person(str(p["peer"]))
	if id!="" and GameState.npc(id).get("alive",false) and answer<2: Journey.modules["coping"].contact(id)
	if id!="" and GameState.npc(id).get("alive",false): BondStats.apply(id,{"affection":2 if answer<2 else -1,"respect":2 if answer<2 else -2}); FamilyChronicle.remember(id,"Shared a personal project: "+str(scene[1][answer]))
	h.done("🌿","A worthwhile ordinary life","Stage %d/3 · quality %d. The chosen scope and collaboration shaped the work; there is no cash prize." % [p["stage"],p["quality"]],{"happiness":2,"stress":1 if answer==0 else -1 if answer==1 else 2})
	if int(p["stage"])>=3:
		if float(p["quality"])>=60: Market.learn(str(HOBBIES[p["kind"]][1]),1); GameState.add_milestone(int(GameState.player["age"]),"completed "+str(HOBBIES[p["kind"]][0]))
		close("Completed")
func yearly() -> void: pass
func menu(_page: String) -> Dictionary:
	var rows: Array=[h.row("leisure","Enjoy a quiet activity","1 time · free · once a year · no project required","casual",null,not h.used("casual_leisure"))]
	var info: Array=["Casual leisure restores wellbeing. Optional projects build skills and friendships across years without requiring wealth, fame or a perfect score."]
	var p: Dictionary=st()["project"]
	if p.is_empty():
		for kind in HOBBIES: rows.append(h.row("leisure",HOBBIES[kind][0],"Three annual stages · start "+GameState.fmt_money(Actions._cost(int(HOBBIES[kind][2]))),"start",kind,not st()["undertaken"].has(kind) and (kind!="photo" or GameState.year_now()>=1840)))
	else:
		info.append(str(HOBBIES[p["kind"]][0])+" · stage %d/3 · quality %d" % [int(p["stage"])+1,p["quality"]])
		rows.append(h.row("leisure","Continue my project","1 time · one stage a year","step",null,int(p["last"])!=GameState.year_now()))
		rows.append(h.row("leisure","Leave the project","Keep participation and memories; no completion benefit","leave"))
	for record in st()["history"]: info.append(str(HOBBIES[record["kind"]][0])+" · "+str(record["result"])+" · quality "+str(int(record["quality"])))
	return {"title":"Hobbies & quiet goals","icon":"🌿","info":info,"rows":rows}
func act(key: String, arg: Variant) -> void:
	match key:
		"casual": casual()
		"start": start(str(arg))
		"step": step()
		"leave": if h.blocked(6)=="": close("Left by choice")
