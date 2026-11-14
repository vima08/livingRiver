extends SceneTree

# Offline, original deterministic synthesis. Never loaded by the game.
const RATE := 22050
const PERIOD := 32.0
var streams: Dictionary = {}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio")
	write_sound("engine", 2.0)
	write_sound("river_theme", PERIOD)
	for kind in ["collision", "refuel", "low_fuel", "delivery", "failure", "gear"]:
		write_sound(kind, 0.8 if kind in ["delivery", "failure"] else 0.4)
	write_preview()
	print("Original audio rendered: engine 2 s, theme 32 s, six cues, 102 s review preview.")
	quit()

func pitch(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)

func music(t: float) -> float:
	# Dmaj9 / Gmaj7 / Bm7 / Asus2: slow pads, soft bass and a sparse plucked melody.
	var chords := [[50, 57, 61, 64, 69], [43, 54, 59, 62, 66], [47, 54, 57, 62, 66], [45, 52, 59, 64, 69]]
	var value := 0.0
	for bar in range(4):
		var age := fposmod(t - bar * 8.0, PERIOD)
		if age < 8.0:
			var pad := pow(sin(PI * age / 8.0), 1.5)
			for note in chords[bar]:
				var phase := TAU * pitch(note) * age
				value += pad * (sin(phase) * 0.017 + sin(phase * 2.0) * 0.002)
			value += sin(TAU * pitch(chords[bar][0] - 12) * age) * pad * 0.035
	var melody := [74, 69, 66, 69, 71, 74, 78, 74, 73, 69, 66, 62, 64, 69, 71, 69]
	for i in range(melody.size()):
		var age := fposmod(t - i * 2.0 - 0.3, PERIOD)
		if age < 5.0:
			var env := (1.0 - exp(-age * 30.0)) * exp(-age * 1.5) * pow(1.0 - age / 5.0, 2.0)
			var phase := TAU * pitch(melody[i]) * age
			value += env * (sin(phase) * 0.055 + sin(phase * 2.0) * 0.011 + sin(phase * 3.0) * 0.004)
	return value

func engine(t: float) -> float:
	var cycle := TAU * 42.0 * t
	var pulse := 0.7 + 0.3 * sin(TAU * 7.0 * t)
	var value := pulse * (sin(cycle) * 0.19 + sin(cycle * 2.0) * 0.09 + sin(cycle * 3.0) * 0.05 + sin(cycle * 5.0) * 0.02)
	# Periodic broad mechanical texture; all components close at the two-second boundary.
	for i in range(12):
		value += sin(TAU * (173.0 + i * 47.0) * t + i * 1.713) * 0.005 * pulse
	return value

func cue(kind: String, t: float) -> float:
	var duration := 0.8 if kind in ["delivery", "failure"] else 0.4
	var env := minf(t / 0.012, 1.0) * pow(maxf(0.0, 1.0 - t / duration), 2.0)
	if kind == "collision":
		return env * (sin(TAU * (105.0 * t - 55.0 * t * t)) * 0.36 + sin(TAU * 587.0 * t) * 0.07)
	if kind == "gear":
		return env * exp(-t * 20.0) * (sin(TAU * 190.0 * t) * 0.3 + sin(TAU * 510.0 * t) * 0.08)
	var notes: Array = {"delivery": [74, 78, 81], "refuel": [66, 74], "low_fuel": [66, 66], "failure": [57, 52, 50]}[kind]
	var value := 0.0
	for i in range(notes.size()):
		var age := t - i * duration / (notes.size() + 1.0)
		if age > 0.0:
			value += sin(TAU * pitch(notes[i]) * age) * minf(age / 0.012, 1.0) * exp(-age * 9.0) * 0.24
	return value * env

func pcm(value: float) -> int:
	return int(round(clampf(value, -1.0, 1.0) * 32767.0)) & 65535

func write_wav(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(36 + bytes.size())
	file.store_buffer("WAVEfmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(RATE)
	file.store_32(RATE * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(bytes.size())
	file.store_buffer(bytes)
	file.close()

func write_sound(kind: String, duration: float) -> void:
	var bytes := PackedByteArray()
	bytes.resize(int(duration * RATE) * 2)
	for i in range(bytes.size() / 2):
		var t := float(i) / RATE
		var value := engine(t) if kind == "engine" else (music(t) if kind == "river_theme" else cue(kind, t))
		bytes.encode_u16(i * 2, pcm(value))
	streams[kind] = bytes
	write_wav("res://assets/audio/%s.wav" % kind, bytes)

func sample(kind: String, time: float) -> float:
	var bytes: PackedByteArray = streams[kind]
	var index := int(time * RATE) % (bytes.size() / 2)
	return float(bytes.decode_s16(index * 2)) / 32768.0

func write_preview() -> void:
	# Four engine phases repeated through three music boundaries; cues separated in time.
	var bytes := PackedByteArray()
	bytes.resize(102 * RATE * 2)
	var phase := 0.0
	for i in range(bytes.size() / 2):
		var t := float(i) / RATE
		var part := int(t / 8.0) % 6
		var demand := [0.0, 0.45, 1.0, 0.0, 0.7, 0.0][part] as float
		phase += (0.85 + demand * 0.65) / RATE
		var value := sample("river_theme", t) * 0.35
		if part != 5:
			value += sample("engine", phase) * (0.22 + demand * 0.15) * minf(fposmod(t, 8.0), 0.25) * 4.0 * minf(8.0 - fposmod(t, 8.0), 0.25) * 4.0
		var events := {12: "gear", 28: "refuel", 44: "collision", 60: "low_fuel", 76: "delivery", 92: "failure"}
		for start in events:
			if t >= start and t < start + 0.8:
				var cue_bytes: PackedByteArray = streams[events[start]]
				if t - start < float(cue_bytes.size() / 2) / RATE:
					value += sample(events[start], t - start) * 0.65
		bytes.encode_u16(i * 2, pcm(value))
	write_wav("res://doc/evidence/milestone4-audio-listening-preview-102s.wav", bytes)
