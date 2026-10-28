extends Node3D
#@ 1
## La scène principale du niveau. À cette étape : un sol, une lumière et une caméra, de quoi lancer le projet (F5)
## et voir qu'il tient debout ; le héros, le boss et l'arène arrivent aux étapes suivantes.
#@ 2
## La scène principale du niveau : le sol, la lumière, la caméra, et le héros qui court par rapport à elle.
#@ 3+
## La scène principale du niveau : le sol, la lumière, le héros, la caméra à la troisième personne qui le suit, et
## une cible à verrouiller (le boss prendra sa place).
#@ all
#@ 1-2

@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	_camera.make_current()
#@ 3+


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#@ all
