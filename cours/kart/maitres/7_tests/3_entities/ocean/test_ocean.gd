extends GdUnitTestSuite
## Règles de l'océan, sans fenêtre, donc sans RenderingDevice : la houle ne démarre pas, l'eau est plate à
## hauteur 0, et la mer calme remplace la surface de l'océan, dont aucun carré n'est construit. Le masque de
## l'île est faible sur l'île, vaut 1 au large, et garde la valeur de son bord au-delà du carré qu'il couvre.
#@ 9+
## Ondulations, vagues d'impact et écume vont chacune à sa simulation, et toutes suivent le joueur.
#@ all

const OCEAN := preload("res://3_entities/ocean/ocean.tscn")
const START := Vector3(4.8399, 4.47262, -5.20099)

var _ocean: Ocean


func before_test() -> void:
	_ocean = auto_free(OCEAN.instantiate())
	add_child(_ocean)


func test_sans_rendering_device_la_mer_calme_remplace_l_ocean() -> void:
	assert_object(RenderingServer.get_rendering_device()).is_null()
	assert_bool((_ocean.get_node("CalmSea") as MeshInstance3D).visible).is_true()
	assert_int(_ocean.get_node("QuadTree3DView/SubQuads").get_child_count()).is_equal(0)


func test_sans_houle_l_eau_est_plate() -> void:
	for _frame: int in 3:
		await get_tree().physics_frame
	for point: Vector3 in [Vector3(100.0, 0.0, 100.0), Vector3(400.0, 0.0, -300.0), START]:
		assert_float(_ocean.get_wave_height(point)).is_equal(0.0)


func test_le_masque_est_faible_sur_l_ile_et_vaut_un_au_large() -> void:
	assert_float(_ocean.get_island_mask(START)).is_less(0.3)
	assert_float(_ocean.get_island_mask(Vector3(400.0, 0.0, 400.0))).is_equal_approx(1.0, 0.01)


func test_au_dela_du_masque_la_valeur_de_son_bord() -> void:
	assert_float(_ocean.get_island_mask(Vector3(3000.0, 0.0, 0.0))).is_equal_approx(
		_ocean.get_island_mask(Vector3(479.0, 0.0, 0.0)), 0.001)
	assert_float(_ocean.get_island_mask(Vector3(-3000.0, 0.0, 2000.0))).is_equal_approx(1.0, 0.01)
#@ 9+


func test_ondulations_vagues_et_ecume_vont_a_leur_simulation() -> void:
	_ocean.add_ripple(Vector3(1.0, 0.0, 2.0), 0.1, 4.0)
	_ocean.add_wave(Vector3(3.0, 0.0, 4.0), 0.2, 3.0)
	_ocean.add_foam(Vector3(5.0, 0.0, 6.0), 0.5, 0.4)
	assert_that(_ocean.water_ripples.ripple_origins).is_equal([Vector4(1.0, 2.0, 0.1, 4.0)])
	assert_that(_ocean.water_waves.ripple_origins).is_equal([Vector4(3.0, 4.0, 0.2, 3.0)])
	assert_that(_ocean.water_foam.foam_origins).is_equal([Vector4(5.0, 6.0, 0.5, 0.4)])


func test_les_simulations_suivent_le_joueur() -> void:
	var player := Vector3(12.0, 0.5, -7.0)
	_ocean.set_player_position(player)
	assert_vector(_ocean.water_ripples.texture_offset).is_equal(player)
	assert_vector(_ocean.water_waves.texture_offset).is_equal(player)
	assert_vector(_ocean.water_foam.texture_offset).is_equal(player)
#@ all
