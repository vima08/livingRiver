extends SceneTree

# Full fixed-step simulation; setup reaches origins through committed profile APIs.
# No edits to position/resources after launch. Not graphical or human evidence.
const Profile = preload("res://scripts/player_profile.gd")
const Contracts = preload("res://scripts/river_contracts.gd")
var game: Node
var failures := 0
var results: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func origin_profile(origin: String, upgraded: bool) -> RefCounted:
	var profile := Profile.new("", false)
	if origin == "koya":
		profile.award_order(profile.begin_mission("base_light"), "koya_filters")
	elif origin == "luma":
		profile.award_order(profile.begin_mission("base_full"), "luma_food")
	if upgraded:
		profile.credits = maxi(100, profile.credits)
		profile.try_purchase("river_triple")
		profile.equip_engine("river_triple")
	return profile

func run_case(id: String, branch: String, upgraded: bool = false, skip: bool = false) -> void:
	game.profile = origin_profile(str(Contracts.job(id).origin), upgraded)
	game.ui_screen = "map"
	check(game.select_contract(id), id + " selected at local origin")
	game.pilot_branch = branch
	game.pilot_skip_luma = skip
	game.start_run()
	game.select_gear(3 if upgraded else 2)
	var launched: bool = game.state == "running"
	var north_flow: bool = false
	var impacts: Array = []
	for i in range(18000):
		if game.state != "running":
			break
		north_flow = north_flow or game.current_at(game.boat_pos).y < -0.001
		var controls: Array = game.pilot_controls()
		var before: float = game.hull
		game.simulate(1.0 / 60.0, controls[0], controls[1], controls[2])
		if game.hull < before:
			impacts.append({"x": game.boat_pos.x, "y": game.boat_pos.y, "time": game.elapsed})
	var row := {"contract": id, "channel": branch, "engine": game.engine.engine_id,
		"seconds": snappedf(game.elapsed, 0.01), "hull": snappedf(game.hull, 0.01),
		"fuel": snappedf(game.fuel, 0.01), "support": game.run_support,
		"landing": game.profile.current_landing, "state": game.state, "skipped_luma": skip, "impacts": impacts}
	results.append(row)
	print(JSON.stringify(row))
	check(launched and game.state == ("partial" if skip else "success"), id + "/" + branch + " complete outcome")
	check(game.fuel >= 5.0 and (upgraded or game.hull == 100.0), id + "/" + branch + " fuel reserve and clean starter hull")
	check(game.profile.current_landing == Contracts.job(id).destination and not north_flow, id + " destination saved; encountered flow never north")
	check(game.run_support == (100 if skip else Contracts.reward(id)), id + " exact support")
	if id.begins_with("base_"):
		check(game.elapsed >= 150 and game.elapsed <= 240, id + " approximate three-minute duration")
	game.open_map()
	check(game.ui_screen == "map" and game.contract().origin == game.profile.current_landing and game.boat_pos == game.landing_position(game.profile.current_landing), id + " next map stays at saved landing")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	for id in ["base_light", "base_full", "luma_base"]:
		for branch in ["safe", "rapids"]:
			run_case(id, branch)
	for id in ["koya_luma", "luma_koya"]:
		run_case(id, "safe")
	run_case("base_full", "rapids", true)
	run_case("luma_base", "rapids", true)
	run_case("base_full", "safe", false, true)
	DirAccess.make_dir_recursive_absolute("res://doc/evidence")
	FileAccess.open("res://doc/evidence/journey5-viability.json", FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	game.free()
	print("JOURNEY_CHECKS5 failures=%d" % failures)
	quit(1 if failures else 0)
