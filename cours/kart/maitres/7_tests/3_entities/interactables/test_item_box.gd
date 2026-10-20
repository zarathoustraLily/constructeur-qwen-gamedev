extends GdUnitTestSuite
## Règles de la boîte à objets : le kart d'un joueur y prend un objet, un éclair le frappe,
## la boîte disparaît puis revient au bout d'une seconde.

const SCENE_BOITE := "res://3_entities/interactables/item_box/item_box.tscn"
const SCENE_JOUEUR := "res://3_entities/player/player.tscn"

## L'éclair s'ajoute à la scène courante : les tests en fournissent une, retirée ensuite.
var _scene: Node3D
var _scene_d_avant: Node
var _joueur: Player


func before_test() -> void:
	_scene_d_avant = get_tree().current_scene
	_scene = Node3D.new()
	get_tree().root.add_child(_scene)
	get_tree().current_scene = _scene
	_joueur = load(SCENE_JOUEUR).instantiate()
	_scene.add_child(_joueur)


func after_test() -> void:
	get_tree().current_scene = _scene_d_avant
	_scene.free()


func _boite() -> Node3D:
	var boite: Node3D = load(SCENE_BOITE).instantiate()
	_scene.add_child(boite)
	return boite


func _eclairs() -> Array[Node]:
	return _scene.find_children("*", "LightningStrike", false, false)


func test_au_depart_la_boite_est_active_et_visible() -> void:
	var boite := _boite()
	assert_bool(boite.active).is_true()
	assert_bool(boite.visual_item_box.visible).is_true()
	assert_float(boite.light.omni_range).is_greater(0.0)


func test_desactivee_elle_est_cachee_et_eteinte_puis_revient_comme_avant() -> void:
	var boite := _boite()
	var portee: float = boite.light.omni_range
	boite.deactivate()
	assert_bool(boite.active).is_false()
	assert_bool(boite.visual_item_box.visible).is_false()
	assert_float(boite.light.omni_range).is_equal(0.0)
	boite.activate()
	assert_bool(boite.active).is_true()
	assert_bool(boite.visual_item_box.visible).is_true()
	assert_float(boite.light.omni_range).is_equal(portee)


func test_le_kart_d_un_joueur_prend_un_objet_et_un_eclair_le_frappe() -> void:
	var boite := _boite()
	boite._on_area_3d_body_entered(_joueur.kart)
	assert_int(_joueur.inventory.items.size()).is_equal(1)
	assert_str(_joueur.inventory.items[0].name).is_equal("bomb")
	assert_bool(boite.active).is_false()
	assert_int(_eclairs().size()).is_equal(1)


func test_la_boite_revient_au_bout_d_une_seconde() -> void:
	var boite := _boite()
	boite._on_area_3d_body_entered(_joueur.kart)
	await await_millis(800)
	assert_bool(boite.active).is_false()
	await await_millis(400)
	assert_bool(boite.active).is_true()


func test_une_boite_vide_ne_donne_rien() -> void:
	var boite := _boite()
	boite.deactivate()
	boite._on_area_3d_body_entered(_joueur.kart)
	assert_array(_joueur.inventory.items).is_empty()
	assert_array(_eclairs()).is_empty()


func test_un_corps_qui_n_est_pas_un_joueur_ne_prend_rien() -> void:
	var boite := _boite()
	var parent := Node3D.new()
	var corps := StaticBody3D.new()
	parent.add_child(corps)
	_scene.add_child(parent)
	boite._on_area_3d_body_entered(corps)
	assert_bool(boite.active).is_true()
	assert_array(_eclairs()).is_empty()


func test_deux_boites_coup_sur_coup_relancent_le_meme_eclair() -> void:
	_boite()._on_area_3d_body_entered(_joueur.kart)
	var premier: Node = _joueur.kart.get_meta("lightning_strike")
	_boite()._on_area_3d_body_entered(_joueur.kart)
	assert_int(_eclairs().size()).is_equal(1)
	assert_object(_joueur.kart.get_meta("lightning_strike")).is_same(premier)
	assert_int(_joueur.inventory.items.size()).is_equal(2)
