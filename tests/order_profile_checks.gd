extends SceneTree

const Profile = preload("res://scripts/player_profile.gd")
const SAVE := "res://tests/.order-profile-checks-isolated.json"
const BLOCKED := "res://tests/.order-profile-checks-missing/profile.json"
var failures := 0

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func write_data(data: Variant) -> void:
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func clean() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))

func _initialize() -> void:
	clean()
	for engines in [["river_twin"], ["river_twin", "river_triple"], ["river_triple", "river_twin"]]:
		for equipment in engines:
			for boundary in [0, 7, 8]:
				var old := {"version": 1, "credits": 237, "owned": engines, "equipped": equipment,
					"last_rewarded_mission": boundary, "next_mission_id": 9}
				write_data(old)
				var migrated := Profile.new(SAVE)
				migrated.load_profile()
				check(migrated.credits == 237 and migrated.owned == engines and migrated.equipped == equipment
					and migrated.last_rewarded_mission == boundary and migrated.next_mission_id == 9 and migrated.load_notice.is_empty(),
					"Valid v1 migration preserves credits, ownership, equipment and counters: %s/%s/%d" % [engines, equipment, boundary])
				var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
				check(disk.version == 2 and disk.size() == 8 and disk.receipt_orders.is_empty(), "Migration writes bounded v2 schema")
				if boundary == 8:
					check(not migrated.award_order(8, "luma_food") and not migrated.award_delivery(8) and migrated.credits == 237,
						"Already-paid v1 mission cannot pay either order")
				check(not migrated.award_order(7, "luma_food"), "Abandoned older mission rejected even if never paid")
				var mission: int = migrated.begin_mission()
				check(mission == 9 and migrated.award_order(mission, "luma_food") and migrated.credits == 297, "New migrated run pays fixed food reward")
				var reload := Profile.new(SAVE)
				reload.load_profile()
				check(reload.has_receipt(9, "luma_food") and not reload.award_order(9, "luma_food") and reload.award_delivery(9)
					and reload.credits == 397, "Reload after first stop allows second exactly once")
				reload.load_profile()
				check(reload.receipt_orders.size() == 2 and not reload.award_delivery(9) and not reload.award_order(9, "luma_food")
					and reload.credits == 397, "Reload after both stops preserves receipts and balance")
	var profile := Profile.new(SAVE)
	profile.load_profile()
	var previous := profile._data()
	profile._save_path = BLOCKED
	check(profile.begin_mission() == 0 and profile._data() == previous and not profile.load_notice.is_empty(), "Failed new-run save preserves both receipts and mission counter")
	profile._save_path = SAVE
	var mission: int = profile.begin_mission()
	check(profile.receipt_orders.is_empty() and not profile.has_receipt(mission - 1, "luma_food")
		and not profile.award_order(mission - 1, "koya_filters"), "New run discards bounded receipts and rejects prior run")
	check(not profile.award_order(mission, "unknown") and not profile.award_order(mission + 1, "luma_food")
		and not profile.award_order(0, "luma_food"), "Unknown orders, unissued and zero IDs rejected")
	previous = profile._data()
	profile._save_path = BLOCKED
	check(not profile.award_order(mission, "luma_food") and profile._data() == previous
		and not profile.has_receipt(mission, "luma_food") and not profile.load_notice.is_empty(), "First reward write failure rolls back all state with notice")
	profile._save_path = SAVE
	check(profile.award_order(mission, "luma_food"), "First reward safely retries after write failure")
	previous = profile._data()
	profile._save_path = BLOCKED
	check(not profile.award_order(mission, "koya_filters") and profile._data() == previous
		and profile.has_receipt(mission, "luma_food") and not profile.has_receipt(mission, "koya_filters"), "Second reward write failure retains committed first receipt")
	profile._save_path = SAVE
	profile.load_profile()
	check(profile.award_order(mission, "koya_filters") and not profile.award_order(mission, "koya_filters"), "Second reward safely retries after reload, once")
	var valid := profile._data()
	var invalid: Array[Dictionary] = []
	var changed: Dictionary = valid.duplicate(true)
	changed.receipt_orders = ["luma_food", "luma_food"]
	invalid.append(changed)
	changed = valid.duplicate(true)
	changed.receipt_orders = ["unknown"]
	invalid.append(changed)
	changed = valid.duplicate(true)
	changed.receipt_orders = ["luma_food", "koya_filters", "luma_food"]
	invalid.append(changed)
	changed = valid.duplicate(true)
	changed.receipt_mission = mission - 1
	invalid.append(changed)
	changed = valid.duplicate(true)
	changed.last_rewarded_mission = mission - 1
	invalid.append(changed)
	changed = valid.duplicate(true)
	changed.extra = 1
	invalid.append(changed)
	changed = valid.duplicate(true)
	changed.erase("receipt_mission")
	invalid.append(changed)
	changed = valid.duplicate(true)
	changed.receipt_mission = true
	invalid.append(changed)
	changed = valid.duplicate(true)
	changed.version = 3
	invalid.append(changed)
	for data in invalid:
		write_data(data)
		profile.load_profile()
		check(profile.credits == 0 and profile.next_mission_id == 1 and not profile.load_notice.is_empty(), "Malformed v2 schema falls back safely")
	var old := {"version": 1, "credits": 531, "owned": ["river_twin", "river_triple"],
		"equipped": "river_triple", "last_rewarded_mission": 20, "next_mission_id": 22}
	write_data(old)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SAVE + ".tmp"))
	profile.load_profile()
	check(profile.credits == 531 and profile.equipped == "river_triple" and profile.next_mission_id == 22
		and not profile.load_notice.is_empty() and JSON.parse_string(FileAccess.get_file_as_string(SAVE)).version == 1,
		"Blocked migration preserves valid v1 progress in memory and on disk with notice")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + ".tmp"))
	profile.load_profile()
	check(profile.credits == 531 and profile.load_notice.is_empty()
		and JSON.parse_string(FileAccess.get_file_as_string(SAVE)).version == 2, "Migration safely retries after write obstruction removed")
	write_data(old)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(SAVE + ".bak"))
	profile.load_profile()
	check(profile.credits == 531 and profile.next_mission_id == 22 and profile.equipped == "river_triple"
		and not profile.load_notice.is_empty() and not profile.award_delivery(20), "Valid v1 backup recovers and migrates with old reward boundary intact")
	write_data(valid)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(SAVE + ".bak"))
	profile.load_profile()
	check(profile._data() == valid and not profile.load_notice.is_empty() and not profile.award_order(mission, "luma_food"), "Backup recovers both committed rewards without duplicates")
	check(profile.reset_profile() and profile.credits == 0 and profile.receipt_mission == 0 and profile.receipt_orders.is_empty(), "Explicit reset clears receipts and progression together")
	profile.load_profile()
	check(profile.next_mission_id == 1 and profile.credits == 0 and profile.receipt_orders.is_empty(), "Reset persists across reload")
	var bounded := Profile.new("", false)
	for index in 100:
		var current: int = bounded.begin_mission()
		bounded.award_order(current, "luma_food")
		bounded.award_order(current, "koya_filters")
	check(bounded.credits == 16000 and bounded._data().size() == 8 and bounded.receipt_orders.size() == 2, "One hundred full runs keep only two receipts and fixed rewards")
	bounded.begin_mission()
	bounded.credits = Profile.MAX_VALUE - 59
	previous = bounded._data()
	check(not bounded.award_order(bounded.next_mission_id - 1, "luma_food") and bounded._data() == previous, "Credit limit cannot overflow or create receipt")
	clean()
	quit(1 if failures else 0)
