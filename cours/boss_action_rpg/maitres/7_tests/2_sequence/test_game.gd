extends GdUnitTestSuite
## Règles du jeu entier : il commence au Terrier, mains vides, porte fermée ; sans arme la plinthe arrête Bobine ; une arme
## prise lève la plinthe ; son seuil mène à la salle sous le comptoir, l'arme en main, et le noir retombe à zéro ; le seuil
## suivant mène au Gardien, toujours armée ; sa manette répond dans chaque salle ; un second seuil pendant un passage ne
## compte pas.

const GAME := preload("res://2_sequence/game.tscn")
const CELLAR: String = "res://2_sequence/cellar.tscn"
const BOSS: String = "res://2_sequence/main.tscn"


func _game() -> Game:
	var game: Game = auto_free(GAME.instantiate())
	add_child(game)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return game


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func _settled(game: Game) -> void:
	while game.changing:
		await get_tree().physics_frame


func _hero(game: Game) -> Hero:
	return game.level.get_node("Hero") as Hero


func _door(game: Game) -> PlinthDoor:
	return game.level.get_node("Door") as PlinthDoor


func _take(game: Game, stand_name: String) -> WeaponKit:
	var stand: WeaponStand = game.level.get_node("Armory/" + stand_name) as WeaponStand
	(stand.get_node("Hand") as Interactable).use()
	return stand.kit


func _gamepad_y(pressed: bool) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_Y
	event.pressed = pressed
	return event


func test_il_commence_au_terrier_mains_vides_porte_fermee() -> void:
	var game: Game = _game()
	await _frames(2)
	assert_str(game.level.name).is_equal("Burrow")
	assert_bool(_hero(game).unarmed).is_true()
	assert_bool(_door(game).open).is_false()
	assert_float(game.fade_alpha()).is_equal(0.0)


func test_sans_arme_la_plinthe_arrete_bobine() -> void:
	var game: Game = _game()
	var hero: Hero = _hero(game)
	hero.get_node("Input").free()
	await _frames(3)
	hero.global_position = Vector3(8.0, 0.0, -17.5)
	hero.stick = Vector2(0.0, -1.0)
	(game.level.get_node("OrbitCamera") as OrbitCamera).yaw = -PI / 2.0
	await _frames(60)
	assert_float(hero.global_position.x).is_less(11.0)
	assert_str(game.level.name).is_equal("Burrow")


func test_une_arme_prise_leve_la_plinthe() -> void:
	var game: Game = _game()
	await _frames(2)
	_take(game, "Needle")
	assert_bool(_door(game).open).is_true()


func test_son_seuil_mene_sous_le_comptoir_l_arme_en_main_et_le_noir_retombe() -> void:
	var game: Game = _game()
	await _frames(2)
	var kit: WeaponKit = _take(game, "Cork")
	_hero(game).global_position = Vector3(13.6, 0.0, -17.5)
	await _frames(4)
	assert_bool(game.changing).is_true()
	await _settled(game)
	assert_str(game.level.name).is_equal("Cellar")
	assert_that(_hero(game).weapon).is_same(kit)
	assert_str((game.level as Level).hud.weapon_name.text).is_equal(kit.display_name)
	assert_float(game.fade_alpha()).is_equal(0.0)


func test_le_seuil_suivant_mene_au_gardien_toujours_armee() -> void:
	var game: Game = _game()
	await _frames(2)
	var kit: WeaponKit = _take(game, "Caps")
	game.go_to(CELLAR)
	await _settled(game)
	game.go_to(BOSS)
	await _settled(game)
	assert_object(game.level.get_node("Golem")).is_not_null()
	assert_that(_hero(game).gun.settings).is_same(kit.gun)
	assert_bool(_hero(game).unarmed).is_false()


func test_sa_manette_repond_apres_un_changement_de_salle() -> void:
	var game: Game = _game()
	await _frames(2)
	_take(game, "Nailer")
	game.go_to(CELLAR)
	await _settled(game)
	await _frames(10)
	var hero: Hero = _hero(game)
	var start: Vector3 = hero.global_position
	var stick: InputEventJoypadMotion = InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_Y
	stick.axis_value = -1.0
	Input.parse_input_event(stick)
	Input.flush_buffered_events()
	await _frames(20)
	stick.axis_value = 0.0
	Input.parse_input_event(stick)
	Input.flush_buffered_events()
	assert_float(hero.global_position.distance_to(start)).is_greater(0.5)


func test_un_second_seuil_pendant_un_passage_ne_compte_pas() -> void:
	var game: Game = _game()
	await _frames(2)
	_take(game, "Nailer")
	game.go_to(CELLAR)
	game.go_to(BOSS)
	await _settled(game)
	assert_str(game.level.name).is_equal("Cellar")
