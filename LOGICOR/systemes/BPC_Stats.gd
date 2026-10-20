class_name BPC_Stats
extends RefCounted
## BPC_Stats.gd
## Le système de stats : PV, souffle, i-frames, dernier effort, combo.

signal mort(cible: Node)
signal frappe_appliquee(cible: Node, degats: int, source: Node, est_crit: bool)

var fiche: FicheHeros
var vie: int = 30
var souffle: int = 50
var combo: int = 0
var en_invuln: bool = false
var temps_invuln: float = 0.0
var temps_dernier_effort: float = 0.0
var modif_degrats_subis: float = 1.0
var mode_facile: bool = false


func _init(fiche_heros: FicheHeros = null) -> void:
	fiche = fiche_heros
	if fiche:
		vie = fiche.vie_max
		souffle = fiche.souffle_max


## Appliquer des dégâts à cette cible. Renvoie les dégâts réellement infligés.
func appliquer_degrats(montant: int, source: Node = null, est_crit: bool = false) -> int:
	if en_invuln:
		return 0
	var final: int = montant
	# Modificateur de base.
	final = int(round(float(final) * modif_degrats_subis))
	# Crit.
	if est_crit:
		final = int(round(float(final) * 3.0))
	# Mode facile.
	if mode_facile:
		final = int(round(float(final) * _multipl_mode_facile()))
	# Dernier effort (réduction).
	if temps_dernier_effort > 0.0 and fiche:
		final = int(round(float(final) * fiche.dernier_effort_modif))
	vie -= final
	combo = 0  # Un coup encaissé casse le combo.
	_check_invuln()
	_check_dernier_effort()
	if vie <= 0:
		vie = 0
		mort.emit(self)
		return final
	frappe_appliquee.emit(self, final, source, est_crit)
	return final


## Soigner (fractions de PV). Renvoie les PV réellement gagnés.
func soigner(montant: int) -> int:
	if vie >= (fiche.vie_max if fiche else vie):
		return 0
	var gagnés: int = mini(montant, (fiche.vie_max if fiche else vie) - vie)
	vie += gagnés
	return gagnés


## Consommer du souffle. Renvoie le souffle réellement consommé.
func consommer_souffle(montant: int) -> int:
	if souffle < montant:
		return 0
	souffle -= montant
	return montant


## Gagner du souffle.
func gagner_souffle(montant: int) -> int:
	var max_s: int = fiche.souffle_max if fiche else souffle
	var gagnés: int = mini(montant, max_s - souffle)
	souffle += gagnés
	return gagnés


## Ajouter au combo.
func ajouter_combo(montant: int = 1) -> void:
	combo += montant
	if fiche and combo >= fiche.seuil_combo:
		combo = 0


## Tick de temps (pour les i-frames et le dernier effort).
func tick(delta: float) -> void:
	if en_invuln:
		temps_invuln -= delta
		if temps_invuln <= 0.0:
			en_invuln = false
			temps_invuln = 0.0
	if temps_dernier_effort > 0.0:
		temps_dernier_effort -= delta
		if temps_dernier_effort <= 0.0:
			temps_dernier_effort = 0.0


## Vérifier les i-frames : si PV sous seuil ET dégâts min, activer.
func _check_invuln() -> void:
	if not fiche:
		return
	if en_invuln:
		return
	var seuil: float = maxf(float(fiche.vie_max) * fiche.seuil_invuln, float(fiche.degat_min_invuln))
	if vie <= int(seuil):
		en_invuln = true
		temps_invuln = fiche.duree_invuln


## Vérifier le dernier effort : si PV très bas, activer.
func _check_dernier_effort() -> void:
	if not fiche:
		return
	if temps_dernier_effort > 0.0:
		return
	var seuil: float = float(fiche.vie_max) * 0.1
	if vie <= int(seuil):
		temps_dernier_effort = fiche.dernier_effort_duree
		soigner(int(float(fiche.vie_max) * fiche.dernier_effort_soin))


func _multipl_mode_facile() -> float:
	if not fiche:
		return 1.0
	return fiche.mode_facile_base
