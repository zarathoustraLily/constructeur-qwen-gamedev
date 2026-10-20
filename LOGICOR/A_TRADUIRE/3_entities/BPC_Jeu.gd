extends Node
## BPC_Jeu.gd
## La scène principale : orchestre le jeu.

@export var heros_scene: PackedScene
@export var salle_scene: PackedScene
@export var hud_scene: PackedScene
@export var camera_scene: PackedScene

# Données
@export var fiche_heros: FicheHeros
@export var spawn_pools: Array = []
@export var encounter_profile: Dictionary = {}
@export var niveau: int = 1

# Références
var heros: Node = null
var salle: Node = null
var hud: CanvasLayer = null
var camera: Camera3D = null


func _ready() -> void:
	# Créer la salle
	if salle_scene:
		salle = salle_scene.instantiate()
		add_child(salle)

	# Créer le héros
	if heros_scene:
		heros = heros_scene.instantiate()
		heros.fiche = fiche_heros
		add_child(heros)

	# Configurer la salle
	if salle:
		salle.heros = heros
		salle.niveau = niveau
		salle.spawn_pools = spawn_pools
		salle.encounter_profile = encounter_profile
		# Charger la fiche de salle depuis les données
		var path_fiche: String = "res://donnees/SLA-%02d.tres" % niveau
		if ResourceLoader.exists(path_fiche):
			salle.fiche = load(path_fiche)

	# Créer la caméra
	if camera_scene:
		camera = camera_scene.instantiate()
		camera.heros = heros
		add_child(camera)

	# Créer le HUD
	if hud_scene:
		hud = hud_scene.instantiate()
		hud.heros = heros
		add_child(hud)
