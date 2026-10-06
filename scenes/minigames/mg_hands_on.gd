extends Minigame
## Three distinct untimed activities share saved rounds and a guarded result.
var kind := "repair"
var rounds := 5
var round_i := 0
var points := 0.0
var history: Array=[]
var target: Array=[]
var current: Array=[]
var inspected: Array=[]
var notes: Array=[]
var played: Array=[]
var effort := 0
var seed_value := 0
var offer := 70.0
var scope := 80.0
var round_ready := false
var prompt: Label
var feedback: Label
var buttons: Array[Button]=[]
var submit: Button
var continuation: Button
var offer_slider: HSlider
var scope_slider: HSlider
func build() -> void:
	kind=str(params.get("kind","repair")); rounds=clampi(int(params.get("rounds",5)),1,5)
	seed_value=int(params.get("board_seed",12345)); make_status()
	var p: Dictionary=params.get("progress",{})
	if not p.is_empty():
		round_i=int(p.get("round",0)); points=float(p.get("points",0)); history=p.get("history",[]).duplicate(true)
		target=p.get("target",[]).duplicate(); current=p.get("current",[]).duplicate(); inspected=p.get("inspected",[]).duplicate()
		notes=p.get("notes",[]).duplicate(); played=p.get("played",[]).duplicate(); effort=int(p.get("effort",0))
		offer=float(p.get("offer",70)); scope=float(p.get("scope",80)); round_ready=p.get("round_ready",false)
	place(label(str(params.get("title","Workshop")),27,true),Vector2(50,42),Vector2(900,42))
	prompt=label("",20,true); prompt.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; place(prompt,Vector2(50,94),Vector2(900,126))
	feedback=label(str(p.get("feedback","")),17); feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; place(feedback,Vector2(50,382),Vector2(900,78))
	if kind=="repair":
		for i in range(3):
			var inspect_button := button("Inspect "+["A","B","C"][i],inspect.bind(i),"Row"); inspect_button.focus_mode=Control.FOCUS_ALL
			place(inspect_button,Vector2(50+i*300,222),Vector2(280,52)); buttons.append(inspect_button)
			var switch_button := button("",toggle.bind(i),"Primary"); switch_button.focus_mode=Control.FOCUS_ALL
			place(switch_button,Vector2(50+i*300,284),Vector2(280,52)); buttons.append(switch_button)
	elif kind=="music":
		for i in range(5):
			var b := button(["DO","RE","MI","SO","LA"][i],note.bind(i),"Primary"); b.focus_mode=Control.FOCUS_ALL
			place(b,Vector2(50+i*180,232),Vector2(164,66)); buttons.append(b)
		var reset := button("Clear phrase",reset_phrase,"Row"); reset.focus_mode=Control.FOCUS_ALL
		place(reset,Vector2(50,312),Vector2(280,50)); buttons.append(reset)
	else:
		place(label("Offer",19,true),Vector2(50,226),Vector2(140,38))
		offer_slider=HSlider.new(); offer_slider.min_value=35; offer_slider.max_value=130; offer_slider.step=1
		place(offer_slider,Vector2(220,226),Vector2(700,40)); offer_slider.value_changed.connect(func(value): offer=value; refresh(); checkpoint())
		place(label("Delivery scope",19,true),Vector2(50,298),Vector2(170,38))
		scope_slider=HSlider.new(); scope_slider.min_value=50; scope_slider.max_value=100; scope_slider.step=1
		place(scope_slider,Vector2(220,298),Vector2(700,40)); scope_slider.value_changed.connect(func(value): scope=value; refresh(); checkpoint())
	submit=button("Test repair" if kind=="repair" else "Play phrase" if kind=="music" else "Make offer",submit_round,"Primary")
	submit.focus_mode=Control.FOCUS_ALL; place(submit,Vector2(650,476),Vector2(300,48))
	continuation=button("Continue",next_round,"Primary"); continuation.focus_mode=Control.FOCUS_ALL
	place(continuation,Vector2(650,476),Vector2(300,48)); continuation.visible=false
	if target.is_empty() and notes.is_empty(): generate()
	refresh(); checkpoint()
func generate() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed=absi((str(seed_value)+":"+str(round_i)).hash())
	target=[]; current=[]; inspected=[]; notes=[]; played=[]; effort=0; round_ready=false
	for i in range(3): target.append(rng.randi_range(0,1)); inspected.append(false)
	current=target.duplicate(); var faulty := rng.randi_range(0,2); current[faulty]=1-int(current[faulty])
	for i in range(3+round_i%2): notes.append(rng.randi_range(0,4))
	offer=70+round_i*4; scope=80
	feedback.text="Inspect before changing parts." if kind=="repair" else "Tap the notes in order; there is no timer." if kind=="music" else "Balance your margin, the client's budget and delivery."
