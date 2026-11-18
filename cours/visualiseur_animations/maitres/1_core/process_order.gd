class_name ProcessOrder extends RefCounted
## L'ordre d'exécution du visualiseur, nommé : chaque nœud qui en dépend prend sa priorité ici (process_priority),
## jamais un nombre écrit sur place. Les plus petits passent d'abord : on lit les entrées (souris, clavier, manette),
## puis la lecture des animations avance, puis la caméra suit, et l'interface relit l'état en dernier pour l'afficher.

## Les entrées : souris, clavier, manette.
const INPUT: int = -20
## La lecture : l'animation en cours avance.
const PLAYBACK: int = -10
## La caméra : elle tourne autour du sujet.
const CAMERA: int = 0
## L'interface : elle affiche ce qui vient de changer.
const VIEWS: int = 10


## Les priorités, de la première à la dernière.
static func sequence() -> Array[int]:
	return [INPUT, PLAYBACK, CAMERA, VIEWS]
