# Neon Static: design document

Version 0.2 (draft for approval, revised after three independent reviews), 2026-11-18. This file is the rules of the game. Every brief points at a section here. All numbers are first-pass values and live in one settings file (`cfg.gd`) so they can be tuned without touching code.

## 0. Decisions made by Nima

| Date | Decision |
|---|---|
| 2026-11-17 | Working title "Neon Static". Original game: own name, characters, stations and story. Nothing taken from any film or game. |
| 2026-11-17 | Desktop app only, built in Godot 4.7 with its full renderer (Forward+). No web version. |
| 2026-11-17 | First-person on foot and in the car. Keyboard and mouse only. The player never holds a weapon. |
| 2026-11-17 | First two incident types: robbery filmed while unseen, and a street pursuit filmed while driving. |
| 2026-11-17 | Several ways to cross the line from the start. |
| 2026-11-17 | Endless career. A bad night costs money and reputation. No game over. |
| 2026-11-17 | Camera starts simple and gets deeper with gear. Old-camcorder viewfinder. |
| 2026-11-17 | Driving is arcade and forgiving. You juggle steering and filming; a hired driver is a late upgrade. |
| 2026-11-17 | Hints while filming, the verdict at the news desk. |
| 2026-11-17 | Some blood, not explicit. |
| 2026-11-18 | Look: "Acid Cyber" (preset `godot/looks/CX.gd`): acid green and yellow with magenta and cyan accents, heavy rain, wet road, dense signs. |
| 2026-11-18 | The game is built on Nima's Windows PC, not the Mac, and ships first as a Windows app. The project lives in a private GitHub repo. |
| 2026-11-18 | First milestone is a near-complete first draft of the whole game on a small district of 4 to 6 blocks. People and sound may be placeholders. Traffic, menus and writing are built properly. |
| 2026-11-18 | Fable (extra effort) plans, reviews, does all graphics alone, and builds the feel-critical code (camcorder, scoring, car, stealth, crossing the line). Opus builds the rest. Sonnet tests. Two build chats at a time. About 10 chats in total. |

## 1. What the game is

You are a freelance night stringer in a rain-soaked city called **Vantage**. You listen to the police scanner, race to incidents, film them before anyone else, and sell the tape to whichever station pays most. Better tape buys better gear. The stations pay more the closer and uglier the footage gets, and nobody asks how you got it.

**Pillars**

1. **The camcorder is the verb.** Everything you do is aimed at getting something in frame, in focus, for long enough.
2. **Get there first, get close.** Time and distance are the two things you spend.
3. **The line is yours to cross.** The game never forces you to tamper. It only makes it pay.
4. **Satire, not celebration.** Stations cheer the worst footage in the blandest corporate language. Violence is brief and never the player's own act.

**Tone rules for writers and artists:** dry and corporate from the stations, clipped and procedural from dispatch, no jokes about victims, no real brands or real people.

## 2. The loop

One **night** runs from 22:00 to 05:00 in game time, which is **12 minutes** of play.

1. **Garage.** You start at your lock-up with your car and gear. The scanner is on.
2. **Scanner.** Calls come in every 60 to 110 seconds, 5 to 7 per night, often overlapping so you must choose. Each call shows a type, a street, and two countdowns in real seconds: how long ago it came in and roughly when police arrive. (The night clock is for mood; anything you must act on is shown as a countdown.)
3. **Drive.** Reach the scene. Arriving before police and before the rival crew matters.
4. **Film.** Raise the camcorder, record. Tape and battery are limited. Decide how close to get and whether to cross the line.
5. **Leave.** Scenes end on their own (arrest, escape, police clearing you out). You can film several in one night.
6. **News desk.** At 05:00, or when you choose to end the night, you review your clips and sell each to one station.
7. **Shop and bills.** Buy gear, repair the car, pay rent when due. Then the next night.

A night also ends early if you are arrested or knocked out (section 10).

## 3. The player

