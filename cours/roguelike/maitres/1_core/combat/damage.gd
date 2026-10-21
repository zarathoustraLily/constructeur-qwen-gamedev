class_name Damage
## Le calcul des dégâts, sans scène (règle SIM-10) : une fonction pure, testable seule.

## Pourcentage qui laisse les dégâts tels quels.
const FULL_PERCENT := 100.0


## Dégâts d'un coup de `base` points, avec une statistique de dégâts de `percent` % (100 : les dégâts de base ;
## 150 : une fois et demie).
static func scaled(base: float, percent: float) -> float:
	return base * percent / FULL_PERCENT
