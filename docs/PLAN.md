# Neon Static: plan for Milestone 1 (first draft of the whole game)

Version 0.2 (draft for approval, revised after three independent reviews), 2026-11-18. Read section 0 of `DESIGN.md` first; Nima's decisions there override anything here.

## 1. What Milestone 1 delivers

A Windows app in which you can play endless nights in the Lowgate district: take scanner calls, drive, film robberies and pursuits through the camcorder, cross the line in four ways, sell clips to three stations, buy gear, pay rent, save and continue. People and sound are placeholders. Everything else is built to be kept.

**Done means, in numbers:**

- Zero script errors across 20 bot-played nights; every night ends; no character stuck for more than 5 seconds; cash never goes below the debt cap.
- The economy bot's income lands inside the target band in `DESIGN.md` section 13.
- 60 fps on the build PC at high quality in all four test views.
- Nima has played the build against a one-page checklist (walking, car, camcorder, stealth, selling) and answered yes or "needs change" to each line.

## 2. The chats: eight standing chats plus a tester per stage

Each lane is **one standing chat** that keeps a short `HANDOFF.md` in its folder. A lane's chat is only replaced when it gets long, and the replacement starts from that hand-off note.

| # | Chat | Model | Owns (under `godot/` unless noted) | Builds |
|---|---|---|---|---|
| 0 | **Orchestrator** | Fable, extra effort | `docs/`, `project.godot`, `core/events.gd` | Design, plan, status board, contracts, briefs with pass checks, reviews, commits. Applies every change to the two shared files between briefs, so no build chat ever edits them. |
| 1 | **Foundation and integration** | Opus | `core/` (except events), `game/` (the main scene that assembles everything), `dev/`, `tests/`, `tools/` | Skeleton, settings loader, save file, loading screen, test tools, the two bots, the check script, Windows app packaging from day one, and the end-of-stage integration of everyone's work. |
| 2 | **Graphics** | Fable, extra effort, alone | `assets/`, `shaders/`, `looks/`, `city/`, `tools/blender/` | Acid Cyber at 60 fps, quality levels, the Lowgate district (roads data, grey-box, markers, dressing, interiors), all models including cars and stand-in people with their animation clips. |
| 3 | **Camcorder and scoring** | Fable, extra effort | `camcorder/`, `scoring/`, `cfg/camcorder.gd`, `cfg/scoring.gd` | The one player camera, viewfinder, zoom, focus, record, battery, tape, shake, live hints; subject tags, recorder, clip value, stills, a debug score panel. |
| 4 | **Movement** | Fable, extra effort | `player/`, `vehicles/`, `cfg/player.gd`, `cfg/vehicles.gd` | On-foot controller (walk, run, crouch, lean, carry), the single car body with its steer/throttle/brake interface, your keyboard driver, getting in and out, camera mount points, damage as cost. |
| 5 | **Stealth and the line** | Fable, extra effort | `stealth/`, `line/`, `cfg/stealth.gd`, `cfg/line.gd` | Light zones (fixed and moving), sight, noise, suspicion with ceilings and tells; trespass, rearrange, provoke, withhold, witnesses, the ledger. |
| 6 | **World** | Opus | `traffic/`, `npc/`, `incidents/`, `scanner/`, `police/` and their `cfg/` files | Lane map from the roads data, AI drivers (traffic, pursuit, police, getaway, rival van), character behaviours, scanner, night clock and generator, the incident frame with line-crossing hooks, robbery, pursuit, filler calls, police arrival, tape, heat, arrest, clinic. |
| 7 | **Career and front end** | Opus builds, Fable writes the text | `newsroom/`, `career/`, `ui/`, `audio/`, `text/` and their `cfg/` files | News desk, three stations, offers, verdict, reputation, money, rent, debt, shop, HUD, map, menus, the teaching night, placeholder sound. |
| T | **Tester** | Sonnet | nothing | One standing tester chat per stage (six in all). Gets only the pass checks of each brief in that stage. Reports PASS, FAIL or NOT CHECKED with evidence. Designs nothing, fixes nothing. |

**At most two build chats run at once:** Graphics plus one code chat. Two code chats never run together.

## 3. How every task runs

1. Orchestrator tags a clean point in git, then writes a brief in `docs/briefs/<id>.md`: why, what to build, files it may touch, what is out of bounds, at most about 6 numbered pass checks, the design sections it implements. One system per brief.
2. The build chat builds exactly that, runs `tools/check.sh`, writes a report of under 300 words in `docs/reports/<id>.md` including a line "interfaces changed: none / list", and stops.
3. The stage's tester checks the pass checks.
4. Orchestrator reviews the changes, the tester's report and the pictures or clips. Pass: commit, update `docs/STATUS.md` and `docs/CONTRACTS.md`. Fail: a fix note goes back to the same chat.
5. Three failed rounds on one brief, or a chat that crashes mid-task: the orchestrator restores that brief's files to the tagged point and brings it to Nima if it was the third failure.

**Every stage ends with an integration brief** (Foundation): wire the stage's systems into the main scene, run the smoke bot and the four frame-rate views, package the app. Only then does Nima get the checkpoint, always as a double-clickable app.

## 4. Before stage A: contracts (orchestrator)

`docs/CONTRACTS.md` is written first and fixes what every chat builds against:

- The full event list, the input actions and the collision layers (including a "blocks camera" layer that leaves out glass and rain).
- The car input interface, the camera mount points, the subject tag, the light zone, the save-section rule.
- The incident frame's hooks for crossing the line (skip a stage, delay police, list of movable objects).
- The marker names every robbery site carries.
- The small interface the bots use (drive to, aim at, record, sell best).

