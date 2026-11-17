@tool
extends Node2D

@export var filters_loaded := true:
	set(value):
		filters_loaded = value
		_sync_parts()
@export var food_loaded := true:
	set(value):
		food_loaded = value
		_sync_parts()
@export var hull_damaged := false:
	set(value):
		hull_damaged = value
		_sync_parts()

func _ready() -> void:
	_sync_parts()

func set_boat_state(filters: bool, food: bool, damaged: bool) -> void:
	filters_loaded = filters
	food_loaded = food
	hull_damaged = damaged

func _sync_parts() -> void:
	if not has_node("Filters") or not has_node("Food") or not has_node("Damage"):
		return
	get_node("Filters").visible = filters_loaded
	get_node("Food").visible = food_loaded
	get_node("Damage").visible = hull_damaged
