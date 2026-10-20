extends Node
## Audio global : la musique qui traverse les scènes, et les volumes (ARC-09). Les bruitages
## restent dans la scène qui les émet (un AudioStreamPlayer3D dans le script _view de l'entité).
## Entrées : play_music(), stop_music(), set_volume(). Possède : le lecteur de musique.

var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	add_child(_music)


func play_music(stream: AudioStream) -> void:
	if stream == null:
		push_error("AudioManager.play_music : flux absent")
		return
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.play()


func stop_music() -> void:
	_music.stop()


func is_playing_music() -> bool:
	return _music.playing


## Volume d'un bus audio, de 0 (muet) à 1 (plein).
func set_volume(bus: StringName, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		push_error("AudioManager.set_volume : bus inconnu %s" % bus)
		return
	AudioServer.set_bus_volume_db(i, linear_to_db(clampf(linear, 0.0, 1.0)))
