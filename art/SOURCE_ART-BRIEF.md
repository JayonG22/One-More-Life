# ONE MORE LIFE — Art brief (what to make)

Everything the game could use as real art instead of stock emoji, including new variations the game does not have yet. Each row says what it is, how many, and where it shows. "Have" means the game already needs it; "New" means it needs new code to use it (small: a lookup from an id to an image).

**Format for everything:** square PNG or SVG, 256×256, transparent background, readable at 24 px, same line weight and palette across the set. Characters and portraits: 512×512. Frames and banners: 9-slice where noted. Name files by id (given in brackets).

---

## 1. Brand (do first)
| Asset | Count | Notes |
|---|---|---|
| App icon [`icon`] | 1 master + 16/32/48/64/128/256 | Windows .ico and PNG |
| Title mark and logo lockup | 2 | "ONE MORE LIFE" wordmark, plus the emblem alone |
| Mode emblems | 3 | Human, Pets Life, Prison Life (shown on the mode picker) |
| Share-card frame | 3 | Human, Pets, Prison; plus a "Modified life" stamp |
| Loading / empty-state spot art | 6 | empty log, empty inventory, empty graveyard, empty attic, no pets, no applications |

## 2. Avatar and people
The player portrait is one picture built from parts that fit together. If you draw these as a layered kit (shared head and shoulder anchors), any combination works. If you prefer whole portraits, the minimum set is the grid at the end.

### 2a. Base bodies [`body_<stage>_<build>`]
- **Age stages (6):** baby (0–2), child (3–12), teen (13–17), young adult (18–39), adult (40–64), elder (65+)
- **Builds (3):** slim, average, broad. Figure is separate from gender, so each build is drawn neutral and tinted per skin tone.
- **Skin tones (6):** classic yellow, light, medium-light, medium, medium-dark, dark. A tint is fine if the line art holds.

### 2b. Faces and expressions
- **Face shapes (4):** round, oval, square, heart
- **Expressions (8):** neutral, happy, sad, angry, worried, in love, sick, proud. Shown on the portrait when the life state changes (illness, grief, success).
- **Eyes (6), brows (4), mouths (6), noses (4):** plain variety so lives look different.
- **Aging marks (4):** freckles, laugh lines, deep wrinkles, scar (three scar variants are earnable from events)

### 2c. Hair [`hair_<style>_<colour>`]
- **Styles (20):** bald, buzz, short, side part, curls, afro, long straight, long wavy, ponytail, bun, braids, cornrows, locs, mohawk, bob, pixie, spikes, undercut, top knot, headwrap
- **Colours (12):** black, dark brown, brown, auburn, blond, ginger, grey, white, pink, blue, green, purple. The last four are premium dyes.
- **Facial hair (6):** stubble, goatee, full beard, moustache, handlebar, chinstrap

### 2d. Headwear (vanity items, 24)
Cap, beanie, sun hat, bucket hat, cowboy hat, top hat, bowler, beret, flat cap, graduation cap, hard hat, helmet, crown, tiara, turban, headscarf, hijab, kippah, headband, bandana, party hat, santa hat, pirate hat, wizard hat.

### 2e. Eyewear (10)
Round glasses, square glasses, cat-eye, shades, aviators, monocle, goggles, 3D glasses, eye patch, heart glasses.

### 2f. Clothes [`top_<style>`]
- **Tops (16):** t-shirt, hoodie, shirt, blouse, jumper, suit jacket, tuxedo, dress, uniform, lab coat, apron, hi-vis vest, leather jacket, tracksuit, robe, prison jumpsuit
- **Work uniforms, one per major career family (14):** doctor, nurse, police, firefighter, military (army / navy / air force), chef, pilot, judge, teacher, scientist, athlete, astronaut, mechanic, office
- **Life-path outfits (10):** royal robes, vampire cape, witch robes, superhero costume, pirate coat, spacesuit, time-traveller coat, prisoner orange, guard uniform, undead rags
- **Colours:** the clothing is drawn in a single neutral and tinted with 12 colours, so one drawing gives 12 variants.

### 2g. Accessories and extras (cosmetic, 24)
Headphones, earrings, nose ring, necklace, chain, scarf, tie, bow tie, medal, badge, flower, ribbon, gem, star, tattoo sleeve, face tattoo, face paint, mask, bandage, glow eyes, fangs, halo, devil horns, angel wings.

