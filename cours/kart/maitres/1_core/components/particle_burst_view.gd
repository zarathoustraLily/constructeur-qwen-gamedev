@tool
class_name ParticleBurstView extends Node3D
## Effet ponctuel (une explosion, un éclat) : il joue une fois toutes ses particules GPUParticles3D enfants dès
## son arrivée dans la scène, puis se supprime au bout de `duration` secondes ; le minuteur s'arrête en pause
## (règle SIM-08). Dans l'éditeur, le bouton « Play Particles » rejoue l'effet.

## Durée de vie de l'effet (s) ; 0 ou moins : l'effet reste dans la scène.
@export var duration: float = 5.0

## Bouton d'éditeur : rejoue les particules.
@export_tool_button("Play Particles")
var play_button: Callable = func() -> void: play()


## Relance toutes les particules enfants.
func play() -> void:
	for child: Node in get_children():
		var particles := child as GPUParticles3D
		if particles != null:
			particles.restart()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	play()
	if duration > 0.0:
		await get_tree().create_timer(duration, false).timeout
		queue_free()
