@tool
extends MeshInstance3D
## Effet de lame : un quad posé le long de l'épée, dessiné par le shader de la traînée (dash.gdshader). Il n'est
## visible que pendant la forme de coup attack_type, et son effacement suit celui que l'animation du coup écrit
## dans l'emplacement de l'arme (vfx_threshold). C'est de la présentation : il lit l'emplacement à chaque image,
## jusque dans l'éditeur (d'où @tool), où l'on voit l'effet en jouant l'animation.

## L'emplacement de l'arme, que l'animation du coup écrit.
@export var weapon_slot: WeaponSlot
## La forme de coup pendant laquelle l'effet se voit.
@export var attack_type: WeaponSlot.Mode = WeaponSlot.Mode.SLASH


func _process(_delta: float) -> void:
	var material := material_override as ShaderMaterial
	if weapon_slot == null or material == null:
		return
	visible = weapon_slot.attack_mode == attack_type
	material.set_shader_parameter(&"threshold", weapon_slot.vfx_threshold)
