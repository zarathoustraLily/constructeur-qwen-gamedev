extends Node
## BPC_SalleBase.gd
## Le corps de base d'une salle (cycle de vie, spawn, issues).

@export var fiche: FicheSalle
@export var heros: Node
@export var niveau: int = 1

# Scènes à instancier
@export var scene_ennemi: PackedScene
@export var scene_boss: PackedScene
@export var scene_miniboss: PackedScene

# Données de spawn
@export var spawn_pools: Array = []
@export var encounter_profile: Dictionary = {}

enum EtatSalle {
	ATTENTE,
	COMBAT,
	COMBAT_FINI,
	VERROUILLEE,
}

var etat: int = EtatSalle.ATTENTE
var delai_apparition: float = 0.5
var delai_deverrouillage: float = 0.4
var delai_fin_combat: float = 0.2
var temps_ecoulé: float = 0.0

# Ennemis actifs
var ennemis_actifs: Array[Node] = []

# Points de spawn (positions dans la salle)
var points_spawn: Array[Vector3] = [
	Vector3(3, 0, 3), Vector3(-3, 0, 3),
	Vector3(3, 0, -3), Vector3(-3, 0, -3),
	Vector3(0, 0, 4), Vector3(0, 0, -4),
	Vector3(4, 0, 0), Vector3(-4, 0, 0),
]

# Nombre d'ennemis à spawner
var nombre_ennemis: int = 3

# Boss / mini-boss
var boss_active: Node = null


func _ready() -> void:
	if fiche:
		delai_apparition = fiche.delai_apparition
		delai_deverrouillage = fiche.delai_deverrouillage
		delai_fin_combat = fiche.delai_fin_combat
	# Calculer le nombre d'ennemis
	_calculer_nombre_ennemis()


func _process(delta: float) -> void:
	match etat:
		EtatSalle.ATTENTE:
			temps_ecoulé += delta
			if temps_ecoulé >= delai_apparition:
				etat = EtatSalle.COMBAT
				temps_ecoulé = 0.0
				_spawner_ennemis()
		EtatSalle.COMBAT:
			# Vérifier si le combat est fini
			if _combat_fini():
				etat = EtatSalle.COMBAT_FINI
				temps_ecoulé = 0.0
		EtatSalle.COMBAT_FINI:
			temps_ecoulé += delta
			if temps_ecoulé >= delai_fin_combat:
				etat = EtatSalle.VERROUILLEE


## Calculer le nombre d'ennemis à spawner.
func _calculer_nombre_ennemis() -> void:
	if encounter_profile.is_empty():
		nombre_ennemis = 3
		return
	var base: float = encounter_profile.get("ActiveEnemyCapBase", 2.3)
	var ramp: float = encounter_profile.get("ActiveEnemyCapDepthRamp", 0.35)
	var cap_max: int = encounter_profile.get("ActiveEnemyCapMax", 8)
	nombre_ennemis = int(base + float(niveau - 1) * ramp)
	nombre_ennemis = mini(nombre_ennemis, cap_max)
	nombre_ennemis = maxi(nombre_ennemis, 1)


## Spawner les ennemis.
func _spawner_ennemis() -> void:
	if spawn_pools.is_empty():
		return
	for i in range(nombre_ennemis):
		var entry: Dictionary = _choisir_ennemi()
		var ref: String = entry.get("Ref", "")
		var est_elite: bool = entry.get("Elite", false)

		# Charger la fiche
		var path: String = "res://donnees/%s.tres" % ref
		if not ResourceLoader.exists(path):
			continue
		var fiche_ennemi: Resource = load(path)

		# Instancier la scène
		if not scene_ennemi:
			continue
		var ennemi: CharacterBody3D = scene_ennemi.instantiate()
		ennemi.fiche = fiche_ennemi
		ennemi.heros = heros

		# Position aléatoire dans les points de spawn
		var index: int = i % points_spawn.size()
		ennemi.global_position = points_spawn[index]

		get_parent().add_child(ennemi)
		ennemis_actifs.append(ennemi)


## Choisir un ennemi aléatoire (pondéré).
func _choisir_ennemi() -> Dictionary:
	var poids_total: int = 0
	for entry in spawn_pools:
		poids_total += int(entry.get("Weight", 1))
	var r: int = randi() % poids_total
	var cumul: int = 0
	for entry in spawn_pools:
		cumul += int(entry.get("Weight", 1))
		if r < cumul:
			return entry
	return spawn_pools[0]


## Vérifier si le combat est fini.
func _combat_fini() -> bool:
	# Retirer les ennemis morts
	ennemis_actifs = ennemis_actifs.filter(func(e): return not e.est_mort())
	return ennemis_actifs.is_empty()


## Réinitialiser la salle.
func reset() -> void:
	etat = EtatSalle.ATTENTE
	temps_ecoulé = 0.0
	ennemis_actifs.clear()
