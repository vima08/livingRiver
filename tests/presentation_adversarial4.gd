extends SceneTree

# Independent review: input events pass through the viewport and Input Map.
# Dock placement is staged; this does not establish whole-route playability.
var game: Node
var failures := 0
const Text = preload("res://scripts/localization.gd")

func _initialize() -> void:
	call_deferred("review")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func settle() -> void:
	await create_timer(0.075).timeout

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await settle()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await settle()

func button(label: String, node: Node = null) -> Button:
	if node == null:
		node = game.front_end
	if node is Button and node.text == label:
		return node
	for child in node.get_children():
		var found := button(label, child)
		if found != null:
			return found
	return null

func mouse(event: InputEvent) -> void:
	if DisplayServer.get_name() == "headless":
		root.push_input(event, true)
	else:
		Input.parse_input_event(event)

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await game.save_capture(name + ".png")

func click(label: String) -> void:
	var target := button(label)
	check(target != null, "Visible button exists: " + label)
	if target == null:
		return
	var event := InputEventMouseButton.new()
	event.position = target.get_global_rect().get_center()
	event.global_position = event.position
	var motion := InputEventMouseMotion.new()
	motion.position = event.position
	motion.global_position = event.position
	mouse(motion)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	mouse(event)
	await settle()
	event = event.duplicate()
	event.pressed = false
	mouse(event)
	await settle()

func snapshot() -> Array:
	return [game.state, game.boat_pos, game.velocity, game.fuel, game.hull,
		game.elapsed, game.unload_progress, game.mission_id, game.selected_gear,
		game.manifest.completed_count(), game.profile.next_mission_id, game.profile.credits]

func blocked_keys(screen: String) -> void:
	var before := snapshot()
	for code in [KEY_R, KEY_B, KEY_2, KEY_9]:
		await key(code)
	check(snapshot() == before and game.ui_screen == screen, screen + " captures R/B/gears without hidden mutation")

func review() -> void:
	if "--persist-seed" in OS.get_cmdline_user_args() or "--persist-reload" in OS.get_cmdline_user_args():
		await persistence_process()
		return
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	game.set_meta("show_frontend", true)
	root.add_child(game)
	await settle()
	check(game.ui_screen == "language", "First launch presents language chooser")
	await capture("step4_settings_critic_language")
	await blocked_keys("language")
	await key(KEY_ENTER)
	check(game.ui_screen == "menu" and game.state == "ready" and game.mission_id == 0, "Physical Enter chooses English without issuing mission")
	await capture("step4_settings_critic_menu")
	await blocked_keys("menu")
	await click("Credits")
	await blocked_keys("credits")
	await key(KEY_ENTER)
	check(game.ui_screen == "menu" and game.mission_id == 0, "Credits Back via Enter preserves unissued mission")
	await click("Settings")
	await blocked_keys("settings")
	await key(KEY_ENTER)
	check(game.ui_screen == "settings" and game.mission_id == 0, "Settings Enter activates language control without launching")
	await key(KEY_ESCAPE)
	check(game.ui_screen == "menu", "Escape returns Settings to menu")
	await key(KEY_ENTER)
	check(game.ui_screen.is_empty() and game.state == "ready" and game.mission_id == 0, "Play Enter opens briefing without double launch")
	check(game.select_load("full"), "Briefing selects full relief")
	await key(KEY_ENTER)
	check(game.state == "running" and game.mission_id > 0, "Separate Enter launches briefing")
	game.boat_pos = game.luma_pos
	game.velocity = Vector2.ZERO
	game.unload_progress = 0.8
	await key(KEY_ESCAPE)
	check(game.state == "paused", "Escape pauses actual running input path")
	await click("Settings")
	var paused := snapshot()
	await capture("step4_settings_critic_paused_settings")
	await blocked_keys("settings")
	await click("Русский")
	check(game.settings.locale == "ru" and snapshot() == paused, "Russian language change preserves paused cargo and mission")
	await click("English")
	for i in 5:
		game.simulate(1, Vector2(1, -1), false, true)
	await settle()
	check(snapshot() == paused, "Paused settings freezes cargo, unload hold, resources, mission and position")
	await click("Back")
	check(game.ui_screen.is_empty() and game.state == "paused" and snapshot() == paused, "Settings Back restores paused state without advancing simulation")
	await click("Resume")
	check(game.state == "running", "Mouse Resume restores active play")
	check(game.complete_order("luma"), "Staged Luma order commits 60 support")
	await key(KEY_ESCAPE)
	await click("End run and return to menu")
	check(game.ui_screen == "menu" and game.state == "ready" and game.mission_id == 0 and game.profile.credits == 60, "End run discards unfinished mission and retains committed support")
	await click("Play")
	check(game.state == "ready" and game.manifest.completed_count() == 0 and game.profile.credits == 60, "Replay opens fresh cargo briefing with committed support")
	game.settings.set_locale("ru")
	game.settings.set_volume("music", 0)
	game.settings.set_volume("master", 0)
	game.settings.set_volume("effects", 0)
	await settle()
	for bus_name in ["Master", "Music", "Effects"]:
		check(AudioServer.is_bus_mute(AudioServer.get_bus_index(bus_name)), bus_name + " zero sets true bus mute")
	game.open_depot()
	game.reset_progression()
	game.reset_progression()
	check(game.profile.credits == 0 and game.settings.locale == "ru" and game.settings.music == 0, "Confirmed depot reset preserves session language and volume")
	print("Independent presentation checks: %d failure(s)" % failures)
	quit(failures)

func persistence_process() -> void:
	# Caller must redirect APPDATA/LOCALAPPDATA to a dedicated empty test directory.
	var seeding := "--persist-seed" in OS.get_cmdline_user_args()
	if seeding:
		var profile = load("res://scripts/player_profile.gd").new()
		profile.load_profile()
		var mission: int = profile.begin_mission()
		check(profile.award_delivery(mission), "Separate process seeds committed support")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	if seeding:
		check(game.ui_screen == "language", "Persistent fresh process shows chooser")
		await click("Русский")
		await click(Text.t("Settings"))
		game.settings.set_volume("music", 0)
		game.settings.set_volume("effects", 0.65)
		game.settings.set_volume("master", 0.23)
		await click(Text.t("Back"))
	else:
		check(game.ui_screen == "menu" and game.settings.locale == "ru", "New process restores Russian and skips first chooser")
		check(game.settings.music == 0 and game.settings.effects == 0.65 and game.settings.master == 0.23, "New process restores separate volume settings")
		check(game.profile.credits == 100 and game.profile.next_mission_id == 2, "Menu quit/relaunch retains committed support without issuing mission")
	print("Persistent process checks: %d failure(s)" % failures)
	if failures:
		quit(failures)
		return
	await click(Text.t("Quit"))
	await settle()
	# Reaching this indicates Quit did not close the scene tree.
	check(false, "Quit button exits the process")
	quit(failures)
