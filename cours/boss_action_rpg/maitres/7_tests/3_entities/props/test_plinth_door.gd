extends GdUnitTestSuite
## Règles de la plinthe : fermée, elle arrête les corps, et la main dit pourquoi ; ouverte, le passage est libre et la main se
## tait ; elle finit levée de toute sa hauteur.

const DOOR := preload("res://3_entities/props/plinth_door/plinth_door.tscn")


func _door() -> PlinthDoor:
	var door: PlinthDoor = auto_free(DOOR.instantiate())
	add_child(door)
	return door


func test_fermee_elle_arrete_les_corps_et_la_main_dit_pourquoi() -> void:
	var door: PlinthDoor = _door()
	assert_bool((door.get_node("Panel/Shape") as CollisionShape3D).disabled).is_false()
	assert_bool((door.get_node("Hand") as Interactable).enabled).is_true()
	assert_str((door.get_node("Hand") as Interactable).prompt).contains("arme")


func test_ouverte_le_passage_est_libre_et_la_main_se_tait() -> void:
	var door: PlinthDoor = _door()
	door.open_door()
	await get_tree().physics_frame
	await get_tree().process_frame
	assert_bool((door.get_node("Panel/Shape") as CollisionShape3D).disabled).is_true()
	assert_bool((door.get_node("Hand") as Interactable).enabled).is_false()


func test_elle_finit_levee_de_toute_sa_hauteur() -> void:
	var door: PlinthDoor = _door()
	door.open_door()
	door._process(10.0)
	assert_float((door.get_node("Panel") as Node3D).position.y).is_equal_approx(PlinthDoor.LIFT, 0.001)
