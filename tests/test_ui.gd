extends SceneTree
var game: Node
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.audio_enabled = false
	await process_frame
	check(game.screen == "menu" and game.buttons.has("start"), "Main menu")
	for name: String in ["controls", "options"]:
		game.show_screen(name)
		await process_frame
		check(game.buttons.has("back"), "Back button in " + name)
	game.start_game()
	await process_frame
	check(game.buttons.has("work") and game.buttons.has("hide"), "In-game controls")
	for code: int in [KEY_1, KEY_2, KEY_3, KEY_KP_1, KEY_KP_2, KEY_KP_3]:
		var choice: int = [KEY_1, KEY_2, KEY_3, KEY_KP_1, KEY_KP_2, KEY_KP_3].find(code) % 3
		game.model.hidden = false
		game.model.suspicion = 0
		game.model.bug_active = true
		game.model.bug_index = choice
		var fixed_before: int = game.model.bugs_fixed
		var key := InputEventKey.new()
		key.keycode = code
		key.pressed = true
		Input.parse_input_event(key)
		await process_frame
		check(game.model.bugs_fixed == fixed_before + 1, "Number key dispatch: %d" % code)
		key.pressed = false
		Input.parse_input_event(key)
	game.model.bug_active = true
	game.model.bug_index = 0
	var physical := InputEventKey.new()
	physical.physical_keycode = KEY_1
	physical.pressed = true
	Input.parse_input_event(physical)
	await process_frame
	check(not game.model.bug_active, "Physical digit fallback")
	physical.pressed = false
	Input.parse_input_event(physical)
	game.model.progress = 19
	game.model.tokens = 666
	await process_frame
	game.switch_tab()
	await process_frame
	check(game.model.hidden, "Switch to documentation")
	game.switch_tab()
	game.model.spawn_bug()
	await process_frame
	check(game.buttons["fix0"].visible and game.buttons["work"].disabled, "Bug choices replace generation")
	game.answer_bug(game.model.Bugs.CASES[game.model.bug_index]["correct"])
	await process_frame
	check(not game.buttons["fix0"].visible and game.model.boost_left > 0, "Correct fix restores generation and boost")
	game.model.begin_recovery()
	await process_frame
	await process_frame
	check(game.screen == "recovery" and game.buttons.has("arrow0"), "Bounce Back overlay has usable arrow controls")
	game.pause_game()
	var recovery_before: float = game.model.recovery_left
	await process_frame
	check(game.model.recovery_left == recovery_before, "Pause freezes recovery countdown")
	game.resume_game()
	await process_frame
	check(game.screen == "recovery", "Resume restores recovery instead of skipping it")
	var arrows: Array[int] = game.model.recovery_sequence.duplicate()
	for direction: int in arrows:
		game.recovery_input(direction)
	await process_frame
	await process_frame
	check(game.screen == "playing" and game.model.hidden, "Successful bounce returns to a safe tab")
	game.pause_game()
	var before: float = game.model.time_left
	await process_frame
	check(game.model.time_left == before, "Pause freezes countdown")
	game.return_screen = "paused"
	game.show_screen("options")
	await process_frame
	game.show_screen("paused")
	await process_frame
	game.show_screen("playing")
	game.model.finish(true, "shipped")
	await process_frame
	await process_frame
	check(game.screen == "result" and game.buttons.has("retry"), "Win screen")
	game.start_game()
	game.model.finish(false, "caught")
	await process_frame
	await process_frame
	check(game.screen == "result", "Caught screen")
	game.start_game()
	game.model.finish(false, "timeout")
	await process_frame
	await process_frame
	check(game.screen == "result", "Deadline screen")
	print("UI RESULT: menus, bug controls, paused recovery, successful bounce and endings; %d failures" % failures)
	game.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
