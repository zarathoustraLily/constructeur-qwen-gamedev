class_name Golem extends CharacterBody3D
## Le Gardien du Comptoir : un golem de pierre en armure, quatre fois la taille d'un homme, qui garde le comptoir du
## saloon d'un géant. À cette étape, il tient sa place (son modèle joue l'attente) ; il a son corps (couche du boss),
## sa santé, la zone qui reçoit les tirs du héros et le point que la caméra verrouille, à hauteur de poitrine. Sa
## machine à états (réveil, approche, attaques) vient ensuite.

## La santé du golem.
@onready var health: HealthComponent = $Health
## Le point que la caméra verrouille.
@onready var lock_point: Node3D = $LockPoint


func _ready() -> void:
	collision_layer = Layers.bit(Layers.BOSS)
	collision_mask = Layers.mask([Layers.WORLD, Layers.HERO])