**On foot.** Walk 3.2 m/s, run 5.5 m/s, crouch 1.6 m/s. Lean left and right around corners (Q and E). Jump is a small hop for kerbs only. Interact (F) with doors, the car, and objects marked as movable. Carried objects float at arm's length and can be set down or dropped.

**No health bar.** If you are hit by a car, shot at close range, or caught by a robber, the screen cuts to black and you wake at the clinic: the night is over, you pay a medical bill ($250) and you lose the tape that was in the camcorder. Clips already "banked" in the car are safe (see below).

**Banking tapes.** A tape holds a limited number of minutes. Swapping tapes is done at the car. Tapes left in the car are safe from seizure on foot. This makes the walk back to the car part of the risk.

**Controls**

| Action | Key |
|---|---|
| Move, steer | W A S D |
| Run / handbrake | Shift / Space |
| Crouch | Ctrl |
| Lean | Q, E |
| Interact, enter or exit car | F |
| Raise camcorder | Hold right mouse (toggle option in settings) |
| Record on/off | Left mouse while raised |
| Zoom | Mouse wheel |
| Focus lock | Middle mouse or R |
| Scanner: next call / set destination | Tab / G |
| Horn (also a provoke tool) | H |
| Phone: call 911 | C |
| Map | M |
| Pause | Esc |

## 4. The camcorder

Raising it switches the view to the viewfinder: scanlines, slight grain, a REC dot, timecode, battery bar, tape minutes left, zoom bar and a focus bracket. It works the same on foot and in the driver's seat.

**On foot:** movement slows to walking pace while raised. Running lowers it.

**In the car:** W A S D still drive. The mouse aims the camcorder within a cone of about 100 degrees left and right. While raised, the windscreen view narrows to the viewfinder, so you see less of the road. That is the trade.

**Stats that gear changes**

| Stat | Starter | Best |
|---|---|---|
| Zoom | 1x to 4x | 1x to 16x |
| Battery | 6 minutes of recording | 20 minutes |
| Tape | 4 minutes per tape, 2 tapes | 10 minutes per tape, 4 tapes |
| Autofocus | Slow (0.8 s to settle) | Fast (0.15 s), plus manual focus ring |
| Steadiness | Heavy shake when moving or zoomed | Stabilised |
| Low light | Dark areas read as noise | Clean in shadow |

**Focus.** Starter gear autofocuses on whatever is under the centre bracket, with a delay. It locks on to cars more readily than people, and shake from road movement is milder than shake from walking, so a beginner who keeps a fleeing car centred at 15 to 40 m gets about 0.5 clarity. Focus lock (R) holds the current distance. Manual focus is a later gear unlock.

**Live hints, no numbers.** The bracket is white when nothing newsworthy is framed, yellow when a subject is in frame but small, soft or blocked, green when it is a good shot. A small tick sounds when a key moment is captured. The real verdict only comes at the news desk.

## 5. What counts as a good shot

Every newsworthy thing in the world carries a **subject tag**: who or what it is, how much it is worth, and a few sample points on its body. Whenever the camcorder is raised, ten times a second, the game checks each tagged subject in view (this drives the live hints). The results are written to the tape only while recording.

**A clip is all your footage of one incident**, joined into one timeline however many times you stopped and started. Each incident is sold once, to one station. Stopping and restarting never resets anything.

**Per sample, each subject gets a clarity value from 0 to 1**, made from:

- **Visible:** how many of its sample points are unblocked. Shop glass does not block the shot; it costs a small clarity penalty (10%). Rain never blocks.
- **Size:** how much of the frame it fills. Best between 15% and 60% of frame height.
- **Centred:** mild bonus near the middle; not a strict rule.
- **In focus:** how close the focus distance is to the subject.
- **Steady:** how little the camera is shaking.
- **Lit:** dark subjects score low unless the gear has good low-light.

**Key moments** are short events that incidents announce: a gun drawn, a shot fired, cash grabbed, a crash, an arrest, a getaway. When a key moment fires, the game takes one extra reading at that instant, so a split-second event is never missed between checks. If the subject's clarity is above 0.4, the moment is **captured**.

