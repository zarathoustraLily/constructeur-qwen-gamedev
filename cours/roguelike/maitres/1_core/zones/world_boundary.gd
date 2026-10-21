class_name WorldBoundary extends Area3D
## Limite du monde, sous le niveau : sa forme est un plan sans bord (WorldBoundaryShape3D), et tout ce qui
#@ 4-5
## tombe sous lui est dedans. Elle signale chaque corps tombé (body_fell) ; le niveau décide quoi en faire.
#@ 6+
## tombe sous lui est dedans. Un personnage qui y tombe (il a un HealthComponent) perd toute sa santé, donc il
## est vaincu, et disparaît. Elle signale aussi chaque corps tombé (body_fell).
#@ all

## Émis quand un corps passe sous la limite du monde.
signal body_fell(body: Node3D)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
#@ 6+
	var health := body.get_node_or_null(^"HealthComponent") as HealthComponent
	if health != null:
		# Caché d'abord : qui écoute la défaite peut le faire réapparaître aussitôt.
		body.visible = false
		health.take_damage(health.max_health)
#@ all
	body_fell.emit(body)
