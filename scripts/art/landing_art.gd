@tool
extends Node2D

const Text = preload("res://scripts/localization.gd")
var _crew: Array[Node] = []
var _rings: Array[Node] = []
var _beacons: Array[Node] = []

func _ready() -> void:
	if not Engine.is_editor_hint():
		refresh_locale()
	_crew = find_children("Crew*", "Node2D", true, false)
	for part: Node in find_children("*", "Line2D", true, false):
		if part.has_meta("dock_pulse"):
			_rings.append(part)
		if part.has_meta("beacon_pivot"):
			_beacons.append(part)

func set_received(received: bool) -> void:
	get_node("Waiting").visible = not received
	get_node("Received").visible = received

func refresh_locale() -> void:
	for label: Node in find_children("*", "Label", true, false):
		if label.has_meta("localization_key"):
			label.text = Text.t(str(label.get_meta("localization_key")))

func set_animation_time(time: float) -> void:
	for crew: Node2D in _crew:
		var phase := float(crew.get_meta("crew_index")) * 2.0
		crew.position.x = (sin(time * 1.6 + phase) - sin(phase)) * float(crew.get_meta("crew_amplitude"))
	for ring: Line2D in _rings:
		ring.modulate.a = (0.6 + sin(time * 2.0) * 0.15) / 0.6
	for beacon: Line2D in _beacons:
		var factor := (19.0 + sin(time * 2.0) * 3.0) / 19.0
		beacon.scale = Vector2.ONE * factor
		beacon.position = Vector2(beacon.get_meta("beacon_pivot")) * (1.0 - factor)
