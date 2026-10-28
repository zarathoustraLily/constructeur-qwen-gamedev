class_name Volume extends RefCounted
## Conversions entre le volume d'un curseur (linéaire, de 0 à 1) et les décibels d'un bus audio. L'oreille
## entend en décibels : un curseur à moitié correspond à environ -6 dB, pas à la moitié du son.

## Le volume le plus bas, en dB : en dessous, un bus est considéré comme coupé.
const FLOOR_DB: float = -60.0


## Les décibels du volume `linear` (de 0 à 1) ; 0 ou moins donne FLOOR_DB, jamais moins.
static func to_db(linear: float) -> float:
	if linear <= 0.0:
		return FLOOR_DB
	return maxf(linear_to_db(linear), FLOOR_DB)


## Le volume linéaire (de 0 à 1) de `db` décibels ; FLOOR_DB ou moins donne 0.
static func to_linear(db: float) -> float:
	if db <= FLOOR_DB:
		return 0.0
	return clampf(db_to_linear(db), 0.0, 1.0)


## Le volume en pourcentage arrondi, pour un libellé : « 75 % ».
static func percent_text(linear: float) -> String:
	return "%d %%" % roundi(clampf(linear, 0.0, 1.0) * 100.0)


## Le volume `linear` déplacé de `delta`, arrondi au pas `step` et borné entre 0 et 1.
static func step_value(linear: float, delta: float, step: float) -> float:
	return clampf(snappedf(linear + delta, step), 0.0, 1.0)
