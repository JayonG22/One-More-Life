extends Minigame

## Untimed scenarios use numerical constraints, sequences and tactical counterplay.
var round_i := 0
var rounds := 5
var points := 0.0
var choices: Array=[]
var buttons: Array[Button]=[]
var prompt: Label
var feedback: Label
var next_button: Button
var budget := 100
var stamina := 100
var order: Array=[]
var history: Array=[]
var kind := "repair"
var restored := false
func build() -> void:
	rounds=clampi(int(params.get("rounds",5)),1,5)
	kind=str(params.get("kind","repair")); make_status()
	stamina=70+mini(8,int(params.get("belt",0)))*4
	var progress: Dictionary=params.get("progress",{})
	if not progress.is_empty():
		round_i=clampi(int(progress.get("round",0)),0,rounds); points=float(progress.get("points",0)); budget=int(progress.get("budget",100)); stamina=int(progress.get("stamina",stamina)); history=progress.get("history",[]).duplicate(true); restored=true
	var title := label(str(params.get("title","Practical challenge")),27,true)
	place(title,Vector2(60,46),Vector2(880,45))
	prompt=label("",22,true); prompt.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(prompt,Vector2(60,103),Vector2(880,105))
	for i in range(3):
		var b := button("",choose.bind(i),"Primary"); b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size",20); b.focus_mode=Control.FOCUS_ALL
		place(b,Vector2(80,220+i*64),Vector2(840,58)); buttons.append(b)
	feedback=label("",17); feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; place(feedback,Vector2(80,415),Vector2(840,60))
	next_button=button("Continue",next,"Primary"); place(next_button,Vector2(650,480),Vector2(270,44)); next_button.visible=false
	next_button.add_theme_font_size_override("font_size",20); next_button.focus_mode=Control.FOCUS_ALL
	set_round()
func save_progress() -> void:
	if not params.has("progress_token") or done: return
	Journey.modules["skills"].checkpoint({"round":round_i,"points":points,"budget":budget,"stamina":stamina,"history":history.duplicate(true),"order":order.duplicate(),"ready":next_button.visible,"feedback":feedback.text},int(params["progress_token"]),str(params["progress_owner"]))
