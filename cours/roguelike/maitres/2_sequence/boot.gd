extends Node
## Scène de démarrage : elle donne au chef d'orchestre (GameFlow) la séquence du jeu, posée dans boot.tscn. Elle
## ne charge aucune scène elle-même : GameFlow charge la première étape, puis toutes les suivantes.
#@ 14+
## Avant, elle remet les liaisons des commandes sauvegardées par le menu des contrôles.
#@ all

## La séquence du jeu (2_sequence/sequence.tres).
@export var sequence: Sequence
#@ 14+
## Les actions qu'on peut lier et le fichier de leurs liaisons sauvegardées (5_data/input/bindings.tres).
@export var bindings: BindingSettings
#@ all


func _ready() -> void:
	if sequence == null:
		push_error("Boot : la séquence (sequence) n'est pas posée dans boot.tscn")
		return
#@ 14+
	apply_saved_bindings()
#@ all
	# La scène de démarrage est encore en train d'entrer dans l'arbre : le chargement attend la fin de l'image.
	GameFlow.start.call_deferred(sequence)
#@ 14+


## Remet les liaisons sauvegardées par le menu des contrôles, s'il y en a : le jeu démarre avec les touches et les
## boutons choisis.
func apply_saved_bindings() -> void:
	if bindings == null:
		push_error("Boot : les réglages des liaisons (bindings) ne sont pas posés dans boot.tscn")
		return
	InputBindings.load_from(bindings.save_path, bindings.actions())
#@ all
