> Design reference, not a list of delivered custom artwork. Counts reflect
> the original inventory and may need reconciliation with the current build.
> See the [art index](README.md).

# Art and icon list — what needs design

Everything the game currently shows with a stock emoji, plus the few things drawn in code. A full machine-readable list of every emoji with where it is used is in `ASSET-EMOJI-INVENTORY.csv` (808 distinct emoji, sorted by how often they appear).

**How icons are wired:** most are plain text in data files (`"icon": "🏠"`) or GDScript. If you replace emoji with images, we add one lookup (icon id → PNG/SVG) and the 574 `icon` fields keep working; nothing else in the game needs to change. Suggest square PNG/SVG at 256×256 (displayed 24–90 px), transparent background, readable at 24 px.

## 1. Brand and window (a handful, highest priority)
| Asset | Notes |
| --- | --- |
| App icon (`icon.png`, `icon.ico`) | 256, 128, 64, 48, 32, 16 px |
| Title screen mark / crown | now the 👑 emoji at 64 px |
| Share-card header and frame | the life card image players share |
| Tombstone / graveyard marker | per ending style |

## 2. People (the part you asked about)
| Asset | Count | Notes |
| --- | --- | --- |
| Player portrait | 1 per age stage × gender × skin tone | now: baby, child, adult, elder × man/woman/person × 6 tones (the emoji's own set). Plus the "Look" choices: beard, turban, headscarf, cap, builder, officer, detective, royal (×2), wizard, cowboy, hero, ninja, vampire, elf |
| Hair options | 5 | red, curly, white, bald, blond |
| Avatar backdrops | 8 colours | currently flat circles |
| NPC faces (relatives, friends, partners, coworkers) | same set as the player | pets use the animal set below |
| Life-path portraits | 12 | human, royal, vampire, witch, super, revenant, pirate, colonist, traveler, pet, prisoner, guard (plus the superpowers: strength, flight, speed, telekinesis, invisibility, mind, fire, healing) |

## 3. Animals (Pets Life and companions)
12 species: dog, cat, rabbit, parrot, horse, hamster, guinea pig, goldfish, turtle, ferret, lizard, snake. Currently one emoji each (hamster and guinea pig share one); ideally a baby, young, adult and senior version of each.

## 4. Content icons (by area, with approximate counts)
| Area | Count | Where |
| --- | --- | --- |
| Event popups | about 400 distinct | `data/events/*.json` (1,061 uses) |
| Achievements | 393, plus 6 tier frames (bronze → diamond) | `data/achievements.json` |
| Jobs and careers | 56 jobs, 100+ career ranks | `data/jobs.json`, career files |
| Majors | 25 | `data/majors.json` |
| Traits | 12 | `data/traits.json` |
| Countries and cities | 14 flags | `data/countries.json` |
| Challenges and daily goals | 13 | `data/challenges.json` |
| Licences | 6 families × 3 | `data/licenses.json` |
| Missions | 66 | `data/missions.json` |
| Activities, actions and menu rows | about 400 | `autoload/*.gd` (actions, shop, menus) |
| Star Shop items | 18 | `autoload/items.gd` |
| Minigames | 39, each with an icon and a result board | `autoload/minigames.gd` |
| Stat icons | 5 (happiness, health, smarts, looks, stress) + money, fame, heat and others | `scenes/ui_kit.gd` |
| Notification / toast types | about 12 | achievement, warning, good, bad … |

## 5. Drawn in code (design these as sprites if you want them replaced)
| Asset | Notes |
| --- | --- |
| Casino games | slots symbols (7), roulette wheel + chips, horse sprites, rocket, plinko ball and pegs, scratch card symbols (6), lucky wheel, playing cards |
| Family tree frame and nodes | 3 styles of node (alive, deceased, current) |
| Graveyard | headstone styles per ending, grass, candles |
| The Attic (heirlooms) | frames, shelves, mantelpiece |
| Light rays behind achievements | one shape |
| Particle sprites | sparks, hearts, coins, confetti, tears, smoke (currently emoji) |
| Backdrop art per mode | Pets, Prison, Prison guard, Celebrity, Royal, Vampire… (currently colour themes) |

## 6. Typography and theme
Two open fonts (Nunito, Noto Color Emoji). If emoji are replaced, Noto Color Emoji can be dropped from the build (it is about 10 MB). Themes: 9 colour palettes (dark, light, celebrity, vampire, undead, villain, superhero, royal, witch).

## Suggested order
1. Brand (section 1), then portraits and animals (2, 3): the parts players look at most.
2. Achievements (393) and event icons (about 400): the largest volume. Many events can share icons by theme, so a set of about 150 reusable icons covers most.
3. Everything else as time allows. Anything not replaced keeps its emoji.
