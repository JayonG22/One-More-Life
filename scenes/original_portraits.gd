class_name OriginalPortraits
extends RefCounted
## The matching original Windows face paths; never a replacement head drawing.
static var parts: Dictionary={}
static var cache: Dictionary={}
static func supported(av: Dictionary, years: int) -> bool:
	return years<13 or (int(av.get("style",0))==0 and (years>=65 or int(av.get("hair",0))==0))
static func person_kind(years: int, gender: String) -> String:
	if years<3: return "baby"
	if years<13: return "girl" if gender=="female" else "boy" if gender=="male" else "child"
	if years>=65: return "old_woman" if gender=="female" else "old_man" if gender=="male" else "older_person"
	return "woman" if gender=="female" else "man" if gender=="male" else "person"
static func texture(av: Dictionary, years: int, gender: String, mood: String) -> Texture2D:
	if not supported(av,years): return null
	var hair := int(av.get("portrait_hair",0)); var eyes := int(av.get("portrait_eyes",0))
	var accessory := int(av.get("portrait_accessory",0)); var detail := int(av.get("portrait_detail",0))
	if hair==0 and eyes==0 and accessory==0 and detail==0 and mood in ["steady","neutral","remembered"]: return null
	var gen := gender
	match int(av.get("figure",0)):
		1: gen="male"
		2: gen="female"
		3: gen="nonbinary"
	var who := person_kind(years,gen)
	var tone: String=["default","light","medium-light","medium","medium-dark","dark"][int(av.get("skin",0))]
	var source := who+"_flat_"+tone
	var key := "%s:%d:%d:%d:%d:%s" % [source,hair,eyes,accessory,detail,mood]
	if cache.has(key): return cache[key]
	if parts.is_empty(): parts=ContentDB._load_json("res://data/original_portraits.json",{})
	if not parts.has(source): return null
	var mouth_axis: float={"baby":48.8,"boy":47.2,"girl":47.6,"child":47.2,"old_woman":47.0}.get(who,47.0)
	var eye_axis: float={"baby":19.5,"boy":18.1,"girl":18.7,"child":18.1}.get(who,17.5)
	var svg := '<svg width="128" height="128" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">'
	for part in parts[source]:
		var path: String=part["svg"]; var role: String=part["role"]
		if role=="hair" and hair>0: path=path.replace('fill="'+str(part["fill"])+'"','fill="'+Avatar.HAIR_COL[hair-1]+'"')
		if role=="iris" and eyes>0: path=path.replace('fill="'+str(part["fill"])+'"','fill="'+Avatar.EYE_COL[eyes-1]+'"')
		var transform := ""
		if role=="mouth":
			if mood in ["low","strain","unwell"]: transform="translate(0 %s) scale(1 -1)" % mouth_axis
			elif mood=="happy": transform="translate(-1.28 -1.18) scale(1.08 1.05)"
			elif mood=="tired": transform="translate(0 %s) scale(1 0.5)" % (mouth_axis*0.25)
		if role in ["eye","iris"] and mood in ["tired","unwell"]: transform="translate(0 %s) scale(1 0.64)" % (eye_axis*0.36)
		if role=="brow":
			if mood in ["low","unwell"]: transform="translate(0 0.6)"
			elif mood=="strain": transform="translate(0 1.1)"
			elif mood=="happy": transform="translate(0 -0.45)"
		svg+=path if transform=="" else '<g transform="'+transform+'">'+path+'</g>'
	var decorations := extras(accessory,detail)
	if who in ["baby","boy","girl","child"] and decorations!="":
		decorations='<g transform="translate(0 %s)">' % (eye_axis-17.5)+decorations+'</g>'
	svg+=decorations
	svg+='</svg>'
	var image := Image.new()
	if image.load_svg_from_string(svg)!=OK: return null
	var result := ImageTexture.create_from_image(image)
	# Small bounded cache shared by every portrait; no per-frame rasterization.
	if cache.size()>=128: cache.erase(cache.keys()[0])
	cache[key]=result
	return result

static func extras(accessory: int, detail: int) -> String:
	var svg := ""
	match detail:
		1: svg+='<g fill="#ad8067" opacity="0.65"><circle cx="9.8" cy="19.4" r="0.22"/><circle cx="10.6" cy="19.8" r="0.19"/><circle cx="11.4" cy="19.3" r="0.22"/><circle cx="20.6" cy="19.3" r="0.22"/><circle cx="21.4" cy="19.8" r="0.19"/><circle cx="22.2" cy="19.4" r="0.22"/></g>'
		2: svg+='<circle cx="21.5" cy="20.4" r="0.3" fill="#6c4c38"/>'
		3: svg+='<path d="M21 13.5 L21.7 14.5" stroke="#ba9280" stroke-width="0.38" stroke-linecap="round"/>'
	match accessory:
		1: svg+='<g fill="none" stroke="#607681" stroke-width="0.42"><circle cx="11.5" cy="17.2" r="3.1"/><circle cx="20.5" cy="17.2" r="3.1"/><path d="M14.6 16.8 Q16 16.2 17.4 16.8 M8.4 16 L6.7 15.7 M23.6 16 L25.3 15.7"/></g>'
		2: svg+='<g fill="none" stroke="#725947" stroke-width="0.5"><rect x="8.5" y="14.9" width="6.1" height="4.9" rx="1.2"/><rect x="17.4" y="14.9" width="6.1" height="4.9" rx="1.2"/><path d="M14.6 16.4 Q16 15.8 17.4 16.4 M8.5 16 L6.7 15.7 M23.5 16 L25.3 15.7"/></g>'
		3: svg+='<g fill="#27313c" stroke="#65727c" stroke-width="0.4"><rect x="8.5" y="14.9" width="6.1" height="4.9" rx="1.2"/><rect x="17.4" y="14.9" width="6.1" height="4.9" rx="1.2"/><path d="M14.6 16.4 Q16 15.8 17.4 16.4" fill="none"/></g>'
		4: svg+='<g fill="#c6b99d"><circle cx="7" cy="20.1" r="0.55"/><circle cx="25" cy="20.1" r="0.55"/></g>'
		5: svg+='<g fill="none" stroke="#c6b99d" stroke-width="0.38"><ellipse cx="7" cy="20.7" rx="0.7" ry="1.2"/><ellipse cx="25" cy="20.7" rx="0.7" ry="1.2"/></g>'
	return svg
