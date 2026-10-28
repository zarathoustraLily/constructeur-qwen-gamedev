class_name ProcessOrder extends RefCounted
## L'ordre d'exécution du jeu, nommé : chaque nœud qui en dépend prend sa priorité ici (process_priority ou
## process_physics_priority), jamais un nombre écrit sur place. Les plus petits passent d'abord : on lit les entrées,
## puis les composants mettent leurs minuteurs à jour, puis le héros et le boss décident, puis les projectiles volent,
## puis les vues montrent, et la caméra suit en dernier ce qui a bougé.

## Les entrées du joueur.
const INPUT: int = -30
## Les composants (santé, endurance, minuteurs).
const COMPONENTS: int = -20
## Le héros et le boss : leurs machines à états.
const ACTORS: int = -10
## Les projectiles et les zones de coup.
const PROJECTILES: int = 0
## Les vues (animations, effets) : elles montrent l'état déjà calculé.
const VIEWS: int = 10
## La caméra.
const CAMERA: int = 20


## Les priorités, de la première à la dernière.
static func sequence() -> Array[int]:
	return [INPUT, COMPONENTS, ACTORS, PROJECTILES, VIEWS, CAMERA]
