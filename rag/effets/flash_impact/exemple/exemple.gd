extends Node3D
## Exemple : flash d'impact. Une sphère rouge devient blanche au moment du coup, puis un Tween la ramène à sa couleur.
## `flasher` est la fonction à reprendre ; on lit la couleur au centre de l'image rendue avant, pendant et après.

const FLASH: Shader = preload("res://exemple/flash.gdshader")
const DUREE_FLASH := 0.25  # dans un jeu, cette durée vient d'un .tres de 5_data (principe 2 du plan)

var _materiau: ShaderMaterial


func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 0.0, 3.0)
	add_child(camera)
	var lumiere := DirectionalLight3D.new()
	lumiere.rotation_degrees = Vector3(-30.0, 20.0, 0.0)
	add_child(lumiere)
	_materiau = ShaderMaterial.new()
	_materiau.shader = FLASH
	var sphere := MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.material_override = _materiau
	add_child(sphere)
	var avant := await _couleur_au_centre()
	var tween := flasher(_materiau, DUREE_FLASH)
	var pendant := await _couleur_au_centre()
	await tween.finished
	var apres := await _couleur_au_centre()
	var rouge_avant := avant.r > 0.3 and avant.g < 0.3
	var blanc_pendant := pendant.r > 0.9 and pendant.g > 0.9 and pendant.b > 0.9
	var revenu := absf(apres.r - avant.r) + absf(apres.g - avant.g) + absf(apres.b - avant.b) < 0.02
	if rouge_avant and blanc_pendant and revenu:
		print("EXEMPLE VERIFIE : centre %s avant le coup, %s pendant le flash, %s après %.2f s"
				% [_texte(avant), _texte(pendant), _texte(apres), DUREE_FLASH])
	else:
		push_error("centre %s avant, %s pendant, %s après" % [_texte(avant), _texte(pendant), _texte(apres)])
	get_tree().quit()


## Le coup : `flash` passe à 1, puis revient à 0 en `duree` secondes.
func flasher(materiau: ShaderMaterial, duree: float) -> Tween:
	materiau.set_shader_parameter(&"flash", 1.0)
	var regler := func(v: float) -> void: materiau.set_shader_parameter(&"flash", v)
	var tween := create_tween()
	tween.tween_method(regler, 1.0, 0.0, duree)
	return tween


## La couleur du pixel central, deux images après le changement (le moteur dessine, puis on lit).
func _couleur_au_centre() -> Color:
	for _image: int in 2:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	return image.get_pixel(int(image.get_width() * 0.5), int(image.get_height() * 0.5))


func _texte(c: Color) -> String:
	return "(%.2f, %.2f, %.2f)" % [c.r, c.g, c.b]
