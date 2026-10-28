class_name FlaskComponent extends Node
## Les fioles de soin : un nombre limité de charges, une par fiole bue. Ce qu'une fiole rend et le temps qu'il faut
## pour la boire sont l'affaire de qui la boit ; ici, on ne compte que les fioles.

## Il reste `charges` fioles sur `maximum` (pour l'interface).
signal changed(charges: int, maximum: int)

## Le nombre de fioles au plus.
var max_charges: int = 0
## Les fioles qui restent.
var charges: int = 0


## Remplit `count` fioles : le maximum et les charges.
func fill(count: int) -> void:
	max_charges = count
	charges = count
	changed.emit(charges, max_charges)


## Vrai s'il reste une fiole.
func has_charge() -> bool:
	return charges > 0


## Prend une fiole ; rend faux s'il n'en reste plus.
func use() -> bool:
	if charges <= 0:
		return false
	charges -= 1
	changed.emit(charges, max_charges)
	return true
