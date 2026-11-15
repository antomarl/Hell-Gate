class_name HellGateModel
extends RefCounted

const PatrolScript = preload("res://scripts/patrol.gd")
const Bugs = preload("res://scripts/bugs.gd")
const Dialogue = preload("res://scripts/dialogue.gd")
const STAGES = ["IDEA", "CODICE", "DEBUG", "CONSEGNA"]
const PROMPTS = [
	"Inventami un gioco stealth all'Haven.\nTema: Bounce Back. Cadi, impara, riparti.",
	"Scrivi il gioco in GDScript. Aggiungi\nun organizzatore che ci tenga d'occhio.",
	"Richard attraversa i tavoli. Risolvi il bug.\nE no, non cancellare l'organizzatore.",
	"Ultimo controllo. Aggiungi il menu,\nesporta la build e fai partire la demo."]
const REPLIES = [
	"Certamente! Ecco un'idea originale:\n\nUn hackathon ad Acireale. Tu, un laptop,\nun'IA molto disponibile. Richard passa\ntra i tavoli. Finisci prima della demo.\n\n> Tema: Bounce Back / rialzarsi\n> Checkpoint: salva, sbaglia, riparti\n> Boss finale: 'avete fatto tutto voi?'\n\nPreparo la struttura del progetto...",
	"Creo il progetto Godot 4...\n\nextends Node2D\n\nvar sospetto := 0.0\nvar tab_aperto := true\n\nfunc _process(delta):\n    if richard.guarda() and tab_aperto:\n        sospetto += 32.0 * delta\n    aggiorna_pixel()\n\n# TODO: sembrare impegnati\n# Non dimenticare il cambio di tab!\n\nScene generate: aula, laptop, Richard.",
	"Analizzo il problema...\n\n[!] Richard ignora la fisica dei tavoli.\n[OK] Aggiunti punti nel corridoio.\n[OK] Percorsi casuali a ogni partita.\n[OK] Pausa prima delle ispezioni.\n\nfunc nascondi_ia():\n    tab_aperto = false\n    mostra_documentazione()\n\nTest di regressione: superati.\nLa scusa 'era Stack Overflow' è pronta.",
	"Controllo finale della demo...\n\n[OK] Menu e comandi\n[OK] Dialoghi di Richard\n[OK] Pattuglie imprevedibili\n[OK] Audio, particelle, pixel\n[OK] Nessun tab sospetto visibile*\n\nEsportazione in corso...\n████████████████████████\n\n* La responsabilità del tab è vostra.\n\nHell gate è pronto per essere consegnato!"]
var patrol = PatrolScript.new()
var rng := RandomNumberGenerator.new()
var state: String = "idle"
var difficulty: int = 1
var progress: float = 0.0
var suspicion: float = 0.0
var time_left: float = 150.0
var elapsed: float = 0.0
var ai_time: float = 0.0
var hidden: bool = false
var working: bool = false
var coffee_used: bool = false
var decoy_used: bool = false
var warning_grace: float = 0.8
var warning_active: bool = false
var dialogue: String = ""
var speaker: String = "RICHARD"
var dialogue_left: float = 0.0
var chatter_left: float = 5.0
var stage_notice: float = 0.0
var hide_count: int = 0
var score: int = 0
var last_line: String = ""
var result_reason: String = ""
var tokens: int = 0
var heat: float = 0.0
var bug_active: bool = false
var bug_index: int = -1
var bug_gates: Array[bool] = [false, false, false, false]
var bugs_fixed: int = 0
var bug_errors: int = 0
var bug_history: Array[int] = []
var overloads: int = 0
var bounce_charges: int = 1
var bounce_count: int = 0
var boost_left: float = 0.0
var recovery_left: float = 0.0
var recovery_sequence: Array[int] = []
var recovery_index: int = 0
var recovery_errors: int = 0
var feedback: String = ""
var feedback_left: float = 0.0

