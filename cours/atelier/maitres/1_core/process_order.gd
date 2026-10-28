class_name ProcessOrder extends RefCounted
## L'ordre d'exécution du jeu, nommé : chaque nœud qui en dépend prend sa priorité ici (process_priority ou
## process_physics_priority), jamais un nombre écrit sur place. Les plus petits passent d'abord.

## Les entrées du joueur sont lues avant tout le reste.
const INPUT: int = -20
## Les composants (santé, minuteurs) se mettent à jour avant les entités qui les lisent.
const COMPONENTS: int = -10
## Les machines à états et la logique des entités.
const ENTITIES: int = 0
## La présentation (vues, effets) montre l'état déjà calculé.
const VIEWS: int = 10
## La caméra suit en dernier ce qui a bougé.
const CAMERA: int = 20
