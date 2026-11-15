extends Node2D

const ModelScript = preload("res://scripts/game_model.gd")
const MONO = preload("res://assets/mono.ttf")
const DISPLAY = preload("res://assets/display.ttf")
const CREAM = Color("eee7cf")
const ORANGE = Color("f18050")
const GREEN = Color("b6d795")
const CYAN = Color("86dbd0")
const MUTED = Color("91a393")
const DARK = Color("101c19")
var model = ModelScript.new()
var screen: String = "menu"
var return_screen: String = "menu"
var ui: Control
var buttons: Dictionary = {}
var difficulty: int = 1
var audio_enabled: bool = true
var reduced_flashes: bool = false
var best: int = 0
var ticks: float = 0
var sound_clock: float = 0
var foot_clock: float = 0
var warning_clock: float = 0
var last_stage: int = 0
var typing_touch: bool = false
var stats_saved: bool = false
var audio_player: AudioStreamPlayer
var tones: Dictionary = {}
var selected_menu: int = 0

func _ready() -> void:
	load_settings()
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	for spec: Array in [["click", 430, 0.045], ["tab", 290, 0.09], ["stage", 730, 0.22], ["warning", 170, 0.11], ["type", 850, 0.018], ["win", 880, 0.4], ["lose", 115, 0.5], ["step", 75, 0.03]]:
		tones[spec[0]] = make_tone(float(spec[1]), float(spec[2]))
	get_window().focus_exited.connect(_on_focus_lost)
	show_screen("menu")

func make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data := PackedByteArray()
	var count: int = int(duration * 22050)
	data.resize(count * 2)
	for i: int in range(count):
		var envelope: float = pow(1.0 - float(i) / float(count), 2)
		var wave: float = 1.0 if sin(TAU * frequency * float(i) / 22050.0) > 0 else -1.0
		data.encode_s16(i * 2, int(wave * envelope * 1800))
	wav.data = data
	return wav

func play_sound(kind: String) -> void:
	if audio_enabled and tones.has(kind):
		audio_player.stream = tones[kind]
		audio_player.play()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://hellgate.cfg") == OK:
		difficulty = clampi(int(cfg.get_value("settings", "difficulty", 1)), 0, 2)
		audio_enabled = bool(cfg.get_value("settings", "audio", true))
		reduced_flashes = bool(cfg.get_value("settings", "reduced_flashes", false))
		best = int(cfg.get_value("scores", "best", 0))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "difficulty", difficulty)
	cfg.set_value("settings", "audio", audio_enabled)
	cfg.set_value("settings", "reduced_flashes", reduced_flashes)
	cfg.set_value("scores", "best", best)
	cfg.save("user://hellgate.cfg")

