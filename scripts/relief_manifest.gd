class_name ReliefManifest
extends RefCounted

var orders: Array[Dictionary] = []
var preset := "light"

func _init(load_name: String = "light") -> void:
	configure(load_name)

func configure(load_name: String) -> bool:
	if load_name not in ["light", "full"]:
		return false
	preset = load_name
	orders.clear()
	if preset == "full":
		orders.append({"id": "luma_food", "cargo": "Food", "recipient": "Luma Landing", "stop": "luma", "reward": 60, "completed": false})
	orders.append({"id": "koya_filters", "cargo": "Water filters", "recipient": "Koya Landing", "stop": "koya", "reward": 100, "completed": false})
	return true

func valid_data() -> bool:
	if preset not in ["light", "full"] or orders.size() != (2 if preset == "full" else 1):
		return false
	var seen: Array[String] = []
	for order in orders:
		for field in ["id", "cargo", "recipient", "stop", "reward", "completed"]:
			if not order.has(field):
				return false
		if order.id in seen or not order.completed is bool:
			return false
		if order.id == "luma_food":
			if preset != "full" or order.stop != "luma" or order.cargo != "Food" or order.reward != 60 or order.recipient != "Luma Landing":
				return false
		elif order.id == "koya_filters":
			if order.stop != "koya" or order.cargo != "Water filters" or order.reward != 100 or order.recipient != "Koya Landing":
				return false
		else:
			return false
		seen.append(order.id)
	return "koya_filters" in seen

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
	return orders.size() == 2 and not completed_order("luma_food")
