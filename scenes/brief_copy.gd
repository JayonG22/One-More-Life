extends RefCounted
## Authored short screen summaries. Full explanations remain available on demand.
const SUMMARY := {
	"Connected lives":"People, projects and choices that carry forward.",
	"People & commitments":"Keep promises, build trust and repair relationships.",
	"School plans":"Age-appropriate lessons and projects that stay in your record.",
	"Work practice":"Short challenges with clear feedback and relevant skill effects.",
	"Lessons & curriculum":"Study, practise subjects and build grade readiness.",
	"Projects & portfolio":"Choose longer schoolwork and keep its results.",
	"Teams & seasons":"Train and play three tactical fixtures each season.",
	"Learning & placements":"Build practical skills through courses and supervised work.",
	"Ambitions & enterprise":"Pursue goals and deliver work people can rely on.",
	"Trouble & recovery":"Face consequences, recover and rebuild.",
	"Places & community":"Find local opportunities and improve your neighbourhood.",
	"Generations & later life":"Care, mentor and prepare the next generation.",
	"Identity & stories":"Appearance, story chapters and content preferences.",
	"Hobbies & quiet goals":"Enjoy ordinary activities or build a personal project.",
	"Shared household reserve":"Save together while keeping each person's share recorded.",
	"Museum & collecting":"Build, care for and share a collection.",
	"Work & independence":"Projects, training, promotions and finances.",
	"Company operations":"Manage products, staff, customers and accounts.",
	"Family succession":"Choose a successor or transfer company ownership now.",
	"Fresh Start":"Build a steady adult life through four chapters.",
	"Debt recovery":"Make a workable repayment plan and rebuild credit.",
	"Relationships":"Choose a person to see their life and shared history.",
	"Household":"Share the work, bills and care at home.",
	"Shopping":"Find goods, homes, vehicles and pets.",
	"Education":"Study, practise and earn qualifications.",
	"Health":"Manage wellbeing, treatment and recovery.",
	"Prison":"Navigate custody, prepare release and face the aftermath.",
	"Pet life":"Care, training, competitions and pet family history."
}
static func summary(title: String) -> String: return str(SUMMARY.get(title,""))
