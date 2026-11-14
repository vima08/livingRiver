extends SceneTree

var game: Node
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func place(y: float, offset: float) -> void:
	game.reset_run()
	game.start_run()
	game.boat_pos = Vector2(game.river_center(y) + offset, y)
	game.camera_y = y - 520

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	check(game.select_gear(2), "Briefing accepts available second gear")
	game.start_run()
	check(game.selected_gear == 2, "Cast off preserves briefing gear selection")
	var fixture: Resource = game.engine.duplicate()
	fixture.forward_speeds = PackedFloat32Array([1, 2, 3, 4, 5, 6, 7, 8, 9])
	fixture.forward_accelerations = PackedFloat32Array([1, 1, 1, 1, 1, 1, 1, 1, 1])
	check(not fixture.valid_data(), "Reject nine forward gears because 9 is reverse")
	fixture.forward_speeds = PackedFloat32Array([95, 95])
	fixture.forward_accelerations = PackedFloat32Array([260, 210])
	check(not fixture.valid_data(), "Reject non-increasing speed curve")
	fixture.forward_speeds = PackedFloat32Array([95, NAN])
	check(not fixture.valid_data(), "Reject non-finite speed curve")
	fixture.forward_speeds = PackedFloat32Array([95, 155])
	fixture.forward_accelerations = PackedFloat32Array([260, 0])
	check(not fixture.valid_data(), "Reject zero acceleration")
	for frozen: String in ["ready", "paused", "success", "failure", "depot"]:
		place(-9400, 185)
		game.velocity = Vector2(20, -100)
		game.state = frozen
		var before := [game.boat_pos, game.velocity, game.camera_y, game.elapsed, game.fuel, game.hull, game.unload_progress]
		game.simulate(1.0, Vector2(1, -1), false, true)
		check(before == [game.boat_pos, game.velocity, game.camera_y, game.elapsed, game.fuel, game.hull, game.unload_progress], frozen + " freezes all river simulation")
	for y: float in [-3500, -5500, -7600, -11200]:
		for offset: float in [-155, 185]:
			var center: float = game.river_center(y)
			var left: Vector2 = game.current_at(Vector2(center + offset, y - 0.1))
			var right: Vector2 = game.current_at(Vector2(center + offset, y + 0.1))
			check(left.distance_to(right) < 0.01, "Smooth force boundary y=%.0f offset=%.0f" % [y, offset])
	for offset: float in [-155, 185]:
		var positions: Array[Vector2] = []
		var fuels: Array[float] = []
		for hz: int in [30, 60, 120]:
			place(-8500, offset)
			game.select_gear(2)
			for i in range(hz * 3):
				game.simulate(1.0 / hz, Vector2(0, -1), false, false)
			positions.append(game.boat_pos)
			fuels.append(game.fuel)
		check(positions[0].distance_to(positions[2]) < 4.0, "Fork 30/120Hz position tolerance <4 units offset %.0f (%.3f)" % [offset, positions[0].distance_to(positions[2])])
		check(absf(fuels[0] - fuels[2]) < 0.001, "Fork delta-aware fuel offset %.0f" % offset)
		place(-9400, offset)
		game.select_gear(9)
		for i in range(300):
			game.simulate(1.0 / 60, Vector2(0, -1), false, false)
		check(game.boat_pos.y > -9200 and game.hull == 100, "Starter reverse escapes opposing/assisting fork flow offset %.0f" % offset)
		place(-9400, offset)
		game.select_gear(1)
		for i in range(120):
			game.simulate(1.0 / 60, Vector2(0.3 if offset < 0 else -0.3, -1), false, false)
		check(game.state == "running" and game.hull > 60, "Poor approach remains recoverable offset %.0f" % offset)
	place(-4300, 0)
	var before: Vector2 = game.boat_pos
	game.simulate(0.1, Vector2.ZERO, false, false)
	check(game.boat_pos.is_equal_approx(before + game.velocity * 0.1) and is_equal_approx(game.camera_y, game.boat_pos.y - 520), "Current once only with camera exactly derived from position")
	check(is_equal_approx(game.speed_kmh(), game.boat_pos.distance_to(before) / 0.1 * 0.18), "Speed includes lateral and north/south drift")
	game.reset_run()
	check(game.current_at(game.boat_pos) == Vector2.ZERO and game.velocity == Vector2.ZERO and game.unload_progress == 0 and game.selected_gear == 1, "Restart clears current interaction and controls")
	quit(1 if failures else 0)
