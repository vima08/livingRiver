extends SceneTree

var game: Node
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func deliver_staged() -> void:
	game.boat_pos = game.dock_pos
	game.velocity = Vector2.ZERO
	for frame in range(130):
		game.simulate(1.0 / 60, Vector2.ZERO, true, true)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	var buttons: Array = game.hud.canvas.depot_buttons
	game.open_depot()
	buttons[1].pressed.emit()
	check(game.profile.credits == 0 and game.profile.owned == ["river_twin"], "Depot Buy callback rejects insufficient funds")
	game.close_depot()
	game.start_run()
	game.open_depot()
	game.buy_engine()
	game.equip_engine("river_triple")
	game.reset_progression()
	check(game.state == "running" and game.engine.engine_id == "river_twin" and not game.reset_profile_pending, "Running state rejects depot, purchase, equipment and progression reset")
	deliver_staged()
	check(game.state == "success" and game.profile.credits == 100, "Real unloading transition awards support once (staged dock)")
	deliver_staged()
	check(game.profile.credits == 100, "Continued unloading after success cannot duplicate reward")
	game.open_depot()
	buttons[1].pressed.emit()
	check(game.profile.credits == 0 and game.profile.owned.size() == 2 and game.engine.engine_id == "river_twin", "Actual depot callback purchases once without silently equipping")
	buttons[1].pressed.emit()
	buttons[1].pressed.emit()
	check(game.profile.credits == 0 and game.engine.engine_id == "river_triple", "Repeated depot callback equips owned engine free without spending again")
	buttons[3].pressed.emit()
	check(game.state == "ready" and game.engine.engine_id == "river_triple" and game.selected_gear == 1, "Depot plan callback returns briefing with equipped engine and valid gear")
	game.start_run()
	game.open_depot()
	game.equip_engine("river_twin")
	check(game.state == "running" and game.engine.engine_id == "river_triple", "Owned starter cannot be equipped midrun")
	deliver_staged()
	check(game.profile.credits == 100 and game.state == "success", "Alternative engine can receive a second legitimate delivery reward (staged dock)")
	game.open_depot()
	buttons[0].pressed.emit()
	check(game.engine.engine_id == "river_twin" and game.profile.credits == 100, "Actual starter equip callback switches back free")
	buttons[2].pressed.emit()
	check(game.reset_profile_pending and game.profile.credits == 100, "Progression reset requires confirmation")
	game.close_depot()
	game.open_depot()
	check(not game.reset_profile_pending, "Leaving depot cancels pending reset")
	buttons[2].pressed.emit()
	buttons[2].pressed.emit()
	check(game.profile.credits == 0 and game.profile.owned == ["river_twin"] and game.mission_id == 0, "Confirmed reset clears progression and invalidates terminal mission")
	game.close_depot()
	deliver_staged()
	check(game.profile.credits == 0, "Old terminal dock cannot grant reward after progression reset")
	game.reset_run()
	game.start_run()
	game.fuel = 0.001
	game.simulate(1.0 / 60, Vector2.ZERO, false, true)
	check(game.state == "failure" and game.profile.credits == 0, "Fuel failure grants no reward or debt")
	var samples: Array = []
	for id in ["river_twin", "river_triple"]:
		game.reset_run()
		if id == "river_triple":
			game.profile.owned.append(id)
		game.profile.equipped = id
		game.start_run()
		game.select_gear(game.engine.gear_count())
		for frame in range(600):
			game.simulate(1.0 / 60, Vector2(0, -1), false, false)
		samples.append({"distance": -game.boat_pos.y, "fuel": 100 - game.fuel})
		print("MEASURE %s 10-second top-gear distance=%.3f fuel_used=%.3f" % [id, -game.boat_pos.y, 100 - game.fuel])
	check(samples[1].distance > samples[0].distance * 1.1 and samples[1].fuel > samples[0].fuel * 1.1, "Measured alternative gains travel distance at higher fuel use under real simulation")
	game.state = "paused"
	game.open_depot()
	game.equip_engine("river_twin")
	check(game.state == "paused" and game.engine.engine_id == "river_triple", "Pause cannot bypass between-run equipment guard")
	game.state = "running"
	deliver_staged()
	game.selected_gear = 9
	game.pickup_taken = true
	game.velocity = Vector2(55, 40)
	game.reset_run()
	check(game.profile.credits == 100 and game.profile.owned.size() == 2 and game.profile.equipped == "river_triple" and game.selected_gear == 1 and game.velocity == Vector2.ZERO and game.fuel == 100 and not game.pickup_taken and not game.delivered and game.mission_id == 0, "Restart clears dirty mission state while preserving credits, ownership and equipped engine")
	game.free()
	quit(1 if failures else 0)
