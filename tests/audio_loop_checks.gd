extends SceneTree

# Exercise the actual engine decoder/resampler, including its loop boundary.
# This is an offline mixer check; it cannot approve heard timbre or device output.
const RiverAudio = preload("res://scripts/river_audio.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func inspect(stream: AudioStreamWAV, pitch_mode: String) -> void:
	var playback := stream.instantiate_playback()
	playback.start()
	var samples := PackedVector2Array()
	var frames := int(AudioServer.get_mix_rate()) * 12
	var current_pitch := 0.85
	while samples.size() < frames:
		var time := float(samples.size()) / AudioServer.get_mix_rate()
		var target := 0.85
		if pitch_mode == "throttle":
			target = 1.45
		elif pitch_mode == "transitions":
			target = 1.45 if int(time / 2.0) % 2 == 1 else 0.85
		current_pitch = lerpf(current_pitch, target, 1.0 - exp(-6.0 * 256.0 / AudioServer.get_mix_rate()))
		var chunk := playback.mix_audio(current_pitch, mini(256, frames - samples.size()))
		if chunk.is_empty():
			break
		samples.append_array(chunk)
	var max_step := 0.0
	var max_curvature := 0.0
	var transient_count := 0
	for i in range(2, samples.size()):
		max_step = maxf(max_step, absf(samples[i].x - samples[i - 1].x))
		var curvature := absf(samples[i].x - 2.0 * samples[i - 1].x + samples[i - 2].x)
		max_curvature = maxf(max_curvature, curvature)
		if curvature > 0.012:
			transient_count += 1
	check(samples.size() == frames, pitch_mode + " mixes twelve seconds without stopping")
	check(transient_count == 0, "%s actual mixer has no isolated sharp transients: step=%.6f curvature=%.6f count=%d" % [pitch_mode, max_step, max_curvature, transient_count])
	playback.stop()

func _initialize() -> void:
	var audio := RiverAudio.new()
	var engine: AudioStreamWAV = audio.looped(RiverAudio.ENGINE_ASSET)
	check(engine.loop_end == int(round(RiverAudio.ENGINE_ASSET.get_length() * engine.mix_rate)), "Guard frame preserves original engine loop period")
	for mode in ["idle", "throttle", "transitions"]:
		inspect(engine, mode)
	audio.free()
	print("AUDIO_LOOP_CHECKS failures=%d; actual offline mixer checked; hearing remains unverified" % failures)
	quit(1 if failures else 0)
