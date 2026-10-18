extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://godot/player.tscn")

var _failures: Array[String] = []
var _world: Node2D

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_world = Node2D.new()
	_world.name = "SmokeWorld"
	root.add_child(_world)
	var floor_body: StaticBody2D = _make_platform(Vector2(0, 3.5), Vector2(20, 1.0))
	_world.add_child(floor_body)
	var lower_floor: StaticBody2D = _make_platform(Vector2(0, 10.0), Vector2(50, 1.0))
	_world.add_child(lower_floor)

	var player: UltimatePlayerController = PLAYER_SCENE.instantiate() as UltimatePlayerController
	player.position = Vector2(0, 0)
	_world.add_child(player)
	var player_sprite: Sprite2D = player.get_node("Visual/Sprite") as Sprite2D
	_check(player_sprite.scale.x < 0.01, "player texture keeps its world-unit scale")

	var stats: ControllerStats = player.stats
	_check(is_equal_approx(stats.max_speed, 14.0), "stats max_speed is 14")
	_check(is_equal_approx(stats.acceleration, 120.0), "stats acceleration is 120")
	_check(is_equal_approx(stats.coyote_time, 0.15), "stats coyote_time is 0.15")
	_check(is_equal_approx(stats.jump_buffer, 0.2), "stats jump_buffer is 0.2")

	await _wait_physics(45)
	_check(player.is_grounded, "player lands on the platform")

	Input.action_press("move_right")
	await _wait_physics(15)
	Input.action_release("move_right")
	_check(player.velocity.x > 0.0, "right input accelerates the player")
	_check(player.velocity.x <= stats.max_speed + 0.01, "horizontal speed is capped")
	await _wait_physics(45)
	_check(absf(player.velocity.x) < 0.01, "ground deceleration stops the player")

	Input.action_press("jump")
	await _wait_physics(3)
	Input.action_release("jump")
	_check(player.velocity.y < 0.0, "jump applies upward velocity")
	await _wait_physics(8)
	_check(player.velocity.y > -10.0, "early jump release applies stronger gravity")
	_check(player.velocity.y <= stats.max_fall_speed + 0.01, "fall speed stays within the configured cap")

	await _wait_physics(80)
	_check(player.is_grounded, "player lands after a jump")

	Input.action_press("move_right")
	var left_ground: bool = false
	for _frame: int in range(60):
		await _wait_physics(1)
		if not player.is_grounded:
			left_ground = true
			break
	Input.action_release("move_right")
	_check(left_ground, "player can leave the platform")

	if left_ground:
		await _wait_physics(2)
		Input.action_press("jump")
		await _wait_physics(3)
		Input.action_release("jump")
		_check(player.velocity.y < 0.0, "coyote jump works after leaving the ledge")

	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	var buffer_player: UltimatePlayerController = PLAYER_SCENE.instantiate() as UltimatePlayerController
	buffer_player.position = Vector2(0, 0)
	_world.add_child(buffer_player)
	await _wait_physics(45)
	Input.action_press("move_right")
	var buffer_left_ground: bool = false
	for _frame: int in range(90):
		await _wait_physics(1)
		if not buffer_player.is_grounded:
			buffer_left_ground = true
			break
	Input.action_release("move_right")
	if buffer_left_ground:
		for _frame: int in range(30):
			await _wait_physics(1)
			if buffer_player.get_coyote_remaining() <= 0.0:
				break
		for _frame: int in range(120):
			await _wait_physics(1)
			if buffer_player.position.y >= 7.0 or buffer_player.is_grounded:
				break
		if buffer_player.position.y < 7.0 or buffer_player.is_grounded:
			_check(false, "buffer test player reaches the lower landing")
		else:
			buffer_player.last_jump_was_grounded = false
			Input.action_press("jump")
			await _wait_physics(30)
			Input.action_release("jump")
			_check(buffer_player.last_jump_was_grounded, "jump buffer triggers on landing")
	else:
		_check(false, "buffer test player can leave the platform")

	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	for audio_node: Node in _world.find_children("*", "AudioStreamPlayer2D", true, false):
		(audio_node as AudioStreamPlayer2D).stop()
	_world.queue_free()
	await process_frame
	if _failures.is_empty():
		print("CONTROLLER_SMOKE_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		print("CONTROLLER_SMOKE_FAIL count=%d" % _failures.size())
		quit(1)

func _make_platform(position: Vector2, size: Vector2) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = position
	body.collision_layer = 1
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	return body

func _wait_physics(frames: int) -> void:
	for _frame: int in range(frames):
		await process_frame
		await physics_frame

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
