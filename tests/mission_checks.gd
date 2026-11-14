extends SceneTree

var game: Node
var failures := 0
var results: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	results.append(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	# Exercise a full route through the real simulation, using visible center water.
	for frame in range(60 * 230):
		var controls: Array = game.pilot_controls()
		game.simulate(1.0 / 60, controls[0], controls[1], controls[2])
		if game.state != "running":
			break
	check(game.state == "success", "Full authored route completes with delivery")
	check(game.elapsed > 150 and game.elapsed < 210, "Successful route is roughly three minutes: %.2fs" % game.elapsed)
	check(game.pickup_taken, "Full run collects midpoint refuel buoy")
	check(game.hull > 0 and game.fuel > 0, "Full run preserves hull and fuel: %.1f / %.1f" % [game.hull, game.fuel])
	check(game.delivered, "Success enables village feedback")
	var terminal_time: float = game.elapsed
	var terminal_fuel: float = game.fuel
	game.simulate(10, Vector2.ONE, false, true)
	check(game.elapsed == terminal_time and game.fuel == terminal_fuel, "Terminal state stops mission simulation")
	game.reset_run()
	check(game.state == "ready" and game.elapsed == 0 and game.fuel == 100 and game.hull == 100 and not game.pickup_taken and not game.delivered and game.velocity == Vector2.ZERO and game.boat_pos == Vector2(640, 0) and game.camera_y == -520 and game.unload_progress == 0 and not game.low_fuel_warned, "Restart restores mission, boat, camera, village, pickup and resources")
	game.start_run()
	game.fuel = 0.001
	game.simulate(1.0 / 60, Vector2.ZERO, true, false)
	check(game.state == "failure" and game.failure_reason.begins_with("Fuel"), "Fuel exhaustion causes clear failure")
	game.reset_run()
	game.start_run()
	game.hull = 1
	game.boat_pos = game.rocks[0].pos + Vector2(0, 30)
	game.velocity = Vector2(0, -150)
	game.simulate(1.0 / 60, Vector2.ZERO, false, false)
	check(game.state == "failure" and game.failure_reason.begins_with("Hull"), "Actual rock collision can cause hull failure")
	game.reset_run()
	game.start_run()
	game.fuel = 95
	game.boat_pos = game.fuel_pickup
	game.simulate(1.0 / 60, Vector2.ZERO, true, false)
	check(game.pickup_taken and game.fuel == 100, "Fuel pickup is capped at maximum")
	game.fuel = 50
	game.simulate(1.0 / 60, Vector2.ZERO, true, false)
	check(game.fuel < 50, "Fuel pickup cannot be collected twice")
	game.boat_pos = Vector2(640, 0)
	for i in range(180):
		game.simulate(1.0 / 60, Vector2.ZERO, true, true)
	check(not game.delivered and game.unload_progress == 0, "Cannot unload away from dock")
	game.boat_pos = game.dock_pos
	game.velocity = Vector2(0, -150)
	check(not game.can_deliver(), "Cannot unload at excessive speed")
	game.velocity = Vector2.ZERO
	check(game.can_deliver(), "Dock allows unloading when stationary")
	game.simulate(0.5, Vector2.ZERO, true, true)
	game.simulate(1.0 / 60, Vector2.ZERO, true, false)
	check(game.unload_progress == 0, "Releasing interaction resets unloading progress")
	game.state = "paused"
	terminal_time = game.elapsed
	terminal_fuel = game.fuel
	game.simulate(5, Vector2.ONE, false, true)
	check(game.elapsed == terminal_time and game.fuel == terminal_fuel, "Pause stops boat and resource simulation")
	# Compare real movement after ten seconds at two fixed step sizes.
	var positions: Array[Vector2] = []
	for rate in [60, 120]:
		game.reset_run()
		game.start_run()
		for frame in range(rate * 10):
			game.simulate(1.0 / rate, Vector2.ZERO, false, false)
		positions.append(game.boat_pos)
	check(positions[0].distance_to(positions[1]) < 2, "Movement remains consistent at 60/120 simulation steps")
	DirAccess.make_dir_recursive_absolute("res://doc/evidence")
	var report := "# Mission simulation checks\n\nGodot %s. Real game simulation, scripted controls; not a human playtest.\n\n" % Engine.get_version_info().string
	for result in results:
		print(result)
		report += "- " + result + "\n"
	FileAccess.open("res://doc/evidence/mission-checks.md", FileAccess.WRITE).store_string(report)
	print("Failures: ", failures)
	quit(1 if failures else 0)
