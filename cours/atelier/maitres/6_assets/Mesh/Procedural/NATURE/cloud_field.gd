@tool
class_name CloudField extends MultiMeshInstance3D
## Le champ de nuages : des bouffées sphériques réparties dans un disque, dessinées en un seul MultiMesh.

## Les réglages du champ ; les changer le reconstruit.
@export var settings: CloudSettings:
	set(value):
		settings = value
		if is_inside_tree():
			rebuild()


func _ready() -> void:
	rebuild()


## Reconstruit le champ d'après les réglages.
func rebuild() -> void:
	if settings == null:
		multimesh = null
		return
	var puff: SphereMesh = SphereMesh.new()
	puff.radial_segments = 8
	puff.rings = 4
	multimesh = Scatter.multimesh(puff, Scatter.cloud_puffs(settings.puff_count, settings.radius, settings.height,
		settings.size, settings.random_seed))
