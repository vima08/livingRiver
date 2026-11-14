extends SceneTree

class Fixture extends Node:
	var state := "running"
	var ui_screen := ""
	var fuel := 100.0
	var engine_throttle := 0.0
	var selected_gear := 2
	var settings := {"master": 1.0, "music": 0.0, "effects": 1.0}
	var manifest = preload("res://scripts/relief_manifest.gd").new()

var fixture: Fixture
var audio: Node
var recorder: AudioEffectRecord
var elapsed := 0.0
var done := false

func _initialize() -> void:
	call_deferred("setup")

func setup() -> void:
	fixture = Fixture.new()
	root.add_child(fixture)
	audio = preload("res://scripts/river_audio.gd").new()
	audio.game = fixture
	fixture.add_child(audio)
	if not audio.output_enabled:
		quit(2)
		return
	recorder = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	recorder.set_recording_active(true)
	print("ENGINE_PROBE idle 0..8s, second-gear throttle 8..16s, alternate throttle/coast 16..24s; no event cues, no music")

func _process(delta: float) -> bool:
	if not is_instance_valid(audio) or done:
		return false
	elapsed += delta
	fixture.engine_throttle = 0.0 if elapsed < 8 else (1.0 if elapsed < 16 else float(int(elapsed) % 2))
	if elapsed >= 24:
		done = true
		finish()
	return false

func finish() -> void:
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	var result := recording.save_to_wav("res://doc/evidence/milestone4-engine-click-probe-24s.wav")
	print("ENGINE_PROBE capture_seconds=%.3f save_result=%d" % [recording.get_length(), result])
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	fixture.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(result)
