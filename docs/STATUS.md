# Neon Static: status board

Only the orchestrator edits this file. Last updated 2026-11-18.

## Where things stand

- Design (`DESIGN.md` v0.2) and plan (`PLAN.md` v0.2) approved by Nima on 2026-11-18.
- Look chosen: **Acid Cyber** (`godot/looks/CX.gd`, picture `docs/looks/look_CX.png`).
- The only code so far is the look test: a 73-piece model kit, shaders and one street. It ran at about 12 fps on the Mac it was made on.
- The build moves to Nima's Windows PC. Nothing has been built there yet.

## First session on this PC (orchestrator does these, in order)

1. Run `godot --version`, `blender --version`, `python --version`, `git --version`, `ffmpeg -version`. Fix anything missing or not on PATH (install with winget, or add to PATH). Record the versions below.
2. Record the PC's hardware below (CPU, graphics card, memory, screen resolution). The 60 fps target in `DESIGN.md` section 18 was written for a MacBook Pro M4; restate it for this PC.
3. Write brief **F0: Windows port of the tools** for the Foundation chat (Opus): make `tools/gslot.sh`, `tools/render_looks.sh` and the Blender kit build work from Git Bash on Windows; remove the Mac-only time-limit helper; drop the lock-folder name shared with another project; add a Windows export preset. Pass check: `sh tools/render_looks.sh CX` produces `docs/looks/look_CX.png` on this PC, and it looks like the committed one.
4. Write `docs/CONTRACTS.md` (see `PLAN.md` section 4).
5. Then stage A of `PLAN.md`: F1, F2 with G1, G2 alongside.

## This PC

| Item | Value |
|---|---|
| CPU | to be recorded |
| Graphics card | to be recorded |
| Memory | to be recorded |
| Godot / Blender / Python | to be recorded |

## Board

| ID | Work | Lane | State | Files it owns |
|---|---|---|---|---|
| F0 | Windows port of the tools | Foundation | brief not written | `tools/` |
| CON | Contracts page | Orchestrator | not started | `docs/CONTRACTS.md` |
| F1 | Skeleton, settings loader, save registry, loading screen | Foundation | waits for F0, CON | `godot/core/`, `godot/game/` |
| F2 | Dev harness, tests, check script, frame log, app packaging | Foundation | waits for F1 | `godot/dev/`, `godot/tests/`, `tools/` |
| G1 | Acid Cyber at 60 fps, quality levels | Graphics | waits for F0 | `godot/shaders/`, `godot/looks/`, `godot/scripts/` (look test) |
| G2 | Lowgate roads data and grey-box | Graphics | waits for G1, CON | `godot/city/` |

## Waiting on Nima

- Nothing yet. First checkpoint: before/after pictures from G1.

## Open design questions (from DESIGN.md section 21)

1. Should the rival crew cross the line too, and can you film them?
2. Should MERIDIAN broadcast a correction naming you after buying tampered tape?
3. First rent after 7 nights or 5?
