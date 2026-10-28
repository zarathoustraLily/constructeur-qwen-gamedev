class_name Layers extends RefCounted
## Les couches de collision du jeu, nommées comme dans project.godot ([layer_names]) : un corps est sur une couche
## (collision_layer) et regarde des couches (collision_mask). Le masque est un entier où la couche n donne le bit n - 1.

## Le décor.
const WORLD: int = 1
## Le héros.
const HERO: int = 2
## Le boss.
const BOSS: int = 3
## Les projectiles du héros.
const PROJECTILES: int = 4
## Les zones de coup du boss.
const BOSS_HITS: int = 5
#@ 5+
## Les zones qui reçoivent les tirs du héros (Hurtbox) : corps du boss, points faibles, bouclier, cibles.
const TARGETS: int = 6
#@ all


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
