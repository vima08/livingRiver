extends SceneTree

# Independent UI critic. Locations are explicitly staged through isolated profiles.
# Mouse and key events traverse the viewport; mooring uses normal 60 Hz physics.
const Text = preload("res://scripts/localization.gd")
const Profile = preload("res://scripts/player_profile.gd")
var game: Node
var failures := 0
var rows: Array[String] = []
var suffix := "720"

func _initialize() -> void:
	call_deferred("review")

func check(ok: bool, label: String) -> void:
	rows.append(("PASS " if ok else "FAIL ") + label)
	print(rows.back())
	if not ok: failures += 1

func settle() -> void:
	await create_timer(0.12).timeout

func key(code: int, held: bool = false) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await settle()
	if not held:
		e = e.duplicate()
		e.pressed = false
		Input.parse_input_event(e)
		await settle()

func release(code: int) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = false
	Input.parse_input_event(e)
	await settle()

func find_button(label: String, node: Node = null, index: Array = [0]) -> Button:
	if node == null: node = game
	if node is Button and node.is_visible_in_tree() and node.text == label:
		if index[0] == 0: return node
		index[0] -= 1
	for child in node.get_children():
		var result := find_button(label, child, index)
		if result != null: return result
	return null

func click(source: String, nth: int = 0) -> void:
	var b := find_button(Text.t(source), null, [nth])
	check(b != null, "Button visible: " + source)
	if b == null: return
	var e := InputEventMouseButton.new()
	e.position = b.get_global_rect().get_center() * (Vector2(root.size) / Vector2(1280, 720))
	e.global_position = e.position
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	Input.parse_input_event(e)
	await settle()
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await settle()

func capture(label: String) -> void:
	await game.save_capture("map5_%s_%s_%s.png" % [suffix, Text.locale, label])

func stage(origin: String) -> void:
	var p := Profile.new("", false)
	if origin == "luma": p.award_order(p.begin_mission("base_full"), "luma_food")
	if origin == "koya": p.award_order(p.begin_mission("base_light"), "koya_filters")
	game.profile = p
	game.open_map()
	await settle()
	check(game.front_end.inspected_landing == origin, "Map entry inspects current saved landing")

