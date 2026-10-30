class_name SoundBoard extends Node3D
## La table des sons : des voix (AudioStreamPlayer3D) préparées une fois, sur le bus des bruitages. Un son se joue à une
## position, sur la voix suivante : quand toutes ont servi, la plus ancienne reprend (son son est coupé). Notre code ne
## crée rien en combat ; le moteur, lui, crée deux objets par son lancé (sa lecture) : `played` les fait compter.

## Un son vient d'être lancé : `cue` en `at`.
signal played_sound(cue: SoundCue, at: Vector3)

## Le nombre de voix.
@export_range(1, 64, 1) var voice_count: int = 16
## Le bus des voix.
@export var bus: StringName = &"SFX"
## La graine du tirage des variantes et des hauteurs : une partie rejouée sonne pareil.
@export var rng_seed: int = 1

## Combien de sons ont été lancés.
var played: int = 0
## Le dernier son lancé (aucun au départ).
var last_cue: SoundCue

var _voices: Array[AudioStreamPlayer3D] = []
var _next: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = rng_seed
	for i: int in voice_count:
		var voice: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		voice.name = "Voice%d" % i
		voice.bus = bus
		add_child(voice)
		_voices.append(voice)


## Joue `cue` en `at` : une variante et une hauteur tirées, sur la voix suivante. Un son sans variante ne joue rien.
func play(cue: SoundCue, at: Vector3) -> void:
	if cue == null or cue.streams.is_empty():
		return
	var voice: AudioStreamPlayer3D = _voices[_next]
	_next = (_next + 1) % _voices.size()
	voice.stream = cue.streams[_rng.randi_range(0, cue.streams.size() - 1)]
	voice.volume_db = cue.volume_db
	voice.pitch_scale = _rng.randf_range(cue.pitch_min, cue.pitch_max)
	voice.max_distance = cue.max_distance
	voice.global_position = at
	voice.play()
	played += 1
	last_cue = cue
	played_sound.emit(cue, at)
