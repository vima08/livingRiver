extends SceneTree

var game: Node
var failures := 0
var results: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	results.append(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	check(game.selected_gear == 1 and game.engine.gear_count() == 2, "Starter engine starts in first with two forward gears")
	game.start_run()
	check(not game.select_gear(3) and game.selected_gear == 1 and game.gear_notice_time > 0, "Unavailable gear leaves selection unchanged with feedback")
	check(not game.select_gear(0) and not game.select_gear(10), "Invalid gear numbers are rejected")
	for i in range(120):
		game.simulate(1.0 / 60, Vector2(0, -1), false, false)
	check(is_equal_approx(game.velocity.y, -95), "First gear caps forward drive at 95 units/s")
	check(game.select_gear(2), "Forward upshift accepted while moving")
	for i in range(120):
		game.simulate(1.0 / 60, Vector2(0, -1), false, false)
	check(is_equal_approx(game.velocity.y, -155), "Second gear reaches original cruising speed")
	check(is_equal_approx(game.speed_kmh(), 27.9), "Speedometer reports actual velocity with consistent meter scale")
	check(not game.select_gear(9) and game.selected_gear == 2, "Direction change at speed rejected without changing selection")
	for i in range(120):
		game.simulate(1.0 / 60, Vector2(0, 1), false, false)
	check(game.velocity == Vector2.ZERO, "S brakes to rest and never automatically reverses")
	check(game.select_gear(9), "Reverse selected after braking")
	for i in range(60):
		game.simulate(1.0 / 60, Vector2(0, -1), false, false)
	check(is_equal_approx(game.velocity.y, 100), "W throttle drives south in reverse gear")
	check(not game.select_gear(1), "Forward direction also requires braking from reverse")
	game.reset_run()
	check(game.selected_gear == 1 and game.speed_kmh() == 0 and game.gear_notice_time == 0, "Restart restores first gear, zero speed, and shift feedback")
	game.start_run()
	game.select_gear(9)
	for i in range(180):
		game.simulate(1.0 / 60, Vector2(0, -1), false, false)
	check(game.boat_pos.y == 90 and game.speed_kmh() == 0, "Starting boundary stops actual velocity and speedometer")
	check(game.select_gear(2), "Boundary stop permits safe direction recovery without phantom speed")
	game.boat_pos = Vector2(game.river_center(-26150), -26150)
	game.velocity = Vector2.ZERO
	game.simulate(1.0 / 60, Vector2(0, -1), false, false)
	check(game.boat_pos.y == -26150 and game.speed_kmh() == 0, "Far boundary also clears blocked forward velocity")
	game.reset_run()
	var upgraded: Resource = game.engine.duplicate()
	upgraded.forward_speeds = PackedFloat32Array([95, 155, 190])
	upgraded.forward_accelerations = PackedFloat32Array([260, 210, 170])
	game.engine = upgraded
	game.start_run()
	check(game.select_gear(3), "Data-defined three-gear engine accepts third gear without new control code")
	for i in range(120):
		game.simulate(1.0 / 60, Vector2(0, -1), false, false)
	check(is_equal_approx(game.velocity.y, -190), "Additional engine gear uses its own speed curve")
	game.state = "paused"
	check(not game.select_gear(1), "Paused mission cannot change gear")
	var report := "# Starter gearbox checks\n\nActual simulation and engine Resources. Three-gear engine is a test fixture, not a purchasable game item.\n\n"
	for result in results:
		print(result)
		report += "- " + result + "\n"
	FileAccess.open("res://doc/evidence/gear-checks.md", FileAccess.WRITE).store_string(report)
	quit(1 if failures else 0)
