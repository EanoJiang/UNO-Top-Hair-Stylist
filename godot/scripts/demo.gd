class_name ControllerDemo
extends Node2D

@onready var _player: UltimatePlayerController = %Player
@onready var _telemetry: Label = %Telemetry

func _process(_delta: float) -> void:
	if _player == null:
		return
	_telemetry.text = "Velocity  %6.2f, %6.2f\nGrounded  %s\nCoyote    %0.3fs\nJump buf  %0.3fs" % [
		_player.velocity.x,
		_player.velocity.y,
		str(_player.is_grounded),
		_player.get_coyote_remaining(),
		_player.get_jump_buffer_remaining(),
	]
