extends SceneTree

# Independent critic: physical press/release events at real time and normal physics.
# Dock approaches are explicitly staged; no full-route or human-comfort claim.
const Profile = preload("res://scripts/player_profile.gd")
const Contracts = preload("res://scripts/river_contracts.gd")
const Text = preload("res://scripts/localization.gd")
var game: Node
var failures := 0
var rows: Array[String] = []
var held: Dictionary = {}

func _initialize() -> void:
	call_deferred("review")

func check(ok: bool, label: String) -> void:
	rows.append(("PASS " if ok else "FAIL ") + label)
	print(rows.back())
	if not ok: failures += 1

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func key(code: int, pressed: bool) -> void:
	if held.get(code, false) == pressed: return
	held[code] = pressed
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(code: int) -> void:
	key(code, true)
	await wait(0.08)
	key(code, false)
	await wait(0.08)

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await game.save_capture("cruise-" + name + ".png")

func setup(id: String) -> void:
	for code: int in held.keys(): key(code, false)
	game.return_to_menu()
	game.profile = Profile.new("", false)
	if Contracts.job(id).origin == "koya":
		game.profile.award_order(game.profile.begin_mission("base_light"), "koya_filters")
	game.ui_screen = "map"
	game.select_contract(id)
	await wait(0.2)
	await tap(KEY_ENTER)
	check(game.state == "running" and game.velocity.length() < 0.1 and game.engine_throttle == 0, id + " launches stopped with engine off")

func driving(id: String) -> void:
	await setup(id)
	var direction: float = Contracts.direction(id)
	var start: Vector2 = game.boat_pos
	await tap(KEY_W)
	await wait(1.25)
	var first: float = game.velocity.y * direction
	check(first > 85 and (game.boat_pos.y-start.y)*direction > 60 and game.engine_throttle > 0, id + " W tap continues first-gear drive after release")
	await tap(KEY_2)
	await wait(1.0)
	check(game.velocity.y*direction > first + 40, id + " gear 2 accelerates active cruise without a new W press")
	await tap(KEY_9)
	check(game.selected_gear == 2, id + " reverse remains gated at speed")
	await tap(KEY_SPACE)
	await wait(0.35)
	check(game.velocity.y*direction > 145 and game.engine_throttle > 0, id + " Space has no running game control")
	key(KEY_D, true)
	await wait(0.35)
	check(game.velocity.x > 20, id + " D remains screen-right")
	key(KEY_D, false)
	key(KEY_A, true)
	await wait(0.75)
	check(game.velocity.x < -20, id + " A remains screen-left")
	key(KEY_A, false)
	await capture(id + "-cruise")
	await tap(KEY_S)
	await wait(0.8)
	check(game.velocity.length() < 0.1 and game.engine_throttle == 0, id + " S tap stops drive and brakes after release")
	check(game.audio.targets().x == 0, id + " stopped engine has silent audio target")
	await capture(id + "-stopped")
	await tap(KEY_9)
	await tap(KEY_UP)
	await wait(0.7)
	check(game.selected_gear == 9 and game.velocity.y*direction < -50, id + " reverse and Up alias start persistent reverse thrust")
	await tap(KEY_DOWN)
	await wait(0.6)
	check(game.velocity.length() < 0.1 and game.engine_throttle == 0, id + " Down alias stops reverse after release")
	await tap(KEY_1)
	key(KEY_W, true)
	key(KEY_S, true)
	await wait(0.2)
	key(KEY_W, false)
	key(KEY_S, false)
	await wait(0.6)
	check(game.velocity.length() < 0.1 and game.engine_throttle == 0, id + " S wins simultaneous W/S and remains stopped")
	await tap(KEY_W)
	await wait(0.4)
	await tap(KEY_ESCAPE)
	check(game.state == "paused" and game.engine_throttle == 0 and game.audio.targets().x == 0, id + " pause switches engine off")
	await tap(KEY_W)
	await tap(KEY_ESCAPE)
	await wait(0.8)
	check(game.state == "running" and game.engine_throttle == 0 and game.velocity.length() < 0.1, id + " paused W is ignored and resume does not restart cruise")
	await tap(KEY_W)
	await wait(0.3)
	await tap(KEY_R)
	check(game.state == "ready" and game.ui_screen == "map" and game.engine_throttle == 0 and game.velocity.length() < 0.1, id + " R resets engine and mission without departure")
	await tap(KEY_W)
	check(game.state == "ready" and game.engine_throttle == 0, id + " map owns W input")

func docking(id: String, landing: String) -> void:
	await setup(id)
	# Staged calm approach, then normal physical-key navigation and docking.
	var direction: float = Contracts.direction(id)
	game.boat_pos = game.landing_position(landing) - Vector2(0, direction * 180)
	game.velocity = Vector2.ZERO
	await tap(KEY_W)
	await wait(1.1)
	await tap(KEY_S)
	await wait(0.6)
	check(game.can_deliver() and game.engine_throttle == 0, id + " staged approach reaches docking speed through W tap / S tap")
	await capture(landing + "-dock-ready")
	key(KEY_E, true)
	await wait(2.3)
	key(KEY_E, false)
	check(game.state == "success" and game.profile.current_landing == landing and game.engine_throttle == 0, id + " holding E after released S commits matching delivery")

func presentation() -> void:
	await setup("base_light")
	game.reset_run()
	for locale in ["en", "ru"]:
		Text.set_locale(locale)
		await wait(0.2)
		await capture(locale + "-briefing")
	await tap(KEY_ENTER)
	await tap(KEY_W)
	await wait(0.7)
	await capture("ru-active-hints")
	await tap(KEY_S)
	await wait(0.5)
	Text.set_locale("en")
	await wait(0.2)
	await capture("en-stopped-hints")
	# Explicitly stage a clear point inside the bounded gentle-current zone.
	game.boat_pos = Vector2(game.river_center(-4500), -4500)
	game.velocity = Vector2.ZERO
	await tap(KEY_S)
	await wait(0.6)
	check(game.velocity.y > 25 and game.velocity.x < -5 and game.engine_throttle == 0 and game.audio.targets().x == 0, "S stops engine while bounded current still produces southward ground drift")
	await capture("current-drift-engine-off")

func review() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	await wait(0.2)
	check(not game.profile._persistence and not game.settings._persistence, "fixture isolates profile and settings before tree entry")
	if "--presentation-only" not in OS.get_cmdline_user_args():
		await driving("base_light")
		await driving("koya_luma")
		await docking("base_light", "koya")
		await docking("koya_luma", "luma")
	await presentation()
	for code: int in held.keys(): key(code, false)
	var report := "# Independent cruise controls review\n\nNormal clock/physics and physical InputEventKey press/release through Input Map. Isolated profile and settings. Dock approaches are staged, followed by actual keyboard-driven movement and docking. This is scoped technical evidence, not human comfort, listening, or full-route acceptance. Renderer: " + DisplayServer.get_name() + ".\n\n"
	for row in rows: report += "- " + row + "\n"
	report += "\nVerdict: " + ("PASS for scoped controls checks" if failures == 0 else "REWORK") + ".\n"
	DirAccess.make_dir_recursive_absolute("res://doc/evidence")
	FileAccess.open("res://doc/evidence/cruise-review-presentation.md" if "--presentation-only" in OS.get_cmdline_user_args() else "res://doc/evidence/cruise-review.md", FileAccess.WRITE).store_string(report)
	print("CRUISE_CONTROLS failures=%d" % failures)
	game.queue_free()
	game = null
	await process_frame
	await process_frame
	quit(1 if failures else 0)
