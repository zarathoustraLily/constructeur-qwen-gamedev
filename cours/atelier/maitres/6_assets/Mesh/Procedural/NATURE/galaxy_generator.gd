@tool
class_name GalaxyGenerator extends MultiMeshInstance3D
## Le générateur de galaxie : ses étoiles en un seul MultiMesh coloré, d'après ses réglages.

## Les réglages de la galaxie ; les changer la reconstruit.
@export var settings: GalaxySettings:
	set(value):
		settings = value
		if is_inside_tree():
			rebuild()


func _ready() -> void:
	rebuild()


## Reconstruit la galaxie d'après les réglages ; les couleurs des étoiles passent par celles des instances.
func rebuild() -> void:
	if settings == null:
		multimesh = null
		return
	multimesh = Galaxy.build(settings)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material_override = material
