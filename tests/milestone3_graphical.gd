extends SceneTree

# Critic-owned evidence: normal-speed staged input is separate from the full pilot.
var game: Node
var frame := 0
var failures := 0
var results: Array[String] = []
var motion := false
var finished := false
var samples: Dictionary = {}
var captures: Dictionary = {}

func _initialize() -> void:
	call_deferred("setup")

func setup() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	motion = "--motion" in OS.get_cmdline_user_args()
	if not motion:
		game.set_physics_process(false)
		game.select_load("full")
		game.start_run()
		game.select_gear(2)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func click(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)

func check(ok: bool, label: String) -> void:
	results.append(("PASS " if ok else "FAIL ") + label)
	print(results.back())
	if not ok:
		failures += 1

func capture(label: String) -> void:
	if not captures.has(label):
		captures[label] = true
		game.save_capture.call_deferred("step3_critic_" + label + ".png")

func finish() -> void:
	var report := "# Milestone 3 graphical harness results\n\n"
	report += "Normal-speed 30 fps staged physical-key and actual-button input. Positions are staged only at the start of each named scenario. Not a human playtest.\n\n" if motion else "Complete full-load starter wide-channel route. 24 fixed 1/60-second simulation steps per rendered frame; accelerated analog pilot, no teleports or resource changes within route.\n\n"
	for result in results:
		report += "- " + result + "\n"
	report += "\nSamples: " + JSON.stringify(samples) + "\n"
	FileAccess.open("res://doc/evidence/step3_critic_%s.md" % ("motion" if motion else "route"), FileAccess.WRITE).store_string(report)
	# Deferred screenshots must finish before their viewport is released.
	await RenderingServer.frame_post_draw
	await process_frame
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

func stage_stop(stop: String) -> void:
	key(KEY_W, false)
	key(KEY_SPACE, false)
	key(KEY_E, false)
	game.boat_pos = (game.luma_pos if stop == "luma" else game.dock_pos) + Vector2(0, 195)
	game.velocity = Vector2(0, -155)
	game.camera_y = game.boat_pos.y - 520
	game.select_gear(1)
	key(KEY_W, true)

