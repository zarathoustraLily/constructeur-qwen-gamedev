@tool
extends Node3D
## Joue une fois toutes les particules GPUParticles3D enfants dès son arrivée dans la scène, puis
## se supprime au bout de `duration` secondes (effets ponctuels : explosion, éclat).
## Dans l'éditeur, le bouton « Play Particles » rejoue l'effet.


## Durée de vie de l'effet (s) ; 0 ou moins : l'effet reste dans la scène.
@export var duration : float = 5.0

## Bouton d'éditeur : rejoue les particules.
@export_tool_button("Play Particles")
var play_button := func () -> void: _play()

func _play() -> void:
	for child in get_children():
		if child is GPUParticles3D:
			child.restart()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_play()
			
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
		queue_free()
