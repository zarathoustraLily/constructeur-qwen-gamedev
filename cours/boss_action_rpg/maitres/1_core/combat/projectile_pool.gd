class_name ProjectilePool extends Node3D
## La réserve des projectiles : tous sont créés au chargement du niveau, puis relancés sans fin. Aucun nœud n'est
## créé ni détruit pendant le combat : instancier en plein combat coûte des allocations, donc des saccades.

## La scène d'un projectile (racine Projectile).
@export var scene: PackedScene
## Combien de projectiles préparer : plus que la cadence × la durée de vol (10 × 0,6 = 6 en vol au plus).
@export_range(1, 512, 1) var size: int = 32

var _idle: Array[Projectile] = []


func _ready() -> void:
	for _i: int in size:
		var projectile: Projectile = scene.instantiate() as Projectile
		add_child(projectile)
		projectile.finished.connect(_on_finished)
		_idle.append(projectile)


## Lance un projectile prêt (voir Projectile.launch) et le rend ; null si tous volent.
func fire(origin: Vector3, direction: Vector3, speed: float, damage: float, lifetime: float) -> Projectile:
	if _idle.is_empty():
		return null
	var projectile: Projectile = _idle.pop_back()
	projectile.launch(origin, direction, speed, damage, lifetime)
	return projectile


## Combien de projectiles sont prêts à partir.
func available() -> int:
	return _idle.size()


func _on_finished(projectile: Projectile) -> void:
	_idle.append(projectile)
