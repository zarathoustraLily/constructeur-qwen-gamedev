class_name ProcessOrder extends RefCounted
## L'ordre d'exécution de l'éditeur, nommé : chaque nœud qui en dépend prend sa priorité ici (process_priority), jamais
## un nombre écrit sur place. Les plus petits passent d'abord : on lit les entrées (souris, clavier), puis le document
## applique les actions demandées, puis les vues redessinent la salle, et le cadre de sélection se dessine en dernier,
## par-dessus ce qui vient de bouger.

## Les entrées : raccourcis, souris, glisser.
const INPUT: int = -20
## Le document : il applique les actions et met l'annulation à jour.
const DOCUMENT: int = -10
## Les vues : la salle, les collisions, les apparitions, les effets.
const VIEWS: int = 0
## Le cadre de sélection et ses poignées, par-dessus tout le reste.
const OVERLAY: int = 10


## Les priorités, de la première à la dernière.
static func sequence() -> Array[int]:
	return [INPUT, DOCUMENT, VIEWS, OVERLAY]