### 2h. Backdrops and frames
- **Backdrops (16):** 8 plain colours, plus 8 scenes (city, beach, forest, space, stage, prison yard, castle, home)
- **Portrait frames (12):** plain circle, rounded square, bronze / silver / gold / platinum / diamond (matching achievement tiers), royal, vampire, witch, superhero, celebrity (earnable)

### 2i. Whole-portrait fallback (minimum viable)
6 stages × 3 genders × 6 tones = 108 portraits, plus 14 "Look" characters (beard, turban, headscarf, cap, builder, officer, detective, royal ×2, wizard, cowboy, hero, ninja, vampire, elf) × 6 tones = 84.

### 2j. People who are not the player [NPCs]
Same kit, plus: baby, toddler, school kid, and silhouette versions for strangers and "unknown caller". Relationship states shown as a small badge: friend, best friend, partner, spouse, ex, rival, enemy, estranged, deceased, in prison.

## 3. Animals
**Species (12):** dog, cat, rabbit, parrot, horse, hamster, guinea pig, goldfish, turtle, ferret, lizard, snake.
- **Life stages (4):** baby, young, adult, senior
- **Coats per species (6 each):** e.g. dog: black, brown, white, spotted, tan, brindle. Cat: black, grey, orange, tabby, calico, white. Rest: 3–6 natural variants.
- **Moods (6):** happy, sleepy, hungry, sick, scared, bonded
- **Cosmetics (new, 16):** collar (plain, spiked, bell, gem), bandana, bow, cape, sweater, hat, saddle, show ribbon, cone, glasses, bed, bowl, toy, leash, harness, tag
- **Origins (7):** a loving house, farm litter, mill, shelter, the street, working line, show line (one picture each, for the start screen)
- **Pet minigames (5):** Stalk and Pounce, Scent Work, Sneak, Agility, Herding. A board background and 3–4 sprites each.

## 4. Star Shop and items
**Star items (18, each also in 3 rarity frames: common, rare, legendary):** Do-Over, first-aid kit, spa voucher, study guide, elixir of youth, fine wine, spare hours, cash envelope, favour card, pardon letter, golden ticket, glowing reference, résumé polish, cure-all tonic, pet care bundle, travel pass, lucky charm, makeover.
- **New item ideas, since variety is open (12):** extra-life charm, name-change token, time-skip candle, lottery ticket, first-class upgrade, lawyer on retainer, apology card, second wind, mentor introduction, house blessing, fortune cookie, mystery box.
- **Shop UI:** shelf background, "sold out" stamp, "new stock" ribbon, star currency icon (small, medium, large), rotation timer clock.

## 5. Shopping in the game world
**Store fronts (12):** jeweler, alley dealer, electronics, sporting goods, music shop, clothing, novelty, bookstore, motorcycle dealer, boat dealer, aircraft broker, art and collectibles.
**Brand houses (6):** each is an invented maker with a logo, so six logos: Marrow & Lint, Harrowgate, Voss Aurel, Castellane Frères, NOCTURNE//, Aldridge & Wray. Each also needs a small tag for "numbered edition", "archive reissue".
**Goods (illustration per category, 8–12 pieces each):** rings and watches; phones, computers, cameras, consoles; bikes, gym gear, rods, bows; guitar, piano, drums, DJ decks; suits, designer outfits; lucky charms, gadgets; books; scooters and motorbikes; kayaks to yachts; ultralights to jets; art and antiques.
**Vehicles (12):** bicycle, used hatchback, new sedan, sports car, SUV, van, truck, motorbike, scooter, boat, yacht, small plane, jet. Plus bus, train and walking icons for transit.
**Homes (8):** family home, rented flat, shared flat, student room, house, mansion, penthouse, mobile home, plus a prison cell and a kennel / basket for pets.

## 6. Icons by area
### 6a. UI and stats (have)
Happiness, health, smarts, looks, stress; money, net worth, fame, heat, time points, stars; age; year; settings, save, load, share, help; tabs: Activities, People, Work, Assets, More; filter chips: All, Money, People, Work, Health.

### 6b. Achievements (393, have)
Each needs an icon, and each tier gets a frame: bronze 95, silver 139, gold 133, platinum 26 (legendary and diamond frames are defined but unused so far). Categories to colour-code (15): life 64, career 49, prison 45, wealth 30, pets 28, paths 25, grit 24, family 23, legacy 23, minigames 20, crime 17, fame 13, empires 13, outdoors 10, secret 9.
The achievement pop-up also uses: a light-ray burst, a trophy header, and a card background per tier (6).

