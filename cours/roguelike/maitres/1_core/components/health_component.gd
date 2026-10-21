class_name HealthComponent extends Node
## Composant de santé d'un personnage, enfant direct de sa racine et nommé HealthComponent (les attaques le
## cherchent par ce nom). take_damage() retire des points de vie et prévient par signaux ; à 0 ou moins, le
## personnage est vaincu. Il ne joue aucun son et ne connaît aucun singleton : le personnage, ou sa vue, écoute
## ses signaux.

## Émis à chaque coup reçu, avec les dégâts, avant health_changed.
signal damage_taken(amount: float)
## Émis après chaque changement de santé, avec la santé restante.
signal health_changed(value: float)
## Émis quand la santé tombe à 0 ou moins.
signal defeated

## Santé de départ et santé maximale.
@export var max_health: float = 100.0

## Santé actuelle ; vaut max_health au départ.
var current_health: float


func _ready() -> void:
	current_health = max_health


## Retire `amount` points de vie ; émet damage_taken, puis health_changed, puis defeated à 0 ou moins.
func take_damage(amount: float) -> void:
	current_health -= amount
	damage_taken.emit(amount)
	health_changed.emit(current_health)
	if current_health <= 0.0:
		defeated.emit()


## Rend toute sa santé au personnage.
func restore() -> void:
	current_health = max_health
	health_changed.emit(current_health)
#@ 13+


## Augmente la santé maximale de `amount`, et la santé actuelle d'autant.
func raise_max_health(amount: float) -> void:
	max_health += amount
	current_health += amount
	health_changed.emit(current_health)
#@ all
