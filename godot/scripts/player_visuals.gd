class_name PlayerVisuals
extends Node2D

## Visual and feedback companion for UltimatePlayerController.
## This ports the Unity PlayerAnimator responsibilities without coupling
## movement decisions to animation state.

const FOOTSTEPS: Array[AudioStream] = [
	preload("res://godot/assets/splat_1.wav"),
	preload("res://godot/assets/splat_2.wav"),
	preload("res://godot/assets/splat_3.wav"),
]

@export_range(1.0, 3.0, 0.05) var max_idle_speed: float = 2.0
@export var max_tilt_degrees: float = 5.0
@export var tilt_speed_degrees: float = 20.0

@onready var _controller: UltimatePlayerController = get_parent() as UltimatePlayerController
@onready var _sprite: Sprite2D = %Sprite
@onready var _move_particles: CPUParticles2D = %MoveParticles
@onready var _jump_particles: CPUParticles2D = %JumpParticles
@onready var _launch_particles: CPUParticles2D = %LaunchParticles
@onready var _land_particles: CPUParticles2D = %LandParticles
@onready var _footstep_audio: AudioStreamPlayer2D = %FootstepAudio
@onready var _ground_color_ray: RayCast2D = %GroundColorRay

var _scale_tween: Tween
var _ground_color: Color = Color.WHITE
var _sprite_base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	if _controller == null:
		return
	_controller.jumped.connect(_on_jumped)
	_controller.grounded_changed.connect(_on_grounded_changed)
	get_tree().root.tree_exiting.connect(_on_tree_exiting, CONNECT_ONE_SHOT)
	_sprite_base_scale = _sprite.scale
	_move_particles.emitting = true
	_detect_ground_color()

func _exit_tree() -> void:
	_stop_audio()
	if _controller == null:
		return
	if _controller.jumped.is_connected(_on_jumped):
		_controller.jumped.disconnect(_on_jumped)
	if _controller.grounded_changed.is_connected(_on_grounded_changed):
		_controller.grounded_changed.disconnect(_on_grounded_changed)

func _on_tree_exiting() -> void:
	_stop_audio()

func _stop_audio() -> void:
	if _footstep_audio != null and _footstep_audio.playing:
		_footstep_audio.stop()

func _process(delta: float) -> void:
	if _controller == null:
		return
	_detect_ground_color()
	_handle_sprite_flip()
	_handle_idle_speed(delta)
	_handle_character_tilt(delta)

func _handle_sprite_flip() -> void:
	if not is_zero_approx(_controller.frame_input.x):
		_sprite.flip_h = _controller.frame_input.x < 0.0

func _handle_idle_speed(delta: float) -> void:
	var input_strength: float = absf(_controller.frame_input.x)
	var speed_scale: float = lerpf(1.0, max_idle_speed, input_strength)
	_sprite.scale = _sprite_base_scale * Vector2(1.0 + 0.02 * (speed_scale - 1.0), 1.0 - 0.02 * (speed_scale - 1.0))
	_move_particles.scale = _move_particles.scale.move_toward(Vector2.ONE * input_strength, 2.0 * delta)
	_move_particles.color = _ground_color

func _handle_character_tilt(delta: float) -> void:
	var target_tilt: float = 0.0
	if _controller.is_grounded:
		target_tilt = deg_to_rad(max_tilt_degrees * _controller.frame_input.x)
	rotation = move_toward(rotation, target_tilt, deg_to_rad(tilt_speed_degrees) * delta)

func _on_jumped() -> void:
	_play_scale_tween(Vector2(1.35, 0.67), 0.2167)
	if _controller.last_jump_was_grounded:
		_jump_particles.emitting = true
		_launch_particles.emitting = true

func _on_grounded_changed(grounded: bool, impact: float) -> void:
	if grounded:
		_play_scale_tween(Vector2(1.44, 0.60), 0.3333)
		_land_particles.scale = Vector2.ONE * clampf(remap(0.0, 40.0, 0.0, 1.0, impact), 0.0, 1.0)
		_land_particles.emitting = true
		_move_particles.emitting = true
		if DisplayServer.get_name() != "headless":
			_footstep_audio.stream = FOOTSTEPS[randi() % FOOTSTEPS.size()]
			_footstep_audio.play()
	else:
		_move_particles.emitting = false

func _play_scale_tween(first_scale: Vector2, duration: float) -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", first_scale, duration * 0.5)
	_scale_tween.tween_property(self, "scale", Vector2.ONE, duration * 0.5)

func _detect_ground_color() -> void:
	_ground_color_ray.force_raycast_update()
	if not _ground_color_ray.is_colliding():
		return
	var collider: Object = _ground_color_ray.get_collider()
	if collider is CanvasItem:
		_ground_color = (collider as CanvasItem).modulate * 0.9