## 5. Stages and order

| Stage | Code briefs (one at a time, in this order) | Graphics briefs (alongside) | Checkpoint for Nima |
|---|---|---|---|
| **A. Base** | F1 skeleton, settings loader, save registry, loading screen. F2 dev harness, logic tests, check script, frame log, app packaging. | G1 Acid Cyber at 60 fps on the look-test street; quality levels. G2 Lowgate roads data and grey-box of all five blocks with collision. | Before/after pictures: what the look kept and gave up to reach 60 fps. |
| **B. Move and film** | M1 on foot. M2 car body and keyboard driver. C1 camera, viewfinder, record, battery, tape. M3 in and out of the car, filming from the seat. **INT-B.** | G3 your car with interior, camcorder model. G4 grey-box robbery sites with all markers and first light zones (component from S0). | **Play build 1:** walk, drive and film in the grey district. Feel checklist. |
| **C. Living street** | S0 light-zone component. C2 subject tags, recorder, clip value, debug score panel. W1 lane map and AI driver. W2 traffic and lights. W3 stand-in people and bystanders. **INT-C.** | G5 stand-in people with animation clips, police car, getaway car, van. G6 dress Kessler Avenue and two more blocks. | Pictures of the dressed blocks with traffic. |
| **D. Incidents** | W4 scanner and night clock. W5 incident frame with hooks. S1 sight, noise, suspicion. W6 robbery. W7 pursuit and the chain. W8 police arrival and tape. W9 heat, fines, arrest, clinic. F3 smoke bot. **INT-D.** | G7 dress the three sites and interiors; tune light zones for stealth. G8 remaining blocks, alleys, district edge. | **Play build 2:** a robbery and a pursuit, filmed, with scores in the debug panel. |
| **E. The loop** | N1 news desk, stations, offers, verdict. N2 money, rent, debt. N3 shop and gear tiers. S2 the four acts, witnesses, ledger. W10 filler calls and night generator. U1 HUD and map. U2 menus and settings. U3 teaching night and all text. F4 economy bot. **INT-E.** | G9 rain, steam and night variation polish. | **Play build 3:** three full nights with selling and upgrades. |
| **F. Finish** | U4 placeholder sound. B1 balance from the economy bot. X1 bug pass from the smoke bot and Nima's list. **INT-F.** | G10 final performance pass on every block. | **Play the first draft.** Sign-off or change list. |

About 45 briefs, each one system.

**The two bots** (replacing the single "plays 20 nights" bot, which could not exist early and would take hours):

- **Smoke bot** (stage D): follows scripted routes through one robbery and one pursuit in the real game to catch errors and stuck characters.
- **Economy bot** (stage E): runs without graphics, draws clip outcomes for an "average" player from skill ranges, and pushes them through the real scoring, news desk and career code. Twenty nights in seconds.

## 6. Rules every chat follows

- Read section 0 of `DESIGN.md`, then your brief, then `docs/STATUS.md`, `docs/CONTRACTS.md` and your lane's `HANDOFF.md`. Nothing more than you need.
- Touch only the files your brief lists. Need a new event, input action or project setting? Ask for it in your report; the orchestrator adds it.
- Never commit, push, stash or reset. Never run more than one Godot at a time; always through `tools/gslot.sh`.
- Tuning numbers go in your lane's `cfg/` file. No test code in gameplay scripts.
- Never report a picture you have not opened and looked at. Motion (rain, shake, traffic) is shown with a short clip.
- Any outside file is logged in `docs/ASSETS.md` before it is added.
- Nothing from any existing film or game: no names, designs, lines or music.

## 7. Documents the orchestrator keeps

| File | Purpose |
|---|---|
| `docs/DESIGN.md` | The rules of the game. |
| `docs/PLAN.md` | This file. |
| `docs/STATUS.md` | The board: each brief, its lane, its state, the files it owns, what is waiting on Nima. |
| `docs/CONTRACTS.md` | How systems talk to each other. |
| `docs/briefs/`, `docs/reports/` | One brief and one report per task. |
| `docs/ASSETS.md` | Source, licence and date for every outside file. |
| `docs/looks/` | Look-test pictures and the Acid Cyber preset notes. |
| `docs/research/` | Engine and Godot research, and the design review of 2026-11-18. |

## 8. Risks, stated plainly

1. **Frame rate.** The look test ran at about 12 fps on the Mac with every expensive effect switched on; the PC's graphics card may do better, which stage A measures first. Stage A must reach 60 before anything is built on it. If the look has to give something up, Nima chooses from pictures.
2. **Car feel and camera feel** cannot be judged by a bot. They need Nima at play builds 1 and 2; expect a round of changes after each.
3. **Size.** About 45 briefs with review rounds is several weeks of sessions. Fable at extra effort on four lanes is the heaviest use of the plan allowance.
4. **Shared machine.** The build runs on the Windows PC. Keep to two Godot copies at once there too, or frame-rate measurements become meaningless.
5. **Placeholders that stay.** People and sound are stand-ins by decision and get their own milestone afterwards.
6. **No precedent.** Nobody has published a game of this size built this way. The stage structure exists so problems show up at four play builds instead of at the end.

## 9. After Milestone 1

Finished characters and animation; full sound and voiced dispatch; car crash and structure fire incidents; more districts; the hired driver; story characters; a release build.
