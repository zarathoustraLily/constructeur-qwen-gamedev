extends Area3D
## BPC_Projet.gd
## Un projet (tile de dégâts sur le sol).
## Apparaît, dure, puis disparaît.

@export var degats: int = 10
@export var duree: float = 2.0
@export var rayon: float = 100.0

var temps: float = 0.0
var actif: bool = false


func _ready() -> void:
	# Désactiver au départ
	set_process(false)


func activer() -> void:
	actif = true
	temps = 0.0
	set_process(true)


func _process(delta: float) -> void:
	temps += delta
	if temps >= duree:
		deacter()
		return
	# Appliquer les dégâts aux héros dans la zone
	for corps in get_overlapping_bodies():
		if corps.has_method("prendre_degrats"):
			# Un dégât par seconde
			if floor(temps) != floor(temps - delta):
				corps.prendre_degrats(degats, self, false)


func deacter() -> void:
	actif = false
	set_process(false)
	queue_free()
