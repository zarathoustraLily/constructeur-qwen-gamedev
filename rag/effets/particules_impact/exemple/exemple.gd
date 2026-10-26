extends Node3D
## Exemple : particules d'impact. Une salve unique (`one_shot`, `explosiveness` 1) d'étincelles orange au point touché.
## On compte les pixels orange : aucun avant le coup, des étincelles juste après, plus rien une fois leur durée de vie
## passée. Puis une seconde salve, relancée par `eclater`, se voit à son tour.

# Dans un jeu, ces réglages viennent d'un .tres de 5_data (principe 2 du plan).
const DUREE_DE_VIE := 0.4
const NOMBRE := 32
const COULEUR := Color(1.0, 0.55, 0.1)


func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 0.5, 3.0)
	add_child(camera)
	var particules := creer_etincelles(NOMBRE, DUREE_DE_VIE, COULEUR)
	add_child(particules)
	var avant := await _pixels_orange_apres(2)
	eclater(particules, Vector3.ZERO)
	var pendant := await _pixels_orange_apres(6)
	var apres := await _pixels_orange_apres(int(DUREE_DE_VIE * 60.0) + 10)
	eclater(particules, Vector3(0.5, 0.0, 0.0))
	var seconde := await _pixels_orange_apres(6)
	if avant == 0 and pendant > 20 and apres == 0 and seconde > 20:
		print("EXEMPLE VERIFIE : %d pixels orange avant le coup, %d juste après, %d une fois la salve finie, %d à la seconde salve"
				% [avant, pendant, apres, seconde])
	else:
		push_error("pixels orange : %d avant, %d pendant, %d après, %d seconde salve" % [avant, pendant, apres, seconde])
	get_tree().quit()


## Les étincelles : une salve unique, toutes émises au même instant, projetées dans toutes les directions et retombant.
func creer_etincelles(nombre: int, duree_de_vie: float, couleur: Color) -> GPUParticles3D:
	var processus := ParticleProcessMaterial.new()
	processus.direction = Vector3.UP
	processus.spread = 180.0
	processus.initial_velocity_min = 2.0
	processus.initial_velocity_max = 4.0
	processus.gravity = Vector3(0.0, -9.8, 0.0)
	processus.color = couleur
	var apparence := StandardMaterial3D.new()
	apparence.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	apparence.vertex_color_use_as_albedo = true  # la couleur du processus arrive par la couleur des sommets
	var goutte := SphereMesh.new()
	goutte.radius = 0.04
	goutte.height = 0.08
	goutte.material = apparence
	var particules := GPUParticles3D.new()
	particules.amount = nombre
	particules.lifetime = duree_de_vie
	particules.one_shot = true
	particules.explosiveness = 1.0
	particules.emitting = false
	particules.process_material = processus
	particules.draw_pass_1 = goutte
	return particules


## Le coup : la salve part du point touché.
func eclater(particules: GPUParticles3D, ou: Vector3) -> void:
	particules.global_position = ou
	particules.restart()


func _pixels_orange_apres(images: int) -> int:
	for _i: int in images:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var n := 0
	for y: int in range(0, image.get_height(), 2):
		for x: int in range(0, image.get_width(), 2):
			var c := image.get_pixel(x, y)
			if c.r > 0.8 and c.g > 0.35 and c.g < 0.75 and c.b < 0.3:
				n += 1
	return n
