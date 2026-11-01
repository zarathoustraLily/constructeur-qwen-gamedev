extends GdUnitTestSuite
## Règles de l'éclairage à l'écran : une lumière ne lit que l'image de son côté, et le shader dit la même chose que `SixWay.lit`. La scène
## cuit ses deux images, rend la carte, et sa lumière tourne.

const SCENE := preload("res://2_sequence/six_way_puff.tscn")
const VIEW := preload("res://1_core/gpu/shaders/six_way_view.gdshader")
const PIXELS := 32
const MIDDLE := 16


func _viewport() -> SubViewport:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(PIXELS, PIXELS)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	return auto_free(viewport)


func _texture(color: Color) -> ImageTexture:
	var image: Image = Image.create_empty(2, 2, false, Image.FORMAT_RGBAF)
	image.fill(color)
	return ImageTexture.create_from_image(image)


## Un plan qui remplit l'image, cuit avec `first` et `second`, et une lumière tournée de `turn` degrés autour de y.
func _lit_quad(first: Color, second: Color, turn: float) -> SubViewport:
	var viewport: SubViewport = _viewport()
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = VIEW
	material.set_shader_parameter("first_lights", _texture(first))
	material.set_shader_parameter("second_lights", _texture(second))
	var plan: MeshInstance3D = MeshInstance3D.new()
	plan.mesh = QuadMesh.new()
	plan.scale = Vector3(4.0, 4.0, 1.0)
	plan.material_override = material
	viewport.add_child(plan)
	var lumiere: DirectionalLight3D = DirectionalLight3D.new()
	lumiere.rotation_degrees = Vector3(0.0, turn, 0.0)
	viewport.add_child(lumiere)
	var camera: Camera3D = Camera3D.new()
	camera.position = Vector3(0.0, 0.0, 1.0)
	viewport.add_child(camera)
	return viewport


## L'image du viewport. Une scène immobile ne redessine pas d'elle-même : on force le dessin.
func _image(viewport: SubViewport) -> Image:
	for _i: int in 3:
		await get_tree().process_frame
		RenderingServer.force_draw(false)
	return viewport.get_texture().get_image()


func test_une_lumiere_de_droite_eclaire_ce_qui_regarde_a_droite() -> void:
	var image: Image = await _image(_lit_quad(Color(1.0, 0.0, 0.0, 1.0), Color(0.0, 0.0, 0.0, 1.0), 90.0))
	assert_float(image.get_pixel(MIDDLE, MIDDLE).r).is_greater(0.5)


func test_une_lumiere_de_gauche_ne_voit_pas_l_image_de_droite() -> void:
	var image: Image = await _image(_lit_quad(Color(1.0, 0.0, 0.0, 1.0), Color(0.0, 0.0, 0.0, 1.0), -90.0))
	assert_float(image.get_pixel(MIDDLE, MIDDLE).r).is_less(0.02)


func test_une_lumiere_de_face_lit_l_avant() -> void:
	var image: Image = await _image(_lit_quad(Color(0.0, 0.0, 0.0, 1.0), Color(0.0, 0.0, 1.0, 1.0), 0.0))
	assert_float(image.get_pixel(MIDDLE, MIDDLE).r).is_greater(0.5)


func test_une_lumiere_de_dos_lit_l_arriere() -> void:
	var image: Image = await _image(_lit_quad(Color(0.0, 0.0, 1.0, 1.0), Color(0.0, 0.0, 0.0, 1.0), 180.0))
	assert_float(image.get_pixel(MIDDLE, MIDDLE).r).is_greater(0.5)


func test_l_opacite_vient_de_la_premiere_image() -> void:
	var image: Image = await _image(_lit_quad(Color(0.0, 0.0, 0.0, 0.5), Color(0.0, 0.0, 0.0, 0.0), 0.0))
	assert_float(image.get_pixel(MIDDLE, MIDDLE).a).is_equal_approx(0.5, 0.02)


func test_la_scene_cuit_ses_deux_images_et_sa_lumiere_tourne() -> void:
	var viewport: SubViewport = _viewport()
	var scene: Node3D = SCENE.instantiate()
	viewport.add_child(scene)
	var material: ShaderMaterial = (scene.get_node("Quad") as MeshInstance3D).material_override
	assert_object(material.get_shader_parameter("first_lights")).is_not_null()
	assert_object(material.get_shader_parameter("second_lights")).is_not_null()
	var lumiere: DirectionalLight3D = scene.get_node("Light")
	var depart: float = lumiere.rotation.y
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(lumiere.rotation.y).is_not_equal(depart)
