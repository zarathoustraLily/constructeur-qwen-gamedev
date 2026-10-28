class_name SfxPool extends Node
## Une réserve de lecteurs d'effets sonores : un effet ne coupe pas le précédent tant qu'une voix est libre ; quand
## toutes jouent, la plus ancienne est reprise. Chaque effet varie un peu en hauteur et en volume : le même son répété
## ne sonne pas comme une mitraillette.

## Le bus des lecteurs.
@export var bus: StringName = &"SFX"
## Voix, variations, graine.
@export var settings: AudioSettings

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = settings.random_seed
	for i: int in settings.sfx_voices:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "Voice%d" % i
		player.bus = bus
		add_child(player)
		_players.append(player)


## Joue `stream` sur une voix libre (ou la plus ancienne), avec une hauteur et un volume légèrement tirés ; rend la
## voix employée.
func play(stream: AudioStream) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = free_voice()
	player.stream = stream
	player.pitch_scale = jitter(1.0, settings.pitch_variation, _rng)
	player.volume_db = _rng.randf_range(-settings.volume_variation_db, settings.volume_variation_db)
	player.play()
	return player


## La première voix qui ne joue pas ; si toutes jouent, la suivante dans l'ordre (la plus ancienne reprise).
func free_voice() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _players:
		if not player.playing:
			return player
	var stolen: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	return stolen


## Les voix de la réserve.
func voices() -> Array[AudioStreamPlayer]:
	return _players


## `base` varié de plus ou moins `variation` (en part de `base`), tiré par `rng`.
static func jitter(base: float, variation: float, rng: RandomNumberGenerator) -> float:
	return base * (1.0 + rng.randf_range(-variation, variation))