**Clip value**

`clip value = (coverage value + key moment value) × exclusivity × authenticity`

- **Coverage value:** for each subject, its base worth × seconds of good footage, with strongly diminishing returns after 8 seconds, so holding one static shot stops paying.
- **Key moment value:** each captured moment's worth × its clarity at that instant. This is most of a good clip's value.
- **Exclusivity:** ×1.5 if you were recording before police arrived and the rival crew has no footage; ×1.0 normally; ×0.6 if you arrived after the scene was taped off.
- **Authenticity:** ×1.0 for clean footage. Tampering changes it per station (section 11).

**Starting values**

| Thing | Worth |
|---|---|
| Suspect (per second, clear) | $6 |
| Police officer at work (per second) | $3 |
| Victim or clerk (per second) | $4 |
| Getaway or fleeing car (per second) | $5 |
| Key moment: gun drawn | $80 |
| Key moment: shot fired | $150 |
| Key moment: cash grabbed, getaway start | $60 each |
| Key moment: crash, forced stop | $180 |
| Key moment: arrest on the ground | $120 |
| Key moment: blood visible | $100 |
| Suspect's face clear, 2 s or more | $70 bonus |

A clean first-week robbery clip should land around $300 to $500. A great one with a pursuit ending can pass $1,200.

The scoring is a plain calculation on a recorded timeline, with no dependence on what is on screen at review time, so it can be tested automatically with made-up tapes.

## 6. Scanner and the shape of an incident

A **call** has: a type code and plain-language line, a street address, a "minutes ago", and a police arrival estimate. Calls are text with radio static in the first draft.

Every incident, whatever the type, is built on the same frame:

- **Stages** in order, each with a duration range and things that can cut it short.
- **Actors** with roles (suspect, lookout, victim, officer, bystander).
- **Subject tags** and **key moments** it can announce.
- **Police timeline:** when units are dispatched, when they arrive, when the scene is taped off, when it is cleared.
- **Endings**, each with a consequence (arrest, escape, chains into another incident).
- **Hooks for crossing the line:** which objects can be moved, where the tape line goes, what provoking does.

A night's calls are drawn from a weighted pool with rules: at least 5 calls, at most 3 robberies, never the same site twice in one night, at least one call close to the player early in the night, and difficulty rising with career week. Which store, which vantage points are usable and where actors stand vary from night to night.

**Call types in the first draft:** robbery in progress; pursuit (either chained from a robbery or on its own: "vehicle failing to stop on Kessler"); and three light filler calls built from the same parts with no stages: shots heard (officers search an alley), traffic stop (an arrest moment, 40% chance), minor collision (two cars, an argument). Fillers pay $40 to $150 and keep the night full.

**An incident's clock is anchored to the player, not just the call.** Each incident has a wait stage that holds until the player is within 150 m or a time limit passes, so driving promptly always gets you there for the main event.

A **rival crew** (a white van) responds to about half the calls. If it arrives and films before you, you lose the exclusivity bonus. In the first draft it drives to the scene, parks, and one figure stands filming.

## 7. Incident: robbery in progress

**Sites:** a convenience store, a pawn shop and a pharmacy, each with glass frontage, a back door on an alley, and a dark vantage point across the street.

**Actors:** two robbers inside (masked, one armed), one lookout at the door, a clerk, a getaway driver waiting in a car nearby, zero to three bystanders.

| Stage | Length | What happens | Key moments |
|---|---|---|---|
| 0. Wait | until you are within 150 m, or 45 s | Getaway car idles nearby. Lookout loiters. The call has just come in. | none |
| 1. Casing | 20 to 40 s | Lookout watches the street. Robbers enter. | none |
| 2. Hold-up | 30 to 50 s | Gun drawn on clerk, cash demanded. | gun drawn, cash grabbed |
| 3. Trouble (40% chance) | 5 to 15 s | Clerk resists or a bystander walks in. A shot may be fired. | shot fired, blood visible |
| 4. Getaway | 10 to 20 s | Robbers run to the car and leave. | getaway start |
| 5. Police | arrive 90 to 150 s after casing starts | Officers secure the site, tape goes up after 30 s, scene cleared after 3 minutes. | arrest (if robbers still present) |

