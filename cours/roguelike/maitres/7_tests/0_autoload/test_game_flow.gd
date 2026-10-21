extends GdUnitTestSuite
## Règles du chef d'orchestre, qui seul charge les scènes : il charge le premier niveau de l'ordre ; une étape finie,
## il charge la suivante, après un fondu au noir ; après la dernière, la première ; « retry » recharge l'étape ; le
## joueur est gardé de côté pendant un changement, et l'étape suivante le reprend, mais pas sur un « retry » ; une
## même graine tire un même ordre ; une séquence vide ne charge rien. La séquence du jeu tire l'ordre de ses trois
## niveaux, et la scène de démarrage la remet à GameFlow.
#@ 13+
## Après un niveau vient l'intermède, avec le joueur gardé, puis le niveau suivant ; la séquence du jeu a pour
## intermède la boutique.
#@ all

const STEP_A := preload("res://7_tests/0_autoload/step_a.tscn")
const STEP_B := preload("res://7_tests/0_autoload/step_b.tscn")
const GAME_SEQUENCE := preload("res://2_sequence/sequence.tres")
const BOOT := preload("res://2_sequence/boot.tscn")

var _saved_scene: Node
var _saved_fade: float
var _saved_pause: float
var _placeholder: Node


func before_test() -> void:
	_saved_scene = get_tree().current_scene
	_saved_fade = GameFlow.fade_time
	_saved_pause = GameFlow.pause_time
	# Des fondus courts : quelques images.
	GameFlow.fade_time = 0.05
	GameFlow.pause_time = 0.05
	# Une scène courante jetable : GameFlow la libère en chargeant la première étape.
	_placeholder = Node.new()
	get_tree().root.add_child(_placeholder)
	get_tree().current_scene = _placeholder


func after_test() -> void:
	var current := get_tree().current_scene
	if is_instance_valid(current) and current != _saved_scene:
		current.free()
	if is_instance_valid(_placeholder):
		_placeholder.free()
	var carried := GameFlow.take_player()
	if carried != null:
		carried.free()
	get_tree().current_scene = _saved_scene
	GameFlow.fade_time = _saved_fade
	GameFlow.pause_time = _saved_pause


func _sequence(shuffle: bool) -> Sequence:
	var sequence := Sequence.new()
	sequence.steps = [STEP_A, STEP_B]
	sequence.shuffle = shuffle
	return sequence


func _current_name() -> String:
	await get_tree().process_frame
	return str(get_tree().current_scene.name)


## Le temps d'un changement : fondu, pause, retour de l'image.
func _transition() -> void:
	for _frame: int in int((GameFlow.fade_time * 2.0 + GameFlow.pause_time) * 60.0) + 10:
		await get_tree().process_frame


func test_il_charge_le_premier_niveau_de_l_ordre() -> void:
	GameFlow.start(_sequence(false))
	assert_str(await _current_name()).is_equal("StepA")


func test_une_etape_finie_il_charge_la_suivante_apres_un_fondu() -> void:
	GameFlow.start(_sequence(false))
	await _transition()
	GameFlow.current_step.finish()
	await get_tree().process_frame
	assert_str(str(get_tree().current_scene.name)).is_equal("StepA")
	await _transition()
	assert_str(await _current_name()).is_equal("StepB")
	assert_float((GameFlow.get_node("Veil") as ColorRect).color.a).is_equal_approx(0.0, 0.01)


func test_apres_la_derniere_il_revient_a_la_premiere() -> void:
	GameFlow.start(_sequence(false))
	GameFlow.current_step.finish()
	await _transition()
	GameFlow.current_step.finish()
	await _transition()
	assert_str(await _current_name()).is_equal("StepA")


func test_retry_recharge_l_etape() -> void:
	GameFlow.start(_sequence(false))
	var first := GameFlow.current_step
	GameFlow.current_step.finish(&"retry")
	await _transition()
	assert_str(await _current_name()).is_equal("StepA")
	assert_object(GameFlow.current_step).is_not_same(first)


func test_le_joueur_est_garde_et_l_etape_suivante_le_reprend() -> void:
	GameFlow.start(_sequence(false))
	var player: Node3D = Node3D.new()
	player.add_to_group(&"player")
	GameFlow.current_step.add_child(player)
	GameFlow.current_step.finish()
	await _transition()
	assert_str(await _current_name()).is_equal("StepB")
	assert_object(GameFlow.take_player()).is_same(player)
	assert_object(GameFlow.take_player()).is_null()
	player.free()


func test_sur_un_retry_le_joueur_n_est_pas_garde() -> void:
	GameFlow.start(_sequence(false))
	var player: Node3D = Node3D.new()
	player.add_to_group(&"player")
	GameFlow.current_step.add_child(player)
	GameFlow.current_step.finish(&"retry")
	await _transition()
	assert_object(GameFlow.take_player()).is_null()


func test_une_meme_graine_tire_un_meme_ordre() -> void:
	var orders: Array[String] = []
	for _run: int in 2:
		var sequence := Sequence.new()
		sequence.steps = [STEP_A, STEP_B, STEP_A, STEP_B, STEP_A]
		sequence.shuffle = true
		sequence.random_seed = 4
		GameFlow.start(sequence)
		orders.append(str(GameFlow.order.map(func(scene: PackedScene) -> String: return scene.resource_path.get_file())))
	assert_str(orders[1]).is_equal(orders[0])


func test_une_sequence_vide_ne_charge_rien() -> void:
	assert_error(func() -> void: GameFlow.start(Sequence.new())).is_push_error("GameFlow.start : séquence vide")
	assert_object(get_tree().current_scene).is_same(_placeholder)


func test_la_sequence_du_jeu_tire_l_ordre_de_ses_trois_niveaux() -> void:
	assert_int(GAME_SEQUENCE.steps.size()).is_equal(3)
	assert_bool(GAME_SEQUENCE.shuffle).is_true()


func test_la_scene_de_demarrage_remet_la_sequence_du_jeu() -> void:
	var boot := BOOT.instantiate()
	assert_object(boot.get("sequence")).is_same(GAME_SEQUENCE)
	boot.free()
#@ 13+


func test_apres_un_niveau_l_intermede_puis_le_niveau_suivant() -> void:
	var sequence := _sequence(false)
	sequence.steps = [STEP_A]
	sequence.interlude = STEP_B
	GameFlow.start(sequence)
	var player: Node3D = Node3D.new()
	player.add_to_group(&"player")
	GameFlow.current_step.add_child(player)
	GameFlow.current_step.finish()
	await _transition()
	assert_str(await _current_name()).is_equal("StepB")
	assert_object(GameFlow.carried_player()).is_same(player)
	GameFlow.current_step.finish()
	await _transition()
	assert_str(await _current_name()).is_equal("StepA")
	assert_object(GameFlow.take_player()).is_same(player)
	player.free()


func test_la_sequence_du_jeu_a_pour_intermede_la_boutique() -> void:
	assert_str(GAME_SEQUENCE.interlude.resource_path).is_equal("res://2_sequence/menus/upgrade_shop/upgrade_shop.tscn")
#@ all
