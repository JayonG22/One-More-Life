extends RefCounted
## Original person-portrait proportions, sized in a 100-unit canvas. Features are part of
## the face; no expression emoji or facial-status badge is created.
var view: Control
var av: Dictionary
var age: int
var gender: String
var mood: String
var skin: Color
var hair: Color
var ink := Color("#443832")
func _init(target: Control): view=target
func ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(40):
		var angle := TAU*i/40.0
		points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	view.draw_colored_polygon(points,color)
	points.append(points[0]); view.draw_polyline(points,color,0.75,true)
func line(points: Array, color: Color, width: float = 1.4) -> void:
	view.draw_polyline(PackedVector2Array(points),color,width,true)
func curve(center: Vector2, radius: Vector2, start: float, end: float, color: Color, width: float = 1.4) -> void:
	var points: Array=[]
	for i in range(25):
		var angle := lerpf(start,end,i/24.0)
		points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	line(points,color,width)
func paint(a: Dictionary, years: int, gen: String, expression: String) -> void:
	av=Avatar.sanitize(a); age=years; gender=gen; mood=expression
	if int(av["figure"])>0: gender=["male","female","nonbinary"][int(av["figure"])-1]
	skin=Color(Avatar.SKIN_COL[int(av["skin"])])
	if mood=="unwell": skin=skin.lerp(Color("#b9c5b0"),0.20)
	if mood=="strain": skin=skin.lerp(Color("#c58d7e"),0.10)
	if mood=="remembered": skin=skin.lerp(Color("#929996"),0.45)
	hair=Color(Avatar.HAIR_COL[int(av["hair_color"])])
	if int(av["hair_color"])==0:
		hair=Color("#6c4c38")
		if int(av["hair"])==1: hair=Color("#a65c39")
		if int(av["hair"])==3: hair=Color("#d2d0c4")
		if int(av["hair"])==5: hair=Color("#d8bd78")
	if age>=55: hair=hair.lerp(Color("#cbc8bc"),clampf((age-55)/40.0,0,0.8))
	var cut := int(av["cut"])
	if cut==0:
		cut=4 if gender=="female" else 2
		if int(av["hair"])==2: cut=6
		if int(av["hair"])==4: cut=16
	if age<3: cut=1
	var dress := Color(Avatar.CLOTH_COL[int(av["clothes"])])
	var style := int(av["style"])
	if style==25: skin=Color("#b0bab9"); ink=Color("#465661")
	elif style==26: skin=Color("#a1b997"); ink=Color("#443832")
	else: ink=Color("#443832")
	if style in [6,7,12]: dress=Color("#4a5b72")
	if style in [16,18,21,22]: dress=Color("#b8c2b9")
	if style in [8,9,13]: dress=Color("#7e536b")
	# The face carries the silhouette, as in the original person emojis.
	# Keep clothing as a small collar accent rather than a doll-like bust.
	ellipse(Vector2(50,79),Vector2(19,4),dress)
	if cut in [4,5,8,9,14]: ellipse(Vector2(50,44),Vector2(27,37 if cut==14 else 33),hair)
	if cut==10: ellipse(Vector2(75,45),Vector2(9,19),hair)
	if cut==11: ellipse(Vector2(50,18),Vector2(12,10),hair)
	if style in [3,12]: ellipse(Vector2(50,47),Vector2(29,36),Color("#647c7b") if style==3 else Color("#353943"))
	# Face shape alters jaw width without replacing the person's identity.
	var widths := [27.0,25.5,29.5,26.5,28.5]
	var heights := [31.0,33.0,30.0,32.0,31.5]
	var face_shape := int(av["face_shape"])
	var radius := Vector2(widths[face_shape],heights[face_shape])
	if age<13: radius=Vector2(radius.x+2,radius.y-2)
	ellipse(Vector2(50-radius.x,48),Vector2(4.0,6),skin.darkened(0.08))
	ellipse(Vector2(50+radius.x,48),Vector2(4.0,6),skin.darkened(0.08))
	if style==14:
		view.draw_colored_polygon(PackedVector2Array([Vector2(22,39),Vector2(23,56),Vector2(32,49)]),skin)
		view.draw_colored_polygon(PackedVector2Array([Vector2(78,39),Vector2(77,56),Vector2(68,49)]),skin)
	# Broad soft shading keeps the face legible like a person emoji.
	ellipse(Vector2(50,47),radius,skin.darkened(0.10))
	for i in range(7):
		var blend := i/6.0
		ellipse(Vector2(50,46-blend*1.5),Vector2(radius.x-0.6-blend*2.2,radius.y-0.8-blend*2.2),skin.darkened(0.045*(1-blend)))
	# Small highlights and blush have the same restrained, rounded character.
	ellipse(Vector2(42,32),Vector2(11,5),Color(1,0.95,0.83,0.035))
	if mood=="happy":
		ellipse(Vector2(35,57),Vector2(5,2.5),Color(0.86,0.33,0.25,0.24))
		ellipse(Vector2(65,57),Vector2(5,2.5),Color(0.86,0.33,0.25,0.24))
	if style not in [2,3,12]: draw_hair(cut)
	draw_eyes()
	draw_brows()
	var nose := int(av["nose"])
	if nose==0: ellipse(Vector2(50,54),Vector2(3,1.6),skin.darkened(0.22))
	elif nose==1: ellipse(Vector2(50,53),Vector2(3.2,2.0),skin.darkened(0.12))
	elif nose==2: line([Vector2(50,48),Vector2(48,54),Vector2(52,54)],skin.darkened(0.25),1.1)
	elif nose==3: curve(Vector2(50,54),Vector2(4,2),0,PI,skin.darkened(0.25),1.3)
	else: ellipse(Vector2(50,53),Vector2(2,3),skin.darkened(0.14))
	draw_mouth()
	draw_details()
	draw_accessories(style)
