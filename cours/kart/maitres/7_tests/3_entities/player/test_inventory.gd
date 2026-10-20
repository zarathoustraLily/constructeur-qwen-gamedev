extends GdUnitTestSuite
## Règles de l'inventaire du joueur : deux objets au plus, on utilise le premier ramassé,
## les cases affichent les objets portés.

const SCENE_JOUEUR := "res://3_entities/player/player.tscn"


## Objet qui compte ses utilisations au lieu de lancer sa scène.
class ObjetTemoin extends ItemType:
	var utilisations := 0

	func use(_player: Player) -> void:
		utilisations += 1


var _joueur: Player


func before_test() -> void:
	_joueur = auto_free(load(SCENE_JOUEUR).instantiate())
	add_child(_joueur)


func _objet(nom: String) -> ObjetTemoin:
	var objet := ObjetTemoin.new()
	objet.name = nom
	objet.sprite = PlaceholderTexture2D.new()
	return objet


func test_au_depart_l_inventaire_est_vide_et_cache() -> void:
	assert_array(_joueur.inventory.items).is_empty()
	assert_bool(_joueur.inventory.inventory_control.visible).is_false()


func test_deux_objets_au_plus() -> void:
	var a := _objet("a")
	var b := _objet("b")
	assert_bool(_joueur.inventory.add_item(a)).is_true()
	assert_bool(_joueur.inventory.add_item(b)).is_true()
	assert_bool(_joueur.inventory.add_item(_objet("c"))).is_false()
	assert_array(_joueur.inventory.items).is_equal([a, b])


func test_un_objet_ramasse_apparait_dans_sa_case() -> void:
	var a := _objet("a")
	_joueur.inventory.add_item(a)
	assert_bool(_joueur.inventory.inventory_control.visible).is_true()
	assert_object(_joueur.inventory.item_slots[0].texture).is_same(a.sprite)
	assert_object(_joueur.inventory.item_slots[1].texture).is_null()


func test_on_utilise_le_premier_objet_ramasse() -> void:
	var a := _objet("a")
	var b := _objet("b")
	_joueur.inventory.add_item(a)
	_joueur.inventory.add_item(b)
	assert_bool(_joueur.inventory.use_item(_joueur)).is_true()
	assert_int(a.utilisations).is_equal(1)
	assert_int(b.utilisations).is_equal(0)
	assert_array(_joueur.inventory.items).is_equal([b])
	assert_object(_joueur.inventory.item_slots[0].texture).is_same(b.sprite)
	assert_object(_joueur.inventory.item_slots[1].texture).is_null()


func test_sans_objet_utiliser_ne_fait_rien() -> void:
	assert_bool(_joueur.inventory.use_item(_joueur)).is_false()


func test_le_joueur_range_ce_qu_il_recoit_dans_son_inventaire() -> void:
	var a := _objet("a")
	_joueur.add_item(a)
	assert_array(_joueur.inventory.items).is_equal([a])


func test_un_seul_objet_s_utilise_aussi() -> void:
	var a := _objet("a")
	_joueur.inventory.add_item(a)
	assert_bool(_joueur.inventory.use_item(_joueur)).is_true()
	assert_int(a.utilisations).is_equal(1)
	assert_array(_joueur.inventory.items).is_empty()
	assert_bool(_joueur.inventory.inventory_control.visible).is_false()


func test_la_commande_use_item_utilise_le_premier_objet() -> void:
	var a := _objet("a")
	_joueur.add_item(a)
	var commande := InputEventAction.new()
	commande.action = "use_item"
	commande.pressed = true
	_joueur._input(commande)
	assert_int(a.utilisations).is_equal(1)


func test_une_autre_commande_n_utilise_rien() -> void:
	var a := _objet("a")
	_joueur.add_item(a)
	var commande := InputEventAction.new()
	commande.action = "move_jump"
	commande.pressed = true
	_joueur._input(commande)
	assert_int(a.utilisations).is_equal(0)