**Worked example (a test case for the bot):** call at 0 s; you arrive and park at 35 s (casing starts); you are at the vantage point with the camcorder up by 55 s; hold-up runs 60 to 105 s; getaway 105 to 120 s; police arrive at about 135 s.

**If you are seen** (section 9): the lookout shouts, the hold-up skips to the getaway (you lose stages 2 and 3 footage), and the armed robber may come for you: you have about 4 seconds to break line of sight or you are knocked down and lose the tape.

**Chaining:** 50% of getaways become a **pursuit**. The getaway car has a scripted slow start (a stall, a blocked junction or a red light) that lasts until you are in your car or 20 s have passed, and the pursuit begins when it meets the first arriving patrol car. Staying on the robbers' car is the best money in the draft.

**Fleeing by car when spotted:** the armed robber fires at your car instead (repair bill of $150 to $300) and the hold-up still skips to the getaway.

## 8. Incident: street pursuit

**Actors:** one fleeing car, two police cars, traffic.

- The fleeing car follows a route of 1.2 to 1.8 km lasting 60 to 90 seconds at about 18 m/s on average: mostly one lap of the loop with a cut through the underpass, never the same corners twice.
- **Staying filmable:** the chase slows when you are more than 80 m behind and speeds up only when you are closer than 10 m, so 15 to 40 m is the stable band and also the best filming distance. You should never notice this.
- **The ending is chosen at the start** and placed at a fixed point on the route so it happens where you can film it.
- **Key moments:** near miss with traffic ($40), sideswipe ($90), crash or forced stop ($180), arrest ($120), suspect runs on foot ($60).
- **Endings:** forced stop and arrest (45%), crash (30%), escape (25%, no ending footage, clip is worth much less).
- **Your risks:** hitting anything costs repair money. Hitting a police car or blocking them adds heat (section 10). Running a red light in front of police adds a little heat.
- Filming needs the camcorder raised while you steer. The fleeing car and police cars carry subject tags; best size-in-frame is at 15 to 40 m.

## 9. Being seen

Each watcher (lookout, robber, officer) has a **suspicion** value from 0 to 100 about you.

- **Sight:** 28 m range, 110 degree cone, blocked by walls and cars.
- **How fast it rises** depends on distance, light and what you are doing:

| You are... | Rise per second at 15 m |
|---|---|
| Standing in light | 40 |
| Standing in shadow | 12 |
| Crouched in shadow | 4 |
| Behind cover, leaning out | 6 |
| Running anywhere in view | 70 |

  Closer is faster (double at 7 m), farther is slower (half at 25 m).
- **Each hidden pose has a ceiling.** Crouched in shadow levels off at 30, behind cover leaning out at 35, standing in shadow at 50. Suspicion only climbs past the ceiling if you move, step into light or come closer than 10 m. So a dark vantage point can be held for a whole hold-up if you stay still and low, and standing up in it gets you stared at but not spotted.
- **In the car:** parked with lights and engine off counts as standing in shadow; engine running or headlights on counts as standing in light; a moving car in view counts as running.
- **Light** comes from marked light zones under lamps, signs and shopfronts. The district is built with dark doorways and alleys on purpose.
- **The camcorder gives you away a little:** the REC light adds 25% to the rise rate. A piece of black tape over it is a cheap early upgrade.
- **Noise:** running, the car horn and car doors make sound events with a radius (12 m, 40 m, 10 m). A watcher who hears one turns to look.
- **It falls** by 15 per second when you are out of sight, and by 3 per second while you hold a hidden pose above its ceiling.
- **Thresholds:** at 40 the watcher stops and stares in your direction (a visible tell, and your hint to back off). At 100 you are spotted.
- A small eye icon fills as the highest nearby suspicion rises. It shows on the HUD at all times, camcorder up or down.
- Light comes from **light zones**: fixed ones under lamps, signs and shopfronts, and moving ones attached to headlights and police cars. Scoring's "lit" value reads the same zones.

