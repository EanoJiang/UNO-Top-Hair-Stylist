# Ultimate 2D Controller · Godot

This repository is a Godot 4 migration of Matthew J. Spencer's Unity Ultimate 2D Controller. The runnable project is `godot/demo.tscn`, and the controller is implemented in typed GDScript with the original movement defaults and timing rules.

The port includes:

- acceleration and ground/air deceleration
- input dead zones and optional snap-to-cardinal input
- coyote-time jumps and buffered jumps
- early jump release gravity
- ceiling protection and capped fall speed
- squash-and-stretch, flip, tilt, dust particles, and landing audio
- a demo scene matching the original ground and platform layout

The source Unity scripts and `.unitypackage` remain in the repository as migration references. They are not loaded by the Godot project.

## Run the Godot demo

From this repository root:

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64.exe' --editor --path .
```

Controls: **A/D** or **Left/Right** to move, **Space/C** to jump.

## Verify the migration

The headless smoke test exercises stats, acceleration, deceleration, jump impulse, gravity, coyote time, and jump buffering:

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://godot/tests/controller_smoke.gd
```

The test prints `CONTROLLER_SMOKE_PASS` and exits successfully when all checks pass.

## Project layout

```text
godot/
├── assets/                 # Extracted player/platform textures and landing audio
├── resources/              # ControllerStats Resource (ScriptableStats port)
├── scenes/platform.tscn    # Reusable static platform
├── scripts/                # Controller, visuals, and demo scripts
├── tests/controller_smoke.gd
├── demo.tscn               # Default runnable scene
└── player.tscn             # Reusable CharacterBody2D player
```

See [`docs/migration.md`](docs/migration.md) for the Unity-to-Godot mapping and implementation notes.

Attribution is welcomed, as requested by the original project. The original license and source remain available in [`LICENSE`](LICENSE), [`Scripts`](Scripts), and [`Tarodev 2D Controller.unitypackage`](Tarodev%202D%20Controller.unitypackage).
