@tool
extends Node2D

@export_range(0, 63) var variant: int = 0:
	set(value):
		variant = clampi(value, 0, 63)
		_refresh()
@export_range(1.0, 100.0) var radius: float = 40.0:
	set(value):
		radius = value
		_refresh()

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	var sprite := get_node_or_null("Crown") as Sprite2D
	if sprite == null:
		return
	sprite.texture = load("res://assets/visual/canopy_%02d.svg" % variant)
	sprite.scale = Vector2.ONE * radius / 40.0
