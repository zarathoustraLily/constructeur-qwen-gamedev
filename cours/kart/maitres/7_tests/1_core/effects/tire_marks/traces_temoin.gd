extends Node
## Gestionnaire de traces de pneus de test : il garde les traces demandées au lieu de les calculer.
## Il se range dans le groupe « tire_marks », où le joueur cherche le gestionnaire de la scène.

## Traces demandées, dans l'ordre : [position, rayon, force].
var traces: Array = []
## Dernier centre reçu par set_player_position().
var centre := Vector3.INF


func _init() -> void:
	add_to_group("tire_marks")


## Retient le centre demandé.
func set_player_position(pos: Vector3) -> void:
	centre = pos


## Retient la trace demandée.
func add_tire(position: Vector3, radius: float, strength: float) -> void:
	traces.append([position, radius, strength])