Police use the same system for a different purpose: they notice trespassing and tampering (section 11).

## 10. Police, heat and what a bad night costs

**Heat** is a number from 0 to 100 that carries across nights and drops by 15 each night.

| Act | Heat |
|---|---|
| Seen crossing a tape line | +15 |
| Seen moving evidence | +35 |
| Blocking or hitting a police car | +25 |
| Reckless driving in view of police | +5 |
| Ignoring an officer's order to move back | +10 |

| Heat | Consequence |
|---|---|
| 0 to 29 | Officers ignore you outside the tape. |
| 30 to 59 | You get ordered back sooner; fines ($150) for each act seen. |
| 60 to 84 | Officers check you at scenes and seize the tape in the camcorder. |
| 85 or more | You are arrested on sight when breaking a rule: night ends, $600 fine, tape seized. |

There is no game over. **Rent** is due every 7 nights. It starts at $900, rises 8% a week and stops rising at $1,800 (week 10). If you cannot pay, you take a debt with 10% weekly interest, never more than four weeks' rent in total, and one station's reputation drops ("we hear you're having problems"). The pressure is slow and financial, and an endless career can always recover.

## 11. Crossing the line

Four acts in the first draft. Each makes better tape and has a price.

| Act | What you do | What you gain | What it risks |
|---|---|---|---|
| **Trespass** | Step past police tape, or enter a site by the back door during a robbery. | Closer shots, faces, blood. | Heat if an officer sees you. Being spotted by robbers. |
| **Rearrange** | Pick up and move a marked object (a dropped gun, a cash bag, a shoe) into the light or into frame. | A "money shot": +$120 if the object is filmed clearly after the move. Once per incident. | +35 heat if seen. The tape is flagged as tampered if it shows your hands, or if it shows the object in two different places (the recorder remembers where each object first appeared). Moving it before you ever film it leaves no trace on tape. |
| **Provoke** | Sound the horn, shout, or flash headlights to make something happen now. | Skips to the trouble stage of a robbery with a 75% chance of a shot fired. | Robbers look for the source (from the car, they shoot at the car). Bystanders can be hurt, which stations love and which is on you. |
| **Withhold** | Someone at a scene is hurt and no ambulance has been called, or you find an incident before any call goes out (a tip-line call or one you drive past). Call (C) and help comes at once, or keep filming. | More time alone with the scene and the "blood visible" moment stays on camera longer. | The delay is recorded in the ledger. If a witness sees you standing there filming, it becomes a story (below). |

**Witnesses.** Each time you provoke or withhold, there is a 25% chance (40% if the rival crew is on scene) that someone films you doing it. That adds +20 heat, and MERIDIAN runs a short item about "a freelance cameraman" that costs you 15 reputation with them. The pay from the other stations is untouched. This is what makes the clean choice a real choice.

**How stations react** is in section 12. In short: one loves it, one punishes it if they can tell, one doesn't care as long as you are first.

**The ledger.** The game quietly keeps a count of what you did: people hurt after you provoked or withheld, evidence moved, lines crossed. It is shown back to you in news-desk captions and end-of-week summaries, in the stations' own cheerful language. There is no morality score and no lecture. The first draft only needs the ledger and the captions.

## 12. Stations and selling

Three buyers, each with a taste. Names are invented.

| Station | Taste | Pays | On tampering |
|---|---|---|---|
| **Channel 6 Vantage Now** (tabloid TV) | Blood, guns, faces, crashes. Key moments ×1.3. | Highest. | Loves staged shots: rearranged evidence ×1.2. |
| **MERIDIAN Public** (serious broadcaster) | Clear, steady, verifiable. Coverage ×1.3; pays a 25% premium for a clean, steady clip with a clear face or police at work. Shaky footage penalised. | Lower on raw action, the best payer for clean, complete coverage. | If the tape is flagged as tampered: refuses it and reputation −10. |
| **HALO Stream** (online feed) | First and raw. Exclusivity counts double. | Starts high, and drops 5% for every game-hour since the incident. | Indifferent. |

