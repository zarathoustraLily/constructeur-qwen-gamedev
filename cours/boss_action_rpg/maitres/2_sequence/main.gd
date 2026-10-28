extends Node3D
#@ 1
## La scène principale du niveau. À cette étape : un sol, une lumière et une caméra, de quoi lancer le projet (F5)
## et voir qu'il tient debout ; le héros, le boss et l'arène arrivent aux étapes suivantes.
#@ 2+
## La scène principale du niveau : le sol, la lumière, la caméra, et le héros qui court par rapport à elle.
#@ all

@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	_camera.make_current()
