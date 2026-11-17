extends SceneTree

const Profile = preload("res://scripts/player_profile.gd")
const SAVE := "res://tmp/profile-journey5.json"
var failures := 0

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func write(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func fresh():
	var profile := Profile.new(SAVE)
	profile.load_profile()
	return profile

func block() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SAVE + ".tmp"))

func unblock() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + ".tmp"))

func cross_process(stage: String) -> void:
	if stage.begins_with("seed-"):
		var version := int(stage.trim_prefix("seed-"))
		var old := {"version": version, "credits": 237, "owned": ["river_twin", "river_triple"], "equipped": "river_triple", "last_rewarded_mission": 8, "next_mission_id": 9}
		if version == 2:
			old.receipt_mission = 8
			old.receipt_orders = ["luma_food"]
		write(old)
		check(FileAccess.file_exists(SAVE), "Separate-process migration fixture written")
	elif stage == "migrate-and-food":
		var profile = fresh()
		check(profile.credits == 237 and profile.current_landing == "base" and profile.equipped == "river_triple" and not profile.award_delivery(8), "Separate-process migration preserves progress and seals prior reward")
		var mission: int = profile.begin_mission("base_full")
		check(mission == 9 and profile.award_order(mission, "luma_food"), "Separate-process food commit before process exit")
	elif stage == "recover-and-terminal":
		var profile = fresh()
		check(profile.current_landing == "luma" and profile.credits == 297 and profile.has_receipt(9, "luma_food") and not profile.award_order(9, "luma_food"), "Separate-process Luma recovery preserves exact committed support")
		check(profile.award_order(9, "koya_filters"), "Separate-process terminal commit before process exit")
	elif stage == "recover-terminal":
		var profile = fresh()
		check(profile.current_landing == "koya" and profile.credits == 397 and profile.receipt_terminal and not profile.award_delivery(9) and not profile.award_order(9, "luma_food"), "Separate-process terminal recovery seals every stale callback")
	else:
		check(false, "Unknown cross-process stage")
	quit(1 if failures else 0)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	if not OS.get_cmdline_user_args().is_empty():
		cross_process(OS.get_cmdline_user_args()[0])
		return
	unblock()
	for suffix in ["", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	var old := {"version": 1, "credits": 237, "owned": ["river_twin", "river_triple"], "equipped": "river_triple", "last_rewarded_mission": 8, "next_mission_id": 9}
	for version in [1, 2]:
		old.version = version
		if version == 2:
			old.receipt_mission = 8
			old.receipt_orders = ["luma_food"]
		write(old)
		block()
		var profile = fresh()
		check(profile.credits == 237 and profile.equipped == "river_triple" and profile.current_landing == "base" and profile.next_mission_id == 9 and profile.mutation_blocked, "v%d blocked migration retains valid progress" % version)
		check(profile.begin_mission("base_full") == 0 and not profile.award_order(8, "koya_filters") and JSON.parse_string(FileAccess.get_file_as_string(SAVE)).version == version, "Blocked migration cannot issue or reinterpret old mission")
		unblock()
		check(profile.save_profile() and not profile.mutation_blocked and JSON.parse_string(FileAccess.get_file_as_string(SAVE)).version == 3, "Migration retries with strict v3 write")
		check(not profile.award_order(8, "luma_food") and not profile.award_order(8, "koya_filters"), "Migrated receipts are sealed")
	var profile = fresh()
	check(profile.reset_profile(), "Explicit reset succeeds")
	check(profile.begin_mission("koya_luma") == 0 and profile.next_mission_id == 1, "Remote contract cannot allocate mission")
	var mission: int = profile.begin_mission("base_full")
	var before: Dictionary = profile._data()
	block()
	check(not profile.award_order(mission, "luma_food") and profile._data() == before and fresh()._data() == before, "Food failure rolls back reward, receipt and checkpoint in memory/disk")
	unblock()
	check(profile.award_order(mission, "luma_food") and profile.current_landing == "luma" and profile.credits == 60 and not profile.receipt_terminal, "Food retry atomically commits intermediate Luma")
	profile = fresh()
	check(profile.current_landing == "luma" and profile.has_receipt(mission, "luma_food") and not profile.award_order(mission, "luma_food"), "Reload recovers intermediate checkpoint and rejects duplicate")
	before = profile._data()
	block()
	check(not profile.award_order(mission, "koya_filters") and profile._data() == before and fresh()._data() == before, "Terminal failure retains intermediate checkpoint and receipt")
	unblock()
	check(profile.award_order(mission, "koya_filters") and fresh().current_landing == "koya" and fresh().credits == 160, "Terminal retry survives immediate reload")
	check(not profile.award_order(mission, "luma_food") and not profile.award_order(mission, "koya_filters"), "Terminal rejects all late callbacks")
	mission = profile.begin_mission("koya_luma")
	check(mission > 0 and profile.award_order(mission, "luma_food") and profile.current_landing == "luma" and profile.credits == 220, "Koya locally supplies downstream food")
	mission = profile.begin_mission("luma_base")
	before = profile._data()
	block()
	check(not profile.commit_arrival(mission) and profile._data() == before and fresh().current_landing == "luma", "Empty arrival failure retains Luma and zero payout")
	unblock()
	check(profile.commit_arrival(mission) and profile.current_landing == "base" and profile.credits == 220 and fresh().receipt_terminal and fresh().current_landing == "base", "Empty arrival retries and persists with zero reward")
	check(not profile.commit_arrival(mission) and not profile.award_delivery(mission), "Empty arrival is deduplicated and cannot pay")
	mission = profile.begin_mission("base_full")
	check(profile.award_order(mission, "koya_filters") and not profile.award_order(mission, "luma_food") and profile.current_landing == "koya" and profile.credits == 320, "Skipping Luma terminally checkpoints Koya; stale food cannot pay or relocate")
	var valid: Dictionary = profile._data()
	var malformed: Array[Dictionary] = []
	for field in ["current_landing", "receipt_contract", "receipt_terminal", "receipt_mission", "receipt_orders", "version"]:
		var bad := valid.duplicate(true)
		match field:
			"current_landing": bad[field] = "base"
			"receipt_contract": bad[field] = "unknown"
			"receipt_terminal": bad[field] = false
			"receipt_mission": bad[field] = 0
			"receipt_orders": bad[field] = ["koya_filters", "luma_food"]
			"version": bad[field] = 99
		malformed.append(bad)
	for bad in malformed:
		write(bad)
		var original := FileAccess.get_file_as_string(SAVE)
		profile = fresh()
		check(profile.mutation_blocked and profile.begin_mission() == 0 and not profile.save_profile() and not profile.try_purchase("river_triple") and not profile.equip_engine("river_twin") and original == FileAccess.get_file_as_string(SAVE), "Malformed/future source is preserved and mutation blocked")
	check(profile.reset_profile() and not profile.mutation_blocked and fresh().current_landing == "base" and fresh().credits == 0, "Explicit reset replaces protected save safely")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	quit(1 if failures else 0)
