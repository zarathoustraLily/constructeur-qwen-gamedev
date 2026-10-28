class_name RippleSurface extends MeshInstance3D
## Une surface d'eau qui ondule : une grille (GridMesh) dont les sommets suivent l'onde du dernier impact (Ripple).
## Son maillage est reconstruit à chaque image tant que l'onde vit ; au repos, elle est plate.

## L'onde et la grille.
@export var settings: RippleSettings

## Le temps écoulé depuis le dernier impact, en secondes ; négatif : aucun impact.
var time_since_impact: float = -1.0
## Le point d'impact (x, z), dans le repère de la surface.
var impact: Vector2 = Vector2.ZERO

var _flat: PackedVector3Array


func _ready() -> void:
	process_priority = ProcessOrder.VIEWS
	_flat = GridMesh.positions(settings.size, settings.cells)
	mesh = GridMesh.build(_flat, settings.cells)


func _process(delta: float) -> void:
	advance(delta)


## Lance une onde depuis `point` (x, z).
func drop(point: Vector2) -> void:
	impact = point
	time_since_impact = 0.0


## Fait passer `delta` secondes et reconstruit le maillage si une onde est en cours.
func advance(delta: float) -> void:
	if time_since_impact < 0.0:
		return
	time_since_impact += delta
	mesh = GridMesh.build(Ripple.displace(_flat, impact, time_since_impact, settings), settings.cells)


## La hauteur de l'eau au point (x, z) en ce moment.
func height_at(point: Vector2) -> float:
	if time_since_impact < 0.0:
		return 0.0
	return Ripple.height(point.distance_to(impact), time_since_impact, settings)
