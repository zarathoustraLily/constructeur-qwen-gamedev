extends Node3D
## Exemple : vent dans l'herbe. Un brin (QuadMesh subdivisé en hauteur) face à la caméra. On compare deux images à
## 20 images d'écart, ligne par ligne : sans vent, rien ne bouge ; avec du vent, le haut du brin bouge et son pied
## reste en place.

const HERBE: Shader = preload("res://exemple/herbe.gdshader")
# Dans un jeu, ces réglages viennent d'un .tres de 5_data (principe 2 du plan).
const FORCE := 0.3
const VITESSE := 2.0


func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.0, 2.2)
	add_child(camera)
	add_child(DirectionalLight3D.new())  # éclaire la face du brin tournée vers la caméra
	var quad := QuadMesh.new()
	quad.size = Vector2(0.25, 2.0)
	quad.subdivide_depth = 12
	var materiau := ShaderMaterial.new()
	materiau.shader = HERBE
	var brin := MeshInstance3D.new()
	brin.mesh = quad
	brin.position = Vector3(0.0, 1.0, 0.0)  # pied à y = 0, pointe à y = 2
	brin.material_override = materiau
	add_child(brin)
	regler_vent(materiau, 0.0, VITESSE)
	var sans_vent := _changements(await _image(), await _image_plus_tard(20))
	regler_vent(materiau, FORCE, VITESSE)
	var avec_vent := _changements(await _image(), await _image_plus_tard(20))
	var haut: int = avec_vent[0]
	var pied: int = avec_vent[1]
	if sans_vent[0] + sans_vent[1] == 0 and haut > 0 and pied == 0:
		print("EXEMPLE VERIFIE : sans vent, 0 pixel changé ; avec du vent, %d pixels changés en haut du brin, %d au pied"
				% [haut, pied])
	else:
		push_error("sans vent %s ; avec du vent : haut %d, pied %d" % [sans_vent, haut, pied])
	get_tree().quit()


## Régler le vent : `force` 0 pour l'arrêter.
func regler_vent(materiau: ShaderMaterial, force: float, vitesse: float) -> void:
	materiau.set_shader_parameter(&"force", force)
	materiau.set_shader_parameter(&"vitesse", vitesse)


func _image() -> Image:
	for _i: int in 2:
		await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _image_plus_tard(images: int) -> Image:
	for _i: int in images:
		await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


## Pixels changés dans le haut du brin (le quart supérieur de sa hauteur à l'écran) et à son pied (les 4 % du bas).
func _changements(a: Image, b: Image) -> Array[int]:
	var lignes_du_brin: Array[int] = []
	for y: int in a.get_height():
		for x: int in a.get_width():
			if _vert(a.get_pixel(x, y)) or _vert(b.get_pixel(x, y)):
				lignes_du_brin.append(y)
				break
	if lignes_du_brin.is_empty():
		return [0, 0]
	var sommet: int = lignes_du_brin[0]
	var base: int = lignes_du_brin[-1]
	var hauteur := base - sommet
	var haut := 0
	var pied := 0
	for y: int in range(sommet, base + 1):
		var zone_haute := y < sommet + int(hauteur * 0.25)
		var zone_pied := y > base - int(hauteur * 0.04)
		if not zone_haute and not zone_pied:
			continue
		for x: int in a.get_width():
			if not a.get_pixel(x, y).is_equal_approx(b.get_pixel(x, y)):
				if zone_haute:
					haut += 1
				else:
					pied += 1
	return [haut, pied]


## Un pixel du brin : nettement plus vert que rouge et que bleu (le fond est gris).
func _vert(c: Color) -> bool:
	return c.g > c.r + 0.05 and c.g > c.b + 0.05