func draw_hair(cut: int) -> void:
	if cut==16: return
	if cut==15:
		curve(Vector2(50,30),Vector2(20,11),PI,TAU,hair,4)
		return
	if cut in [6,7,13]:
		var count := 11 if cut==7 else 9
		for i in range(count):
			var angle := PI+i*PI/(count-1)
			ellipse(Vector2(50,33)+Vector2(cos(angle)*20,sin(angle)*17),Vector2(7 if cut==13 else 5,8 if cut==13 else 6),hair)
		if cut==13:
			ellipse(Vector2(25,37),Vector2(7,14),hair); ellipse(Vector2(75,37),Vector2(7,14),hair)
		return
	if cut==1:
		curve(Vector2(52,22),Vector2(7,5),PI,TAU,hair,3)
		return
	# Rounded, softly shaded tufts follow the original emoji-like silhouette.
	if cut in [2,10,11]:
		# Smooth swept hair follows the earlier person portrait.
		ellipse(Vector2(50,27),Vector2(26,12),hair)
		ellipse(Vector2(31,27),Vector2(9,10),hair)
		ellipse(Vector2(41,20),Vector2(11,9),hair)
		ellipse(Vector2(54,20),Vector2(12,9),hair)
		ellipse(Vector2(66,24),Vector2(10,10),hair)
		curve(Vector2(43,22),Vector2(10,6),PI+0.2,TAU-0.4,hair.lightened(0.06),1.5)
	else:
		ellipse(Vector2(50,25),Vector2(29,14),hair.darkened(0.05))
		ellipse(Vector2(49,23),Vector2(27,12),hair)
		curve(Vector2(47,23),Vector2(19,8),PI+0.25,TAU-0.5,hair.lightened(0.055),1.5)
	ellipse(Vector2(28,34),Vector2(5,11),hair)
	ellipse(Vector2(72,34),Vector2(5,10),hair)
	if cut in [3,4,5,12,14]:
		ellipse(Vector2(39,30),Vector2(15,9 if cut in [3,12] else 7),hair)
		ellipse(Vector2(65,28),Vector2(8,10),hair)
		curve(Vector2(40,29),Vector2(12,6),PI,TAU,hair.lightened(0.10),1.4)
	if cut in [4,14]:
		line([Vector2(28,35),Vector2(25,52),Vector2(28,69)],hair,6)
		line([Vector2(72,35),Vector2(75,52),Vector2(72,69)],hair,6)
	if cut==5:
		for x in [26,74]: curve(Vector2(x,49),Vector2(4,17),-PI/2,PI/2,hair,5)
	if cut in [8,9]:
		for x in [28,35,42,49,56,63,70]:
			line([Vector2(x,23),Vector2(x-2,30),Vector2(x,63 if x<=28 or x>=70 else 37)],hair.lightened(0.06),4)
	if cut==10: ellipse(Vector2(73,34),Vector2(6,9),hair)
