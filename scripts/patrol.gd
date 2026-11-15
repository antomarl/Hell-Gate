class_name RichardPatrol
extends RefCounted

var rng := RandomNumberGenerator.new()
var position := Vector2(425, 155)
var target := Vector2(425, 155)
var facing := Vector2.DOWN
var mode: String = "wait"
var wait_left: float = 4.5
var speed: float = 53.0
var inspect_left: float = 0.0
var distraction_left: float = 0.0
var inspection_cooldown: float = 0.0
var retreat_next: bool = false
var visits: int = 0
var destination_history: Array[Vector2] = []
var points: Array[Vector2] = [Vector2(335, 158), Vector2(465, 162), Vector2(365, 218), Vector2(460, 245), Vector2(325, 293), Vector2(470, 317), Vector2(385, 335), Vector2(410, 195)]

func reset(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	position = Vector2(425, 155)
	target = position
	facing = Vector2.DOWN
	mode = "wait"
	wait_left = 4.5
	inspect_left = 0.0
	distraction_left = 0.0
	inspection_cooldown = 0.0
	retreat_next = false
	visits = 0
	destination_history.clear()

func update(delta: float, suspicion: float, difficulty: int) -> String:
	var event: String = ""
	inspection_cooldown = maxf(0.0, inspection_cooldown - delta)
	if distraction_left > 0.0:
		distraction_left -= delta
		position = position.move_toward(Vector2(475, 150), delta * 100.0)
		facing = Vector2.UP
		mode = "distracted"
		if distraction_left <= 0.0:
			mode = "wait"
			wait_left = 1.0
		return event
	if mode == "inspect":
		inspect_left -= delta
		facing = (Vector2(388, 382) - position).normalized()
		if inspect_left <= 0.0:
			mode = "wait"
			retreat_next = true
			inspection_cooldown = 8.0
			wait_left = rng.randf_range(0.6, 1.2)
			event = "safe" if suspicion < 45.0 else "suspicious"
	elif mode == "walk":
		var old: Vector2 = position
		position = position.move_toward(target, speed * delta)
		if position.distance_to(old) > 0.01:
			facing = (position - old).normalized()
		if position.distance_to(target) < 1.0:
			visits += 1
			if position.y > 265 and inspection_cooldown <= 0.0:
				mode = "inspect"
				inspect_left = rng.randf_range(2.2, 3.9)
				inspection_cooldown = 6.0
				event = "approach"
			else:
				mode = "wait"
				wait_left = rng.randf_range(0.7, 2.6)
	else:
		wait_left -= delta
		if wait_left <= 0.0:
			pick_destination(suspicion, difficulty)
	return event

func pick_destination(suspicion: float, difficulty: int) -> void:
	var candidates: Array[Vector2] = []
	for point: Vector2 in points:
		if point.distance_to(position) > 65.0:
			candidates.append(point)
	var check_chance: float = 0.24 + float(difficulty) * 0.08 + suspicion * 0.002
	if retreat_next:
		target = Vector2(rng.randf_range(325, 465), rng.randf_range(150, 188))
		retreat_next = false
	elif rng.randf() < check_chance and inspection_cooldown <= 0.0:
		target = Vector2(rng.randf_range(340, 430), rng.randf_range(300, 338))
	else:
		target = candidates[rng.randi_range(0, candidates.size() - 1)]
	# Small offsets and varying speeds avoid identical waypoint loops.
	target += Vector2(rng.randf_range(-13, 13), rng.randf_range(-9, 9))
	target.x = clampf(target.x, 310, 485)
	target.y = clampf(target.y, 150, 340)
	speed = rng.randf_range(43, 69) + float(difficulty) * 5.0
	mode = "walk"
	destination_history.append(target)

func risk() -> float:
	if distraction_left > 0.0:
		return 0.0
	var offset: Vector2 = Vector2(388, 382) - position
	var distance: float = offset.length()
	if distance > 188.0:
		return 0.0
	var looking: float = facing.dot(offset.normalized())
	if looking < 0.25 and mode != "inspect":
		return 0.0
	return clampf((188.0 - distance) / 110.0, 0.0, 1.0)

func distract() -> void:
	distraction_left = 7.0
	mode = "distracted"
