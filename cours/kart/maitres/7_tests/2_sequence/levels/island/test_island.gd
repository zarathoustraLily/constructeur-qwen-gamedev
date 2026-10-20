extends GdUnitTestSuite
## Règles de l'île : son terrain, sa piste et sa ligne d'arrivée sont des corps solides avec leur forme de
## collision, sur les couches Terrain et Circuit ; un kart posé au départ se pose sur le terrain ; l'île a son
## soleil, avec des ombres, et son environnement ; ses rampes ont une collision.
#@ 4-6
## En attendant l'eau (étape 007), une mer provisoire et solide, au niveau 0, porte le kart.
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
#@ 4-6


func test_la_mer_provisoire_porte_le_kart_au_niveau_zero() -> void:
	var kart: Kart = await _drop_kart(Vector3(400.0, 3.0, 400.0), 120)
	assert_bool(kart.is_on_ground()).is_true()
	assert_float(kart.global_position.y).is_between(-0.5, 0.5)
#@ all
