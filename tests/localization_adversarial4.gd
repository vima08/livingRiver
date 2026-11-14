extends SceneTree

# Independent localization review. Screen poses are staged, not a route playtest.
const Text = preload("res://scripts/localization.gd")
var game: Node
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("review")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures.append(label)

func settle() -> void:
	await create_timer(0.12).timeout

func button(label: String, node: Node = null) -> Button:
	if node == null:
		node = game
	if node is Button and node.visible and node.text == label:
		return node
	for child in node.get_children():
		var found := button(label, child)
		if found != null:
			return found
	return null

func click(label: String) -> void:
	var target := button(label)
	check(target != null, "GUI button " + label)
	if target == null:
		return
	var motion := InputEventMouseMotion.new()
	motion.position = target.get_global_rect().get_center()
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = motion.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await settle()

func key(physical: int, logical: int = 0, unicode_value: int = 0, pressed: bool = true) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.keycode = physical if logical == 0 else logical
	event.unicode = unicode_value
	event.pressed = pressed
	Input.parse_input_event(event)
	await settle()

func capture(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var path := "res://doc/evidence/step4_localization_" + name + ".png"
	check(root.get_texture().get_image().save_png(path) == OK, "Capture " + name)

func review() -> void:
	Text.set_locale("ru")
	check(Text.catalog_errors.is_empty(), "Valid Russian placeholder signatures")
	var font := ThemeDB.fallback_font
	for row in [
		["B Depot / %d credits / %s / R keeps credits and engines", [0, "River Twin"], 15, 720],
		["Fuel exhausted. The relief crew is safe; plan your refuel stop.", [], 17, 640],
		["Hull damaged. The relief crew is safe; take a wider line.", [], 17, 640],
		["%s / %s: %s", ["Koya Landing", "Water filters", "undelivered / returns to depot"], 16, 640],
		["%s / %s: %s", ["Luma Landing", "Food", "undelivered / returns to depot"], 16, 640],
		["R returns to briefing. Credits and engines persist. Reset progression is separate.", [], 14, 840]]:
		var width := font.get_string_size(Text.t(row[0], row[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, row[2]).x
		print("METRIC ", row[0], " width=", width, " available=", row[3])
		if str(row[0]).begins_with("Hull damaged"):
			check(FileAccess.get_file_as_string("res://scripts/hud.gd").contains('paragraph(Vector2(130, y), game.localized_notice("failure_reason")'), "Long hull failure uses wrapped paragraph")
		else:
			check(width <= row[3], "Russian bounded line: " + row[0])
	if "--graphical" not in OS.get_cmdline_user_args():
		quit(0 if failures.is_empty() else 1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	game.set_meta("show_frontend", true)
	root.add_child(game)
	await settle()
	await capture("language")
	await click("Русский")
	check(game.ui_screen == "menu" and game.settings.locale == "ru", "Russian chooser enters menu")
	await capture("ru_menu")
	await click("Настройки")
	await capture("ru_settings")
	root.size = Vector2i(960, 540)
	await capture("ru_settings_960x540")
	await click("Назад")
	await click("Об игре")
	await capture("ru_credits_960x540")
	await click("Назад")
	await click("Играть")
	await capture("ru_briefing_960x540")
	root.size = Vector2i(1280, 720)
	await capture("ru_briefing")
	await click("Выбрать полный груз")
	await click("ENTER / Отправиться")
	check(game.state == "running", "Russian briefing mouse launch")
	var before: float = game.boat_pos.y
	# Russian logical key/Unicode with W's physical position, through Input Map.
	await key(KEY_W, 1062, 1094)
	await key(KEY_W, 1062, 1094, false)
	check(game.boat_pos.y < before, "Physical W with Russian logical Ц/ц applies throttle")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, 0, 0, false)
	check(game.state == "paused", "Escape pauses Russian run")
	await capture("ru_pause")
	await click("Настройки")
	await click("English")
	await capture("en_settings")
	root.size = Vector2i(960, 540)
	await capture("en_settings_960x540")
	await click("Русский")
	await click("Назад")
	await click("Продолжить")
	game.set_physics_process(false)
	root.size = Vector2i(1280, 720)
	game.boat_pos = game.luma_pos
	game.camera_y = game.boat_pos.y - 520
	game.velocity = Vector2.ZERO
	await capture("ru_luma")
	game.set_notice("unload_notice", "Delivery not saved. Cargo retained. Hold E to retry. %s", ["Profile could not be saved. The change was cancelled."])
	await capture("ru_delivery_save_error")
	game.unload_notice = ""
	game.boat_pos = game.dock_pos
	game.camera_y = game.boat_pos.y - 520
	await capture("ru_koya_partial_warning")
	check(game.complete_order("koya"), "Staged Koya partial delivery")
	await capture("ru_partial")
	game.reset_run()
	game.select_load("full")
	game.start_run()
	game.boat_pos = game.luma_pos
	game.velocity = Vector2.ZERO
	check(game.complete_order("luma"), "Staged Luma delivery")
	game.boat_pos = game.dock_pos
	check(game.complete_order("koya"), "Staged full delivery")
	await capture("ru_success")
	game.reset_run()
	game.select_load("full")
	game.start_run()
	game.set_notice("failure_reason", "Fuel exhausted. The relief crew is safe; plan your refuel stop.")
	game.state = "failure"
	await capture("ru_failure")
	game.set_notice("failure_reason", "Hull damaged. The relief crew is safe; take a wider line.")
	await capture("ru_hull_failure")
	game.open_depot()
	await capture("ru_depot")
	game.return_to_menu()
	await settle()
	await click("Настройки")
	game.settings.notice = "Settings could not be saved. Your choices remain active for this session."
	await capture("ru_settings_save_error")
	await click("English")
	await click("Back")
	await click("Play")
	await capture("en_briefing")
	root.size = Vector2i(960, 540)
	await capture("en_briefing_960x540")
	print("Localization review failures: ", failures)
	quit(0 if failures.is_empty() else 1)
