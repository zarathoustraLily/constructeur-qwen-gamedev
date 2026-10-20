extends CharacterBody3D
## BPC_HerosBase.gd
## Le corps de base du héros (CharacterBody3D).
## Mouvement, attaque, dash, stats.

@export var fiche: FicheHeros
var stats: BPC_Stats

# Références
@export var camera: Camera3D
@export var attack_hitbox: Area3D

# Vitesse de base
var vitesse: float = 300.0

# Attaque
var en_attaque: bool = false
var temps_attaque: float = 0.0
var duree_attaque: float = 0.3
var cooldown_attaque: float = 0.5
var temps_cooldown: float = 0.0

# Dash
var en_dash: bool = false
var temps_dash: float = 0.0
var duree_dash: float = 0.4
var vitesse_dash: float = 800.0
var cooldown_dash: float = 1.0
var temps_cooldown_dash: float = 0.0


func _ready() -> void:
	if not stats:
		stats = BPC_Stats.new(fiche)
		if fiche:
			stats.vie = fiche.vie_max
			stats.souffle = fiche.souffle_max
			vitesse = fiche.vitesse if fiche.vitesse > 0 else 300.0
			duree_dash = fiche.dash_duree


func _physics_process(delta: float) -> void:
	# Tick des i-frames et du dernier effort.
	if stats:
		stats.tick(delta)

	# Cooldowns
	if temps_cooldown > 0.0:
		temps_cooldown -= delta
	if temps_cooldown_dash > 0.0:
		temps_cooldown_dash -= delta

	# Mouvement
	var direction: Vector3 = Vector3.ZERO
	if Input.is_action_pressed("move_right"):
		direction.x += 1.0
	if Input.is_action_pressed("move_left"):
		direction.x -= 1.0
	if Input.is_action_pressed("move_up"):
		direction.z -= 1.0
	if Input.is_action_pressed("move_down"):
		direction.z += 1.0

	if direction != Vector3.ZERO:
		direction = direction.normalized()

	# Dash
	if Input.is_action_just_pressed("dash") and not en_dash and temps_cooldown_dash <= 0.0:
		en_dash = true
		temps_dash = duree_dash
		temps_cooldown_dash = cooldown_dash

	# Appliquer la vitesse
	if en_dash:
		temps_dash -= delta
		velocity = direction * vitesse_dash
		if temps_dash <= 0.0:
			en_dash = false
	else:
		velocity = direction * vitesse

	move_and_slide()

	# Attaque
	if Input.is_action_just_pressed("attack") and not en_attaque and temps_cooldown <= 0.0:
		en_attaque = true
		temps_attaque = 0.0
		temps_cooldown = cooldown_attaque

	if en_attaque:
		temps_attaque += delta
		# Au milieu de l'animation d'attaque, appliquer les dégâts
		if temps_attaque >= duree_attaque * 0.4 and temps_attaque < duree_attaque * 0.4 + delta:
			_attaquer()
		if temps_attaque >= duree_attaque:
			en_attaque = false


## Attaquer : appliquer les dégâts à tous les ennemis dans le hitbox.
func _attaquer() -> void:
	if not attack_hitbox:
		return
	var degat: int = 10
	if fiche:
		degat = fiche.degat_attaque if fiche.degat_attaque > 0 else 10
	for corps in attack_hitbox.get_overlapping_bodies():
		if corps.has_method("prendre_degrats"):
			corps.prendre_degrats(degat, self, false)


## Prendre des dégâts.
func prendre_degrats(montant: int, source: Node = null, est_crit: bool = false) -> int:
	var degats: int = stats.appliquer_degrats(montant, source, est_crit)
	return degats


## Soigner.
func soigner(montant: int) -> int:
	return stats.soigner(montant)


## Est mort ?
func est_mort() -> bool:
	return stats.vie <= 0