func start(level: int = 1, seed_value: int = 0) -> void:
	difficulty = clampi(level, 0, 2)
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value + 100
	patrol.reset(seed_value)
	state = "playing"
	progress = 0
	suspicion = 0
	time_left = [200.0, 175.0, 145.0][difficulty]
	elapsed = 0
	ai_time = 0
	hidden = false
	working = false
	coffee_used = false
	decoy_used = false
	warning_grace = 0.8
	warning_active = false
	dialogue_left = 0
	chatter_left = 5
	stage_notice = 0
	hide_count = 0
	score = 0
	tokens = 0
	result_reason = ""
	heat = 0
	bug_active = false
	bug_index = -1
	bug_gates = [false, false, false, false]
	bugs_fixed = 0
	bug_errors = 0
	bug_history.clear()
	overloads = 0
	bounce_charges = 1
	bounce_count = 0
	boost_left = 0
	recovery_left = 0
	recovery_sequence.clear()
	recovery_index = 0
	recovery_errors = 0
	feedback = ""
	feedback_left = 0
	say("Tra poco si presenta. A che punto siete?", 4.0)

func stage() -> int:
	return mini(3, int(progress / 25.0))

func phase_progress() -> float:
	return clampf((progress - float(stage()) * 25.0) / 25.0, 0, 1)

func response() -> String:
	var full: String = REPLIES[stage()]
	return full.substr(0, int(phase_progress() * full.length()))

func update(delta: float) -> void:
	if state == "recovering":
		elapsed += delta
		time_left = maxf(0, time_left - delta)
		recovery_left = maxf(0, recovery_left - delta)
		if time_left <= 0:
			finish(false, "timeout")
		elif recovery_left <= 0:
			finish(false, "recovery")
		return
	if state != "playing":
		return
	elapsed += delta
	time_left = maxf(0.0, time_left - delta)
	dialogue_left = maxf(0.0, dialogue_left - delta)
	stage_notice = maxf(0.0, stage_notice - delta)
	boost_left = maxf(0, boost_left - delta)
	feedback_left = maxf(0, feedback_left - delta)
	var event: String = patrol.update(delta, suspicion, difficulty)
	if not event.is_empty():
		if event == "approach":
			say_random(Dialogue.APPROACH)
		elif event == "safe":
			say_random(Dialogue.SAFE if hidden else Dialogue.SUSPICIOUS)
		else:
			say_random(Dialogue.SUSPICIOUS)
	chatter_left -= delta
	if chatter_left <= 0 and dialogue_left <= 0:
		say_random(Dialogue.IDLE)
		chatter_left = rng.randf_range(8, 13)
	var danger: float = patrol.risk()
	if danger > 0.10:
		if not warning_active:
			warning_active = true
			warning_grace = 0.8 if difficulty < 2 else 0.6
		warning_grace = maxf(0, warning_grace - delta)
	else:
		warning_active = false
		warning_grace = 0.8
	if hidden:
		suspicion = maxf(0, suspicion - delta * 8.5)
	elif danger > 0.10 and warning_grace <= 0:
		suspicion += delta * danger * (45.0 if working else 30.0) * [0.78, 1.0, 1.2][difficulty]
	else:
		suspicion = maxf(0, suspicion - delta * 2.0)
	if working and not hidden and not bug_active:
		heat = minf(100, heat + delta * [10.0, 12.0, 14.0][difficulty])
		var old_stage: int = stage()
		progress = minf(100.0, progress + delta * [2.15, 2.05, 2.0][difficulty] * (1.5 if boost_left > 0 else 1.0))
		ai_time += delta
		tokens = int(ai_time * 67.0)
		if stage() != old_stage:
			stage_notice = 2.0
			say(["L'idea c'è! Ora il codice...", "Codice generato. Ma ovviamente c'è un bug.", "Bug risolti. Manca solo la consegna."][mini(old_stage, 2)], 3.0, "TU")
	else:
		heat = maxf(0, heat - delta * (18.0 if hidden else 11.0))
	var current_stage: int = stage()
	if not bug_active and not bug_gates[current_stage] and phase_progress() >= 0.5:
		bug_gates[current_stage] = true
		spawn_bug()
	if heat >= 100:
		overloads += 1
		rollback(7)
		time_left = maxf(0, time_left - 6)
		suspicion += 12
		heat = 48
		spawn_bug()
		set_feedback("OVERLOAD! -6 s / checkpoint conservato", 4)
		say("È crashato? Bene: ora sappiamo cosa sistemare.", 4, "TU")
	suspicion = clampf(suspicion, 0, 100)
	if time_left <= 0:
		finish(false, "timeout")
	elif suspicion >= 100:
		begin_recovery()
	elif progress >= 100:
		finish(true, "shipped")

func toggle_hide() -> void:
	if state != "playing":
		return
	hidden = not hidden
	working = false
	if hidden:
		hide_count += 1

