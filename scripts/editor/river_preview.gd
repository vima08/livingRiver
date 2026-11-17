@tool
extends RefCounted

# A data-only model for the editor. It never creates the game controller or services.
const Layout = preload("res://scripts/river_layout.gd")

class PreviewCargo:
	extends RefCounted

	func pending_for_stop(stop: String) -> Array:
		return [stop] if stop in ["koya", "luma"] else []

var camera_y := -520.0
var boat_pos := Vector2(640, 0)
var elapsed := 0.0
var velocity := Vector2.ZERO
var travel_sign := -1.0
var hull := 100.0
var impact_flash := 0.0
var pickup_taken := false
var rocks: Array = []
var fuel_pickup := Vector2.ZERO
var dock_pos := Vector2.ZERO
var luma_pos := Vector2.ZERO
var base_pos := Vector2.ZERO
var manifest := PreviewCargo.new()

func _init() -> void:
	var route: Dictionary = Layout.build()
	rocks = route.rocks
	fuel_pickup = route.fuel_pickup
	dock_pos = route.dock_pos
	luma_pos = route.luma_pos
	base_pos = route.base_pos

func river_center(y: float) -> float:
	return Layout.river_center(y)

func river_half_width(y: float) -> float:
	return Layout.river_half_width(y)

func island_center(y: float) -> float:
	return Layout.island_center(y)

func island_half_width(y: float) -> float:
	return Layout.island_half_width(y)

func current_at(pos: Vector2) -> Vector2:
	return Layout.current_at(pos)

func completed_order(_id: String) -> bool:
	return false

func boat_angle() -> float:
	return PI if travel_sign > 0.0 else 0.0
