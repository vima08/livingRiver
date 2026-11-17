class_name RiverProfile
extends RefCounted

const DELIVERY_REWARD := 100
const ORDER_REWARDS := {"luma_food": 60, "koya_filters": DELIVERY_REWARD}
const ENGINE_PRICE := 100
const MAX_VALUE := 1000000000
const ENGINE_IDS := ["river_twin", "river_triple"]
const Contracts = preload("res://scripts/river_contracts.gd")

var credits: int = 0
var owned: Array[String] = ["river_twin"]
var equipped: String = "river_twin"
var last_rewarded_mission: int = 0
var next_mission_id: int = 1
var receipt_mission: int = 0
var receipt_orders: Array[String] = []
var current_landing: String = "base"
var receipt_contract: String = ""
var receipt_terminal: bool = true
var mutation_blocked: bool = false
var _protected_source: bool = false
var _migration_pending: bool = false
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
	receipt_mission = 0
	receipt_orders.clear()
	current_landing = "base"
	receipt_contract = ""
	receipt_terminal = true

func _data() -> Dictionary:
	return {"version": 3, "credits": credits, "owned": owned.duplicate(), "equipped": equipped,
		"last_rewarded_mission": last_rewarded_mission, "next_mission_id": next_mission_id,
		"receipt_mission": receipt_mission, "receipt_orders": receipt_orders.duplicate(),
		"current_landing": current_landing, "receipt_contract": receipt_contract, "receipt_terminal": receipt_terminal}

func _apply(data: Dictionary) -> void:
	credits = int(data.credits)
	owned.assign(data.owned)
	equipped = data.equipped
	last_rewarded_mission = int(data.last_rewarded_mission)
	next_mission_id = int(data.next_mission_id)
	receipt_mission = int(data.get("receipt_mission", 0))
	receipt_orders.assign(data.get("receipt_orders", []))
	current_landing = data.get("current_landing", "base")
	receipt_contract = data.get("receipt_contract", "")
	receipt_terminal = data.get("receipt_terminal", true)

