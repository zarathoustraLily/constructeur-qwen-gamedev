class_name BPC_DernierEffort
extends RefCounted
## BPC_DernierEffort.gd
## Le système de "dernier effort" (LastStand).

var actif: bool = false
var temps_restant: float = 0.0
var duree: float = 5.0
var soin_fraction: float = 0.4
var modif_degrats: float = 0.3
var seuil_fraction: float = 0.1


func _init(fiche: FicheHeros = null) -> void:
	if fiche:
		duree = fiche.dernier_effort_duree
		soin_fraction = fiche.dernier_effort_soin
		modif_degrats = fiche.dernier_effort_modif


## Vérifier si le dernier effort doit s'activer.
func verifier(pv: int, pv_max: int) -> int:
	if actif:
		return 0
	var seuil: float = float(pv_max) * seuil_fraction
	if pv <= int(seuil):
		activer()
		var soin: int = int(float(pv_max) * soin_fraction)
		return soin
	return 0


## Activer le dernier effort.
func activer() -> void:
	actif = true
	temps_restant = duree


## Tick de temps.
func tick(delta: float) -> void:
	if not actif:
		return
	temps_restant -= delta
	if temps_restant <= 0.0:
		actif = false
		temps_restant = 0.0


## Est-ce que le dernier effort est actif ?
func est_actif() -> bool:
	return actif


## Le multiplicateur de dégâts subi quand le dernier effort est actif.
func get_modif_degrats() -> float:
	if actif:
		return modif_degrats
	return 1.0
