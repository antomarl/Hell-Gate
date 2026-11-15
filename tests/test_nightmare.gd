extends SceneTree
const Model = preload("res://scripts/game_model.gd")
func _initialize() -> void:
	var wins: int = 0
	var remaining: Array[float] = []
	var recoveries: int = 0
	for seed_value: int in range(1, 301):
		var game = Model.new()
		game.start(2, seed_value)
		var cooling: bool = false
		var bug_read: float = 0
		var decision: float = 0
		var arrow_wait: float = 0
		for frame: int in range(3200):
			if game.state not in ["playing", "recovering"]:
				break
			if game.state == "recovering":
				arrow_wait += 0.05
				if arrow_wait >= 0.4:
					game.recovery_input(game.recovery_sequence[game.recovery_index])
					arrow_wait = 0
				game.update(0.05)
				continue
			if game.bug_active and not game.hidden:
				bug_read += 0.05
			decision -= 0.05
			if decision <= 0:
				decision = 0.3
				if game.heat > 75:
					cooling = true
				if game.heat < 30:
					cooling = false
				var cover: bool = cooling or (game.warning_active and game.warning_grace < 0.4)
				if cover != game.hidden:
					game.toggle_hide()
				if game.bug_active and not game.hidden and bug_read >= 2.0:
					game.answer_bug(game.Bugs.CASES[game.bug_index]["correct"])
					bug_read = 0
				if game.suspicion > 55 and not game.coffee_used:
					game.coffee()
				if game.time_left < 65 and game.patrol.risk() > 0.2 and not game.decoy_used:
					game.distract()
			game.working = not game.hidden and not game.bug_active
			game.update(0.05)
		if game.state == "won":
			wins += 1
			remaining.append(game.time_left)
			recoveries += game.bounce_count
		else:
			print("FAILED seed=%d progress=%.1f reason=%s" % [seed_value, game.progress, game.result_reason])
	remaining.sort()
	print("INCUBO: %d/300 wins; minimum time left %.1f s; median %.1f s; recoveries %d. Decisions every 300 ms, bug reading 2 s, arrows every 400 ms." % [wins, remaining[0] if not remaining.is_empty() else 0, remaining[remaining.size()/2] if not remaining.is_empty() else 0, recoveries])
	quit(0 if wins == 300 else 1)
