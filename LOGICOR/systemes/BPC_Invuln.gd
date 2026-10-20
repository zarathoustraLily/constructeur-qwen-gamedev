class_name BPC_Invuln
extends RefCounted
## BPC_Invuln.gd
## Le système d'i-frames.

var en_invuln: bool = false
var temps_restant: float = 0.0
var duree: float = 1.3
var seuil_fraction: float = 0.25
var seuil_min: int = 15


func _init(fiche: FicheHeros = null) -> void:
	if fiche:
		duree = fiche.duree_invuln
		seuil_fraction = fiche.seuil_invuln
		seuil_min = fiche.degat_min_invuln


## Vérifier si l'invulnérabilité doit s'activer.
func verifier(pv: int, pv_max: int) -> void:
	if en_invuln:
		return
	var seuil: float = maxf(float(pv_max) * seuil_fraction, float(seuil_min))
	if pv <= int(seuil):
		activer()


## Activer les i-frames.
func activer() -> void:
	en_invuln = true
	temps_restant = duree


## Tick de temps.
func tick(delta: float) -> void:
	if not en_invuln:
		return
	temps_restant -= delta
	if temps_restant <= 0.0:
		en_invuln = false
		temps_restant = 0.0


## Est-ce que la cible est invulnérable ?
func est_invuln() -> bool:
	return en_invuln
