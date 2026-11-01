extends SceneTree
## Combien d'objets crée la lecture d'un son : par AudioStreamPlayer3D.play(), puis par un flux polyphonique
## (AudioStreamPlaybackPolyphonic.play_stream). Compteur d'allocations de l'ObjectDB, comme mesurer_combat.gd.

const MASQUE_COMPTEUR: int = (1 << 39) - 1

var _frame: int = 0
var _simple: AudioStreamPlayer3D
var _poly: AudioStreamPlayer3D
var _playback: AudioStreamPlaybackPolyphonic
var _son: AudioStreamOggVorbis


func _initialize() -> void:
	_son = AudioStreamOggVorbis.load_from_file(OS.get_cmdline_user_args()[0])
	var monde: Node3D = Node3D.new()
	root.add_child(monde)
	_simple = AudioStreamPlayer3D.new()
	_simple.stream = _son
	_simple.max_polyphony = 4
	monde.add_child(_simple)
	_poly = AudioStreamPlayer3D.new()
	var flux: AudioStreamPolyphonic = AudioStreamPolyphonic.new()
	flux.polyphony = 8
	_poly.stream = flux
	monde.add_child(_poly)


func _compteur() -> int:
	var temoin: Object = Object.new()
	var c: int = (temoin.get_instance_id() >> 24) & MASQUE_COMPTEUR
	temoin.free()
	return c


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_poly.play()
		_playback = _poly.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if _frame == 10:
		var avant: int = _compteur()
		for _i: int in 20:
			_simple.play()
		print("play() x20 : ", _compteur() - avant - 1, " objets")
		avant = _compteur()
		for _i: int in 20:
			_playback.play_stream(_son)
		print("play_stream() x20 : ", _compteur() - avant - 1, " objets")
		avant = _compteur()
		print("rien : ", _compteur() - avant - 1, " objets")
	return _frame >= 12