func _process(_delta: float) -> bool:
	if finished or not is_instance_valid(game):
		return false
	frame += 1
	if not motion:
		for i in range(24):
			var controls: Array = game.pilot_controls()
			game.simulate(1.0 / 60, controls[0], controls[1], controls[2])
			if game.state != "running":
				break
		if game.boat_pos.distance_to(game.luma_pos) < 200:
			capture("route_luma_approach")
		if game.completed_order("luma_food"):
			capture("route_luma_delivered")
		if game.boat_pos.distance_to(game.dock_pos) < 200:
			capture("route_koya_approach")
		if game.state != "running":
			check(game.state == "success" and game.run_support == 160, "Complete graphical full relief route delivers both orders and pays 160")
			check(game.fuel >= 5, "Starter wide-channel full route retains five fuel")
			samples = {"seconds": game.elapsed, "fuel": game.fuel, "hull": game.hull, "support": game.run_support}
			capture("route_full_result")
			finished = true
			finish.call_deferred()
		return false
	match frame:
		5: capture("motion_briefing")
		10: click(Vector2(820, 417), true)
		11: click(Vector2(820, 417), false)
		15:
			check(game.load_preset == "full", "Actual full-load briefing button selects food and filters")
			key(KEY_ENTER, true)
		16: key(KEY_ENTER, false)
		20:
			key(KEY_2, true)
			key(KEY_W, true)
		21: key(KEY_2, false)
		32:
			samples.heavy_speed = game.velocity.length()
			capture("motion_heavy_acceleration")
		65:
			key(KEY_W, false)
			key(KEY_SPACE, true)
		80:
			check(game.velocity.length() < 1, "Full load brakes to rest with Space")
			key(KEY_SPACE, false)
			key(KEY_R, true)
		81: key(KEY_R, false)
		85:
			check(game.state == "ready", "Physical R returns to briefing")
			click(Vector2(440, 417), true)
		86: click(Vector2(440, 417), false)
		90:
			check(game.load_preset == "light", "Actual light-load button selects filters only")
			key(KEY_ENTER, true)
		91: key(KEY_ENTER, false)
		95:
			key(KEY_2, true)
			key(KEY_W, true)
		96: key(KEY_2, false)
		107:
			samples.light_speed = game.velocity.length()
			check(samples.light_speed > samples.heavy_speed * 1.15, "Same-duration throttle visibly accelerates light load faster")
			capture("motion_light_acceleration")
		112:
			key(KEY_W, false)
			game.boat_pos = game.luma_pos
			game.camera_y = game.boat_pos.y - 520
			game.velocity = Vector2.ZERO
			key(KEY_E, true)
		125:
			check(game.run_support == 0 and not game.completed_order("koya_filters"), "Physical E with filters at Luma unloads nothing and grants no support")
			capture("motion_no_matching_cargo")
		130:
			key(KEY_W, false)
			key(KEY_E, false)
			key(KEY_R, true)
		131: key(KEY_R, false)
		135: click(Vector2(820, 417), true)
		136: click(Vector2(820, 417), false)
		140: key(KEY_ENTER, true)
		141: key(KEY_ENTER, false)
		145: stage_stop("luma")
		170: capture("motion_luma_approach")
		175:
			key(KEY_W, false)
			key(KEY_SPACE, true)
		195:
			check(game.can_deliver(), "Normal-speed staged Luma approach stops inside unload circle")
			key(KEY_E, true)
		220: capture("motion_luma_unloading")
		265:
			check(game.completed_order("luma_food") and not game.manifest.full_load() and game.state == "running", "Physical E delivers food and lightens boat while filters stay aboard")
			capture("motion_luma_delivered")
		280:
			key(KEY_E, false)
			key(KEY_SPACE, false)
			key(KEY_ESCAPE, true)
		281: key(KEY_ESCAPE, false)
		290:
			check(game.state == "paused", "Physical Escape pauses")
			key(KEY_ESCAPE, true)
		291: key(KEY_ESCAPE, false)
		300: stage_stop("koya")
		325:
			check(not "No matching cargo" in game.unload_notice, "Leaving completed Luma clears obsolete cargo feedback before Koya")
			capture("motion_koya_approach")
		330:
			key(KEY_W, false)
			key(KEY_SPACE, true)
		350:
			check(game.can_deliver(), "Normal-speed staged Koya approach stops inside unload circle")
			key(KEY_E, true)
		375: capture("motion_koya_unloading")
		420:
			check(game.state == "success" and game.run_support == 160, "Physical E at both docks reaches itemized full result")
			capture("motion_full_result")
		430:
			key(KEY_E, false)
			key(KEY_SPACE, false)
			key(KEY_B, true)
		431: key(KEY_B, false)
		440:
			check(game.state == "depot" and game.profile.credits == 160, "Physical B opens depot with both saved rewards")
			capture("motion_depot")
		445: click(Vector2(690, 539), true)
		446: click(Vector2(690, 539), false)
		450:
			check(game.state == "ready" and game.profile.credits == 160, "Actual depot Plan next run button returns to briefing retaining support")
			key(KEY_ENTER, true)
		451: key(KEY_ENTER, false)
		455:
			check(game.state == "running" and game.load_preset == "full", "Physical Enter launches replay from depot-planned briefing")
			game.boat_pos = game.luma_pos
			game.velocity = Vector2.ZERO
			game.complete_order("luma")
			game.fuel = 0.001
		460:
			check(game.state == "failure" and game.run_support == 60, "Staged fuel failure retains food support and returns filters")
			capture("motion_failure_after_luma")
		480:
			finished = true
			finish.call_deferred()
	return false


