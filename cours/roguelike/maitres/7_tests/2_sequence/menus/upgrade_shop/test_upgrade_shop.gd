extends GdUnitTestSuite
## Règles de la boutique : elle propose deux améliorations différentes ; une même graine et un même rang, les mêmes ;
## la première carte a le focus ; à la manette, la croix change de carte et A choisit ; le choix s'applique au
## joueur gardé par GameFlow et l'étape finit, une seule fois.

const SHOP := preload("res://2_sequence/menus/upgrade_shop/upgrade_shop.tscn")
const PLAYER := preload("res://3_entities/player/player.tscn")

var _saved_rank: int


func before_test() -> void:
	_saved_rank = GameState.level


func after_test() -> void:
	GameState.level = _saved_rank
	var carried := GameFlow.take_player()
	if carried != null:
		carried.free()


func _shop() -> Node:
	var shop: Node = auto_free(SHOP.instantiate())
	add_child(shop)
	return shop


func test_elle_propose_deux_ameliorations_differentes() -> void:
	var offers: Array[Upgrade] = _shop().call(&"offers")
	assert_int(offers.size()).is_equal(2)
	assert_object(offers[0]).is_not_same(offers[1])


func test_une_meme_graine_et_un_meme_rang_les_memes() -> void:
	GameState.level = 2
	var first: Array[Upgrade] = _shop().call(&"offers")
	var second: Array[Upgrade] = _shop().call(&"offers")
	assert_array(second).is_equal(first)


func test_la_premiere_carte_a_le_focus() -> void:
	var shop := _shop()
	await get_tree().process_frame
	var first := shop.get_node("MarginContainer/VBoxContainer/HBoxContainer").get_child(0) as UpgradeIcon
	assert_bool(first.button.has_focus()).is_true()


func test_le_choix_s_applique_au_joueur_garde_et_l_etape_finit_une_fois() -> void:
	var player := PLAYER.instantiate() as Player
	add_child(player)
	remove_child(player)
	GameFlow.set("_carried_player", player)
	var shop := _shop()
	var outcomes: Array[StringName] = []
	(shop as Step).finished.connect(func(outcome: StringName) -> void: outcomes.append(outcome))
	var icons := shop.get_node("MarginContainer/VBoxContainer/HBoxContainer").get_children()
	var upgrade := (icons[0] as UpgradeIcon).upgrade
	var initial := upgrade.current_value(player)
	(icons[0] as UpgradeIcon).button.pressed.emit()
	(icons[1] as UpgradeIcon).button.pressed.emit()
	assert_float(upgrade.current_value(player)).is_equal(initial + upgrade.bonus)
	assert_array(outcomes).is_equal([&"done"])


func test_a_la_manette_la_croix_change_de_carte_et_a_choisit() -> void:
	var shop := _shop()
	var outcomes: Array[StringName] = []
	(shop as Step).finished.connect(func(outcome: StringName) -> void: outcomes.append(outcome))
	# Le conteneur place les cartes à l'image suivante, et le focus est donné à la fin de l'image.
	await get_tree().process_frame
	await get_tree().process_frame
	var second := shop.get_node("MarginContainer/VBoxContainer/HBoxContainer").get_child(1) as UpgradeIcon
	var chosen: Array[Upgrade] = []
	second.chosen.connect(func(upgrade: Upgrade) -> void: chosen.append(upgrade))
	_tap(JOY_BUTTON_DPAD_RIGHT)
	assert_bool(second.button.has_focus()).is_true()
	_tap(JOY_BUTTON_A)
	assert_array(chosen).is_equal([second.upgrade])
	assert_array(outcomes).is_equal([&"done"])


# Appuie sur un bouton de la manette, puis le relâche : les événements vont à l'interface, comme ceux d'une vraie
# manette.
func _tap(pad_button: JoyButton) -> void:
	get_viewport().push_input(_pad_event(pad_button, true))
	get_viewport().push_input(_pad_event(pad_button, false))


func _pad_event(pad_button: JoyButton, is_down: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = pad_button
	event.pressed = is_down
	return event
