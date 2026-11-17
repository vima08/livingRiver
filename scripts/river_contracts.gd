class_name RiverContracts
extends RefCounted

const LANDINGS := {"base": "Base", "luma": "Luma Landing", "koya": "Koya Landing"}
const LANDING_Y := {"base": 0.0, "luma": -14500.0, "koya": -26000.0}
const JOBS := {
	"base_light": {"origin": "base", "destination": "koya", "source": "Base logistics depot", "title": "Filters for Koya", "orders": ["koya_filters"]},
	"base_full": {"origin": "base", "destination": "koya", "source": "Base logistics depot", "title": "Full relief via Luma", "orders": ["luma_food", "koya_filters"]},
	"koya_luma": {"origin": "koya", "destination": "luma", "source": "Koya cooperative", "title": "Food for Luma", "orders": ["luma_food"]},
	"luma_koya": {"origin": "luma", "destination": "koya", "source": "Luma regional supply cache", "title": "Filters for Koya", "orders": ["koya_filters"]},
	"luma_base": {"origin": "luma", "destination": "base", "source": "Luma Landing", "title": "Empty return to Base", "orders": []},
}
const ORDERS := {
	"luma_food": {"id": "luma_food", "cargo": "Food", "recipient": "Luma Landing", "stop": "luma", "reward": 60},
	"koya_filters": {"id": "koya_filters", "cargo": "Water filters", "recipient": "Koya Landing", "stop": "koya", "reward": 100},
}

static func job(id: String) -> Dictionary:
	return JOBS.get(id, {}).duplicate(true)

static func available(landing: String) -> Array[String]:
	var result: Array[String] = []
	for id: String in JOBS:
		if JOBS[id].origin == landing:
			result.append(id)
	return result

static func direction(id: String) -> float:
	var data := job(id)
	return signf(float(LANDING_Y[data.destination]) - float(LANDING_Y[data.origin])) if not data.is_empty() else -1.0

static func reward(id: String) -> int:
	var result := 0
	for order: String in job(id).get("orders", []):
		result += int(ORDERS[order].reward)
	return result
