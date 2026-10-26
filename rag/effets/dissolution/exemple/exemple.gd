extends Node3D
## Exemple : dissolution. On fait monter `progression` de 0 à 1 sur une sphère et on compte, sur une grille de points
## de l'image rendue, la part de la sphère qui a disparu (le fond y réapparaît). Puis on compte les appels de dessin :
## entièrement dissoute, la sphère en coûte encore ; `dissoudre` la libère à la fin, et le coût disparaît.

const DISSOLUTION: Shader = preload("res://exemple/dissolution.gdshader")
const DUREE := 0.3  # dans un jeu, cette durée vient d'un .tres de 5_data (principe 2 du plan)

var _materiau: ShaderMaterial
var _fond: Color


func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 0.0, 1.6)
	add_child(camera)
	add_child(DirectionalLight3D.new())
	_materiau = ShaderMaterial.new()
	_materiau.shader = DISSOLUTION
	var sphere := MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.material_override = _materiau
	add_child(sphere)
	_fond = RenderingServer.get_default_clear_color()
	var parts: Array[float] = []
	for progression: float in [0.0, 0.5, 1.0]:
		_materiau.set_shader_parameter(&"progression", progression)
		parts.append(await _part_disparue())
	var appels_dissoute := await _appels_de_dessin()
	await dissoudre(_materiau, sphere, DUREE).finished
	var appels_liberee := await _appels_de_dessin()
	var parts_ok := parts[0] < 0.02 and parts[1] > 0.1 and parts[1] < 0.9 and parts[2] > 0.98
	if parts_ok and appels_dissoute > appels_liberee and not is_instance_valid(sphere):
		print(("EXEMPLE VERIFIE : part disparue %.2f, %.2f puis %.2f pour une progression de 0, 0,5 et 1 ; "
				+ "%d appels de dessin sphère dissoute, %d une fois libérée par dissoudre")
				% [parts[0], parts[1], parts[2], appels_dissoute, appels_liberee])
	else:
		push_error("parts disparues %s, appels %d puis %d" % [parts, appels_dissoute, appels_liberee])
	get_tree().quit()


## La disparition : `progression` monte de 0 à 1 en `duree` secondes, puis l'objet est libéré.
func dissoudre(materiau: ShaderMaterial, objet: Node3D, duree: float) -> Tween:
	var regler := func(v: float) -> void: materiau.set_shader_parameter(&"progression", v)
	var tween := create_tween()
	tween.tween_method(regler, 0.0, 1.0, duree)
	tween.tween_callback(objet.queue_free)
	return tween


func _appels_de_dessin() -> int:
	for _image: int in 2:
		await RenderingServer.frame_post_draw
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)


## Part des points d'une grille au centre de l'image qui montrent le fond (la sphère y a disparu).
func _part_disparue() -> float:
	for _image: int in 2:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var fond := 0
	var total := 0
	for i: int in 9:
		for j: int in 9:
			var p := Vector2i(int(image.get_width() * (0.4 + 0.025 * i)), int(image.get_height() * (0.4 + 0.025 * j)))
			var c := image.get_pixelv(p)
			total += 1
			if absf(c.r - _fond.r) + absf(c.g - _fond.g) + absf(c.b - _fond.b) < 0.03:
				fond += 1
	return float(fond) / float(total)
