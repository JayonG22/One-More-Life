extends Node

## NAMES — employers and businesses that sound like what they are.
##
## A hospital is not "Halden Logistics" and the army is not a lightbulb company.
## Each field has its own word lists and its own shapes of name, a life never
## meets the same name twice, and the armed forces are named for the country.

const SHAPES_GENERIC := ["{a} {b}", "{a} & {c}", "{a} {b}", "{s} {b}", "The {adj} {noun}", "{a}{a2} {b}"]

const ADJ := ["Golden", "Little", "Blue", "Old", "Crooked", "Silver", "Red", "Happy", "Quiet", "Lucky", "Green", "Northern", "Corner", "Midnight", "Copper", "Wild", "Honest", "Rolling"]
const A := ["Halden", "Brightwell", "Corvin", "Ashby", "Northfield", "Kestrel", "Marlow", "Pryor", "Tandem", "Greaves", "Fairlight", "Oakhurst", "Vantage", "Penrose", "Holloway", "Sterling", "Quill", "Redgrave", "Meridian", "Thornton", "Cobalt", "Alder", "Ravenscroft", "Whitlock", "Hargreave", "Bellamy", "Dunmore", "Ellery", "Foxley", "Garrick", "Harlow", "Ingram", "Juniper", "Kingsley", "Lockhart", "Montague", "Nightingale", "Ormsby", "Pemberton", "Radcliffe", "Sheldon", "Tremaine", "Underhill", "Vance", "Wexford", "Yardley", "Zeller", "Aldous", "Barrow", "Calloway", "Dellwood", "Everly", "Finch", "Grantham", "Hollis", "Iverson", "Jarrow", "Keswick", "Linden", "Maddox", "Norwood", "Overton", "Prescott", "Quenby", "Rowan", "Stanhope", "Talbot", "Upton", "Vickery", "Winslow"]
const A2 := ["ton", "well", "ley", "ford", "mont", "wick", "stead", "crest"]

