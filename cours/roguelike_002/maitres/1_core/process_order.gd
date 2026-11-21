class_name ProcessOrder extends RefCounted
## L'ordre d'exécution du jeu, nommé : chaque nœud qui en dépend prend sa priorité ici (process_priority), jamais un
## nombre écrit sur place. Les plus petites passent d'abord : on lit les entrées (clavier, manette), puis le déroulé
## décide (écran suivant, chargement, choix du menu), et les vues relisent l'état en dernier pour l'afficher.

## Les entrées : clavier et manette.
const INPUT: int = -20
## Le déroulé : les écrans, leurs chargements et leurs choix.
const FLOW: int = -10
## Les vues : elles montrent ce qui vient de changer.
const VIEWS: int = 10


## Les priorités, de la première à la dernière.
static func sequence() -> Array[int]:
	return [INPUT, FLOW, VIEWS]
