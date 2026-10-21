extends Node
## Ce qui dure d'un niveau à l'autre (singleton GameState) : le rang du niveau en cours, à partir de 1, qui fixe la
## taille de la vague. Un niveau fini le fait monter ; une défaite le ramène à 1.

## Rang du niveau en cours, à partir de 1.
var level: int = 1


## Un niveau de plus est fini : le suivant aura une vague plus nombreuse.
func finish_level() -> void:
	level += 1


## Retour au premier rang (le joueur a été vaincu).
func reset() -> void:
	level = 1
