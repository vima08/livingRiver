class_name RiverProfile
extends RefCounted

const DELIVERY_REWARD := 100
const ENGINE_PRICE := 100
const MAX_VALUE := 1000000000
const ENGINE_IDS := ["river_twin", "river_triple"]

var credits: int = 0
var owned: Array[String] = ["river_twin"]
var equipped: String = "river_twin"
var last_rewarded_mission: int = 0
var next_mission_id: int = 1
var load_notice: String = ""
var _save_path: String
var _persistence: bool

func _init(save_path: String = "user://profile.json", persistence: bool = true) -> void:
	_save_path = save_path
	_persistence = persistence

func _defaults() -> void:
	credits = 0
	owned.assign(["river_twin"])
	equipped = "river_twin"
	last_rewarded_mission = 0
	next_mission_id = 1

func _data() -> Dictionary:
	return {"version": 1, "credits": credits, "owned": owned.duplicate(), "equipped": equipped,
		"last_rewarded_mission": last_rewarded_mission, "next_mission_id": next_mission_id}

func _apply(data: Dictionary) -> void:
	credits = int(data.credits)
	owned.assign(data.owned)
	equipped = data.equipped
	last_rewarded_mission = int(data.last_rewarded_mission)
	next_mission_id = int(data.next_mission_id)

func _whole(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	return is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

func _valid(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 6:
		return false
	for key in ["version", "credits", "owned", "equipped", "last_rewarded_mission", "next_mission_id"]:
		if not data.has(key):
			return false
	if not _whole(data.version, 1, 1) or not _whole(data.credits, 0, MAX_VALUE):
		return false
	if not _whole(data.next_mission_id, 1, MAX_VALUE) or not _whole(data.last_rewarded_mission, 0, int(data.next_mission_id) - 1):
		return false
	if not data.owned is Array or data.owned.size() < 1 or data.owned.size() > 2:
		return false
	var seen: Array[String] = []
	for id in data.owned:
		if not id is String or id not in ENGINE_IDS or id in seen:
			return false
		seen.append(id)
	return "river_twin" in seen and data.equipped is String and data.equipped in seen

func load_profile() -> void:
	_defaults()
	load_notice = ""
	if not _persistence:
		return
	# Recover the previous committed file if a platform fallback was interrupted.
	var source := _save_path
	if not FileAccess.file_exists(source) and FileAccess.file_exists(source + ".bak"):
		source += ".bak"
	if not FileAccess.file_exists(source):
		return
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null or file.get_length() > 16384:
		load_notice = "Profile could not be read. Using the starter profile."
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not _valid(json.data):
		load_notice = "Invalid profile. Using the starter profile."
		return
	_apply(json.data)
	if source != _save_path:
		load_notice = "Recovered the previous saved profile."

func save_profile() -> bool:
	if not _valid(_data()):
		load_notice = "Profile changes could not be saved: invalid data."
		return false
	if not _persistence:
		return true
	var temporary := _save_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _save_failed()
	file.store_string(JSON.stringify(_data()))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return _save_failed()
	var target := ProjectSettings.globalize_path(_save_path)
	var pending := ProjectSettings.globalize_path(temporary)
	if DirAccess.rename_absolute(pending, target) == OK:
		DirAccess.remove_absolute(target + ".bak")
		load_notice = ""
		return true
	# Some filesystems cannot replace an existing file by rename.
	var backup := target + ".bak"
	if not FileAccess.file_exists(_save_path):
		return _save_failed()
	if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
		return _save_failed()
	if DirAccess.rename_absolute(target, backup) != OK:
		return _save_failed()
	if DirAccess.rename_absolute(pending, target) != OK:
		DirAccess.rename_absolute(backup, target)
		return _save_failed()
	DirAccess.remove_absolute(backup)
	load_notice = ""
	return true

func _save_failed() -> bool:
	load_notice = "Profile could not be saved. The change was cancelled."
	return false

func _commit(previous: Dictionary) -> bool:
	if save_profile():
		return true
	_apply(previous)
	return false

func begin_mission() -> int:
	if next_mission_id >= MAX_VALUE:
		load_notice = "Mission counter is full. Reset progression to begin again."
		return 0
	var previous := _data()
	var mission := next_mission_id
	next_mission_id += 1
	return mission if _commit(previous) else 0

func award_delivery(mission_id: int) -> bool:
	if mission_id <= last_rewarded_mission or mission_id <= 0 or mission_id >= next_mission_id or credits > MAX_VALUE - DELIVERY_REWARD:
		return false
	var previous := _data()
	credits += DELIVERY_REWARD
	last_rewarded_mission = mission_id
	return _commit(previous)

func try_purchase(engine_id: String) -> bool:
	if engine_id != "river_triple" or engine_id in owned or credits < ENGINE_PRICE:
		return false
	var previous := _data()
	credits -= ENGINE_PRICE
	owned.append(engine_id)
	return _commit(previous)

func equip_engine(engine_id: String) -> bool:
	if engine_id not in owned:
		return false
	if equipped == engine_id:
		return true
	var previous := _data()
	equipped = engine_id
	return _commit(previous)

func reset_profile() -> bool:
	var previous := _data()
	_defaults()
	return _commit(previous)