**At the news desk** you see each clip as a strip of up to 10 still frames with captions for the key moments caught, then three offers. You sell each clip to one station. Unsold clips are worthless tomorrow. **Each station's offer drops 15% for every clip it has already bought from you that night**, so spreading your sales pays.

Stills are small (320 by 180), taken in the background at least half a second apart so they never cause a stutter at the big moment, kept only until the night's sale, and never written to the save file.

**Reputation** with each station runs 0 to 100. Selling good clips raises it; refused or weak clips lower it. Higher reputation raises that station's offers (up to +30%) and unlocks perks: a tip line (one early call per night), a retainer (small nightly fee), and requests ("get me a face") with a bonus.

**The verdict screen** shows the breakdown per clip: what was caught, what was missed, what blocked the shot, and one dry line from the buyer.

## 13. Money and gear

Start with **$300**, the starter camcorder, an old sedan and a basic scanner.

| Upgrade | Tiers | Price range |
|---|---|---|
| Lens (zoom) | 4x, 8x, 12x, 16x | $400 to $2,400 |
| Battery | 6, 10, 15, 20 minutes | $150 to $900 |
| Tape stock | longer tapes, more tapes | $100 to $700 |
| Autofocus and manual ring | 3 steps | $300 to $1,500 |
| Stabiliser | 3 steps | $350 to $1,800 |
| Low-light sensor | 3 steps | $400 to $2,000 |
| Black tape over REC light | 1 | $20 |
| Scanner | range, earlier calls, police arrival estimate accuracy | $250 to $1,600 |
| Car | grip, top speed, toughness; a second car later | $500 to $6,000 |
| Dash mount | films forward hands-free at fixed zoom | $450 |
| Hired driver | drives while you film (late game) | $200 per night |

Costs: rent (section 10), car repairs ($40 to $400 per night depending on damage), fines, medical bills, tapes are reusable.

**Target curve:** week 1 nets about $200 to $500 a night; a full first tier of gear by the end of week 2; top gear takes around 6 weeks of good play. A test bot plays 20 nights at "average" skill to check this.

## 14. The district

**Name:** Lowgate, a district of Vantage. Five blocks in an uneven grid, about 350 m by 300 m of drivable area.

- **Garage** (your start point) on the south edge.
- **Kessler Avenue:** the wide main street with the elevated rail crossing it. The look-test street grows into this.
- **Three robbery sites** on different blocks: Volt Mart (convenience), Orbit Pawn, Mira Pharmacy. Each has a front on a lit street, a back door on an alley and a dark vantage across the road.
- **Alleys** behind every block, dark, with dumpsters and fire escapes for cover.
- **The loop:** a ring of wider streets around the district (about 1.3 km round) plus a short underpass that cuts across it, giving pursuits 1.2 to 1.8 km routes with two long straights and four hard corners.
- **The road network is fixed early** as one data file (every street, the underpass, the loop, junctions and lights). Traffic lanes and pursuit routes are generated from it. Later art may dress the roads but never move them.
- Each robbery site carries named markers placed in the grey-box stage (front door, back door, counter, vantage points, getaway parking, movable-object spots, tape line). Art dresses around the markers and never moves them.
- **Landmarks** so you can navigate without the map: the rail line, a tall hologram tower, a red-lantern market lane, a clinic.
- The district is ringed by tall facades and blocked-off streets (construction barriers, flood closure) so the edge never looks like an edge.

## 15. People and traffic

- **People are placeholders in the first draft:** simple stylised figures with idle, walk, run, crouch, aim, hands-up and fall. Role is shown by silhouette and colour (mask, uniform, apron).
- At most **12 animated people** in view at once; others freeze or are removed off-screen.
- **Traffic is built properly:** cars follow a lane map of the district, stop at lights, queue, and get out of the way of sirens. At most **14 moving cars** near the player. Parked cars line the streets.
- Bystanders walk fixed loops on sidewalks, stop to stare at incidents, and run from gunfire.
- Every character has a visible tell before it acts, a minimum time in each state, and a "stuck" timer that resets it.

