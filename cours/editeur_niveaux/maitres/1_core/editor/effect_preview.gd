class_name EffectPreview
extends RefCounted
## L'aperçu d'un effet placé, calculé sans hasard : à l'instant `time`, chaque particule a un âge (de 0 à 1 de sa vie),
## une direction (l'angle d'or, qui répartit les directions sans motif visible) et s'éloigne du centre en grandissant
## et en s'effaçant. Le même instant donne toujours la même image : l'aperçu se teste et se capture. Ce n'est pas la
## simulation du jeu, seulement une idée de son débit, de sa durée, de sa taille et de sa couleur.

## Le nombre maximal de particules d'un aperçu.
const MAX_PARTICLES: int = 64
## L'angle d'or, en radians : deux particules voisines ne partent jamais dans la même direction.
const GOLDEN_ANGLE: float = 2.399963
## La distance parcourue par une particule en fin de vie, en tailles de particule.
const TRAVEL: float = 3.0


## Le nombre de particules vivantes à la fois : débit × durée de vie, borné.
static func count(effect: FxDef) -> int:
	return clampi(roundi(effect.rate * effect.lifetime_s), 1, MAX_PARTICLES)


## Les particules de `effect` placé en `center` (mètres, plan x, z) à l'instant `time` (secondes) : pour chacune, sa
## position (mètres), son rayon (mètres) et son opacité.
static func particles(effect: FxDef, center: Vector2, time: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var total: int = count(effect)
	for index: int in total:
		var age: float = fposmod(time / effect.lifetime_s + float(index) / float(total), 1.0)
		var direction: Vector2 = Vector2.RIGHT.rotated(GOLDEN_ANGLE * index)
		result.append({
			&"position": center + direction * age * effect.size_m * TRAVEL,
			&"radius": effect.size_m * (0.5 + age),
			&"alpha": effect.color.a * (1.0 - age),
		})
	return result