const SECTORS := {
	"Retail": {"b": ["Mart", "Superstore", "Outlet", "Bazaar", "Emporium", "Market", "Stores", "Trading Co."], "c": ["Daughters", "Sons", "Brothers"], "noun": ["Basket", "Shelf", "Till", "Trolley", "Bargain"], "full": ["Penny's Pantry", "Corner Basket", "Value Barn", "Bargain Bay", "Pocket Mart", "Dollar Dock", "Good Day Grocers", "Fresh & Fair", "The Daily Aisle", "Handy Hardware"]},
	"Food": {"b": ["Kitchen", "Bistro", "Diner", "Grill", "Cafe", "Tavern", "Eatery", "Smokehouse", "Bakery", "Noodle Bar", "Taqueria"], "c": ["Daughters", "Sons", "Fennel", "Thyme"], "noun": ["Spoon", "Ladle", "Fork", "Oven", "Skillet", "Pepper"], "full": ["Salt & Ember", "The Hungry Heron", "Mama Rosa's", "Burger Barn", "Pho Real", "Crumb & Co", "The Drunken Spoon", "Spice Route", "Golden Wok", "Slice of Heaven", "Big Tom's Chippy", "Café Fernweh"]},
	"Recreation": {"b": ["Leisure Centre", "Adventure Park", "Lanes", "Arcade", "Fitness", "Pool & Gym", "Playhouse", "Fun Fair"], "c": ["Sports", "Play"], "noun": ["Splash", "Strike", "Bounce", "Rally"], "full": ["Splash Zone", "Strike Lanes", "Jump Jungle", "Pixel Palace", "Lakeside Leisure", "Total Fitness"]},
	"Care": {"b": ["Care Home", "Nursery", "Day Centre", "Home Care", "Lodge", "Court", "Kindercare"], "c": ["Friends", "Carers"], "noun": ["Haven", "Cradle", "Acorn", "Harbour"], "full": ["Little Acorns Nursery", "Willow Court Care", "Sunbeam Day Centre", "Rainbow Bridge Care", "Maple Lodge", "Gentle Hands Home Care", "Evergreen Residential", "The Cedars"]},
	"Education": {"b": ["Primary School", "Academy", "College", "Grammar School", "Tutors", "Learning Centre", "Prep"], "c": ["Foundation", "Trust"], "noun": ["Oak", "Beacon", "Lantern"], "full": ["St Aldric's School", "Ridgeway Academy", "Brookside Primary", "Hartwell College", "Elmgrove Community School", "Northgate Sixth Form", "Silverlea Tutors", "Beacon Learning Centre"]},
	"Transport": {"b": ["Buses", "Coaches", "Cabs", "Transit", "Rail", "Ferries", "Taxis", "Rides"], "c": ["Travel", "Lines"], "noun": ["Route", "Wheel", "Ticket"], "full": ["Metroline Transit", "Swift Cabs", "Harbour Ferries", "Greenline Coaches", "Daybreak Rail", "City Loop Buses", "Blue Door Taxis", "Cross-Country Express"]},
	"Logistics": {"b": ["Logistics", "Freight", "Haulage", "Distribution", "Cargo", "Dispatch", "Warehousing", "Courier"], "c": ["Carriers", "Movers"], "noun": ["Pallet", "Crate", "Convoy"], "full": ["Northbound Freight", "Rapid Drop Courier", "Ironroad Haulage", "Parcel Hub", "Bridgeway Distribution", "Anchor Cargo"]},
	"Facilities": {"b": ["Cleaning", "Facilities", "Maintenance", "Property Services", "Janitorial", "Estates"], "c": ["Cleaners", "Services"], "noun": ["Broom", "Mop", "Sparkle"], "full": ["Spotless Cleaning", "Brightside Facilities", "Tidy Tom Maintenance", "Shine & Co", "Clearview Estates", "Fresh Start Cleaning"]},
	"Security": {"b": ["Security", "Guarding", "Protection", "Patrol", "Watch", "Shield"], "c": ["Guards"], "noun": ["Lock", "Beacon", "Sentry"], "full": ["Ironclad Security", "Sentinel Guarding", "Blue Shield Protection", "Nightwatch Patrol", "Castle Gate Security", "Vigil Services"]},
	"Office": {"b": ["Admin", "Business Services", "Solutions", "Temps", "Partners", "Associates", "Group"], "c": ["Partners", "Associates"], "noun": ["Ledger", "Folder", "Stapler"], "full": ["Pennington & Hale", "Keystone Office Solutions", "Paper Trail Partners", "Reliable Temps", "Clerk & Co", "Orbit Admin"]},
	"Trades": {"b": ["Builders", "Electrical", "Plumbing & Heating", "Joinery", "Roofing", "Construction", "Contractors", "Decorators", "Groundworks"], "c": ["& Sons", "Brothers"], "noun": ["Hammer", "Spanner", "Level"], "full": ["Dunmore & Sons Builders", "Sparky's Electrical", "Hot & Cold Plumbing", "Redbrick Construction", "Tradewind Joinery", "Rooftop Roofing", "Steady Hands Decorators", "Bolt & Beam"]},
	"Beauty": {"b": ["Hair Studio", "Salon", "Barbers", "Spa", "Nail Bar", "Beauty Lounge"], "c": ["& Co"], "noun": ["Comb", "Shears", "Blossom"], "full": ["Sharp Cuts Barbers", "The Polished Fox", "Velvet Hair Studio", "Lotus Spa", "Curl Up & Dye", "Blush & Bloom", "Razor & Ryder"]},
	"Public Safety": {"b": ["Fire & Rescue Service", "Police Service", "Paramedics", "Ambulance Service", "Constabulary"], "c": [""], "noun": [""], "full": ["__safety__"]},
	"Government": {"b": ["Council", "Borough Council", "Revenue Office", "Registry", "Housing Authority", "Department of Works", "Civil Service"], "c": [""], "noun": [""], "full": ["__gov__"]},
	"Aviation": {"b": ["Airways", "Air", "Aviation", "Airlines", "Air Charter", "Ground Services"], "c": ["Jets", "Wings"], "noun": ["Wing", "Skyline", "Contrail"], "full": ["Skyward Airways", "Meridian Air", "Coastline Charter", "Cirrus Airlines", "Altitude Ground Services", "Kestrel Air"]},
	"Tech": {"b": ["Labs", "Software", "Systems", "Digital", "Networks", "Cloud", "Interactive", "Data", "AI", "Studios"], "c": [""], "noun": ["Pixel", "Byte", "Vector", "Node", "Cache"], "full": ["Lumen Labs", "Pixelforge", "Quantafy", "Nodewise", "Bytecraft Studios", "Cloudberry Systems", "Signal & Noise", "Gridlock Games", "Oakleaf Software", "Vectorly"]},
	"Healthcare": {"b": ["Hospital", "Medical Centre", "Clinic", "Health Trust", "Surgery", "Dental Practice", "Pharmacy", "Mercy Hospital"], "c": ["Health"], "noun": ["Cross", "Pulse", "Remedy"], "full": ["St Brendan's Hospital", "Riverside Medical Centre", "Greenfield Surgery", "Mercy General", "Bright Smile Dental", "Westbank Clinic", "Victoria Infirmary", "Pulse Health Trust", "Lakeside Pharmacy", "Holy Cross Hospital"]},
	"Finance": {"b": ["Bank", "Capital", "Trust", "Wealth", "Savings & Loan", "Credit Union", "Insurance", "Securities", "Mutual"], "c": ["& Co", "Partners"], "noun": ["Vault", "Ledger"], "full": ["Sterling & Vance", "Meridian Trust", "Harbour Savings", "Ironbridge Capital", "Northern Mutual", "Cornerstone Credit Union", "Pembroke Insurance", "Greaves Wealth"]},
	"Business": {"b": ["Consulting", "Group", "Holdings", "Ventures", "Advisory", "Enterprises", "Strategy", "Partners"], "c": ["& Partners", "Associates"], "noun": ["Compass", "Summit"], "full": ["Summit Advisory", "Compass & Crane", "Redwood Ventures", "Blackwell Consulting", "Anchor Enterprises", "Keystone Strategy"]},
	"Engineering": {"b": ["Engineering", "Dynamics", "Works", "Industries", "Systems", "Fabrication", "Power", "Materials"], "c": [""], "noun": ["Gear", "Piston", "Girder"], "full": ["Ironbridge Engineering", "Halcyon Dynamics", "Brightwell Power", "Atlas Fabrication", "Northern Gear Works", "Axle & Arc"]},
	"Design": {"b": ["Studio", "Design", "Creative", "Atelier", "Collective", "Workshop"], "c": ["& Co"], "noun": ["Brush", "Sketch", "Palette"], "full": ["Paper Moon Studio", "Fable Design", "Kiln & Co", "Blot Creative", "Studio Marlowe", "Tangerine Collective"]},
	"Media": {"b": ["Media", "Broadcasting", "Press", "News", "Productions", "Radio", "Pictures", "Daily"], "c": [""], "noun": ["Herald", "Beacon", "Courier"], "full": ["The Evening Courier", "Channel Nine Broadcasting", "Signal FM", "Meridian Pictures", "The Daily Lantern", "Northlight Productions", "Greywater Press", "Open Air Radio"]},
	"Science": {"b": ["Research Institute", "Laboratories", "Biosciences", "Pharma", "Observatory", "Genomics", "Analytics"], "c": [""], "noun": ["Helix", "Quark"], "full": ["Halcyon Biosciences", "Meridian Research Institute", "Northfield Laboratories", "Helix Genomics", "Quark Analytics", "Aldous Pharma", "Rosalind Institute"]},
	"Legal": {"b": ["Solicitors", "Law", "Legal", "Chambers", "Attorneys", "LLP"], "c": ["& Associates"], "noun": [""], "full": ["__law__"]},
	"Military": {"b": [""], "c": [""], "noun": [""], "full": ["__mil__"]},
}

