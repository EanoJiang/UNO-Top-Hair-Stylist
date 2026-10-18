# Ultimate 2D Controller Godot Migration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the Unity Ultimate 2D Controller sample into a self-contained Godot 4 project with equivalent movement, coyote-time and jump-buffer behavior, plus a runnable demo.

**Architecture:** Use a `CharacterBody2D` controller with a typed `ControllerStats` resource and a separate visual/feedback component. Keep input gathering in `_process()` and deterministic movement in `_physics_process()`. Build the demo from reusable player, platform, and camera scenes so the controller can be dropped into another project.

**Tech Stack:** Godot 4.7.2, GDScript 2.0, `CharacterBody2D`, `CollisionShape2D`, `AnimatedSprite2D`, `GPUParticles2D`, `AudioStreamPlayer2D`, and headless smoke tests.

**Spec:** Unity source in `Scripts/PlayerController.cs`, `Scripts/ScriptableStats.cs`, `Scripts/PlayerAnimator.cs`, and `Tarodev 2D Controller.unitypackage`.

## Global Constraints

- Preserve the Unity defaults: max speed 14, acceleration 120, ground deceleration 60, air deceleration 30, grounding force -1.5, jump power 36, max fall speed 40, fall acceleration 110, early-jump gravity multiplier 3, coyote time 0.15 s, jump buffer 0.2 s.
- Use typed GDScript and modern Godot 4 APIs (`CharacterBody2D.velocity`, `move_and_slide()`, `await`, typed signals).
- Keep the Godot project runnable from the repository root and make the demo the default scene.
- Preserve original Unity source/package as reference material; runtime behavior must come from Godot files.

---

### Task 1: Create the Godot project skeleton

**Files:**
- Create: `project.godot`
- Create: `godot/` asset and scene directories
- Create: `docs/migration.md`
- Modify: `README.md`

- [x] Add project settings, input actions (`move_left`, `move_right`, `move_up`, `move_down`, `jump`), display settings, physics tick, and `run/main_scene`.
- [x] Document the Unity-to-Godot mapping and how to run the demo.

### Task 2: Port stats and controller behavior

**Files:**
- Create: `godot/scripts/controller_stats.gd`
- Create: `godot/scripts/player_controller.gd`
- Create: `godot/player.tscn`
- Create: `godot/resources/controller_stats.tres`

- [x] Implement dead-zone snapping and jump edge/held input capture.
- [x] Implement capsule-equivalent floor/ceiling checks through `CharacterBody2D` floor state, coyote time, buffered jumps, early release gravity, acceleration, deceleration, and movement.
- [x] Emit `grounded_changed` and `jumped` signals with typed payloads.
- [x] Expose controller telemetry needed by tests and visual feedback.

### Task 3: Port animation and feedback

**Files:**
- Create: `godot/scripts/player_visuals.gd`
- Create or modify: `godot/player.tscn`
- Copy: `godot/assets/player.png`, `godot/assets/circle.png`, `godot/assets/splat_*.wav`

- [x] Reproduce idle/run speed, horizontal flip, grounded tilt, jump/land squash-and-stretch, dust particles, and landing/footstep audio with Godot nodes.
- [x] Keep visuals independent of movement logic and subscribe to controller signals.

### Task 4: Build the demo scene

**Files:**
- Create: `godot/scripts/demo.gd`
- Create: `godot/demo.tscn`
- Create: `godot/scenes/platform.tscn`

- [x] Recreate the original demo layout with ground and colored platforms.
- [x] Add a camera, controls overlay, and live controller telemetry so behavior is inspectable.

### Task 5: Add headless behavioral verification

**Files:**
- Create: `godot/tests/controller_smoke.gd`

- [x] Verify stats defaults, horizontal acceleration/deceleration, gravity cap, jump impulse, early-release gravity, coyote jump, and buffered jump from the headless script runner.
- [x] Run the project in headless mode and fail with a non-zero exit code on any assertion failure.

### Task 6: Review and finish migration documentation

- [x] Run Godot import and headless smoke tests.
- [x] Search the runnable Godot project for Unity-only APIs and unresolved resource paths.
- [x] Update README with exact commands, controls, limitations, and migration provenance.