func _whole(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	return is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

func _valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	for key in ["version", "credits", "owned", "equipped", "last_rewarded_mission", "next_mission_id"]:
		if not data.has(key):
			return false
	if not _whole(data.version, 1, 3) or not _whole(data.credits, 0, MAX_VALUE):
		return false
	if data.size() != {1: 6, 2: 8, 3: 11}[int(data.version)]:
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
	if not ("river_twin" in seen and data.equipped is String and data.equipped in seen):
		return false
	if int(data.version) == 1:
		return true
	if not data.has("receipt_mission") or not data.has("receipt_orders"):
		return false
	if not _whole(data.receipt_mission, 0, int(data.next_mission_id) - 1) or not data.receipt_orders is Array:
		return false
	if data.receipt_orders.size() > ORDER_REWARDS.size():
		return false
	var seen_orders: Array[String] = []
	for order_id in data.receipt_orders:
		if not order_id is String or not ORDER_REWARDS.has(order_id) or order_id in seen_orders:
			return false
		seen_orders.append(order_id)
	if int(data.receipt_mission) == 0 and not seen_orders.is_empty():
		return false
	if int(data.receipt_mission) > 0:
		if int(data.receipt_mission) != int(data.next_mission_id) - 1:
			return false
		if seen_orders.is_empty() and int(data.last_rewarded_mission) >= int(data.receipt_mission):
			return false
		if not seen_orders.is_empty() and int(data.last_rewarded_mission) != int(data.receipt_mission):
			return false
	if int(data.version) == 2:
		return true
	for key in ["current_landing", "receipt_contract", "receipt_terminal"]:
		if not data.has(key):
			return false
	if not data.current_landing is String or not Contracts.LANDINGS.has(data.current_landing):
		return false
	if not data.receipt_contract is String or not data.receipt_terminal is bool:
		return false
	# Empty context is a fresh or migrated profile: historical receipts are sealed.
	if data.receipt_contract.is_empty():
		return data.receipt_terminal and data.current_landing == "base"
	if not Contracts.JOBS.has(data.receipt_contract) or int(data.receipt_mission) == 0:
		return false
	var job: Dictionary = Contracts.JOBS[data.receipt_contract]
	for order_id in seen_orders:
		if order_id not in job.orders:
			return false
	if data.receipt_terminal:
		if data.current_landing != job.destination:
			return false
		return job.orders.is_empty() or (not seen_orders.is_empty() and Contracts.ORDERS[seen_orders.back()].stop == job.destination)
	if seen_orders.is_empty():
		return data.current_landing == job.origin
	return data.receipt_contract == "base_full" and seen_orders == ["luma_food"] and data.current_landing == "luma"

func load_profile() -> void:
	_defaults()
	load_notice = ""
	_protected_source = false
	_migration_pending = false
	mutation_blocked = false
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
		_protect("Profile could not be read. Original save preserved; progression changes are blocked until an explicit reset.")
		return
	var json := JSON.new()
	var contents := file.get_as_text()
	file.close()
	if json.parse(contents) != OK or not _valid(json.data):
		_protect("Invalid or unsupported profile. Original save preserved; progression changes are blocked until an explicit reset.")
		return
	_apply(json.data)
	# Old missions are abandoned, never reinterpreted as payable contracts.
	if int(json.data.version) < 3 and not save_profile():
		_migration_pending = true
		mutation_blocked = true
		load_notice = "Older profile loaded. Migration could not be saved; launch must wait for a safe save. Please retry."
		return
	if source != _save_path:
		load_notice = "Recovered the previous saved profile."

func save_profile() -> bool:
	if _protected_source:
		return false
	if not _valid(_data()):
		load_notice = "Profile changes could not be saved: invalid data."
		return false
	if not _persistence:
		_migration_pending = false
		mutation_blocked = false
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
		_migration_pending = false
		mutation_blocked = false
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
	_migration_pending = false
	mutation_blocked = false
	return true

func _protect(notice: String) -> void:
	_protected_source = true
	mutation_blocked = true
	load_notice = notice

func _ready_to_change() -> bool:
	if _protected_source:
		return false
	return save_profile() if _migration_pending else true

func _save_failed() -> bool:
	load_notice = "Profile could not be saved. The change was cancelled."
	return false

func _commit(previous: Dictionary) -> bool:
	if save_profile():
		return true
	_apply(previous)
	return false

func begin_mission(contract_id: String = "base_light") -> int:
	if not _ready_to_change() or not Contracts.JOBS.has(contract_id) or Contracts.JOBS[contract_id].origin != current_landing:
		return 0
	if next_mission_id >= MAX_VALUE:
		load_notice = "Mission counter is full. Reset progression to begin again."
		return 0
	var previous := _data()
	var mission := next_mission_id
	next_mission_id += 1
	receipt_mission = mission
	receipt_orders.clear()
	receipt_contract = contract_id
	receipt_terminal = false
	return mission if _commit(previous) else 0

func award_delivery(mission_id: int) -> bool:
	return award_order(mission_id, "koya_filters")

func has_receipt(mission_id: int, order_id: String) -> bool:
	return mission_id == receipt_mission and order_id in receipt_orders

func award_order(mission_id: int, order_id: String) -> bool:
	if not _ready_to_change() or receipt_terminal or not Contracts.JOBS.has(receipt_contract):
		return false
	if order_id not in Contracts.JOBS[receipt_contract].orders or mission_id <= 0 or mission_id != receipt_mission:
		return false
	if has_receipt(mission_id, order_id):
		return false
	# A migrated v1 paid mission has no per-order receipts and must never pay again.
	if mission_id <= last_rewarded_mission and (receipt_mission != mission_id or receipt_orders.is_empty()):
		return false
	var reward: int = ORDER_REWARDS[order_id]
	if credits > MAX_VALUE - reward:
		return false
	var previous := _data()
	credits += reward
	last_rewarded_mission = mission_id
	receipt_mission = mission_id
	receipt_orders.append(order_id)
	current_landing = Contracts.ORDERS[order_id].stop
	receipt_terminal = current_landing == Contracts.JOBS[receipt_contract].destination
	return _commit(previous)

func commit_arrival(mission_id: int) -> bool:
	if not _ready_to_change() or receipt_terminal or mission_id <= 0 or mission_id != receipt_mission:
		return false
	if not Contracts.JOBS.has(receipt_contract) or not Contracts.JOBS[receipt_contract].orders.is_empty():
		return false
	var previous := _data()
	current_landing = Contracts.JOBS[receipt_contract].destination
	receipt_terminal = true
	return _commit(previous)

func try_purchase(engine_id: String) -> bool:
	if not _ready_to_change():
		return false
	if engine_id != "river_triple" or engine_id in owned or credits < ENGINE_PRICE:
		return false
	var previous := _data()
	credits -= ENGINE_PRICE
	owned.append(engine_id)
	return _commit(previous)

func equip_engine(engine_id: String) -> bool:
	if not _ready_to_change():
		return false
	if engine_id not in owned:
		return false
	if equipped == engine_id:
		return true
	var previous := _data()
	equipped = engine_id
	return _commit(previous)

func reset_profile() -> bool:
	var previous := _data()
	var protected_before := _protected_source
	var migration_before := _migration_pending
	_protected_source = false
	_migration_pending = false
	mutation_blocked = false
	_defaults()
	if _commit(previous):
		return true
	_protected_source = protected_before
	_migration_pending = migration_before
	mutation_blocked = protected_before or migration_before
	return false