const GOV := ["%s Borough Council", "%s County Council", "City of %s Revenue Office", "%s Housing Authority", "%s Department of Works", "%s Registry Office", "%s Planning Office", "State of %s Civil Service"]
const SAFETY := ["%s Fire & Rescue", "%s Police Service", "%s Ambulance Service", "%s Constabulary", "%s Paramedic Response", "%s Coastguard"]
const LAW := ["%s & %s LLP", "%s, %s & Co Solicitors", "%s %s Chambers", "The Law Offices of %s & %s", "%s %s Attorneys"]
const PLACES := ["Ashford", "Brookfield", "Carlow", "Dunbridge", "Eastgate", "Fairhaven", "Glenmoor", "Highcliffe", "Ironbridge", "Kingsmead", "Lakeside", "Millbrook", "Newhaven", "Oakdale", "Portmouth", "Queensferry", "Riverbend", "Stonebridge", "Thornbury", "Westmere"]

const MIL_US := ["U.S. Army", "U.S. Navy", "U.S. Air Force", "U.S. Marine Corps", "U.S. Coast Guard", "Army National Guard", "Air National Guard", "U.S. Army Reserve"]
const MIL_UK := ["British Army", "Royal Navy", "Royal Air Force", "Royal Marines", "Army Reserve", "Royal Logistic Corps", "Parachute Regiment", "Royal Engineers"]
const MIL_X := ["%s Army", "%s Navy", "%s Air Force", "%s Marines", "%s Defence Force", "%s Reserve", "%s Land Forces"]


