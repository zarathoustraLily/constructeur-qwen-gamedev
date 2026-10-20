extends TireMarksManager
## Gestionnaire de traces de pneus de test : il garde les traces demandées au lieu de les calculer. Il se
## range dans le groupe « tire_marks », où le kart cherche le gestionnaire de la scène.

## Traces demandées, dans l'ordre : [position, force, rayon en pixels].
var traces: Array[Array] = []
## Dernier centre reçu par set_player_position().
var centre: Vector3 = Vector3.INF


func _init() -> void:
	add_to_group("tire_marks")


func set_player_position(pos: Vector3) -> void:
	centre = pos


func add_tire(position: Vector3, strength: float, radius_px: float) -> void:
	traces.append([position, strength, radius_px])
