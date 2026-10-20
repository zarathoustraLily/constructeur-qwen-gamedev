extends GdUnitTestSuite
## Règles de l'île : son terrain, sa piste et sa ligne d'arrivée sont des corps solides avec leur forme de
## collision, sur les couches Terrain et Circuit ; un kart posé au départ se pose sur le terrain ; l'île a son
## soleil, avec des ombres, et son environnement ; ses rampes ont une collision.
#@ 4-6
## En attendant l'eau (étape 007), une mer provisoire et solide, au niveau 0, porte le kart.
#@ 7+
## La mer est la surface d'eau de la scène (groupe « ocean ») : un kart lâché au large y flotte à sa hauteur
## de flottaison, et les bouées y flottent.
#@ all

const ISLAND := preload("res://2_sequence/levels/island/island.tscn")
const KART := preload("res://3_entities/kart/kart.tscn")
const START := Vector3(4.8399, 4.47262, -5.20099)

var _island: Node


func before_test() -> void:
	_island = auto_free(ISLAND.instantiate())
	add_child(_island)


func _body(path: String) -> StaticBody3D:
	return _island.get_node(path) as StaticBody3D


func _shape(body: StaticBody3D) -> Shape3D:
	for child: Node in body.get_children():
		var collision := child as CollisionShape3D
		if collision != null:
			return collision.shape
	return null


## Pose un kart en `position` et le laisse tomber `frames` images ; rend le kart.
func _drop_kart(position: Vector3, frames: int) -> Kart:
	var kart: Kart = auto_free(KART.instantiate())
	kart.input = null
	kart.position = position
	add_child(kart)
	for _frame: int in frames:
		await get_tree().physics_frame
	return kart


func test_le_terrain_la_piste_et_l_arrivee_sont_solides() -> void:
	for path: String in ["Environment/Terrain", "Environment/RaceTrack", "Environment/FinishLine"]:
		var body := _body(path)
		assert_object(body).override_failure_message(path + " absent").is_not_null()
		assert_object(_shape(body)).override_failure_message(path + " sans forme de collision").is_not_null()


func test_le_terrain_est_sur_la_couche_terrain_et_la_piste_sur_la_couche_circuit() -> void:
	assert_int(_body("Environment/Terrain").collision_layer).is_equal(8)
	assert_int(_body("Environment/RaceTrack").collision_layer).is_equal(16)


func test_un_kart_pose_au_depart_se_pose_sur_le_terrain() -> void:
	var kart: Kart = await _drop_kart(START + Vector3.UP, 90)
	assert_bool(kart.is_on_ground()).is_true()
	assert_float(kart.global_position.y).is_between(START.y - 1.5, START.y + 1.0)


func test_l_ile_a_son_soleil_avec_des_ombres_et_son_environnement() -> void:
	var sun := _island.get_node("Sun") as DirectionalLight3D
	assert_object(sun).is_not_null()
	assert_bool(sun.shadow_enabled).is_true()
	assert_object(_island.get_node("Environment2") as WorldEnvironment).is_not_null()


func test_les_rampes_ont_une_collision() -> void:
	var ramps := _island.get_node("Ramps").get_children()
	assert_int(ramps.size()).is_greater(0)
	for ramp: Node in ramps:
		assert_int(ramp.find_children("*", "CollisionShape3D", true, false).size()).override_failure_message(str(ramp.name)).is_greater(0)
#@ 6+


func test_l_herbe_est_semee_en_blocs_nommes() -> void:
	var blocks := _island.get_node("Details").get_children()
	assert_int(blocks.size()).is_greater(100)
	for block: Node in blocks:
		assert_bool(block is MultiMeshInstance3D).override_failure_message(str(block.name)).is_true()
		assert_bool(str(block.name).begins_with("DetailBlock")).override_failure_message(str(block.name)).is_true()
#@ 4-6


func test_la_mer_provisoire_porte_le_kart_au_niveau_zero() -> void:
	var kart: Kart = await _drop_kart(Vector3(400.0, 3.0, 400.0), 120)
	assert_bool(kart.is_on_ground()).is_true()
	assert_float(kart.global_position.y).is_between(-0.5, 0.5)
#@ 7+


func test_la_mer_est_la_surface_d_eau_de_la_scene() -> void:
	assert_object(get_tree().get_first_node_in_group("ocean") as WaterSurface).is_not_null()


func test_au_large_le_kart_flotte_sur_la_mer() -> void:
	var kart: Kart = await _drop_kart(Vector3(400.0, 3.0, 400.0), 240)
	assert_bool(kart.is_in_water()).is_true()
	assert_float(kart.global_position.y).is_equal_approx(kart.settings.water_ride_height, 0.05)


func test_les_bouees_flottent() -> void:
	for _frame: int in 300:
		await get_tree().physics_frame
	for buoy: Node in _island.get_node("Buoys").get_children():
		var body := buoy as BuoyantBody3D
		assert_bool(body.submerged).override_failure_message(str(body.name) + " hors de l'eau").is_true()
		assert_float(body.global_position.y).override_failure_message(str(body.name) + " a coulé").is_greater(-3.0)
		assert_float(body.linear_velocity.length()).override_failure_message(str(body.name) + " dérive").is_less(0.5)
#@ all
