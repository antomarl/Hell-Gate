extends SceneTree
const Model = preload("res://scripts/game_model.gd")
const Patrol = preload("res://scripts/patrol.gd")
var checks: int = 0
var failures: int = 0

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error("FAIL: " + message)
		failures += 1

func _initialize() -> void:
	var game = Model.new()
	game.start(1, 42)
	game.suspicion = 60
	game.coffee()
	game.coffee()
	verify(is_equal_approx(game.suspicion, 30), "Coffee is one-use and subtracts exactly 30")
	game.distract()
	verify(game.patrol.risk() == 0, "Distraction clears current viewing risk")
	game.update(1)
	game.distract()
	verify(game.patrol.distraction_left <= 6.0, "Distraction cannot be refreshed")
	game.start(1, 99)
	game.hidden = true
	game.working = true
	for i: int in range(500):
		game.update(0.05)
	verify(game.progress == 0 and game.suspicion == 0, "Hidden AI cannot generate or raise suspicion")
	game.start(1, 99)
	game.toggle_hide()
	verify(game.hidden and not game.working and game.hide_count == 1, "Tab toggle stops generation")
	var a = Patrol.new()
	var b = Patrol.new()
	a.reset(101)
	b.reset(102)
	for i: int in range(1400):
		a.update(0.05, 0, 1)
		b.update(0.05, 0, 1)
	verify(a.destination_history != b.destination_history, "Different seeds generate different paths")
	verify(a.destination_history.size() > 6, "Patrol keeps moving")
	for point: Vector2 in a.destination_history:
		verify(point.x >= 310 and point.x <= 485 and point.y >= 150 and point.y <= 340, "Patrol stays in aisle")
	var reckless_losses: int = 0
	for seed_value: int in range(1, 31):
		for level: int in range(3):
			game.start(level, seed_value)
			var cooling: bool = false
			var bug_wait: float = 0
			for frame: int in range(5000):
				if game.state not in ["playing", "recovering"]:
					break
				if game.state == "recovering":
					game.recovery_input(game.recovery_sequence[game.recovery_index])
					game.update(0.2)
					continue
				if game.heat > 72:
					cooling = true
				if game.heat < 28:
					cooling = false
				if level == 2 and game.time_left < 65 and game.patrol.risk() > 0.2 and not game.decoy_used:
					game.distract()
				game.hidden = cooling or (game.patrol.risk() > 0.10 and game.warning_grace < 0.25)
				if game.bug_active and not game.hidden:
					bug_wait += 0.05
					if bug_wait > 1.4:
						game.answer_bug(game.Bugs.CASES[game.bug_index]["correct"])
						bug_wait = 0
				game.working = not game.hidden and not game.bug_active
				game.update(0.05)
			verify(game.state == "won", "Careful play wins: seed %d, difficulty %d, progress %.1f, reason %s" % [seed_value, level, game.progress, game.result_reason])
			verify(game.bugs_fixed >= 4, "All four phase bugs must be fixed")
		game.start(1, seed_value)
		for frame: int in range(3500):
			if game.state not in ["playing", "recovering"]:
				break
			game.working = true
			game.update(0.05)
		if game.state == "lost":
			reckless_losses += 1
	verify(reckless_losses >= 24, "Ignoring Richard usually loses (%d/30)" % reckless_losses)
	game.start(1, 42)
	game.time_left = 0.01
	game.update(0.05)
	verify(game.state == "lost" and game.result_reason == "timeout", "Deadline loss works")
	var remaining: float = game.time_left
	game.update(10)
	verify(game.time_left == remaining, "Ended games stop updating")
	game.start(1, 321)
	game.spawn_bug()
	game.progress = 36
	var before_time: float = game.time_left
	var correct: int = game.Bugs.CASES[game.bug_index]["correct"]
	game.answer_bug((correct + 1) % 3)
	verify(game.bug_active and game.time_left == before_time - 5 and game.suspicion == 8, "Wrong fix costs time and suspicion")
	game.hidden = true
	game.answer_bug(correct)
	verify(game.bug_active, "Cannot repair from the innocent tab")
	game.hidden = false
	game.answer_bug(correct)
	verify(not game.bug_active and game.bugs_fixed == 1 and game.boost_left == 6, "Fix earns comeback boost")
	game.progress = 28
	game.heat = 99.9
	game.working = true
	game.update(0.05)
	verify(game.overloads == 1 and game.progress == 25 and game.bug_active, "Overload rolls back only to checkpoint and requires repair")
	game.start(1, 42)
	game.progress = 54
	game.suspicion = 100
	game.begin_recovery()
	verify(game.state == "recovering" and game.bounce_charges == 0, "First discovery opens a limited second chance")
	var seq: Array[int] = game.recovery_sequence.duplicate()
	for direction: int in seq:
		game.recovery_input(direction)
	verify(game.state == "playing" and game.progress == 50 and game.bounce_count == 1 and game.hidden and game.boost_left == 10, "Successful recovery preserves checkpoint, hides AI and grants boost")
	game.begin_recovery()
	verify(game.state == "lost", "Cannot bounce back with exhausted charges")
	game.start(0, 42)
	game.begin_recovery()
	verify(game.bounce_charges == 0, "Easy mode also has exactly one recovery")
	for i: int in range(3):
		game.recovery_input((game.recovery_sequence[game.recovery_index] + 1) % 4)
	verify(game.state == "lost" and game.result_reason == "recovery", "Three wrong arrows end recovery")
	game.start(1, 42)
	game.begin_recovery()
	game.update(12)
	verify(game.state == "lost" and game.result_reason == "recovery", "Recovery expires on its own deadline")
	game.start(1, 42)
	game.time_left = 0.1
	game.begin_recovery()
	game.update(0.2)
	verify(game.state == "lost" and game.result_reason == "timeout", "Demo deadline still runs during recovery")
	for level: int in range(3):
		game.start(level, 91)
		verify(game.bounce_charges == 1, "Every difficulty starts with exactly one recovery")
		game.begin_recovery()
		var inputs: Array[int] = game.recovery_sequence.duplicate()
		for direction: int in inputs:
			game.recovery_input(direction)
		game.begin_recovery()
		verify(game.state == "lost", "Second recovery is impossible at every difficulty")
	game.start(1, 18)
	game.patrol.position = Vector2(388, 315)
	game.patrol.mode = "inspect"
	game.patrol.inspect_left = 20
	for frame: int in range(86):
		game.update(0.05)
	verify(game.state == "recovering", "Watching an open idle tab catches the player within 4.3 seconds")
	print("RESULT: %d checks / %d failures; reckless losses %d/30." % [checks, failures, reckless_losses])
	quit(1 if failures > 0 else 0)
