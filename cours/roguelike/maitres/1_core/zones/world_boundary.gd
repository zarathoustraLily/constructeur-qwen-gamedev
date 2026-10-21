class_name WorldBoundary extends Area3D
## Limite du monde, sous le niveau : sa forme est un plan sans bord (WorldBoundaryShape3D), et tout ce qui
## tombe sous lui est dedans. Elle signale chaque corps tombé (body_fell) ; le niveau décide quoi en faire.

## Émis quand un corps passe sous la limite du monde.
signal body_fell(body: Node3D)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	body_fell.emit(body)