func draw_eyes() -> void:
	var shape := int(av["eyes"])
	var eye_color := Color(Avatar.EYE_COL[int(av["eye_color"])])
	for x in [39.0,61.0]:
		if mood=="remembered":
			curve(Vector2(x,48),Vector2(4.8,3.2),PI,TAU,ink,2.4)
			continue
		var heights := [3.4,2.8,4.1,3.2,2.2,3.2]
		var ry: float=heights[shape]
		if mood in ["unwell","tired"]: ry*=0.65
		elif mood=="happy": ry*=0.85
		# White almond eyes and small irises retain the earlier face design.
		ellipse(Vector2(x,46),Vector2(5.0,ry),Color("#f5ede0"))
		ellipse(Vector2(x,46.1),Vector2(2.7,ry*0.94),eye_color)
		ellipse(Vector2(x,46.3),Vector2(1.4,ry*0.77),ink.darkened(0.45))
		ellipse(Vector2(x-0.65,45.3),Vector2(0.55,0.65),Color(1,0.97,0.90,0.85))
		curve(Vector2(x,46),Vector2(5,ry),PI,TAU,ink,1.05)
		if shape in [3,5]: line([Vector2(x+2,44),Vector2(x+3.6,42.9)],ink,0.8)
		if mood in ["tired","unwell"]: curve(Vector2(x,49.7),Vector2(4.0,1.3),0,PI,skin.darkened(0.20),0.9)
func draw_brows() -> void:
	var brow := int(av["brows"]); var weight: float=[1.3,2.0,1.0,1.6,2.2][brow]
	for side in [-1,1]:
		var x: float=50.0+side*11
		var inner := Vector2(x-side*4,39.5); var outer := Vector2(x+side*4,39.8)
		if mood in ["low","unwell"]: inner.y-=2.2; outer.y+=1
		if mood=="strain": inner.y+=1.5; outer.y-=1.5
		if brow==3: inner.y-=1
		line([outer,Vector2(x,38.4 if brow!=4 else 39.6),inner],hair.darkened(0.16),weight)
func draw_mouth() -> void:
	var width: float=[8.0,10.0,8.5,6.0][int(av["mouth"])]
	var lip := Color("#62402f")
	if mood=="happy":
		var smile := PackedVector2Array([Vector2(50-width,59),Vector2(50+width,59)])
		for i in range(21):
			var angle := i*PI/20.0
			smile.append(Vector2(50+cos(angle)*width,59+sin(angle)*5))
		view.draw_colored_polygon(smile,lip)
		view.draw_colored_polygon(PackedVector2Array([Vector2(50-width+1,59.3),Vector2(50+width-1,59.3),Vector2(50+width-2,60.8),Vector2(50-width+2,60.8)]),Color("#fff1df"))
	elif mood in ["low","unwell"]: curve(Vector2(50,65),Vector2(width,3),PI,TAU,lip,1.8)
	elif mood=="strain": line([Vector2(44,62),Vector2(48,61),Vector2(52,63),Vector2(57,61)],lip,1.5)
	elif mood in ["tired","remembered"]: line([Vector2(44,62),Vector2(56,62)],lip,1.5)
	elif mood=="neutral": line([Vector2(44,62),Vector2(56,62)],lip,1.8)
	else: curve(Vector2(50,58.5),Vector2(width,3.3),0.12,PI-0.12,lip,2.1)
func draw_details() -> void:
	var details := int(av["details"])
	if details in [1,2]:
		for x in [34,38,41,59,62,66]: ellipse(Vector2(x,55+(x%3)),Vector2(0.75,0.75),skin.darkened(0.30))
	if details==2: ellipse(Vector2(50,56),Vector2(0.7,0.7),skin.darkened(0.3))
	if details==3: ellipse(Vector2(63,57),Vector2(1.0,1.0),skin.darkened(0.5))
	if details==4: line([Vector2(64,33),Vector2(63,38)],skin.darkened(0.25),1.3)
	if age>=55:
		for x in [31,69]: line([Vector2(x,46),Vector2(x+(2 if x>50 else -2),48)],skin.darkened(0.22),0.8)
		curve(Vector2(50,37),Vector2(9,1),PI,TAU,skin.darkened(0.16),0.7)
	var beard := int(av["facial_hair"])
	if int(av["style"])==1 and beard==0: beard=3
	if age>=16 and beard>0:
		if beard in [1,2]: curve(Vector2(50,72),Vector2(16,8),PI,TAU,Color(hair,0.3),3.5)
		if beard in [2,3,5]: curve(Vector2(50,57),Vector2(18,16),0,PI,hair,5 if beard==2 else 8)
		if beard in [3,4,5]:
			curve(Vector2(46,58),Vector2(5,2),PI,TAU,hair,2.5); curve(Vector2(54,58),Vector2(5,2),PI,TAU,hair,2.5)
		if beard==5: ellipse(Vector2(50,70),Vector2(4,6),hair)
