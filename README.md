# Neon Static

A first-person game about a freelance night news cameraman in a rainy cyberpunk city. You chase police-scanner calls, film robberies and pursuits through an old camcorder, and sell the tape to whichever station pays most. Built in Godot 4.7.

This repository is the whole project: design, plan, the look test and (as it gets built) the game.

- `docs/DESIGN.md`: the rules of the game
- `docs/PLAN.md`: Milestone 1, the chats and the build order
- `docs/STATUS.md`: the board: what is done, in progress and waiting
- `docs/looks/`: the look-test pictures. The chosen look is **Acid Cyber** (`look_CX.png`)
- `godot/`: the Godot project
- `tools/`: scripts that build models, render pictures and run checks

## Setting up on a Windows PC

You need a PC with a dedicated graphics card and Windows 10 or 11. Everything below is free.

### 1. Install the tools

Open **PowerShell** (press Start, type "PowerShell", press Enter) and run these one at a time. Each asks you to agree once.

```powershell
winget install --id Git.Git -e
```

```powershell
winget install --id GodotEngine.GodotEngine -e
```

```powershell
winget install --id BlenderFoundation.Blender -e
```

```powershell
winget install --id Python.Python.3.13 -e
```

```powershell
winget install --id GitHub.cli -e
```

```powershell
winget install --id Gyan.FFmpeg -e
```

| Tool | What it is for | Version |
|---|---|---|
| Git for Windows | Downloads the project and saves progress. Includes "Git Bash", which runs the project's scripts. | any recent |
| Godot Engine | The game engine. Use the **standard** build, not the ".NET" one. | 4.7.x (project was started on 4.7.2) |
| Blender | Builds the 3D models from scripts in `tools/blender`. | 5.3 or newer |
| Python | Runs small helper scripts (picture sheets, textures). | 3.12 or newer |
| GitHub CLI | Lets you sign in to GitHub once so this private repo can be downloaded. | any recent |
| FFmpeg | Turns test recordings into short clips. | any recent |
| Claude desktop app | Where the build chats run. Download from https://claude.com/download and sign in. | latest |

If `winget` gives you a Godot version other than 4.7.x, download 4.7.2 from https://godotengine.org/download/archive/ instead and unzip it to `C:\Godot`.

Close PowerShell and open it again so the new tools are found. Then install the one Python add-on:

```powershell
python -m pip install pillow
```

### 2. Sign in to GitHub and download the project

```powershell
gh auth login
```

Choose GitHub.com, HTTPS, and "Login with a web browser". Then:

```powershell
cd $HOME\Documents
```

```powershell
gh repo clone nimammovahedi-del/neon-static
```

The project is now in `Documents\neon-static`.

### 3. Check the tools are found

```powershell
godot --version
```

```powershell
blender --version
```

```powershell
git --version
```

Each should print a version number. If `godot` or `blender` says "not recognized", that tool is installed but Windows cannot find it by name. Tell the first Claude chat "godot is not on PATH" and it will fix it for you.

### 4. Open the project once in Godot

Start Godot, click **Import**, choose `Documents\neon-static\godot\project.godot`, and open it. Wait until the progress bar at the bottom finishes (it is preparing the models), then close Godot. This only needs doing once.

### 5. Start the first chat

Open the Claude desktop app, go to the **Code** tab, choose the folder `Documents\neon-static`, pick the model **Fable** and paste this:

> Read CLAUDE.md, docs/PLAN.md and docs/STATUS.md. You are the orchestrator. This is the first session on the Windows PC: do the "First session on this PC" steps in docs/STATUS.md, then carry on with the plan.

From then on, every chat in this folder reads `CLAUDE.md` and knows the rules.

## Working across two computers

The project lives on GitHub. Whichever computer did work last must **push**; the other must **pull** before starting. The orchestrator chat does both for you when asked ("push the project" / "pull the latest").

## Licence and originality

All models, shaders and code in this repository were made for this project. Any outside file must be listed in `docs/ASSETS.md` with its source and licence before it is added. Nothing here is taken from any existing film or game.
