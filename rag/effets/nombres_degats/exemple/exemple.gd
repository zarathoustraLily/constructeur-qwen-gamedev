extends Node3D
## Exemple : nombre de dégâts. Un Label3D tourné vers la caméra apparaît au point touché, monte et s'efface, puis
## disparaît. On suit ses pixels : présents au départ, plus hauts à mi-parcours, absents à la fin, et le Label3D est
## libéré.

# Dans un jeu, ces réglages viennent d'un .tres de 5_data (principe 2 du plan).
const MONTEE := 0.6
const DUREE := 0.5


func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 0.3, 2.0)
	add_child(camera)
	var etiquette := afficher_degats(self, 42, Vector3.ZERO, MONTEE, DUREE)
	var depart := await _texte_apres(2)
	var milieu := await _texte_apres(int(DUREE * 30.0))
	await get_tree().create_timer(DUREE).timeout
	var fin := await _texte_apres(2)
	var monte := milieu.y < depart.y  # y de l'image : vers le haut, il diminue
	if depart.x > 20 and milieu.x > 0 and monte and fin.x == 0 and not is_instance_valid(etiquette):
		print("EXEMPLE VERIFIE : %d pixels de texte au départ (ligne %d), %d à mi-parcours (ligne %d), %d à la fin, étiquette libérée"
				% [depart.x, depart.y, milieu.x, milieu.y, fin.x])
	else:
		push_error("départ %s, milieu %s, fin %s, libérée %s" % [depart, milieu, fin, not is_instance_valid(etiquette)])
	get_tree().quit()


## Un nombre de dégâts : il monte de `montee` mètres en `duree` secondes en s'effaçant, puis il est libéré.
func afficher_degats(parent: Node3D, valeur: int, ou: Vector3, montee: float, duree: float) -> Label3D:
	var etiquette := Label3D.new()
	etiquette.text = str(valeur)
	etiquette.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # toujours face à la caméra
	etiquette.no_depth_test = true  # lisible même derrière un obstacle
	etiquette.outline_size = 8
	parent.add_child(etiquette)
	etiquette.global_position = ou
	var tween := etiquette.create_tween().set_parallel()  # lié à l'étiquette : il s'arrête avec elle
	tween.tween_property(etiquette, "position:y", etiquette.position.y + montee, duree)
	tween.tween_property(etiquette, "modulate:a", 0.0, duree)
	tween.chain().tween_callback(etiquette.queue_free)
	return etiquette


## Nombre de pixels du texte (x) et leur hauteur moyenne dans l'image (y). Le texte s'efface : on compte les pixels
## qui s'écartent du fond, texte clair ou contour sombre.
func _texte_apres(images: int) -> Vector2i:
	for _i: int in images:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var fond := RenderingServer.get_default_clear_color().get_luminance()
	var n := 0
	var somme_y := 0
	for y: int in image.get_height():
		for x: int in range(0, image.get_width(), 2):
			if absf(image.get_pixel(x, y).get_luminance() - fond) > 0.05:
				n += 1
				somme_y += y
	return Vector2i(n, roundi(float(somme_y) / n) if n > 0 else 0)
