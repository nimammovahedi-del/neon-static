# Neon Static: rules for every chat in this folder

Original first-person game, Godot 4.7 (Forward+, typed GDScript). Built on a Windows PC. The creator, Nima, does not code: do the technical work yourself, explain in plain language, and never ask him to edit files or use the Godot editor beyond what README.md describes.

## Read first, in this order

1. `docs/DESIGN.md` section 0 (Nima's decisions; they override everything)
2. Your brief in `docs/briefs/` (build chats) or `docs/PLAN.md` (orchestrator)
3. `docs/STATUS.md`, `docs/CONTRACTS.md`, and your lane's `HANDOFF.md` if it exists

Read nothing more than you need. `docs/research/` is reference, not reading material.

## Who does what

- **Orchestrator** (Fable, extra effort): plans, writes briefs with pass checks, reviews, and is the only chat that commits and pushes. Owns `docs/`, `godot/project.godot` and `godot/core/events.gd`.
- **Graphics** (Fable, extra effort, on its own): all models, shaders, lighting and the city.
- **Camcorder and scoring, Movement, Stealth and the line** (Fable, extra effort).
- **Foundation and integration, World, Career and front end** (Opus).
- **Testers** (Sonnet): check pass checks only. Design nothing, fix nothing.

Lanes, folders and order are in `docs/PLAN.md`. At most two build chats at once: Graphics plus one code chat.

## Rules

- Touch only the files your brief lists. Need a new event, input action or project setting? Ask in your report.
- Build chats never commit, push, stash or reset.
- Never run more than one Godot at a time, and run it through `tools/gslot.sh` (from Git Bash).
- Tuning numbers go in your lane's `godot/cfg/` file. No test code in gameplay scripts.
- Never report a picture you have not opened and looked at. Show motion with a short clip.
- Log any outside file in `docs/ASSETS.md` (source, licence, date) before adding it.
- Nothing from any existing film or game: no names, designs, lines or music. Invented sign words only.
- Reports: under 300 words in `docs/reports/<id>.md`, each pass check as PASS / FAIL / NOT CHECKED, plus "interfaces changed: none / list". Then stop.
- Keep tests short. Get the information you need and move on.

## Windows notes

- Scripts in `tools/` are shell scripts: run them from **Git Bash**, for example `sh tools/render_looks.sh CX`.
- They were written on a Mac. Until brief F0 in `docs/STATUS.md` is done, expect some to need fixing (paths, the time-limit helper in `gslot.sh`, the `godot` and `blender` command names).
- Rendering pictures needs a real window (Forward+), never `--headless`.