func checkpoint() -> void:
	if done or not params.has("progress_token"): return
	Journey.modules["skills"].checkpoint({"round":round_i,"points":points,"history":history.duplicate(true),"target":target.duplicate(),"current":current.duplicate(),"inspected":inspected.duplicate(),"notes":notes.duplicate(),"played":played.duplicate(),"effort":effort,"offer":offer,"scope":scope,"round_ready":round_ready,"feedback":feedback.text},int(params["progress_token"]),str(params["progress_owner"]))
func refresh() -> void:
	if round_i>=rounds:
		finish(clampf(points/float(rounds)*(0.75+clampf(float(params.get("skill",50)),0,100)/400.0),0,1),{"rounds":rounds,"feedback":"\n".join(history),"practice":params.get("practice",false)}); return
	status.text="Round %d/%d · untimed" % [round_i+1,rounds]
	if kind=="repair":
		prompt.text="A toy console has one faulty relay. Inspect a relay, change its setting, then test. Extra work reduces the round score."
		for i in range(3):
			buttons[i*2].text="%s: %s" % [["A","B","C"][i],("needs ON" if int(target[i])==1 else "needs OFF") if inspected[i] else "inspect"]
			buttons[i*2+1].text="%d · %s %s" % [i+1,["A","B","C"][i],"ON" if int(current[i])==1 else "OFF"]
	elif kind=="music":
		var names: Array=["DO","RE","MI","SO","LA"]
		prompt.text="Phrase: "+" → ".join(notes.map(func(i): return names[int(i)]))+"\nPlayed: "+" → ".join(played.map(func(i): return names[int(i)]))
	else:
		var cost := 35.0+round_i*4+scope*0.35; var cap := 90+round_i*4; var minimum := 65+round_i%3*5
		prompt.text="Client budget %d · needs scope %d+.\nOffer %d · scope %d · cost %d · margin %d · client room %d." % [cap,minimum,offer,scope,cost,offer-cost,cap-offer]
		offer_slider.set_value_no_signal(offer); scope_slider.set_value_no_signal(scope)
		offer_slider.editable=not round_ready; scope_slider.editable=not round_ready
	for b in buttons: b.disabled=round_ready
	submit.visible=not round_ready; continuation.visible=round_ready
func inspect(index: int) -> void:
	if done or round_ready or index not in [0,1,2] or inspected[index]: return
	inspected[index]=true; effort+=1; refresh(); checkpoint()
func toggle(index: int) -> void:
	if done or round_ready or index not in [0,1,2]: return
	current[index]=1-int(current[index]); effort+=1; refresh(); checkpoint()
func note(index: int) -> void:
	if done or round_ready or index<0 or index>=5 or played.size()>=notes.size(): return
	played.append(index); refresh(); checkpoint()
func reset_phrase() -> void:
	if done or round_ready: return
	played.clear(); effort+=1; refresh(); checkpoint()
func submit_round() -> void:
	if done or round_ready: return
	var gain := 0.0; var text := ""
	if kind=="repair":
		var correct := current==target
		gain=maxf(0.35,1.0-maxi(0,effort-4)*0.08) if correct else 0.15
		text="Repair worked · %d actions." % effort if correct else "The test still found a fault."
	elif kind=="music":
		if played.size()!=notes.size(): feedback.text="Complete the phrase before playing it."; return
		var matched := 0
		for i in range(notes.size()): if int(notes[i])==int(played[i]): matched+=1
		gain=maxf(0,float(matched)/notes.size()-effort*0.03); text="%d/%d notes matched." % [matched,notes.size()]
	else:
		var cost := 35.0+round_i*4+scope*0.35; var cap := 90+round_i*4; var minimum := 65+round_i%3*5
		var feasible := offer>=cost and offer<=cap and scope>=minimum
		gain=clampf(0.40+minf(1,(offer-cost)/25.0)*0.25+scope/100.0*0.25+minf(1,(cap-offer)/20.0)*0.1,0,1) if feasible else 0.15
		text="Agreement fits · margin %d, scope %d." % [offer-cost,scope] if feasible else "No agreement: check cost, budget and required scope."
	points+=gain; round_ready=true; history.append(text); feedback.text=text+" Round score %d%%." % (gain*100)
	refresh(); continuation.grab_focus(); checkpoint()
func next_round() -> void:
	if done or not round_ready: return
	round_i+=1
	if round_i<rounds: generate()
	refresh(); checkpoint()
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5]:
			if kind=="music": note(int(event.keycode)-KEY_1)
			elif kind=="repair" and event.keycode<=KEY_3: toggle(int(event.keycode)-KEY_1)
			else: return
		elif event.keycode in [KEY_ENTER,KEY_SPACE]:
			if round_ready: next_round()
			else: submit_round()
		else: return
		get_viewport().set_input_as_handled()
