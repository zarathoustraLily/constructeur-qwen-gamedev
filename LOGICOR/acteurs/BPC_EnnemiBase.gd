extends CharacterBody3D
## BPC_EnnemiBase.gd
## Le corps de base d'un ennemi (CharacterBody3D).
## IA simple : suivi du héros, attaque en portée, mort.

@export var fiche: FicheEnnemi
var stats: BPC_Stats
var mort: bool = false

# Référence au héros (set par la salle)
var heros: Node = null

# IA
var portee_aggro: float = 600.0
var portee_attaque: float = 100.0
var duree_attaque: float = 1.0
var temps_attaque: float = 0.0
var en_attaque: bool = false
var cooldown_attaque: float = 1.5
var temps_cooldown: float = 0.0

# Aggro
var aggro: bool = false


func _ready() -> void:
	if not stats:
		stats = BPC_Stats.new()
		if fiche:
			stats.vie = fiche.PV_Max
			portee_aggro = fiche.IA_PorteeAggro if fiche.IA_PorteeAggro > 0 else 600.0


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

	# Attaque
	if en_attaque:
		temps_attaque += delta
		if temps_attaque >= duree_attaque:
			en_attaque = false
			temps_cooldown = cooldown_attaque
		return

	if dist <= portee_attaque and temps_cooldown <= 0.0:
		# Attaquer
		en_attaque = true
		temps_attaque = 0.0
		_attaquer()
		return

	# Suivre le héros
	var direction: Vector3 = (heros.global_position - global_position).normalized()
	velocity = direction * (fiche.Vitesse if fiche and fiche.Vitesse > 0 else 150.0)
	move_and_slide()


## Attaquer le héros.
func _attaquer() -> void:
	if not heros or not is_instance_valid(heros):
		return
	var degat: int = 5
	if heros.has_method("prendre_degrats"):
		heros.prendre_degrats(degat, self, false)


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
	# Ici : effets de mort, drops, notification à la salle
	queue_free()


## Vérifier si l'ennemi est mort.
func est_mort() -> bool:
	return mort
