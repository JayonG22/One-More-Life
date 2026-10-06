"""Author adult-only narrative arcs with delayed consequences; no graphic scenes."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[2]
EVENTS = []
def outcome(text, effects, **extra):
    if isinstance(extra.get('jail'), dict):
        sentence = extra['jail']
        extra['crime'] = sentence['crime']
        extra['jail'] = sentence['years']
    return dict(text=text, effects=effects, weight=1, **extra)
def arc(key, icon, title, text, choices, echo_title, echo_text, echo_choices, conditions=None, roles=None):
    cond = dict(age=[18, 100], life=['human','royal','vampire','witch','super','revenant'])
    cond.update(conditions or {})
    event = dict(id='mature.'+key, icon=icon, title=title, text=text, mature=True,
                 once=True, themes=['mature',key], weight=0.7, conditions=cond, choices=[])
    if roles: event['roles']=roles
    for label, outs in choices:
        for o in outs:
            o['schedule'] = dict(event='mature.'+key+'.echo', years=[1,3])
            o.setdefault('flags',[]).append('mature_'+key)
        event['choices'].append(dict(label=label,outcomes=outs))
    echo = dict(id='mature.'+key+'.echo', icon=icon, title=echo_title, text=echo_text,
                mature=True, followup_only=True, required=True, themes=['mature',key],
                conditions=dict(age=[18,150], life=cond['life'], flags=['mature_'+key], prison_any=True),
                choices=[dict(label=label,outcomes=outs) for label,outs in echo_choices])
    EVENTS.extend([event,echo])

arc('intimacy','🌙','The conversation before the door closes',
    'You and {partner.first}, both adults, have a quiet evening alone. Desire is easy to name; boundaries and expectations take more courage.',[
    ('Talk honestly about what you both want',[outcome('We agreed on what felt right. The night stayed private, and we felt closer.',{'happiness':5,'stress':-3},relationship={'partner':8}),outcome('We wanted different things. We stopped, talked, and kept each other’s trust.',{'happiness':1},relationship={'partner':5})]),
    ('Take things slowly',[outcome('We shared an unhurried evening without pushing further. Nobody had to prove anything.',{'happiness':3,'stress':-2},relationship={'partner':4}),outcome('It was a little awkward, but we laughed and agreed to talk again.',{'happiness':2},relationship={'partner':2})]),
    ('Say you would rather stop tonight',[outcome('My boundary was respected. The evening ended gently.',{'stress':-4},relationship={'partner':3}),outcome('Disappointment was real, but stopping was still the right choice for me.',{'happiness':-1,'stress':-1},relationship={'partner':1})])],
    'What we remember about that night','The private evening is long past. What remains is how you made room for each other’s boundaries.',[
    ('Ask how they felt',[outcome('We found words for something we had both carried quietly.',{'happiness':3,'stress':-2}),outcome('The conversation was difficult, but it made the next one easier.',{'stress':1,'smarts':1})]),
    ('Make time for connection again',[outcome('We protected an evening from the rest of our responsibilities.',{'happiness':4,'stress':-2}),outcome('Life interrupted our plans. We made another date instead of blaming each other.',{'happiness':1})]),
    ('Reconsider what you need',[outcome('I understood my own boundaries more clearly.',{'stress':-3,'smarts':1}),outcome('I realised a conversation I had avoided was still waiting.',{'stress':3})])],
    conditions={'has_partner':True},roles={'partner':{'relation_any':['partner','spouse'],'min_age':18}})

arc('affair','💔','A message you should not answer',
    'An adult acquaintance sends a flirtatious invitation. You have a partner. There is no misunderstanding about what is being offered.',[
    ('Decline and keep the boundary',[outcome('I declined. The invitation stopped there.',{'karma':3,'stress':-2}),outcome('They called me boring. I could live with that.',{'karma':3,'happiness':-1})]),
    ('Talk to your partner before doing anything',[outcome('We had a hard conversation about what was missing between us.',{'stress':4,'karma':2}),outcome('Honesty exposed problems we could no longer pretend away.',{'happiness':-3,'stress':5})]),
    ('Begin a secret consensual affair',[outcome('The thrill was real. So was the lie I carried home.',{'happiness':6,'stress':12,'karma':-10},flags=['mature_affair_betrayal']),outcome('We crossed the boundary, and my partner learned about it soon after.',{'happiness':-8,'stress':18,'karma':-12},flags=['mature_affair_betrayal'])])],
    'The invitation leaves a mark','That invitation changed how you think about loyalty. The consequences did not end with deleting a message.',[
    ('Face the conversation you owe',[outcome('I took responsibility for my choices instead of arguing about how they looked.',{'stress':5,'karma':4}),outcome('There was no quick forgiveness. I accepted that repair takes time.',{'happiness':-4,'stress':5,'karma':3})]),
    ('Invest in the relationship you want',[outcome('Counselling and time helped me become more honest.',{'money':-300,'stress':-4,'karma':2}),outcome('Money did not solve the tension, but the work gave us a place to start.',{'money':-300,'stress':1})]),
    ('Keep avoiding the subject',[outcome('Silence made every disagreement feel larger.',{'stress':8,'happiness':-4}),outcome('The old uncertainty followed me into a new argument.',{'stress':6,'karma':-2})])],conditions={'has_partner':True})

arc('health','🩺','A message after a private night',
    'Someone you were intimate with as an adult says they may have a sexually transmitted infection. They ask you to get tested. Nothing about the message is a diagnosis.',[
    ('Arrange a confidential clinical appointment',[outcome('I got professional advice and a plan for testing. Uncertainty was easier with help.',{'money':-120,'stress':-2,'health':2}),outcome('The appointment did not answer everything immediately. I followed the clinician’s plan.',{'money':-120,'stress':3,'health':1})]),
    ('Tell current adult partners and seek advice',[outcome('The conversation was uncomfortable, but we could make informed choices together.',{'stress':4,'karma':4,'health':1}),outcome('Someone was frightened. We chose facts and clinical advice over blame.',{'stress':6,'karma':3})]),
    ('Ignore the message',[outcome('I avoided an awkward appointment and kept worrying.',{'stress':9,'karma':-3}),outcome('Delaying care made the uncertainty harder to manage.',{'health':-4,'stress':10,'karma':-4})])],
    'Care is a continuing choice','The private health concern is no longer new. Follow-through and honest communication still matter.',[
    ('Follow up with a clinician',[outcome('I completed the recommended follow-up and felt steadier.',{'money':-100,'health':3,'stress':-5}),outcome('I needed another visit. Having a plan helped.',{'money':-100,'health':1,'stress':-2})]),
    ('Check in with the people affected',[outcome('We spoke respectfully about boundaries and care.',{'karma':3,'stress':-3}),outcome('The conversation was difficult, but nobody was left guessing.',{'karma':2,'stress':2})]),
    ('Keep putting it off',[outcome('The worry stayed with me longer than I expected.',{'stress':7}),outcome('I eventually had to face the concern I had avoided.',{'stress':8,'health':-2})])])

arc('murder_offer','🕯️','A price on someone’s life',
    'A criminal contact offers money if you help arrange the murder of an adult rival. They speak about a person as if they were a business expense.',[
    ('Refuse and leave',[outcome('I walked away. The contact stopped calling.',{'stress':5,'karma':5}),outcome('Refusing cost me the contact’s trust. Keeping it would have cost more.',{'stress':8,'karma':5})]),
    ('Seek legal help and report the threat',[outcome('I gave a statement with legal support. An investigation began.',{'money':-1000,'stress':10,'karma':8},flags=['mature_reported_threat']),outcome('Reporting brought difficult questions, but the intended victim received a warning.',{'money':-1000,'stress':12,'karma':8},flags=['mature_reported_threat'])]),
    ('Agree to participate',[outcome('A person died because of the decision I made. Investigators traced my involvement; I was convicted.',{'money':-15000,'stress':30,'karma':-50},jail={'years':[18,25],'crime':'conspiracy to murder'},flags=['mature_homicide_conviction']),outcome('The plan was intercepted. I was convicted for my role in the attempted murder.',{'money':-8000,'stress':25,'karma':-35},jail={'years':[10,18],'crime':'conspiracy to murder'},flags=['mature_homicide_conviction'])])],
    'The offer that will not stay in the past','The murder plot changed lives. Whether you refused, reported it, or participated, its shadow remains.',[
    ('Cooperate with the continuing inquiry',[outcome('I gave a truthful account. It did not erase what happened.',{'stress':8,'karma':5}),outcome('The interview reopened old fear. I answered with legal support.',{'money':-500,'stress':10,'karma':3})]),
    ('Seek support and face your responsibility',[outcome('I began the slow work of living honestly with my choices.',{'stress':-5,'karma':3}),outcome('Support helped me function. It did not turn the past into something harmless.',{'stress':-2,'happiness':-3})]),
    ('Pretend it has nothing to do with you',[outcome('Denial made it harder to speak honestly to anyone.',{'stress':12,'karma':-5}),outcome('A new question pulled me straight back into the memory.',{'stress':10,'happiness':-5})])])

arc('witness','⚖️','What you saw after midnight',
    'You witness the aftermath of a fatal attack on an adult outside a club. A familiar adult asks you to say they were somewhere else.',[
    ('Give a truthful witness statement',[outcome('I described only what I knew. My statement became part of the investigation.',{'stress':8,'karma':8}),outcome('I corrected a detail rather than guessing. The investigators needed honesty, not a perfect story.',{'stress':10,'karma':7})]),
    ('Get a lawyer before making a statement',[outcome('Legal advice helped me separate facts from fear.',{'money':-700,'stress':5,'smarts':1}),outcome('The waiting was miserable, but I gave a careful statement with support.',{'money':-700,'stress':8,'karma':3})]),
    ('Give the false alibi',[outcome('My lie was contradicted by other evidence. I was convicted of obstructing the investigation.',{'stress':18,'karma':-20},jail={'years':[2,5],'crime':'obstruction of justice'}),outcome('The lie held for now. I knew an innocent person might bear the cost.',{'stress':15,'karma':-25},flags=['mature_false_alibi'])])],
    'The statement is read aloud','The fatal attack has become a court case. Someone reads the statement you gave, and your choices return in public.',[
    ('Clarify the truth with legal support',[outcome('I corrected the record. It was painful and necessary.',{'money':-500,'stress':8,'karma':5}),outcome('The court questioned every change. I kept to what I actually knew.',{'stress':10,'karma':4})]),
    ('Support the people harmed',[outcome('I offered practical help without making their grief about me.',{'money':-200,'karma':4,'happiness':-2}),outcome('They wanted distance. I respected it.',{'karma':2,'happiness':-3})]),
    ('Avoid every reminder',[outcome('The case stayed on the news. Avoidance was not an ending.',{'stress':8}),outcome('I could stop reading, but I could not stop remembering.',{'stress':10,'happiness':-4})])])

arc('blackmail','📱','Pay up, or everyone finds out',
    'Someone threatens to publish private, consensual adult messages unless you pay. Their demand is an act of exploitation, not a debt you owe.',[
    ('Seek support and report the threat',[outcome('I asked for help and preserved what I could safely share with investigators.',{'stress':6,'karma':3}),outcome('The process was slow. Having someone on my side made it bearable.',{'stress':8,'happiness':1})]),
    ('Tell the people who could be affected',[outcome('A painful conversation took some power away from the threat.',{'stress':10,'karma':4}),outcome('Not everyone reacted kindly. I still had support from someone I trusted.',{'stress':12,'happiness':-3})]),
    ('Pay the demand',[outcome('I paid $2,000. The demand returned with a larger number.',{'money':-2000,'stress':12},flags=['mature_blackmail_paid']),outcome('The messages stopped for now. I had bought uncertainty, not safety.',{'money':-2000,'stress':8},flags=['mature_blackmail_paid'])])],
    'The threat comes back','A reminder of the extortion arrives. You have another chance to choose support over isolation.',[
    ('Ask for professional help',[outcome('I made a supported plan instead of answering alone.',{'money':-300,'stress':-4}),outcome('The problem was not instantly solved, but I had a clear next step.',{'money':-300,'stress':-2})]),
    ('Lean on someone you trust',[outcome('I was believed. That mattered more than a clever reply.',{'happiness':3,'stress':-5}),outcome('Talking was hard. Keeping the secret had been harder.',{'stress':-3})]),
    ('Keep dealing with it alone',[outcome('Every notification made me flinch.',{'stress':9,'happiness':-3}),outcome('I spent another year arranging my life around someone else’s threat.',{'stress':10,'happiness':-4})])])

arc('corruption','💼','An envelope without a receipt',
    'A supplier offers a private payment if you steer a contract their way. They call it appreciation. The contract team calls it a conflict of interest.',[
    ('Refuse and disclose the approach',[outcome('I reported the offer. The review delayed the project but protected the process.',{'job_perf':3,'stress':5,'karma':5}),outcome('Someone complained that I made trouble. I kept a clear record of my decision.',{'job_perf':-1,'stress':6,'karma':5})]),
    ('Withdraw from the decision',[outcome('I handed the decision to an independent colleague.',{'job_perf':1,'karma':3}),outcome('The supplier tried again elsewhere. My withdrawal did not end the concern.',{'stress':4,'karma':2})]),
    ('Accept the private payment',[outcome('The $5,000 felt easy until the audit began.',{'money':5000,'stress':12,'karma':-15},flags=['mature_bribe_accepted']),outcome('The offer was part of an investigation. I was convicted of bribery.',{'money':-4000,'job_perf':-20,'stress':18,'karma':-15},jail={'years':[1,3],'crime':'bribery'},flags=['mature_bribe_accepted'])])],
    'The audit asks one more question','The contract is being reviewed. The question is no longer whether the project looked successful, but who benefited.',[
    ('Cooperate truthfully',[outcome('I answered directly and accepted scrutiny.',{'stress':6,'karma':4}),outcome('Cooperation exposed a decision I regretted. I stopped making excuses.',{'stress':9,'karma':3})]),
    ('Get independent legal advice',[outcome('Advice helped me respond carefully and honestly.',{'money':-700,'stress':-2}),outcome('There was no painless route through the review.',{'money':-700,'stress':4})]),
    ('Blame a colleague',[outcome('The accusation damaged my credibility when the records contradicted it.',{'job_perf':-8,'stress':10,'karma':-8}),outcome('I kept my position for now, but people stopped trusting me.',{'job_perf':-5,'happiness':-4,'karma':-10})])],conditions={'employed':True})

arc('open_relationship','💬','Different rules, honest answers',
    'Your adult partner asks whether a consensually non-monogamous relationship could work for you both. An honest no is as valid as an honest yes.',[
    ('Discuss boundaries and decide together',[outcome('We agreed on rules, check-ins and the freedom to change our minds.',{'happiness':3,'stress':2},relationship={'partner':5}),outcome('The discussion showed that we needed different things. We chose not to rush.',{'stress':4},relationship={'partner':2})]),
    ('Say you want monogamy',[outcome('I stated what I needed. My partner respected the answer.',{'stress':-2},relationship={'partner':4}),outcome('Our needs differed. We had a difficult but honest conversation.',{'happiness':-3,'stress':5},relationship={'partner':-2})]),
    ('Ask for time to think',[outcome('We paused the decision and talked without pressure.',{'stress':-1},relationship={'partner':3}),outcome('Uncertainty was uncomfortable, but I refused to promise what I did not mean.',{'stress':3},relationship={'partner':1})])],
    'Checking the agreement','Whatever relationship rules you chose, they only work when everyone can speak freely about them.',[
    ('Check whether the agreement still works',[outcome('We adjusted expectations before resentment grew.',{'stress':-3,'happiness':2}),outcome('A boundary had changed. We took it seriously.',{'stress':3,'karma':2})]),
    ('Name an uncomfortable feeling',[outcome('Naming jealousy made it easier to discuss without accusation.',{'stress':-2,'smarts':1}),outcome('There was no easy answer, but the feeling was heard.',{'stress':2,'happiness':1})]),
    ('Pretend you are fine',[outcome('Resentment seeped into unrelated arguments.',{'stress':7,'happiness':-3}),outcome('I realised silence had become its own decision.',{'stress':5,'happiness':-2})])],conditions={'has_partner':True},roles={'partner':{'relation_any':['partner','spouse'],'min_age':18}})

arc('desperation','🧾','A bill with no good answer',
    'A friend needs urgent help with a debt. A fixer offers to erase it if you help conceal money from an illegal operation.',[
    ('Look for lawful support',[outcome('A slow payment plan gave my friend room to breathe.',{'money':-300,'stress':4,'karma':4}),outcome('There was no immediate rescue. I helped with the practical work anyway.',{'money':-300,'stress':7,'karma':3})]),
    ('Refuse the scheme but stay beside your friend',[outcome('I could not fix the debt, but I did not abandon them.',{'happiness':1,'karma':3}),outcome('They were angry. Later, they understood why I had refused.',{'happiness':-2,'stress':3,'karma':3})]),
    ('Take the fixer’s deal',[outcome('The debt disappeared. A new obligation to the fixer took its place.',{'money':2500,'stress':14,'karma':-12},flags=['mature_fixer_debt']),outcome('The transaction was investigated. I was convicted of money laundering.',{'money':-3000,'stress':18,'karma':-15},jail={'years':[2,4],'crime':'money laundering'},flags=['mature_fixer_debt'])])],
    'The price of the favour','Your friend’s crisis changed the limits you thought you had. The favour still has a price, even if the bill looks different now.',[
    ('Find a lawful way forward',[outcome('I began unpicking obligations with professional help.',{'money':-400,'stress':-3,'karma':3}),outcome('The route was slow, but it stopped adding new lies.',{'money':-400,'stress':1,'karma':3})]),
    ('Talk honestly with your friend',[outcome('We stopped treating the problem as a secret test of loyalty.',{'stress':-3,'happiness':2}),outcome('Honesty changed the friendship. It was overdue.',{'stress':3,'karma':2})]),
    ('Keep accepting the obligations',[outcome('Every favour made the next refusal harder.',{'stress':10,'karma':-5}),outcome('I had become useful to people who did not care what it cost me.',{'stress':12,'happiness':-4,'karma':-5})])])

arc('work_boundary','🚪','Opportunity with a condition attached',
    'A senior colleague implies an adult promotion opportunity depends on private sexual attention. This is pressure from someone with power, not a genuine choice of equal partners.',[
    ('Refuse and seek independent support',[outcome('I refused and spoke to an independent adviser. The process was stressful, but I was not alone.',{'stress':8,'karma':4}),outcome('Refusing made work awkward. Support helped me plan the next step.',{'stress':10,'job_perf':-2,'karma':4})]),
    ('Report the conduct',[outcome('An inquiry began. I was asked difficult questions with support available.',{'stress':12,'karma':6}),outcome('The organisation handled it badly. I looked for advice beyond the workplace.',{'stress':16,'happiness':-4,'karma':5})]),
    ('Seek another role and protect your boundaries',[outcome('I chose distance from the pressure and began applying elsewhere.',{'stress':5,'job_perf':-1}),outcome('Leaving the opportunity hurt. Keeping my boundaries mattered more.',{'happiness':-3,'stress':4,'karma':3})])],
    'What a safe workplace would mean','The pressure at work made you reconsider who gets to set the conditions of opportunity.',[
    ('Follow up with independent support',[outcome('I found people who took the concern seriously.',{'stress':-4,'happiness':2}),outcome('Progress was slow. I kept control of what I chose to share.',{'stress':-1})]),
    ('Support someone facing similar pressure',[outcome('I listened without telling them what they had to do.',{'karma':4,'happiness':2}),outcome('I helped them find independent advice and respected their choices.',{'karma':3,'stress':1})]),
    ('Focus on rebuilding your own life',[outcome('A healthier routine gave me some room back.',{'stress':-5,'health':2}),outcome('Recovery was uneven, but I could make choices for myself again.',{'stress':-2,'happiness':1})])],conditions={'employed':True})

(ROOT/'data/events/mature.json').write_text(json.dumps(EVENTS,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(f'Mature content: {len(EVENTS)} events, {sum(len(e["choices"]) for e in EVENTS)} choices.')
