extends Node3D
## Exemple : eau stylisée. Un plan subdivisé vu de biais. On compare deux images à 20 images d'écart : figée
## (`vitesse` 0), l'eau ne change pas ; animée, elle change. Sur une colonne de l'image, crêtes et creux ont deux
## teintes nettement différentes.

const EAU: Shader = preload("res://exemple/eau.gdshader")
# Dans un jeu, ces réglages viennent d'un .tres de 5_data (principe 2 du plan).
const AMPLITUDE := 0.15
const VITESSE := 1.5


func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 3.0, 5.0)
	camera.rotation_degrees = Vector3(-30.0, 0.0, 0.0)
	add_child(camera)
	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	add_child(soleil)
	var plan := PlaneMesh.new()
	plan.size = Vector2(12.0, 12.0)
	plan.subdivide_width = 96
	plan.subdivide_depth = 96
	var materiau := ShaderMaterial.new()
	materiau.shader = EAU
	var eau := MeshInstance3D.new()
	eau.mesh = plan
	eau.material_override = materiau
	add_child(eau)
	regler_vagues(materiau, AMPLITUDE, 0.0)
	var figee := _ecarts(await _image(), await _image_plus_tard(20))
	regler_vagues(materiau, AMPLITUDE, VITESSE)
	var avant := await _image()
	var animee := _ecarts(avant, await _image_plus_tard(20))
	var contraste := _contraste_de_colonne(avant)
	if figee == 0 and animee > 50 and contraste > 0.15:
		print("EXEMPLE VERIFIE : %d points changés en 20 images eau figée, %d eau animée ; écart de luminance crête/creux %.2f"
				% [figee, animee, contraste])
	else:
		push_error("figée %d, animée %d, contraste %.2f" % [figee, animee, contraste])
	get_tree().quit()


## Régler la houle : `amplitude` en mètres, `vitesse` 0 pour figer l'eau.
func regler_vagues(materiau: ShaderMaterial, amplitude: float, vitesse: float) -> void:
	materiau.set_shader_parameter(&"amplitude", amplitude)
	materiau.set_shader_parameter(&"vitesse", vitesse)


func _image() -> Image:
	for _i: int in 2:
		await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _image_plus_tard(images: int) -> Image:
	for _i: int in images:
		await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


## Points d'une grille de 48 × 27 dont la couleur a changé entre les deux images.
func _ecarts(a: Image, b: Image) -> int:
	var n := 0
	for i: int in 48:
		for j: int in 27:
			var p := Vector2i(int(a.get_width() * (i + 0.5) / 48.0), int(a.get_height() * (j + 0.5) / 27.0))
			if not a.get_pixelv(p).is_equal_approx(b.get_pixelv(p)):
				n += 1
	return n


## Écart entre le point le plus clair et le plus sombre de la colonne du milieu, sous l'horizon.
func _contraste_de_colonne(image: Image) -> float:
	var x := int(image.get_width() * 0.5)
	var plus_clair := 0.0
	var plus_sombre := 1.0
	for y: int in range(int(image.get_height() * 0.5), image.get_height()):
		var l := image.get_pixel(x, y).get_luminance()
		plus_clair = maxf(plus_clair, l)
		plus_sombre = minf(plus_sombre, l)
	return plus_clair - plus_sombre
