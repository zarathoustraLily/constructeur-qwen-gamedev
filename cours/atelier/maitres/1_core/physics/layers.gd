class_name Layers extends RefCounted
## Les couches de collision du jeu, nommées comme dans project.godot ([layer_names]) : un corps est sur une couche
## (collision_layer) et regarde des couches (collision_mask). Les numéros des couches vont de 1 à 32 ; le masque
## est un entier où la couche n donne le bit n - 1.

## Le décor : sol, murs, obstacles.
const WORLD: int = 1
## Le joueur.
const PLAYER: int = 2
## Les ennemis et les cibles.
const ENEMY: int = 3
## Les zones de coup (attaques).
const HITBOX: int = 4


## Le bit de la couche numéro `layer` (de 1 à 32).
static func bit(layer: int) -> int:
	return 1 << (layer - 1)


## Le masque qui regarde toutes les couches de `layers`.
static func mask(layers: Array[int]) -> int:
	var value: int = 0
	for layer: int in layers:
		value |= bit(layer)
	return value


## Vrai si le masque `value` regarde la couche numéro `layer`.
static func has(value: int, layer: int) -> bool:
	return value & bit(layer) != 0