func _pick(a: Array) -> String:
	return str(a[randi() % a.size()])


func _used() -> Dictionary:
	var p := GameState.player
	if p.is_empty():
		return {}
	if not p.has("used_names") or not (p["used_names"] is Dictionary):
		p["used_names"] = {}
	return p["used_names"]


## A name for an employer in this field, different from every other the life has met.
func company(field: String, country: String = "") -> String:
	var used := _used()
	var nm := ""
	for _i in 30:
		nm = _make(field, country)
		if not used.has(nm):
			break
	used[nm] = true
	if used.size() > 400:
		used.clear()
	return nm


func _make(field: String, country: String) -> String:
	var sec: Dictionary = SECTORS.get(field, {})
	if sec.is_empty():
		return _generic(SECTORS["Business"])
	var full: Array = sec["full"]
	if full.size() == 1:
		match str(full[0]):
			"__mil__": return _military(country)
			"__gov__": return str(GOV[randi() % GOV.size()]) % _pick(PLACES)
			"__safety__": return str(SAFETY[randi() % SAFETY.size()]) % _pick(PLACES)
			"__law__": return str(LAW[randi() % LAW.size()]) % [_pick(A), _pick(A)]
	if randf() < 0.45:
		return _pick(full)
	return _generic(sec)


func _generic(sec: Dictionary) -> String:
	var shape := _pick(SHAPES_GENERIC)
	var b := _pick(sec["b"])
	var c := _pick(sec["c"])
	var noun := _pick(sec["noun"])
	if c == "" and "{c}" in shape:
		shape = "{a} {b}"
	if noun == "" and "{noun}" in shape:
		shape = "{a} {b}"
	var s := _pick(A)
	return shape.replace("{a2}", _pick(A2).to_lower() if false else "").replace("{a}", _pick(A)).replace("{b}", b).replace("{c}", c).replace("{s}", s).replace("{adj}", _pick(ADJ)).replace("{noun}", noun).strip_edges()


func _military(country: String) -> String:
	match country:
		"us": return _pick(MIL_US)
		"uk": return _pick(MIL_UK)
	var nm := country
	if country != "" and not ContentDB.country(country).is_empty():
		nm = str(ContentDB.country(country)["name"])
	if nm == "":
		return _pick(MIL_US)
	return str(MIL_X[randi() % MIL_X.size()]) % nm
