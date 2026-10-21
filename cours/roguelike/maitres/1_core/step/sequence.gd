class_name Sequence extends Resource
## Le déroulé du jeu (2_sequence/sequence.tres) : les niveaux, à jouer dans un ordre tiré au hasard (avec une
## graine) ou dans l'ordre de la liste, et l'intermède joué entre deux niveaux. Changer le déroulé, c'est changer
## ce fichier.

## Les scènes des niveaux.
@export var steps: Array[PackedScene] = []
## Tirer l'ordre des niveaux au démarrage.
@export var shuffle: bool = false
## Graine du tirage de l'ordre : une même graine, un même ordre.
@export var random_seed: int = 0
#@ 13+
## L'intermède joué après chaque niveau, avant le suivant (la boutique) ; vide : pas d'intermède.
@export var interlude: PackedScene
#@ all
