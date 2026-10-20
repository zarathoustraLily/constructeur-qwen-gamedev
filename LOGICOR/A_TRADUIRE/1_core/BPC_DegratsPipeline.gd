class_name BPC_DegratsPipeline
extends RefCounted
## BPC_DegratsPipeline.gd
## Le pipeline de dégâts : base × modif + additif, crit ×3.

## Calculer les dégâts finaux.
static func calculer(
	base: int,
	mult: float = 1.0,
	additif: int = 0,
	est_crit: bool = false,
	mult_crit: float = 3.0
) -> int:
	var final: float = float(base) * mult + float(additif)
	if est_crit:
		final *= mult_crit
	return int(round(final))


## Vérifier si un coup est un crit.
static func est_critique(
	pv_cible: int,
	pv_max_cible: int,
	seuil: float = 0.25,
	min_pv: int = 15
) -> bool:
	if pv_max_cible <= 0:
		return false
	var seuil_abs: float = maxf(float(pv_max_cible) * seuil, float(min_pv))
	return pv_cible <= int(seuil_abs)
