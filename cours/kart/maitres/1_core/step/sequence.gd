class_name Sequence extends Resource
## La liste ordonnée des étapes du jeu (2_sequence/sequence.tres). Changer l'ordre du jeu, c'est changer ce
## fichier. La pause et les menus ouverts par-dessus le jeu ne sont pas des étapes : ils ne font pas avancer le
## déroulé (4_ui/overlays/).

## Les scènes des étapes, dans l'ordre du déroulé.
@export var steps: Array[PackedScene] = []
