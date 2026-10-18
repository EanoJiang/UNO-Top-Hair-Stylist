# Unity to Godot migration notes

The migration follows the behavior in the checked-in Unity scripts, rather than the optional Patreon extended controller. The original README mentions speedy apex and anti-gravity apex, but those features are not present in this repository's `PlayerController.cs`; the port therefore keeps the implemented behavior exact.

## Runtime mapping

| Unity | Godot |
| --- | --- |
| `ScriptableStats : ScriptableObject` | `ControllerStats : Resource` in `godot/resources/controller_stats.tres` |
| `Rigidbody2D` with gravity disabled | `CharacterBody2D` with project gravity set to `0` |
| `CapsuleCollider2D` | `CollisionShape2D` with `CapsuleShape2D` |
| `Physics2D.CapsuleCast` ground/ceiling probes | thin `ShapeCast2D` probes at the collider bottom/top |
| `Input.GetAxisRaw` and `GetButton` | typed GDScript input sampling with `Input.get_axis` and explicit edge detection |
| `Mathf.MoveTowards` | `move_toward` |
| `GroundedChanged(bool, float)` | `grounded_changed(grounded: bool, impact: float)` |
| `Jumped` event | `jumped` signal |
| `Animator` triggers and curves | typed visual signal handlers and squash-and-stretch tweens |
| `ParticleSystem` | `CPUParticles2D` |
| `AudioSource.PlayOneShot` | `AudioStreamPlayer2D` with the three extracted Splat clips |

## Timing and coordinate conversion

Unity's controller uses +Y as up. Godot uses +Y down, so `jump_power` is applied as a negative Y velocity, while the positive fall and grounding values move toward `+max_fall_speed` and `+grounding_force`. Input time is accumulated in `_process()` and movement is applied in `_physics_process()` so buffered and coyote windows are measured in real elapsed time like the source.

The physics order remains collision state → jump → horizontal direction → gravity → movement. The controller deliberately keeps the grounded state until the next collision probe after a jump, matching Unity's pre-movement cast timing.

## Original defaults

`max_speed=14`, `acceleration=120`, `ground_deceleration=60`, `air_deceleration=30`, `grounding_force=1.5` (mapped from Unity `-1.5`), `jump_power=36`, `max_fall_speed=40`, `fall_acceleration=110`, `jump_end_early_gravity_modifier=3`, `coyote_time=0.15`, and `jump_buffer=0.2`.

The Unity package's serialized asset uses older `CoyoteFrames` and `JumpBufferFrames` names, so the current C# source values are the authoritative source for the migrated resource.

## Verification

Run `godot/tests/controller_smoke.gd` in headless mode. It validates the defaults, landing, acceleration, stopping, jump gravity, coyote jumping, and buffered landing jumps. The demo's telemetry label exposes velocity and the remaining coyote/buffer windows for manual inspection.
