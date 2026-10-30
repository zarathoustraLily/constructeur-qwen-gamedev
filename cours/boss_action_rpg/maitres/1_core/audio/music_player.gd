class_name MusicPlayer extends AudioStreamPlayer
## Une musique qui entre en fondu (start), sort en fondu (fade_out) puis s'arrête. Le fondu se fait dans update, sans
## Tween : en créer un en combat, c'est des objets alloués.

## Le volume plein et les durées des fondus.
@export var settings: MusicSettings

## Le niveau du moment, de 0 (silence) à 1 (plein).
var level: float = 0.0

var _target: float = 0.0


func _ready() -> void:
	volume_linear = 0.0


func _process(delta: float) -> void:
	update(delta)


## La musique entre en fondu ; elle part du début si elle ne jouait pas.
func start() -> void:
	if not playing:
		play()
	_target = 1.0


## La musique sort en fondu, puis s'arrête.
func fade_out() -> void:
	_target = 0.0


## Fait passer `delta` secondes sur le fondu ; revenue au silence, elle s'arrête.
func update(delta: float) -> void:
	var duree: float = settings.fade_in_time if _target > level else settings.fade_out_time
	level = move_toward(level, _target, delta / duree)
	volume_linear = db_to_linear(settings.volume_db) * level
	if playing and level == 0.0 and _target == 0.0:
		stop()