func draw_accessories(style: int) -> void:
	var accessory := int(av["accessory"])
	if style==16 and accessory==0: accessory=1
	if style==23 and accessory==0: accessory=7
	if style in [27,28] or accessory in [1,2,3]:
		var glass := Color("#303a43") if style==27 or accessory==3 else Color("#665c4c")
		for x in [39,61]:
			if style==28 and x==39: continue
			if accessory==3 or style==27: ellipse(Vector2(x,46),Vector2(7,5),glass)
			else: curve(Vector2(x,46),Vector2(7,5 if accessory==1 else 6.5),0,TAU,glass,1.6)
		line([Vector2(46,45),Vector2(54,45)],glass,1.3)
	if accessory in [4,5]:
		for x in [27,73]:
			if accessory==4: ellipse(Vector2(x,53),Vector2(1.6,2),Color("#b4a272"))
			else: curve(Vector2(x,56),Vector2(2.5,4),0,TAU,Color("#b4a272"),1.5)
	if accessory==6: ellipse(Vector2(53,55),Vector2(1,1),Color("#b1b8ba"))
	if accessory==7: curve(Vector2(50,46),Vector2(32,32),PI,TAU,Color("#536878"),3); ellipse(Vector2(23,47),Vector2(4,10),Color("#637d85")); ellipse(Vector2(77,47),Vector2(4,10),Color("#637d85"))
	if style in [2,3,4,5,6,7,8,9,10,17,18,19,20,29,30,35]:
		var cap_color := Color("#547c83")
		if style==2: cap_color=Color("#d3cdb8")
		if style in [5,8]: cap_color=Color("#cfb777")
		if style in [7,10,19]: cap_color=Color("#8b7456")
		if style==9: cap_color=Color("#696182")
		if style in [18,35]: cap_color=Color("#d0d1be")
		if style==8:
			view.draw_colored_polygon(PackedVector2Array([Vector2(29,27),Vector2(27,14),Vector2(40,20),Vector2(50,8),Vector2(60,20),Vector2(73,14),Vector2(71,27)]),cap_color)
		elif style in [9,29]:
			view.draw_colored_polygon(PackedVector2Array([Vector2(29,25),Vector2(49,1),Vector2(70,25)]),cap_color)
			line([Vector2(26,26),Vector2(74,26)],cap_color,4)
		elif style==30: curve(Vector2(50,12),Vector2(18,4),0,TAU,Color("#cbb97e"),2)
		else:
			ellipse(Vector2(50,22),Vector2(23,12),cap_color)
			line([Vector2(28,28),Vector2(73,28)],cap_color.darkened(0.1),4)
	if style in [31]: curve(Vector2(50,22),Vector2(22,10),PI,TAU,Color("#797583"),6)
	if style in [15,16,18,21,22,23,24,32,33]:
		line([Vector2(43,79),Vector2(50,87),Vector2(57,79)],Color("#d4d8ca"),2)
		if style in [32,33]: line([Vector2(50,83),Vector2(50,96)],Color("#493e4c"),3)
	if style==13:
		view.draw_colored_polygon(PackedVector2Array([Vector2(45,64),Vector2(47,68),Vector2(48,64)]),Color("#f4edda"))
		view.draw_colored_polygon(PackedVector2Array([Vector2(52,64),Vector2(53,68),Vector2(55,64)]),Color("#f4edda"))
	if style==17: curve(Vector2(50,44),Vector2(30,36),0,TAU,Color("#b7c4c0"),3); line([Vector2(27,67),Vector2(73,67)],Color("#8a9fa5"),3)
	if style==24:
		view.draw_colored_polygon(PackedVector2Array([Vector2(22,22),Vector2(50,12),Vector2(78,22),Vector2(50,31)]),Color("#424751"))
		line([Vector2(72,24),Vector2(73,38)],Color("#b4a373"),1.5)
	if style==15: ellipse(Vector2(45,22),Vector2(24,8),Color("#7a6471"))
	if style==22: line([Vector2(60,83),Vector2(60,92)],Color("#967068"),2); line([Vector2(56,87),Vector2(64,87)],Color("#967068"),2)
	if style==25: line([Vector2(50,17),Vector2(50,10)],Color("#829797"),2); ellipse(Vector2(50,8),Vector2(3,3),Color("#b69579")); line([Vector2(36,67),Vector2(64,67)],Color("#829797"),1)
	if style==26: curve(Vector2(50,23),Vector2(21,17),PI,TAU,Color("#91a788"),3)
	if style==36: curve(Vector2(50,25),Vector2(24,14),PI,TAU,Color("#8a9aab"),7)
	if style==37:
		for side in [-1,1]:
			view.draw_colored_polygon(PackedVector2Array([Vector2(50+side*24,40),Vector2(50+side*34,43),Vector2(50+side*27,53)]),Color("#7c9c99"))
