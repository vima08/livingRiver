class_name BoatEngine
extends Resource

# Gear 9 is always reverse, so engines support up to eight forward gears.
@export var display_name := "River Twin"
@export var forward_speeds := PackedFloat32Array([95.0, 155.0])
@export var forward_accelerations := PackedFloat32Array([260.0, 210.0])
@export var reverse_speed := 100.0
@export var reverse_acceleration := 210.0

func gear_count() -> int:
	return mini(forward_speeds.size(), 8)

func supports_gear(gear: int) -> bool:
	return gear == 9 or (gear >= 1 and gear <= gear_count())

func speed_for(gear: int) -> float:
	if gear == 9:
		return reverse_speed
	return forward_speeds[gear - 1] if supports_gear(gear) else 0.0

func acceleration_for(gear: int) -> float:
	if gear == 9:
		return reverse_acceleration
	if supports_gear(gear) and gear <= forward_accelerations.size():
		return forward_accelerations[gear - 1]
	return 210.0
