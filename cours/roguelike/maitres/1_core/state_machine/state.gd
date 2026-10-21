class_name State extends Node
## Un état d'une machine à états (StateMachine) : un nœud enfant de la machine, avec son propre script. On en
## hérite et on redéfinit les fonctions utiles. Pour changer d'état, il émet finished avec le nom du nœud de
## l'état suivant. Il ne lit jamais les touches : son acteur lui donne des commandes (règle ARC-04).

## Émis quand l'état est fini : la machine passe à l'état `next_state` (le nom d'un nœud frère). Ce sont les
## états dérivés qui l'émettent : l'avertissement « signal jamais employé dans la classe » ne vaut pas ici.
@warning_ignore("unused_signal")
signal finished(next_state: StringName)


## Appelée par la machine à chaque image physique, tant que l'état est actif.
func physics_update(_delta: float) -> void:
	pass


## Appelée par la machine quand l'état devient actif ; `_previous_state` : le nom de l'état quitté (vide au
## départ).
func enter(_previous_state: StringName) -> void:
	pass


## Appelée par la machine juste avant de quitter l'état, pour faire le ménage.
func exit() -> void:
	pass
