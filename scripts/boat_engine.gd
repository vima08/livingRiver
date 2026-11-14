class_name BoatEngine
extends Resource

# Gear 9 is always reverse, so engines support up to eight forward gears.
@export var display_name := "River Twin"
@export var engine_id := "river_twin"
@export var fuel_multiplier := 1.0
@export var forward_speeds := PackedFloat32Array([95.0, 155.0])
@export var forward_accelerations := PackedFloat32Array([260.0, 210.0])
@export var reverse_speed := 100.0
@export var reverse_acceleration := 210.0

func valid_data() -> bool:
	if engine_id.is_empty() or forward_speeds.is_empty() or forward_speeds.size() > 8:
		return false
	if forward_speeds.size() != forward_accelerations.size():
		return false
	var previous := 0.0
	for i in range(forward_speeds.size()):
		if not is_finite(forward_speeds[i]) or forward_speeds[i] <= previous:
			return false
		if not is_finite(forward_accelerations[i]) or forward_accelerations[i] <= 0.0:
			return false
		previous = forward_speeds[i]
	return is_finite(reverse_speed) and reverse_speed > 0.0 and is_finite(reverse_acceleration) and reverse_acceleration > 0.0 and is_finite(fuel_multiplier) and fuel_multiplier > 0.0

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
