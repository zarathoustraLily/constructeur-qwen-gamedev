class_name OptionsInput extends Node
## Les entrées de l'écran des options (seul fichier de l'écran qui lit le clavier et la manette, règle ARC-04) :
## gauche et droite (flèches, croix, stick) demandent la valeur précédente ou suivante de la ligne mise en avant ;
## revenir (B, Échap) demande le retour. Il les prend dans `_input`, avant l'interface : sinon, Godot s'en servirait
## pour déplacer le focus de côté.

## Le joueur demande la valeur précédente.
signal previous_requested
## Le joueur demande la valeur suivante.
signal next_requested
## Le joueur demande à revenir.
signal back_requested


func _ready() -> void:
	process_priority = ProcessOrder.INPUT


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_left"):
		previous_requested.emit()
	elif event.is_action_pressed(&"ui_right"):
		next_requested.emit()
	elif event.is_action_pressed(&"ui_cancel"):
		back_requested.emit()
	else:
		return
	get_viewport().set_input_as_handled()
