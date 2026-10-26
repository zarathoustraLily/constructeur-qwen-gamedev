extends Node3D
## Exemple : contour par coque inversée. Le matériau du contour est la « passe suivante » (next_pass) du matériau de
## l'objet. On compte les pixels sombres sur la ligne du milieu de l'image : sans contour, avec, puis après l'avoir retiré.

const CONTOUR: Shader = preload("res://exemple/contour.gdshader")


func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 0.0, 3.0)
	add_child(camera)
	add_child(DirectionalLight3D.new())
	var surface := StandardMaterial3D.new()
	surface.albedo_color = Color(0.9, 0.9, 0.9)
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var sphere := MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.material_override = surface
	add_child(sphere)
	var sans := await _pixels_sombres()
	var trait_noir := ShaderMaterial.new()
	trait_noir.shader = CONTOUR
	trait_noir.set_shader_parameter(&"thickness", 0.06)
	entourer(surface, trait_noir)
	var avec := await _pixels_sombres()
	retirer_contour(surface)
	var apres := await _pixels_sombres()
	if sans == 0 and avec >= 4 and apres == 0:
		print("EXEMPLE VERIFIE : %d pixels sombres sur la ligne du milieu sans contour, %d avec, %d une fois retiré"
				% [sans, avec, apres])
	else:
		push_error("pixels sombres : %d sans contour, %d avec, %d une fois retiré" % [sans, avec, apres])
	get_tree().quit()


## Montrer le contour : le matériau du trait est dessiné après la surface, sur le même maillage.
func entourer(surface: Material, trait_contour: ShaderMaterial) -> void:
	surface.next_pass = trait_contour


## Retirer le contour.
func retirer_contour(surface: Material) -> void:
	surface.next_pass = null


func _pixels_sombres() -> int:
	for _image: int in 2:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var y := int(image.get_height() * 0.5)
	var n := 0
	for x: int in image.get_width():
		if image.get_pixel(x, y).get_luminance() < 0.05:
			n += 1
	return n