## 16. Screens

Title, new career or continue, settings (mouse, volume, quality low/medium/high, hold or toggle for the camcorder, content toggle for blood: when off, blood is drawn as a cut-away and still scores), a short playable first night that teaches driving, filming and selling, the HUD (scanner strip, destination arrow, clock, cash, heat), the viewfinder, the map, the news desk, the verdict, the shop, the weekly summary with rent, pause.

## 17. Sound (placeholder in the first draft)

Rain loop, engine tied to speed, tyres, horn, sirens, radio static and a tone for each scanner call, camcorder motor and REC beep, gunshot, glass, footsteps, a low synth bed. Scanner calls are text. All sounds are generated in-house or CC0 and logged.

## 18. Performance budget

Target: **60 frames per second at 1080p on Nima's Windows PC** at high quality (hardware recorded in `STATUS.md`), and 60 on medium on any recent laptop with a graphics card.

- The frame has 16.6 ms. The graphics chat works to a per-feature budget of render time, not just counts: the costliest effects in the look test (real-time bounce lighting, the heaviest reflections, the densest fog volume, about 80,000 rain particles) are cut back or replaced by cheaper shader versions first.
- No more than 24 real lights affecting the view; the rest of the glow is emissive surfaces. No more than 4 lights casting shadows. Traffic headlights and police light bars are glowing meshes with fake cones; only your car and the nearest police car cast real light.
- No more than 1,500 draw calls in any view; repeated props are batched.
- The whole district loads once behind the loading screen. Distant buildings swap to simple versions and hidden ones are skipped. No streaming of blocks in and out.
- Rain does not fall inside shops or the car.
- Shot checks: at most 10 times a second, only while the camcorder is raised.
- **Four test views:** three standing views and one scripted pursuit drive with the viewfinder up, 14 traffic cars and 12 people. Graphics briefs and each end-of-stage integration brief measure frame rate with the machine to themselves; other briefs run a quick smoke check only.

## 19. Build rules

- Godot 4.7, Forward+, typed GDScript, the Godot input map for all controls.
- One folder per system; each chat owns its folders (see `PLAN.md`). Systems talk through a shared event list (`events.gd`) and the small interfaces in `docs/CONTRACTS.md`, never by reaching into each other's scripts.
- Every tuning number lives in that system's own settings file (`cfg/camcorder.gd`, `cfg/stealth.gd` and so on), loaded by one small `Cfg` loader. No numbers in logic scripts.
- **One camera.** The camcorder system owns the only player camera (aim, zoom, shake). Movement provides the mount point on the player's head and the driver's seat. The viewfinder is a single full-screen overlay, never a second render of the scene. Physics interpolation is on.
- **One car body.** Every car (yours, traffic, police, getaway, the rival van) is the same car scene driven through one input interface: steer, throttle, brake. You feed it from the keyboard; AI drivers feed it from routes.
- **One save file**, plain JSON. Each system registers its own section with its own version number. Written to a temporary file then renamed, with the previous save kept as a backup.
- Test and capture tools live in their own dev harness, never inside gameplay scripts.
- Models are made in-house in Blender from scripts. Any outside file (people, animations, sounds, fonts) is logged in `docs/ASSETS.md` with source, licence and date before it enters the project.
- At most two Godot copies on the machine at once, through `tools/gslot.sh`. Local commits only, by the orchestrator.

## 20. Not in the first draft

Car crash and structure fire incidents, more districts, voiced dispatch, finished character models, the hired driver, a second car, story characters and scripted events, gamepad support, achievements.

## 21. Open questions

1. The rival crew can film you crossing the line (section 11). Should they cross it too, and can you film them doing it?
2. Should MERIDIAN ever broadcast a correction that names you after buying tampered tape?
3. How long should a first session be before the first rent is due: 7 nights (84 minutes of play) or 5?
