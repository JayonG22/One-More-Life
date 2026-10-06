"""Four scenes per authored arc: a decision and three distinct delayed branches."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ARCS = [
 ('promise','🗓️','The date on the fridge',[18,80],['child'],'{person.first} asks you to attend an important school presentation. It clashes with an optional appointment you already made.',[
  ('Protect the time','I rearranged my appointment and stayed for the whole presentation.','A broken microphone made the afternoon chaotic, but I was there.',5,'I showed up when it mattered.','The calendar became a promise I could point to.'),
  ('Be honest and arrange another evening','I explained the clash and made a specific plan for time together.','They were disappointed. We put our replacement evening on the calendar.',2,'I explained why I could not attend.','An honest compromise still needed follow-through.'),
  ('Promise to attend, then skip it','I said I would come and did not. The empty chair did the explaining.','My excuse arrived after the presentation. It did not erase the wait.',-8,'I broke a promise to be there.','The missed afternoon changed what my promises meant.')]),
 ('launch','🧳','A first place of their own',[35,95],['child'],'An adult child, {person.first}, is planning to leave home. They want help making a realistic budget, rather than a speech about how easy your youth was.',[
  ('Build the budget together','We included bills, food and an emergency cushion before looking at apartments.','The numbers ruled out the first apartment. A smaller place became a real option.',5,'We planned my move together.','The spreadsheet outlasted the excitement of the move.'),
  ('Offer advice and leave the choice to them','I shared what I knew and let them make the final call.','They chose differently from me. I kept the conversation open.',3,'My independence was respected.','Advice only helped while it left room for a decision.'),
  ('Dismiss the plan as a waste of time','I called the idea unrealistic without asking about their numbers.','My lecture ended the conversation before we had discussed a single bill.',-6,'My plans were dismissed.','The practical question became a question about respect.')]),
 ('care','🫖','The tasks nobody wrote down',[25,90],['mother','father','grandparent'],'An older relative, {person.first}, is tired of a routine that has become difficult. They ask for practical help, while wanting a say in what happens next.',[
  ('Agree on a small practical plan','We chose two tasks I could reliably help with and kept their preferences central.','The first arrangement was awkward. We adjusted it rather than taking over.',5,'We agreed on help I actually wanted.','Care became a routine, not a heroic afternoon.'),
  ('Ask who else can share the work','I asked what support already existed and offered to coordinate a conversation.','Someone felt overlooked, but the family finally named the work being done.',2,'We talked about sharing care.','Sharing the work meant also sharing the decisions.'),
  ('Avoid the conversation','I said I was busy and left without asking what was most difficult.','I answered a different question and hoped the request would disappear.',-5,'My request for help went unanswered.','The work still existed after the conversation ended.')]),
 ('sibling','⚖️','The family comparison',[16,90],['sibling','stepsibling'],'At a family gathering, someone compares your achievements with {person.first}’s. Your sibling is smiling too carefully.',[
  ('Challenge the comparison gently','I said our lives did not need a winner. My sibling visibly relaxed.','The joke did not land with everyone, but the comparison stopped.',5,'We refused to turn our lives into a contest.','That small defence became part of our shared history.'),
  ('Check in privately later','I let the public moment pass and asked privately how it felt.','They were guarded at first. I listened instead of giving another speech.',3,'Someone noticed how the comparison felt.','A private conversation carried what the party could not.'),
  ('Enjoy being the favourite','I laughed along and accepted the compliment at their expense.','I added my own joke. Their smile got smaller.',-7,'My sibling joined in the comparison.','Winning the comparison left a cost between us.')]),
 ('reconnect','📮','A friendship left on read',[18,95],['friend','best_friend','family_friend'],'You find an old message from {person.first}. Neither of you has properly caught up in a long time. There was no dramatic breakup; life simply filled the silence.',[
  ('Send a specific invitation','I suggested a day and a place, rather than another vague promise.','Our schedules did not match, but we agreed on a second date.',4,'We made an effort to reconnect.','A real invitation gave the friendship something to answer.'),
  ('Acknowledge the gap honestly','I said I missed them and had let too much time pass.','They had also been struggling to reach out. Neither of us needed a perfect excuse.',3,'We named the distance without blaming each other.','Naming the silence was the first piece of repair.'),
  ('Leave it unread again','I closed the message and told myself I would answer next week.','Another week became another month without a reply.',-4,'My message was left unanswered again.','Neglect did not need a dramatic farewell.')]),
 ('school','📚','Help without doing it for you',[10,17],['mother','father'],'A school assignment is harder than expected. {person.first} offers to help, but you have to decide whether that means learning together or handing over the work.',[
  ('Ask them to explain one difficult part','We worked through an example and I finished the rest myself.','It took longer than copying an answer. I understood why the answer worked.',4,'We learned something together.','The help became a skill I could use without them.'),
  ('Try alone, then ask for feedback','I brought a rough attempt instead of an empty page.','Their suggestions stung at first. Revising felt better than giving up.',2,'I asked for feedback on my own attempt.','Independence included knowing when to ask.'),
  ('Ask them to do the whole assignment','I handed over the work and submitted an answer I could not explain.','The teacher asked a follow-up question and my borrowed confidence vanished.',-2,'I avoided learning the difficult part.','The shortcut left a gap in what I knew.')]),
 ('ambition','🪜','A promotion and the people at home',[22,65],['partner','spouse'],'A possible promotion would mean longer hours. {person.first} asks what would change at home. You have not accepted anything yet.',[
  ('Discuss the trade-offs before applying','We named the hours, the money and the responsibilities someone would have to absorb.','We did not agree immediately. At least the costs were no longer invisible.',5,'We discussed ambition as a shared practical choice.','The conversation made hidden costs visible.'),
  ('Ask for a trial arrangement','I suggested a temporary plan with a date to review whether it worked.','The plan needed revisions before either of us felt comfortable.',3,'We agreed to revisit the arrangement.','A review date mattered as much as the initial agreement.'),
  ('Say they should simply support you','I treated their questions as disloyalty instead of practical concerns.','I talked about my future as if nobody else would be living in it.',-6,'My concerns about the new hours were dismissed.','Ambition became harder to celebrate together.')]),
 ('debt','🧾','A request that is also a boundary',[25,90],['sibling','child'],'An adult relative, {person.first}, asks for help dealing with a bill. They have not yet explained whether it is a one-off problem or part of a larger pattern.',[
  ('Review the bill and discuss realistic options','We looked at the actual amount and talked about what help I could afford.','The conversation was uncomfortable, but the problem became specific.',4,'We discussed the bill without pretending money was unlimited.','A clear boundary made practical help possible.'),
  ('Offer time and planning help instead of cash','I helped list the deadlines and options, while saying I could not pay it.','They wanted money, not a plan. I stayed honest about my limits.',1,'Help had limits, but they were explained.','Saying no to a payment did not have to mean saying no to a person.'),
  ('Make a vague promise you cannot keep','I said I would handle it without checking my own situation.','My reassurance lasted until they asked when the payment would arrive.',-6,'A promised solution never became a concrete plan.','The promise increased the uncertainty it was meant to relieve.')]),
 ('boundary','☎️','Work follows you home',[18,70],['child','partner','spouse'],'During time you set aside together, {person.first} notices you answering another non-urgent work message. They ask whether you are really available.',[
  ('Put the phone away and explain the boundary at work','I stopped answering and made my availability clear for the next day.','The habit was harder to break than I expected. Tonight, I stayed present.',5,'Time together finally had a boundary around it.','Availability became something I chose deliberately.'),
  ('Agree on a short window, then stop','I asked for ten minutes, finished the message and kept the limit.','The interruption still annoyed them. Keeping the time limit helped.',2,'The interruption had an honest limit.','A negotiated interruption still counted as an interruption.'),
  ('Call them unreasonable and keep typing','I defended every message and barely looked up.','They stopped trying to speak. The work message was not even urgent.',-7,'Work mattered more than the conversation in front of me.','The phone was small; the absence felt large.')]),
 ('heirloom','🪡','An object with an inconvenient story',[18,95],['mother','father','grandparent'],'{person.first} shows you an old family object and explains why they kept it. The story is more complicated than the polished version you heard as a child.',[
  ('Ask about the difficult parts as well','I listened to the story without insisting that every relative had been admirable.','Some details were uncertain. We kept uncertainty in the account.',5,'The family story was heard without being polished clean.','The object became a reminder to ask better questions.'),
  ('Record what they are comfortable sharing','I wrote down the details they agreed to share and marked what we did not know.','They changed their mind about one detail. I respected that boundary.',3,'A family story was recorded with care.','Recording a memory also meant recording its limits.'),
  ('Turn it into a flattering story immediately','I skipped the awkward details and repeated a simpler version.','My tidy account made them ask whether I had listened at all.',-4,'The difficult parts of the story were edited away.','A pleasing legend displaced an honest account.')]),
 ('distance','🚉','Keeping a friendship across distance',[18,85],['friend','best_friend'],'{person.first} is moving farther away. You both say you will keep in touch, but this time you could turn that phrase into a workable plan.',[
  ('Choose a simple recurring check-in','We chose a low-pressure routine and agreed missed calls could be rearranged.','The first call ran short. A routine mattered more than a perfect evening.',4,'We made a realistic plan to stay in touch.','Distance changed the form of the friendship.'),
  ('Leave room for occasional longer catch-ups','We agreed not to measure affection by daily messages.','Our messages were irregular, but we were honest about what we could manage.',2,'We accepted a slower rhythm for the friendship.','A slower rhythm could still be a real connection.'),
  ('Promise daily calls without checking your schedules','I promised a daily routine that neither calendar could support.','We both sounded enthusiastic. The first missed call arrived almost immediately.',-3,'An unrealistic promise made distance feel like failure.','The calendar could not carry what the promise claimed.')]),
 ('plans','🧭','The future is not a shared assumption',[18,65],['partner','spouse'],'You and {person.first} discover that you have been imagining different futures: where to live, how to spend your time, and what you want your household to become.',[
  ('Talk through the differences carefully','We separated the things we preferred from the things we could not compromise on.','One answer hurt. Hearing it now was better than building a life on a guess.',5,'We talked honestly about different futures.','Compatibility became a conversation rather than an assumption.'),
  ('Agree to revisit one decision at a time','We chose the nearest practical decision and set a date for the larger conversation.','The smaller discussion helped, but the bigger differences were still real.',2,'We agreed on a way to keep discussing our plans.','A process helped without pretending every question was solved.'),
  ('Assume they will eventually change their mind','I treated their future as a phase and my own as the final plan.','They asked whether their answer would ever count as an answer.',-7,'My future was treated as less real than theirs.','An unspoken assumption became a visible conflict.')]),
 ('honesty','🪞','Advice your grown child did not ask for',[35,100],['child'],'Your adult child, {person.first}, tells you about a difficult decision. Halfway through, you realise you are preparing a lecture instead of listening.',[
  ('Ask whether they want advice or a listener','They wanted to talk first. I let the story reach its ending.','They did ask for advice, once they knew I had heard the actual problem.',5,'My parent asked what kind of help I wanted.','Being useful began with listening.'),
  ('Share an experience without making it the answer','I offered one relevant mistake of my own and left the decision with them.','Our situations were different. I said so instead of forcing the comparison.',3,'Advice was offered without taking over my decision.','An honest mistake was more useful than a perfect-parent story.'),
  ('Explain exactly what they must do','I gave instructions before hearing the whole situation.','They stopped giving details. I called that agreement when it was withdrawal.',-6,'My decision became someone else’s lecture.','Less disagreement did not necessarily mean more trust.')]),
 ('repair','🧩','An apology without a receipt',[18,95],['sibling','friend','partner','spouse'],'You remember something hurtful you said to {person.first}. You would like the discomfort to disappear, but an apology cannot require immediate forgiveness.',[
  ('Name what you did and accept their response','I apologised for the specific thing I had done and did not argue with their reaction.','They needed time. I accepted that instead of asking them to comfort me.',5,'An apology left room for my own response.','Repair began without a demand for instant forgiveness.'),
  ('Ask to understand the harm before explaining yourself','I listened to how it had landed before saying what I had intended.','Their account differed from my memory. I did not use that as an escape.',3,'The harm was heard before the intention was defended.','Listening changed what I thought I was apologising for.'),
  ('Say sorry and demand that they move on','I offered an apology with a deadline attached.','My explanation became another argument about their reaction.',-7,'The apology demanded that I stop being hurt.','A rushed apology created another thing to repair.')]),
]

events=[]
for key,icon,title,ages,relations,text,branches in ARCS:
    root='chronicle.'+key
    role={'relation_any':relations}
    if key in ['launch','debt','honesty']: role['min_age']=18
    if key=='promise': role.update(min_age=5,max_age=17)
    if key=='care': role['min_age']=60
    event=dict(id=root,icon=icon,title=title,text=text,once=True,weight=.55,
      themes=['family','continuity',key],conditions=dict(age=ages,life=['human','royal','vampire','witch','super','revenant']),roles={'person':role},choices=[])
    if key in ['ambition','boundary']: event['conditions']['employed']=True
    for branch,(label,good,mixed,bond,memory,echo) in enumerate(branches):
        follow=root+'.'+str(branch+1)
        outs=[]
        for result,prose in enumerate([good,mixed]):
            outs.append(dict(text=prose,weight=1,effects={'happiness':2 if bond>0 else -2,'stress':-1 if bond>0 else 3},
              relationship={'person':bond if result==0 else int(bond*.6)},bond={'trust':bond},bond_role='person',
              family_memory={'role':'person','memory':memory,'tone':'warm' if bond>0 else 'strained'},
              schedule={'event':follow,'years':[1,3]}))
        event['choices'].append(dict(label=label,outcomes=outs))
        # Retrospective wording remains truthful if the original person died.
        choices=[]
        for response,delta,closing in [
          ('Reflect on what the choice changed',2,'I understood more clearly what my decision had meant, and what I wanted to carry forward.'),
          ('Write down an honest account',1,'I wrote down what happened, including the part that made me uncomfortable.'),
          ('Avoid thinking about it',-2,'I kept the memory at a distance. Avoiding it did not change what had happened.')]:
            choices.append(dict(label=response,outcomes=[
              dict(text=closing,weight=1,effects={'happiness':delta,'stress':-delta},family_memory={'role':'person','memory':'Looking back: '+memory,'tone':'reflective'}),
              dict(text='The memory was complicated. I could not reduce it to a neat lesson.',weight=1,effects={'smarts':1,'stress':1},family_memory={'role':'person','memory':'A complicated memory: '+memory,'tone':'reflective'})]))
        events.append(dict(id=follow,icon=icon,title='What stayed: '+title.lower(),text='Looking back on your history with {person.first}: '+echo,
          followup_only=True,required=True,themes=['family','continuity',key],conditions={'age':[0,150],'life':event['conditions']['life'],'prison_any':True},
          roles={'person':{'bound':True,'allow_dead':True}},choices=choices))
    events.append(event)

assert len(events)==56
(ROOT/'data/events/family_chronicle.json').write_text(json.dumps(events,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Authored 14 arcs, 56 scenes, 168 choices and 336 outcome variants.')
