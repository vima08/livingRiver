@tool
extends Node2D

# The gallery is a standalone scene. Its native instances are visible before play.
func _ready() -> void:
	$BoatEmpty.set_boat_state(false, false, false)
	$BoatLoaded.set_boat_state(true, true, false)
	$BoatDamaged.set_boat_state(true, false, true)
	$LumaReceived.set_received(true)
	$KoyaReceived.set_received(true)
