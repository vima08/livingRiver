class_name ReliefManifest
extends RefCounted

const Contracts = preload("res://scripts/river_contracts.gd")

var orders: Array[Dictionary] = []
var preset := "light"
var contract_id := "base_light"

func _init(load_name: String = "light") -> void:
	configure(load_name)

func configure(load_name: String) -> bool:
	if load_name not in ["light", "full"]:
		return false
	return configure_contract("base_" + load_name)

func configure_contract(id: String) -> bool:
	var job: Dictionary = Contracts.job(id)
	if job.is_empty():
		return false
	contract_id = id
	preset = "full" if id == "base_full" else "empty" if job.orders.is_empty() else "light"
	orders.clear()
	for order_id: String in job.orders:
		var order: Dictionary = Contracts.ORDERS[order_id].duplicate(true)
		order.completed = false
		orders.append(order)
	return true

func valid_data() -> bool:
	var job: Dictionary = Contracts.job(contract_id)
	if job.is_empty() or orders.size() != job.orders.size():
		return false
	if preset != ("full" if contract_id == "base_full" else "empty" if job.orders.is_empty() else "light"):
		return false
	var seen: Array[String] = []
	for i in range(orders.size()):
		var order: Dictionary = orders[i]
		for field in ["id", "cargo", "recipient", "stop", "reward", "completed"]:
			if not order.has(field):
				return false
		if order.id in seen or order.id != job.orders[i] or not order.completed is bool:
			return false
		var expected: Dictionary = Contracts.ORDERS[order.id]
		for field: String in expected:
			if typeof(order[field]) != typeof(expected[field]) or order[field] != expected[field]:
				return false
		seen.append(order.id)
	return true

func pending_for_stop(stop: String) -> Dictionary:
	for order in orders:
		if order.stop == stop and not order.completed:
			return order
	return {}

func next_order() -> Dictionary:
	for order in orders:
		if not order.completed:
			return order
	return {}

func completed_order(id: String) -> bool:
	for order in orders:
		if order.id == id:
			return order.completed
	return false

func mark_completed(id: String) -> bool:
	for order in orders:
		if order.id == id and not order.completed:
			order.completed = true
			return true
	return false

func completed_count() -> int:
	var count := 0
	for order in orders:
		if order.completed:
			count += 1
	return count

func total_count() -> int:
	return orders.size()

func earned_support() -> int:
	var amount := 0
	for order in orders:
		if order.completed:
			amount += order.reward
	return amount

func full_load() -> bool:
	var aboard := 0
	for order: Dictionary in orders:
		if not order.completed:
			aboard += 1
	return aboard > 1
