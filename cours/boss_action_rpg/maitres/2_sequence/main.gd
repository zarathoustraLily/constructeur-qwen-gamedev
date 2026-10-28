extends Node3D
#@ 1
## La scène principale du niveau. À cette étape : un sol, une lumière et une caméra, de quoi lancer le projet (F5)
## et voir qu'il tient debout ; le héros, le boss et l'arène arrivent aux étapes suivantes.
#@ 2
## La scène principale du niveau : le sol, la lumière, la caméra, et le héros qui court par rapport à elle.
#@ 3+
## La scène principale du niveau : le sol, la lumière, le héros, la caméra à la troisième personne qui le suit, et
## une cible à verrouiller (le boss prendra sa place).
#@ 6+
## Quand le héros tombe, le niveau recommence après un délai : tout repart de zéro (héros, fioles, cible, et le boss
## quand il sera là), en rechargeant la scène.
#@ all
#@ 1-2

@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	_camera.make_current()
#@ 6+

## Ce qui entoure le combat : le délai avant de recommencer.
@export var settings: EncounterSettings

@onready var _hero: Hero = $Hero
@onready var _restart_timer: Timer = $RestartTimer
#@ 3+


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#@ 6+
	_hero.defeated.connect(_on_hero_defeated)
	_restart_timer.timeout.connect(_restart)


func _on_hero_defeated() -> void:
	_restart_timer.start(settings.restart_delay)


func _restart() -> void:
	get_tree().reload_current_scene()
#@ all
