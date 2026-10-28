class_name InputBuffer extends Node
## La mémoire d'un appui : un bouton pressé un peu trop tôt (pendant une roulade, par exemple) reste valable `window`
## secondes ; l'action part dès que possible, et l'appui est alors consommé. Sans elle, le jeu « mange » les appuis
## faits juste avant la fin d'une action et paraît lent à répondre.

## Combien de temps un appui reste valable, en secondes ; son propriétaire le pose depuis ses réglages.
var window: float = 0.0

var _left: float = 0.0


func _ready() -> void:
	process_physics_priority = ProcessOrder.COMPONENTS


func _physics_process(delta: float) -> void:
	tick(delta)


## Note un appui : il vaut pour les `window` secondes qui viennent.
func press() -> void:
	_left = window


## Vrai, une seule fois, si un appui est encore valable : il est alors consommé.
func consume() -> bool:
	if _left <= 0.0:
		return false
	_left = 0.0
	return true


## Vrai tant qu'un appui attend.
func is_pending() -> bool:
	return _left > 0.0


## Fait passer `delta` secondes : un appui trop ancien est oublié.
func tick(delta: float) -> void:
	_left = maxf(_left - delta, 0.0)
