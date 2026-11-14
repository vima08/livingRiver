extends SceneTree

const RiverAudio = preload("res://scripts/river_audio.gd")
var failures := 0

class Fixture extends Node:
	var state := "running"
	var ui_screen := ""
	var fuel := 100.0
	var engine_throttle := 1.0
	var selected_gear := 8
	var settings := {"master": 1.0, "music": 1.0, "effects": 1.0}
	var manifest = preload("res://scripts/relief_manifest.gd").new()

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func run() -> void:
	var fixture := Fixture.new()
	root.add_child(fixture)
	var audio := RiverAudio.new()
	audio.game = fixture
	fixture.add_child(audio)
	audio.set_process(false)
	for pair in [[RiverAudio.ENGINE_ASSET, audio.engine_player.stream], [RiverAudio.MUSIC_ASSET, audio.music_player.stream]]:
		var source: AudioStreamWAV = pair[0]
		var actual: AudioStreamWAV = pair[1]
		check(actual.loop_end == source.data.size() / 2 and actual.loop_begin == 0, "Actual loop endpoints exactly cover all mono PCM frames")
		check(actual != source and actual.data.slice(0, source.data.size()) == source.data, "Loop setup preserves cached original PCM prefix")
		check(actual.data.size() == source.data.size() + 2 and actual.data.slice(source.data.size()) == source.data.slice(0, 2), "Loop stream includes one guard frame matching its first PCM frame")
	for delta in [0.0, 0.001, 0.5, 10.0]:
		audio._process(delta)
		check(is_finite(audio.engine_pitch) and audio.engine_pitch >= 0.849999 and audio.engine_pitch <= 1.960001 and audio.engine_level >= 0 and audio.engine_level <= 0.370001, "Extreme valid frame delta %.3f preserves gain/pitch bounds for eighth gear" % delta)
	var nodes := audio.get_child_count()
	var start := Time.get_ticks_usec()
	for i in range(20000):
		audio._process(1.0 / 60)
	var duration := Time.get_ticks_usec() - start
	check(audio.get_child_count() == nodes, "Twenty thousand audio updates allocate no extra player nodes")
	print("CONTROL_MICROBENCH %d updates in %.2f ms, %.3f us/update; headless control overhead only, not mixer/render performance" % [20000, duration / 1000.0, duration / 20000.0])
	fixture.fuel = 0
	audio._process(10)
	check(audio.engine_level < 0.0005 and (not audio.output_enabled or audio.engine_player.stream_paused), "Fuel-empty engine reaches silent gain (stream pause requires actual playback)")
	fixture.fuel = 100
	audio._process(0.016)
	check(not audio.engine_player.stream_paused and audio.engine_level > 0, "Fuel restoration resumes same stream")
	var before := audio.events_played
	audio.play_event("not-a-real-cue")
	check(audio.events_played == before and not audio.cooldowns.has("not-a-real-cue"), "Unknown cue cannot allocate voices or cooldown entries")
	fixture.free()
	await create_timer(0.1).timeout
	print("AUDIO_ADVERSARIAL4 failures=%d" % failures)
	quit(1 if failures else 0)
