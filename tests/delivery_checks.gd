extends SceneTree

var game: Node
var failures := 0
var results: Array[String] = []
var runs: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	results.append(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func fresh(load_name: String = "full") -> void:
	game.reset_run()
	game.select_load(load_name)
	game.start_run()
	game.select_gear(2)

func stage_dock(stop: String) -> void:
	game.boat_pos = game.luma_pos if stop == "luma" else game.dock_pos
	game.velocity = Vector2.ZERO
	game.camera_y = game.boat_pos.y - 520
	for i in range(125):
		game.simulate(1.0 / 60, Vector2.ZERO, true, true)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	game.select_load("full")
	game.manifest.orders.append(game.manifest.orders[0].duplicate())
	game.start_run()
	check(game.state == "ready" and game.mission_id == 0, "Over-capacity manifest cannot launch or allocate a run")
	game.select_load("full")
	game.manifest.orders[1] = game.manifest.orders[0].duplicate()
	game.start_run()
	check(game.state == "ready", "Duplicate cargo orders cannot launch")
	game.select_load("full")
	game.manifest.orders[0].reward = NAN
	game.start_run()
	check(game.state == "ready", "Non-finite cargo reward cannot launch")
	check(game.select_load("full") and game.manifest.total_count() == 2 and game.manifest.full_load(), "Full preset loads exactly matching food and filters")
	check(not game.select_load("empty") and game.load_preset == "full", "Unknown load cannot replace valid manifest")
	game.start_run()
	check(not game.select_load("light"), "Manifest is locked during active run")
	stage_dock("luma")
	check(game.completed_order("luma_food") and not game.completed_order("koya_filters") and game.state == "running", "Food unloading continues run with filters aboard")
	check(game.profile.credits == 60 and game.run_support == 60 and not game.manifest.full_load(), "First delivery commits60 and lightens boat")
	check(game.unload_notice.contains("support saved") and not game.unload_notice.contains("No matching"), "Held E preserves successful food receipt while still at Luma")
	game.boat_pos = Vector2(game.river_center(-15000), -15000)
	game.simulate(1.0 / 60, Vector2.ZERO, true, false)
	check(game.unload_notice.is_empty(), "Leaving a landing clears its stop-specific notice")
	stage_dock("luma")
	check(game.profile.credits == 60, "Holding E at completed stop cannot repay")
	stage_dock("koya")
	check(game.state == "success" and game.delivered and game.run_support == 160 and game.profile.credits == 160, "Two matching orders complete with160 support")
	game.reset_run()
	check(game.state == "ready" and game.profile.credits == 160 and game.manifest.completed_count() == 0 and game.run_support == 0, "Restart returns briefing, clears run receipts visually, keeps saved credits")
	fresh("light")
	var prior: int = game.profile.credits
	stage_dock("luma")
	check(game.manifest.completed_count() == 0 and game.profile.credits == prior and not game.can_deliver(), "Light load cannot unload filters at food landing")
	stage_dock("koya")
	check(game.state == "success" and game.run_support == 100, "Light run remains one-stop success")
	fresh()
	stage_dock("koya")
	check(game.state == "partial" and not game.delivered and game.run_support == 100 and not game.completed_order("luma_food"), "Skipping food ends with explicit partial result and onlyfilter reward")
	fresh()
	stage_dock("luma")
	prior = game.profile.credits
	game.fuel = 0.001
	game.simulate(1.0 / 60, Vector2.ZERO, false, false)
	check(game.state == "failure" and game.profile.credits == prior and game.run_support == 60, "Failure after food retains committed support and itemized partial aid")
	fresh()
	game.boat_pos = game.luma_pos
	game.velocity = Vector2.ZERO
	prior = game.profile.credits
	game.profile._persistence = true
	game.profile._save_path = "res://tmp/missing_delivery_%d/profile.json" % Time.get_ticks_usec()
	stage_dock("luma")
	check(not game.completed_order("luma_food") and game.profile.credits == prior and game.manifest.full_load() and not game.unload_notice.is_empty(), "Failed save retains cargo, weight and credits with retry notice")
	game.profile._persistence = false
	stage_dock("luma")
	check(game.completed_order("luma_food") and game.profile.credits == prior + 60, "Reward-save retry commits once after storage recovers")
	stage_dock("luma")
	check(game.profile.credits == prior + 60, "Repeated retry cannot duplicate committed reward")
	# Identical starting conditions isolate weight from engine and river flow.
	var measurements: Array[Dictionary] = []
	for load_name in ["light", "full"]:
		fresh(load_name)
		game.select_gear(2)
		for i in range(20):
			game.simulate(1.0 / 60, Vector2(0, -1), false, false)
		var accel_speed: float = -game.velocity.y
		game.velocity = Vector2(0, -155)
		var start_y: float = game.boat_pos.y
		for i in range(80):
			game.simulate(1.0 / 60, Vector2.ZERO, true, false)
		measurements.append({"speed": accel_speed, "stopping": start_y - game.boat_pos.y})
	check(measurements[1].speed < measurements[0].speed * 0.85, "Full cargo reduces acceleration by20percent at samegear/input")
	check(measurements[1].stopping > measurements[0].stopping * 1.15, "Full cargo requires longer braking distance")
	for load_name in ["light", "full"]:
		for branch in ["safe", "rapids"]:
			fresh(load_name)
			game.pilot_branch = branch
			game.pilot_skip_luma = false
			for frame in range(60 * 250):
				var input: Array = game.pilot_controls()
				game.simulate(1.0 / 60, input[0], input[1], input[2])
				if game.state != "running":
					break
			var snapshot := {"load": load_name, "branch": branch, "engine": game.engine.display_name, "seconds": game.elapsed, "hull": game.hull, "fuel": game.fuel, "support": game.run_support, "state": game.state}
			runs.append(snapshot)
			check(game.state == "success", "%s/%s starter full route succeeds" % [load_name, branch])
			check(game.fuel >= 5 and game.hull > 0, "%s/%s starter finishes with at least5 fuel reserve" % [load_name, branch])
			check(game.run_support == (160 if load_name == "full" else 100), "%s/%s grants exactly manifest support" % [load_name, branch])
	fresh()
	game.reset_run()
	game.open_depot()
	game.buy_engine()
	game.equip_engine("river_triple")
	game.close_depot()
	game.start_run()
	game.select_gear(3)
	game.pilot_branch = "rapids"
	for frame in range(60 * 240):
		var input: Array = game.pilot_controls()
		game.simulate(1.0 / 60, input[0], input[1], input[2])
		if game.state != "running":
			break
	runs.append({"load": "full", "branch": "rapids", "engine": game.engine.display_name, "seconds": game.elapsed, "hull": game.hull, "fuel": game.fuel, "support": game.run_support, "state": game.state})
	check(game.state == "success" and game.run_support == 160, "Purchased upgrade completes both relief deliveries")
	var report := "# Third-milestone delivery checks\n\nReal simulation with isolated in-memory profile. Staged docks are explicit unit scenarios; complete route runs below use no position/fuel staging. Not a human playtest.\n\n"
	for result in results:
		print(result)
		report += "- " + result + "\n"
	report += "\n| Load | Branch | Engine | Seconds | Hull | Fuel | Support | State |\n|---|---|---|---:|---:|---:|---:|---|\n"
	for result in runs:
		var row := "| %s | %s | %s | %.2f | %.1f | %.1f | %d | %s |" % [result.load, result.branch, result.engine, result.seconds, result.hull, result.fuel, result.support, result.state]
		print(row)
		report += row + "\n"
	report += "\nWeight comparison: " + str(measurements) + "\n"
	FileAccess.open("res://doc/evidence/delivery-checks3.md", FileAccess.WRITE).store_string(report)
	quit(1 if failures else 0)
