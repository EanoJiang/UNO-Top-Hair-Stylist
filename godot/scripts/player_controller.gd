class_name UltimatePlayerController
extends CharacterBody2D

## Godot port of Tarodev's original Unity PlayerController.
##
## Input is sampled in _process so a short jump press is not lost between
## physics ticks. Movement is calculated in _physics_process with the same
## ordering as the Unity version: collision state, jump, direction, gravity,
## then movement.

signal grounded_changed(grounded: bool, impact: float)
signal jumped

@export var stats: ControllerStats

var frame_input: Vector2 = Vector2.ZERO
var jump_held: bool = false
var jump_down: bool = false

var is_grounded: bool = false
var last_grounded_impact: float = 0.0
var last_jump_was_grounded: bool = false

var _time: float = 0.0
var _jump_to_consume: bool = false
var _buffered_jump_usable: bool = false
var _ended_jump_early: bool = false
var _coyote_usable: bool = false
var _time_jump_was_pressed: float = 0.0
var _frame_left_grounded: float = -INF
var _pre_move_vertical_velocity: float = 0.0
var _previous_jump_held: bool = false

@onready var _ground_cast: ShapeCast2D = %GroundCast
@onready var _ceiling_cast: ShapeCast2D = %CeilingCast

func _ready() -> void:
	if stats == null:
		stats = ControllerStats.new()
	collision_mask = stats.ground_collision_mask
	floor_snap_length = 0.0
	floor_stop_on_slope = true
	up_direction = Vector2.UP
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED

func _process(delta: float) -> void:
	_time += delta
	_gather_input()

func _gather_input() -> void:
	var raw_input: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if stats.snap_input:
		raw_input.x = 0.0 if absf(raw_input.x) < stats.horizontal_dead_zone_threshold else signf(raw_input.x)
		raw_input.y = 0.0 if absf(raw_input.y) < stats.vertical_dead_zone_threshold else signf(raw_input.y)
	frame_input = raw_input

	jump_held = Input.is_action_pressed("jump")
	# is_action_just_pressed is event-buffer based. The explicit edge check also
	# handles programmatic Input.action_press calls and devices that only report
	# their held state.
	jump_down = Input.is_action_just_pressed("jump") or (jump_held and not _previous_jump_held)
	_previous_jump_held = jump_held
	if jump_down:
		_jump_to_consume = true
		_time_jump_was_pressed = _time

func _physics_process(delta: float) -> void:
	_update_grounded_state_before_move()
	_handle_jump()
	_handle_direction(delta)
	_handle_gravity(delta)
	_pre_move_vertical_velocity = velocity.y
	if _ceiling_cast.is_colliding():
		velocity.y = maxf(0.0, velocity.y)
	move_and_slide()

func _update_grounded_state_before_move() -> void:
	_ground_cast.force_shapecast_update()
	_ceiling_cast.force_shapecast_update()
	var ground_hit: bool = _ground_cast.is_colliding() or is_on_floor()
	_set_grounded_state(ground_hit, absf(_pre_move_vertical_velocity))

func _set_grounded_state(ground_hit: bool, impact: float) -> void:
	if ground_hit == is_grounded:
		return
	if ground_hit:
		is_grounded = true
		_coyote_usable = true
		_buffered_jump_usable = true
		_ended_jump_early = false
		last_grounded_impact = impact
		grounded_changed.emit(true, impact)
	else:
		is_grounded = false
		_frame_left_grounded = _time
		grounded_changed.emit(false, 0.0)

func _has_buffered_jump() -> bool:
	return _buffered_jump_usable and _time < _time_jump_was_pressed + stats.jump_buffer

func _can_use_coyote() -> bool:
	return _coyote_usable and not is_grounded and _time < _frame_left_grounded + stats.coyote_time

func _handle_jump() -> void:
	# Godot's Y axis points down, so upward motion has a negative velocity.
	if not _ended_jump_early and not is_grounded and not jump_held and velocity.y < 0.0:
		_ended_jump_early = true

	if not _jump_to_consume and not _has_buffered_jump():
		return
	if is_grounded or _can_use_coyote():
		_execute_jump()
	_jump_to_consume = false

func _execute_jump() -> void:
	last_jump_was_grounded = is_grounded
	_ended_jump_early = false
	_time_jump_was_pressed = 0.0
	_buffered_jump_usable = false
	_coyote_usable = false
	velocity.y = -stats.jump_power
	jumped.emit()

func _handle_direction(delta: float) -> void:
	if is_zero_approx(frame_input.x):
		var deceleration: float = stats.ground_deceleration if is_grounded else stats.air_deceleration
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, frame_input.x * stats.max_speed, stats.acceleration * delta)

func _handle_gravity(delta: float) -> void:
	if is_grounded and velocity.y >= 0.0:
		velocity.y = stats.grounding_force
		return
	var in_air_gravity: float = stats.fall_acceleration
	if _ended_jump_early and velocity.y < 0.0:
		in_air_gravity *= stats.jump_end_early_gravity_modifier
	velocity.y = move_toward(velocity.y, stats.max_fall_speed, in_air_gravity * delta)

func get_frame_input() -> Vector2:
	return frame_input

func get_jump_buffer_remaining() -> float:
	if not _buffered_jump_usable:
		return 0.0
	return maxf(0.0, _time_jump_was_pressed + stats.jump_buffer - _time)

func get_coyote_remaining() -> float:
	if not _coyote_usable or is_grounded:
		return 0.0
	return maxf(0.0, _frame_left_grounded + stats.coyote_time - _time)
