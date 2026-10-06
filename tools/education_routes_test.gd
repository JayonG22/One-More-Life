extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func clear() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear()
func fresh() -> void:
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=25; GameState.player["money"]=100000; GameState.player["time_left"]=100
	GameState.player["education"]["hs_graduated"]=true
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes(); clear()
func next_year() -> void:
	GameState.player["age"]+=1; GameState.player["time_left"]=100; clear()
func _ready() -> void:
	seed(101100); fresh(); var learning=Journey.modules["learning"]
	GameState.player["country"]="gb"
	var cash: int=GameState.player["money"]; learning.enrol("Tech","college")
	ok(learning.st()["course"].is_empty() and GameState.player["money"]==cash,"Unsupported country charged a college fee")
	GameState.player["country"]="us"; GameState.player["education"]["hs_graduated"]=false; learning.enrol("Tech","college")
	ok(learning.st()["course"].is_empty(),"College ignored entry qualification")
	GameState.player["education"]["hs_graduated"]=true; GameState.player["age"]=17; learning.enrol("Tech","college")
	ok(learning.st()["course"].is_empty(),"College ignored adulthood requirement")
	GameState.player["age"]=25; learning.enrol("Tech","college"); clear()
	ok(learning.st()["course"]["route"]=="college" and learning.st()["course"]["country"]=="us","College route not recorded")
	var enrolled_money: int=GameState.player["money"]
	for i in range(3):
		learning.unit()
		var prompt: Dictionary=Journey.state()["prompt"]
		var index: int=prompt["args"]["order"].find(0)
		var spec: Dictionary=prompt["def"]["choices"][index]["outcomes"][0]["journey"].duplicate(true)
		clear(); Journey.outcome(spec); clear(); next_year()
	for attempt in range(30):
		learning.assess(); clear()
		if learning.st()["course"].is_empty(): break
		next_year()
	ok(learning.st()["course"].is_empty() and GameState.edu_level()=="associate","College did not award separate associate qualification")
	ok(GameState.player["education"]["degrees"].size()==1 and GameState.player["education"]["degrees"][0]["field"]=="Tech","College diploma field lost")
	ok(GameState.player["money"]==enrolled_money,"Diploma created a cash reward or duplicate fee")
	ok(Actions.can_enroll("graduate")!="","Associate diploma bypasses bachelor prerequisite")
	ok(Actions.college_credit("computer_science")==2 and Actions.college_credit("culinary")==1 and Actions.college_credit("medicine")==0,"Regional college credit incorrect")
	ok(is_equal_approx(Market.education_fit({"field":"Tech"}),0.07),"College diploma has no application evidence")
	var requirement := Actions.job_requirement(ContentDB.job("developer"))
	ok(requirement!="","Associate diploma passed a bachelor job requirement")
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
	ok(GameState.edu_level()=="associate" and Actions.college_credit("computer_science")==2,"Reload lost college diploma")
	GameState.player["country"]="ca"
	ok(Actions.college_credit("computer_science")==0,"Foreign college credit silently transferred")
	Journey.modules["places"].arrived("ca"); Journey.modules["places"].review_credentials(); clear()
	ok(Actions.college_credit("computer_science")==2 and not Law.has_license("pilot"),"Credential review omitted diploma recognition or granted an unrelated licence")
	cash=GameState.player["money"]; Journey.modules["places"].review_credentials()
	ok(GameState.player["money"]==cash,"Credential review repeated its fee")
	GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
	ok(Actions.college_credit("computer_science")==2,"Saved recognition lost after reload")
	GameState.player["country"]="us"
	# An accepted bachelor application starts with actual prior college credit.
	GameState.player["education"]["gpa_years"]=1; GameState.player["education"]["gpa_sum"]=4.0
	for attempt in range(30):
		Actions.enroll("computer_science"); clear()
		if GameState.in_university(): break
	ok(GameState.in_university() and GameState.player["education"]["uni"]["year"]==2,"Bachelor admission ignored college credit")
	var e: Dictionary=GameState.player["education"]; e["uni"]["performance"]=73; e["uni"]["scholarship"]=0.5
	GameState.player["loan"]=8000; Actions.drop_out(); clear()
	ok(not GameState.in_university() and e["interrupted_study"].size()==1,"Interruption discarded academic transcript")
	cash=GameState.player["money"]; Actions.return_to_study(0)
	ok(not GameState.in_university() and GameState.player["money"]==cash,"Same-year return bypassed interval")
	next_year(); GameState.from_dict(JSON.parse_string(JSON.stringify(GameState.to_dict()))); clear()
	Actions.return_to_study(0); clear(); e=GameState.player["education"]
	ok(GameState.in_university() and e["uni"]["year"]==2 and e["uni"]["performance"]==73,"Return reset earned study/grades")
	ok(e["uni"]["scholarship"]==0 and GameState.player["loan"]==8000,"Return restored ended scholarship or cleared debt")
	cash=GameState.player["money"]; Actions.return_to_study(0)
	ok(GameState.player["money"]==cash and e["interrupted_study"][0]["state"]=="returned","Return replayed or failed to close record")
	# More than twenty completed fields remain permanent, preventing re-enrolment.
	fresh()
	for field in Employment.programs: learning.st()["completed"].append({"field":field,"route":"campus","year":GameState.year_now()})
	cash=GameState.player["money"]; learning.enrol("Aviation","campus")
	ok(learning.st()["completed"].size()==28 and learning.st()["course"].is_empty() and GameState.player["money"]==cash,"Old qualification forgotten and farmed again")
	print("EDUCATION ROUTES checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
