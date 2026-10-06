#!/usr/bin/env python3
"""Short original timeline summaries; no dialogue, screenshots or theme music.
Each season/arc coverage is stated; continuing stories have no invented death.
"""
import json, re
from pathlib import Path
R=Path(__file__).resolve().parents[2]
profiles=[
('aang','Aang','Cartoon','Avatar: The Last Airbender','The original animated series','🌬️','male',[
('The Southern Air Temple','Childhood','Aang grows up among the Air Nomads. Learning he is the Avatar turns a familiar childhood into a duty he fears.'),
('The century in the ice','A hundred years later','Aang’s escape ends in a storm. Katara and Sokka eventually find him, and he wakes to a world transformed by war.'),
('The water journey','Book One','Travelling with his new friends, Aang begins learning waterbending. The Northern Water Tribe faces a Fire Nation assault.'),
('Learning to stand firm','Book Two','Toph joins the group and teaches Aang earthbending. Her lessons demand a steadiness that airbending let him avoid.'),
('The fall of Ba Sing Se','Book Two','The group’s search for safety leads into a struggle inside Ba Sing Se. Aang is gravely wounded and Katara saves him.'),
('The teacher from the enemy','Book Three','Zuko rejects his father’s path and offers to teach firebending. Trust must be rebuilt before the final confrontation.'),
('A victory without an execution','Sozin’s Comet','Aang confronts Ozai and removes his bending. He ends the threat without abandoning his refusal to kill.'),
('After the war','Series endpoint','The war ends and Zuko becomes Fire Lord. Aang and his friends can begin rebuilding. This chapter closes; their lives continue.')],['https://www.nick.com/info-page/udnx2v/aang','https://www.nick.com/fan-hub/avatar','https://www.youtube.com/watch?v=kXShLPXfWZA']),
('fry','Philip J. Fry','Adult Animation','Futurama','Selected milestones through Meanwhile (2013)','🚀','male',[
('An ordinary delivery','1999','Fry works as a pizza delivery boy in New York. A New Year’s Eve delivery takes him to a cryogenics laboratory.'),
('A thousand years away','2999','An accident freezes Fry. He wakes a millennium later, with the familiar city replaced by a strange future.'),
('The people of the new city','A new beginning','Fry meets Leela and Bender. Escaping his assigned career leads him to his distant relative, Professor Farnsworth.'),
('Planet Express','A working life','Fry joins the interplanetary delivery crew. Another delivery job becomes a way to belong among an unlikely group of people.'),
('The family left behind','The Luck of the Fryrish','Fry searches for a reminder of his old life. What he learns about his brother changes the meaning of that memory.'),
('The music he cannot keep','The Devil’s Hands Are Idle Playthings','A deal grants Fry remarkable musical ability. The bargain unravels, but his connection with Leela matters beyond the performance.'),
('Time outside the world','Meanwhile','A broken time device leaves Fry and Leela together while the world is frozen. They share a life beyond its ordinary clock.'),
('Another beginning','Selected arc endpoint','The Professor offers a way back. Fry and Leela face another beginning together. This selected arc ends without inventing their deaths.')],['https://www.hulu.com/guides/futurama','https://www.hulu.com/series/futurama-85bf4cc1-cd8b-4469-ad87-7289217a0b74','https://en.wikipedia.org/wiki/Meanwhile_(Futurama)']),
('naruto','Naruto Uzumaki','Anime','Naruto / Naruto Shippuden','Birth through becoming the Seventh Hokage','🍥','male',[
('The child with the Nine Tails','Birth','Naruto is born during the attack on the Hidden Leaf Village. His parents die protecting him; the Nine Tails is sealed inside him.'),
('Recognition at the academy','Childhood','Naruto struggles at the academy and dreams of becoming Hokage. Iruka’s recognition gives him a place to begin.'),
('Team Seven','Genin','Naruto joins Sasuke and Sakura under Kakashi. Missions teach the team that living with danger requires more than ambition.'),
('The teacher on the road','Training','Jiraiya becomes Naruto’s teacher. New techniques and difficult encounters give the dream of Hokage a more demanding shape.'),
('The friend who leaves','A divided team','Sasuke leaves the village. Naruto’s attempt to bring him back fails, but the promise becomes central to his path.'),
('The village under attack','Pain’s assault','Naruto returns to confront Pain after the village is devastated. His response earns recognition from people who once avoided him.'),
('War and the final confrontation','Fourth Great Ninja War','Naruto fights alongside allies in the war. Afterward he and Sasuke confront each other again before reaching reconciliation.'),
('The Seventh Hokage','Arc endpoint','Naruto becomes the Seventh Hokage. The dream becomes a responsibility to others. This arc ends while his adult life continues.')],['https://naruto-official.com/en/news/01_1610','https://naruto-official.com/en/news/01_1611','https://naruto-official.com/en/about']),
('walter','Walter White','Crime / Action','Breaking Bad','The television series through Felina','🧪','male',[
('A teacher’s ordinary life','Before the diagnosis','Walter teaches chemistry in Albuquerque and works another job. He lives with Skyler and their son, Walter Jr.'),
('The diagnosis','Season One','A cancer diagnosis changes Walter’s view of his future. He enters the drug trade with former student Jesse Pinkman.'),
('The name Heisenberg','The growing operation','Walter adopts an alias as the operation grows. Each attempt to control events draws him further into violence and deception.'),
('The new employer','Gus Fring’s operation','Working for Gus offers an organised operation. The apparent security brings new dependencies and increasingly dangerous conflicts.'),
('The power struggle','The break with Gus','Walter’s struggle with Gus ends in a deadly confrontation. Removing one threat leaves Walter more willing to exercise power himself.'),
('The empire fractures','The final season','The expanding operation destroys the separation between Walter’s criminal and family lives. Hank’s investigation closes in.'),
('Ozymandias','The collapse','Hank is killed and Walter’s family breaks apart. Walter escapes into isolation with the consequences of what he has built.'),
('Felina','Series endpoint','Walter returns to settle his affairs, frees Jesse from captivity and is fatally wounded. His story ends in the laboratory.')],['https://www.amcglobalmedia.com/2007/07/15/amc-to-launch-new-original-drama-series-breaking-bad/','https://www.amc.com/blogs/follow-the-rise-and-fall-of-the-white-family-in-these-breaking-bad-episodes--1008871','https://en.wikipedia.org/wiki/Felina_(Breaking_Bad)'])]
out=[]
aliases = {
 'aang': ('Aangxiety', 'The Last Air-Errand', {'Aang': 'Aangxiety'}),
 'fry': ('Philip J. Fryday', 'Future-Rama', {'Fry': 'Fryday'}),
 'naruto': ('Noodle Uzumayhem', 'Noodle: Extra Broth', {'Naruto': 'Noodle'}),
 'walter': ('Walter Off-White', 'Breaking Plaid', {'Walter White': 'Walter Off-White', 'Walter': 'Walter Off-White'}),
}
for key,name,category,show,coverage,icon,gender,chapters,sources in profiles:
 alias, alias_show, replacements = aliases[key]
 def renamed(text):
  return re.sub('|'.join(re.escape(key) for key in replacements), lambda match: replacements[match.group(0)], text)
 out.append(dict(id=key,name=alias,category=category,show=alias_show,reference_name=name,reference_show=show,coverage=coverage,icon=icon,gender=gender,sources=sources,chapters=[dict(title=t,period=p,text=renamed(x)) for t,p,x in chapters]))
(R/'data/tv_life.json').write_text(json.dumps(out,ensure_ascii=False,indent=1)+'\n',encoding='utf-8',newline='\n')
print(len(out),'TVLife profiles,',sum(len(p['chapters']) for p in out),'chapters')