func set_round() -> void:
	if round_i>=rounds:
		var readiness := 0.75+clampf(float(params.get("skill",50)),0,100)/400.0
		finish(clampf(points/float(rounds)*readiness,0,1),{"feedback":"\n".join(history),"rounds":rounds,"practice":params.get("practice",false)}); return
	var good := ""; var bad := ""; var mixed := ""; var text := ""; var explain := ""
	match kind:
		"budget":
			var essential := 18+round_i*2; var wanted := 25+round_i*3
			text="Cash %d. This round needs an essential payment of %d; keep at least 5 for emergencies." % [budget,essential]
			good="Pay essential %d; keep the reserve" % essential; bad="Buy the optional item for %d" % wanted; mixed="Spend 5 now; postpone the essential bill"
			explain="Paying essentials while keeping a reserve protects the next round."
		"logistics":
			var route := 8+round_i*2; var limit := route+2
			text="The delivery has %d minutes left. Route A takes %d, B takes %d, and C takes %d but requires a vehicle you do not have." % [limit,route+5,route,route-2]
			good="Take B within the limit"; bad="Take unavailable C"; mixed="Take A and miss the window"; explain="A feasible route matters more than the shortest advertised one."
		"negotiation":
			var cost := 40+round_i*5; var cap := cost+15
			text="Your cost floor is %d. The client disclosed a budget of %d. Reputation falls for hidden fees." % [cost,cap]
			good="Offer %d with the scope written down" % (cost+10); bad="Offer %d; add hidden fees" % (cost-5); mixed="Insist on %d and risk losing the work" % (cap+20); explain="An honest offer inside both constraints sustains the contract."
		"music":
			var notes := ["DO","RE","MI","SO","LA"]
			var a := (round_i+int(params.get("skill",50))/20)%5; var b := (a+2)%5
			text="Read the phrase %s → %s → %s, then choose the matching ending. This exercise is untimed." % [notes[a],notes[b],notes[(b+1)%5]]
			good=notes[(b+1)%5]; bad=notes[(b+3)%5]; mixed=notes[(b+4)%5]; explain="Read the whole phrase; the next ending follows the printed sequence."
		"tactics":
			var tells := ["high attack","low attack","patient guard","rushed advance","counter trap"]
			text="Opponent: %s · tells a %s. Stamina %d; belt %d. Defence and spacing preserve energy." % [params.get("opponent_style","patient"),tells[int(params.get("tells",[0,1,2,3,4])[round_i])],stamina,params.get("belt",0)]
			good=["High guard and measured counter","Low guard and reset","Change angle and conserve effort","Control distance before countering","Feint, observe and reset"][int(params.get("tells",[0,1,2,3,4])[round_i])]
			bad="Spend 30 stamina forcing an attack"; mixed="Retreat without reading the tell"; explain="Counter the actual tell; constant attacking consumes the stamina needed later."
		"repair":
			text=["The equipment's safety status is not confirmed.","Two possible faults share the same symptom.","A replacement is available but its compatibility is unclear.","The first check works; the original failure was intermittent.","The customer asks what was fixed and what remains uncertain."][round_i]
			good=["Confirm safe handling with the qualified procedure","Compare a diagnostic result against the symptom","Check the specification before fitting it","Verify the relevant operating conditions","Give an honest record and follow-up plan"][round_i]
			bad="Declare success without checking"; mixed="Replace parts based only on a guess"; explain="Diagnosis and verification reduce guesswork; this is an abstract game task."
		"cooking":
			text=["Three orders arrive; one has a stated dietary restriction.","A meal is ready but the table's other dishes are delayed.","An ingredient label does not match the planned dish.","The queue is growing and one station is overloaded.","A customer reports the wrong dish before eating."][round_i]
			good=["Confirm the restriction before preparing that order","Coordinate a complete table delivery","Pause and confirm a suitable substitute","Redistribute work with the team","Correct the order and record the mix-up"][round_i]
			bad="Ignore the discrepancy to move faster"; mixed="Rush without confirming the change"; explain="A safe, coordinated service is more valuable than an unchecked shortcut."
		"care":
			text=["Two people need support but have different preferences.","A scheduled appointment overlaps a transport problem.","Someone's needs changed since the last plan.","A caregiver says they are exhausted.","The handover record contains an unanswered concern."][round_i]
			good=["Ask about consent, needs and available support","Coordinate transport with the service","Request a qualified review of the plan","Share the workload and arrange support","Document the concern and request follow-up"][round_i]
			bad="Pretend the concern is resolved"; mixed="Choose for them without asking"; explain="Respect consent and use qualified support; the exercise awards coordination, not medical treatment."
		"interview":
			text=["The interviewer asks for evidence of a skill.","Your experience includes an unsuccessful project.","A gap in your CV needs context.","A question asks about responsibilities beyond your training.","The offer's hours differ from what was advertised."][round_i]
			good=["Give a concrete task and its measured result","Explain what happened and what you learned","Explain the gap without inventing employment","State my limits and the supervision I would need","Ask for the actual terms in writing"][round_i]
			bad="Invent a perfect record"; mixed="Avoid the question entirely"; explain="Specific, honest evidence and clear terms build a credible interview."
	choices=[{"text":good,"score":1.0,"explain":explain},{"text":bad,"score":0.0,"explain":explain},{"text":mixed,"score":0.35,"explain":explain}]
	if restored:
		order=params["progress"].get("order",[0,1,2]).duplicate()
	else: order=[0,1,2]; order.shuffle()
	prompt.text=text
	for i in range(3): buttons[i].text="%d · %s" % [i+1,choices[order[i]]["text"]]; buttons[i].disabled=false
	status.text="Round %d/%d · untimed · skill %d/100" % [round_i+1,rounds,params.get("skill",50)]
	feedback.text=""; next_button.visible=false
	if restored:
		feedback.text=str(params["progress"].get("feedback","")); next_button.visible=bool(params["progress"].get("ready",false))
		for b in buttons: b.disabled=next_button.visible
		restored=false
	save_progress()
func choose(index: int) -> void:
	if done or next_button.visible or index<0 or index>2: return
	var picked: Dictionary=choices[order[index]]; var gain := float(picked["score"])
	if kind=="budget": budget-=18+round_i*2 if gain==1 else 25+round_i*3 if gain==0 else 5; budget+=20; gain=0 if budget<5 else gain
	if kind=="tactics":
		var discipline := str(params.get("martial_style",""))
		var tell := int(params.get("tells",[0,1,2,3,4])[round_i])
		var matches := {"karate":0,"boxing":0,"judo":3,"taekwondo":1,"krav":2,"bjj":4}
		if gain==1 and matches.get(discipline,-1)==tell: stamina+=4
		stamina-=(8 if gain==1 else 30 if gain==0 else 4)+(4 if params.get("opponent_style","")=="aggressive" else 2 if params.get("opponent_style","")=="countering" and gain<1 else 0); gain*=0.5 if stamina<0 else 1.0
	points+=gain; history.append("Round %d: %s" % [round_i+1,picked["explain"]])
	feedback.text=picked["explain"]+" · round score "+str(int(gain*100))+"%"
	for b in buttons: b.disabled=true
	next_button.visible=true; next_button.grab_focus()
	save_progress()
func next() -> void:
	if not next_button.visible or done: return
	round_i+=1; set_round()
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_1,KEY_2,KEY_3]: choose(int(event.keycode)-KEY_1); get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_ENTER,KEY_SPACE] and next_button.visible: next(); get_viewport().set_input_as_handled()
