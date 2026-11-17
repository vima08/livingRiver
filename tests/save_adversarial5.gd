extends SceneTree

const Profile = preload("res://scripts/player_profile.gd")
const SAVE := "user://critic-save5.json"
var failures := 0
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL " + label)
	else:
		print("PASS " + label)

func clean() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))

func write(data: Variant, suffix := "") -> void:
	var file := FileAccess.open(SAVE + suffix, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_saved():
	var result = Profile.new(SAVE)
	result.load_profile()
	return result

func block() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SAVE + ".tmp"))

func unblock() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + ".tmp"))

func stage(arg: String) -> void:
	if arg == "seed":
		clean()
		var p = load_saved()
		check(p.award_order(p.begin_mission("base_full"), "luma_food"), "Process A commits Luma then exits")
	elif arg == "recover":
		var p = load_saved()
		check(p.current_landing == "luma" and p.credits == 60 and p.receipt_orders == ["luma_food"], "Process B immediately recovers Luma support/receipt")
		check(p.begin_mission("luma_base") == 2 and p.commit_arrival(2), "Process B abandons remaining filters and commits explicit empty return")
	elif arg == "verify":
		var p = load_saved()
		check(p.current_landing == "base" and p.credits == 60 and p.receipt_terminal and p.next_mission_id == 3, "Process C recovers empty arrival without payout")
		check(not p.award_order(1, "koya_filters") and not p.commit_arrival(2), "Process C rejects abandoned cargo and repeated empty arrival")
		clean()
	quit(1 if failures else 0)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("ISOLATED USER DIRECTORY " + OS.get_user_data_dir())
	if not OS.get_cmdline_user_args().is_empty():
		stage(OS.get_cmdline_user_args()[0])
		return
	clean()
	var p = load_saved()
	var before: Dictionary = p._data()
	block()
	check(p.begin_mission("base_full") == 0 and p._data() == before and not FileAccess.file_exists(SAVE), "Failed initial launch consumes no ID and creates no committed mission")
	unblock()
	var mission: int = p.begin_mission("base_full")
	check(mission == 1 and p.award_order(mission, "koya_filters"), "Partial terminal commits only Koya")
	p = load_saved()
	check(p.credits == 100 and p.current_landing == "koya" and not p.award_order(mission, "luma_food"), "Reloaded partial terminal rejects stale Luma reward/checkpoint")
	var terminal: Dictionary = p._data()
	write(terminal, ".bak")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	p = load_saved()
	check(p._data() == terminal and not p.mutation_blocked and not p.load_notice.is_empty(), "Missing primary recovers exact valid committed backup")
	check(p.begin_mission("koya_luma") == 2 and p.award_order(2, "luma_food"), "Recovered backup permits atomic next departure/arrival")
	var valid: Dictionary = p._data()
	var invalids: Array = [null, [], {}, {"version": 999}]
	for field in ["credits", "next_mission_id", "receipt_mission", "receipt_terminal", "current_landing", "owned", "receipt_orders"]:
		var bad: Dictionary = valid.duplicate(true)
		match field:
			"credits": bad[field] = -1
			"next_mission_id": bad[field] = 2
			"receipt_mission": bad[field] = 1
			"receipt_terminal": bad[field] = "true"
			"current_landing": bad[field] = "koya"
			"owned": bad[field] = ["river_twin", "river_twin"]
			"receipt_orders": bad[field] = ["luma_food", "luma_food"]
		invalids.append(bad)
	for bad in invalids:
		write(valid, ".bak")
		write(bad)
		var original := FileAccess.get_file_as_string(SAVE)
		p = load_saved()
		check(p.mutation_blocked and p.begin_mission() == 0 and not p.save_profile() and FileAccess.get_file_as_string(SAVE) == original, "Invalid primary with valid backup is protected, not silently overwritten")
	clean()
	p = load_saved()
	for cycle in range(30):
		mission = p.begin_mission("base_full")
		var old_id := mission
		check(p.award_order(mission, "luma_food") and p.award_order(mission, "koya_filters"), "Repeated upstream cycle %d" % cycle)
		mission = p.begin_mission("koya_luma")
		check(not p.award_order(old_id, "luma_food") and p.award_order(mission, "luma_food"), "New run rejects superseded receipts %d" % cycle)
		mission = p.begin_mission("luma_base")
		check(p.commit_arrival(mission) and not p.commit_arrival(mission), "Repeated empty return deduplicates %d" % cycle)
		p = load_saved()
		check(p.current_landing == "base" and p.receipt_orders.is_empty() and p.credits == (cycle + 1) * 220 and FileAccess.get_file_as_string(SAVE).length() < 500, "Repeated journeys retain bounded latest context %d" % cycle)
	var cap: Dictionary = p._data()
	cap.next_mission_id = Profile.MAX_VALUE
	cap.receipt_mission = Profile.MAX_VALUE - 1
	write(cap)
	p = load_saved()
	check(not p.mutation_blocked and p.begin_mission() == 0 and p.next_mission_id == Profile.MAX_VALUE, "Exhausted mission counter safely refuses launch")
	clean()
	p = load_saved()
	var settings_path := "user://settings.cfg"
	var settings_before := FileAccess.get_file_as_bytes(settings_path) if FileAccess.file_exists(settings_path) else PackedByteArray()
	var settings_existed := FileAccess.file_exists(settings_path)
	if not settings_existed:
		var preferences := FileAccess.open(settings_path, FileAccess.WRITE)
		preferences.store_string("[preferences]\nlanguage=\"ru\"\nmaster_volume=0.37\n")
		preferences.close()
	var settings_sentinel := FileAccess.get_file_as_bytes(settings_path)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.set_meta("test_mode", true)
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	scene.profile = p
	scene.open_map()
	scene.select_contract("base_full")
	scene.start_run()
	scene.boat_pos = scene.luma_pos
	scene.velocity = Vector2.ZERO
	before = p._data()
	block()
	check(not scene.complete_order("luma") and not scene.completed_order("luma_food") and scene.state == "running" and p._data() == before and scene.manifest.full_load(), "Scene failed Luma save retains active heavy cargo/reward/checkpoint")
	unblock()
	check(scene.complete_order("luma") and scene.completed_order("luma_food") and p.current_landing == "luma", "Scene Luma save retry commits before removing cargo")
	scene.boat_pos = scene.dock_pos
	before = p._data()
	block()
	check(not scene.complete_order("koya") and not scene.completed_order("koya_filters") and scene.state == "running" and p._data() == before, "Scene failed terminal save retains filters and Luma checkpoint")
	unblock()
	scene.open_map()
	check(scene.boat_pos == scene.luma_pos and scene.ui_screen == "map" and scene.mission_id == 0 and p.credits == 60, "Abandon after Luma returns to saved map without extra issue/reward")
	scene.select_contract("luma_base")
	scene.start_run()
	scene.boat_pos = scene.base_pos
	before = p._data()
	block()
	check(not scene.complete_order("base") and scene.state == "running" and p._data() == before, "Scene failed empty arrival retains active trip and Luma checkpoint")
	unblock()
	check(scene.complete_order("base") and scene.state == "success" and p.current_landing == "base" and p.credits == 60, "Scene empty retry commits Base with no reward")
	check(not scene.complete_order("base") and p.credits == 60, "Scene terminal callback cannot reenter arrival")
	scene.open_map()
	scene.select_contract("base_full")
	scene.start_run()
	scene.boat_pos = scene.dock_pos
	before = p._data()
	block()
	check(not scene.complete_order("koya") and scene.state == "running" and scene.manifest.full_load() and p._data() == before, "Scene failed partial terminal preserves full cargo for retry")
	unblock()
	check(scene.complete_order("koya") and scene.state == "partial" and p.current_landing == "koya" and p.credits == 160, "Scene terminal retry path commits partial Koya without Luma payout")
	scene.boat_pos = scene.luma_pos
	check(not scene.complete_order("luma") and not scene.completed_order("luma_food") and p.current_landing == "koya" and p.credits == 160, "Scene stale Luma callback after partial cannot remove cargo/pay/roll checkpoint back")
	check(p.reset_profile() and FileAccess.get_file_as_bytes(settings_path) == settings_sentinel, "Progression reset preserves separate preference file byte for byte")
	scene.queue_free()
	await process_frame
	if settings_existed:
		var preferences := FileAccess.open(settings_path, FileAccess.WRITE)
		preferences.store_buffer(settings_before)
		preferences.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
	clean()
	print("CRITIC CHECKS %d FAILURES %d" % [checks, failures])
	quit(1 if failures else 0)
