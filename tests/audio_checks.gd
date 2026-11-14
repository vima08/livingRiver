extends SceneTree

const RiverAudio = preload("res://scripts/river_audio.gd")
const Manifest = preload("res://scripts/relief_manifest.gd")
var failures := 0
var results: Array[String] = []

class Fixture extends Node:
	var state := "running"
	var ui_screen := ""
	var fuel := 100.0
	var engine_throttle := 0.0
	var selected_gear := 1
	var velocity := Vector2.ZERO
	var settings := {"master": 0.8, "music": 0.4, "effects": 0.7}
	var manifest = preload("res://scripts/relief_manifest.gd").new()

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	results.append(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1

func inspect_buffer(stream: AudioStreamWAV, label: String, loop_boundary: bool) -> float:
	check(stream.format == AudioStreamWAV.FORMAT_16_BITS, label + " uses uncompressed signed 16-bit PCM")
	var data := stream.data
	var peak := 0
	for i in range(data.size() / 2):
		peak = maxi(peak, absi(data.decode_s16(i * 2)))
	check(peak > 100 and peak < 24000, "%s non-silent buffer has conservative peak %.4f" % [label, float(peak) / 32768.0])
	if loop_boundary:
		var boundary := absf(float(data.decode_s16(0) - data.decode_s16(data.size() - 2)) / 32768.0)
		check(boundary < 0.015, "%s endpoint step %.5f (numerical seam check only)" % [label, boundary])
	return float(peak) / 32768.0

func run() -> void:
	# This fixture never initializes settings persistence or player progression.
	var fixture := Fixture.new()
	root.add_child(fixture)
	var audio := RiverAudio.new()
	audio.game = fixture
	fixture.add_child(audio)
	audio.set_process(false)
	var engine_peak := inspect_buffer(RiverAudio.ENGINE_ASSET, "Engine", true)
	var music_peak := inspect_buffer(RiverAudio.MUSIC_ASSET, "Music", true)
	var event_peak := 0.0
	for event in RiverAudio.EVENTS:
		event_peak = maxf(event_peak, inspect_buffer(RiverAudio.EVENTS[event], event, false))
	# Sum independent peak bounds at maximum settings, including four worst-case cues.
	var max_mix_bound := engine_peak * 0.37 + music_peak * 0.35 + 4 * event_peak * db_to_linear(-7.0)
	check(max_mix_bound < 0.9, "Conservative full-settings four-voice mix peak bound %.4f stays below clipping" % max_mix_bound)
	check(audio.engine_player.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and audio.music_player.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Both continuous players loop in the actual playback streams")
	check(audio.engine_player.bus == "Effects" and audio.music_player.bus == "Music", "Engine and music have separate playback and buses")
	var idle: Vector2 = audio.targets()
	fixture.velocity = Vector2(0, 200)
	check(audio.targets() == idle, "Current-driven ground velocity cannot change idle")
	fixture.engine_throttle = 1.0
	var first: Vector2 = audio.targets()
	check(first.x > idle.x and first.y > idle.y, "Drive demand raises engine level and pitch even at low ground speed")
	fixture.selected_gear = 2
	check(audio.targets().y > first.y, "Gear changes loaded engine pitch")
	var light: Vector2 = audio.targets()
	fixture.manifest.configure("full")
	check(audio.targets().y < light.y, "Full cargo changes loaded engine response")
	fixture.selected_gear = 9
	check(audio.targets().y > idle.y, "Reverse responds to throttle")
	for state in ["ready", "paused", "failure", "partial", "success", "depot"]:
		fixture.state = state
		check(audio.targets().x == 0.0, "Engine fades out in " + state)
	fixture.state = "running"
	fixture.ui_screen = "settings"
	check(audio.targets().x == 0.0, "Engine is silent behind Settings")
	fixture.ui_screen = ""
	fixture.fuel = 0
	check(audio.targets().x == 0.0, "Fuel exhaustion shuts engine down")
	fixture.fuel = 100
	for bus in ["Master", "Music", "Effects"]:
		fixture.settings[bus.to_lower()] = 0.0
		audio.update_mix()
		check(AudioServer.is_bus_mute(AudioServer.get_bus_index(bus)), bus + " zero really mutes")
		fixture.settings[bus.to_lower()] = 0.5
		audio.update_mix()
		check(not AudioServer.is_bus_mute(AudioServer.get_bus_index(bus)), bus + " restores from mute")
	var music_id := audio.music_player.get_instance_id()
	var engine_id := audio.engine_player.get_instance_id()
	audio.play_event("gear")
	var played: int = audio.events_played
	for i in range(100):
		audio.play_event("gear")
	check(audio.events_played == played, "Repeated gear events respect cooldown")
	for kind in RiverAudio.EVENTS:
		audio.play_event(kind)
	check(audio.voices.size() == RiverAudio.VOICE_LIMIT and audio.get_child_count() == RiverAudio.VOICE_LIMIT + 2, "Burst events retain exactly four cached voices and two loops")
	for i in range(20):
		fixture.state = "paused" if i % 2 == 0 else "running"
		audio._process(0.1)
	check(audio.music_player.get_instance_id() == music_id and audio.engine_player.get_instance_id() == engine_id, "Repeated state changes retain exactly the same loop players")
	fixture.state = "paused"
	for i in range(100):
		audio._process(0.02)
	check(audio.engine_level < 0.0005 and (not audio.output_enabled or audio.engine_player.stream_paused), "Engine smoothly reaches silent paused gain")
	fixture.state = "running"
	audio._process(0.02)
	check(not audio.engine_player.stream_paused and audio.engine_level > 0.0, "Engine resumes through smooth gain rather than another loop")
	for line in results:
		print(line)
	print("AUDIO_CHECKS failures=%d; headless output disabled; hearing/overlap/output quality remains unverified" % failures)
	fixture.free()
	await create_timer(0.1).timeout
	quit(1 if failures else 0)
