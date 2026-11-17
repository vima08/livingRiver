@tool
extends Node2D

func set_animation_time(time: float) -> void:
	get_node("Pulse").scale = Vector2.ONE * (35.0 + sin(time * 3.0) * 3.0) / 35.0
