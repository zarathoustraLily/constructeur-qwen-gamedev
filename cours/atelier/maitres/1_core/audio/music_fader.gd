class_name MusicFader extends Node
## La musique et ses fondus enchaînés : deux lecteurs se relaient ; le nouveau morceau monte pendant que l'ancien
## descend, à puissance constante (cosinus et sinus) : le volume perçu ne creuse pas au milieu du fondu.

## Le bus des lecteurs.
@export var bus: StringName = &"Music"
## La durée des fondus.
@export var settings: AudioSettings

## L'avancée du fondu en cours, de 0 (début) à 1 (fini).
var progress: float = 1.0

var _players: Array[AudioStreamPlayer] = []
var _active: int = 0


func _ready() -> void:
	for i: int in 2:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "Deck%d" % i
		player.bus = bus
		player.volume_db = Volume.FLOOR_DB
		add_child(player)
		_players.append(player)


func _process(delta: float) -> void:
	advance(delta)


## Lance `stream` en fondu enchaîné sur `settings.crossfade_time` ; le même morceau déjà en cours ne relance rien.
func play(stream: AudioStream) -> void:
	if current().stream == stream and current().playing:
		return
	_active = 1 - _active
	current().stream = stream
	current().play()
	progress = 0.0 if settings.crossfade_time > 0.0 else 1.0
	apply()


## Fait avancer le fondu de `delta` secondes ; à la fin, l'ancien lecteur s'arrête.
func advance(delta: float) -> void:
	if progress >= 1.0:
		return
	progress = minf(progress + delta / settings.crossfade_time, 1.0)
	apply()
	if progress >= 1.0:
		previous().stop()


## Pose les volumes des deux lecteurs selon l'avancée du fondu.
func apply() -> void:
	var gains: Vector2 = equal_power(progress)
	previous().volume_db = Volume.to_db(gains.x)
	current().volume_db = Volume.to_db(gains.y)


## Le lecteur du morceau qui monte (ou qui joue).
func current() -> AudioStreamPlayer:
	return _players[_active]


## Le lecteur du morceau qui descend.
func previous() -> AudioStreamPlayer:
	return _players[1 - _active]


## Les gains (x : sortant, y : entrant) à l'avancée `t` (0 à 1) d'un fondu à puissance constante :
## cos et sin de t × PI/2, dont la somme des carrés vaut toujours 1.
static func equal_power(t: float) -> Vector2:
	var angle: float = clampf(t, 0.0, 1.0) * PI / 2.0
	return Vector2(cos(angle), sin(angle))