func coffee() -> void:
	if state != "playing" or coffee_used:
		return
	coffee_used = true
	suspicion = maxf(0, suspicion - 30)
	say("Un sorso di caffè. Un po' meno panico. (-30 sospetto)", 3.5, "TU")

func distract() -> void:
	if state != "playing" or decoy_used:
		return
	decoy_used = true
	patrol.distract()
	say_random(Dialogue.DISTRACT)

func say(line: String, duration: float = 4.3, who: String = "RICHARD") -> void:
	dialogue = line
	speaker = who
	dialogue_left = duration

func say_random(lines: Array) -> void:
	var choices: Array = lines.filter(func(line): return line != last_line)
	var line: String = choices[rng.randi_range(0, choices.size() - 1)]
	last_line = line
	say(line)

func finish(win: bool, reason: String) -> void:
	state = "won" if win else "lost"
	working = false
	result_reason = reason
	score = int(1000 + time_left * 10 + (100 - suspicion) * 3 + difficulty * 250 + bugs_fixed * 90 + bounce_count * 180) if win else int(progress * 10)
	if reason == "recovery":
		say("Ci avete provato. Il prossimo rimbalzo sarà quello giusto.", 30)
	elif reason == "timeout":
		say("Tempo! Tutti pronti per la demo?", 30)
	else:
		say_random(Dialogue.WIN if win else Dialogue.CAUGHT)


func checkpoint() -> float:
	return float(stage()) * 25.0

func rollback(amount: float) -> void:
	progress = maxf(checkpoint(), progress - amount)

func set_feedback(message: String, duration: float = 3.0) -> void:
	feedback = message
	feedback_left = duration

func spawn_bug() -> void:
	var pool: Array[int] = []
	for i: int in range(Bugs.CASES.size()):
		if not bug_history.has(i):
			pool.append(i)
	if pool.is_empty():
		bug_history.clear()
		for i: int in range(Bugs.CASES.size()):
			pool.append(i)
	bug_index = pool[rng.randi_range(0, pool.size() - 1)]
	bug_history.append(bug_index)
	bug_active = true
	working = false
	set_feedback("BUILD BLOCCATA / scegli il fix: 1, 2 o 3")

func answer_bug(choice: int) -> bool:
	if state != "playing" or not bug_active or hidden or choice < 0 or choice > 2:
		return false
	if choice == int(Bugs.CASES[bug_index]["correct"]):
		bug_active = false
		bugs_fixed += 1
		heat = maxf(0, heat - 20)
		boost_left = 6.0
		set_feedback("Funziona. Generazione x1.5 per 6 s", 4)
		say_random(Dialogue.BOUNCE)
		return true
	bug_errors += 1
	time_left = maxf(0, time_left - 5)
	suspicion = minf(100, suspicion + 8)
	set_feedback("Fix sbagliato: -5 s, +8 sospetto. Riprova!", 3)
	if time_left <= 0:
		finish(false, "timeout")
	elif suspicion >= 100:
		begin_recovery()
	return false

func begin_recovery() -> void:
	if state != "playing":
		return
	if bounce_charges <= 0:
		finish(false, "caught")
		return
	bounce_charges -= 1
	state = "recovering"
	working = false
	recovery_left = 8.0 if difficulty == 2 else 11.0
	recovery_index = 0
	recovery_errors = 0
	recovery_sequence.clear()
	for i: int in range(6 if difficulty == 2 else 5):
		recovery_sequence.append(rng.randi_range(0, 3))
	say("Va bene, avete un tentativo per sistemarlo.", 20)

func recovery_input(direction: int) -> bool:
	if state != "recovering" or direction < 0 or direction > 3:
		return false
	if direction != recovery_sequence[recovery_index]:
		recovery_errors += 1
		recovery_left = maxf(0, recovery_left - 1.5)
		recovery_index = maxi(0, recovery_index - 1)
		if recovery_errors >= 3 or recovery_left <= 0:
			finish(false, "recovery")
		return false
	recovery_index += 1
	if recovery_index >= recovery_sequence.size():
		bounce_count += 1
		rollback(8)
		time_left = maxf(0, time_left - 5)
		if time_left <= 0:
			finish(false, "timeout")
			return false
		suspicion = 15
		heat = 20
		hidden = true
		working = false
		boost_left = 10.0
		state = "playing"
		patrol.distract()
		patrol.distraction_left = 4.0
		set_feedback("Ripristino riuscito / x1.5 per 10 s", 5)
		say_random(Dialogue.BOUNCE)
	return true
