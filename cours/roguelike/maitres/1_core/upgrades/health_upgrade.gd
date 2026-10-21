class_name HealthUpgrade extends Upgrade
## L'amélioration de la santé : elle augmente la santé maximale du composant de santé de la cible (son enfant
## HealthComponent), et la santé actuelle d'autant.


## La santé maximale actuelle de `target`.
func current_value(target: Node) -> float:
	return (target.get_node(^"HealthComponent") as HealthComponent).max_health


## Augmente la santé maximale de `target`, et sa santé actuelle d'autant.
func apply(target: Node) -> void:
	(target.get_node(^"HealthComponent") as HealthComponent).raise_max_health(bonus)
