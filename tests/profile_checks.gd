extends SceneTree

const Profile = preload("res://scripts/player_profile.gd")
const SAVE := "res://tests/.profile-checks-isolated.json"
var failures := 0

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func _initialize() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	var profile := Profile.new(SAVE)
	profile.load_profile()
	check(profile.credits == 0 and profile.equipped == "river_twin", "Missing save starts with owned starter")
	check(not profile.try_purchase("river_triple") and not profile.equip_engine("river_triple"), "Insufficient funds and unowned equip rejected")
	check(not profile.try_purchase("unknown") and not profile.award_delivery(0) and not profile.award_delivery(1), "Unknown engine and unissued rewards rejected")
	var mission := profile.begin_mission()
	check(mission == 1 and profile.award_delivery(mission) and profile.credits == 100, "Issued mission rewards 100 support credits")
	check(not profile.award_delivery(mission), "Repeat delivery cannot grant credits")
	var reloaded := Profile.new(SAVE)
	reloaded.load_profile()
	check(reloaded.credits == 100 and not reloaded.award_delivery(mission), "Reload preserves reward boundary")
	check(reloaded.try_purchase("river_triple") and reloaded.credits == 0 and reloaded.owned.size() == 2, "Purchase spends exactly 100 once")
	check(not reloaded.try_purchase("river_triple") and reloaded.credits == 0, "Repeat purchase rejected")
	check(reloaded.equip_engine("river_triple"), "Owned alternative equips")
	profile.load_profile()
	check(profile.equipped == "river_triple" and profile.owned.size() == 2, "Reload persists equipped engine and ownership")
	check(profile.equip_engine("river_twin"), "Starter can be equipped again")
	var abandoned := profile.begin_mission()
	var completed := profile.begin_mission()
	check(not profile.award_delivery(abandoned), "New issuance immediately closes an abandoned mission reward")
	check(completed > abandoned and profile.award_delivery(completed) and not profile.award_delivery(abandoned), "Restart advances mission boundary and cannot reward an older mission after success")
	check(profile.reset_profile() and profile.credits == 0 and profile.owned.size() == 1 and profile.next_mission_id == 1, "Explicit reset clears progression")
	var blocked := Profile.new("res://tests/missing-profile-check-dir/profile.json")
	check(blocked.begin_mission() == 0 and blocked.next_mission_id == 1 and not blocked.load_notice.is_empty(), "Save failure cancels mission issuance with feedback")
	var memory := Profile.new("", false)
	var earned := memory.begin_mission()
	memory.award_delivery(earned)
	memory._persistence = true
	memory._save_path = "res://tests/missing-profile-check-dir/profile.json"
	check(not memory.try_purchase("river_triple") and memory.credits == 100 and memory.owned.size() == 1, "Failed purchase save rolls back credits and ownership")
	check(not memory.award_delivery(memory.next_mission_id), "Unissued future reward rejected after save failure")
	var rollback := Profile.new("", false)
	var rollback_mission := rollback.begin_mission()
	rollback._persistence = true
	rollback._save_path = "res://tests/missing-profile-check-dir/profile.json"
	check(not rollback.award_delivery(rollback_mission) and rollback.credits == 0 and rollback.last_rewarded_mission == 0, "Failed reward save rolls back balance and reward boundary")
	rollback._persistence = false
	rollback.award_delivery(rollback_mission)
	rollback.try_purchase("river_triple")
	rollback._persistence = true
	check(not rollback.equip_engine("river_triple") and rollback.equipped == "river_twin", "Failed equipment save restores prior engine")
	check(not rollback.reset_profile() and rollback.owned.size() == 2 and rollback.next_mission_id == 2, "Failed progression reset restores ownership and mission boundary")
	profile = Profile.new(SAVE)
	profile.begin_mission()
	profile.award_delivery(1)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(SAVE + ".bak"))
	profile.load_profile()
	check(profile.credits == 100 and not profile.award_delivery(1), "Interrupted replacement recovers committed backup without duplicate reward")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + ".bak"))
	var invalid_cases: Array[String] = ["{", "[]", '{"version":1}',
		'{"version":1,"credits":-1,"owned":["river_twin"],"equipped":"river_twin","last_rewarded_mission":0,"next_mission_id":1}',
		'{"version":1,"credits":0.5,"owned":["river_twin"],"equipped":"river_twin","last_rewarded_mission":0,"next_mission_id":1}',
		'{"version":1,"credits":true,"owned":["river_twin"],"equipped":"river_twin","last_rewarded_mission":0,"next_mission_id":1}',
		'{"version":1,"credits":0,"owned":["river_twin","river_twin"],"equipped":"river_twin","last_rewarded_mission":0,"next_mission_id":1}',
		'{"version":1,"credits":0,"owned":["river_twin"],"equipped":"river_triple","last_rewarded_mission":1,"next_mission_id":1}']
	for invalid in invalid_cases:
		var file := FileAccess.open(SAVE, FileAccess.WRITE)
		file.store_string(invalid)
		file.close()
		profile.load_profile()
		check(profile.credits == 0 and profile.owned == ["river_twin"] and not profile.load_notice.is_empty(), "Corrupt or inconsistent profile falls back safely: " + invalid.left(45))
	var twin: Resource = load("res://resources/engines/river_twin.tres")
	var triple: Resource = load("res://resources/engines/river_triple.tres")
	check(twin.valid_data() and triple.valid_data() and triple.fuel_multiplier > twin.fuel_multiplier and triple.forward_accelerations[0] < twin.forward_accelerations[0], "Both engine resources valid; alternative trades acceleration and fuel for speed")
	var invalid_engine: Resource = twin.duplicate()
	invalid_engine.forward_speeds = PackedFloat32Array([])
	check(not invalid_engine.valid_data(), "Empty engine gear curve rejected")
	invalid_engine.forward_speeds = PackedFloat32Array([95, 90])
	check(not invalid_engine.valid_data(), "Decreasing engine speeds rejected")
	invalid_engine.forward_speeds = PackedFloat32Array([95, 155])
	invalid_engine.forward_accelerations = PackedFloat32Array([260])
	check(not invalid_engine.valid_data(), "Mismatched acceleration curve rejected")
	invalid_engine.forward_accelerations = PackedFloat32Array([260, 210])
	invalid_engine.fuel_multiplier = NAN
	check(not invalid_engine.valid_data(), "Nonfinite engine fuel use rejected")
	invalid_engine.fuel_multiplier = 1.0
	invalid_engine.forward_speeds = PackedFloat32Array([1,2,3,4,5,6,7,8,9])
	invalid_engine.forward_accelerations = PackedFloat32Array([1,1,1,1,1,1,1,1,1])
	check(not invalid_engine.valid_data(), "More than eight engine gears rejected")
	for suffix in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	quit(1 if failures else 0)
