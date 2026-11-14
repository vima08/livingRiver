extends SceneTree

var game: Node
var results: Array[String] = []
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	results.append(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func fresh() -> void:
	game.reset_run()
	game.select_load("full")
	game.start_run()
	game.boat_pos = game.luma_pos
	game.velocity = Vector2.ZERO

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	fresh()
	game.velocity = Vector2(46, 0)
	check(not game.can_deliver() and not game.complete_order("luma"), "Lateral ground speed above threshold prevents unloading")
	game.velocity = Vector2(27, 36)
	check(not game.can_deliver(), "Combined ground speed at threshold prevents unloading")
	game.velocity = Vector2(20, 0)
	var old_velocity: Vector2 = game.velocity
	var old_position: Vector2 = game.boat_pos
	check(game.complete_order("luma"), "Matching low-speed food unload completes")
	check(game.velocity == old_velocity and game.boat_pos == old_position, "Food removal never jumps position or rescales velocity")
	check(not game.manifest.full_load() and game.manifest.pending_for_stop("koya").size() > 0, "Food removal restores light handling while retaining filters")
	var balance: int = game.profile.credits
	game.open_depot()
	game.buy_engine()
	check(game.state == "running" and game.profile.credits == balance, "Active mission cannot open depot or purchase equipment")
	fresh()
	for frame in range(60):
		game.simulate(1.0 / 60, Vector2.ZERO, true, true)
	check(game.unload_progress > 0.9 and game.unload_progress < 1.1, "Holding E accumulates actual dwell time")
	game.boat_pos = game.dock_pos
	game.simulate(1.0 / 60, Vector2.ZERO, true, true)
	check(game.unload_progress < 0.02 and game.manifest.completed_count() == 0, "Switching stops discards prior dock progress")
	game.state = "paused"
	var previous_progress: float = game.unload_progress
	var previous_fuel: float = game.fuel
	game.simulate(1, Vector2.ZERO, true, true)
	check(game.unload_progress == previous_progress and game.fuel == previous_fuel, "Paused simulation preserves resources and unloading progress")
	game.set_physics_process(true)
	Input.action_press("restart")
	await physics_frame
	await process_frame
	Input.action_release("restart")
	game.set_physics_process(false)
	check(game.state == "ready" and game.manifest.completed_count() == 0 and game.unload_progress == 0 and game.profile.credits == balance, "Restart action returns briefing and clears cargo progress while preserving support")
	game.select_load("light")
	check(game.manifest.total_count() == 1, "Restart permits choosing a different load")
	game.start_run()
	game.boat_pos = Vector2(game.river_center(-4500), -4500)
	game.velocity = Vector2.ZERO
	var flow: Vector2 = game.current_at(game.boat_pos)
	game.simulate(1.0 / 60, Vector2.ZERO, false, false)
	check(game.velocity.dot(flow) > 0 and game.speed_kmh() > 0, "Bounded river current still causes ground drift without throttle")
	var report := "# Independent gameplay critic: third milestone\n\nFunctional verdict: **PASS** for inspected order, weight, interaction, and route contracts. Integrated verdict: **BLOCKED** pending normal-speed graphical motion and human handling feedback.\n\nInspected `main.gd`, `relief_manifest.gd`, HUD, profile API, `thirdSteps.md`, and actual delivery-check output. Ran the independent adversarial simulation below with a test-mode in-memory profile. Docks are staged, and Input actions are synthetic; these are not a human playtest.\n\n"
	for result in results:
		print(result)
		report += "- " + result + "\n"
	report += "\nThe separate complete-route simulation artifact (`delivery-checks3.md`) records all four starter preset/channel combinations finishing with 14.6–23.7 fuel, above the five-unit reserve, and the upgraded full route finishing with 19.9 fuel. Full load adds about 2.8 seconds with the pilot, despite a measured 20% acceleration reduction and longer braking distance. This meets viability; whether this trade-off is meaningful to a player remains unproven. Its upgraded pilot takes 15.5 hull damage, so it demonstrates completion rather than a clean upgraded route.\n\nLargest remaining gap: demonstrate normal-speed handling and both actual dock approaches, then obtain the required human load-choice/handling feedback. Still images, staged docks, and accelerated analog pilots cannot establish that gate. Persistence transactions are covered by a separate independent critic; this scoped review does not approve disk recovery.\n"
	FileAccess.open("res://doc/evidence/delivery-review3.md", FileAccess.WRITE).store_string(report)
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
