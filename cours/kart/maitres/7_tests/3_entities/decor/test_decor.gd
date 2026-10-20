extends GdUnitTestSuite
## Règles du décor : les rochers et les palmiers sont solides, sur la couche Terrain ; un kart lancé tout droit
## sur un palmier ou sur un rocher ne le traverse pas ; les nuages sont un grand plan ; le vent que lisent
## les shaders est déclaré dans les paramètres globaux du projet.

const ROCK := preload("res://3_entities/decor/rock/rock.tscn")
const PALM := preload("res://3_entities/decor/palm/small_palm.tscn")
const CLOUD := preload("res://3_entities/decor/cloud/cloud.tscn")
const KART := preload("res://3_entities/kart/kart.tscn")


func _ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 8
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(auto_free(ground))


## Lance un kart à plein gaz vers -Z, depuis z = 0, sur un obstacle posé en z = -12 ; rend le z le plus loin
## atteint par le kart.
func _drive_into(obstacle: Node3D) -> float:
	_ground()
	obstacle.position = Vector3(0.0, 0.0, -12.0)
	add_child(auto_free(obstacle))
	var kart: Kart = auto_free(KART.instantiate())
	kart.input = null
	kart.position = Vector3(0.0, 0.6, 0.0)
	add_child(kart)
	kart.commands.throttle = 1.0
	var furthest := 0.0
	for _frame: int in 180:
		await get_tree().physics_frame
		furthest = minf(furthest, kart.global_position.z)
	return furthest


func _solid_bodies(scene: Node) -> Array[StaticBody3D]:
	var bodies: Array[StaticBody3D] = []
	for body: Node in scene.find_children("*", "StaticBody3D", true, false):
		bodies.append(body as StaticBody3D)
	return bodies


func test_les_rochers_et_les_palmiers_sont_solides_sur_la_couche_terrain() -> void:
	for scene: PackedScene in [ROCK, PALM]:
		var decor: Node3D = auto_free(scene.instantiate())
		var bodies := _solid_bodies(decor)
		assert_int(bodies.size()).override_failure_message(scene.resource_path).is_greater(0)
		for body: StaticBody3D in bodies:
			assert_bool(body.get_collision_layer_value(4)).override_failure_message(scene.resource_path).is_true()


func test_le_kart_ne_traverse_pas_un_palmier() -> void:
	var furthest: float = await _drive_into(PALM.instantiate())
	assert_float(furthest).is_greater(-12.0)


func test_le_kart_ne_traverse_pas_un_rocher() -> void:
	var furthest: float = await _drive_into(ROCK.instantiate())
	assert_float(furthest).is_greater(-12.0)


func test_les_nuages_sont_un_grand_plan() -> void:
	var clouds: MeshInstance3D = auto_free(CLOUD.instantiate())
	assert_object(clouds.mesh as PlaneMesh).is_not_null()
	assert_object(clouds.material_override as ShaderMaterial).is_not_null()


func test_le_vent_est_declare_dans_les_parametres_globaux() -> void:
	for global_name: String in ["wind_noise_texture", "wind_direction", "wind_strength"]:
		assert_bool(ProjectSettings.has_setting("shader_globals/" + global_name)).override_failure_message(global_name).is_true()