func style(bg: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = 18
	s.content_margin_right = 18
	return s

func add_button(id: String, caption: String, box: Rect2, action: Callable, primary: bool = false, size_value: int = 15) -> Button:
	var b := Button.new()
	b.text = caption
	b.position = box.position
	b.size = box.size
	b.add_theme_font_override("font", MONO)
	b.add_theme_font_size_override("font_size", size_value)
	b.add_theme_color_override("font_color", DARK if primary else CREAM)
	b.add_theme_color_override("font_hover_color", DARK if primary else Color.WHITE)
	b.add_theme_color_override("font_pressed_color", DARK)
	b.add_theme_stylebox_override("normal", style(ORANGE if primary else Color("1b2b25"), ORANGE if primary else Color("48604d")))
	b.add_theme_stylebox_override("hover", style(Color("ffa677") if primary else Color("304b3a"), CREAM))
	b.add_theme_stylebox_override("pressed", style(GREEN, GREEN))
	b.add_theme_stylebox_override("focus", style(Color(0, 0, 0, 0), CREAM, 2))
	b.add_theme_stylebox_override("disabled", style(Color("18201c"), Color("2c3b30")))
	b.add_theme_color_override("font_disabled_color", Color("526352"))
	b.focus_mode = Control.FOCUS_ALL if screen != "playing" else Control.FOCUS_NONE
	b.pressed.connect(func():
		play_sound("click")
		action.call())
	ui.add_child(b)
	buttons[id] = b
	return b

func show_screen(next: String) -> void:
	for child: Node in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	buttons.clear()
	screen = next
	typing_touch = false
	if next == "menu":
		add_button("start", "GIOCA   >", Rect2(80, 360, 340, 55), start_game, true, 17)
		add_button("controls", "COMANDI E REGOLE", Rect2(80, 430, 340, 45), func(): return_screen = "menu"; show_screen("controls"))
		add_button("options", "OPZIONI", Rect2(80, 488, 340, 45), func(): return_screen = "menu"; show_screen("options"))
		add_button("fullscreen", "SCHERMO INTERO  [F11]", Rect2(80, 547, 340, 39), toggle_fullscreen, false, 12)
		buttons["start"].grab_focus()
	elif next == "playing":
		add_button("pause", "II  PAUSA", Rect2(1118, 28, 140, 40), pause_game, false, 13)
		var work: Button = add_button("work", "SPAZIO  /  GENERA CON IA", Rect2(20, 602, 372, 57), func(): pass, true, 16)
		work.button_down.connect(func(): typing_touch = true)
		work.button_up.connect(func(): typing_touch = false)
		add_button("hide", "SHIFT / NASCONDI", Rect2(404, 602, 284, 57), switch_tab, false, 15)
		add_button("coffee", "C / CAFFÈ", Rect2(700, 602, 244, 57), use_coffee, false, 14)
		add_button("decoy", "E / DISTRAI", Rect2(956, 602, 304, 57), use_decoy, false, 14)
		for i: int in range(3):
			var index: int = i
			var fix: Button = add_button("fix%d" % i, "", Rect2(862, 331 + i * 49, 378, 43), func(): answer_bug(index), false, 11)
			fix.visible = false
	elif next == "recovery":
		add_button("pause", "II  PAUSA", Rect2(1118, 28, 140, 40), pause_game, false, 13)
		for i: int in range(4):
			var direction: int = i
			add_button("arrow%d" % i, ["↑", "→", "↓", "←"][i], Rect2(406 + i * 119, 440, 108, 52), func(): recovery_input(direction), false, 25)
	elif next == "paused":
		add_button("resume", "RIPRENDI   [ESC]", Rect2(440, 320, 400, 54), resume_game, true)
		add_button("controls", "COMANDI", Rect2(440, 390, 193, 44), func(): return_screen = "paused"; show_screen("controls"))
		add_button("options", "OPZIONI", Rect2(647, 390, 193, 44), func(): return_screen = "paused"; show_screen("options"))
		add_button("restart", "RICOMINCIA", Rect2(440, 451, 400, 44), start_game)
		add_button("menu", "TORNA AL MENU", Rect2(440, 510, 400, 44), func(): model.state = "idle"; show_screen("menu"))
		buttons["resume"].grab_focus()
	elif next == "controls":
		add_button("back", "<  INDIETRO", Rect2(100, 614, 270, 48), func(): show_screen(return_screen), true)
	elif next == "options":
		add_button("difficulty", difficulty_caption(), Rect2(190, 242, 900, 58), cycle_difficulty)
		add_button("audio", "AUDIO RETRO: " + ("ON" if audio_enabled else "OFF"), Rect2(190, 320, 900, 58), toggle_audio)
		add_button("flashes", "EFFETTI LUMINOSI: " + ("RIDOTTI" if reduced_flashes else "NORMALI"), Rect2(190, 398, 900, 58), toggle_flashes)
		add_button("fullscreen", "SCHERMO INTERO   [F11]", Rect2(190, 476, 900, 48), toggle_fullscreen)
		add_button("back", "<  SALVA E TORNA", Rect2(190, 591, 360, 48), func(): save_settings(); show_screen(return_screen), true)
	elif next == "result":
		add_button("retry", "RIPROVA   >", Rect2(362, 531, 360, 55), start_game, true)
		add_button("menu", "MENU", Rect2(742, 531, 176, 55), func(): show_screen("menu"))
		buttons["retry"].grab_focus()
	queue_redraw()

func difficulty_caption() -> String:
	return "DIFFICOLTÀ: " + ["TRANQUILLO  /  200 s", "HACKATHON  /  175 s", "INCUBO  /  145 s"][difficulty] + "    >"

func cycle_difficulty() -> void:
	difficulty = (difficulty + 1) % 3
	buttons["difficulty"].text = difficulty_caption()
	save_settings()

func toggle_audio() -> void:
	audio_enabled = not audio_enabled
	buttons["audio"].text = "AUDIO RETRO: " + ("ON" if audio_enabled else "OFF")
	save_settings()

func toggle_flashes() -> void:
	reduced_flashes = not reduced_flashes
	buttons["flashes"].text = "EFFETTI LUMINOSI: " + ("RIDOTTI" if reduced_flashes else "NORMALI")
	save_settings()

func toggle_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func start_game() -> void:
	model.start(difficulty)
	last_stage = 0
	stats_saved = false
	show_screen("playing")
	play_sound("stage")

func resume_game() -> void:
	show_screen("recovery" if model.state == "recovering" else "playing")

func pause_game() -> void:
	if screen in ["playing", "recovery"]:
		model.working = false
		show_screen("paused")

func _on_focus_lost() -> void:
	pause_game()

func switch_tab() -> void:
	if screen != "playing":
		return
	model.toggle_hide()
	typing_touch = false
	play_sound("tab")

func use_coffee() -> void:
	if screen == "playing" and not model.coffee_used:
		model.coffee()
		play_sound("stage")

func use_decoy() -> void:
	if screen == "playing" and not model.decoy_used:
		model.distract()
		play_sound("tab")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			toggle_fullscreen()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			if screen in ["playing", "recovery"]:
				pause_game()
			elif screen == "paused":
				resume_game()
			elif screen in ["controls", "options"]:
				show_screen(return_screen)
			get_viewport().set_input_as_handled()
		elif screen == "recovery":
			match event.keycode:
				KEY_UP, KEY_W: recovery_input(0)
				KEY_RIGHT, KEY_D: recovery_input(1)
				KEY_DOWN, KEY_S: recovery_input(2)
				KEY_LEFT, KEY_A: recovery_input(3)
			get_viewport().set_input_as_handled()
		elif screen == "playing":
			# Physical codes also cover layouts that report a symbol above the digits.
			var digit: int = event.physical_keycode
			if digit not in [KEY_1, KEY_2, KEY_3, KEY_KP_1, KEY_KP_2, KEY_KP_3]:
				digit = event.keycode
			var answers: Array[int] = [KEY_1, KEY_2, KEY_3, KEY_KP_1, KEY_KP_2, KEY_KP_3]
			if answers.has(digit):
				answer_bug(answers.find(digit) % 3)
				get_viewport().set_input_as_handled()
				return
			match event.keycode:
				KEY_SHIFT: switch_tab()
				KEY_C: use_coffee()
				KEY_E: use_decoy()
				KEY_SPACE: get_viewport().set_input_as_handled()
		elif screen == "menu" and event.keycode == KEY_ENTER:
			# Native buttons handle Enter when focused.
			pass

func answer_bug(choice: int) -> void:
	if screen != "playing" or model.hidden or not model.bug_active:
		return
	var solved: bool = model.answer_bug(choice)
	typing_touch = false
	play_sound("stage" if solved else "warning")

func recovery_input(direction: int) -> void:
	if screen != "recovery":
		return
	var success: bool = model.recovery_input(direction)
	play_sound("stage" if success else "warning")

func _process(delta: float) -> void:
	ticks += delta
	if screen in ["playing", "recovery"]:
		model.working = screen == "playing" and (Input.is_physical_key_pressed(KEY_SPACE) or typing_touch) and not model.hidden and not model.bug_active
		model.update(minf(delta, 0.08))
		if model.state == "recovering" and screen != "recovery":
			show_screen("recovery")
			play_sound("warning")
		elif model.state == "playing" and screen == "recovery":
			show_screen("playing")
			play_sound("win")
		elif model.state in ["won", "lost"]:
			if model.score > best:
				best = model.score
			save_settings()
			play_sound("win" if model.state == "won" else "lose")
			show_screen("result")
	if screen == "playing":
		if model.stage() != last_stage:
			last_stage = model.stage()
			play_sound("stage")
		sound_clock -= delta
		foot_clock -= delta
		warning_clock -= delta
		if model.working and sound_clock <= 0:
			play_sound("type")
			sound_clock = 0.15
		if model.patrol.mode == "walk" and foot_clock <= 0 and not model.working:
			play_sound("step")
			foot_clock = 0.34
		if model.warning_active and not model.hidden and warning_clock <= 0:
			play_sound("warning")
			warning_clock = 1.15
		buttons["work"].disabled = model.hidden or model.bug_active
		buttons["work"].text = "BUILD BLOCCATA: DEBUG" if model.bug_active else ("IA NASCOSTA" if model.hidden else ("GENERAZIONE IN CORSO..." if model.working else "SPAZIO  /  GENERA CON IA"))
		buttons["hide"].text = "SHIFT / TORNA ALL'IA" if model.hidden else "SHIFT / NASCONDI"
		buttons["coffee"].disabled = model.coffee_used
		buttons["coffee"].text = "CAFFÈ FINITO" if model.coffee_used else "C / CAFFÈ (-30)"
		buttons["decoy"].disabled = model.decoy_used
		buttons["decoy"].text = "DISTRAZIONE USATA" if model.decoy_used else "E / DISTRAI (7 s)"
		for i: int in range(3):
			buttons["fix%d" % i].visible = model.bug_active and not model.hidden
			if model.bug_active:
				buttons["fix%d" % i].text = "%d  %s" % [i + 1, model.Bugs.CASES[model.bug_index]["choices"][i]]
	queue_redraw()

func px(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(roundf(x), roundf(y), w, h), color)

func txt(line: String, x: float, y: float, size_value: int = 14, color: Color = CREAM, font: Font = MONO) -> void:
	draw_string(font, Vector2(x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value, color)

func lines(content: String, x: float, y: float, size_value: int = 14, color: Color = CREAM, gap: float = 23) -> void:
	var row: int = 0
	for line: String in content.split("\n"):
		txt(line, x, y + float(row) * gap, size_value, color)
		row += 1

func panel(box: Rect2, bg: Color = DARK, border: Color = Color("385040")) -> void:
	draw_rect(box, bg)
	draw_rect(box, border, false, 1)

func bar(box: Rect2, value: float, color: Color) -> void:
	draw_rect(box, Color("283a2d"))
	draw_rect(Rect2(box.position, Vector2(box.size.x * clampf(value, 0, 1), box.size.y)), color)

func _draw() -> void:
	if screen in ["playing", "recovery", "paused", "result"] or (screen in ["options", "controls"] and return_screen == "paused"):
		draw_game()
	else:
		draw_set_transform(Vector2.ZERO, 0, Vector2(1.6, 1.6))
		draw_room()
		draw_set_transform(Vector2.ZERO)
		px(0, 0, 1280, 720, Color(0.025, 0.065, 0.045, 0.48))
		px(0, 0, 650, 720, Color(0.025, 0.065, 0.045, 0.78))
	if screen == "menu":
		draw_menu()
	elif screen == "controls":
		draw_controls()
	elif screen == "options":
		draw_options()
	elif screen == "paused":
		px(0, 0, 1280, 720, Color(0.02, 0.05, 0.035, 0.84))
		panel(Rect2(389, 171, 502, 423))
		txt("PARTITA IN PAUSA", 455, 216, 13, ORANGE)
		txt("IN PAUSA", 468, 284, 43, CREAM, DISPLAY)
	elif screen == "recovery":
		draw_recovery()
	elif screen == "result":
		draw_result()
	# Restrained CRT texture. Disabled with reduced light effects.
	if not reduced_flashes:
		for y: int in range(0, 720, 4):
			px(0, y, 1280, 1, Color(0, 0, 0, 0.045))

func draw_menu() -> void:
	txt("HACK CLUB / HAVEN / ACIREALE", 80, 73, 13, ORANGE)
	txt("HELL", 74, 177, 93, CREAM, DISPLAY)
	txt("GATE", 74, 270, 93, ORANGE, DISPLAY)
	txt("La demo è vicina. Non farti beccare.", 80, 314, 17, CREAM)
	panel(Rect2(818, 422, 383, 187), Color(0.04, 0.09, 0.065, 0.91))
	txt("COME SI GIOCA", 843, 454, 12, ORANGE)
	lines("Finisci il gioco prima della demo.\nChiudi la chat se passa Richard.\nSe va tutto storto, recupera\ndall'ultimo checkpoint.", 843, 486, 14, CREAM, 25)
	txt("RECORD  %05d" % best, 80, 638, 14, GREEN)
	txt(["TRANQUILLO", "HACKATHON", "INCUBO"][difficulty] + " / HAVEN", 80, 666, 11, MUTED)
	txt("HAVEN / ACIREALE", 913, 687, 10, CREAM)

func draw_controls() -> void:
	px(0, 0, 1280, 720, Color(0.025, 0.06, 0.04, 0.92))
	txt("COMANDI", 100, 82, 12, ORANGE)
	txt("Comandi & regole", 97, 141, 44, CREAM, DISPLAY)
	var rows: Array = [
		["SPAZIO", "GENERA CON IA", "Tieni premuto. Alterna lavoro e pause: il PC si scalda."],
		["SHIFT", "CAMBIA TAB", "Nascondi la chat e raffredda il portatile più in fretta."],
		["1 / 2 / 3", "RIPARA UN BUG", "Leggi il problema e scegli il fix. Richard continua a muoversi!"],
		["FRECCE", "BOUNCE BACK", "Se scoperto, ripeti la sequenza. Anche WASD o pulsanti."],
		["C", "UN CAFFÈ", "-30 sospetto. Una sola volta per partita."],
		["E", "DISTRAZIONE", "7 secondi senza lo sguardo di Richard. Una sola volta."],
		["ESC / P", "PAUSA", "Ferma anche la sfida Bounce Back. F11: schermo intero."]]
	for i: int in range(rows.size()):
		var y: float = 193 + i * 43
		panel(Rect2(100, y - 20, 125, 33), Color("203529"))
		txt(rows[i][0], 110, y + 2, 11, GREEN)
		txt(rows[i][1], 245, y, 12, CREAM)
		txt(rows[i][2], 458, y, 12, MUTED)
	lines("CHECKPOINT ogni 25%. OVERLOAD: -6 s e rollback, mai sotto il checkpoint.\nFIX SBAGLIATO: -5 s e +8 sospetto. FIX GIUSTO: generazione x1.5 per 6 s.\nSOSPETTO 100%: 1 solo ripristino per partita. Sequenza a tempo, 3 errori = KO.\nRECUPERO: rollback fino a 8%, -5 s, boost x1.5 per 10 s. Il tempo continua a scorrere.", 100, 511, 12, ORANGE, 23)
	txt("Finisci il progetto prima della demo. Puoi usare anche i pulsanti a schermo.", 399, 644, 10, MUTED)

func draw_options() -> void:
	px(0, 0, 1280, 720, Color(0.025, 0.06, 0.04, 0.94))
	txt("IMPOSTAZIONI", 190, 101, 12, ORANGE)
	txt("Opzioni", 187, 164, 48, CREAM, DISPLAY)
	txt("La difficoltà si applica alla prossima partita. Le altre opzioni sono immediate.", 190, 202, 12, MUTED)
	txt("Impostazioni e record sono salvati su questo dispositivo.", 190, 562, 12, MUTED)

func draw_game() -> void:
	px(0, 0, 1280, 720, Color("101a15"))
	txt("HELL GATE", 20, 45, 27, ORANGE, DISPLAY)
	txt("HAVEN / BOUNCE BACK", 22, 71, 10, MUTED)
	txt("PROGETTO", 270, 31, 10, MUTED)
	txt("%03d%%" % int(model.progress), 270, 59, 24, GREEN)
	bar(Rect2(369, 44, 190, 8), model.progress / 100.0, GREEN)
	txt("SOSPETTO", 590, 31, 10, MUTED)
	var danger_color: Color = ORANGE if model.suspicion > 55 else GREEN
	txt("%02d%%" % int(model.suspicion), 590, 59, 24, danger_color)
	bar(Rect2(677, 44, 170, 8), model.suspicion / 100.0, danger_color)
	txt("ALLA DEMO", 899, 31, 10, MUTED)
	txt("%02d:%02d" % [int(model.time_left) / 60, int(model.time_left) % 60], 899, 62, 28, ORANGE if model.time_left < 25 else CREAM)
	px(20, 88, 1240, 1, Color("354334"))
	draw_set_transform(Vector2(20, 105))
	draw_room()
	draw_set_transform(Vector2.ZERO)
	panel(Rect2(20, 557, 800, 28), Color("19281e"))
	var status: String = "RICHARD È LONTANO. VAI COL PROMPT."
	var status_color: Color = GREEN
	if model.patrol.distraction_left > 0:
		status = "DISTRAZIONE ATTIVA / %.1f SECONDI" % model.patrol.distraction_left
	elif model.hidden:
		status = "TAB INNOCENTE APERTO. RESPIRA."
	elif model.warning_active:
		status = "! RICHARD STA GUARDANDO. NASCONDI L'IA!"
		status_color = ORANGE
	elif model.patrol.position.y > 230:
		status = "RICHARD SI AVVICINA. TIENI PRONTO SHIFT."
		status_color = Color("dfc88f")
	if model.feedback_left > 0 and not (model.warning_active and not model.hidden):
		status = model.feedback
		status_color = CYAN
	txt(status, 34, 576, 11, status_color)
	panel(Rect2(20, 523, 800, 34), Color("162b21"))
	txt("CALORE %02d%%" % int(model.heat), 32, 544, 11, ORANGE if model.heat > 75 else CYAN)
	bar(Rect2(143, 535, 155, 7), model.heat / 100, ORANGE if model.heat > 75 else CYAN)
	txt("SAVE %02d%%" % int(model.checkpoint()), 320, 544, 11, GREEN)
	txt("RIPRISTINI %d" % model.bounce_charges, 438, 544, 11, ORANGE)
	txt("x1.5 / %.1f s" % model.boost_left if model.boost_left > 0 else "BUG RISOLTI %d" % model.bugs_fixed, 575, 544, 12, CYAN)
	draw_terminal()
	for i: int in range(4):
		var x: float = 20 + i * 203
		var c: Color = GREEN if i < model.stage() else (ORANGE if i == model.stage() else MUTED)
		txt(("OK" if i < model.stage() else "0%d" % (i + 1)) + "  " + model.STAGES[i], x, 688, 11, c)
	txt("RECORD %05d  /  %s" % [best, ["TRANQUILLO", "HACKATHON", "INCUBO"][model.difficulty]], 859, 688, 11, MUTED)

func draw_terminal() -> void:
	var x: float = 842
	panel(Rect2(x, 105, 418, 480), Color("122421"), Color("486c59"))
	px(x + 1, 106, 416, 37, Color("23443a") if not model.hidden else Color("334034"))
	px(x + 15, 120, 7, 7, GREEN if model.hidden else CYAN)
	txt("documentazione.gd" if model.hidden else "HAVEN AI / CHAT PRIVATA", x + 32, 130, 12, CREAM)
	txt("-  □  ×", x + 343, 130, 12, MUTED)
	if model.bug_active and not model.hidden:
		draw_bug_terminal(x)
		return
	if model.hidden:
		txt("> CODICE INNOCENTE", x + 22, 177, 13, GREEN)
		lines("extends Node2D\n\n# Appunti per la demo\nvar progetto = \"Hell gate\"\nvar fatto_tutto_noi = true\n\nfunc _ready():\n    print(\"Ciao, Haven!\")\n\n# Studiare la documentazione\n# Fare un commit\n# Non guardare Richard\n# Troppo tardi: lo stai guardando", x + 22, 210, 12, MUTED, 22)
		panel(Rect2(x + 18, 503, 382, 61), Color("203c2b"), Color("41644a"))
		txt("SCHERMO AL SICURO", x + 33, 528, 15, GREEN)
		txt("BUG IN ATTESA / SHIFT per riparare" if model.bug_active else "SHIFT per tornare alla chat IA", x + 33, 549, 11, MUTED)
		return
	txt("TU  /  PROMPT %d DI 4" % (model.stage() + 1), x + 22, 168, 10, ORANGE)
	panel(Rect2(x + 18, 178, 382, 58), Color("2b3831"), Color("3a5446"))
	lines(model.PROMPTS[model.stage()], x + 29, 200, 12, CREAM, 19)
	var pulse: String = [".", "..", "..."][int(ticks * 3) % 3]
	txt("IA  /  " + ("GENERO" + pulse if model.working else "IN ATTESA"), x + 22, 260, 11, CYAN)
	var reply: String = model.response()
	if reply.is_empty():
		lines("Tieni SPAZIO per inviare il prompt\ne generare la risposta.", x + 22, 291, 12, MUTED, 22)
	else:
		var all_lines: PackedStringArray = reply.split("\n")
		var first: int = maxi(0, all_lines.size() - 11)
		var shown: String = "\n".join(all_lines.slice(first))
		lines(shown, x + 22, 286, 12, CYAN, 19)
		if model.working and int(ticks * 3) % 2 == 0:
			var end_line: String = all_lines[all_lines.size() - 1]
			px(x + 22 + MONO.get_string_size(end_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, 277 + (mini(all_lines.size(), 11) - 1) * 19, 7, 13, CYAN)
	px(x + 18, 506, 382, 1, Color("355045"))
	txt("%d TOKEN" % model.tokens, x + 22, 528, 10, CYAN)
	txt("FASE %d%%" % int(model.phase_progress() * 100), x + 288, 528, 10, MUTED)
	bar(Rect2(x + 22, 540, 374, 5), model.phase_progress(), CYAN)
	txt("SHIFT: cambia scheda", x + 22, 567, 9, MUTED)

func draw_result() -> void:
	px(0, 0, 1280, 720, Color(0.02, 0.05, 0.035, 0.88))
	panel(Rect2(277, 114, 726, 509), Color("14261d"), ORANGE)
	var won: bool = model.state == "won"
	txt("DEMO PRONTA" if won else "PARTITA FINITA", 367, 163, 13, GREEN if won else ORANGE)
	txt("CONSEGNATO" if won else ("TEMPO SCADUTO" if model.result_reason == "timeout" else ("RIMBALZO FALLITO" if model.result_reason == "recovery" else "BECCATI!")), 358, 235, 32 if model.result_reason == "recovery" else 46, CREAM if won else ORANGE, DISPLAY)
	lines("Build pronta. Stavolta possiamo presentarla." if won else ("La demo è iniziata. Il vostro gioco è ancora un prompt." if model.result_reason == "timeout" else ("La seconda chance è finita. Al prossimo tentativo!" if model.result_reason == "recovery" else "Richard ha visto la chat. Serviva un cambio di tab.")), 362, 275, 13, MUTED, 22)
	panel(Rect2(362, 300, 556, 73), Color("213b2a"))
	txt("RICHARD", 379, 324, 10, ORANGE)
	# End lines use two rows rather than overflowing the panel.
	var result_text: String = model.dialogue
	if result_text.length() > 57:
		var split_at: int = result_text.rfind(" ", 57)
		result_text = result_text.substr(0, split_at) + "\n" + result_text.substr(split_at + 1)
	lines(result_text, 379, 346, 12, CREAM, 18)
	txt("PUNTEGGIO", 362, 411, 11, MUTED)
	txt("%05d" % model.score, 362, 454, 35, GREEN)
	txt("PROGETTO", 581, 411, 11, MUTED)
	txt("%d%%" % int(model.progress), 581, 454, 35, CREAM)
	txt("RECUPERI", 786, 411, 11, MUTED)
	txt("%02d" % model.bounce_count, 786, 454, 35, ORANGE)
	txt("RECORD %05d / BUG %d / OVERLOAD %d / ERRORI FIX %d" % [best, model.bugs_fixed, model.overloads, model.bug_errors], 362, 493, 11, MUTED)

func draw_room() -> void:
	px(0, 0, 800, 452, Color("8d8b6f"))
	px(0, 0, 800, 145, Color("d0c6a3"))
	px(0, 95, 800, 50, Color("9da58c"))
	px(0, 140, 800, 7, Color("67735d"))
	for y: int in range(149, 452, 27):
		px(0, y, 800, 1, Color("787e63"))
		for x: int in range(0 if y % 2 == 0 else 30, 800, 60):
			px(x, y, 1, 27, Color("787e63"))
	for i: int in range(180):
		px((i * 127) % 800, 148 + (i * 53) % 300, 2, 1, Color("aaa382") if i % 2 == 0 else Color("70785e"))
	# Window, wall screen and the same rear exit as the reference classroom.
	px(40, 21, 169, 104, Color("6d7b5e"))
	px(46, 27, 157, 91, Color("e6d8ac"))
	px(52, 34, 67, 76, Color("acc294"))
	px(126, 34, 69, 76, Color("bccd9f"))
	px(52, 73, 143, 4, Color("ddd3aa"))
	px(52, 35, 8, 34, Color("d4ddac"))
	px(36, 120, 178, 8, Color("ede0b6"))
	px(270, 31, 172, 89, Color("606a55"))
	px(274, 35, 164, 80, Color("25382e"))
	px(279, 41, 154, 65, Color("354d3b"))
	txt("H A V E N", 300, 77, 20, GREEN)
	txt("HACK CLUB / ACIREALE", 295, 98, 8, Color("a6b891"))
	px(551, 28, 76, 118, Color("78896a"))
	px(557, 34, 64, 112, Color("3d5140"))
	px(563, 39, 53, 107, Color("667d59"))
	px(604, 98, 4, 7, Color("d6c79b"))
	px(568, 10, 40, 13, Color("527647"))
	txt("EXIT v", 570, 20, 8, CREAM)
	px(218, 15, 314, 2, Color("9a9e84"))
	px(530, 15, 2, 85, Color("9a9e84"))
	px(532, 98, 17, 2, Color("9a9e84"))
	px(654, 78, 146, 3, Color("b8bea0"))
	px(661, 58, 3, 21, Color("b8bea0"))
	px(649, 55, 18, 12, Color("c7c9ab"))
	px(653, 58, 4, 5, Color("5e705a"))
	# Warm Sicilian daylight.
	draw_colored_polygon(PackedVector2Array([Vector2(40, 147), Vector2(203, 147), Vector2(381, 452), Vector2(0, 452)]), Color(1, 0.88, 0.55, 0.10))
	room_chair(135, 204)
	room_desk(52, 177, 175)
	room_chair(662, 204)
	room_desk(557, 177, 183)
	room_person(Vector2(126, 277), 1.25, false)
	room_chair(131, 294)
	room_desk(35, 270, 205)
	room_person(Vector2(658, 278), 1.25, false, Color("727e68"))
	room_chair(670, 294)
	room_desk(557, 270, 209)
	# A view cone follows Richard's actual facing direction.
	var p: Vector2 = model.patrol.position
	if model.patrol.distraction_left <= 0:
		var face: Vector2 = model.patrol.facing
		var origin: Vector2 = p - Vector2(0, 20)
		var left: Vector2 = origin + face.rotated(-0.48) * 162
		var right: Vector2 = origin + face.rotated(0.48) * 162
		var cone: Color = Color(1, 0.65, 0.25, 0.13) if not model.hidden else Color(0.7, 0.87, 0.58, 0.1)
		draw_colored_polygon(PackedVector2Array([origin, left, right]), cone)
		draw_line(left, right, Color(cone, 0.2), 1)
	room_person(p, 1.55, true)
	txt("RICHARD", p.x - 31, p.y - 77, 9, Color("f4e4b8"))
	if model.warning_active:
		var lift: float = 0 if reduced_flashes else sin(ticks * 7) * 3
		px(p.x - 10, p.y - 111 + lift, 20, 24, ORANGE)
		txt("!", p.x - 5, p.y - 92 + lift, 22, DARK, DISPLAY)
	elif model.patrol.distraction_left > 0:
		txt("? HDMI ?", p.x - 30, p.y - 93, 11, CYAN)
	# Your station: a much brighter screen and animated hands when generating.
	room_chair(388, 408)
	room_person(Vector2(388, 390), 1.3, false, Color("aa5e47"))
	if model.working and not model.hidden:
		var flicker: float = 0.09 if reduced_flashes else 0.1 + sin(ticks * 6) * 0.025
		px(292, 322, 195, 113, Color(0.4, 1.0, 0.8, flicker))
	room_desk(293, 388, 194, true)
	if model.working:
		var offset: int = 2 if int(ticks * 12) % 2 == 0 else 0
		px(373, 389 + offset, 8, 4, Color("dcb28b"))
		px(394, 391 - offset, 8, 4, Color("dcb28b"))
		for i: int in range(3):
			var lift: float = fmod(ticks * 27 + float(i * 17), 48)
			txt(["01", "+", "10"][i], 346 + i * 25, 346 - lift, 10, CYAN)
	px(315, 369, 5, 15, Color("b6cbb3"))
	px(316, 366, 3, 4, CREAM)
	txt("VOI", 373, 443, 9, ORANGE)
	room_desk(30, 421, 166)
	px(54, 406, 34, 14, Color("684c37"))
	px(62, 401, 17, 6, Color("684c37"))
	room_desk(580, 421, 192)
	px(704, 398, 7, 20, Color("718575"))
	# Little plant next to the wall.
	px(476, 126, 22, 20, Color("677852"))
	px(483, 108, 7, 22, Color("6d804e"))
	px(472, 110, 21, 7, Color("7b9259"))
	px(483, 103, 18, 8, Color("84995d"))
	if model.dialogue_left > 0 and not model.dialogue.is_empty():
		var bubble_x: float = 210
		panel(Rect2(bubble_x, 7, 560, 61), Color("efe4c5"), Color("5a6249"))
		txt(model.speaker, bubble_x + 13, 24, 9, Color("8c5538"))
		var speech: String = model.dialogue
		if speech.length() > 67:
			var split_at: int = speech.rfind(" ", 67)
			speech = speech.substr(0, split_at) + "\n" + speech.substr(split_at + 1)
		lines(speech, bubble_x + 13, 42, 12, DARK, 17)
	if model.boost_left > 0:
		var bounce_y: float = 337 - absf(sin(ticks * 4)) * 36 if not reduced_flashes else 315
		px(453, bounce_y, 10, 10, CYAN)
		px(455, bounce_y + 2, 3, 3, CREAM)
		txt("x1.5", 467, 322, 10, CYAN)
	if model.stage_notice > 0:
		panel(Rect2(242, 246, 310, 46), Color("203f2c"), GREEN)
		txt("FASE COMPLETATA!  AVANTI >", 258, 275, 15, GREEN)
	if model.hidden:
		panel(Rect2(297, 419, 190, 17), Color("1f3626"))
		txt("TAB INNOCENTE / SHIFT", 306, 431, 10, GREEN)
	else:
		panel(Rect2(297, 419, 190, 17), Color("15433b"))
		txt("IA " + ("ATTIVA / +TOKEN" if model.working else "APERTA / IN ATTESA"), 306, 431, 10, CYAN)
	# Frame the whole classroom.
	draw_rect(Rect2(0, 0, 800, 452), Color("42583d"), false, 1)

func room_chair(x: float, y: float) -> void:
	px(x - 12, y - 11, 25, 18, Color("26352e"))
	px(x - 13, y - 8, 3, 13, Color("526451"))
	px(x - 8, y + 7, 17, 6, Color("223028"))
	px(x - 2, y + 13, 4, 11, Color("535e4c"))
	px(x - 14, y + 24, 28, 3, Color("26372b"))
	px(x - 14, y + 24, 4, 6, Color("1d2923"))
	px(x + 10, y + 24, 4, 6, Color("1d2923"))

func room_desk(x: float, y: float, width: float, player: bool = false) -> void:
	px(x + 6, y + 25, width, 32, Color(0.12, 0.19, 0.12, 0.18))
	px(x + 6, y + 18, 6, 32, Color("a9ac92"))
	px(x + width - 12, y + 18, 6, 32, Color("9fa98d"))
	px(x, y, width, 23, Color("a6ad94"))
	px(x, y, width, 17, Color("dcd9b9"))
	px(x, y, width, 3, Color("f0e6c5"))
	var monitor_width: float = 67 if player else 49
	var monitor_height: float = 42 if player else 31
	px(x + 27, y - monitor_height + 8, monitor_width, monitor_height, Color("20352c"))
	var screen_color: Color = Color("5f7961") if model.hidden else Color("558f80")
	px(x + 31, y - monitor_height + 12, monitor_width - 8, monitor_height - 8, screen_color if player else Color("526d5b"))
	px(x + 46, y + 8, 7, 5, Color("304735"))
	px(x + 36, y + 13, 27, 3, Color("354b36"))
	px(x + 98, y + 7, 35, 6, Color("84917a"))
	for i: int in range(4):
		var line_width: float = 18 + ((i * 7 + int(ticks * 5)) % 20) if player and model.working else 16 + i * 4
		px(x + 35, y - monitor_height + 16 + i * 5, line_width, 2, CYAN if player and not model.hidden else Color("c4d3a9"))
	if player:
		txt("DOCS" if model.hidden else "HAVEN AI", x + 34, y + 1, 7, GREEN if model.hidden else CREAM)

func room_person(pos: Vector2, scale_value: float, richard: bool = true, hoodie: Color = Color("a75e4b")) -> void:
	var x: float = pos.x
	var y: float = pos.y
	var moving: bool = richard and model.patrol.mode == "walk" and screen == "playing"
	var step: float = sin(ticks * 10) * 2 if moving else 0.0
	var s: float = scale_value
	draw_rect(Rect2(x - 11 * s, y, 23 * s, 4 * s), Color(0.05, 0.1, 0.05, 0.24))
	var shapes: Array = [
		[-6, -13 + step, 5, 13, Color("537b92") if richard else Color("554f5e")],
		[1, -13 - step, 5, 13, Color("537b92") if richard else Color("554f5e")],
		[-7, -2 + step, 7, 3, Color("22302b")], [1, -2 - step, 7, 3, Color("22302b")],
		[-9, -31, 18, 19, Color("35432f") if richard else hoodie],
		[-4, -30, 8, 18, Color("e8dfbf") if richard else hoodie.lightened(0.1)],
		[-2, -25, 5, 5, Color("dbb548") if richard else hoodie],
		[-11, -29, 4, 20, Color("35432f") if richard else hoodie],
		[7, -29, 4, 20, Color("35432f") if richard else hoodie],
		[-11, -10, 4, 4, Color("dba77e")], [7, -10, 4, 4, Color("dba77e")],
		[-6, -41, 13, 13, Color("dba77e")],
		[-8, -45, 16, 8, Color("222820")], [-8, -38, 3, 8, Color("222820")],
		[5, -38, 3, 7, Color("222820")], [-5, -37, 3, 5, Color("222820")],
		[-1, -38, 3, 4, Color("222820")], [-3, -33, 2, 2, Color("30372a")],
		[4, -33, 2, 2, Color("30372a")], [1, -28, 3, 1, Color("966f4b")]]
	for shape: Array in shapes:
		px(x + float(shape[0]) * s, y + float(shape[1]) * s, float(shape[2]) * s, float(shape[3]) * s, shape[4])


func draw_bug_terminal(x: float) -> void:
	var bug: Dictionary = model.Bugs.CASES[model.bug_index]
	txt("BUILD FALLITA / SERVE UN FIX", x + 22, 172, 12, ORANGE)
	txt(bug["title"], x + 22, 204, 13, CREAM)
	lines(bug["question"], x + 22, 237, 12, MUTED, 22)
	txt("SCEGLI 1, 2 O 3", x + 22, 307, 12, CYAN)
	panel(Rect2(x + 18, 493, 382, 71), Color("213a2b"))
	txt("Ok, troviamo il problema.", x + 30, 516, 12, GREEN)
	txt("Fix giusto: boost x1.5 per 6 s", x + 30, 537, 11, MUTED)
	txt("Fix sbagliato: -5 s / +8 sospetto", x + 30, 555, 10, ORANGE)

func draw_recovery() -> void:
	px(0, 0, 1280, 720, Color(0.02, 0.05, 0.035, 0.91))
	panel(Rect2(240, 126, 800, 454), Color("142b23"), ORANGE)
	txt("TI HA VISTO. HAI UN SOLO TENTATIVO PER RECUPERARE.", 291, 168, 14, ORANGE)
	txt("BOUNCE BACK", 356, 232, 53, CREAM, DISPLAY)
	txt("Ripeti la sequenza da sinistra a destra. Frecce o WASD.", 308, 273, 13, MUTED)
	var count: int = model.recovery_sequence.size()
	var start_x: float = 640 - float(count) * 42
	for i: int in range(count):
		var color: Color = GREEN if i < model.recovery_index else (ORANGE if i == model.recovery_index else MUTED)
		panel(Rect2(start_x + i * 84, 298, 70, 66), Color("203e2e"), color)
		txt(["↑", "→", "↓", "←"][model.recovery_sequence[i]], start_x + i * 84 + 21, 345, 34, color)
	txt("%.1f s" % model.recovery_left, 358, 407, 24, ORANGE)
	txt("ERRORI %d/3" % model.recovery_errors, 529, 403, 15, MUTED)
	txt("DEMO %02d:%02d" % [int(model.time_left) / 60, int(model.time_left) % 60], 756, 403, 14, CREAM)
	txt("Recuperi dal checkpoint: -5 s / rollback max 8% / boost x1.5.", 304, 530, 12, GREEN)
	txt("Il tempo scorre. Un errore costa 1.5 s e un passo indietro.", 310, 555, 11, MUTED)