func review() -> void:
	suffix = "540" if "--small" in OS.get_cmdline_user_args() else "720"
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	game.set_meta("show_frontend", true)
	root.add_child(game)
	await settle()
	await key(KEY_ENTER)
	check(game.ui_screen == "menu", "Startup Enter selects language only")
	await key(KEY_ENTER)
	check(game.ui_screen == "map" and game.mission_id == 0, "Separate Play Enter opens map only")
	for locale in ["en", "ru"]:
		game.settings.set_locale(locale)
		Text.set_locale(locale)
		for origin in ["base", "koya", "luma"]:
			await stage(origin)
			if origin == "base":
				for step in range(6): await key(KEY_TAB)
				await key(KEY_ENTER)
				check(game.state == "ready" and game.ui_screen.is_empty() and game.mission_id == 0, "Keyboard Tab focus and Enter open unissued local briefing")
				await key(KEY_ESCAPE)
				check(game.ui_screen == "map" and game.mission_id == 0, "Keyboard Escape backs out without launching")
			await capture(origin + "_map")
			var snapshot: Array = [game.boat_pos, game.profile.current_landing, game.profile.next_mission_id, game.profile.credits]
			var remote := "Koya Landing" if origin != "koya" else "Base"
			await click(remote)
			check(snapshot == [game.boat_pos, game.profile.current_landing, game.profile.next_mission_id, game.profile.credits], locale + "/" + origin + " remote inspect preserves position/progression")
			var disabled := find_button(Text.t("Choose contract"))
			check(disabled != null and disabled.disabled, "Remote departure disabled")
			await capture(origin + "_remote")
			await stage(origin)
			await click("Choose contract", 1 if origin == "luma" else 0)
			check(game.state == "ready" and game.ui_screen.is_empty() and game.mission_id == 0, "Contract click opens unissued briefing")
			await capture(origin + "_briefing")
			await click("Back / Landing map")
			check(game.ui_screen == "map" and game.profile.current_landing == origin and game.mission_id == 0, "Briefing Back retains landing and mission counter")
			await click("Choose contract", 1 if origin == "luma" else 0)
			await key(KEY_ENTER)
			check(game.state == "running" and game.profile.next_mission_id == snapshot[2] + 1, "Separate Cast off Enter issues exactly one mission")
			await capture(origin + "_running")
			if origin in ["koya", "luma"]:
				game.boat_pos.y += 800.0
				game.camera_y = game.boat_pos.y - 200.0
				await settle()
				await capture(origin + "_south_banner")
			await key(KEY_ESCAPE)
			await capture(origin + "_pause")
			await click("Settings")
			var before: Array = [game.boat_pos, game.mission_id, game.fuel, game.hull, game.elapsed]
			await click("Back")
			check(game.state == "paused" and game.ui_screen.is_empty() and before == [game.boat_pos, game.mission_id, game.fuel, game.hull, game.elapsed], "Settings Back preserves paused run")
			await click("Abandon leg / Landing map")
			check(game.ui_screen == "map" and game.profile.current_landing == origin and game.boat_pos == game.landing_position(origin), "Abandon recovers saved landing")
			await click("Choose contract", 1 if origin == "luma" else 0)
			await key(KEY_ENTER)
			await key(KEY_R)
			check(game.ui_screen == "map" and game.profile.current_landing == origin and game.boat_pos == game.landing_position(origin), "Physical R recovers saved landing map")
		await stage("luma")
		await click("Choose contract", 1)
		check(game.manifest.orders.is_empty(), "Empty briefing has zero orders")
		await key(KEY_ENTER)
		game.boat_pos = game.base_pos
		game.velocity = Vector2.ZERO
		game.camera_y = -200.0
		var credits: int = game.profile.credits
		await key(KEY_E, true)
		await create_timer(3.2).timeout
		await release(KEY_E)
		check(game.state == "success" and game.profile.current_landing == "base" and game.profile.credits == credits and game.run_support == 0, "Normal physics E hold commits staged empty Base mooring without reward")
		await capture("empty_result")
		await click("Plan next trip")
		check(game.ui_screen == "map" and game.profile.current_landing == "base", "Result plans trip from committed Base")
		await stage("luma")
		await click("River depot")
		game.settings.set_volume("music", 0.17)
		await click("Reset progression")
		check(game.profile.current_landing == "luma", "First reset click is confirmation only")
		await click("Confirm reset")
		check(game.profile.current_landing == "base" and game.profile.credits == 0 and game.settings.locale == locale and game.settings.music == 0.17, "Confirmed reset retains language/audio and clears landing/progression")
		var bad_path := "res://.godot/map5-invalid-profile.json"
		var bad_file := FileAccess.open(bad_path, FileAccess.WRITE)
		bad_file.store_string("{\"version\":99}")
		bad_file.close()
		var bad_profile := Profile.new(bad_path, true)
		bad_profile.load_profile()
		game.profile = bad_profile
		game.open_map()
		await settle()
		await click("Choose contract")
		var counter: int = game.profile.next_mission_id
		await key(KEY_ENTER)
		check(game.state == "ready" and game.mission_id == 0 and game.profile.next_mission_id == counter and game.profile.mutation_blocked, "Protected invalid profile launch remains unissued and ready")
		check(FileAccess.get_file_as_string(bad_path) == "{\"version\":99}", "Invalid original file preserved by actual launch attempt")
		await capture("protected_profile_launch")
	var f := FileAccess.open("res://doc/evidence/map5-ui-" + suffix + ".txt", FileAccess.WRITE)
	f.store_string("\n".join(rows) + "\nFailures: %d\n" % failures)
	print("MAP_GRAPHICAL5 failures=%d" % failures)
	quit(1 if failures else 0)
