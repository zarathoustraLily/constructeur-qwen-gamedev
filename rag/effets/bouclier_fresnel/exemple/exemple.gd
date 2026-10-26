extends Node3D
## Exemple : bouclier par effet de Fresnel. Sur une sphère, le centre laisse voir le fond ; les bords brillent. On lit
## la ligne du milieu de l'image : le pixel central est proche du fond, et le plus lumineux se trouve près du bord.
## Puis `encaisser` (un coup reçu) fait briller la bulle plus fort, et elle revient à sa lueur ordinaire.

const BOUCLIER: Shader = preload("res://exemple/bouclier.gdshader")
# Dans un jeu, ces réglages viennent d'un .tres de 5_data (principe 2 du plan).
const INTENSITE := 1.5
const INTENSITE_COUP := 4.0
const DUREE_COUP := 0.3


func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 0.0, 2.2)
	add_child(camera)
	var materiau := ShaderMaterial.new()
	materiau.shader = BOUCLIER
	materiau.set_shader_parameter(&"intensity", INTENSITE)
	var sphere := MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.material_override = materiau
	add_child(sphere)
	var fond := RenderingServer.get_default_clear_color()
	var ligne := await _ligne_du_milieu()
	var milieu := ligne.size() * 0.5
	var centre: Color = ligne[int(milieu)]
	var x_max := 0
	for x: int in ligne.size():
		if ligne[x].b > ligne[x_max].b:
			x_max = x
	var bleu_max: float = ligne[x_max].b
	var ecart_au_centre := absf(x_max - milieu) / milieu
	var lueur := _lueur(ligne, fond)
	var tween := encaisser(materiau, INTENSITE, INTENSITE_COUP, DUREE_COUP)
	var lueur_coup := _lueur(await _ligne_du_milieu(), fond)
	await tween.finished
	var lueur_apres := _lueur(await _ligne_du_milieu(), fond)
	var forme_ok := absf(centre.b - fond.b) < 0.1 and bleu_max > centre.b + 0.3 and ecart_au_centre > 0.05
	if forme_ok and lueur_coup > lueur * 1.2 and absf(lueur_apres - lueur) < lueur * 0.02:
		print(("EXEMPLE VERIFIE : centre %.2f de bleu (fond %.2f), bord %.2f, à %.0f %% de la demi-largeur ; "
				+ "lueur de la ligne %.1f, %.1f pendant le coup, %.1f après")
				% [centre.b, fond.b, bleu_max, ecart_au_centre * 100.0, lueur, lueur_coup, lueur_apres])
	else:
		push_error("centre %.2f, fond %.2f, maximum %.2f à %.2f ; lueur %.1f, %.1f, %.1f"
				% [centre.b, fond.b, bleu_max, ecart_au_centre, lueur, lueur_coup, lueur_apres])
	get_tree().quit()


## Un coup encaissé : la bulle brille à `intensite_coup`, puis revient à `intensite` en `duree` secondes.
func encaisser(materiau: ShaderMaterial, intensite: float, intensite_coup: float, duree: float) -> Tween:
	materiau.set_shader_parameter(&"intensity", intensite_coup)
	var regler := func(v: float) -> void: materiau.set_shader_parameter(&"intensity", v)
	var tween := create_tween()
	tween.tween_method(regler, intensite_coup, intensite, duree)
	return tween


func _ligne_du_milieu() -> Array[Color]:
	for _image: int in 2:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var y := int(image.get_height() * 0.5)
	var ligne: Array[Color] = []
	for x: int in image.get_width():
		ligne.append(image.get_pixel(x, y))
	return ligne


## Le bleu ajouté au fond, sommé sur la ligne : la lueur de la bulle.
func _lueur(ligne: Array[Color], fond: Color) -> float:
	var total := 0.0
	for c: Color in ligne:
		total += maxf(c.b - fond.b, 0.0)
	return total
