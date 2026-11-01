extends GdUnitTestSuite
## Règles de la main : elle voit ce qui entre dans sa zone, et plus ce qui en sort ; elle retient le plus proche ; elle
## ignore un objet inactif ; elle redit l'invite quand le choix change et quand le texte de l'objet change ; sans rien à
## portée, l'invite est vide et l'actionner ne fait rien.


func _hand() -> Interactor:
	var hand: Interactor = auto_free(Interactor.new())
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 2.0
	shape.shape = sphere
	hand.add_child(shape)
	add_child(hand)
	return hand


func _item(at: Vector3, prompt: String) -> Interactable:
	var item: Interactable = auto_free(Interactable.new())
	item.prompt = prompt
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.5
	shape.shape = sphere
	item.add_child(shape)
	add_child(item)
	item.global_position = at
	return item


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func test_elle_voit_ce_qui_entre_dans_sa_zone_et_plus_ce_qui_en_sort() -> void:
	var hand: Interactor = _hand()
	var item: Interactable = _item(Vector3(1.0, 0.0, 0.0), "a")
	await _frames(3)
	assert_that(hand.focused).is_same(item)
	item.global_position = Vector3(30.0, 0.0, 0.0)
	await _frames(3)
	assert_object(hand.focused).is_null()


func test_elle_retient_le_plus_proche() -> void:
	var hand: Interactable = null
	var main: Interactor = _hand()
	var far: Interactable = _item(Vector3(1.8, 0.0, 0.0), "loin")
	hand = _item(Vector3(0.7, 0.0, 0.0), "près")
	await _frames(3)
	assert_that(main.focused).is_same(hand)
	assert_that(main.focused).is_not_same(far)


func test_elle_ignore_un_objet_inactif() -> void:
	var hand: Interactor = _hand()
	var item: Interactable = _item(Vector3(1.0, 0.0, 0.0), "a")
	item.enabled = false
	await _frames(3)
	assert_object(hand.focused).is_null()


func test_elle_redit_l_invite_quand_le_choix_ou_le_texte_change() -> void:
	var hand: Interactor = _hand()
	var said: Array[String] = []
	hand.focus_changed.connect(func(prompt: String) -> void: said.append(prompt))
	var item: Interactable = _item(Vector3(1.0, 0.0, 0.0), "Souffler")
	await _frames(3)
	item.prompt = "Rallumer"
	await _frames(1)
	item.global_position = Vector3(30.0, 0.0, 0.0)
	await _frames(3)
	assert_array(said).contains_exactly(["Souffler", "Rallumer", ""])


func test_sans_rien_a_portee_l_actionner_ne_fait_rien() -> void:
	assert_bool(_hand().use_focused()).is_false()
