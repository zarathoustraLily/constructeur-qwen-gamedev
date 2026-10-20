extends CharacterBody3D
## BPC_BossBase.gd
## Le corps de base d'un boss (CharacterBody3D).
## Gère les phases et les attaques.

@export var fiche: FicheBoss
var stats: BPC_Stats
var mort: bool = false

var heros: Node = null

# Phases
var phase_actuelle: int = 0
var phases: Array[Dictionary] = []

# Attaques de la phase actuelle
var attaques_phase: Array[Dictionary] = []
var attaque_actuelle: Dictionary = {}
var en_attaque: bool = false
var temps_attaque: float = 0.0
var cooldown_attaque: float = 1.0
var temps_cooldown: float = 0.0

# Aggro
var aggro: bool = false
var portee_aggro: float = 1000.0


func _ready() -> void:
	if not stats:
		stats = BPC_Stats.new()
		if fiche:
			stats.vie = fiche.PV_Max
			phases = fiche.phases
			portee_aggro = fiche.IA_PorteeAggro if fiche.IA_PorteeAggro > 0 else 1000.0

	# Préparer la phase 0
	if not phases.is_empty():
		_changer_phase(0)


func _physics_process(delta: float) -> void:
	if mort:
		return

	if not heros or not is_instance_valid(heros) or (heros.has_method("est_mort") and heros.est_mort()):
		return

	# Cooldown
	if temps_cooldown > 0.0:
		temps_cooldown -= delta

	# Aggro
	var dist: float = global_position.distance_to(heros.global_position)
	if not aggro and dist <= portee_aggro:
		aggro = true

	if not aggro:
		return

	# Vérifier les transitions de phase
	_verifier_phases()

	# Attaque
	if en_attaque:
		temps_attaque += delta
		var props: Dictionary = attaque_actuelle.get("props", {})
		var annonce: float = props.get("IA.AnnonceDuree", 1.0)
		var tir: float = props.get("IA.TirDuree", 0.0)
		var recuperation: float = props.get("IA.RecuperationDuree", 0.5)
		var duree_totale: float = annonce + tir + recuperation
		if temps_attaque >= annonce:
			_appliquer_degrats()
		if temps_attaque >= duree_totale:
			en_attaque = false
			temps_cooldown = cooldown_attaque
		return

	if temps_cooldown <= 0.0:
		choisir_attaque()


## Vérifier si on doit changer de phase.
func _verifier_phases() -> void:
	if phases.is_empty():
		return
	var fraction: float = float(stats.vie) / float(stats.vie_max) if stats.vie_max > 0 else 0.0
	for i in range(phases.size() - 1, -1, -1):
		var props: Dictionary = phases[i].get("props", {})
		var type_transition: String = props.get("TypeTransition", "SeuilPV")
		if type_transition == "SeuilPV":
			var seuil: float = props.get("Seuil", 1.0)
			if fraction <= seuil and i != phase_actuelle:
				_changer_phase(i)
				break


## Changer de phase.
func _changer_phase(index: int) -> void:
	if index >= phases.size():
		return
	phase_actuelle = index
	var phase: Dictionary = phases[index]
	# Lister les armes équipées
	var armes: Array = phase.get("props", {}).get("ArmesEquipees", [])
	# Filtrer les attaques de la fiche qui correspondent
	attaques_phase = []
	if fiche and fiche.attaques:
		for attaque in fiche.attaques:
			if armes.is_empty() or armes.has(attaque.get("id", "")):
				attaques_phase.append(attaque)
	# Si pas de filtre, prendre toutes les attaques
	if attaques_phase.is_empty() and fiche and fiche.attaques:
		attaques_phase = fiche.attaques


## Choisir une attaque aléatoire de la phase.
func choisir_attaque() -> void:
	if attaques_phase.is_empty():
		return
	var index: int = randi() % attaques_phase.size()
	attaque_actuelle = attaques_phase[index]
	en_attaque = true
	temps_attaque = 0.0
	_degats_appliques = false


## Appliquer les dégâts pendant la phase de tir.
var _degats_appliques: bool = false

func _appliquer_degrats() -> void:
	if _degats_appliques:
		return
	if not heros or not is_instance_valid(heros):
		return
	var props: Dictionary = attaque_actuelle.get("props", {})
	var degat: int = props.get("Degats", 10)
	var portee: float = props.get("IA.PorteeAttaque", 200.0)
	var dist: float = global_position.distance_to(heros.global_position)
	if dist <= portee and heros.has_method("prendre_degrats"):
		heros.prendre_degrats(degat, self, false)
	_degats_appliques = true


## Prendre des dégâts.
func prendre_degrats(montant: int, source: Node = null, est_crit: bool = false) -> int:
	if mort:
		return 0
	var degats: int = stats.appliquer_degrats(montant, source, est_crit)
	if stats.vie <= 0:
		mourir()
	return degats


## Mourir.
func mourir() -> void:
	if mort:
		return
	mort = true
	set_physics_process(false)
	queue_free()


## Vérifier si le boss est mort.
func est_mort() -> bool:
	return mort
