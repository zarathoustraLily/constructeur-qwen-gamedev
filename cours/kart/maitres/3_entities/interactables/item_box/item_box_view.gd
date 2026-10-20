class_name ItemBoxView extends Node3D
## Présentation de la boîte à objets : elle flotte, tourne sur elle-même et change de couleur, la boîte et sa
## lumière ensemble ; prise, elle se cache et s'éteint jusqu'à son retour. Elle lit l'état de la boîte sans le
## changer. Le temps est compté par la vue elle-même : à cadence fixe, deux parties donnent les mêmes images.

## La boîte montrée.
@export var box: ItemBox
## Le nœud qui flotte et tourne.
@export var visual: Node3D
## Le maillage de la boîte, dont la couleur défile (paramètre d'instance « box_color »).
@export var box_mesh: MeshInstance3D
## La lumière de la boîte.
@export var light: OmniLight3D
## Amplitude (m) du flottement.
@export var bob_height: float = 0.5
## Battements du flottement par seconde.
@export var bob_frequency: float = 0.5
## Vitesses de rotation (rad/s) autour des trois axes.
@export var spin: Vector3 = Vector3(1.2, 0.8, 1.5)
## Tours de la roue chromatique par seconde.
@export var hue_speed: float = 0.5

var _time: float = 0.0
var _light_range: float = 0.0


func _ready() -> void:
	_light_range = light.omni_range


func _process(delta: float) -> void:
	_time += delta
	visual.visible = box.active
	light.omni_range = _light_range if box.active else 0.0
	visual.position.y = bob_height * sin(TAU * bob_frequency * _time)
	var rotation_x := Quaternion(Vector3.RIGHT, _time * spin.x)
	var rotation_y := Quaternion(Vector3.UP, _time * spin.y)
	var rotation_z := Quaternion(Vector3.FORWARD, _time * spin.z)
	visual.basis = Basis(rotation_x * rotation_y * rotation_z)
	var color := Color.from_hsv(fposmod(_time * hue_speed, 1.0), 0.8, 1.0)
	light.light_color = color
	box_mesh.set_instance_shader_parameter(&"box_color", Vector3(color.r, color.g, color.b))
