extends Node
## Plays the synthesised sounds in assets/sfx. A missing file is silent, never
## an error, so the game runs before the sounds are built.

const DIR: String = "res://assets/sfx/"
const VOICES: int = 20

var muted: bool = false
var master_db: float = 0.0
var music_db: float = 0.0
var sfx_db: float = 0.0
var _cache: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _loops: Dictionary = {}
var played: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(VOICES):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)


func stream(sound: String) -> AudioStream:
	if _cache.has(sound):
		return _cache[sound]
	var path := DIR + sound + ".wav"
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	_cache[sound] = s
	return s


func play(sound: String, volume_db: float = 0.0, pitch: float = 1.0, vary: float = 0.07) -> void:
	played[sound] = int(played.get(sound, 0)) + 1
	if muted:
		return
	var s := stream(sound)
	if s == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % VOICES
	p.stream = s
	p.volume_db = volume_db + master_db + sfx_db
	p.pitch_scale = maxf(0.05, pitch * (1.0 + randf_range(-vary, vary)))
	p.play()


## A looping bed (wind, music). One per slot; a new sound replaces the old.
func loop(slot: String, sound: String, volume_db: float = -14.0) -> void:
	if _loops.has(slot):
		var old: AudioStreamPlayer = _loops[slot]
		if old.get_meta("sound", "") == sound:
			old.set_meta("base_db", volume_db)
			old.volume_db = volume_db + master_db + (music_db if slot == "music" else sfx_db)
			return
		old.queue_free()
		_loops.erase(slot)
	if sound == "" or muted:
		return
	var s := stream(sound)
	if s == null:
		return
	var st: AudioStream = s.duplicate()
	if st is AudioStreamWAV:
		var w: AudioStreamWAV = st
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		var bytes := 2 if w.format == AudioStreamWAV.FORMAT_16_BITS else 1
		w.loop_end = w.data.size() / (bytes * (2 if w.stereo else 1))
	var p := AudioStreamPlayer.new()
	p.stream = st
	p.volume_db = volume_db + master_db + (music_db if slot == "music" else sfx_db)
	p.set_meta("sound", sound)
	p.set_meta("base_db", volume_db)
	add_child(p)
	p.play()
	_loops[slot] = p


## After a volume change: every loop at its own level plus the new buses.
func refresh_loops() -> void:
	for slot: Variant in _loops.keys():
		var p: AudioStreamPlayer = _loops[slot]
		if is_instance_valid(p):
			p.volume_db = float(p.get_meta("base_db", -14.0)) + master_db + (music_db if String(slot) == "music" else sfx_db)


func stop_loop(slot: String) -> void:
	loop(slot, "")