### 6c. Careers and education (have)
- **Jobs (56):** one icon each (part-time jobs, trades, office, medical, legal, public service, military, pilot, and so on)
- **Majors (25)**, **traits (12)**, **licences (6 families × 3)**, **challenges (13)**, **missions (66)**, **interviews (8)**
- **Career ladders (new):** a rank pip set (stripes, bars, stars) for 5 ladders: military, police, corporate, medical, academic

### 6d. Countries and places (have)
14 flags (US, UK, Germany, France, Japan, Brazil, Mexico, Philippines, Nigeria, India, South Korea, Egypt, Canada, Australia) as an original stylised set, plus a skyline per country (new, 14) for the New Life screen.

### 6e. Events (about 400 distinct icons, have)
Group by theme and draw one set that many events reuse. About 150 icons cover most: family, birth, school, exams, bullying, romance, wedding, divorce, illness, hospital, accident, crime, court, prison, money, bills, debt, inheritance, lottery, housing, moving, travel, weather, disaster, holiday, party, hobby, sport, music, fame, scandal, work, promotion, firing, strike, business, politics, war, spirit and supernatural, space, time travel, pets.

### 6f. Life paths (12, have)
Human, royal, vampire, witch, gifted (superhero), undead, pirate, space colonist, time traveller, pets, prisoner, guard. Each: an emblem, a colour theme, and a banner. The 8 superpowers each need an icon: strength, speed, flight, telekinesis, invisibility, mind reading, fire, healing.

### 6g. Endings and legacy
- **Endings (50):** a small illustration per ending for the tombstone and the share card
- **Ribbons (about 20):** big family, tycoon, scholar, at peace, ordinary, fertile, lazy, and so on
- **Tombstone styles (6):** plain, stone cross, angel, pet marker, prison grave, royal tomb
- **Heirlooms (the Attic, new):** a picture for each of about 30 heirloom types (ring, watch, letter, photo, medal, instrument, tool, recipe book, key, necklace, etc.), 4 quality frames, a mantelpiece, and shelves.

## 7. Minigames (39)
Each needs an icon, a board background (1000×540), and the sprites listed.

**Career and life (22):** Licence Theory Test, Audition, Live Set, Clutch Moment, Debate, Safecracker, Pickpocket, Docking, Runway, Fight Night, On Set, Infiltration, Potion Brewing, Blackjack, Prison Break, Break-in, Minefield, Fishing, Evidence Board, Negotiation, Road Test, Memory Test, Operating Room.
**Casino (8):**
- Slots: 7 reel symbols (cherry, lemon, bell, star, diamond, seven, gift), machine frame, lever
- Roulette: wheel, ball, felt table, 10 bet chips
- The Races: 6 horses with jockey colours, track, finish line
- Rocket: rocket, flames, explosion, multiplier backdrop
- Plinko: ball, pegs, 9 buckets
- Scratch card: card, 6 symbols, coin
- Lucky Wheel: wheel, flapper
- High or Low: card faces (52, or 13 values × 4 suits), back
**Pets (5)** and **prison (3: Parole Board, Cell Search, Talk Him Down)**, as in section 3.
**Shared:** grade stars (5), result banners (Perfect, Great, Solid, Rough, Flop), coin, chip, cash stack icons.

## 8. Effects and particles
Sparks, hearts, coins, confetti (4 colours), tears, smoke, stars, money rain, blood drop (optional, off by default), sleep "Z", heart-break, ghost, fire, snow, rain. 128 px sprites or 8-frame sheets.

## 9. Backdrops and themes
Mode backdrops (Pets, Prison, Guard): 3 wide scenes. Theme textures for the 9 colour themes (dark, light, celebrity, vampire, undead, villain, superhero, royal, witch): a subtle pattern tile and a header image each.

## 10. Totals
| Group | Rough count |
|---|---|
| Brand, share cards, empty states | about 25 |
| Avatar kit (bodies, faces, hair, headwear, eyewear, clothes, extras, backdrops, frames) | about 330 pieces |
| Animals (12 species × stages × coats, plus cosmetics) | about 400 |
| Star items and shop | about 60 |
| Shopping world (stores, brands, goods, vehicles, homes) | about 140 |
| UI, stats, careers, countries, life paths | about 250 |
| Achievements and tier frames | about 400 |
| Events (shared set) | about 150 |
| Endings, ribbons, tombstones, heirlooms | about 110 |
| Minigame boards and sprites | about 200 |
| Effects and backdrops | about 40 |

**If time is short, in this order:** brand → avatar kit (2a–2f) → animals → star items → achievements → event icons → everything else. Anything not drawn keeps its emoji, so the game stays whole while art arrives.
