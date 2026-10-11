extends Node
## Sons ponctuels : un petit groupe de lecteurs réutilisés (aucune création pendant le jeu).

const POOL_SIZE := 8

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var player := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.play()
