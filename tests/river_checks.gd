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

func place(y: float, x_offset: float = 0) -> void:
	game.boat_pos = Vector2(game.river_center(y) + x_offset, y)
	game.velocity = Vector2.ZERO
	game.camera_y = y - 520

func complete_run(branch: String, upgraded: bool) -> Dictionary:
	game.reset_run()
	if upgraded:
		game.profile.credits = 100
		game.open_depot()
		game.buy_engine()
		game.equip_engine("river_triple")
		game.close_depot()
	game.start_run()
	game.select_gear(3 if upgraded else 2)
	game.pilot_branch = branch
	for frame in range(60 * 260):
		var input: Array = game.pilot_controls()
		game.simulate(1.0 / 60, input[0], input[1], input[2])
		if game.state != "running":
			break
	return {"engine": game.engine.display_name, "branch": branch, "seconds": game.elapsed, "fuel": game.fuel, "hull": game.hull, "state": game.state, "reward": game.reward_received}

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	check(game.current_at(Vector2(640, 0)) == Vector2.ZERO, "Starting area is still water")
	place(-4300)
	game.select_gear(2)
	for i in range(120):
		game.simulate(1.0 / 60, Vector2(0, -1), false, false)
	check(game.velocity.y > -130 and game.velocity.y < -110, "Gentle opposing current slows same forward throttle")
	game.reset_run()
	game.start_run()
	place(-4300)
	game.select_gear(9)
	for i in range(120):
		game.simulate(1.0 / 60, Vector2(0, -1), false, false)
	check(game.velocity.y > 125 and game.velocity.y < 140, "Same current assists reverse travel")
	game.reset_run()
	game.start_run()
	place(-4300)
	var before: Vector2 = game.boat_pos
	game.simulate(1.0 / 60, Vector2.ZERO, false, false)
	check(game.boat_pos.is_equal_approx(before + game.velocity / 60), "Current is integrated once in ground velocity")
	check(game.velocity.length() > 0 and game.speed_kmh() > 0, "Unpowered drift appears in speedometer")
	game.state = "paused"
	before = game.boat_pos
	var speed: Vector2 = game.velocity
	game.simulate(1, Vector2.ZERO, false, false)
	check(game.boat_pos == before and game.velocity == speed, "Pause freezes current-driven motion")
	var flow_a: Vector2 = game.current_at(Vector2(game.river_center(-3500), -3500))
	var flow_b: Vector2 = game.current_at(Vector2(game.river_center(-3501), -3501))
	check(flow_a.length() == 0 and flow_b.length() < 0.01, "Current entry fades in continuously")
	check(game.current_at(Vector2(game.river_center(-5500), -5500)).length() == 0, "Current zone has a bounded exit")
	var positions: Array[Vector2] = []
	for hz in [60, 120]:
		game.reset_run()
		game.start_run()
		place(-4300)
		game.select_gear(2)
		for i in range(hz * 3):
			game.simulate(1.0 / hz, Vector2(0, -1), false, false)
		positions.append(game.boat_pos)
	check(positions[0].distance_to(positions[1]) < 2, "Current movement 60/120 step difference under 2 world units")
	game.reset_run()
	game.start_run()
	place(-9400, 45)
	game.velocity = Vector2(0, -100)
	game.simulate(1.0 / 60, Vector2.ZERO, false, false)
	check(absf(game.boat_pos.x - game.island_center(game.boat_pos.y)) >= game.island_half_width(game.boat_pos.y) + 16, "Island collision ejects boat to visible water")
	check(game.hull < 100, "Island contact uses existing collision damage")
	check(game.current_at(game.dock_pos) == Vector2.ZERO, "Delivery dock remains in still water")
	for branch in ["safe", "rapids"]:
		var result := complete_run(branch, false)
		runs.append(result)
		check(result.state == "success", "Starter engine completes %s branch" % branch)
		check(result.fuel > 0 and result.hull > 0 and result.reward, "Starter %s branch preserves resources and rewards once" % branch)
		check(result.seconds > 150 and result.seconds < 210, "Starter %s branch remains roughly three minutes" % branch)
	check(runs[1].seconds + 5 < runs[0].seconds, "Rapids save at least five seconds over wide channel")
	check(runs[1].fuel > runs[0].fuel, "Rapids reduce total trip fuel despite steering demand")
	check(game.profile.equipped == "river_twin", "Starter remains usable without purchase")
	var upgraded := complete_run("rapids", true)
	runs.append(upgraded)
	check(upgraded.state == "success" and upgraded.reward, "Purchased equipped three-gear engine completes another delivery")
	check(upgraded.seconds < runs[1].seconds, "Third gear changes actual route time")
	# Compare fixed-time same-input fuel, independent of route-length savings.
	var consumption: Array[float] = []
	for id in ["river_twin", "river_triple"]:
		game.reset_run()
		game.open_depot()
		game.equip_engine(id)
		game.close_depot()
		game.start_run()
		game.select_gear(2)
		for i in range(600):
			game.simulate(1.0 / 60, Vector2(0, -1), false, false)
		consumption.append(100.0 - game.fuel)
	check(consumption[1] > consumption[0] * 1.17, "Triple consumes 18% more fuel for matched gear/throttle/time")
	var report := "# River and complete-run checks\n\nScripted simulation, test-only in-memory profile. No human handling claim.\n\n"
	for result in results:
		print(result)
		report += "- " + result + "\n"
	report += "\n## Complete runs\n\n| Engine | Branch | Seconds | Fuel | Hull | State |\n|---|---|---:|---:|---:|---|\n"
	for result in runs:
		var row := "| %s | %s | %.2f | %.1f | %.1f | %s |" % [result.engine, result.branch, result.seconds, result.fuel, result.hull, result.state]
		print(row)
		report += row + "\n"
	FileAccess.open("res://doc/evidence/river-checks.md", FileAccess.WRITE).store_string(report)
	quit(1 if failures else 0)
