class_name HitFlash extends Node
## L'éclair d'un coup : le maillage montré prend un voile coloré (material_overlay non éclairé) qui s'efface en
## `flash_duration` secondes par un Tween, puis le voile est retiré. Un nouveau coup relance l'éclair.

## Le maillage qui s'éclaire.
@export var mesh: MeshInstance3D
## Couleur et durée de l'éclair.
@export var settings: VfxSettings

var _overlay: StandardMaterial3D
var _tween: Tween


## Lance l'éclair : le voile à pleine couleur, puis son effacement ; un éclair en cours est remplacé.
func flash() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_overlay = make_overlay(settings.flash_color)
	mesh.material_overlay = _overlay
	_tween = create_tween()
	_tween.tween_property(_overlay, "albedo_color:a", 0.0, settings.flash_duration)
	_tween.tween_callback(clear)


## Retire le voile.
func clear() -> void:
	mesh.material_overlay = null


## Vrai pendant un éclair.
func is_flashing() -> bool:
	return mesh.material_overlay != null


## Le voile d'un éclair : non éclairé (couleur franche), transparent selon l'alpha de `color`.
static func make_overlay(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	return material
