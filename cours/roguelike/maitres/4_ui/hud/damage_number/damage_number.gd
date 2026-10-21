class_name DamageNumber extends Node2D
## Un chiffre de dégâts : il s'affiche à l'écran au-dessus d'un point du monde (target_position), que la caméra
## projette à chaque image ; son animation « spawn » le grossit, le réduit, puis le libère.

## Le point du monde au-dessus duquel s'affiche le chiffre.
var target_position: Vector3 = Vector3.ZERO

@onready var label: Label = $Label


## Écrit `amount` avec une décimale (« 5.0 »).
func set_damage_text(amount: float) -> void:
	if not is_node_ready():
		await ready
	label.text = "%.1f" % amount


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		position = camera.unproject_position(target_position)
