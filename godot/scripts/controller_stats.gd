class_name ControllerStats
extends Resource

## Tunable data ported from Unity's ScriptableStats asset.
## The original Unity controller uses +Y as up. Godot uses +Y down, so the
## controller maps jump_power to a negative velocity and the fall values to
## positive velocity internally.

@export_group("Collision")
@export var ground_collision_mask: int = 1
@export_range(0.0, 0.5, 0.001) var grounder_distance: float = 0.05

@export_group("Input")
@export var snap_input: bool = true
@export_range(0.01, 0.99, 0.01) var vertical_dead_zone_threshold: float = 0.3
@export_range(0.01, 0.99, 0.01) var horizontal_dead_zone_threshold: float = 0.1

@export_group("Movement")
@export var max_speed: float = 14.0
@export var acceleration: float = 120.0
@export var ground_deceleration: float = 60.0
@export var air_deceleration: float = 30.0
@export_range(0.0, 10.0, 0.1) var grounding_force: float = 1.5

@export_group("Jump")
@export var jump_power: float = 36.0
@export var max_fall_speed: float = 40.0
@export var fall_acceleration: float = 110.0
@export var jump_end_early_gravity_modifier: float = 3.0
@export var coyote_time: float = 0.15
@export var jump_buffer: float = 0.2
