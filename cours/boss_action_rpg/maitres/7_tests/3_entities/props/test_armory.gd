extends GdUnitTestSuite
## Règles de l'Établi : un socle présente la forme de son arme, et son invite la nomme ; le prendre vide ce socle et le dit ;
## prendre une autre arme rend la première à son socle ; un seul socle est vide à la fois.

const STAND := preload("res://3_entities/props/armory/weapon_stand.tscn")
const CORK := preload("res://5_data/weapons/cork.tres")
const NEEDLE := preload("res://5_data/weapons/needle.tres")


func _stand(kit: WeaponKit, parent: Node) -> WeaponStand:
	var stand: WeaponStand = STAND.instantiate()
	stand.kit = kit
	parent.add_child(stand)
	return stand


func _armory() -> Armory:
	var armory: Armory = auto_free(Armory.new())
	_stand(CORK, armory)
	_stand(NEEDLE, armory)
	add_child(armory)
	return armory


func _hand(stand: WeaponStand) -> Interactable:
	return stand.get_node("Hand") as Interactable


func test_un_socle_presente_son_arme_et_son_invite_la_nomme() -> void:
	var stand: WeaponStand = _armory().stands[0]
	assert_object((stand.get_node("Display") as MeshInstance3D).mesh).is_not_null()
	assert_str(_hand(stand).prompt).contains(CORK.display_name)


func test_le_prendre_vide_ce_socle_et_le_dit() -> void:
	var armory: Armory = _armory()
	var chosen: Array[WeaponKit] = []
	armory.chosen.connect(func(kit: WeaponKit) -> void: chosen.append(kit))
	_hand(armory.stands[0]).use()
	assert_array(chosen).contains_exactly([CORK])
	assert_bool(armory.stands[0].empty).is_true()
	assert_bool(_hand(armory.stands[0]).enabled).is_false()
	assert_bool((armory.stands[0].get_node("Display") as Node3D).visible).is_false()


func test_prendre_une_autre_arme_rend_la_premiere_a_son_socle() -> void:
	var armory: Armory = _armory()
	_hand(armory.stands[0]).use()
	_hand(armory.stands[1]).use()
	assert_bool(armory.stands[0].empty).is_false()
	assert_bool(_hand(armory.stands[0]).enabled).is_true()
	assert_bool(armory.stands[1].empty).is_true()
