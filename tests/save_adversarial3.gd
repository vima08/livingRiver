extends SceneTree

const Main = preload("res://scripts/main.gd")
const Profile = preload("res://scripts/player_profile.gd")
const SAVE := "res://tests/.save-adversarial3.json"
var failures := 0
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func disk() -> RefCounted:
	var profile := Profile.new(SAVE)
	profile.load_profile()
	return profile

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	var game := Main.new()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	game.profile = Profile.new(SAVE)
	game.select_load("full")
	game.start_run()
	var first: int = game.mission_id
	game.boat_pos = game.luma_pos
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SAVE + ".tmp"))
	check(not game.complete_order("luma") and game.run_support == 0 and not game.completed_order("luma_food")
		and game.manifest.full_load() and game.profile.credits == 0 and disk().credits == 0
		and game.unload_notice.contains("retry"), "Actual scene keeps food, handling and credit state consistent after blocked reward write")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + ".tmp"))
	check(game.complete_order("luma") and game.run_support == 60 and not game.manifest.full_load()
		and disk().credits == 60, "Actual scene retries food commit and unloads only after disk reward")
	check(not game.complete_order("luma") and disk().credits == 60, "Repeated scene delivery cannot pay twice")
	game.hull = 0
	game.simulate(0.01, Vector2.ZERO, true, false)
	check(game.state == "failure" and game.run_support == 60 and disk().credits == 60
		and not game.completed_order("koya_filters"), "Actual hull failure after Luma retains committed support and pending filters")
	game.reset_run()
	check(game.state == "ready" and game.mission_id == 0 and game.manifest.completed_count() == 0
		and game.profile.credits == 60 and disk().credits == 60, "Actual restart abandons cargo state while keeping saved food reward")
	game.profile = disk()
	game.start_run()
	check(game.mission_id > first and not game.profile.award_order(first, "koya_filters"), "Reload and launch close the prior run identity")
	game.boat_pos = game.dock_pos
	game.velocity = Vector2.ZERO
	check(game.complete_order("koya") and game.state == "partial" and game.run_support == 100
		and game.profile.credits == 160 and disk().credits == 160, "Actual skipped-Luma result persists only Koya support")
	game.open_depot()
	game.buy_engine()
	game.equip_engine("river_triple")
	check(disk().credits == 60 and disk().owned.size() == 2 and disk().equipped == "river_triple", "Partial-result depot saves purchase and equipment")
	game.reset_progression()
	check(game.reset_profile_pending and disk().owned.size() == 2 and disk().credits == 60, "First progression-reset click changes no saved progress")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SAVE + ".tmp"))
	game.reset_progression()
	check(not game.reset_profile_pending and game.profile.credits == 60 and game.profile.owned.size() == 2
		and game.profile.equipped == "river_triple" and disk().owned.size() == 2, "Failed confirmed progression reset retains purchase and equipment")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + ".tmp"))
	game.reset_progression()
	game.reset_progression()
	game.close_depot()
	check(game.profile.credits == 0 and game.profile.owned == ["river_twin"] and game.mission_id == 0
		and not game.complete_order("koya") and disk().credits == 0, "Confirmed reset invalidates terminal reward and persists starter progression")
	game.reset_run()
	game.start_run()
	game.open_depot()
	game.reset_progression()
	check(game.state == "running" and not game.reset_profile_pending, "Active mission cannot open depot or reset progression")
	game.free()
	for suffix in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("Adversarial scene persistence: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
